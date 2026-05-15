---
title: Vercel Functions
description: Serverless compute on Vercel — Fluid Compute by default in 2026. Hosts Server Components rendering, Server Actions, Route Handlers, and AI streaming.
product:
  name: Vercel Functions
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, system-architect, devops-engineer]
  authoritative_url: https://vercel.com/docs/functions
  notes: "Fluid Compute (2025) replaces traditional serverless billing model. In-function concurrency + active CPU billing makes old `cold start vs warm` reasoning wrong. Edge ↔ Node runtimes converging."
---

## What it is

Vercel Functions are the serverless compute primitive on Vercel — they host Server Components rendering, Server Actions, Route Handlers, and streaming responses. As of 2025, the default execution model is **Fluid Compute**: in-instance concurrency, active CPU billing, dynamic CPU scaling within a single instance.

Functions come in two runtimes:

- **Node (Fluid)** — default; full Node API surface; TCP DB connections; the 2026 baseline.
- **Edge** — narrower runtime, lower latency, geo-distributed; converging with Node since 2025.

See [vercel.com/docs/functions](https://vercel.com/docs/functions).

## Route Handlers

`app/api/.../route.ts` exposes HTTP endpoints. Export `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`. Use Route Handlers when:

- A **third-party caller** needs to hit your domain (webhook, mobile app, integration partner, CLI).
- You need **non-JSON responses** (binary streams, SSE, file downloads).
- You're building a **public API** versioned independently.
- You need a **manual response shape** (custom status codes, headers) the Server Action machinery doesn't expose.
- You need **streaming** (AI streaming belongs here, not in Server Actions).

Don't use them for app-internal mutations — [Server Actions](/stacks/vercel/server-actions/) handle those better.

## When to use Node vs Edge runtime

| Factor | Pick Node (Fluid) | Pick Edge |
|--------|-------------------|-----------|
| Postgres/MySQL via TCP | Node | Node (Edge needs HTTP DB clients like Neon HTTP driver) |
| Long-running (> 5s) | Node | Avoid Edge (narrower duration) |
| Heavy CPU (hashing, image processing) | Node | Avoid |
| Streaming SSE for AI | Either | Either |
| Read Edge Config + return JSON | Either | Edge for lowest latency |
| Geo-aware redirects | Either | Edge in middleware |
| `node:fs`, `node:crypto` with key material | Node | Some `node:*` available; verify |
| Sticky concurrency / shared state in-instance | Node + Fluid | Avoid Edge (no instance reuse semantics) |

**2026 default:** Node + Fluid. Reach for Edge in middleware, geo-routing, and low-latency reads against Edge Config / KV. The cost/perf delta is much smaller post-Fluid than it was in 2023.

## 2025-2026 currency anchors

- **Fluid Compute GA 2025.** See [Fluid Compute](/stacks/vercel/fluid-compute/) for the cost/perf math.
- **Node ↔ Edge convergence.** Many Edge-only APIs (`waitUntil`, `geolocation`) are available in Node via `@vercel/functions`; many `node:*` modules now available in Edge.
- **`after()` GA** (formerly `unstable_after`) — schedule post-response work without blocking.
- **`maxDuration` per function**: 60s default, up to 800s Pro, 900s Enterprise. Set in route file or `vercel.json`.
- **Streaming responses stable** — stream tokens/events without buffering the full body.

## Patterns + anti-patterns

**Pattern: Webhook handler with signature verification + queue offload.**

```ts
// app/api/webhooks/stripe/route.ts
import { headers } from 'next/headers';
import { stripe } from '@/lib/server-only-stripe';
import { Queue } from '@vercel/queues';
const eventQueue = new Queue('stripe-events');

export async function POST(req: Request) {
  const sig = (await headers()).get('stripe-signature')!;
  const body = await req.text();
  const event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  await eventQueue.enqueue({ eventId: event.id, type: event.type });
  return Response.json({ received: true });
}
```

**Pattern: `after()` for fire-and-forget.**

```ts
import { after } from 'next/server';

export async function POST(req: Request) {
  const body = await req.json();
  // ... handle ...
  after(async () => { await logToAnalytics({ event: 'submitted', body }); });
  return Response.json({ ok: true });
}
```

**Pattern: Connection pooling at module scope.**

```ts
// lib/db.ts
import 'server-only';
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql);  // Shared across the function instance
```

**Anti-pattern: Re-instantiating DB clients per request.** Fluid shares module-level state across concurrent invocations; reuse.

**Anti-pattern: Skipping signature verification on webhooks.** Always `constructEvent`.

**Anti-pattern: ACK > 5s on a webhook.** Providers retry on slow responses; offload to Queue/Workflow/`after()`.

**Anti-pattern: Edge runtime by reflex.** The 2023-era advice "use Edge for speed" is outdated. Fluid Node is cheap, supports TCP DB connections, fewer constraints. Use Edge in middleware and for genuinely latency-critical reads.

## Gotchas

- **`maxDuration` still applies under Fluid.** A function awaiting 60s of I/O for a single request hits the same cap. Set explicitly for long endpoints.
- **Module-level state is shared across concurrent invocations** on the same Fluid instance. Good (connection reuse) and bad (race conditions if you store request-scoped state in module variables).
- **Edge runtime has narrower duration limits** than Node.
- **CORS is your responsibility** for endpoints called from non-same-origin clients.
- **`runtime` export** at route level overrides default: `export const runtime = 'edge'` or `'nodejs'`.

## Cross-references

- [Fluid Compute](/stacks/vercel/fluid-compute/) — the 2025 execution model
- [Server Actions](/stacks/vercel/server-actions/) — when to use those instead of Route Handlers
- [Vercel Cron](/stacks/vercel/vercel-cron/) — scheduled invocations
- [Vercel Queues](/stacks/vercel/vercel-queues/) — async work offload
- [Workflow](/stacks/vercel/workflow/) — durable multi-step work
- [Vercel Sandbox](/stacks/vercel/vercel-sandbox/) — for untrusted code
- [backend-architect on Vercel](/stacks/vercel/backend-architect/)
- Authoritative: [Functions docs](https://vercel.com/docs/functions), [vercel.com/docs/limits](https://vercel.com/docs/limits)
- Delegate: `vercel:vercel-functions`, `vercel:routing-middleware`
