"""
Pydantic models for retrieval results, citations, and specialist drafts.
These are the data contracts between the retrieval layer and the agent layer.
"""
from __future__ import annotations

from typing import Optional
from pydantic import BaseModel, Field


class Citation(BaseModel):
    source_id: str                   # e.g. "cdc_benefits_2024"
    source_type: str = "unknown"     # "government" | "peer_reviewed" | "charity" | "web"
    title: str = ""
    url: str = ""
    snippet: str = ""                # short excerpt for UI display
    benefit_id: Optional[str] = None # set when retrieved via /kb/{benefit_id}


class RetrievedChunk(BaseModel):
    content: str
    source_id: str
    source_type: str = "unknown"
    benefit_id: Optional[str] = None
    score: float = 0.0
    metadata: dict = Field(default_factory=dict)


class RetrievalResult(BaseModel):
    chunks: list[RetrievedChunk] = Field(default_factory=list)
    citations: list[Citation] = Field(default_factory=list)
    strategy_used: str = "vector"    # "vector" | "vector+graph" | "none"
    query: str = ""

    def format_for_prompt(self) -> str:
        """Return retrieved chunks as a structured text block for injection into prompts."""
        if not self.chunks:
            return "(No relevant knowledge base content found)"
        lines: list[str] = []
        for i, chunk in enumerate(self.chunks, 1):
            tag = f"[{chunk.source_type.upper()}:{chunk.source_id}]"
            lines.append(f"[{i}] {tag}\n{chunk.content[:400].strip()}")
        return "\n\n".join(lines)


class KeyPoint(BaseModel):
    claim: str
    source_id: str = ""             # must match a Citation.source_id if provided


class AppAction(BaseModel):
    label: str                       # e.g. "Try breathing exercise"
    deeplink: str                    # e.g. "xhale://breathing"
    description: str = ""


class SpecialistDraft(BaseModel):
    """
    Structured output returned by every specialist agent.
    The Synthesizer receives a dict of these and composes the final reply.
    Specialists return structured JSON, NOT free-form prose.
    """
    agent: str
    key_points: list[KeyPoint] = Field(default_factory=list)
    tone_hint: str = "warm_supportive"
    # tone options: "factual_reassuring" | "warm_supportive" | "motivational" |
    #               "reflective_listening" | "urge_surfing" | "gentle_redirect"
    suggested_deeplinks: list[AppAction] = Field(default_factory=list)
    raw_context: str = ""           # retrieved text the synthesizer may quote from
    citations: list[Citation] = Field(default_factory=list)
