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

    # Missing credentials/identifiers are deployment errors, not transient
    # provider outages: fail before accepting traffic.
    from app.health import check_readiness, missing_required_settings
    missing = missing_required_settings()
    if missing:
        logger.error("missing_required_env_vars", vars=missing)
        raise RuntimeError(f"Missing required runtime configuration: {', '.join(missing)}")

    # Pre-compile the LangGraph (avoids first-request cold start)
    try:
        from app.graph.builder import get_compiled_preparation_graph
        get_compiled_preparation_graph()
        logger.info("langgraph_compiled")
    except Exception as exc:
        logger.error("langgraph_compile_failed", error=str(exc))
        raise RuntimeError("LangGraph compilation failed") from exc

    # Transient provider failure does not crash the process: liveness remains
    # available and /ready returns 503 until dependencies recover.
    readiness = await check_readiness(force=True)
    if readiness["status"] != "ready":
        logger.warning("hailey_backend_started_not_ready", components=readiness["components"])

    logger.info("hailey_backend_ready")
    yield

    # Shutdown
    from app.memory.curation_tasks import drain_memory_curation_tasks
    await drain_memory_curation_tasks()
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
    from app.routers.events import router as events_router
    from app.routers.account import router as account_router

    app.include_router(chat_router)
    app.include_router(history_router)
    app.include_router(memory_router)
    app.include_router(events_router)
    app.include_router(export_router)
    app.include_router(account_router)
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

    # Backward-compatible process liveness. Dependency state is exposed only
    # through /ready so Docker does not restart a healthy process during a
    # transient provider outage.
    @app.get("/health", include_in_schema=False)
    async def health():
        return {"status": "alive", "version": "2.0.0"}

    @app.get("/live", include_in_schema=False)
    async def live():
        return {"status": "alive", "version": "2.0.0"}

    @app.get("/ready", include_in_schema=False)
    async def ready():
        from fastapi.responses import JSONResponse
        from app.health import check_readiness

        result = await check_readiness()
        return JSONResponse(content=result, status_code=200 if result["status"] == "ready" else 503)

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=7860, reload=False)
