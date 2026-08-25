"""
CLI for ingesting documents into the Qdrant knowledge base.

Usage:
    python -m ingestion.ingest_kb --file path/to/doc.pdf
    python -m ingestion.ingest_kb --url https://example.com/article
    python -m ingestion.ingest_kb --folder path/to/folder
    python -m ingestion.ingest_kb --file doc.txt --source-id my_source --source-type government

Options:
    --file      Path to a .pdf or .txt file
    --url       URL to a web page or PDF
    --folder    Directory: ingests all .pdf and .txt files
    --source-id Override the auto-generated source_id
    --source-type government|peer_reviewed|charity|web (default: unknown)
    --benefit-id Tag chunks with a health benefit ID
    --topic-tags Comma-separated topic tags
    --collection kb_chunks (default) or health_benefit_chunks
    --force     Re-ingest even if source_id already exists

Requires:
    pip install ".[ingestion]"
    Environment: QDRANT_URL, QDRANT_API_KEY, CF_ACCOUNT_ID, CF_WORKERS_AI_TOKEN
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import os
import sys
from pathlib import Path
from typing import Optional

# Add project root to path so app.* imports work
sys.path.insert(0, str(Path(__file__).parent.parent))

from ingestion.chunk import ChunkPoint, chunk_text
from app.config import settings
from app.observability.logging import configure_logging, get_logger

configure_logging()
logger = get_logger(__name__)


def _auto_source_id(path_or_url: str) -> str:
    """Generate a deterministic source_id from a file path or URL."""
    return hashlib.md5(path_or_url.encode()).hexdigest()[:12]


def _read_pdf(path: str) -> str:
    """Extract text from a PDF file using PyMuPDF."""
    try:
        import pymupdf
        with pymupdf.open(path) as doc:
            pages = [page.get_text() for page in doc]
        return "\n\n".join(pages)
    except ImportError:
        logger.error("pymupdf_not_installed", hint="pip install '.[ingestion]'")
        raise


def _read_txt(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        return f.read()


def _read_url(url: str) -> str:
    """Fetch and extract text from a URL (HTML or PDF)."""
    import requests
    resp = requests.get(
        url,
        timeout=20,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/127.0.0.0 Safari/537.36"
            ),
            "Accept": "text/html,application/xhtml+xml,application/pdf;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
        },
    )
    resp.raise_for_status()
    content_type = resp.headers.get("content-type", "")
    if "pdf" in content_type or url.lower().endswith(".pdf"):
        import tempfile, pymupdf
        with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as f:
            f.write(resp.content)
            tmp = f.name
        try:
            with pymupdf.open(tmp) as doc:
                return "\n\n".join(page.get_text() for page in doc)
        finally:
            os.unlink(tmp)
    else:
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(resp.content, "html.parser")
        for tag in soup(["script", "style", "nav", "footer", "header"]):
            tag.decompose()
        return soup.get_text(separator="\n", strip=True)


async def embed_chunks(chunks: list[ChunkPoint]) -> list[dict]:
    """Embed all chunk contents using Cloudflare Workers AI."""
    from app.llm.workers_ai_client import embed_batch
    texts = [c.content for c in chunks]
    # Batch in groups of 20 to respect Workers AI limits
    vectors: list[list[float]] = []
    batch_size = 20
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        batch_vectors = await embed_batch(batch)
        vectors.extend(batch_vectors)
        logger.info("embedding_progress", done=len(vectors), total=len(texts))
    return vectors


async def upsert_to_qdrant(chunks: list[ChunkPoint], vectors: list[list[float]], collection: str) -> None:
    """Upsert embedded chunks into the Qdrant collection."""
    from app.retrieval.vector_store import upsert
    from qdrant_client.models import VectorParams, Distance
    from app.retrieval.vector_store import get_qdrant_client

    client = get_qdrant_client()
    # Ensure collection exists
    collections = await client.get_collections()
    existing = [c.name for c in collections.collections]
    if collection not in existing:
        logger.info("creating_qdrant_collection", collection=collection)
        await client.create_collection(
            collection_name=collection,
            vectors_config=VectorParams(size=settings.qdrant_vector_size, distance=Distance.COSINE),
        )

    points = [
        {
            "id": chunk.id,
            "vector": vector,
            "payload": {
                "content": chunk.content,
                "source_id": chunk.source_id,
                "source_type": chunk.source_type,
                "benefit_id": chunk.benefit_id,
                "topic_tags": chunk.topic_tags,
                "recency_date": chunk.recency_date,
                "chunk_index": chunk.chunk_index,
                "total_chunks": chunk.total_chunks,
            },
        }
        for chunk, vector in zip(chunks, vectors)
    ]
    await upsert(collection, points)
    logger.info("upsert_complete", collection=collection, count=len(points))


async def ingest_text(
    text: str,
    source_id: str,
    source_type: str = "unknown",
    benefit_id: Optional[str] = None,
    topic_tags: Optional[list[str]] = None,
    recency_date: str = "",
    collection: str = "",
) -> int:
    """Chunk, embed, and upsert a text document. Returns number of chunks ingested."""
    coll = collection or settings.qdrant_kb_collection
    chunks = chunk_text(
        text,
        source_id=source_id,
        source_type=source_type,
        benefit_id=benefit_id,
        topic_tags=topic_tags,
        recency_date=recency_date,
    )
    if not chunks:
        logger.warning("no_chunks_produced", source_id=source_id)
        return 0
    logger.info("chunking_complete", source_id=source_id, chunks=len(chunks))
    vectors = await embed_chunks(chunks)
    await upsert_to_qdrant(chunks, vectors, coll)
    return len(chunks)


async def main(args: argparse.Namespace) -> None:
    topic_tags = [t.strip() for t in args.topic_tags.split(",")] if args.topic_tags else []
    collection = args.collection or settings.qdrant_kb_collection

    if args.file:
        path = Path(args.file)
        source_id = args.source_id or _auto_source_id(str(path))
        if path.suffix.lower() == ".pdf":
            text = _read_pdf(str(path))
        else:
            text = _read_txt(str(path))
        n = await ingest_text(text, source_id, args.source_type, args.benefit_id, topic_tags, collection=collection)
        print(f"✓ Ingested {n} chunks from {path.name} → {collection}")

    elif args.url:
        source_id = args.source_id or _auto_source_id(args.url)
        text = _read_url(args.url)
        n = await ingest_text(text, source_id, args.source_type, args.benefit_id, topic_tags, collection=collection)
        print(f"✓ Ingested {n} chunks from {args.url} → {collection}")

    elif args.folder:
        folder = Path(args.folder)
        total = 0
        for fp in sorted(folder.glob("**/*")):
            if fp.suffix.lower() not in (".pdf", ".txt"):
                continue
            sid = _auto_source_id(str(fp))
            text = _read_pdf(str(fp)) if fp.suffix.lower() == ".pdf" else _read_txt(str(fp))
            n = await ingest_text(text, sid, args.source_type, topic_tags=topic_tags, collection=collection)
            total += n
            print(f"  ✓ {fp.name}: {n} chunks")
        print(f"\nTotal: {total} chunks ingested → {collection}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest documents into the Hailey knowledge base")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--file", help="Path to a .pdf or .txt file")
    group.add_argument("--url", help="URL to fetch and ingest")
    group.add_argument("--folder", help="Directory to batch-ingest")
    parser.add_argument("--source-id", help="Override auto-generated source_id")
    parser.add_argument("--source-type", default="unknown",
                        choices=["government", "peer_reviewed", "charity", "web", "unknown"])
    parser.add_argument("--benefit-id", help="Tag chunks with a health benefit ID")
    parser.add_argument("--topic-tags", help="Comma-separated topic tags")
    parser.add_argument("--collection", help="Target Qdrant collection name (default: kb_chunks)")
    parser.add_argument("--force", action="store_true", help="Re-ingest even if source already exists")
    asyncio.run(main(parser.parse_args()))
