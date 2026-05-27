"""
GET  /history/         — returns the authenticated user's conversation history
DELETE /history/       — clears the authenticated user's conversation history
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import get_current_user
from app.memory.conversation_store import delete_history, get_recent_turns
from app.models.chat import HistoryResponse, HistoryTurn
from app.observability.logging import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/history", tags=["history"])


@router.get("/", response_model=HistoryResponse)
async def get_history(
    limit: int = 20,
    user_id: str = Depends(get_current_user),
):
    """
    Return the user's recent conversation turns, oldest first.
    Only the authenticated user can access their own history.
    """
    turns = await get_recent_turns(user_id, limit=limit)
    return HistoryResponse(
        user_id=user_id,
        turns=[
            HistoryTurn(
                turn_id=t.turn_id,
                role=t.role,
                content=t.content,
                timestamp=t.timestamp,
                citations=[{"source_id": c} if isinstance(c, str) else c for c in t.citations],
            )
            for t in turns
        ],
        total=len(turns),
    )


@router.delete("/", status_code=status.HTTP_204_NO_CONTENT)
async def clear_history(user_id: str = Depends(get_current_user)):
    """
    Delete all conversation history for the authenticated user.
    Returns 204 No Content on success.
    """
    count = await delete_history(user_id)
    logger.info("history_cleared", user_id=user_id, count=count)
