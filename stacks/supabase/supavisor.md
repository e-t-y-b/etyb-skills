---
title: Supavisor
description: Supabase's connection pooler. Replaced PgBouncer as default in 2024. Transaction vs session mode determines which Postgres features work.
product:
  name: Supavisor
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect, devops-engineer]
  authoritative_url: https://github.com/supabase/supavisor
  notes: "Pooler mode behavior (prepared statements, SET, LISTEN, advisory locks) is THE source of broken-in-prod ORM bugs."
---

## What it is

Supavisor is Supabase's open-source connection pooler — a multi-tenant scalable proxy that sits between application clients and Postgres backend connections. As of 2024, it's the **default pooler** on every new Supabase project; PgBouncer is gone for new projects.

Source: [github.com/supabase/supavisor](https://github.com/supabase/supavisor).

## When to use

You use Supavisor whether you want to or not — every Supabase project routes through it by default. The question is **which mode** for which workload.

| URL | Pooler? | Mode | Port | When |
|-----|---------|------|------|------|
| **Direct** | None | — | `5432` | Studio, `psql` debugging, replication subscribers — limited connection count |
| **Session pooler** | Supavisor session | Session | `5432` (pooler hostname) | Migrations, prepared statements, `LISTEN/NOTIFY`, long-running app servers |
| **Transaction pooler** | Supavisor transaction | Transaction | `6543` | **Default for app traffic** — serverless, Edge Functions, Vercel/Lambda/Cloudflare Workers |

## 2025-2026 currency anchors

- **Replaced PgBouncer** as default in 2024. Raw PgBouncer port `6432` from older guides → use `6543` (transaction) or pooler hostname (session) instead.
- **Transaction mode disables prepared statements** by default — ORMs (Prisma, postgres-js, Drizzle, Kysely) need explicit config.
- **Multiplexes thousands of client connections** onto the project's backend connection budget.
- **Connection budget scales with project compute tier.**

## Patterns and anti-patterns

### Patterns

**Default routing rule:**
- Serverless / Edge / Lambda / Workers → **transaction pooler** (`:6543`).
- Long-lived Node/Bun/Rails/Django servers → **session pooler**.
- Migrations / ETL / `LISTEN/NOTIFY` / advisory locks → **session pooler** or direct.
- Studio / debug `psql` / replication → **direct**.

**ORM compatibility matrix** for transaction pooler:

| ORM | Required config |
|-----|-----------------|
| `supabase-js` (PostgREST) | N/A — uses HTTP, not Postgres wire protocol |
| postgres-js | `postgres(url, { prepare: false })` |
| node-postgres (`pg`) | don't call `client.prepare()`; set short `statement_timeout` |
| Prisma | URL: `?pgbouncer=true&connection_limit=1` |
| Drizzle (postgres-js) | inherits — `prepare: false` |
| Kysely (postgres-js dialect) | `prepare: false` |
| TypeORM | `prepareStatements: false` |

**Keep transactions short.** Aim for sub-100ms median on transaction-pooled traffic. Anything that holds a connection for seconds belongs in session pooler or a worker process.

**Statement timeouts at the role level:**

```sql
alter role authenticated set statement_timeout = '5s';
alter role service_role set statement_timeout = '30s';
```

### Anti-patterns

- **Prepared statements via transaction pooler without ORM config.** First query throws `prepared statement "..." does not exist`. The classic Supavisor-trips-Prisma bug.
- **`SET search_path` (non-LOCAL) on transaction pooler.** Doesn't persist between checkouts. Use `SET LOCAL` inside a transaction.
- **Session-level advisory locks** (`pg_advisory_lock`) on transaction pooler — locks die between transactions. Use transaction-level (`pg_advisory_xact_lock`).
- **`LISTEN/NOTIFY` on transaction pooler.** Listeners die between transactions. Use Supabase Realtime / Broadcast instead.
- **Long-running transactions on transaction pooler.** A 30-second transaction holds a backend slot from a budget meant for thousands of short transactions. Move to a worker.
- **Pre-Supavisor port `6432`** from older docs — that was PgBouncer. Use `6543` for transaction or pooler hostname for session.

## Gotchas

- **Prepared statements break silently** until first prepared query runs in prod. Add a sanity-check query in staging that exercises the prepared-statement path.
- **Temp tables don't survive between transactions** on transaction mode.
- **Cursors that outlive a transaction** don't work on transaction mode.
- **`SET LOCAL search_path = ''`** is still needed inside `SECURITY DEFINER` functions even on transaction pooler — that's set during the transaction, so it works.
- **Connection count math**: client count × idle time / backend count = whether you're saturating. Use `select * from pg_stat_activity` to see.
- **Different pooler hostnames** for transaction vs session — use the right one. Studio shows both under Project Settings → Database.

## Cross-references

- [Postgres](/stacks/supabase/postgres/) — what Supavisor pools
- [Migrations](/stacks/supabase/migrations/) — needs session pooler
- [Edge Functions](/stacks/supabase/edge-functions/) — defaults to transaction pooler when using ORMs
- [backend-architect role view](/stacks/supabase/backend-architect/) — ORM selection rules
- [database-architect role view](/stacks/supabase/database-architect/) — connection-saturation diagnosis
- Source: [github.com/supabase/supavisor](https://github.com/supabase/supavisor)
