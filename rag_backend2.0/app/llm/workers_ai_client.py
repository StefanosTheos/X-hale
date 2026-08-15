"""
Cloudflare Workers AI client.

Used for:
- Generating text embeddings: @cf/baai/bge-small-en-v1.5  (384-dim)
- Optional small-model inference: @cf/meta/llama-3.2-3b-instruct

Tracks per-day quota usage and logs a warning at 70%.
"""
from __future__ import annotations

import time
import asyncio
from typing import AsyncIterator

import requests

from app.config import settings
from app.observability.logging import get_logger
from app.observability.metrics import record_cf_quota

logger = get_logger(__name__)

# Simple in-process daily quota tracking (resets at midnight UTC)
_quota_state: dict = {"count": 0, "day": -1}


def _get_quota_count() -> int:
    import datetime
    today = datetime.date.today().toordinal()
    if _quota_state["day"] != today:
        _quota_state["count"] = 0
        _quota_state["day"] = today
    return _quota_state["count"]


def _increment_quota(n: int = 1) -> None:
    _quota_state["count"] += n
    used = _quota_state["count"]
    record_cf_quota(used)
    threshold = int(settings.cf_workers_ai_daily_quota * 0.7)
    if used >= threshold:
        logger.warning(
            "cf_workers_ai_quota_warning",
            used=used,
            limit=settings.cf_workers_ai_daily_quota,
        )


def _base_url(model: str) -> str:
    return (
        f"{settings.cf_workers_ai_base_url}/"
        f"{settings.cf_account_id}/ai/run/{model}"
    )


def _headers() -> dict:
    return {"Authorization": f"Bearer {settings.cf_workers_ai_token}"}


def _post_json_sync(url: str, payload: dict, timeout: float = 30.0) -> dict:
    """POST through requests; its transport is reliable in the Space runtime."""
    with requests.Session() as session:
        session.trust_env = False
        response = session.post(url, headers=_headers(), json=payload, timeout=timeout)
        response.raise_for_status()
        return response.json()


async def _post_json(url: str, payload: dict, timeout: float = 30.0) -> dict:
    return await asyncio.to_thread(_post_json_sync, url, payload, timeout)


async def embed(text: str) -> list[float]:
    """
    Embed a single text string using bge-small-en-v1.5.
    Returns a 384-dimensional float vector.
    """
    url = _base_url(settings.cf_embedding_model)
    data = await _post_json(url, {"text": [text]})
    _increment_quota(1)
    return data["result"]["data"][0]


async def embed_batch(texts: list[str]) -> list[list[float]]:
    """Embed a list of texts in a single Workers AI call."""
    url = _base_url(settings.cf_embedding_model)
    data = await _post_json(url, {"text": texts})
    _increment_quota(len(texts))
    return data["result"]["data"]


class WorkersAIClient:
    """Small-model inference via Cloudflare Workers AI. For triage fallback only."""

    def __init__(self, model: str | None = None) -> None:
        self._model = model or settings.cf_small_model

    async def complete(
        self,
        messages: list[dict],
        temperature: float = 0.0,
        json_mode: bool = False,
        max_tokens: int = 512,
    ) -> str:
        url = _base_url(self._model)
        payload: dict = {
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }
        data = await _post_json(url, payload)
        _increment_quota(1)
        return data.get("result", {}).get("response", "")

    async def stream(
        self,
        messages: list[dict],
        temperature: float = 0.5,
        max_tokens: int = 512,
    ) -> AsyncIterator[str]:
        """Workers AI does not support streaming for custom calls; yield full response."""
        result = await self.complete(messages, temperature, max_tokens=max_tokens)
        yield result
