# Hailey 2.0 — Architecture Reference

This document describes the deployed architecture of Hailey 2.0.
The design rationale is in `chatbot_revamp_overview.md` (project root).

## Phase Status

| Phase | Status | Description |
|---|---|---|
| 0 | ✅ Complete | Auth, URL config, logging |
| 1 | ✅ Complete | FastAPI foundation, Qdrant, Appwrite history, Medical agent, SSE |
| 2 | ✅ Complete | Multi-agent supervisor, Emotional + Craving agents, Memory Curator |
| 3 | ✅ Complete | Knowledge graph and entity extractor (off by default), Reflection + Relapse-Risk agents, reranker (off by default) |
| 4 | 🟡 Partial | Crisis handler done; benchmark harness (eval categories, judge prompts, CI) pending |
| 5 | ⏳ Deferred | Fine-tuning pipeline |

## Request Flow

```
POST /chat/
  │
  ├─ Auth: verify Appwrite JWT → get user_id
  │
  ├─ [status: triaging]
  │   └─ Triage node: fast_crisis_check (sync) → GPT OSS 20B classify (temp=0)
  │       → TriageResult {intent, emotion, urgency, crisis_flag, specialists[]}
  │
  ├─ If crisis_flag → Crisis Handler (deterministic) → output_node → SSE done
  ├─ If irrelevant → irrelevant_node → output_node → SSE done
  ├─ If needs_clarification → clarification_node → output_node → SSE done
  │
  ├─ [status: loading_context]
  │   └─ context_loader_node: build_snapshot (parallel Appwrite reads)
  │       → UserMemorySnapshot {profile, recent_turns, top_facts}
  │
  ├─ Supervisor: decide_specialists(triage, memory) → requested_specialists[]
  │
  ├─ Specialist nodes (sequential dispatch):
  │   ├─ medical_node: retrieve (Qdrant) → GPT OSS 20B key_points → SpecialistDraft
  │   ├─ craving_support_node: GPT OSS 20B urge-surfing script + deeplinks
  │   ├─ emotional_support_node: GPT OSS 20B MI-style reflection
  │   ├─ reflection_node: diary retrieval + GPT OSS 20B theme analysis
  │   └─ relapse_risk_node: behavioral signals + GPT OSS 20B support draft
  │
  ├─ [status: composing]
  │   └─ router-driven GPT OSS 120B stream → final reply (citations extracted, content-filtered)
  │
  ├─ [status: saving]
  │   └─ output_node: append turns to Appwrite + fire memory_curator (async)
  │
  └─ SSE done event {citations, deeplinks, turn_id}
```

## Technology Stack

| Layer | Technology | Free Tier |
|---|---|---|
| API server | FastAPI + LangGraph | HF Spaces (16 GB CPU, no spin-down) |
| Synthesis LLM | Groq `openai/gpt-oss-120b` | Subject to Groq account quota |
| Routing/specialist LLM | Groq `openai/gpt-oss-20b` | Subject to the same account quota |
| Embeddings | Cloudflare Workers AI bge-small-en-v1.5 | Yes (10k/day) |
| Vector store | Qdrant Cloud | Yes (1 GB, no spin-down) |
| Conv. history | Appwrite chatbot_messages | Yes (existing project) |
| User facts | Appwrite chatbot_user_facts | Yes (existing project) |
| App data | Appwrite (users, diary, etc.) | Yes (read-only from chatbot) |
| Streaming | SSE via sse-starlette | N/A |

## Agent Responsibilities

| Agent | Model | Call type | Purpose |
|---|---|---|---|
| Triage | GPT OSS 20B, temp=0 | JSON completion | Classify intent/emotion/urgency/crisis |
| Supervisor | Pure Python | No LLM | Decide which specialists to invoke |
| Medical | GPT OSS 20B, temp=0 | JSON completion | Extract evidence-based key points from KB |
| Craving Support | GPT OSS 20B, temp=0.1 | JSON completion | Urge-surfing script + deeplinks |
| Emotional Support | GPT OSS 20B, temp=0.3 | JSON completion | MI-style reflective draft |
| Reflection | GPT OSS 20B, temp=0.3 | JSON completion | Diary pattern analysis |
| Relapse-Risk | GPT OSS 20B, temp=0.2 | JSON completion | Interpret behavioral signals and draft support |
| Synthesizer | GPT OSS 120B, temp=0.5 | Streaming | Compose final reply in Hailey's voice |
| Memory Curator | GPT OSS 20B, temp=0 | JSON completion | Extract durable user facts (async) |
| Crisis Handler | Deterministic | One constrained sentence | Fixed safety message + hotlines |

## Memory Architecture

```
Per-turn context budget (~5400 tokens):
  1. System prompt + Hailey persona          ~800 tok
  2. User profile snapshot                   ~200 tok
  3. User facts (top 30 by confidence)       ~600 tok
  4. Last 10 conversation turns              ~1500 tok
  5. Retrieved KB chunks (vector search)     ~1500 tok
  6. Specialist draft outputs                ~800 tok
```

## Phase 3 Feature Flags

All Phase 3 features are implemented. Two remain off by default:

| Flag | Default | Notes |
|---|---|---|
| `ENABLE_KNOWLEDGE_GRAPH` | `false` | 139-node/206-edge domain graph; entity extractor uses keyword matching (no ML dep) |
| `ENABLE_RERANKER` | `false` | `BAAI/bge-reranker-base` cross-encoder; enable when KB exceeds ~250 diverse chunks |
