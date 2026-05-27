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
from appwrite.services.databases import Databases

from app.config import settings
from app.models.user_facts import ConversationTurn
from app.observability.logging import get_logger

logger = get_logger(__name__)


def _build_client() -> tuple[Databases, str]:
    """Build an Appwrite Databases client using the server API key."""
    client = Client()
    (
        client
        .set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_key(settings.appwrite_api_key)
    )
    return Databases(client), settings.appwrite_database_id


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
        db.create_document,
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
        db.list_documents,
        db_id,
        settings.appwrite_chat_messages_collection_id,
        queries=[
            Query.equal("userId", user_id),
            Query.order_desc("timestamp"),
            Query.limit(n),
        ],
    )
    # SDK v19+: result.documents is a list of Document objects;
    # user-defined fields live in doc.data (dict), system fields on doc directly.
    docs = result.documents
    # Reverse to get oldest-first order
    docs = list(reversed(docs))
    turns: list[ConversationTurn] = []
    for doc in docs:
        d = doc.data if isinstance(doc.data, dict) else {}
        citations_raw = d.get("citations", "[]")
        try:
            citations = json.loads(citations_raw) if isinstance(citations_raw, str) else []
        except json.JSONDecodeError:
            citations = []
        turns.append(ConversationTurn(
            turn_id=d.get("turn_id", doc.id),
            user_id=user_id,
            role=d["role"],
            content=d["content"],
            timestamp=datetime.fromisoformat(d["timestamp"]),
            citations=citations,
        ))
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
            db.list_documents,
            db_id,
            settings.appwrite_chat_messages_collection_id,
            queries=[Query.equal("userId", user_id), Query.limit(100)],
        )
        docs = result.documents
        if not docs:
            break
        for doc in docs:
            await asyncio.to_thread(
                db.delete_document,
                db_id,
                settings.appwrite_chat_messages_collection_id,
                doc.id,
            )
            deleted += 1
    logger.info("conversation_history_deleted", user_id=user_id, count=deleted)
    return deleted
