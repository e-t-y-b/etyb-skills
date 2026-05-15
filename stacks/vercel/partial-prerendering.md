---
title: Partial Prerendering (PPR)
description: Static shell at build time + streamed dynamic Suspense holes per request. The 2026 default rendering model in Next.js 16.
product:
  name: Partial Prerendering
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, system-architect]
  authoritative_url: https://nextjs.org/docs/app/getting-started/partial-prerendering
  notes: "GA in Next.js 16; default rendering for most routes. Different mental model from SSR/SSG/ISR — neither pure static nor pure dynamic."
---

## What it is

Partial Prerendering (PPR) lets a single route ship a **static shell** prerendered at build time, with **dynamic holes** wrapped in `<Suspense>` that stream in per request. Within those dynamic holes, individual components can be **cached** (with `'use cache'`) at their own TTL and tag.

This is the 2026 default rendering model in Next.js 16 — neither SSG, SSR, nor ISR in the classical sense. See [nextjs.org/docs/app/getting-started/partial-prerendering](https://nextjs.org/docs/app/getting-started/partial-prerendering).

## When to use

For most pages on Vercel in 2026, PPR is the default. It's the right model for:

- **Pages with a fast static frame and slow personalized chunks** — product detail pages with cached metadata and live pricing/inventory; dashboards with cached navigation and personalized data.
- **Marketing/content pages** that need fast TTFB and occasional dynamic insertion (logged-in vs logged-out CTAs, A/B variants).
- **Routes where the "shell" is the same for everyone** and dynamic data lives in well-defined Suspense boundaries.

PPR doesn't fit when:

- **Everything is dynamic per user** (auth-walled dashboard with no shared shell) — full dynamic is fine; PPR has nothing static to prerender.
- **Everything is static** — pure SSG/`output: 'export'` is lighter.
- **Real-time data** (chat, live scores, collaborative editing) — Suspense holes streaming once per request doesn't help; use SSE/WebSockets/Realtime.

## 2025-2026 currency anchors

- **GA in Next.js 16** as the default rendering model for new App Router projects.
- **`experimental.ppr = 'incremental'`** in `next.config.ts` lets you opt-in route-by-route during migration; `experimental_ppr = true` per route file enables it.
- **Composes with Cache Components.** A PPR Suspense hole can contain a `'use cache'`-marked Server Component with its own TTL and tag.
- **Streaming is automatic** for content inside a `<Suspense>` boundary on a PPR route.

## Patterns + anti-patterns

**Pattern: Static shell + streamed dynamic.**

```tsx
import { Suspense } from 'react';

export default function Page() {
  return (
    <>
      <ProfileHeader />              {/* Static — prerendered */}
      <Suspense fallback={<TopProductsSkeleton />}>
        <TopProductsCached />        {/* Cached server component, streamed */}
      </Suspense>
      <Suspense fallback={<MetricsSkeleton />}>
        <LiveMetrics />              {/* Dynamic per request, streamed */}
      </Suspense>
    </>
  );
}
```

**Pattern: Parallel Suspense boundaries.** Each `<Suspense>` streams independently — don't nest a slow component inside a fast one if they don't share data.

**Pattern: Meaningful skeletons that match the eventual layout.** Same grid columns, same approximate height — avoids CLS when content arrives.

**Anti-pattern: SSR for everything just because it works.** Pages 95% identical for all users have no business being rendered per request. PPR + Cache Components for the 95%, stream the 5%.

**Anti-pattern: `'use client'` at the page root.** Zero static shell — defeats PPR.

**Anti-pattern: Reading `searchParams` at the page root** without isolating it into a Suspense child. Opts the entire page out of static rendering.

**Anti-pattern: Nested-only Suspense.**

```tsx
// ❌ Waterfall — Reviews don't start until Header finishes
<Suspense fallback={<HeaderSkeleton />}>
  <Header />
  <Suspense fallback={<ReviewsSkeleton />}>
    <Reviews />
  </Suspense>
</Suspense>
```

Flatten to parallel boundaries.

## Gotchas

- **PPR routes can't have route-level `dynamic = 'force-dynamic'` and a static shell** at the same time — those settings conflict. Pick one model per route.
- **The static shell can't read per-request data.** Push reads into Suspense children that handle dynamic.
- **Streaming order matters less than you'd think** — React dispatches as children resolve; users see content fill in as fast as the slowest of each branch.
- **Skeletons should match layout** — mismatched skeleton + content causes CLS.

## Cross-references

- [App Router](/stacks/vercel/app-router/) — where PPR routes live
- [Cache Components](/stacks/vercel/cache-components/) — composes with PPR Suspense holes
- [Server Components](/stacks/vercel/server-components/) — the cells in PPR's grid
- [Next.js](/stacks/vercel/nextjs/)
- [frontend-architect on Vercel](/stacks/vercel/frontend-architect/)
- Authoritative: [PPR docs](https://nextjs.org/docs/app/getting-started/partial-prerendering)
- Delegate: `vercel:nextjs`, `vercel:next-cache-components`
