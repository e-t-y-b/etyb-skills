---
title: Vercel KV
description: Redis-compatible key-value store on Vercel, now Marketplace-driven via Upstash. For sessions, rate-limit counters, idempotency keys, feature flag overrides.
product:
  name: Vercel KV
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect]
  authoritative_url: https://vercel.com/docs/storage/vercel-kv
  notes: "Now part of unified Vercel Storage; transitioning to managed Upstash/Marketplace partners. `@vercel/kv` still works but new provisioning UX leads with partner installs."
---

## What it is

Vercel KV is a Redis-compatible key-value store, provisioned through the Marketplace (typically Upstash). Sub-millisecond reads, simple SET/GET/INCR/EXPIRE semantics, and TLS by default. See [vercel.com/docs/storage/vercel-kv](https://vercel.com/docs/storage/vercel-kv) and the [Upstash Redis docs](https://upstash.com/docs/redis/overall/getstarted) for the underlying API.

## When to use

- **Sessions** — small, hot, per-user.
- **Rate-limit counters** — `INCR` + `EXPIRE` pattern.
- **Idempotency keys** — `SETNX` with TTL.
- **Feature flag overrides per user** — when [Edge Config](/stacks/vercel/edge-config/) is too coarse.
- **Per-request shared cache** — small values reused across concurrent function invocations.

Don't use KV as:

- **A document store** — Postgres JSONB is better.
- **An event stream** — use [Queues](/stacks/vercel/vercel-queues/) or Kafka.
- **A vector store** — use a vector DB.
- **Storage for blobs > 100KB per key** — use [Vercel Blob](/stacks/vercel/vercel-blob/).

## 2025-2026 currency anchors

- **Marketplace-driven provisioning** — install Upstash via Marketplace; env vars auto-wire.
- **`@vercel/kv` still works** but the storage UX leads with partner provisioning.
- **`@upstash/redis` directly** is often the cleaner choice for new code — fewer abstraction layers.
- **Per-command pricing** with Upstash — cache hit rate and command count matter for cost.

## Patterns + anti-patterns

**Pattern: Rate limiting with INCR + EXPIRE.**

```ts
import { kv } from '@vercel/kv';

export async function rateLimit(key: string, { rpm }: { rpm: number }) {
  const count = await kv.incr(key);
  if (count === 1) await kv.expire(key, 60);
  return count <= rpm;
}
```

**Pattern: Idempotency with SETNX + TTL.**

```ts
const acquired = await kv.set(`idem:${key}`, '1', { nx: true, ex: 3600 });
if (!acquired) return { skipped: 'duplicate' };
// ... do the work ...
```

**Pattern: Session store for short-lived tokens.** TTL aligned to session lifetime.

**Anti-pattern: Storing large JSON blobs.** KV at scale gets expensive fast for the wrong shapes.

**Anti-pattern: Per-tenant data without TTL.** KV is for hot, transient data; without TTL, it accumulates.

**Anti-pattern: Using KV when Edge Config would do.** For read-mostly hot-path config, Edge Config is sub-15ms globally and cheaper.

## Gotchas

- **Per-command pricing** — chatty workloads add up.
- **Eventual consistency** at the Upstash global tier — verify the tier you're on.
- **TLS by default** — connection string includes `rediss://`.
- **`@vercel/kv` is a thin wrapper** — many teams use `@upstash/redis` directly.

## Cross-references

- [Edge Config](/stacks/vercel/edge-config/) — for read-only hot-path config
- [Vercel Postgres](/stacks/vercel/vercel-postgres/) — for relational data
- [Marketplace](/stacks/vercel/marketplace/) — how Upstash gets wired
- [backend-architect on Vercel](/stacks/vercel/backend-architect/) — storage decision matrix
- Authoritative: [KV docs](https://vercel.com/docs/storage/vercel-kv)
- Delegate: `vercel:vercel-storage`
