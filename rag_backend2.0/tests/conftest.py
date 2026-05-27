"""
Shared pytest fixtures for unit and integration tests.
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from typing import AsyncIterator
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.graph.state import HaileyState
from app.models.retrieval import Citation, SpecialistDraft, KeyPoint, RetrievalResult, RetrievedChunk
from app.models.user_facts import (
    ConversationTurn,
    TriageResult,
    UserFact,
    UserMemorySnapshot,
    UserProfile,
)


# ── Environment fixtures ──────────────────────────────────────────────────────

@pytest.fixture(autouse=True)
def mock_env(monkeypatch):
    """Inject minimal required env vars for all tests."""
    monkeypatch.setenv("GROQ_API_KEY", "test_groq_key")
    monkeypatch.setenv("APPWRITE_PROJECT_ID", "test_project")
    monkeypatch.setenv("APPWRITE_API_KEY", "test_api_key")
    monkeypatch.setenv("APPWRITE_DATABASE_ID", "test_db")
    monkeypatch.setenv("QDRANT_URL", "http://localhost:6333")
    monkeypatch.setenv("CF_ACCOUNT_ID", "test_cf_account")
    monkeypatch.setenv("CF_WORKERS_AI_TOKEN", "test_cf_token")
    monkeypatch.setenv("APPWRITE_CHAT_MESSAGES_COLLECTION_ID", "test_chat_col")
    monkeypatch.setenv("APPWRITE_USER_FACTS_COLLECTION_ID", "test_facts_col")
    monkeypatch.setenv("APPWRITE_USERS_COLLECTION_ID", "test_users_col")
    monkeypatch.setenv("APPWRITE_DIARY_COLLECTION_ID", "test_diary_col")
    monkeypatch.setenv("APPWRITE_ACHIEVEMENTS_COLLECTION_ID", "test_ach_col")


# ── Sample data fixtures ──────────────────────────────────────────────────────

@pytest.fixture
def sample_user_id() -> str:
    return "user_test_123"


@pytest.fixture
def sample_profile(sample_user_id) -> UserProfile:
    return UserProfile(
        user_id=sample_user_id,
        name="Alex",
        quit_date=datetime(2024, 1, 1, tzinfo=timezone.utc),
        days_quit=100,
        cigs_per_day=20,
        years_smoking=10,
        money_saved=250.0,
        num_achievements=15,
        locale="en",
    )


@pytest.fixture
def sample_memory(sample_user_id, sample_profile) -> UserMemorySnapshot:
    return UserMemorySnapshot(
        user_id=sample_user_id,
        profile=sample_profile,
        recent_turns=[
            ConversationTurn(
                turn_id="turn_1",
                user_id=sample_user_id,
                role="user",
                content="I'm struggling with cravings in the morning.",
                timestamp=datetime.now(timezone.utc),
            ),
            ConversationTurn(
                turn_id="turn_2",
                user_id=sample_user_id,
                role="assistant",
                content="Morning cravings are really common. Have you tried...",
                timestamp=datetime.now(timezone.utc),
            ),
        ],
        top_facts=[
            UserFact(
                user_id=sample_user_id,
                fact_type="trigger",
                fact_key="morning_coffee",
                fact_value="Biggest craving trigger, mentioned multiple times",
                confidence=0.9,
            )
        ],
    )


@pytest.fixture
def sample_triage_medical() -> TriageResult:
    return TriageResult(
        intent="medical_question",
        emotion="neutral",
        topic_relevance="relevant",
        urgency="low",
        crisis_flag=False,
        requested_specialists=["medical"],
    )


@pytest.fixture
def sample_triage_crisis() -> TriageResult:
    return TriageResult(
        intent="emotional_support",
        emotion="fear",
        topic_relevance="relevant",
        urgency="high",
        crisis_flag=True,
        requested_specialists=[],
    )


@pytest.fixture
def sample_triage_craving() -> TriageResult:
    return TriageResult(
        intent="craving_support",
        emotion="anxiety",
        topic_relevance="relevant",
        urgency="high",
        crisis_flag=False,
        requested_specialists=["craving_support", "emotional_support"],
    )


@pytest.fixture
def sample_state(sample_user_id, sample_memory, sample_triage_medical) -> HaileyState:
    return HaileyState(
        user_id=sample_user_id,
        user_input="How long until my lungs fully recover after quitting?",
        locale="en",
        user_memory=sample_memory,
        triage=sample_triage_medical,
        specialist_drafts={},
        requested_specialists=["medical"],
        citations=[],
        deeplinks=[],
        final_response="",
        turn_id="test_turn_1",
        is_crisis=False,
        is_irrelevant=False,
        needs_clarification=False,
        error=None,
    )


@pytest.fixture
def sample_retrieval_result() -> RetrievalResult:
    return RetrievalResult(
        query="lung recovery after quitting",
        chunks=[
            RetrievedChunk(
                content="Lung cilia begin to regenerate within a few weeks of quitting smoking.",
                source_id="nhs_quit_benefits",
                source_type="government",
                score=0.87,
            ),
            RetrievedChunk(
                content="After 1 year smoke-free, your risk of coronary heart disease is halved.",
                source_id="cdc_benefits_timeline",
                source_type="government",
                score=0.81,
            ),
        ],
        citations=[
            Citation(source_id="nhs_quit_benefits", source_type="government"),
            Citation(source_id="cdc_benefits_timeline", source_type="government"),
        ],
        strategy_used="vector",
    )


# ── Mock LLM fixtures ─────────────────────────────────────────────────────────

@pytest.fixture
def mock_groq_complete():
    """Mock the GroqClient.complete method to return a fixed JSON response."""
    with patch("app.llm.groq_client.GroqClient.complete", new_callable=AsyncMock) as m:
        m.return_value = '{"intent": "medical_question", "emotion": "neutral", "topic_relevance": "relevant", "urgency": "low", "crisis_flag": false, "requested_specialists": ["medical"]}'
        yield m


@pytest.fixture
def mock_retrieval():
    """Mock the hybrid_retriever.retrieve function."""
    with patch("app.retrieval.hybrid_retriever.retrieve", new_callable=AsyncMock) as m:
        yield m
