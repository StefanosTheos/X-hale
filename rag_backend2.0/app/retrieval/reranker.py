"""
Cross-encoder reranker for re-sorting retrieved chunks.

# ══════════════════════════════════════════════════════════════════
# PHASE 3 — NOT YET IMPLEMENTED
# Status: feature-flagged stub. Enable with ENABLE_RERANKER=true
#         and install the [reranker] optional dependency group.
# Model: BAAI/bge-reranker-base (runs on CPU, ~50ms for 10 candidates)
# ══════════════════════════════════════════════════════════════════

When implemented, this module will:
  1. Accept a query string and a list of RetrievedChunk objects.
  2. Use the cross-encoder to score each (query, chunk) pair.
  3. Return the chunks re-sorted by cross-encoder score (highest first).
  4. Drop chunks below a minimum score threshold.

The hybrid_retriever calls rerank() if settings.enable_reranker is True.
"""
from __future__ import annotations

from app.config import settings
from app.models.retrieval import RetrievedChunk
from app.observability.logging import get_logger

logger = get_logger(__name__)


async def rerank(query: str, chunks: list[RetrievedChunk]) -> list[RetrievedChunk]:
    """
    Re-rank retrieved chunks using a cross-encoder model.

    Returns the original list unchanged if ENABLE_RERANKER=false (current default).
    When Phase 3 is implemented, this will use BAAI/bge-reranker-base on CPU.
    """
    if not settings.enable_reranker:
        return chunks

    # ── Phase 3 implementation goes here ──────────────────────────────────
    # from sentence_transformers import CrossEncoder
    # _model = CrossEncoder("BAAI/bge-reranker-base")
    # pairs = [(query, chunk.content) for chunk in chunks]
    # scores = _model.predict(pairs)
    # ranked = sorted(zip(scores, chunks), key=lambda x: x[0], reverse=True)
    # return [chunk for score, chunk in ranked if score > 0.3]
    # ── End Phase 3 ────────────────────────────────────────────────────────

    logger.warning("reranker_enabled_but_not_implemented")
    return chunks
