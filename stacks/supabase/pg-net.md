---
title: pg_net
description: Async HTTP calls from Postgres. The primitive under Database Webhooks. Treat as best-effort and back-pressured.
product:
  name: pg_net
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect]
  authoritative_url: https://supabase.com/docs/guides/database/extensions/pg_net
  notes: "Async only — never call synchronously from a trigger. Queue can back-pressure under load."
---

## What it is

`pg_net` is a Postgres extension that queues HTTP requests from inside the database. Requests go into `net.http_request_queue`; responses land in `net._http_response`. The extension powers [Database Webhooks](/stacks/supabase/database-webhooks/) and is the right primitive when you need "trigger fires → external API gets called" without standing up an Edge Function.

Source: [pg_net docs](https://supabase.com/docs/guides/database/extensions/pg_net).

## When to use

| Use pg_net for | Don't use pg_net for |
|----------------|----------------------|
| Async fire-and-forget HTTP from a trigger | Synchronous HTTP from a trigger — serializes the transaction |
| Database Webhooks (the wrapper) | Anything requiring retry-with-backoff (use a Queue) |
| Cron-scheduled HTTP calls (Edge Function invocation) | High-throughput external sync (the queue back-pressures) |

## 2025-2026 currency anchors

- **Async-only semantics.** Requests enqueue; responses arrive later in `net._http_response`.
- **Queue back-pressures under load.** Inspect `net.http_request_queue` size as an ops signal.
- **At-least-once delivery, no automatic retry.** Build idempotent receivers.
- **Supabase wraps pg_net** in Database Webhooks; you rarely call it directly except from cron jobs or custom workflows.

## Patterns and anti-patterns

### Patterns

**Direct async POST** (rare; usually prefer Database Webhooks):

```sql
select net.http_post(
  url := 'https://external.example.com/event',
  body := jsonb_build_object('event', 'order_created', 'order_id', '...'),
  headers := jsonb_build_object('Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'webhook_token'))
);
```

**Inspect response history:**

```sql
select status_code, content_type, created
from net._http_response
order by created desc
limit 20;
```

**Trigger queue depth as an ops signal:**

```sql
select count(*) from net.http_request_queue;
```

### Anti-patterns

- **Synchronous HTTP from a trigger** — `net.http_get(url)` inside a `BEFORE INSERT` trigger blocks the row write on the HTTP roundtrip and serializes the transaction. Always async.
- **Using pg_net for payment/billing settlement.** No retry-with-backoff. Use [Supabase Queues](/stacks/supabase/supabase-queues/).
- **Treating responses as immediate.** They land in `net._http_response`; querying is a separate step.
- **Hard-coding API keys** in trigger bodies. Use [Vault](/stacks/supabase/supabase-vector/) (or Supabase secrets accessible from Edge Functions if the call moves there).

## Gotchas

- **Queue can grow unbounded** if the target endpoint is slow/down. Monitor and clean.
- **No exponential backoff.** A failing webhook stays in the queue and re-attempts at intervals — but won't space out automatically.
- **Response retention is bounded** — older responses are purged. Don't rely on `net._http_response` as an audit trail.
- **Different Supabase compute tiers have different pg_net throughput.** Heavy webhook fan-out may need tier upgrade.
- **TLS verification is on by default.** Self-signed certs will fail.

## Cross-references

- [Database Webhooks](/stacks/supabase/database-webhooks/) — the dashboard-configured wrapper
- [Supabase Queues](/stacks/supabase/supabase-queues/) — durable retry-capable alternative
- [pg_cron](/stacks/supabase/pg-cron/) — pairs with pg_net for scheduled HTTP
- [Database Functions](/stacks/supabase/database-functions/) — never call pg_net synchronously from triggers
- Supabase docs: [pg_net](https://supabase.com/docs/guides/database/extensions/pg_net)
