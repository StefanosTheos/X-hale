"""
Relapse-Risk Agent.

Activated by the supervisor when behavioral signals indicate declining engagement
or when the user has flagged a relapse. Reads behavioral data from Appwrite and
emits a risk-informed intervention suggestion for the synthesizer.
"""
from __future__ import annotations

import json

from app.agents.base import AgentBase
from app.llm.client import get_triage_client
from app.llm.schemas import SPECIALIST_DRAFT_SCHEMA
from app.models.retrieval import AppAction, KeyPoint, SpecialistDraft
from app.observability.logging import get_logger
from app.prompts.relapse_risk import RELAPSE_RISK_SYSTEM, RELAPSE_RISK_USER_TEMPLATE
from app.tools.behavioral_signals import get_behavioral_signals

logger = get_logger(__name__)


class RelapseRiskAgent(AgentBase):
    name = "relapse_risk"

    async def run(self, state) -> SpecialistDraft:  # type: ignore[override]
        user_id: str = state["user_id"]
        user_input: str = state["user_input"]
        memory = state.get("user_memory")
        memory_context = memory.to_prompt_block() if memory else "(no memory)"

        triage = state.get("triage")
        signals = await get_behavioral_signals(
            user_id,
            explicit_relapse_report=bool(triage and triage.intent == "relapse_concern"),
        )

        client = get_triage_client()
        messages = [
            {"role": "system", "content": RELAPSE_RISK_SYSTEM},
            {
                "role": "user",
                "content": RELAPSE_RISK_USER_TEMPLATE.format(
                    user_input=user_input,
                    signals=signals.to_prompt_snippet(),
                    memory_context=memory_context,
                    risk_score=signals.risk_score,
                ),
            },
        ]
        try:
            raw = await client.complete(
                messages=messages, temperature=0.2, json_mode=True,
                response_schema=SPECIALIST_DRAFT_SCHEMA, max_tokens=512,
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
            logger.warning("relapse_risk_agent_parse_failed", error=str(exc))
            return SpecialistDraft(
                agent=self.name,
                key_points=[
                    KeyPoint(claim="Every setback is a learning opportunity on your quit journey.")
                ],
                tone_hint="warm_supportive",
                raw_context="",
            )
