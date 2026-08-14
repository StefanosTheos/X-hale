"""
Post-generation content filter.

Runs on the synthesizer's output BEFORE it is streamed to the client.
Catches cases where the LLM may have:
  - Issued a medical prescription ("you should take X mg of...")
  - Attempted to diagnose a condition
  - Produced content that slipped past triage

Unsafe medical output is replaced rather than amended, so prohibited advice is
never delivered alongside a disclaimer. Returns (safe_content, blocked, reason).
"""
from __future__ import annotations

import re

_PRESCRIPTION_PATTERNS: list[re.Pattern] = [
    re.compile(r"\b(?:take|use|inject)\s+\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml)\b", re.IGNORECASE),
    re.compile(
        r"\byou should (?:take|use|apply|inject)\s+(?:this|the|a|an|your)?\s*"
        r"(?:medicine|medication|drug|tablet|pill|patch|injection|dose)\b",
        re.IGNORECASE,
    ),
    re.compile(r"\b(?:prescribed? dose|dosage of)\s+\d", re.IGNORECASE),
]

_DIAGNOSIS_PATTERNS: list[re.Pattern] = [
    re.compile(r"\byou (have|are experiencing|are suffering from) (a )?(medical )?condition\b", re.IGNORECASE),
    re.compile(r"\b(?:i diagnose you|you are diagnosed with)\b", re.IGNORECASE),
]

_SAFE_MEDICAL_FALLBACK = (
    "I can't safely provide a diagnosis or personalised medication instructions. "
    "A doctor or pharmacist can assess your situation and advise you on the right treatment. "
    "If your symptoms feel severe or urgent, please contact local emergency services now."
)


def filter_response(content: str) -> tuple[str, bool, str]:
    """
    Block generated medical prescriptions or diagnoses before client delivery.
    """
    for pattern in _PRESCRIPTION_PATTERNS:
        if pattern.search(content):
            return _SAFE_MEDICAL_FALLBACK, True, "prescription_language_detected"

    for pattern in _DIAGNOSIS_PATTERNS:
        if pattern.search(content):
            return _SAFE_MEDICAL_FALLBACK, True, "diagnosis_language_detected"

    return content, False, ""
