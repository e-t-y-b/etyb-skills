---
title: Analytics Engine
description: Cloudflare's time-series datapoint store — write structured events from a Worker, query with SQL over HTTP, priced per million datapoints.
product:
  name: Analytics Engine
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, database-architect, backend-architect, sre-engineer]
  authoritative_url: https://developers.cloudflare.com/analytics/analytics-engine/
  notes: "SQL-over-HTTP querying stable; field schema (indexes + doubles + blobs) constrained — plan field assignments up front."
---

## What it is

Analytics Engine is Cloudflare's time-series datapoint store, callable from a [Worker](/stacks/cloudflare/workers/) via the `analytics_engine_datasets` binding. You `writeDataPoint({ indexes, doubles, blobs })`; later, you query with SQL over HTTP. Designed for high-write throughput and per-million-datapoints pricing — the canonical Cloudflare-native path for custom application metrics.

Authoritative reference: [developers.cloudflare.com/analytics/analytics-engine](https://developers.cloudflare.com/analytics/analytics-engine/).

## When to use

- **Custom application metrics** — per-tenant request counts, per-endpoint latency histograms, per-user feature usage.
- **High-cardinality counters** that would crush [KV](/stacks/cloudflare/kv/) or [D1](/stacks/cloudflare/d1/) — Analytics Engine is built for append-heavy.
- **Online dashboards over the last hour / day / week** — query latency is good enough for Grafana-style boards.
- **Cost-aware metrics pipeline** — when full Datadog metrics ingestion is too expensive but you still want SQL queryability.

Don't reach for Analytics Engine when:

- You need transactional consistency — it's append-only, not a DB.
- You need cross-row updates / deletes — same reason.
- You need very long retention with arbitrary querying — fan to [R2](/stacks/cloudflare/r2/) + [R2 SQL](/stacks/cloudflare/r2/) via [Pipelines](/stacks/cloudflare/pipelines/) or Logpush for that.

## 2025-2026 currency anchors

- **SQL API** is mature; supports filtering, aggregation, ordering, intervals (`NOW() - INTERVAL '1' HOUR`).
- **Field constraints** (indexes / doubles / blobs counts, per-datapoint size) are stable but worth re-verifying for new schemas.
- **Pricing** is per million datapoints — cheap relative to most metrics products at moderate scale.

## Patterns

### Write a datapoint from a Worker

`wrangler.toml`:

```toml
[[analytics_engine_datasets]]
binding = "ANALYTICS"
dataset = "app-events"
```

Handler:

```ts
env.ANALYTICS.writeDataPoint({
  indexes: ["api"],                          // up to 1 index for sampling key
  doubles: [response_time_ms, response_size_bytes],
  blobs: [tenant_id, endpoint, status_code.toString()]
});
```

### Query via SQL over HTTP

```sql
SELECT
  blob1 AS tenant_id,
  blob2 AS endpoint,
  COUNT(*) AS calls,
  AVG(double1) AS avg_latency_ms,
  quantileWeighted(0.95)(double1, 1) AS p95_latency_ms
FROM app_events
WHERE timestamp > NOW() - INTERVAL '1' HOUR
GROUP BY blob1, blob2
ORDER BY calls DESC
LIMIT 50;
```

```bash
curl -X POST \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"query": "SELECT ..."}' \
  https://api.cloudflare.com/client/v4/accounts/<id>/analytics_engine/sql
```

### Per-tenant SLO dashboards

```sql
SELECT
  blob1 AS tenant_id,
  (SUM(CASE WHEN blob3 LIKE '5%' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS error_rate
FROM app_events
WHERE timestamp > NOW() - INTERVAL '1' DAY
GROUP BY blob1
HAVING error_rate > 0.01;
```

Pair with Grafana or Cloudflare's dashboard widgets.

## Anti-patterns

- **Treating Analytics Engine as a DB.** No updates, no deletes (beyond retention windows), no transactions. It's a metrics store.
- **Writing a datapoint per minor event in a hot handler.** Per-million-datapoints pricing is cheap but cardinality × QPS can still add up — sample where it makes sense.
- **Forgetting which field is which.** `blob1`, `blob2`, `double1` aren't self-documenting. Maintain a schema document (or wrap the binding in a typed helper) so the next engineer doesn't have to guess.
- **High-cardinality blobs.** Blobs are queryable but not indexed in the traditional sense — cardinality on join fields affects query cost.

## Gotchas

1. **Field type constraints.** Total of indexes + doubles + blobs is capped per datapoint (check current docs for exact limits) and total size per datapoint is small (~5KB). Plan assignments up front.
2. **Retention is plan-dependent.** Default retention is short (~30-90 days); for long retention, push to [R2](/stacks/cloudflare/r2/) via [Pipelines](/stacks/cloudflare/pipelines/) or Logpush.
3. **Query latency** is good for dashboards but not real-time alerting — alerting on the SQL endpoint at < 1-minute granularity is fragile.
4. **No `JOIN` across datasets** — Analytics Engine SQL is single-table.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — write surface
- [Workers Logs](/stacks/cloudflare/workers-logs/) — complementary: logs vs metrics
- [Logpush](/stacks/cloudflare/logpush/) — long-retention fan-out
- [Pipelines](/stacks/cloudflare/pipelines/) — alternative for high-volume → R2 → SQL
- [D1](/stacks/cloudflare/d1/) — when you need transactional reads against the same data
- Role overlay: [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/), [database-architect on Cloudflare](/stacks/cloudflare/database-architect/)
- Authoritative: [developers.cloudflare.com/analytics/analytics-engine](https://developers.cloudflare.com/analytics/analytics-engine/), [SQL API reference](https://developers.cloudflare.com/analytics/analytics-engine/sql-api/)
