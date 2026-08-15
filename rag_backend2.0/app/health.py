"""Liveness, configuration validation, and cached dependency readiness checks."""
from __future__ import annotations

import asyncio
import time

from appwrite.query import Query

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)

_READINESS_TTL_SECONDS = 60.0
_readiness_cache: tuple[float, dict] | None = None
_readiness_lock = asyncio.Lock()


def missing_required_settings() -> list[str]:
    """Return required runtime settings that are empty or unusable."""
    required = {
        "GROQ_API_KEY": settings.groq_api_key,
        "CF_ACCOUNT_ID": settings.cf_account_id,
        "CF_WORKERS_AI_TOKEN": settings.cf_workers_ai_token,
        "APPWRITE_ENDPOINT": settings.appwrite_endpoint,
        "APPWRITE_PROJECT_ID": settings.appwrite_project_id,
        "APPWRITE_API_KEY": settings.appwrite_api_key,
        "APPWRITE_DATABASE_ID": settings.appwrite_database_id,
        "APPWRITE_USERS_COLLECTION_ID": settings.appwrite_users_collection_id,
        "APPWRITE_DIARY_COLLECTION_ID": settings.appwrite_diary_collection_id,
        "APPWRITE_ACHIEVEMENTS_COLLECTION_ID": settings.appwrite_achievements_collection_id,
        "APPWRITE_MILESTONES_COLLECTION_ID": settings.appwrite_milestones_collection_id,
        "APPWRITE_HEALTH_BENEFITS_COLLECTION_ID": settings.appwrite_health_benefits_collection_id,
        "APPWRITE_CHAT_MESSAGES_COLLECTION_ID": settings.appwrite_chat_messages_collection_id,
        "APPWRITE_USER_FACTS_COLLECTION_ID": settings.appwrite_user_facts_collection_id,
        "QDRANT_URL": settings.qdrant_url,
        "QDRANT_KB_COLLECTION": settings.qdrant_kb_collection,
        "QDRANT_HEALTH_BENEFITS_COLLECTION": settings.qdrant_health_benefits_collection,
    }
    if settings.qdrant_url.startswith("https://"):
        required["QDRANT_API_KEY"] = settings.qdrant_api_key
    return sorted(name for name, value in required.items() if not value)


async def _check_appwrite() -> None:
    """Verify the server key can read an application row collection."""
    import asyncio
    from app.memory.conversation_store import _build_client

    db, database_id = _build_client()
    await asyncio.to_thread(
        db.list_rows,
        database_id,
        settings.appwrite_users_collection_id,
        queries=[Query.limit(1)],
    )


async def _check_qdrant() -> None:
    from app.retrieval.vector_store import get_qdrant_client

    result = await get_qdrant_client().get_collections()
    available = {collection.name for collection in result.collections}
    required = {settings.qdrant_kb_collection, settings.qdrant_health_benefits_collection}
    missing = required - available
    if missing:
        raise RuntimeError(f"missing configured collection(s): {', '.join(sorted(missing))}")


async def _check_groq() -> None:
    from groq import AsyncGroq

    client = AsyncGroq(api_key=settings.groq_api_key, max_retries=0, timeout=10.0)
    try:
        await client.models.list()
    finally:
        await client.close()


async def _check_cloudflare() -> None:
    # Call the primary provider directly so readiness distinguishes it from
    # the local fallback used by the application.
    from app.llm.workers_ai_client import _base_url, _post_json

    data = await _post_json(_base_url(settings.cf_embedding_model), {"text": ["X-hale readiness probe"]})
    vector = data["result"]["data"][0]
    if len(vector) != settings.qdrant_vector_size:
        raise RuntimeError(
            f"embedding dimension {len(vector)} != configured {settings.qdrant_vector_size}"
        )


async def _check_local_embeddings() -> None:
    from app.llm.workers_ai_client import embed_local

    vector = (await embed_local(["X-hale local readiness probe"]))[0]
    if len(vector) != settings.qdrant_vector_size:
        raise RuntimeError(
            f"local embedding dimension {len(vector)} != configured {settings.qdrant_vector_size}"
        )


async def check_readiness(*, force: bool = False) -> dict:
    """Return cached component readiness without exposing provider errors to callers."""
    global _readiness_cache
    now = time.monotonic()
    if not force and _readiness_cache and now < _readiness_cache[0]:
        return _readiness_cache[1]

    async with _readiness_lock:
        now = time.monotonic()
        if not force and _readiness_cache and now < _readiness_cache[0]:
            return _readiness_cache[1]

        missing = missing_required_settings()
        components: dict[str, str] = {"configuration": "ready" if not missing else "not_ready"}
        errors: dict[str, str] = {}
        checks = {
            "appwrite": _check_appwrite,
            "qdrant": _check_qdrant,
            "groq": _check_groq,
            "cloudflare": _check_cloudflare,
            "local_embeddings": _check_local_embeddings,
        }
        if missing:
            for name in checks:
                components[name] = "not_checked"
            errors["configuration"] = f"missing: {', '.join(missing)}"
        else:
            results = await asyncio.gather(
                *(check() for check in checks.values()), return_exceptions=True,
            )
            for name, result in zip(checks, results):
                if isinstance(result, BaseException):
                    components[name] = "not_ready"
                    detail = str(result) or "no provider message"
                    errors[name] = f"{type(result).__name__}: {detail}"
                else:
                    components[name] = "ready"

        core_ready = all(
            components.get(name) == "ready"
            for name in ("configuration", "appwrite", "qdrant", "groq")
        )
        embeddings_ready = (
            components.get("cloudflare") == "ready"
            or (
                settings.enable_local_embedding_fallback
                and components.get("local_embeddings") == "ready"
            )
        )
        ready = core_ready and embeddings_ready
        payload = {"status": "ready" if ready else "not_ready", "components": components}
        _readiness_cache = (time.monotonic() + _READINESS_TTL_SECONDS, payload)
        if not ready:
            logger.warning("readiness_check_failed", errors=errors)
        return payload


def clear_readiness_cache() -> None:
    """Testing/deployment helper for forcing the next live dependency check."""
    global _readiness_cache
    _readiness_cache = None
