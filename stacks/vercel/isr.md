---
title: ISR (Incremental Static Regeneration)
description: Legacy revalidation model — pages prerendered then refreshed on a TTL or on-demand. Superseded by Cache Components for most 2026 cases.
product:
  name: ISR
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect]
  authoritative_url: https://nextjs.org/docs/app/building-your-application/data-fetching/fetching-caching-and-revalidating
  notes: "Still works in Next.js 15/16; for new code Cache Components is the recommended replacement. The `export const revalidate = N` pattern is legacy but supported."
---

## What it is

Incremental Static Regeneration is the pattern of statically generating a page at build time then refreshing it on a TTL or on-demand. In Pages Router it was `getStaticProps` with `revalidate`; in App Router (pre-Cache Components) it was `export const revalidate = N` at the route level, `fetch(url, { next: { revalidate, tags } })`, or `unstable_cache()` wrapping a non-fetch function.

See [the data-fetching reference](https://nextjs.org/docs/app/building-your-application/data-fetching/fetching-caching-and-revalidating) for the legacy patterns. **For new code in Next.js 16, prefer [Cache Components](/stacks/vercel/cache-components/).**

## When to use

- **Existing codebases on Next.js 15 or earlier** — ISR patterns are stable and don't need an urgent migration.
- **Simple cases** where `fetch(url, { next: { revalidate: 3600, tags: ['x'] } })` reads more cleanly than wiring `'use cache'`.
- **Route-level TTL** via `export const revalidate = N` for whole-page cache.

For Next.js 16 new development, use Cache Components instead. The mental model is more flexible (file/function/component scope, named tags, profile-based TTL) and the ergonomics are better.

## 2025-2026 currency anchors

- **`export const revalidate = N`** still works in Next.js 16 but is legacy for new code.
- **`fetch(url, { next: { revalidate, tags } })`** still works and is the lightest way to cache an external API fetch.
- **`unstable_cache()`** is superseded by Cache Components' `'use cache'` for new code; existing usage is fine.
- **`revalidatePath(path)`** and **`revalidateTag(tag)`** still work and are the right way to invalidate from Server Actions / webhook handlers.
- **`getStaticProps` + `revalidate`** is Pages-Router-only; that whole API is legacy.

## Patterns + anti-patterns

**Pattern: `fetch` with `next.revalidate` for external API caching.**

```ts
const res = await fetch('https://api.example.com/products', {
  next: { revalidate: 3600, tags: ['products'] },
});
```

**Pattern: `revalidateTag` from Server Action or webhook handler.**

```ts
'use server';
import { revalidateTag } from 'next/cache';

export async function refreshProducts() {
  // ... do work ...
  revalidateTag('products');
}
```

**Anti-pattern: New code with `unstable_cache`.** Use Cache Components instead; the API is clearer and the future is `'use cache'`.

**Anti-pattern: Long TTL with no invalidation tag.** Set a tag — `tags: ['x']` — and call `revalidateTag('x')` from your mutation paths.

## Gotchas

- **`export const revalidate` is route-level.** Once set, the whole page revalidates on the TTL. For finer control, use Cache Components.
- **`revalidatePath` vs `revalidateTag`.** Path invalidates everything cached for that route; Tag invalidates everything sharing the tag (across routes). Tag is the more surgical primitive.
- **ISR + Server Actions** — the action must call `revalidatePath` or `revalidateTag` for the reader to see fresh data on the next request. The framework doesn't auto-invalidate.

## Cross-references

- [Cache Components](/stacks/vercel/cache-components/) — the 2026 successor
- [Partial Prerendering](/stacks/vercel/partial-prerendering/) — the 2026 rendering model that composes with Cache Components
- [Server Actions](/stacks/vercel/server-actions/) — where `revalidateTag` typically fires
- [App Router](/stacks/vercel/app-router/)
- Authoritative: [data fetching docs](https://nextjs.org/docs/app/building-your-application/data-fetching/fetching-caching-and-revalidating)
- Delegate: `vercel:nextjs`, `vercel:next-cache-components`
