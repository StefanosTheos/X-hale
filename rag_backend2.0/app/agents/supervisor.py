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

    # Supervisor overrides / additions based on memory signals
    if memory:
        # Check behavioral risk (if memory indicates concerning patterns)
        # Phase 3: relapse_risk agent will be wired in here
        pass

    # Ensure at least one specialist is invoked for relevant messages
    if not specialists and triage.topic_relevance == "relevant":
        # Default to emotional support for unclear cases
        if triage.emotion not in ("neutral", "calm", "joy", "hope"):
            specialists = ["emotional_support"]
        else:
            specialists = ["medical"]  # best-effort knowledge answer

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
