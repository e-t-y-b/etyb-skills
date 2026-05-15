---
title: KV
description: Cloudflare's eventually-consistent global key-value store — read-heavy, fast at edge, ~60s write propagation. Use for config, sessions, feature flags.
product:
  name: KV
  stack: cloudflare
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect]
  authoritative_url: https://developers.cloudflare.com/kv/
  notes: "Eventually-consistent semantics stable for years; limits and pricing tier (Standard) shifted 2024."
---

## What it is

KV is Cloudflare's globally-distributed eventually-consistent key-value store. Reads are fast from any Cloudflare colo (cached at the edge). Writes propagate to read POPs over up to ~60 seconds. Per-key write rate limit ~1/sec.

Authoritative reference: [developers.cloudflare.com/kv](https://developers.cloudflare.com/kv/).

## When to use

- **Read-heavy config** — feature flags, allow lists, lookup tables.
- **Session tokens** with TTL — auto-expire after inactivity, OK to be stale by 60s.
- **Cached transformations** — Worker fetches → transforms → caches in KV.
- **Anywhere stale-by-60s is acceptable.**

Don't use KV when:

- **Read-your-writes matters.** The user adds an item, hits checkout, doesn't see it, files a bug.
- **Transactional state, payment flows, account capability checks** — anything where stale is a bug.
- **High-write counters** — per-key rate limit ~1/sec; you'll hit it. Use [DO](/stacks/cloudflare/durable-objects/), Workers Rate Limiting binding, or [Analytics Engine](/stacks/cloudflare/analytics-engine/).
- **PII without TTL** — GDPR/DSAR/deletion gets ugly. Use [D1](/stacks/cloudflare/d1/) so you can `DELETE FROM users WHERE id = ?` cleanly.

## 2025-2026 currency anchors

- **KV semantics have been stable for years** — eventual consistency, ~60s globally, ~1/sec/key write rate, value size limits, TTL support.
- **KV Standard pricing tier** shifted in 2024 — verify against [pricing](https://developers.cloudflare.com/kv/platform/pricing/) before estimating large-scale usage.

## Patterns

### Session token with TTL

```ts
await env.SESSIONS.put(`session:${sessionId}`, JSON.stringify(payload), {
  expirationTtl: 60 * 60 * 24 * 7  // 7 days
});

const raw = await env.SESSIONS.get(`session:${sessionId}`);
const session = raw ? JSON.parse(raw) : null;
```

KV TTL handles expiry automatically. Don't try to implement "delete after X" yourself.

### Feature flags

```ts
const flags = await env.CONFIG.get("feature-flags", { type: "json", cacheTtl: 60 });
if (flags?.new_checkout) {
  // ...
}
```

`cacheTtl` parameter caches the value locally in the Worker isolate for that duration — reduces colo-level KV reads.

### Cache API alternative for very-short-TTL data

```ts
async fetch(req, env, ctx) {
  const cache = caches.default;
  let res = await cache.match(req);
  if (res) return res;

  res = await origin(req);
  ctx.waitUntil(cache.put(req, res.clone()));
  return res;
}
```

For short-TTL data that doesn't need to be globally consistent, the Cache API is free reads/writes within a colo — preferable to KV for ephemeral caching. Use KV when you need cross-colo consistency.

## Anti-patterns

- **KV as transactional state** — cart contents, payment state, account-level capability flags. All wrong fits.
- **Writing through KV under load** — per-key rate limit ~1/sec. Increment-counter-in-KV breaks at modest traffic.
- **Using TTL as the sole "delete" mechanism for sensitive data** — TTL is best-effort. For hard-delete with audit, use D1.
- **Cardholder data in KV** — eventual consistency + no TTL guarantees on deletes. Never put PCI/PHI in KV.

## Gotchas

1. **Writes are eventually consistent (~60s globally).** Reads after a write may be stale.
2. **Per-key write rate limit ~1/sec.** Burst writes get rejected.
3. **Value size limit** (verify current). Don't put large blobs in KV — use [R2](/stacks/cloudflare/r2/).
4. **Listing keys is paginated** and bounded — KV is not designed for "give me all keys matching a prefix" at scale.
5. **No transactions** — read-modify-write is racy. Use DO for that.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime that consumes KV bindings
- [D1](/stacks/cloudflare/d1/) — when you need transactional / read-your-writes
- [Durable Objects](/stacks/cloudflare/durable-objects/) — when you need per-entity strong consistency
- [R2](/stacks/cloudflare/r2/) — for larger blobs that don't fit KV's profile
- Role overlay: [database-architect on Cloudflare](/stacks/cloudflare/database-architect/), [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/)
- Authoritative: [developers.cloudflare.com/kv](https://developers.cloudflare.com/kv/)
