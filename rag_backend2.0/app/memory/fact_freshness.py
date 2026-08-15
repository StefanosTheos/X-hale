"""Engineering retention policy for derived conversational memory facts.

Expiry here means expiry from active personalization, not deletion.  Stale rows
remain available to the authenticated user for review, reconfirmation, export,
or erasure.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.models.user_facts import FactType, UserFact


FACT_TTL_DAYS: dict[FactType, int] = {
    "physical_symptom_reported": 30,
    "nrt_use": 30,
    "stage_of_change": 30,
    "trigger": 90,
    "coping_strategy_validated": 90,
    "coping_strategy_failed": 90,
    "social_context": 90,
    "motivation": 180,
    "past_attempt_history": 365,
}


def fact_expires_at(fact: UserFact) -> datetime | None:
    """Return the UTC expiry instant, or ``None`` for an unknown fact type."""
    anchor = fact.last_confirmed or fact.first_observed
    ttl_days = FACT_TTL_DAYS.get(fact.fact_type)
    if anchor is None or ttl_days is None:
        return None
    if anchor.tzinfo is None:
        anchor = anchor.replace(tzinfo=timezone.utc)
    return anchor.astimezone(timezone.utc) + timedelta(days=ttl_days)


def is_fact_stale(fact: UserFact, *, now: datetime | None = None) -> bool:
    """Facts without a usable timestamp are conservatively treated as stale."""
    expires_at = fact_expires_at(fact)
    if expires_at is None:
        return True
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None:
        current = current.replace(tzinfo=timezone.utc)
    return current.astimezone(timezone.utc) >= expires_at
