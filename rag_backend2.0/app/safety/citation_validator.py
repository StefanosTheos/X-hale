"""Deterministic claim-level validation for citations exposed to clients."""
from __future__ import annotations

import re
from dataclasses import dataclass

from app.models.retrieval import Citation

_TOKEN_RE = re.compile(r"[a-z0-9]+")
_NUMBER_RE = re.compile(r"\b\d+(?:\.\d+)?\b")
_SENTENCE_RE = re.compile(r"(?<=[.!?])\s+|\n+")
_NEGATION_RE = re.compile(r"\b(?:not|no|never|neither|nor|without|cannot|can't|won't)\b", re.IGNORECASE)
_STOPWORDS = frozenset({
    "a", "an", "and", "are", "as", "at", "be", "been", "being", "but", "by",
    "can", "could", "for", "from", "has", "have", "in", "into", "is", "it",
    "its", "may", "of", "on", "or", "that", "the", "their", "then", "there",
    "these", "this", "to", "was", "were", "will", "with", "you", "your",
})
_SYNONYMS = {
    "nonsmoker": "non-smoker", "nonsmokers": "non-smoker",
    "decrease": "drop", "decreases": "drop", "decreased": "drop",
    "reduce": "drop", "reduces": "drop", "reduced": "drop",
    "improve": "better", "improves": "better", "improved": "better",
    "circulation": "bloodflow", "blood": "blood", "flow": "bloodflow",
    "weeks": "week", "months": "month", "years": "year", "hours": "hour",
}


@dataclass(frozen=True)
class CitationValidation:
    citations: list[Citation]
    supported_source_ids: set[str]
    represented_claims: int
    sourced_claims: int
    rejection_reasons: dict[str, list[str]]


def _normalise_token(token: str) -> str:
    """Apply small, predictable suffix normalisation without external NLP models."""
    normalized = token
    if len(token) > 5 and token.endswith("ing"):
        normalized = token[:-3]
    elif len(token) > 4 and token.endswith("ed"):
        normalized = token[:-2]
    elif len(token) > 4 and token.endswith("s"):
        normalized = token[:-1]
    return _SYNONYMS.get(normalized, normalized)


def _content_tokens(text: str) -> set[str]:
    return {
        _normalise_token(token)
        for token in _TOKEN_RE.findall(text.lower())
        if token not in _STOPWORDS and len(token) > 1
    }


def claim_is_represented(claim: str, response: str) -> bool:
    """Return whether response materially represents a source-attributed claim."""
    claim_tokens = _content_tokens(claim)
    if not claim_tokens:
        return False
    claim_numbers = set(_NUMBER_RE.findall(claim))
    claim_has_negation = bool(_NEGATION_RE.search(claim))
    required_overlap = 0.5 if len(claim_tokens) <= 4 else 0.4
    for sentence in _SENTENCE_RE.split(response):
        response_tokens = _content_tokens(sentence)
        overlap = len(claim_tokens & response_tokens) / len(claim_tokens)
        if overlap < required_overlap:
            continue
        # Numeric claims must retain their source's numbers; otherwise a similar
        # sentence could cite evidence for a different dose or timeline.
        if claim_numbers and not claim_numbers.issubset(set(_NUMBER_RE.findall(sentence))):
            continue
        if claim_has_negation != bool(_NEGATION_RE.search(sentence)):
            continue
        return True
    return False


def validate_citations(
    response: str,
    source_claims: dict[str, list[str]],
    citation_by_id: dict[str, Citation],
    declared_source_ids: list[str],
) -> CitationValidation:
    """Expose only retrieved sources with claims represented in the final answer.

    Declared citation markers are treated as model hints, not proof. When markers
    are absent, represented source-backed claims are still covered automatically;
    unrelated retrieved sources are never attached.
    """
    represented: set[str] = set()
    rejection_reasons: dict[str, list[str]] = {}
    represented_claims = 0
    sourced_claims = 0
    for source_id, claims in source_claims.items():
        sourced_claims += len(claims)
        citation = citation_by_id.get(source_id)
        if citation is None:
            rejection_reasons.setdefault(source_id, []).append("missing_citation_metadata")
            continue
        if not citation.snippet.strip():
            rejection_reasons.setdefault(source_id, []).append("empty_source_snippet")
            continue
        for claim in claims:
            source_supports_claim = claim_is_represented(claim, citation.snippet)
            response_represents_claim = claim_is_represented(claim, response)
            if source_supports_claim and response_represents_claim:
                represented.add(source_id)
                represented_claims += 1
            elif not source_supports_claim:
                rejection_reasons.setdefault(source_id, []).append("claim_not_entailed_by_source")
            elif not response_represents_claim:
                rejection_reasons.setdefault(source_id, []).append("claim_not_present_in_response")

    # Direct evidence alignment is the primary path: a final-answer sentence may
    # be supported by a retrieved passage even when the specialist paraphrased or
    # omitted an intermediate key point. Numeric and negation safeguards remain
    # enforced by claim_is_represented().
    response_sentences = [
        sentence.strip() for sentence in _SENTENCE_RE.split(response)
        if len(_content_tokens(sentence)) >= 3
    ]
    for source_id, citation in citation_by_id.items():
        if source_id in represented or not citation.snippet.strip():
            continue
        for sentence in response_sentences:
            if claim_is_represented(sentence, citation.snippet):
                represented.add(source_id)
                represented_claims += 1
                rejection_reasons.pop(source_id, None)
                break

    ordered_ids = list(dict.fromkeys(
        declared_source_ids + list(source_claims) + list(citation_by_id)
    ))
    # A declared ID still needs entailment. Claim matching also supplies coverage
    # when markers are absent or incomplete.
    eligible = represented & set(citation_by_id)
    citations = [citation_by_id[sid] for sid in ordered_ids if sid in eligible]
    for source_id in declared_source_ids:
        if source_id not in citation_by_id:
            rejection_reasons.setdefault(source_id, []).append("source_not_retrieved")
    for source_id in citation_by_id:
        if source_id not in source_claims and source_id not in represented:
            rejection_reasons.setdefault(source_id, []).append(
                "no_specialist_claim_attributed"
            )
    return CitationValidation(
        citations, represented, represented_claims, sourced_claims, rejection_reasons,
    )
