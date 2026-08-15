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

1. Apply the inclusion criteria: direct relevance to smoking cessation; coverage
   of harms, dependence, withdrawal, recovery, treatment, cravings, coping, or
   relapse; an authoritative public-health, clinical, governmental, or
   established nonprofit publisher; scientifically supported content; and no
   unresolved contradiction with stronger sources.
2. Reject sources that lack adequate scientific support, have unclear or
   untrusted provenance, or conflict with stronger evidence without a defensible
   explanation.
3. Add an entry to `sources.yaml` with `ingested: false` and complete its
   governance metadata. Record the actual fetch date, reviewer, review scope,
   access/licensing status, inclusion decision, page/document version where
   available, and SHA-256 hash of the exact fetched content.
4. Preserve the fetched source snapshot in the controlled research archive.
   Public accessibility does not by itself establish permission to redistribute
   a full snapshot; archive and share it only as allowed by the source terms.
5. Run `ingest_kb.py` with the appropriate flags and validate the resulting
   source IDs, chunk counts, dimensions, and payload fields before promotion.
6. Set `ingested: true`, record the ingestion date and corpus version, and
   commit the manifest with the validation report. The manifest documents the
   intended corpus; a separate Qdrant inventory is required to prove deployed
   contents.

## Review and re-indexing

- Review every included source at least every six months and additionally when
  its URL, guideline, medically significant recommendation, or publisher status
  changes.
- The developer review assesses relevance, authority, scientific support, and
  consistency. Independent clinical/content review is recorded separately and
  must not be implied while its status is `pending`.
- At review, re-fetch the source, record the exact date and content hash, compare
  it with the archived version, document the reviewer and inclusion decision,
  and resolve changed or contradictory claims.
- Material changes create a new corpus version. Re-ingest into a staged
  collection, validate it, and only then promote it. Do not silently modify a
  corpus frozen for an active evaluation; benchmark results remain tied to the
  earlier corpus version.
- Removed sources retain an audit record with the exclusion reason and date;
  their points are deleted from the next corpus version and verified absent.

The original 28-source corpus predates this procedure. Git establishes
ingestion-evidence dates of 27 May 2026 for the initial five sources and 12 June
2026 for the expanded 23-source set, but exact fetch dates, source snapshots,
content versions, and hashes were not retained. `sources.yaml` marks these fields
as unavailable rather than reconstructing them retrospectively. All 28 sources
received developer review by Stefanos Theos; independent content review remains
pending.

## Retrieval threshold calibration

The prepared post-campaign retriever uses a minimum cosine score of `0.60`,
over-fetches four times the requested candidate count, removes
formatting-equivalent text, and retains at most one chunk per source before
applying the requested result limit. The cutoff was calibrated read-only against
the frozen corpus using 60 medical/NRT benchmark queries as positive controls
and 30 off-topic queries as negative controls. A raw cutoff of `0.65433` retained
95% of positive top results and rejected all negative top results. Rounding down
to `0.60` retained 59/60 positive top results (98.3%) while still rejecting all
30 negative top results in this authored suite.

The case-level artifact is stored at
`ingestion/artifacts/retrieval_threshold_analysis_2026-08-15.json`. These query
categories are proxy labels rather than clinician judgments of individual
chunks; the threshold is specific to this corpus, English suite, and
`BAAI/bge-small-en-v1.5`. Recalibrate after changing the corpus or embedding
model. The prepared behavior is not part of the benchmark frozen at commit
`7793af0` and must receive a new full evaluation after activation.
