"""Governance metadata for the curated cessation knowledge sources."""
from datetime import date
from pathlib import Path

import yaml


MANIFEST = Path(__file__).parents[2] / "ingestion" / "sources.yaml"


def test_all_manifest_sources_have_bounded_governance_metadata():
    data = yaml.safe_load(MANIFEST.read_text(encoding="utf-8"))
    sources = data["sources"]

    assert len(sources) == 28
    assert len({source["source_id"] for source in sources}) == 28

    for source in sources:
        governance = source["governance"]
        assert governance["fetch_date"] is None
        assert governance["fetch_date_status"] == "unavailable"
        assert governance["reviewer_name"] == "Stefanos Theos"
        assert governance["access_status"] == "publicly_accessible"
        assert governance["licensing_status"] == (
            "reuse_license_and_permission_not_independently_verified"
        )
        assert governance["content_version"] == "unavailable"
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
