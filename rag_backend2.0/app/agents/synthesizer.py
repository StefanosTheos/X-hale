"""
Synthesizer Agent — uses Groq llama-3.3-70b-versatile.

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
from app.safety.content_filter import filter_response

logger = get_logger(__name__)

_CITATION_PATTERN = re.compile(r"<!--\s*citations:\s*(\[.*?\])\s*-->", re.DOTALL)
_INLINE_MARKER_PATTERN = re.compile(r"\[[a-z][a-z0-9_]+\]")


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
    Streaming synthesis. Yields raw tokens as they arrive.
    The router extracts citations from the accumulated full text when done.
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
    # Build valid source_ids + deduplicated Citation objects from all specialist drafts
    valid_ids: set[str] = set()
    draft_citations: list[Citation] = []
    for draft_json in state.get("specialist_drafts", {}).values():
        try:
            draft = json.loads(draft_json) if isinstance(draft_json, str) else draft_json
            for c in draft.get("citations", []):
                sid = c.get("source_id", "") if isinstance(c, dict) else getattr(c, "source_id", "")
                stype = c.get("source_type", "unknown") if isinstance(c, dict) else getattr(c, "source_type", "unknown")
                if sid and sid not in valid_ids:
                    valid_ids.add(sid)
                    draft_citations.append(Citation(source_id=sid, source_type=stype))
        except (json.JSONDecodeError, AttributeError):
            pass

    text, cited_ids = _extract_citations(raw, valid_ids)
    filtered_text, _, _ = filter_response(text)

    if cited_ids:
        citations = [Citation(source_id=sid, source_type="unknown") for sid in cited_ids]
    else:
        # Model didn't emit the HTML comment block — fall back to all retrieved sources
        logger.debug("citations_fallback_to_drafts", count=len(draft_citations))
        citations = draft_citations

    return filtered_text, citations
