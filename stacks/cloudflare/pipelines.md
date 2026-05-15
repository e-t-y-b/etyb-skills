---
title: Pipelines
description: Cloudflare's HTTP-ingest → R2 (Parquet/JSON) data pipeline — the Cloudflare-native "fire-hose into analytics" path.
product:
  name: Pipelines
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, database-architect, ai-ml-engineer]
  authoritative_url: https://developers.cloudflare.com/pipelines/
  notes: "Data-ingest product (HTTP → R2 + transform); newer surface, naming and limits in flux."
---

## What it is

Pipelines is Cloudflare's data-ingest product — accept HTTP-posted events, buffer + batch them, write to [R2](/stacks/cloudflare/r2/) in Parquet or JSON. Later you query that R2 data ad-hoc with R2 SQL. The Cloudflare-native equivalent of "Kinesis Firehose → S3 → Athena" on AWS.

Authoritative reference: [developers.cloudflare.com/pipelines](https://developers.cloudflare.com/pipelines/).

## When to use

- **High-volume events you want to retain for offline analytics** — clickstream, IoT events, audit logs, telemetry.
- **Firehose ingestion** where you don't need low-latency reads but do need durable retention + occasional ad-hoc queries.
- **Per-tenant or per-environment data buckets** routed via Worker → Pipelines binding.

Don't use Pipelines when:

- **Low-latency operational queries** — use [Analytics Engine](/stacks/cloudflare/analytics-engine/) for online metrics.
- **Transactional data** — use [D1](/stacks/cloudflare/d1/).
- **Per-message decoupling with retries** — that's [Queues](/stacks/cloudflare/queues/).

## 2025-2026 currency anchors

- **Newer surface** — naming, limits, and binding shape are still evolving. Verify against [docs](https://developers.cloudflare.com/pipelines/) before committing to schema.
- **Pipelines + R2 SQL** is the canonical analytics-data-lake on Cloudflare.

## Patterns

### Worker → Pipelines → R2

```ts
async fetch(req, env, ctx) {
  const event = await req.json();
  await env.PIPELINE.send({
    user_id: event.userId,
    event: event.type,
    timestamp: Date.now(),
    url: req.url
  });
  return new Response(null, { status: 204 });
}
```

```toml
[[pipelines]]
binding = "PIPELINE"
pipeline = "my-events-pipeline"
```

Pipelines batches by time/size, writes Parquet to R2 with a partitioned key structure (e.g., `year=2026/month=05/day=14/`).

### Query the data with R2 SQL

```sql
SELECT user_id, COUNT(*) AS events
FROM 'r2://my-bucket/events/year=2026/month=05/'
WHERE event_type = 'click'
GROUP BY user_id
ORDER BY events DESC LIMIT 100;
```

Pair the Pipelines target bucket with R2 SQL for ad-hoc analytics; no Athena/Snowflake required.

## Anti-patterns

- **Using Pipelines for operational metrics** — wrong tool. Analytics Engine for online dashboards.
- **Schema drift** — Parquet schemas are baked into the file. Plan the event schema before scale; migrate carefully.
- **Per-event Workers calls without batching** — Pipelines does its own batching; just send events, don't pre-batch.

## Gotchas

1. **Newer product surface** — verify against current docs; bindings and config syntax may shift.
2. **R2 SQL costs are per-query** — scanning lots of data adds up.
3. **Partition discipline matters** — R2 SQL is faster when queries can prune partitions (year/month/day).
4. **Ordering not guaranteed** — events from one Worker may interleave with another's in R2.

## Cross-references

- [R2](/stacks/cloudflare/r2/) — destination for Pipelines data
- [Workers](/stacks/cloudflare/workers/) — runtime that posts events to the Pipelines binding
- [Analytics Engine](/stacks/cloudflare/analytics-engine/) — alternative for online metrics
- [Queues](/stacks/cloudflare/queues/) — alternative for decoupled message processing
- Role overlay: [database-architect on Cloudflare](/stacks/cloudflare/database-architect/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/pipelines](https://developers.cloudflare.com/pipelines/)
