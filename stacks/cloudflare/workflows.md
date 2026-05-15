---
title: Workflows
description: Cloudflare's durable-execution primitive — multi-step orchestration with checkpointed steps, retries with backoff, sleeps that don't burn compute, and survival across Worker restarts.
product:
  name: Workflows
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, ai-ml-engineer]
  authoritative_url: https://developers.cloudflare.com/workflows/
  notes: "Durable-execution primitive, GA in 2025; new pattern most teams have not seen — Temporal-as-a-binding for Cloudflare."
---

## What it is

Workflows is Cloudflare's durable-execution primitive — think Temporal as a Cloudflare binding. Each `step.do()` is checkpointed; results survive Worker restarts; retries are step-level with configurable backoff; `step.sleep()` suspends without burning compute. The right primitive for any multi-step async business process.

Authoritative reference: [developers.cloudflare.com/workflows](https://developers.cloudflare.com/workflows/).

## When to use

- **Multi-step business processes** — order fulfillment, onboarding flows, payment reconciliation.
- **Long-running, sleepable work** — wait an hour, then check status; retry with backoff; resume after Worker restart.
- **Saga pattern across services** — a Workflow is the right primitive for distributed transactions.
- **Tool-using agents** — see [ai-ml-engineer overlay](/stacks/cloudflare/ai-ml-engineer/) for the agent-in-a-Workflow pattern.

Don't use Workflows when:

- **Single-shot request handling** — that's a [Worker fetch handler](/stacks/cloudflare/workers/).
- **Fire-and-forget fan-out** — that's [Queues](/stacks/cloudflare/queues/).
- **Per-entity scheduled work** — that's a [DO alarm](/stacks/cloudflare/durable-objects/).
- **Periodic batch** — that's a [Cron Trigger](/stacks/cloudflare/cron-triggers/) (which may kick a Workflow).

## 2025-2026 currency anchors

- **GA'd in 2025.** Pre-2025, the multi-step orchestration story on Cloudflare was "Queues + DO + cron, build the state machine yourself." Workflows replaces that pattern.
- **For any new long-running orchestration, your default should be Workflows.** Queues remain for fan-out/decoupling; DOs for per-entity serialized state.
- **If you find architecture diagrams with "DO state machine" boxes** for orchestration, re-evaluate — that's a Workflow now.

## Patterns

### Basic Workflow

```ts
import { WorkflowEntrypoint, WorkflowStep, WorkflowEvent } from "cloudflare:workers";

type OrderParams = { orderId: string };

export class FulfillOrder extends WorkflowEntrypoint<Env, OrderParams> {
  async run(event: WorkflowEvent<OrderParams>, step: WorkflowStep) {
    const { orderId } = event.payload;

    const order = await step.do("load-order", async () => {
      return this.env.DB.prepare("SELECT * FROM orders WHERE id=?").bind(orderId).first();
    });

    await step.do("charge-card", { retries: { limit: 3, delay: "10 seconds", backoff: "exponential" } }, async () => {
      await fetch("https://api.stripe.com/v1/charges", { /* ... */ });
    });

    await step.sleep("wait-before-ship", "1 hour");

    await step.do("dispatch-warehouse", async () => {
      await this.env.WAREHOUSE.dispatch(orderId);
    });
  }
}
```

Each `step.do()` is durable: result is checkpointed, retried independently, survives Worker restarts. `step.sleep()` doesn't burn CPU — the workflow is suspended until the time elapses.

### Trigger from a fetch handler

```ts
async fetch(req, env, ctx) {
  const body = await req.json();
  const instance = await env.MY_WORKFLOW.create({
    id: `order-${body.orderId}`,
    params: body
  });
  return Response.json({ workflowId: instance.id, status: await instance.status() });
}
```

Pass an explicit `id` for idempotency — re-triggering with the same ID returns the existing instance.

### Tool-using agent in a Workflow

See [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/) for the full pattern. Workflows give you durable agent state — agent runs that take minutes (or hours, with sleeps) survive Worker restarts because each tool-call turn is a checkpointed step.

### Workflow as external-orchestrator integration seam

When integrating Cloudflare with Temporal / AWS Step Functions / GCP Workflows:

- Wrap each Cloudflare-side operation as a Workflow.
- Expose Workflow's `instances.create` as your contract.
- External orchestrator triggers Workflow instances by ID; queries status; subscribes to events.

You can build complex distributed orchestration where Cloudflare handles a slice and an external system handles another, with Workflows as the durable boundary.

## Anti-patterns

- **Queues + DO state + cron to build a state machine** — that's what Workflows are for now. Refactor when you encounter this pattern.
- **`step.do()` with non-idempotent side effects** — steps retry. If your step charges a card without idempotency keys, you'll double-charge.
- **Doing all the work in one `step.do()`** — defeats the durability story. Split logical steps.
- **Long-running step bodies** (>30s CPU/wall) — each step is still a Worker invocation with the usual limits.

## Gotchas

1. **Steps must be deterministic** — same inputs should produce the same outputs (modulo external API state). If you `Date.now()` inside a step, capture the result in the checkpoint; don't recompute on retry.
2. **`step.sleep()` doesn't burn compute** but the workflow instance has a maximum lifetime — verify against current docs for long-sleeping flows.
3. **Pricing is request-based** — many short steps may cost more than one long step. Profile.
4. **Workflows is Workers Paid** — not on the free tier.
5. **Step retries are configurable** via the second argument to `step.do(name, opts, fn)` — set `retries.limit`, `retries.delay`, `retries.backoff`.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime that hosts Workflow entrypoints
- [Queues](/stacks/cloudflare/queues/) — for fan-out/decoupling instead of multi-step orchestration
- [Durable Objects](/stacks/cloudflare/durable-objects/) — for per-entity serialized state (often paired with Workflows)
- [Cron Triggers](/stacks/cloudflare/cron-triggers/) — kicks Workflows for periodic batch orchestration
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/), [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/)
- Authoritative: [developers.cloudflare.com/workflows](https://developers.cloudflare.com/workflows/)
