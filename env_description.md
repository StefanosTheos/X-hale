# X-hale (smoking2.0) — Detailed Environment Report

## 1. High-level overview

**X-hale** is a multi-platform **Flutter** quit-smoking companion app paired with a Python **FastAPI + LangGraph + ChromaDB** RAG backend that powers the in-app conversational coach named **Hailey**. Authentication, user data, social features, and per-user persistence are handled by **Appwrite** (project `685d2b28003a614fa813`, EU endpoint). Push notifications and FCM tokens flow through **Firebase** (project `xhale-92476`). Daily affirmations and diary reminders use `flutter_local_notifications` (Europe/Athens TZ).

```
smoking2.0/
├── lib/                         # Flutter app (Dart)
│   ├── main.dart                # entrypoint → SplashScreen → AuthPage → HomePage
│   ├── firebase_options.dart    # FlutterFire-generated platform config
│   ├── constants/               # static data (achievements, health_benefits, affirmations)
│   ├── extensions/              # enums, Milestone & ProgressState extensions
│   ├── models/                  # Freezed state classes (+ generated *.freezed.dart)
│   ├── providers/               # Riverpod StateNotifiers (one per domain)
│   ├── pages/                   # UI screens grouped by area
│   └── mini_games/              # Flame-based games (snake, flappy_bird, 2048, tic-tac-toe)
├── rag_backend/                 # Python RAG service (FastAPI + LangGraph)
├── android/ ios/ macos/ linux/ windows/ web/   # Flutter platform shells
├── assets/                      # icons (131), images (8), audio, tiles
├── fonts/                       # CalSans-Regular, StarJedi, Comfortaa
├── chroma_db/                   # local Chroma vector store (sqlite + index)
├── firebase.exe / firebase.json # bundled Firebase CLI
├── pubspec.yaml                 # Flutter deps
├── starter-for-flutter/, test/  # scaffolding/tests
└── .env, .venv, .deepeval       # secrets + Python venv + eval cache
```

`pubspec.yaml` declares notable dependencies: `flutter_riverpod`, `freezed`, `appwrite`, `firebase_core/messaging`, `flame`/`flame_audio`/`flame_tiled`, `fl_chart`, `flutter_local_notifications`, `timezone`, `audioplayers`, `hive`, `mobx`, `provider`, `get` (carried in for Flappy Bird), `permission_handler`, `image_picker`, `shared_preferences`, `flutter_dotenv`, `http`, `intl`.

⚠️ **Secrets exposed in repo**: `.env` and `rag_backend/.env` contain a literal Groq API key, Google API key, Confident AI API key, and the ngrok base URL is hard-coded in `lib/models/chat_service.dart`. These should be rotated and removed from source control.

---

## 2. Flutter application

### 2.1 Entrypoint & navigation flow

`lib/main.dart` (37 lines)
- Initializes Firebase (`DefaultFirebaseOptions.currentPlatform`) and `NotificationService`.
- Wraps the app in a Riverpod `ProviderScope`.
- Builds an Appwrite `Client`/`Account` (`fra.cloud.appwrite.io/v1`, project `685d2b28003a614fa813`) and hands the `Account` to `SplashScreen`.

Navigation chain:
```
main → SplashScreen → AuthPage
       (6.5 s animated logo,
        particles, message cycle)
                                  → InitialSmokingPreferencesPage (new users / Google first-login)
                                  → HomePage                       (existing users)
```

### 2.2 Starting pages (`lib/pages/starting_pages/`)
- **`splash_page.dart`** (331 L) – Custom particle animation + glowing logo + 3-message cycle; pre-caches `assets/icons/X-hale_logo.png`, then pushes `AuthPage` after 6.5 s.
- **`auth.dart`** (575 L) – Email/password + Google OAuth via Appwrite (`createOAuth2Session`, `createEmailPasswordSession`). On login it (a) registers an FCM push target `push_<userId>` against Appwrite provider `6899ba48001bda3c6a7c`, (b) schedules a daily affirmation, (c) schedules a 21:00 diary reminder if there is no entry yet today. Validates email regex + strong password (≥8, upper/lower/digit).
- **`initial_smoking_preferences.dart`** (476 L) – Collects `cigsPerDay`, `cigsPerPack`, `pricePerPack`, `yearsSmoking`, `minutesPerCig`, currency, quit date and writes them into the Appwrite user document via `userProvider.initializeUser`.

### 2.3 Home + tab pages (`lib/pages/home_pages/`)

`home.dart` (1580 L) is the dashboard. AppBar exposes diary, motivations, settings; bottom `BottomNavigationBar` has 5 entries: Dashboard, Achievements, **Chatbot**, Biometrics, Explore. It renders a vertical stack of `_framedSection` cards:
- **Smoke-Free Timer** (days/hours/min/sec) — driven by `progressProvider` ticking every 1 s.
- **Milestones** — selectable Day/Week/Month/Year; next-milestone progress bar, ETA.
- **Progress grid** — cigarettes avoided, money saved, life gained, time saved.
- **Daily Affirmation** — index = `dayOfYear % dailyAffirmations.length` over the 156-item list in `constants/affirmations.dart`.
- **Health Benefits preview** — first un-achieved benefit + progress.
- **Latest Achievement** — most recent from `achievementProvider`, with trophy color by `level`.
- **Ongoing Challenges** — financial = money saved progress bar; physical = last-entry date.
- **Forum** — `latestForumPostProvider` shows most recent post.
- **Social** — entry into `FriendsPage`.

Other home pages:

| File | Lines | Purpose |
|---|---|---|
| `chatbot_page.dart` | 423 | The Hailey chat UI (see §3) |
| `biometrics.dart` | 1860 | `fl_chart` weekly graphs for heart rate, BP, SpO₂, sleep; gated behind a fake Samsung Health verification dialog |
| `challenges_main.dart` / `create_challenge.dart` / `edit_challenge.dart` | 526 / 406 / 662 | Physical & Financial challenges CRUD over Appwrite collection `685d3233002933bc80d6` |
| `achievement_main.dart` | 444 | Tabbed achievement viewer; categories from `constants/achievements.dart` |
| `diary.dart` | 735 | Mood-tagged diary entries; tag chips, mood color, daily reminder integration |
| `forum.dart` | 505 | Global forum feed; opens user profile sheet → friend request / DM |
| `friends_main.dart` | 1043 | Friends list, incoming/outgoing requests, search by username, DM list |
| `dm.dart` | 304 | 1-on-1 direct message thread |
| `milestones.dart` | 466 | Full list grouped Day/Week/Month/Year with completion toggle |
| `motivations.dart` | 563 | Pinned user-written motivation cards |
| `health_benefits.dart` | 429 | Visual list of all health-benefit milestones with progress bars; tappable for a follow-up Hailey question via `ChatbotPage(initialPrompt: …)` |
| `explore_main.dart` | 266 | Grid of category cards → explore pages |

### 2.4 Explore pages (`lib/pages/explore_pages/`)

Static informational pages (each ~150 L unless noted):
- `withdrawal_tips.dart`, `mental_prep.dart`, `break_habits.dart`, `non_smoker_mindset.dart`, `nutritional_tips.dart`, `sleep_matters.dart`, `exercise_is_key.dart`
- **Interactive tools**:
  - `breathing.dart` (421 L) – Box / 4-7-8 / Nadi Shodhana animator backed by `models/breathing_state.dart` + audio cues from `assets/audio/*_inhale.mp3` etc.
  - `mini_games.dart` (174 L) – Cards launching the four games.
  - `distractions_main.dart` (141 L) – Dropdown switch between:
    - `distractions_sounds.dart` (344) – nature ambient player (ocean, forest, crickets, fireplace, brown noise).
    - `distractions_wheel.dart` (339) – spin-a-wheel; increments `totalWheelSpins`.
    - `distractions_draw.dart` (350) – freehand canvas painter.
    - `distractions_stretching.dart` (434) – timed stretches driven by `models/stretches_state.dart`.

### 2.5 Account + settings
- `account/account.dart` (1112 L) – avatar picker (`image_picker`), edit profile/smoking prefs, delete all milestones, logout (`Account.deleteSession`).
- `account/change_account_info.dart` (654) – name/email/phone/quitDate editor.
- `account/change_smoking_preferences.dart` (537) – mutates `userProvider` fields, triggers re-sync to Appwrite + progress recalculation.
- `settings/settings.dart` (596) – theme switch (light/dark), notifications toggle (`permission_handler`), language placeholder, About/FAQ/More-Help entries.

### 2.6 Utilities (`lib/pages/utils/`)
- **`themes.dart`** – `AppThemes` static palette: dark/light gradients, dialog gradients, card colors, theme-aware helpers (`elevatedButtonBackground`, `inputHintStyle`, etc.). All pages read `userProvider.theme` and select pairs from this file.
- **`notification_service.dart`** – Singleton wrapping `FlutterLocalNotificationsPlugin` + `FirebaseMessaging`. Foreground/background handlers, FCM permission, `scheduleDailyAffirmation` (12:00 daily, id 1001), `scheduleDiaryReminder` (21:00, id 1002, skipped if entry exists). TZ is hard-coded `Europe/Athens`.
- **`animated_progress_bar.dart`** – Custom-painted bar with color shifting from red→green based on value.
- **`loading_screen.dart`** – Themed `CircularProgressIndicator`.

### 2.7 Models (`lib/models/`)

All domain state is **Freezed** + JSON-serializable. The `*.freezed.dart` files are generated; do not edit. Each model commonly defines `initial()` and `fromAppwriteDocument(doc)` factories plus a `toAppwritePartial()` for sync.

| Model | Role |
|---|---|
| `user_state.dart` | The big one (118 L) — userId, smoking prefs (cigs/day, /pack, price, minutes/cig, years, quit date), avatarPath, theme, language, FCM-related fields, plus counters (numFriends, numForumPosts, diaryCount, snakeHighScore, flappyHighScore, high2048Score, numHealthBenefit, numMilestonesCompleted, achievementPoints, etc.) used by the achievement evaluator. |
| `userprofile_state.dart` | Lightweight view of another user (id, name, avatar, quitDate, achievementsCount). |
| `progress_state.dart` | `calculateFromUser(...)`: derives time-since-quit, cigsAvoided = `totalMinutes / (1440/cigsPerDay)`, moneySaved = `cigsAvoided * pricePerPack/cigsPerPack`, lifeGained = `cigsAvoided * 20 min`, timeSaved = `cigsAvoided * minutesPerCig`. |
| `milestone_state.dart` | Builds the milestone list (12 day-thresholds × 15 week × 15 month × 12 year). Marks each completed/eligible. |
| `achievement_state.dart` | A single achievement record. |
| `challenge_state.dart` | `Challenge` (physical / financial) + entries (notes). `ChallengeState.active/completed/forfeited` views. |
| `diary_state.dart` | Diary entries with mood + tags + color. |
| `forum_state.dart` | `ForumPost` + list state. |
| `friends_state.dart` | Friendships, incoming/outgoing requests, DMs. |
| `healthbenefits_state.dart` | Computes elapsed/total against each `HealthBenefits.allBenefits[*].time_interval` (in minutes). |
| `motivation_state.dart` | Pinned-able motivation strings with icon + color. |
| `stretches_state.dart` | 5 stretch exercises (neck, shoulder, hamstring, quad, chest opener) with duration + image. |
| `breathing_state.dart` | 3 breathing techniques. |
| **`chat_message.dart`** | `{content, isUser, timestamp}` — the chat DTO used by `ChatbotPage`. |
| **`chat_service.dart`** | HTTP client calling the RAG backend; see §3. |

### 2.8 Providers (`lib/providers/`)

All are Riverpod `StateNotifierProvider`s; each owns its own `Appwrite Databases` client.

| Provider | Collection ID | Key behavior |
|---|---|---|
| `user_provider.dart` | `685d2f88001fc9471631` | CRUD on user doc + counters (`syncNumFriends`, `syncAchievementsCount`, `updateDiaryCount`, etc.), Google-sign-in helpers, push target plumbing. |
| `progress_provider.dart` | (same user collection, also writes `totalCigsAvoided` etc.) | Ticks every 1 s via `Timer.periodic` → recomputes `ProgressState` → syncs to Appwrite at most every 5 min (`_maybeSyncWithAppwrite`). Also auto-completes financial challenges when `moneySaved >= goalBudget` and triggers the celebratory dialog. |
| `milestone_provider.dart` | `685d3181002fc385b957` | Adds/removes milestone docs (`color: '#4CAF50'` for completed) and refreshes `numMilestonesCompleted`. |
| `achievement_provider.dart` | `685d32f80037407606c4` | `evaluateAchievements(user)` iterates `allAchievements` (constants/achievements.dart) and creates or deletes Appwrite docs based on category-specific user counters. Updates `achievementPoints` total. |
| `challenge_provider.dart` | `685d3233002933bc80d6` + entries `685d32bb0023444507f9` | Physical (entry log) + Financial (goalBudget) variants. `updateFinancialProgressAndStatus` derives collected = `days_since_creation * dailyCigaretteCost`. |
| `diary_provider.dart` | `685d31ff000ee7a914ff` | Entry add/delete, mood→color mapping, `hasEntryForToday()` used by the diary reminder. |
| `forum_provider.dart` | `685d31d9003c29f13421` | Global posts; exposes `latestForumPostProvider` (FutureProvider) for the dashboard. |
| `friends_provider.dart` | friendships `6880cd730012d3aac2cc`, requests `6880ce0d000a1ad99b58`, DMs `6880ce5800193d799b9f` | Search by username, send request, accept/decline, friendship + DM cascade delete. |
| `healthbenefits_provider.dart` | `685d31af00311c899268` | Compares elapsed time to each benefit threshold; persists newly-achieved IDs and updates `numHealthBenefit`. |
| `motivation_provider.dart` | `685d314700303649367a` | Motivation cards CRUD + pin toggle. |
| `user_message_provider.dart` | `686d38950033f3fcd785` | Small generic "send a message" repository — appears auxiliary. |

### 2.9 Constants
- **`constants/achievements.dart`** – `allAchievements: List<Achievement>` with **~108** entries grouped by category (Milestones, Diary, Physical, Financial, Health, Social, Community, Engagement, Game1=Snake, Game2=Flappy, Game3=2048), 3 tiers each (bronze 100p / silver 200p / gold 300p).
- **`constants/health_benefits.dart`** – 14 benefits (20min → 20 years), with `time_interval` in minutes and `severity` low/medium/high, each pointing to an icon asset.
- **`constants/affirmations.dart`** – 156 daily affirmations consumed by `home.dart` and `notification_service.dart`.

### 2.10 Extensions
- `extensions/enums.dart` – `AppTheme {light, dark}` and `ChatRole {user, ai}` with string converters.
- `extensions/milestone_threshold.dart` – `Milestone.dayThreshold(startDate)`.
- `extensions/progress_state.dart` – Duplicate of `toAppwritePartial`; same map appears in `models/progress_state.dart`. Mild dead-code risk.

---

## 3. AI chatbot — end-to-end stack

### 3.1 Flutter side

**`lib/models/chat_message.dart`** — Plain DTO `{content, isUser, timestamp}` with `toJson` / `fromJson`.

**`lib/models/chat_service.dart`** — Static HTTP wrapper with one configuration constant:
```dart
static const String baseUrl = 'https://a1dc-31-217-173-116.ngrok-free.app';
```
Four endpoints:

| Call | HTTP | Endpoint | Body / Effect |
|---|---|---|---|
| `sendMessage` | POST | `/chat/` | `{user_id, input}` → `{response, history}` |
| `loadMessages` | GET | `/history/{user_id}` | Returns `{history: [{content, role, timestamp}]}` |
| `clearHistory` | DELETE | `/history/{user_id}` | Deletes all chat history |
| `saveMessage` | POST | `/save/` | `{user_id, content, role, timestamp}` |

**`lib/pages/home_pages/chatbot_page.dart`** (423 L) — `ConsumerStatefulWidget` (`ChatbotPage`):
- Receives a `userId` and an optional `initialPrompt` (used by `health_benefits.dart` and `biometrics.dart` to pre-fill a contextual question).
- On `initState`: loads history; if empty, injects a welcome message (`"👋 Hello! I'm Hailey — here to support you on your quit smoking journey..."`) and `saveMessage`s it.
- `_sendMessage`: optimistic-append user bubble, sets `_isLoading`, calls `ChatService.sendMessage`, then appends bot bubble.
- `_clearHistory`: confirm-dialog → `ChatService.clearHistory`.
- Themed bubbles (left = bot, right = user), gradient background driven by `userProvider.theme`.
- Auto-scrolls on every state mutation; error fallback message is bilingual ("❌ Σφάλμα: …").

The chatbot is also reachable from the bottom-nav middle button on `HomePage`.

### 3.2 Python RAG backend (`rag_backend/`)

**Stack**: FastAPI · LangChain · LangGraph · `ChatGroq` (Llama-3.3-70B-versatile) · HuggingFace embeddings (`all-MiniLM-L6-v2`) · ChromaDB (local persistent dir `./chroma_db`) · DuckDuckGo search · DeepEval for evaluation. Python 3.11.9 (`runtime.txt`).

#### File-by-file

| File | Lines | Role |
|---|---|---|
| `main.py` | 8 | FastAPI app, `app.include_router(router)`. Sets `ALLOW_CHROMA_TELEMETRY=FALSE`. |
| `apiRoutes.py` | 57 | The 4 endpoints. `/chat/` appends user message → builds last-10 formatted history → invokes `rag_agent_executor` → appends AI message → returns response + history. |
| `config.py` | 22 | Loads env, instantiates `llm = ChatGroq(model="llama-3.3-70b-versatile", temperature=0.7)` and `HuggingFaceEmbeddings("sentence-transformers/all-MiniLM-L6-v2")`. |
| `chromaClient.py` | 22 | `get_chroma_collection(name)` → returns a `langchain_chroma.Chroma` instance bound to `CHROMA_DB_PATH`. Two collections used: `knowledge_base` and `chat_history`. |
| `memory.py` | 70 | Persists chat turns into the `chat_history` Chroma collection with metadata `{user_id, timestamp, role}`. Exposes `append_to_history`, `load_user_history` (similarity), `load_user_history_as_list` (chronological, capped at k=20), `delete_user_history`, `get_formatted_memory` (formatted "User: …\nHailey: …" string for prompts), `load_chat_history_for_prompt` (HumanMessage/AIMessage). |
| `retriever.py` | 39 | `retrieve_documents(user_id, query, k=3)` does parallel similarity search over both `knowledge_base` (k=3) and `chat_history` filtered to `user_id` (k=1), and returns merged docs. `retrieve_chat_history(user_id, limit=10)` is the chronological history fetcher used by `memory.py`. |
| `web_search.py` | 13 | `web_search(query)` uses `duckduckgo_search.DDGS` and wraps each hit as a `Document`. |
| `prompt_templates.py` | 267 | **All Hailey prompts**: SYSTEM_PROMPT, RAG_PROMPT, FALLBACK_PROMPT, INTENT_CLASSIFICATION_PROMPT (`use_rag` vs `use_fallback`), EMOTION_DETECTION_PROMPT (12 labels), TOPIC_RELEVANCE_PROMPT (`relevant`/`irrelevant`), IRRELEVANT_TOPIC_PROMPT (gentle redirect), MOTIVATION_PROMPT, CLARIFICATION_PROMPT, KNOWLEDGE_SOURCE_ROUTER_PROMPT (`internal` vs `web`), CONTEXT_REFINER_PROMPT (dedup + bullet rewrite), STRUCTURED_RAG_PROMPT (4-section template: opener / explanation / bullets / encouragement). |
| `chains.py` | 109 | Builds 11 LCEL chains (`PROMPT | llm | parser`). High-level wrappers: `needs_clarification`, `classify_intent`, `detect_emotion`, `check_topic_relevance`, `generate_irrelevant_reply`, `generate_motivation`, `run_rag_chain`, `run_structured_rag_chain`, `refine_context_chain`, `decide_knowledge_source_chain`, `run_fallback_chain`. `format_docs` strips PDF artifacts and chat-like docs, enforces 1000-token cap. |
| `graph_builder.py` | 218 | **The LangGraph orchestrator** — see §3.3. Exports `rag_agent_executor`. |
| `ingest.py` | 117 | CLI: `--file`, `--url`, `--folder`. Extracts text from PDFs via `fitz`/PyMuPDF, HTML via BeautifulSoup (strips script/style), or `.txt`. Inserts cleaned text into the `knowledge_base` Chroma collection. Skips snippets under 50 chars. |
| `health_benefit_ingest.py` | 60 | Calls `ingest.ingest_benefit_sources(benefit_id, urls)` for 14 benefit IDs against CDC / NHS / Mayo / Cancer.org / WHO / Hopkins / Harvard pages. Each chunk tagged with `metadata.benefit_id`. |
| `check_DB.py` | 22 | Dumps every doc + metadata in the `knowledge_base` collection (for debugging). |
| `test_agent.py` | 78 | Calls the live API for a test prompt and runs DeepEval `ContextualRelevancyMetric` on it. |
| `test_example.py` | 13 | Minimal DeepEval `AnswerRelevancyMetric` smoke test. |
| `temp_ingest.pdf` | – | 1 MB PDF cached by `ingest_url` when the URL responds with `application/pdf`. |
| `resources/text/` | 9 files | Pre-ingested knowledge corpus: CDC, NHS, APA, "what happens when you quit smoking", etc. |
| `resources/pdfs/` | 4 files | Academic PDFs (sleep & cessation, non-smoker identity, etc.). |
| `chroma_db/` | – | Persistent Chroma sqlite + Parquet indices. |

#### 3.3 The LangGraph flow (`graph_builder.py`)

`GraphState` TypedDict carries `user_id`, `input`, `intent_classification`, `emotion`, `topic_relevance`, `needs_clarification`, `response`, `conversation_history`, `raw_docs`, `refined_context`, `knowledge_source`, `retrieved_docs`.

Node graph:

```
                  ┌───────────────────────┐
START ──▶ clarification_check_node ────┐ │
              │needs?                   ▼ │
              │      ┌─── output_node ◀───┘  (clarification reply emitted, done)
              ▼
        topic_relevance_check_node ─── irrelevant ──▶ output_node
              │ relevant
              ▼
        intent_classification_node      (use_rag | use_fallback)
              │
              ▼
       conversation_history_node        (formatted last-10 turns)
              │
              ▼
        emotion_detection_node
              │
   ┌──────────┴───────────────┐
   │ use_rag                  │ use_fallback
   ▼                          ▼
knowledge_source_router_node  fallback_response_node
   │ (internal|web)                       │
   ▼                                       │
retrieve_node ──► context_refiner_node ──► structured_response_node
                                                  │
                                                  ▼
                                          motivation_node
                                                  │
                                                  ▼
                                            output_node ──▶ END
```

Key behaviors:
- `clarification_check_node` short-circuits if the user message is vague (LLM rephrases as "could you clarify…").
- `topic_relevance_check_node` short-circuits with a gentle redirect when the message is off-topic.
- `knowledge_source_router_node` decides between local vector store and live web search.
- `retrieve_node`: if `knowledge_source == "web"` → `web_search`, else → `retrieve_documents` (KB + per-user chat history).
- `context_refiner_node` dedupes / bullet-izes the raw docs against the question.
- `structured_response_node` runs the 4-section structured RAG prompt with the user's detected emotion as an input.
- `motivation_node` appends a motivational paragraph **only** when the detected emotion is in `{sadness, fear, anxiety, shame, guilt, frustration, loneliness}`.
- `output_node` is the terminal aggregator.

Memory model: per-user chat history is stored as Chroma vectors in the `chat_history` collection. Retrieval is both **vector-similarity** (for context blending) and **chronological** (for the visible transcript and the formatted prompt history).

---

## 4. Mini-games (`lib/mini_games/`)

| Game | Stack | Key files | High-score sync |
|---|---|---|---|
| **Snake** | Pure Flutter (`AnimationController`, timer-based loop on a 500-cell grid) | `snake/game_page.dart` (379), `snake/game_over.dart` | `userProvider.updateSnakeHighScore(score*100)` |
| **Flappy Bird** | Flame engine (`FlappyDash extends FlameGame`) with parallax background, obstacle generator, collision detection, GetX `DashGameController` (`gameState: GAME_LAUNCH/STARTED/OVER/PAUSE`, `userScore`). Tap or space to jump. | `flappy_bird/flappy_dash_game.dart`, `dash_game_controller.dart`, `flappy_bird2_game_page.dart`, `player/{dash,base_platform,obstacle_generator}.dart`, `menus/{game_intro,game_over,game_score}.dart`, `world/parallex_background.dart`, `utils/{audio_controller,user_prefereces,consts,utils}.dart`, `widget/rounded_button.dart` | `userProvider.updateFlappyHighScore` |
| **2048** | Pure Flutter swipe-gesture grid; logic in `game.dart` (slide/combine/win/over), UI in `home2048.dart` (332), tile widget `tile.dart`, palette `mycolor.dart`. Uses `shared_preferences` for local high score. | `2048/{game,grid,home2048,mycolor,point,tile}.dart` | `userProvider.update2048HighScore` |
| **Tic-Tac-Toe** | Pure Flutter; `flame_audio` for tap/win/draw SFX. Single-player vs random AI or local 2-player. | `tic-tac-toe/{ttt_homepage,game_button,custom_dailog}.dart` | None (just session scoreboard) |

The `tiles/` asset directory (`Level1.tmx`, `Level2.tmx`, `Spritesheet.tsx`) plus `flame_tiled: 3.0.4` suggest a Tiled-based level format was prototyped (likely for Flappy Bird platforms) but is currently unused or partially wired through `flame_tiled`.

---

## 5. External services & integration points

### 5.1 Appwrite

Endpoint: `https://fra.cloud.appwrite.io/v1` · Project: `685d2b28003a614fa813` · Database: `685d2f83002cb88b5ddf`

| Collection ID | Domain |
|---|---|
| `685d2f88001fc9471631` | **users** (canonical profile + all counters) |
| `685d3181002fc385b957` | **milestones** completed |
| `685d31af00311c899268` | **health_benefits** progress (`achievedBenefits[]`) |
| `685d31ff000ee7a914ff` | **diary** entries |
| `685d31d9003c29f13421` | **forum** posts |
| `685d3233002933bc80d6` | **challenges** |
| `685d32bb0023444507f9` | **challenge_entries** |
| `685d32f80037407606c4` | **achievements** unlocked |
| `685d314700303649367a` | **motivations** |
| `6880cd730012d3aac2cc` | **friendships** |
| `6880ce0d000a1ad99b58` | **friend_requests** |
| `6880ce5800193d799b9f` | **direct_messages** |
| `686d38950033f3fcd785` | misc messages (used by `user_message_provider`) |
| `6846c4ff0016d774f145` | referenced for financial-challenge progress update (legacy?) |
| `6899ba48001bda3c6a7c` | push provider ID for FCM target registration |

### 5.2 Firebase
- Project `xhale-92476`, separate API keys per platform (`firebase_options.dart`).
- `firebase_messaging` for push, `firebase_core` for init.
- `firebase.exe` (≈220 MB) bundled at repo root — the Firebase CLI itself, which is unusual to ship in-tree and should probably be removed from VCS.

### 5.3 RAG backend reachable only via ngrok
The Flutter app hits `https://a1dc-31-217-173-116.ngrok-free.app` directly — fragile (ngrok URLs change on restart). For prod this should be a stable HTTPS endpoint with auth.

---

## 6. Notable cross-file dependencies

```
main.dart
└── NotificationService (timezone, FCM, local notifications, diary reminder uses diaryProvider)
└── SplashScreen ──▶ AuthPage
                     └── userProvider (login/register, Appwrite Account)
                     └── NotificationService.scheduleDailyAffirmation / scheduleDiaryReminder
                     └── InitialSmokingPreferencesPage ──▶ userProvider.initializeUser ──▶ HomePage
                                                                                          └── Every provider, every page

userProvider ◀── achievementProvider (uses counters as goal source-of-truth)
            ◀── healthBenefitsProvider (reads quitDate, syncs numHealthBenefit)
            ◀── milestoneProvider (reads quitDate, syncs numMilestonesCompleted)
            ◀── challengeProvider (writes physicalCount, financialCount)
            ◀── progressProvider (every 1 s reads cigsPerDay/quitDate etc.)
            ◀── diaryProvider, forumProvider, friendsProvider, motivationProvider
            ◀── HomePage and every other page (theme, currency, name, avatar)

ChatbotPage ──▶ chat_service.dart ──▶ ngrok URL
                                       └── FastAPI router (apiRoutes.py)
                                            ├── memory.py (Chroma chat_history)
                                            └── graph_builder.rag_agent_executor
                                                 ├── chains.py (11 LCEL chains)
                                                 │    └── config.llm (ChatGroq Llama-3.3-70B)
                                                 ├── retriever.py
                                                 │    └── chromaClient.get_chroma_collection(knowledge_base|chat_history)
                                                 ├── web_search.py (DDGS)
                                                 └── prompt_templates.py
```

The knowledge base is populated by running:
```
python ingest.py --file resources/pdfs/...
python ingest.py --url <smoking-cessation-url>
python ingest.py --folder resources/text
python health_benefit_ingest.py
```

---

## 7. Observations / risks

1. **Secrets in repo** — Groq, Google, Confident AI keys; rotate immediately.
2. **Hard-coded ngrok endpoint** in `chat_service.dart` will break on every backend restart.
3. **`firebase.exe` (220 MB)** committed — should be a developer dependency, not a tracked artifact.
4. **Duplicate `toAppwritePartial`** in both `models/progress_state.dart` and `extensions/progress_state.dart`.
5. **TZ hard-coded to `Europe/Athens`** in `NotificationService`; users in other zones will get drifted reminders.
6. `iosBundleId: 'com.example.smoking'` in `firebase_options.dart` is still the default scaffolding bundle.
7. Error strings in `chatbot_page.dart` and `notification_service.dart` are mixed Greek/English ("Σφάλμα").
8. `check_DB.py` and `test_*.py` reference a local `http://localhost:8080`, while the app uses the ngrok URL — the test harness assumes a side-by-side local FastAPI dev server.
9. The DeepEval directory `.deepeval/` is committed at both the root and in `rag_backend/`.
10. The LangGraph flow runs the LLM at least 4–6 times per user turn (clarification check → topic check → intent → emotion → router → refine → structured → optional motivation), which is heavy; consider batching the upstream classifications into a single structured-output call.
