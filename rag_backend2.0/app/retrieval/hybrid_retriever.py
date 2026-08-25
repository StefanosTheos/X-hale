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

Knowledge-graph expansion, entity extraction, optional reranking, and optional
web fallback are implemented and controlled through feature flags.
"""
from __future__ import annotations

import re
from typing import Literal, Optional

from app.config import settings
from app.models.retrieval import Citation, RetrievalResult, RetrievedChunk, bounded_excerpt
from app.observability.logging import get_logger

logger = get_logger(__name__)

RetrievalStrategy = Literal["factual", "exploratory", "benefit", "emotional", "web"]

_MEDICAL_QUERY_EXPANSIONS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"\b(?:fitness|stamina|exercise|workout|sport)\b", re.I),
     "physical activity lung function oxygen circulation breathing"),
    (re.compile(r"\b(?:skin|complexion|wrinkle)\b", re.I), "skin circulation healing"),
    (re.compile(r"\b(?:eye|eyesight|vision)\b", re.I),
     "eye health cataract macular degeneration"),
    (re.compile(r"\b(?:mouth|oral|gum|teeth|tooth)\b", re.I),
     "oral health gum disease teeth"),
    (re.compile(r"\b(?:fertility|pregnan|reproductive)\w*\b", re.I),
     "fertility reproductive health pregnancy"),
    (re.compile(r"\b(?:wound|surgery|operation)\w*\b", re.I),
     "wound healing circulation oxygen surgery"),
    (re.compile(r"\b(?:bone|osteoporosis|fracture)\w*\b", re.I),
     "bone health osteoporosis fracture"),
    (re.compile(r"\b(?:immune|infection)\w*\b", re.I), "immune system infection"),
    (re.compile(r"\b(?:sleep|dream|insomnia)\w*\b", re.I),
     "nicotine withdrawal sleep dreams insomnia"),
    (re.compile(r"\b(?:diabetes|blood sugar|glucose|insulin)\b", re.I),
     "diabetes blood sugar glucose insulin nicotine cessation"),
    (re.compile(r"\b(?:hormone|menstrual|period|cycle)\w*\b", re.I),
     "hormones menstrual cycle reproductive health smoking cessation"),
    (re.compile(r"\b(?:acupuncture|hypnosis|hypnotherapy|herbal cigarette)\w*\b", re.I),
     "alternative methods evidence acupuncture hypnosis herbal cigarettes cessation"),
    (re.compile(r"\b(?:champix|chantix|varenicline|alcohol)\w*\b", re.I),
     "varenicline alcohol interaction medication safety"),
    (re.compile(r"\b(?:prescription|pharmacy|over the counter|2mg|4mg|step.down)\b", re.I),
     "nicotine replacement pharmacy prescription gum 2 mg 4 mg patch step down"),
)


def _expand_medical_query(query: str, intent: str) -> str:
    """Add conservative domain terms without adding medical claims."""
    if intent not in {"medical", "factual", "exploratory", "unknown"}:
        return query
    additions = [terms for pattern, terms in _MEDICAL_QUERY_EXPANSIONS if pattern.search(query)]
    return f"{query} {' '.join(additions)}".strip() if additions else query


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

    try:
        retrieval_query = _expand_medical_query(query, intent)
        chunks = await _vector_retrieval(retrieval_query, strategy, filters, k)
    except Exception as exc:
        # Public retrieval boundary: callers receive an empty, explicit result
        # even if an unexpected lower-level provider error escapes its adapter.
        logger.error("vector_retrieval_failed", user_id=user_id, error=str(exc))
        chunks = []

    # Knowledge graph expansion: find related concepts and retrieve additional chunks
    # tagged with the expanded topic_tags, then merge with the vector results.
    strategy_used = "vector"
    if settings.enable_knowledge_graph and strategy in ("factual", "exploratory"):
        from app.retrieval.entity_extractor import extract_entities
        from app.retrieval.knowledge_graph import expand_entities
        entities = extract_entities(query)
        if entities:
            expansion = expand_entities(entities, hops=2)
            if not expansion.is_empty():
                kg_chunks = await _kg_retrieval(query, expansion.topic_tags, k=3)
                chunks = _merge_chunks(chunks, kg_chunks, max_total=k + 3)
                strategy_used = "vector+graph"

    # Web search fallback if KB returns fewer than 2 meaningful chunks.
    # Skip for general conversation — web search adds no value for greetings.
    _web_intents = {"medical", "factual", "exploratory", "unknown"}
    if len(chunks) < 2 and strategy in ("factual", "exploratory") and intent in _web_intents:
        chunks = await _web_fallback(query, chunks)

    # Rerank when enabled; otherwise rerank() returns the original ordering.
    from app.retrieval.reranker import rerank
    chunks = await rerank(query, chunks)

    citations = _chunks_to_citations(chunks)
    return RetrievalResult(
        query=query,
        chunks=chunks,
        citations=citations,
        strategy_used=strategy_used,
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
    candidates = await search(
        query_vector=query_vector,
        collection=settings.qdrant_kb_collection,
        k=effective_k * settings.retrieval_candidate_multiplier,
        filters=filters,
        score_threshold=settings.retrieval_min_score,
    )
    return _select_diverse_chunks(candidates, limit=effective_k)


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


async def _kg_retrieval(
    query: str,
    topic_tags: list[str],
    k: int = 3,
) -> list[RetrievedChunk]:
    """
    Second-pass vector search filtered to chunks tagged with any of the
    KG-expanded topic_tags (OR filter). Returns at most k chunks.
    """
    from app.llm.workers_ai_client import embed
    from app.retrieval.vector_store import search

    try:
        query_vector = await embed(query)
    except Exception as exc:
        logger.warning("kg_retrieval_embed_failed", error=str(exc))
        return []

    candidates = await search(
        query_vector=query_vector,
        collection=settings.qdrant_kb_collection,
        k=k * settings.retrieval_candidate_multiplier,
        topic_tags_should=topic_tags,
        score_threshold=settings.retrieval_min_score,
    )
    return _select_diverse_chunks(candidates, limit=k)


def _content_key(content: str) -> str:
    """Normalize chunk text for formatting-insensitive exact deduplication."""
    return re.sub(r"\s+", " ", content).strip().casefold()


def _select_diverse_chunks(
    chunks: list[RetrievedChunk],
    *,
    limit: int,
) -> list[RetrievedChunk]:
    """Keep strong, distinct content from no more than one chunk per source."""
    seen_sources: set[str] = set()
    seen_content: set[str] = set()
    selected: list[RetrievedChunk] = []
    for chunk in sorted(chunks, key=lambda item: item.score, reverse=True):
        if chunk.score < settings.retrieval_min_score:
            continue
        content_key = _content_key(chunk.content)
        if chunk.source_id in seen_sources or not content_key or content_key in seen_content:
            continue
        seen_sources.add(chunk.source_id)
        seen_content.add(content_key)
        selected.append(chunk)
        if len(selected) == limit:
            break
    return selected


def _merge_chunks(
    primary: list[RetrievedChunk],
    secondary: list[RetrievedChunk],
    max_total: int = 8,
) -> list[RetrievedChunk]:
    """
    Merge two chunk lists, deduplicating by source_id.
    Primary chunks take precedence; secondary chunks are appended if not already present.
    Result is capped at max_total and sorted by score descending.
    """
    seen: set[str] = set()
    merged: list[RetrievedChunk] = []

    for chunk in primary:
        if chunk.source_id not in seen:
            seen.add(chunk.source_id)
            merged.append(chunk)

    for chunk in secondary:
        if chunk.source_id not in seen:
            seen.add(chunk.source_id)
            merged.append(chunk)

    merged.sort(key=lambda c: c.score, reverse=True)
    return merged[:max_total]


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
                title=str(chunk.metadata.get("title", "")),
                url=str(chunk.metadata.get("url", chunk.metadata.get("source_url", ""))),
                snippet=bounded_excerpt(chunk.content, 500),
            ))
    return citations
