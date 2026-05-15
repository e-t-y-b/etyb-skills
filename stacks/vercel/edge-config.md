---
title: Edge Config
description: Ultra-low-latency, read-only config store. <15ms reads globally. For feature flags, allowlists, geo routing, A/B variants — the hot-path config layer.
product:
  name: Edge Config
  stack: vercel
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect, devops-engineer]
  authoritative_url: https://vercel.com/docs/storage/edge-config
  notes: "Stable. Read-only at the edge; writes via Vercel API or Marketplace integration. Use for feature flags, allowlists, geo routing — anything read on every request."
---

## What it is

Edge Config is a read-only, ultra-low-latency configuration store. Reads complete in < 15ms globally. Writes happen through the Vercel API or via Marketplace integrations (Statsig, LaunchDarkly mirror flag state to Edge Config). See [vercel.com/docs/storage/edge-config](https://vercel.com/docs/storage/edge-config).

## When to use

- **Feature flags** — read in middleware or Server Components on every request.
- **Allowlists / blocklists** — geo, IP, tenant ID.
- **A/B test variant configuration.**
- **Geo routing rules** — country → region/feature mapping.
- **On-call rotation** — current on-call person, escalation paths.
- **Anything read on every request** — Edge Config beats DB / KV for hot-path config.

Don't use Edge Config for:

- **Data you mutate frequently** — writes go through Vercel API; high-frequency writes are expensive.
- **Per-user data** — use [KV](/stacks/vercel/vercel-kv/) for hot per-user state.
- **Large payloads** — Edge Config is for small config-shaped data, not blobs.

## 2025-2026 currency anchors

- **Stable** — API surface largely unchanged in 2026.
- **< 15ms reads globally** — the platform's hot-path config layer.
- **Marketplace integration with feature-flag providers** (Statsig, LaunchDarkly) — they mirror state to Edge Config so your reads are sub-15ms.

## Patterns + anti-patterns

**Pattern: Feature flag read in middleware.**

```ts
import { get } from '@vercel/edge-config';

export async function middleware(req: NextRequest) {
  const newCheckout = await get<boolean>('new-checkout-enabled');
  if (newCheckout) {
    return NextResponse.rewrite(new URL('/checkout-v2', req.url));
  }
}
```

**Pattern: Geo routing.**

```ts
const geoConfig = await get<Record<string, string>>('geo-routes');
const country = req.geo?.country ?? 'US';
const variant = geoConfig[country] ?? 'default';
```

**Pattern: Mirror feature flag provider state.** Use Statsig/LaunchDarkly Marketplace integration to keep flags in their UI while reads go to Edge Config.

**Anti-pattern: Edge Config for hot-mutating data.** Writes are expensive; use KV or Postgres.

**Anti-pattern: Large JSON blobs.** Edge Config is for small config; don't store catalogs.

**Anti-pattern: Skipping Edge Config and reading from DB in middleware.** DB query in middleware multiplies your DB load by your request volume.

## Gotchas

- **Writes go through the Vercel API** — not from your function. High-frequency writes are expensive and rate-limited.
- **Reads are eventually consistent** with writes — propagation across the edge takes seconds.
- **Type safety is your responsibility** — `get<T>()` casts; the runtime data shape is your invariant.

## Cross-references

- [Vercel KV](/stacks/vercel/vercel-kv/) — for hot per-user state
- [Marketplace](/stacks/vercel/marketplace/) — for Statsig/LaunchDarkly mirroring
- [Vercel Functions](/stacks/vercel/vercel-functions/) — middleware reads Edge Config
- [backend-architect on Vercel](/stacks/vercel/backend-architect/)
- Authoritative: [Edge Config docs](https://vercel.com/docs/storage/edge-config)
- Delegate: `vercel:vercel-storage`
