"""Medical-agent source attribution regressions."""
from app.agents.medical import (
    _canonicalise_key_points, _parse_json_object, _promote_retrieved_evidence,
)
from app.models.retrieval import RetrievalResult, RetrievedChunk
from app.models.retrieval import bounded_excerpt


def _retrieval() -> RetrievalResult:
    return RetrievalResult(chunks=[
        RetrievedChunk(
            content="Nicotine replacement therapy can help manage nicotine cravings.",
            source_id="nhs_nrt_guide",
        ),
        RetrievedChunk(
            content="Stopping smoking reduces exposure to harmful tobacco smoke.",
            source_id="cdc_quitting",
        ),
    ])


def test_numeric_model_source_is_mapped_to_canonical_id():
    points = _canonicalise_key_points(
        [{"claim": "NRT can help manage cravings.", "source_id": "1"}],
        _retrieval(),
    )
    assert points[0].source_id == "nhs_nrt_guide"
    assert points[0].claim == "Nicotine replacement therapy can help manage nicotine cravings."


def test_broader_model_mechanism_is_replaced_by_exact_source_sentence():
    retrieval = RetrievalResult(chunks=[RetrievedChunk(
        content="The risk of stroke decreases steadily after smoking cessation.",
        source_id="cdc_stroke",
    )])
    points = _canonicalise_key_points([{
        "claim": "Blood vessels recover and reduce clot formation after quitting.",
        "source_id": "cdc_stroke",
    }], retrieval)

    assert points == []


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


def test_legacy_mid_sentence_chunk_prefix_is_removed_from_excerpt():
    text = "ing from a broken prior sentence. Sleep problems can occur during withdrawal."
    assert bounded_excerpt(text) == "Sleep problems can occur during withdrawal."
