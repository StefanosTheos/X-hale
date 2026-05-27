"""
GET /kb/{benefit_id} — returns pre-chunked knowledge base content for a health benefit.

Used by the Flutter app's "Learn More" buttons on the Health Benefits screen.
Bypasses the full agent pipeline — pure metadata-filtered Qdrant fetch.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user
from app.config import settings
from app.models.chat import KBChunkResponse, KBResponse
from app.retrieval.vector_store import get_by_metadata
from app.observability.logging import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/kb", tags=["knowledge-base"])


@router.get("/{benefit_id}", response_model=KBResponse)
async def get_kb_for_benefit(
    benefit_id: str,
    limit: int = 5,
    user_id: str = Depends(get_current_user),
):
    """
    Return knowledge base chunks tagged with the given benefit_id.
    benefit_id values match the 14 health benefit IDs in the Flutter app
    (e.g. "20min", "8hr", "24hr", "48hr", "72hr", "2wk", "1mo", "3mo",
           "6mo", "1yr", "5yr", "10yr", "15yr", "20yr").
    """
    chunks = await get_by_metadata(
        collection=settings.qdrant_health_benefits_collection,
        filters={"benefit_id": benefit_id},
        limit=limit,
    )
    logger.info("kb_fetch", benefit_id=benefit_id, count=len(chunks), user_id=user_id)
    return KBResponse(
        benefit_id=benefit_id,
        chunks=[
            KBChunkResponse(
                content=c.content,
                source_id=c.source_id,
                source_type=c.source_type,
                benefit_id=c.benefit_id,
                score=c.score,
            )
            for c in chunks
        ],
    )
