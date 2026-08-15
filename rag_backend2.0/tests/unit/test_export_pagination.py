"""Complete Hailey export reads every Appwrite page."""
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest

from app.memory.conversation_store import get_all_turns
from app.memory.user_facts_store import get_all_facts


def _turn(row_id: str, timestamp: str):
    return SimpleNamespace(
        id=row_id,
        data={
            "turn_id": row_id,
            "role": "user",
            "content": f"message {row_id}",
            "timestamp": timestamp,
            "citations": "[]",
        },
    )


def _fact(row_id: str, *, superseded_by: str | None = None):
    return SimpleNamespace(
        id=row_id,
        data={
            "fact_type": "trigger",
            "fact_key": row_id,
            "fact_value": f"value {row_id}",
            "confidence": 0.8,
            "source_turn_ids": '["turn-1"]',
            "first_observed": "2026-01-01T00:00:00+00:00",
            "last_confirmed": "2026-01-02T00:00:00+00:00",
            "superseded_by": superseded_by,
        },
    )


@pytest.mark.asyncio
async def test_get_all_turns_continues_from_full_page():
    db = MagicMock()
    db.list_rows.side_effect = [
        SimpleNamespace(rows=[
            _turn("t1", "2026-01-01T00:00:00+00:00"),
            _turn("t2", "2026-01-02T00:00:00+00:00"),
        ]),
        SimpleNamespace(rows=[_turn("t3", "2026-01-03T00:00:00+00:00")]),
    ]
    with patch("app.memory.conversation_store._build_client", return_value=(db, "db")):
        turns = await get_all_turns("u1", page_size=2)

    assert [turn.turn_id for turn in turns] == ["t1", "t2", "t3"]
    assert db.list_rows.call_count == 2
    second_queries = db.list_rows.call_args_list[1].kwargs["queries"]
    assert any("cursorAfter" in query for query in second_queries)


@pytest.mark.asyncio
async def test_get_all_facts_includes_active_and_superseded_pages():
    db = MagicMock()
    db.list_rows.side_effect = [
        SimpleNamespace(rows=[_fact("f1", superseded_by="f2"), _fact("f2")]),
        SimpleNamespace(rows=[_fact("f3")]),
    ]
    with patch("app.memory.user_facts_store._build_client", return_value=(db, "db")):
        facts = await get_all_facts("u1", page_size=2)

    assert [fact.fact_id for fact in facts] == ["f1", "f2", "f3"]
    assert facts[0].superseded_by == "f2"
    assert facts[0].source_turn_ids == ["turn-1"]
    assert db.list_rows.call_count == 2
    second_queries = db.list_rows.call_args_list[1].kwargs["queries"]
    assert any("cursorAfter" in query for query in second_queries)


@pytest.mark.parametrize("page_size", [0, 101])
@pytest.mark.asyncio
async def test_export_page_size_is_bounded(page_size: int):
    with pytest.raises(ValueError, match="between 1 and 100"):
        await get_all_turns("u1", page_size=page_size)
    with pytest.raises(ValueError, match="between 1 and 100"):
        await get_all_facts("u1", page_size=page_size)
