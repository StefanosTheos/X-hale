"""
LangGraph StateGraph compilation.

Builds and compiles the Hailey agent graph. Returns a single
`compiled_graph` singleton used by the /chat router.

Node inventory:
  triage_node           → runs TriageAgent, sets state.triage
  context_loader_node   → loads UserMemorySnapshot into state.user_memory
  supervisor_node       → sets state.requested_specialists
  medical_node          → runs MedicalAgent, adds to state.specialist_drafts
  craving_support_node  → runs CravingSupportAgent
  emotional_support_node→ runs EmotionalSupportAgent
  reflection_node       → stub (Phase 3)
  relapse_risk_node     → stub (Phase 3)
  synthesizer_node      → runs Synthesizer, sets state.final_response
  output_node           → saves turn to Appwrite, fires memory curator
  crisis_handler_node   → deterministic crisis path, sets state.final_response
  clarification_node    → returns a clarification question, sets state.final_response
  irrelevant_node       → returns a polite redirect, sets state.final_response
"""
from __future__ import annotations

import asyncio
import json
import uuid
from functools import lru_cache

from langgraph.graph import END, START, StateGraph

from app.graph.routing import route_after_triage, route_after_supervisor
from app.graph.state import HaileyState
from app.observability.logging import get_logger

logger = get_logger(__name__)


# ── Node implementations ──────────────────────────────────────────────────────

async def triage_node(state: HaileyState) -> HaileyState:
    from app.agents.triage import run_triage
    triage = await run_triage(state["user_input"])
    return {**state, "triage": triage}


async def context_loader_node(state: HaileyState) -> HaileyState:
    from app.memory.snapshot import build_snapshot
    memory = await build_snapshot(state["user_id"])
    return {**state, "user_memory": memory}


async def supervisor_node(state: HaileyState) -> HaileyState:
    from app.agents.supervisor import decide_specialists
    specialists = decide_specialists(
        triage=state["triage"],
        memory=state.get("user_memory"),
    )
    return {**state, "requested_specialists": specialists}


async def medical_node(state: HaileyState) -> HaileyState:
    from app.agents.medical import MedicalAgent
    draft = await MedicalAgent().run(state)
    drafts = dict(state.get("specialist_drafts") or {})
    drafts["medical"] = draft.model_dump()
    return {**state, "specialist_drafts": drafts}


async def craving_support_node(state: HaileyState) -> HaileyState:
    from app.agents.craving_support import CravingSupportAgent
    draft = await CravingSupportAgent().run(state)
    drafts = dict(state.get("specialist_drafts") or {})
    drafts["craving_support"] = draft.model_dump()
    return {**state, "specialist_drafts": drafts}


async def emotional_support_node(state: HaileyState) -> HaileyState:
    from app.agents.emotional_support import EmotionalSupportAgent
    draft = await EmotionalSupportAgent().run(state)
    drafts = dict(state.get("specialist_drafts") or {})
    drafts["emotional_support"] = draft.model_dump()
    return {**state, "specialist_drafts": drafts}


async def reflection_node(state: HaileyState) -> HaileyState:
    from app.agents.reflection import ReflectionAgent
    draft = await ReflectionAgent().run(state)
    drafts = dict(state.get("specialist_drafts") or {})
    drafts["reflection"] = draft.model_dump()
    return {**state, "specialist_drafts": drafts}


async def relapse_risk_node(state: HaileyState) -> HaileyState:
    from app.agents.relapse_risk import RelapseRiskAgent
    draft = await RelapseRiskAgent().run(state)
    drafts = dict(state.get("specialist_drafts") or {})
    drafts["relapse_risk"] = draft.model_dump()
    return {**state, "specialist_drafts": drafts}


async def synthesizer_node(state: HaileyState) -> HaileyState:
    from app.agents.synthesizer import synthesize
    text, citations = await synthesize(state)
    # Collect deeplinks from all specialist drafts
    deeplinks = []
    for draft_data in (state.get("specialist_drafts") or {}).values():
        if isinstance(draft_data, dict):
            for dl in draft_data.get("suggested_deeplinks", []):
                deeplinks.append(dl)
    return {**state, "final_response": text, "citations": citations, "deeplinks": deeplinks}


async def output_node(state: HaileyState) -> HaileyState:
    """Save the completed turn to Appwrite and fire the memory curator async."""
    from app.memory.conversation_store import append_turn
    user_id = state["user_id"]
    user_input = state["user_input"]
    final_response = state.get("final_response", "")
    citations = state.get("citations", [])
    turn_id = state.get("turn_id") or str(uuid.uuid4())

    # Save user message
    await append_turn(
        user_id=user_id,
        role="user",
        content=user_input,
        turn_id=turn_id + "_user",
    )
    # Save Hailey's reply
    await append_turn(
        user_id=user_id,
        role="assistant",
        content=final_response,
        citations=[c.model_dump() if hasattr(c, "model_dump") else c for c in citations],
        turn_id=turn_id,
    )

    # Fire-and-forget memory curation — skip for casual turns (nothing to extract)
    intent = state.get("triage").intent if state.get("triage") else "unknown"
    if intent not in ("off_topic", "unknown"):
        from app.agents.memory_curator import curate_memory
        asyncio.ensure_future(curate_memory(user_id, user_input, final_response, turn_id))

    return {**state, "turn_id": turn_id}


async def crisis_handler_node(state: HaileyState) -> HaileyState:
    from app.agents.crisis_handler import handle_crisis
    message, _ = await handle_crisis(
        user_id=state["user_id"],
        locale=state.get("locale", "en"),
    )
    return {**state, "final_response": message, "is_crisis": True, "citations": [], "deeplinks": []}


async def clarification_node(state: HaileyState) -> HaileyState:
    response = "I want to make sure I understand what you're asking — could you tell me a bit more?"
    return {**state, "final_response": response, "citations": [], "deeplinks": []}


async def irrelevant_node(state: HaileyState) -> HaileyState:
    response = (
        "That's a bit outside what I can help with — I'm here to support your quit journey. "
        "Is there something about quitting smoking, cravings, or how you're feeling that I can help with?"
    )
    return {**state, "final_response": response, "citations": [], "deeplinks": []}


# ── Graph assembly ────────────────────────────────────────────────────────────

def _build_graph(*, stop_before_synthesis: bool = False) -> StateGraph:
    g = StateGraph(HaileyState)

    # Add all nodes
    g.add_node("triage_node", triage_node)
    g.add_node("context_loader_node", context_loader_node)
    g.add_node("supervisor_node", supervisor_node)
    g.add_node("medical_node", medical_node)
    g.add_node("craving_support_node", craving_support_node)
    g.add_node("emotional_support_node", emotional_support_node)
    g.add_node("reflection_node", reflection_node)
    g.add_node("relapse_risk_node", relapse_risk_node)
    if not stop_before_synthesis:
        g.add_node("synthesizer_node", synthesizer_node)
        g.add_node("output_node", output_node)
    g.add_node("crisis_handler_node", crisis_handler_node)
    g.add_node("clarification_node", clarification_node)
    g.add_node("irrelevant_node", irrelevant_node)

    # Entry point
    g.add_edge(START, "triage_node")

    # After triage: conditional routing
    g.add_conditional_edges(
        "triage_node",
        route_after_triage,
        {
            "crisis_handler_node": "crisis_handler_node",
            "clarification_node": "clarification_node",
            "irrelevant_node": "irrelevant_node",
            "context_loader_node": "context_loader_node",
        },
    )

    # Context → Supervisor
    g.add_edge("context_loader_node", "supervisor_node")

    # Supervisor → specialists (conditional fan-out)
    # We use a simpler sequential approach: supervisor sets the list,
    # and we route to each specialist one at a time via a dispatcher node.
    synthesis_target = END if stop_before_synthesis else "synthesizer_node"

    g.add_conditional_edges(
        "supervisor_node",
        _specialist_dispatcher,
        {
            "medical_node": "medical_node",
            "craving_support_node": "craving_support_node",
            "emotional_support_node": "emotional_support_node",
            "reflection_node": "reflection_node",
            "relapse_risk_node": "relapse_risk_node",
            "synthesizer_node": synthesis_target,
        },
    )

    # Each specialist feeds back into a collector that checks if more specialists remain
    for specialist_node in [
        "medical_node", "craving_support_node", "emotional_support_node",
        "reflection_node", "relapse_risk_node",
    ]:
        g.add_conditional_edges(
            specialist_node,
            _next_specialist_or_synthesizer,
            {
                "medical_node": "medical_node",
                "craving_support_node": "craving_support_node",
                "emotional_support_node": "emotional_support_node",
                "reflection_node": "reflection_node",
                "relapse_risk_node": "relapse_risk_node",
                "synthesizer_node": synthesis_target,
            },
        )

    # Terminal paths
    if stop_before_synthesis:
        g.add_edge("crisis_handler_node", END)
        g.add_edge("clarification_node", END)
        g.add_edge("irrelevant_node", END)
    else:
        g.add_edge("synthesizer_node", "output_node")
        g.add_edge("output_node", END)
        g.add_edge("crisis_handler_node", "output_node")
        g.add_edge("clarification_node", "output_node")
        g.add_edge("irrelevant_node", "output_node")

    return g


def _specialist_dispatcher(state: HaileyState) -> str:
    """Route to the first requested specialist, or directly to synthesizer."""
    specialists = state.get("requested_specialists", [])
    completed = set(state.get("specialist_drafts", {}).keys())
    for s in specialists:
        if s not in completed:
            return f"{s}_node"
    return "synthesizer_node"


def _next_specialist_or_synthesizer(state: HaileyState) -> str:
    """After one specialist completes, route to the next pending one or synthesizer."""
    return _specialist_dispatcher(state)


@lru_cache(maxsize=1)
def get_compiled_graph():
    """Return the compiled LangGraph graph. Compiled once at startup."""
    logger.info("compiling_langgraph")
    graph = _build_graph()
    return graph.compile()


@lru_cache(maxsize=1)
def get_compiled_preparation_graph():
    """Return the graph that prepares a turn and stops before synthesis/persistence."""
    logger.info("compiling_langgraph_preparation")
    return _build_graph(stop_before_synthesis=True).compile()
