"""
SSE streaming helpers.

Provides:
- async_token_generator_to_sse(): wraps an async token stream into SSE-formatted lines
- status_event(): emits an intermediate status SSE event
- done_event(): emits the terminal SSE event with citations and deeplinks
- error_event(): emits an error SSE event
"""
from __future__ import annotations

import json
from typing import AsyncIterator

from app.models.retrieval import AppAction, Citation


def _sse_line(event: str, data: dict | str) -> str:
    """Format a single SSE message."""
    payload = data if isinstance(data, str) else json.dumps(data)
    return f"event: {event}\ndata: {payload}\n\n"


def status_event(state: str) -> str:
    """Emit an intermediate status event. State should be one of the SSEStatusEvent literals."""
    return _sse_line("status", {"state": state})


def token_event(token: str) -> str:
    """Emit a single token."""
    return _sse_line("token", {"token": token})


def done_event(
    citations: list[Citation],
    deeplinks: list[AppAction],
    turn_id: str = "",
) -> str:
    """Emit the terminal done event."""
    return _sse_line("done", {
        "citations": [c.model_dump() for c in citations],
        "deeplinks": [d.model_dump() for d in deeplinks],
        "turn_id": turn_id,
    })


def error_event(code: str, message: str) -> str:
    """Emit an error event."""
    return _sse_line("error", {"code": code, "message": message})


async def stream_tokens(
    token_iter: AsyncIterator[str],
) -> AsyncIterator[str]:
    """
    Wrap a raw async token iterator into SSE token events.
    Yields SSE-formatted strings ready to be sent as StreamingResponse content.
    """
    async for token in token_iter:
        yield token_event(token)
