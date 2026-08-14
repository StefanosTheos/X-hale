"""Aggregate deterministic benchmark shard artifacts into one verified full sweep."""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from finetune.eval.run_benchmark import _load_cases, _suite_hash


def aggregate(paths: list[Path]) -> dict:
    expected_cases = _load_cases()
    expected_ids = [case.id for case in expected_cases]
    expected_set = set(expected_ids)
    expected_hash = _suite_hash(expected_cases)
    documents = [json.loads(path.read_text(encoding="utf-8")) for path in paths]
    if not documents:
        raise ValueError("no shard artifacts supplied")

    identity_keys = ("suite_hash", "suite_total", "source_commit", "judge_provider", "judge_model")
    identity = {key: documents[0].get(key) for key in identity_keys}
    if identity["suite_hash"] != expected_hash or identity["suite_total"] != len(expected_ids):
        raise ValueError("shards do not match the current 300-case suite")

    cases_by_id: dict[str, dict] = {}
    shard_indices: set[int] = set()
    shard_count = documents[0].get("shard_count")
    for document in documents:
        for key, value in identity.items():
            if document.get(key) != value:
                raise ValueError(f"mixed shard identity for {key}")
        if document.get("shard_count") != shard_count:
            raise ValueError("mixed shard counts")
        if not document.get("complete"):
            raise ValueError(f"shard {document.get('shard_index')} is incomplete")
        shard_index = int(document["shard_index"])
        if shard_index in shard_indices:
            raise ValueError(f"duplicate shard index {shard_index}")
        shard_indices.add(shard_index)
        for case in document.get("cases", []):
            case_id = case["case_id"]
            if case_id in cases_by_id:
                raise ValueError(f"duplicate case ID {case_id}")
            cases_by_id[case_id] = case

    missing = [case_id for case_id in expected_ids if case_id not in cases_by_id]
    unexpected = sorted(set(cases_by_id) - expected_set)
    if missing or unexpected:
        raise ValueError(f"suite coverage mismatch; missing={missing}, unexpected={unexpected}")

    cases = [cases_by_id[case_id] for case_id in expected_ids]
    evaluated = [case for case in cases if not case.get("error")]
    errored = [case for case in cases if case.get("error")]
    quality = round(100 * sum(1 for case in evaluated if case.get("passed")) / len(evaluated)) if evaluated else 0
    error_rate = round(100 * len(errored) / len(cases))
    return {
        "schema_version": 4,
        "aggregation_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        **identity,
        "shard_count": shard_count,
        "shards": sorted(shard_indices),
        "complete": True,
        "total": len(cases),
        "evaluated": len(evaluated),
        "passed": sum(1 for case in evaluated if case.get("passed")),
        "errors": len(errored),
        "quality_pct": quality,
        "error_rate_pct": error_rate,
        "quality_threshold_pct": 80,
        "maximum_error_rate_pct": 20,
        "cases": cases,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Aggregate Hailey benchmark shards")
    parser.add_argument("inputs", nargs="+", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        result = aggregate(args.inputs)
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(f"FAIL — {exc}", file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(
        f"Full sweep: quality {result['quality_pct']}%, errors {result['error_rate_pct']}% "
        f"({result['total']} unique cases)"
    )
    return 0 if result["quality_pct"] >= 80 and result["error_rate_pct"] <= 20 else 1


if __name__ == "__main__":
    sys.exit(main())
