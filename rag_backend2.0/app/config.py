"""
Centralised configuration via pydantic-settings.
All values come from environment variables (see .env.example).
This module instantiates a single `settings` singleton imported everywhere.
"""
from __future__ import annotations

from functools import lru_cache
from typing import Optional

from pydantic import Field
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
    groq_triage_model: str = "openai/gpt-oss-20b"
    groq_synthesis_model: str = "openai/gpt-oss-120b"
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
    enable_local_embedding_fallback: bool = True

    # ── Qdrant ──────────────────────────────────────────────────────────────
    qdrant_url: str = "http://localhost:6333"
    qdrant_api_key: Optional[str] = None
    qdrant_kb_collection: str = "kb_chunks"
    qdrant_health_benefits_collection: str = "health_benefit_chunks"
    qdrant_vector_size: int = 384   # bge-small-en-v1.5 output dim
    retrieval_min_score: float = Field(default=0.60, ge=-1.0, le=1.0)
    retrieval_candidate_multiplier: int = Field(default=4, ge=1, le=20)

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
    appwrite_forum_collection_id: str = "685d31d9003c29f13421"
    appwrite_challenges_collection_id: str = "685d3233002933bc80d6"
    appwrite_challenge_entries_collection_id: str = "685d32bb0023444507f9"
    appwrite_motivations_collection_id: str = "685d314700303649367a"
    appwrite_friendships_collection_id: str = "6880cd730012d3aac2cc"
    appwrite_friend_requests_collection_id: str = "6880ce0d000a1ad99b58"
    appwrite_direct_messages_collection_id: str = "6880ce5800193d799b9f"
    appwrite_messages_misc_collection_id: str = "686d38950033f3fcd785"
    appwrite_user_avatars_bucket_id: str = "6a031c95003375921887"

    # New collections (create manually — see ARCHITECTURE.md)
    appwrite_chat_messages_collection_id: str = ""
    appwrite_user_facts_collection_id: str = ""

    # Authenticated Appwrite user reserved for benchmark execution. Its turns
    # are persisted normally, but post-response memory curation is disabled.
    benchmark_test_user_id: str = ""

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

@lru_cache
def get_settings() -> Settings:
    return Settings()


# Module-level singleton for direct import
settings: Settings = get_settings()
