---
title: Workers RPC
description: "The canonical inter-worker pattern via `WorkerEntrypoint` classes — typed method calls between Workers, replacing legacy `fetcher.fetch()` service bindings."
product:
  name: Workers RPC
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect]
  authoritative_url: https://developers.cloudflare.com/workers/runtime-apis/rpc/
  notes: "WorkerEntrypoint became canonical 2024-25; service binding HTTP-fetch form is legacy."
---

## What it is

Workers RPC lets one Worker call methods on another Worker (or [Durable Object](/stacks/cloudflare/durable-objects/)) as if they were local — typed args and return values, no HTTP overhead, no JSON serialization at the surface. The mechanism: a `WorkerEntrypoint` class exported from the target Worker; the calling Worker declares a service binding with the entrypoint name; methods become methods on `env.<BINDING>`.

Authoritative reference: [developers.cloudflare.com/workers/runtime-apis/rpc](https://developers.cloudflare.com/workers/runtime-apis/rpc/).

## When to use

- **Two Workers in your own account that need to call each other → RPC (service binding).** Free, internal, no HTTP overhead.
- **A Worker calling a Durable Object → DO binding + RPC method.** `env.MY_DO.idFromName("user-42").someMethod(args)`.
- **A Worker calling a customer's Worker ([Workers for Platforms](/stacks/cloudflare/workers-for-platforms/)) → Dispatch Namespace binding.** Routes by namespace.

Don't use RPC for:

- **External APIs** (Stripe, OpenAI, your non-CF service) — use `fetch()`. Counts as a subrequest.
- **Fire-and-forget across Workers** — use [Queues](/stacks/cloudflare/queues/) (decouple, retries, batching).

## 2025-2026 currency anchors

- **`WorkerEntrypoint` is the canonical pattern** as of 2024-25. Older `env.OTHER.fetch(request)` service bindings still work but new code should use entrypoints.
- **RPC traverses Workers, Durable Objects, and Workers for Platforms** — same primitive across all three surfaces.
- **RPC method args/returns** can be primitives, `ArrayBuffer`, `Request`/`Response`, `ReadableStream`, `Map`/`Set`, dates, errors. Callable stubs and disposable resources are supported.

## Patterns

### Modern pattern (canonical)

```ts
// Worker B — exports an entrypoint class
import { WorkerEntrypoint } from "cloudflare:workers";

export class MyService extends WorkerEntrypoint<Env> {
  async getUser(userId: string): Promise<User> {
    return this.env.DB.prepare("SELECT * FROM users WHERE id=?").bind(userId).first<User>();
  }
}

// Worker A — calls a method directly
export default {
  async fetch(req, env) {
    const user = await env.OTHER.getUser("u_42");
    return Response.json(user);
  }
}
```

```toml
# Worker A wrangler.toml
[[services]]
binding = "OTHER"
service = "worker-b"
entrypoint = "MyService"
```

### Per-Worker `WorkerEntrypoint` for clean public APIs

Instead of `fetch` returning JSON, expose a typed RPC surface:

```ts
export class OrdersService extends WorkerEntrypoint<Env> {
  async createOrder(input: CreateOrderInput): Promise<Order> {
    return createOrder(new OrderRepo(this.env.DB), input);
  }
  async getOrder(id: string): Promise<Order | null> {
    return new OrderRepo(this.env.DB).get(id);
  }
}

// Default export still handles HTTP — for browsers / external callers
export default { async fetch(req, env, ctx) { return app.fetch(req, env, ctx); } };
```

Other Workers call via RPC bindings (type-safe). External callers hit the HTTP routes. **Same service, two surfaces** — the class is the source of truth.

### Legacy pattern (still works, do not use for new code)

```ts
// Worker A
export default {
  async fetch(req, env) {
    return env.OTHER.fetch(new Request("https://service/foo", { body }));
  }
}
```

If you find this in code, migrate to `WorkerEntrypoint` — typed, faster, more observable.

## Anti-patterns

- **Service bindings with HTTP fetch when both sides are your Workers.** Use RPC. Faster, type-safe, less overhead.
- **JSON-stringifying args you could pass as objects.** RPC handles structured types natively.
- **Forgetting `wrangler types` after adding an entrypoint** — the calling Worker's `Env` interface won't reflect the new methods until you regenerate.

## Gotchas

1. **Bindings must declare `entrypoint`** for RPC to surface methods. Without it you get the legacy `Fetcher` shape.
2. **Method args/return must be RPC-serializable.** Functions, classes (other than known RPC types), DOM-style nodes don't cross the boundary.
3. **RPC across accounts isn't supported** — service bindings are intra-account. For cross-account, you fall back to HTTP `fetch()` over the public internet.
4. **Tests:** `@cloudflare/vitest-pool-workers` supports RPC bindings — test the calling Worker against a fixture Worker.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime context
- [Durable Objects](/stacks/cloudflare/durable-objects/) — RPC on DOs uses the same primitive
- [Workers for Platforms](/stacks/cloudflare/workers-for-platforms/) — Dispatch Namespaces use RPC for tenant routing
- [Wrangler](/stacks/cloudflare/wrangler/) — service binding configuration and `wrangler types`
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/workers/runtime-apis/rpc](https://developers.cloudflare.com/workers/runtime-apis/rpc/)
