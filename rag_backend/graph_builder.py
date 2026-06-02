from langgraph.graph import StateGraph
from typing import TypedDict
import logging

from chains import (
    classify_all,
    generate_irrelevant_reply,
    generate_motivation,
    run_clarification_chain,
    run_fallback_chain,
    run_structured_rag_chain,
    refine_context_chain,
)

from config import ENABLE_WEB_SEARCH_FALLBACK
from memory import get_formatted_memory
from retriever import retrieve_documents
from web_search import web_search

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# === STATE === #
class GraphState(TypedDict):
    user_id: str
    input: str
    intent_classification: str
    emotion: str
    topic_relevance: str
    needs_clarification: bool
    response: str
    conversation_history: str
    raw_docs: list[str]
    refined_context: str
    knowledge_source: str
    retrieved_docs: list[str]


# === NODES === #
def conversation_history_node(state: GraphState) -> GraphState:
    logger.info("[conversation_history] Fetching conversation history...")
    history = get_formatted_memory(state["user_id"], limit=10)
    logger.info(f"Retrieved history: {history[:100]}...")
    return {**state, "conversation_history": history, "response": None}


def retrieve_node(state: GraphState) -> GraphState:
    logger.info("[retrieve_node]")
    if ENABLE_WEB_SEARCH_FALLBACK and state["knowledge_source"] == "web":
        docs = web_search(state["input"])
    else:
        docs = retrieve_documents(state["user_id"], state["input"])

    # Keep raw_docs as Documents so downstream (refine_context_chain,
    # format_docs) can read .page_content uniformly. Previously the internal
    # branch flattened to strings, which crashed the refiner — and erased the
    # source tags added by retrieve_documents.
    return {**state, "raw_docs": docs, "retrieved_docs": docs}



def context_refiner_node(state: GraphState) -> GraphState:
    logger.info("[context_refiner]")
    refined = refine_context_chain(state["raw_docs"], state["input"])
    return {**state, "refined_context": refined}


def structured_response_node(state: GraphState) -> GraphState:
    logger.info("[structured_response]")
    reply = run_structured_rag_chain(
        history=state["conversation_history"],
        context=state["refined_context"],
        question=state["input"],
        emotion=state["emotion"]
    )
    return {**state, "response": reply}


def fallback_response_node(state: GraphState) -> GraphState:
    logger.info("[fallback_response] Generating fallback emotional support answer...")
    reply = run_fallback_chain(history=state["conversation_history"], question=state["input"])
    logger.info(f"Fallback response: {reply}")
    return {**state, "response": reply}


def motivation_node(state: GraphState) -> GraphState:
    logger.info("[motivation] Checking if motivational boost is needed...")
    if state["emotion"] in [
        "sadness", "fear", "anxiety", "shame", "guilt", "frustration", "loneliness"
    ]:
        motivation = generate_motivation(
            state["input"],
            state["conversation_history"],
        )
        logger.info(f"Motivation added: {motivation}")
        return {**state, "response": state["response"] + "\n\n" + motivation}
    logger.info("No motivation needed.")
    return state


def classify_all_node(state: GraphState) -> GraphState:
    """Single LLM call that fills in clarification / topic / intent / emotion /
    knowledge_source. Replaces 4 sequential classifier nodes (~4× fewer Groq
    round-trips per turn)."""
    logger.info("[classify_all] Batched classification...")
    result = classify_all(state["input"])
    logger.info(f"Classifiers: {result}")
    return {
        **state,
        "needs_clarification": result["needs_clarification"],
        "topic_relevance": result["topic_relevance"],
        "intent_classification": result["intent"],
        "emotion": result["emotion"],
        "knowledge_source": result["knowledge_source"],
    }


def clarification_reply_node(state: GraphState) -> GraphState:
    logger.info("[clarification_reply] Generating clarification...")
    reply = run_clarification_chain(
        state["input"], state.get("conversation_history", "")
    )
    return {**state, "response": reply}


def irrelevant_reply_node(state: GraphState) -> GraphState:
    logger.info("[irrelevant_reply] Generating gentle redirect...")
    reply = generate_irrelevant_reply(state["input"])
    return {**state, "response": reply}


def output_node(state: GraphState) -> str:
    logger.info("[output] Final response ready.")
    logger.info(f"Final state: {state}")
    return state


# === GRAPH === #
# One classification call up front replaces the 4 sequential
# {clarification → topic → intent → emotion → knowledge_source} calls.
# Clarification / irrelevant short-circuits run a single reply chain. The
# common RAG path is now: classify_all → history → retrieve → refine →
# structured → motivation (4 LLM calls vs the old 6–7).
graph = StateGraph(GraphState)
graph.set_entry_point("classify_all_node")

graph.add_node("classify_all_node", classify_all_node)
graph.add_node("clarification_reply_node", clarification_reply_node)
graph.add_node("irrelevant_reply_node", irrelevant_reply_node)
graph.add_node("conversation_history_node", conversation_history_node)
graph.add_node("retrieve_node", retrieve_node)
graph.add_node("context_refiner_node", context_refiner_node)
graph.add_node("structured_response_node", structured_response_node)
graph.add_node("fallback_response_node", fallback_response_node)
graph.add_node("motivation_node", motivation_node)
graph.add_node("output_node", output_node)


def _route_after_classify(s: GraphState) -> str:
    if s["needs_clarification"]:
        return "clarification_reply_node"
    if s["topic_relevance"] == "irrelevant":
        return "irrelevant_reply_node"
    return "conversation_history_node"


graph.add_conditional_edges("classify_all_node", _route_after_classify)

graph.add_edge("clarification_reply_node", "output_node")
graph.add_edge("irrelevant_reply_node", "output_node")

graph.add_conditional_edges(
    "conversation_history_node",
    lambda s: "retrieve_node"
    if s["intent_classification"] == "use_rag"
    else "fallback_response_node",
)

graph.add_edge("retrieve_node", "context_refiner_node")
graph.add_edge("context_refiner_node", "structured_response_node")

graph.add_edge("structured_response_node", "motivation_node")
graph.add_edge("fallback_response_node", "motivation_node")
graph.add_edge("motivation_node", "output_node")

graph.set_finish_point("output_node")

# === COMPILE === #
rag_agent_executor = graph.compile()
