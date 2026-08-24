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

_MEDICATION = re.compile(
    r"\b(?:varenicline|champix|chantix|bupropion|zyban|cytisine|nicotine\s+"
    r"(?:replacement|patch(?:es)?|gum|lozenges?|sprays?|inhalers?)|nrt|"
    r"patch(?:es)?|nicotine gum|nicotine lozenges?)\b",
    re.IGNORECASE,
)
_CONTRAINDICATION_CONTEXT = re.compile(
    r"\b(?:pregnan\w*|breastfeed\w*|alcohol|interaction\w*|side effects?|"
    r"allerg\w*|heart condition|blood pressure|seizure\w*|other medications?|"
    r"combine|together|dose|dosage|step[- ]?down|still (?:smok\w*|having)|"
    r"months?|years?)\b",
    re.IGNORECASE,
)


def medical_risk_tier(query: str) -> str:
    if _HIGH_RISK.search(query):
        return "high"
    if _TIMELINE_OR_QUANTITY.search(query):
        return "medium"
    return "low"


def is_cessation_medication_query(query: str) -> bool:
    return bool(_MEDICATION.search(query))


def requires_professional_escalation(query: str) -> bool:
    """Identify medication decisions that require individual clinical advice."""
    return bool(_MEDICATION.search(query) and _CONTRAINDICATION_CONTEXT.search(query))


def professional_escalation_message(query: str) -> str | None:
    if not requires_professional_escalation(query):
        return None
    if re.search(r"\b(?:pregnan\w*|breastfeed\w*)\b", query, re.IGNORECASE):
        return (
            "Because pregnancy or breastfeeding changes the safety decision, "
            "check with a doctor, pharmacist, or midwife before starting or changing this treatment."
        )
    return (
        "Because the safest product, combination, and dose depend on your health, "
        "other medicines, and current symptoms, check with a doctor or pharmacist "
        "before starting, combining, changing, or stopping treatment."
    )
