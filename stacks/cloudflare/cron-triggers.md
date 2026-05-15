---
title: Cron Triggers
description: Cloudflare Workers scheduled handler — UTC cron expressions, 1-minute granularity, free, perfect for periodic batch tasks.
product:
  name: Cron Triggers
  stack: cloudflare
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/workers/configuration/cron-triggers/
  notes: "Stable; UTC only, max one-minute granularity."
---

## What it is

Cron Triggers fire a Worker's `scheduled(controller, env, ctx)` handler on a schedule. UTC cron expressions, 1-minute granularity, multiple crons per Worker. `controller.cron` tells the handler which schedule fired.

Authoritative reference: [developers.cloudflare.com/workers/configuration/cron-triggers](https://developers.cloudflare.com/workers/configuration/cron-triggers/).

## When to use

- **Periodic batch tasks** — every 5 minutes do X, every day at 2am do Y.
- **Polling external systems** when webhooks aren't available.
- **Maintenance jobs** — cleanup, aggregation, exports.

Don't use Cron Triggers when:

- **Per-entity scheduled work** — use [DO alarms](/stacks/cloudflare/durable-objects/) (one alarm per DO, cheaper, scoped).
- **Sub-minute granularity** — Cron Triggers cap at 1-minute. For tighter loops, consume from a Queue or use a Workflow that schedules itself.
- **Long-running orchestration** — use [Workflows](/stacks/cloudflare/workflows/); cron can kick a Workflow but shouldn't carry orchestration state.

## 2025-2026 currency anchors

- **Stable.** UTC, 1-minute granularity, multiple crons per Worker hasn't shifted.
- **Cron Triggers require Workers Paid** ($5/month plan).

## Patterns

### Multiple crons per Worker

```ts
export default {
  async scheduled(controller: ScheduledController, env: Env, ctx: ExecutionContext) {
    if (controller.cron === "*/5 * * * *") {
      ctx.waitUntil(fiveMinutelyJob(env));
    } else if (controller.cron === "0 2 * * *") {
      ctx.waitUntil(dailyJob(env));
    }
  }
}
```

```toml
[[triggers.crons]]
cron = "*/5 * * * *"

[[triggers.crons]]
cron = "0 2 * * *"
```

`ctx.waitUntil` extends the Worker lifetime past the schedule trigger.

### Cron kicks Workflow for long jobs

```ts
async scheduled(controller, env, ctx) {
  if (controller.cron === "0 2 * * *") {
    await env.MY_WORKFLOW.create({ id: `daily-${Date.now()}`, params: { runDate: new Date().toISOString() } });
  }
}
```

For multi-step or long-running scheduled work, kick a [Workflow](/stacks/cloudflare/workflows/) from the scheduled handler.

## Anti-patterns

- **One Worker per cron** when one Worker with branching on `controller.cron` would do — extra deploys, extra overhead.
- **Doing >30s of CPU work in `scheduled`** — push to Workflow.
- **Forgetting `ctx.waitUntil`** — the handler returns immediately and the Worker may be recycled.

## Gotchas

1. **UTC only** — translate user timezone in code if needed.
2. **1-minute minimum granularity.** No sub-minute schedules.
3. **Cron Triggers don't replay** — if the Worker is failing during the scheduled time, the missed run is lost. Use a Workflow or idempotent re-run logic for critical schedules.
4. **Available on Workers Paid only.**

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime for the scheduled handler
- [Workflows](/stacks/cloudflare/workflows/) — for long-running or multi-step scheduled work
- [Durable Objects](/stacks/cloudflare/durable-objects/) — DO alarms for per-entity scheduled work
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/workers/configuration/cron-triggers](https://developers.cloudflare.com/workers/configuration/cron-triggers/)
