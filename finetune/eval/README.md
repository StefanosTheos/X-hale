# Hailey benchmark execution

The full suite contains 300 cases and is executed as 20 deterministic shards of 15 cases. Sharding is positional and exhaustive: across indices `0..19`, every case appears exactly once.

## Run or resume a shard

```bash
python finetune/eval/run_benchmark.py \
  --shard-count 20 --shard-index 0 \
  --output finetune/eval/results/shard_00.json
```

The output is rewritten atomically after every completed case. To continue the same suite, commit, shard, and judge configuration:

```bash
python finetune/eval/run_benchmark.py \
  --shard-count 20 --shard-index 0 --resume \
  --output finetune/eval/results/shard_00.json
```

Exit code `75` means the shard stopped early after quota exhaustion or consecutive infrastructure errors; the checkpoint remains resumable. A complete shard applies the 80% overall quality gate, zero-infrastructure-error gate, crisis sensitivity/specificity floors, 100% medical-grounding gate, and 100% executable-action gate.
Resume retains completed quality pass/fail outcomes but automatically retries cases carrying infrastructure errors.

## Judge configuration

The default GitHub configuration uses a separate Gemini judge so evaluation does not consume the chatbot's Groq GPT OSS 20B quota:

```text
BENCHMARK_JUDGE_PROVIDER=gemini
BENCHMARK_JUDGE_MODEL=gemini-3.5-flash-lite
GEMINI_API_KEY=<secret>
```

All requested semantic rubrics and fallback semantic theme matching are evaluated in one response per case. The judge receives benchmark-only execution traces and retrieved snippets for grounding checks. Groq remains available by setting the provider to `groq` and supplying `GROQ_API_KEY`.

## Evidence and reporting

Schema-version 5 artifacts include the triage decision, relevance-selected
context facts, requested/completed specialists, retrieval source IDs, snippets,
scores, action provenance, citation-validation decisions, actual route, and
safety-filter result. This trace is returned only to the configured benchmark
account and is not exposed in ordinary chat responses.

Reports separate overall and per-category quality from critical safety, crisis
sensitivity, crisis specificity, medical grounding, route accuracy, executable
actions, and memory accuracy. Crisis cases remain marked `pending` for expert
review; automated results must not be described as clinical validation. See
`clinical_review_protocol.md`.

Expected content has three tiers: `mandatory_themes`, `optional_themes` (legacy
`expected_themes` are treated as optional), and `invalid_themes` that the
evaluator must not require or introduce.

The benchmark account receives isolated per-case memory fixtures. An empty
fixture is a true no-memory baseline; supplied fixtures support relevant,
irrelevant, superseded, stale, contradictory, and absent-memory cases without
persisting them to Appwrite.

## Aggregate the full sweep

After all 20 shard artifacts are complete:

```bash
python finetune/eval/aggregate_benchmark.py path/to/shards/*.json \
  --output finetune/eval/results/full_sweep.json
```

Aggregation fails if artifacts mix commits, suite definitions, shard counts, judge providers/models, duplicate case IDs, incomplete shards, or anything other than the exact current 300-case set.

The GitHub `Benchmark Evaluation` workflow runs or resumes one shard. `Aggregate Benchmark Sweep` accepts comma-separated completed benchmark run IDs and creates the final retained artifact.

## Automated free-tier campaign

`Daily Full Benchmark Campaign` runs at 04:15 UTC each day and resumes one
checkpoint containing the full deterministic 300-case suite. It checkpoints
after every case and stops when any backend model reaches 170,000 tokens in
that run, after five hours, or when an upstream quota is exhausted. This keeps
a 15% margin below Groq's 200,000-token daily free-plan cap.

The deployed backend must set `BENCHMARK_TEST_USER_ID` to the same dedicated
Appwrite user stored in the GitHub Actions secret. Only that authenticated user
receives request-level LLM usage metadata and skips post-response memory
curation. Response generation, retrieval, safety checks, persistence, and
evaluation remain unchanged.
