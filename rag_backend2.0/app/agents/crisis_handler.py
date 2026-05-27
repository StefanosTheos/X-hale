"""
Crisis Handler — deterministic Python. NOT an LLM agent.

Triggered when triage.crisis_flag == True.
Bypasses the normal agent pipeline entirely.

Returns a fixed, vetted safety message with:
  1. One LLM-generated empathetic opening sentence (tightly constrained).
  2. A deterministic body with hotline resources.

IMPORTANT: The LLM is ONLY used to generate a single empathetic opening sentence.
The hotlines, body content, and safety framing are ALL deterministic.
This is non-negotiable for user safety.
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

    # Try to generate one empathetic opening sentence
    opening = await _generate_empathetic_opening()

    hotlines_text = format_hotlines_for_message(locale)
    body = _DETERMINISTIC_BODY.format(hotlines=hotlines_text)

    full_message = opening + "\n" + body
    return full_message, True


async def _generate_empathetic_opening() -> str:
    """
    Generate ONE empathetic sentence using a tightly constrained prompt.
    Falls back to a hardcoded string on any failure.
    """
    try:
        from app.llm.client import get_triage_client
        from app.prompts.crisis_oneliner import CRISIS_ONELINER_SYSTEM, CRISIS_ONELINER_USER
        client = get_triage_client()
        result = await client.complete(
            messages=[
                {"role": "system", "content": CRISIS_ONELINER_SYSTEM},
                {"role": "user", "content": CRISIS_ONELINER_USER},
            ],
            temperature=0.3,
            max_tokens=60,
        )
        # Validate: must be a single sentence under 30 words
        sentence = result.strip().strip('"').split(".")[0] + "."
        if len(sentence.split()) <= 30:
            return sentence
    except Exception as exc:
        logger.warning("crisis_oneliner_failed", error=str(exc))
    return _EMPATHY_FALLBACK
