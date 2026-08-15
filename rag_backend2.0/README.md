---
title: Hailey Backend
emoji: 🚭
colorFrom: blue
colorTo: purple
sdk: docker
pinned: false
---

# Hailey 2.0 — X-hale Chatbot Backend

Agentic RAG chatbot backend for the X-hale quit-smoking companion app.
Multi-agent supervisor architecture with specialist agents, Qdrant-backed knowledge retrieval,
Appwrite-persisted conversation history and user facts, and SSE streaming.

## Architecture

```
Flutter App  →  HTTPS + Appwrite JWT  →  FastAPI (HF Spaces)
                                              │
                                         LangGraph
                                         Triage → Supervisor → Specialists → Synthesizer
                                              │              │
                                         Groq API        Qdrant Cloud (kb_chunks)
                                         (GPT OSS 20B,  CF Workers AI (embeddings)
                                          120B synth)   Appwrite (history, user facts)
```

## Quick Start (local)

```bash
# 1. Clone and enter the directory
cd rag_backend2.0

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure environment
cp .env.example .env
# Edit .env with your API keys

# 4. Run locally
uvicorn app.main:app --reload --port 7860

# 5. Or with Docker Compose (includes local Qdrant)
docker compose -f docker/compose.yml up
```

## Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/chat/` | Send a message, receive SSE stream |
| `GET` | `/history/` | Get conversation history |
| `DELETE` | `/history/` | Clear conversation history |
| `GET` | `/memory/` | View Hailey's remembered facts about you |
| `DELETE` | `/memory/{fact_id}` | Remove a specific fact |
| `POST` | `/events/relapse` | Record the authenticated user's explicit relapse action |
| `GET` | `/kb/{benefit_id}` | Get knowledge base content for a health benefit |
| `GET` | `/health` | Backward-compatible process liveness check |
| `GET` | `/live` | Process liveness check |
| `GET` | `/ready` | Cached Appwrite, Qdrant, Groq, and embedding-provider readiness check; accepts the same-model local fallback when Cloudflare is unavailable and returns HTTP 503 if no usable path remains |
| `GET` | `/metrics` | Prometheus metrics |

## SSE Event Types (POST /chat/)

```
event: status   data: {"state": "triaging|loading_context|searching_kb|composing|saving"}
event: token    data: {"token": "..."}
event: done     data: {"citations": [...], "deeplinks": [...], "turn_id": "..."}
event: error    data: {"code": "...", "message": "..."}
```

## Ingesting the Knowledge Base

```bash
pip install ".[ingestion]"

# Ingest all health benefit sources (run once on fresh Qdrant cluster)
python -m ingestion.reingest_health_benefits

# Ingest a custom document
python -m ingestion.ingest_kb --url https://www.nhs.uk/... --source-type government
```

See `ingestion/README.md` for full documentation.

## Appwrite Collections to Create Manually

Create these two collections in your Appwrite Console before first run:

### `chatbot_messages`
| Attribute | Type | Required | Notes |
|---|---|---|---|
| userId | String | ✓ | Index |
| role | String | ✓ | "user" or "assistant" |
| content | String(8000) | ✓ | |
| timestamp | DateTime | ✓ | Index |
| turn_id | String | ✓ | |
| citations | String(4000) | | JSON array |

Composite index: `(userId ASC, timestamp DESC)`

### `chatbot_user_facts`
| Attribute | Type | Required | Notes |
|---|---|---|---|
| userId | String | ✓ | Index |
| fact_type | String | ✓ | |
| fact_key | String | ✓ | |
| fact_value | String(2000) | ✓ | |
| confidence | Float | ✓ | 0.0–1.0 |
| source_turn_ids | String(1000) | | JSON array |
| first_observed | DateTime | | |
| last_confirmed | DateTime | | |
| superseded_by | String | | |

Index: `(userId ASC, fact_type ASC)`

## Deploying to Hugging Face Spaces

1. Create a new HF Space (Docker SDK, public)
2. Add all secrets from `.env.example` as Space Secrets
3. Push the code (Dockerfile in `docker/Dockerfile` — copy to root for HF)
4. HF Spaces will build and serve on port 7860

## Environment Variables

See `.env.example` for the full list. Minimum required:
- `GROQ_API_KEY`
- `APPWRITE_PROJECT_ID`, `APPWRITE_API_KEY`, `APPWRITE_DATABASE_ID`
- `APPWRITE_CHAT_MESSAGES_COLLECTION_ID`, `APPWRITE_USER_FACTS_COLLECTION_ID`
- `QDRANT_URL`, `QDRANT_API_KEY`
- `CF_ACCOUNT_ID`, `CF_WORKERS_AI_TOKEN`

## Running Tests

```bash
pip install ".[dev]"
pytest tests/unit/          # fast, no external services
pytest tests/integration/   # requires running services

# With Appwrite integration tests:
APPWRITE_INTEGRATION_TEST=true pytest tests/integration/test_appwrite_round_trip.py
```
