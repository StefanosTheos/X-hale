"""
Groq API client implementing the LLMClient protocol.

Used for:
- Triage, specialists, memory curator, crisis opener: openai/gpt-oss-20b
- Synthesizer: openai/gpt-oss-120b, temperature=0.5, streaming

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
from app.llm.usage import record_usage

logger = get_logger(__name__)


class GroqClient:
    def __init__(self, model: str | None = None) -> None:
        self._model = model or settings.groq_triage_model
        self._client = AsyncGroq(
            api_key=settings.groq_api_key,
            max_retries=4,
            timeout=55.0,
        )

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
            record_usage(self._model, resp.usage)
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
                    stream_options={"include_usage": True},
                ),
                timeout=settings.request_timeout_seconds,
            )
            async for chunk in stream:
                record_usage(self._model, getattr(chunk, "usage", None))
                if not chunk.choices:
                    continue
                delta = chunk.choices[0].delta.content
                if delta:
                    yield delta
        except RateLimitError:
            logger.error("groq_rate_limit_during_stream")
            yield "\n\n*[Hailey is temporarily unavailable — please try again in a moment]*"
        except asyncio.TimeoutError:
            logger.error("groq_stream_timeout")
            yield "\n\n*[Response timed out — please try again]*"
