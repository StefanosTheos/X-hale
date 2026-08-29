"""
Medical Information Agent.

Retrieves evidence-based content from the knowledge base and returns
a SpecialistDraft with key_points, each traced to a source_id.
"""
from __future__ import annotations

import json
import re

from app.agents.base import AgentBase
from app.llm.client import get_triage_client
from app.llm.schemas import SPECIALIST_DRAFT_SCHEMA
from app.models.retrieval import Citation, KeyPoint, SpecialistDraft, bounded_excerpt
from app.observability.logging import get_logger
from app.prompts.medical import MEDICAL_SYSTEM, MEDICAL_USER_TEMPLATE
from app.retrieval.hybrid_retriever import retrieve

logger = get_logger(__name__)

_SENTENCE_RE = re.compile(r"(?<=[.!?])\s+|\n+")
_WORD_RE = re.compile(r"[a-z0-9]+")
_EVIDENCE_STOPWORDS = frozenset({
    "a", "an", "and", "are", "can", "do", "does", "for", "how", "i", "in",
    "is", "it", "my", "of", "or", "the", "to", "use", "what", "when", "while",
    "will", "with", "after", "quit", "quitting", "smoking",
})
_QUERY_EVIDENCE_EXPANSIONS: tuple[tuple[re.Pattern[str], set[str]], ...] = (
    (re.compile(r"\bskin|complexion|wrinkle", re.I), {"skin", "complexion", "wrinkle"}),
    (re.compile(r"\bfertil|reproduct", re.I), {"fertility", "fertile", "reproductive"}),
    (re.compile(r"\bwound|surgery", re.I), {"wound", "healing", "surgery", "surgical"}),
    (re.compile(r"\bimmune|infection", re.I), {"immune", "infection"}),
    (re.compile(r"\bbone|osteoporosis", re.I), {"bone", "density", "osteoporosis", "fracture"}),
    (re.compile(r"\bsleep|dream", re.I), {"sleep", "dream", "dreams", "insomnia"}),
    (re.compile(r"\b(?:mouth|oral|gum|teeth)", re.I), {"mouth", "oral", "gum", "gums", "teeth", "periodontitis"}),
    (re.compile(r"\b(?:nrt|patch|gum|varenicline|champix|chantix)", re.I),
     {"nrt", "nicotine", "patch", "patches", "gum", "varenicline", "champix", "chantix"}),
)


def _parse_json_object(raw: str) -> dict:
    """Parse strict JSON or the first JSON object in a fallback model reply."""
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        start = raw.find("{")
        end = raw.rfind("}")
        if start < 0 or end <= start:
            raise
        value = json.loads(raw[start:end + 1])
    if not isinstance(value, dict):
        raise ValueError("medical specialist output must be a JSON object")
    return value


def _canonicalise_key_points(
    raw_key_points: list[dict], retrieval,
) -> list[KeyPoint]:
    """Map model claims to complete source sentences with canonical source IDs."""
    source_ids = [chunk.source_id for chunk in retrieval.chunks]
    by_casefold = {source_id.casefold(): source_id for source_id in source_ids}
    key_points: list[KeyPoint] = []
    for value in raw_key_points:
        claim = str(value.get("claim", "")).strip()
        raw_source_id = str(value.get("source_id", "")).strip()
        source_id = by_casefold.get(raw_source_id.casefold())
        if source_id is None and raw_source_id.isdigit():
            index = int(raw_source_id) - 1
            if 0 <= index < len(source_ids):
                source_id = source_ids[index]
        if claim and source_id:
            claim_terms = set(_WORD_RE.findall(claim.casefold())) - _EVIDENCE_STOPWORDS
            candidates: list[tuple[float, str]] = []
            for chunk in retrieval.chunks:
                if chunk.source_id != source_id:
                    continue
                for sentence in _SENTENCE_RE.split(chunk.content):
                    sentence = " ".join(sentence.split()).strip()
                    if len(sentence) < 25 or len(sentence) > 420:
                        continue
                    sentence_terms = set(_WORD_RE.findall(sentence.casefold())) - _EVIDENCE_STOPWORDS
                    if not claim_terms or not sentence_terms:
                        continue
                    overlap = len(claim_terms & sentence_terms) / len(claim_terms)
                    if overlap >= 0.25:
                        candidates.append((overlap, sentence))
            if candidates:
                # Preserve the retrieved wording rather than allowing synthesis
                # to attribute a broader model-created mechanism to the source.
                _, supported_sentence = max(candidates, key=lambda item: item[0])
                key_points.append(KeyPoint(claim=supported_sentence, source_id=source_id))
            else:
                logger.warning("medical_key_point_not_grounded", source_id=source_id)
        elif claim:
            logger.warning("medical_key_point_invalid_source", source_id=raw_source_id)
    return key_points


def _promote_retrieved_evidence(user_input: str, retrieval, limit: int = 2) -> list[KeyPoint]:
    """Copy complete, query-relevant source sentences when extraction is empty."""
    query_terms = {
        token for token in _WORD_RE.findall(user_input.casefold())
        if token not in _EVIDENCE_STOPWORDS and len(token) > 2
    }
    for pattern, terms in _QUERY_EVIDENCE_EXPANSIONS:
        if pattern.search(user_input):
            query_terms.update(terms)
    ranked: list[tuple[float, str, str]] = []
    for chunk in retrieval.chunks:
        for sentence in _SENTENCE_RE.split(chunk.content):
            sentence = " ".join(sentence.split()).strip()
            if len(sentence) < 35 or len(sentence) > 420:
                continue
            sentence_terms = set(_WORD_RE.findall(sentence.casefold()))
            overlap = query_terms & sentence_terms
            if not overlap:
                continue
            ranked.append((len(overlap) + float(chunk.score), sentence, chunk.source_id))
    promoted: list[KeyPoint] = []
    seen: set[tuple[str, str]] = set()
    for _, sentence, source_id in sorted(ranked, reverse=True):
        key = (sentence.casefold(), source_id)
        if key in seen:
            continue
        seen.add(key)
        promoted.append(KeyPoint(claim=sentence, source_id=source_id))
        if len(promoted) == limit:
            break
    return promoted


class MedicalAgent(AgentBase):
    name = "medical"

    async def run(self, state) -> SpecialistDraft:  # type: ignore[override]
        user_input: str = state["user_input"]
        memory = state.get("user_memory")
        profile_snippet = memory.format_profile_for_prompt() if memory else "(no profile)"

        retrieval = await retrieve(
            query=user_input,
            user_id=state["user_id"],
            strategy="factual",
            k=5,
            intent=(state.get("triage").intent if state.get("triage") else "unknown"),
        )

        if not retrieval.chunks:
            logger.info("medical_agent_no_chunks", user_id=state["user_id"])
            return SpecialistDraft(
                agent=self.name,
                key_points=[],
                tone_hint="factual_reassuring",
                raw_context="I couldn't find specific information on that in my knowledge base.",
                citations=[],
                retrieval_trace={
                    "query": retrieval.query, "strategy": retrieval.strategy_used,
                    "collections": ["kb_chunks"], "documents": [],
                },
            )

        client = get_triage_client()  # Low-temperature model for structured extraction
        messages = [
            {"role": "system", "content": MEDICAL_SYSTEM},
            {
                "role": "user",
                "content": MEDICAL_USER_TEMPLATE.format(
                    user_input=user_input,
                    retrieved_context=retrieval.format_for_prompt(),
                    user_profile_snippet=profile_snippet,
                ),
            },
        ]
        try:
            raw = await client.complete(
                messages=messages, temperature=0.0, json_mode=True,
                response_schema=SPECIALIST_DRAFT_SCHEMA, max_tokens=900,
            )
            data = _parse_json_object(raw)
            key_points = _canonicalise_key_points(data.get("key_points", []), retrieval)
            if not key_points:
                key_points = _promote_retrieved_evidence(user_input, retrieval)
                if key_points:
                    logger.info(
                        "medical_evidence_promoted",
                        source_ids=[point.source_id for point in key_points],
                    )
            trace = {
                "query": retrieval.query,
                "strategy": retrieval.strategy_used,
                "collections": sorted({
                    chunk.metadata.get("collection", "web") for chunk in retrieval.chunks
                }),
                "documents": [
                    {"document_id": chunk.metadata.get("document_id"),
                     "collection": chunk.metadata.get("collection", "web"),
                     "source_id": chunk.source_id, "source_type": chunk.source_type,
                     "score": chunk.score, "snippet": bounded_excerpt(chunk.content, 400)}
                    for chunk in retrieval.chunks
                ],
                "specialist_source_ids": [kp.source_id for kp in key_points if kp.source_id],
                "proposed_citation_ids": [c.source_id for c in retrieval.citations],
            }
            return SpecialistDraft(
                agent=self.name,
                key_points=key_points,
                tone_hint=data.get("tone_hint", "factual_reassuring"),
                # Do not give synthesis a second, unattributed paraphrase path.
                # The canonical key points are the complete evidence contract.
                raw_context=" ".join(point.claim for point in key_points),
                citations=retrieval.citations,
                suggested_deeplinks=[],
                retrieval_trace=trace,
            )
        except (json.JSONDecodeError, ValueError) as exc:
            logger.warning("medical_agent_parse_failed", error=str(exc))
            promoted = _promote_retrieved_evidence(user_input, retrieval)
            return SpecialistDraft(
                agent=self.name,
                key_points=promoted,
                tone_hint="factual_reassuring",
                raw_context=" ".join(point.claim for point in promoted),
                citations=retrieval.citations,
                retrieval_trace={
                    "query": retrieval.query, "strategy": retrieval.strategy_used,
                    "collections": sorted({
                        chunk.metadata.get("collection", "web") for chunk in retrieval.chunks
                    }),
                    "documents": [
                        {"document_id": chunk.metadata.get("document_id"),
                         "collection": chunk.metadata.get("collection", "web"),
                         "source_id": chunk.source_id, "source_type": chunk.source_type,
                         "score": chunk.score, "snippet": bounded_excerpt(chunk.content, 400)}
                        for chunk in retrieval.chunks
                    ],
                    "specialist_source_ids": [point.source_id for point in promoted],
                    "proposed_citation_ids": [c.source_id for c in retrieval.citations],
                },
            )
