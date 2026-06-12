"""
Read-only access to the user's unlocked achievements from Appwrite.
Used by the Synthesizer to personalise responses with milestone context.
"""
from __future__ import annotations

import asyncio

from appwrite.client import Client
from appwrite.query import Query
from appwrite.services.tables_db import TablesDB

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)


def _build_db() -> tuple[TablesDB, str]:
    client = Client()
    (
        client
        .set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_key(settings.appwrite_api_key)
    )
    return TablesDB(client), settings.appwrite_database_id


async def get_recent_achievements(user_id: str, limit: int = 5) -> list[dict]:
    """Return the most recently unlocked achievements for a user."""
    db, db_id = _build_db()
    try:
        result = await asyncio.to_thread(
            db.list_rows,
            db_id,
            settings.appwrite_achievements_collection_id,
            queries=[
                Query.equal("userId", user_id),
                Query.order_desc("$createdAt"),
                Query.limit(limit),
            ],
        )
        achievements = []
        for doc in result.rows:
            d = doc.data if isinstance(doc.data, dict) else {}
            achievements.append({
                "name": d.get("achievementName", d.get("name", "Unknown")),
                "category": d.get("category", ""),
                "tier": d.get("tier", ""),
                "unlocked_at": doc.createdat,
            })
        return achievements
    except Exception as exc:
        logger.warning("achievement_fetch_failed", user_id=user_id, error=str(exc))
        return []
