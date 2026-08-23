"""Claim entailment and citation coverage checks."""
from app.models.retrieval import Citation
from app.safety.citation_validator import claim_is_represented, validate_citations
from app.agents.synthesizer import post_process_synthesis
from app.safety.medical_risk import medical_risk_tier


def _citation(source_id: str, snippet: str = "Recovery begins quickly after quitting.") -> Citation:
    return Citation(
        source_id=source_id,
        source_type="government",
        title=f"Title {source_id}",
        url=f"https://example.org/{source_id}",
        snippet=snippet,
    )


def test_supported_claim_is_cited_without_model_marker():
    citation = _citation("nhs")
    result = validate_citations(
        "Recovery begins quickly after quitting.",
        {"nhs": ["Recovery begins quickly after smoking cessation."]},
        {"nhs": citation},
        [],
    )

    assert result.citations == [citation]
    assert result.represented_claims == 1


def test_declared_source_without_support_is_removed():
    result = validate_citations(
        "Try a breathing exercise when a craving arrives.",
        {"nhs": ["Lung function improves after quitting."]},
        {"nhs": _citation("nhs", "Lung function improves after quitting.")},
        ["nhs"],
    )

    assert result.citations == []
    assert result.rejection_reasons["nhs"] == ["claim_not_present_in_response"]


def test_incomplete_model_markers_are_completed_from_represented_claims():
    result = validate_citations(
        "Recovery begins quickly, and circulation improves within weeks.",
        {
            "nhs": ["Recovery begins quickly after quitting."],
            "cdc": ["Circulation improves within several weeks."],
        },
        {
            "nhs": _citation("nhs", "Recovery begins quickly after quitting."),
            "cdc": _citation("cdc", "Circulation improves within several weeks."),
        },
        ["nhs"],
    )

    assert [citation.source_id for citation in result.citations] == ["nhs", "cdc"]


def test_numeric_claim_requires_matching_number():
    assert claim_is_represented(
        "Cravings often peak for 5 minutes.",
        "Cravings often peak for 20 minutes.",
    ) is False


def test_negated_claim_does_not_entail_positive_source_claim():
    assert claim_is_represented(
        "Cardiovascular risk decreases after quitting.",
        "Cardiovascular risk does not decrease after quitting.",
    ) is False


def test_fabricated_source_id_is_never_exposed():
    result = validate_citations(
        "Recovery begins quickly after quitting.",
        {"nhs": ["Recovery begins quickly after quitting."]},
        {"nhs": _citation("nhs")},
        ["fabricated"],
    )

    assert [citation.source_id for citation in result.citations] == ["nhs"]
    assert result.rejection_reasons["fabricated"] == ["source_not_retrieved"]


def test_final_claim_matching_hallucinated_key_point_is_not_cited():
    result = validate_citations(
        "Recovery takes exactly 90 years.",
        {"nhs": ["Recovery takes exactly 90 years."]},
        {"nhs": _citation("nhs", "Recovery begins within several weeks.")},
        ["nhs"],
    )

    assert result.citations == []


def test_retrieved_source_without_attributed_claim_has_rejection_reason():
    result = validate_citations(
        "A cautious answer.", {}, {"nhs": _citation("nhs")}, [],
    )
    assert result.rejection_reasons["nhs"] == ["no_specialist_claim_attributed"]


def test_final_answer_can_align_directly_with_retrieved_evidence():
    citation = _citation("cdc", "Blood circulation improves after quitting smoking.")
    result = validate_citations(
        "After quitting, your circulation can improve.", {}, {"cdc": citation}, [],
    )
    assert result.citations == [citation]


def test_medical_post_processing_keeps_supported_canonical_citation():
    citation = _citation("nhs_nrt", "Nicotine replacement therapy helps manage cravings.")
    state = {
        "requested_specialists": ["medical"],
        "specialist_drafts": {
            "medical": {
                "key_points": [{
                    "claim": "Nicotine replacement therapy helps manage cravings.",
                    "source_id": "nhs_nrt",
                }],
                "citations": [citation.model_dump()],
            },
        },
        "trace": {},
    }
    text, citations = post_process_synthesis(
        "Nicotine replacement therapy helps manage cravings.\n"
        '<!-- citations: ["nhs_nrt"] -->',
        state,
    )
    assert text == "Nicotine replacement therapy helps manage cravings."
    assert citations == [citation]
    assert state["trace"]["citation_validation"]["rejection_reasons"] == {}
    assert state["trace"]["citation_validation"]["candidate_response"] == (
        "Nicotine replacement therapy helps manage cravings."
    )
    assert state["trace"]["citation_validation"]["source_claims"] == {
        "nhs_nrt": ["Nicotine replacement therapy helps manage cravings."]
    }


def test_medical_risk_tiers_protect_medication_and_timeline_queries():
    assert medical_risk_tier("Can I use a nicotine patch while pregnant?") == "high"
    assert medical_risk_tier("How long until my lungs improve?") == "medium"
    assert medical_risk_tier("Can quitting help my fitness?") == "low"


def test_low_risk_uncited_answer_is_retained_with_uncertainty():
    citation = _citation("fitness", "Exercise can support a quit attempt.")
    state = {
        "user_input": "Can quitting help my fitness?",
        "requested_specialists": ["medical"],
        "specialist_drafts": {"medical": {"key_points": [], "citations": [citation.model_dump()]}},
        "trace": {},
    }
    text, citations = post_process_synthesis("Your fitness may improve after quitting.", state)
    assert "could not verify a passage closely enough" in text
    assert citations == []


def test_medium_risk_uncited_answer_still_abstains():
    citation = _citation("timeline", "Recovery varies between people.")
    state = {
        "user_input": "How long until my lungs recover?",
        "requested_specialists": ["medical"],
        "specialist_drafts": {"medical": {"key_points": [], "citations": [citation.model_dump()]}},
        "trace": {},
    }
    text, citations = post_process_synthesis("It takes two weeks.", state)
    assert text.startswith("I couldn't verify enough source-backed information")
    assert citations == []
