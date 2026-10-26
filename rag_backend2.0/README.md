---
title: Hailey Backend
emoji: 🚭
colorFrom: blue
colorTo: purple
sdk: docker
pinned: false
---

# Hailey — X-hale backend

The active FastAPI/LangGraph service for X-hale: context-aware routing, specialist drafting, Qdrant retrieval, Appwrite conversation/fact storage and an SSE API. This is a research prototype with documented safety and evaluation limitations.

See [the current architecture](ARCHITECTURE.md) and [complete setup guide](../docs/SETUP.md). The sibling `rag_backend/` is a legacy predecessor, not a required second service.

## Local start

From this directory, with Python 3.11+:

```bash
python -m venv .venv
# POSIX: source .venv/bin/activate
# PowerShell: .\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m pip install -e ".[dev]"
cp .env.example .env
# Fill with your own credentials and provision Appwrite/Qdrant first.
python -m uvicorn app.main:app --reload --port 7860
```

Do not overwrite an existing `.env`. The setup guide documents Appwrite fields, indexes, client configuration, Firebase, ingestion and device networking. There is no complete automatic Appwrite bootstrap yet.

Defaults: Groq `openai/gpt-oss-20b` for triage/specialists/curation and `openai/gpt-oss-120b` for synthesis; Qdrant with Cloudflare `bge-small-en-v1.5` embeddings and optional same-model local fallback. Graph expansion, reranking and web fallback are **off by default**. Retained Gemini configuration is not an alternate-provider switch for the active factories.

Processing order: deterministic crisis precheck → context loading → model triage → routing/specialists. The preparation graph stops after specialist drafts; the endpoint buffers and post-processes synthesis, emits the response, persists the turn, awaits eligible memory curation, then emits `done`. Crisis guidance is deterministic, but detection is not exhaustive.

## API

User-data routes require an Appwrite JWT in `Authorization: Bearer <jwt>`.

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/chat/` | Chat through SSE |
| `GET`, `DELETE` | `/history/` | Read/clear conversation history |
| `GET`, `DELETE` | `/memory/` | Inspect/clear remembered facts |
| `DELETE` | `/memory/{fact_id}` | Delete an owned fact |
| `POST` | `/memory/{fact_id}/confirm` | Confirm an owned fact |
| `POST` | `/events/relapse` | Record explicit relapse action |
| `GET` | `/kb/{benefit_id}` | Fetch health-benefit content |
| `GET` | `/export/` | Export the authenticated user's data |
| `DELETE` | `/account/` | Explicitly requested account/data deletion |

Operational endpoints have separate exposure considerations: `/health` and `/live` are liveness checks; `/ready` checks dependency readiness and can return HTTP 503; `/metrics` exposes Prometheus metrics when enabled. API documentation is available at `/docs`. Do not assume all endpoints are authenticated or appropriate for unrestricted production exposure.

SSE examples:

```text
event: status
data: {"state":"composing"}

event: token
data: {"token":"Processed response content"}

event: done
data: {"citations":[],"deeplinks":[],"turn_id":"..."}

event: error
data: {"code":"internal_error","message":"Something went wrong. Please try again."}
```

Model output is buffered until citation/safety post-processing completes. SSE transport does not mean raw provider tokens are immediately forwarded.

## Knowledge, tests and deployment

See [ingestion](ingestion/README.md) for permitted-source ingestion and governance. Install extras with `python -m pip install -e ".[ingestion]"` from this directory. The source manifest is not a deployed-corpus inventory.

```bash
python -m pytest tests/unit/
```

Integration tests require configured services; read their fixtures and opt-in flags before execution. The scenario benchmark lives at [`../finetune/eval/`](../finetune/eval/), not inside this backend. Its results are not independent clinical validation.

Build a container with `docker build -t xhale-hailey .` using this directory's root Dockerfile, which pre-caches fallback embedding weights. For Hugging Face Spaces, deploy this directory as the Docker context, retain the frontmatter and configure runtime secrets. Do not promise free-tier uptime or fixed provider quotas. See [setup](../docs/SETUP.md), [roadmap](../docs/ROADMAP.md) and [third-party notices](../THIRD_PARTY_NOTICES.md).
