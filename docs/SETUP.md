# X-hale development setup

Run commands from the repository root unless a step changes directory. The active backend is `rag_backend2.0/`; the legacy `rag_backend/` is not required.

## Prerequisites and service configuration

- Flutter with Dart satisfying the `pubspec.yaml` constraint `^3.7.2`; Android SDK/emulator or a supported physical device. iOS builds require macOS/Xcode.
- Python 3.11+ and a virtual environment.
- Appwrite authentication, database/tables and storage configured for your own development project.
- Groq access to the configured 20B/120B models.
- Qdrant, either your own cloud instance or a local instance, with compatible 384-dimensional collections.
- Cloudflare Workers AI embedding credentials. A same-model local fallback is available for provider failure, but startup validation still requires the Cloudflare settings. The fallback needs model files and sufficient local resources; its first use may download weights.
- Firebase configuration for your own application if using the current Flutter startup/push integration. Startup calls `Firebase.initializeApp`; disabling push alone is not a complete Firebase-free setup.

The repository does **not** currently export a complete Appwrite application schema or one-command bootstrap. A fresh deployment requires manual schema/permissions work. It cannot be reproduced merely by copying the owner's project IDs. This gap is tracked in [the roadmap](ROADMAP.md).

## 1. Configure Appwrite

Create a development project and register your mobile platform identifiers. Enable the authentication method you will use. Use a database compatible with the Python `TablesDB` API and the Flutter `Databases` API employed in this source.

Set the endpoint, project, database, bucket and collection IDs in [`lib/services/appwrite_config.dart`](../lib/services/appwrite_config.dart), and set matching IDs in the backend `.env`. These IDs are public client configuration, not substitutes for access permissions.

The mobile app uses tables/collections for users, milestones, health benefits, diary, forum, challenges, challenge entries, achievements, motivations, friendships, friend requests, direct messages and miscellaneous messages, plus an avatar storage bucket. Use the field serializers in [`lib/models/`](../lib/models/) and accesses in [`lib/providers/`](../lib/providers/) when defining the schema. Client access must be scoped to the intended owner, conversation participants or explicitly public community content. The friend-name search also needs a full-text index on `name`.

Hailey additionally requires these two tables/collections. Column names are case-sensitive:

| `chatbot_messages` column | Type / requirement |
| --- | --- |
| `userId` | Required string; indexed |
| `role` | Required string: `user` or `assistant` |
| `content` | Required string, capacity 8000 |
| `timestamp` | Required datetime; indexed |
| `turn_id` | Required string |
| `citations` | Optional string, capacity 4000; JSON-encoded array |

Add an index supporting `userId` and descending `timestamp`. History/export also order by timestamp; verify the queries against your Appwrite schema.

| `chatbot_user_facts` column | Type / requirement |
| --- | --- |
| `userId` | Required string; indexed |
| `fact_type`, `fact_key` | Required strings |
| `fact_value` | Required string, capacity 2000 |
| `confidence` | Required float, range 0–1 |
| `source_turn_ids` | Optional string, capacity 1000; JSON-encoded array |
| `first_observed`, `last_confirmed` | Optional datetimes |
| `superseded_by` | Optional string; replacing fact's ID |

Add an index supporting `userId` and `fact_type`; verify queries filtering null `superseded_by` as well. The stores' module docstrings are the field reference: [`conversation_store.py`](../rag_backend2.0/app/memory/conversation_store.py) and [`user_facts_store.py`](../rag_backend2.0/app/memory/user_facts_store.py).

Create a backend-only Appwrite API key with the operations actually required. Account deletion additionally needs row/file deletion and user deletion capabilities; inspect [`account.py`](../rag_backend2.0/app/routers/account.py) and the account-deletion service before enabling it. Do not embed this server key in Dart, client configuration or screenshots. Review client permissions separately: server-key access can bypass client-level protections.

## 2. Install and start Hailey

```bash
cd rag_backend2.0
python -m venv .venv
```

Activate the environment:

```bash
# POSIX
source .venv/bin/activate
```

```powershell
# PowerShell
.\.venv\Scripts\Activate.ps1
```

Then:

```bash
python -m pip install -r requirements.txt
python -m pip install -e ".[dev]"
cp .env.example .env
```

Use `Copy-Item .env.example .env` in PowerShell if preferred. Copy only when `.env` does not already exist. Fill it with your own values:

| Settings | Purpose |
| --- | --- |
| `GROQ_API_KEY`, `GROQ_TRIAGE_MODEL`, `GROQ_SYNTHESIS_MODEL` | Active model provider; defaults are `openai/gpt-oss-20b` / `openai/gpt-oss-120b` |
| `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, `APPWRITE_API_KEY`, `APPWRITE_DATABASE_ID` | Backend connection and server credentials |
| `APPWRITE_*_COLLECTION_ID`, `APPWRITE_USER_AVATARS_BUCKET_ID` | Your actual application and chatbot schema IDs |
| `QDRANT_URL`, optional `QDRANT_API_KEY` | Knowledge store; credentials depend on deployment |
| `CF_ACCOUNT_ID`, `CF_WORKERS_AI_TOKEN` | Cloudflare embedding path |
| `ENABLE_LOCAL_EMBEDDING_FALLBACK` | Same-model local fallback, enabled by repository default |
| `ENABLE_KNOWLEDGE_GRAPH`, `ENABLE_RERANKER`, `ENABLE_WEB_SEARCH_FALLBACK` | Optional retrieval paths; leave `false` for the documented baseline |
| `BENCHMARK_TEST_USER_ID` | Optional dedicated test user; do not set to an ordinary user. Enables benchmark telemetry/context overrides and skips post-response memory curation for that identity. |

The retained Gemini settings do not switch the active Groq factories. Keep real credentials in ignored environment files or deployment secret stores.

Start the API from `rag_backend2.0/` so `.env` resolves correctly:

```bash
python -m uvicorn app.main:app --reload --port 7860
```

Check `http://localhost:7860/live`, `http://localhost:7860/ready` and `http://localhost:7860/docs`. Missing required configuration can prevent startup. A running process can remain unready when external dependencies fail; `/ready` can return HTTP 503.

## 3. Populate Qdrant

An empty Qdrant service is not a populated knowledge base. From `rag_backend2.0/`, with `.env` configured:

```bash
python -m pip install -e ".[ingestion]"
python -m ingestion.ingest_kb --file /path/to/permitted-source.pdf --source-type government --source-id my_reviewed_source
```

Replace the example path with content you are authorized to use. Health-benefit re-ingestion is available via `python -m ingestion.reingest_health_benefits`; it fetches external sources and writes the configured collection. Use a development/staging collection and review the target before running it. See [ingestion documentation](../rag_backend2.0/ingestion/README.md) for corpus governance, source terms and inventory validation.

Do not treat the source manifest, legacy PDFs or a successful ingestion command as proof that your deployed corpus matches a published evaluation snapshot.

## 4. Configure and run Flutter

Return to the repository root. Configure your Appwrite IDs in the central config and your Firebase project/platform registrations. [`firebase_options.dart`](../lib/firebase_options.dart) currently identifies the author's project; regenerate it for your project using the official [FlutterFire setup](https://firebase.google.com/docs/flutter/setup). Native service configuration files are intentionally ignored. Update platform identifiers consistently.

```bash
flutter pub get
flutter run --dart-define=HAILEY_API_URL=http://10.0.2.2:7860
```

The URL above is for an Android emulator. For a USB-connected Android phone:

```bash
adb devices
adb reverse tcp:7860 tcp:7860
flutter run --dart-define=HAILEY_API_URL=http://localhost:7860
```

For LAN devices, use the development computer's reachable address, start uvicorn with `--host 0.0.0.0`, and permit the development port in your local firewall. For an iOS simulator on the same host, use the appropriate host URL. Use HTTPS for deployed services and check platform transport restrictions for local HTTP.

Sign up/sign in against your development Appwrite project; the client obtains an Appwrite JWT for Hailey. A server API key is not a client JWT.

Tracked Freezed/JSON generated source is required by the current app build. If models are changed, regenerate deliberately with `dart run build_runner build --delete-conflicting-outputs` after reviewing local generated-file changes. Keep `pubspec.lock`.

## 5. Verify and deploy deliberately

Run `flutter analyze` and `flutter test` at the root; run `python -m pytest tests/unit/` in the backend environment. Service-backed integration tests and the evaluation campaign require separate credentials and consume quota; consult their documentation before running them.

For a container build, use the active backend's **root** Dockerfile from `rag_backend2.0/`:

```bash
docker build -t xhale-hailey .
docker run --rm --env-file .env -p 7860:7860 xhale-hailey
```

That root Dockerfile pre-caches fallback embedding weights. The older `docker/Dockerfile` remains a separate development artifact and should not be substituted silently. `docker/compose.yml` also references the root Dockerfile; review its Qdrant readiness probe and service configuration before relying on that convenience stack.

For Hugging Face Spaces, deploy `rag_backend2.0/` as the Docker build context, keep its README frontmatter, and supply runtime secrets through Space settings. Hosting price, idle behavior, provider quotas and availability depend on the service/account; the repository makes no free-tier or uptime guarantee.

Before public release, complete [third-party rights review](../THIRD_PARTY_NOTICES.md), the [roadmap](ROADMAP.md) and cloud access review.
