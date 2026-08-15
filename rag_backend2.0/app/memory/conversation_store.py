"""
Appwrite-backed chronological conversation history.

Collection: chatbot_messages
Attributes (create in Appwrite Console):
  - userId       (string, required, index)
  - role         (string enum: "user" | "assistant", required)
  - content      (string, required, size 8000)
  - timestamp    (datetime, required, index)
  - turn_id      (string, required, unique)
  - citations    (string, optional, size 4000)  ← JSON array of Citation dicts

Composite index: (userId ASC, timestamp DESC) for efficient recent-history fetches.
"""
from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone

from appwrite.client import Client
from appwrite.id import ID
from appwrite.query import Query
from appwrite.services.tables_db import TablesDB

from app.config import settings
from app.models.user_facts import ConversationTurn
from app.observability.logging import get_logger

logger = get_logger(__name__)


def _build_client() -> tuple[TablesDB, str]:
    """Build an Appwrite TablesDB client using the server API key."""
    client = Client()
    (
        client
        .set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_key(settings.appwrite_api_key)
    )
    return TablesDB(client), settings.appwrite_database_id


def _turn_from_row(row: object, user_id: str) -> ConversationTurn:
    """Convert an Appwrite row to the domain model used by history/export."""
    d = row.data if isinstance(row.data, dict) else {}
    citations_raw = d.get("citations", "[]")
    try:
        parsed = json.loads(citations_raw) if isinstance(citations_raw, str) else []
        citations = parsed.get("c", []) if isinstance(parsed, dict) else parsed
    except json.JSONDecodeError:
        citations = []
    return ConversationTurn(
        turn_id=d.get("turn_id", row.id),
        user_id=user_id,
        role=d["role"],
        content=d["content"],
        timestamp=datetime.fromisoformat(d["timestamp"]),
        citations=citations,
    )


async def append_turn(
    user_id: str,
    role: str,
    content: str,
    citations: list[dict] | None = None,
    turn_id: str | None = None,
) -> str:
    """
    Append one conversation turn to the chatbot_messages collection.
    Returns the turn_id.
    """
    import asyncio
    tid = turn_id or str(uuid.uuid4())
    db, db_id = _build_client()
    data = {
        "userId": user_id,
        "role": role,
        "content": content,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "turn_id": tid,
        "citations": json.dumps(citations or []),
    }
    await asyncio.to_thread(
        db.create_row,
        db_id,
        settings.appwrite_chat_messages_collection_id,
        ID.unique(),
        data,
    )
    return tid


async def get_recent_turns(user_id: str, limit: int | None = None) -> list[ConversationTurn]:
    """
    Return the most recent `limit` turns for the user, ordered oldest→newest.
    Default limit comes from settings.max_conversation_turns.
    """
    import asyncio
    n = limit or settings.max_conversation_turns
    db, db_id = _build_client()
    result = await asyncio.to_thread(
        db.list_rows,
        db_id,
        settings.appwrite_chat_messages_collection_id,
        queries=[
            Query.equal("userId", user_id),
            Query.order_desc("timestamp"),
            Query.limit(n),
        ],
    )
    docs = result.rows
    # Reverse to get oldest-first order
    docs = list(reversed(docs))
    return [_turn_from_row(doc, user_id) for doc in docs]


async def get_all_turns(user_id: str, page_size: int = 100) -> list[ConversationTurn]:
    """Return every conversation turn for export, oldest first, using cursor pagination."""
    import asyncio
    if not 1 <= page_size <= 100:
        raise ValueError("page_size must be between 1 and 100")
    db, db_id = _build_client()
    turns: list[ConversationTurn] = []
    cursor: str | None = None
    while True:
        queries = [
            Query.equal("userId", user_id),
            Query.order_asc("timestamp"),
            Query.limit(page_size),
        ]
        if cursor is not None:
            queries.append(Query.cursor_after(cursor))
        result = await asyncio.to_thread(
            db.list_rows,
            db_id,
            settings.appwrite_chat_messages_collection_id,
            queries=queries,
        )
        rows = result.rows
        turns.extend(_turn_from_row(row, user_id) for row in rows)
        if len(rows) < page_size:
            break
        cursor = rows[-1].id
    return turns


async def delete_history(user_id: str) -> int:
    """
    Delete all conversation turns for a user.
    Returns the number of documents deleted.
    """
    import asyncio
    db, db_id = _build_client()
    deleted = 0
    while True:
        result = await asyncio.to_thread(
            db.list_rows,
            db_id,
            settings.appwrite_chat_messages_collection_id,
            queries=[Query.equal("userId", user_id), Query.limit(100)],
        )
        docs = result.rows
        if not docs:
            break
        await asyncio.gather(*[
            asyncio.to_thread(
                db.delete_row,
                db_id,
                settings.appwrite_chat_messages_collection_id,
                doc.id,
            )
            for doc in docs
        ])
        deleted += len(docs)
    logger.info("conversation_history_deleted", user_id=user_id, count=deleted)
    return deleted
