---
title: Cache Components
description: "The `'use cache'` directive — file/function/component-scoped caching with `cacheLife()` + `cacheTag()`. The 2026 default caching model in Next.js 16."
product:
  name: Cache Components
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect]
  authoritative_url: https://nextjs.org/docs/app/api-reference/directives/use-cache
  notes: "New default caching model in Next.js 16; replaces ad-hoc fetch caching + ISR + unstable_cache for most use cases. Mental models from pre-16 are wrong."
---

## What it is

`'use cache'` is to Server Components what `'use server'` is to Server Actions: a directive that changes how the function executes. It marks a server function or component as cached; results are stored, keyed by input args, and reused until invalidated.

Paired with `cacheLife()` (TTL profile) and `cacheTag()` (invalidation tag), it's the recommended caching model in Next.js 16. See [nextjs.org/docs/app/api-reference/directives/use-cache](https://nextjs.org/docs/app/api-reference/directives/use-cache).

## When to use

- **Read-heavy server data** with predictable TTL or tag-based invalidation: feature flags, navigation, product catalogs, blog post lists, anything fetched on many requests.
- **Replacing `unstable_cache`** for new code.
- **Replacing `fetch(... { next: { revalidate } })`** when you need named tag invalidation rather than just a TTL.

Don't `'use cache'`:

- **Page-level Server Components that depend on per-user data** — that's a slow leak waiting to happen. Cache the underlying shared queries (feature flags, top-level navigation), not the page.
- **Functions that read per-request state** (`headers()`, `cookies()`, `searchParams`) — they can't be cached at that scope. Push the dynamic dependency up, or use `connection()` to mark a boundary.
- **AI responses or anything personalized.** Cache at the prompt level (AI Gateway prompt cache, Anthropic prompt caching) instead.

## 2025-2026 currency anchors

- **GA in Next.js 16** as the default caching primitive.
- **Replaces `unstable_cache`** for new code; existing `unstable_cache` still works in 15.x and as a fallback.
- **Composes with PPR Suspense holes** — a cached component inside a dynamic Suspense boundary streams its cached result.
- **`cacheLife`** takes a profile string (`'seconds'`, `'minutes'`, `'hours'`, `'days'`, `'weeks'`, `'max'`) or an explicit `{ stale, revalidate, expire }` object. Tune profiles in `next.config.ts` for custom buckets.
- **`cacheTag`** is freeform — use `kind:id` or `kind:slug` so revalidation is targeted.

## Mental model

```tsx
// app/dashboard/top-products-cached.tsx
'use cache';
import { cacheLife, cacheTag } from 'next/cache';

export async function TopProductsCached() {
  cacheLife('hours');             // TTL bucket: revalidate every hour-ish
  cacheTag('top-products');       // Invalidatable tag
  const products = await db.query.topProducts();
  return <ProductList items={products} />;
}
```

Then in a Server Action elsewhere:

```ts
// app/admin/actions.ts
'use server';
import { revalidateTag } from 'next/cache';

export async function refreshTopProducts() {
  // ... do work ...
  revalidateTag('top-products');
}
```

## Patterns + anti-patterns

**Pattern: Cache the shared subqueries, not the per-user page.** Server Component pages stay dynamic; their cached child components carry the cache.

**Pattern: Tag with `kind:id`.** `cacheTag('product:${id}')`, `cacheTag('comments:${postId}')`. Avoid global tags like `'all'`.

**Pattern: Mutation → `revalidateTag` → next request sees fresh data.** The loop is closed without any client-side cache management.

**Pattern: `'use cache'` at function scope** for one cached function inside a module. **File scope** for an entire module of cached exports. **Component scope** for the cheapest granularity. Pick the smallest scope that works.

**Anti-pattern: Caching everything.** "I'll just put `'use cache'` on everything to make it fast" — then you can't invalidate (forgot `cacheTag`), the cache fills with stale data, you have no idea what's coming from where.

**Anti-pattern: Missing `cacheTag()`.** TTL is the platform default if you don't set one; without a tag, you can't invalidate on demand.

**Anti-pattern: `'use cache'` on a page that depends on `cookies()` or `auth()`.** Will break at runtime or — worse — silently leak one user's data to another.

## Gotchas

- **Cached components MUST be deterministic in their args.** If a function uses `headers()`, `cookies()`, `searchParams`, or any per-request thing, it can't be cached at that scope.
- **`'use cache'` at file scope caches the whole module's exports.** At function scope caches that function. At component scope caches the component's render. Pick deliberately.
- **`cacheLife('seconds')` is not "1 second"** — profiles are buckets (stale + revalidate + expire). Tune profiles in `next.config.ts` if you need precise control.
- **Cache Components storage + reads have their own line item** in Vercel pricing — high-volume cached routes show up there.
- **Migrating from `unstable_cache`** is mechanical — wrap with `'use cache'` instead, move `revalidate` to `cacheLife`, move `tags` to `cacheTag`.

## When to use Cache Components vs alternatives

| Need | Pick |
|------|------|
| Cache a server function's return for an hour, tag-invalidate | `'use cache'` + `cacheLife` + `cacheTag` |
| Cache a `fetch()` result inline | `fetch(url, { next: { revalidate: 3600, tags: ['x'] } })` — still supported; lighter |
| Cache something not from `fetch()` (DB call, computation) | `'use cache'` (was `unstable_cache` pre-16) |
| Route-level revalidation on a timer | `export const revalidate = 3600` (legacy; still works) |
| Force a route to be dynamic | `export const dynamic = 'force-dynamic'` or `connection()` inside the page |

## Cross-references

- [ISR](/stacks/vercel/isr/) — the legacy revalidation model Cache Components supersedes
- [Partial Prerendering](/stacks/vercel/partial-prerendering/) — PPR Suspense holes can wrap cached components
- [Server Actions](/stacks/vercel/server-actions/) — where `revalidateTag` typically fires
- [Server Components](/stacks/vercel/server-components/)
- [Vercel Cache](/stacks/vercel/vercel-cache/) — storage tier
- Authoritative: [`'use cache'` reference](https://nextjs.org/docs/app/api-reference/directives/use-cache), [cacheLife](https://nextjs.org/docs/app/api-reference/functions/cacheLife), [cacheTag](https://nextjs.org/docs/app/api-reference/functions/cacheTag)
- Delegate: `vercel:next-cache-components`, `vercel:nextjs`
