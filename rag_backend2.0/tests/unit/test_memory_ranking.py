from datetime import datetime, timedelta, timezone

from app.memory.snapshot import rank_facts
from app.models.user_facts import UserFact


def _fact(kind, key, value, confidence=0.9, **kwargs):
    return UserFact(
        user_id="u1", fact_type=kind, fact_key=key, fact_value=value,
        confidence=confidence, **kwargs,
    )


def test_memory_ranking_prefers_relevance_over_global_confidence():
    now = datetime.now(timezone.utc)
    facts = [
        _fact("trigger", "coffee", "Morning coffee triggers cravings", 0.99, last_confirmed=now),
        _fact("trigger", "work_stress", "A difficult workday triggers cravings", 0.80, last_confirmed=now),
    ]
    selected = rank_facts(facts, "Work was difficult today", 5)
    assert [fact.fact_key for fact in selected] == ["work_stress"]


def test_memory_ranking_excludes_stale_superseded_and_unrelated_medical_facts():
    now = datetime.now(timezone.utc)
    facts = [
        _fact("trigger", "old_work", "Work triggers cravings", last_confirmed=now - timedelta(days=200)),
        _fact("trigger", "superseded_work", "Work never triggers cravings", last_confirmed=now, superseded_by="new"),
        _fact("physical_symptom_reported", "work_cough", "Cough at work", last_confirmed=now),
        _fact("trigger", "current_work", "Work stress triggers cravings", last_confirmed=now),
    ]
    selected = rank_facts(facts, "Work was stressful", 5)
    assert [fact.fact_key for fact in selected] == ["current_work"]
