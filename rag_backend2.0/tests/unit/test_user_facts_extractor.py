"""Unit tests for the Memory Curator fact extraction."""
from __future__ import annotations

import json
from unittest.mock import AsyncMock, patch

import pytest

from app.agents.memory_curator import curate_memory


@pytest.mark.asyncio
async def test_curate_memory_extracts_trigger():
    """Memory curator should extract a trigger fact from the conversation."""
    mock_facts = json.dumps([
        {
            "fact_type": "trigger",
            "fact_key": "morning_coffee",
            "fact_value": "User mentioned morning coffee as a major trigger",
            "confidence": 0.9,
        }
    ])
    with patch("app.agents.memory_curator.get_triage_client") as mock_fn, \
         patch("app.agents.memory_curator.upsert_fact", new_callable=AsyncMock):
        mock_client = AsyncMock()
        mock_client.complete.return_value = mock_facts
        mock_fn.return_value = mock_client
        await curate_memory("u1", "I always crave when I drink my morning coffee", "I hear you...", "t1")
        mock_client.complete.assert_called_once()


@pytest.mark.asyncio
async def test_curate_memory_skips_low_confidence():
    """Facts below confidence 0.5 should not be upserted."""
    mock_facts = json.dumps([
        {
            "fact_type": "trigger",
            "fact_key": "maybe_coffee",
            "fact_value": "Possibly related to coffee",
            "confidence": 0.3,
        }
    ])
    with patch("app.agents.memory_curator.get_triage_client") as mock_fn, \
         patch("app.agents.memory_curator.upsert_fact", new_callable=AsyncMock) as mock_upsert:
        mock_client = AsyncMock()
        mock_client.complete.return_value = mock_facts
        mock_fn.return_value = mock_client
        await curate_memory("u1", "maybe coffee?", "Hmm...", "t1")
        mock_upsert.assert_not_called()


@pytest.mark.asyncio
async def test_curate_memory_handles_llm_failure():
    """Memory curator should not raise if the LLM call fails."""
    with patch("app.agents.memory_curator.get_triage_client") as mock_fn:
        mock_client = AsyncMock()
        mock_client.complete.side_effect = Exception("Groq timeout")
        mock_fn.return_value = mock_client
        # Should not raise
        await curate_memory("u1", "test input", "test reply", "t1")
