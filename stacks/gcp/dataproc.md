---
title: Dataproc
description: Managed Spark / Hadoop / Flink / Presto on GCP — Dataproc Serverless is the default for new Spark workloads in 2026.
product:
  name: Dataproc
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/dataproc/docs
  notes: "Dataproc Serverless GA — default for new Spark workloads; classic Dataproc clusters still supported for existing investments."
---

## What it is

Dataproc is GCP's managed Hadoop/Spark/Flink/Presto service. Two flavors:
- **Dataproc Serverless** (GA) — submit Spark jobs without provisioning clusters; Google manages everything. **Default for new workloads.**
- **Dataproc clusters** (classic) — you create and size a cluster; jobs run on it. For existing investments or workloads needing specific cluster customization.

Authoritative reference: [cloud.google.com/dataproc/docs](https://cloud.google.com/dataproc/docs).

## When to use

Pick Dataproc when:
- Existing Spark / Hadoop / Flink codebase
- ML pipelines that depend on Spark MLlib or PySpark patterns
- Migrating an on-prem Hadoop estate to GCP

For new pipelines on GCP without Spark legacy, evaluate [Dataflow](/stacks/gcp/dataflow/) or [BigQuery + Dataform](/stacks/gcp/dataform/) first — they're often simpler.

## 2025-2026 currency anchors

- **Dataproc Serverless** — default for new Spark workloads; no cluster management.
- **Spark + GPU** supported on Dataproc Serverless.
- **BigQuery Studio** integrates PySpark notebooks — write Spark code directly in the BQ Studio UI.

## Patterns

### Submit a Serverless Spark batch job

```bash
gcloud dataproc batches submit pyspark gs://my-bucket/scripts/etl.py \
  --region=us-central1 \
  --batch=etl-2026-05-14 \
  --deps-bucket=gs://my-bucket/deps
```

No cluster to create or tear down; pay for the batch runtime.

### Dataproc cluster (when Serverless doesn't fit)

```bash
gcloud dataproc clusters create my-cluster \
  --region=us-central1 \
  --enable-component-gateway \
  --num-workers=2 \
  --worker-machine-type=n2-standard-4 \
  --image-version=2.2-debian12
```

Pick Serverless unless you need a long-running cluster (e.g., interactive notebooks against persistent HDFS).

## Anti-patterns

- **Long-running Dataproc cluster** when Serverless covers the workload — paying for idle capacity.
- **Dataproc for new SQL-only transformations** — use [Dataform](/stacks/gcp/dataform/) in BigQuery Studio.

## Gotchas

- **Dataproc Serverless cold start** is a few minutes; not for interactive workloads.
- **Component versions** (Spark, Scala, Python) — pin and verify against your code.
- **HDFS** in Dataproc clusters is ephemeral by default; persist to [Cloud Storage](/stacks/gcp/cloud-storage/) for durability.

## Cross-references

- Related: [Dataflow](/stacks/gcp/dataflow/), [BigQuery](/stacks/gcp/bigquery/), [Dataform](/stacks/gcp/dataform/), [Cloud Storage](/stacks/gcp/cloud-storage/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Authoritative: [cloud.google.com/dataproc/docs](https://cloud.google.com/dataproc/docs)
