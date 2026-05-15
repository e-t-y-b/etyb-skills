---
title: Expo API Routes
description: "`+api.ts` files in `app/` that deploy as Cloudflare Workers via EAS Hosting. The BFF for Expo Router apps. Workers runtime, not Node."
product:
  name: Expo API Routes
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect, devops-engineer]
  authoritative_url: https://docs.expo.dev/router/reference/api-routes/
  notes: "`+api.ts` files run on EAS Hosting Workers (Cloudflare runtime) — diff from Vercel/Node; no `node:fs`, no full Node API"
---

## What it is

**Expo API Routes** are server-side endpoints colocated with your Expo Router app. Any file matching `app/**/*+api.ts` becomes a route handler. The runtime when deployed via **EAS Hosting** is **Cloudflare Workers** — not Node.

```ts
// app/api/users+api.ts
export async function GET(request: Request) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit') ?? '20');
  const users = await db.users.findMany({ limit });
  return Response.json({ users });
}

export async function POST(request: Request) {
  const body = await request.json();
  // validate, persist, etc.
  return Response.json({ ok: true }, { status: 201 });
}
```

Canonical surface: [API Routes reference](https://docs.expo.dev/router/reference/api-routes/).

## When to use

For the **backend-for-frontend (BFF)** layer of an Expo app:

- Server-only logic (auth code exchange, secret handling)
- Aggregating data from multiple APIs into a single mobile-shaped response
- Webhooks (Stripe, Twilio, Slack)
- Lightweight CRUD against a serverless DB (Neon, D1, PlanetScale Serverless)
- Image/file upload endpoints

**Don't use** for:

- Heavy compute (>30s) — Workers have CPU time limits; use a queue + worker
- Long-polling — use WebSockets via Durable Objects or a managed service
- Anything requiring `node:fs`, raw TCP sockets, or the full Node API

## 2025-2026 currency anchors

- **Runtime is Cloudflare Workers** when deployed via [EAS Hosting](/stacks/expo/eas-hosting/) — no `node:fs`, no `node:net`, no full Node API surface.
- **CPU time limits** — 50ms free tier, 30s on paid tiers.
- **Bindings** instead of env vars for KV/D1/R2 — configure via `wrangler.toml` or EAS Hosting dashboard.
- **Web Crypto API** built in; `crypto-js` and Node-targeted crypto libs may not work.
- **Database**: `@neondatabase/serverless`, `drizzle-orm`, `@prisma/client` (edge mode), `cloudflare:d1`. Don't `pg` (TCP) or `mysql2` (TCP).
- **`Response.json()`** is built in; same shape as Web Fetch.
- **`+api.ts` files don't render web/native UI** — pure handlers.
- **Type signature**: `Request → Response | Promise<Response>` per HTTP method export.

## Patterns + anti-patterns

### Pattern: REST endpoint with validation

```ts
// app/api/orders+api.ts
import { z } from 'zod';

const PostBody = z.object({
  productId: z.string(),
  quantity: z.number().int().positive(),
});

export async function POST(request: Request) {
  const body = await request.json();
  const parsed = PostBody.safeParse(body);
  if (!parsed.success) {
    return Response.json({ error: parsed.error.flatten() }, { status: 400 });
  }
  const order = await placeOrder(parsed.data);
  return Response.json(order, { status: 201 });
}
```

### Pattern: Dynamic route + Workers-compatible DB

```ts
// app/api/orders/[id]+api.ts
import { neon } from '@neondatabase/serverless';

export async function GET(request: Request, { id }: { id: string }) {
  const sql = neon(process.env.DATABASE_URL!);
  const [order] = await sql`SELECT * FROM orders WHERE id = ${id}`;
  if (!order) return new Response('Not found', { status: 404 });
  return Response.json(order);
}
```

### Pattern: Webhook with signature verification

```ts
// app/api/webhooks/stripe+api.ts
export async function POST(request: Request) {
  const sig = request.headers.get('stripe-signature');
  const raw = await request.text();
  const event = await verifyStripeSignature(raw, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  // handle event…
  return new Response('ok', { status: 200 });
}
```

Use Web Crypto for HMAC verification; don't import `node:crypto`.

### Pattern: Auth code exchange (mobile + OIDC)

```ts
// app/api/auth/exchange+api.ts
export async function POST(request: Request) {
  const { code, verifier } = await request.json();
  const r = await fetch('https://auth.example.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      code_verifier: verifier,
      client_id: process.env.OAUTH_CLIENT_ID!,
      client_secret: process.env.OAUTH_CLIENT_SECRET!, // server-only
      redirect_uri: process.env.OAUTH_REDIRECT_URI!,
    }),
  });
  const tokens = await r.json();
  // Return short-lived session token to mobile; keep refresh token server-side
  return Response.json({ accessToken: tokens.access_token });
}
```

The mobile app never sees the OAuth client secret.

### Anti-pattern: Importing Node libs

```ts
// BAD — Workers has no fs
import fs from 'node:fs';
const data = fs.readFileSync('./data.json');
```

Use a Workers-compatible alternative (KV, R2, or inline the data).

### Anti-pattern: Long-running tasks

```ts
// BAD — 60s job in a Worker
export async function POST(request: Request) {
  await heavyComputation(); // 60s
  return Response.json({ ok: true });
}
```

Hit CPU limits. Push to a queue (Cloudflare Queues, AWS SQS) and respond immediately.

### Anti-pattern: Connection-pooled TCP DBs

```ts
import { Pool } from 'pg';   // 👈 TCP — doesn't work
```

Use `@neondatabase/serverless` (Postgres over HTTP + WS), `drizzle-orm` with the serverless driver, or `cloudflare:d1`.

## Gotchas

- **Local dev runs on a Node shim** (`npx expo start`); production runs on Workers. Things that work locally may fail in production. Verify against `eas deploy --preview` before promoting.
- **CORS** — set CORS headers explicitly; Workers don't default to permissive.
- **Cookies** — set via `Response` headers; HTTP-only + Secure for sensitive ones.
- **Streaming responses** — supported via `ReadableStream`; useful for SSE.
- **No `request.body` re-read** — body streams once; if you need it twice, `tee()` or buffer to a string first.
- **Edge runtime caveats** — no setTimeout > 30s, no synchronous IO, no top-level await for slow imports.

## Cross-references

- [EAS Hosting](/stacks/expo/eas-hosting/) — where API routes deploy
- [Expo Router](/stacks/expo/expo-router/) — colocates API routes with screens
- [Cloudflare Stack](../cloudflare/) — Workers runtime in depth (bindings, KV, D1, R2)
- `expo-api-routes` skill (delegate) — API route patterns
- Role overlays: [frontend-architect](/stacks/expo/frontend-architect/)
- [API Routes reference](https://docs.expo.dev/router/reference/api-routes/)
