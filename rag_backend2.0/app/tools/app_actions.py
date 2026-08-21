"""
Deeplink generator for the Craving Support Agent.

Maps craving-support strategies to in-app navigation deeplinks.
The Flutter app must register these URI schemes in its router.

URI scheme: xhale://<route>
"""
from __future__ import annotations

import json
from pathlib import Path

from app.models.retrieval import AppAction

_REGISTRY_PATH = Path(__file__).parents[1] / "data" / "hailey_deeplinks.json"
VALID_DEEPLINKS = frozenset(json.loads(_REGISTRY_PATH.read_text(encoding="utf-8")))


# Static mapping of strategy → AppAction
# Extend this as new features are added to the Flutter app.
CRAVING_ACTIONS: list[AppAction] = [
    AppAction(
        label="Try a breathing exercise",
        deeplink="xhale://breathing",
        description="Box breathing, 4-7-8, or Nadi Shodhana — takes 2-5 minutes",
    ),
    AppAction(
        label="Spin the Wheel",
        deeplink="xhale://distractions/spin",
        description="Random distraction activity to shift your attention",
    ),
    AppAction(
        label="Play a quick game",
        deeplink="xhale://explore/games",
        description="Snake, Flappy Bird, 2048 — gives your hands something to do",
    ),
    AppAction(
        label="Write in your diary",
        deeplink="xhale://diary/new",
        description="Logging how you feel can defuse the craving",
    ),
    AppAction(
        label="View your progress",
        deeplink="xhale://dashboard",
        description="See how far you've come — remind yourself why you quit",
    ),
    AppAction(
        label="Try stretching",
        deeplink="xhale://distractions/stretches",
        description="Physical movement helps reduce craving intensity",
    ),
    AppAction(
        label="Listen to ambient sounds",
        deeplink="xhale://distractions/sounds",
        description="Calming background sounds to help you wait it out",
    ),
]


def validate_action(action: AppAction) -> bool:
    return action.deeplink in VALID_DEEPLINKS


def get_craving_actions(limit: int = 3, situation: str = "") -> list[AppAction]:
    """Return varied rule-based fallbacks appropriate to the situation."""
    text = situation.casefold()
    if any(word in text for word in ("bed", "sleep", "night", "anxious", "panic")):
        preferred = ["xhale://distractions/sounds", "xhale://breathing", "xhale://diary/new"]
    elif any(word in text for word in ("work", "meeting", "desk", "call", "break")):
        preferred = ["xhale://distractions/stretches", "xhale://distractions/spin", "xhale://diary/new"]
    elif any(word in text for word in ("hands", "bored", "waiting", "alone")):
        preferred = ["xhale://explore/games", "xhale://distractions/spin", "xhale://diary/new"]
    elif any(word in text for word in ("motivation", "progress", "why", "proud")):
        preferred = ["xhale://dashboard", "xhale://achievements", "xhale://diary/new"]
    else:
        preferred = ["xhale://distractions/spin", "xhale://breathing", "xhale://explore/games"]
    by_uri = {action.deeplink: action for action in CRAVING_ACTIONS}
    return [
        by_uri[uri].model_copy(update={"provenance": "fallback"})
        for uri in preferred[:limit]
    ]


def get_action_by_strategy(strategy: str) -> AppAction | None:
    """Look up an action by strategy keyword (fuzzy)."""
    strategy_lower = strategy.lower()
    for action in CRAVING_ACTIONS:
        if any(kw in action.deeplink for kw in strategy_lower.split()):
            return action
    return None
