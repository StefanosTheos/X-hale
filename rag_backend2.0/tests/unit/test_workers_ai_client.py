"""Cloudflare embedding transport and local fallback behavior."""
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import requests

from app.llm import workers_ai_client


def test_cloudflare_transport_uses_default_tls_first():
    response = MagicMock()
    response.json.return_value = {"result": {"data": [[0.0] * 384]}}
    with patch.object(workers_ai_client.requests, "post", return_value=response) as post:
        result = workers_ai_client._post_json_sync("https://example.test", {"text": ["x"]})

    assert result == response.json.return_value
    post.assert_called_once()
    response.raise_for_status.assert_called_once()


def test_cloudflare_transport_retries_tls12_after_default_tls_error():
    response = MagicMock()
    response.json.return_value = {"ok": True}
    session = MagicMock()
    session.__enter__.return_value = session
    session.post.return_value = response
    with (
        patch.object(
            workers_ai_client.requests,
            "post",
            side_effect=requests.exceptions.SSLError("default TLS failed"),
        ),
        patch.object(workers_ai_client.requests, "Session", return_value=session),
    ):
        result = workers_ai_client._post_json_sync("https://example.test", {})

    assert result == {"ok": True}
    session.mount.assert_called_once()
    response.raise_for_status.assert_called_once()


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
