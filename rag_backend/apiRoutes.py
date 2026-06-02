import logging

from pydantic import BaseModel
from fastapi import APIRouter
from memory import append_to_history, delete_user_history, load_user_history_as_list
from graph_builder import rag_agent_executor

logger = logging.getLogger(__name__)
router = APIRouter()

class ChatRequest(BaseModel):
    user_id: str
    input: str

@router.post("/chat/")
async def chat(request: ChatRequest):
    append_to_history(request.user_id, "user", request.input)

    result = rag_agent_executor.invoke({
        "user_id": request.user_id,
        "input": request.input,
        "conversation_history": "",
    })

    logger.debug("Raw graph result: %s", result)

    final_response = result["response"]

    logger.debug("Cleaned response:\n%s", final_response)

    append_to_history(request.user_id, "ai", final_response)

    return {
        "response": final_response,
        "history": result.get("conversation_history", ""),
        "refined_context": result.get("refined_context", ""),
    }

class SaveMessageRequest(BaseModel):
    user_id: str
    content: str
    role: str

@router.post("/save/")
async def save_message(request: SaveMessageRequest):
    append_to_history(request.user_id, request.role, request.content)
    return {"status": "saved"}

WELCOME_MESSAGE = (
    "👋 Hello! I'm Hailey — here to support you on your quit smoking journey. "
    "How can I help today?"
)


@router.get("/history/{user_id}")
async def get_history(user_id: str):
    full_history = load_user_history_as_list(user_id, k=20)
    if not full_history:
        # First-time user: seed the welcome server-side so the client doesn't
        # have to inject it after the fact. If the user manages to send a
        # message before this GET returns, the POST /chat/ path appends the
        # user message and we skip seeding (history is no longer empty).
        append_to_history(user_id, "ai", WELCOME_MESSAGE)
        full_history = load_user_history_as_list(user_id, k=20)
    logger.debug("Returned history: %s", full_history)
    return {"history": full_history}

@router.delete("/history/{user_id}")
async def delete_history(user_id: str):
    delete_user_history(user_id)
    return {"status": "history deleted"}
