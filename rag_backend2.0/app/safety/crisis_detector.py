"""
Layer 1 crisis detection: fast regex/keyword filter.

This runs SYNCHRONOUSLY before the triage LLM call (~0ms overhead).
If it fires, the crisis path is taken immediately without waiting for triage.

Layer 2 is the triage agent's crisis_flag field.

IMPORTANT: This list is NOT exhaustive and should not be the only safety mechanism.
It catches explicit, unambiguous signals only. The triage LLM handles nuanced cases.

Expand this list with the help of a clinical professional before public launch.
"""
from __future__ import annotations

import re

# High-specificity patterns for explicit ideation and credible indirect signals.
# Compound indirect patterns deliberately require more than a single generic
# distress word, reducing false activation for ordinary frustration or figures
# of speech such as "I'm dying for a cigarette".
_CRISIS_PATTERNS: list[re.Pattern] = [
    re.compile(r"\b(want to|going to|thinking (of|about))\s+(kill|end|harm)\s+(my)?self\b", re.IGNORECASE),
    re.compile(r"\b(suicid(al|e)|self.harm|self.injur)\b", re.IGNORECASE),
    re.compile(r"\bdon'?t want to (be alive|live|exist)\b", re.IGNORECASE),
    re.compile(r"\b(no reason to live|life (is|has) no (point|meaning))\b", re.IGNORECASE),
    re.compile(r"\bwish(ing)? i (was|were|could be) dead\b", re.IGNORECASE),
    re.compile(r"\b(overdose|od'?ing)\b", re.IGNORECASE),
    re.compile(r"\b(cut(ting)? (my)?self|slash(ing)? (my)?self)\b", re.IGNORECASE),
    # Passive death wishes and statements about no longer being present.
    re.compile(r"\bwoke up\b.{0,40}\bwish(?:ing|ed)?\s+i\s+hadn['’]?t\b", re.IGNORECASE),
    re.compile(r"\b(?:thoughts? about|thinking about)\s+(?:not being|no longer being)\s+(?:here|around)\b", re.IGNORECASE),
    # Hopelessness expressed through two mutually reinforcing signals.
    re.compile(r"\b(?:feel|feeling)\s+(?:completely\s+)?trapped\b.{0,80}\b(?:no|any)\s+way\s+out\b", re.IGNORECASE),
    re.compile(
        r"(?:\bmy\s+life\b.{0,50}|\blife\s+has\s+felt\b.{0,30})"
        r"\b(?:completely\s+)?meaningless\b",
        re.IGNORECASE,
    ),
    re.compile(r"\b(?:haven['’]?t|have not)\s+left\s+(?:my|the)\s+house\b.{0,100}\b(?:dark place|hopeless)\b", re.IGNORECASE),
    re.compile(r"\bdestroying\s+myself\b.{0,100}\bwhat['’]?s\s+the\s+point\b", re.IGNORECASE),
    # Preparatory behavior and statements naming a sole protective factor.
    re.compile(r"\b(?:written|wrote|writing)\s+(?:a\s+)?(?:letter|note)\s+to\s+(?:my\s+)?(?:family|loved ones)\b.{0,100}\b(?:just in case something happens|goodbye|final)\b", re.IGNORECASE),
    re.compile(r"\b(?:the\s+)?only\s+(?:thing|person|one)\b.{0,60}\bkeeping\s+me\s+(?:going|alive)\b", re.IGNORECASE),
    re.compile(r"\b(?:feel|feeling)\s+like\s+giving\s+up\s+on\s+(?:absolutely\s+)?everything\b", re.IGNORECASE),
]


def fast_crisis_check(text: str) -> bool:
    """
    Return True if any crisis pattern matches the input.
    This is Layer 1 — fast, synchronous, no LLM involved.
    """
    for pattern in _CRISIS_PATTERNS:
        if pattern.search(text):
            return True
    return False
