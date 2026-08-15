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
from app.memory.fact_freshness import is_fact_stale
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


def _fact_from_row(row: object, user_id: str) -> UserFact:
    """Convert an Appwrite row to a structured fact without dropping provenance."""
    d = row.data if isinstance(row.data, dict) else {}
    source_raw = d.get("source_turn_ids", "[]")
    try:
        source_ids = json.loads(source_raw) if isinstance(source_raw, str) else []
    except json.JSONDecodeError:
        source_ids = []
    return UserFact(
        fact_id=row.id,
        user_id=user_id,
        fact_type=d["fact_type"],
        fact_key=d["fact_key"],
        fact_value=d["fact_value"],
        confidence=d.get("confidence", 0.7),
        source_turn_ids=source_ids,
        first_observed=datetime.fromisoformat(d["first_observed"]) if d.get("first_observed") else None,
        last_confirmed=datetime.fromisoformat(d["last_confirmed"]) if d.get("last_confirmed") else None,
        superseded_by=d.get("superseded_by"),
    )


async def get_facts(
    user_id: str,
    fact_type: str | None = None,
    *,
    include_stale: bool = False,
) -> list[UserFact]:
    """Return non-superseded facts, excluding stale facts unless requested."""
    import asyncio
    db, db_id = _build_client()
    queries = [
        Query.equal("userId", user_id),
        Query.is_null("superseded_by"),
        Query.limit(settings.max_user_facts),
    ]
    if fact_type:
        queries.append(Query.equal("fact_type", fact_type))
    result = await asyncio.to_thread(
        db.list_rows,
        db_id,
        settings.appwrite_user_facts_collection_id,
        queries=queries,
    )
    facts = [_fact_from_row(doc, user_id) for doc in result.rows]
    if include_stale:
        return facts
    return [fact for fact in facts if not is_fact_stale(fact)]


async def get_all_facts(user_id: str, page_size: int = 100) -> list[UserFact]:
    """Return every active and superseded fact for export using cursor pagination."""
    import asyncio
    if not 1 <= page_size <= 100:
        raise ValueError("page_size must be between 1 and 100")
    db, db_id = _build_client()
    facts: list[UserFact] = []
    cursor: str | None = None
    while True:
        queries = [
            Query.equal("userId", user_id),
            Query.order_asc("$createdAt"),
            Query.limit(page_size),
        ]
        if cursor is not None:
            queries.append(Query.cursor_after(cursor))
        result = await asyncio.to_thread(
            db.list_rows,
            db_id,
            settings.appwrite_user_facts_collection_id,
            queries=queries,
        )
        rows = result.rows
        facts.extend(_fact_from_row(row, user_id) for row in rows)
        if len(rows) < page_size:
            break
        cursor = rows[-1].id
    return facts


async def upsert_fact(fact: UserFact) -> UserFact:
    """
    Insert or update a user fact.
    Identical values are confirmations: sources are merged and confidence never falls.
    A conflicting value replaces the active fact only when its confidence is higher;
    the previous row is retained and linked through ``superseded_by`` for auditability.
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
            Query.is_null("superseded_by"),
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
        existing = existing_docs[0]
        existing_data = existing.data if isinstance(existing.data, dict) else {}
        existing_confidence = float(existing_data.get("confidence", 0.7))
        if existing_data.get("fact_value") == fact.fact_value:
            try:
                old_sources = json.loads(existing_data.get("source_turn_ids", "[]"))
            except (json.JSONDecodeError, TypeError):
                old_sources = []
            data["source_turn_ids"] = json.dumps(list(dict.fromkeys(old_sources + fact.source_turn_ids)))
            data["confidence"] = max(existing_confidence, fact.confidence)
            updated = await asyncio.to_thread(
                db.update_row, db_id, settings.appwrite_user_facts_collection_id, existing.id, data,
            )
            fact.fact_id = updated.id
            fact.confidence = data["confidence"]
        elif fact.confidence <= existing_confidence:
            fact.fact_id = existing.id
            fact.fact_value = existing_data.get("fact_value", fact.fact_value)
            fact.confidence = existing_confidence
            logger.info("user_fact_replacement_rejected", fact_id=existing.id)
            return fact
        else:
            data["first_observed"] = now
            created = await asyncio.to_thread(
                db.create_row, db_id, settings.appwrite_user_facts_collection_id, ID.unique(), data,
            )
            try:
                await asyncio.to_thread(
                    db.update_row,
                    db_id,
                    settings.appwrite_user_facts_collection_id,
                    existing.id,
                    {"superseded_by": created.id},
                )
            except Exception:
                # Avoid leaving two active values if the audit-link write fails.
                await asyncio.to_thread(
                    db.delete_row, db_id, settings.appwrite_user_facts_collection_id, created.id,
                )
                raise
            fact.fact_id = created.id
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


async def delete_fact(fact_id: str, user_id: str | None = None) -> None:
    """Delete a fact, optionally enforcing ownership before deletion."""
    import asyncio
    db, db_id = _build_client()
    if user_id is not None:
        row = await asyncio.to_thread(
            db.get_row, db_id, settings.appwrite_user_facts_collection_id, fact_id,
        )
        data = row.data if isinstance(row.data, dict) else {}
        if data.get("userId") != user_id:
            raise PermissionError("fact does not belong to authenticated user")
    await asyncio.to_thread(
        db.delete_row,
        db_id,
        settings.appwrite_user_facts_collection_id,
        fact_id,
    )
    logger.info("user_fact_deleted", fact_id=fact_id)


async def confirm_fact(fact_id: str, user_id: str) -> UserFact:
    """Reconfirm an existing active fact after enforcing user ownership."""
    import asyncio
    db, db_id = _build_client()
    row = await asyncio.to_thread(
        db.get_row, db_id, settings.appwrite_user_facts_collection_id, fact_id,
    )
    data = row.data if isinstance(row.data, dict) else {}
    if data.get("userId") != user_id or data.get("superseded_by"):
        raise PermissionError("fact is unavailable or does not belong to authenticated user")
    updated = await asyncio.to_thread(
        db.update_row,
        db_id,
        settings.appwrite_user_facts_collection_id,
        fact_id,
        {"last_confirmed": datetime.now(timezone.utc).isoformat()},
    )
    logger.info("user_fact_reconfirmed", user_id=user_id, fact_id=fact_id)
    return _fact_from_row(updated, user_id)


async def delete_all_facts(user_id: str) -> int:
    """Delete every fact belonging to user_id. Returns the count deleted."""
    import asyncio
    db, db_id = _build_client()
    count = 0
    while True:
        result = await asyncio.to_thread(
            db.list_rows,
            db_id,
            settings.appwrite_user_facts_collection_id,
            queries=[Query.equal("userId", user_id), Query.limit(100)],
        )
        if not result.rows:
            break
        for doc in result.rows:
            await asyncio.to_thread(
                db.delete_row, db_id, settings.appwrite_user_facts_collection_id, doc.id,
            )
            count += 1
    logger.info("all_user_facts_deleted", user_id=user_id, count=count)
    return count
