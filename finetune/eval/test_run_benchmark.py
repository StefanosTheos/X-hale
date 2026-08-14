"""Focused tests for deterministic and resumable benchmark execution."""
import json
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import pytest

from finetune.eval.run_benchmark import (
    TestCase as BenchmarkCase,
    _judge_case,
    _lexical_theme_check,
    _load_checkpoint,
    _select_shard,
    _add_model_usage,
)


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


def test_deterministic_shards_cover_each_case_once():
    cases = [BenchmarkCase(str(i), "cat", "input", []) for i in range(23)]
    shards = [_select_shard(cases, index, 5) for index in range(5)]
    ids = [case.id for shard in shards for case in shard]
    assert sorted(ids, key=int) == [str(i) for i in range(23)]
    assert len(ids) == len(set(ids))


def test_checkpoint_rejects_mixed_commit(tmp_path):
    path = tmp_path / "checkpoint.json"
    path.write_text(json.dumps({
        "suite_hash": "hash", "shard_index": 0, "shard_count": 20,
        "source_commit": "old", "judge_provider": "gemini", "judge_model": "flash",
        "cases": [],
    }), encoding="utf-8")
    with pytest.raises(ValueError, match="source_commit mismatch"):
        _load_checkpoint(path, {
            "suite_hash": "hash", "shard_index": 0, "shard_count": 20,
            "source_commit": "new", "judge_provider": "gemini", "judge_model": "flash",
        })


def test_checkpoint_resume_retries_infrastructure_errors(tmp_path):
    path = tmp_path / "checkpoint.json"
    identity = {
        "suite_hash": "hash", "shard_index": 0, "shard_count": 20,
        "source_commit": "commit", "judge_provider": "gemini", "judge_model": "flash",
    }
    base = {
        "category": "cat", "input": "input", "response": "response",
        "citations": [], "deeplinks": [], "latency_s": 1, "checks": [],
        "expected_themes": [],
    }
    path.write_text(json.dumps({
        **identity,
        "cases": [
            {**base, "case_id": "quality-fail", "error": None},
            {**base, "case_id": "transient-error", "error": "API unavailable"},
        ],
    }), encoding="utf-8")

    results = _load_checkpoint(path, identity)

    assert [result.case_id for result in results] == ["quality-fail"]


def test_backend_usage_accumulates_independently_per_model():
    totals = {}
    _add_model_usage(totals, {
        "by_model": {
            "openai/gpt-oss-20b": {"prompt_tokens": 1200, "completion_tokens": 300},
            "openai/gpt-oss-120b": {"prompt_tokens": 800, "completion_tokens": 200},
        }
    })
    _add_model_usage(totals, {
        "by_model": {
            "openai/gpt-oss-20b": {"prompt_tokens": 400, "completion_tokens": 100},
        }
    })
    assert totals == {
        "openai/gpt-oss-20b": 2000,
        "openai/gpt-oss-120b": 1000,
    }


@pytest.mark.asyncio
async def test_combined_judge_uses_one_request_for_all_checks(monkeypatch):
    payload = {
        "judgments": {
            "answer_relevant": {"pass": True, "reason": "Directly answers."},
            "tone_warm_empathetic": {"pass": True, "reason": "Warm tone."},
        },
        "matched_themes": ["craving relief"],
        "theme_reason": "Equivalent coping guidance is present.",
    }
    completion = AsyncMock(return_value=SimpleNamespace(
        choices=[SimpleNamespace(message=SimpleNamespace(content=json.dumps(payload)))]
    ))
    fake = SimpleNamespace(chat=SimpleNamespace(completions=SimpleNamespace(create=completion)))
    monkeypatch.setenv("BENCHMARK_JUDGE_PROVIDER", "groq")
    with patch("finetune.eval.run_benchmark._judge", return_value=fake):
        results = await _judge_case(
            "Help", "Try a breathing exercise.",
            ["answer_relevant", "tone_warm_empathetic"], ["craving relief", "support"],
        )
    assert completion.await_count == 1
    assert {result.name for result in results} == {
        "answer_relevant", "tone_warm_empathetic", "expected_theme_coverage",
    }
    assert all(result.passed for result in results)
