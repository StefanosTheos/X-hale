"""Unit tests for the LangGraph routing functions."""
from __future__ import annotations

import pytest

from app.graph.routing import route_after_triage
from app.graph.state import HaileyState
from app.models.user_facts import TriageResult


def _make_state(triage: TriageResult) -> HaileyState:
    return HaileyState(
        user_id="u1",
        user_input="test",
        locale="en",
        triage=triage,
        specialist_drafts={},
        requested_specialists=[],
        citations=[],
        deeplinks=[],
        final_response="",
        turn_id="t1",
        is_crisis=False,
        is_irrelevant=False,
        needs_clarification=False,
        error=None,
        user_memory=None,
    )


def test_route_crisis():
    triage = TriageResult(crisis_flag=True, topic_relevance="relevant", intent="emotional_support",
                          emotion="fear", urgency="high")
    state = _make_state(triage)
    assert route_after_triage(state) == "crisis_handler_node"


def test_route_irrelevant():
    triage = TriageResult(topic_relevance="irrelevant", intent="off_topic", emotion="neutral",
                          urgency="low", crisis_flag=False)
    state = _make_state(triage)
    assert route_after_triage(state) == "irrelevant_node"


def test_route_clarification():
    triage = TriageResult(intent="needs_clarification", topic_relevance="relevant",
                          emotion="neutral", urgency="low", crisis_flag=False)
    state = _make_state(triage)
    assert route_after_triage(state) == "clarification_node"


def test_route_normal():
    triage = TriageResult(intent="medical_question", topic_relevance="relevant",
                          emotion="neutral", urgency="low", crisis_flag=False)
    state = _make_state(triage)
    assert route_after_triage(state) == "context_loader_node"
