"""Cloudflare embedding transport and local fallback behavior."""
from unittest.mock import AsyncMock, patch

import pytest
import requests

from app.llm import workers_ai_client


@pytest.mark.asyncio
async def test_embed_uses_local_fallback_after_cloudflare_transport_failure():
    fallback_vector = [0.25] * 384
    with (
        patch.object(
            workers_ai_client,
            "_post_json",
            new=AsyncMock(side_effect=requests.exceptions.SSLError("TLS failure")),
        ),
        patch.object(
            workers_ai_client,
            "embed_local",
            new=AsyncMock(return_value=[fallback_vector]),
        ) as local_embed,
        patch.object(workers_ai_client.settings, "enable_local_embedding_fallback", True),
    ):
        result = await workers_ai_client.embed("test query")

    assert result == fallback_vector
    local_embed.assert_awaited_once_with(["test query"])


@pytest.mark.asyncio
async def test_embed_propagates_transport_failure_when_fallback_is_disabled():
    with (
        patch.object(
            workers_ai_client,
            "_post_json",
            new=AsyncMock(side_effect=requests.exceptions.SSLError("TLS failure")),
        ),
        patch.object(workers_ai_client.settings, "enable_local_embedding_fallback", False),
    ):
        with pytest.raises(requests.exceptions.SSLError):
            await workers_ai_client.embed("test query")
