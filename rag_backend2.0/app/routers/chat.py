"""
POST /chat — the main chat endpoint with SSE streaming.

Flow:
1. Verify Appwrite JWT → get user_id
2. Build initial HaileyState
3. Run the preparation LangGraph through specialist drafting
4. Buffer synthesis output, enforce safety, then stream the safe response

SSE event types:
  event: status   data: {"state": "triaging"|"loading_context"|"searching_kb"|"composing"|"saving"}
  event: token    data: {"token": "..."}
  event: done     data: {"citations": [...], "deeplinks": [...], "turn_id": "..."}
  event: error    data: {"code": "...", "message": "..."}
"""
from __future__ import annotations

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
from app.config import settings
from app.llm.usage import begin_usage_tracking, end_usage_tracking
from app.tools.app_actions import VALID_DEEPLINKS

logger = get_logger(__name__)
router = APIRouter(prefix="/chat", tags=["chat"])

def _collect_deeplinks(state: HaileyState) -> list[AppAction]:
    """Collect specialist deeplinks without duplicating identical targets."""
    collected: list[AppAction] = []
    seen: set[str] = set()
    for draft in (state.get("specialist_drafts") or {}).values():
        if not isinstance(draft, dict):
            continue
        for value in draft.get("suggested_deeplinks", []):
            action = value if isinstance(value, AppAction) else AppAction.model_validate(value)
            if action.deeplink in VALID_DEEPLINKS and action.deeplink not in seen:
                seen.add(action.deeplink)
                collected.append(action)
    return collected

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
        usage, usage_token = begin_usage_tracking()
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
                "trace": {},
                "benchmark_memory_facts": (
                    body.benchmark_memory_facts
                    if settings.benchmark_test_user_id == user_id else []
                ),
                "benchmark_context_override": settings.benchmark_test_user_id == user_id,
                "benchmark_profile": (
                    body.benchmark_profile
                    if settings.benchmark_test_user_id == user_id else {}
                ),
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
                async for token in synthesize_stream(final_state):
                    raw_parts.append(token)

                response_text, citations = post_process_synthesis("".join(raw_parts), final_state)
                # Safety must run before any model text reaches the client.
                yield token_event(response_text)
                final_state["final_response"] = response_text
                final_state["citations"] = citations
                final_state["deeplinks"] = _collect_deeplinks(final_state)
                trace = dict(final_state.get("trace") or {})
                trace["actual_route"] = "specialists"
                trace["synthesis"] = {
                    "completed": True,
                    "response_characters": len(response_text),
                    "stream_ended_normally": True,
                }
                trace["actions"] = [
                    {
                        "deeplink": action.deeplink,
                        "provenance": action.provenance,
                        "valid": action.deeplink in VALID_DEEPLINKS,
                    }
                    for action in final_state["deeplinks"]
                ]
                final_state["trace"] = trace

            # Status: saving
            yield status_event("saving")

            # Persist only after a complete response has been generated.
            final_state = await output_node(final_state)

            # Done event with citations and deeplinks
            citations: list[Citation] = final_state.get("citations", [])
            deeplinks: list[AppAction] = final_state.get("deeplinks", [])
            response_turn_id: str = final_state.get("turn_id", turn_id)

            record_request("ok")
            benchmark_usage = usage.as_dict() if (
                settings.benchmark_test_user_id
                and user_id == settings.benchmark_test_user_id
            ) else None
            benchmark_trace = final_state.get("trace") if benchmark_usage is not None else None
            yield done_event(
                citations=citations, deeplinks=deeplinks,
                turn_id=response_turn_id, usage=benchmark_usage, trace=benchmark_trace,
            )

        except Exception as exc:
            logger.error("chat_endpoint_error", user_id=user_id, error=str(exc))
            record_request("error")
            yield error_event("internal_error", "Something went wrong. Please try again.")
        finally:
            end_usage_tracking(usage_token)

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
