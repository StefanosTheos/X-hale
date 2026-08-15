"""Integrity checks for the archived frozen-corpus inventory."""
import json
from pathlib import Path

from ingestion.inventory_corpus import _sha256


ARTIFACT = (
    Path(__file__).parents[2]
    / "ingestion"
    / "artifacts"
    / "qdrant_inventory_2026-08-15.json"
)


def test_archived_inventory_hash_and_evaluation_identity_are_valid():
    inventory = json.loads(ARTIFACT.read_text(encoding="utf-8"))
    archived_hash = inventory.pop("snapshot_sha256")

    assert _sha256(inventory) == archived_hash
    assert inventory["read_only_snapshot"] is True
    assert inventory["application_commit"] == (
        "7793af0034cd6820e4f52f18301bd6d9f2d3ef78"
    )
    assert inventory["source_manifest_revision"] == inventory["application_commit"]
    assert inventory["benchmark_run_id"] == "31889842986"


def test_archived_inventory_reports_live_counts_dimensions_and_manifest_difference():
    inventory = json.loads(ARTIFACT.read_text(encoding="utf-8"))
    collections = {item["collection"]: item for item in inventory["collections"]}
    kb = collections["kb_chunks"]
    health = collections["health_benefit_chunks"]

    assert kb["reported_points_count"] == kb["inventoried_points_count"] == 487
    assert health["reported_points_count"] == health["inventoried_points_count"] == 25
    assert kb["vector_dimensions"] == {"384": 487}
    assert health["vector_dimensions"] == {"384": 25}
    assert kb["required_payload_complete"] is True
    assert health["required_payload_complete"] is True

    comparison = inventory["manifest_deployment_comparison"]
    assert comparison["manifest_source_count"] == 28
    assert comparison["deployed_kb_source_count"] == 23
    assert comparison["manifest_sources_absent_from_kb_chunks"] == [
        "acs_quit_timeline",
        "aha_why_quit",
        "cdc_benefits_timeline",
        "mayo_quit_smoking",
        "nhs_quit_benefits",
    ]
    assert comparison["kb_chunk_sources_absent_from_manifest"] == []


def test_archived_point_inventory_excludes_content_and_vectors():
    inventory = json.loads(ARTIFACT.read_text(encoding="utf-8"))
    allowed = {"point_id", "source_id", "chunk_index", "total_chunks", "benefit_id"}
    for collection in inventory["collections"]:
        for identifier in collection["source_chunk_identifiers"]:
            assert set(identifier) == allowed
