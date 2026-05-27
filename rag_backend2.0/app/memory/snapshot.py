"""
UserMemorySnapshot builder.

Assembles the full in-context memory object for a single turn by pulling:
  1. User profile from Appwrite users collection (via tools/user_profile)
  2. Recent conversation turns from conversation_store
  3. Top user facts from user_facts_store (ordered by confidence desc)
"""
from __future__ import annotations

import asyncio

from app.models.user_facts import UserMemorySnapshot
from app.observability.logging import get_logger

logger = get_logger(__name__)


async def build_snapshot(user_id: str) -> UserMemorySnapshot:
    """
    Load profile, recent turns, and top facts concurrently.
    Returns a UserMemorySnapshot ready for injection into prompts.
    """
    from app.tools.user_profile import get_user_profile
    from app.memory.conversation_store import get_recent_turns
    from app.memory.user_facts_store import get_facts

    profile, turns, facts = await asyncio.gather(
        get_user_profile(user_id),
        get_recent_turns(user_id),
        get_facts(user_id),
        return_exceptions=True,
    )

    # Degrade gracefully if any fetch fails
    from app.models.user_facts import UserProfile, ConversationTurn, UserFact

    if isinstance(profile, Exception):
        logger.warning("snapshot_profile_fetch_failed", error=str(profile))
        from app.config import settings as s
        profile = UserProfile(user_id=user_id)

    if isinstance(turns, Exception):
        logger.warning("snapshot_turns_fetch_failed", error=str(turns))
        turns = []

    if isinstance(facts, Exception):
        logger.warning("snapshot_facts_fetch_failed", error=str(facts))
        facts = []

    # Sort facts by confidence descending
    from app.config import settings
    sorted_facts = sorted(facts, key=lambda f: f.confidence, reverse=True)[: settings.max_user_facts]

    return UserMemorySnapshot(
        user_id=user_id,
        profile=profile,
        recent_turns=turns,
        top_facts=sorted_facts,
    )
