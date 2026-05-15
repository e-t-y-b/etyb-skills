---
title: Fluid Compute
description: Vercel's 2025 execution model — in-function concurrency, active CPU billing, dynamic CPU scaling within one instance. The default for Vercel Functions.
product:
  name: Fluid Compute
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, system-architect]
  authoritative_url: https://vercel.com/docs/fluid-compute
  notes: "GA 2025. Fundamentally changes cost + concurrency math. Pre-Fluid `cold start vs warm` reasoning is wrong. Default for Vercel Functions in 2026."
---

## What it is

Fluid Compute is the 2025 execution model for Vercel Functions. Instead of each invocation getting its own instance and you paying for wall-clock GB-seconds, Fluid:

- **Multiplexes in-process concurrency** — one instance serves multiple concurrent invocations.
- **Bills active CPU** — actual CPU time executing your code, not time spent awaiting I/O.
- **Scales CPU dynamically** within a single instance.

This is the default for Vercel Functions on Node runtime. See [vercel.com/docs/fluid-compute](https://vercel.com/docs/fluid-compute).

## When to use

Fluid is the default — there's no opt-in needed for Node-runtime Vercel Functions. The relevant decision is whether **a workload fits Fluid** vs needs Edge runtime, Workflow, off-Vercel compute, or Sandbox:

- **Fits Fluid:** I/O-bound work (DB query, LLM call, API call), request lifecycle < 60s (or up to 800/900s on higher tiers), concurrency benefits from in-instance multiplexing.
- **Doesn't fit:** continuous background work, GPU inference, sticky-session WebSocket at large scale, local-disk-heavy workloads.

## 2025-2026 currency anchors

- **GA 2025.** The pricing/concurrency math is fundamentally different from pre-Fluid serverless. Old guidance about "cold start vs warm" is wrong.
- **Active CPU is the bill driver**, not wall-clock GB-seconds.
- **Module-level state is shared** across concurrent invocations on the same instance — connection pools, in-memory caches reused.
- **`maxDuration` still applies.** A function awaiting 60s of I/O hits the cap.

## The math you need to know

Implications of Fluid:

1. **Async I/O is nearly free.** A function awaiting a 2s LLM call costs the active CPU during the await, not 2s × memory.
2. **In-process concurrency means in-process bugs hurt.** Module-level state (e.g., `let connectionPool: Pool | null = null`) is now shared across concurrent invocations on the same instance. This is good (connection reuse) and bad (race conditions if you're not careful).
3. **Bad N+1 queries become "expensive but not slow."** Concurrency masks them. Add tracing.
4. **Memory tier matters less** than response time + active CPU.

## Patterns + anti-patterns

**Pattern: Module-scope DB clients.**

```ts
import 'server-only';
import { neon } from '@neondatabase/serverless';
export const sql = neon(process.env.DATABASE_URL!);  // Shared across concurrent invocations
```

**Pattern: OTel tracing to surface what Fluid hides.**

```ts
// instrumentation.ts (at project root)
import { registerOTel } from '@vercel/otel';
export function register() { registerOTel({ serviceName: 'my-app' }); }
```

Auto-instruments Server Actions, Route Handlers, fetch calls. Without tracing, Fluid hides the kind of issues "look at the function logs" used to catch.

**Anti-pattern: Storing request-scoped state in module variables.** Module variables persist across concurrent invocations on the same instance — a `currentUser` global would leak across users.

**Anti-pattern: Per-route blanket `maxDuration: 800`.** Inflates worst-case cost and masks bad design.

**Anti-pattern: Reasoning about cost from pre-Fluid GB-second guides.** Re-model on active CPU.

## Gotchas

- **`maxDuration` is still the cap.** Fluid doesn't make long-running work free.
- **Module-level state shared across concurrent invocations** can be subtle — race conditions in shared mutable state will bite.
- **Edge runtime doesn't have Fluid semantics** (no instance reuse semantics like Fluid Node). Choose runtime carefully.
- **Tracing is mandatory** at any meaningful scale — Fluid masks slow-but-not-failing operations.

## Cross-references

- [Vercel Functions](/stacks/vercel/vercel-functions/) — the surface Fluid powers
- [backend-architect on Vercel](/stacks/vercel/backend-architect/)
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — cost monitoring under Fluid
- Authoritative: [Fluid Compute docs](https://vercel.com/docs/fluid-compute)
- Delegate: `vercel:vercel-functions`
