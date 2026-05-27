"""
Prometheus-compatible metrics exposed at GET /metrics.

Tracks per-request counters and histograms. Import and call the helper
functions from agent and router code. All metrics are no-ops when
settings.metrics_enabled is False.
"""
from __future__ import annotations

from app.config import settings

if settings.metrics_enabled:
    from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

    requests_total = Counter(
        "hailey_requests_total",
        "Total chat requests",
        ["status"],  # "ok" | "error" | "crisis" | "irrelevant"
    )
    triage_intent = Counter(
        "hailey_triage_intent_total",
        "Triage intent distribution",
        ["intent"],
    )
    triage_emotion = Counter(
        "hailey_triage_emotion_total",
        "Triage emotion distribution",
        ["emotion"],
    )
    specialist_invocations = Counter(
        "hailey_specialist_invocations_total",
        "Number of times each specialist was invoked",
        ["specialist"],
    )
    fallback_rate = Counter(
        "hailey_triage_parse_failures_total",
        "Number of triage JSON parse failures (silent degradation)",
    )
    retrieval_hits = Counter(
        "hailey_retrieval_chunks_total",
        "Total knowledge base chunks retrieved",
    )
    request_latency = Histogram(
        "hailey_request_latency_seconds",
        "End-to-end request latency",
        buckets=[0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0],
    )
    cf_quota_used = Gauge(
        "hailey_cf_workers_ai_calls_today",
        "Cloudflare Workers AI calls used today",
    )

    def record_request(status: str) -> None:
        requests_total.labels(status=status).inc()

    def record_triage(intent: str, emotion: str) -> None:
        triage_intent.labels(intent=intent).inc()
        triage_emotion.labels(emotion=emotion).inc()

    def record_specialist(name: str) -> None:
        specialist_invocations.labels(specialist=name).inc()

    def record_fallback() -> None:
        fallback_rate.inc()

    def record_retrieval(n: int) -> None:
        retrieval_hits.inc(n)

    def record_cf_quota(n: int) -> None:
        cf_quota_used.set(n)

    def metrics_response() -> tuple[bytes, str]:
        return generate_latest(), CONTENT_TYPE_LATEST

else:
    # No-op stubs when metrics are disabled
    def record_request(status: str) -> None: pass
    def record_triage(intent: str, emotion: str) -> None: pass
    def record_specialist(name: str) -> None: pass
    def record_fallback() -> None: pass
    def record_retrieval(n: int) -> None: pass
    def record_cf_quota(n: int) -> None: pass
    def metrics_response() -> tuple[bytes, str]: return b"", "text/plain"
