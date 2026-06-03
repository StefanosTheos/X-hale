import logging
from chromaClient import get_chroma_collection
from langchain.schema import Document

logger = logging.getLogger(__name__)

# Visible markers prepended to each retrieved chunk's page_content so the LLM
# downstream can tell trusted reference material apart from the user's own
# earlier messages. CONTEXT_REFINER_PROMPT is taught to weight these.
_KB_TAG = "[KNOWLEDGE BASE]"
_HIST_TAG = "[USER PRIOR MESSAGE — not an authoritative source]"


def retrieve_documents(user_id: str, query: str, k: int = 3):
    kb = get_chroma_collection("knowledge_base")
    history = get_chroma_collection("chat_history")

    kb_docs = kb.similarity_search(query, k=k)
    hist_docs = history.similarity_search(query, k=1, filter={"user_id": user_id})

    tagged_docs = [
        Document(
            page_content=f"{_KB_TAG}\n{doc.page_content}",
            metadata={**doc.metadata, "source_type": "knowledge_base"},
        )
        for doc in kb_docs
    ] + [
        Document(
            page_content=f"{_HIST_TAG}\n{doc.page_content}",
            metadata={**doc.metadata, "source_type": "chat_history"},
        )
        for doc in hist_docs
    ]

    logger.info("Retrieved %d documents (kb=%d, history=%d)",
                len(tagged_docs), len(kb_docs), len(hist_docs))
    for doc in tagged_docs:
        logger.debug("- content: %s...", doc.page_content[:100])
        logger.debug("  metadata: %s", doc.metadata)

    return tagged_docs
    
def retrieve_chat_history(user_id: str, limit: int = 10) -> list[dict]:
    collection = get_chroma_collection("chat_history")
    items = collection.get(where={"user_id": user_id}, include=['metadatas', 'documents'])

    filtered = [
        {
            "timestamp": meta["timestamp"],
            "content": doc,
            "role": meta.get("role", "user")
        }
        for doc, meta in zip(items["documents"], items["metadatas"])
    ]

    sorted_items = sorted(filtered, key=lambda x: x["timestamp"], reverse=True)
    return sorted_items[:limit][::-1]  # reverse to oldest-first order

