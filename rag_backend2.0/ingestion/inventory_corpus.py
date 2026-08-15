"""Create a non-content Qdrant corpus inventory for evaluation provenance."""
from __future__ import annotations

import argparse
import asyncio
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
from typing import Any

from qdrant_client import AsyncQdrantClient
import yaml

from app.config import settings


def _jsonable(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return _jsonable(value.model_dump(mode="json"))
    if isinstance(value, dict):
        return {str(key): _jsonable(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_jsonable(item) for item in value]
    return value


def _canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        _jsonable(value), sort_keys=True, separators=(",", ":"), ensure_ascii=False,
    ).encode("utf-8")


def _sha256(value: Any) -> str:
    return hashlib.sha256(_canonical_bytes(value)).hexdigest()


def _value_type(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int):
        return "integer"
    if isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__


async def _scroll_all(client: AsyncQdrantClient, collection: str) -> list[Any]:
    points: list[Any] = []
    offset = None
    while True:
        page, offset = await client.scroll(
            collection_name=collection,
            limit=256,
            offset=offset,
            with_payload=True,
            with_vectors=True,
        )
        points.extend(page)
        if offset is None:
            return points


async def _inventory_collection(client: AsyncQdrantClient, name: str) -> dict[str, Any]:
    info = await client.get_collection(name)
    points = await _scroll_all(client, name)
    points.sort(key=lambda point: str(point.id))

    schema: dict[str, set[str]] = defaultdict(set)
    field_presence: Counter[str] = Counter()
    source_counts: Counter[str] = Counter()
    dimensions: Counter[int] = Counter()
    identifiers: list[dict[str, Any]] = []
    corpus_hasher = hashlib.sha256()

    for point in points:
        payload = dict(point.payload or {})
        vector = point.vector
        if isinstance(vector, list):
            dimensions[len(vector)] += 1
        elif isinstance(vector, dict):
            for named_vector in vector.values():
                if isinstance(named_vector, list):
                    dimensions[len(named_vector)] += 1

        for key, value in payload.items():
            schema[key].add(_value_type(value))
            field_presence[key] += 1

        source_id = str(payload.get("source_id", "<missing>"))
        source_counts[source_id] += 1
        identifiers.append({
            "point_id": str(point.id),
            "source_id": payload.get("source_id"),
            "chunk_index": payload.get("chunk_index"),
            "total_chunks": payload.get("total_chunks"),
            "benefit_id": payload.get("benefit_id"),
        })
        corpus_hasher.update(_canonical_bytes({
            "point_id": str(point.id), "payload": payload, "vector": vector,
        }))
        corpus_hasher.update(b"\n")

    required = ["source_id", "source_type", "chunk_index"]
    if name == settings.qdrant_kb_collection:
        required.extend(["total_chunks", "topic_tags", "recency_date"])
    else:
        required.append("benefit_id")
    content_present = sum(
        1 for point in points if (point.payload or {}).get("text") or (point.payload or {}).get("content")
    )
    completeness = {
        field: {"present": field_presence[field], "missing": len(points) - field_presence[field]}
        for field in required
    }
    completeness["text_or_content"] = {
        "present": content_present, "missing": len(points) - content_present,
    }
    required_complete = all(item["missing"] == 0 for item in completeness.values())

    configuration = _jsonable(info.config)
    return {
        "collection": name,
        "reported_points_count": info.points_count,
        "inventoried_points_count": len(points),
        "vector_dimensions": {str(key): value for key, value in sorted(dimensions.items())},
        "payload_schema": {key: sorted(values) for key, values in sorted(schema.items())},
        "required_payload_fields": required + ["text_or_content"],
        "payload_completeness": completeness,
        "required_payload_complete": required_complete,
        "source_counts": dict(sorted(source_counts.items())),
        "source_chunk_identifiers": identifiers,
        "collection_configuration": configuration,
        "collection_configuration_sha256": _sha256(configuration),
        "corpus_sha256_including_payload_and_vectors": corpus_hasher.hexdigest(),
    }


async def create_inventory(args: argparse.Namespace) -> dict[str, Any]:
    client = AsyncQdrantClient(
        url=settings.qdrant_url,
        api_key=settings.qdrant_api_key or None,
        timeout=60,
        prefer_grpc=False,
    )
    try:
        collections = [
            await _inventory_collection(client, settings.qdrant_kb_collection),
            await _inventory_collection(client, settings.qdrant_health_benefits_collection),
        ]
    finally:
        await client.close()

    manifest_git_path = "rag_backend2.0/ingestion/sources.yaml"
    manifest_bytes = subprocess.check_output(
        ["git", "show", f"{args.manifest_commit}:{manifest_git_path}"],
        cwd=Path(__file__).parents[2],
    )
    manifest = yaml.safe_load(manifest_bytes)
    manifest_ids = sorted(source["source_id"] for source in manifest["sources"])
    deployed_kb_ids = sorted(collections[0]["source_counts"])
    inventory = {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "read_only_snapshot": True,
        "application_commit": args.application_commit,
        "deployed_space_revision": args.space_revision,
        "benchmark_run_id": args.benchmark_run_id,
        "qdrant_endpoint_host": settings.qdrant_url.split("//", 1)[-1].split("/", 1)[0],
        "source_manifest_revision": args.manifest_commit,
        "source_manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
        "manifest_deployment_comparison": {
            "manifest_source_count": len(manifest_ids),
            "deployed_kb_source_count": len(deployed_kb_ids),
            "manifest_sources_absent_from_kb_chunks": sorted(set(manifest_ids) - set(deployed_kb_ids)),
            "kb_chunk_sources_absent_from_manifest": sorted(set(deployed_kb_ids) - set(manifest_ids)),
            "counts_match": len(manifest_ids) == len(deployed_kb_ids),
            "source_sets_match": set(manifest_ids) == set(deployed_kb_ids),
        },
        "collections": collections,
    }
    inventory["snapshot_sha256"] = _sha256(inventory)
    return inventory


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--application-commit", required=True)
    parser.add_argument("--manifest-commit", required=True)
    parser.add_argument("--space-revision", required=True)
    parser.add_argument("--benchmark-run-id", required=True)
    args = parser.parse_args()

    inventory = asyncio.run(create_inventory(args))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(inventory, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "output": str(args.output),
        "snapshot_sha256": inventory["snapshot_sha256"],
        "collections": {
            item["collection"]: item["inventoried_points_count"]
            for item in inventory["collections"]
        },
    }))


if __name__ == "__main__":
    main()
