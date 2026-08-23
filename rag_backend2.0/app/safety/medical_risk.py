"""Deterministic medical-query risk tiers used by response grounding policy."""
from __future__ import annotations

import re

_HIGH_RISK = re.compile(
    r"\b(?:varenicline|bupropion|champix|zyban|nicotine (?:patch(?:es)?|gum|lozenges?|sprays?|inhalers?)|"
    r"nrt|dose|dosage|mg|pregnan\w*|breastfeed\w*|contraindication|interaction|overdose|"
    r"chest pain|coughing blood|cannot breathe|can't breathe)\b",
    re.IGNORECASE,
)
_TIMELINE_OR_QUANTITY = re.compile(
    r"\b(?:how long|how quickly|when|hours?|days?|weeks?|months?|years?|percent|risk)\b",
    re.IGNORECASE,
)


def medical_risk_tier(query: str) -> str:
    if _HIGH_RISK.search(query):
        return "high"
    if _TIMELINE_OR_QUANTITY.search(query):
        return "medium"
    return "low"
