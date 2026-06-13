"""Unit tests for the knowledge graph loader, entity extractor, and hybrid retriever KG path."""
from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from app.retrieval.knowledge_graph import load_graph, expand_entities, GraphExpansionResult
from app.retrieval.entity_extractor import extract_entities
from app.retrieval.hybrid_retriever import _merge_chunks
from app.models.retrieval import RetrievedChunk


# ── Graph loading ─────────────────────────────────────────────────────────────

def test_load_graph_returns_non_empty():
    """Graph must load from YAML with meaningful node and edge counts."""
    load_graph.cache_clear()
    G = load_graph()
    assert G.number_of_nodes() >= 100
    assert G.number_of_edges() >= 150


def test_load_graph_nodes_have_required_attrs():
    """Every node must have type, label, aliases, and topic_tags attributes."""
    G = load_graph()
    for node_id, attrs in G.nodes(data=True):
        assert "type" in attrs, f"{node_id} missing type"
        assert "label" in attrs, f"{node_id} missing label"
        assert "aliases" in attrs, f"{node_id} missing aliases"
        assert "topic_tags" in attrs, f"{node_id} missing topic_tags"


def test_load_graph_all_edge_nodes_exist():
    """No edge should reference a node that doesn't exist (validated by YAML authoring tool)."""
    G = load_graph()
    node_ids = set(G.nodes())
    for src, dst in G.edges():
        assert src in node_ids
        assert dst in node_ids


def test_load_graph_topic_tags_are_valid():
    """All topic_tags must be from the approved vocabulary (matching Qdrant payloads)."""
    valid_tags = {
        "health_benefits", "quit_timeline", "withdrawal", "lung_health",
        "cancer_risk", "cardiovascular", "motivation", "nrt", "nicotine_patches",
        "nicotine_gum", "cessation_methods", "cravings", "triggers",
        "behavioral_support", "coping_strategies", "tobacco_harms",
        "global_statistics", "addiction", "nicotine", "nicotine_dependence",
        "lung_disease", "copd", "lung_cancer", "mouth_cancer", "throat_cancer",
        "tobacco_related_mortality", "secondhand_smoke", "passive_smoking",
        "children", "pregnancy", "maternal_health", "varenicline", "bupropion",
        "prescription_medications", "relapse_prevention", "clinical_guidelines",
        "counseling",
    }
    G = load_graph()
    for node_id, attrs in G.nodes(data=True):
        for tag in attrs.get("topic_tags", []):
            assert tag in valid_tags, f"Node {node_id} has invalid tag '{tag}'"


# ── expand_entities ───────────────────────────────────────────────────────────

def test_expand_entities_empty_input():
    result = expand_entities([])
    assert result.is_empty()
    assert result.topic_tags == []


def test_expand_entities_invalid_ids():
    result = expand_entities(["nonexistent_node_xyz"])
    assert result.topic_tags == []


def test_expand_entities_withdrawal_symptom_reaches_withdrawal_tags():
    """Expanding from a withdrawal symptom must include the 'withdrawal' topic_tag."""
    result = expand_entities(["sym_irritability"], hops=2)
    assert not result.is_empty()
    assert "withdrawal" in result.topic_tags


def test_expand_entities_trigger_reaches_cravings_tags():
    """Expanding from a trigger node must include 'cravings' and 'coping_strategies'."""
    result = expand_entities(["trig_coffee"], hops=2)
    assert "cravings" in result.topic_tags
    assert "coping_strategies" in result.topic_tags


def test_expand_entities_medication_reaches_nrt_tags():
    """Expanding from a medication node must include 'nrt' and 'cessation_methods'."""
    result = expand_entities(["med_nicotine_patch"], hops=2)
    assert "nrt" in result.topic_tags
    assert "cessation_methods" in result.topic_tags


def test_expand_entities_hops_1_is_narrower_than_hops_2():
    """Fewer hops should produce fewer or equal tags."""
    r1 = expand_entities(["sym_irritability"], hops=1)
    r2 = expand_entities(["sym_irritability"], hops=2)
    assert len(r1.topic_tags) <= len(r2.topic_tags)


def test_expand_entities_disease_reaches_tobacco_harms():
    """Expanding from a lung disease node must include tobacco_harms and cancer tags."""
    result = expand_entities(["disease_lung_cancer"], hops=2)
    assert "cancer_risk" in result.topic_tags or "tobacco_harms" in result.topic_tags


def test_expand_entities_returns_sorted_tags():
    """topic_tags should be sorted for deterministic downstream behaviour."""
    result = expand_entities(["sym_irritability"], hops=2)
    assert result.topic_tags == sorted(result.topic_tags)


# ── Entity extractor ──────────────────────────────────────────────────────────

def test_extract_entities_empty_query():
    assert extract_entities("") == []


def test_extract_entities_irritable_matches_symptom():
    result = extract_entities("I've been really irritable since I quit")
    assert "sym_irritability" in result


def test_extract_entities_coffee_matches_trigger():
    result = extract_entities("Every time I have a coffee I want to smoke")
    assert "trig_coffee" in result


def test_extract_entities_insomnia_matches_symptom():
    result = extract_entities("I can't sleep at all since quitting")
    assert "sym_insomnia" in result


def test_extract_entities_champix_matches_varenicline():
    result = extract_entities("My doctor prescribed Champix")
    assert "med_varenicline" in result


def test_extract_entities_respects_max_entities():
    # A query mentioning many concepts should still be capped
    query = "I'm irritable, can't sleep, always tired, drinking coffee, feeling anxious and depressed"
    result = extract_entities(query, max_entities=4)
    assert len(result) <= 4


def test_extract_entities_no_false_positive_short_alias():
    # "nrt" should not match in a word like "smart"
    result = extract_entities("That's a smart strategy")
    assert "cope_nrt_use" not in result
    assert "med_nicotine_patch" not in result


def test_extract_entities_case_insensitive():
    result_lower = extract_entities("i feel irritable")
    result_upper = extract_entities("I FEEL IRRITABLE")
    assert set(result_lower) == set(result_upper)


def test_extract_entities_longer_alias_ranked_higher():
    """Nodes matched by longer aliases should appear earlier in the result."""
    result = extract_entities("I've been really anxious since quitting")
    # "anxious since quitting" (longer alias) should rank sym_anxiety_withdrawal highly
    if "sym_anxiety_withdrawal" in result:
        idx = result.index("sym_anxiety_withdrawal")
        assert idx < 4  # should be near the top


# ── _merge_chunks helper ──────────────────────────────────────────────────────

def _chunk(source_id: str, score: float = 0.7) -> RetrievedChunk:
    return RetrievedChunk(content="x", source_id=source_id, source_type="government", score=score)


def test_merge_chunks_deduplicates_by_source_id():
    primary = [_chunk("a", 0.9), _chunk("b", 0.8)]
    secondary = [_chunk("b", 0.7), _chunk("c", 0.6)]
    result = _merge_chunks(primary, secondary)
    ids = [c.source_id for c in result]
    assert ids.count("b") == 1


def test_merge_chunks_primary_takes_precedence():
    primary = [_chunk("a", 0.9)]
    secondary = [_chunk("a", 0.5)]  # same source_id, lower score
    result = _merge_chunks(primary, secondary)
    assert len(result) == 1
    assert result[0].score == 0.9


def test_merge_chunks_sorted_by_score():
    primary = [_chunk("a", 0.5)]
    secondary = [_chunk("b", 0.9), _chunk("c", 0.7)]
    result = _merge_chunks(primary, secondary)
    scores = [c.score for c in result]
    assert scores == sorted(scores, reverse=True)


def test_merge_chunks_respects_max_total():
    primary = [_chunk(f"p{i}", 0.9 - i * 0.01) for i in range(6)]
    secondary = [_chunk(f"s{i}", 0.5 - i * 0.01) for i in range(6)]
    result = _merge_chunks(primary, secondary, max_total=5)
    assert len(result) == 5


# ── KG path in hybrid retriever ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_retriever_kg_path_adds_chunks(monkeypatch, sample_state):
    """When KG is enabled and entities match, the retriever should merge extra chunks."""
    from app.retrieval.hybrid_retriever import retrieve
    from app.models.retrieval import RetrievedChunk

    monkeypatch.setattr("app.retrieval.hybrid_retriever.settings.enable_knowledge_graph", True)
    monkeypatch.setattr("app.retrieval.hybrid_retriever.settings.enable_web_search_fallback", False)
    monkeypatch.setattr("app.retrieval.hybrid_retriever.settings.enable_reranker", False)

    vector_chunk = RetrievedChunk(content="NRT info", source_id="nrt_src", source_type="government", score=0.85)
    kg_chunk = RetrievedChunk(content="Withdrawal info", source_id="wd_src", source_type="government", score=0.70)

    with (
        patch("app.retrieval.hybrid_retriever._vector_retrieval", new=AsyncMock(return_value=[vector_chunk])),
        patch("app.retrieval.hybrid_retriever._kg_retrieval", new=AsyncMock(return_value=[kg_chunk])),
        patch("app.retrieval.entity_extractor.extract_entities", return_value=["sym_irritability"]),
        patch("app.retrieval.knowledge_graph.expand_entities", return_value=GraphExpansionResult(
            seed_node_ids=["sym_irritability"],
            related_node_ids=["concept_nicotine_withdrawal"],
            topic_tags=["withdrawal", "coping_strategies"],
        )),
    ):
        result = await retrieve("I'm very irritable", "user_123", strategy="factual")

    assert result.strategy_used == "vector+graph"
    source_ids = {c.source_id for c in result.chunks}
    assert "nrt_src" in source_ids
    assert "wd_src" in source_ids


@pytest.mark.asyncio
async def test_retriever_kg_path_skipped_when_disabled(monkeypatch):
    """When ENABLE_KNOWLEDGE_GRAPH=false, entity extraction must not be called."""
    from app.retrieval.hybrid_retriever import retrieve

    monkeypatch.setattr("app.retrieval.hybrid_retriever.settings.enable_knowledge_graph", False)
    monkeypatch.setattr("app.retrieval.hybrid_retriever.settings.enable_web_search_fallback", False)
    monkeypatch.setattr("app.retrieval.hybrid_retriever.settings.enable_reranker", False)

    with (
        patch("app.retrieval.hybrid_retriever._vector_retrieval", new=AsyncMock(return_value=[])),
        patch("app.retrieval.entity_extractor.extract_entities") as mock_extract,
    ):
        result = await retrieve("test query", "user_123", strategy="factual")

    mock_extract.assert_not_called()
    assert result.strategy_used == "vector"
