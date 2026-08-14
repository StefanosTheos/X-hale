"""
Hailey 2.0 — Benchmark Evaluation Harness

Usage:
  python run_benchmark.py                         # full suite
  python run_benchmark.py --sample 0.05          # random 5% sample
  python run_benchmark.py --category crisis       # single category
  python run_benchmark.py --dry-run              # validate YAML, no API calls
  python run_benchmark.py --output results/x.json

Required env vars:
  HAILEY_API_URL          e.g. https://stefanostheos-hailey-backend.hf.space
  APPWRITE_ENDPOINT       e.g. https://cloud.appwrite.io/v1
  APPWRITE_PROJECT_ID     from Appwrite console
  APPWRITE_BENCHMARK_KEY  Appwrite server key with users.write scope
  BENCHMARK_TEST_USER_ID  dedicated test Appwrite user's ID
  GEMINI_API_KEY          for Gemini judge calls (recommended)
  GROQ_API_KEY            only when BENCHMARK_JUDGE_PROVIDER=groq

Optional:
  RESULTS_PATH            override default output path
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import os
import random
import re
import sys
import time
from datetime import datetime, timezone
from math import ceil
from dataclasses import dataclass, asdict, field
from pathlib import Path

import httpx
import yaml

EVAL_DIR = Path(__file__).parent
CATEGORIES_FILE = EVAL_DIR / "categories.yaml"
JUDGE_PROMPTS_DIR = EVAL_DIR / "judge_prompts"
RESULTS_DIR = EVAL_DIR / "results"

DETERMINISTIC_CHECKS = frozenset({
    "citation_present",
    "no_external_app",
    "deeplink_present",
    "crisis_path_fires",
    "crisis_not_fires",
    "max_words_300",
    "redirects_in_app",
})

JUDGE_CHECKS = frozenset({
    "tone_warm_empathetic",
    "answer_relevant",
    "medically_faithful",
    "non_judgmental",
    "mi_style",
})

# Markers that must appear in a crisis response
_CRISIS_MARKERS = [
    "helpline", "hotline", "116", "1018", "988", "samaritans",
    "lifeline", "emergency", "trained counsellor", "please reach out",
    "crisis", "immediate help",
]

_EXTERNAL_APP_RE = re.compile(
    r"\b(nhs app|smokefree app|quit genius|nicorette app|kwit|smoke free app"
    r"|download the|google play|app store)\b",
    re.IGNORECASE,
)

_IN_APP_RE = re.compile(
    r"(xhale://|breathing exercise|spin the wheel|write in your diary"
    r"|view your progress|listen to ambient|in the app|within the app"
    r"|open the app|try stretching|play a quick game)",
    re.IGNORECASE,
)


# ── Data types ────────────────────────────────────────────────────────────────

@dataclass
class TestCase:
    id: str
    category: str
    input: str
    checks: list[str]
    expected_themes: list[str] = field(default_factory=list)
    notes: str = ""


@dataclass
class CheckResult:
    name: str
    passed: bool
    detail: str = ""
    infrastructure_error: bool = False


@dataclass
class CaseResult:
    case_id: str
    category: str
    input: str
    response: str
    citations: list
    deeplinks: list
    latency_s: float
    checks: list[CheckResult]
    expected_themes: list[str] = field(default_factory=list)
    error: str | None = None

    @property
    def passed(self) -> bool:
        return self.error is None and all(c.passed for c in self.checks)

    @classmethod
    def from_dict(cls, data: dict) -> "CaseResult":
        return cls(
            case_id=data["case_id"], category=data["category"], input=data["input"],
            response=data.get("response", ""), citations=data.get("citations", []),
            deeplinks=data.get("deeplinks", []), latency_s=float(data.get("latency_s", 0)),
            checks=[CheckResult(**check) for check in data.get("checks", [])],
            expected_themes=data.get("expected_themes", []), error=data.get("error"),
        )


# ── Auth ──────────────────────────────────────────────────────────────────────

async def _get_jwt(client: httpx.AsyncClient) -> str:
    """Mint a JWT for the test user via Appwrite server API.

    Uses the user ID directly (stored as BENCHMARK_TEST_USER_ID secret) to
    avoid a user-lookup call that requires users.read scope on the API key.
    """
    endpoint = os.environ["APPWRITE_ENDPOINT"].rstrip("/")
    project_id = os.environ["APPWRITE_PROJECT_ID"]
    benchmark_key = os.environ["APPWRITE_BENCHMARK_KEY"]  # users.write scope only
    user_id = os.environ["BENCHMARK_TEST_USER_ID"]

    jwt_resp = await client.post(
        f"{endpoint}/users/{user_id}/jwts",
        headers={
            "X-Appwrite-Project": project_id,
            "X-Appwrite-Key": benchmark_key,
            "Content-Type": "application/json",
        },
        json={"duration": 900},
    )
    jwt_resp.raise_for_status()
    return jwt_resp.json()["jwt"]


# ── API call ──────────────────────────────────────────────────────────────────

async def _call_chat(
    client: httpx.AsyncClient,
    api_url: str,
    jwt: str,
    user_input: str,
) -> tuple[str, list, list, float]:
    """Stream /chat SSE; return (text, citations, deeplinks, latency_s)."""
    start = time.monotonic()
    tokens: list[str] = []
    citations: list = []
    deeplinks: list = []
    current_event: str | None = None

    async with client.stream(
        "POST",
        f"{api_url.rstrip('/')}/chat/",
        json={"message": user_input, "locale": "en"},
        headers={"Authorization": f"Bearer {jwt}", "Accept": "text/event-stream"},
        timeout=90.0,
    ) as resp:
        resp.raise_for_status()
        async for raw_line in resp.aiter_lines():
            line = raw_line.strip()
            if line.startswith("event: "):
                current_event = line[7:]
            elif line.startswith("data: ") and current_event:
                try:
                    payload = json.loads(line[6:])
                except json.JSONDecodeError:
                    continue
                if current_event == "token":
                    tokens.append(payload.get("token", ""))
                elif current_event == "done":
                    citations = payload.get("citations", [])
                    deeplinks = payload.get("deeplinks", [])
                elif current_event == "error":
                    raise RuntimeError(
                        f"API error {payload.get('code')}: {payload.get('message')}"
                    )
                current_event = None

    return "".join(tokens), citations, deeplinks, time.monotonic() - start


async def _clear_history(client: httpx.AsyncClient, api_url: str, jwt: str) -> None:
    """Isolate benchmark cases while preserving seeded long-term memory facts."""
    response = await client.delete(
        f"{api_url.rstrip('/')}/history/",
        headers={"Authorization": f"Bearer {jwt}"},
        timeout=30.0,
    )
    response.raise_for_status()


# ── Deterministic checks ──────────────────────────────────────────────────────

def _det_check(
    name: str,
    response: str,
    citations: list,
    deeplinks: list,
) -> CheckResult:
    text = response.lower()

    if name == "citation_present":
        ok = len(citations) > 0
        return CheckResult(name, ok, f"{len(citations)} citation(s)")

    if name == "no_external_app":
        m = _EXTERNAL_APP_RE.search(response)
        ok = m is None
        return CheckResult(name, ok, f"found '{m.group()}'" if m else "clean")

    if name == "deeplink_present":
        ok = len(deeplinks) > 0
        return CheckResult(name, ok, f"{len(deeplinks)} deeplink(s)")

    if name == "crisis_path_fires":
        ok = any(marker in text for marker in _CRISIS_MARKERS)
        return CheckResult(name, ok, "crisis content present" if ok else "no crisis markers found")

    if name == "crisis_not_fires":
        fires = any(marker in text for marker in _CRISIS_MARKERS)
        return CheckResult(name, not fires, "clean" if not fires else "unexpected crisis content")

    if name == "max_words_300":
        count = len(response.split())
        ok = count <= 300
        return CheckResult(name, ok, f"{count} words")

    if name == "redirects_in_app":
        ok = bool(_IN_APP_RE.search(response))
        return CheckResult(name, ok, "in-app reference found" if ok else "no in-app reference")

    return CheckResult(name, False, f"unknown deterministic check: {name}")


_THEME_STOPWORDS = frozenset({"a", "an", "and", "as", "at", "for", "in", "of", "on", "or", "the", "to", "with"})


def _normalise_theme_tokens(value: str) -> set[str]:
    """Normalise concept labels for deterministic expected-theme coverage."""
    tokens = re.findall(r"[a-z0-9]+", value.lower())
    normalised: set[str] = set()
    for token in tokens:
        if token in _THEME_STOPWORDS:
            continue
        # Lightweight stemming keeps the check dependency-free while matching
        # common variants such as cravings/craving and improved/improvement.
        for suffix in ("ments", "ment", "ing", "ed", "ies", "s"):
            if token.endswith(suffix) and len(token) - len(suffix) >= 4:
                token = token[:-len(suffix)]
                break
        normalised.add(token)
    return normalised


def _lexical_theme_check(response: str, expected_themes: list[str]) -> CheckResult:
    """Require deterministic lexical evidence for a representative theme subset."""
    if not expected_themes:
        return CheckResult("expected_theme_coverage", True, "no expected themes declared")

    response_tokens = _normalise_theme_tokens(response)
    matched: list[str] = []
    for theme in expected_themes:
        theme_tokens = _normalise_theme_tokens(theme)
        if theme_tokens and theme_tokens.issubset(response_tokens):
            matched.append(theme)

    required = max(1, ceil(len(expected_themes) * 0.4))
    passed = len(matched) >= required
    return CheckResult(
        "expected_theme_coverage",
        passed,
        f"matched {len(matched)}/{len(expected_themes)} themes; required {required}: {matched}",
    )


# ── LLM judge ────────────────────────────────────────────────────────────────

_judge_client = None


def _judge_provider() -> str:
    return os.environ.get("BENCHMARK_JUDGE_PROVIDER", "groq").lower()


def _judge_model() -> str:
    default = "gemini-3.5-flash-lite" if _judge_provider() == "gemini" else "openai/gpt-oss-20b"
    return os.environ.get("BENCHMARK_JUDGE_MODEL", default)


def _judge():
    global _judge_client
    if _judge_client is not None:
        return _judge_client
    provider = _judge_provider()
    if provider == "gemini":
        from openai import AsyncOpenAI
        _judge_client = AsyncOpenAI(
            api_key=os.environ["GEMINI_API_KEY"],
            base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
        )
    elif provider == "groq":
        from groq import AsyncGroq
        _judge_client = AsyncGroq(api_key=os.environ["GROQ_API_KEY"])
    else:
        raise ValueError(f"unsupported BENCHMARK_JUDGE_PROVIDER: {provider}")
    return _judge_client


def _rubric(name: str) -> str:
    prompt_file = JUDGE_PROMPTS_DIR / f"{name}.txt"
    if not prompt_file.exists():
        raise FileNotFoundError(f"missing judge prompt: {name}.txt")
    text = prompt_file.read_text(encoding="utf-8")
    criteria_at = text.find("Scoring criteria")
    return_at = text.find("Return JSON")
    if criteria_at < 0:
        return text
    return text[criteria_at:return_at if return_at >= 0 else len(text)].strip()


def _parse_json_object(content: str) -> dict:
    """Accept strict JSON and tolerate a provider wrapping it in a code fence."""
    start = content.find("{")
    end = content.rfind("}")
    if start < 0 or end < start:
        raise ValueError("judge returned no JSON object")
    return json.loads(content[start:end + 1])


async def _judge_case(
    question: str,
    response: str,
    check_names: list[str],
    expected_themes: list[str],
) -> list[CheckResult]:
    """Evaluate every requested semantic criterion in one provider call."""
    lexical = _lexical_theme_check(response, expected_themes)
    needs_semantic_themes = bool(expected_themes) and not lexical.passed
    if not check_names and not needs_semantic_themes:
        return [lexical]

    judgment_schema = {
        "type": "object",
        "properties": {
            name: {
                "type": "object",
                "properties": {"pass": {"type": "boolean"}, "reason": {"type": "string"}},
                "required": ["pass", "reason"],
                "additionalProperties": False,
            }
            for name in check_names
        },
        "required": check_names,
        "additionalProperties": False,
    }
    properties: dict = {"judgments": judgment_schema}
    required = ["judgments"]
    if needs_semantic_themes:
        properties["matched_themes"] = {"type": "array", "items": {"type": "string"}}
        properties["theme_reason"] = {"type": "string"}
        required.extend(["matched_themes", "theme_reason"])
    schema = {
        "name": "combined_benchmark_judgment",
        "strict": True,
        "schema": {
            "type": "object",
            "properties": properties,
            "required": required,
            "additionalProperties": False,
        },
    }
    rubrics = "\n\n".join(f"## {name}\n{_rubric(name)}" for name in check_names)
    theme_instruction = (
        "\nAlso identify expected themes substantively present using synonyms or equivalent advice. "
        "Copy matched values exactly from the supplied list."
        if needs_semantic_themes else ""
    )
    output_template: dict = {
        "judgments": {
            name: {"pass": True, "reason": "one short sentence"}
            for name in check_names
        }
    }
    if needs_semantic_themes:
        output_template.update(matched_themes=[], theme_reason="one short sentence")
    prompt = (
        "Evaluate the response once against every named rubric. Return only one JSON object matching "
        "the supplied structure. Keep every reason to one short sentence. "
        f"Required JSON shape: {json.dumps(output_template)}"
        f"{theme_instruction}\n\nUser message: {question}\nHailey response: {response}\n"
        f"Expected themes: {json.dumps(expected_themes if needs_semantic_themes else [])}\n\n{rubrics}"
    )
    try:
        kwargs = dict(
            model=_judge_model(),
            messages=[{"role": "user", "content": prompt}],
            temperature=0,
            max_completion_tokens=512,
        )
        if _judge_provider() == "groq":
            kwargs.update(
                reasoning_effort="low", include_reasoning=False,
                response_format={"type": "json_schema", "json_schema": schema},
            )
        chat = await _judge().chat.completions.create(**kwargs)
        result = _parse_json_object(chat.choices[0].message.content or "")
        checks = [
            CheckResult(name, bool(result["judgments"][name]["pass"]), str(result["judgments"][name]["reason"]))
            for name in check_names
        ]
        if not needs_semantic_themes:
            checks.append(lexical)
            return checks
        allowed = set(expected_themes)
        matched = list(dict.fromkeys(t for t in result["matched_themes"] if t in allowed))
        theme_required = max(1, ceil(len(expected_themes) * 0.4))
        checks.append(CheckResult(
            "expected_theme_coverage", len(matched) >= theme_required,
            f"semantic match {len(matched)}/{len(expected_themes)}; required {theme_required}: "
            f"{matched}. {result['theme_reason']}",
        ))
        return checks
    except Exception as exc:
        names = check_names + (["expected_theme_coverage"] if needs_semantic_themes else [])
        return [
            CheckResult(name, False, f"judge infrastructure error: {exc}", True)
            for name in names
        ]


# ── Case runner ───────────────────────────────────────────────────────────────

async def _run_case(
    case: TestCase,
    client: httpx.AsyncClient,
    api_url: str,
    jwt: str,
) -> CaseResult:
    last_exc: Exception | None = None
    for attempt in range(3):  # up to 2 retries on transient errors
        try:
            response, citations, deeplinks, latency = await _call_chat(
                client, api_url, jwt, case.input
            )
            last_exc = None
            break
        except Exception as exc:
            last_exc = exc
            if attempt < 2:
                await asyncio.sleep(20)  # give Groq rate limits time to reset

    if last_exc is not None:
        return CaseResult(
            case_id=case.id,
            category=case.category,
            input=case.input,
            response="",
            citations=[],
            deeplinks=[],
            latency_s=0.0,
            checks=[],
            expected_themes=case.expected_themes,
            error=str(last_exc),
        )

    check_results: list[CheckResult] = []
    judge_names: list[str] = []
    for check_name in case.checks:
        if check_name in DETERMINISTIC_CHECKS:
            result = _det_check(check_name, response, citations, deeplinks)
            check_results.append(result)
        elif check_name in JUDGE_CHECKS:
            judge_names.append(check_name)
        else:
            result = CheckResult(check_name, False, f"unknown check: {check_name}")
            check_results.append(result)

    check_results.extend(await _judge_case(case.input, response, judge_names, case.expected_themes))

    evaluation_errors = [c.detail for c in check_results if c.infrastructure_error]

    return CaseResult(
        case_id=case.id,
        category=case.category,
        input=case.input,
        response=response,
        citations=citations,
        deeplinks=deeplinks,
        latency_s=latency,
        checks=check_results,
        expected_themes=case.expected_themes,
        error="; ".join(evaluation_errors) if evaluation_errors else None,
    )


# ── YAML loader ───────────────────────────────────────────────────────────────

def _load_cases(category_filter: str | None = None) -> list[TestCase]:
    raw = yaml.safe_load(CATEGORIES_FILE.read_text(encoding="utf-8"))
    cases: list[TestCase] = []
    for cat_name, cat_data in raw.get("categories", {}).items():
        if category_filter and cat_name != category_filter:
            continue
        for item in cat_data.get("cases", []):
            cases.append(TestCase(
                id=item["id"],
                category=cat_name,
                input=item["input"],
                checks=item.get("checks", []),
                expected_themes=item.get("expected_themes", []),
                notes=item.get("notes", ""),
            ))
    return cases


def _suite_hash(cases: list[TestCase]) -> str:
    """Stable identity for the selected case definitions and checks."""
    payload = [asdict(case) for case in cases]
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def _select_shard(cases: list[TestCase], shard_index: int, shard_count: int) -> list[TestCase]:
    """Partition cases deterministically with no duplicates or omissions."""
    if shard_count < 1:
        raise ValueError("shard_count must be at least 1")
    if not 0 <= shard_index < shard_count:
        raise ValueError("shard_index must be in [0, shard_count)")
    return [case for position, case in enumerate(cases) if position % shard_count == shard_index]


def _is_quota_error(detail: str) -> bool:
    lowered = detail.lower()
    return (
        "tokens per day" in lowered
        or "rate_limit_exceeded" in lowered and "token" in lowered
        or "resource_exhausted" in lowered and "quota" in lowered
    )


def _load_checkpoint(path: Path, expected: dict) -> list[CaseResult]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    for key in (
        "suite_hash", "shard_index", "shard_count", "source_commit",
        "judge_provider", "judge_model",
    ):
        if data.get(key) != expected[key]:
            raise ValueError(
                f"checkpoint {key} mismatch: {data.get(key)!r} != {expected[key]!r}"
            )
    results = [CaseResult.from_dict(item) for item in data.get("cases", [])]
    ids = [result.case_id for result in results]
    if len(ids) != len(set(ids)):
        raise ValueError("checkpoint contains duplicate case IDs")
    return results


# ── Reporting ─────────────────────────────────────────────────────────────────

def _print_report(results: list[CaseResult]) -> None:
    total = len(results)
    errored = [r for r in results if r.error]
    evaluated = [r for r in results if not r.error]
    n_pass = sum(1 for r in evaluated if r.passed)
    pct = round(100 * n_pass / len(evaluated)) if evaluated else 0
    err_pct = round(100 * len(errored) / total) if total else 0

    print(f"\n{'='*64}")
    print(f"BENCHMARK  {n_pass}/{len(evaluated)} passed  ({pct}%)  |  {len(errored)} backend error(s) ({err_pct}%)")
    print(f"{'='*64}")

    cats: dict[str, list[CaseResult]] = {}
    for r in results:
        cats.setdefault(r.category, []).append(r)

    for cat, items in sorted(cats.items()):
        cat_eval = [r for r in items if not r.error]
        cat_pass = sum(1 for r in cat_eval if r.passed)
        cat_err = len(items) - len(cat_eval)
        err_tag = f"  ⚠ {cat_err} error(s)" if cat_err else ""
        icon = "✅" if cat_pass == len(cat_eval) and not cat_err else "❌"
        print(f"\n{icon} {cat}: {cat_pass}/{len(cat_eval)} passed{err_tag}")
        for r in items:
            status = "PASS" if r.passed else "FAIL"
            lat = f"{r.latency_s:.1f}s" if r.latency_s else "ERR"
            print(f"    {status}  [{r.case_id}]  {lat}  {r.input[:55]}")
            if not r.passed:
                if r.error:
                    print(f"          error: {r.error}")
                for c in r.checks:
                    if not c.passed:
                        print(f"          FAIL  {c.name}: {c.detail}")

    latencies = sorted(r.latency_s for r in results if not r.error and r.latency_s)
    if latencies:
        p50 = latencies[len(latencies) // 2]
        p95 = latencies[max(0, int(len(latencies) * 0.95) - 1)]
        print(f"\nLatency  p50={p50:.1f}s  p95={p95:.1f}s")

    # Per-check pass rate
    check_totals: dict[str, list[bool]] = {}
    for r in results:
        for c in r.checks:
            check_totals.setdefault(c.name, []).append(c.passed)
    if check_totals:
        print("\nCheck pass rates:")
        for check_name, votes in sorted(check_totals.items()):
            pct_check = round(100 * sum(votes) / len(votes))
            print(f"    {check_name:<30} {pct_check}%  ({sum(votes)}/{len(votes)})")


def _save_results(results: list[CaseResult], path: Path, metadata: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = {
        "schema_version": 3,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "timestamp": int(time.time()),
        "quality_threshold_pct": 80,
        "maximum_error_rate_pct": 20,
        "total": len(results),
        "passed": sum(1 for r in results if r.passed),
        **metadata,
        "cases": [
            {
                "case_id": r.case_id,
                "category": r.category,
                "input": r.input,
                "response": r.response,
                "latency_s": r.latency_s,
                "passed": r.passed,
                "error": r.error,
                "citations": r.citations,
                "deeplinks": r.deeplinks,
                "expected_themes": r.expected_themes,
                "checks": [asdict(c) for c in r.checks],
            }
            for r in results
        ],
    }
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(data, indent=2, default=str), encoding="utf-8")
    temporary.replace(path)


# ── Main ──────────────────────────────────────────────────────────────────────

async def main() -> int:
    parser = argparse.ArgumentParser(description="Hailey benchmark harness")
    parser.add_argument(
        "--sample", type=float, default=1.0,
        help="Fraction of cases to run, e.g. 0.05 for 5%%"
    )
    parser.add_argument("--category", help="Run only this category name")
    parser.add_argument("--dry-run", action="store_true", help="Validate YAML only, no API calls")
    parser.add_argument("--output", help="JSON results path (default: results/run_<ts>.json)")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for sample selection")
    parser.add_argument("--shard-count", type=int, default=1, help="Number of deterministic suite shards")
    parser.add_argument("--shard-index", type=int, default=0, help="Zero-based shard to execute")
    parser.add_argument(
        "--resume", action="store_true",
        help="Resume completed cases from --output; metadata must match the selected shard",
    )
    parser.add_argument(
        "--stop-after-errors", type=int, default=3,
        help="Checkpoint and stop after this many consecutive infrastructure errors",
    )
    parser.add_argument(
        "--preserve-history",
        action="store_true",
        help="Do not clear test-user chat history between cases (disabled by default for isolation)",
    )
    args = parser.parse_args()

    all_cases = _load_cases(args.category)
    print(f"Loaded {len(all_cases)} cases" + (f" for category '{args.category}'" if args.category else ""))

    if args.dry_run:
        # Validate all check names
        unknown = set()
        for c in all_cases:
            for chk in c.checks:
                if chk not in DETERMINISTIC_CHECKS and chk not in JUDGE_CHECKS:
                    unknown.add(chk)
        if unknown:
            print(f"ERROR: unknown checks: {unknown}", file=sys.stderr)
            return 1
        print("Dry run OK — YAML valid, all check names recognised.")
        return 0

    if args.sample < 1.0:
        if args.shard_count != 1:
            parser.error("--sample and deterministic sharding cannot be combined")
        rng = random.Random(args.seed)
        n = max(1, int(len(all_cases) * args.sample))
        cases = rng.sample(all_cases, n)
        print(f"Sampled {len(cases)} cases (seed={args.seed})")
    else:
        try:
            cases = _select_shard(all_cases, args.shard_index, args.shard_count)
        except ValueError as exc:
            parser.error(str(exc))
        print(f"Selected shard {args.shard_index + 1}/{args.shard_count}: {len(cases)} cases")

    api_url = os.environ["HAILEY_API_URL"]
    out = Path(args.output) if args.output else RESULTS_DIR / f"run_{int(time.time())}.json"
    metadata = {
        "suite_hash": _suite_hash(all_cases),
        "suite_total": len(all_cases),
        "shard_index": args.shard_index,
        "shard_count": args.shard_count,
        "selected_total": len(cases),
        "category_filter": args.category,
        "sample": args.sample,
        "seed": args.seed,
        "source_commit": os.environ.get("GITHUB_SHA", "local"),
        "judge_provider": _judge_provider(),
        "judge_model": _judge_model(),
        "complete": False,
        "stop_reason": None,
    }
    results = _load_checkpoint(out, metadata) if args.resume else []
    completed_ids = {result.case_id for result in results}
    if results:
        print(f"Resuming {len(results)} completed case(s) from {out}")

    async with httpx.AsyncClient(timeout=90.0) as client:
        print(f"Running {len(cases)} cases against {api_url}")

        consecutive_errors = 0
        stopped_early = False
        for i, case in enumerate(cases, 1):
            if case.id in completed_ids:
                print(f"  [{i:>3}/{len(cases)}] {case.id} ... RESUMED")
                continue
            print(f"  [{i:>3}/{len(cases)}] {case.id} ...", end=" ", flush=True)
            if results:
                await asyncio.sleep(3)  # pace requests to avoid Groq rate limits
            try:
                jwt = await _get_jwt(client)  # fresh JWT per case; avoids expiry during retries
                if not args.preserve_history:
                    await _clear_history(client, api_url, jwt)
                result = await _run_case(case, client, api_url, jwt)
            except Exception as exc:
                result = CaseResult(
                    case_id=case.id,
                    category=case.category,
                    input=case.input,
                    response="",
                    citations=[],
                    deeplinks=[],
                    latency_s=0.0,
                    checks=[],
                    expected_themes=case.expected_themes,
                    error=f"case setup error: {exc}",
                )
            results.append(result)
            completed_ids.add(result.case_id)
            consecutive_errors = consecutive_errors + 1 if result.error else 0
            metadata["stop_reason"] = None
            _save_results(results, out, metadata)
            if result.error:
                print(f"ERROR: {result.error}")
            elif result.passed:
                print(f"PASS  ({result.latency_s:.1f}s)")
            else:
                failed = [c.name for c in result.checks if not c.passed]
                print(f"FAIL  ({result.latency_s:.1f}s)  failed: {', '.join(failed)}")

            if result.error and _is_quota_error(result.error):
                metadata["stop_reason"] = "judge_quota_exhausted"
                stopped_early = True
            elif consecutive_errors >= args.stop_after_errors:
                metadata["stop_reason"] = "consecutive_infrastructure_errors"
                stopped_early = True
            if stopped_early:
                _save_results(results, out, metadata)
                print(f"STOP — {metadata['stop_reason']}; resume this shard from the checkpoint.")
                break

    _print_report(results)
    metadata["complete"] = len(completed_ids) == len(cases) and not stopped_early
    _save_results(results, out, metadata)
    print(f"\nResults → {out}")

    if not metadata["complete"]:
        return 75

    evaluated = [r for r in results if not r.error]
    errored = [r for r in results if r.error]
    quality_pct = round(100 * sum(1 for r in evaluated if r.passed) / len(evaluated)) if evaluated else 0
    error_pct = round(100 * len(errored) / len(results)) if results else 0

    if quality_pct < 80:
        print(f"\nFAIL — quality pass rate {quality_pct}% is below 80% threshold.")
        return 1
    if error_pct > 20:
        print(f"\nFAIL — backend error rate {error_pct}% exceeds 20% threshold.")
        return 1
    print(f"\nPASS — quality {quality_pct}%, error rate {error_pct}%.")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
