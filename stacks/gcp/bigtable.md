---
title: Bigtable
description: Petabyte-scale wide-column NoSQL with single-digit ms latency at any scale — time series, IoT telemetry, ad-tech, ML feature serving.
product:
  name: Bigtable
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, system-architect, ai-ml-engineer, social-platform-architect]
  authoritative_url: https://cloud.google.com/bigtable/docs
  notes: "Mature. Continuous materialized views Preview (2025-2026); HBase-compatible API; Key Visualizer for hotspot detection."
---

## What it is

Bigtable is GCP's wide-column NoSQL database — the same substrate that powers Google Search, Maps, and Analytics. Petabyte scale, single-digit-ms p99 latency at any scale, HBase API compatibility, designed for time series and high-throughput streaming workloads.

Bigtable is a different mental model from Cloud SQL/AlloyDB/Spanner — row keys matter intensely, schema is flexible columns within column families, queries are by row key range (no SQL, though there's a SQL Query API for select cases).

Authoritative reference: [cloud.google.com/bigtable/docs](https://cloud.google.com/bigtable/docs).

## When to use

Pick Bigtable when:
- **High-volume time series** — IoT telemetry, ad-tech events, financial tick data
- **Petabyte-scale** workload with sub-10ms p99 latency
- **ML feature serving** at scale — feature lookups for online inference
- HBase compatibility — existing HBase workload migrating

Don't pick Bigtable when:
- SQL access patterns dominate — use [BigQuery](/stacks/gcp/bigquery/) (analytical) or [Spanner](/stacks/gcp/spanner/) (transactional)
- Document model — use [Firestore](/stacks/gcp/firestore/)
- TimescaleDB extension on Cloud SQL would suffice — Bigtable's operational complexity (row key design) is real

## 2025-2026 currency anchors

- **Continuous materialized views** (Preview, 2025-2026) — real-time aggregation for reporting on top of Bigtable.
- **SQL Query API** — limited SQL syntax over Bigtable; useful for ad-hoc queries.
- **Key Visualizer** is the canonical hotspot-detection tool — use it during row-key design.
- **Cross-region replication** GA; doubles cost but provides DR posture.
- **Bigtable + BigQuery federation** for analytical queries that span hot store + warehouse.

## Patterns

### Row key design — the critical decision

Bigtable's perf depends entirely on row key design. Rules:

- **Lexicographic order**: rows stored in sorted order; range scans over consecutive keys are fast
- **Avoid hotspots**: monotonically-increasing keys (timestamps, sequential IDs) hotspot the trailing tablet
- **Reverse timestamps**: `ULONG_MAX - timestamp` for "newest-first" without hotspotting
- **Salt prefixes**: hash a portion of the key into the prefix to distribute load

Example for time series:
```
<entity_id>#<reverse_timestamp>
```

Range scan for entity X's recent data is fast (consecutive rows); writes distribute across tablets because `entity_id` varies.

### Create an instance

```bash
gcloud bigtable instances create my-instance \
  --cluster-config=id=my-cluster,zone=us-central1-b,nodes=3 \
  --display-name="Production telemetry" \
  --instance-type=PRODUCTION
```

Nodes scale linearly with QPS and storage. Use the **Autoscaling** option in production; manual node management at scale is operational toil.

### ML feature serving

Pattern: model serving service (Cloud Run / Vertex AI Endpoint) queries Bigtable for online features by `user_id`; falls back to defaults if not found; logs feature freshness for drift monitoring.

Bigtable's sub-10ms p99 makes it the canonical hot store for online ML features. See [Vertex AI Feature Store](/stacks/gcp/vertex-ai/) for the managed alternative.

## Anti-patterns

- **Monotonically increasing row keys** — guaranteed hotspot.
- **Designing row keys without Key Visualizer** — discover hotspots in prod instead of design.
- **No replication** when DR is required — Bigtable single-zone outage takes you down.
- **Bigtable when Cloud SQL with TimescaleDB would suffice** — Bigtable's learning curve is real; don't reach for it reflexively.

## Gotchas

- **Tall vs wide tables**: Bigtable favors wide tables (many cells per row); deep tables (many rows, few cells) work but are less idiomatic.
- **Compactions** happen automatically; range tombstones from `DROP` are deleted asynchronously.
- **GC policies** per column family control TTL and version retention; design carefully.
- **Emulator** for local development; useful for unit tests, less faithful for perf testing.

## Cross-references

- Related: [BigQuery](/stacks/gcp/bigquery/) (analytical federation), [Pub/Sub](/stacks/gcp/pub-sub/) (ingestion), [Vertex AI](/stacks/gcp/vertex-ai/) (online feature serving)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [system-architect on GCP](/stacks/gcp/system-architect/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Authoritative: [cloud.google.com/bigtable/docs](https://cloud.google.com/bigtable/docs)
