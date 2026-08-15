"""
GET    /memory/                   — returns the user's structured facts
POST   /memory/{fact_id}/confirm — explicitly reconfirms an active fact
DELETE /memory/                   — clears all facts for the authenticated user
DELETE /memory/{fact_id}          — lets the user delete a specific fact
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import get_current_user
from app.memory.fact_freshness import fact_expires_at, is_fact_stale
from app.memory.user_facts_store import confirm_fact, delete_all_facts, delete_fact, get_facts
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
    # Stale facts remain visible for review/deletion, but get_facts' default
    # excludes them from snapshots and other personalization consumers.
    facts = await get_facts(user_id, fact_type=fact_type, include_stale=True)
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
                expires_at=fact_expires_at(f),
                is_stale=is_fact_stale(f),
                requires_reconfirmation=is_fact_stale(f),
            )
            for f in facts
        ],
        total=len(facts),
    )


@router.post("/{fact_id}/confirm", response_model=MemoryFactResponse)
async def reconfirm_fact(
    fact_id: str,
    user_id: str = Depends(get_current_user),
):
    """Confirm that a stored fact is still accurate and renew its use period."""
    try:
        fact = await confirm_fact(fact_id, user_id)
    except Exception as exc:
        logger.warning("user_fact_reconfirmation_failed", fact_id=fact_id, error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Fact {fact_id!r} not found or unavailable.",
        )
    return MemoryFactResponse(
        fact_id=fact.fact_id or "",
        fact_type=fact.fact_type,
        fact_key=fact.fact_key,
        fact_value=fact.fact_value,
        confidence=fact.confidence,
        first_observed=fact.first_observed,
        last_confirmed=fact.last_confirmed,
        expires_at=fact_expires_at(fact),
        is_stale=False,
        requires_reconfirmation=False,
    )


@router.delete("/", status_code=status.HTTP_204_NO_CONTENT)
async def clear_memory(user_id: str = Depends(get_current_user)):
    """Delete all memory facts for the authenticated user."""
    count = await delete_all_facts(user_id)
    logger.info("memory_cleared", user_id=user_id, count=count)


@router.delete("/{fact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_fact(
    fact_id: str,
    user_id: str = Depends(get_current_user),
):
    """
    Delete a specific user fact by its ID.
    Ownership is verified server-side before deletion.
    """
    try:
        await delete_fact(fact_id, user_id=user_id)
        logger.info("user_fact_deleted_by_user", user_id=user_id, fact_id=fact_id)
    except Exception as exc:
        logger.warning("user_fact_delete_failed", fact_id=fact_id, error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Fact {fact_id!r} not found or already deleted.",
        )
