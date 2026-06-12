"""
Hybrid retriever — the single entry point for all agent retrieval.

Agents never call Qdrant or web search directly. They call:
    result = await HybridRetriever.retrieve(query, user_id, strategy, filters)

Strategy options:
  "factual"     → vector search over kb_chunks (+ graph expansion in Phase 3)
  "exploratory" → vector search with wider k, more diverse chunks
  "benefit"     → metadata filter by benefit_id (no vector needed)
  "emotional"   → no retrieval (emotional support uses user memory, not KB)
  "web"         → fallback web search if KB returns too few results

Phase 3 note: knowledge graph expansion and entity extraction are not yet
implemented. The TODO blocks below mark where they will be wired in.
"""
from __future__ import annotations

from typing import Literal, Optional

from app.config import settings
from app.models.retrieval import Citation, RetrievalResult, RetrievedChunk
from app.observability.logging import get_logger

logger = get_logger(__name__)

RetrievalStrategy = Literal["factual", "exploratory", "benefit", "emotional", "web"]


async def retrieve(
    query: str,
    user_id: str,
    strategy: RetrievalStrategy = "factual",
    filters: Optional[dict] = None,
    k: int = 5,
    intent: str = "unknown",
) -> RetrievalResult:
    """
    Main retrieval entry point.

    Args:
        query: The user's question or extracted medical sub-query.
        user_id: Used for logging and potential per-user filtering.
        strategy: Which retrieval mode to use.
        filters: Optional metadata filters (e.g. {"benefit_id": "20min"}).
        k: How many chunks to retrieve.

    Returns:
        RetrievalResult with chunks, citations, and strategy_used.
    """
    if strategy == "emotional":
        return RetrievalResult(query=query, strategy_used="none")

    if strategy == "benefit" and filters and "benefit_id" in filters:
        return await _benefit_retrieval(query, filters["benefit_id"])

    chunks = await _vector_retrieval(query, strategy, filters, k)

    # ── Phase 3: knowledge graph expansion goes here ──────────────────────
    # if settings.enable_knowledge_graph and strategy in ("factual", "exploratory"):
    #     from app.retrieval.entity_extractor import extract_entities
    #     from app.retrieval.knowledge_graph import expand_entities
    #     entities = extract_entities(query)
    #     graph_context = expand_entities(entities, hops=2)
    #     # Use graph_context.related_node_ids to add a second Qdrant filter pass
    # ── End Phase 3 ────────────────────────────────────────────────────────

    # Web search fallback if KB returns fewer than 2 meaningful chunks.
    # Skip for general conversation — web search adds no value for greetings.
    _web_intents = {"medical", "factual", "exploratory", "unknown"}
    if len(chunks) < 2 and strategy in ("factual", "exploratory") and intent in _web_intents:
        chunks = await _web_fallback(query, chunks)

    # Rerank if enabled (currently a pass-through stub)
    from app.retrieval.reranker import rerank
    chunks = await rerank(query, chunks)

    citations = _chunks_to_citations(chunks)
    return RetrievalResult(
        query=query,
        chunks=chunks,
        citations=citations,
        strategy_used="vector" if not settings.enable_knowledge_graph else "vector+graph",
    )


async def _vector_retrieval(
    query: str,
    strategy: RetrievalStrategy,
    filters: Optional[dict],
    k: int,
) -> list[RetrievedChunk]:
    """Embed the query and search Qdrant kb_chunks."""
    from app.llm.workers_ai_client import embed
    from app.retrieval.vector_store import search

    try:
        query_vector = await embed(query)
    except Exception as exc:
        logger.error("embed_failed", error=str(exc))
        return []

    effective_k = k if strategy != "exploratory" else k * 2
    return await search(
        query_vector=query_vector,
        collection=settings.qdrant_kb_collection,
        k=effective_k,
        filters=filters,
    )


async def _benefit_retrieval(query: str, benefit_id: str) -> RetrievalResult:
    """Metadata-only fetch for /kb/{benefit_id} — no vector embedding needed."""
    from app.retrieval.vector_store import get_by_metadata
    chunks = await get_by_metadata(
        collection=settings.qdrant_health_benefits_collection,
        filters={"benefit_id": benefit_id},
        limit=5,
    )
    citations = _chunks_to_citations(chunks)
    return RetrievalResult(
        query=query,
        chunks=chunks,
        citations=citations,
        strategy_used="benefit_metadata",
    )


async def _web_fallback(query: str, existing_chunks: list[RetrievedChunk]) -> list[RetrievedChunk]:
    """Append web search results when the KB has too few matches."""
    if not settings.enable_web_search_fallback:
        return existing_chunks
    from app.tools.web_search import web_search
    web_docs = await web_search(query, max_results=3)
    web_chunks = [
        RetrievedChunk(
            content=doc.content,
            source_id=f"web:{doc.url[:50]}",
            source_type="web",
            score=0.5,
        )
        for doc in web_docs
    ]
    return existing_chunks + web_chunks


def _chunks_to_citations(chunks: list[RetrievedChunk]) -> list[Citation]:
    """Convert retrieved chunks to Citation objects (deduplicated by source_id)."""
    seen: set[str] = set()
    citations: list[Citation] = []
    for chunk in chunks:
        if chunk.source_id not in seen:
            seen.add(chunk.source_id)
            citations.append(Citation(
                source_id=chunk.source_id,
                source_type=chunk.source_type,
                benefit_id=chunk.benefit_id,
                snippet=chunk.content[:200],
            ))
    return citations
