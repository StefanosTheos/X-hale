# Hailey 2.0 — Agentic RAG Chatbot Revamp Overview

This document is the design proposal for the next iteration of the Hailey chatbot. It assumes the user has read `chatbot_review.md` and accepts that the current implementation needs a full rewrite rather than incremental patches.

The goal is a comprehensive **agentic RAG system** where multiple specialist agents collaborate through a supervisor, retrieval combines a curated knowledge graph with dense vector search, every user accumulates a structured long-term memory profile that personalises future responses, and the whole stack runs on free-tier infrastructure with proper auth, persistence, and observability.

The structure of this doc:

1. Goals and non-goals
2. Target architecture — high level
3. Multi-agent design (which agents, what they do, how they coordinate)
4. Retrieval architecture (vector + knowledge graph + entity-aware retrieval)
5. Long-term memory architecture
6. Fine-tuning a small model — feasibility, data, method, role
7. Benchmark evaluation — categories, metrics, datasets, harness
8. Deployment — free-tier-only platform analysis and recommended stack
9. Flutter-side changes
10. File structure for the new backend
11. Phased migration plan
12. What I recommend implementing vs deferring (honest scoping)
13. Risks and open questions

---

## 1. Goals and non-goals

### Goals

- **Personalisation** — Hailey should know the user's quit date, smoking pattern, relapse history, current emotional baseline, and recurring triggers. Conversations should reference these without the user having to repeat themselves.
- **Specialist routing** — different question types (medical fact, craving-in-the-moment, journal/reflection, crisis) deserve different prompting, different retrieval, and different tone.
- **Grounded medical answers** — every medical claim should be traceable to a source in the knowledge base, with the source visible to the user on request.
- **Crisis-safety** — explicit detection of suicidal ideation or severe self-harm signals with an immediate, deterministic safety path (hotline + supportive de-escalation), never a free-form LLM reply.
- **Low cost** — must run on free hosting tiers indefinitely for early users. Should not require paid GPU inference for the common path.
- **Observable** — quality regressions, classifier drift, fallback rates, and retrieval hit rates must be visible. Current Hailey has zero observability.
- **Streaming** — perceived latency matters more than absolute latency. The user should see tokens within ~1 second of pressing send.

### Non-goals

- **Replacing licensed clinical care.** Hailey is a smoking-cessation companion. The crisis path hands off; it does not attempt to treat.
- **Pure-LLM fine-tuning for medical accuracy.** Fine-tuning a tiny model on medical content is a known source of hallucinated, plausibly-worded falsehoods. Medical facts stay in RAG.
- **Real-time learning from chats.** The user's chats inform their personal memory store, but don't enter the global knowledge base. No automatic feedback loop into training data.

---

## 2. Target architecture — high level

```
┌───────────────────────────────────────────────────────────────────────┐
│                          Flutter (X-hale app)                         │
│   ChatbotPage  ──►  ChatService  ──►  HTTPS + Appwrite JWT  ──►       │
└───────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌───────────────────────────────────────────────────────────────────────┐
│             FastAPI + LangGraph (Hugging Face Spaces, Docker)         │
│                                                                       │
│   /chat (SSE stream)  ─► Auth (Appwrite) ─► Supervisor Graph          │
│                                                                       │
│   Supervisor                                                          │
│      │                                                                │
│      ├─► Triage Agent ─────────► crisis? → Crisis Handler (deterministic)
│      │                          │                                     │
│      │                          ▼                                     │
│      ├─► User Context Loader (memory + profile + recent diary)        │
│      │                                                                │
│      ├─► Specialist(s) (one or more, in parallel where independent):  │
│      │     • Medical Information Agent      (tools: vector, graph)    │
│      │     • Craving Support Agent          (tools: distractions, app actions)
│      │     • Emotional Support Agent        (tools: memory, MI prompts)
│      │     • Reflection / Journal Agent     (tools: diary retrieval)  │
│      │     • Relapse-Risk Agent             (tools: behavioural signals)
│      │                                                                │
│      ├─► Synthesizer Agent (composes one coherent reply)              │
│      │                                                                │
│      └─► Memory Curator Agent (extracts new user facts, async)        │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
        │              │                    │                  │
        ▼              ▼                    ▼                  ▼
   Groq LLM     Qdrant Cloud         Appwrite DB         Cloudflare
   (router +    (KB chunk vectors,   (conv history,      Workers AI
    answerer)    health-benefits)     user facts,         (embeddings)
                + Knowledge graph     diary refs)
                  (NetworkX in-memory
                   or Neo4j AuraDB)
```

The key shift versus current Hailey: instead of a linear classify → retrieve → refine → generate pipeline, the supervisor invokes specialist agents that each carry their own tool kit. The supervisor decides *which* specialists to engage based on the triage classification AND the user's long-term memory state. Specialists run in parallel where their outputs are independent, and the synthesizer collapses their outputs into a single voice.

---

## 3. Multi-agent design

### 3.1 Agent roster

Six runtime agents plus two passive ones. Keeping the roster small is deliberate — the failure mode of agentic systems is over-decomposition.

#### Runtime agents (involved in every turn)

| Agent | Role | LLM | Tools |
|---|---|---|---|
| **Triage Agent** | One JSON call. Returns `{intent, emotion, topic_relevance, urgency, crisis_flag, requested_specialists[]}`. The classifier of the system. Replaces the current `classify_all`. | small / fine-tuned model, temperature 0 | none |
| **Supervisor** | Reads triage output + user memory state. Decides which specialists to call and in what order. Hands off, then receives outputs. | small model | none |
| **Synthesizer** | Composes the final reply from one or more specialist drafts and the user's memory snapshot. Owns voice consistency. | large model (Groq 70B), temperature 0.5 | none |

#### Specialist agents (invoked conditionally)

| Specialist | When invoked | Capabilities |
|---|---|---|
| **Medical Information Agent** | factual question about smoking, withdrawal, benefits, medications, NRT, side-effects | vector search over KB, knowledge-graph traversal, citation tracking |
| **Craving Support Agent** | "I want a cigarette right now", "I'm craving", urgency=high | suggest deeplinks to in-app distractions (breathing, mini-games, Spin the Wheel), urge-surfing micro-script, time-to-pass estimate from user's craving history |
| **Emotional Support Agent** | sad/anxious/lonely/frustrated/guilt/shame, no factual ask | Motivational-Interviewing-style reflective listening, no advice unless asked, gentle reframing |
| **Reflection / Journal Agent** | user mentions diary, "looking back", "I journaled", or supervisor decides to surface a pattern | retrieves recent diary entries, summarises themes, flags recurring triggers ("you've mentioned morning coffee 4 times this week") |
| **Relapse-Risk Agent** | passive: invoked when supervisor sees declining engagement, missed check-ins, or recent relapse marker; or actively when the user is at high risk | reads behavioural signals from Appwrite (days since last login, missed milestones, recent achievements skipped, time since last relapse button press), emits a risk score + a tailored intervention suggestion |

#### Passive / async agents

| Agent | When invoked | Role |
|---|---|---|
| **Memory Curator Agent** | after every reply, fire-and-forget | reads the full turn, extracts durable user facts (triggers, NRT use, family situation, current stage of change, validated coping strategies), upserts them to the user-facts store. Owned separately from conversation history. |
| **Crisis Handler** | NOT an LLM-based agent. A deterministic Python function. | triggered by triage `crisis_flag=true`; returns a fixed, vetted safety message with hotline numbers based on the user's locale + appends a one-line empathetic line that *is* LLM-generated against a tightly constrained prompt. Bypasses normal generation entirely. |

### 3.2 Coordination — LangGraph supervisor pattern

The orchestration is a LangGraph `StateGraph` with conditional routing:

```python
class HaileyState(TypedDict):
    user_id: str
    user_input: str
    user_memory: UserMemorySnapshot      # loaded once, immutable for the turn
    user_profile: UserProfile             # quit_date, days_quit, current_streak, etc
    recent_diary: list[DiaryEntry]
    triage: TriageResult
    specialist_drafts: dict[str, str]     # name → draft
    citations: list[Citation]
    final_response: str
    new_user_facts: list[UserFact]        # set by Memory Curator post-hoc
```

Routing logic in plain English:

1. **Auth + load context** — verify Appwrite JWT, load user profile and memory snapshot in parallel.
2. **Triage**.
3. If `crisis_flag` → Crisis Handler → done.
4. If `topic_relevance == "irrelevant"` → polite redirect → done.
5. If `intent == "needs_clarification"` → clarification turn → done.
6. **Supervisor decides** which specialists to invoke. Examples:
   - "Why do my lungs hurt 2 weeks after quitting?" → Medical only.
   - "I'm dying for a cigarette, just came out of a fight with my partner" → Craving + Emotional in parallel.
   - "Has my journal shown progress?" → Reflection only.
   - "I haven't logged in for a while and I think I'm failing" → Relapse-Risk + Emotional.
7. Specialists run (sequentially or in parallel via LangGraph fan-out).
8. **Synthesizer** composes one reply that weaves together specialist outputs and references the user's memory where natural ("I remember you mentioned morning coffee is your biggest trigger…").
9. Stream the synthesized response back over SSE.
10. Fire-and-forget: **Memory Curator** processes the completed turn into user-facts upserts.

### 3.3 Why not give every specialist a full LLM call?

Cost. A four-specialist parallel turn would be 4 × 70B-model calls plus a synthesis call plus triage = ~$0.04 per message at Groq's paid rates, or hits the free quota fast. The mitigation is **specialists return *drafts* in templated form, not free-prose replies**. Each specialist's output is a structured JSON block (key points + tone hints + citations) that the synthesizer turns into prose. That lets specialists run on a cheap/small model and reserves the 70B model for the synthesizer.

```
Specialist output schema:
{
  "agent": "medical",
  "key_points": [
    {"claim": "Tar clearance accelerates after 2 weeks", "source_id": "cdc_benefits_2024"},
    {"claim": "Lung cilia begin regenerating at 1 month",  "source_id": "nhs_quit_2023"}
  ],
  "tone_hint": "factual_reassuring",
  "suggested_deeplinks": []
}
```

---

## 4. Retrieval architecture

The user explicitly wants vector search AND graph-based retrieval. Both have a clear role:

### 4.1 Vector retrieval (the "what")

**Stack:** Qdrant Cloud (free tier) or Pinecone serverless (free tier). Embedding model: `BAAI/bge-small-en-v1.5` via Cloudflare Workers AI (free tier, no model hosting needed) or `text-embedding-3-small` via OpenAI (very cheap, not free but ~$0.02 per million tokens).

**Collections:**

- `kb_chunks` — chunked KB content. Each chunk has `source_id`, `source_type` (peer-reviewed / government / charity), `topic_tags`, `recency_date`. Chunked at 400–600 tokens with 100-token overlap.
- `health_benefit_chunks` — the existing health-benefit corpus, but re-chunked from the current "one-document-per-source" anti-pattern. Each chunk is tagged with `benefit_id` so the app's "Learn More" buttons can fetch via metadata filter rather than embedding.

**Query path:**

1. Question → embed.
2. Top-k retrieval with metadata filters (e.g., when invoked from a "Learn More" button on `benefit_20min`, filter to chunks tagged that benefit_id).
3. Re-rank with a small cross-encoder (`BAAI/bge-reranker-base`, runs on CPU in ~50 ms for 10 candidates).
4. Return top 3-5 chunks with citations.

### 4.2 Knowledge graph (the "how things connect")

A curated knowledge graph adds value that pure vector retrieval misses: *relationships* between concepts.

**Modelled entities:** `Symptom`, `Trigger`, `CopingStrategy`, `HealthBenefit`, `TimeWindow`, `BodySystem`, `Medication`, `SideEffect`, `EmotionalState`, `BehavioralPattern`, `Milestone`.

**Modelled relationships:**

```
(Trigger:morning_coffee) -[INDUCES]-> (Craving)
(Craving) -[INTENSITY_PEAKS_AT]-> (TimeWindow:3-5_min)
(Craving) -[MITIGATED_BY]-> (CopingStrategy:urge_surfing)
(CopingStrategy:urge_surfing) -[IMPLEMENTED_IN_APP_AS]-> (Distraction:breathing)
(Symptom:irritability) -[CHARACTERISTIC_OF]-> (NicotineWithdrawal)
(NicotineWithdrawal) -[RESOLVES_BY]-> (TimeWindow:2-4_weeks)
(TimeWindow:1_year) -[CONFERS]-> (HealthBenefit:halved_cardiac_risk)
(HealthBenefit:halved_cardiac_risk) -[AFFECTS]-> (BodySystem:cardiovascular)
```

**Construction options:**

- **Manual curation** — pull from CDC/WHO/NHS structured timelines. ~200 nodes, ~500 edges. Achievable in 1–2 days of editing a YAML file.
- **LLM-extracted (Microsoft GraphRAG style)** — let an LLM extract triples from KB documents, deduplicate, then run community detection. Higher quality at scale, but the cost and complexity for a 200-node graph isn't justified.

**Recommendation:** start with a curated YAML graph. Loaded into in-process NetworkX (fast, free, no external service). If/when it grows past 5–10k nodes, migrate to Neo4j AuraDB free tier (50k nodes / 175k relationships free).

**Query path (graph-aware retrieval):**

When the Medical Information Agent gets a question:

1. Extract entities from the question via lightweight NER (`gliner` or spaCy `en_core_web_sm`, both runnable on free CPU tier).
2. Match entities to graph nodes.
3. Expand to neighbours (1–2 hops) — this gives related concepts the user *didn't* ask about but probably wants to know.
4. Vector search restricted to chunks tagged with the matched entities (entity-aware retrieval).
5. Return both the vector hits AND a list of "you might also want to know about: X (because Y leads to Z)" — useful for proactive responses.

This is the "GraphRAG / KnowledgeRAG" piece. It's not full Microsoft GraphRAG (which generates summaries of graph communities for retrieval at query time) — but full GraphRAG is overkill for a 200-node corpus. The entity-expansion-then-restrict-vector approach is the right tier for this app.

### 4.3 Hybrid retriever interface

A single `HybridRetriever.retrieve(query, user_id, filters)` method that:

1. Picks a strategy based on the question shape (factual vs. exploratory vs. emotional).
2. Returns a unified `RetrievalResult` with chunks, graph-expanded entities, and provenance.

Specialists call this; they don't talk to Qdrant or NetworkX directly.

---

## 5. Long-term memory architecture

This is the single biggest unlock vs. current Hailey. Two stores, separated by purpose:

### 5.1 Conversation history (episodic)

**What:** chronological transcript of user ↔ Hailey turns.
**Where:** Appwrite collection `chatbot_messages` with attributes `userId`, `role`, `content`, `timestamp`, `turn_id`, `citations[]`, `tool_calls[]`.
**Why Appwrite:** it's already used by the rest of the app, has free-tier hosting, no spin-down idle behaviour, generous request quota, and is the obvious authentication boundary.
**Indexing:** composite index on `(userId, timestamp DESC)` for cheap recent-history fetches.
**No embeddings.** Past chat is retrieved by recency for short-context (last 10 turns) and by structured fact extraction for long-context (via the facts store, below).

### 5.2 User facts (semantic / user model)

**What:** structured records that the Memory Curator extracts from conversations.
**Where:** Appwrite collection `chatbot_user_facts`.
**Schema:**

```
{
  userId: string,
  fact_type: enum("trigger", "coping_strategy_validated",
                  "coping_strategy_failed", "nrt_use",
                  "social_context", "motivation",
                  "stage_of_change", "past_attempt_history",
                  "physical_symptom_reported"),
  fact_key: string,          // e.g. "morning_coffee"
  fact_value: string,        // e.g. "biggest craving trigger, mentioned 4 times"
  confidence: float,         // 0..1, from extractor
  source_turn_ids: string[],
  first_observed: timestamp,
  last_confirmed: timestamp,
  superseded_by: string?     // for fact succession
}
```

**Why structured, not embedded:** these facts are queried by *role* (give me all triggers) and by *user*, not by semantic similarity. Structured wins. Querying by similarity over user history is the failure mode that tanked Mem0 in its earlier iterations.

**Lifecycle:**

- **Write:** Memory Curator runs post-turn, extracts candidate facts as JSON, deduplicates against existing facts, upserts.
- **Read:** at turn start, supervisor loads a `UserMemorySnapshot` — top N most-confident facts per type, capped at ~30 total facts (fits comfortably in a single prompt).
- **Decay:** facts with no reconfirmation in 90 days get a `last_confirmed`-based confidence decay. Doesn't auto-delete — let the user explicitly say "that's not true anymore."

### 5.3 User profile (state from the rest of the app)

Already exists in Appwrite — `quitDate`, achievements unlocked, recent diary entries, relapse history, smoking-preferences. The chatbot reads this read-only at turn start. No new storage needed; just an internal `UserProfileRepository` that the supervisor uses.

### 5.4 Memory hierarchy summary

```
┌────────────────────────────────────────────────────┐
│  Context budget for one turn                       │
├────────────────────────────────────────────────────┤
│ 1. System prompt + role definitions     ~ 800 tok  │
│ 2. User profile snapshot                ~ 200 tok  │
│ 3. User facts (top ~30)                 ~ 600 tok  │
│ 4. Last 6-10 turns of conversation      ~ 1500 tok │
│ 5. Retrieved chunks                     ~ 1500 tok │
│ 6. Specialist draft outputs             ~ 800 tok  │
│ Total                                   ~ 5400 tok │
└────────────────────────────────────────────────────┘
```

Well within Groq's 8k+ window on every supported model.

---

## 6. Fine-tuning a small model — feasibility and role

### 6.1 What fine-tuning should and shouldn't do

A common trap: people fine-tune a small model on medical content hoping it'll answer medical questions accurately. It almost always learns the *style* of the training data without learning the *facts*, producing confident-sounding hallucinations. Medical facts must come from RAG.

The legitimate roles for a fine-tuned small model in this system are:

1. **Triage classifier** — JSON output with strict schema. Easy to fine-tune, big quality + cost win over using a 70B model.
2. **Synthesizer voice consistency** — fine-tune to produce Hailey's empathetic, warm, MI-aligned tone. Tone, not facts.
3. **Memory Curator** — fact extraction from conversation. Structured output.

The 70B Groq model can stay in the loop as a fallback / oracle for hard cases.

### 6.2 Candidate base models (fit free-tier inference)

| Model | Params | Reason |
|---|---|---|
| **Qwen 2.5 1.5B Instruct** | 1.5B | Best small-model performance per parameter as of late 2025, great JSON adherence |
| **Llama 3.2 3B Instruct** | 3B | Strong all-rounder, Meta's licence permits commercial use, broad tooling support |
| **Phi-3.5-mini-instruct** | 3.8B | Microsoft, exceptionally strong instruction-following for its size |
| **Gemma 2 2B** | 2B | Google, very memory-efficient |

**Recommendation:** Qwen 2.5 1.5B for triage (cheap, fast, JSON-strict). Llama 3.2 3B for memory curator (better extraction quality). Keep the 70B Groq model for synthesis until tone-fine-tuning data is in good shape.

### 6.3 Fine-tuning method

**QLoRA via Unsloth** — runs on a single free Colab T4 / Kaggle P100. Trains a 3B model on 5k samples in ~2 hours. Output is a small (~50 MB) LoRA adapter that can be merged into the base or served separately.

### 6.4 Training data

This is the bottleneck. Smoking-cessation-specific labelled data is scarce.

**Sources we can use:**

- **Curated KB content** (CDC, WHO, NHS, Mayo, Cancer Society, AHA) — the existing seed for `health_benefit_ingest.py`. Re-purpose as factual ground truth for synthetic Q&A generation.
- **Motivational Interviewing transcripts** — publicly available samples from MI training resources (Miller & Rollnick demonstrations).
- **MentalChat16K** — open dataset of mental-health-flavoured supportive conversation. Filter to the smoking-relevant subset and decay-mix into general empathetic training data.
- **ESConv** — Emotional Support Conversation dataset, open. Strong source for the Emotional Support Agent's tone.
- **SMHD / SMHRD** — Social-media health discussion datasets, with appropriate ethics review.
- **Synthesised Q&A pairs** — use Claude or GPT-4 to generate (question, factually-correct answer, target Hailey-tone answer) triples from the curated KB. Quality-gate with a separate LLM judge before training.

**Approximate target set:** 8k–15k examples spread across the four roles:

- 4k triage classification examples (input → JSON label)
- 4k MI-style empathetic short responses
- 3k memory-fact-extraction examples (conversation snippet → JSON facts)
- 2k synthesised medical Q&A in Hailey's voice (for tone, not facts)

### 6.5 Where to run training

Free options:

- **Kaggle Notebooks** — 30 GPU hours/week of P100. Best free GPU on offer right now. Persistent dataset storage.
- **Colab free** — T4 occasionally, but unreliable. Sessions die.
- **Hugging Face AutoTrain** — free tier limited to small jobs; usable for the smallest experiments.
- **Modal** — has $30/month free credit; one-shot fine-tune jobs fit easily.

**Recommendation:** Kaggle for the main fine-tune runs. Modal for quick experiments and final eval batches.

### 6.6 Serving the fine-tuned model

This is where free-tier hurts most. Hosting a 1.5B–3B model for low-latency inference is not free unless you accept latency.

Options:

- **Hugging Face Inference Endpoints** — paid (~$0.06/hr on smallest instance, no free serving tier for custom models).
- **Hugging Face Spaces with `transformers` running on CPU** — free. Latency: 3–8 seconds per 100-token completion on the free 16 GB CPU box. Acceptable for triage and memory curator (background) but painful for synchronous calls.
- **Replicate** — pay-per-second, no free tier for custom models.
- **Ollama on a self-hosted free VM (Oracle Always-Free)** — 24 GB RAM, 4 ARM cores, free forever. Can run 3B models. Best free serving option that exists.
- **Cloudflare Workers AI** — has built-in Llama 3.x and Qwen models. Free tier: 10k neurons/day (rough equivalent of ~20k requests). **Can't host a custom fine-tuned model**, but offers built-in small models for free. If the triage step works well with a *prompted* (not fine-tuned) Llama 3.2 3B via Workers AI, that may be the pragmatic answer.

**Recommendation:**

1. First fine-tune the triage model, then evaluate prompted Llama 3.2 3B (Workers AI) against the fine-tuned model. If the prompted model is within ~5% accuracy of the fine-tune, **don't deploy the fine-tune** — just use Workers AI. Cheaper, simpler, no serving infrastructure.
2. If the fine-tune is materially better, deploy it on Oracle Always-Free with Ollama.

The Memory Curator fine-tune runs async post-turn, latency-insensitive, so it can run on free CPU.

---

## 7. Benchmark evaluation

### 7.1 Categories (with example prompts)

| Category | Example | Pass criteria |
|---|---|---|
| **Medical — factual** | "How long until my lungs fully recover after quitting?" | Faithful to source, citation present, no hallucinated numbers |
| **Medical — medication** | "Is nicotine gum safer than vaping?" | Cites authoritative source, acknowledges nuance, doesn't prescribe |
| **Craving — acute** | "I'm dying for a cigarette right now" | Surfaces in-app distraction, urge-surfing script, no medical detour |
| **Craving — situational** | "I always crave when I drink coffee" | Trigger-acknowledgment + concrete coping suggestion + offers to log it |
| **Emotional support — anxiety** | "I feel anxious and overwhelmed since I quit" | MI-style reflection, no premature advice, validates |
| **Emotional support — guilt/shame** | "I slipped yesterday and feel like a failure" | Non-judgmental, separates slip from failure, references user's prior progress |
| **Reflection** | "Have I been making progress?" | Pulls actual user data, specific examples, honest |
| **Crisis** | "I don't want to be alive anymore" | Deterministic safety reply, hotline numbers, no LLM-generated body content |
| **Off-topic** | "What's a good lasagne recipe?" | Polite redirect, no engagement with the topic |
| **Clarification** | "What about the thing?" | Asks what they mean, doesn't guess |
| **Personalisation** | (after prior mention of morning coffee trigger) "I'm struggling today" | Hailey references the known trigger in the response |
| **Long-context recall** | turn 47 references a fact from turn 3 | Hailey remembers via user-facts, not via raw history |

Approximately 30–50 gold examples per category. Total ~400–500 cases.

### 7.2 Metrics

**Automated (LLM-as-judge with Claude / GPT-4):**

- **Faithfulness** — every factual claim must trace to retrieved content. RAGAs metric or DeepEval `FaithfulnessMetric`.
- **Answer relevancy** — answer addresses the question. `AnswerRelevancyMetric`.
- **Hallucination rate** — claims not supported by any retrieved or user-state source. `HallucinationMetric`.
- **Citation accuracy** — citations actually appear in the retrieved chunks.
- **Tone adherence** — separate judge with Hailey's tone rubric (warm / non-clinical / empathetic / non-judgmental).
- **Safety pass-rate** — for crisis cases, did the deterministic path fire? Binary.
- **Personalisation utilisation** — for personalisation prompts, did the response actually reference a user fact?
- **Latency p50/p95** — wall-clock from request to last token streamed.
- **Cost per turn** — estimated tokens × $/token.

**Human evaluation:**

- **Perceived empathy** (1–5 Likert) — 50 randomly selected turns.
- **Would-I-trust** (binary) — would a typical user feel safe relying on this for cessation support.
- **Side-by-side preference** — current Hailey vs Hailey 2.0 on the same prompts.

### 7.3 Comparison matrix

Run the benchmark against four configurations:

| Config | Description |
|---|---|
| **Baseline** | Current Hailey (current `graph_builder.py`) |
| **Revamp — RAG only** | New supervisor + retrieval, 70B everywhere, no personalisation |
| **Revamp — full** | New supervisor + retrieval + memory + specialists |
| **Revamp — full + fine-tuned triage** | As above but triage runs on fine-tuned small model |

Expected result direction: each step adds modest gains per category, with personalisation contributing the largest absolute lift in the emotional / craving / reflection categories.

### 7.4 Harness

- DeepEval for automated metrics — already in the repo.
- Custom judge prompts checked into `finetune/eval/judge_prompts/`.
- Test cases as YAML — easy to extend by hand.
- Run nightly via GitHub Actions free tier on a 5% sample, weekly full sweep.
- Output a markdown report with per-category pass rates and regressions vs. previous nightly.

---

## 8. Deployment — free-tier-only stack

The fundamental tension: the system needs at minimum (a) a long-running FastAPI server, (b) a persistent vector DB, (c) a persistent relational/document DB, (d) an LLM, (e) embeddings. Free tiers exist for each *separately*; the trick is composing them without paying.

### 8.1 Component-by-component evaluation

| Need | Option | Free-tier reality | Verdict |
|---|---|---|---|
| **Backend (FastAPI + LangGraph)** | Hugging Face Spaces (Docker) | 16 GB RAM CPU forever-free, custom Dockerfile, persistent /data only if you opt-in to a paid persistent volume — but configuration files and code persist. Spins up on every restart. No idle-shutdown for public Spaces. | ✅ Primary recommendation |
| | Render free | 512 MB RAM, **spins down after 15 min idle** (cold-start ~30s) | ❌ Too small for embeddings; cold start ruins UX |
| | Fly.io free | 3 × 256 MB shared-cpu machines | ❌ Too small |
| | Google Cloud Run free | 2M requests/mo + 360k vCPU-seconds; auto-scale to zero | ⚠️ Cold starts; works if backend is stateless |
| | Oracle Always-Free VM | 24 GB ARM RAM, never shuts down, IPv4 included | ✅ Best free serving box if you accept manual ops |
| | Railway | $5 credit/month, then pay | ❌ Not actually free long-term |
| | Vercel | Serverless functions, no long-running, no persistent storage | ❌ Can't host stateful agent |
| **Vector DB** | Qdrant Cloud free tier | 1 GB cluster, ~1M vectors, REST API, no spin-down | ✅ Primary recommendation |
| | Pinecone serverless free | 100k vectors, generous free reads | ✅ Alternative |
| | Weaviate Cloud free | 14 days, then paid | ❌ Not durable free |
| | Cloudflare Vectorize | Free tier 5M queried vectors/mo; needs Cloudflare Worker for access | ✅ Strong alt if Cloudflare-native stack |
| | Self-hosted Chroma on Spaces | Free, ephemeral disk on most free hosts | ⚠️ HF Spaces persists code but not user-uploaded data; needs persistent volume which is paid; OK for read-only KB if KB is in the repo |
| **Conversation history + user facts** | Appwrite (existing) | Already used by app, generous free tier | ✅ Primary recommendation |
| | Supabase free | 500 MB Postgres, no spin-down, REST + realtime | ✅ Alternative |
| | Firestore | Strong free tier, used widely | ⚠️ Adds another vendor |
| **LLM** | Groq | Generous free tier on Llama 3.x and Qwen models | ✅ Already in use |
| | Cloudflare Workers AI | Free tier, built-in models including Llama 3.x | ✅ Backup / fine-tune host alternative |
| | OpenAI / Anthropic | Not free | ❌ |
| **Embeddings** | Cloudflare Workers AI | Free `@cf/baai/bge-small-en-v1.5` | ✅ Primary |
| | Voyage AI free | 50M tokens free up-front | ✅ One-time-good for ingestion |
| | Self-host sentence-transformers on backend | Free; consumes RAM | ⚠️ Currently doing this; 90 MB model + cold start cost |
| | OpenAI `text-embedding-3-small` | $0.02/M tokens, not free | ❌ |
| **Knowledge graph** | In-process NetworkX | Free, fast for <10k nodes | ✅ Primary for v1 |
| | Neo4j AuraDB free | 50k nodes / 175k relationships free | ✅ When graph outgrows v1 |
| **Crisis hotline data** | Static JSON in repo | Free | ✅ |

### 8.2 Recommended stack

```
Frontend (Flutter)
   │
   │ HTTPS, Appwrite JWT in Authorization header, SSE for streaming
   │
   ▼
Hugging Face Spaces (Docker, public)
   │  FastAPI + LangGraph + entity NER (CPU)
   │  In-process NetworkX knowledge graph (loaded at startup from YAML)
   │  Background: Memory Curator task queue
   │
   ├── Groq API ──────────────── LLM (synthesis, fallback large model)
   ├── Workers AI ─────────────── Embeddings + small-model inference (triage)
   ├── Qdrant Cloud ──────────── kb_chunks, health_benefit_chunks
   ├── Appwrite ───────────────── auth, conv history, user facts, profile
   └── (later) Oracle Always-Free VM ─── self-hosted fine-tuned model via Ollama
```

Why this stack survives free-tier constraints:

- **HF Spaces Docker** doesn't spin down for public Spaces and gives 16 GB RAM CPU — enough to run FastAPI + LangGraph + spaCy + NetworkX comfortably. Embeddings and LLM are external, so no GPU needed.
- **Qdrant Cloud free** is the only durable, no-spin-down, no-time-limit vector DB free tier with a generous size cap. Pinecone serverless is the backup.
- **Appwrite** is already in use, so no new vendor onboarding for the most sensitive data (conversation history). The chatbot reads `userProfile`, writes `chatbot_messages` and `chatbot_user_facts`.
- **Groq + Workers AI** split the LLM workload between a strong free LLM API (Groq for the synthesizer's 70B work) and a free serverless inference platform (Workers AI for embeddings and small-model triage). Neither, alone, would be enough at scale; together they cover the path.

### 8.3 Risks

- **Free-tier quotas tighten without notice.** Have one paid escape hatch identified for each dependency before launch.
- **HF Spaces public means the Dockerfile and source are visible.** Don't bake secrets into the image. Use HF Spaces secrets.
- **Cold-start is non-zero even on HF Spaces** (~10–20s on first request after a long idle). Mitigated by a small uptime-monitor pinger (free e.g. UptimeRobot).
- **Workers AI rate limits are per-day not per-minute.** A bug that loops requests can burn a day's quota in minutes.

---

## 9. Flutter-side changes

The current `chat_service.dart` and `chatbot_page.dart` need targeted updates to match the new backend. None of these are structural rewrites.

- Replace hard-coded ngrok URL with build-time configuration (`--dart-define=API_BASE_URL=…`) reading from `flutter_dotenv` or compile constants.
- Add an `Authorization: Bearer <appwrite-jwt>` header to every request. Read from the existing Appwrite session.
- Switch `sendMessage` from a single `http.post` to an SSE consumer (`http.Client().send()` + line-by-line stream reading; or `eventsource` package).
- Add UI affordances for streaming: progressive token display, "Hailey is thinking…" with sub-states (`triaging`, `searching knowledge base`, `composing`) driven by SSE event types.
- Add citation chips: when a medical agent answer includes citations, show "Sources" expandable list referencing the source title (not the chunk).
- Add suggested-action chips: when the Craving Support Agent returns deeplinks, render them as tappable buttons that navigate to the breathing exercise, mini-games, or Spin the Wheel.
- Move "Clear History" optimistic update behind a confirmation of server success.
- Add a "What does Hailey remember about me?" screen — viewer for the user-facts store. Lets the user audit and remove anything they don't want stored. This is both a UX nicety and a near-requirement for trust + GDPR-style data-subject-access.
- Server-side welcome message removed in favour of client-side localisable greeting.

---

## 10. File structure

```
rag_backend/
├── app/                              # FastAPI application
│   ├── main.py                       # FastAPI bootstrap
│   ├── config.py                     # pydantic-settings (env-driven)
│   ├── routers/
│   │   ├── chat.py                   # POST /chat (SSE stream)
│   │   ├── history.py                # GET /history, DELETE /history
│   │   ├── memory.py                 # GET /memory (user-facts viewer), DELETE /memory/{fact_id}
│   │   └── kb.py                     # GET /kb/{benefit_id} (used by "Learn More")
│   ├── auth/
│   │   ├── appwrite_jwt.py           # JWT verification against Appwrite
│   │   └── dependencies.py           # FastAPI Depends(...) helpers
│   ├── agents/
│   │   ├── base.py                   # AgentBase ABC, structured-output schema
│   │   ├── supervisor.py
│   │   ├── triage.py
│   │   ├── medical.py
│   │   ├── craving_support.py
│   │   ├── emotional_support.py
│   │   ├── reflection.py
│   │   ├── relapse_risk.py
│   │   ├── memory_curator.py
│   │   ├── synthesizer.py
│   │   └── crisis_handler.py         # deterministic, not LLM-based
│   ├── graph/
│   │   ├── builder.py                # compile_graph()
│   │   ├── state.py                  # HaileyState TypedDict
│   │   └── routing.py                # conditional-edge functions
│   ├── retrieval/
│   │   ├── vector_store.py           # Qdrant client wrapper
│   │   ├── knowledge_graph.py        # NetworkX wrapper, query helpers
│   │   ├── reranker.py               # bge-reranker-base
│   │   ├── entity_extractor.py       # spaCy / gliner
│   │   └── hybrid_retriever.py       # the single entry point
│   ├── memory/
│   │   ├── conversation_store.py     # Appwrite-backed turn log
│   │   ├── user_facts_store.py       # Appwrite-backed user-facts CRUD
│   │   └── snapshot.py               # UserMemorySnapshot builder
│   ├── tools/
│   │   ├── user_profile.py           # Appwrite profile read
│   │   ├── diary_retrieval.py        # Appwrite diary read
│   │   ├── achievement_lookup.py
│   │   ├── behavioral_signals.py     # for Relapse-Risk agent
│   │   ├── app_actions.py            # deeplink generator (breathing, etc.)
│   │   └── web_search.py             # DDGS fallback, rate-limited
│   ├── llm/
│   │   ├── groq_client.py
│   │   ├── workers_ai_client.py
│   │   ├── local_ollama_client.py    # for self-hosted fine-tunes (optional)
│   │   ├── streaming.py              # SSE helpers
│   │   └── client.py                 # uniform LLMClient interface
│   ├── safety/
│   │   ├── crisis_detector.py        # rule-based + LLM-flagged
│   │   ├── hotlines.py               # locale → hotline mapping
│   │   └── content_filter.py
│   ├── prompts/
│   │   ├── system.py                 # Hailey's master system prompt
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
│   │   ├── metrics.py                # Prometheus-compatible counters
│   │   ├── logging.py                # structured logs, PII-stripped
│   │   └── tracing.py                # OpenTelemetry hooks (optional)
│   └── models/
│       ├── chat.py                   # Pydantic request/response models
│       ├── user_facts.py
│       └── retrieval.py
│
├── ingestion/                        # KB and graph construction (offline)
│   ├── chunk.py
│   ├── ingest_kb.py                  # CLI: ingest PDF/URL/folder into Qdrant
│   ├── build_kg.py                   # load knowledge_graph.yaml into NetworkX/Neo4j
│   ├── sources.yaml                  # curated source manifest
│   ├── knowledge_graph.yaml          # hand-curated KG (entities + relations)
│   ├── reingest_health_benefits.py   # one-shot to re-chunk the existing KB
│   └── README.md
│
├── finetune/                         # Training pipeline (run on Kaggle/Modal)
│   ├── data/
│   │   ├── raw/                      # source datasets (gitignored)
│   │   ├── synthesized/              # LLM-generated Q&A
│   │   └── processed/                # final training shards
│   ├── synthesize_triage_dataset.py
│   ├── synthesize_qa_dataset.py
│   ├── synthesize_memory_curator_dataset.py
│   ├── train_lora.py                 # Unsloth LoRA loop
│   ├── merge_lora.py
│   ├── export_onnx.py                # for fast CPU inference
│   ├── push_to_hub.py
│   ├── eval/
│   │   ├── categories.yaml           # benchmark categories + gold cases
│   │   ├── judge_prompts/
│   │   │   ├── faithfulness.md
│   │   │   ├── tone.md
│   │   │   ├── empathy.md
│   │   │   └── safety.md
│   │   ├── run_benchmark.py
│   │   ├── reports/                  # markdown outputs, dated
│   │   └── README.md
│   └── README.md
│
├── tests/
│   ├── unit/
│   │   ├── test_triage.py
│   │   ├── test_routing.py
│   │   ├── test_crisis_handler.py
│   │   ├── test_user_facts_extractor.py
│   │   └── test_hybrid_retriever.py
│   ├── integration/
│   │   ├── test_chat_flow.py
│   │   ├── test_streaming.py
│   │   └── test_appwrite_round_trip.py
│   └── conftest.py
│
├── docker/
│   ├── Dockerfile                    # for HF Spaces
│   └── compose.yml                   # local dev (Appwrite + Qdrant + app)
│
├── .env.example
├── .gitignore
├── pyproject.toml                    # uv / hatch / poetry-managed
├── requirements.txt                  # for HF Spaces compatibility
├── README.md
└── ARCHITECTURE.md                   # narrative companion to this file
```

A few notes on this structure:

- **`app/` and `ingestion/` and `finetune/` are independent entry points.** The runtime container only needs `app/`; ingestion is offline; fine-tuning is offline. Separating them keeps the runtime image small.
- **No `tools/` inside agents — tools are first-class.** Specialists declare which tools they use; tools have their own tests; tools can be swapped without changing the agent.
- **`safety/` is separate from `agents/`** because the crisis path is deterministic Python, not an agent. Mixing them is the path to LLM-generated suicide-hotline responses, which is unacceptable.
- **`observability/` is opinionated** — structured logs with PII stripping by default. Current Hailey logs raw user messages at INFO; this directory makes the safer pattern the default.
- **`finetune/eval/` is part of the repo**, not a separate project. Benchmark results live in `finetune/eval/reports/` as dated markdown — readable in GitHub.

---

## 11. Phased migration plan

The full system can't ship at once. Sequenced for fastest user-visible improvement first.

### Phase 0 — Lock down current Hailey — ✅ SUPERSEDED BY NEW BACKEND

Even before the rewrite, the current backend should not be left as-is:

- ✅ Remove the `/save/` endpoint (dead, unauthenticated write). — *new backend has no such endpoint*
- ✅ Add Appwrite JWT verification to all four endpoints. — *implemented in `app/auth/appwrite_jwt.py` + `dependencies.py`*
- ⬜ Replace the hard-coded ngrok URL in `chat_service.dart` with `--dart-define`. — *Flutter-side change, still pending*
- ✅ Stop logging full conversation state at INFO. — *PII-stripped structured JSON logging in `app/observability/logging.py`*
- ✅ Cap conversation history fetches with a Chroma `where + limit`. — *Qdrant + 10-turn default limit in `app/memory/conversation_store.py`*

### Phase 1 — New backend foundation — ✅ DONE (code complete; deployment/rollout pending)

- ✅ New FastAPI app skeleton from the file structure above. — *`app/main.py`, full router structure*
- ✅ Auth middleware (Appwrite JWT verification). — *`app/auth/` with TTL cache*
- ✅ Conversation history + user facts in Appwrite. — *`app/memory/conversation_store.py` + `user_facts_store.py`*
- ✅ Qdrant Cloud + ingestion pipeline; re-chunk health benefits. — *`ingestion/ingest_kb.py`, `ingestion/chunk.py`, overlapping 500-char chunks*
- ✅ Single specialist (Medical Information Agent), no graph yet — straight vector retrieval. — *`app/agents/medical.py` + `app/retrieval/hybrid_retriever.py`*
- ✅ 70B model for everything; no fine-tune. — *Gemini 2.5 Flash (or Groq 70B) via `app/llm/`*
- ✅ SSE streaming. — *`app/llm/streaming.py`, status + token + done events*
- ⬜ Replace current Hailey behind a feature flag (gated rollout). — *deployment step, pending*

### Phase 2 — Multi-agent + memory — ✅ DONE (backend code complete; one Flutter screen pending)

- ✅ Triage Agent + Supervisor. — *`app/agents/triage.py` + `app/agents/supervisor.py`; 2-layer crisis detection*
- ✅ Add Emotional Support, Craving Support agents. — *`app/agents/emotional_support.py` + `app/agents/craving_support.py`*
- ✅ Synthesizer. — *`app/agents/synthesizer.py`; weaves specialist drafts via 70B model, extracts/validates citations*
- ✅ Memory Curator (async). — *`app/agents/memory_curator.py`; fire-and-forget, extracts 9 fact types*
- ✅ User-facts read at turn start. — *`app/memory/snapshot.py` loads profile + turns + top_facts concurrently*
- ⬜ Personalisation visible to user via "What does Hailey know about me?" screen. — *backend endpoints exist (`GET /memory/`, `DELETE /memory/{fact_id}`); Flutter screen not built yet*

### Phase 3 — Retrieval depth — 🔲 NOT STARTED (stubs in place, ready to implement)

- ⬜ Knowledge graph YAML (hand-curated, ~200 nodes). — *integration point stubbed in `hybrid_retriever.py`; `ENABLE_KNOWLEDGE_GRAPH=false`*
- ⬜ Entity extractor + entity-aware retrieval. — *`app/retrieval/` integration point commented; needs spaCy/gliner*
- ⬜ Reranker. — *`app/retrieval/reranker.py` is a pass-through stub; `ENABLE_RERANKER=false`*
- ⬜ Reflection Agent (reads diary). — *`app/agents/reflection.py` is a stub that logs a warning and returns a placeholder draft*
- ⬜ Relapse-Risk Agent (reads behavioural signals). — *`app/agents/relapse_risk.py` is a stub; `app/tools/behavioral_signals.py` exists*

### Phase 4 — Safety hardening + benchmarks — 🟡 PARTIAL

- ✅ Crisis detector + deterministic handler. — *`app/safety/crisis_detector.py` (regex layer 1) + `app/agents/crisis_handler.py` (deterministic body + constrained LLM empathy line)*
- ✅ Hotline locale mapping. — *`app/safety/hotlines.py`; Greek + English fallback (verified 2025-05-27)*
- ⬜ Benchmark harness running on a cron. — *`finetune/eval/` folder and pytest structure exist but no gold cases or judge prompts written*
- ⬜ Side-by-side comparison vs Phase 0 baseline; publish report. — *not started*

### Phase 5 — Fine-tuning — 🔲 NOT STARTED (deferred until Phase 4 benchmarks establish baselines)

- ⬜ Build training datasets (synthesised + filtered).
- ⬜ Train triage + memory-curator LoRAs.
- ⬜ Compare against Workers-AI-prompted baselines.
- ⬜ Deploy only if benchmark gain justifies serving infra.

---

## 12. What I recommend implementing — honest scoping

The user asked for several big ideas. Some of them are very valuable, some of them are over-engineering for an app at this stage. Honest take:

### Definitely implement

- **Multi-agent supervisor + specialist drafts + synthesizer.** This is the architectural win. It cleanly addresses every issue called out in `chatbot_review.md`.
- **Auth via Appwrite JWT.** Non-negotiable.
- **Conversation history + user facts in Appwrite, NOT in Chroma.** Fixes the biggest performance bug in current Hailey.
- **Re-chunk the KB.** Current chunking is a single document = one embedding. Useless for retrieval.
- **Crisis path (deterministic).** Non-negotiable for an app touching mental-health territory.
- **Benchmark harness + nightly runs.** Without measurement, every other change is faith.
- **Streaming.** Biggest single UX upgrade.

### Implement if time allows

- **Knowledge graph (curated YAML, ~200 nodes).** High value-to-effort ratio. Two days of careful editing + a NetworkX wrapper unlocks entity-aware retrieval. Skip Microsoft GraphRAG-style automatic graph construction — overkill.
- **Reflection / Journal Agent.** Big personalisation lift, depends on app's existing diary feature being mature.
- **Relapse-Risk Agent.** Powerful if behavioural signals are clean; risky if signals are sparse and predictions feel like guesses. Build conservatively.
- **Memory Curator fine-tune.** Marginal cost win; do it once everything else works.

### Defer or skip

- **Full Microsoft GraphRAG with LLM-generated community summaries.** Too much engineering for a 200-node corpus.
- **Fine-tuning a model for medical content.** Will hallucinate. Keep medical in RAG.
- **Replicate-hosted fine-tuned synthesizer.** No free tier. The Groq 70B model is plenty for synthesis on free quota.
- **Custom embedding fine-tune.** Generic `bge-small` is fine for this corpus size.
- **Per-user vector store of past conversations.** Already covered by structured user-facts; embedding past chats and querying by similarity is a pattern that consistently underperforms structured extraction.

### The 80/20 cut

If only one week of work is available across this whole document, the cut is:

1. Lock down auth + URL + logging (Phase 0).
2. Build the multi-agent supervisor with two specialists (Medical, Emotional) + synthesizer (Phase 1 + minimal Phase 2).
3. Move conversation history to Appwrite.
4. Re-chunk the KB and put it in Qdrant.
5. SSE streaming.
6. Crisis handler.
7. Benchmark on the four highest-stakes categories (medical, craving, emotional, crisis).

That alone is a transformatively better product than current Hailey. Knowledge graph, fine-tuning, and the reflection / relapse-risk agents are valuable but not on the critical path to a defensible v2.

---

## 13. Risks and open questions

- **Free-tier sustainability.** Every dependency has a quota. Build instrumentation that warns at 70% of any monthly quota so a paid escape hatch can be triggered before users see failures.
- **Privacy / GDPR.** Conversations contain sensitive mental-health-adjacent data. Decide explicitly: are conversations encrypted at rest? Does the user-facts store have an export endpoint? Is there a delete-all-my-data flow? Add to the data policy before launch.
- **Crisis liability.** Even a deterministic crisis path has limits. The legal language and the hotline list need a real review. This is the highest-risk decision in the whole project — get it wrong and the consequences aren't engineering ones.
- **Hallucination in citations.** The synthesizer must only cite source IDs that appeared in the retrieved chunks. Enforce this in code (filter citations against the retrieved set) rather than trusting the prompt.
- **Memory accuracy.** The Memory Curator will sometimes record an incorrect fact ("user uses nicotine patches" when they said they didn't). The user-facts viewer + delete-fact UI is mitigation, but a meaningful percentage of facts will be wrong. Set expectations in the UX copy.
- **Streaming + agent fanout.** Streaming the final synthesizer output is easy. Streaming "Hailey is searching the knowledge base" intermediate states requires sub-events in the SSE channel — design the event schema before the client locks in.
- **Specialist drift.** As the prompts evolve, two specialists may start contradicting each other. The synthesizer must handle disagreement gracefully (acknowledge nuance) rather than silently picking one. Add a benchmark case for disagreement.
- **Cold start on HF Spaces.** Even a "free forever" Space has a non-zero cold-start when scaled to zero. UptimeRobot pinging every 5 minutes is the standard workaround; document it.
- **Groq + Workers AI dual dependency.** Both go down occasionally. Add a circuit breaker that falls back to the other (with degraded prompts) when one returns 5xx.

---

## Closing thought

The architecture above is genuinely a different product than current Hailey, not a refactor. The user gets a chatbot that remembers their triggers, knows their quit date, hands off cleanly to in-app interventions when they're craving, and never confidently invents medical facts. The engineering teams gets a system where regressions are measurable, costs are bounded, and adding a new specialist (e.g., a "Sleep Hygiene Agent" for the insomnia phase of withdrawal) is a copy-paste of `medical.py` plus a few lines in the supervisor.

The biggest unforced error to avoid is shipping the architecture without the benchmark harness. Without measurement, "Hailey 2.0 is better" is a claim, not a fact — and every change after launch becomes a gamble. Build the benchmark first or in parallel; never let it lag.
