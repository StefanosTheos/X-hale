"""
Pydantic models for user facts, triage results, memory snapshots, and user profiles.
These are the core data contracts shared across agents, memory stores, and routers.
"""
from __future__ import annotations

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field

# ---------------------------------------------------------------------------
# Triage
# ---------------------------------------------------------------------------

IntentType = Literal[
    "medical_question",
    "craving_support",
    "emotional_support",
    "reflection",
    "relapse_concern",
    "off_topic",
    "needs_clarification",
    "general_conversation",
]

EmotionType = Literal[
    "sadness", "fear", "anxiety", "shame", "guilt",
    "frustration", "loneliness", "anger", "joy", "neutral",
    "confusion", "hope", "calm",
]

SpecialistName = Literal[
    "medical", "craving_support", "emotional_support",
    "reflection", "relapse_risk",
]


class TriageResult(BaseModel):
    intent: IntentType = "general_conversation"
    emotion: EmotionType = "neutral"
    topic_relevance: Literal["relevant", "irrelevant"] = "relevant"
    urgency: Literal["low", "medium", "high"] = "low"
    crisis_flag: bool = False
    requested_specialists: list[SpecialistName] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# User Facts (stored in Appwrite chatbot_user_facts collection)
# ---------------------------------------------------------------------------

FactType = Literal[
    "trigger",
    "coping_strategy_validated",
    "coping_strategy_failed",
    "nrt_use",
    "social_context",
    "motivation",
    "stage_of_change",
    "past_attempt_history",
    "physical_symptom_reported",
]


class UserFact(BaseModel):
    fact_id: Optional[str] = None          # Appwrite document $id
    user_id: str
    fact_type: FactType
    fact_key: str                           # e.g. "morning_coffee"
    fact_value: str                         # e.g. "biggest craving trigger, mentioned 4 times"
    confidence: float = Field(default=0.7, ge=0.0, le=1.0)
    source_turn_ids: list[str] = Field(default_factory=list)
    first_observed: Optional[datetime] = None
    last_confirmed: Optional[datetime] = None
    superseded_by: Optional[str] = None    # fact_id of the replacing fact


# ---------------------------------------------------------------------------
# User Profile (read-only from Appwrite users collection)
# ---------------------------------------------------------------------------

class UserProfile(BaseModel):
    user_id: str
    name: str = "there"
    quit_date: Optional[datetime] = None
    days_quit: int = 0
    cigs_per_day: int = 0
    cigs_per_pack: int = 20
    price_per_pack: float = 0.0
    years_smoking: int = 0
    total_cigs_avoided: int = 0
    money_saved: float = 0.0
    num_achievements: int = 0
    num_milestones_completed: int = 0
    num_diary_entries: int = 0
    num_health_benefits_reached: int = 0
    locale: str = "en"                     # used for hotline locale selection


# ---------------------------------------------------------------------------
# Conversation Turn (stored in Appwrite chatbot_messages collection)
# ---------------------------------------------------------------------------

class ConversationTurn(BaseModel):
    turn_id: str
    user_id: str
    role: Literal["user", "assistant"]
    content: str
    timestamp: datetime
    citations: list[dict] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Memory Snapshot (assembled once per turn, never written back)
# ---------------------------------------------------------------------------

class UserMemorySnapshot(BaseModel):
    user_id: str
    profile: UserProfile
    recent_turns: list[ConversationTurn] = Field(default_factory=list)
    top_facts: list[UserFact] = Field(default_factory=list)

    def format_profile_for_prompt(self) -> str:
        """Return a concise text block describing the user's quit journey."""
        lines: list[str] = []
        p = self.profile
        lines.append(f"User name: {p.name}")
        if p.quit_date:
            lines.append(f"Quit date: {p.quit_date.strftime('%Y-%m-%d')} ({p.days_quit} days smoke-free)")
        if p.cigs_per_day:
            lines.append(f"Smoking history: {p.cigs_per_day} cigarettes/day for {p.years_smoking} years")
        if p.money_saved:
            lines.append(f"Money saved: €{p.money_saved:.2f}")
        if p.total_cigs_avoided:
            lines.append(f"Cigarettes avoided: {p.total_cigs_avoided}")
        if p.num_achievements:
            lines.append(f"Achievements unlocked: {p.num_achievements}")
        if p.num_milestones_completed:
            lines.append(f"Milestones completed: {p.num_milestones_completed}")
        return "\n".join(lines)

    def format_facts_for_prompt(self) -> str:
        """Return the top user facts as a bullet list."""
        if not self.top_facts:
            return "(No facts recorded yet)"
        lines: list[str] = []
        for f in self.top_facts[:30]:
            lines.append(f"  [{f.fact_type}] {f.fact_key}: {f.fact_value}")
        return "\n".join(lines)

    def format_history_for_prompt(self) -> str:
        """Return the last N turns as a Human/Assistant dialogue string."""
        lines: list[str] = []
        for turn in self.recent_turns[-10:]:
            label = "User" if turn.role == "user" else "Hailey"
            lines.append(f"{label}: {turn.content}")
        return "\n".join(lines)

    def to_prompt_block(self) -> str:
        """Full memory context block for injection into prompts (~2300 tokens max)."""
        return (
            "=== User Profile ===\n"
            + self.format_profile_for_prompt()
            + "\n\n=== Known Facts About This User ===\n"
            + self.format_facts_for_prompt()
            + "\n\n=== Recent Conversation ===\n"
            + self.format_history_for_prompt()
        )
