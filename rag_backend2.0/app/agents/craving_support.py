"""
Craving Support Agent.

Activated when urgency=high or intent=craving_support.
Provides an urge-surfing micro-script and suggests in-app distractions.
"""
from __future__ import annotations

import json

from app.agents.base import AgentBase
from app.llm.client import get_triage_client
from app.models.retrieval import AppAction, KeyPoint, SpecialistDraft
from app.observability.logging import get_logger
from app.prompts.craving import CRAVING_SYSTEM, CRAVING_USER_TEMPLATE
from app.tools.app_actions import KNOWN_DEEPLINK_URLS, get_craving_actions

logger = get_logger(__name__)


class CravingSupportAgent(AgentBase):
    name = "craving_support"

    async def run(self, state) -> SpecialistDraft:  # type: ignore[override]
        user_input: str = state["user_input"]
        memory = state.get("user_memory")
        memory_context = memory.to_prompt_block() if memory else "(no memory)"

        client = get_triage_client()
        messages = [
            {"role": "system", "content": CRAVING_SYSTEM},
            {
                "role": "user",
                "content": CRAVING_USER_TEMPLATE.format(
                    user_input=user_input,
                    memory_context=memory_context,
                ),
            },
        ]
        try:
            raw = await client.complete(messages=messages, temperature=0.1, json_mode=True, max_tokens=512)
            data = json.loads(raw)
            key_points = [KeyPoint(**kp) for kp in data.get("key_points", [])]
            deeplinks_raw = data.get("suggested_deeplinks", [])
            if deeplinks_raw:
                validated = [AppAction(**d) for d in deeplinks_raw if d.get("deeplink") in KNOWN_DEEPLINK_URLS]
                deeplinks = validated if validated else get_craving_actions(3)
            else:
                deeplinks = get_craving_actions(3)
            return SpecialistDraft(
                agent=self.name,
                key_points=key_points,
                tone_hint="urge_surfing",
                raw_context=data.get("raw_context", ""),
                suggested_deeplinks=deeplinks,
            )
        except (json.JSONDecodeError, ValueError) as exc:
            logger.warning("craving_agent_parse_failed", error=str(exc))
            return SpecialistDraft(
                agent=self.name,
                key_points=[KeyPoint(claim="Cravings peak at 3-5 minutes and then pass. You can do this.")],
                tone_hint="urge_surfing",
                raw_context="",
                suggested_deeplinks=get_craving_actions(3),
            )
