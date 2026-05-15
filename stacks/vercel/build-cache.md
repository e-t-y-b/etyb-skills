---
title: Build Cache
description: Turborepo Remote Cache plus Vercel's build artifact caching. The lever that turns a 5-minute monorepo build into a 30-second one for unchanged packages.
product:
  name: Build Cache
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, frontend-architect]
  authoritative_url: https://vercel.com/docs/monorepos/turborepo
  notes: "Turborepo Remote Cache patterns mature; free with Vercel. The big win on monorepos. Vercel's per-project build cache layers underneath."
---

## What it is

Build cache on Vercel has two layers:

- **Vercel's per-project build cache** — automatic; speeds up unchanged-deps builds.
- **Turborepo Remote Cache** — shares build artifacts across team members + CI. Free with Vercel.

See [vercel.com/docs/monorepos/turborepo](https://vercel.com/docs/monorepos/turborepo) and the [Turborepo docs](https://turborepo.com/docs).

## When to use

- **Any monorepo** — Turborepo + Remote Cache is the 2026 default.
- **Single-app projects** — Vercel's auto-cache helps; Turborepo less critical.
- **CI pipelines doing repeated work** — Remote Cache eliminates redundant compilation.

## 2025-2026 currency anchors

- **Turborepo Remote Cache is free on Vercel** — `turbo link` connects your repo.
- **Pipeline + caching defined in `turbo.json`** — schema is stable.
- **`turbo-ignore`** in Vercel's "Ignored Build Step" only deploys an app when it (or its deps) actually changed.

## The `turbo.json` shape

```jsonc
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**"]
    },
    "lint": {},
    "test": { "dependsOn": ["^build"], "outputs": ["coverage/**"] },
    "dev": { "cache": false, "persistent": true }
  }
}
```

## Patterns + anti-patterns

**Pattern: `turbo link` + Remote Cache for monorepos.**

```bash
turbo link               # Link to Vercel for Remote Cache
turbo run build          # Local build hits cache from CI
```

A CI build that took 5 minutes can drop to 30 seconds for an unchanged package.

**Pattern: Per-app Vercel project in a monorepo.**

- Root Directory: `apps/web` (or whichever).
- Build Command: `cd ../.. && turbo run build --filter=web`.
- Install Command: `pnpm install --frozen-lockfile`.
- Output Directory: `apps/web/.next`.
- Ignored Build Step: `npx turbo-ignore` — only deploys if the app or its deps changed.

**Pattern: Outputs configured tightly.** `outputs: [".next/**", "!.next/cache/**"]` excludes Next.js's internal cache from Turborepo's cache key (it's not deterministic).

**Anti-pattern: One Vercel project for many apps in a monorepo.** Builds, env vars, and rollbacks become miserable. One project per app.

**Anti-pattern: `cache: true` on `dev` tasks.** Dev shouldn't be cached.

**Anti-pattern: Untracked env vars in `globalDependencies`.** If a task's output depends on an env var, declare it; otherwise cache lies.

## Gotchas

- **Remote Cache misses on input hash mismatch** — environment differences (Node version, OS) can invalidate. Verify CI matches local.
- **Outputs must be deterministic.** Random timestamps, non-deterministic hashes in outputs cause cache misses.
- **`turbo-ignore`** uses git to detect changes — needs the full git history (configure `GIT_FETCH_DEPTH` in CI).
- **Cache hit rate is measurable** in `turbo run` output — track it.

## Cross-references

- [Turbopack](/stacks/vercel/turbopack/) — separate bundler; complements Turborepo
- [Vercel CLI](/stacks/vercel/vercel-cli/) — `vercel link` for the Vercel side
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — monorepo + build optimization
- Authoritative: [Turborepo docs](https://turborepo.com/docs), [Vercel monorepo docs](https://vercel.com/docs/monorepos/turborepo)
- Delegate: `vercel:deployments-cicd`
