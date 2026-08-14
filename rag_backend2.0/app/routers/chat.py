"""
POST /chat — the main chat endpoint with SSE streaming.

Flow:
1. Verify Appwrite JWT → get user_id
2. Build initial HaileyState
3. Run the preparation LangGraph through specialist drafting
4. Stream synthesis-model tokens, post-process, persist, and emit done

SSE event types:
  event: status   data: {"state": "triaging"|"loading_context"|"searching_kb"|"composing"|"saving"}
  event: token    data: {"token": "..."}
  event: done     data: {"citations": [...], "deeplinks": [...], "turn_id": "..."}
  event: error    data: {"code": "...", "message": "..."}
"""
from __future__ import annotations

import re
import uuid

from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse

from app.auth.dependencies import get_current_user
from app.agents.synthesizer import post_process_synthesis, synthesize_stream
from app.graph.builder import get_compiled_preparation_graph, output_node
from app.graph.state import HaileyState
from app.llm.streaming import done_event, error_event, status_event, token_event
from app.models.chat import ChatRequest
from app.models.retrieval import AppAction, Citation
from app.observability.logging import get_logger
from app.observability.metrics import record_request

logger = get_logger(__name__)
router = APIRouter(prefix="/chat", tags=["chat"])

_CITATION_START = "<!-- citations:"
_STREAM_TAIL_SIZE = len(_CITATION_START) - 1
_INLINE_MARKER_PATTERN = re.compile(r"\[[a-z][a-z0-9_]+\]")


def _collect_deeplinks(state: HaileyState) -> list[AppAction]:
    """Collect specialist deeplinks without duplicating identical targets."""
    collected: list[AppAction] = []
    seen: set[str] = set()
    for draft in (state.get("specialist_drafts") or {}).values():
        if not isinstance(draft, dict):
            continue
        for value in draft.get("suggested_deeplinks", []):
            action = value if isinstance(value, AppAction) else AppAction.model_validate(value)
            if action.deeplink not in seen:
                seen.add(action.deeplink)
                collected.append(action)
    return collected


def _visible_stream_part(buffer: str, *, final: bool = False) -> tuple[str, str, bool]:
    """Remove citation metadata while retaining a tail for split SSE/LLM tokens."""
    marker_at = buffer.find(_CITATION_START)
    if marker_at >= 0:
        return _INLINE_MARKER_PATTERN.sub("", buffer[:marker_at]).rstrip(), "", True
    if final:
        return _INLINE_MARKER_PATTERN.sub("", buffer), "", False
    if len(buffer) <= _STREAM_TAIL_SIZE:
        return "", buffer, False
    cut = len(buffer) - _STREAM_TAIL_SIZE
    return _INLINE_MARKER_PATTERN.sub("", buffer[:cut]), buffer[cut:], False


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

            graph = get_compiled_preparation_graph()
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

            final_state: HaileyState = dict(initial_state)
            loading_sent = False
            searching_sent = False
            async for update in graph.astream(initial_state, stream_mode="updates"):
                for node_name, node_update in update.items():
                    if node_update:
                        final_state.update(node_update)
                    triage = final_state.get("triage")
                    is_crisis = bool(triage and triage.crisis_flag)
                    if node_name == "triage_node" and not is_crisis:
                        yield status_event("loading_context")
                        loading_sent = True
                    elif node_name == "supervisor_node" and "medical" in final_state.get("requested_specialists", []):
                        yield status_event("searching_kb")
                        searching_sent = True

            # Defensive status completion if a graph implementation changes its update granularity.
            if final_state.get("user_memory") is not None and not loading_sent:
                yield status_event("loading_context")
            if "medical" in final_state.get("requested_specialists", []) and not searching_sent:
                yield status_event("searching_kb")

            yield status_event("composing")

            # Crisis/clarification/off-topic paths already contain deterministic output.
            response_text = final_state.get("final_response", "")
            if response_text:
                yield token_event(response_text)
            else:
                raw_parts: list[str] = []
                pending = ""
                metadata_started = False
                streamed_text = ""
                async for token in synthesize_stream(final_state):
                    raw_parts.append(token)
                    if metadata_started:
                        continue
                    pending += token
                    visible, pending, metadata_started = _visible_stream_part(pending)
                    if visible:
                        streamed_text += visible
                        yield token_event(visible)

                if not metadata_started:
                    visible, _, _ = _visible_stream_part(pending, final=True)
                    if visible:
                        streamed_text += visible
                        yield token_event(visible)

                response_text, citations = post_process_synthesis("".join(raw_parts), final_state)
                # The safety filter may append a disclaimer after generation.
                if response_text.startswith(streamed_text):
                    suffix = response_text[len(streamed_text):]
                    if suffix:
                        yield token_event(suffix)
                final_state["final_response"] = response_text
                final_state["citations"] = citations
                final_state["deeplinks"] = _collect_deeplinks(final_state)

            # Status: saving
            yield status_event("saving")

            # Persist only after a complete response has been generated.
            final_state = await output_node(final_state)

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
