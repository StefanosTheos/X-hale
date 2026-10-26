# Hailey 2.0 architecture

This guide describes the active repository implementation. Runtime settings can differ through environment overrides; evaluation results must identify the actual code, model and corpus versions.

## System boundaries

The Flutter app communicates directly with Appwrite for application data and authentication. It sends an Appwrite JWT to the FastAPI Hailey service. Hailey reads the relevant Appwrite context, calls external model/embedding services, queries Qdrant and persists conversations and derived facts. Provider API keys remain backend-only.

`rag_backend2.0/` is the active service. The sibling `rag_backend/` is the legacy ChromaDB-era implementation and is not required by this architecture.

## Active chat request

1. `/chat/` authenticates the Appwrite JWT and initializes request state.
2. `crisis_precheck_node` runs deterministic detection before context or model I/O. A positive precheck routes directly to deterministic crisis guidance.
3. Otherwise, `context_loader_node` assembles a snapshot from profile data, recent conversation records and selected user facts.
4. `triage_node` classifies the message with that context. Routing can select crisis guidance, a clarification question, an off-topic redirect, or the supervisor.
5. The Python supervisor chooses specialists. The dispatcher runs the selected medical, craving-support, emotional-support, reflection and/or relapse-risk nodes **sequentially**.
6. The preparation graph ends after specialist drafting. The endpoint collects synthesis output, validates citations and applies output filtering before emitting model response content.
7. Deterministic branches already have their response text and do not need synthesis.
8. The endpoint calls `output_node`: persist both conversation records, then await eligible lifecycle-managed, retriable memory curation.
9. Only then emit the terminal SSE `done` event with citations, deeplinks and turn ID. The configured benchmark identity also receives evaluation telemetry.

The endpoint imports `get_compiled_preparation_graph()`. A complete graph with synthesis/output nodes exists for other callers; do not describe it as the active endpoint execution path. See [`builder.py`](app/graph/builder.py) and [`chat.py`](app/routers/chat.py).

## Models and retrieval

The active factories select Groq. `Settings` defaults are `openai/gpt-oss-20b` for triage/specialists/curation and `openai/gpt-oss-120b` for synthesis. Gemini client/configuration code remains available but is not selected by the current factories.

The retriever uses Qdrant with 384-dimensional `bge-small-en-v1.5` embeddings, normally obtained through Cloudflare Workers AI, with a same-model local fallback when configured. Medical retrieval uses vector search and metadata filtering over cessation/health-benefit collections.

| Optional path | Repository default |
| --- | --- |
| Knowledge-graph expansion | `ENABLE_KNOWLEDGE_GRAPH=false` |
| Cross-encoder reranking | `ENABLE_RERANKER=false` |
| Web-search fallback | `ENABLE_WEB_SEARCH_FALLBACK=false` |

The existence of graph data or web/reranker code does not imply those paths execute. The source manifest is an intended corpus/governance record; deployed Qdrant contents require a separate inventory.

## Memory lifecycle

The snapshot contains a profile, recent conversation **records**, and selected remembered facts. Limits and ranking are implementation constraints, not promises to include all relevant history. Triage uses a smaller formatted subset of that context; specialists need not receive identical prompt content.

Facts retain provenance and can be inspected/deleted by their owner. Extracted confidence is model-assigned and uncalibrated. Expired/superseded facts are handled separately from active facts.

After persistence, eligible curation is scheduled as a tracked task and awaited through `asyncio.shield`. Bounded retries, strong task references and shutdown draining manage its lifecycle. The benchmark identity and some intent categories skip curation. This is not a detached fire-and-forget job. Conversation deletion and fact deletion are distinct operations; do not claim atomic erasure across them.

## SSE and safety boundaries

SSE includes `status`, `token`, `done` and `error`; response data uses `{"token": "..."}`. The current endpoint buffers model synthesis before post-processing and emits the processed response, rather than forwarding raw provider tokens immediately. Status labels are presentation events and should not be treated as precise internal timing instrumentation.

The crisis guidance text is deterministic. Detection can miss cases, static resources have limited locale coverage, and the overall completion lifecycle may still include persistence/curation. Citation validation and output filtering do not establish clinical accuracy or exhaustive risk coverage. Relapse-risk scoring is a support-priority heuristic, not a validated clinical prediction.

## Operations and evidence

User-data routes require JWT authentication. Liveness/readiness, documentation and metrics have different access/exposure considerations; see [`main.py`](app/main.py). `/live` and `/health` report liveness; `/ready` checks cached dependency readiness and can return HTTP 503.

Benchmark Actions workflows execute developer-authored scenarios and retain artifacts; green workflow status is not proof that all case gates passed. Sequential scenario completion does not establish availability, scale or production reliability. Fine-tuning is deferred. See [evaluation](../finetune/eval/README.md), [setup](../docs/SETUP.md) and [limitations](../docs/ROADMAP.md).
