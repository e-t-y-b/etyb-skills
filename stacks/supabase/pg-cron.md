---
title: pg_cron
description: Scheduled SQL jobs inside Postgres. Now wrapped by Supabase Cron UI for auditability.
product:
  name: pg_cron
  stack: supabase
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect]
  authoritative_url: https://supabase.com/docs/guides/database/extensions/pg_cron
  notes: "Stable extension; Supabase Cron is the recommended UI surface for new work."
---

## What it is

`pg_cron` is a Postgres extension that schedules SQL jobs via cron syntax. Jobs live in `cron.job` and run history in `cron.job_run_details`. On Supabase, [Supabase Cron](/stacks/supabase/supabase-cron/) wraps it with a dashboard UI and audit log — prefer that for new work.

Source: [pg_cron in Supabase docs](https://supabase.com/docs/guides/database/extensions/pg_cron).

## When to use

| Use pg_cron / Supabase Cron for | Use elsewhere |
|---------------------------------|---------------|
| Hourly housekeeping (cleanup, retention) | Sub-minute cadence (use Realtime/Queues) |
| Worker poll (drain a queue every minute) | Long-running batch jobs (use a worker, not cron) |
| Scheduled exports (query → CSV → Storage) | Cross-system orchestration (use a workflow engine) |
| Periodic Edge Function invocation | Anything needing observability beyond run/no-run |

## 2025-2026 currency anchors

- **Supabase Cron** (late 2024) — UI on top of pg_cron with auth-bound auditability. Prefer over raw `cron.schedule(...)` from the SQL editor.
- **Minimum interval is one minute** via standard cron syntax. Supabase Cron may expose sub-minute via dashboard.
- **Job history retention is bounded** — log to your own audit table for longer retention.

## Patterns and anti-patterns

### Patterns

**Pure SQL job** — hourly housekeeping:

```sql
select cron.schedule(
  'cleanup-stale-sessions',
  '0 * * * *',
  $$ delete from public.sessions where expires_at < now() $$
);
```

**Edge Function invocation** — worker poll on a queue:

```sql
select cron.schedule(
  'process-queue-orders',
  '*/1 * * * *',  -- every minute
  $$
    select net.http_post(
      url := 'https://<project>.supabase.co/functions/v1/process-queue',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('supabase.functions.invoke_key')
      ),
      body := '{}'::jsonb
    )
  $$
);
```

**Inspect job history:**

```sql
select * from cron.job_run_details
where jobid = (select jobid from cron.job where jobname = 'process-queue-orders')
order by start_time desc limit 20;
```

### Anti-patterns

- **Hard-coding the service-role key in the job body.** Use `current_setting('supabase.functions.invoke_key')` or Vault.
- **Running pg_cron via SQL editor in production without auditability.** Use Supabase Cron — the dashboard records who scheduled what.
- **Sub-second cadence.** pg_cron's floor is one minute via standard cron. For high-frequency work, use [Supabase Queues](/stacks/supabase/supabase-queues/) + a constantly-running worker.
- **Heavy work in a SQL job.** A 10-minute SQL job holds a backend connection; route to an Edge Function instead.

## Gotchas

- **Jobs run as the `postgres` role** — they bypass RLS. Be deliberate about which tables the job touches.
- **A failed job is logged but not retried.** Build the SQL to be idempotent so a missed run doesn't compound.
- **Time zones**: jobs run in the database's timezone. Verify via `select current_setting('TIMEZONE');`.
- **Overlapping invocations** — if a job runs longer than its interval, the next invocation may queue. Use a lock pattern in the job body if overlap is harmful.
- **pg_cron requires PG superuser to install** but Supabase provides it pre-enabled — you don't run `create extension`.

## Cross-references

- [Supabase Cron](/stacks/supabase/supabase-cron/) — the managed UI on top
- [pg_net](/stacks/supabase/pg-net/) — used to invoke HTTP/Edge Functions from a job
- [Supabase Queues](/stacks/supabase/supabase-queues/) — for tasks that exceed one-minute cadence
- [Edge Functions](/stacks/supabase/edge-functions/) — common cron targets
- Supabase docs: [pg_cron](https://supabase.com/docs/guides/database/extensions/pg_cron)
