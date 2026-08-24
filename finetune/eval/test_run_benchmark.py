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
    _load_cases,
    _select_shard,
    _add_model_usage,
    _det_check,
    _hard_gate_failures,
    _reporting_metrics,
    CaseResult,
    CheckResult,
)


def test_off_topic_cases_use_scope_specific_evaluation():
    cases = _load_cases("off_topic")

    assert len(cases) == 30
    assert all("scope_redirect_appropriate" in case.checks for case in cases)
    assert all("answer_relevant" not in case.checks for case in cases)
    assert all(case.expected_themes == [] for case in cases)


def test_invented_xhale_feature_is_deterministically_rejected():
    result = _det_check("no_invented_xhale_feature", "Open the Craving Tracker.", [], [])
    assert result.passed is False


def test_uncited_low_risk_medical_answer_fails_citation_policy():
    result = _det_check(
        "citation_present",
        "I could not verify a passage closely enough to attach a source.",
        [], [], {"citation_validation": {"risk_tier": "low"}},
    )
    assert result.passed is False


def test_reporting_separates_safe_abstention_from_other_medical_failures():
    checks = [CheckResult("citation_present", False, "0 citations")]
    safe = CaseResult(
        case_id="safe", category="medical_factual", input="question",
        response="I couldn't verify enough source-backed information to answer that safely.",
        citations=[], deeplinks=[], latency_s=1.0, checks=checks,
    )
    unsafe = CaseResult(
        case_id="unsafe", category="medical_factual", input="question",
        response="An unsupported medical claim.", citations=[], deeplinks=[],
        latency_s=1.0, checks=checks,
    )
    metrics = _reporting_metrics([safe, unsafe])
    assert metrics["safe_medical_abstentions"] == 1
    assert metrics["unsafe_or_inadequate_medical_failures"] == 1


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


def test_crisis_checks_use_actual_route_not_response_keywords():
    misleading = _det_check(
        "crisis_path_fires", "Please call a crisis hotline", [], [],
        {"actual_route": "specialists"}, "crisis",
    )
    assert misleading.passed is False


def test_deeplink_check_rejects_unknown_target():
    result = _det_check(
        "action_executable", "", [],
        [{"deeplink": "xhale://doctor-visit"}], {}, "",
    )
    assert result.passed is False


def test_reporting_separates_crisis_sensitivity_and_specificity():
    def result(case_id, category, name, passed):
        return CaseResult(
            case_id, category, "", "", [], [], 1,
            [CheckResult(name, passed)], clinical_review_status=(
                "pending" if category == "crisis" else "not_required"
            ),
        )
    metrics = _reporting_metrics([
        result("p1", "crisis", "crisis_path_fires", True),
        result("p2", "crisis", "crisis_path_fires", False),
        result("n1", "off_topic", "crisis_not_fires", True),
    ])
    assert metrics["crisis_sensitivity_pct"] == 50.0
    assert metrics["crisis_specificity_pct"] == 100.0
    assert metrics["clinical_review_status"] == "pending"
    assert any("crisis sensitivity" in failure for failure in _hard_gate_failures(metrics))


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


@pytest.mark.asyncio
async def test_combined_judge_recovers_once_from_malformed_json(monkeypatch):
    valid = {
        "judgments": {
            "answer_relevant": {"pass": True, "reason": "Direct answer."},
        },
        "matched_themes": ["support"],
        "theme_reason": "Support is present.",
    }
    completion = AsyncMock(side_effect=[
        SimpleNamespace(choices=[SimpleNamespace(
            message=SimpleNamespace(content='{"judgments": {broken}')
        )]),
        SimpleNamespace(choices=[SimpleNamespace(
            message=SimpleNamespace(content=json.dumps(valid))
        )]),
    ])
    fake = SimpleNamespace(chat=SimpleNamespace(completions=SimpleNamespace(create=completion)))
    monkeypatch.setenv("BENCHMARK_JUDGE_PROVIDER", "gemini")
    with patch("finetune.eval.run_benchmark._judge", return_value=fake):
        results = await _judge_case(
            "Help", "Here is direct support.", ["answer_relevant"], ["support", "care"],
        )
    assert completion.await_count == 2
    assert all(result.passed for result in results)
    assert completion.await_args_list[0].kwargs["response_format"] == {"type": "json_object"}
    assert "previous output was malformed" in (
        completion.await_args_list[1].kwargs["messages"][0]["content"].lower()
    )


@pytest.mark.asyncio
async def test_combined_judge_recovers_from_incomplete_object(monkeypatch):
    incomplete = {"judgments": {}}
    valid = {
        "judgments": {
            "answer_relevant": {"pass": False, "reason": "Does not answer."},
        },
    }
    completion = AsyncMock(side_effect=[
        SimpleNamespace(choices=[SimpleNamespace(
            message=SimpleNamespace(content=json.dumps(incomplete))
        )]),
        SimpleNamespace(choices=[SimpleNamespace(
            message=SimpleNamespace(content=json.dumps(valid))
        )]),
    ])
    fake = SimpleNamespace(chat=SimpleNamespace(completions=SimpleNamespace(create=completion)))
    monkeypatch.setenv("BENCHMARK_JUDGE_PROVIDER", "gemini")
    with patch("finetune.eval.run_benchmark._judge", return_value=fake):
        results = await _judge_case(
            "Question", "Unrelated", ["answer_relevant"], [],
        )
    assert completion.await_count == 2
    assert results[0].name == "answer_relevant"
    assert results[0].passed is False
    assert results[0].infrastructure_error is False
