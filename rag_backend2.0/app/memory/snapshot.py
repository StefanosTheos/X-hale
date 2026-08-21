"""
UserMemorySnapshot builder.

Assembles the full in-context memory object for a single turn by pulling:
  1. User profile from Appwrite users collection (via tools/user_profile)
  2. Recent conversation turns from conversation_store
  3. Top user facts from user_facts_store (ordered by confidence desc)
"""
from __future__ import annotations

import asyncio
import re

from app.models.user_facts import UserMemorySnapshot
from app.observability.logging import get_logger

logger = get_logger(__name__)


_TOKEN_RE = re.compile(r"[a-z0-9]+")
_MEDICAL_TERMS = frozenset({
    "medical", "medicine", "medication", "nicotine", "patch", "gum", "dose",
    "symptom", "cough", "pain", "breath", "blood", "heart", "lung", "doctor",
})


def rank_facts(facts, query: str, limit: int, *, allow_undated: bool = False):
    """Select a small, query-relevant fact set; confidence breaks ties."""
    query_tokens = set(_TOKEN_RE.findall(query.casefold()))
    medical_query = bool(query_tokens & _MEDICAL_TERMS)
    ranked = []
    for fact in facts:
        from app.memory.fact_freshness import is_fact_stale
        undated = fact.first_observed is None and fact.last_confirmed is None
        if fact.superseded_by or (is_fact_stale(fact) and not (allow_undated and undated)):
            continue
        # Medical and medication memories must not leak into unrelated replies.
        if not medical_query and fact.fact_type in {"nrt_use", "physical_symptom_reported"}:
            continue
        fact_tokens = set(_TOKEN_RE.findall(
            f"{fact.fact_key} {fact.fact_value}".casefold()
        ))
        overlap = len(query_tokens & fact_tokens) / max(1, len(query_tokens))
        # Retain only material lexical matches. Very high-confidence facts receive
        # a small tie-break, never enough to make an unrelated fact relevant.
        if overlap <= 0:
            continue
        ranked.append((overlap, fact.confidence, fact))
    ranked.sort(key=lambda item: (item[0], item[1]), reverse=True)
    return [item[2] for item in ranked[:limit]]


async def build_snapshot(user_id: str, query: str = "") -> UserMemorySnapshot:
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

    # Rank by relevance first, then confidence. Empty queries are used by memory
    # management endpoints and retain the historical confidence ordering.
    from app.config import settings
    if query.strip():
        sorted_facts = rank_facts(facts, query, min(5, settings.max_user_facts))
    else:
        sorted_facts = sorted(facts, key=lambda f: f.confidence, reverse=True)[: settings.max_user_facts]

    return UserMemorySnapshot(
        user_id=user_id,
        profile=profile,
        recent_turns=turns,
        top_facts=sorted_facts,
    )
