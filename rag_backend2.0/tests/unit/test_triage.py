"""Unit tests for the Triage Agent."""
from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest
import yaml

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
@pytest.mark.parametrize("message", [
    "I'm thinking about taking all my medication at once",
    "I want to swallow all my pills",
    "I might take the whole bottle of medicine",
])
async def test_medication_overdose_intent_fires_crisis_layer1(message):
    with patch("app.agents.triage.get_triage_client") as mock_client_fn:
        result = await run_triage(message)

    assert result.crisis_flag is True
    assert result.urgency == "high"
    mock_client_fn.assert_not_called()


@pytest.mark.asyncio
@pytest.mark.parametrize("message", [
    "I forgot whether I took my medication this morning",
    "Should I take all my medication with food?",
])
async def test_medication_near_negatives_do_not_fire_layer1(message):
    normal = json.dumps({
        "intent": "off_topic", "emotion": "neutral",
        "topic_relevance": "irrelevant", "urgency": "low",
        "crisis_flag": False, "requested_specialists": [],
    })
    with patch("app.agents.triage.get_triage_client") as mock_client_fn:
        mock_client = AsyncMock()
        mock_client.complete.return_value = normal
        mock_client_fn.return_value = mock_client
        result = await run_triage(message)

    assert result.crisis_flag is False


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


def test_champix_interaction_is_forced_to_medical_route():
    result = TriageResult(
        intent="medical_question", topic_relevance="relevant",
        requested_specialists=["medical"],
    )
    corrected = _apply_contextual_relevance_policy(
        "Can I drink alcohol while taking Champix or Chantix?", result, None,
    )
    assert corrected.intent == "medical_question"
    assert corrected.topic_relevance == "relevant"
    assert "medical" in corrected.requested_specialists


def test_patch_with_persistent_cravings_adds_medical_specialist():
    result = TriageResult(
        intent="craving_support", topic_relevance="relevant", urgency="high",
        requested_specialists=["craving_support"],
    )
    corrected = _apply_contextual_relevance_policy(
        "I've been on patches for 3 weeks and still having intense cravings — what should I do?",
        result,
        None,
    )
    assert corrected.intent == "medical_question"
    assert corrected.requested_specialists == ["craving_support", "medical"]


def _benchmark_inputs(category: str) -> list[str]:
    categories = Path(__file__).parents[3] / "finetune" / "eval" / "categories.yaml"
    raw = yaml.safe_load(categories.read_text(encoding="utf-8"))
    return [case["input"] for case in raw["categories"][category]["cases"]]


@pytest.mark.parametrize("user_input", _benchmark_inputs("off_topic"))
def test_all_benchmark_off_topic_inputs_override_incorrect_specialist_route(user_input):
    wrong = TriageResult(
        intent="craving_support", topic_relevance="relevant",
        urgency="medium", requested_specialists=["craving_support"],
    )

    corrected = _apply_contextual_relevance_policy(user_input, wrong, None)

    assert corrected.intent == "off_topic"
    assert corrected.topic_relevance == "irrelevant"
    assert corrected.crisis_flag is False
    assert corrected.requested_specialists == []


@pytest.mark.parametrize("user_input", _benchmark_inputs("reflection"))
def test_all_benchmark_reflection_inputs_add_reflection_without_dropping_agent(user_input):
    existing = TriageResult(
        intent="medical_question", topic_relevance="relevant",
        requested_specialists=["medical"],
    )

    corrected = _apply_contextual_relevance_policy(user_input, existing, None)

    assert corrected.topic_relevance == "relevant"
    assert {"medical", "reflection"}.issubset(set(corrected.requested_specialists))


@pytest.mark.asyncio
async def test_literary_hopelessness_is_not_treated_as_personal_crisis():
    mock_response = json.dumps({
        "intent": "emotional_support", "emotion": "sadness",
        "topic_relevance": "relevant", "urgency": "high",
        "crisis_flag": True, "requested_specialists": [],
    })
    with patch("app.agents.triage.get_triage_client") as mock_client_fn:
        mock_client = AsyncMock()
        mock_client.complete.return_value = mock_response
        mock_client_fn.return_value = mock_client
        result = await run_triage("The book I'm reading argues that life is meaningless")

    assert result.intent == "off_topic"
    assert result.crisis_flag is False


def test_unrelated_memory_does_not_rescue_clear_off_topic_request():
    memory = UserMemorySnapshot(
        user_id="u1", profile=UserProfile(user_id="u1"),
        top_facts=[UserFact(
            user_id="u1", fact_type="trigger", fact_key="coffee",
            fact_value="Coffee is a smoking trigger",
        )],
    )
    wrong = TriageResult(intent="off_topic", topic_relevance="irrelevant")

    corrected = _apply_contextual_relevance_policy(
        "Who won the Champions League this year?", wrong, memory,
    )

    assert corrected.intent == "off_topic"
    assert corrected.topic_relevance == "irrelevant"


@pytest.mark.parametrize(("message", "initial", "required"), [
    (
        "I've been really anxious and on edge since I quit — is this normal?",
        ["medical"], {"medical", "emotional_support"},
    ),
    (
        "I feel constantly jittery and restless since I quit, like I can't settle",
        ["craving_support"], {"craving_support", "emotional_support"},
    ),
    (
        "I feel like no matter how hard I try I always end up smoking again",
        ["relapse_risk"], {"relapse_risk", "emotional_support"},
    ),
    (
        "Smoking is destroying my lungs, so I want to stop",
        ["medical"], {"medical", "craving_support"},
    ),
    (
        "I'm using patches but still having awful cravings — is the NRT even doing anything?",
        ["craving_support"], {"craving_support", "medical", "emotional_support"},
    ),
])
def test_mixed_intents_add_required_specialists_without_dropping_existing(
    message, initial, required,
):
    original = TriageResult(
        intent="general_conversation", topic_relevance="relevant",
        requested_specialists=initial,
    )
    corrected = _apply_contextual_relevance_policy(message, original, None)

    assert required.issubset(set(corrected.requested_specialists))
    assert set(initial).issubset(set(corrected.requested_specialists))


def test_quit_date_recall_routes_to_reflection_instead_of_medical_only():
    wrong = TriageResult(
        intent="medical_question", topic_relevance="relevant",
        requested_specialists=["medical"],
    )
    corrected = _apply_contextual_relevance_policy(
        "When exactly did I quit? I can't remember my exact start date", wrong, None,
    )

    assert "reflection" in corrected.requested_specialists
    assert "medical" not in corrected.requested_specialists


@pytest.mark.parametrize(("message", "specialist"), [
    ("How has my health been improving since I quit?", "medical"),
    ("Do you notice a pattern in when my cravings tend to be worst?", "craving_support"),
    ("What do you think caused my last slip or big craving?", "relapse_risk"),
    ("Has my mood gotten better since I quit, or has it been more up and down?", "emotional_support"),
])
def test_mixed_reflection_questions_add_only_the_relevant_specialist(message, specialist):
    initial = TriageResult(
        intent="reflection", topic_relevance="relevant", requested_specialists=[],
    )

    corrected = _apply_contextual_relevance_policy(message, initial, None)

    assert "reflection" in corrected.requested_specialists
    assert specialist in corrected.requested_specialists
