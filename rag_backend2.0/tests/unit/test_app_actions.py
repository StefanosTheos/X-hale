import json
from pathlib import Path

from app.models.retrieval import AppAction
from app.tools.app_actions import VALID_DEEPLINKS, get_craving_actions, validate_action


def test_canonical_deeplink_registry_matches_mobile_contract():
    canonical = set(json.loads(
        (Path(__file__).parents[2] / "app/data/hailey_deeplinks.json").read_text()
    ))
    assert VALID_DEEPLINKS == canonical
    assert validate_action(AppAction(label="x", deeplink="xhale://doctor-visit")) is False


def test_fallback_actions_vary_by_situation_and_are_executable():
    sleep = get_craving_actions(3, "I am anxious in bed at night")
    work = get_craving_actions(3, "A work meeting triggered me")
    bored = get_craving_actions(3, "I am bored and need something for my hands")
    assert [a.deeplink for a in sleep] != [a.deeplink for a in work]
    assert [a.deeplink for a in work] != [a.deeplink for a in bored]
    assert all(a.deeplink in VALID_DEEPLINKS for a in sleep + work + bored)
    assert all(a.provenance == "fallback" for a in sleep + work + bored)
