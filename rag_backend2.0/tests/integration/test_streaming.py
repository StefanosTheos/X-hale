"""Integration tests for SSE streaming helpers."""
from __future__ import annotations

import pytest

from app.llm.streaming import status_event, token_event, done_event, error_event
from app.models.retrieval import Citation, AppAction


def test_status_event_format():
    ev = status_event("triaging")
    assert "event: status" in ev
    assert "triaging" in ev
    assert ev.endswith("\n\n")


def test_token_event_format():
    ev = token_event("Hello")
    assert "event: token" in ev
    assert "Hello" in ev


def test_done_event_includes_citations():
    citations = [Citation(source_id="nhs_quit", source_type="government")]
    deeplinks = [AppAction(label="Try breathing", deeplink="xhale://breathing")]
    ev = done_event(citations=citations, deeplinks=deeplinks, turn_id="t123")
    assert "event: done" in ev
    assert "nhs_quit" in ev
    assert "xhale://breathing" in ev
    assert "t123" in ev


def test_error_event_format():
    ev = error_event("internal_error", "Something went wrong")
    assert "event: error" in ev
    assert "internal_error" in ev
