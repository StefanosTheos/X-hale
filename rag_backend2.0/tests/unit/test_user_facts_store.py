"""User-fact lifecycle rules independent of a live Appwrite project."""
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest

from app.memory.user_facts_store import confirm_fact, delete_all_facts, delete_fact, get_facts, upsert_fact
from app.models.user_facts import UserFact


def _fact(value: str, confidence: float) -> UserFact:
    return UserFact(
        user_id="u1", fact_type="trigger", fact_key="coffee",
        fact_value=value, confidence=confidence, source_turn_ids=["new-turn"],
    )


@pytest.mark.asyncio
async def test_lower_confidence_conflict_does_not_replace_active_fact():
    db = MagicMock()
    existing = SimpleNamespace(
        id="old", data={"fact_value": "morning trigger", "confidence": 0.9, "source_turn_ids": "[]"},
    )
    db.list_rows.return_value = SimpleNamespace(rows=[existing])
    with patch("app.memory.user_facts_store._build_client", return_value=(db, "db")):
        result = await upsert_fact(_fact("evening trigger", 0.6))

    assert result.fact_id == "old"
    assert result.fact_value == "morning trigger"
    db.update_row.assert_not_called()
    db.create_row.assert_not_called()


@pytest.mark.asyncio
async def test_higher_confidence_conflict_supersedes_old_fact():
    db = MagicMock()
    existing = SimpleNamespace(
        id="old", data={"fact_value": "morning trigger", "confidence": 0.6, "source_turn_ids": "[]"},
    )
    db.list_rows.return_value = SimpleNamespace(rows=[existing])
    db.create_row.return_value = SimpleNamespace(id="new")
    with patch("app.memory.user_facts_store._build_client", return_value=(db, "db")):
        result = await upsert_fact(_fact("evening trigger", 0.9))

    assert result.fact_id == "new"
    assert db.update_row.call_args.args[-1] == {"superseded_by": "new"}


@pytest.mark.asyncio
async def test_bulk_delete_continues_past_first_page():
    db = MagicMock()
    first = [SimpleNamespace(id=f"f{i}") for i in range(100)]
    second = [SimpleNamespace(id="f100")]
    db.list_rows.side_effect = [SimpleNamespace(rows=first), SimpleNamespace(rows=second), SimpleNamespace(rows=[])]
    with patch("app.memory.user_facts_store._build_client", return_value=(db, "db")):
        count = await delete_all_facts("u1")

    assert count == 101
    assert db.list_rows.call_count == 3
    assert db.delete_row.call_count == 101


@pytest.mark.asyncio
async def test_delete_fact_enforces_owner():
    db = MagicMock()
    db.get_row.return_value = SimpleNamespace(data={"userId": "someone-else"})
    with patch("app.memory.user_facts_store._build_client", return_value=(db, "db")):
        with pytest.raises(PermissionError):
            await delete_fact("fact", user_id="u1")
    db.delete_row.assert_not_called()


@pytest.mark.asyncio
async def test_get_facts_excludes_stale_by_default_but_can_return_for_controls():
    db = MagicMock()
    db.list_rows.return_value = SimpleNamespace(rows=[
        SimpleNamespace(id="fresh", data={
            "fact_type": "trigger", "fact_key": "coffee", "fact_value": "trigger",
            "last_confirmed": "2026-08-01T00:00:00+00:00",
        }),
        SimpleNamespace(id="legacy", data={
            "fact_type": "trigger", "fact_key": "work", "fact_value": "trigger",
        }),
    ])
    with patch("app.memory.user_facts_store._build_client", return_value=(db, "db")):
        usable = await get_facts("u1")
        visible = await get_facts("u1", include_stale=True)

    assert [fact.fact_id for fact in usable] == ["fresh"]
    assert [fact.fact_id for fact in visible] == ["fresh", "legacy"]


@pytest.mark.asyncio
async def test_confirm_fact_enforces_owner_and_refreshes_timestamp():
    db = MagicMock()
    source = {
        "userId": "u1", "fact_type": "trigger", "fact_key": "coffee",
        "fact_value": "trigger", "confidence": 0.8,
        "first_observed": "2026-01-01T00:00:00+00:00",
    }
    db.get_row.return_value = SimpleNamespace(id="fact", data=source)
    db.update_row.return_value = SimpleNamespace(
        id="fact", data={**source, "last_confirmed": "2026-08-15T00:00:00+00:00"},
    )
    with patch("app.memory.user_facts_store._build_client", return_value=(db, "db")):
        result = await confirm_fact("fact", "u1")

    assert result.last_confirmed == datetime(2026, 8, 15, tzinfo=timezone.utc)
    assert "last_confirmed" in db.update_row.call_args.args[-1]
