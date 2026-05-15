---
title: Next.js
description: The framework. App Router is the path forward; Pages Router is legacy maintenance. Next.js 16 is current; 15.x is the LTS line.
product:
  name: Next.js
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect, system-architect, devops-engineer]
  authoritative_url: https://nextjs.org/docs
  notes: "Next.js 15 → 16 cadence in 2025-2026 reshaped defaults: PPR GA, Cache Components default, Server Actions stabilized, Turbopack build rolling out. Older training data has the wrong mental model."
---

## What it is

Next.js is the React framework Vercel builds; on Vercel, it's the canonical app shape. As of `last_verified_on`, **Next.js 16** is the current major (with 15.x as the LTS line still widely deployed in production). The framework spans the file-system router (`app/`), Server Components, Client Components, Server Actions, Route Handlers, the build pipeline (Webpack/Turbopack), and the runtime contract with Vercel Functions + Vercel Edge Network. See [nextjs.org/docs](https://nextjs.org/docs) for the canonical reference and [github.com/vercel/next.js/releases](https://github.com/vercel/next.js/releases) for precise version-feature mapping.

## When to use

Next.js on Vercel is the default for any new React app where:

- The team wants server rendering (RSC + SSR) without standing up a separate Node server.
- Streaming, edge caching, and image/font optimization are valuable out of the box.
- The deploy story is "git push to Preview, merge to prod" with Vercel's tooling.

Pick something else when:

- You need a pure SPA with no server (Vite + React Router is lighter; you lose SSR).
- You need a non-React framework (Remix, SvelteKit, SolidStart — each has its own story; Remix collapsed into React Router in 2025).
- You're already invested in a non-Vercel runtime (Cloudflare Workers, Deno Deploy) — Next.js can run there via `@cloudflare/next-on-pages` etc., but the canonical home is Vercel.

Inside Next.js, the live decision is App Router vs Pages Router. See the [App Router](/stacks/vercel/app-router/) product page — for new code in 2026, App Router is the only correct choice; Pages Router is for maintaining existing surfaces until they migrate.

## 2025-2026 currency anchors

- **Next.js 16 shipped late 2025** with Cache Components as the recommended caching model, PPR as the default rendering model for new App Router projects, and Turbopack as the production build path (rolling out — verify stability for your version).
- **React 19+ is the baseline**; React 20 is in canary at `last_verified_on`. Server Components, the `use()` hook, Actions, `useActionState`, `useOptimistic`, `useFormStatus`, `ref` as a prop, and Document Metadata in components are all part of the standard surface now.
- **React Compiler (Forget)** is stable opt-in and on by default in Next.js with `experimental.reactCompiler`. It auto-memoizes and drops most manual `useMemo`/`useCallback`.
- **`params` and `searchParams` are Promises** in Next.js 15+. Old `{ params: { id } }` shape is wrong for new code.
- **`after()`** is GA (formerly `unstable_after`) — schedule work after the response without blocking.
- **`taintObjectReference` / `taintUniqueValue`** are the canonical guard against accidentally serializing server-only objects/secrets into a Client Component.
- **Dynamic IO / `connection()`** lets you mark Server Components that must be dynamic without disabling caching globally.
- **`unstable_cache`** is superseded by Cache Components for new code.
- **`getServerSideProps` / `getStaticProps`** are Pages-Router-only and Pages Router is legacy.

## Patterns + anti-patterns

**Pattern: Server Component by default, Client Component on demand.** Every component in `app/` is a Server Component unless marked `'use client'`. The cost of `'use client'` (bundle, hydration, re-execution) is real; pay it only for interactivity, browser APIs, hooks, and event handlers.

**Pattern: Pass server tree as children to a client wrapper.** A `'use client'` shell can render a Server Component as `{children}` without the inner tree shipping to the client bundle. This is how you keep a sidebar/dialog/theme provider client-side without ballooning the bundle.

**Pattern: Server Actions for mutations; Server Components for reads.** Forget Pages-style API routes for app-internal mutations. Form `action={fn}` + `useActionState` is the 2026 baseline.

**Anti-pattern: `'use client'` at the page root.** Zero static shell, zero streaming benefit, full client bundle. Isolate interactivity into Client Component children; keep the page itself a Server Component.

**Anti-pattern: Fetching in `useEffect`.** Almost always wrong in 2026 — fetch on the server, pass as props, or use TanStack Query against a Route Handler when polling/infinite scroll is the real need.

**Anti-pattern: Pages Router for new code.** Every new feature goes App Router. Mixed-router codebases are a tax on every engineer's mental model.

## Gotchas

- **The Pages Router and the App Router are different products in the same repo.** Mixing is supported but every "mix" page is a fork in your team's mental model. If a codebase still has `pages/`, finish the migration before adopting Cache Components, PPR, Server Actions in earnest — those features are App Router-only.
- **`params` is a Promise.** Server Components, generateMetadata, route handlers — all see `params: Promise<...>`. Await it.
- **Hydration mismatches** come from `Date.now()`, `Math.random()`, or locale-dependent rendering between server and client. Log on both sides to triangulate.
- **`'use cache'` cached components must be deterministic in their args.** If a function uses `headers()`, `cookies()`, `searchParams`, or any per-request thing, it can't be cached at that scope.
- **`useEffect` to call a Server Action** is almost always a sign you wanted a Route Handler with TanStack Query, or you wanted to fetch on the server.
- **Server Components leaking server-only data.** Returning a raw DB row to a Client Component via props can serialize secrets/PII to the browser. Use `taintObjectReference()` and `import 'server-only'`.

## Cross-references

- [App Router](/stacks/vercel/app-router/) — the routing + RSC layer
- [Server Components](/stacks/vercel/server-components/) — RSC patterns
- [Server Actions](/stacks/vercel/server-actions/) — mutation primitive
- [Cache Components](/stacks/vercel/cache-components/) — the 2026 caching model
- [Partial Prerendering (PPR)](/stacks/vercel/partial-prerendering/) — the 2026 rendering model
- [Turbopack](/stacks/vercel/turbopack/) — build/dev bundler
- [frontend-architect on Vercel](/stacks/vercel/frontend-architect/) — composed role view
- Authoritative: [Next.js docs](https://nextjs.org/docs), [Next.js releases](https://github.com/vercel/next.js/releases)
- Delegate: `vercel:nextjs`, `vercel:next-upgrade`, `vercel:react-best-practices`
