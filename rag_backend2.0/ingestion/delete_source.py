"""Delete every Qdrant chunk belonging to one exact source ID."""
from __future__ import annotations

import argparse
import asyncio

from qdrant_client.models import (
    FieldCondition, Filter, FilterSelector, MatchValue, PayloadSchemaType,
)

from app.config import settings
from app.retrieval.vector_store import get_qdrant_client


async def delete_source(source_id: str, collection: str) -> tuple[int, int]:
    client = get_qdrant_client()
    await client.create_payload_index(
        collection_name=collection,
        field_name="source_id",
        field_schema=PayloadSchemaType.KEYWORD,
        wait=True,
    )
    source_filter = Filter(must=[
        FieldCondition(key="source_id", match=MatchValue(value=source_id)),
    ])
    before = await client.count(
        collection_name=collection, count_filter=source_filter, exact=True,
    )
    await client.delete(
        collection_name=collection,
        points_selector=FilterSelector(filter=source_filter),
        wait=True,
    )
    after = await client.count(
        collection_name=collection, count_filter=source_filter, exact=True,
    )
    return before.count - after.count, after.count


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_id")
    parser.add_argument("--collection", default=settings.qdrant_kb_collection)
    args = parser.parse_args()
    removed, remaining = asyncio.run(delete_source(args.source_id, args.collection))
    print(f"removed={removed}; remaining={remaining}")
