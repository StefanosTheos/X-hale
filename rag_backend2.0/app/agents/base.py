"""
AgentBase abstract class and SpecialistDraft re-export.
Every specialist agent extends AgentBase.
"""
from __future__ import annotations

from abc import ABC, abstractmethod

from app.models.retrieval import SpecialistDraft


class AgentBase(ABC):
    """
    Base class for all specialist agents.
    Subclasses implement `run(state) -> SpecialistDraft`.
    """

    @property
    @abstractmethod
    def name(self) -> str:
        """Machine name used as the key in HaileyState.specialist_drafts."""
        ...

    @abstractmethod
    async def run(self, state: "HaileyState") -> SpecialistDraft:  # type: ignore[name-defined]
        """Execute the agent and return a structured draft for the synthesizer."""
        ...
