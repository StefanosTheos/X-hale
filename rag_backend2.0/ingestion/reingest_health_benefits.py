"""
One-shot script: re-ingest all 14 health benefit sources into Qdrant
with proper per-chunk benefit_id tagging.

Fixes the current backend's "one document per source" anti-pattern.
Each source is fetched, chunked at 500 chars, and tagged with benefit_id
so the Flutter app's "Learn More" buttons can retrieve by metadata filter.

Run once after setting up a fresh Qdrant cluster:
    python -m ingestion.reingest_health_benefits

Requires: pip install ".[ingestion]"
"""
from __future__ import annotations

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from ingestion.ingest_kb import ingest_text, _read_url
from app.config import settings
from app.observability.logging import configure_logging, get_logger

configure_logging()
logger = get_logger(__name__)

# Mapping: benefit_id → list of authoritative sources
BENEFIT_SOURCES: dict[str, list[dict]] = {
    "20min": [
        {"url": "https://www.cdc.gov/tobacco/quit_smoking/how_to_quit/benefits/index.htm",
         "source_id": "cdc_benefits_timeline", "source_type": "government"},
    ],
    "8hr": [
        {"url": "https://www.nhs.uk/live-well/quit-smoking/benefits-of-quitting-smoking/",
         "source_id": "nhs_quit_benefits", "source_type": "government"},
    ],
    "24hr": [
        {"url": "https://www.cancer.org/healthy/stay-away-from-tobacco/benefits-of-quitting-smoking-over-time.html",
         "source_id": "acs_quit_timeline", "source_type": "charity"},
    ],
    "48hr": [
        {"url": "https://www.nhs.uk/live-well/quit-smoking/benefits-of-quitting-smoking/",
         "source_id": "nhs_quit_benefits", "source_type": "government"},
    ],
    "72hr": [
        {"url": "https://www.cdc.gov/tobacco/quit_smoking/how_to_quit/benefits/index.htm",
         "source_id": "cdc_benefits_timeline", "source_type": "government"},
    ],
    "2wk": [
        {"url": "https://www.cancer.org/healthy/stay-away-from-tobacco/benefits-of-quitting-smoking-over-time.html",
         "source_id": "acs_quit_timeline", "source_type": "charity"},
    ],
    "1mo": [
        {"url": "https://www.nhs.uk/live-well/quit-smoking/benefits-of-quitting-smoking/",
         "source_id": "nhs_quit_benefits", "source_type": "government"},
    ],
    "3mo": [
        {"url": "https://www.cancer.org/healthy/stay-away-from-tobacco/benefits-of-quitting-smoking-over-time.html",
         "source_id": "acs_quit_timeline", "source_type": "charity"},
    ],
    "6mo": [
        {"url": "https://www.mayoclinic.org/healthy-lifestyle/quit-smoking/in-depth/quit-smoking/art-20045452",
         "source_id": "mayo_quit_smoking", "source_type": "government"},
    ],
    "1yr": [
        {"url": "https://www.heart.org/en/healthy-living/healthy-lifestyle/quit-smoking-tobacco/why-quit",
         "source_id": "aha_why_quit", "source_type": "charity"},
    ],
    "5yr": [
        {"url": "https://www.cancer.org/healthy/stay-away-from-tobacco/benefits-of-quitting-smoking-over-time.html",
         "source_id": "acs_quit_timeline", "source_type": "charity"},
    ],
    "10yr": [
        {"url": "https://www.cdc.gov/tobacco/quit_smoking/how_to_quit/benefits/index.htm",
         "source_id": "cdc_benefits_timeline", "source_type": "government"},
    ],
    "15yr": [
        {"url": "https://www.nhs.uk/live-well/quit-smoking/benefits-of-quitting-smoking/",
         "source_id": "nhs_quit_benefits", "source_type": "government"},
    ],
    "20yr": [
        {"url": "https://www.cancer.org/healthy/stay-away-from-tobacco/benefits-of-quitting-smoking-over-time.html",
         "source_id": "acs_quit_timeline", "source_type": "charity"},
    ],
}


async def reingest_all() -> None:
    collection = settings.qdrant_health_benefits_collection
    total_chunks = 0
    errors: list[str] = []

    for benefit_id, sources in BENEFIT_SOURCES.items():
        for src in sources:
            try:
                logger.info("ingesting_benefit", benefit_id=benefit_id, source_id=src["source_id"])
                text = await asyncio.to_thread(_read_url, src["url"])
                n = await ingest_text(
                    text=text,
                    source_id=f"{src['source_id']}_{benefit_id}",
                    source_type=src.get("source_type", "unknown"),
                    benefit_id=benefit_id,
                    topic_tags=["health_benefit", benefit_id],
                    collection=collection,
                )
                total_chunks += n
                print(f"  ✓ benefit={benefit_id:5s}  source={src['source_id']:30s}  chunks={n}")
            except Exception as exc:
                msg = f"FAILED benefit={benefit_id} source={src['source_id']}: {exc}"
                errors.append(msg)
                print(f"  ✗ {msg}")

    print(f"\n{'='*60}")
    print(f"Total chunks ingested: {total_chunks}")
    if errors:
        print(f"Errors ({len(errors)}):")
        for e in errors:
            print(f"  • {e}")


if __name__ == "__main__":
    asyncio.run(reingest_all())
