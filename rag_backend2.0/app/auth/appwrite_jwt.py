"""
Appwrite JWT verification.

Verifies a user JWT by calling Account.get() through the Appwrite Python SDK
(which uses the requests transport — the same as all other Appwrite calls in
this codebase, avoiding the httpx connectivity issues on some networks).

Verified tokens are cached in-process for `settings.jwt_cache_ttl_seconds`
(default 60s) to avoid hammering Appwrite on every SSE chunk.
"""
from __future__ import annotations

import asyncio
import time
from typing import Optional

from appwrite.client import Client
from appwrite.exception import AppwriteException
from appwrite.services.account import Account

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


async def invalidate_user_tokens(user_id: str) -> None:
    """Remove cached JWT verifications for an account that has been deleted."""
    async with _cache_lock:
        stale = [token_hash for token_hash, (cached_user, _) in _cache.items() if cached_user == user_id]
        for token_hash in stale:
            del _cache[token_hash]


def _verify_jwt_sync(token: str) -> Optional[str]:
    """Synchronous JWT verification via the Appwrite SDK (requests transport)."""
    client = Client()
    (
        client
        .set_endpoint(settings.appwrite_endpoint)
        .set_project(settings.appwrite_project_id)
        .set_jwt(token)
    )
    account = Account(client)
    try:
        user = account.get()
        return user.id
    except AppwriteException as exc:
        logger.warning("appwrite_jwt_verify_failed", status=exc.code, message=exc.message)
        return None


async def _call_appwrite_account(token: str) -> Optional[str]:
    """Run JWT verification in a thread (SDK is synchronous)."""
    try:
        return await asyncio.to_thread(_verify_jwt_sync, token)
    except Exception as exc:
        logger.warning("appwrite_jwt_request_error", error=str(exc))
        return None
