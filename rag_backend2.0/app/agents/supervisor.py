"""
Supervisor — decides which specialists to invoke and in what order.

Reads the TriageResult and UserMemorySnapshot, then updates
state["requested_specialists"] with the final list of specialist names.
The graph router reads this list to perform fan-out.
"""
from __future__ import annotations

from app.models.user_facts import TriageResult, UserMemorySnapshot, SpecialistName
from app.observability.logging import get_logger
from app.observability.metrics import record_specialist

logger = get_logger(__name__)


def decide_specialists(
    triage: TriageResult,
    memory: UserMemorySnapshot | None = None,
) -> list[SpecialistName]:
    """
    Pure decision logic (no LLM call needed — triage already classified intent).
    Returns an ordered list of specialist names to invoke.
    """
    specialists: list[SpecialistName] = []

    # Trust the triage classification as the primary signal
    if triage.requested_specialists:
        specialists = list(triage.requested_specialists)

    # Enforce the specialist implied by an explicit intent without replacing
    # any specialists selected for a mixed request.
    intent_specialist: dict[str, SpecialistName] = {
        "medical_question": "medical",
        "craving_support": "craving_support",
        "emotional_support": "emotional_support",
        "reflection": "reflection",
        "relapse_concern": "relapse_risk",
    }
    required = intent_specialist.get(triage.intent)
    if required and required not in specialists:
        specialists.append(required)

    # Behavioral signals are loaded inside RelapseRiskAgent when triage requests it;
    # they are intentionally not fetched here to avoid duplicate Appwrite reads.

    # Ensure at least one specialist is invoked for relevant messages. Never
    # default an ambiguous turn to medical: medical generation requires an
    # explicit medical classification and grounded retrieval.
    if not specialists and triage.topic_relevance == "relevant":
        # Emotional support remains the safe fallback only when no explicit
        # intent-to-specialist invariant applies.
        specialists = ["emotional_support"]

    # Deduplicate while preserving order
    seen: set[str] = set()
    unique: list[SpecialistName] = []
    for s in specialists:
        if s not in seen:
            seen.add(s)
            unique.append(s)

    for s in unique:
        record_specialist(s)

    logger.info("supervisor_decision", specialists=unique, intent=triage.intent)
    return unique
