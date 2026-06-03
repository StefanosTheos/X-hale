import logging

from langchain_core.output_parsers import StrOutputParser, JsonOutputParser
from config import llm

logger = logging.getLogger(__name__)
from prompt_templates import (
    FALLBACK_PROMPT,
    CLARIFICATION_PROMPT,
    IRRELEVANT_TOPIC_PROMPT,
    MOTIVATION_PROMPT,
    STRUCTURED_RAG_PROMPT,
    CONTEXT_REFINER_PROMPT,
    CLASSIFIERS_PROMPT,
)

parser = StrOutputParser()

clarification_chain = CLARIFICATION_PROMPT | llm | parser
irrelevant_topic_chain = IRRELEVANT_TOPIC_PROMPT | llm | parser
generate_motivation_chain = MOTIVATION_PROMPT | llm | parser
fallback_chain = FALLBACK_PROMPT | llm | parser
structured_rag_chain = STRUCTURED_RAG_PROMPT | llm | parser
context_refiner_chain = CONTEXT_REFINER_PROMPT | llm | parser
classify_all_chain = CLASSIFIERS_PROMPT | llm | JsonOutputParser()


def classify_all(input: str) -> dict:
    """One LLM call that returns needs_clarification / topic_relevance / intent
    / emotion / knowledge_source. Replaces 4–5 individual classifier calls.

    Returns a dict with safe defaults if parsing fails so the graph can keep
    running rather than 500-ing on a malformed JSON response.
    """
    try:
        result = classify_all_chain.invoke({"input": input})
        if not isinstance(result, dict):
            raise ValueError(f"expected dict from JsonOutputParser, got {type(result)}")
        return {
            "needs_clarification": bool(result.get("needs_clarification", False)),
            "topic_relevance": result.get("topic_relevance", "relevant"),
            "intent": result.get("intent", "use_fallback"),
            "emotion": result.get("emotion", "neutral"),
            "knowledge_source": result.get("knowledge_source", "internal"),
        }
    except Exception as e:
        logger.warning("classify_all failed, using safe defaults: %s", e)
        return {
            "needs_clarification": False,
            "topic_relevance": "relevant",
            "intent": "use_fallback",
            "emotion": "neutral",
            "knowledge_source": "internal",
        }

# === Clarification ===
def run_clarification_chain(input_text: str, history: str = "") -> str:
    return clarification_chain.invoke({"input": input_text, "history": history})

# === Irrelevant topic fallback ===
def generate_irrelevant_reply(input: str) -> str:
    return irrelevant_topic_chain.invoke({"input": input}).strip()

# === Motivation ===
def generate_motivation(input: str, history: str) -> str:
    return generate_motivation_chain.invoke({
        "history": history,
        "input": input,
    }).strip()

# === Fallback response ===
def run_fallback_chain(history: str, question: str) -> str:
    return fallback_chain.invoke({"history": history, "question": question})


def refine_context_chain(docs, question: str) -> str:
    return context_refiner_chain.invoke({
        "documents": "\n\n".join(d.page_content for d in docs),
        "question": question
    }).strip()


def run_structured_rag_chain(history: str, context: str, question: str, emotion: str) -> str:
    return structured_rag_chain.invoke({
        "history": history,
        "context": context,
        "question": question,
        "emotion": emotion
    }).strip()


