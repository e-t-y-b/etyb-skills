---
title: Supabase Cron
description: pg_cron wrapped in a dashboard UI with auth-bound auditability. Launched late 2024.
product:
  name: Supabase Cron
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect]
  authoritative_url: https://supabase.com/docs/guides/cron
  notes: "UI wrapper on pg_cron; the recommended surface for new work over raw cron.schedule(...) in the SQL editor."
---

## What it is

Supabase Cron is a managed UI on top of the [`pg_cron`](/stacks/supabase/pg-cron/) Postgres extension. It schedules SQL or Edge Function invocations on cron syntax, with run history, auth-bound auditability, and a dashboard editor. Launched late 2024.

Source: [Cron docs](https://supabase.com/docs/guides/cron).

## When to use

Use Supabase Cron for:
- **Worker polling on [Queues](/stacks/supabase/supabase-queues/)** — minute-level Edge Function invocation.
- **Hourly/daily housekeeping** — cleanup, retention, denormalization refresh.
- **Scheduled exports** — query → CSV → upload to Storage.
- **Warm-keep pings** to latency-critical Edge Functions.

Use plain [`pg_cron`](/stacks/supabase/pg-cron/) directly only when working in an existing project that pre-dates the wrapper.

## 2025-2026 currency anchors

- **Auth-bound auditability** — the dashboard records who scheduled what, and edit history.
- **UI editor** for cron syntax and SQL/function body.
- **Job history retention** is bounded — for long retention, log to your own audit table.
- **One-minute minimum cadence** (standard cron). Faster intervals require a constantly-running worker, not cron.

## Patterns and anti-patterns

### Patterns

**Worker poll on a queue** — every minute:

```sql
select cron.schedule(
  'drain-order-queue',
  '*/1 * * * *',
  $$
    select net.http_post(
      url := 'https://<project>.supabase.co/functions/v1/process-orders',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('supabase.functions.invoke_key')
      ),
      body := '{}'::jsonb
    )
  $$
);
```

Or schedule via Studio → Cron with the same body — preferred for the audit trail.

**Hourly housekeeping** — pure SQL:

```sql
select cron.schedule(
  'cleanup-stale-sessions',
  '0 * * * *',
  $$ delete from public.sessions where expires_at < now() $$
);
```

**Daily summary upload** to Storage:

```sql
select cron.schedule(
  'daily-revenue-export',
  '0 1 * * *',
  $$ select net.http_post(url := 'https://<project>.supabase.co/functions/v1/export-revenue', ...) $$
);
```

### Anti-patterns

- **Scheduling via the SQL editor in production** without going through Supabase Cron. No audit trail of who scheduled what.
- **Sub-minute cadence via cron.** Floor is one minute; for high-frequency, use a worker that loops.
- **Heavy SQL bodies** that hold a connection for minutes. Route to an Edge Function.
- **Hard-coded service-role keys** in job bodies. Use `current_setting('supabase.functions.invoke_key')` or Vault.

## Gotchas

- **Jobs run as `postgres` and bypass RLS.** Be deliberate about which tables they touch.
- **Failed runs are logged but not retried.** Build idempotent bodies.
- **Run history retention is bounded.** Log to your own audit table for long-term retention.
- **Overlapping invocations** — if a job's runtime exceeds the interval, the next run may queue. Lock or guard in the job body.
- **Time zones** — jobs run in the database's timezone; verify via `select current_setting('TIMEZONE');`.
- **Cost surface** — many high-frequency jobs add database load; Pro-tier accounting matters.

## Cross-references

- [pg_cron](/stacks/supabase/pg-cron/) — the underlying extension
- [pg_net](/stacks/supabase/pg-net/) — used by cron jobs to invoke Edge Functions
- [Supabase Queues](/stacks/supabase/supabase-queues/) — the typical orchestration paired with cron-invoked workers
- [Edge Functions](/stacks/supabase/edge-functions/) — common cron targets
- Supabase docs: [Cron](https://supabase.com/docs/guides/cron)
