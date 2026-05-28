"""
POST /chat — the main chat endpoint with SSE streaming.

Flow:
1. Verify Appwrite JWT → get user_id
2. Build initial HaileyState
3. Run compiled LangGraph (synthesizer streams tokens)
4. Stream: status events + tokens + done event with citations/deeplinks

SSE event types:
  event: status   data: {"state": "triaging"|"loading_context"|"searching_kb"|"composing"|"saving"}
  event: token    data: {"token": "..."}
  event: done     data: {"citations": [...], "deeplinks": [...], "turn_id": "..."}
  event: error    data: {"code": "...", "message": "..."}
"""
from __future__ import annotations

import asyncio
import uuid

from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse

from app.auth.dependencies import get_current_user
from app.graph.builder import get_compiled_graph
from app.graph.state import HaileyState
from app.llm.streaming import done_event, error_event, status_event, token_event
from app.models.chat import ChatRequest
from app.models.retrieval import AppAction, Citation
from app.observability.logging import get_logger
from app.observability.metrics import record_request

logger = get_logger(__name__)
router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/")
async def chat(
    request: Request,
    body: ChatRequest,
    user_id: str = Depends(get_current_user),
):
    """
    POST /chat/ — accepts a message and streams the response via SSE.
    The client must handle SSE event types: status, token, done, error.
    """
    turn_id = str(uuid.uuid4())

    async def generate():
        try:
            # Status: triaging
            yield status_event("triaging")

            graph = get_compiled_graph()
            initial_state: HaileyState = {
                "user_id": user_id,
                "user_input": body.message,
                "locale": body.locale,
                "turn_id": turn_id,
                "specialist_drafts": {},
                "requested_specialists": [],
                "citations": [],
                "deeplinks": [],
                "final_response": "",
                "is_crisis": False,
                "is_irrelevant": False,
                "needs_clarification": False,
                "error": None,
                "user_memory": None,
                "triage": None,
            }

            # Status: loading context
            yield status_event("loading_context")

            # Run the full graph (non-streaming)
            # The graph saves the final response in state["final_response"]
            final_state: HaileyState = await graph.ainvoke(initial_state)

            # Status: composing (signal that we're about to stream)
            yield status_event("composing")

            # Stream the final response token by token
            # (for simplicity, chunk by word; replace with real token streaming
            #  by wiring the synthesizer's stream generator through state in Phase 2+)
            response_text: str = final_state.get("final_response", "")
            if response_text:
                # Simulate token streaming: yield chunks of ~4 chars
                chunk_size = 4
                for i in range(0, len(response_text), chunk_size):
                    chunk = response_text[i:i + chunk_size]
                    yield token_event(chunk)
                    await asyncio.sleep(0.01)  # small delay for natural feel

            # Status: saving
            yield status_event("saving")

            # Done event with citations and deeplinks
            citations: list[Citation] = final_state.get("citations", [])
            deeplinks: list[AppAction] = final_state.get("deeplinks", [])
            response_turn_id: str = final_state.get("turn_id", turn_id)

            record_request("ok")
            yield done_event(citations=citations, deeplinks=deeplinks, turn_id=response_turn_id)

        except Exception as exc:
            logger.error("chat_endpoint_error", user_id=user_id, error=str(exc))
            record_request("error")
            yield error_event("internal_error", "Something went wrong. Please try again.")

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
