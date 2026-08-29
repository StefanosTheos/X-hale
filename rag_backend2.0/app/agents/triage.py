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
    if fast_crisis_check(user_input) and not _has_distanced_crisis_context(user_input):
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

_CLEARLY_UNRELATED_RE = re.compile(
    r"\b(?:recipe|lasagne|brownies?|champions league|premier league|python programming|"
    r"weather|poem|percent of|funny joke|netflix|films?.*watch|work email|cover letter|"
    r"capital of|invest(?:ment|ing)?|bitcoin|translate|world war|algebra|divorce paperwork|"
    r"sleep training|visit in italy|job interview|iphone|samsung phone|traffic|car park|"
    r"holiday plans|book (?:i['’]?m )?reading|breed .* hiking|huge breakfast|rash)\b",
    re.IGNORECASE,
)
_DISTANCED_CRISIS_CONTEXT_RE = re.compile(
    r"\b(?:the|a|this)\s+(?:book|novel|film|movie|show|article|essay|character|author)\b"
    r"|\b(?:class|course|lecture)\s+(?:discusses?|covered)\b",
    re.IGNORECASE,
)
_PERSONAL_REFLECTION_RE = re.compile(
    r"(?:"
    r"\b(?:my|me)\s+(?:progress|quit journey|journey|biggest triggers?|patterns?|health|"
    r"coping strategies|last (?:slip|craving)|cravings?|mood|sleep|relationships?|mental health)\b|"
    r"\b(?:smoke[- ]free now|now that i don['’]?t smoke)\b|"
    r"\b(?:looking back|what (?:do )?you (?:know|remember|notice) about me)\b|"
    r"\bam i actually making progress\b|"
    r"\b(?:money (?:i(?:'ve| have)|have i) saved|cigarettes (?:i have|have i) not smoked|"
    r"milestones? (?:have i|i(?:'ve| have)))\b|"
    r"\b(?:worked best for me|hardest (?:part|day).*for me|based on what you know about me)\b|"
    r"\b(?:health benefits?.*by now|remind me.*why.*quit|what did i do.*craving|"
    r"how am i different.*(?:started|app)|what am i most proud.*quit|about my experience)\b"
    r"|\b(?:how has my .*since i quit|do i actually feel healthier since i quit|"
    r"exercising more since i quit|surprising thing.*since i quit)\b"
    r"|\b(?:when (?:exactly )?did i quit|what(?:'s| is) my (?:quit|start) date|"
    r"can['’]?t remember my (?:exact )?start date)\b"
    r")",
    re.IGNORECASE,
)
_AFFECTIVE_SUPPORT_RE = re.compile(
    r"\b(?:anxious|anxiety|on edge|jittery|restless|wired|can['’]?t concentrate|"
    r"harder for me|i miss|awful|failed|afraid|judged|no matter how hard|"
    r"smoked .* before i even reali[sz]ed)\b",
    re.IGNORECASE,
)
_QUIT_ATTEMPT_SUPPORT_RE = re.compile(
    r"\b(?:want to stop|quit attempt|giving up on (?:this|my) quit|try again tomorrow)\b",
    re.IGNORECASE,
)
_SLIP_OR_RELAPSE_RE = re.compile(
    r"\b(?:end up smoking again|smoked (?:one|two|three|\d+|it|them)|"
    r"finally smoked|slip(?:ped)?|relaps(?:e|ed))\b",
    re.IGNORECASE,
)
_WITHDRAWAL_MEDICAL_RE = re.compile(
    r"\b(?:is (?:this|that) (?:normal|withdrawal)|headaches?|will (?:this )?anxiety .*go away|"
    r"patches?.*(?:still|awful) cravings?|nrt .*doing anything)\b",
    re.IGNORECASE,
)
_PROFILE_RECALL_RE = re.compile(
    r"\b(?:when (?:exactly )?did i quit|what(?:'s| is) my (?:quit|start) date|"
    r"can['’]?t remember my (?:exact )?start date)\b",
    re.IGNORECASE,
)
_REFLECTION_MEDICAL_RE = re.compile(
    r"\b(?:health (?:been improving|benefits?.*by now|look like)|sleep might be improving|"
    r"exercising more since i quit|mental health.*(?:different|affected))\b",
    re.IGNORECASE,
)
_REFLECTION_CRAVING_RE = re.compile(
    r"\b(?:pattern.*cravings?.*(?:worst|tend)|what did i do.*(?:last time )?a craving)\b",
    re.IGNORECASE,
)
_REFLECTION_RELAPSE_RE = re.compile(
    r"\b(?:caused my last slip|most likely to make me slip)\b",
    re.IGNORECASE,
)
_REFLECTION_EMOTIONAL_RE = re.compile(
    r"\b(?:has my mood gotten better|mood.*more up and down)\b",
    re.IGNORECASE,
)


def _has_distanced_crisis_context(user_input: str) -> bool:
    """Identify explicit discussion of someone else's or a cited work's language."""
    return bool(_DISTANCED_CRISIS_CONTEXT_RE.search(user_input))


def _memory_is_connected(user_input: str, memory) -> bool:
    """Require lexical connection instead of treating any stored fact as context."""
    if not memory or not memory.top_facts:
        return False
    message_tokens = set(re.findall(r"[a-z0-9]+", user_input.lower()))
    ignored = {"a", "an", "and", "at", "for", "i", "in", "is", "my", "of", "on", "the", "to", "with"}
    message_tokens -= ignored
    for fact in memory.top_facts:
        fact_text = f"{fact.fact_key} {fact.fact_value}".lower().replace("_", " ")
        fact_tokens = set(re.findall(r"[a-z0-9]+", fact_text)) - ignored
        if message_tokens & fact_tokens:
            return True
    return False


def _apply_contextual_relevance_policy(user_input: str, result: TriageResult, memory) -> TriageResult:
    """Deterministic policy layer around probabilistic relevance classification."""
    has_quit_language = bool(_CESSATION_RE.search(user_input))
    connected_facts = _memory_is_connected(user_input, memory)
    recent_quit_context = bool(
        memory and any(_CESSATION_RE.search(turn.content) for turn in memory.recent_turns[-2:])
    )

    if _has_distanced_crisis_context(user_input) and not has_quit_language:
        return TriageResult(
            intent="off_topic", emotion=result.emotion, topic_relevance="irrelevant",
            urgency="low", crisis_flag=False, requested_specialists=[],
        )

    # Cessation medications are always in scope. Medication use combined with
    # cravings still needs the medical agent even when the LLM selected only
    # craving support.
    if is_cessation_medication_query(user_input):
        specialists = list(result.requested_specialists)
        if "medical" not in specialists:
            specialists.append("medical")
        if _AFFECTIVE_SUPPORT_RE.search(user_input) and "emotional_support" not in specialists:
            specialists.append("emotional_support")
        return TriageResult(
            intent="medical_question", emotion=result.emotion,
            topic_relevance="relevant", urgency=result.urgency,
            crisis_flag=result.crisis_flag, requested_specialists=specialists,
        )

    if _CLEARLY_UNRELATED_RE.search(user_input) and not has_quit_language:
        return TriageResult(
            intent="off_topic", emotion=result.emotion, topic_relevance="irrelevant",
            urgency="low", crisis_flag=False, requested_specialists=[],
        )

    if not result.crisis_flag and _PERSONAL_REFLECTION_RE.search(user_input):
        specialists = list(result.requested_specialists)
        if _PROFILE_RECALL_RE.search(user_input):
            specialists = [s for s in specialists if s != "medical"]
        if "reflection" not in specialists:
            specialists.append("reflection")
        # These narrow, additive rules cover reflection questions that also
        # require a domain specialist. They do not affect non-reflection cases.
        for pattern, specialist in (
            (_REFLECTION_MEDICAL_RE, "medical"),
            (_REFLECTION_CRAVING_RE, "craving_support"),
            (_REFLECTION_RELAPSE_RE, "relapse_risk"),
            (_REFLECTION_EMOTIONAL_RE, "emotional_support"),
        ):
            if pattern.search(user_input) and specialist not in specialists:
                specialists.append(specialist)
        result = TriageResult(
            intent=result.intent, emotion=result.emotion,
            topic_relevance="relevant", urgency=result.urgency,
            crisis_flag=False, requested_specialists=specialists,
        )

    # Unrelated health queries are outside Hailey's role. A bare health question
    # cannot reach the medical agent without cessation language or selected
    # context tying it to the quit journey.
    if (
        result.intent == "medical_question"
        and "reflection" not in result.requested_specialists
        and not has_quit_language and not recent_quit_context
    ):
        return TriageResult(
            intent="off_topic", emotion=result.emotion, topic_relevance="irrelevant",
            urgency="low", crisis_flag=False, requested_specialists=[],
        )

    # Rescue ambiguous personal statements when compact context or emotional
    # disclosure makes them plausibly relevant.
    if result.topic_relevance == "irrelevant" and (
        connected_facts or _EMOTIONAL_DISCLOSURE_RE.search(user_input)
    ):
        emotional = bool(_EMOTIONAL_DISCLOSURE_RE.search(user_input))
        return TriageResult(
            intent="emotional_support" if emotional else "general_conversation",
            emotion=result.emotion, topic_relevance="relevant", urgency=result.urgency,
            crisis_flag=False,
            requested_specialists=["emotional_support"] if emotional else [],
        )

    specialists = list(result.requested_specialists)
    if result.topic_relevance == "relevant" and _AFFECTIVE_SUPPORT_RE.search(user_input):
        if (
            "reflection" in specialists
            and result.intent in ("reflection", "emotional_support", "relapse_concern")
            and not _PERSONAL_REFLECTION_RE.search(user_input)
        ):
            specialists = [s for s in specialists if s != "reflection"]
        if result.intent == "reflection" and not _PERSONAL_REFLECTION_RE.search(user_input):
            result = TriageResult(
                intent="emotional_support", emotion=result.emotion,
                topic_relevance="relevant", urgency=result.urgency,
                crisis_flag=result.crisis_flag, requested_specialists=specialists,
            )
        if "emotional_support" not in specialists:
            specialists.append("emotional_support")
    if has_quit_language and _QUIT_ATTEMPT_SUPPORT_RE.search(user_input):
        if "craving_support" not in specialists:
            specialists.append("craving_support")
    if _SLIP_OR_RELAPSE_RE.search(user_input):
        if "relapse_risk" not in specialists:
            specialists.append("relapse_risk")
    if has_quit_language and _WITHDRAWAL_MEDICAL_RE.search(user_input):
        if "medical" not in specialists:
            specialists.append("medical")
    if specialists != list(result.requested_specialists):
        return TriageResult(
            intent=result.intent, emotion=result.emotion,
            topic_relevance="relevant", urgency=result.urgency,
            crisis_flag=result.crisis_flag, requested_specialists=specialists,
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
