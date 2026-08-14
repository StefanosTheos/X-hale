"""Unit tests for conservative Appwrite-backed behavioral signals."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, patch

import pytest

from app.models.user_facts import ConversationTurn, UserFact, UserProfile
from app.tools.behavioral_signals import get_behavioral_signals
from app.tools.diary_retrieval import DiaryEntry


@pytest.mark.asyncio
async def test_signals_use_latest_real_activity_and_stored_relapse():
    now = datetime(2026, 8, 14, 12, tzinfo=timezone.utc)
    profile = UserProfile(
        user_id="u1",
        days_quit=28,
        num_milestones_completed=2,
        num_diary_entries=5,
        record_updated_at=now - timedelta(days=6),
    )
    diary = [DiaryEntry("d1", "entry", "neutral", [], now - timedelta(days=4))]
    turns = [ConversationTurn(
        turn_id="t1", user_id="u1", role="user", content="hello",
        timestamp=now - timedelta(days=2),
    )]
    facts = [UserFact(
        user_id="u1", fact_type="past_attempt_history", fact_key="latest_relapse",
        fact_value=(now - timedelta(days=1)).isoformat(), confidence=1.0,
    )]

    with (
        patch("app.tools.behavioral_signals.get_user_profile", new=AsyncMock(return_value=profile)),
        patch("app.tools.behavioral_signals.get_recent_diary_entries", new=AsyncMock(return_value=diary)),
        patch("app.tools.behavioral_signals.get_recent_turns", new=AsyncMock(return_value=turns)),
        patch("app.tools.behavioral_signals.get_facts", new=AsyncMock(return_value=facts)),
    ):
        signals = await get_behavioral_signals("u1", now=now)

    assert signals.days_since_last_activity == 2
    assert signals.relapse_flag is True
    assert signals.relapse_recorded_at == now - timedelta(days=1)
    assert signals.risk_score == pytest.approx(0.8)


@pytest.mark.asyncio
async def test_unknown_data_does_not_create_false_risk():
    failure = RuntimeError("Appwrite unavailable")
    with (
        patch("app.tools.behavioral_signals.get_user_profile", new=AsyncMock(side_effect=failure)),
        patch("app.tools.behavioral_signals.get_recent_diary_entries", new=AsyncMock(side_effect=failure)),
        patch("app.tools.behavioral_signals.get_recent_turns", new=AsyncMock(side_effect=failure)),
        patch("app.tools.behavioral_signals.get_facts", new=AsyncMock(side_effect=failure)),
    ):
        signals = await get_behavioral_signals("u1")

    assert signals.days_since_last_activity is None
    assert signals.missed_diary_days_last_14 is None
    assert signals.milestone_completion_rate is None
    assert signals.relapse_flag is False
    assert signals.risk_score == 0.0
    assert "unknown" in signals.to_prompt_snippet()


@pytest.mark.asyncio
async def test_explicit_current_report_sets_relapse_without_stored_fact():
    profile = UserProfile(user_id="u1")
    with (
        patch("app.tools.behavioral_signals.get_user_profile", new=AsyncMock(return_value=profile)),
        patch("app.tools.behavioral_signals.get_recent_diary_entries", new=AsyncMock(return_value=[])),
        patch("app.tools.behavioral_signals.get_recent_turns", new=AsyncMock(return_value=[])),
        patch("app.tools.behavioral_signals.get_facts", new=AsyncMock(return_value=[])),
    ):
        signals = await get_behavioral_signals("u1", explicit_relapse_report=True)

    assert signals.relapse_flag is True
    assert signals.risk_score == pytest.approx(0.7)
