---
title: NRQL + NRDB
description: New Relic's query language (NRQL, closer to SQL) over the NRDB telemetry database — Materialized Views, Drop Rules, Compute Units billing.
product:
  name: NRQL + NRDB
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer, devops-engineer]
  authoritative_url: https://docs.newrelic.com/docs/nrql/
  notes: "NRQL syntax stable; CU billing model unchanged; Materialized Views (2024+) for repeated heavy queries."
---

## What it is

NRDB is the unified telemetry database underpinning New Relic — metrics, events, logs, traces all queryable via **NRQL** (closer to SQL than PromQL/SignalFlow/SPL). See [docs.newrelic.com/docs/nrql](https://docs.newrelic.com/docs/nrql/).

```sql
SELECT
  filter(count(*), WHERE numeric(http.response.status_code) < 500) / count(*) AS availability
FROM Span
WHERE service.name = 'checkout-api'
SINCE 5 minutes ago
```

## When to use

NRQL is the lingua franca for any work on NR — dashboards, alerts, SLO definitions, ad-hoc investigation. Power users productive faster than with vendor-specific DSLs.

## 2025-2026 currency anchors

- **Materialized Views (2024+)** — pre-compute expensive queries; reduce CU consumption on long-window dashboards.
- **Drop Rules** — drop events at ingest, before storage. Pipeline-level cost control.
- **NRQL Drop Rules in alerts** — prevent expensive queries from running 24/7.

## Patterns

- **Materialized Views for 90d/1y dashboards** — refresh hourly, query against the view.
- **Drop Rules for debug-level events** in production — drop at ingest, save GB + CU.
- **`SINCE` clauses tight** — `SINCE 1 day ago` vs `SINCE 30 days ago` is a 30x CU difference.
- **Use `LIMIT MAX`** when paginating — explicit cap.

## Anti-patterns

- **`FACET` on high-cardinality fields** (user_id, request_id, full URL) — millions of result rows, CU burn.
- **Unbounded `SINCE`** clauses — `SINCE 1 year ago` on a tier-1 dashboard.
- **Dashboards with 50+ widgets each running their own NRQL** — bulk Compute Unit consumption.

## Gotchas

- **CU consumption is hard to forecast** — varies with query complexity, data volume, FACET cardinality.
- **NRQL `SELECT *` is rejected** — must select specific fields.
- **`UNIQUE COUNT` is expensive** at scale — use `cardinality()` estimators when approximate counts suffice.

## Cross-references

- NR APM → [newrelic-apm](/stacks/observability/newrelic-apm/)
- NR Alert Conditions (NRQL-based) → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.newrelic.com/docs/nrql](https://docs.newrelic.com/docs/nrql/), [NerdGraph](https://docs.newrelic.com/docs/apis/nerdgraph/)
