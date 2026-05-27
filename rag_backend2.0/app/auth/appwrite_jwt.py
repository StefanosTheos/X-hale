"""
Appwrite JWT verification.

Appwrite does not expose a public key for offline JWT verification.
The canonical approach is to call GET /account with the user's JWT as a
Bearer token. If the call succeeds the token is valid and we get the user's ID.

Verified tokens are cached in-process for `settings.jwt_cache_ttl_seconds`
(default 60s) to avoid hammering Appwrite on every SSE chunk.
"""
from __future__ import annotations

import asyncio
import time
from typing import Optional

import httpx

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)

# Simple TTL cache: {token_hash: (user_id, expires_at)}
_cache: dict[str, tuple[str, float]] = {}
_cache_lock = asyncio.Lock()


async def verify_appwrite_jwt(token: str) -> Optional[str]:
    """
    Verify an Appwrite JWT and return the user_id on success, or None on failure.
    Uses an in-process TTL cache to avoid repeated Appwrite calls.
    """
    import hashlib
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    now = time.monotonic()

    async with _cache_lock:
        cached = _cache.get(token_hash)
        if cached:
            user_id, expires_at = cached
            if now < expires_at:
                return user_id
            else:
                del _cache[token_hash]

    user_id = await _call_appwrite_account(token)

    if user_id:
        async with _cache_lock:
            _cache[token_hash] = (user_id, now + settings.jwt_cache_ttl_seconds)

    return user_id


async def _call_appwrite_account(token: str) -> Optional[str]:
    """Make a single GET /account call with the user JWT to verify it."""
    url = f"{settings.appwrite_endpoint}/account"
    headers = {
        "X-Appwrite-Project": settings.appwrite_project_id,
        "X-Appwrite-JWT": token,
        "Content-Type": "application/json",
    }
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(url, headers=headers)
        if resp.status_code == 200:
            data = resp.json()
            return data.get("$id")
        logger.warning("appwrite_jwt_verify_failed", status=resp.status_code)
        return None
    except httpx.RequestError as exc:
        logger.warning("appwrite_jwt_request_error", error=str(exc))
        return None
