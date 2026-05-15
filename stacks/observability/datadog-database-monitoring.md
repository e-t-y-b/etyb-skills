---
title: Datadog Database Monitoring
description: Query-level observability for Postgres, MySQL, MongoDB, SQL Server — explain plans, slow queries, blocking, deadlocks.
product:
  name: Datadog Database Monitoring (DBM)
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer, database-architect]
  authoritative_url: https://docs.datadoghq.com/database_monitoring/
  notes: "Coverage expanding: Postgres, MySQL, MongoDB, SQL Server, Oracle (2025); query-level telemetry priced per host."
---

## What it is

Datadog DBM collects query-level performance data — normalized query fingerprints, execution plans, lock waits, blocking sessions, deadlocks — for Postgres, MySQL, MongoDB, SQL Server, and Oracle (2025). Correlates query slowness with the [APM trace](/stacks/observability/datadog-apm/) that issued it. See [docs.datadoghq.com/database_monitoring](https://docs.datadoghq.com/database_monitoring/).

Pricing: per-host monitored. Add to existing DD Agent on the DB host (or use a sidecar pattern for managed DBs like RDS).

## When to use

Pick DBM when:
- You have N+1 query suspicion and want trace → query plan in one click.
- Postgres autovacuum, replication lag, or lock contention is killing latency.
- You're on Datadog and want unified DB + APM + infra.

Alternatives: **pganalyze** (Postgres-deep), **percona-pmm** (MySQL/Postgres OSS), **NR DB Monitoring** ([newrelic-apm](/stacks/observability/newrelic-apm/)), or `postgres-exporter` + Grafana ([prometheus-exporters](/stacks/observability/prometheus-exporters/)).

## 2025-2026 currency anchors

- **Oracle support GA 2025**.
- **Query samples + execution plans** captured for slow queries (configurable threshold).
- **Replication lag, deadlocks, blocking sessions** dashboards out-of-box.
- **Sensitive Data Scanner** ([datadog-sds](/stacks/observability/datadog-sds/)) extends to DB query parameters in 2024.

## Patterns

- **Enable on managed DBs (RDS, Cloud SQL) via sidecar Agent.**
- **Set query sample threshold** to capture explain plans only for queries >100ms (default).
- **Pair with trace correlation** — clicking a slow span surfaces the DB query, statement, and plan.

## Anti-patterns

- **DBM on every microservice's DB without budget** — per-host pricing adds up.
- **Capturing `db.statement` with raw PII** — DB queries often have user emails, IDs. Enable SDS or app-layer parameterization.
- **Treating slow-query report as a TODO list** without budget review — many slow queries are intentional (analytics).

## Gotchas

- Read-only replica monitoring needs separate Agent install with replica-specific tags.
- `pg_stat_statements` extension required for Postgres DBM; verify enabled in your RDS parameter group.
- Query normalization may lose context — two semantically different queries with the same fingerprint look identical.

## Cross-references

- DD APM trace correlation → [datadog-apm](/stacks/observability/datadog-apm/)
- PII in queries (db.statement) scrubbing → [security-engineer overlay](/stacks/observability/security-engineer/)
- Alternative: Postgres exporters → [prometheus-exporters](/stacks/observability/prometheus-exporters/)
- Authoritative: [docs.datadoghq.com/database_monitoring](https://docs.datadoghq.com/database_monitoring/)
