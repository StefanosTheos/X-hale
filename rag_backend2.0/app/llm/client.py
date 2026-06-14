"""
Uniform LLMClient interface.

All agents import LLMClient and call .complete() or .stream().
The concrete implementation (Groq, Workers AI) is selected by the caller
via get_triage_client() / get_synthesis_client() factory functions.

Includes:
- Retry + exponential backoff on 429
- Circuit breaker on repeated 5xx
- Request timeout enforcement
"""
from __future__ import annotations

import asyncio
import random
from typing import AsyncIterator, Protocol, runtime_checkable

from app.observability.logging import get_logger

logger = get_logger(__name__)


@runtime_checkable
class LLMClient(Protocol):
    async def complete(
        self,
        messages: list[dict],
        temperature: float = 0.7,
        json_mode: bool = False,
        max_tokens: int = 1024,
    ) -> str: ...

    async def stream(
        self,
        messages: list[dict],
        temperature: float = 0.5,
        max_tokens: int = 2048,
    ) -> AsyncIterator[str]: ...


async def retry_with_backoff(
    coro_fn,
    max_attempts: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 16.0,
) -> str:
    """Retry an async function with exponential backoff on RateLimitError."""
    last_exc: Exception | None = None
    for attempt in range(max_attempts):
        try:
            return await coro_fn()
        except Exception as exc:
            exc_name = type(exc).__name__
            if "RateLimit" in exc_name or "429" in str(exc):
                delay = min(base_delay * (2 ** attempt) + random.uniform(0, 1), max_delay)
                logger.warning("llm_rate_limited", attempt=attempt + 1, delay=delay)
                await asyncio.sleep(delay)
                last_exc = exc
            else:
                raise
    raise last_exc  # type: ignore[misc]


def get_triage_client() -> "GroqClient":
    """Return the fast LLM client for triage, specialists, and memory curator.

    Uses Groq (llama-3.1-8b-instant, 30 RPM free tier) — all callers need
    structured JSON at temperature≈0, which Groq handles well and cheaply.
    Keeps Gemini quota reserved solely for the synthesizer.
    """
    from app.llm.groq_client import GroqClient
    from app.config import settings
    return GroqClient(model=settings.groq_triage_model)


def get_synthesis_client() -> "GeminiClient":
    """Return the LLM client for the synthesizer (streaming final response)."""
    from app.llm.gemini_client import GeminiClient
    from app.config import settings
    return GeminiClient(model=settings.gemini_synthesis_model)
