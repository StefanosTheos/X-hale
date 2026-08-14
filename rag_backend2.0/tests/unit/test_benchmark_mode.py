from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import pytest

from app.config import settings
from app.graph.builder import output_node


@pytest.mark.asyncio
async def test_benchmark_user_persists_turn_without_memory_curation(monkeypatch):
    monkeypatch.setattr(settings, "benchmark_test_user_id", "benchmark-user")
    state = {
        "user_id": "benchmark-user",
        "user_input": "Coffee is a trigger for me",
        "final_response": "Thanks for sharing that.",
        "citations": [],
        "triage": SimpleNamespace(intent="craving_support"),
        "turn_id": "turn-1",
    }

    with patch("app.memory.conversation_store.append_turn", new_callable=AsyncMock) as append, \
         patch("app.memory.curation_tasks.schedule_memory_curation") as schedule:
        result = await output_node(state)

    assert append.await_count == 2
    schedule.assert_not_called()
    assert result["turn_id"] == "turn-1"
