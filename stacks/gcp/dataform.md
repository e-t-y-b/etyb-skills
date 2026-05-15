---
title: Dataform
description: SQL-based ELT orchestration in BigQuery — version control, testing, dependency management. Integrated into BigQuery Studio.
product:
  name: Dataform
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/dataform/docs
  notes: "Integrated into BigQuery Studio (2024-2025); SQL ELT orchestration with git-backed version control."
---

## What it is

Dataform is GCP's managed SQL ELT orchestration in BigQuery. Define SQLX models (SQL with Jinja-style templating), declare dependencies between them, run assertions / unit tests, version everything in git. **Integrated into BigQuery Studio** (2024-2025) — the authoring surface is now alongside SQL queries and notebooks.

Dataform is the GCP-native alternative to dbt for teams that want BigQuery-only ELT without an external runtime.

Authoritative reference: [cloud.google.com/dataform/docs](https://cloud.google.com/dataform/docs).

## When to use

Pick Dataform when:
- SQL-based transformations in BigQuery dominate your pipeline
- Want version-controlled SQL with dependency DAG, scheduling, assertions
- Team doesn't want to operate dbt Cloud / dbt Core externally
- BigQuery is the single warehouse target

Don't pick Dataform when:
- Multi-warehouse target (Snowflake + BigQuery) — dbt is more portable
- Transformations require Python / complex logic — use [Dataflow](/stacks/gcp/dataflow/) or notebook in BigQuery Studio
- Existing dbt investment is significant — dbt also runs against BigQuery

## 2025-2026 currency anchors

- **Integrated into BigQuery Studio** — author Dataform alongside SQL queries and notebooks in one UI.
- **Git-backed** workflow (GitHub, GitLab, Cloud Source Repositories).
- **Scheduled execution** via Cloud Scheduler or release configs.
- **Assertions** for data quality tests (row count, uniqueness, null checks).

## Patterns

### SQLX model

```sqlx
-- definitions/orders_daily.sqlx
config {
  type: "table",
  schema: "analytics",
  description: "Daily order aggregates",
}

SELECT
  DATE(order_timestamp) AS order_date,
  COUNT(*) AS order_count,
  SUM(amount_cents) AS total_revenue_cents
FROM ${ref("orders_raw")}
WHERE order_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
GROUP BY order_date
```

`${ref("orders_raw")}` declares a dependency; Dataform builds the DAG.

### Assertions

```sqlx
config {
  type: "assertion",
}

SELECT order_id, COUNT(*) AS cnt
FROM ${ref("orders_daily")}
GROUP BY order_id
HAVING cnt > 1
```

If the assertion returns rows, the run fails — data quality gate.

## Anti-patterns

- **Dataform without git** — losing version control on transformations is operational debt.
- **No assertions** — silent data quality drift.
- **Cross-warehouse aspirations** — Dataform is BigQuery-only.

## Gotchas

- **Refresh strategy** (full table, incremental, snapshot) matters for cost; pick deliberately per model.
- **Variables and includes** support per-environment config; use for dev/staging/prod parity.

## Cross-references

- Related: [BigQuery](/stacks/gcp/bigquery/), [Dataflow](/stacks/gcp/dataflow/), [Dataproc](/stacks/gcp/dataproc/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Authoritative: [cloud.google.com/dataform/docs](https://cloud.google.com/dataform/docs)
