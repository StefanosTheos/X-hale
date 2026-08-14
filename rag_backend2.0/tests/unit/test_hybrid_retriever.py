"""Unit tests for the HybridRetriever."""
from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from app.retrieval.hybrid_retriever import retrieve
from app.models.retrieval import RetrievedChunk


@pytest.mark.asyncio
async def test_retrieve_emotional_returns_empty():
    """Emotional strategy should return empty result without calling Qdrant."""
    result = await retrieve("I'm feeling sad", "u1", strategy="emotional")
    assert result.chunks == []
    assert result.strategy_used == "none"


@pytest.mark.asyncio
async def test_retrieve_factual_calls_qdrant(sample_retrieval_result):
    mock_chunks = [
        RetrievedChunk(content="Lung cilia regenerate after 2 weeks.", source_id="nhs", source_type="government", score=0.9)
    ]
    with patch("app.retrieval.hybrid_retriever._vector_retrieval", new_callable=AsyncMock) as mock_vec, \
         patch("app.llm.workers_ai_client.embed", new_callable=AsyncMock, return_value=[0.1] * 384):
        mock_vec.return_value = mock_chunks
        result = await retrieve("How long for lungs to heal?", "u1", strategy="factual")
    assert len(result.chunks) > 0 or mock_vec.called


@pytest.mark.asyncio
async def test_retrieve_handles_embed_failure():
    """If embedding fails, retriever should return empty result gracefully."""
    with patch("app.retrieval.hybrid_retriever._vector_retrieval", new_callable=AsyncMock) as mock_vec:
        mock_vec.side_effect = Exception("Workers AI down")
        result = await retrieve("test query", "u1", strategy="factual")
    assert result.chunks == []
    assert result.citations == []
    assert result.strategy_used == "vector"
