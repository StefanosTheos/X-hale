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

from groq import AsyncGroq, BadRequestError, RateLimitError

from app.config import settings
from app.observability.logging import get_logger
from app.llm.usage import record_usage

logger = get_logger(__name__)


def _structured_output_error_code(exc: BadRequestError) -> str:
    """Extract Groq's validation code across SDK response-body shapes."""
    body = getattr(exc, "body", None) or {}
    if not isinstance(body, dict):
        return ""
    nested = body.get("error")
    if isinstance(nested, dict):
        return str(nested.get("code", ""))
    return str(body.get("code", ""))


class GroqClient:
    def __init__(self, model: str | None = None) -> None:
        self._model = model or settings.groq_triage_model
        self._client = AsyncGroq(
            api_key=settings.groq_api_key,
            # retry_with_backoff is the single retry owner. SDK retries previously
            # nested beneath it, obscuring quota failures and exceeding request timeouts.
            max_retries=0,
            timeout=55.0,
        )

    async def complete(
        self,
        messages: list[dict],
        temperature: float = 0.7,
        json_mode: bool = False,
        response_schema: dict | None = None,
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
            if response_schema is not None:
                kwargs["response_format"] = {
                    "type": "json_schema",
                    "json_schema": {
                        "name": "hailey_response",
                        "strict": True,
                        "schema": response_schema,
                    },
                }
            elif json_mode:
                kwargs["response_format"] = {"type": "json_object"}
            try:
                resp = await asyncio.wait_for(
                    self._client.chat.completions.create(**kwargs),
                    timeout=settings.request_timeout_seconds,
                )
            except BadRequestError as exc:
                error_code = _structured_output_error_code(exc)
                if error_code not in {"json_validate_failed", "json_schema_validation_failed"}:
                    raise
                logger.warning("groq_structured_output_fallback", error_code=error_code)
                fallback_kwargs = dict(kwargs)
                # Preserve syntactic JSON enforcement even when the model fails
                # Groq's strict schema validation. Removing response_format here
                # produced empty/prose/malformed specialist drafts in production.
                fallback_kwargs["response_format"] = {"type": "json_object"}
                resp = await asyncio.wait_for(
                    self._client.chat.completions.create(**fallback_kwargs),
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
                    extra_body={"stream_options": {"include_usage": True}},
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
            raise
        except asyncio.TimeoutError:
            logger.error("groq_stream_timeout")
            raise
