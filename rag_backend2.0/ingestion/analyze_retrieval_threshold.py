"""Estimate a conservative retrieval cutoff from frozen benchmark query groups."""
from __future__ import annotations

import argparse
import asyncio
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path

import yaml

from app.config import settings
from app.llm.workers_ai_client import embed_local
from app.retrieval.vector_store import get_qdrant_client


POSITIVE_CATEGORIES = ("medical_factual", "medical_medication")
NEGATIVE_CATEGORY = "off_topic"


def _candidate_thresholds(scores: list[float]) -> list[float]:
    return sorted({round(score, 6) for score in scores})


async def analyze(suite_path: Path) -> dict:
    raw = suite_path.read_bytes()
    categories = yaml.safe_load(raw)["categories"]
    cases = [
        (category, case)
        for category in (*POSITIVE_CATEGORIES, NEGATIVE_CATEGORY)
        for case in categories[category]["cases"]
    ]
    vectors = await embed_local([case["input"] for _, case in cases])
    client = get_qdrant_client()
    observations = []
    for (category, case), vector in zip(cases, vectors):
        hits = await client.search(
            collection_name=settings.qdrant_kb_collection,
            query_vector=vector,
            limit=10,
            with_payload=True,
        )
        observations.append({
            "case_id": case["id"],
            "category": category,
            "top_scores": [round(float(hit.score), 8) for hit in hits],
            "top_source_ids": [str((hit.payload or {}).get("source_id", "<missing>")) for hit in hits],
        })

    positives = [item["top_scores"][0] for item in observations if item["category"] in POSITIVE_CATEGORIES]
    negatives = [item["top_scores"][0] for item in observations if item["category"] == NEGATIVE_CATEGORY]
    eligible = []
    for threshold in _candidate_thresholds(positives + negatives):
        sensitivity = sum(score >= threshold for score in positives) / len(positives)
        specificity = sum(score < threshold for score in negatives) / len(negatives)
        if sensitivity >= 0.95:
            eligible.append((specificity, threshold, sensitivity))
    specificity, selected, sensitivity = max(eligible)
    operational_threshold = math.floor(selected * 10) / 10
    operational_sensitivity = sum(score >= operational_threshold for score in positives) / len(positives)
    operational_specificity = sum(score < operational_threshold for score in negatives) / len(negatives)

    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "method": "highest observed top-1 cosine cutoff retaining at least 95% medical/NRT query coverage; off-topic cases used as negative controls",
        "suite_path": str(suite_path).replace("\\", "/"),
        "suite_sha256": hashlib.sha256(raw).hexdigest(),
        "collection": settings.qdrant_kb_collection,
        "embedding_model": "BAAI/bge-small-en-v1.5 via FastEmbed",
        "positive_categories": list(POSITIVE_CATEGORIES),
        "positive_cases": len(positives),
        "negative_category": NEGATIVE_CATEGORY,
        "negative_cases": len(negatives),
        "minimum_required_sensitivity": 0.95,
        "selected_threshold": selected,
        "observed_sensitivity": sensitivity,
        "observed_specificity": specificity,
        "operational_threshold": operational_threshold,
        "operational_threshold_rationale": "raw cutoff rounded downward to one decimal to reduce sample-specific overfitting",
        "operational_sensitivity": operational_sensitivity,
        "operational_specificity": operational_specificity,
        "positive_top1_range": [min(positives), max(positives)],
        "negative_top1_range": [min(negatives), max(negatives)],
        "observations": observations,
        "limitations": [
            "Query-category labels are proxy relevance labels, not clinician judgments of each retrieved chunk.",
            "The cutoff is specific to this corpus, embedding model, and authored English benchmark suite.",
            "A new corpus or embedding model requires recalibration and a new benchmark.",
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--suite", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = asyncio.run(analyze(args.suite))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: result[key] for key in (
        "selected_threshold", "observed_sensitivity", "observed_specificity",
        "operational_threshold", "operational_sensitivity", "operational_specificity",
        "positive_top1_range", "negative_top1_range",
    )}))


if __name__ == "__main__":
    main()
