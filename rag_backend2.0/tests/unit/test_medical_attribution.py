"""Medical-agent source attribution regressions."""
from app.agents.medical import (
    _canonicalise_key_points, _parse_json_object, _promote_retrieved_evidence,
)
from app.models.retrieval import RetrievalResult, RetrievedChunk


def _retrieval() -> RetrievalResult:
    return RetrievalResult(chunks=[
        RetrievedChunk(content="First", source_id="nhs_nrt_guide"),
        RetrievedChunk(content="Second", source_id="cdc_quitting"),
    ])


def test_numeric_model_source_is_mapped_to_canonical_id():
    points = _canonicalise_key_points(
        [{"claim": "NRT can help manage cravings.", "source_id": "1"}],
        _retrieval(),
    )
    assert points[0].source_id == "nhs_nrt_guide"


def test_unknown_model_source_is_not_accepted():
    points = _canonicalise_key_points(
        [{"claim": "Unsupported claim.", "source_id": "invented"}],
        _retrieval(),
    )
    assert points == []


def test_json_object_is_recovered_from_fallback_markdown():
    parsed = _parse_json_object('Here is the result:\n```json\n{"key_points": []}\n```')
    assert parsed == {"key_points": []}


def test_retrieval_prompt_has_only_canonical_source_label():
    prompt = _retrieval().format_for_prompt()
    assert "[SOURCE_ID=nhs_nrt_guide; TYPE=UNKNOWN]" in prompt
    assert "[1]" not in prompt


def test_empty_extraction_promotes_exact_relevant_source_sentence():
    retrieval = RetrievalResult(chunks=[RetrievedChunk(
        content=(
            "General introduction. Sleep problems or vivid dreams may occur while "
            "using a nicotine patch. Contact a clinician for severe effects."
        ), source_id="smokefree_patch", score=0.8,
    )])
    points = _promote_retrieved_evidence(
        "Are vivid dreams caused by my nicotine patch?", retrieval,
    )
    assert points
    assert points[0].source_id == "smokefree_patch"
    assert points[0].claim == "Sleep problems or vivid dreams may occur while using a nicotine patch."


def test_evidence_promotion_does_not_use_unrelated_sentence():
    retrieval = RetrievalResult(chunks=[RetrievedChunk(
        content="Exercise can help some people manage cravings.",
        source_id="exercise", score=0.9,
    )])
    assert _promote_retrieved_evidence("Does quitting improve fertility?", retrieval) == []
