---
title: Dataflow
description: Managed Apache Beam — stream + batch ETL with autoscaling, dynamic rebalancing, GPU support. The default for non-trivial data pipelines on GCP.
product:
  name: Dataflow
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/dataflow/docs
  notes: "Dataflow Prime + GPU support; Apache Beam managed; autoscaling and dynamic rebalancing are the signature features."
---

## What it is

Dataflow is GCP's managed Apache Beam service — unified stream + batch processing with autoscaling, dynamic rebalancing, and GCP-native sources/sinks. Use it when your data pipeline outgrows simple SQL ([BigQuery continuous queries](/stacks/gcp/bigquery/)) or simple-shape connectors ([Pub/Sub BigQuery subscription](/stacks/gcp/pub-sub/)).

Authoritative reference: [cloud.google.com/dataflow/docs](https://cloud.google.com/dataflow/docs).

## When to use

Pick Dataflow when:
- Complex stream or batch transformations (multi-stage pipelines, joins, windowing)
- Need autoscaling worker count dynamically with load
- GPU-accelerated processing (Dataflow GPU support)
- Cross-cloud or multi-source pipelines

Don't pick Dataflow when:
- Just need to ingest Pub/Sub to BigQuery → use [Pub/Sub BigQuery subscription](/stacks/gcp/pub-sub/)
- SQL-only transformations in BigQuery → use [Dataform](/stacks/gcp/dataform/) or [continuous queries](/stacks/gcp/bigquery/)
- Existing Spark code dominates → use [Dataproc](/stacks/gcp/dataproc/)
- CDC database replication → use Datastream

## 2025-2026 currency anchors

- **Dataflow Prime** — autotuning + autoscaling improvements; vertical autoscaling per worker.
- **GPU support** — for ML pipelines, image/video processing, accelerated transforms.
- **Streaming engine** is the default for new streaming jobs.

## Patterns

### Simple Pub/Sub → BigQuery streaming pipeline (Python)

```python
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

def parse(msg):
    import json
    return json.loads(msg.decode("utf-8"))

options = PipelineOptions(
    runner="DataflowRunner",
    project="my-proj",
    region="us-central1",
    streaming=True,
    temp_location="gs://my-bucket/tmp",
)

with beam.Pipeline(options=options) as p:
    (p
     | "Read" >> beam.io.ReadFromPubSub(subscription="projects/my-proj/subscriptions/events-sub")
     | "Parse" >> beam.Map(parse)
     | "Filter" >> beam.Filter(lambda r: r.get("type") == "order")
     | "Window" >> beam.WindowInto(beam.window.FixedWindows(60))
     | "Write" >> beam.io.WriteToBigQuery(
         "my-proj:dataset.orders",
         schema="order_id:STRING,amount:FLOAT,timestamp:TIMESTAMP",
         write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
     ))
```

### Flex Templates

For reusable pipelines, build a Flex Template (containerized Beam pipeline) and parameterize via launch options. Operations launch via gcloud or CI.

## Anti-patterns

- **Dataflow for simple Pub/Sub → BigQuery ingestion** — use Pub/Sub BigQuery subscription, not a Dataflow job.
- **Stateful processing without windowing** — unbounded streams need explicit windows or you'll accumulate state indefinitely.
- **No DLQ for failed transforms** — output side-channel for unprocessable records; don't drop silently.

## Gotchas

- **Cold start** for streaming jobs can be minutes; use **always-on** patterns for latency-sensitive pipelines.
- **Worker types**: pick deliberately; n2 / n4 for general, GPU types for accelerated.
- **Beam SDK version** matters; pin in dependencies.
- **Streaming Engine vs classic** — Streaming Engine is the modern path; classic exists for back-compat.

## Cross-references

- Related: [Pub/Sub](/stacks/gcp/pub-sub/), [BigQuery](/stacks/gcp/bigquery/), [Dataproc](/stacks/gcp/dataproc/), [BigQuery continuous queries](/stacks/gcp/bigquery/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [backend-architect on GCP](/stacks/gcp/backend-architect/)
- Authoritative: [cloud.google.com/dataflow/docs](https://cloud.google.com/dataflow/docs)
