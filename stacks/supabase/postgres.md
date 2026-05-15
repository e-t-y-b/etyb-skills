---
title: Postgres (Supabase-hosted)
description: The Postgres database under every Supabase project — the substrate everything else layers on top of.
product:
  name: Postgres
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, security-engineer, saas-architect]
  authoritative_url: https://supabase.com/docs/guides/database
  notes: "Default major bumped to PG17 in 2025; managed schemas (auth, storage, realtime, etc.) and extension defaults shift between Supabase platform releases."
---

## What it is

Every Supabase project is a single Postgres database with a constellation of managed schemas around it. Application data lives in `public` by default; the platform writes into `auth.*` (GoTrue), `storage.*` (Storage service), `realtime.*`, `graphql.*`, `pgsodium.*`, `vault.*`, `supabase_functions.*`, `cron.*`, and `net.*`. Connection routing happens through [Supavisor](/stacks/supabase/supavisor/) by default.

The default Postgres major for new projects is **PG17** (since 2025). PG16 projects can upgrade in-place via Studio → Project Settings → Infrastructure. See the [database guide](https://supabase.com/docs/guides/database) for the platform-shape view.

## When to use

Supabase Postgres is the right answer for any OLTP workload that wants RLS-driven authorization without an API gateway in front. The substrate is just Postgres — every Postgres pattern (CTEs, generated columns, partitioning, materialized views, logical replication) works. The places it stops being "just Postgres":

- **You don't write to `auth.users`** — it's managed by the auth service. Extend via `public.profiles` joined by foreign key.
- **You can't install arbitrary extensions** — Supabase ships ~70 vetted extensions; you opt in via the dashboard.
- **Connection budget is finite**: tier determines max backend connections; route app traffic through [transaction pooler](/stacks/supabase/supavisor/).
- **The `postgres` role is privileged but not unbounded** — you don't get `superuser` for managed safety.

Pick Supabase Postgres over:
- **DynamoDB / single-tenant NoSQL** when you need relational queries, joins, or RLS.
- **Neon / Turso** when you want auth, storage, realtime, and edge functions bundled.
- **Self-hosted Postgres** when you want backups, PITR, monitoring, branching, MCP, and a UI for free.

Reach for self-hosted Postgres (or RDS) when you specifically need a Postgres extension Supabase doesn't ship, or a custom replication topology Supabase doesn't expose.

## 2025-2026 currency anchors

- **PG17 is the default for new projects** (2025). PG16 → PG17 path is in-place via the dashboard; pre-check flags any extension version conflicts. After upgrade, some extensions (notably `pg_graphql`, `pg_cron`, `wrappers`) may need a re-create.
- **`pg_stat_statements` is on by default.** Always.
- **Read replicas** (Pro+) are eventually consistent (<100ms typical lag); application code must opt-in by URL.
- **PITR** (Point-in-Time Recovery) on Pro+ — restore to any point in the last 7 days (configurable to 28).
- **Connection limits scale with compute tier.** Supavisor multiplexes thousands of clients onto the backend budget; you still need to keep transactions short.
- **No Citus / TimescaleDB** on managed Supabase. If you need horizontal sharding, escalate to project-per-tenant.

## Patterns and anti-patterns

### Patterns

**Use the managed schemas as foreign-key anchors, not extension points.** `public.profiles (id uuid primary key references auth.users(id) on delete cascade)` is the canonical pattern; never `alter table auth.users add column`. The auth service owns that table's shape.

**Default to UUIDs for primary keys.** `uuid` (random) or `uuidv7` (time-ordered) — both fit RLS patterns and avoid coordination across branches. Use `bigserial` only when you specifically need monotonic numeric IDs for ordering or external integration.

**Enable `pg_stat_statements` queries in your day-2 dashboard.** This is your hottest-path observability:

```sql
select calls, total_exec_time::int as total_ms, mean_exec_time::int as mean_ms, query
from pg_stat_statements
order by total_exec_time desc
limit 20;
```

**Use generated columns for derived data.** `tsvector` indices for full-text, materialized counts, anything you'd otherwise rebuild on every read.

### Anti-patterns

- **Treating the database as schemaless.** JSONB is for genuinely variable shape (custom fields, raw payloads), not as a substitute for normalized tables.
- **Long-running transactions on transaction pooler.** Anything that holds a backend connection >100ms median is operating outside the pooler's intent. Move to a worker.
- **Adding columns to `auth.users`.** Use `public.profiles` instead.
- **Running `pg_cron` jobs directly from the SQL editor for production.** Use [Supabase Cron](/stacks/supabase/supabase-cron/) for the audit trail.

## Gotchas

- **The `postgres` role is the default migration role; it bypasses RLS.** When debugging "data leaked across tenants," check whether the code path is using service-role (which is `postgres` privilege) before blaming the policy.
- **In-place major version upgrades have downtime.** Schedule outside release windows.
- **`pg_stat_statements` can drop entries under heavy load.** For complete observability, ship pg_stat_statements snapshots to a SIEM.
- **Connection budget is per-project, not per-environment.** Staging and production on separate projects (not separate schemas).
- **The free tier pauses inactive projects.** Pro+ for any real workload.

## Cross-references

- [Row-Level Security](/stacks/supabase/row-level-security/) — the authorization plane on top of Postgres
- [Supavisor](/stacks/supabase/supavisor/) — connection routing and pooler modes
- [Migrations](/stacks/supabase/migrations/) — declarative vs diff-based workflows
- [Branching](/stacks/supabase/branching/) — preview databases per PR
- [database-architect role view](/stacks/supabase/database-architect/) — schema strategy and index design
- Supabase docs: [Database guide](https://supabase.com/docs/guides/database)
