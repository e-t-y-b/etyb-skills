---
title: Queues
description: Cloudflare's managed message queue for decoupling producers from consumers — batch consumption, retries with backoff, dead-letter queues, per-message ack/retry.
product:
  name: Queues
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/queues/
  notes: "GA; pull consumers, message delays, dead-letter, batch retry semantics added through 2025."
---

## What it is

Queues is Cloudflare's managed message queue between Workers — producers `send()` messages, consumer Workers receive `MessageBatch<T>` in a `queue(batch, env, ctx)` handler. Built-in retries with backoff, batch consumption (up to 100 messages), dead-letter queues, per-message ack/retry. Up to 4500 msg/sec per queue.

Authoritative reference: [developers.cloudflare.com/queues](https://developers.cloudflare.com/queues/).

## When to use

- **Decouple producer from consumer** — accept work fast, process async.
- **Batch processing** — payment notifications, webhook fan-out, email sending.
- **Retries with backoff** — Queues handles retry semantics so your handler can throw and the message redelivers.
- **Buffering for downstream rate limits** — your consumer can be rate-limited; the queue absorbs bursts.

Don't use Queues when:

- **Multi-step orchestration with conditional branches** — use [Workflows](/stacks/cloudflare/workflows/).
- **Per-entity scheduled work** — use [DO alarms](/stacks/cloudflare/durable-objects/).
- **Periodic batch tasks** — use [Cron Triggers](/stacks/cloudflare/cron-triggers/).
- **High-volume firehose ingest** — use [Pipelines](/stacks/cloudflare/pipelines/) → [R2](/stacks/cloudflare/r2/) for that shape.

## 2025-2026 currency anchors

- **GA stable.** Pull consumers, message delays, dead-letter queues, batch retry semantics all added through 2025.
- **Per-message control** — `msg.ack()`, `msg.retry({ delaySeconds })`, `batch.ackAll()`, `batch.retryAll()` for correct batch-with-partial-failure handling.
- **Workflows replaced "Queues + DO state + cron"** for orchestration — Queues remain the right choice for fan-out / decoupling.

## Patterns

### Producer

```ts
async fetch(req, env, ctx) {
  // ... handle request
  ctx.waitUntil(env.JOBS.send({
    type: "send_welcome_email",
    userId,
    at: Date.now()
  }, { contentType: "json", delaySeconds: 60 }));
  return new Response("queued");
}
```

### Consumer

```ts
export default {
  async queue(batch: MessageBatch<Job>, env: Env, ctx: ExecutionContext) {
    for (const msg of batch.messages) {
      try {
        await processJob(msg.body, env);
        msg.ack();
      } catch (e) {
        msg.retry({ delaySeconds: 30 });
      }
    }
  }
}
```

```toml
[[queues.producers]]
binding = "JOBS"
queue = "jobs-prod"

[[queues.consumers]]
queue = "jobs-prod"
max_batch_size = 25
max_batch_timeout = 5
max_retries = 3
dead_letter_queue = "jobs-prod-dlq"
```

Per-message `ack`/`retry`/`retryAll`/`ackAll` lets you handle batch-with-partial-failure correctly.

### Always configure a DLQ

Silent message loss is hard to debug. Set `dead_letter_queue` on every consumer. Run a separate Worker / scheduled job that drains the DLQ into a triage view (Workers Logs, D1 table, Slack notification).

### Idempotency on consumers

Consumer can run a message more than once (retry after a transient failure, batch redelivery). Make handlers idempotent:

```ts
const existing = await env.DB.prepare("SELECT * FROM processed_events WHERE id=?").bind(msg.body.eventId).first();
if (existing) {
  msg.ack();
  continue;
}
// ... process
await env.DB.prepare("INSERT INTO processed_events ...").run();
msg.ack();
```

## Anti-patterns

- **Queues + DO state + cron as a workflow** — that's what Workflows are for. Reach for Workflows if your flow has >2 steps with dependencies.
- **No DLQ** — messages that fail max retries vanish silently.
- **Non-idempotent consumers** — duplicate processing causes data corruption.
- **Letting one bad message poison the batch** — use per-message `retry`, not `throw` from the handler (throwing fails the whole batch).

## Gotchas

1. **At-least-once delivery semantics** — design for idempotency.
2. **Batch size and timeout** balance throughput vs latency. Tune per workload.
3. **Workers Paid** unlocks Queues — not available on the free tier.
4. **Consumer scaling** — Cloudflare scales consumers automatically; you don't size them.
5. **Message size limit** — verify against current docs; large payloads should be stored in R2 with the queue carrying a reference.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime for producers and consumers
- [Workflows](/stacks/cloudflare/workflows/) — for multi-step orchestration instead of DIY on Queues
- [Pipelines](/stacks/cloudflare/pipelines/) — for high-volume firehose ingest instead of Queues
- [Durable Objects](/stacks/cloudflare/durable-objects/) — DO alarms for per-entity scheduled work
- [Cron Triggers](/stacks/cloudflare/cron-triggers/) — periodic batch tasks
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/queues](https://developers.cloudflare.com/queues/)
