"""
Behavioral signal extraction for the Relapse-Risk Agent (Phase 3 stub uses this).
Reads Appwrite metadata to detect declining engagement patterns.

Signals tracked:
  - days_since_last_login: derived from user document updatedAt
  - missed_diary_days_last_14: 14 - unique diary days in last 14 calendar days
  - milestone_gap: expected milestones at current stage - actual milestones completed
  - achievement_gap: same for achievements
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from dataclasses import dataclass

from app.tools.user_profile import get_user_profile
from app.tools.diary_retrieval import get_recent_diary_entries
from app.observability.logging import get_logger

logger = get_logger(__name__)


@dataclass
class BehavioralSignals:
    user_id: str
    days_since_last_activity: int = 0
    missed_diary_days_last_14: int = 0
    milestone_completion_rate: float = 1.0   # 0.0 → 1.0
    relapse_flag: bool = False                # set if user pressed relapse button
    risk_score: float = 0.0                  # 0.0 (low) → 1.0 (high)

    def to_prompt_snippet(self) -> str:
        lines = [
            f"Days since last app activity: {self.days_since_last_activity}",
            f"Missed diary entries (last 14 days): {self.missed_diary_days_last_14}/14",
            f"Milestone completion rate: {self.milestone_completion_rate:.0%}",
        ]
        if self.relapse_flag:
            lines.append("⚠️ User has recently indicated a relapse.")
        return "\n".join(lines)


async def get_behavioral_signals(user_id: str) -> BehavioralSignals:
    """
    Compute behavioral signals for a user.
    All signals degrade gracefully if data is unavailable.
    """
    profile, diary_entries = await asyncio.gather(
        get_user_profile(user_id),
        get_recent_diary_entries(user_id, days=14, limit=50),
        return_exceptions=True,
    )

    signals = BehavioralSignals(user_id=user_id)

    if not isinstance(profile, Exception):
        # Approximate last activity from days_quit and total progress
        # A more accurate measure would require a last_login field in the user document
        signals.days_since_last_activity = 0  # placeholder — refine if last_login is added

        if profile.num_milestones_completed is not None and profile.days_quit > 0:
            # Very rough rate: expect ~1 milestone per week
            expected = max(1, profile.days_quit // 7)
            actual = profile.num_milestones_completed
            signals.milestone_completion_rate = min(1.0, actual / expected)

    if not isinstance(diary_entries, Exception):
        unique_days = len({e.created_at.date() for e in diary_entries})
        signals.missed_diary_days_last_14 = max(0, 14 - unique_days)

    # Compute composite risk score (heuristic)
    risk = 0.0
    if signals.missed_diary_days_last_14 > 7:
        risk += 0.3
    if signals.milestone_completion_rate < 0.5:
        risk += 0.3
    if signals.days_since_last_activity > 3:
        risk += 0.2
    if signals.relapse_flag:
        risk += 0.5
    signals.risk_score = min(1.0, risk)

    return signals
