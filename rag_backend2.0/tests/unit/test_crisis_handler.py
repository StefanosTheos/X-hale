"""Unit tests for the deterministic crisis handler."""
from __future__ import annotations

import pytest

from app.agents.crisis_handler import _EMPATHY_FALLBACK, handle_crisis
from app.safety.crisis_detector import fast_crisis_check


def test_fast_crisis_check_positive():
    assert fast_crisis_check("I want to kill myself") is True
    assert fast_crisis_check("I don't want to be alive anymore") is True
    assert fast_crisis_check("suicidal thoughts are overwhelming me") is True


@pytest.mark.parametrize(
    "message",
    [
        "I feel completely trapped and I don't see any way out of this",
        "I woke up this morning wishing I hadn't",
        "Life has felt completely meaningless since I stopped smoking",
        "I haven't left the house in two weeks and I'm in a very dark place",
        "I feel like I'm slowly destroying myself anyway so what's the point in stopping",
        "I've written a letter to my family just in case something happens to me",
        "The only thing keeping me going right now is my dog, honestly",
        "I feel like giving up on absolutely everything, not just smoking",
    ],
)
def test_fast_crisis_check_indirect_positive(message):
    assert fast_crisis_check(message) is True


def test_fast_crisis_check_negative():
    assert fast_crisis_check("I'm dying for a cigarette") is False
    assert fast_crisis_check("This craving is killing me") is False
    assert fast_crisis_check("How do I quit smoking?") is False


@pytest.mark.parametrize(
    "message",
    [
        "I'm trapped in traffic and I can't find a way out of the car park",
        "I wish I hadn't smoked that cigarette this morning",
        "The book argues that life is meaningless",
        "I haven't left the house because I'm recovering from surgery",
        "Smoking is destroying my lungs, so I want to stop",
        "I wrote my family a letter about our holiday plans just in case I forget",
        "My dog keeps me going on daily walks",
        "I feel like giving up on this puzzle",
    ],
)
def test_fast_crisis_check_indirect_negative_controls(message):
    assert fast_crisis_check(message) is False


@pytest.mark.asyncio
async def test_crisis_handler_returns_hotlines():
    """Crisis handler should always include a hotline number in the response."""
    message, is_crisis = await handle_crisis("u1", locale="en")
    assert is_crisis is True
    assert "988" in message or "Crisis" in message or "Samaritans" in message


@pytest.mark.asyncio
async def test_crisis_handler_greek_locale():
    """Greek locale should return Greek hotlines."""
    message, _ = await handle_crisis("u1", locale="el")
    assert "10306" in message or "KLIMAKA" in message


@pytest.mark.asyncio
async def test_crisis_handler_is_deterministic_and_well_formed():
    """Crisis output never waits for an LLM or accepts punctuation-only text."""
    message, is_crisis = await handle_crisis("u1", locale="en")
    assert is_crisis is True
    assert message.startswith(_EMPATHY_FALLBACK)
    assert not message.startswith(".")
    assert len(message) > 50
