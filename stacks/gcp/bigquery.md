---
title: BigQuery
description: "Serverless analytical warehouse — BigQuery Studio unification, vector search GA, continuous queries GA, ML in SQL via `REMOTE MODEL`, editions vs on-demand pricing."
product:
  name: BigQuery
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer, system-architect, backend-architect]
  authoritative_url: https://cloud.google.com/bigquery/docs
  notes: "BigQuery Studio unification 2024-2025, vector search GA, continuous queries GA, BigQuery editions vs on-demand pricing repositioned."
---

## What it is

BigQuery is GCP's serverless analytical warehouse — columnar storage, separation of storage and compute, scales transparently from megabytes to petabytes. **BigQuery Studio** (2024-2025) unifies SQL + notebook (PySpark / Python) + Dataform + Spark in one IDE.

Authoritative reference: [cloud.google.com/bigquery/docs](https://cloud.google.com/bigquery/docs).

## When to use

Pick BigQuery for:
- Analytical workloads, ad-hoc SQL on large datasets
- Data warehousing — ELT pipelines with [Dataform](/stacks/gcp/dataform/) / Dataflow / Pub/Sub
- ML on warehouse data via [BigQuery ML](/stacks/gcp/bigquery-ml/)
- Vector search at warehouse scale (batch / analytical)
- Cross-cloud analytics via [BigLake](/stacks/gcp/biglake/) / BigQuery Omni

Don't use BigQuery when:
- Transactional / OLTP workload — use [Cloud SQL](/stacks/gcp/cloud-sql/) / [AlloyDB](/stacks/gcp/alloydb/) / [Spanner](/stacks/gcp/spanner/)
- Low-latency request-response (BigQuery is analytical; per-query overhead is seconds)
- High-frequency single-row reads — use [Bigtable](/stacks/gcp/bigtable/) / [Firestore](/stacks/gcp/firestore/)

## 2025-2026 currency anchors

- **BigQuery Studio** (GA) — unified SQL + notebook + Spark + Dataform IDE. Older "BigQuery Console + separate Dataform UI" mental model is obsolete.
- **Vector search GA** — `VECTOR_SEARCH(...)`, `CREATE VECTOR INDEX`.
- **Continuous queries GA** — streaming SQL views into Bigtable or another BigQuery table.
- **Materialized views** with incremental refresh; native + BigLake source tables.
- **BI Engine** — sub-second interactive analysis; auto-accelerates leaf-level queries.
- **Object tables** — query unstructured data (images, audio) in Cloud Storage.
- **`ML.GENERATE_TEXT`, `ML.GENERATE_EMBEDDING`** — call Vertex AI Gemini / embedding models from SQL via `REMOTE MODEL`.
- **Editions vs on-demand pricing** repositioned: editions for sustained workloads, on-demand for ad-hoc / low-volume.

## Patterns

### Partitioning + clustering

For any table over a few hundred MB, **partition + cluster**:

```sql
CREATE TABLE `proj.dataset.orders` (
  order_id STRING,
  customer_id STRING,
  amount NUMERIC,
  ordered_at TIMESTAMP
)
PARTITION BY DATE(ordered_at)
CLUSTER BY customer_id, order_id;
```

Partitions prune by date filter; clustering further reduces bytes scanned per query. Without these, every query is a full scan.

### Vector search

```sql
CREATE OR REPLACE VECTOR INDEX product_embeddings_idx
ON `proj.dataset.products`(embedding)
OPTIONS(distance_type = 'COSINE', index_type = 'IVF');

SELECT base.id, base.name, distance
FROM VECTOR_SEARCH(
  TABLE `proj.dataset.products`,
  'embedding',
  (SELECT embedding FROM ML.GENERATE_EMBEDDING(
    MODEL `proj.dataset.text_embedding_model`,
    (SELECT 'widget' AS content)
  )),
  top_k => 10
);
```

Right for analytical / batch vector search. Wrong for low-latency request-response — use [AlloyDB AI](/stacks/gcp/alloydb/) or [Vertex AI Vector Search](/stacks/gcp/vertex-ai/).

### Continuous queries

```sql
CREATE CONTINUOUS QUERY my_agg
OPTIONS(target_dataset='streaming_output')
AS SELECT
  window_start, user_id, COUNT(*) as event_count
FROM TABLE(TUMBLE(TABLE `events`, DESCRIPTOR(event_time), 'INTERVAL 1 MINUTE'))
GROUP BY window_start, user_id;
```

Continuous queries replace [Dataflow](/stacks/gcp/dataflow/) for many simple streaming aggregations.

### Editions vs on-demand

| Model | When |
|-------|------|
| **On-demand** ($6.25/TB scanned) | Ad-hoc analysis, < ~$5K/month total spend, unpredictable workloads |
| **Editions (Standard / Enterprise / Enterprise Plus)** — buy reserved slots | Sustained workloads >$5K/month, predictable patterns, cost predictability |

- **Standard** ($0.04/slot-hour): basic; up to 1600 max slots autoscale
- **Enterprise** ($0.06): BI Engine reservation, lineage, column-level security
- **Enterprise Plus** ($0.10): cross-region DR, customer-managed encryption keys

**The mistake**: putting a 50 GB/month workload on Enterprise edition. Editions cost more than on-demand for small workloads.

### Row-level security + column-level security

```sql
CREATE ROW ACCESS POLICY us_only_orders
ON `proj.dataset.orders`
GRANT TO ("group:us-team@example.com")
FILTER USING (country = 'US');
```

Plus column-level policy tags for sensitive columns (mask SSN, etc.). Implements data governance in-warehouse.

## Anti-patterns

- **No partitioning + clustering** on large tables — scan-cost time bomb.
- **Querying BigLake without materialized views** for repeat patterns — egress cost surprise.
- **BigQuery Editions for small workloads** — pay more than on-demand.
- **Synchronous BigQuery queries from a Cloud Run request handler** — BigQuery is analytical; pre-compute, materialize, or use BI Engine.
- **Every BI tool sees the raw table** — compliance liability; use authorized views / column policies / RLS.
- **No spend caps** — runaway query patterns can spike cost; set per-project quota.

## Gotchas

- **Streaming inserts** have a cost; consider Pub/Sub BigQuery subscription instead of writing your own streamer.
- **Time travel** is 7 days default, 28 max — use for accidental delete recovery.
- **`INFORMATION_SCHEMA.JOBS_BY_PROJECT`** is your friend for query analysis and cost attribution.
- **Materialized views** auto-refresh; pick refresh strategy per workload.

## Cross-references

- Related: [BigQuery ML](/stacks/gcp/bigquery-ml/), [BigLake](/stacks/gcp/biglake/), [Dataform](/stacks/gcp/dataform/), [Dataflow](/stacks/gcp/dataflow/), [Pub/Sub](/stacks/gcp/pub-sub/), [Vertex AI](/stacks/gcp/vertex-ai/), [Looker](/stacks/gcp/looker/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/)
- Authoritative: [cloud.google.com/bigquery/docs](https://cloud.google.com/bigquery/docs)
