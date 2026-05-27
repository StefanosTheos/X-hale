"""
Deeplink generator for the Craving Support Agent.

Maps craving-support strategies to in-app navigation deeplinks.
The Flutter app must register these URI schemes in its router.

URI scheme: xhale://<route>
"""
from __future__ import annotations

from app.models.retrieval import AppAction


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


def get_craving_actions(limit: int = 3) -> list[AppAction]:
    """Return the top craving-support actions."""
    return CRAVING_ACTIONS[:limit]


def get_action_by_strategy(strategy: str) -> AppAction | None:
    """Look up an action by strategy keyword (fuzzy)."""
    strategy_lower = strategy.lower()
    for action in CRAVING_ACTIONS:
        if any(kw in action.deeplink for kw in strategy_lower.split()):
            return action
    return None
