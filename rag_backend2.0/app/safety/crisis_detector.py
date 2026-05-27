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

# Patterns that unambiguously indicate crisis / self-harm ideation.
# Kept broad enough to catch paraphrases but specific enough to avoid
# false positives on cessation-adjacent distress ("I want to die for a cigarette").
_CRISIS_PATTERNS: list[re.Pattern] = [
    re.compile(r"\b(want to|going to|thinking (of|about))\s+(kill|end|harm)\s+(my)?self\b", re.IGNORECASE),
    re.compile(r"\b(suicid(al|e)|self.harm|self.injur)\b", re.IGNORECASE),
    re.compile(r"\bdon'?t want to (be alive|live|exist)\b", re.IGNORECASE),
    re.compile(r"\b(no reason to live|life (is|has) no (point|meaning))\b", re.IGNORECASE),
    re.compile(r"\bwish(ing)? i (was|were|could be) dead\b", re.IGNORECASE),
    re.compile(r"\b(overdose|od'?ing)\b", re.IGNORECASE),
    re.compile(r"\b(cut(ting)? (my)?self|slash(ing)? (my)?self)\b", re.IGNORECASE),
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
