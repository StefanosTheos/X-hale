"""
Behavioral signal extraction for the Relapse-Risk Agent.
Reads Appwrite metadata to detect declining engagement patterns.

Signals tracked:
  - days_since_last_login: derived from user document updatedAt
  - missed_diary_days_last_14: 14 - unique diary days in last 14 calendar days
  - milestone_gap: expected milestones at current stage - actual milestones completed
  - achievement_gap: same for achievements
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from dataclasses import dataclass
from typing import Optional

from app.tools.user_profile import get_user_profile
from app.tools.diary_retrieval import get_recent_diary_entries
from app.memory.conversation_store import get_recent_turns
from app.memory.user_facts_store import get_facts
from app.observability.logging import get_logger

logger = get_logger(__name__)


@dataclass
class BehavioralSignals:
    user_id: str
    days_since_last_activity: Optional[int] = None
    missed_diary_days_last_14: Optional[int] = None
    milestone_completion_rate: Optional[float] = None
    relapse_flag: bool = False
    relapse_recorded_at: Optional[datetime] = None
    risk_score: float = 0.0  # Non-clinical support-priority heuristic.

    def to_prompt_snippet(self) -> str:
        lines = [
            "Days since last recorded activity: "
            + (str(self.days_since_last_activity) if self.days_since_last_activity is not None else "unknown"),
            "Missed diary entries (last 14 days): "
            + (f"{self.missed_diary_days_last_14}/14" if self.missed_diary_days_last_14 is not None else "unknown/not an established habit"),
            "Milestone completion rate: "
            + (f"{self.milestone_completion_rate:.0%}" if self.milestone_completion_rate is not None else "unknown"),
        ]
        if self.relapse_flag:
            when = self.relapse_recorded_at.isoformat() if self.relapse_recorded_at else "this conversation"
            lines.append(f"User explicitly reported a relapse ({when}).")
        lines.append("This score prioritises supportive follow-up; it is not a clinical risk prediction.")
        return "\n".join(lines)


def _days_since(value: datetime, now: datetime) -> int:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return max(0, (now - value.astimezone(timezone.utc)).days)


async def get_behavioral_signals(
    user_id: str,
    *,
    explicit_relapse_report: bool = False,
    now: datetime | None = None,
) -> BehavioralSignals:
    """
    Compute behavioral signals for a user.
    All signals degrade gracefully if data is unavailable.
    """
    profile, diary_entries, recent_turns, relapse_facts = await asyncio.gather(
        get_user_profile(user_id),
        get_recent_diary_entries(user_id, days=14, limit=50, raise_on_error=True),
        get_recent_turns(user_id, limit=1),
        get_facts(user_id, fact_type="past_attempt_history"),
        return_exceptions=True,
    )

    signals = BehavioralSignals(user_id=user_id)
    current_time = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    activity_times: list[datetime] = []

    if not isinstance(profile, Exception):
        if profile.record_updated_at:
            activity_times.append(profile.record_updated_at)

        if profile.num_milestones_completed is not None and profile.days_quit > 0:
            # Engagement indicator only; not a validated clinical measure.
            expected = max(1, profile.days_quit // 7)
            actual = profile.num_milestones_completed
            signals.milestone_completion_rate = min(1.0, actual / expected)

    if not isinstance(diary_entries, Exception):
        if diary_entries:
            activity_times.extend(e.created_at for e in diary_entries)
        established_diary_habit = bool(
            not isinstance(profile, Exception)
            and (profile.num_diary_entries >= 3 or len(diary_entries) >= 3)
        )
        if established_diary_habit:
            unique_days = len({e.created_at.date() for e in diary_entries})
            signals.missed_diary_days_last_14 = max(0, 14 - unique_days)

    if not isinstance(recent_turns, Exception) and recent_turns:
        activity_times.extend(t.timestamp for t in recent_turns)

    if activity_times:
        signals.days_since_last_activity = _days_since(max(activity_times), current_time)

    signals.relapse_flag = explicit_relapse_report
    if not isinstance(relapse_facts, Exception):
        matching = [f for f in relapse_facts if f.fact_key == "latest_relapse"]
        for fact in matching:
            try:
                occurred = datetime.fromisoformat(fact.fact_value.replace("Z", "+00:00"))
                if occurred.tzinfo is None:
                    occurred = occurred.replace(tzinfo=timezone.utc)
                if signals.relapse_recorded_at is None or occurred > signals.relapse_recorded_at:
                    signals.relapse_recorded_at = occurred
            except (ValueError, AttributeError):
                logger.warning("invalid_relapse_fact", user_id=user_id, fact_id=fact.fact_id)
        if signals.relapse_recorded_at and _days_since(signals.relapse_recorded_at, current_time) <= 14:
            signals.relapse_flag = True

    # Conservative, non-clinical support-priority score. Unknown data adds no risk.
    risk = 0.0
    if signals.days_since_last_activity is not None and signals.days_since_last_activity > 7:
        risk += 0.2
    elif signals.days_since_last_activity is not None and signals.days_since_last_activity > 3:
        risk += 0.1
    if signals.missed_diary_days_last_14 is not None and signals.missed_diary_days_last_14 > 10:
        risk += 0.1
    if signals.relapse_flag:
        risk += 0.7
    signals.risk_score = min(1.0, risk)

    return signals
