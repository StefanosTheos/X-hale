"""
Keyword-based entity extractor for knowledge graph seeding.

Scans the user query against every node's aliases in the knowledge graph and
returns matching node IDs. No ML dependencies — pure string matching, <1 ms.

Matching rules:
- All comparisons are case-insensitive.
- Multi-word aliases use substring matching (e.g. "can't sleep" in a longer sentence).
- Single-word aliases (len == 1 token) use whole-word boundary matching to avoid
  false positives (e.g. "nrt" should not match "smart").
- Longer aliases are preferred: when multiple aliases match the same span, the
  node with the longest matching alias is ranked highest.
- Duplicate node IDs are deduplicated; order reflects match confidence (longest first).
"""
from __future__ import annotations

import re
from functools import lru_cache

from app.observability.logging import get_logger

logger = get_logger(__name__)

# Pre-compiled word-boundary pattern cache
@lru_cache(maxsize=512)
def _word_boundary_pattern(alias: str) -> re.Pattern:
    return re.compile(r"\b" + re.escape(alias) + r"\b", re.IGNORECASE)


def extract_entities(query: str, max_entities: int = 8) -> list[str]:
    """
    Return up to `max_entities` node IDs whose aliases match the query.

    The result is ordered by descending alias length (specificity) so that
    expand_entities() seeds from the most precise matches first.

    Args:
        query: Raw user message text.
        max_entities: Cap on returned node IDs to keep BFS bounded.

    Returns:
        List of node IDs (may be empty if no aliases match).
    """
    from app.retrieval.knowledge_graph import load_graph  # lazy import avoids circular

    G = load_graph()
    if G.number_of_nodes() == 0:
        return []

    q_lower = query.lower()
    matches: list[tuple[int, str]] = []  # (alias_length, node_id)

    for node_id, attrs in G.nodes(data=True):
        for alias in attrs.get("aliases", []):
            alias_lower = alias.lower()
            tokens = alias_lower.split()

            if len(tokens) == 1:
                # Single word: require whole-word boundary
                if _word_boundary_pattern(alias_lower).search(q_lower):
                    matches.append((len(alias_lower), node_id))
                    break  # one alias match per node is enough
            else:
                # Multi-word: substring is fine
                if alias_lower in q_lower:
                    matches.append((len(alias_lower), node_id))
                    break

    # Sort by alias length descending (longer = more specific)
    matches.sort(key=lambda x: x[0], reverse=True)

    # Deduplicate while preserving order
    seen: set[str] = set()
    result: list[str] = []
    for _, node_id in matches:
        if node_id not in seen:
            seen.add(node_id)
            result.append(node_id)
        if len(result) >= max_entities:
            break

    if result:
        logger.debug("entity_extractor_matched", query_snippet=query[:60], entities=result)

    return result
