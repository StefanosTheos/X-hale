"""
Medical Information Agent.

Retrieves evidence-based content from the knowledge base and returns
a SpecialistDraft with key_points, each traced to a source_id.
"""
from __future__ import annotations

import json

from app.agents.base import AgentBase
from app.llm.client import get_triage_client
from app.llm.schemas import SPECIALIST_DRAFT_SCHEMA
from app.models.retrieval import Citation, KeyPoint, SpecialistDraft
from app.observability.logging import get_logger
from app.prompts.medical import MEDICAL_SYSTEM, MEDICAL_USER_TEMPLATE
from app.retrieval.hybrid_retriever import retrieve

logger = get_logger(__name__)


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
    """Accept only retrieved source IDs, repairing legacy numeric references."""
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
            key_points.append(KeyPoint(claim=claim, source_id=source_id))
        elif claim:
            logger.warning("medical_key_point_invalid_source", source_id=raw_source_id)
    return key_points


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
                     "score": chunk.score, "snippet": chunk.content[:400]}
                    for chunk in retrieval.chunks
                ],
                "specialist_source_ids": [kp.source_id for kp in key_points if kp.source_id],
                "proposed_citation_ids": [c.source_id for c in retrieval.citations],
            }
            return SpecialistDraft(
                agent=self.name,
                key_points=key_points,
                tone_hint=data.get("tone_hint", "factual_reassuring"),
                raw_context=data.get("raw_context", retrieval.format_for_prompt()[:400]),
                citations=retrieval.citations,
                suggested_deeplinks=[],
                retrieval_trace=trace,
            )
        except (json.JSONDecodeError, ValueError) as exc:
            logger.warning("medical_agent_parse_failed", error=str(exc))
            # Graceful degradation: return raw context without structured key_points
            return SpecialistDraft(
                agent=self.name,
                key_points=[],
                tone_hint="factual_reassuring",
                raw_context=retrieval.format_for_prompt()[:600],
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
                         "score": chunk.score, "snippet": chunk.content[:400]}
                        for chunk in retrieval.chunks
                    ],
                    "specialist_source_ids": [],
                    "proposed_citation_ids": [c.source_id for c in retrieval.citations],
                },
            )
