"""
Static locale-to-hotline mapping.
Used by the Crisis Handler to select appropriate resources for the user's locale.
Add new locales as the app expands to new markets.

IMPORTANT: Review hotline numbers periodically — they change.
Last verified: 2025-05-27
"""
from __future__ import annotations

from typing import Optional
from pydantic import BaseModel


class Hotline(BaseModel):
    name: str
    number: str
    sms: Optional[str] = None
    url: Optional[str] = None
    available_24_7: bool = True
    description: str = ""


# Locale → list of hotlines, ordered by relevance
HOTLINES: dict[str, list[Hotline]] = {
    "el": [
        Hotline(
            name="KLIMAKA — Crisis Helpline",
            number="10306",
            url="https://www.klimaka.org.gr",
            available_24_7=True,
            description="Greek national crisis and suicide prevention line",
        ),
        Hotline(
            name="SOS Line 197",
            number="197",
            url="https://www.sos-line.gr",
            available_24_7=False,
            description="Mental health support line (Greece)",
        ),
    ],
    "en": [
        Hotline(
            name="International Association for Suicide Prevention",
            number="",
            url="https://www.iasp.info/resources/Crisis_Centres/",
            available_24_7=True,
            description="Find a crisis centre in your country",
        ),
        Hotline(
            name="Crisis Text Line (US/UK/CA/IE)",
            number="",
            sms="HOME to 741741",
            url="https://www.crisistextline.org",
            available_24_7=True,
            description="Text-based crisis support",
        ),
        Hotline(
            name="988 Suicide & Crisis Lifeline (US)",
            number="988",
            url="https://988lifeline.org",
            available_24_7=True,
            description="US national crisis line — call or text 988",
        ),
        Hotline(
            name="Samaritans (UK/IE)",
            number="116 123",
            url="https://www.samaritans.org",
            available_24_7=True,
            description="Free, confidential support in the UK and Ireland",
        ),
    ],
}

_DEFAULT_LOCALE = "en"


def get_hotlines(locale: str) -> list[Hotline]:
    """Return hotlines for the given locale, falling back to English."""
    return HOTLINES.get(locale, HOTLINES[_DEFAULT_LOCALE])


def format_hotlines_for_message(locale: str) -> str:
    """Return a human-readable hotline block for injection into the crisis message."""
    lines: list[str] = []
    for h in get_hotlines(locale):
        parts = [f"**{h.name}**"]
        if h.number:
            parts.append(f"📞 {h.number}")
        if h.sms:
            parts.append(f"💬 {h.sms}")
        if h.url:
            parts.append(f"🌐 {h.url}")
        lines.append(" | ".join(parts))
    return "\n".join(lines)
