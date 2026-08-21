"""LLM retry policy regressions."""
import pytest

from app.llm.client import retry_with_backoff


class RateLimitErrorForTest(Exception):
    status_code = 429


@pytest.mark.asyncio
async def test_daily_token_quota_is_not_retried():
    attempts = 0

    async def fail():
        nonlocal attempts
        attempts += 1
        raise RateLimitErrorForTest(
            "rate_limit_exceeded: tokens per day limit reached"
        )

    with pytest.raises(RateLimitErrorForTest):
        await retry_with_backoff(fail, max_attempts=3, base_delay=0)
    assert attempts == 1


@pytest.mark.asyncio
async def test_transient_rate_limit_can_recover():
    attempts = 0

    async def recover():
        nonlocal attempts
        attempts += 1
        if attempts == 1:
            raise RateLimitErrorForTest("requests per minute limit reached")
        return "ok"

    assert await retry_with_backoff(recover, max_attempts=3, base_delay=0) == "ok"
    assert attempts == 2
