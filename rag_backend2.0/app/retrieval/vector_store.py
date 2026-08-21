"""
Qdrant Cloud async client wrapper.

Provides:
- search(query_vector, collection, k, filters): vector similarity search
- upsert(collection, points): insert/update vectors
- get_by_metadata(collection, filters, limit): metadata-only fetch (no vector needed)

Two collections:
  - kb_chunks: global knowledge base (500-character chunks by default, source-tagged)
  - health_benefit_chunks: benefit-specific content, tagged with benefit_id

Single AsyncQdrantClient instance shared across the process.
"""
from __future__ import annotations

from functools import lru_cache
from typing import Optional

from qdrant_client import AsyncQdrantClient
from qdrant_client.models import (
    Distance,
    FieldCondition,
    Filter,
    MatchValue,
    PointStruct,
    ScoredPoint,
    VectorParams,
)

# Qdrant filter helpers not imported at module level to keep the import minimal
# — used inside search() when topic_tags_should is provided.

from app.config import settings
from app.models.retrieval import RetrievedChunk
from app.observability.logging import get_logger
from app.observability.metrics import record_retrieval

logger = get_logger(__name__)


@lru_cache(maxsize=1)
def get_qdrant_client() -> AsyncQdrantClient:
    """Return the shared Qdrant client. Called lazily on first use."""
    return AsyncQdrantClient(
        url=settings.qdrant_url,
        api_key=settings.qdrant_api_key or None,
        timeout=30,
        prefer_grpc=False,
    )


async def search(
    query_vector: list[float],
    collection: str,
    k: int = 5,
    filters: Optional[dict] = None,
    topic_tags_should: Optional[list[str]] = None,
    score_threshold: Optional[float] = None,
) -> list[RetrievedChunk]:
    """
    Perform a vector similarity search in the given Qdrant collection.

    Args:
        query_vector: The embedded query vector (384-dim for bge-small-en-v1.5).
        collection: Collection name (use settings.qdrant_kb_collection etc.).
        k: Number of results to return.
        filters: Optional dict of {field: value} MUST (AND) metadata filters.
        topic_tags_should: Optional list of topic_tag values for OR filtering.
            A chunk matches if its topic_tags array contains ANY of these values.
            Combined with `filters` as: must(filters) AND should(topic_tags).

    Returns:
        List of RetrievedChunk objects sorted by relevance score (highest first).
    """
    client = get_qdrant_client()
    qdrant_filter: Optional[Filter] = None

    must_conditions = []
    if filters:
        must_conditions = [
            FieldCondition(key=key, match=MatchValue(value=val))
            for key, val in filters.items()
        ]

    should_conditions = []
    if topic_tags_should:
        should_conditions = [
            FieldCondition(key="topic_tags", match=MatchValue(value=tag))
            for tag in topic_tags_should
        ]

    if must_conditions and should_conditions:
        qdrant_filter = Filter(must=must_conditions, should=should_conditions)
    elif must_conditions:
        qdrant_filter = Filter(must=must_conditions)
    elif should_conditions:
        qdrant_filter = Filter(should=should_conditions)

    try:
        hits: list[ScoredPoint] = await client.search(
            collection_name=collection,
            query_vector=query_vector,
            query_filter=qdrant_filter,
            limit=k,
            score_threshold=score_threshold,
            with_payload=True,
        )
    except Exception as exc:
        logger.error("qdrant_search_failed", collection=collection, error=str(exc))
        return []

    chunks: list[RetrievedChunk] = []
    for hit in hits:
        payload = hit.payload or {}
        # Support both "text" (ingestion key) and "content" (legacy key)
        text = payload.get("text") or payload.get("content", "")
        chunks.append(RetrievedChunk(
            content=text,
            source_id=payload.get("source_id", "unknown"),
            source_type=payload.get("source_type", "unknown"),
            benefit_id=payload.get("benefit_id"),
            score=float(hit.score),
            metadata={
                **{k: v for k, v in payload.items() if k not in ("text", "content")},
                "document_id": str(hit.id),
                "collection": collection,
            },
        ))

    record_retrieval(len(chunks))
    return chunks


async def get_by_metadata(
    collection: str,
    filters: dict,
    limit: int = 10,
) -> list[RetrievedChunk]:
    """
    Fetch chunks by metadata filter only (no vector similarity).
    Used by GET /kb/{benefit_id} to return pre-tagged content.
    """
    client = get_qdrant_client()
    conditions = [
        FieldCondition(key=key, match=MatchValue(value=val))
        for key, val in filters.items()
    ]
    qdrant_filter = Filter(must=conditions)
    try:
        results, _ = await client.scroll(
            collection_name=collection,
            scroll_filter=qdrant_filter,
            limit=limit,
            with_payload=True,
            with_vectors=False,
        )
    except Exception as exc:
        logger.error("qdrant_metadata_fetch_failed", collection=collection, error=str(exc))
        return []

    return [
        RetrievedChunk(
            content=p.payload.get("text") or p.payload.get("content", ""),
            source_id=p.payload.get("source_id", "unknown"),
            source_type=p.payload.get("source_type", "unknown"),
            benefit_id=p.payload.get("benefit_id"),
            score=1.0,
            metadata={
                **p.payload, "document_id": str(p.id), "collection": collection,
            },
        )
        for p in results
        if p.payload
    ]


async def upsert(collection: str, points: list[dict]) -> None:
    """
    Upsert a list of point dicts into the collection.
    Each dict must have: id (str/int), vector (list[float]), payload (dict).
    """
    client = get_qdrant_client()
    qdrant_points = [
        PointStruct(id=p["id"], vector=p["vector"], payload=p["payload"])
        for p in points
    ]
    await client.upsert(collection_name=collection, points=qdrant_points)
    logger.info("qdrant_upsert_ok", collection=collection, count=len(qdrant_points))
