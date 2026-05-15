---
title: Vercel Queues
description: First-party producer/consumer queues with visibility timeout, DLQ, and max-receive count. The 2026 default for async work-deferral on Vercel.
product:
  name: Vercel Queues
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect]
  authoritative_url: https://vercel.com/docs/queues
  notes: "Newer surface (GA 2025). Producer/consumer semantics + visibility timeout patterns. Check changelog for current limits + per-plan quotas."
---

## What it is

Vercel Queues are a first-party producer/consumer queue. Producers `enqueue` messages; consumers (declared as Route Handlers via `handle()` from `@vercel/queues/next`) process them with visibility-timeout semantics, max-receive count, and a dead-letter queue (DLQ) for failed messages. See [vercel.com/docs/queues](https://vercel.com/docs/queues).

## When to use

- **Decoupling** webhook handlers from heavy processing (Stripe → enqueue → consumer handles in background).
- **Spreading load** across worker invocations.
- **Retry semantics** (visibility timeout + max receives + DLQ) for transient failures.
- **Fan-out** small per-tenant or per-record processing jobs.

Alternatives:

- **Upstash QStash** (Marketplace) — same idea, HTTP-based.
- **AWS SQS** — when already on AWS.
- **Cloudflare Queues** — when on Cloudflare.

Pick Vercel Queues for greenfield Vercel apps — one bill, no integration friction.

## 2025-2026 currency anchors

- **GA 2025.** Newer surface; check the changelog for per-plan limits, payload size, and retention policies.
- **Producer/consumer semantics** with visibility timeout — a message is invisible to other consumers for the timeout duration after dequeue.
- **DLQ for max-receive** — messages exceeding max receives land in a DLQ for inspection.
- **First-party billing** through Vercel — no separate vendor relationship needed.

## Patterns + anti-patterns

**Pattern: Webhook → Queue → Workflow.** A Stripe webhook fires → Route Handler verifies and enqueues → Queue consumer triggers a Workflow that runs the multi-step business logic. ACK is fast, processing is durable, retries are explicit.

```ts
// Producer
import { Queue } from '@vercel/queues';
const ingestQueue = new Queue('ingest');
await ingestQueue.enqueue({ jobId, payload });
```

```ts
// Consumer — app/api/queues/ingest/route.ts
import { handle } from '@vercel/queues/next';

export const POST = handle('ingest', async (msg) => {
  // process msg.payload
  // throw to retry; return to ack
});
```

**Pattern: Idempotent consumers.** Webhooks retry; consumers must handle replays. Key by event ID + check before processing.

**Pattern: DLQ alerting.** Wire a monitor on DLQ depth — anything > 0 should page.

**Anti-pattern: Long-running consumer in a single dequeue.** If the work takes minutes, trigger a Workflow from the consumer and return fast.

**Anti-pattern: Treating Queues as a database.** Queues are transient — they're not for state storage. Persist what you need in Postgres.

**Anti-pattern: No DLQ monitoring.** Failed messages pile up silently; alert on DLQ depth.

## Gotchas

- **Visibility timeout must exceed your expected processing time.** Too short → duplicate dequeues. Too long → stuck-message lag.
- **Max-receive matters.** Buggy code hits DLQ; tune the count to the volume you can hand-process.
- **Payload size limits apply** — check current docs for the per-plan cap.
- **Queues are async by definition.** Don't expect immediate consistency between producer and reader of the post-queue state.

## Cross-references

- [Vercel Functions](/stacks/vercel/vercel-functions/) — Route Handlers as consumers
- [Workflow](/stacks/vercel/workflow/) — multi-step durable work triggered from a queue
- [Vercel Cron](/stacks/vercel/vercel-cron/) — scheduled enqueue alternative
- [backend-architect on Vercel](/stacks/vercel/backend-architect/)
- Authoritative: [Queues docs](https://vercel.com/docs/queues)
