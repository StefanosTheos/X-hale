"""Unit tests for the Reflection Agent."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest

from app.agents.reflection import ReflectionAgent, _format_entries
from app.tools.diary_retrieval import DiaryEntry


def _entry(content: str, mood: str = "neutral", tags: list[str] | None = None, days_ago: int = 1) -> DiaryEntry:
    from datetime import timedelta
    ts = datetime.now(timezone.utc) - timedelta(days=days_ago)
    return DiaryEntry(
        entry_id=f"entry_{days_ago}",
        content=content,
        mood=mood,
        tags=tags or [],
        created_at=ts,
    )


def _mock_llm(response_dict):
    client = AsyncMock()
    client.complete.return_value = json.dumps(response_dict)
    return client


# ── _format_entries unit tests ────────────────────────────────────────────────

def test_format_entries_empty():
    assert _format_entries([]) == "(No diary entries in this period)"


def test_format_entries_includes_content_snippet():
    entries = [_entry("I had a tough morning but got through it without smoking.", mood="anxious", tags=["morning", "coffee"])]
    result = _format_entries(entries)
    assert "tough morning" in result
    assert "mood: anxious" in result
    assert "coffee" in result


def test_format_entries_truncates_long_content():
    long_content = "a" * 300
    result = _format_entries([_entry(long_content)])
    assert "…" in result
    assert len(result) < 400


def test_format_entries_caps_at_15():
    entries = [_entry(f"entry {i}", days_ago=i) for i in range(1, 25)]
    result = _format_entries(entries)
    assert result.count("•") == 15


# ── Agent integration tests ───────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_reflection_with_diary_entries(sample_state):
    """Normal flow with diary entries should return a valid SpecialistDraft."""
    entries = [
        _entry("Struggled with coffee cravings again.", mood="anxious", tags=["coffee", "morning"], days_ago=1),
        _entry("Good day, went for a walk instead.", mood="calm", tags=["exercise"], days_ago=3),
    ]
    llm_response = {
        "agent": "reflection",
        "key_points": [
            {"claim": "Coffee appears as a trigger in 1 of 2 recent entries.", "source_id": ""},
            {"claim": "You substituted exercise for a craving once this week.", "source_id": ""},
        ],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [
            {"label": "Write in diary", "deeplink": "xhale://diary/new", "description": "Keep the streak going"},
        ],
        "raw_context": "You've been noticing patterns — that's a real skill.",
    }
    with (
        patch("app.agents.reflection.get_recent_diary_entries", new=AsyncMock(return_value=entries)),
        patch("app.agents.reflection.get_triage_client", return_value=_mock_llm(llm_response)),
    ):
        draft = await ReflectionAgent().run(sample_state)

    assert draft.agent == "reflection"
    assert len(draft.key_points) == 2
    assert draft.tone_hint == "warm_supportive"
    assert draft.raw_context != ""
    assert len(draft.suggested_deeplinks) == 1


@pytest.mark.asyncio
async def test_reflection_empty_diary(sample_state):
    """No diary entries should still produce a valid draft."""
    llm_response = {
        "agent": "reflection",
        "key_points": [
            {"claim": "You haven't written in your diary recently — starting can help surface patterns.", "source_id": ""},
        ],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [
            {"label": "Write in diary", "deeplink": "xhale://diary/new", "description": ""},
        ],
        "raw_context": "Keeping a diary even briefly can reveal a lot.",
    }
    with (
        patch("app.agents.reflection.get_recent_diary_entries", new=AsyncMock(return_value=[])),
        patch("app.agents.reflection.get_triage_client", return_value=_mock_llm(llm_response)),
    ):
        draft = await ReflectionAgent().run(sample_state)

    assert draft.agent == "reflection"
    assert len(draft.key_points) >= 1


@pytest.mark.asyncio
async def test_reflection_parse_failure_returns_fallback(sample_state):
    """JSON parse failure should return the safe fallback draft, not raise."""
    client = AsyncMock()
    client.complete.return_value = "not valid json {{{"

    with (
        patch("app.agents.reflection.get_recent_diary_entries", new=AsyncMock(return_value=[])),
        patch("app.agents.reflection.get_triage_client", return_value=client),
    ):
        draft = await ReflectionAgent().run(sample_state)

    assert draft.agent == "reflection"
    assert len(draft.key_points) == 1
    assert "won't guess" in draft.key_points[0].claim.lower()


@pytest.mark.asyncio
async def test_reflection_passes_entry_content_to_llm(sample_state):
    """Diary entry content (not just metadata) must reach the LLM user message."""
    entries = [_entry("Woke up craving badly but drank water and it passed.", mood="anxious", tags=["morning"])]
    client = AsyncMock()
    client.complete.return_value = json.dumps({
        "agent": "reflection",
        "key_points": [{"claim": "Morning cravings appear in your diary.", "source_id": ""}],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [],
        "raw_context": "",
    })

    with (
        patch("app.agents.reflection.get_recent_diary_entries", new=AsyncMock(return_value=entries)),
        patch("app.agents.reflection.get_triage_client", return_value=client),
    ):
        await ReflectionAgent().run(sample_state)

    user_message = client.complete.call_args.kwargs["messages"][1]["content"]
    assert "craving badly" in user_message
    assert "entry_count=1" not in user_message  # template rendered, not raw
    assert "1 entries" in user_message


@pytest.mark.asyncio
async def test_reflection_diary_fetch_failure_degrades_gracefully(sample_state):
    """If diary fetch raises, the agent should still return a draft."""
    llm_response = {
        "agent": "reflection",
        "key_points": [{"claim": "Unable to load diary at this moment.", "source_id": ""}],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [],
        "raw_context": "",
    }
    # get_recent_diary_entries returns [] on any exception (see diary_retrieval.py),
    # so we simulate that here to confirm the agent handles the empty case cleanly.
    with (
        patch("app.agents.reflection.get_recent_diary_entries", new=AsyncMock(return_value=[])),
        patch("app.agents.reflection.get_triage_client", return_value=_mock_llm(llm_response)),
    ):
        draft = await ReflectionAgent().run(sample_state)

    assert draft.agent == "reflection"


@pytest.mark.asyncio
async def test_benchmark_diary_entries_are_injected_without_appwrite_access(sample_state):
    """Benchmark evidence is in-memory, isolated, and never fetched from Appwrite."""
    sample_state["benchmark_context_override"] = True
    sample_state["benchmark_diary_entries"] = [{
        "entry_id": "fixture-entry",
        "created_at": "2026-08-27T18:00:00Z",
        "mood": "proud",
        "tags": ["exercise"],
        "content": "A short walk helped the craving pass.",
    }]
    client = _mock_llm({
        "agent": "reflection",
        "key_points": [{"claim": "A short walk helped a recent craving.", "source_id": ""}],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [],
        "raw_context": "The diary records one useful coping response.",
    })
    fetch = AsyncMock(side_effect=AssertionError("Appwrite must not be called"))

    with (
        patch("app.agents.reflection.get_recent_diary_entries", new=fetch),
        patch("app.agents.reflection.get_triage_client", return_value=client),
    ):
        await ReflectionAgent().run(sample_state)

    fetch.assert_not_awaited()
    prompt = client.complete.call_args.kwargs["messages"][1]["content"]
    assert "short walk helped" in prompt.lower()
    assert sample_state["trace"]["benchmark_diary_entries_selected"] == ["fixture-entry"]


@pytest.mark.asyncio
async def test_empty_benchmark_diary_is_an_explicit_no_data_condition(sample_state):
    sample_state["benchmark_context_override"] = True
    sample_state["benchmark_diary_entries"] = []
    client = _mock_llm({
        "agent": "reflection",
        "key_points": [{"claim": "There is not enough recorded information to know.", "source_id": ""}],
        "tone_hint": "warm_supportive",
        "suggested_deeplinks": [],
        "raw_context": "I will not guess without recorded information.",
    })
    fetch = AsyncMock(side_effect=AssertionError("Appwrite must not be called"))

    with (
        patch("app.agents.reflection.get_recent_diary_entries", new=fetch),
        patch("app.agents.reflection.get_triage_client", return_value=client),
    ):
        await ReflectionAgent().run(sample_state)

    fetch.assert_not_awaited()
    prompt = client.complete.call_args.kwargs["messages"][1]["content"]
    assert "No diary entries" in prompt
