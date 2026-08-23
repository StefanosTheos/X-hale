"""Governance metadata for the curated cessation knowledge sources."""
from datetime import date
from pathlib import Path

import yaml


MANIFEST = Path(__file__).parents[2] / "ingestion" / "sources.yaml"


def test_all_manifest_sources_have_bounded_governance_metadata():
    data = yaml.safe_load(MANIFEST.read_text(encoding="utf-8"))
    sources = data["sources"]

    assert len(sources) == 30
    assert len({source["source_id"] for source in sources}) == 30

    for source in sources:
        governance = source["governance"]
        if source["source_id"] in {"smokefree_workout_effects", "cdc_tobacco_oral_health"}:
            assert str(governance["fetch_date"]) == "2026-08-23"
            assert governance["fetch_date_status"] == "verified_during_developer_review"
        else:
            assert governance["fetch_date"] is None
            assert governance["fetch_date_status"] == "unavailable"
        assert governance["reviewer_name"] == "Stefanos Theos"
        assert governance["access_status"] == "publicly_accessible"
        assert governance["licensing_status"] == (
            "reuse_license_and_permission_not_independently_verified"
        )
        assert governance["content_version"]
        assert governance["content_sha256"] == "unavailable"
        assert governance["inclusion_decision"] == "included_after_developer_review"
        assert governance["independent_content_review"] == "pending"
        assert date.fromisoformat(str(governance["next_scheduled_review"]))


def test_ingestion_evidence_dates_match_repository_history_groups():
    sources = yaml.safe_load(MANIFEST.read_text(encoding="utf-8"))["sources"]
    evidence_dates = [
        str(source["governance"]["ingestion_evidence_date"])
        for source in sources
    ]

    assert evidence_dates.count("2026-05-27") == 5
    assert evidence_dates.count("2026-06-12") == 23
    assert evidence_dates.count("2026-08-23") == 2
