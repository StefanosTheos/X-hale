"""Strict full-sweep artifact aggregation tests."""
import json

import pytest

from finetune.eval.aggregate_benchmark import aggregate
from finetune.eval.run_benchmark import _load_cases, _select_shard, _suite_hash


def _write_shards(tmp_path, *, omit_last=False):
    cases = _load_cases()
    paths = []
    for shard_index in range(20):
        selected = _select_shard(cases, shard_index, 20)
        if omit_last and shard_index == 19:
            selected = selected[:-1]
        document = {
            "schema_version": 3,
            "suite_hash": _suite_hash(cases),
            "suite_total": len(cases),
            "source_commit": "abc123",
            "judge_provider": "gemini",
            "judge_model": "gemini-3.5-flash-lite",
            "shard_count": 20,
            "shard_index": shard_index,
            "complete": True,
            "cases": [
                {
                    "case_id": case.id, "category": case.category, "input": case.input,
                    "response": "response", "latency_s": 1.0, "passed": True,
                    "error": None, "citations": [], "deeplinks": [],
                    "expected_themes": case.expected_themes, "checks": [],
                }
                for case in selected
            ],
        }
        path = tmp_path / f"shard-{shard_index}.json"
        path.write_text(json.dumps(document), encoding="utf-8")
        paths.append(path)
    return paths


def test_aggregate_requires_and_orders_exact_300_cases(tmp_path):
    result = aggregate(_write_shards(tmp_path))
    assert result["total"] == 300
    assert result["quality_pct"] == 100
    assert result["error_rate_pct"] == 0
    assert [case["case_id"] for case in result["cases"]] == [case.id for case in _load_cases()]


def test_aggregate_rejects_missing_case(tmp_path):
    with pytest.raises(ValueError, match="suite coverage mismatch"):
        aggregate(_write_shards(tmp_path, omit_last=True))
