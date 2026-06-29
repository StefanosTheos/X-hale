# Hailey 2.0 — Agentic RAG Chatbot

An agentic RAG system where specialist agents collaborate through a supervisor, vector retrieval covers a curated knowledge base, every user accumulates a structured long-term memory profile, and the whole stack runs on free-tier infrastructure with Appwrite auth, SSE streaming, and structured observability.

---

## 1. Goals and non-goals

**Goals:**
- **Personalisation** — Hailey knows the user's quit date, smoking pattern, relapse history, emotional baseline, and recurring triggers.
- **Specialist routing** — medical facts, craving-in-the-moment, journal reflection, and crisis each get different prompting, retrieval, and tone.
- **Grounded medical answers** — every medical claim is traceable to a KB source, visible to the user on request.
- **Crisis-safety** — explicit detection of suicidal ideation with a deterministic safety path. Never a free-form LLM reply.
- **Low cost** — free hosting tiers throughout.
- **Streaming** — tokens start appearing within ~1 second of send.

**Non-goals:**
- Replacing licensed clinical care. The crisis path hands off; it does not treat.
- Fine-tuning for medical accuracy. Medical facts stay in RAG.
- Real-time learning from chats. Chats update the user's personal memory store, not the global KB.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Flutter (X-hale app)                         │
│  ChatbotPage → ChatService → HTTPS + Appwrite JWT                   │
└─────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│           FastAPI + LangGraph (Hugging Face Spaces, Docker)         │
│                                                                     │
│  /chat (SSE) → Auth (Appwrite JWT) → Supervisor Graph               │
│                                                                     │
│  Triage ──► crisis? → Crisis Handler (deterministic)                │
│         │                                                           │
│         ▼                                                           │
│  User Context Loader (memory + profile + recent diary)              │
│         │                                                           │
│         ▼                                                           │
│  Supervisor → Specialist(s) (parallel where able):                  │
│     • Medical Information Agent    (tools: vector search)           │
│     • Craving Support Agent        (tools: app actions)             │
│     • Emotional Support Agent      (tools: memory, MI prompts)      │
│     • Reflection / Journal Agent   (tools: diary retrieval)         │
│     • Relapse-Risk Agent           (tools: behavioural signals)     │
│         │                                                           │
│         ▼                                                           │
│  Synthesizer (composes one reply, streams via SSE)                  │
│         │                                                           │
│         ▼ (fire-and-forget)                                         │
│  Memory Curator (extracts user facts, async)                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
        │              │                  │                 │
        ▼              ▼                  ▼                 ▼
   Groq API       Cloudflare AI      Qdrant Cloud       Appwrite DB
   (LLMs)         (embeddings)       (kb_chunks)        (history, facts,
                                                         diary, profile)
```

**LLM split:** Groq `llama-3.1-8b-instant` handles triage, specialist drafts, and memory curation. Groq `llama-3.3-70b-versatile` handles synthesis (1 call per turn).

---

## 3. Multi-agent design

### Agent roster

#### Runtime (every turn)

| Agent | Role | Model |
|---|---|---|
| **Triage** | Classifies intent, emotion, urgency, crisis_flag | Groq 8B, temp 0 |
| **Supervisor** | Selects specialists from triage result. No LLM call. | — |
| **Synthesizer** | Composes final reply from specialist drafts, streams tokens | Groq 70B, temp 0.5 |

#### Specialists (conditional)

| Specialist | When invoked | Capabilities |
|---|---|---|
| **Medical** | Factual question about smoking, withdrawal, benefits, NRT | Vector search over KB, citation tracking |
| **Craving Support** | `intent=craving_support` or `urgency=high` | Urge-surfing script, deeplinks to in-app distractions |
| **Emotional Support** | Sadness / anxiety / guilt / shame | MI-style reflective listening, no advice unless asked |
| **Reflection** | User mentions diary or supervisor detects pattern | Diary retrieval + theme summary |
| **Relapse-Risk** | Declining engagement or relapse marker | Behavioural signal read + risk score |

#### Async / deterministic

| Agent | Trigger | Role |
|---|---|---|
| **Memory Curator** | Post-reply, fire-and-forget. Skips `off_topic`/`unknown`. | Extracts durable user facts, upserts to Appwrite |
| **Crisis Handler** | `crisis_flag=true` — deterministic Python, not LLM | Fixed vetted safety message + locale hotlines + one constrained empathy line |

### Routing sequence

1. Auth + load context (profile, memory snapshot) in parallel.
2. Triage.
3. `crisis_flag` → Crisis Handler → done.
4. `topic_relevance == "irrelevant"` → polite redirect → done.
5. `intent == "needs_clarification"` → clarification turn → done.
6. Supervisor selects specialists.
7. Specialists run in parallel where outputs are independent.
8. Synthesizer composes one reply, streams over SSE.
9. Memory Curator processes the turn async.

---

## 4. Retrieval

### Vector retrieval

**Stack:** Qdrant Cloud (free tier). Embeddings: `@cf/baai/bge-small-en-v1.5` via Cloudflare Workers AI.

**Collections:**
- `kb_chunks` — chunked KB content, 400–600 tokens with 100-token overlap.
- `health_benefit_chunks` — health-benefit corpus, tagged with `benefit_id` for metadata-filter fetches.

All agents call `retrieve(query, user_id, strategy, intent, k)` — they never talk to Qdrant directly.

### Knowledge graph (Phase 3 — currently disabled)

~200-node YAML graph loaded into in-process NetworkX at startup. Adds relationship traversal that pure vector retrieval misses. **Disabled** (`ENABLE_KNOWLEDGE_GRAPH=false`) to stay within Groq free-tier TPM limits — KG expansion adds up to 3 extra chunks per query. Re-enable on a paid tier.

### Web search fallback (currently disabled)

DuckDuckGo fallback fires when Qdrant returns fewer than 2 chunks and intent is not `general_conversation`. **Disabled** (`ENABLE_WEB_SEARCH_FALLBACK=false`) for the same free-tier quota reason.

---

## 5. Memory

### Conversation history
Stored in `chatbot_messages` (Appwrite). Last 10 turns injected into prompt context.

### User facts
Stored in `chatbot_user_facts` (Appwrite). Written by Memory Curator post-turn. Read at turn start as `UserMemorySnapshot` (top ~30 facts). Fact types: `trigger`, `coping_strategy_validated`, `coping_strategy_failed`, `nrt_use`, `social_context`, `motivation`, `stage_of_change`, `past_attempt_history`, `physical_symptom_reported`.

Users can audit and delete individual facts via the "What does Hailey know about me?" screen, or erase everything via the "Data & Privacy" screen.

### User profile
Read-only from existing Appwrite collections (`users`, `diary`, `achievements`, `milestones`). No new storage.

---

## 6. Safety

- **Layer 1** — fast regex check (`crisis_detector.py`) fires synchronously before any LLM call.
- **Layer 2** — triage LLM sets `crisis_flag=true` for nuanced signals the regex misses.
- **Crisis Handler** — deterministic Python: one constrained empathy sentence (LLM, max 60 tokens, falls back to hardcoded string on failure) + fixed body with locale-appropriate hotlines. Never free-form.
- **Hotlines** — verified 2026-06-27. Greek locale: 1018 (KLIMAKA), 10306 (psychosocial), 197 (social emergency). English locale: 988 US/CA, Samaritans 116 123, SHOUT 85258, Crisis Text per country, Lifeline AU, Beyond Blue.
- **Flutter "Seek Help" page** — crisis banner (988, 116 123, 1018) at top, smoking quitlines below. Quitlines verified 2026-06-27.

---

## 7. Benchmark evaluation

| Category | Pass criteria |
|---|---|
| Medical — factual | Faithful to source, citation present, no hallucinated numbers |
| Medical — medication | Cites authoritative source, no prescribing |
| Craving — acute | Urge-surfing script, in-app deeplink |
| Craving — situational | Trigger acknowledgment + coping suggestion |
| Emotional — anxiety | MI-style reflection, validates, no premature advice |
| Emotional — guilt | Non-judgmental, separates slip from failure |
| Reflection | Uses actual user data |
| Crisis | Deterministic safety reply, hotline numbers |
| Off-topic | Polite redirect |
| Personalisation | References known user fact |

**Current:** 300 cases (30 per category). Target for Phase 5 baselines: 50 per category (~500 total).

**Harness:** Custom (`finetune/eval/run_benchmark.py`). Deterministic checks run in-process; LLM-as-judge (Groq 8B, structured JSON) covers tone, relevancy, faithfulness, non-judgmental, MI style. Pass threshold: quality ≥ 80% and error rate ≤ 20%. **Benchmark currently passing.** GitHub Actions nightly — 5% sample Mon–Sat, full sweep Sunday.

---

## 8. Deployment

| Component | Service |
|---|---|
| Backend (FastAPI + LangGraph) | Hugging Face Spaces (Docker, public, no spin-down) |
| Vector DB | Qdrant Cloud free tier |
| Conv history + user facts | Appwrite (free tier) |
| LLM — triage/specialists | Groq `llama-3.1-8b-instant` |
| LLM — synthesis | Groq `llama-3.3-70b-versatile` |
| Embeddings | Cloudflare Workers AI `@cf/baai/bge-small-en-v1.5` |

**HF deploy command:**
```
git subtree split --prefix rag_backend2.0 -b hf-deploy && git push hf hf-deploy:main --force && git branch -D hf-deploy
```

**Open risks:**
- Free-tier quotas tighten without notice. KG and web fallback disabled; chunk cap at 400 chars; medical `k=3`. All increase on paid Groq tier.
- Memory Curator occasionally records incorrect facts. Mitigation: user-facing delete UI. Set UX copy expectations accordingly.
- Cold-start mitigated — GitHub Actions keep-alive pings `/health` and Qdrant `/collections` every 5 minutes.

---

## 9. Flutter-side changes

- `--dart-define=HAILEY_API_URL` replaces hard-coded URL.
- `Authorization: Bearer <appwrite-jwt>` on every request.
- SSE consumer in `chat_service.dart` with `HaileyEvent` sealed class.
- History loaded at chatbot page open; welcome message shown in all code paths.
- Citation chips — expandable "Sources" list for medical answers, with human-readable labels for 30+ source IDs.
- Suggested-action chips — tappable deeplink chips rendered below assistant bubbles when Craving agent returns app actions.
- "What does Hailey know about me?" screen (`HaileyMemoryPage`) — facts grouped by type, confidence bars, delete with confirmation, pull-to-refresh.
- "Data & Privacy" screen (`HaileyDataPrivacyPage`) — inline privacy policy, export-to-clipboard (`GET /export/`), delete-all-chatbot-data with confirmation. Backend: `GET /export/` (GDPR Art. 20), `DELETE /memory/` bulk erase.

---

## 10. File structure

```
rag_backend2.0/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── routers/
│   │   ├── chat.py           # POST /chat (SSE)
│   │   ├── history.py        # GET /history, DELETE /history
│   │   ├── memory.py         # GET /memory, DELETE /memory, DELETE /memory/{fact_id}
│   │   ├── export.py         # GET /export (GDPR Article 20)
│   │   └── kb.py             # GET /kb/{benefit_id}
│   ├── auth/
│   │   ├── appwrite_jwt.py
│   │   └── dependencies.py
│   ├── agents/
│   │   ├── triage.py
│   │   ├── supervisor.py
│   │   ├── medical.py
│   │   ├── craving_support.py
│   │   ├── emotional_support.py
│   │   ├── reflection.py
│   │   ├── relapse_risk.py
│   │   ├── memory_curator.py
│   │   ├── synthesizer.py
│   │   └── crisis_handler.py
│   ├── graph/
│   │   ├── builder.py
│   │   ├── state.py
│   │   └── routing.py
│   ├── retrieval/
│   │   ├── vector_store.py
│   │   ├── hybrid_retriever.py
│   │   ├── knowledge_graph.py
│   │   ├── reranker.py
│   │   └── entity_extractor.py
│   ├── memory/
│   │   ├── conversation_store.py
│   │   ├── user_facts_store.py
│   │   └── snapshot.py
│   ├── tools/
│   │   ├── user_profile.py
│   │   ├── diary_retrieval.py
│   │   ├── achievement_lookup.py
│   │   ├── behavioral_signals.py
│   │   ├── app_actions.py
│   │   └── web_search.py
│   ├── llm/
│   │   ├── groq_client.py
│   │   ├── gemini_client.py
│   │   ├── workers_ai_client.py
│   │   ├── streaming.py
│   │   └── client.py
│   ├── safety/
│   │   ├── crisis_detector.py
│   │   ├── hotlines.py
│   │   └── content_filter.py
│   ├── prompts/
│   │   ├── system.py
│   │   ├── triage.py
│   │   ├── medical.py
│   │   ├── craving.py
│   │   ├── emotional.py
│   │   ├── reflection.py
│   │   ├── relapse_risk.py
│   │   ├── synthesizer.py
│   │   ├── memory_curator.py
│   │   └── crisis_oneliner.py
│   ├── observability/
│   │   ├── metrics.py
│   │   └── logging.py
│   └── models/
│       ├── chat.py
│       ├── user_facts.py
│       └── retrieval.py
│
├── ingestion/
│   ├── bulk_ingest.py
│   ├── ingest_kb.py
│   ├── chunk.py
│   ├── reingest_health_benefits.py
│   ├── sources.yaml
│   ├── knowledge_graph.yaml
│   └── README.md
│
├── tests/
│   ├── unit/
│   │   ├── test_crisis_handler.py
│   │   ├── test_hybrid_retriever.py
│   │   ├── test_knowledge_graph.py
│   │   ├── test_reflection_agent.py
│   │   ├── test_relapse_risk_agent.py
│   │   ├── test_reranker.py
│   │   ├── test_routing.py
│   │   ├── test_triage.py
│   │   └── test_user_facts_extractor.py
│   ├── integration/
│   │   ├── test_appwrite_round_trip.py
│   │   ├── test_chat_flow.py
│   │   └── test_streaming.py
│   └── conftest.py
│
├── finetune/
│   ├── eval/
│   │   ├── categories.yaml        # 300 gold cases across 10 categories (30 each)
│   │   ├── judge_prompts/
│   │   ├── run_benchmark.py
│   │   ├── requirements-eval.txt
│   │   └── results/
│   └── README.md
│
├── Dockerfile
├── docker/compose.yml
├── .env.example
├── requirements.txt
└── README.md
```

---

## 11. Phase summary

| Phase | Status |
|---|---|
| 1 — Backend foundation (FastAPI, auth, Qdrant, SSE) | ✅ Done |
| 2 — Multi-agent + memory (triage, supervisor, specialists, memory curator) | ✅ Done |
| 3 — Retrieval depth (KG, entity extractor, reranker, reflection, relapse-risk) | ✅ Done |
| 4 — Safety + benchmarks (crisis handler, hotlines, eval harness, nightly CI) | ✅ Done |
| 5 — Fine-tuning | ⬜ Not started |

---

## 12. Next steps

1. **Phase 5 fine-tuning** — build training datasets (synthesised triage + memory-curator examples), train LoRAs on Qwen 2.5 1.5B (triage) and Llama 3.2 3B (memory curator) via QLoRA/Unsloth, benchmark against current Groq baselines, deploy only if the gain justifies serving infrastructure.

2. **Re-enable KG and web search fallback** — one-line config change each (`ENABLE_KNOWLEDGE_GRAPH=true`, `ENABLE_WEB_SEARCH_FALLBACK=true`) once on a paid Groq tier.

3. **Loosen chunk cap and medical k** — raise the 400-char chunk truncation in `format_for_prompt()` and increase medical specialist from `k=3` once token budget allows.

4. **App store submission** — Google Play listing, screenshots, store copy, and privacy policy link. Can run in parallel with the technical work above.
