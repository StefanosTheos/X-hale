"""
Appwrite JWT verification.

Verifies a user JWT by calling Account.get() through the Appwrite Python SDK
(which uses the requests transport — the same as all other Appwrite calls in
this codebase, avoiding the httpx connectivity issues on some networks).

Every protected HTTP request is verified against Appwrite. Authentication is
performed once before an SSE response starts, not once per streamed chunk.
"""
from __future__ import annotations

import asyncio
from typing import Optional

from appwrite.client import Client
from appwrite.exception import AppwriteException
from appwrite.services.account import Account

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)

async def verify_appwrite_jwt(token: str) -> Optional[str]:
    """
    Verify an Appwrite JWT and return the user_id on success, or None on failure.

    Successful results are deliberately not cached: a token revoked in Appwrite
    must be rejected by the next protected request rather than remaining usable
    for a local cache window.
    """
    return await _call_appwrite_account(token)


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
