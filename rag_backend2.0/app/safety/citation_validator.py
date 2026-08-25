"""Deterministic claim-level validation for citations exposed to clients."""
from __future__ import annotations

import re
from dataclasses import dataclass

from app.models.retrieval import Citation

_TOKEN_RE = re.compile(r"[a-z0-9]+")
_NUMBER_RE = re.compile(r"\b\d+(?:\.\d+)?\b")
_SENTENCE_RE = re.compile(r"(?<=[.!?])\s+|\n+")
_NEGATION_RE = re.compile(
    r"\b(?:not|no|never|neither|nor|without|cannot|can['’]t|won['’]t|"
    r"hasn['’]t|haven['’]t|hadn['’]t|isn['’]t|aren['’]t|doesn['’]t|didn['’]t)\b",
    re.IGNORECASE,
)
_REFERENCE_MARKER_RE = re.compile(r"\(\s*\d{1,3}\s*\)")
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
    "dying": "death", "chance": "risk", "chances": "risk",
    "half": "50", "halved": "50", "decade": "10",
    "abstinent": "abstinence",
    "inconclusive": "unclear", "mixed": "unclear",
    "study": "evidence", "studies": "evidence", "research": "evidence",
    "therapy": "aid", "therapies": "aid",
    "hypnosis": "hypnotherapy",
    "shown": "demonstrate", "found": "demonstrate", "show": "demonstrate",
    "help": "increase", "helps": "increase", "helped": "increase",
    "rates": "rate",
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
    text = _REFERENCE_MARKER_RE.sub("", text)
    return {
        _normalise_token(token)
        for token in _TOKEN_RE.findall(text.lower())
        if token not in _STOPWORDS and len(token) > 1
    }


def _numbers(text: str) -> set[str]:
    """Return canonical numeric values so 19 and 19.0 compare equally."""
    text = _REFERENCE_MARKER_RE.sub("", text)
    values: set[str] = set()
    for raw in _NUMBER_RE.findall(text):
        try:
            values.add(f"{float(raw):g}")
        except ValueError:
            values.add(raw)
    lowered = text.casefold()
    if re.search(r"\b(?:half|halved)\b", lowered):
        values.add("50")
    if re.search(r"\b(?:a|one) decade\b|\bdecade\b", lowered):
        values.add("10")
    return values


def _comparison_windows(text: str) -> list[str]:
    """Use adjacent sentences because scraped passages often split a timeline heading."""
    sentences = [part.strip() for part in _SENTENCE_RE.split(text) if part.strip()]
    windows = list(sentences)
    windows.extend(
        f"{sentences[index]} {sentences[index + 1]}"
        for index in range(len(sentences) - 1)
    )
    return windows or [text]


def claim_is_represented(
    claim: str,
    response: str,
    *,
    allow_partial_numeric_claim: bool = False,
) -> bool:
    """Return whether response materially represents a source-attributed claim."""
    claim_tokens = _content_tokens(claim)
    if not claim_tokens:
        return False
    claim_numbers = _numbers(claim)
    claim_has_negation = bool(_NEGATION_RE.search(claim))
    required_overlap = 0.5 if len(claim_tokens) <= 4 else 0.4
    for sentence in _comparison_windows(response):
        response_tokens = _content_tokens(sentence)
        overlap = len(claim_tokens & response_tokens) / len(claim_tokens)
        minimum_overlap = 0.3 if allow_partial_numeric_claim and claim_numbers else required_overlap
        if overlap < minimum_overlap:
            continue
        # Numeric claims must retain their source's numbers; otherwise a similar
        # sentence could cite evidence for a different dose or timeline.
        response_numbers = _numbers(sentence)
        if claim_numbers:
            if allow_partial_numeric_claim:
                # A generated sentence may accurately represent a bounded part
                # of a long evidence statement (for example, abstinence rates
                # without also repeating its RR and confidence interval). It
                # must never introduce a number absent from the source claim.
                if response_numbers and not response_numbers.issubset(claim_numbers):
                    continue
                if not response_numbers and overlap < 0.6:
                    continue
            elif not claim_numbers.issubset(response_numbers):
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
            response_represents_claim = claim_is_represented(
                claim, response, allow_partial_numeric_claim=True,
            )
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
        # Broad topical similarity is not claim-level evidence. Only repair
        # alignment for sources explicitly attributed by the medical specialist.
        if source_id not in source_claims:
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
