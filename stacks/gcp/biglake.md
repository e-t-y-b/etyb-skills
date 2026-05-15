---
title: BigLake / BigQuery Omni
description: Cross-cloud querying — BigLake exposes Cloud Storage / S3 / Azure Blob as BigQuery tables with security policies; BigQuery Omni runs in AWS / Azure regions.
product:
  name: BigLake
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, system-architect, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/biglake/docs
  notes: "Cross-cloud querying of S3 + Azure Blob; cross-cloud joins GA; materialized views to dodge egress."
---

## What it is

**BigLake** tables expose Cloud Storage / S3 / Azure Blob data as queryable BigQuery tables with BigQuery security policies (column-level, row-level, dynamic masking). No data movement.

**BigQuery Omni** runs BigQuery compute in AWS / Azure regions; query S3 / Azure Blob without leaving those clouds. Cross-cloud joins (BigQuery + S3 + Azure Blob) GA.

Authoritative reference: [cloud.google.com/biglake/docs](https://cloud.google.com/biglake/docs).

## When to use

Pick BigLake when:
- Data lives in Cloud Storage and you want BigQuery's query engine + security model without ingestion
- Data lake on Cloud Storage with mixed access patterns (BQ for analytics, Spark for ML)
- Multi-format data (Parquet, ORC, Avro, JSON, CSV)

Pick BigQuery Omni when:
- Data lives in AWS S3 / Azure Blob and you can't (or won't) move it
- Cross-cloud analytics — join GCP warehouse with AWS / Azure data
- Compliance / contractual reasons keep data in another cloud

Don't use:
- For data that already lives in BigQuery — native tables are faster and cheaper
- When repeat queries pattern is heavy — egress / scan costs add up

## 2025-2026 currency anchors

- **Cross-cloud joins GA** — join GCP data with S3 / Azure Blob data in one query.
- **Materialized views over BigLake** GA — avoid repeated egress costs on S3 queries.
- **Iceberg / Delta Lake / Hudi** table format support — modern lakehouse formats queryable via BigLake.

## Patterns

### Create a BigLake table over Cloud Storage

```sql
CREATE EXTERNAL TABLE `proj.dataset.events_external`
WITH CONNECTION `proj.us.biglake-conn`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://my-bucket/events/*.parquet']
);
```

Apply row-level security and column policies as if it were a native table.

### Query Iceberg

```sql
CREATE EXTERNAL TABLE `proj.dataset.iceberg_orders`
WITH CONNECTION `proj.us.biglake-conn`
OPTIONS (
  format = 'ICEBERG',
  uris = ['gs://my-bucket/iceberg/orders/metadata/v1.metadata.json']
);
```

### Materialized view over BigLake

```sql
CREATE MATERIALIZED VIEW `proj.dataset.events_daily`
AS SELECT DATE(event_time) AS day, COUNT(*) AS n
FROM `proj.dataset.events_external`
GROUP BY day;
```

Avoids re-scanning the underlying S3 / GCS files for repeat queries.

## Anti-patterns

- **BigLake when ingestion to BigQuery is feasible** — native tables faster for hot data.
- **Querying BigLake without materialized views** for repeat patterns — egress / scan cost surprise.
- **No security policies on BigLake tables** — exposed via BigQuery is exposed.

## Gotchas

- **Egress costs** for BigQuery Omni cross-cloud queries — verify cost model before committing.
- **Format support** matters — Parquet/ORC/Iceberg perform best; CSV/JSON scan everything.
- **Permission model**: BigLake connections hold the IAM that grants BigQuery access to the external storage — secure them.

## Cross-references

- Related: [BigQuery](/stacks/gcp/bigquery/), [Cloud Storage](/stacks/gcp/cloud-storage/), [Dataform](/stacks/gcp/dataform/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [system-architect on GCP](/stacks/gcp/system-architect/)
- Authoritative: [cloud.google.com/biglake/docs](https://cloud.google.com/biglake/docs)
