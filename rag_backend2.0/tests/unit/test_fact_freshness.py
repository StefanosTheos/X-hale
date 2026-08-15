"""Expiry boundaries for derived conversational memory."""
from datetime import datetime, timedelta, timezone

from app.memory.fact_freshness import FACT_TTL_DAYS, fact_expires_at, is_fact_stale
from app.models.user_facts import UserFact


def _fact(fact_type="trigger", confirmed=None):
    return UserFact(
        user_id="u1",
        fact_type=fact_type,
        fact_key="key",
        fact_value="value",
        last_confirmed=confirmed,
    )


def test_fact_is_fresh_until_exact_expiry_boundary():
    confirmed = datetime(2026, 1, 1, tzinfo=timezone.utc)
    fact = _fact(confirmed=confirmed)
    expiry = confirmed + timedelta(days=FACT_TTL_DAYS["trigger"])

    assert fact_expires_at(fact) == expiry
    assert not is_fact_stale(fact, now=expiry - timedelta(microseconds=1))
    assert is_fact_stale(fact, now=expiry)


def test_missing_legacy_timestamp_requires_reconfirmation():
    assert is_fact_stale(_fact())


def test_sensitive_dynamic_fact_has_shorter_ttl_than_historical_fact():
    assert FACT_TTL_DAYS["physical_symptom_reported"] < FACT_TTL_DAYS["past_attempt_history"]
