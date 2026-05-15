---
title: Pages
description: Cloudflare Pages — git-integrated static site / SSR hosting. In maintenance mode; new builds should use Workers Static Assets instead.
product:
  name: Pages
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect, backend-architect, frontend-architect]
  authoritative_url: https://developers.cloudflare.com/pages/
  notes: "Pages is in maintenance — new builds should use Workers Static Assets; migration guide published 2024."
---

## What it is

Cloudflare Pages is the git-integrated static site and SSR hosting product — connect a repo, framework auto-detect, deploy on push, per-PR previews. As of 2024, Pages is in **maintenance mode** — new platform features land in [Workers Static Assets](/stacks/cloudflare/workers-static-assets/) first. Existing Pages projects keep working.

Authoritative reference: [developers.cloudflare.com/pages](https://developers.cloudflare.com/pages/).

## When to use

- **Existing Pages project, working fine.** Leave on Pages; migrate when adding non-trivial logic.
- **You explicitly need a Pages feature** (specific integration, deployment workflow) not yet in Workers Static Assets.

Don't use Pages when:

- **New project, net-new build.** Use [Workers Static Assets](/stacks/cloudflare/workers-static-assets/).
- **You're adding Workers-level features** (RPC, full bindings) to a Pages project — migrate.

## 2025-2026 currency anchors

- **Pages is in maintenance mode** as of 2024-2025. The migration guide is published and supported.
- **Pages → Workers migration** is recommended for any non-trivial Pages project that's adding new functionality.
- **Pages Git integration is legacy** — for net-new managed CI, use Cloudflare Workers Builds or GitHub Actions.

## Pages → Workers Static Assets migration

For an existing Pages project:

1. Add `[assets]` block to `wrangler.toml`:
   ```toml
   [assets]
   directory = "./dist"
   binding = "ASSETS"
   not_found_handling = "single-page-application"  # or "404-page" for SSG
   ```
2. Add a top-level `src/index.ts` Worker that serves through `env.ASSETS.fetch(request)`.
3. Move Pages Functions (`functions/api/*.ts`) into the Worker as route handlers in Hono.
4. Test `wrangler dev` locally; deploy to a staging Worker.
5. Cut over DNS / route from Pages project to the new Worker.
6. Decommission Pages project.

The migration guide on Cloudflare docs has version-specific details — consult before starting: [Pages → Workers migration](https://developers.cloudflare.com/workers/static-assets/migration-guides/migrate-from-pages/).

## Anti-patterns

- **"Use Pages for a new project."** No — use Workers Static Assets.
- **Adding Pages Functions to grow a Pages project** — migrate to Workers Static Assets where you get full bindings + RPC + everything else Workers offers.

## Gotchas

1. **Pages Functions are the legacy serverless surface** on Pages; the canonical pattern in 2026 is the Workers + Workers Static Assets model.
2. **Maintenance mode doesn't mean broken** — Pages projects keep working. But missing-feature questions ("does Pages support X?") increasingly answer "no — use Workers Static Assets."
3. **Pages legacy Git integration** is separate from Cloudflare Workers Builds (the managed CI for Workers/Pages).

## Cross-references

- [Workers Static Assets](/stacks/cloudflare/workers-static-assets/) — successor; preferred for new projects
- [Workers](/stacks/cloudflare/workers/) — runtime for the Worker that fronts Static Assets
- [Wrangler](/stacks/cloudflare/wrangler/) — CLI for Pages and Workers Static Assets deploys
- Role overlay: [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/pages](https://developers.cloudflare.com/pages/), [Pages → Workers migration](https://developers.cloudflare.com/workers/static-assets/migration-guides/migrate-from-pages/)
