"""
Centralised configuration via pydantic-settings.
All values come from environment variables (see .env.example).
This module instantiates a single `settings` singleton imported everywhere.
"""
from __future__ import annotations

from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── LLM ────────────────────────────────────────────────────────────────
    groq_api_key: str = ""
    groq_triage_model: str = "llama-3.1-8b-instant"
    groq_synthesis_model: str = "llama-3.3-70b-versatile"
    groq_triage_temperature: float = 0.0
    groq_synthesis_temperature: float = 0.5

    # ── Google Gemini ───────────────────────────────────────────────────────
    gemini_api_key: str = ""
    gemini_triage_model: str = "gemini-2.5-flash"
    gemini_synthesis_model: str = "gemini-2.5-flash"

    # ── Cloudflare Workers AI ───────────────────────────────────────────────
    cf_account_id: str = ""
    cf_workers_ai_token: str = ""
    cf_embedding_model: str = "@cf/baai/bge-small-en-v1.5"
    cf_small_model: str = "@cf/meta/llama-3.2-3b-instruct"
    cf_workers_ai_daily_quota: int = 10_000
    cf_workers_ai_base_url: str = "https://api.cloudflare.com/client/v4/accounts"

    # ── Qdrant ──────────────────────────────────────────────────────────────
    qdrant_url: str = "http://localhost:6333"
    qdrant_api_key: Optional[str] = None
    qdrant_kb_collection: str = "kb_chunks"
    qdrant_health_benefits_collection: str = "health_benefit_chunks"
    qdrant_vector_size: int = 384   # bge-small-en-v1.5 output dim

    # ── Appwrite ────────────────────────────────────────────────────────────
    appwrite_endpoint: str = "https://fra.cloud.appwrite.io/v1"
    appwrite_project_id: str = ""
    appwrite_api_key: str = ""
    appwrite_database_id: str = ""

    # Existing collections (read-only from chatbot)
    appwrite_users_collection_id: str = ""
    appwrite_diary_collection_id: str = ""
    appwrite_achievements_collection_id: str = ""
    appwrite_milestones_collection_id: str = ""
    appwrite_health_benefits_collection_id: str = ""

    # New collections (create manually — see ARCHITECTURE.md)
    appwrite_chat_messages_collection_id: str = ""
    appwrite_user_facts_collection_id: str = ""

    # ── Feature flags ───────────────────────────────────────────────────────
    enable_reranker: bool = False
    enable_knowledge_graph: bool = False
    enable_web_search_fallback: bool = False

    # ── Observability ───────────────────────────────────────────────────────
    log_level: str = "INFO"
    metrics_enabled: bool = True

    # ── Request limits ──────────────────────────────────────────────────────
    request_timeout_seconds: int = 60
    max_conversation_turns: int = 10
    max_user_facts: int = 30

    # ── Auth ────────────────────────────────────────────────────────────────
    jwt_cache_ttl_seconds: int = 60   # how long a verified JWT is trusted in-process


@lru_cache
def get_settings() -> Settings:
    return Settings()


# Module-level singleton for direct import
settings: Settings = get_settings()
