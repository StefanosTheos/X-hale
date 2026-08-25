"""
Text chunking utility for ingestion into Qdrant.

Splits documents into 500-character chunks with 100-character overlap by default.
Each chunk is tagged with source metadata and gets a stable UUID derived
from (source_id, chunk_index) so re-ingestion is idempotent.
"""
from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class ChunkPoint:
    """A single chunk ready to be upserted into Qdrant."""
    id: str                       # stable UUID derived from source_id + chunk_index
    content: str
    source_id: str
    source_type: str = "unknown"  # "government" | "peer_reviewed" | "charity" | "web"
    benefit_id: Optional[str] = None
    topic_tags: list[str] = field(default_factory=list)
    recency_date: str = ""        # ISO date string, e.g. "2024-01-01"
    chunk_index: int = 0
    total_chunks: int = 1


def _stable_id(source_id: str, chunk_index: int) -> str:
    """Generate a stable UUID from source_id + chunk_index for idempotent upserts."""
    key = f"{source_id}:{chunk_index}"
    return str(uuid.UUID(hashlib.md5(key.encode()).hexdigest()))


def chunk_text(
    text: str,
    source_id: str,
    source_type: str = "unknown",
    benefit_id: Optional[str] = None,
    topic_tags: Optional[list[str]] = None,
    recency_date: str = "",
    chunk_size: int = 500,
    chunk_overlap: int = 100,
) -> list[ChunkPoint]:
    """
    Split text into overlapping chunks and return a list of ChunkPoints.

    Uses a simple character-based splitter that tries to break on paragraph
    boundaries first, then sentence boundaries.

    Args:
        text: The raw document text.
        source_id: Unique identifier for the source document.
        source_type: Source credibility type.
        benefit_id: Optional health benefit ID for the health_benefit_chunks collection.
        topic_tags: Optional list of topic tags.
        recency_date: ISO date string of the source's publication date.
        chunk_size: Target chunk size in characters (~500 chars ≈ 125 tokens).
        chunk_overlap: Overlap between consecutive chunks in characters.

    Returns:
        List of ChunkPoint objects ready for embedding and upsert.
    """
    tags = topic_tags or []

    # Clean the text
    text = " ".join(text.split())  # normalize whitespace

    if len(text) <= chunk_size:
        return [ChunkPoint(
            id=_stable_id(source_id, 0),
            content=text,
            source_id=source_id,
            source_type=source_type,
            benefit_id=benefit_id,
            topic_tags=tags,
            recency_date=recency_date,
            chunk_index=0,
            total_chunks=1,
        )]

    # Split into paragraphs first, then re-join into chunks
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]

    chunks: list[str] = []
    current = ""

    for para in paragraphs:
        if len(current) + len(para) + 2 <= chunk_size:
            current = (current + "\n\n" + para).strip()
        else:
            if current:
                chunks.append(current)
            # If a single paragraph is too long, split by sentence
            if len(para) > chunk_size:
                sentences = para.replace(". ", ".|").replace("? ", "?|").replace("! ", "!|").split("|")
                sub = ""
                for sent in sentences:
                    if len(sub) + len(sent) + 1 <= chunk_size:
                        sub = (sub + " " + sent).strip()
                    else:
                        if sub:
                            chunks.append(sub)
                        sub = sent
                if sub:
                    current = sub
                else:
                    current = ""
            else:
                current = para

    if current:
        chunks.append(current)

    # Apply overlap at a word boundary. Character slicing previously produced
    # leading fragments such as "ughs" and encouraged incomplete key points.
    overlapped: list[str] = []
    for i, chunk in enumerate(chunks):
        if i > 0 and chunk_overlap > 0:
            previous = chunks[i - 1]
            overlap_start = max(0, len(previous) - chunk_overlap)
            if overlap_start:
                next_space = previous.find(" ", overlap_start)
                overlap_start = next_space + 1 if next_space >= 0 else overlap_start
            overlap_text = previous[overlap_start:]
            chunk = overlap_text + " " + chunk
        overlapped.append(chunk)

    total = len(overlapped)
    return [
        ChunkPoint(
            id=_stable_id(source_id, i),
            content=c,
            source_id=source_id,
            source_type=source_type,
            benefit_id=benefit_id,
            topic_tags=tags,
            recency_date=recency_date,
            chunk_index=i,
            total_chunks=total,
        )
        for i, c in enumerate(overlapped)
        if len(c.strip()) >= 50  # skip tiny fragments
    ]
