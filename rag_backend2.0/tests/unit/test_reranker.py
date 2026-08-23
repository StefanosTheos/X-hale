"""Unit tests for the cross-encoder reranker."""
from __future__ import annotations

from unittest.mock import patch

import pytest

from app.models.retrieval import RetrievedChunk
from app.retrieval.reranker import rerank, _MIN_SCORE


def _chunk(content: str, source_id: str = "s", score: float = 0.8) -> RetrievedChunk:
    return RetrievedChunk(content=content, source_id=source_id, source_type="government", score=score)


# ── Flag-off behaviour ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_rerank_disabled_uses_cheap_lexical_ordering(monkeypatch):
    """Without the model, relevant vector candidates still move to the front."""
    monkeypatch.setattr("app.retrieval.reranker.settings.enable_reranker", False)
    chunks = [_chunk("unrelated", "a"), _chunk("lung recovery after quitting", "b")]
    result = await rerank("lung recovery", chunks)
    assert [chunk.source_id for chunk in result] == ["b", "a"]


@pytest.mark.asyncio
async def test_rerank_disabled_does_not_load_model(monkeypatch):
    """The cross-encoder must not be instantiated when the flag is off."""
    monkeypatch.setattr("app.retrieval.reranker.settings.enable_reranker", False)
    with patch("app.retrieval.reranker._get_cross_encoder") as mock_load:
        await rerank("query", [_chunk("a")])
    mock_load.assert_not_called()


# ── Flag-on behaviour ─────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_rerank_reorders_by_cross_encoder_score(monkeypatch):
    """Chunks must be returned highest cross-encoder score first."""
    monkeypatch.setattr("app.retrieval.reranker.settings.enable_reranker", True)
    chunks = [_chunk("low relevance", "a"), _chunk("high relevance", "b"), _chunk("medium", "c")]
    # scores align with chunks order: a=0.2 (below threshold), b=0.9, c=0.5
    with patch("app.retrieval.reranker._predict_sync", return_value=[0.2, 0.9, 0.5]):
        result = await rerank("query", chunks)
    assert result[0].source_id == "b"
    assert result[1].source_id == "c"
    assert len(result) == 2   # "a" dropped (score 0.2 < 0.3)


@pytest.mark.asyncio
async def test_rerank_drops_chunks_below_threshold(monkeypatch):
    """Chunks with cross-encoder score <= _MIN_SCORE must be excluded."""
    monkeypatch.setattr("app.retrieval.reranker.settings.enable_reranker", True)
    chunks = [_chunk("good", "g"), _chunk("poor", "p")]
    with patch("app.retrieval.reranker._predict_sync", return_value=[0.85, 0.10]):
        result = await rerank("query", chunks)
    assert len(result) == 1
    assert result[0].source_id == "g"


@pytest.mark.asyncio
async def test_rerank_all_below_threshold_keeps_best(monkeypatch):
    """If every chunk is below _MIN_SCORE at least the top-scoring one is kept."""
    monkeypatch.setattr("app.retrieval.reranker.settings.enable_reranker", True)
    chunks = [_chunk("a", "a"), _chunk("b", "b"), _chunk("c", "c")]
    with patch("app.retrieval.reranker._predict_sync", return_value=[0.05, 0.15, 0.10]):
        result = await rerank("query", chunks)
    assert len(result) == 1
    assert result[0].source_id == "b"   # highest score (0.15) even though below threshold


@pytest.mark.asyncio
async def test_rerank_empty_input_returns_empty(monkeypatch):
    """Empty input must return empty without touching the model."""
    monkeypatch.setattr("app.retrieval.reranker.settings.enable_reranker", True)
    with patch("app.retrieval.reranker._predict_sync") as mock_predict:
        result = await rerank("query", [])
    assert result == []
    mock_predict.assert_not_called()


@pytest.mark.asyncio
async def test_rerank_model_failure_returns_original(monkeypatch):
    """A cross-encoder error must degrade gracefully — return the original list."""
    monkeypatch.setattr("app.retrieval.reranker.settings.enable_reranker", True)
    chunks = [_chunk("a"), _chunk("b")]
    with patch("app.retrieval.reranker._predict_sync", side_effect=RuntimeError("model OOM")):
        result = await rerank("query", chunks)
    assert result is chunks


@pytest.mark.asyncio
async def test_rerank_single_chunk_above_threshold(monkeypatch):
    """Single chunk above threshold is returned as a one-element list."""
    monkeypatch.setattr("app.retrieval.reranker.settings.enable_reranker", True)
    chunks = [_chunk("only chunk", "only")]
    with patch("app.retrieval.reranker._predict_sync", return_value=[0.75]):
        result = await rerank("query", chunks)
    assert len(result) == 1
    assert result[0].source_id == "only"
