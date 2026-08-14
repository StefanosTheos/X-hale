"""
FastAPI application bootstrap for Hailey 2.0.

Startup sequence:
  1. Configure structured logging.
  2. Mount all routers.
  3. Register lifespan hooks (warm Qdrant connection, validate config).
  4. Add CORS middleware.
  5. Add metrics endpoint (if enabled).

Port: 7860 (Hugging Face Spaces default).
"""
from __future__ import annotations

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.observability.logging import configure_logging, get_logger

# Configure logging before any other imports that might log
configure_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown hooks."""
    logger.info("hailey_backend_starting", version="2.0.0")

    # Validate required config
    missing = []
    if not settings.groq_api_key:
        missing.append("GROQ_API_KEY")
    if not settings.appwrite_project_id:
        missing.append("APPWRITE_PROJECT_ID")
    if not settings.appwrite_api_key:
        missing.append("APPWRITE_API_KEY")
    if not settings.qdrant_url:
        missing.append("QDRANT_URL")
    if missing:
        logger.warning("missing_required_env_vars", vars=missing)

    # Warm the Qdrant connection
    try:
        from app.retrieval.vector_store import get_qdrant_client
        client = get_qdrant_client()
        collections = await client.get_collections()
        logger.info("qdrant_connected", collections=[c.name for c in collections.collections])
    except Exception as exc:
        logger.warning("qdrant_warmup_failed", error=str(exc))

    # Pre-compile the LangGraph (avoids first-request cold start)
    try:
        from app.graph.builder import get_compiled_preparation_graph
        get_compiled_preparation_graph()
        logger.info("langgraph_compiled")
    except Exception as exc:
        logger.warning("langgraph_compile_warning", error=str(exc))

    logger.info("hailey_backend_ready")
    yield

    # Shutdown
    logger.info("hailey_backend_stopping")


def create_app() -> FastAPI:
    app = FastAPI(
        title="Hailey 2.0 — X-hale Chatbot Backend",
        version="2.0.0",
        description="Agentic RAG chatbot backend for the X-hale quit-smoking app.",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
    )

    # CORS — allow the Flutter web build and any Appwrite-hosted frontend
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Tighten in production to specific origins
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Mount routers
    from app.routers.chat import router as chat_router
    from app.routers.export import router as export_router
    from app.routers.history import router as history_router
    from app.routers.kb import router as kb_router
    from app.routers.memory import router as memory_router

    app.include_router(chat_router)
    app.include_router(history_router)
    app.include_router(memory_router)
    app.include_router(export_router)
    app.include_router(kb_router)

    # Metrics endpoint
    if settings.metrics_enabled:
        from fastapi import Response
        from app.observability.metrics import metrics_response

        @app.get("/metrics", include_in_schema=False)
        async def metrics():
            content, content_type = metrics_response()
            return Response(content=content, media_type=content_type)

    # Root — required by Hugging Face Spaces to surface the logs panel
    @app.get("/", include_in_schema=False)
    async def root():
        return {"status": "ok", "service": "Hailey 2.0", "version": "2.0.0"}

    # Health check
    @app.get("/health", include_in_schema=False)
    async def health():
        return {"status": "ok", "version": "2.0.0"}

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=7860, reload=False)
