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

Exit code `75` means the shard stopped early after quota exhaustion or consecutive infrastructure errors; the checkpoint remains resumable. A complete shard still applies the local 80% quality and 20% maximum-error gates.
Resume retains completed quality pass/fail outcomes but automatically retries cases carrying infrastructure errors.

## Judge configuration

The default GitHub configuration uses a separate Gemini judge so evaluation does not consume the chatbot's Groq GPT OSS 20B quota:

```text
BENCHMARK_JUDGE_PROVIDER=gemini
BENCHMARK_JUDGE_MODEL=gemini-3.5-flash-lite
GEMINI_API_KEY=<secret>
```

All requested semantic rubrics and fallback semantic theme matching are evaluated in one response per case. Groq remains available by setting the provider to `groq` and supplying `GROQ_API_KEY`.

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
