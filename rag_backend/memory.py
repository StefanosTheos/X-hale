import logging

from chromaClient import get_chroma_collection
from datetime import datetime, timezone
from retriever import retrieve_chat_history

logger = logging.getLogger(__name__)


def append_to_history(user_id: str, role: str, text: str):
    collection = get_chroma_collection("chat_history")
    now = datetime.now(timezone.utc).isoformat()
    logger.debug(
        "Saving message: %s (user_id=%s, role=%s, timestamp=%s)",
        text,
        user_id,
        role,
        now,
    )
    collection.add_texts(
        [text],
        metadatas=[{
            "user_id": user_id,
            "timestamp": now,
            "role": role
        }]
    )

def load_user_history(user_id: str, k: int = 3):
    """Return the user's most recent k turns joined oldest-to-newest as a
    single string, capped at ~1000 tokens.

    Previously this ran a vector similarity search against the literal seed
    "recent messages", which is meaningless — the embedding of that phrase
    has no relationship to chat-history ordering. Use a chronological fetch
    instead.
    """
    items = load_user_history_as_list(user_id, k=k)

    history = []
    token_count = 0
    for item in items:
        content = item["content"]
        words = content.split()
        if token_count + len(words) > 1000:
            break
        history.append(content)
        token_count += len(words)

    return "\n".join(history)

def load_user_history_as_list(user_id: str, k: int = 20):
    return retrieve_chat_history(user_id, limit=k)

def delete_user_history(user_id: str):
    collection = get_chroma_collection("chat_history")
    deleted = collection.delete(where={"user_id": user_id})
    logger.info("Deleted history for user %s", user_id)
    return deleted

def get_formatted_memory(user_id: str, limit: int = 10) -> str:
    history = retrieve_chat_history(user_id, limit=limit)
    formatted = []
    for h in history:
        role = "User" if h["role"] == "user" else "Hailey"
        formatted.append(f"{role}: {h['content'].strip()}")
    return "\n".join(formatted)