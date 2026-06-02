import logging

from duckduckgo_search import DDGS
from langchain.schema import Document

logger = logging.getLogger(__name__)


def web_search(query: str, max_results=5, timeout: int = 5):
    """Run a DuckDuckGo search and return a list of LangChain Documents.

    Wrapped in try/except + a request timeout so a hung or failing DDGS call
    can't take the whole /chat/ request down with it. On any failure (network,
    rate-limit, parse error, timeout) the function logs and returns an empty
    list — the caller will just have no web context for that turn.
    """
    results = []
    try:
        with DDGS(timeout=timeout) as ddgs:
            for r in ddgs.text(query, max_results=max_results):
                results.append(
                    Document(
                        page_content=r["body"],
                        metadata={"source": r["href"]},
                    )
                )
    except Exception as e:
        logger.warning("web_search failed (%s): %s", type(e).__name__, e)
        return []
    return results
