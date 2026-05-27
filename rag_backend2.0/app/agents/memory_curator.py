"""
Memory Curator Agent — async, fire-and-forget.

Runs AFTER the reply has been streamed. Reads the completed turn,
extracts durable user facts, and upserts them to Appwrite.
Uses the 8B model at temperature=0 for reliable JSON output.
"""
from __future__ import annotations

import json

from app.llm.client import get_triage_client
from app.memory.user_facts_store import upsert_fact
from app.models.user_facts import UserFact
from app.observability.logging import get_logger
from app.prompts.memory_curator import MEMORY_CURATOR_SYSTEM, MEMORY_CURATOR_USER_TEMPLATE

logger = get_logger(__name__)


async def curate_memory(user_id: str, user_input: str, hailey_reply: str, turn_id: str) -> None:
    """
    Extract and persist durable user facts from a completed conversation turn.
    This function is fire-and-forget — errors are logged but not raised.
    """
    try:
        client = get_triage_client()
        messages = [
            {"role": "system", "content": MEMORY_CURATOR_SYSTEM},
            {
                "role": "user",
                "content": MEMORY_CURATOR_USER_TEMPLATE.format(
                    user_input=user_input,
                    hailey_reply=hailey_reply,
                ),
            },
        ]
        raw = await client.complete(messages=messages, temperature=0.0, json_mode=True, max_tokens=512)
        facts_raw: list[dict] = json.loads(raw)
        if not isinstance(facts_raw, list):
            return

        for fact_data in facts_raw:
            if fact_data.get("confidence", 0) < 0.5:
                continue
            fact = UserFact(
                user_id=user_id,
                fact_type=fact_data["fact_type"],
                fact_key=fact_data["fact_key"],
                fact_value=fact_data["fact_value"],
                confidence=float(fact_data.get("confidence", 0.7)),
                source_turn_ids=[turn_id],
            )
            await upsert_fact(fact)
            logger.info("user_fact_upserted", fact_type=fact.fact_type, fact_key=fact.fact_key)

    except Exception as exc:
        logger.error("memory_curator_failed", user_id=user_id, error=str(exc))
