"""
Pydantic models for the HTTP layer: request/response shapes for all API endpoints.
"""
from __future__ import annotations

from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Chat endpoint
# ---------------------------------------------------------------------------

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    locale: str = Field(default="en", max_length=10)  # e.g. "el", "en"


class SSEStatusEvent(BaseModel):
    """Intermediate SSE event sent during processing."""
    state: Literal["triaging", "loading_context", "searching_kb", "composing", "saving"]


class SSETokenEvent(BaseModel):
    """One token streamed from the synthesizer."""
    token: str


class SSEDoneEvent(BaseModel):
    """Final SSE event with citations and deeplinks."""
    citations: list[dict] = Field(default_factory=list)
    deeplinks: list[dict] = Field(default_factory=list)
    turn_id: str = ""


class SSEErrorEvent(BaseModel):
    code: str
    message: str


# ---------------------------------------------------------------------------
# History endpoint
# ---------------------------------------------------------------------------

class HistoryTurn(BaseModel):
    turn_id: str
    role: Literal["user", "assistant"]
    content: str
    timestamp: datetime
    citations: list[dict] = Field(default_factory=list)


class HistoryResponse(BaseModel):
    user_id: str
    turns: list[HistoryTurn]
    total: int


# ---------------------------------------------------------------------------
# Memory endpoint
# ---------------------------------------------------------------------------

class MemoryFactResponse(BaseModel):
    fact_id: str
    fact_type: str
    fact_key: str
    fact_value: str
    confidence: float
    first_observed: Optional[datetime] = None
    last_confirmed: Optional[datetime] = None


class MemoryResponse(BaseModel):
    user_id: str
    facts: list[MemoryFactResponse]
    total: int


# ---------------------------------------------------------------------------
# KB endpoint
# ---------------------------------------------------------------------------

class KBChunkResponse(BaseModel):
    content: str
    source_id: str
    source_type: str
    benefit_id: Optional[str] = None
    score: float = 0.0


class KBResponse(BaseModel):
    benefit_id: str
    chunks: list[KBChunkResponse]
