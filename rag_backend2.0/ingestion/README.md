# Ingestion Pipeline

Scripts for building and maintaining the Hailey 2.0 knowledge base in Qdrant Cloud.

## Setup

```bash
pip install ".[ingestion]"
cp ../.env.example ../.env
# Fill in QDRANT_URL, QDRANT_API_KEY, CF_ACCOUNT_ID, CF_WORKERS_AI_TOKEN
```

## Commands

### Ingest a single file
```bash
python -m ingestion.ingest_kb --file path/to/document.pdf --source-type government
```

### Ingest a URL
```bash
python -m ingestion.ingest_kb --url https://www.nhs.uk/live-well/quit-smoking/ --source-type government --source-id nhs_quit
```

### Ingest a whole folder
```bash
python -m ingestion.ingest_kb --folder path/to/docs/ --source-type peer_reviewed
```

### Re-ingest all 14 health benefit sources (run once on fresh cluster)
```bash
python -m ingestion.reingest_health_benefits
```

## Qdrant Collections

| Collection | Purpose | Typical size |
|---|---|---|
| `kb_chunks` | General cessation knowledge base | ~500–2000 chunks |
| `health_benefit_chunks` | 14 health benefit sources, tagged with `benefit_id` | ~200–500 chunks |

## Chunk format

Each chunk stored in Qdrant has this payload:
```json
{
  "content": "...",
  "source_id": "nhs_quit_benefits",
  "source_type": "government",
  "benefit_id": "1yr",
  "topic_tags": ["health_benefit", "cardiovascular"],
  "recency_date": "2023-06-01",
  "chunk_index": 3,
  "total_chunks": 12
}
```

## Adding new sources

1. Add an entry to `sources.yaml` with `ingested: false`
2. Run `ingest_kb.py` with the appropriate flags
3. Set `ingested: true` in `sources.yaml`
4. Commit `sources.yaml` (it is the ground truth for what's in the KB)
