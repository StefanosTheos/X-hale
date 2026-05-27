"""
Integration test: full chat flow with mocked LLM and Appwrite.
Tests the graph executes correctly end-to-end.
"""
from __future__ import annotations

import json
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.graph.builder import get_compiled_graph
from app.graph.state import HaileyState


@pytest.mark.asyncio
async def test_medical_question_flow(sample_user_id, sample_memory, sample_triage_medical):
    """A medical question should route through medical agent and produce a response."""
    # Reset the lru_cache for the compiled graph between tests
    get_compiled_graph.cache_clear()

    with patch("app.agents.triage.run_triage", new_callable=AsyncMock, return_value=sample_triage_medical), \
         patch("app.memory.snapshot.build_snapshot", new_callable=AsyncMock, return_value=sample_memory), \
         patch("app.agents.medical.MedicalAgent.run", new_callable=AsyncMock) as mock_medical, \
         patch("app.agents.synthesizer.synthesize", new_callable=AsyncMock) as mock_synth, \
         patch("app.graph.builder.output_node", new_callable=AsyncMock, side_effect=lambda s: s):

        from app.models.retrieval import SpecialistDraft, KeyPoint
        mock_medical.return_value = SpecialistDraft(
            agent="medical",
            key_points=[KeyPoint(claim="Lung cilia begin regenerating within 1 month.", source_id="nhs")],
            tone_hint="factual_reassuring",
        )
        mock_synth.return_value = (
            "Great news — your lungs start recovering quite quickly after quitting.",
            [],
        )

        graph = get_compiled_graph()
        initial: HaileyState = {
            "user_id": sample_user_id,
            "user_input": "How long until my lungs heal?",
            "locale": "en",
            "specialist_drafts": {},
            "requested_specialists": [],
            "citations": [],
            "deeplinks": [],
            "final_response": "",
            "turn_id": "test_t1",
            "is_crisis": False,
            "is_irrelevant": False,
            "needs_clarification": False,
            "error": None,
            "user_memory": None,
            "triage": None,
        }
        result = await graph.ainvoke(initial)
        assert result.get("final_response", "") != ""
