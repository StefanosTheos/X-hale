"""Claim entailment and citation coverage checks."""
from app.models.retrieval import Citation
from app.safety.citation_validator import claim_is_represented, validate_citations
from app.agents.synthesizer import (
    _medical_sentence_is_attributed,
    _quantitative_sentence_is_attributed,
    post_process_synthesis,
)
from app.safety.medical_risk import medical_risk_tier
from app.safety.medical_risk import (
    professional_escalation_message,
    requires_professional_escalation,
)


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


def test_unattributed_retrieved_source_cannot_gain_direct_citation():
    citation = _citation("cdc", "Blood circulation improves after quitting smoking.")
    result = validate_citations(
        "After quitting, your circulation can improve.", {}, {"cdc": citation}, [],
    )
    assert result.citations == []


def test_direct_alignment_is_limited_to_specialist_attributed_source():
    citation = _citation("cdc", "Blood circulation improves after quitting smoking.")
    result = validate_citations(
        "After quitting, your circulation can improve.",
        {"cdc": ["Blood circulation improves after quitting smoking."]},
        {"cdc": citation}, [],
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


def test_low_risk_uncited_medical_answer_abstains():
    citation = _citation("fitness", "Exercise can support a quit attempt.")
    state = {
        "user_input": "Can quitting help my fitness?",
        "requested_specialists": ["medical"],
        "specialist_drafts": {"medical": {"key_points": [], "citations": [citation.model_dump()]}},
        "trace": {},
    }
    text, citations = post_process_synthesis("Your fitness may improve after quitting.", state)
    assert text.startswith("I couldn't verify enough source-backed information")
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


def test_generated_timeframe_must_exist_in_attributed_claim():
    claims = ["Lung function can increase by up to 10%."]
    assert _quantitative_sentence_is_attributed(
        "Lung function can increase by up to 10%.", claims,
    ) is True
    assert _quantitative_sentence_is_attributed(
        "By the end of a year, lung function can increase by up to 10%.", claims,
    ) is False


def test_unsupported_medical_explanation_is_rejected():
    claims = ["You may feel hungrier after quitting."]
    assert _medical_sentence_is_attributed(
        "You may feel hungrier after quitting.", claims,
    ) is True
    assert _medical_sentence_is_attributed(
        "Your metabolism slows because nicotine changes your body.", claims,
    ) is False


def test_new_medical_domains_require_attributed_evidence():
    assert _medical_sentence_is_attributed(
        "Quitting boosts immunity and helps gums heal.", [],
    ) is False
    assert _medical_sentence_is_attributed(
        "Nicotine patches can cause vivid dreams.", [],
    ) is False


def test_removed_paraphrased_timeline_is_restored_as_exact_key_point():
    citation = _citation("nhs", "After 48 hours carbon monoxide drops to a non-smoker level.")
    state = {
        "user_input": "How quickly does carbon monoxide leave my body?",
        "requested_specialists": ["medical"],
        "specialist_drafts": {"medical": {
            "key_points": [{
                "claim": "After 48 hours carbon monoxide drops to a non-smoker level.",
                "source_id": "nhs",
            }],
            "citations": [citation.model_dump()],
        }},
        "trace": {},
    }
    text, citations = post_process_synthesis(
        "Within two days carbon monoxide drops to a non-smoker level.", state,
    )
    assert "After 48 hours carbon monoxide drops to a non-smoker level." in text
    assert citations == [citation]


def test_timeline_heading_and_halved_paraphrase_are_aligned():
    citation = _citation(
        "nhs",
        "After 10 years More great news! Your risk of death from lung cancer "
        "will have halved compared with a smoker's.",
    )
    result = validate_citations(
        "Within about a decade, the chance of dying from lung cancer drops roughly 50%.",
        {"nhs": [
            "After 10 years, your risk of death from lung cancer will have halved "
            "compared with a smoker's."
        ]},
        {"nhs": citation},
        ["nhs"],
    )
    assert result.citations == [citation]


def test_response_may_use_supported_subset_of_long_statistical_claim():
    citation = _citation(
        "uspstf",
        "Bupropion SR was associated with abstinence at 6 months or more "
        "(19.0% vs 11.0%; RR 1.64, 95% CI 1.52-1.77).",
    )
    result = validate_citations(
        "Bupropion SR can improve abstinence at six months. About 19% remained "
        "abstinent compared with roughly 11% using placebo.",
        {"uspstf": [
            "Bupropion SR was associated with abstinence at 6 months or more "
            "(19.0% vs 11.0%; RR 1.64, 95% CI 1.52-1.77)."
        ]},
        {"uspstf": citation},
        ["uspstf"],
    )
    assert result.citations == [citation]


def test_medication_decision_requires_professional_escalation():
    query = "Can I drink alcohol while taking Champix?"
    assert requires_professional_escalation(query) is True
    assert "doctor or pharmacist" in professional_escalation_message(query)


def test_pregnancy_uses_specific_professional_escalation():
    message = professional_escalation_message(
        "Can I use nicotine replacement therapy while pregnant?"
    )
    assert message is not None
    assert "midwife" in message
