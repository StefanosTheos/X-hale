"""
Synthesizer Agent — uses the configured Groq synthesis model (GPT OSS 120B by default).

Receives all specialist_drafts + user memory + conversation history.
Composes one coherent reply in Hailey's voice and streams it token-by-token.
Extracts and validates citations from the final response.
"""
from __future__ import annotations

import json
import re
from typing import AsyncIterator

from app.llm.client import get_synthesis_client
from app.models.retrieval import Citation, SpecialistDraft
from app.observability.logging import get_logger
from app.prompts.system import HAILEY_SYSTEM
from app.prompts.synthesizer import SYNTHESIZER_SYSTEM, SYNTHESIZER_USER_TEMPLATE
from app.safety.citation_validator import validate_citations
from app.safety.content_filter import filter_response
from app.safety.medical_risk import medical_risk_tier

logger = get_logger(__name__)

_CITATION_PATTERN = re.compile(r"<!--\s*citations:\s*(\[.*?\])\s*-->", re.DOTALL)
_INLINE_MARKER_PATTERN = re.compile(r"\[[a-z][a-z0-9_]+\]")
_NUMBER_PATTERN = re.compile(r"\b\d+(?:\.\d+)?\b")
_TIME_UNIT_PATTERN = re.compile(r"\b(?:hours?|days?|weeks?|months?|years?)\b", re.IGNORECASE)
_SENTENCE_SPLIT = re.compile(r"(?<=[.!?])\s+|\n+")


def _quantitative_sentence_is_attributed(sentence: str, claims: list[str]) -> bool:
    """Require every stated number and time unit to occur in one attributed claim."""
    sentence_numbers = set(_NUMBER_PATTERN.findall(sentence))
    sentence_units = {unit.casefold().rstrip("s") for unit in _TIME_UNIT_PATTERN.findall(sentence)}
    if not sentence_numbers and not sentence_units:
        return True
    for claim in claims:
        claim_numbers = set(_NUMBER_PATTERN.findall(claim))
        claim_units = {unit.casefold().rstrip("s") for unit in _TIME_UNIT_PATTERN.findall(claim)}
        if sentence_numbers.issubset(claim_numbers) and sentence_units.issubset(claim_units):
            return True
    return False


def _format_specialist_drafts(drafts: dict[str, str]) -> str:
    """Format all specialist drafts into a single text block for the synthesizer."""
    if not drafts:
        return "(No specialist drafts — respond as a friendly general assistant.)"
    lines: list[str] = []
    for agent_name, draft_json in drafts.items():
        lines.append(f"=== {agent_name.upper()} AGENT ===")
        try:
            draft = json.loads(draft_json) if isinstance(draft_json, str) else draft_json
            tone = draft.get("tone_hint", "warm_supportive")
            lines.append(f"Tone hint: {tone}")
            for kp in draft.get("key_points", []):
                claim = kp.get("claim", "") if isinstance(kp, dict) else kp.claim
                src = kp.get("source_id", "") if isinstance(kp, dict) else kp.source_id
                lines.append(f"• {claim}" + (f" [{src}]" if src else ""))
            if raw := (draft.get("raw_context", "") if isinstance(draft, dict) else ""):
                lines.append(f"Context: {raw[:300]}")
        except (json.JSONDecodeError, AttributeError):
            lines.append(str(draft_json)[:400])
        lines.append("")
    return "\n".join(lines)


def _extract_citations(response_text: str, available_source_ids: set[str]) -> tuple[str, list[str]]:
    """
    Extract the <!-- citations: [...] --> block from the response.
    Returns (cleaned_text, validated_source_ids).
    Only returns source_ids that were actually in the retrieved content.
    """
    match = _CITATION_PATTERN.search(response_text)
    if not match:
        clean = _INLINE_MARKER_PATTERN.sub("", response_text).strip()
        return clean, []
    try:
        raw_ids: list[str] = json.loads(match.group(1))
        validated = [sid for sid in raw_ids if sid in available_source_ids]
        clean_text = _INLINE_MARKER_PATTERN.sub("", response_text[: match.start()]).strip()
        return clean_text, validated
    except json.JSONDecodeError:
        return _INLINE_MARKER_PATTERN.sub("", response_text).strip(), []


async def synthesize(state) -> tuple[str, list[Citation]]:
    """
    Non-streaming synthesis for cases where streaming is not needed.
    Returns (final_text, citations).
    """
    client = get_synthesis_client()
    messages = _build_messages(state)
    raw = await client.complete(messages=messages, temperature=0.5, max_tokens=700)
    return _post_process(raw, state)


async def synthesize_stream(state) -> AsyncIterator[str]:
    """
    Stream raw model tokens internally. The router buffers them until safety
    post-processing completes, then emits only the validated response.
    """
    client = get_synthesis_client()
    messages = _build_messages(state)
    async for token in client.stream(messages=messages, temperature=0.5, max_tokens=700):
        yield token


def _build_messages(state) -> list[dict]:
    memory = state.get("user_memory")
    memory_context = memory.to_prompt_block() if memory else "(no user memory)"
    specialist_text = _format_specialist_drafts(state.get("specialist_drafts", {}))

    return [
        {"role": "system", "content": HAILEY_SYSTEM + "\n\n" + SYNTHESIZER_SYSTEM},
        {
            "role": "user",
            "content": SYNTHESIZER_USER_TEMPLATE.format(
                user_input=state["user_input"],
                specialist_drafts=specialist_text,
                memory_context=memory_context,
            ),
        },
    ]


def _post_process(raw: str, state) -> tuple[str, list[Citation]]:
    """Apply content filter and extract validated citations."""
    # Build source metadata and source-attributed claims from specialist drafts.
    valid_ids: set[str] = set()
    citation_by_id: dict[str, Citation] = {}
    source_claims: dict[str, list[str]] = {}
    for draft_json in state.get("specialist_drafts", {}).values():
        try:
            draft = json.loads(draft_json) if isinstance(draft_json, str) else draft_json
            for c in draft.get("citations", []):
                sid = c.get("source_id", "") if isinstance(c, dict) else getattr(c, "source_id", "")
                if sid and sid not in valid_ids:
                    valid_ids.add(sid)
                    citation_by_id[sid] = c if isinstance(c, Citation) else Citation.model_validate(c)
            for key_point in draft.get("key_points", []):
                sid = key_point.get("source_id", "") if isinstance(key_point, dict) else getattr(key_point, "source_id", "")
                claim = key_point.get("claim", "") if isinstance(key_point, dict) else getattr(key_point, "claim", "")
                if sid in valid_ids and claim:
                    source_claims.setdefault(sid, []).append(claim)
        except (json.JSONDecodeError, AttributeError):
            pass

    text, cited_ids = _extract_citations(raw, valid_ids)
    filtered_text, was_blocked, reason = filter_response(text)
    if was_blocked:
        logger.warning("unsafe_synthesis_blocked", reason=reason)
        cited_ids = []
        source_claims = {}

    validation = validate_citations(filtered_text, source_claims, citation_by_id, cited_ids)
    citations = validation.citations
    candidate_text = filtered_text
    medical_requested = "medical" in (state.get("requested_specialists") or [])
    risk_tier = medical_risk_tier(state.get("user_input", "")) if medical_requested else "none"
    if medical_requested and not was_blocked:
        if citations:
            # A failed citation must not erase the whole useful answer. Remove
            # unsupported numerical sentences, whose timelines/doses carry the
            # greatest harm, while retaining the supported response and citations.
            exposed_ids = {citation.source_id for citation in citations}
            attributed_claims = [
                claim for source_id, claims in source_claims.items()
                if source_id in exposed_ids for claim in claims
            ]
            sentences = []
            for sentence in _SENTENCE_SPLIT.split(filtered_text):
                if not _quantitative_sentence_is_attributed(sentence, attributed_claims):
                    continue
                if sentence.strip():
                    sentences.append(sentence.strip())
            filtered_text = " ".join(sentences) or filtered_text
        elif risk_tier == "low" and valid_ids:
            # Low-risk general-benefit answers may be shown with explicit
            # uncertainty when retrieval occurred but no claim-level citation
            # survived. High-risk and quantitative questions still abstain.
            filtered_text = (
                candidate_text.rstrip() +
                "\n\nI could not verify a passage closely enough to attach a source, "
                "so treat this as general information rather than medical advice."
            )
        else:
            filtered_text = (
                "I couldn't verify enough source-backed information to answer that safely. "
                "A doctor or pharmacist can give you guidance based on your circumstances."
            )
    trace = dict(state.get("trace") or {})
    trace["citation_validation"] = {
        "candidate_response": candidate_text,
        "source_claims": source_claims,
        "risk_tier": risk_tier,
        "declared_source_ids": cited_ids,
        "available_source_ids": sorted(valid_ids),
        "exposed_source_ids": [citation.source_id for citation in citations],
        "represented_claims": validation.represented_claims,
        "sourced_claims": validation.sourced_claims,
        "rejection_reasons": validation.rejection_reasons,
    }
    trace["final_citations"] = [citation.source_id for citation in citations]
    trace["safety_filter"] = {"blocked": was_blocked, "reason": reason}
    state["trace"] = trace
    logger.info(
        "citation_validation_complete",
        declared=len(cited_ids),
        exposed=len(citations),
        represented_claims=validation.represented_claims,
        sourced_claims=validation.sourced_claims,
    )

    return filtered_text, citations


def post_process_synthesis(raw: str, state) -> tuple[str, list[Citation]]:
    """Public post-processing entry point for router-driven streaming synthesis."""
    return _post_process(raw, state)
