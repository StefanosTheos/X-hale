"""
Relapse-Risk Agent.

# ══════════════════════════════════════════════════════════════════
# PHASE 3 — NOT YET IMPLEMENTED
# Reads behavioral signals from Appwrite and emits risk score + intervention suggestion.
# Activated passively by supervisor when risk signals are present.
# ══════════════════════════════════════════════════════════════════
"""
from __future__ import annotations

from app.agents.base import AgentBase
from app.models.retrieval import KeyPoint, SpecialistDraft
from app.observability.logging import get_logger

logger = get_logger(__name__)


class RelapseRiskAgent(AgentBase):
    name = "relapse_risk"

    async def run(self, state) -> SpecialistDraft:  # type: ignore[override]
        """
        Phase 3 stub. Returns a placeholder draft.
        When implemented: reads tools/behavioral_signals.py, computes risk score,
        returns tailored intervention suggestion.
        """
        logger.warning("relapse_risk_agent_stub_invoked")
        return SpecialistDraft(
            agent=self.name,
            key_points=[
                KeyPoint(claim="[Phase 3 not yet implemented] Relapse-risk analysis coming soon.")
            ],
            tone_hint="warm_supportive",
            raw_context="",
        )
