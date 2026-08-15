"""Retry-safe deletion of all X-hale Appwrite data owned by one user."""
from __future__ import annotations

import asyncio
from dataclasses import asdict, dataclass, field
from urllib.parse import urlparse

from appwrite.client import Client
from appwrite.query import Query
from appwrite.services.storage import Storage
from appwrite.services.tables_db import TablesDB
from appwrite.services.users import Users

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)


@dataclass
class DeletionReport:
    deleted_rows: dict[str, int] = field(default_factory=dict)
    avatar_files_deleted: int = 0
    identity_deleted: bool = False
    errors: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return asdict(self)


def _build_services() -> tuple[TablesDB, Storage, Users, str]:
    client = Client()
    (
        client.set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_key(settings.appwrite_api_key)
    )
    return TablesDB(client), Storage(client), Users(client), settings.appwrite_database_id


def _collection_ownership() -> list[tuple[str, str, tuple[str, ...]]]:
    """Deletion order keeps child/relationship rows ahead of the user profile."""
    return [
        ("challenge_entries", settings.appwrite_challenge_entries_collection_id, ("userId",)),
        ("direct_messages", settings.appwrite_direct_messages_collection_id, ("senderId", "receiverId")),
        ("friend_requests", settings.appwrite_friend_requests_collection_id, ("senderId", "receiverId")),
        ("friendships", settings.appwrite_friendships_collection_id, ("user1Id", "user2Id")),
        ("messages_misc", settings.appwrite_messages_misc_collection_id, ("userId",)),
        ("forum", settings.appwrite_forum_collection_id, ("userId",)),
        ("diary", settings.appwrite_diary_collection_id, ("userId",)),
        ("motivations", settings.appwrite_motivations_collection_id, ("userId",)),
        ("achievements", settings.appwrite_achievements_collection_id, ("userId",)),
        ("milestones", settings.appwrite_milestones_collection_id, ("userId",)),
        ("health_benefits", settings.appwrite_health_benefits_collection_id, ("userId",)),
        ("challenges", settings.appwrite_challenges_collection_id, ("userId",)),
        ("chat_messages", settings.appwrite_chat_messages_collection_id, ("userId",)),
        ("user_facts", settings.appwrite_user_facts_collection_id, ("userId",)),
        ("users", settings.appwrite_users_collection_id, ("userId",)),
    ]


async def _find_profile_icon(db: TablesDB, database_id: str, user_id: str) -> str | None:
    result = await asyncio.to_thread(
        db.list_rows,
        database_id,
        settings.appwrite_users_collection_id,
        queries=[Query.equal("userId", user_id), Query.limit(1)],
    )
    if not result.rows:
        return None
    data = result.rows[0].data if isinstance(result.rows[0].data, dict) else {}
    return data.get("profileIcon")


def _avatar_file_id(profile_icon: str | None) -> str | None:
    if not profile_icon or "/files/" not in profile_icon:
        return None
    parts = urlparse(profile_icon).path.split("/files/", 1)
    if len(parts) != 2:
        return None
    file_id = parts[1].split("/", 1)[0]
    return file_id or None


async def _delete_user_avatar_files(
    storage: Storage,
    user_id: str,
    current_file_id: str | None,
) -> int:
    """Delete current and older avatar files whose permissions identify the user."""
    owned_ids: set[str] = set()
    cursor: str | None = None
    while True:
        queries = [Query.limit(100)]
        if cursor is not None:
            queries.append(Query.cursor_after(cursor))
        result = await asyncio.to_thread(
            storage.list_files, settings.appwrite_user_avatars_bucket_id, queries=queries,
        )
        files = result.files
        for stored_file in files:
            permissions = getattr(stored_file, "permissions", []) or []
            owned = any(f'user:{user_id}' in permission for permission in permissions)
            if owned or stored_file.id == current_file_id:
                owned_ids.add(stored_file.id)
        if len(files) < 100:
            break
        cursor = files[-1].id
    for file_id in owned_ids:
        await asyncio.to_thread(
            storage.delete_file, settings.appwrite_user_avatars_bucket_id, file_id,
        )
    return len(owned_ids)


async def _delete_matching_rows(
    db: TablesDB,
    database_id: str,
    collection_id: str,
    field_name: str,
    user_id: str,
) -> int:
    """Repeatedly delete the first page; this is cursor-free and retry-safe."""
    deleted = 0
    while True:
        result = await asyncio.to_thread(
            db.list_rows,
            database_id,
            collection_id,
            queries=[Query.equal(field_name, user_id), Query.limit(100)],
        )
        if not result.rows:
            return deleted
        for row in result.rows:
            await asyncio.to_thread(db.delete_row, database_id, collection_id, row.id)
            deleted += 1


async def delete_account_data(user_id: str) -> DeletionReport:
    """Delete application rows/avatar and finally the Appwrite auth identity."""
    db, storage, users, database_id = _build_services()
    report = DeletionReport()

    required = [(name, collection_id) for name, collection_id, _ in _collection_ownership()]
    missing = [name for name, collection_id in required if not collection_id]
    if not settings.appwrite_user_avatars_bucket_id:
        missing.append("user_avatars_bucket")
    if missing:
        report.errors.append(f"missing configuration: {', '.join(missing)}")
        return report

    try:
        profile_icon = await _find_profile_icon(db, database_id, user_id)
        report.avatar_files_deleted = await _delete_user_avatar_files(
            storage, user_id, _avatar_file_id(profile_icon),
        )
    except Exception as exc:
        report.errors.append(f"avatar: {exc}")

    for name, collection_id, ownership_fields in _collection_ownership():
        count = 0
        try:
            for field_name in ownership_fields:
                count += await _delete_matching_rows(
                    db, database_id, collection_id, field_name, user_id,
                )
            report.deleted_rows[name] = count
        except Exception as exc:
            report.errors.append(f"{name}: {exc}")

    if report.errors:
        logger.error("account_data_deletion_incomplete", user_id=user_id, errors=report.errors)
        return report

    try:
        await asyncio.to_thread(users.delete, user_id)
        report.identity_deleted = True
    except Exception as exc:
        report.errors.append(f"identity: {exc}")

    if report.errors:
        logger.error("account_deletion_incomplete", user_id=user_id, errors=report.errors)
    else:
        logger.info("account_deleted", user_id=user_id, deleted_rows=report.deleted_rows)
    return report
