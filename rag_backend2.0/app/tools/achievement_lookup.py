"""
Read-only access to the user's unlocked achievements from Appwrite.
Used by the Synthesizer to personalise responses with milestone context.
"""
from __future__ import annotations

import asyncio

from appwrite.client import Client
from appwrite.query import Query
from appwrite.services.databases import Databases

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)


def _build_db() -> tuple[Databases, str]:
    client = Client()
    (
        client
        .set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_key(settings.appwrite_api_key)
    )
    return Databases(client), settings.appwrite_database_id


async def get_recent_achievements(user_id: str, limit: int = 5) -> list[dict]:
    """Return the most recently unlocked achievements for a user."""
    db, db_id = _build_db()
    try:
        result = await asyncio.to_thread(
            db.list_documents,
            db_id,
            settings.appwrite_achievements_collection_id,
            queries=[
                Query.equal("userId", user_id),
                Query.order_desc("$createdAt"),
                Query.limit(limit),
            ],
        )
        return [
            {
                "name": doc.get("achievementName", doc.get("name", "Unknown")),
                "category": doc.get("category", ""),
                "tier": doc.get("tier", ""),
                "unlocked_at": doc.get("$createdAt", ""),
            }
            for doc in result["documents"]
        ]
    except Exception as exc:
        logger.warning("achievement_fetch_failed", user_id=user_id, error=str(exc))
        return []
