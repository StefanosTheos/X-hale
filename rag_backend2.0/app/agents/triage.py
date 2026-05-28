"""
Triage Agent — the first node in the LangGraph pipeline.

One LLM call at temperature=0 using the small fast model.
Returns a TriageResult JSON with 6 classification fields.
Falls back to safe defaults on any parse failure (and emits a metric).
"""
from __future__ import annotations

import json

from app.llm.client import get_triage_client
from app.models.user_facts import TriageResult
from app.observability.logging import get_logger
from app.observability.metrics import record_fallback, record_triage
from app.prompts.triage import TRIAGE_SYSTEM, TRIAGE_USER_TEMPLATE
from app.safety.crisis_detector import fast_crisis_check

logger = get_logger(__name__)

# Safe fallback used on JSON parse failures
_SAFE_DEFAULT = TriageResult(
    intent="general_conversation",
    emotion="neutral",
    topic_relevance="relevant",
    urgency="low",
    crisis_flag=False,
    requested_specialists=[],
)


async def run_triage(user_input: str) -> TriageResult:
    """
    Classify the user input. Always returns a TriageResult.
    Layer 1 fast crisis check runs before the LLM call.
    """
    # Layer 1: synchronous keyword check (~0ms)
    if fast_crisis_check(user_input):
        logger.info("crisis_detected_layer1")
        return TriageResult(
            intent="emotional_support",
            emotion="fear",
            topic_relevance="relevant",
            urgency="high",
            crisis_flag=True,
            requested_specialists=[],
        )

    client = get_triage_client()
    messages = [
        {"role": "system", "content": TRIAGE_SYSTEM},
        {"role": "user", "content": TRIAGE_USER_TEMPLATE.format(user_input=user_input)},
    ]
    try:
        raw = await client.complete(
            messages=messages,
            temperature=0.0,
            json_mode=True,
            max_tokens=512,
        )
        data = json.loads(_extract_json(raw))
        result = TriageResult(**data)
        record_triage(result.intent, result.emotion)
        return result
    except (json.JSONDecodeError, ValueError, TypeError) as exc:
        logger.warning("triage_parse_failed", error=str(exc))
        record_fallback()
        return _SAFE_DEFAULT


def _extract_json(raw: str) -> str:
    """Extract a JSON object from a response that may be wrapped in markdown fences."""
    raw = raw.strip()
    if not raw:
        return "{}"
    # Strip ```json ... ``` or ``` ... ``` fences
    if raw.startswith("```"):
        lines = raw.split("\n")
        lines = [l for l in lines if not l.startswith("```")]
        raw = "\n".join(lines).strip()
    # Find the first { ... } block in case there's surrounding text
    start = raw.find("{")
    end = raw.rfind("}")
    if start != -1 and end != -1 and end > start:
        return raw[start:end + 1]
    return raw
