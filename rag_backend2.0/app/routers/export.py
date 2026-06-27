"""
GET /export/ — full data export for the authenticated user (GDPR Article 20).

Returns all chat history and memory facts as structured JSON.
The Flutter client copies this to the clipboard for the user.
"""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import get_current_user
from app.memory.conversation_store import get_recent_turns
from app.memory.user_facts_store import get_facts
from app.observability.logging import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/export", tags=["export"])


@router.get("/")
async def export_user_data(user_id: str = Depends(get_current_user)):
    """
    Export all backend data held for the authenticated user:
    chat history (up to 500 turns) and all memory facts.
    """
    try:
        turns = await get_recent_turns(user_id, limit=500)
        facts = await get_facts(user_id)
    except Exception as exc:
        logger.error("export_failed", user_id=user_id, error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Export failed: {exc}",
        )

    return {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "chat_history": [
            {
                "role": t.role,
                "content": t.content,
                "timestamp": t.timestamp,
                "turn_id": t.turn_id,
            }
            for t in turns
        ],
        "memory_facts": [
            {
                "fact_type": f.fact_type,
                "fact_key": f.fact_key,
                "fact_value": f.fact_value,
                "confidence": f.confidence,
                "first_observed": f.first_observed.isoformat() if f.first_observed else None,
                "last_confirmed": f.last_confirmed.isoformat() if f.last_confirmed else None,
            }
            for f in facts
        ],
    }
