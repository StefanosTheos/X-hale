"""Appwrite JWT verification and revocation behavior."""
from unittest.mock import AsyncMock, patch

import pytest

from app.auth import appwrite_jwt


@pytest.mark.asyncio
async def test_each_request_is_verified_against_appwrite():
    verifier = AsyncMock(side_effect=["user-1", None])

    with patch.object(appwrite_jwt, "_call_appwrite_account", new=verifier):
        first_result = await appwrite_jwt.verify_appwrite_jwt("same-token")
        result_after_revocation = await appwrite_jwt.verify_appwrite_jwt("same-token")

    assert first_result == "user-1"
    assert result_after_revocation is None
    assert verifier.await_count == 2
    verifier.assert_any_await("same-token")
