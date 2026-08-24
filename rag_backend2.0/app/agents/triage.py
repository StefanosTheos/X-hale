"""
Triage Agent — the first node in the LangGraph pipeline.

One LLM call at temperature=0 using the small fast model.
Returns a TriageResult JSON with 6 classification fields.
Falls back to safe defaults on any parse failure (and emits a metric).
"""
from __future__ import annotations

import json
import re

from app.llm.client import get_triage_client
from app.llm.schemas import TRIAGE_SCHEMA
from app.models.user_facts import TriageResult
from app.observability.logging import get_logger
from app.observability.metrics import record_fallback, record_triage
from app.prompts.triage import TRIAGE_SYSTEM, TRIAGE_USER_TEMPLATE
from app.safety.crisis_detector import fast_crisis_check
from app.safety.medical_risk import is_cessation_medication_query

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


async def run_triage(user_input: str, memory=None) -> TriageResult:
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
    context = "(No relevant quit-journey context available)"
    if memory is not None:
        facts = memory.format_facts_for_prompt(limit=5)
        history = memory.format_history_for_prompt(limit=4)
        context = f"Known relevant facts:\n{facts}\nRecent conversation:\n{history}"
    messages = [
        {"role": "system", "content": TRIAGE_SYSTEM},
        {"role": "user", "content": TRIAGE_USER_TEMPLATE.format(
            user_input=user_input, context=context,
        )},
    ]
    try:
        raw = await client.complete(
            messages=messages,
            temperature=0.0,
            json_mode=True,
            response_schema=TRIAGE_SCHEMA,
            max_tokens=512,
        )
        data = json.loads(_extract_json(raw))
        result = TriageResult(**data)
        result = _apply_contextual_relevance_policy(user_input, result, memory)
        record_triage(result.intent, result.emotion)
        return result
    except (json.JSONDecodeError, ValueError, TypeError) as exc:
        logger.warning("triage_parse_failed", error=str(exc))
        record_fallback()
        return _SAFE_DEFAULT


_CESSATION_RE = re.compile(
    r"\b(smok|cigarette|nicotine|tobacco|quit|crav|withdraw|nrt|vape|patch|gum|"
    r"varenicline|champix|chantix|bupropion|zyban|cytisine)\w*\b",
    re.IGNORECASE,
)
_EMOTIONAL_DISCLOSURE_RE = re.compile(
    r"\b(feel|feeling|anxious|overwhelm|guilt|guilty|ashamed|lonely|sad|angry|"
    r"frustrated|irritable|struggling|nightmare of a day|proud)\b",
    re.IGNORECASE,
)


def _apply_contextual_relevance_policy(user_input: str, result: TriageResult, memory) -> TriageResult:
    """Deterministic policy layer around probabilistic relevance classification."""
    has_quit_language = bool(_CESSATION_RE.search(user_input))
    selected_facts = bool(memory and memory.top_facts)
    recent_quit_context = bool(
        memory and any(_CESSATION_RE.search(turn.content) for turn in memory.recent_turns[-2:])
    )

    # Cessation medications are always in scope. Medication use combined with
    # cravings still needs the medical agent even when the LLM selected only
    # craving support.
    if is_cessation_medication_query(user_input):
        specialists = list(result.requested_specialists)
        if "medical" not in specialists:
            specialists.append("medical")
        return TriageResult(
            intent="medical_question", emotion=result.emotion,
            topic_relevance="relevant", urgency=result.urgency,
            crisis_flag=result.crisis_flag, requested_specialists=specialists,
        )

    # Unrelated health queries are outside Hailey's role. A bare health question
    # cannot reach the medical agent without cessation language or selected
    # context tying it to the quit journey.
    if result.intent == "medical_question" and not has_quit_language and not recent_quit_context:
        return TriageResult(
            intent="off_topic", emotion=result.emotion, topic_relevance="irrelevant",
            urgency="low", crisis_flag=False, requested_specialists=[],
        )

    # Rescue ambiguous personal statements when compact context or emotional
    # disclosure makes them plausibly relevant.
    if result.topic_relevance == "irrelevant" and (
        selected_facts or _EMOTIONAL_DISCLOSURE_RE.search(user_input)
    ):
        emotional = bool(_EMOTIONAL_DISCLOSURE_RE.search(user_input))
        return TriageResult(
            intent="emotional_support" if emotional else "general_conversation",
            emotion=result.emotion, topic_relevance="relevant", urgency=result.urgency,
            crisis_flag=False,
            requested_specialists=["emotional_support"] if emotional else [],
        )
    return result


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
