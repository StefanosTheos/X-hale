"""Authenticated application events consumed by Hailey's support logic."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel

from app.auth.dependencies import get_current_user
from app.memory.user_facts_store import upsert_fact
from app.models.user_facts import UserFact
from app.observability.logging import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/events", tags=["events"])


class RelapseEvent(BaseModel):
    occurred_at: datetime


@router.post("/relapse", status_code=status.HTTP_204_NO_CONTENT)
async def record_relapse(
    event: RelapseEvent,
    user_id: str = Depends(get_current_user),
) -> Response:
    """Persist an explicit relapse action as a structured, user-owned memory fact."""
    occurred_at = event.occurred_at
    if occurred_at.tzinfo is None:
        occurred_at = occurred_at.replace(tzinfo=timezone.utc)
    occurred_at = min(occurred_at.astimezone(timezone.utc), datetime.now(timezone.utc))
    await upsert_fact(UserFact(
        user_id=user_id,
        fact_type="past_attempt_history",
        fact_key="latest_relapse",
        fact_value=occurred_at.isoformat(),
        confidence=1.0,
    ))
    logger.info("relapse_event_recorded", user_id=user_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
