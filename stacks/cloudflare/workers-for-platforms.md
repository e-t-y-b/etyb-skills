---
title: Workers for Platforms
description: Multi-tenant Worker execution — Dispatch Namespaces, Outbound Workers, Tail Workers. The SaaS pattern for letting customers run their own JS on your edge.
product:
  name: Workers for Platforms
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, backend-architect, devops-engineer, saas-architect]
  authoritative_url: https://developers.cloudflare.com/cloudflare-for-platforms/workers-for-platforms/
  notes: "Premium SKU; Dispatch Namespaces + Outbound Workers + Tail Workers matured 2024-25 for SaaS tenant isolation."
---

## What it is

Workers for Platforms lets you run your customers' code (or scoped per-tenant code you control) on Cloudflare's edge with strong isolation. The core primitives:

- **Dispatch Namespaces** — a namespace of tenant Workers; a router Worker dispatches incoming requests to the right tenant.
- **Outbound Workers** — control what each tenant Worker is allowed to call outbound (egress policy at the platform layer).
- **Tail Workers** — capture per-tenant logs without flooding your global Workers Logs.

This is the **only** sensible pattern at any non-trivial scale for "your customers write JS that runs on your platform." Premium SKU; talk to Cloudflare.

Authoritative reference: [developers.cloudflare.com/cloudflare-for-platforms/workers-for-platforms](https://developers.cloudflare.com/cloudflare-for-platforms/workers-for-platforms/).

## When to use

- **You sell a SaaS where customers extend the product with code.** A function-as-a-service offering, a Shopify-style app platform, a programmable webhook surface.
- **You need strong tenant isolation** beyond `if (tenantId === ...)` branches in one Worker.
- **You need per-tenant observability** (their logs, their analytics) — Tail Workers handle this.
- **You need per-tenant egress controls** — Outbound Workers gate what tenant code can talk to.

Don't use Workers for Platforms when:

- You're a single team running your own multi-tenant logic with data partitioning — a single Worker with tenant-aware bindings is cheaper and simpler.
- Your tenants don't author code; they just have data — that's a normal multi-tenant app, not Workers for Platforms territory.

## 2025-2026 currency anchors

- **Matured through 2024-25** into a coherent SaaS-platform offering — Dispatch Namespaces, Outbound Workers, Tail Workers per tenant are all GA.
- **[Workers RPC](/stacks/cloudflare/workers-rpc/)** traverses Dispatch Namespaces — same primitive as Worker-to-Worker.
- **Premium SKU** — pricing differs from standard Workers Paid; contact Cloudflare for quotes at scale.

## Patterns

### Router Worker + Dispatch Namespace

```ts
// Router Worker (your code)
export default {
  async fetch(req, env) {
    const tenantId = extractTenantFromHost(req);
    const tenantWorker = env.DISPATCHER.get(`tenant-${tenantId}`);
    return tenantWorker.fetch(req);
  }
}
```

```toml
[[dispatch_namespaces]]
binding = "DISPATCHER"
namespace = "tenant-workers"
```

Tenant Workers are deployed into the `tenant-workers` namespace (via API). The router dispatches by namespace name.

### Outbound Worker (egress policy)

```ts
// Outbound Worker — runs for every outbound fetch from a tenant Worker
export default {
  async fetch(req, env, ctx) {
    const target = new URL(req.url);
    // Block tenant calls to disallowed hosts
    if (DISALLOWED_HOSTS.includes(target.hostname)) {
      return new Response("Forbidden destination", { status: 403 });
    }
    // Add auth headers, rate limit, log, etc.
    return fetch(req);
  }
}
```

Each tenant Worker's outbound `fetch()` calls pass through the Outbound Worker first. Use this to:

- Enforce allow/deny lists of destination hosts.
- Inject auth headers for backend services tenants are allowed to reach.
- Rate-limit per tenant.
- Log all egress for compliance.

### Tail Worker for per-tenant logs

```ts
// Tail Worker — runs once per invocation of any worker in the dispatch namespace
export default {
  async tail(events, env) {
    for (const event of events) {
      await env.TENANT_LOG_QUEUE.send({
        tenantId: event.scriptName.replace("tenant-", ""),
        logs: event.logs,
        outcome: event.outcome,
        timestamp: event.eventTimestamp
      });
    }
  }
}
```

Logs route to a queue → tenant-facing storage → tenant dashboard. Not your global Workers Logs.

## Anti-patterns

- **Single-Worker tenant-switch** (`if (tenantId === "A") doA() else doB()`) for customer-authored logic — no isolation, blast radius is global, can't sandbox.
- **Skipping Outbound Workers** — tenant code can call anywhere on the internet, including your internal services. Disastrous for compliance and security.
- **Sharing one Tail Worker output stream across tenants without tagging** — you'll surface other tenants' logs to wrong customers.

## Gotchas

1. **Premium SKU** — confirm pricing with Cloudflare before architecting around it; not Workers Paid.
2. **Cold-start tail** — tenant Workers that haven't been hit recently may have warmer-than-standard cold-starts depending on namespace size; verify against current docs.
3. **Per-namespace limits** — number of Workers per Dispatch Namespace has caps; design for sharding if you have >tens of thousands of tenants.
4. **Tenant code is still V8-isolate-only** — same Workers runtime constraints (no Node, CPU/subrequest budgets) apply per tenant.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime each tenant Worker runs on
- [Workers RPC](/stacks/cloudflare/workers-rpc/) — Dispatch Namespace binding uses RPC under the hood
- [Workers Logs](/stacks/cloudflare/workers-logs/) — Tail Workers replace per-tenant Logs ingestion
- Role overlay: [system-architect on Cloudflare](/stacks/cloudflare/system-architect/), [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/cloudflare-for-platforms/workers-for-platforms](https://developers.cloudflare.com/cloudflare-for-platforms/workers-for-platforms/)
