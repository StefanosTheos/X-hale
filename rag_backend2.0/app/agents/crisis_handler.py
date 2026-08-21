"""
Crisis Handler — deterministic Python. NOT an LLM agent.

Triggered when triage.crisis_flag == True.
Bypasses the normal agent pipeline entirely.

Returns a fixed, vetted safety message. No remote model call is made on this
path: crisis guidance must remain immediate and available during provider
latency or outages.
"""
from __future__ import annotations

from app.observability.logging import get_logger
from app.observability.metrics import record_request
from app.safety.hotlines import format_hotlines_for_message

logger = get_logger(__name__)

_DETERMINISTIC_BODY = """
I want to make sure you have access to real support right now.

Please reach out to one of these services — they're available to talk:

{hotlines}

You don't have to go through this alone. These services exist exactly for moments like this, and the people there are trained to listen without judgment.

If you're ever ready to talk more about your quit journey, I'm here.
"""

_EMPATHY_FALLBACK = "I hear you, and I'm really glad you reached out."


async def handle_crisis(user_id: str, locale: str = "en") -> tuple[str, bool]:
    """
    Generate the crisis response.
    Returns (message_text, is_crisis=True).
    """
    record_request("crisis")
    logger.info("crisis_handler_activated", user_id=user_id, locale=locale)

    opening = _EMPATHY_FALLBACK

    hotlines_text = format_hotlines_for_message(locale)
    body = _DETERMINISTIC_BODY.format(hotlines=hotlines_text)

    full_message = opening + "\n" + body
    return full_message, True
