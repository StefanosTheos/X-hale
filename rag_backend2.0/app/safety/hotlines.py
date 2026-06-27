"""
Static locale-to-hotline mapping.
Used by the Crisis Handler to select appropriate resources for the user's locale.
Add new locales as the app expands to new markets.

IMPORTANT: Review hotline numbers periodically — they change.
Last verified: 2026-06-27
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
            name="KLIMAKA — Γραμμή Παρέμβασης για την Αυτοκτονία",
            number="1018",
            url="https://suicide-help.gr",
            available_24_7=True,
            description="Εθνική γραμμή κρίσης και πρόληψης αυτοκτονίας (24/7, δωρεάν)",
        ),
        Hotline(
            name="Γραμμή Ψυχολογικής Υποστήριξης 10306",
            number="10306",
            url="https://www.klimaka.org.gr",
            available_24_7=True,
            description="Ψυχολογική υποστήριξη για άγχος, πένθος, οικογενειακές κρίσεις",
        ),
        Hotline(
            name="ΕΚΚΑ — Γραμμή Κοινωνικής Βοήθειας",
            number="197",
            url="https://www.ekka.org.gr",
            available_24_7=True,
            description="Έκτακτη κοινωνική βοήθεια (άστεγοι, ενδοοικογενειακή βία, τράφικινγκ)",
        ),
    ],
    "en": [
        # ── United States ──────────────────────────────────────────────────────
        Hotline(
            name="988 Suicide & Crisis Lifeline (US)",
            number="988",
            url="https://988lifeline.org",
            available_24_7=True,
            description="US national crisis line — call, text, or chat 988",
        ),
        Hotline(
            name="Crisis Text Line (US)",
            number="",
            sms="HOME to 741741",
            url="https://www.crisistextline.org",
            available_24_7=True,
            description="Free text-based crisis support (US and Puerto Rico)",
        ),
        # ── United Kingdom ─────────────────────────────────────────────────────
        Hotline(
            name="Samaritans (UK & Ireland)",
            number="116 123",
            url="https://www.samaritans.org",
            available_24_7=True,
            description="Free, confidential support — call any time",
        ),
        Hotline(
            name="Shout Crisis Text Line (UK)",
            number="",
            sms="SHOUT to 85258",
            url="https://www.giveusashout.org",
            available_24_7=True,
            description="Free 24/7 text crisis support (UK)",
        ),
        # ── Canada ─────────────────────────────────────────────────────────────
        Hotline(
            name="9-8-8 Suicide Crisis Helpline (Canada)",
            number="988",
            url="https://988.ca",
            available_24_7=True,
            description="Canada's national crisis line — call or text 988 (English & French)",
        ),
        Hotline(
            name="Crisis Text Line (Canada)",
            number="",
            sms="CONNECT to 686868",
            url="https://www.kidshelphone.ca",
            available_24_7=True,
            description="Free text-based crisis support via Kids Help Phone",
        ),
        # ── Ireland ────────────────────────────────────────────────────────────
        Hotline(
            name="Text About It (Ireland)",
            number="",
            sms="HELLO to 50808",
            url="https://text50808.ie",
            available_24_7=True,
            description="Free 24/7 text crisis support (Ireland)",
        ),
        # ── Australia ──────────────────────────────────────────────────────────
        Hotline(
            name="Lifeline (Australia)",
            number="13 11 14",
            sms="0477 13 11 14",
            url="https://www.lifeline.org.au",
            available_24_7=True,
            description="Crisis support and suicide prevention (call or text 24/7)",
        ),
        Hotline(
            name="Beyond Blue (Australia)",
            number="1300 22 4636",
            url="https://www.beyondblue.org.au",
            available_24_7=True,
            description="Anxiety, depression, and mental wellbeing support",
        ),
        # ── International directory ────────────────────────────────────────────
        Hotline(
            name="Find A Helpline (worldwide)",
            number="",
            url="https://findahelpline.com/i/iasp",
            available_24_7=True,
            description="Find a verified crisis centre in your country (150+ countries)",
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
