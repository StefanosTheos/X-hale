## Unresolved errors

### Materials and Methods audit — actionable issues

- [ ] **#1 — The participant study has no reportable ethics decision or informed-consent record.**
  Section 3.9 cannot currently state an ethics-committee approval, exemption, identifier, or consent procedure. This is a submission-critical human-subject reporting gap, not a detail that can be inferred from the application.
  **Fix:** Recover the original approval/exemption and consent documentation and report it exactly. If neither exists, determine the applicable institutional and journal requirements before retaining the participant evidence; do not manufacture retrospective approval.

- [ ] **#2 — Essential participant-study procedural metadata are missing.**
  The retained record does not identify recruitment channel, study dates, test setting, device models, moderator script, assistance rules, or compensation. These omissions limit reproducibility and interpretation of assistance and task-time results.
  **Fix:** Recover these fields from the original protocol, communications, devices, or study notes and add them to Sections 3.9 and the ethics statement. Mark any genuinely unrecoverable field as unavailable.

- [ ] **#3 — The satisfaction and qualitative-feedback procedure cannot be reproduced.**
  The exact satisfaction question and response scale, interview or feedback prompts, transcripts/notes, coding framework, coder identities, and agreement records are absent. The current manuscript can only call the findings descriptive recurring comments.
  **Fix:** Locate the original instrument and qualitative records. If available, document collection and analysis faithfully; otherwise retain only auditable satisfaction counts and clearly labelled descriptive observations, without thematic-analysis or saturation claims.

- [ ] **#4 — Participant-level task-time observations are unavailable.**
  Only task means survive, preventing verification and calculation of dispersion, medians, ranges, or outlier-sensitive summaries.
  **Fix:** Recover and archive the participant-level timing sheet. Recalculate each table from the raw observations with a reproducible analysis file; if recovery is impossible, report only the retained means and the missing-data limitation.

- [ ] **#5 — The reported mobile-performance observations lack a reproducible measurement record.**
  The claimed 1.1–1.2 s startup interval and qualitative rendering/CPU/memory/network observations have no retained tool/version, device, OS/build, repetitions, startup definition, sampling window, raw traces, or summary statistics.
  **Fix:** Either recover the original profiler artifacts or repeat profiling on a frozen application build with a documented protocol. Until then, remove unsupported claims such as “no memory leaks,” “exceeded benchmarks,” or “acceptable latency.”

- [ ] **#6 — The participant evidence evaluates the earlier chatbot, not Hailey 2.0.**
  SUS, task completion, satisfaction, and qualitative chatbot impressions cannot be attributed to the revised agent, citation interface, action cards, memory controls, or current safety behavior.
  **Fix:** Keep the evidence streams explicitly separated in this article. Any user-experience claim specific to Hailey 2.0 requires a separate ethically governed user evaluation; do not relabel the earlier study.

- [ ] **#7 — The biometrics interface uses static demonstration data without an explicit in-app provenance warning.**
  It displays health-oriented values despite having no operational Apple Health, Health Connect, Samsung Health, or wearable connection and supplies no data to Hailey.
  **Fix:** Label the screen and values unambiguously as demonstration data or remove the feature from the evaluated build and manuscript figures. Do not claim wearable integration until a functioning, consented data path is implemented and verified.

- [ ] **#8 — Knowledge-source governance metadata are incomplete.**
  The 28-source manifest lacks exact fetch dates, reviewer identity, licensing/access terms, and a completed independent content-review decision. `recency_date` alone does not establish when or by whom deployed content was verified.
  **Fix:** Extend the manifest with fetch/review dates, reviewer, authority rationale, access/licensing status, version/hash, and inclusion decision; establish and document a review/re-indexing procedure.

- [ ] **#9 — The frozen deployed Qdrant corpus has not been inventoried and archived.**
  Repository manifest counts do not prove deployed collection contents, chunk counts, payload completeness, or identity at benchmark time.
  **Fix:** Before final analysis, export collection counts, vector dimensions, payload-schema checks, source/chunk identifiers, and stable corpus/configuration hashes from the evaluated deployment and archive them with the benchmark artifact.

- [ ] **#10 — Health-benefit chunks lack claim-level canonical URLs.**
  The `health_benefit_chunks` collection can expose internal source labels and excerpts but cannot provide complete bibliographic traceability for each displayed claim.
  **Fix:** Add canonical source URL/title and review metadata to each curated health-benefit payload, re-ingest, and validate lookup output. If this occurs after benchmark start, treat it as a new corpus/version rather than silently changing the frozen evaluation.

- [ ] **#11 — Active retrieval has no minimum similarity threshold or content-level deduplication.**
  The top three Qdrant results are accepted even when weak or redundant, and multiple chunks from one source can dominate context. The implemented reranker is disabled.
  **Fix:** After the current frozen campaign, evaluate and configure a defensible similarity threshold and source/content deduplication. Any change requires a new benchmark configuration and must not be credited to the running campaign.

- [ ] **#12 — Citation objects omit canonical URL and document title, and validation is lexical rather than entailment-based.**
  Users receive source identifiers, types, and snippets, but not complete clickable attribution; the current check cannot demonstrate that every generated claim is entailed by its source.
  **Fix:** Persist title and canonical URL in Qdrant payloads and return them in citation objects. Add a separately validated claim–source assessment or expert review if the paper intends to claim citation faithfulness; otherwise retain the narrower “citation object present” wording.

- [ ] **#13 — Recent context is counted as records rather than complete dialogue exchanges.**
  The ten-record limit normally provides about five user–assistant exchanges and can split an exchange under unusual persistence conditions.
  **Fix:** Retrieve complete turn pairs by turn identifier or define the window in exchanges/tokens. Version and re-evaluate the change after the frozen campaign.

- [ ] **#14 — The 30-fact memory limit is applied before confidence sorting.**
  Appwrite returns up to 30 active rows without database-level confidence ordering, after which only that subset is sorted. The result is not guaranteed to contain the globally highest-confidence facts.
  **Fix:** Add deterministic database ordering or retrieve all eligible active facts before bounded ranking, with stable tie-breaking and tests.

- [ ] **#15 — Model-assigned memory confidence is uncalibrated and fact extraction has no empirical validation.**
  The 0.5 threshold is an engineering rule, not an estimated probability, and extraction can omit, distort, or incorrectly attribute information.
  **Fix:** Build a consent-compatible, manually annotated memory test set and report extraction precision/recall, attribution, contradiction, cross-user isolation, and deletion tests before claiming accurate personalization.

- [ ] **#16 — Active facts have no expiry or stale-fact handling.**
  A fact can remain active indefinitely until a higher-confidence conflicting fact is generated or the user deletes it.
  **Fix:** Add confirmation/expiry rules appropriate to fact type, expose `last_confirmed` in user controls, and prompt for reconfirmation of old or sensitive facts. Validate supersession and stale-fact behavior before evaluation claims.

- [ ] **#17 — Conversation and derived-memory deletion are separate, non-atomic operations.**
  Clearing history does not remove facts derived from it, and fact deletion leaves the source conversation. The Flutter combined action sends two concurrent requests and can partially succeed.
  **Fix:** Provide a server-side authenticated combined-erasure transaction or resumable deletion job with a clear completion report, while preserving separate controls only where the lifecycle distinction is explained to users.

- [x] **#18 — Resolved: the chatbot export now paginates through all Hailey records.**
  Cursor-based Appwrite reads now export every conversation turn and every active or superseded memory fact, including source-turn and supersession provenance. The JSON response also reports record totals and remains compatible with the Flutter clipboard consumer.
  **Remaining boundary:** This is a complete export of the two Hailey-owned Appwrite datasets, not a full X-hale account export or proof of GDPR portability across wider application data and external processors.

- [ ] **#19 — Revoked Appwrite JWTs may remain accepted for up to 60 seconds.**
  Successful verification is cached by token hash, introducing a bounded revocation delay.
  **Fix:** Assess the risk and either shorten/disable the cache for sensitive operations, add a revocation-aware mechanism, or document and test the accepted revocation window.

- [ ] **#20 — The deployed API is not configured with least-privilege exposure.**
  CORS permits all origins, and root, health, generated documentation, and metrics endpoints are public when enabled. Metrics reveal operational information even without message bodies.
  **Fix:** Restrict allowed origins, disable public API documentation in production, and authenticate or network-restrict metrics and operational endpoints. Add configuration tests for the production environment.

- [ ] **#21 — Triage parse failure defaults to non-crisis general conversation.**
  A malformed model response can suppress crisis routing for an indirect crisis input that the lexical detector missed.
  **Fix:** Implement and test a safer fallback, such as a constrained clarification/safety response or secondary deterministic assessment, without asserting that all crises can be detected. Changing routing requires a new benchmark version after the current campaign.

- [ ] **#22 — The Flutter client does not transmit the stored application locale to Hailey.**
  Requests use the service default `en`, so the implemented Greek crisis-resource mapping is not selected through the current client flow.
  **Fix:** Send and validate the user's active locale with every chat request, add integration tests for Greek and English, and re-evaluate locale-dependent safety responses.

- [ ] **#23 — Crisis-resource selection and maintenance are too coarse.**
  The English mapping combines resources from several countries, relies on periodic manual verification, and does not establish the user's jurisdiction. Hailey also cannot confirm that help was reached.
  **Fix:** Add jurisdiction-aware resource selection with a maintained verification owner/date and a safe international fallback. Clearly disclose that the system cannot contact or monitor emergency services unless such a workflow is deliberately implemented and governed.

- [ ] **#24 — Prompt-injection and multilingual safety behavior are unevaluated.**
  Request-length validation and the current English benchmark do not cover adversarial instruction attacks, multilingual crisis language, or systematic medical-boundary evasion.
  **Fix:** Add a separately versioned adversarial and multilingual safety suite, with expert review where clinical interpretation is required. Do not modify the active 300-case suite mid-campaign.

- [ ] **#25 — Logging has no completed redaction audit, retention schedule, or access analysis.**
  Structured logs normally avoid full messages and fact values, but user/turn identifiers and provider exception detail remain, and downstream handling is not documented.
  **Fix:** Perform a log-field and exception-path audit, redact or pseudonymize identifiers where feasible, define retention/access controls, and document provider-side logging boundaries.

- [x] **#26 — Resolved: authenticated account-wide Appwrite deletion is implemented.**
  The privacy screen now invokes a confirmation-protected backend workflow that deletes user-owned rows across X-hale and Hailey collections, both sides of social relationships and messages, current and identifiable historical avatar files, and finally the Appwrite authentication identity. The identity is preserved when an earlier step fails so deletion can be retried, and the API returns an explicit incomplete report.
  **Remaining boundary:** The workflow controls X-hale data held in the configured Appwrite project. It cannot independently erase records that an external processor retains under its own policy; the user-facing text now states this boundary.

- [ ] **#27 — The Flutter privacy text contains claims not established by the implementation.**
  It refers to encryption, provider retention, complete export, account deletion, and a 30-day erasure period that have not all been verified or implemented.
  **Fix:** Immediately align the text with the actual bounded controls and verified provider terms. Any GDPR, encryption-at-rest, retention-period, or erasure-timeline statement requires supporting technical and legal evidence.

- [ ] **#28 — Runtime feature-flag documentation is inconsistent.**
  `.env.example` enables web-search fallback while the central default and frozen benchmark configuration disable it. Hosted secrets can override either value.
  **Fix:** Align the example and code defaults, log resolved non-secret flags at startup, and preserve them in benchmark metadata. Do not change the evaluated Space configuration during the active campaign.

- [x] **#29 — Resolved: startup validation, liveness, and dependency readiness are separated.**
  Missing mandatory Groq, Cloudflare, Appwrite, or Qdrant configuration now prevents startup, as does failure to compile the LangGraph. `/health` and `/live` report process liveness only, while cached `/ready` checks Appwrite row access, both configured Qdrant collections, Groq API access, the primary Cloudflare embedding route, and a local FastEmbed route using the same `BAAI/bge-small-en-v1.5` model. Readiness requires every core dependency plus at least one usable embedding route and returns HTTP 503 otherwise. Transient failure of the primary embedding provider therefore degrades to the explicitly enabled local route without falsely declaring the entire service unavailable or forcing Docker to restart an otherwise live process.
  **Operational note:** A forced or cache-expired readiness check performs one small embedding request against each route; the result is cached for 60 seconds. The local model is downloaded during the container build rather than at first request.

- [ ] **#30 — The declared request-latency histogram is never observed.**
  Prometheus exposes the metric definition but the runtime does not populate it, leaving only external benchmark latency.
  **Fix:** Instrument the authenticated request lifecycle and, if useful, major graph stages with bounded labels; test that observations are emitted without recording sensitive text.

- [ ] **#31 — The five-minute keep-alive workflow is not an end-to-end availability check.**
  Workflow failures are converted to messages, and successful health/Qdrant pings do not validate authentication, embedding, retrieval, inference, filtering, or persistence.
  **Fix:** Add a low-cost synthetic transaction or readiness probe with explicit alert/failure semantics and no real-user data. Do not describe the keep-alive job as uptime evidence.

- [ ] **#32 — The deployed Hugging Face revision is not cryptographically tied to the application commit.**
  The Space is maintained through a separate Git remote, so an application commit alone does not prove which service revision generated benchmark responses.
  **Fix:** Record the deployed Space revision/image digest, application commit, dependency lock, prompt/suite hashes, corpus hashes, resolved flags, model IDs, and evaluation dates in one archived reproducibility bundle and release tag.

- [ ] **#33 — The 300-case suite and judge lack independent clinical validation.**
  The prompts and expected themes are developer-authored, and the Gemini judge has no clinician calibration, human inter-rater analysis, or independent test-set adjudication.
  **Fix:** Report the present suite strictly as an engineering benchmark. For stronger medical or safety claims, obtain blinded expert ratings on a prespecified sample and compare automated judgments with those ratings.

- [ ] **#34 — The benchmark does not evaluate natural multi-turn dialogue or memory acquisition.**
  History is cleared between cases and memory curation is disabled for the benchmark account; seeded facts test use of existing memory only.
  **Fix:** Add a separate, versioned multi-turn and memory-lifecycle evaluation covering extraction, supersession, stale facts, deletion, and cross-user leakage. Keep it distinct from the running isolated-case campaign.

- [ ] **#35 — The complete Hailey 2.0 benchmark artifact is still pending.**
  Intermediate checkpoints cannot support final quality, safety, latency, or token-use results, and the obsolete three-prompt DeepEval scores do not evaluate the revised system.
  **Fix:** Complete all 300 unique cases under one compatible configuration, verify the schema-v4 artifact, archive it durably with workflow provenance, and derive all chatbot Results tables from that artifact.

- [ ] **#36 — The sequential benchmark provides no scalability or availability evidence.**
  It cannot estimate throughput, concurrent-user capacity, saturation, autoscaling, failover, regional latency, or service-level availability.
  **Fix:** Keep those claims out of the current article. If production-capacity claims become necessary, run a separate controlled load/soak and failure-recovery study without disturbing the frozen quality benchmark.

### Existing application/code backlog — renumbered after the Methods audit

- [ ] **#37 — `2048` has no pause / no resume affordance.**
  `lib/mini_games/2048/home2048.dart` — both Snake (`game_page.dart:181-210`, play/pause FAB) and Flappy (`menus/game_intro.dart` + `game_over.dart`) have an explicit pause path. 2048 only has a reset button (line 278-285). For a session-style game where users may put the phone down mid-board, this is inconsistent UX.
  **Fix:** Add a pause FAB that flips a `bool _isPaused`; `handleGesture` early-returns when paused.

- [ ] **#38 — `HealthBenefitsState` is hand-written; every other state model uses `@freezed`.**
  `lib/models/healthbenefits_state.dart:3-60` — manual `copyWith` (lines 30-40), manual `toAppwrite` / `fromAppwrite`. The codebase has nine `*.freezed.dart` files for the other state classes. The hand-written copyWith is error-prone — every new field needs a manual entry, and there's no compile-time guard that all fields are wired.
  **Fix:** Annotate with `@freezed`, regenerate via `dart run build_runner build --delete-conflicting-outputs`. Keep `hasAchieved`, `timeSinceQuit`, `calculateProgress`, `completionDateFor` as Freezed methods.

- [ ] **#39 — `ObstacleGenerator.generateObstacle` allocates `Random()` twice per spawn.**
  `lib/mini_games/flappy_bird/player/obstacle_generator.dart:70, 86` — line 70: `Random().nextDouble() * 100` and line 86: `Random().nextInt(...)` each instantiate a fresh `Random`. The 2048 code already adopted the single-static pattern (`grid.dart:6`). Flappy spawns a pair on every screen-crossing tick and re-seeds the generator each time.
  **Fix:** Add `final Random _rng = Random();` at class level and reuse it.

- [ ] **#40 — `tic_tac_toe::autoPlay` allocates `Random()` on every AI turn.**
  `lib/mini_games/tic_tac_toe/ttt_homepage.dart:109` — `empty[Random().nextInt(empty.length)]`. Called every 400 ms during single-player; same allocation anti-pattern as #39.
  **Fix:** Add `final Random _random = Random();` to `TicHomePageState` and reuse it.

- [ ] **#41 — `UserState.initial()` uses `.toUtc()` for `quitDate`; the fromAppwrite empty-doc fallback uses `.toLocal()`.**
  `lib/models/user_state.dart:60` vs `lib/models/user_state.dart:73` — the two "default-ish" initial states label the same moment with different timezone flags. Downstream code that compares quitDates papers over this, but it is a footgun for future code that doesn't.
  **Fix:** Align both factory paths to `.toUtc()` (already the Appwrite-side convention).

- [ ] **#42 — `splash_page.dart` particle painter mutates state inside `paint`; `shouldRepaint => true`. (verify)**
  `lib/pages/starting_pages/splash_page.dart:102-105, 326-327` — `ParticlePainter.paint` calls `p.update(progress)` (mutates particle state) and `shouldRepaint` is unconditionally `true`. The `progress` parameter is ignored — animation speed is time-step-independent. Painter is non-idempotent.
  **Fix:** Drive motion from elapsed seconds (`controller.lastElapsedDuration`); compute new state in `addListener` and read-only inside `paint`.

- [ ] **#43 — `friends_main.dart` remove-friend has no haptic / undoable snackbar.**
  `lib/pages/home_pages/friends_main.dart:422-456` — destructive (wipes message history per dialog body) with no undo and no haptic.
  **Fix:** `HapticFeedback.mediumImpact()` before the destructive call; offer an Undo action on the success snackbar.

- [ ] **#44 — `edit_challenge.dart` Type dropdown is decorative (`onChanged: null`).**
  `lib/pages/home_pages/edit_challenge.dart:358-390` — Physical/Financial dropdown is disabled because type isn't editable post-creation. Showing it as a greyed dropdown rather than a read-only label is misleading.
  **Fix:** Replace with a read-only `Text("Type: Physical")`.

- [ ] **#45 — `dm.dart` filter re-allocates the messages list on every `friendProvider.messages` change. (verify)**
  `lib/pages/home_pages/dm.dart:98-105` — `.select((s) => s.messages)` narrows to the whole messages list. Any inbound DM (even for other chats) triggers a full filter + `toList`.
  **Fix:** Expose `messagesWith(otherUserId)` as a `family` provider that computes the filtered list inside the notifier.

- [ ] **#46 — Avatar picker has three nested dialogs.** (`account.dart:70-150`)

- [ ] **#47 — Mini-game cards have no loading indication for the game itself.** (snake / 2048 / tic-tac-toe)

- [ ] **#48 — Settings page theme switch doesn't preview.**

- [ ] **#49 — `test/` directory is still empty.**

- [ ] **#50 — All four mini-games re-implement their own "game over" overlay.**
  `lib/mini_games/snake/game_over.dart`, `flappy_bird/menus/game_over.dart`, `tic_tac_toe/ttt_homepage.dart:127-199`, `2048/home2048.dart:243-272` — each duplicates the gradient + "Score / High Score / Play Again" scaffold with different colors.
  **Fix:** Extract `MiniGameOverDialog({score, highScore, accentColor, onRetry, onHome})` in `pages/utils/dialogs.dart`.

- [ ] **#51 — `GameState` enum uses `SCREAMING_SNAKE_CASE` with a lint-ignore.**
  `lib/mini_games/flappy_bird/flappy_dash_game.dart:17-18` — `enum GameState { GAME_STARTED, GAME_OVER, GAME_LAUNCH, GAME_PAUSE }`. Matches no other enum in the codebase.
  **Fix:** Rename to `gameStarted`, `gameOver`, `gameLaunch`, `gamePause`; drop the `ignore` directive.

- [ ] **#52 — Flappy mini-game uses `Get` (GetX) for state, conflicting with Riverpod elsewhere. (verify scope)**
  `lib/mini_games/flappy_bird/dash_game_controller.dart`, `dash.dart:12`, `obstacle_generator.dart:13`, `flappy_dash_game.dart:7, 25`, `menus/game_intro.dart:19`, `menus/game_over.dart:23`, `menus/game_score.dart:17`. `Get.put`/`Get.find` is a global singleton that survives navigation (re-entering the game reuses stale state).
  **Fix:** Migrate `DashGameController` to a Riverpod `StateNotifier`/`Notifier`; drop the `get` dependency.

- [ ] **#53 — `ObstacleGenerator.intervalBetweenNextObstacle` is named like a time but used as a speed.**
  `lib/mini_games/flappy_bird/player/obstacle_generator.dart:15, 36` — `obstacle.x -= intervalBetweenNextObstacle * dt;` — units are px/s, not an interval.
  **Fix:** Rename to `obstacleSpeed` (or `scrollSpeed`).

---

## Rag_backend errors

23. **Three dead imports in `test_agent.py`.**
    `AnswerRelevancyMetric`, `FaithfulnessMetric`, and `HallucinationMetric` are imported but their usages are commented out. They are resolved and loaded on every run for no benefit.
    **Fix:** Remove the three unused imports.

---

## Rag_backend file summaries

Files with no outstanding errors — brief notes on what each does and how.

**`config.py`** — Module-level singleton setup. Loads `.env`, instantiates the shared `HuggingFaceEmbeddings` model (`all-MiniLM-L6-v2`) and the `ChatGroq` LLM (`llama-3.3-70b-versatile`). Both are imported by other modules; constructing them once here avoids repeated model loading.

**`main.py`** — FastAPI entry point. Sets `ALLOW_CHROMA_TELEMETRY=FALSE` before any chromadb import, adds open-origin CORS middleware (intentional for development), and mounts `apiRoutes.router`.

**`memory.py`** — History persistence layer. `append_to_history` writes a single message to the `chat_history` ChromaDB collection with `user_id`, `role`, and ISO-UTC timestamp metadata. `load_user_history_as_list` is a thin pass-through to `retrieve_chat_history` for the API layer. `get_formatted_memory` formats history as `"User: …"` / `"Hailey: …"` lines for LLM prompts. `delete_user_history` purges all of a user's messages via a `where` filter.

**`retriever.py`** — Two retrieval functions. `retrieve_documents` performs dual similarity search — top-3 knowledge-base chunks plus the single most relevant prior user message — then prepends source-type tags (`[KNOWLEDGE BASE]` / `[USER PRIOR MESSAGE]`) so the context refiner can weight them appropriately. `retrieve_chat_history` fetches a user's full chronological message log using a server-side `where={"user_id": ...}` filter, sorted by ISO timestamp.

**`chains.py`** — Thin wrappers that bind prompt templates to the LLM and wire up output parsers. All chains are module-level stateless `Runnable` instances. `classify_all` is the only function with business logic: it calls the batched classifier chain, validates the returned dict, and returns safe defaults on any parsing failure so the graph never hard-crashes on a malformed LLM response.

**`web_search.py`** — DuckDuckGo fallback retriever. Wraps `DDGS.text()` in a try/except with a configurable timeout; on any failure logs a warning and returns `[]` so a search outage degrades gracefully rather than crashing the turn.

**`check_DB.py`** — Debug CLI utility. Fetches and pretty-prints every entry in the `knowledge_base` collection (metadata + 300-char snippet). Run directly; not imported by any production module.

**`health_benefit_ingest.py`** — One-time seeding script. Maps each `benefit_*` milestone ID to a list of authoritative URLs and calls `ingest_benefit_sources` for each. Guarded with `if __name__ == "__main__"`; importing the module has no side effects.

**`test_example.py`** — Minimal `deepeval` sanity check with a single hardcoded `LLMTestCase`. Useful for verifying the evaluation framework is installed and reachable. Guarded; no side effects on import.

---

## Already verified false positives

These showed up in prior sweeps but are actually fine — recording so they don't get re-flagged:

- `StateNotifier.mounted` IS exposed by the `state_notifier` package used here. `if (!mounted) return` guards inside notifiers are correct.
- `lib/pages/utils/dialogs.dart` and `lib/pages/utils/empty_state.dart` are already shared utilities — don't recreate them.
- `.flutter-plugins-dependencies` is already in `.gitignore`.
- "Several providers construct fresh `Databases`/HTTP objects per call site" was wrong: the only `Client()`/`Databases(...)` construction in `lib/` lives in `services/appwrite_providers.dart` (the canonical factory). `friends_provider.dart` receives `_db` through `ref.watch(databasesProvider)` at line 13; `notification_service.dart` has no Appwrite imports at all.
- "Delete all milestones has no confirmation" was wrong: both call sites in `account.dart` (lines 543, 599) only run downstream of `showRelapseConfirmDialog` and `showQuitDateChangeConfirmDialog` respectively. The destructive action is always behind a user-confirmed Yes/No prompt — it's just not literally titled "delete milestones".
- "`_lastLoadedAt` plumbing isn't reset on logout" was wrong: both `diaryProvider` and `forumPostProvider` watch `userProvider.select((u) => u.userId)`. A userId change tears down the entire notifier instance, taking `_lastLoadedAt` / `_hasMore` / `state` with it. (Note: this is *not* true for `friendProvider` and `progressProvider` — see #225 and #249.)
- "Several `debugPrint` calls log full state objects" was wrong: grep over `lib/providers/` shows zero dumps of state objects. Most prints are `'Error xyz: $e'` (single line). The only verbose call is `milestone_provider.dart:102` which adds a stack trace — diagnostic value, not noise.
- "`progress_provider` 1 Hz timer fires `state = state` redundantly" was wrong: `timeSinceQuit` advances by one second each tick, so the new state is genuinely different. The `cigsChanged` check is only a side-effect gate, not a state-set gate.
- "`diary.dart::_getColor` is unused" was wrong: it's referenced at `diary.dart:711, 721, 757, 764` to color the diary-entry cards from the stored hex.
- "`ChallengeNotifier.refresh` is a passthrough to `fetchChallenges`" was technically correct but the explicit method is the documented public entry point for pull-to-refresh; keep for callsite stability.
- "`progress_provider._isForeground` guard is redundant" was wrong: `_startTimer` keys off the field to refuse to start while backgrounded; the lifecycle hook is the only writer. Both reads are necessary.
- "Standardise on `State.mounted` over `context.mounted` in `account.dart`" was the wrong direction: modern Flutter's `use_build_context_synchronously` lint expects `context.mounted` when the `BuildContext` is used after the `await`. The file is now consistent on `context.mounted` throughout.
- "Per-page `_showErrorDialog` wrappers around `showAppErrorDialog` are dead re-exports" was wrong: the wrappers in `auth.dart` and `change_account_info.dart` are load-bearing for the `use_build_context_synchronously` lint. An instance-method call captures `this.context` synchronously even when invoked after an `await`; inlining `showAppErrorDialog(context, ...)` at every call site triggers the lint at all ~15 call sites. Keep the wrappers — `showAppErrorDialog` already handles the `context.mounted` check internally.
- "Splash screen is too long at 6.5s" was wrong: the duration is deliberate (brand-message cycle is a UX choice). Don't shorten it.
- "`_SparkleRingPainter` reuses one `Paint` object inside the loop" (`progress_provider.dart:368, 384`) is intentional — only the color mutates per iteration; the rest of the paint setup is constant. Re-allocating Paint per dot would be slower.
