"""Regression checks for the archived retrieval-threshold calibration."""
import json
from pathlib import Path

from app.config import settings


ARTIFACT = (
    Path(__file__).parents[2]
    / "ingestion"
    / "artifacts"
    / "retrieval_threshold_analysis_2026-08-15.json"
)


def test_operational_threshold_matches_archived_analysis_and_configuration():
    analysis = json.loads(ARTIFACT.read_text(encoding="utf-8"))

    assert analysis["positive_cases"] == 60
    assert analysis["negative_cases"] == 30
    assert analysis["operational_threshold"] == settings.retrieval_min_score == 0.60
    assert analysis["operational_sensitivity"] >= 0.98
    assert analysis["operational_specificity"] == 1.0
    assert len(analysis["observations"]) == 90
