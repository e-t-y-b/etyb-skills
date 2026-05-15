---
title: Vercel Cache
description: The platform-level cache tier — Edge Network static asset cache plus Cache Components storage. Drives the cost line for cached-heavy apps.
product:
  name: Vercel Cache
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, devops-engineer, system-architect]
  authoritative_url: https://vercel.com/docs/edge-network/caching
  notes: "The cache surface includes Edge Network for static + Cache Components storage for `'use cache'` results. Cost line visible in 2026 pricing — high-traffic cached routes show up here."
---

## What it is

Vercel Cache is the platform-level cache layer. Two main surfaces:

- **Edge Network cache** — static assets, public files, CDN-cached responses, cached fetches. Global, propagates within seconds.
- **Cache Components storage** — `'use cache'` results stored per route + tag. Invalidated via `revalidateTag()` / `revalidatePath()`.

See [vercel.com/docs/edge-network/caching](https://vercel.com/docs/edge-network/caching) and the [Cache Components reference](/stacks/vercel/cache-components/) for the application-level model.

## When to use

The Edge Network cache is implicit — anything you ship as a static asset, anything with a `Cache-Control` header, anything cached by `fetch()` or Cache Components lands here.

The relevant decisions are:

- **What to cache and at what granularity.** [Cache Components](/stacks/vercel/cache-components/) gives you function/component scope; legacy `fetch` caching gives you per-call.
- **Where to set Cache-Control.** Static assets, public Blob URLs, Route Handlers returning JSON — all can carry their own headers.
- **When to invalidate.** Server Actions calling `revalidateTag` is the 2026 default loop.

## 2025-2026 currency anchors

- **Cache Components storage is a separate line item** in Vercel pricing — high-volume cached routes show up here.
- **Tag-based invalidation propagates within seconds** across the Edge Network.
- **`stale-while-revalidate`** in Cache Components profiles lets stale content serve while a fresh fetch runs in the background.
- **Edge Network is multi-region by default** — content cached at the user's nearest POP.

## Patterns + anti-patterns

**Pattern: Set explicit Cache-Control on Route Handlers.**

```ts
export async function GET() {
  return new Response(JSON.stringify(data), {
    headers: { 'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300' },
  });
}
```

**Pattern: Cache Components for app-internal data.** `'use cache'` is the high-level primitive; underlying storage is platform-managed.

**Pattern: Aggressive caching at the right granularity.** Cache shared subqueries (feature flags, navigation, public catalog), not per-user pages.

**Anti-pattern: Cache everything by reflex.** Per-user pages with `'use cache'` will leak data or show wrong content. Cache deliberately.

**Anti-pattern: Long TTL with no tag.** Without `cacheTag()`, you can't invalidate on mutation. Stale content lingers until TTL.

**Anti-pattern: Bypassing the cache without intent.** `export const dynamic = 'force-dynamic'` or `cookies()`/`headers()` reads opt routes out of caching; do it explicitly, with a comment.

## Gotchas

- **Cache Components storage shows up as a pricing line** — high-volume cached routes are visible there. Tune `cacheLife` profiles before they balloon.
- **Tag invalidation is platform-wide for that project** — if you `revalidateTag('products')` from a webhook, every cached function with that tag refreshes.
- **`stale-while-revalidate` lets stale content serve** — good for UX, but the staleness is real; verify the SLA for your use case.
- **Edge cache vs in-function cache** — Edge cache is platform-managed; in-function module-level state under Fluid is per-instance. Don't conflate them.

## Cross-references

- [Cache Components](/stacks/vercel/cache-components/) — application-level caching primitive
- [Edge Config](/stacks/vercel/edge-config/) — ultra-low-latency config read, different from cache
- [Image Optimization](/stacks/vercel/image-optimization/) — uses Edge cache for transforms
- [ISR](/stacks/vercel/isr/) — the legacy revalidation model
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — cost monitoring
- Authoritative: [caching docs](https://vercel.com/docs/edge-network/caching)
