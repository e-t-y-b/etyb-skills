---
title: Supabase Queues
description: Managed pgmq with DLQ + visibility timeout. Launched 2025. Worker = Edge Function on Cron.
product:
  name: Supabase Queues
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect]
  authoritative_url: https://supabase.com/docs/guides/queues
  notes: "Managed surface on pgmq. UI + auth-bound auditability. Use for durable async work with retry semantics."
---

## What it is

Supabase Queues is a managed message-queue surface built on the `pgmq` Postgres extension. It gives you durable enqueue/dequeue, visibility timeout, batched reads, archive vs delete, and dead-letter-queue patterns — all backed by Postgres rows. Launched 2025.

Source: [Queues docs](https://supabase.com/docs/guides/queues).

## When to use

| Use Queues for | Use [Database Webhooks](/stacks/supabase/database-webhooks/) for |
|----------------|-----------------------------------------------------------------|
| Payment settlement, financial state changes | Slack/Discord notifications |
| Background jobs that need retries | Sync to analytics (best-effort) |
| Async pipelines with DLQ semantics | Quick fire-and-forget |
| Visibility timeout / deduplication | Anything throwaway |

Queues vs Edge Function `EdgeRuntime.waitUntil`:
- **Queues** — durable, retryable, persisted; good for "must eventually succeed."
- **`waitUntil`** — best-effort, bounded by function execution budget; good for "fire and forget."

## 2025-2026 currency anchors

- **Managed surface on `pgmq`** — operations available via SQL (`pgmq.send`, `pgmq.read`, `pgmq.archive`, `pgmq.delete`) and via Studio UI.
- **Worker pattern**: Edge Function invoked by [Supabase Cron](/stacks/supabase/supabase-cron/) every minute (or as fast as your throughput needs), reads a batch, processes, archives.
- **Visibility timeout** — set on `pgmq.read`; if not archived/deleted within the timeout, the message becomes visible again for redelivery.
- **DLQ** — a second queue you `pgmq.send` to on final failure.

## Patterns and anti-patterns

### Patterns

**Enqueue:**

```sql
select pgmq.send('order_processing', '{"order_id": 123}'::jsonb);
```

**Worker = Edge Function on Cron** — the canonical consumer:

```ts
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async () => {
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: messages, error } = await admin.rpc("pgmq_read", {
    queue_name: "order_processing",
    vt: 60,     // visibility timeout in seconds
    qty: 10,    // batch size
  });
  if (error || !messages?.length) return new Response("nothing to do");

  for (const msg of messages) {
    try {
      await processOrder(msg.message);
      await admin.rpc("pgmq_archive", { queue_name: "order_processing", msg_id: msg.msg_id });
    } catch (err) {
      // Let visibility timeout expire; pgmq re-delivers.
      if (msg.read_ct >= 5) {
        await admin.rpc("pgmq_send", {
          queue_name: "order_processing_dlq",
          msg: { original: msg.message, error: err.message },
        });
        await admin.rpc("pgmq_delete", { queue_name: "order_processing", msg_id: msg.msg_id });
      }
    }
  }
  return new Response(`processed ${messages.length}`);
});
```

Schedule with [Supabase Cron](/stacks/supabase/supabase-cron/) at the cadence your throughput needs.

**DLQ as a second queue:** on final failure, `pgmq.send` to `<queue>_dlq` with original payload + error metadata. Periodic review of DLQ is the human-in-the-loop step.

**Visibility timeout > processing time.** Otherwise the message gets delivered to a second worker before the first finishes.

**Idempotent receivers.** Even with archive-after-success, a network hiccup can cause double processing. Use a unique key in the message payload + a `processed_messages` table.

### Anti-patterns

- **`pgmq.read` without `pgmq.archive` / `pgmq.delete`** — messages re-deliver until visibility timeout × retries. Looks fine until you check the table.
- **No DLQ** — failures pile up in the queue and re-deliver forever.
- **Visibility timeout shorter than processing time** — duplicate processing under any load.
- **Heavy work directly in the worker without batching** — one worker per message ignores batched-read efficiency.
- **Using Queues for sub-second cadence work.** Cron's minimum is one minute; a constantly-running worker (different pattern) is needed for high frequency.

## Gotchas

- **Queues are Postgres rows.** Heavy write throughput shows up as Postgres write load. Tier accordingly.
- **`read_ct`** tracks how many times a message has been read; use to identify "stuck" messages for DLQ.
- **Archive vs Delete:** archive keeps the message in a separate table for audit; delete removes it. Pick per use case.
- **Cron-invoked worker has cold-start latency** for the Edge Function. For latency-sensitive queues, keep a warm-keep cron ping.
- **Worker should fail fast on transient errors** (let visibility timeout redeliver) vs permanent errors (DLQ immediately). Categorize errors.
- **The DLQ also needs monitoring.** A growing DLQ is a P1 even if the main queue is clean.

## Cross-references

- [Supabase Cron](/stacks/supabase/supabase-cron/) — the worker scheduler
- [Edge Functions](/stacks/supabase/edge-functions/) — the typical worker runtime
- [Database Webhooks](/stacks/supabase/database-webhooks/) — the lightweight alternative for fire-and-forget
- [backend-architect role view](/stacks/supabase/backend-architect/) — orchestration patterns
- Supabase docs: [Queues](https://supabase.com/docs/guides/queues)
