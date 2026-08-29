"""Unit tests for the HybridRetriever."""
from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from app.retrieval.hybrid_retriever import (
    _expand_medical_query,
    _select_diverse_chunks,
    _vector_retrieval,
    retrieve,
)
from app.models.retrieval import RetrievedChunk


def test_medical_query_expansion_adds_retrieval_terms_without_claims():
    expanded = _expand_medical_query("Will quitting improve my fitness?", "medical")
    assert "lung function" in expanded
    assert "oxygen circulation" in expanded


def test_nonmedical_query_is_not_expanded():
    assert _expand_medical_query("Who won the match?", "off_topic") == "Who won the match?"


@pytest.mark.parametrize(("query", "required"), [
    ("Will my taste and smell come back?", {"taste", "recovery", "timeline"}),
    ("Why is my cough worse after quitting?", {"phlegm", "airways", "clearing"}),
    ("Is it safe to use patches for years?", {"long-term", "safety", "duration"}),
    ("Can I use patches and gum together?", {"combination", "long-acting", "short-acting"}),
    ("Can my teenager use NRT?", {"teen", "doctor", "professional"}),
])
def test_campaign_gap_queries_receive_targeted_retrieval_terms(query, required):
    expanded = _expand_medical_query(query, "medical")
    assert required.issubset(set(expanded.split()))


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


def test_diverse_selection_applies_threshold_source_and_content_deduplication(monkeypatch):
    monkeypatch.setattr(
        "app.retrieval.hybrid_retriever.settings.retrieval_min_score", 0.60,
    )
    chunks = [
        RetrievedChunk(content="Same supported claim", source_id="nhs", score=0.91),
        RetrievedChunk(content="A second NHS chunk", source_id="nhs", score=0.89),
        RetrievedChunk(content="  SAME   supported CLAIM ", source_id="cdc", score=0.87),
        RetrievedChunk(content="Different supported claim", source_id="who", score=0.83),
        RetrievedChunk(content="Weak result", source_id="ala", score=0.59),
    ]

    selected = _select_diverse_chunks(chunks, limit=3)

    assert [(chunk.source_id, chunk.score) for chunk in selected] == [
        ("nhs", 0.91),
        ("who", 0.83),
    ]


@pytest.mark.asyncio
async def test_vector_retrieval_overfetches_and_applies_qdrant_threshold(monkeypatch):
    monkeypatch.setattr(
        "app.retrieval.hybrid_retriever.settings.retrieval_min_score", 0.60,
    )
    monkeypatch.setattr(
        "app.retrieval.hybrid_retriever.settings.retrieval_candidate_multiplier", 4,
    )
    chunks = [RetrievedChunk(content="Supported", source_id="nhs", score=0.8)]
    with (
        patch("app.llm.workers_ai_client.embed", new=AsyncMock(return_value=[0.1] * 384)),
        patch("app.retrieval.vector_store.search", new=AsyncMock(return_value=chunks)) as search,
    ):
        result = await _vector_retrieval("lung recovery", "factual", None, 3)

    assert result == chunks
    search.assert_awaited_once_with(
        query_vector=[0.1] * 384,
        collection="kb_chunks",
        k=12,
        filters=None,
        score_threshold=0.60,
    )
