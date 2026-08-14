"""Focused tests for deterministic benchmark checks."""
from finetune.eval.run_benchmark import _lexical_theme_check


def test_expected_theme_coverage_accepts_common_word_variants():
    result = _lexical_theme_check(
        "Cravings usually improve over several weeks, and breathing can help.",
        ["craving", "improvement", "weeks", "nicotine", "sleep"],
    )
    assert result.passed is True


def test_expected_theme_coverage_rejects_unrelated_response():
    result = _lexical_theme_check(
        "Try opening the dashboard and checking your profile.",
        ["lung recovery", "timeline", "oxygen"],
    )
    assert result.passed is False


def test_expected_theme_coverage_is_neutral_when_not_declared():
    result = _lexical_theme_check("A response", [])
    assert result.passed is True
