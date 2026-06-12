"""
Medical Information Agent.

Retrieves evidence-based content from the knowledge base and returns
a SpecialistDraft with key_points, each traced to a source_id.
"""
from __future__ import annotations

import json

from app.agents.base import AgentBase
from app.llm.client import get_triage_client
from app.models.retrieval import Citation, KeyPoint, SpecialistDraft
from app.observability.logging import get_logger
from app.prompts.medical import MEDICAL_SYSTEM, MEDICAL_USER_TEMPLATE
from app.retrieval.hybrid_retriever import retrieve

logger = get_logger(__name__)


class MedicalAgent(AgentBase):
    name = "medical"

    async def run(self, state) -> SpecialistDraft:  # type: ignore[override]
        user_input: str = state["user_input"]
        memory = state.get("user_memory")
        profile_snippet = memory.format_profile_for_prompt() if memory else "(no profile)"

        retrieval = await retrieve(
            query=user_input,
            user_id=state["user_id"],
            strategy="factual",
            k=5,
            intent=state.get("intent", "unknown"),
        )

        if not retrieval.chunks:
            logger.info("medical_agent_no_chunks", user_id=state["user_id"])
            return SpecialistDraft(
                agent=self.name,
                key_points=[],
                tone_hint="factual_reassuring",
                raw_context="I couldn't find specific information on that in my knowledge base.",
                citations=[],
            )

        client = get_triage_client()  # 8B model is sufficient for structured extraction
        messages = [
            {"role": "system", "content": MEDICAL_SYSTEM},
            {
                "role": "user",
                "content": MEDICAL_USER_TEMPLATE.format(
                    user_input=user_input,
                    retrieved_context=retrieval.format_for_prompt(),
                    user_profile_snippet=profile_snippet,
                ),
            },
        ]
        try:
            raw = await client.complete(messages=messages, temperature=0.0, json_mode=True, max_tokens=512)
            data = json.loads(raw)
            key_points = [KeyPoint(**kp) for kp in data.get("key_points", [])]
            return SpecialistDraft(
                agent=self.name,
                key_points=key_points,
                tone_hint=data.get("tone_hint", "factual_reassuring"),
                raw_context=data.get("raw_context", retrieval.format_for_prompt()[:400]),
                citations=retrieval.citations,
                suggested_deeplinks=[],
            )
        except (json.JSONDecodeError, ValueError) as exc:
            logger.warning("medical_agent_parse_failed", error=str(exc))
            # Graceful degradation: return raw context without structured key_points
            return SpecialistDraft(
                agent=self.name,
                key_points=[],
                tone_hint="factual_reassuring",
                raw_context=retrieval.format_for_prompt()[:600],
                citations=retrieval.citations,
            )
