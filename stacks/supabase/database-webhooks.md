---
title: Database Webhooks
description: Dashboard-configured async HTTP calls fired on row events. Backed by pg_net. Async, best-effort, at-least-once.
product:
  name: Database Webhooks
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect]
  authoritative_url: https://supabase.com/docs/guides/database/webhooks
  notes: "Layer on top of pg_net; queue back-pressures under load; ordering is per-row only."
---

## What it is

Database Webhooks are dashboard-configured async HTTP calls that fire when a row is inserted/updated/deleted. Under the hood they use [`pg_net`](/stacks/supabase/pg-net/) to enqueue an HTTP request to a target URL — your Edge Function, an external service, a Slack incoming webhook.

Source: [Database Webhooks docs](https://supabase.com/docs/guides/database/webhooks).

## When to use

| Use Database Webhooks for | Don't use for |
|---------------------------|---------------|
| Slack/Discord notifications on row events | Payment settlement (no retry semantics) |
| Syncing to third-party analytics | Cross-system state machines |
| Kicking off non-critical CI/email/audit flows | Anything that needs transactional guarantees |
| Quick prototypes of "DB → external" wiring | Anything requiring strict ordering |

For mission-critical "DB event → external system" flows, use [Supabase Queues](/stacks/supabase/supabase-queues/) + an Edge Function consumer instead.

## 2025-2026 currency anchors

- **Configured per-table in Studio** — Database → Webhooks. Pick events (INSERT/UPDATE/DELETE), target URL, headers.
- **Backed by `pg_net`** — the queue is async and back-pressures under load.
- **At-least-once delivery** — duplicates possible.
- **Per-row ordering only** — two updates to different rows may arrive out of order.
- **No built-in retry-with-backoff** — build idempotent receivers.

## Patterns and anti-patterns

### Patterns

**Configure in Studio**, not via SQL — the dashboard surface gives you the run history and edit audit trail.

**Build idempotent receivers.** The webhook payload includes the row's `id` and the event timestamp. Use both as a dedupe key:

```ts
const { record, old_record, type } = await req.json();
const dedupeKey = `${record.id}-${type}-${record.updated_at}`;
if (await alreadyProcessed(dedupeKey)) return new Response("ok");
await processEvent(record, old_record, type);
await markProcessed(dedupeKey);
```

**Inspect the queue when delivery seems slow:**

```sql
select * from net.http_request_queue limit 20;
select * from net._http_response order by created desc limit 20;
```

**Use Database Webhooks for fan-out notifications** and a Queue for fan-out work. They compose: webhook → cheap notify; Queue → durable processing.

### Anti-patterns

- **Using webhooks for payment settlement.** No retry-with-backoff, no exactly-once. Use a Queue.
- **Trusting global ordering.** Different rows arrive in any order; same row's events are per-row ordered.
- **Synchronous expectations.** Webhook delivery is async; the transaction that fired it commits before the HTTP call happens.
- **Webhook target with no auth.** Sign requests with a shared secret you verify in the receiver, or use `pg_net` with an `Authorization` header.

## Gotchas

- **`pg_net` queue can back-pressure.** Under heavy write load, webhook delivery lags. Monitor `net._http_response.status_code` for failures.
- **No replay UI.** A failed webhook (HTTP 5xx from your receiver) does not retry. Implement reconciliation by querying the source table.
- **Webhook payload size is bounded** — large rows may be truncated; reference the row ID and re-fetch if needed.
- **Triggers that call `pg_net` synchronously** (not via Database Webhooks) serialize the transaction on the HTTP roundtrip. Always use the async path.

## Cross-references

- [pg_net](/stacks/supabase/pg-net/) — the async HTTP primitive underneath
- [Supabase Queues](/stacks/supabase/supabase-queues/) — durable, retryable async work
- [Edge Functions](/stacks/supabase/edge-functions/) — the typical receiver
- [backend-architect role view](/stacks/supabase/backend-architect/) — when to choose webhook vs queue
- Supabase docs: [Database Webhooks](https://supabase.com/docs/guides/database/webhooks)
