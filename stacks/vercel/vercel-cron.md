---
title: Vercel Cron
description: "Scheduled HTTP calls declared in `vercel.json`. The simplest way to run periodic work — for anything beyond simple schedules, use Workflow."
product:
  name: Vercel Cron
  stack: vercel
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer]
  authoritative_url: https://vercel.com/docs/cron-jobs
  notes: "Stable. Min interval 1 minute on Pro. Cron endpoints share function timeout — long jobs need a Workflow trigger from cron."
---

## What it is

Vercel Cron triggers HTTP calls to your Route Handlers on a schedule defined in `vercel.json`. Vercel passes an `Authorization: Bearer ${CRON_SECRET}` header you verify in the handler. See [vercel.com/docs/cron-jobs](https://vercel.com/docs/cron-jobs).

## When to use

- **Periodic refresh** — invalidate cache tags, recompute aggregates, sweep stale records.
- **Scheduled reports** — nightly emails, weekly digests.
- **Heartbeats** — ping a monitoring service.

Don't use Cron for:

- **Long-running batch jobs** — cron endpoints share function timeout (60s/800s/900s). For multi-minute work, trigger a [Workflow](/stacks/vercel/workflow/) from the cron handler.
- **Sub-minute schedules** — minimum interval is 1 minute on Pro; lower tiers are longer. For frequent polling, reconsider design.
- **Always-on work** — cron is interval-based, not continuous.

## 2025-2026 currency anchors

- **Stable.** Schema in `vercel.json` is unchanged in 2026.
- **Min interval 1 minute on Pro** — longer on Hobby; verify your plan.
- **`CRON_SECRET`** is auto-set by Vercel; passed as `Authorization: Bearer <secret>` to your cron endpoints.

## Patterns + anti-patterns

**Pattern: Declare in `vercel.json`.**

```jsonc
{
  "crons": [
    { "path": "/api/cron/refresh-cache",    "schedule": "0 * * * *" },
    { "path": "/api/cron/nightly-report",   "schedule": "0 3 * * *" }
  ]
}
```

**Pattern: Verify `CRON_SECRET` in every cron endpoint.**

```ts
// app/api/cron/refresh-cache/route.ts
import { revalidateTag } from 'next/cache';

export async function GET(req: Request) {
  const auth = req.headers.get('authorization');
  if (auth !== `Bearer ${process.env.CRON_SECRET}`) {
    return new Response('Unauthorized', { status: 401 });
  }
  revalidateTag('top-products');
  return Response.json({ ok: true });
}
```

**Pattern: Cron triggers Workflow for long jobs.** Cron endpoint returns fast; Workflow handles multi-step durable work.

**Anti-pattern: Skipping `CRON_SECRET` verification.** Cron paths are otherwise public URLs.

**Anti-pattern: 60-second batch jobs in the cron handler itself.** Hits `maxDuration`. Trigger a Workflow instead.

**Anti-pattern: Five separate crons on the same minute.** They run concurrently; design around shared state contention.

## Gotchas

- **Cron schedule is UTC** by default.
- **Cron endpoints are Route Handlers** — usually `GET`; you choose.
- **Cron isn't a guaranteed-once primitive.** Network blips can cause skipped runs; design idempotent.
- **Cron jobs share function timeout.** For longer work, trigger Workflow.

## Cross-references

- [Vercel Functions](/stacks/vercel/vercel-functions/) — Route Handlers serve cron
- [Workflow](/stacks/vercel/workflow/) — durable multi-step alternative
- [Vercel Queues](/stacks/vercel/vercel-queues/) — for async fan-out
- [backend-architect on Vercel](/stacks/vercel/backend-architect/)
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — `vercel.json` config
- Authoritative: [Cron docs](https://vercel.com/docs/cron-jobs)
