"""Claim entailment and citation coverage checks."""
from app.models.retrieval import Citation
from app.safety.citation_validator import claim_is_represented, validate_citations


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


def test_final_claim_matching_hallucinated_key_point_is_not_cited():
    result = validate_citations(
        "Recovery takes exactly 90 years.",
        {"nhs": ["Recovery takes exactly 90 years."]},
        {"nhs": _citation("nhs", "Recovery begins within several weeks.")},
        ["nhs"],
    )

    assert result.citations == []
