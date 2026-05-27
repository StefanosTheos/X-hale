"""
Conditional-edge functions for the LangGraph StateGraph.

Each function receives the current HaileyState and returns the name of the
next node (or END). These are the routing decisions for the graph.
"""
from __future__ import annotations

from langgraph.graph import END

from app.graph.state import HaileyState
from app.observability.logging import get_logger

logger = get_logger(__name__)


def route_after_triage(state: HaileyState) -> str:
    """
    After triage, decide the primary routing path.

    Paths:
      - crisis     → crisis_handler_node
      - clarify    → clarification_node
      - irrelevant → irrelevant_node
      - normal     → context_loader_node (loads user memory, then supervisor)
    """
    triage = state.get("triage")
    if not triage:
        logger.warning("route_after_triage_no_triage_result")
        return "context_loader_node"

    if triage.crisis_flag or state.get("is_crisis"):
        return "crisis_handler_node"

    if triage.topic_relevance == "irrelevant":
        return "irrelevant_node"

    if triage.intent == "needs_clarification":
        return "clarification_node"

    return "context_loader_node"


def route_after_supervisor(state: HaileyState) -> list[str]:
    """
    After the supervisor decides which specialists to invoke,
    return the list of specialist node names for fan-out.
    If no specialists, go directly to synthesizer.
    """
    specialists = state.get("requested_specialists", [])
    if not specialists:
        return ["synthesizer_node"]
    # Map specialist names to node names
    node_names = [f"{s}_node" for s in specialists]
    return node_names


def route_after_specialists(state: HaileyState) -> str:
    """After all specialists have run, always go to synthesizer."""
    return "synthesizer_node"


def route_after_synthesizer(state: HaileyState) -> str:
    """After synthesis, always go to output_node."""
    return "output_node"
