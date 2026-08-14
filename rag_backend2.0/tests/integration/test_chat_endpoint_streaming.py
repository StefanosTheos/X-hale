"""Integration coverage for router-driven, genuine synthesis streaming."""
from __future__ import annotations

from unittest.mock import AsyncMock, patch

import httpx
import pytest

from app.auth.dependencies import get_current_user
from app.main import app
from app.models.user_facts import TriageResult


class _PreparationGraph:
    async def astream(self, state, stream_mode):
        assert stream_mode == "updates"
        triage = TriageResult(
            intent="medical_question",
            emotion="neutral",
            topic_relevance="relevant",
            urgency="low",
            crisis_flag=False,
            requested_specialists=["medical"],
        )
        yield {"triage_node": {**state, "triage": triage}}
        yield {"context_loader_node": {"user_memory": None}}
        yield {"supervisor_node": {"requested_specialists": ["medical"]}}
        yield {
            "medical_node": {
                "specialist_drafts": {
                    "medical": {
                        "key_points": [{"claim": "Recovery begins quickly.", "source_id": "nhs"}],
                        "citations": [{"source_id": "nhs", "source_type": "government"}],
                        "suggested_deeplinks": [],
                    }
                }
            }
        }


async def _tokens(_state):
    yield "Recovery "
    yield "begins quickly."
    yield '\n<!-- citations: ["nhs"] -->'


@pytest.mark.asyncio
async def test_chat_streams_model_tokens_then_saves_and_completes():
    app.dependency_overrides[get_current_user] = lambda: "user_test"
    saved_state = {}

    async def _save(state):
        saved_state.update(state)
        return state

    try:
        with patch("app.routers.chat.get_compiled_preparation_graph", return_value=_PreparationGraph()), \
             patch("app.routers.chat.synthesize_stream", side_effect=_tokens), \
             patch("app.routers.chat.output_node", new_callable=AsyncMock, side_effect=_save):
            transport = httpx.ASGITransport(app=app)
            async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/chat/",
                    json={"message": "How does recovery begin?", "locale": "en"},
                    headers={"Authorization": "Bearer test"},
                )

        body = response.text
        assert response.status_code == 200
        assert body.index('"state": "triaging"') < body.index('"state": "loading_context"')
        assert body.index('"state": "searching_kb"') < body.index('"state": "composing"')
        assert body.index('"token": "Recovery') < body.index('"state": "saving"')
        assert body.index('"state": "saving"') < body.index("event: done")
        assert "<!-- citations:" not in body
        assert saved_state["final_response"] == "Recovery begins quickly."
        assert saved_state["citations"][0].source_id == "nhs"
    finally:
        app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_chat_never_streams_blocked_medical_output():
    async def _unsafe_tokens(_state):
        yield "You should take this medication every morning."

    app.dependency_overrides[get_current_user] = lambda: "user_test"
    try:
        with patch("app.routers.chat.get_compiled_preparation_graph", return_value=_PreparationGraph()), \
             patch("app.routers.chat.synthesize_stream", side_effect=_unsafe_tokens), \
             patch("app.routers.chat.output_node", new_callable=AsyncMock, side_effect=lambda state: state):
            transport = httpx.ASGITransport(app=app)
            async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/chat/", json={"message": "What should I use?", "locale": "en"},
                    headers={"Authorization": "Bearer test"},
                )

        assert "You should take this medication" not in response.text
        assert "doctor or pharmacist" in response.text
    finally:
        app.dependency_overrides.clear()
