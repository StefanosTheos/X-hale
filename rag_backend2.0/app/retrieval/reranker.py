"""
Cross-encoder reranker for re-sorting retrieved chunks.

Enable with ENABLE_RERANKER=true (requires the [reranker] optional dependency group).
Model: BAAI/bge-reranker-base (~110 MB, CPU inference, ~50 ms for 10 candidates).

Design notes:
- The model is loaded lazily on first use so it doesn't delay startup when disabled.
- CrossEncoder.predict is synchronous CPU work; it runs in asyncio.to_thread to avoid
  blocking the event loop.
- If all chunks fall below _MIN_SCORE the top-scoring chunk is kept rather than returning
  nothing, preventing a silent retrieval failure upstream.
- Any exception during scoring falls back to the original ordering so retrieval never
  breaks due to a reranker failure.
"""
from __future__ import annotations

import asyncio
from typing import Optional

from app.config import settings
from app.models.retrieval import RetrievedChunk
from app.observability.logging import get_logger

logger = get_logger(__name__)

_MIN_SCORE: float = 0.3
_MODEL_NAME: str = "BAAI/bge-reranker-base"
_cross_encoder: Optional[object] = None


def _get_cross_encoder() -> object:
    global _cross_encoder
    if _cross_encoder is None:
        from sentence_transformers import CrossEncoder  # noqa: PLC0415
        _cross_encoder = CrossEncoder(_MODEL_NAME)
        logger.info("reranker_model_loaded", model=_MODEL_NAME)
    return _cross_encoder


def _predict_sync(query: str, chunks: list[RetrievedChunk]) -> list[float]:
    """Score (query, chunk) pairs with the cross-encoder. Runs in a thread."""
    model = _get_cross_encoder()
    pairs = [(query, chunk.content) for chunk in chunks]
    raw = model.predict(pairs)  # type: ignore[union-attr]
    return [float(s) for s in raw]


async def rerank(query: str, chunks: list[RetrievedChunk]) -> list[RetrievedChunk]:
    """
    Re-rank retrieved chunks using a cross-encoder model.

    Returns the original list unchanged when ENABLE_RERANKER=false or on any error.
    When enabled, returns chunks sorted by cross-encoder score, dropping those below
    _MIN_SCORE (with a guarantee that at least one chunk is always returned).
    """
    if not settings.enable_reranker:
        return chunks

    if not chunks:
        return chunks

    try:
        scores = await asyncio.to_thread(_predict_sync, query, chunks)
    except Exception as exc:
        logger.warning("reranker_failed", error=str(exc))
        return chunks

    ranked = sorted(
        zip(scores, chunks),
        key=lambda pair: pair[0],
        reverse=True,
    )

    result = [chunk for score, chunk in ranked if score > _MIN_SCORE]
    if not result:
        result = [ranked[0][1]]

    logger.debug("reranker_complete", input=len(chunks), output=len(result))
    return result
