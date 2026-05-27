"""
Reflection / Journal Agent.

# ══════════════════════════════════════════════════════════════════
# PHASE 3 — NOT YET IMPLEMENTED
# Reads recent diary entries and surfaces patterns/themes/triggers.
# Activated when: user mentions diary, "looking back", "have I progressed".
# ══════════════════════════════════════════════════════════════════
"""
from __future__ import annotations

from app.agents.base import AgentBase
from app.models.retrieval import KeyPoint, SpecialistDraft
from app.observability.logging import get_logger

logger = get_logger(__name__)


class ReflectionAgent(AgentBase):
    name = "reflection"

    async def run(self, state) -> SpecialistDraft:  # type: ignore[override]
        """
        Phase 3 stub. Returns a placeholder draft.
        When implemented: reads diary entries via tools/diary_retrieval.py,
        summarises themes, flags recurring triggers.
        """
        logger.warning("reflection_agent_stub_invoked")
        return SpecialistDraft(
            agent=self.name,
            key_points=[
                KeyPoint(claim="[Phase 3 not yet implemented] Journal reflection coming soon.")
            ],
            tone_hint="warm_supportive",
            raw_context="",
        )
