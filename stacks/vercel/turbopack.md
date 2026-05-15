---
title: Turbopack
description: Next.js's Rust-based bundler — stable for dev since 15+, rolling out as the production build path in 16.
product:
  name: Turbopack
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, devops-engineer]
  authoritative_url: https://nextjs.org/docs/app/api-reference/turbopack
  notes: "Stable for `next dev` in Next.js 15+. `next build --turbopack` is rolling out — verify stability for your version before flipping production builds."
---

## What it is

Turbopack is Next.js's Rust-based incremental bundler. It replaces Webpack for development (HMR) and is rolling out as the production build path. The dev-server experience is markedly faster than Webpack — sub-second HMR on large apps is typical. See [nextjs.org/docs/app/api-reference/turbopack](https://nextjs.org/docs/app/api-reference/turbopack).

## When to use

- **Dev:** always (default in Next.js 15+). `next dev` uses Turbopack out of the box.
- **Build:** opt-in via `next build --turbopack`. Verify stability for your specific Next.js version before flipping prod.

Webpack is still supported; for projects with custom Webpack config that Turbopack doesn't yet handle (rare in 2026), stick with Webpack for build.

## 2025-2026 currency anchors

- **Stable for `next dev`** since Next.js 15.
- **`next build --turbopack`** is rolling out — Next.js 16 makes it the recommended path with widening feature coverage.
- **Custom Webpack loader migration** is necessary for some uncommon configs; Turbopack supports its own loader API. Check your codemod path before migration.

## Patterns + anti-patterns

**Pattern: Default to Turbopack for dev; benchmark for build.** Stand up `next build --turbopack` in CI on a feature branch; compare bundle sizes + build times; flip when stable.

**Pattern: Use `@next/bundle-analyzer` to compare Webpack vs Turbopack output** during the build-side migration.

**Anti-pattern: Flipping prod build to Turbopack without comparison.** Bundle size + tree-shaking can differ subtly; measure before merging.

**Anti-pattern: Heavy custom Webpack config that hasn't been ported.** If your `next.config.ts` has dozens of Webpack overrides, plan the migration; don't expect feature parity day one.

## Gotchas

- **Some Webpack plugins don't have Turbopack equivalents yet.** Inventory before migration.
- **Source maps + sourcemap-based tools** (Sentry source-map upload, etc.) should be verified end-to-end after the build flip.
- **`next.config.ts` `turbopack` block** is the place for Turbopack-specific overrides (resolve aliases, loaders).

## Cross-references

- [Next.js](/stacks/vercel/nextjs/)
- [Build Cache](/stacks/vercel/build-cache/) — Turborepo Remote Cache layers on top
- [Vercel CLI](/stacks/vercel/vercel-cli/) — `vercel dev` uses Turbopack
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — build optimization
- Authoritative: [Turbopack docs](https://nextjs.org/docs/app/api-reference/turbopack)
- Delegate: `vercel:turbopack`
