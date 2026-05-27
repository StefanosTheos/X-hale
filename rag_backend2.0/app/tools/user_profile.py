"""
Read-only access to the user's profile from the Appwrite users collection.
The chatbot reads this at turn start to ground responses in actual user state.
No writes happen here — profile is owned by the Flutter app.
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone

from appwrite.client import Client
from appwrite.services.databases import Databases

from app.config import settings
from app.models.user_facts import UserProfile
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


async def get_user_profile(user_id: str) -> UserProfile:
    """
    Fetch the user document from Appwrite and return a UserProfile.
    Falls back to a minimal profile if the document is not found.
    """
    db, db_id = _build_db()
    try:
        doc = await asyncio.to_thread(
            db.get_document,
            db_id,
            settings.appwrite_users_collection_id,
            user_id,
        )
    except Exception as exc:
        logger.warning("user_profile_fetch_failed", user_id=user_id, error=str(exc))
        return UserProfile(user_id=user_id)

    quit_date: datetime | None = None
    if doc.get("quitDate"):
        try:
            quit_date = datetime.fromisoformat(doc["quitDate"].replace("Z", "+00:00"))
        except (ValueError, AttributeError):
            pass

    days_quit = 0
    if quit_date:
        delta = datetime.now(timezone.utc) - quit_date
        days_quit = max(0, delta.days)

    return UserProfile(
        user_id=user_id,
        name=doc.get("name", "there"),
        quit_date=quit_date,
        days_quit=days_quit,
        cigs_per_day=doc.get("cigsPerDay", 0),
        cigs_per_pack=doc.get("cigsPerPack", 20),
        price_per_pack=float(doc.get("pricePerPack", 0)),
        years_smoking=doc.get("yearsSmoking", 0),
        total_cigs_avoided=doc.get("totalCigsAvoided", 0),
        money_saved=float(doc.get("moneySaved", 0)),
        num_achievements=doc.get("numAchievements", 0),
        num_milestones_completed=doc.get("numMilestonesCompleted", 0),
        num_diary_entries=doc.get("numDiaryEntries", 0),
        num_health_benefits_reached=doc.get("numHealthBenefit", 0),
        locale=doc.get("locale", "en"),
    )
