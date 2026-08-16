"""
Read-only access to the user's profile from the Appwrite users collection.
The chatbot reads this at turn start to ground responses in actual user state.
No writes happen here — profile is owned by the Flutter app.
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone

from appwrite.client import Client
from appwrite.query import Query
from appwrite.services.tables_db import TablesDB

from app.config import settings
from app.models.user_facts import UserProfile
from app.observability.logging import get_logger

logger = get_logger(__name__)


def _parse_datetime(value: object) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def _build_db() -> tuple[TablesDB, str]:
    client = Client()
    (
        client
        .set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_key(settings.appwrite_api_key)
    )
    return TablesDB(client), settings.appwrite_database_id


async def get_user_profile(user_id: str) -> UserProfile:
    """
    Fetch the user document from Appwrite and return a UserProfile.
    Falls back to a minimal profile if the document is not found.
    """
    db, db_id = _build_db()
    try:
        result = await asyncio.to_thread(
            db.list_rows,
            db_id,
            settings.appwrite_users_collection_id,
            queries=[Query.equal("userId", user_id)],
        )
        docs = result.rows
    except Exception as exc:
        logger.warning("user_profile_fetch_failed", user_id=user_id, error=str(exc))
        return UserProfile(user_id=user_id)

    if not docs:
        logger.warning("user_profile_fetch_failed", user_id=user_id, error="no document found")
        return UserProfile(user_id=user_id)

    # SDK v19+: user-defined fields are in doc.data (dict)
    d = docs[0].data if isinstance(docs[0].data, dict) else {}

    quit_date = _parse_datetime(d.get("quitDate"))

    days_quit = 0
    if quit_date:
        delta = datetime.now(timezone.utc) - quit_date
        days_quit = max(0, delta.days)

    return UserProfile(
        user_id=user_id,
        name=d.get("name", "there"),
        quit_date=quit_date,
        days_quit=days_quit,
        cigs_per_day=d.get("cigarettesPerDay", d.get("cigsPerDay", 0)),
        cigs_per_pack=d.get("cigarettesPerPack", d.get("cigsPerPack", 20)),
        price_per_pack=float(d.get("pricePerPack", 0)),
        years_smoking=d.get("yearsSmoking", 0),
        total_cigs_avoided=d.get("totalCigsAvoided", 0),
        money_saved=float(d.get("moneySaved", 0)),
        num_achievements=d.get("achievementsCount", d.get("numAchievements", 0)),
        num_milestones_completed=d.get("numMilestonesCompleted", 0),
        num_diary_entries=d.get("diaryCount", d.get("numDiaryEntries", 0)),
        num_health_benefits_reached=d.get("numHealthBenefit", 0),
        locale=d.get("language") or d.get("locale") or "en",
        record_created_at=_parse_datetime(docs[0].createdat),
        record_updated_at=_parse_datetime(docs[0].updatedat),
    )
