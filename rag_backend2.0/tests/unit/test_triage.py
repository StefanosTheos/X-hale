"""Unit tests for the Triage Agent."""
from __future__ import annotations

import json
from unittest.mock import AsyncMock, patch

import pytest

from app.agents.triage import run_triage
from app.models.user_facts import TriageResult
from app.agents.triage import _apply_contextual_relevance_policy
from app.models.user_facts import UserFact, UserMemorySnapshot, UserProfile


@pytest.mark.asyncio
async def test_triage_medical_question():
    """Medical question should be classified as medical_question intent."""
    mock_response = json.dumps({
        "intent": "medical_question",
        "emotion": "neutral",
        "topic_relevance": "relevant",
        "urgency": "low",
        "crisis_flag": False,
        "requested_specialists": ["medical"],
    })
    with patch("app.agents.triage.get_triage_client") as mock_client_fn:
        mock_client = AsyncMock()
        mock_client.complete.return_value = mock_response
        mock_client_fn.return_value = mock_client
        result = await run_triage("How long until my lungs heal after quitting?")
    assert result.intent == "medical_question"
    assert result.crisis_flag is False
    assert "medical" in result.requested_specialists


@pytest.mark.asyncio
async def test_triage_crisis_layer1():
    """Layer 1 (keyword) crisis detection should fire before LLM call."""
    with patch("app.agents.triage.get_triage_client") as mock_client_fn:
        mock_client = AsyncMock()
        mock_client_fn.return_value = mock_client
        result = await run_triage("I don't want to be alive anymore")
    # Layer 1 should catch this before calling the LLM
    assert result.crisis_flag is True
    mock_client.complete.assert_not_called()


@pytest.mark.asyncio
async def test_triage_indirect_crisis_layer1():
    """High-specificity indirect risk signals bypass probabilistic triage."""
    with patch("app.agents.triage.get_triage_client") as mock_client_fn:
        mock_client = AsyncMock()
        mock_client_fn.return_value = mock_client
        result = await run_triage(
            "The only thing keeping me going right now is my dog, honestly"
        )

    assert result.crisis_flag is True
    assert result.urgency == "high"
    assert result.requested_specialists == []
    mock_client.complete.assert_not_called()


@pytest.mark.asyncio
async def test_triage_parse_failure_returns_safe_default():
    """JSON parse failure should return safe defaults, not raise."""
    with patch("app.agents.triage.get_triage_client") as mock_client_fn:
        mock_client = AsyncMock()
        mock_client.complete.return_value = "not valid json {{{"
        mock_client_fn.return_value = mock_client
        result = await run_triage("hello")
    assert isinstance(result, TriageResult)
    assert result.intent == "general_conversation"
    assert result.crisis_flag is False


@pytest.mark.asyncio
async def test_triage_irrelevant_topic():
    """Off-topic queries should be classified as irrelevant."""
    mock_response = json.dumps({
        "intent": "off_topic",
        "emotion": "neutral",
        "topic_relevance": "irrelevant",
        "urgency": "low",
        "crisis_flag": False,
        "requested_specialists": [],
    })
    with patch("app.agents.triage.get_triage_client") as mock_client_fn:
        mock_client = AsyncMock()
        mock_client.complete.return_value = mock_response
        mock_client_fn.return_value = mock_client
        result = await run_triage("What's a good pasta recipe?")
    assert result.topic_relevance == "irrelevant"


def test_unrelated_health_question_is_forced_off_topic_without_quit_context():
    result = TriageResult(
        intent="medical_question", topic_relevance="relevant",
        requested_specialists=["medical"],
    )
    corrected = _apply_contextual_relevance_policy(
        "What could this rash on my arm be?", result, None,
    )
    assert corrected.intent == "off_topic"
    assert corrected.requested_specialists == []


def test_selected_memory_rescues_ambiguous_personal_message():
    memory = UserMemorySnapshot(
        user_id="u1", profile=UserProfile(user_id="u1"),
        top_facts=[UserFact(
            user_id="u1", fact_type="trigger", fact_key="drinks_with_friends",
            fact_value="Drinks with smoking friends trigger cravings",
        )],
    )
    result = TriageResult(intent="off_topic", topic_relevance="irrelevant")
    corrected = _apply_contextual_relevance_policy(
        "Drinks with friends tonight", result, memory,
    )
    assert corrected.topic_relevance == "relevant"
    assert corrected.intent == "general_conversation"
