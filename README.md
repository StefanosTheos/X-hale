# X-hale — Quit Smoking Companion

A full-stack mobile application for quitting smoking, combining a Flutter client with **Hailey**, an agentic RAG chatbot backend built on FastAPI + LangGraph.

---

## Contents

- [App Overview](#app-overview)
- [Hailey — AI Chatbot](#hailey--ai-chatbot)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Backend Setup](#backend-setup)
- [Knowledge Base Ingestion](#knowledge-base-ingestion)
- [Deployment](#deployment)
- [Environment Variables](#environment-variables)
- [API Reference](#api-reference)

---

## App Overview

X-hale supports the full quit journey through structured features across four pillars:

### Tracking & Progress
- **Quit timer** — live countdown from the user's quit date
- **Health benefits timeline** — visualises the 20-minute to 15-year recovery arc with real medical sources
- **Biometrics dashboard** — charts for health metrics over time
- **Milestones** — time-based smoke-free achievements
- **Achievement system** — unlockable badges for behaviours and streaks

### Craving & Habit Management
- **Guided breathing exercises** — animated breath timers with audio cues
- **Distraction toolkit** — drawing canvas, ambient sounds, stretching routines, spin-the-wheel activity selector
- **Mini-games** — Snake, Flappy Bird, 2048, Tic-Tac-Toe to occupy craving windows
- **Challenges** — user-created and community challenges

### Journaling & Reflection
- **Diary** — mood-tagged entries with tagging support
- **Motivations feed** — rotating personalised motivational content

### Social
- **Friends** — mutual follow system
- **Forum** — community discussion board
- **Direct messaging** — peer-to-peer chat

---

## Hailey — AI Chatbot

Hailey is a multi-agent RAG chatbot that personalises every conversation using the user's quit history, known triggers, coping strategies, and long-term memory. She is not a general assistant — every response is scoped to smoking cessation.

### Multi-agent architecture

```
User message
    │
    ▼
Triage (8B, temp=0) ──── crisis? ──→ Crisis Handler (deterministic + hotlines)
    │
    ▼
Context Loader (parallel Appwrite reads)
    │                    ┌─────────────────────────────────┐
    ▼                    │  User profile + last 10 turns   │
Supervisor (pure Python) │  + top 30 user facts            │
    │                    └─────────────────────────────────┘
    ├──→ Medical Agent          (8B · vector search → KB citations)
    ├──→ Craving Support Agent  (8B · urge-surfing script + deeplinks)
    ├──→ Emotional Support Agent(8B · MI-style reflection)
    ├──→ Reflection Agent       (8B · diary pattern analysis)
    └──→ Relapse-Risk Agent     (8B · behavioural signals → risk score)
    │
    ▼
Synthesizer (Gemini Flash · streams tokens via SSE)
    │
    ▼
output_node ──→ Appwrite (save turn) ──→ Memory Curator (async, fire-and-forget)
```

### Retrieval pipeline

Hailey uses a two-pass retrieval pipeline for medical queries:

1. **Vector search** — query embedded via Cloudflare Workers AI (`bge-small-en-v1.5`), nearest neighbours fetched from Qdrant Cloud
2. **Knowledge graph expansion** — 139-node domain graph (symptoms, triggers, medications, health benefits, diseases, coping strategies) matches entities in the query and expands to related topic tags, driving a second filtered Qdrant pass that surfaces related content the vector search missed
3. **Cross-encoder reranker** — `BAAI/bge-reranker-base` available, disabled by default; enable via `ENABLE_RERANKER=true` when KB exceeds ~250 chunks

### Long-term memory

The Memory Curator runs post-reply on every non-casual turn and extracts durable facts into Appwrite (`chatbot_user_facts`):

| Fact type | Example |
|---|---|
| `trigger` | "coffee is biggest craving trigger" |
| `coping_strategy_validated` | "deep breathing works in the morning" |
| `coping_strategy_failed` | "chewing gum didn't help" |
| `nrt_use` | "using 21mg nicotine patch" |
| `social_context` | "partner still smokes at home" |
| `motivation` | "wants to be healthy for kids" |
| `physical_symptom_reported` | "experiencing insomnia since quitting" |

Facts are loaded at the start of every turn and injected into every agent's context window, making Hailey progressively more personalised without the user repeating themselves.

Users can view and delete their stored facts via the **"What does Hailey know about me?"** screen (psychology icon in the chatbot AppBar).

### Crisis safety

Any message containing suicidal ideation bypasses the LLM pipeline entirely. A deterministic handler returns a fixed, vetted safety message, locale-matched hotline numbers (Greek + English), and one constrained empathy sentence generated under tight constraints. No free-form LLM reply is ever returned for a crisis message.

---

## Tech Stack

### Flutter client

| Layer | Technology |
|---|---|
| Framework | Flutter 3.7+ / Dart |
| State management | Riverpod 2.x |
| Data models | Freezed + JSON serializable |
| Backend-as-a-service | Appwrite (auth, database, storage) |
| Push notifications | Firebase Cloud Messaging |
| Charts | fl_chart |
| Game engine | Flame |
| Audio | audioplayers |
| HTTP | http (REST + SSE streaming) |

### Python backend

| Layer | Technology |
|---|---|
| API framework | FastAPI + uvicorn |
| Agent orchestration | LangGraph |
| LLM — triage & specialists | Groq `llama-3.1-8b-instant` |
| LLM — synthesizer | Gemini Flash (`gemini-2.5-flash`) |
| Embeddings | Cloudflare Workers AI `bge-small-en-v1.5` |
| Vector store | Qdrant Cloud |
| Graph | NetworkX (in-process, no external DB) |
| Auth | Appwrite JWT verification |
| Conversation + facts store | Appwrite |
| Streaming | SSE via sse-starlette |
| Observability | Prometheus + structlog |

All backend infrastructure runs on **free tiers** (Groq, Cloudflare, Qdrant Cloud, Appwrite, Hugging Face Spaces).

---

## Project Structure

```
x-hale/
├── lib/                            # Flutter app
│   ├── main.dart
│   ├── constants/                  # App-wide constants (achievements, limits, affirmations)
│   ├── extensions/                 # Dart extensions (theme helpers)
│   ├── mixins/                     # Scroll controller mixin
│   ├── models/                     # Freezed data classes (23 models)
│   ├── providers/                  # Riverpod providers (12 providers)
│   ├── services/                   # Appwrite + ChatService
│   ├── mini_games/                 # Snake, Flappy Bird, 2048, Tic-Tac-Toe
│   └── pages/
│       ├── starting_pages/         # Splash, auth, onboarding
│       ├── home_pages/             # Main screens (chatbot, diary, achievements, …)
│       ├── explore_pages/          # Distractions, breathing, wellness content
│       ├── account_pages/          # Profile, preferences
│       ├── settings_pages/         # Settings, FAQs, about
│       └── utils/                  # Themes, dialogs, notification service
│
├── rag_backend2.0/                 # Hailey chatbot backend
│   ├── app/
│   │   ├── main.py
│   │   ├── config.py               # Pydantic-settings, all env vars
│   │   ├── agents/                 # 10 agents (triage → synthesizer → memory curator)
│   │   ├── graph/                  # LangGraph state, builder, routing
│   │   ├── retrieval/              # Hybrid retriever, vector store, KG, reranker
│   │   ├── memory/                 # Conversation + user facts stores, snapshot builder
│   │   ├── llm/                    # Groq, Gemini, Workers AI clients
│   │   ├── prompts/                # System prompts for all agents
│   │   ├── routers/                # FastAPI routers (chat, history, memory, kb)
│   │   ├── safety/                 # Crisis detector, hotlines, content filter
│   │   ├── tools/                  # Diary retrieval, user profile, behavioural signals
│   │   ├── models/                 # Pydantic schemas
│   │   └── observability/          # Metrics, logging
│   ├── ingestion/                  # KB ingestion pipeline
│   │   ├── ingest_kb.py
│   │   ├── bulk_ingest.py
│   │   ├── sources.yaml            # Ground truth for what's in Qdrant
│   │   └── knowledge_graph.yaml    # 139-node domain graph (206 edges)
│   ├── tests/
│   │   ├── unit/                   # 65+ unit tests
│   │   └── integration/
│   ├── docker/Dockerfile
│   └── pyproject.toml
│
└── assets/                         # Icons, images, audio, game tiles
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.7.2`
- Python 3.11+
- Accounts: [Appwrite](https://appwrite.io), [Groq](https://console.groq.com), [Cloudflare](https://dash.cloudflare.com), [Qdrant Cloud](https://cloud.qdrant.io), [Google AI Studio](https://aistudio.google.com) (Gemini)

### Flutter app

```bash
# Install dependencies
flutter pub get

# Run on a device or emulator
# Replace the URL with your backend address
flutter run --dart-define=HAILEY_API_URL=http://localhost:7860
```

For a physical Android device, forward the port first:

```bash
adb reverse tcp:7860 tcp:7860
flutter run --dart-define=HAILEY_API_URL=http://localhost:7860
```

---

## Backend Setup

```bash
cd rag_backend2.0

# Create virtual environment
python -m venv .venv
source .venv/bin/activate        # Windows: .\.venv\Scripts\activate

# Install runtime dependencies
pip install -e .

# Copy and fill in environment variables
cp .env.example .env

# Start the server
uvicorn app.main:app --reload --port 7860
```

The server will be available at `http://localhost:7860`. The knowledge graph loads at startup (~100 ms).

### Appwrite collections

Create these two collections manually in your Appwrite project alongside the existing app collections:

| Collection | Key fields |
|---|---|
| `chatbot_messages` | `userId`, `role`, `content`, `timestamp`, `turn_id`, `citations[]` |
| `chatbot_user_facts` | `userId`, `fact_type`, `fact_key`, `fact_value`, `confidence`, `source_turn_ids[]`, `first_observed`, `last_confirmed` |

Add an index on `(userId, timestamp DESC)` to `chatbot_messages` for efficient history queries.

---

## Knowledge Base Ingestion

The knowledge base lives in Qdrant Cloud. Run ingestion once on a fresh cluster, then add sources as needed.

```bash
# Install ingestion extras
pip install -e ".[ingestion]"

# Re-ingest all 14 health benefit sources
python -m ingestion.reingest_health_benefits

# Ingest a URL
python -m ingestion.ingest_kb \
  --url https://www.nhs.uk/live-well/quit-smoking/ \
  --source-id nhs_quit \
  --source-type government

# Ingest a local PDF
python -m ingestion.ingest_kb \
  --file path/to/document.pdf \
  --source-type peer_reviewed
```

`ingestion/sources.yaml` is the ground truth for what's in Qdrant. Set `ingested: true` after each successful ingest and commit the file.

---

## Deployment

### Backend — Hugging Face Spaces (recommended)

1. Create a new Space on [huggingface.co/spaces](https://huggingface.co/spaces), type **Docker**
2. Push `rag_backend2.0/` as the Space repository root
3. Set all environment variables under **Settings → Variables and secrets**
4. The `Dockerfile` in `docker/` handles the build; the server binds to port 7860

The free HF Spaces tier provides 16 GB CPU RAM with no spin-down.

### Backend — Docker (self-hosted)

```bash
cd rag_backend2.0
docker build -f docker/Dockerfile -t hailey-backend .
docker run -p 7860:7860 --env-file .env hailey-backend
```

### Flutter — production build

```bash
# Android APK
flutter build apk --dart-define=HAILEY_API_URL=https://your-hf-space.hf.space

# iOS
flutter build ipa --dart-define=HAILEY_API_URL=https://your-hf-space.hf.space
```

---

## Environment Variables

All backend configuration is via environment variables. See `rag_backend2.0/.env.example` for the full list.

| Variable | Description |
|---|---|
| `GROQ_API_KEY` | Groq API key |
| `GEMINI_API_KEY` | Google Gemini API key |
| `CF_ACCOUNT_ID` | Cloudflare account ID |
| `CF_WORKERS_AI_TOKEN` | Cloudflare Workers AI token |
| `QDRANT_URL` | Qdrant Cloud cluster URL |
| `QDRANT_API_KEY` | Qdrant Cloud API key |
| `APPWRITE_PROJECT_ID` | Appwrite project ID |
| `APPWRITE_API_KEY` | Appwrite server API key |
| `APPWRITE_DATABASE_ID` | Appwrite database ID |
| `APPWRITE_CHAT_MESSAGES_COLLECTION_ID` | chatbot_messages collection |
| `APPWRITE_USER_FACTS_COLLECTION_ID` | chatbot_user_facts collection |
| `ENABLE_KNOWLEDGE_GRAPH` | `true` (default) — domain KG-guided retrieval |
| `ENABLE_RERANKER` | `false` (default) — enable when KB > ~250 chunks |
| `ENABLE_WEB_SEARCH_FALLBACK` | `true` (default) — DuckDuckGo fallback for sparse KB hits |

---

## API Reference

All endpoints require `Authorization: Bearer <appwrite-jwt>`.

| Method | Path | Description |
|---|---|---|
| `POST` | `/chat/` | Send a message; returns an SSE stream |
| `GET` | `/history/` | Fetch the last 10 conversation turns |
| `DELETE` | `/history/` | Clear conversation history |
| `GET` | `/memory/` | List all stored user facts |
| `DELETE` | `/memory/{fact_id}` | Remove a specific user fact |
| `GET` | `/kb/{benefit_id}` | Retrieve health benefit KB chunks by ID |
| `GET` | `/health` | Health check |
| `GET` | `/metrics` | Prometheus metrics |

### SSE event types (`POST /chat/`)

```
event: status   data: {"status": "triaging"}
event: status   data: {"status": "loading_context"}
event: status   data: {"status": "searching_kb"}
event: status   data: {"status": "composing"}
event: token    data: {"text": "It sounds like..."}
event: done     data: {"citations": [...], "deeplinks": [...], "turn_id": "..."}
event: error    data: {"message": "..."}
```
