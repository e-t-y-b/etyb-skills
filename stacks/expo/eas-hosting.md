---
title: EAS Hosting
description: "Cloudflare-Workers-backed serverless host for Expo Router web + API routes. GA 2025. `eas deploy`, branch previews, custom domains, auto-TLS."
product:
  name: EAS Hosting
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, frontend-architect]
  authoritative_url: https://docs.expo.dev/eas/hosting/introduction/
  notes: "GA 2025 — Cloudflare-Workers-backed serverless host for Expo Router web + API routes; routing/limits still maturing"
---

## What it is

**EAS Hosting** is Expo's web host — Cloudflare Workers underneath, with Expo Router's web output (`expo export --platform web`) deployed as static assets + Workers for API routes (`+api.ts`). Custom domains with auto-TLS, branch previews, environment variable management, Worker logs.

```bash
npx expo export --platform web    # produces dist/
eas deploy --prod                 # uploads + makes live
```

Canonical surface: [EAS Hosting Introduction](https://docs.expo.dev/eas/hosting/introduction/).

## When to use

Default host for the web target of an Expo Router app. Especially well-suited when:

- The web target is the marketing site, blog, or admin surface that complements the mobile app
- API routes (`+api.ts`) are the BFF for the mobile app
- You want zero-config Workers + edge CDN
- Custom domain + auto-TLS via Cloudflare is desired

Pick **Vercel** instead when:

- The web target is a heavyweight Next.js app that doesn't share the mobile codebase
- You need specific Vercel features (Vercel Functions, Vercel KV, Vercel-specific integrations)
- The team already runs Vercel for other properties and wants one bill

**Don't fan out to both** unless you have a specific architectural reason. Pick one for a given app.

## 2025-2026 currency anchors

- **GA 2025** — production-ready; replaces "Expo for Web" + Vercel for the canonical Expo Router web target.
- **Cloudflare Workers runtime** for API Routes — no `node:fs`, no full Node. See [Expo API Routes](/stacks/expo/expo-api-routes/) for the runtime constraint detail.
- **Branch previews automatically** — `eas deploy` without `--prod` produces a preview URL like `https://expo-app--feature-checkout-redesign.expo.app`.
- **Custom domains** in EAS dashboard; auto-TLS via Cloudflare.
- **Environment variables** managed per-environment (production / preview) in EAS dashboard or via `eas env:create --scope project`.
- **CPU time limits**: 50ms free tier, 30s on paid tiers. No long-polling; use Durable Objects via Workers for WebSockets.
- **Bindings**: KV / D1 / R2 access via Workers-style imports (`cloudflare:kv`, etc.), configured in EAS Hosting dashboard.

## Patterns + anti-patterns

### Pattern: Static + dynamic combo

```json
// app.json
"expo": {
  "web": { "output": "static" }
}
```

- `output: "static"` for marketing/SEO surfaces — pre-renders HTML at build time, hydrates on client.
- `output: "server"` for auth-aware dynamic pages — renders on Workers per request (SDK 55 alpha).
- `output: "single"` for SPA app-shell — no SEO need.

Most apps split: marketing static + app shell as `single`. SSR is alpha; use when you genuinely need per-request server rendering.

### Pattern: Preview deploys per branch

```bash
eas deploy --message "Preview for feature/checkout-redesign"
# Returns: https://expo-app--feature-checkout-redesign.expo.app
```

Share with stakeholders for review; auto-cleaned after some retention period.

### Pattern: Custom domain + auto-TLS

In EAS Hosting dashboard:

1. Add domain (`app.example.com`).
2. Add the suggested CNAME/`ALIAS` record at your DNS provider.
3. Wait for verification + TLS provisioning (~minutes).

No manual cert issuance; Cloudflare handles renewal.

### Pattern: API Routes consuming server-only env vars

```ts
// app/api/users+api.ts
export async function POST(request: Request) {
  const body = await request.json();
  const result = await callExternalAPI(process.env.SERVER_API_KEY, body);
  return Response.json(result);
}
```

`SERVER_API_KEY` lives in EAS Hosting env vars; never in `EXPO_PUBLIC_*`. Workers see env vars at runtime; the bundle never inlines them.

### Anti-pattern: Importing Node libs in API routes

```ts
// app/api/users+api.ts
import fs from 'node:fs';   // 👈 BAD — Workers runtime has no fs
```

Workers ≠ Node. Use Workers-compatible libraries:

- DB: `@neondatabase/serverless`, `drizzle-orm`, `@prisma/client` (edge mode), `cloudflare:d1`
- Crypto: Web Crypto API (built in)
- HTTP: `fetch` (built in)
- Cache: `cloudflare:kv` or Workers Cache API

See the [Cloudflare Stack](../cloudflare/) overlay for the Workers runtime in depth.

### Anti-pattern: Long-running tasks in API routes

```ts
// BAD — 60s job in a Worker
export async function POST(request: Request) {
  const data = await heavyComputation(); // 60s
  return Response.json(data);
}
```

Workers have CPU time limits (50ms free, 30s paid). Long-running jobs belong in a queue + worker (e.g., Cloudflare Queues, AWS SQS), not in a request handler.

## Gotchas

- **No `vercel.json`** — EAS Hosting config is in `app.json` under `expo.web` or in the EAS Hosting dashboard. Vercel-shape configs don't apply.
- **Logs are in the EAS dashboard** — `eas hosting:logs` for live tail. Worker logs are short-lived (no permanent retention by default).
- **Cold start latency** for Workers is generally <10ms but can spike for first-byte on cold regions.
- **Cache-Control** headers from API routes are honored; static assets are cached at the edge by default.
- **Database connections** — TCP-pool-based libs (`pg`, `mysql2`) don't work; use serverless variants. `@neondatabase/serverless` (Postgres over HTTP+WebSockets) is the standard.
- **WebSockets** — Workers support them via Durable Objects; non-trivial to set up. For real-time pub/sub, consider Cloudflare's `cloudflare:durable-objects` or a managed service (Ably, Pusher).

## Cross-references

- [Expo API Routes](/stacks/expo/expo-api-routes/) — `+api.ts` files running on EAS Hosting
- [Expo Router](/stacks/expo/expo-router/) — what produces the web output
- [EAS CLI](/stacks/expo/eas-cli/) — `eas deploy`, `eas hosting:logs`
- [Cloudflare Stack](../cloudflare/) — Workers runtime in depth
- `expo-api-routes` skill (delegate) — Expo Router API routes
- `expo-deployment` skill (delegate) — web hosting flows
- Role overlays: [devops-engineer](/stacks/expo/devops-engineer/), [frontend-architect](/stacks/expo/frontend-architect/)
- [EAS Hosting Introduction](https://docs.expo.dev/eas/hosting/introduction/)
