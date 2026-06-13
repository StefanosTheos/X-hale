"""Unit tests for the Relapse-Risk Agent."""
from __future__ import annotations

import json
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.agents.relapse_risk import RelapseRiskAgent
from app.tools.behavioral_signals import BehavioralSignals


def _make_signals(*, relapse_flag=False, risk_score=0.1, missed_diary=2, milestone_rate=0.9):
    return BehavioralSignals(
        user_id="user_test_123",
        days_since_last_activity=0,
        missed_diary_days_last_14=missed_diary,
        milestone_completion_rate=milestone_rate,
        relapse_flag=relapse_flag,
        risk_score=risk_score,
    )


def _mock_llm(response_dict):
    client = AsyncMock()
    client.complete.return_value = json.dumps(response_dict)
    return client


@pytest.mark.asyncio
async def test_relapse_risk_low_risk(sample_state):
    """Low-risk signals should still return a valid SpecialistDraft."""
    signals = _make_signals(risk_score=0.1)
    llm_response = {
        "agent": "relapse_risk",
        "key_points": [{"claim": "You're doing great — keep up the diary habit.", "source_id": ""}],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [{"label": "View progress", "deeplink": "xhale://dashboard", "description": ""}],
        "raw_context": "Your engagement looks solid. Keep it up!",
    }
    with (
        patch("app.agents.relapse_risk.get_behavioral_signals", new=AsyncMock(return_value=signals)),
        patch("app.agents.relapse_risk.get_triage_client", return_value=_mock_llm(llm_response)),
    ):
        draft = await RelapseRiskAgent().run(sample_state)

    assert draft.agent == "relapse_risk"
    assert len(draft.key_points) == 1
    assert draft.tone_hint == "warm_supportive"
    assert len(draft.suggested_deeplinks) == 1


@pytest.mark.asyncio
async def test_relapse_risk_high_risk_with_relapse_flag(sample_state):
    """Relapse flag should trigger a non-judgmental acknowledgment as the first key point."""
    signals = _make_signals(relapse_flag=True, risk_score=0.8, missed_diary=10)
    llm_response = {
        "agent": "relapse_risk",
        "key_points": [
            {"claim": "Slipping up is part of the journey — it doesn't erase your progress.", "source_id": ""},
            {"claim": "Each quit attempt teaches you more about your triggers.", "source_id": ""},
        ],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [
            {"label": "Write in diary", "deeplink": "xhale://diary/new", "description": "Reflect on what happened"},
        ],
        "raw_context": "It takes courage to come back. You're not starting from zero.",
    }
    with (
        patch("app.agents.relapse_risk.get_behavioral_signals", new=AsyncMock(return_value=signals)),
        patch("app.agents.relapse_risk.get_triage_client", return_value=_mock_llm(llm_response)),
    ):
        draft = await RelapseRiskAgent().run(sample_state)

    assert draft.agent == "relapse_risk"
    assert len(draft.key_points) == 2
    assert len(draft.suggested_deeplinks) == 1
    assert draft.suggested_deeplinks[0].deeplink == "xhale://diary/new"


@pytest.mark.asyncio
async def test_relapse_risk_parse_failure_returns_fallback(sample_state):
    """JSON parse failure should return a safe fallback draft, not raise."""
    signals = _make_signals()
    client = AsyncMock()
    client.complete.return_value = "not valid json {{{"

    with (
        patch("app.agents.relapse_risk.get_behavioral_signals", new=AsyncMock(return_value=signals)),
        patch("app.agents.relapse_risk.get_triage_client", return_value=client),
    ):
        draft = await RelapseRiskAgent().run(sample_state)

    assert draft.agent == "relapse_risk"
    assert len(draft.key_points) == 1
    assert "setback" in draft.key_points[0].claim.lower()


@pytest.mark.asyncio
async def test_relapse_risk_passes_signals_to_llm(sample_state):
    """Behavioral signals snippet must be included in the LLM user message."""
    signals = _make_signals(missed_diary=9, risk_score=0.4)
    client = AsyncMock()
    client.complete.return_value = json.dumps({
        "agent": "relapse_risk",
        "key_points": [{"claim": "You've missed some diary entries.", "source_id": ""}],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [],
        "raw_context": "",
    })

    with (
        patch("app.agents.relapse_risk.get_behavioral_signals", new=AsyncMock(return_value=signals)),
        patch("app.agents.relapse_risk.get_triage_client", return_value=client),
    ):
        await RelapseRiskAgent().run(sample_state)

    call_args = client.complete.call_args
    user_message = call_args.kwargs["messages"][1]["content"]
    assert "Missed diary entries" in user_message
    assert "0.40" in user_message
