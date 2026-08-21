from app.agents.supervisor import decide_specialists
from app.models.user_facts import TriageResult


def test_ambiguous_relevant_turn_never_defaults_to_medical():
    triage = TriageResult(
        intent="general_conversation", topic_relevance="relevant",
        emotion="neutral", requested_specialists=[],
    )
    assert decide_specialists(triage) == ["emotional_support"]
