"""
Integration tests for Appwrite memory stores.
These are skipped in CI unless APPWRITE_INTEGRATION_TEST=true is set.
"""
from __future__ import annotations

import os
import pytest

SKIP = not os.getenv("APPWRITE_INTEGRATION_TEST")

pytestmark = pytest.mark.skipif(SKIP, reason="Set APPWRITE_INTEGRATION_TEST=true to run")


@pytest.mark.asyncio
async def test_conversation_store_round_trip():
    """Write a turn to Appwrite and read it back."""
    from app.memory.conversation_store import append_turn, get_recent_turns, delete_history

    user_id = "integration_test_user"
    try:
        turn_id = await append_turn(user_id, "user", "Hello Hailey", turn_id="it_turn_1")
        assert turn_id == "it_turn_1"

        turns = await get_recent_turns(user_id, limit=5)
        assert any(t.turn_id == "it_turn_1" for t in turns)
    finally:
        await delete_history(user_id)


@pytest.mark.asyncio
async def test_user_facts_store_round_trip():
    """Write a user fact and read it back."""
    from app.memory.user_facts_store import upsert_fact, get_facts, delete_fact
    from app.models.user_facts import UserFact

    user_id = "integration_test_user"
    fact = UserFact(
        user_id=user_id,
        fact_type="trigger",
        fact_key="morning_coffee_test",
        fact_value="Integration test trigger",
        confidence=0.9,
    )
    try:
        saved = await upsert_fact(fact)
        assert saved.fact_id is not None

        facts = await get_facts(user_id, fact_type="trigger")
        assert any(f.fact_key == "morning_coffee_test" for f in facts)
    finally:
        if fact.fact_id:
            await delete_fact(fact.fact_id)
