"""
Groq API client implementing the LLMClient protocol.

Used for:
- Triage agent: llama-3.1-8b-instant, temperature=0, json_mode=True
- Synthesizer: llama-3.3-70b-versatile, temperature=0.5, streaming
- Crisis one-liner: llama-3.1-8b-instant, tightly constrained prompt

Handles:
- 429 retry / exponential backoff (delegated to retry_with_backoff)
- Streaming via async generator
- Request timeout from settings
"""
from __future__ import annotations

import asyncio
import json
from typing import AsyncIterator

from groq import AsyncGroq, RateLimitError

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)


class GroqClient:
    def __init__(self, model: str | None = None) -> None:
        self._model = model or settings.groq_triage_model
        self._client = AsyncGroq(api_key=settings.groq_api_key)

    async def complete(
        self,
        messages: list[dict],
        temperature: float = 0.7,
        json_mode: bool = False,
        max_tokens: int = 1024,
    ) -> str:
        """Non-streaming completion with retry on 429."""

        async def _call() -> str:
            kwargs: dict = {
                "model": self._model,
                "messages": messages,
                "temperature": temperature,
                "max_tokens": max_tokens,
            }
            if json_mode:
                kwargs["response_format"] = {"type": "json_object"}

            resp = await asyncio.wait_for(
                self._client.chat.completions.create(**kwargs),
                timeout=settings.request_timeout_seconds,
            )
            return resp.choices[0].message.content or ""

        from app.llm.client import retry_with_backoff
        return await retry_with_backoff(_call)

    async def stream(
        self,
        messages: list[dict],
        temperature: float = 0.5,
        max_tokens: int = 2048,
    ) -> AsyncIterator[str]:
        """Streaming completion — yields tokens as they arrive."""
        try:
            stream = await asyncio.wait_for(
                self._client.chat.completions.create(
                    model=self._model,
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens,
                    stream=True,
                ),
                timeout=settings.request_timeout_seconds,
            )
            async for chunk in stream:
                delta = chunk.choices[0].delta.content
                if delta:
                    yield delta
        except RateLimitError:
            logger.error("groq_rate_limit_during_stream")
            yield "\n\n*[Hailey is temporarily unavailable — please try again in a moment]*"
        except asyncio.TimeoutError:
            logger.error("groq_stream_timeout")
            yield "\n\n*[Response timed out — please try again]*"
