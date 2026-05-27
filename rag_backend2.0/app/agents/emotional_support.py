"""
Emotional Support Agent.

Uses Motivational Interviewing principles.
Activates when emotion ∈ {sadness, fear, anxiety, shame, guilt, frustration, loneliness, anger}.
"""
from __future__ import annotations

import json

from app.agents.base import AgentBase
from app.llm.client import get_triage_client
from app.models.retrieval import KeyPoint, SpecialistDraft
from app.observability.logging import get_logger
from app.prompts.emotional import EMOTIONAL_SYSTEM, EMOTIONAL_USER_TEMPLATE

logger = get_logger(__name__)


class EmotionalSupportAgent(AgentBase):
    name = "emotional_support"

    async def run(self, state) -> SpecialistDraft:  # type: ignore[override]
        user_input: str = state["user_input"]
        memory = state.get("user_memory")
        memory_context = memory.to_prompt_block() if memory else "(no memory)"
        triage = state.get("triage")
        emotion = triage.emotion if triage else "neutral"

        client = get_triage_client()
        messages = [
            {"role": "system", "content": EMOTIONAL_SYSTEM},
            {
                "role": "user",
                "content": EMOTIONAL_USER_TEMPLATE.format(
                    user_input=user_input,
                    emotion=emotion,
                    memory_context=memory_context,
                ),
            },
        ]
        try:
            raw = await client.complete(messages=messages, temperature=0.3, json_mode=True, max_tokens=512)
            data = json.loads(raw)
            key_points = [KeyPoint(**kp) for kp in data.get("key_points", [])]
            return SpecialistDraft(
                agent=self.name,
                key_points=key_points,
                tone_hint="reflective_listening",
                raw_context=data.get("raw_context", ""),
            )
        except (json.JSONDecodeError, ValueError) as exc:
            logger.warning("emotional_agent_parse_failed", error=str(exc))
            return SpecialistDraft(
                agent=self.name,
                key_points=[KeyPoint(claim="It sounds like you're going through a really tough moment.")],
                tone_hint="reflective_listening",
                raw_context="",
            )
