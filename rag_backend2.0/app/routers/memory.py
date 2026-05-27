"""
GET  /memory/           — returns the user's structured facts ("What does Hailey know about me?")
DELETE /memory/{fact_id} — lets the user delete a specific fact (GDPR / trust)
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import get_current_user
from app.memory.user_facts_store import delete_fact, get_facts
from app.models.chat import MemoryFactResponse, MemoryResponse
from app.observability.logging import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/memory", tags=["memory"])


@router.get("/", response_model=MemoryResponse)
async def get_memory(
    fact_type: str | None = None,
    user_id: str = Depends(get_current_user),
):
    """
    Return all structured facts Hailey has recorded about the user.
    Optionally filter by fact_type (e.g. "trigger", "coping_strategy_validated").
    """
    facts = await get_facts(user_id, fact_type=fact_type)
    return MemoryResponse(
        user_id=user_id,
        facts=[
            MemoryFactResponse(
                fact_id=f.fact_id or "",
                fact_type=f.fact_type,
                fact_key=f.fact_key,
                fact_value=f.fact_value,
                confidence=f.confidence,
                first_observed=f.first_observed,
                last_confirmed=f.last_confirmed,
            )
            for f in facts
        ],
        total=len(facts),
    )


@router.delete("/{fact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_fact(
    fact_id: str,
    user_id: str = Depends(get_current_user),
):
    """
    Delete a specific user fact by its ID.
    The user can only delete their own facts (fact ownership is not currently
    enforced at DB level — Appwrite permissions should restrict this per-document).
    """
    try:
        await delete_fact(fact_id)
        logger.info("user_fact_deleted_by_user", user_id=user_id, fact_id=fact_id)
    except Exception as exc:
        logger.warning("user_fact_delete_failed", fact_id=fact_id, error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Fact {fact_id!r} not found or already deleted.",
        )
