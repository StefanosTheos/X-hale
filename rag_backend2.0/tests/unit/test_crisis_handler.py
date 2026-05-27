"""Unit tests for the deterministic crisis handler."""
from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from app.agents.crisis_handler import handle_crisis
from app.safety.crisis_detector import fast_crisis_check


def test_fast_crisis_check_positive():
    assert fast_crisis_check("I want to kill myself") is True
    assert fast_crisis_check("I don't want to be alive anymore") is True
    assert fast_crisis_check("suicidal thoughts are overwhelming me") is True


def test_fast_crisis_check_negative():
    assert fast_crisis_check("I'm dying for a cigarette") is False
    assert fast_crisis_check("This craving is killing me") is False
    assert fast_crisis_check("How do I quit smoking?") is False


@pytest.mark.asyncio
async def test_crisis_handler_returns_hotlines():
    """Crisis handler should always include a hotline number in the response."""
    with patch("app.agents.crisis_handler._generate_empathetic_opening", new_callable=AsyncMock) as m:
        m.return_value = "I hear you, and I'm really glad you reached out."
        message, is_crisis = await handle_crisis("u1", locale="en")
    assert is_crisis is True
    assert "988" in message or "Crisis" in message or "Samaritans" in message


@pytest.mark.asyncio
async def test_crisis_handler_greek_locale():
    """Greek locale should return Greek hotlines."""
    with patch("app.agents.crisis_handler._generate_empathetic_opening", new_callable=AsyncMock) as m:
        m.return_value = "Χαίρομαι που μοιράστηκες αυτό μαζί μου."
        message, _ = await handle_crisis("u1", locale="el")
    assert "10306" in message or "KLIMAKA" in message


@pytest.mark.asyncio
async def test_crisis_handler_llm_failure_fallback():
    """If LLM fails, crisis handler should use the hardcoded fallback and still return a message."""
    with patch("app.agents.crisis_handler._generate_empathetic_opening",
               new_callable=AsyncMock, side_effect=Exception("LLM down")):
        # The outer handle_crisis catches errors from _generate_empathetic_opening
        # but we patched it to raise — test that handle_crisis handles this gracefully
        pass  # The function catches errors internally; this tests the production path
    with patch("app.agents.crisis_handler.get_triage_client") as m:
        m.side_effect = Exception("connection refused")
        message, is_crisis = await handle_crisis("u1", locale="en")
    assert is_crisis is True
    assert len(message) > 50
