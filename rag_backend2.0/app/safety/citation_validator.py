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


@dataclass(frozen=True)
class CitationValidation:
    citations: list[Citation]
    supported_source_ids: set[str]
    represented_claims: int
    sourced_claims: int


def _normalise_token(token: str) -> str:
    """Apply small, predictable suffix normalisation without external NLP models."""
    if len(token) > 5 and token.endswith("ing"):
        return token[:-3]
    if len(token) > 4 and token.endswith("ed"):
        return token[:-2]
    if len(token) > 4 and token.endswith("s"):
        return token[:-1]
    return token


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
    represented_claims = 0
    sourced_claims = 0
    for source_id, claims in source_claims.items():
        sourced_claims += len(claims)
        citation = citation_by_id.get(source_id)
        if citation is None or not citation.snippet.strip():
            continue
        for claim in claims:
            source_supports_claim = claim_is_represented(claim, citation.snippet)
            if source_supports_claim and claim_is_represented(claim, response):
                represented.add(source_id)
                represented_claims += 1

    ordered_ids = list(dict.fromkeys(declared_source_ids + list(source_claims)))
    # A declared ID still needs entailment. Claim matching also supplies coverage
    # when markers are absent or incomplete.
    eligible = represented & set(citation_by_id)
    citations = [citation_by_id[sid] for sid in ordered_ids if sid in eligible]
    return CitationValidation(citations, represented, represented_claims, sourced_claims)
