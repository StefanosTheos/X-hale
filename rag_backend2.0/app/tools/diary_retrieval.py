"""
Read-only access to the user's diary entries from Appwrite.
Used by the Reflection Agent (Phase 3 stub) and the Memory Curator.
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Optional

from appwrite.client import Client
from appwrite.query import Query
from appwrite.services.tables_db import TablesDB

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)


class DiaryEntry:
    def __init__(self, entry_id: str, content: str, mood: str, tags: list[str], created_at: datetime):
        self.entry_id = entry_id
        self.content = content
        self.mood = mood
        self.tags = tags
        self.created_at = created_at

    def __repr__(self) -> str:
        return f"DiaryEntry(mood={self.mood}, date={self.created_at.date()}, tags={self.tags})"


def _build_db() -> tuple[TablesDB, str]:
    client = Client()
    (
        client
        .set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_key(settings.appwrite_api_key)
    )
    return TablesDB(client), settings.appwrite_database_id


async def get_recent_diary_entries(
    user_id: str,
    days: int = 14,
    limit: int = 20,
) -> list[DiaryEntry]:
    """
    Return diary entries from the last `days` days, newest first.
    """
    db, db_id = _build_db()
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    try:
        result = await asyncio.to_thread(
            db.list_rows,
            db_id,
            settings.appwrite_diary_collection_id,
            queries=[
                Query.equal("userId", user_id),
                Query.greater_than("createdAt", since),
                Query.order_desc("createdAt"),
                Query.limit(limit),
            ],
        )
    except Exception as exc:
        logger.warning("diary_fetch_failed", user_id=user_id, error=str(exc))
        return []

    entries: list[DiaryEntry] = []
    for doc in result.rows:
        d = doc.data if isinstance(doc.data, dict) else {}
        tags_raw = d.get("tags", [])
        tags = tags_raw if isinstance(tags_raw, list) else []
        created_at = datetime.now(timezone.utc)
        try:
            created_at = datetime.fromisoformat(d.get("createdAt", "").replace("Z", "+00:00"))
        except (ValueError, AttributeError):
            pass
        entries.append(DiaryEntry(
            entry_id=doc.id,
            content=d.get("entry", d.get("content", "")),
            mood=d.get("mood", "neutral"),
            tags=tags,
            created_at=created_at,
        ))
    return entries


def summarise_entries(entries: list[DiaryEntry]) -> str:
    """
    Produce a brief text summary of diary entries for injection into agent prompts.
    """
    if not entries:
        return "(No recent diary entries)"
    lines: list[str] = [f"Recent diary entries ({len(entries)} entries):"]
    for e in entries[:10]:
        tag_str = ", ".join(e.tags[:3]) if e.tags else "no tags"
        lines.append(f"  • {e.created_at.strftime('%Y-%m-%d')} | mood: {e.mood} | tags: {tag_str}")
    return "\n".join(lines)
