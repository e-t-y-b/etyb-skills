---
title: Workers Static Assets
description: "The successor to Pages for static-asset hosting — `assets` binding in `wrangler.toml`, _headers, _redirects, _routes.json, run_worker_first."
product:
  name: Workers Static Assets
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, system-architect, frontend-architect]
  authoritative_url: https://developers.cloudflare.com/workers/static-assets/
  notes: "Replaces Pages for new projects; assets binding + _headers + _routes.json + run_worker_first semantics still evolving."
---

## What it is

Workers Static Assets is the canonical Cloudflare pattern for hosting static sites (Next.js, Astro, SvelteKit, plain HTML) alongside a Worker. Configured via `[assets]` block in `wrangler.toml`; serves files through `env.ASSETS.fetch(request)`; supports `_headers`, `_redirects`, `_routes.json`, and `run_worker_first` for routes that always hit the Worker.

Replaces [Pages](/stacks/cloudflare/pages/) for new projects.

Authoritative reference: [developers.cloudflare.com/workers/static-assets](https://developers.cloudflare.com/workers/static-assets/).

## When to use

- **New static-asset-heavy site** (Next.js, Astro, SvelteKit, plain HTML).
- **Hybrid** (some static, some served by a function) — `run_worker_first` for specific routes.
- **Existing Pages project migrating** to Workers for full bindings, RPC, observability.

Don't use Workers Static Assets when:

- **Large media library, user-uploaded files** — use [R2](/stacks/cloudflare/r2/) directly (signed URLs or fronted by a Worker for auth).
- **Pure-static site with no Worker logic at all** — Workers Static Assets is fine, but you can also just put files in R2 + cache headers + custom domain if zero compute is needed.

## 2025-2026 currency anchors

- **Workers Static Assets is the preferred path** for new builds as of 2024-25.
- **Pages → Workers Static Assets migration** is documented and recommended for non-trivial Pages projects.
- **Semantics around `run_worker_first`, `not_found_handling`, and `_routes.json`** still evolving — verify against current docs.

## Patterns

### `wrangler.toml` with static assets

```toml
name = "my-site"
main = "src/index.ts"
compatibility_date = "2026-05-01"
compatibility_flags = ["nodejs_compat_v2"]

[assets]
directory = "./public"
binding = "ASSETS"
not_found_handling = "single-page-application"   # for SPA
run_worker_first = ["/api/*"]                     # routes that always hit the Worker
```

### Worker handler with `env.ASSETS.fetch`

```ts
import { Hono } from "hono";

const app = new Hono<{ Bindings: Env }>();

app.get("/api/*", (c) => /* API logic */ c.json({ ok: true }));

// Fall through to static assets for anything else
app.all("*", (c) => c.env.ASSETS.fetch(c.req.raw));

export default app;
```

### Project bootstrap

```bash
npm create cloudflare@latest -- my-site --framework=next-on-pages
npm create cloudflare@latest -- my-site --framework=astro
npm create cloudflare@latest -- my-site --framework=sveltekit
```

Framework adapters auto-configure the `[assets]` block.

### `_headers`, `_redirects`

Standard headers/redirects files (Netlify-style format) in the `public/` directory:

```
# public/_headers
/*
  X-Frame-Options: DENY
  Strict-Transport-Security: max-age=31536000; includeSubDomains; preload

/api/*
  Access-Control-Allow-Origin: *
```

```
# public/_redirects
/old-path  /new-path  301
```

## Anti-patterns

- **Recommending Pages for a new project.** Pages is in maintenance.
- **Putting all logic in Pages Functions** instead of migrating — you cap your platform features.
- **`run_worker_first` for everything** — defeats the static-asset CDN advantage. Use for API routes specifically.

## Gotchas

1. **`not_found_handling`** matters — `"single-page-application"` for SPA (fall back to `index.html`), `"404-page"` for SSG sites with explicit 404 pages, `"none"` for plain static.
2. **`run_worker_first` precedence** — Worker handles those routes before checking assets. Order/syntax has evolved; verify.
3. **Cache headers via `_headers` apply to the asset response** before the Worker sees it.
4. **`_routes.json`** for advanced routing — verify schema against current docs.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime that fronts static assets
- [Pages](/stacks/cloudflare/pages/) — predecessor in maintenance mode
- [Wrangler](/stacks/cloudflare/wrangler/) — `wrangler deploy` deploys both Worker + assets
- [R2](/stacks/cloudflare/r2/) — for large user-uploaded assets that don't fit the static model
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/workers/static-assets](https://developers.cloudflare.com/workers/static-assets/)
