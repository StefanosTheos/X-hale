"""
Reflection / Journal Agent.

Activated when the user mentions their diary, asks about progress, or uses
phrases like "looking back" or "have I improved". Reads recent diary entries,
surfaces patterns and mood trends, and frames them as gentle observations.
"""
from __future__ import annotations

import json

from app.agents.base import AgentBase
from app.llm.client import get_triage_client
from app.llm.schemas import SPECIALIST_DRAFT_SCHEMA
from app.models.retrieval import AppAction, KeyPoint, SpecialistDraft
from app.observability.logging import get_logger
from app.prompts.reflection import REFLECTION_SYSTEM, REFLECTION_USER_TEMPLATE
from app.tools.diary_retrieval import DiaryEntry, get_recent_diary_entries

logger = get_logger(__name__)

_DAYS = 30
_LIMIT = 20
_CONTENT_SNIPPET_LEN = 200
_MAX_ENTRIES_IN_PROMPT = 15


def _format_entries(entries: list[DiaryEntry]) -> str:
    """Produce a concise text block of diary entries for prompt injection."""
    if not entries:
        return "(No diary entries in this period)"
    lines: list[str] = []
    for e in entries[:_MAX_ENTRIES_IN_PROMPT]:
        snippet = e.content[:_CONTENT_SNIPPET_LEN].strip()
        if len(e.content) > _CONTENT_SNIPPET_LEN:
            snippet += "…"
        tag_str = ", ".join(e.tags[:3]) if e.tags else "no tags"
        lines.append(
            f"• {e.created_at.strftime('%Y-%m-%d')} | mood: {e.mood} | tags: {tag_str}\n"
            f"  \"{snippet}\""
        )
    return "\n".join(lines)


class ReflectionAgent(AgentBase):
    name = "reflection"

    async def run(self, state) -> SpecialistDraft:  # type: ignore[override]
        user_id: str = state["user_id"]
        user_input: str = state["user_input"]
        memory = state.get("user_memory")
        memory_context = memory.to_prompt_block() if memory else "(no memory)"

        entries = await get_recent_diary_entries(user_id, days=_DAYS, limit=_LIMIT)

        client = get_triage_client()
        messages = [
            {"role": "system", "content": REFLECTION_SYSTEM},
            {
                "role": "user",
                "content": REFLECTION_USER_TEMPLATE.format(
                    user_input=user_input,
                    memory_context=memory_context,
                    entry_count=len(entries),
                    days=_DAYS,
                    diary_entries=_format_entries(entries),
                ),
            },
        ]
        try:
            raw = await client.complete(
                messages=messages, temperature=0.3, json_mode=True,
                response_schema=SPECIALIST_DRAFT_SCHEMA, max_tokens=600,
            )
            data = json.loads(raw)
            key_points = [KeyPoint(**kp) for kp in data.get("key_points", [])]
            deeplinks_raw = data.get("suggested_deeplinks", [])
            deeplinks = [AppAction(**d) for d in deeplinks_raw]
            return SpecialistDraft(
                agent=self.name,
                key_points=key_points,
                tone_hint="warm_supportive",
                raw_context=data.get("raw_context", ""),
                suggested_deeplinks=deeplinks,
            )
        except (json.JSONDecodeError, ValueError) as exc:
            logger.warning("reflection_agent_parse_failed", error=str(exc))
            return SpecialistDraft(
                agent=self.name,
                key_points=[
                    KeyPoint(claim="Your quit journey reflects real strength, even in the difficult moments.")
                ],
                tone_hint="warm_supportive",
                raw_context="",
            )
