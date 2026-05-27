"""
Structured JSON logging setup for the Hailey backend.
Provides a `get_logger` factory used throughout the application.

Usage:
    from app.observability.logging import get_logger
    logger = get_logger(__name__)
    logger.info("event_name", key="value", ...)
"""
from __future__ import annotations

import logging
import sys
from typing import Any

from pythonjsonlogger import jsonlogger

from app.config import settings

_configured = False


def _configure_root_logger() -> None:
    global _configured
    if _configured:
        return
    _configured = True

    root = logging.getLogger()
    root.setLevel(settings.log_level.upper())

    handler = logging.StreamHandler(sys.stdout)
    formatter = jsonlogger.JsonFormatter(
        fmt="%(asctime)s %(name)s %(levelname)s %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    )
    handler.setFormatter(formatter)

    # Remove any default handlers then attach ours
    root.handlers.clear()
    root.addHandler(handler)


class _StructuredAdapter(logging.LoggerAdapter):
    """
    Adapter that merges keyword-argument context into the log record's `extra` dict,
    making every field a top-level JSON key.
    """

    def process(self, msg: str, kwargs: dict[str, Any]) -> tuple[str, dict]:
        extra = self.extra.copy()  # type: ignore[attr-defined]
        # Pull any caller-supplied keyword extras out of kwargs
        extra.update(kwargs.pop("extra", {}))
        kwargs["extra"] = extra
        return msg, kwargs

    # Convenience: allow logger.info("event", key=val) style
    def _log_with_kwargs(self, level: int, msg: str, **kw: Any) -> None:
        extra = self.extra.copy()  # type: ignore[attr-defined]
        extra.update(kw)
        self.logger.log(level, msg, extra=extra)

    def debug(self, msg: str, *args: Any, **kw: Any) -> None:  # type: ignore[override]
        self._log_with_kwargs(logging.DEBUG, msg, **kw)

    def info(self, msg: str, *args: Any, **kw: Any) -> None:  # type: ignore[override]
        self._log_with_kwargs(logging.INFO, msg, **kw)

    def warning(self, msg: str, *args: Any, **kw: Any) -> None:  # type: ignore[override]
        self._log_with_kwargs(logging.WARNING, msg, **kw)

    def error(self, msg: str, *args: Any, **kw: Any) -> None:  # type: ignore[override]
        self._log_with_kwargs(logging.ERROR, msg, **kw)

    def exception(self, msg: str, *args: Any, **kw: Any) -> None:  # type: ignore[override]
        kw.setdefault("exc_info", True)
        self._log_with_kwargs(logging.ERROR, msg, **kw)


def get_logger(name: str) -> _StructuredAdapter:
    """Return a structured logger for the given module name."""
    _configure_root_logger()
    base = logging.getLogger(name)
    return _StructuredAdapter(base, extra={})
