"""Unit tests for authenticated behavioral-event persistence."""
from __future__ import annotations

from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest

from app.routers.events import RelapseEvent, record_relapse


@pytest.mark.asyncio
async def test_record_relapse_writes_structured_fact():
    occurred_at = datetime(2026, 8, 10, 9, tzinfo=timezone.utc)
    with patch("app.routers.events.upsert_fact", new=AsyncMock()) as upsert:
        response = await record_relapse(RelapseEvent(occurred_at=occurred_at), user_id="u1")

    fact = upsert.await_args.args[0]
    assert response.status_code == 204
    assert fact.user_id == "u1"
    assert fact.fact_type == "past_attempt_history"
    assert fact.fact_key == "latest_relapse"
    assert fact.fact_value == occurred_at.isoformat()
    assert fact.confidence == 1.0
