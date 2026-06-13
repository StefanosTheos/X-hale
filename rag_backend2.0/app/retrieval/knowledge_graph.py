"""
Quit-smoking domain knowledge graph.

Loads ingestion/knowledge_graph.yaml into an in-process NetworkX DiGraph at
startup. Provides expand_entities() which, given a list of matched node IDs,
returns the union of topic_tags reachable within `hops` steps. Those tags are
then used as OR filters on a second Qdrant vector search in hybrid_retriever.

Design notes:
- Graph is loaded once at module import via a module-level singleton.
- Traversal uses BFS over the undirected projection of the DiGraph so that
  relationships work in both directions (e.g. "symptom caused_by withdrawal"
  also expands from withdrawal back to related symptoms).
- networkx and pyyaml must be installed (both are in the main dependencies).
"""
from __future__ import annotations

from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Optional

import networkx as nx
import yaml

from app.observability.logging import get_logger

logger = get_logger(__name__)

_YAML_PATH = Path(__file__).parent.parent.parent / "ingestion" / "knowledge_graph.yaml"


@dataclass
class GraphExpansionResult:
    """Return value from expand_entities()."""
    seed_node_ids: list[str] = field(default_factory=list)
    related_node_ids: list[str] = field(default_factory=list)
    topic_tags: list[str] = field(default_factory=list)

    def is_empty(self) -> bool:
        return not self.topic_tags


@lru_cache(maxsize=1)
def load_graph() -> nx.DiGraph:
    """
    Parse knowledge_graph.yaml and return a NetworkX DiGraph.
    Cached after first call — the graph never changes at runtime.
    """
    if not _YAML_PATH.exists():
        logger.warning("kg_yaml_not_found", path=str(_YAML_PATH))
        return nx.DiGraph()

    with _YAML_PATH.open(encoding="utf-8") as f:
        data = yaml.safe_load(f)

    G = nx.DiGraph()

    for node in data.get("nodes", []):
        G.add_node(
            node["id"],
            type=node.get("type", ""),
            label=node.get("label", node["id"]),
            aliases=node.get("aliases", []),
            topic_tags=node.get("topic_tags", []),
        )

    for edge in data.get("edges", []):
        src = edge.get("from")
        dst = edge.get("to")
        if src and dst and G.has_node(src) and G.has_node(dst):
            G.add_edge(src, dst, relation=edge.get("relation", "related"))

    logger.info(
        "kg_loaded",
        nodes=G.number_of_nodes(),
        edges=G.number_of_edges(),
    )
    return G


def expand_entities(entity_ids: list[str], hops: int = 2) -> GraphExpansionResult:
    """
    BFS-expand from seed entity IDs up to `hops` steps on the undirected graph.

    Returns a GraphExpansionResult containing all reachable node IDs and the
    union of their topic_tags. Returns an empty result if the graph is not
    loaded or no valid seeds are provided.
    """
    if not entity_ids:
        return GraphExpansionResult()

    G = load_graph()
    if G.number_of_nodes() == 0:
        return GraphExpansionResult()

    valid_seeds = [nid for nid in entity_ids if G.has_node(nid)]
    if not valid_seeds:
        logger.debug("kg_expand_no_valid_seeds", requested=entity_ids)
        return GraphExpansionResult(seed_node_ids=entity_ids)

    # Traverse the undirected projection so edges fire in both directions
    undirected = G.to_undirected()
    visited: set[str] = set()

    frontier = set(valid_seeds)
    for _ in range(hops):
        next_frontier: set[str] = set()
        for node in frontier:
            for neighbour in undirected.neighbors(node):
                if neighbour not in visited and neighbour not in frontier:
                    next_frontier.add(neighbour)
        visited.update(frontier)
        frontier = next_frontier

    visited.update(frontier)  # include the final hop

    # Collect unique topic_tags from all visited nodes (seeds + reachable)
    all_nodes = set(valid_seeds) | visited
    tags: set[str] = set()
    for nid in all_nodes:
        tags.update(G.nodes[nid].get("topic_tags", []))

    logger.debug(
        "kg_expand_complete",
        seeds=valid_seeds,
        reachable=len(all_nodes),
        tags=sorted(tags),
    )

    return GraphExpansionResult(
        seed_node_ids=valid_seeds,
        related_node_ids=sorted(all_nodes - set(valid_seeds)),
        topic_tags=sorted(tags),
    )
