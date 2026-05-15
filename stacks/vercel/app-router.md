---
title: App Router
description: "The `app/` directory routing model. File-system routing, Server Components by default, layouts, parallel routes, intercepting routes — the 2026 baseline."
product:
  name: App Router
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect, system-architect]
  authoritative_url: https://nextjs.org/docs/app
  notes: "Cache Components + PPR + Server Actions all converge on the App Router. Pages Router is legacy maintenance; the App Router mental model is the 2026 default."
---

## What it is

The App Router is the file-system router under `app/` introduced in Next.js 13 and now the canonical routing model. Every directory under `app/` is a route segment; each segment can carry `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx`, `route.ts` (for HTTP handlers), `template.tsx`, `default.tsx`, plus the file conventions for metadata (`opengraph-image.tsx`, `robots.ts`, `sitemap.ts`, `icon.tsx`). See [nextjs.org/docs/app](https://nextjs.org/docs/app) for the reference.

App Router pages are Server Components by default. Client Components are opt-in via the `'use client'` directive. Layouts persist across navigations; templates remount.

## When to use

For new code in 2026, **always App Router**. Pages Router is for maintaining existing surfaces. The Cache Components, PPR, and Server Actions story all live in App Router — those features are not available in Pages Router.

Exceptions:
- An existing Pages Router codebase you haven't migrated yet — finish the migration before adopting Cache Components / PPR / Server Actions in earnest.
- Specific Pages-era libraries that haven't migrated (rare in 2026; check before assuming).

## 2025-2026 currency anchors

- **`params` and `searchParams` are Promises** in 15+. Await them. The old `{ params: { id } }` shape is wrong.
- **`searchParams` opts a Server Component into dynamic rendering.** Push the read into a Suspense boundary so the rest of the route can stay cached.
- **PPR is default rendering** for new App Router projects in Next.js 16. Static shell + streamed dynamic Suspense holes per route.
- **Cache Components (`'use cache'`)** is the default caching primitive — replaces ad-hoc `fetch(... { revalidate })`, `unstable_cache`, and `export const revalidate`.
- **`<Link legacyBehavior>`** is gone in 14+. Use the modern `<Link>` form.
- **Parallel routes (`app/@modal/...`)** and **intercepting routes (`app/(.)photo/[id]/page.tsx`)** are stable patterns for modals over a list.
- **Route groups (`app/(marketing)/about`)** don't affect URL; they scope layouts.

## Routing patterns

- **Static route:** `app/about/page.tsx` → `/about`
- **Dynamic segment:** `app/posts/[slug]/page.tsx`
- **Catch-all:** `app/docs/[...path]/page.tsx`
- **Optional catch-all:** `app/[[...slug]]/page.tsx`
- **Route group:** `app/(marketing)/about/page.tsx` → `/about` (group doesn't appear in URL)
- **Parallel route:** `app/@modal/(.)photo/[id]/page.tsx` — intercept a route for a modal overlay
- **Layouts:** `layout.tsx` persists; nested layouts compose
- **Templates:** `template.tsx` re-mounts on navigation (use sparingly — kills perf)
- **Loading UI:** `loading.tsx` becomes an automatic `<Suspense>` boundary
- **Error UI:** `error.tsx` is a Client Component segment-level error boundary
- **Not found:** `not-found.tsx`; triggered via `notFound()`
- **Middleware:** `middleware.ts` at project root; runs on every matched request *before* the cache layer

## Patterns + anti-patterns

**Pattern: Wrap dynamic-on-searchParams reads in Suspense.** Lets the rest of the route prerender.

**Pattern: Parallel Suspense boundaries.** Each `<Suspense>` streams independently — don't nest a slow component inside a fast one if they don't actually depend on each other.

**Pattern: Group dynamic segments under a route group for layout sharing.** `(dashboard)/orders/[id]` and `(dashboard)/settings` share `(dashboard)/layout.tsx` without `/dashboard` showing in the URL.

**Anti-pattern: Sequential nested Suspense.** Each level waits for the parent; flatten to parallel boundaries.

**Anti-pattern: Reading `searchParams` at the page root** without isolating it into a child component — opts the entire page out of static rendering.

**Anti-pattern: Middleware that hits a DB.** Middleware runs on every matched request, including cached ones. Keep it lean.

## Gotchas

- **`useRouter` import differs:** `next/router` (Pages) vs `next/navigation` (App).
- **`router.push` semantics differ slightly** between Pages and App Router; consult migration docs.
- **`error.tsx` must be a Client Component** (it uses class-component error-boundary semantics).
- **`global-error.tsx` replaces `_error.tsx`** for catastrophic crashes.
- **`generateStaticParams` replaces `getStaticPaths`.**
- **`_app.tsx` → `app/layout.tsx`**; `_document.tsx` → root layout's `<html>` + `<body>`.

## Cross-references

- [Next.js](/stacks/vercel/nextjs/) — framework overview
- [Server Components](/stacks/vercel/server-components/) — default component type in App Router
- [Server Actions](/stacks/vercel/server-actions/) — mutation primitive
- [Partial Prerendering](/stacks/vercel/partial-prerendering/) — the 2026 rendering model
- [Cache Components](/stacks/vercel/cache-components/) — the 2026 caching model
- [frontend-architect on Vercel](/stacks/vercel/frontend-architect/)
- Authoritative: [App Router docs](https://nextjs.org/docs/app)
- Delegate: `vercel:nextjs`, `vercel:routing-middleware`
