import pytest

from app.agents.supervisor import decide_specialists
from app.models.user_facts import TriageResult


def test_ambiguous_relevant_turn_never_defaults_to_medical():
    triage = TriageResult(
        intent="general_conversation", topic_relevance="relevant",
        emotion="neutral", requested_specialists=[],
    )
    assert decide_specialists(triage) == ["emotional_support"]


def test_reflection_intent_always_invokes_reflection_agent():
    triage = TriageResult(
        intent="reflection", topic_relevance="relevant",
        emotion="neutral", requested_specialists=[],
    )
    assert decide_specialists(triage) == ["reflection"]


def test_reflection_is_additive_for_mixed_specialist_request():
    triage = TriageResult(
        intent="reflection", topic_relevance="relevant",
        emotion="neutral", requested_specialists=["medical"],
    )
    assert decide_specialists(triage) == ["medical", "reflection"]


@pytest.mark.parametrize(
    ("intent", "expected"),
    [
        ("medical_question", ["medical"]),
        ("craving_support", ["craving_support"]),
        ("emotional_support", ["emotional_support"]),
        ("relapse_concern", ["relapse_risk"]),
    ],
)
def test_existing_explicit_intents_keep_their_specialist(intent, expected):
    triage = TriageResult(
        intent=intent, topic_relevance="relevant",
        emotion="neutral", requested_specialists=[],
    )
    assert decide_specialists(triage) == expected
