"""
Post-generation content filter.

Runs on the synthesizer's output BEFORE it is streamed to the client.
Catches cases where the LLM may have:
  - Issued a medical prescription ("you should take X mg of...")
  - Attempted to diagnose a condition
  - Produced content that slipped past triage

Returns (filtered_content, was_filtered, reason).
The original content is returned unchanged if no filter fires.
"""
from __future__ import annotations

import re

_PRESCRIPTION_PATTERNS: list[re.Pattern] = [
    re.compile(r"\b(take|prescribed?|dosage of|mg of|pill(s)?)\b", re.IGNORECASE),
    re.compile(r"\byou should (take|use|apply|inject)\b", re.IGNORECASE),
]

_DIAGNOSIS_PATTERNS: list[re.Pattern] = [
    re.compile(r"\byou (have|are experiencing|are suffering from) (a )?(medical )?condition\b", re.IGNORECASE),
    re.compile(r"\bdiagnos(is|ed with)\b", re.IGNORECASE),
]

_DISCLAIMER = (
    "\n\n*Please consult a healthcare professional for personalised medical advice.*"
)


def filter_response(content: str) -> tuple[str, bool, str]:
    """
    Check the generated content for medical prescriptions or diagnoses.
    Returns (content, was_filtered, reason).
    """
    for pattern in _PRESCRIPTION_PATTERNS:
        if pattern.search(content):
            return content + _DISCLAIMER, True, "prescription_language_detected"

    for pattern in _DIAGNOSIS_PATTERNS:
        if pattern.search(content):
            return content + _DISCLAIMER, True, "diagnosis_language_detected"

    return content, False, ""
