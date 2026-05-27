"""
Reflection / Journal Agent prompt.

# ══════════════════════════════════════════════════════════════════
# PHASE 3 — NOT YET IMPLEMENTED
# ══════════════════════════════════════════════════════════════════
"""

REFLECTION_SYSTEM = """[PHASE 3 STUB — not yet active]
You are the Reflection component of a quit-smoking chatbot.
You read the user's diary entries and surface patterns, progress, and recurring themes.
"""

REFLECTION_USER_TEMPLATE = """User message: {user_input}
Recent diary entries: {diary_summary}
Return JSON SpecialistDraft."""
