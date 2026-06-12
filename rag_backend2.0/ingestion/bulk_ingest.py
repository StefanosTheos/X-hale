"""
Bulk ingestion runner — reads sources.yaml and ingests all pending sources.

Usage (from rag_backend2.0/):
    python -m ingestion.bulk_ingest
    python -m ingestion.bulk_ingest --dry-run
    python -m ingestion.bulk_ingest --source-id smokefree_cravings
    python -m ingestion.bulk_ingest --force
    python -m ingestion.bulk_ingest --delay 3

Options:
    --dry-run     List pending sources without ingesting anything
    --force       Re-ingest sources already marked as ingested
    --source-id   Only ingest one specific source_id
    --collection  Override target Qdrant collection (default: kb_chunks)
    --delay       Seconds to pause between sources (default: 2, be polite to servers)

Requirements:
    pip install ".[ingestion]"   # adds pymupdf, beautifulsoup4, requests, pyyaml
    .env must have: QDRANT_URL, QDRANT_API_KEY, CF_ACCOUNT_ID, CF_WORKERS_AI_TOKEN
"""
from __future__ import annotations

import argparse
import asyncio
import sys
import time
from pathlib import Path
from typing import Any

import yaml

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings
from app.observability.logging import configure_logging, get_logger
from ingestion.ingest_kb import _read_url, ingest_text

configure_logging()
logger = get_logger(__name__)

MANIFEST = Path(__file__).parent / "sources.yaml"

_MIN_CONTENT_LENGTH = 200  # chars — shorter than this means a JS-gated or empty page


# ── Manifest helpers ──────────────────────────────────────────────────────────

def _load_manifest() -> dict[str, Any]:
    with open(MANIFEST, encoding="utf-8") as f:
        return yaml.safe_load(f)


def _mark_ingested(source_id: str) -> None:
    """Flip `ingested: false` → `ingested: true` for the given source_id in-place.
    Uses string-level replacement so comments and formatting are preserved."""
    content = MANIFEST.read_text(encoding="utf-8")
    lines = content.splitlines(keepends=True)
    in_target = False
    out = []
    for line in lines:
        if f"source_id: {source_id}" in line:
            in_target = True
        if in_target and "ingested: false" in line:
            line = line.replace("ingested: false", "ingested: true")
            in_target = False
        elif in_target and line.strip().startswith("- source_id:") and source_id not in line:
            in_target = False  # entered next entry without finding the flag
        out.append(line)
    MANIFEST.write_text("".join(out), encoding="utf-8")


# ── Core ingestion ────────────────────────────────────────────────────────────

async def _ingest_source(entry: dict[str, Any], collection: str) -> int:
    url = entry["url"]
    source_id = entry["source_id"]
    source_type = entry.get("source_type", "unknown")
    topic_tags = entry.get("topic_tags") or []
    benefit_ids = entry.get("benefit_ids") or []
    benefit_id = benefit_ids[0] if benefit_ids else None
    recency_date = entry.get("recency_date", "") or ""

    logger.info("fetching", source_id=source_id, url=url)
    text = _read_url(url)  # raises on HTTP error

    if len(text.strip()) < _MIN_CONTENT_LENGTH:
        raise ValueError(
            f"Content too short ({len(text)} chars) — likely a JS-gated or empty page"
        )

    n = await ingest_text(
        text=text,
        source_id=source_id,
        source_type=source_type,
        benefit_id=benefit_id,
        topic_tags=topic_tags,
        recency_date=str(recency_date),
        collection=collection,
    )
    return n


# ── Entry point ───────────────────────────────────────────────────────────────

async def main(args: argparse.Namespace) -> None:
    data = _load_manifest()
    sources: list[dict[str, Any]] = data.get("sources", [])
    collection = args.collection or settings.qdrant_kb_collection

    pending = [
        s for s in sources
        if (args.force or not s.get("ingested", False))
        and (not args.source_id or s["source_id"] == args.source_id)
    ]

    if not pending:
        print("Nothing to ingest. Use --force to re-ingest existing sources.")
        return

    print(f"\nPending: {len(pending)} source(s) → collection '{collection}'\n")
    for s in pending:
        tag = "force" if s.get("ingested") else "new"
        print(f"  [{tag:5s}] {s['source_id']:45s} {s['url']}")

    if args.dry_run:
        print("\n(dry-run — no changes made)")
        return

    print()
    success = failed = 0

    for i, entry in enumerate(pending, 1):
        sid = entry["source_id"]
        prefix = f"[{i:2d}/{len(pending)}] {sid}"
        print(f"{prefix} ...", end="", flush=True)

        try:
            n = await _ingest_source(entry, collection)
            print(f"\r{prefix} — {n} chunks  ✓")
            _mark_ingested(sid)
            success += 1
        except Exception as exc:
            print(f"\r{prefix} — FAILED: {exc}")
            logger.error("ingest_failed", source_id=sid, error=str(exc))
            failed += 1

        if i < len(pending):
            time.sleep(args.delay)

    print(f"\n{'─'*50}")
    print(f"Done. {success} succeeded, {failed} failed.")
    if failed:
        print("Re-run to retry failed sources (they remain marked ingested: false).")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Bulk-ingest all pending sources from sources.yaml into Qdrant"
    )
    parser.add_argument("--dry-run", action="store_true",
                        help="Show pending sources without ingesting")
    parser.add_argument("--force", action="store_true",
                        help="Re-ingest sources already marked ingested")
    parser.add_argument("--source-id",
                        help="Ingest only this source_id")
    parser.add_argument("--collection",
                        help="Override target collection (default: kb_chunks)")
    parser.add_argument("--delay", type=float, default=2.0,
                        help="Seconds between sources (default: 2)")
    asyncio.run(main(parser.parse_args()))
