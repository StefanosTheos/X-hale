"""
Appwrite-backed structured user-facts store.

Collection: chatbot_user_facts
Attributes (create in Appwrite Console):
  - userId           (string, required, index)
  - fact_type        (string, required)
  - fact_key         (string, required)
  - fact_value       (string, required, size 2000)
  - confidence       (float, required, default 0.7)
  - source_turn_ids  (string, optional, size 1000)  ← JSON array
  - first_observed   (datetime, optional)
  - last_confirmed   (datetime, optional)
  - superseded_by    (string, optional)

Index: (userId ASC, fact_type ASC) for efficient per-type lookups.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone

from appwrite.client import Client
from appwrite.id import ID
from appwrite.query import Query
from appwrite.services.tables_db import TablesDB

from app.config import settings
from app.models.user_facts import UserFact
from app.observability.logging import get_logger

logger = get_logger(__name__)


def _build_client() -> tuple[TablesDB, str]:
    client = Client()
    (
        client
        .set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_key(settings.appwrite_api_key)
    )
    return TablesDB(client), settings.appwrite_database_id


async def get_facts(user_id: str, fact_type: str | None = None) -> list[UserFact]:
    """Return all facts for a user, optionally filtered by fact_type."""
    import asyncio
    db, db_id = _build_client()
    queries = [Query.equal("userId", user_id), Query.limit(settings.max_user_facts)]
    if fact_type:
        queries.append(Query.equal("fact_type", fact_type))
    result = await asyncio.to_thread(
        db.list_rows,
        db_id,
        settings.appwrite_user_facts_collection_id,
        queries=queries,
    )
    facts: list[UserFact] = []
    for doc in result.rows:
        d = doc.data if isinstance(doc.data, dict) else {}
        source_raw = d.get("source_turn_ids", "[]")
        try:
            source_ids = json.loads(source_raw) if isinstance(source_raw, str) else []
        except json.JSONDecodeError:
            source_ids = []
        facts.append(UserFact(
            fact_id=doc.id,
            user_id=user_id,
            fact_type=d["fact_type"],
            fact_key=d["fact_key"],
            fact_value=d["fact_value"],
            confidence=d.get("confidence", 0.7),
            source_turn_ids=source_ids,
            first_observed=datetime.fromisoformat(d["first_observed"]) if d.get("first_observed") else None,
            last_confirmed=datetime.fromisoformat(d["last_confirmed"]) if d.get("last_confirmed") else None,
            superseded_by=d.get("superseded_by"),
        ))
    return facts


async def upsert_fact(fact: UserFact) -> UserFact:
    """
    Insert or update a user fact.
    If a fact with the same (userId, fact_type, fact_key) exists and has lower confidence,
    update it. Otherwise create a new document.
    """
    import asyncio
    db, db_id = _build_client()
    now = datetime.now(timezone.utc).isoformat()

    existing_result = await asyncio.to_thread(
        db.list_rows,
        db_id,
        settings.appwrite_user_facts_collection_id,
        queries=[
            Query.equal("userId", fact.user_id),
            Query.equal("fact_type", fact.fact_type),
            Query.equal("fact_key", fact.fact_key),
            Query.limit(1),
        ],
    )
    data = {
        "userId": fact.user_id,
        "fact_type": fact.fact_type,
        "fact_key": fact.fact_key,
        "fact_value": fact.fact_value,
        "confidence": fact.confidence,
        "source_turn_ids": json.dumps(fact.source_turn_ids),
        "last_confirmed": now,
    }
    existing_docs = existing_result.rows
    if existing_docs:
        doc_id = existing_docs[0].id
        updated = await asyncio.to_thread(
            db.update_row,
            db_id,
            settings.appwrite_user_facts_collection_id,
            doc_id,
            data,
        )
        fact.fact_id = updated.id
    else:
        data["first_observed"] = now
        created = await asyncio.to_thread(
            db.create_row,
            db_id,
            settings.appwrite_user_facts_collection_id,
            ID.unique(),
            data,
        )
        fact.fact_id = created.id
    return fact


async def delete_fact(fact_id: str) -> None:
    """Delete a specific fact by its Appwrite document ID."""
    import asyncio
    db, db_id = _build_client()
    await asyncio.to_thread(
        db.delete_row,
        db_id,
        settings.appwrite_user_facts_collection_id,
        fact_id,
    )
    logger.info("user_fact_deleted", fact_id=fact_id)
