"""
Rate-limited DuckDuckGo web search fallback.

Used by the Medical Agent when the knowledge base returns insufficient results.
Gated behind settings.enable_web_search_fallback.

Fixes from current implementation:
- Documents are explicitly tagged [WEB SEARCH] (was untagged before)
- Per-session call limit prevents quota abuse
- Errors are logged, not silently swallowed
"""
from __future__ import annotations

import asyncio
from dataclasses import dataclass

from app.config import settings
from app.observability.logging import get_logger

logger = get_logger(__name__)

_WEB_SEARCH_SESSION_LIMIT = 3   # max web search calls per user turn
_session_call_count: dict[str, int] = {}  # request_id → count


@dataclass
class WebDocument:
    content: str
    url: str
    title: str
    source_tag: str = "[WEB SEARCH]"


async def web_search(query: str, request_id: str = "", max_results: int = 3) -> list[WebDocument]:
    """
    Search DuckDuckGo and return tagged WebDocument objects.
    Returns empty list if web search is disabled or rate limit is exceeded.
    """
    if not settings.enable_web_search_fallback:
        return []

    if request_id:
        count = _session_call_count.get(request_id, 0)
        if count >= _WEB_SEARCH_SESSION_LIMIT:
            logger.warning("web_search_session_limit_reached", request_id=request_id)
            return []
        _session_call_count[request_id] = count + 1

    try:
        from duckduckgo_search import DDGS
        results = await asyncio.to_thread(
            lambda: list(DDGS().text(query, max_results=max_results))
        )
        docs: list[WebDocument] = []
        for r in results:
            body = r.get("body", r.get("snippet", ""))
            url = r.get("href", r.get("link", ""))
            title = r.get("title", "Web result")
            if body:
                docs.append(WebDocument(
                    content=f"[WEB SEARCH] {title}\n{body}",
                    url=url,
                    title=title,
                ))
        return docs
    except Exception as exc:
        logger.warning("web_search_failed", query_len=len(query), error=str(exc))
        return []
