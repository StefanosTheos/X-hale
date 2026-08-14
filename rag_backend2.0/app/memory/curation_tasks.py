"""Lifecycle-managed background execution for memory curation."""
from __future__ import annotations

import asyncio

from app.observability.logging import get_logger

logger = get_logger(__name__)
_pending_tasks: set[asyncio.Task] = set()


def schedule_memory_curation(
    user_id: str,
    user_input: str,
    hailey_reply: str,
    turn_id: str,
) -> asyncio.Task:
    """Schedule retriable curation and retain a strong reference until completion."""
    from app.agents.memory_curator import curate_memory

    task = asyncio.create_task(
        curate_memory(user_id, user_input, hailey_reply, turn_id),
        name=f"memory-curation:{turn_id}",
    )
    _pending_tasks.add(task)
    task.add_done_callback(_pending_tasks.discard)
    return task


async def drain_memory_curation_tasks(timeout_seconds: float = 15.0) -> None:
    """Give scheduled writes a bounded opportunity to finish during shutdown."""
    if not _pending_tasks:
        return
    tasks = tuple(_pending_tasks)
    logger.info("memory_curation_draining", count=len(tasks))
    done, pending = await asyncio.wait(tasks, timeout=timeout_seconds)
    for task in pending:
        task.cancel()
    if pending:
        await asyncio.gather(*pending, return_exceptions=True)
        logger.warning("memory_curation_drain_timeout", cancelled=len(pending))
    for task in done:
        if not task.cancelled() and task.exception() is not None:
            logger.error("memory_curation_task_failed", error=str(task.exception()))
