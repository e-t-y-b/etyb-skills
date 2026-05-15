---
title: Static Web Apps
description: SWA — tight Azure integration for SPA + Functions backend. Investment is slowing in 2025; evaluate Vercel/Cloudflare for cutting-edge frontend.
product:
  name: Azure Static Web Apps
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, backend-architect]
  authoritative_url: https://learn.microsoft.com/azure/static-web-apps/
  notes: "Slowing investment; for cutting-edge frontend, Vercel/Cloudflare Pages are competitive; SWA is fine for Azure-integrated SPAs."
---

## What it is

Azure Static Web Apps hosts a static frontend (React, Vue, Svelte, Angular, etc.) with an optional Functions-style backend in the `api/` folder. GitHub Actions deploys automatically. Canonical reference: [SWA docs](https://learn.microsoft.com/azure/static-web-apps/).

## When to use

Pick SWA when:

- **Azure-integrated SPA** — your auth is Entra ID / External ID, your DB is Cosmos / SQL, and you want the simplest deploy path.
- **Tiny backend** — < 10 Functions endpoints, basic CRUD with the SWA-managed `api/` folder.
- **Static + auth + simple API** is genuinely the whole app.

Don't pick SWA for:

- **Cutting-edge frontend** (RSC + edge SSR + advanced routing) — Vercel and Cloudflare Pages are ahead. Microsoft is slowing investment.
- **Complex backend** — use [Container Apps](/stacks/azure/container-apps/) or [App Service](/stacks/azure/app-service/).
- **Self-hosted ISR / on-demand revalidation** at scale — SWA's caching model is basic.

## 2025-2026 currency anchors

- **Investment is slowing** as of 2025. Microsoft confirmed the service is maintained but not where they're prioritizing new features.
- **Auth providers** — built-in Entra ID, GitHub, custom OIDC. `x-ms-client-principal` header injected into backend functions.
- **`staticwebapp.config.json`** controls routing, auth, headers, MIME types.
- **GitHub Actions deploy workflow** auto-generated on connect.

## Patterns + anti-patterns

### Pattern: SWA + Entra External ID for customer auth

Configure External ID as a custom OIDC provider; SWA handles redirect / token exchange; backend reads `x-ms-client-principal` header.

### Pattern: SWA backend as glue, not the API

Use the SWA-managed Functions API for simple CRUD against a managed data tier. For real business logic, host a separate Functions or Container Apps service and call from the frontend.

### Anti-pattern: SWA for "next-gen" frontend features

If you need RSC, edge SSR, advanced caching, image optimization, or app-level streaming — Vercel and Cloudflare are ahead. Evaluate honestly.

### Anti-pattern: Complex backend in `api/` folder

The SWA-managed backend is intentionally limited. For real APIs, host them separately and call cross-origin.

## Gotchas

- **Two pricing tiers** (Free / Standard). Standard adds custom domains, larger backend, more bandwidth.
- **Backend Functions are managed** — you don't control the Functions runtime version directly.
- **Auth `userRoles` semantics** are SWA-specific — different from Entra ID's group claims.

## Cross-references

- [App Service](/stacks/azure/app-service/) — for traditional web apps with backend logic
- [Container Apps](/stacks/azure/container-apps/) — for containerized backend
- [Entra External ID](/stacks/azure/entra-external-id/) — customer auth
- [Static Web Apps docs](https://learn.microsoft.com/azure/static-web-apps/)
