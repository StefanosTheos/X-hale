"""
HaileyState — the shared state TypedDict passed between all LangGraph nodes.

Every node reads from and writes to this dict. LangGraph merges state updates
automatically between nodes.
"""
from __future__ import annotations

from typing import Any, Optional, TypedDict

from app.models.retrieval import AppAction, Citation, SpecialistDraft
from app.models.user_facts import TriageResult, UserMemorySnapshot


class HaileyState(TypedDict, total=False):
    # ── Input (set at request start, never mutated) ─────────────────────────
    user_id: str
    user_input: str
    locale: str                            # "el" | "en" | ...

    # ── Context (loaded once per turn) ──────────────────────────────────────
    user_memory: Optional[UserMemorySnapshot]
    benchmark_memory_facts: list[dict[str, Any]]
    benchmark_context_override: bool
    benchmark_profile: dict[str, Any]

    # ── Triage ───────────────────────────────────────────────────────────────
    triage: Optional[TriageResult]

    # ── Specialist orchestration ─────────────────────────────────────────────
    requested_specialists: list[str]        # set by supervisor node
    specialist_drafts: dict[str, Any]       # agent_name → serialised SpecialistDraft dict

    # ── Output ────────────────────────────────────────────────────────────────
    final_response: str
    citations: list[Citation]
    deeplinks: list[AppAction]
    turn_id: str

    # ── Error handling ────────────────────────────────────────────────────────
    error: Optional[str]
    is_crisis: bool
    is_irrelevant: bool
    needs_clarification: bool

    # Benchmark/debug trace. Exposed only for the dedicated benchmark user.
    trace: dict[str, Any]
