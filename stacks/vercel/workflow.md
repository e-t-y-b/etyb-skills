---
title: Workflow
description: Durable functions — long-running, multi-step, replay-safe processes. The 2026 default for background jobs and AI agent orchestration on Vercel.
product:
  name: Workflow
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, system-architect]
  authoritative_url: https://vercel.com/docs/workflow
  notes: "GA 2025-2026. Semantics still maturing — verify against current docs before committing. Use for stepwise/retry-safe long-running work; don't reach for Inngest/Temporal before checking fit."
---

## What it is

Vercel Workflow is a durable-function platform — long-running, multi-step processes that survive failures via persistent step results. Each step is wrapped in `step()`; the runtime checkpoints results so re-runs from a failure don't double-execute completed steps. See [vercel.com/docs/workflow](https://vercel.com/docs/workflow).

## When to use

- **Multi-step processes that must complete** even if a single step fails (with retries).
- **Long-running work** spanning minutes/hours/days (post-purchase onboarding email sequences, generative job pipelines, multi-API orchestration).
- **Replay-safe state** — re-runs from failure don't double-execute completed steps.

Don't use Workflow:

- **Single-step async work** — use a [Queue](/stacks/vercel/vercel-queues/), or `after()` for fire-and-forget.
- **Strict ordering across millions of events** — use a real event-streaming platform (Kafka/Pulsar) off-platform.
- **Workflows that need to interact with a user mid-flight** — keep human-in-the-loop in your app code, not in the workflow.

Alternatives:

- **Inngest** (Marketplace) — richer event-driven patterns, fan-out, debouncing.
- **Trigger.dev** (Marketplace) — long-running job platform.
- **Temporal** — for very complex multi-service orchestration; runs outside Vercel.

Pick based on event volume + step complexity + visibility needs. For greenfield Vercel work, default to Workflow.

## 2025-2026 currency anchors

- **GA 2025-2026.** Semantics still maturing — verify the current `@vercel/workflow` API before committing.
- **First-party platform.** Observability + retries + step persistence are managed by Vercel.
- **Composes with Queues, Cron, and Server Actions** — any of those can trigger a workflow.

## Patterns + anti-patterns

**Pattern: Wrap each side-effectful operation in `step()`.**

```ts
// app/workflows/onboard-customer.ts
import { workflow, step } from '@vercel/workflow';
import { stripe } from '@/lib/stripe';
import { sendEmail } from '@/lib/email';

export const onboardCustomer = workflow(
  'onboard-customer',
  async (input: { userId: string; email: string }) => {
    const customer = await step('create-stripe-customer', () =>
      stripe.customers.create({ email: input.email }),
    );

    await step('save-customer-id', () =>
      db.update(users).set({ stripeCustomerId: customer.id }).where(eq(users.id, input.userId)),
    );

    await step('welcome-email', () =>
      sendEmail({ to: input.email, template: 'welcome' }),
    );

    await step.sleep('3 days');

    const user = await step('check-active', () =>
      db.query.users.findFirst({ where: eq(users.id, input.userId) }),
    );

    if (!user?.lastActiveAt) {
      await step('nudge-email', () =>
        sendEmail({ to: input.email, template: 'nudge' }),
      );
    }
  },
);
```

Then trigger from a Server Action or webhook:

```ts
await onboardCustomer.trigger({ userId, email });
```

**Pattern: Workflow-driven AI pipelines.** For multi-step AI work ("extract entities, look up each, classify, summarize"), each step is a separate LLM call wrapped in `step()`. Durable, retry-safe, observable.

**Pattern: Stable step names.** Renaming a step breaks in-flight workflows — the runtime keys on step name.

**Anti-pattern: Modeling every async call as a workflow.** Sending a welcome email after signup is `after()` or a Queue, not a workflow.

**Anti-pattern: Side effects outside `step()`.** Anything not in a `step()` re-executes on replay — non-idempotent code outside a step is a bug waiting to happen.

**Anti-pattern: Workflows that need user interaction mid-flight.** Keep human-in-the-loop in your app; workflows are for autonomous orchestration.

## Gotchas

- **Step names are stable identifiers across deploys.** Don't rename them lightly.
- **Steps must be idempotent enough to retry.** Design your side effects with retry in mind (idempotency keys, upserts vs inserts).
- **`step.sleep` doesn't burn function time** — the runtime parks the workflow.
- **Workflow loops can burn durable function time** — add explicit max-iterations to bounded loops.
- **The runtime persists step results** — large step return values increase storage cost.

## Cross-references

- [Vercel Functions](/stacks/vercel/vercel-functions/) — what triggers workflows
- [Vercel Queues](/stacks/vercel/vercel-queues/) — queue consumers often trigger workflows
- [Vercel Cron](/stacks/vercel/vercel-cron/) — cron triggers workflows for long jobs
- [Vercel Agent](/stacks/vercel/vercel-agent/) — alternative for agentic use cases
- [backend-architect on Vercel](/stacks/vercel/backend-architect/)
- [ai-ml-engineer on Vercel](/stacks/vercel/ai-ml-engineer/) — Workflow for AI pipelines
- Authoritative: [Workflow docs](https://vercel.com/docs/workflow)
- Delegate: `vercel:workflow`
