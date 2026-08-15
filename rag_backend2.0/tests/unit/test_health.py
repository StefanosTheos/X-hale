"""Configuration, liveness, and provider-readiness behavior."""
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app import health
from app.main import lifespan


@pytest.mark.asyncio
async def test_readiness_reports_all_dependencies_ready():
    health.clear_readiness_cache()
    with (
        patch.object(health, "missing_required_settings", return_value=[]),
        patch.object(health, "_check_appwrite", new=AsyncMock()),
        patch.object(health, "_check_qdrant", new=AsyncMock()),
        patch.object(health, "_check_groq", new=AsyncMock()),
        patch.object(health, "_check_cloudflare", new=AsyncMock()),
    ):
        result = await health.check_readiness(force=True)

    assert result["status"] == "ready"
    assert set(result["components"].values()) == {"ready"}


@pytest.mark.asyncio
async def test_readiness_is_not_ready_when_one_provider_fails():
    health.clear_readiness_cache()
    with (
        patch.object(health, "missing_required_settings", return_value=[]),
        patch.object(health, "_check_appwrite", new=AsyncMock()),
        patch.object(health, "_check_qdrant", new=AsyncMock(side_effect=RuntimeError("offline"))),
        patch.object(health, "_check_groq", new=AsyncMock()),
        patch.object(health, "_check_cloudflare", new=AsyncMock()),
    ):
        result = await health.check_readiness(force=True)

    assert result["status"] == "not_ready"
    assert result["components"]["qdrant"] == "not_ready"
    assert "offline" not in str(result)  # provider details stay in server logs


@pytest.mark.asyncio
async def test_missing_configuration_skips_provider_calls():
    health.clear_readiness_cache()
    appwrite = AsyncMock()
    with (
        patch.object(health, "missing_required_settings", return_value=["GROQ_API_KEY"]),
        patch.object(health, "_check_appwrite", new=appwrite),
    ):
        result = await health.check_readiness(force=True)

    assert result["status"] == "not_ready"
    assert result["components"]["configuration"] == "not_ready"
    assert result["components"]["appwrite"] == "not_checked"
    appwrite.assert_not_awaited()


@pytest.mark.asyncio
async def test_missing_required_configuration_fails_startup():
    with patch("app.health.missing_required_settings", return_value=["APPWRITE_API_KEY"]):
        with pytest.raises(RuntimeError, match="APPWRITE_API_KEY"):
            async with lifespan(MagicMock()):
                pass
