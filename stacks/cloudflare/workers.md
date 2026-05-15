---
title: Workers
description: Cloudflare's V8-isolate runtime (workerd) for HTTP, scheduled, queue, email, and alarm handlers — the compute primitive every Cloudflare app composes around.
product:
  name: Workers
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, devops-engineer, ai-ml-engineer, security-engineer]
  authoritative_url: https://developers.cloudflare.com/workers/
  notes: "Compatibility-date model + nodejs_compat flags shift quarterly; runtime keeps adding Node-compat surface."
---

## What it is

Cloudflare Workers is the V8-isolate runtime (`workerd`) that wakes up on a request, runs for some milliseconds, and may be recycled at any time. It is **not Node.js, not a traditional FaaS, not a long-running server**. It is a web-standards runtime (Fetch, Streams, Crypto, URLPattern, WebSockets) extended with Cloudflare bindings. Distributed by default — every Worker runs in every Cloudflare data center; routing happens automatically.

Authoritative reference: [developers.cloudflare.com/workers](https://developers.cloudflare.com/workers/).

## When to use

Workers is the compute primitive Cloudflare expects you to build on. Reach for it when:

- HTTP API handler, <30s per request, V8-runnable code.
- Edge transforms (caching, A/B, rewrites, geolocation).
- Anything composing with Cloudflare bindings (D1, KV, R2, DO, Queues, AI, Vectorize, Hyperdrive).

Don't reach for Workers when:

- Code in a language Workers can't run (Python beyond limited beta, Ruby, Go without Wasm) — use [Containers on Workers](/stacks/cloudflare/workers/) (beta) or external compute.
- You need >30s wall clock or >30s CPU — push to [Workflows](/stacks/cloudflare/workflows/) for durable multi-step, or containers/external for heavy CPU.
- You need persistent local disk — Workers have none. State lives in [DO](/stacks/cloudflare/durable-objects/), [D1](/stacks/cloudflare/d1/), [KV](/stacks/cloudflare/kv/), or [R2](/stacks/cloudflare/r2/).
- You need to shell out to a binary (FFmpeg, ImageMagick, Pandoc) — containers.

## 2025-2026 currency anchors

- **`compatibility_date` is not optional.** Without one, the runtime falls back to old (pre-2022-ish) semantics — fetch streams, encoding, headers all behave differently. Pin near deployment date; don't bump blindly.
- **`nodejs_compat_v2`** is the modern flag (replaces `nodejs_compat`). Enables more Node APIs (Buffer, EventEmitter, util, crypto, async_hooks).
- **Workers RPC** with `WorkerEntrypoint` classes is the canonical inter-worker pattern as of 2024-25. See [Workers RPC](/stacks/cloudflare/workers-rpc/).
- **Wrangler v4** is current. `wrangler deploy` (not `publish`). See [Wrangler](/stacks/cloudflare/wrangler/).
- **`@cloudflare/vitest-pool-workers`** is the only testing primitive worth recommending — runs Vitest against actual workerd with bindings.

## Handler types

Workers expose a small set of entrypoint handlers. Pick the one that matches the trigger; don't multiplex:

| Handler | Triggered by | Notable limits |
|---------|--------------|----------------|
| `fetch(request, env, ctx)` | HTTP request to a route/domain | CPU 10ms/30s; subrequest 50/1000; body 100MB streamed |
| `scheduled(controller, env, ctx)` | [Cron Triggers](/stacks/cloudflare/cron-triggers/) (UTC, 1-min granularity) | Same CPU as fetch; `controller.cron` identifies which schedule fired |
| `queue(batch, env, ctx)` | [Queues](/stacks/cloudflare/queues/) consumer | Up to 100 messages per batch; batch-level retry |
| `email(message, env, ctx)` | [Email Routing](/stacks/cloudflare/email-routing/) → [Email Worker](/stacks/cloudflare/email-workers/) | Inbound only; forward, drop, or process |
| `tail(events, env, ctx)` | Tail Worker on another Worker | Process logs from another Worker ([Workers for Platforms](/stacks/cloudflare/workers-for-platforms/) pattern) |
| `alarm()` (on a DO) | `state.storage.setAlarm()` | Single alarm per DO; replaces last one on set |
| `connect(ws)` / `webSocketMessage` | WebSocket upgrade in a DO | DO Hibernation API for many idle WebSockets |
| `RPC method` (on a `WorkerEntrypoint`) | Service binding / DO binding RPC call | Method args/return must be RPC-serializable |

## Limits and budgets

- **CPU time:** 10ms (free), 30s (paid). Wall clock can be much longer if you're waiting on I/O.
- **Subrequest budget:** 50 (free) / 1000 (paid) per Worker invocation. Every `fetch()` counts — to D1, R2, Vectorize, KV, another Worker, external APIs.
- **Request body:** 100MB streamed.
- **`ctx.waitUntil`** extends the isolate lifetime up to 30s past the response (longer for some triggers — verify per handler).

## Patterns

### Bindings-first design

Declare bindings in `wrangler.toml` before writing code. The bindings list **is** the architecture diagram:

```toml
name = "orders-api"
main = "src/index.ts"
compatibility_date = "2026-05-01"
compatibility_flags = ["nodejs_compat_v2"]

[[d1_databases]]
binding = "DB"
database_name = "orders-prod"
database_id = "..."

[[kv_namespaces]]
binding = "SESSIONS"
id = "..."

[[r2_buckets]]
binding = "RECEIPTS"
bucket_name = "orders-receipts"

[ai]
binding = "AI"
```

Anti-pattern: dynamic discovery / configuration of "where does data live". Bindings are static; that's a feature.

### Thin handler, modules for logic, repos for DB

```ts
// src/index.ts
import { Hono } from "hono";
import { ordersRouter } from "./routes/orders";

const app = new Hono<{ Bindings: Env }>();
app.route("/orders", ordersRouter);
export default app;
```

Anti-pattern: 800-line `fetch` handler with inline SQL, inline auth, inline business logic.

### Explicit `ctx.waitUntil` for background work

```ts
async fetch(req, env, ctx) {
  const response = await handle(req, env);
  ctx.waitUntil(logToAnalytics(req, response, env));
  return response;
}
```

Anti-pattern: `logToAnalytics(...)` (no `await`, no `waitUntil`) — promise gets garbage-collected when the response returns; work never happens.

### Streaming responses for LLM and large payloads

```ts
async fetch(req, env) {
  const stream = await env.AI.run("@cf/meta/llama-4-...", { messages, stream: true });
  return new Response(stream, {
    headers: { "content-type": "text/event-stream", "cache-control": "no-store" }
  });
}
```

V8 isolates can stream out a response while still running. Wall-clock isn't bound by CPU time.

## Anti-patterns

- **"Just run Express on Workers."** No. Use Hono or itty-router. Express expects Node primitives that Workers don't have.
- **In-memory cache as if it persists** across requests — isolates can be recycled at any time. Use the Cache API or [KV](/stacks/cloudflare/kv/).
- **Subrequest fan-out in a loop** — breaks at the 50/1000 limit. Batch ([D1 batch](/stacks/cloudflare/d1/), R2 list, Vectorize batch), or fan out to a [Queue](/stacks/cloudflare/queues/).
- **Blocking on `crypto` for big payloads** — stream through (chunk + incremental hash) or push to [R2](/stacks/cloudflare/r2/) (server-side checksum).
- **Hardcoded model IDs** — model catalog churns. Env-var indirected.

## Gotchas

1. **There is no Node.js by default.** `fs`, `child_process`, `net`, raw TCP sockets — none exist. Enable `nodejs_compat_v2` for the polyfilled subset. Library choice is gated by this.
2. **`fetch()` from a Worker has different semantics depending on URL.** Hitting your own zone may hit cache. Use [Workers RPC](/stacks/cloudflare/workers-rpc/) or service bindings for in-Cloudflare calls — free, internal, skip the egress hop.
3. **Respect the V8 isolate model.** No stateful in-memory caches expected to persist. No long-running threads. State lives in DO/D1/KV/R2.
4. **Workers Paid plan** ($5/mo) unlocks Cron Triggers, Queues, large CPU limits, DOs. Recommendations branch heavily on plan — ask if unclear.

## Cross-references

- [Workers RPC](/stacks/cloudflare/workers-rpc/) — canonical inter-worker calls
- [Wrangler](/stacks/cloudflare/wrangler/) — dev/deploy CLI
- [Smart Placement](/stacks/cloudflare/smart-placement/) — run Workers near backend
- [Durable Objects](/stacks/cloudflare/durable-objects/) — stateful per-entity workloads
- [Workers Static Assets](/stacks/cloudflare/workers-static-assets/) — replaces Pages for new sites
- [Workers Logs](/stacks/cloudflare/workers-logs/) — queryable observability
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/)
- Authoritative: [developers.cloudflare.com/workers](https://developers.cloudflare.com/workers/), [runtime APIs](https://developers.cloudflare.com/workers/runtime-apis/), [compatibility dates](https://developers.cloudflare.com/workers/configuration/compatibility-dates/)
