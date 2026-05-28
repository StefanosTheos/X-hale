"""
Google Gemini client via the OpenAI-compatible endpoint (Google AI Studio).

Drop-in replacement for GroqClient — implements the same LLMClient protocol.
Base URL: https://generativelanguage.googleapis.com/v1beta/openai/
"""
from __future__ import annotations

import asyncio
from typing import AsyncIterator

from openai import AsyncOpenAI, RateLimitError

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)

_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/openai/"


class GeminiClient:
    def __init__(self, model: str | None = None) -> None:
        self._model = model or settings.gemini_triage_model
        self._client = AsyncOpenAI(
            api_key=settings.gemini_api_key,
            base_url=_BASE_URL,
        )

    async def complete(
        self,
        messages: list[dict],
        temperature: float = 0.7,
        json_mode: bool = False,
        max_tokens: int = 1024,
    ) -> str:
        async def _call() -> str:
            kwargs: dict = {
                "model": self._model,
                "messages": messages,
                "temperature": temperature,
                "max_tokens": max_tokens,
            }
            # Gemini's OpenAI-compatible endpoint returns empty content when
            # response_format=json_object is set; rely on the prompt instead.
            # (GroqClient keeps json_mode for its own endpoint.)

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
            logger.error("gemini_rate_limit_during_stream")
            yield "\n\n*[Hailey is temporarily unavailable — please try again in a moment]*"
        except asyncio.TimeoutError:
            logger.error("gemini_stream_timeout")
            yield "\n\n*[Response timed out — please try again]*"
