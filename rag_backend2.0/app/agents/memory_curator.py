"""
Memory Curator Agent — asynchronous, lifecycle-managed, and retriable.

Runs after the conversation turn is durably stored. Reads the completed turn,
extracts durable user facts, and upserts them to Appwrite with bounded retries.
Uses the configured GPT OSS 20B model at temperature=0 for reliable JSON output.
"""
from __future__ import annotations

import asyncio
import json

from app.llm.client import get_triage_client
from app.memory.user_facts_store import upsert_fact
from app.models.user_facts import UserFact
from app.observability.logging import get_logger
from app.prompts.memory_curator import MEMORY_CURATOR_SYSTEM, MEMORY_CURATOR_USER_TEMPLATE

logger = get_logger(__name__)


async def curate_memory(
    user_id: str,
    user_input: str,
    hailey_reply: str,
    turn_id: str,
    *,
    max_attempts: int = 3,
) -> bool:
    """
    Extract and persist durable user facts from a completed conversation turn.
    Retry transient failures with bounded exponential backoff. Returns whether
    the turn was successfully processed (including valid turns with no facts).
    """
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
    for attempt in range(1, max_attempts + 1):
        try:
            client = get_triage_client()
            raw = await client.complete(messages=messages, temperature=0.0, json_mode=True, max_tokens=512)
            facts_raw: list[dict] = json.loads(raw)
            if not isinstance(facts_raw, list):
                raise ValueError("memory curator output must be a JSON array")

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
            return True

        except Exception as exc:
            if attempt == max_attempts:
                logger.error(
                    "memory_curator_failed", user_id=user_id, turn_id=turn_id,
                    attempts=attempt, error=str(exc),
                )
                return False
            delay = 2 ** (attempt - 1)
            logger.warning(
                "memory_curator_retry", user_id=user_id, turn_id=turn_id,
                attempt=attempt, delay=delay, error=str(exc),
            )
            await asyncio.sleep(delay)
    return False
