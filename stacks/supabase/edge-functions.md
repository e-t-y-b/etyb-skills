---
title: Edge Functions
description: Globally distributed Deno-based HTTP handlers for webhook handlers, AI orchestration, and anything that needs npm or external APIs.
product:
  name: Edge Functions
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, security-engineer]
  authoritative_url: https://supabase.com/docs/guides/functions
  notes: "Deno runtime; npm: imports stable; background tasks (EdgeRuntime.waitUntil) and ephemeral storage GA; JSR specifier preferred for supabase-js."
---

## What it is

Edge Functions are HTTP handlers running on Supabase's globally distributed Deno-based runtime. Source code lives in `supabase/functions/<name>/index.ts`. They're the right place for webhook handlers, AI orchestration, external API calls, and anything that needs npm packages.

Source: [Edge Functions docs](https://supabase.com/docs/guides/functions).

## When to use

| Use an Edge Function when | Use a [Database Function](/stacks/supabase/database-functions/) when |
|---------------------------|---------------------------------------------------------------------|
| You call external APIs (Stripe, OpenAI, SendGrid) | The work is set-based SQL |
| You need npm packages or TypeScript libraries | You want transactional guarantees with surrounding DML |
| The work is webhook-triggered | The function is a trigger |
| You need streaming responses, SSE | You'd expose it via `supabase.rpc(...)` |
| You need `EdgeRuntime.waitUntil` for fire-and-forget | Performance matters (no network hop) |

Prefer Edge Functions over Vercel/Cloudflare Workers when the function lives close to the Supabase database (region pinning) and uses [@supabase/ssr](/stacks/supabase/supabase-ssr/) auth context cleanly.

## 2025-2026 currency anchors

- **`Deno.serve` is the canonical entrypoint.** Older `import { serve } from "std/http/server.ts"` is deprecated.
- **JSR specifier for supabase-js**: `jsr:@supabase/supabase-js@2` — preferred over `https://esm.sh/...` URLs. JSR resolves faster and is recommended since 2025.
- **`npm:` imports are stable.** Pin versions (`npm:stripe@14.5.0`), don't float (`npm:stripe@latest`).
- **`EdgeRuntime.waitUntil`** for background tasks (respond fast, finish work after). Bounded by overall execution budget (~30-60s on Pro).
- **Ephemeral storage** — `/tmp` and `Deno.makeTempFile()` live only for the invocation. Useful for CSV processing, PDF generation.
- **`Deno KV` is not exposed.** Use Postgres or Storage instead.
- **Regional invocation** — runtime picks closest by default; `--region` flag at deploy for data-residency.
- **Background tasks have an overall execution cap.** Don't try to run 5-minute jobs this way; use [Queues](/stacks/supabase/supabase-queues/).

## Patterns and anti-patterns

### Patterns

**Canonical function shape — RLS-bound client:**

```ts
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      auth: { persistSession: false },
    },
  );

  const { data, error } = await supabase.from("orders").select("*").limit(10);
  if (error) return new Response(error.message, { status: 400 });

  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" },
  });
});
```

The five rules baked in:
1. `Deno.serve` entrypoint.
2. JSR specifier (`jsr:@supabase/supabase-js@2`).
3. **Forward the caller's `Authorization` header** so RLS evaluates against the user.
4. `persistSession: false` — functions are stateless.
5. Return a `Response`.

**Background tasks** for fire-and-forget side effects:

```ts
Deno.serve(async (req: Request) => {
  const body = await req.json();
  EdgeRuntime.waitUntil((async () => {
    await sendEmailViaSendgrid(body);
    await logToAnalytics(body);
  })());
  return new Response("queued", { status: 202 });
});
```

Use for notifications, analytics, non-critical side effects. **Not for anything the user needs confirmation of** — use a Queue + dedicated worker.

**Structured logging** — `console.log` writes to Logs Explorer; structure as JSON for filtering:

```ts
console.log(JSON.stringify({
  level: "info",
  function: "process-order",
  order_id: orderId,
  duration_ms: durationMs,
}));
```

**Cold-start hygiene:**
- Small functions (one cold-start surface each).
- Prefer `jsr:@std/...` over `npm:` for stdlib stuff.
- Pin npm versions; avoid sync I/O at module scope.
- Cron-pinged warm-keep for latency-critical paths.

**Service role only with re-authorization**:

```ts
const adminClient = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

// Verify the request authority FIRST (e.g., Stripe signature),
// THEN use the admin client for whatever needs RLS bypass.
```

### Anti-patterns

- **Forwarding caller's `target_user_id` to a service-role client.** Catastrophic — the caller can read anyone's data:
  ```ts
  // DON'T:
  const target = req.url.searchParams.get("target_user_id");
  await adminClient.from("private_data").select("*").eq("user_id", target);
  ```
- **Floating npm versions** (`npm:stripe@latest`). Blows the cache and breaks reproducibility.
- **Sync I/O at module scope** (top-level fetch for config). Added to cold-start; awaited before first request.
- **Using `EdgeRuntime.waitUntil` for long-running jobs.** Bounded by function execution budget; use Queues.
- **Storing secrets in code.** Use `supabase secrets set MY_KEY=...` and `Deno.env.get(...)`.
- **One monolithic function with N endpoints.** One big slow cold-start; split per route.

## Gotchas

- **`Authorization` header forwarding is the #1 source of "function returns 401 for authenticated users."** If you forget it, the function operates as anonymous and RLS blocks the user's own data.
- **Service-role JWT bypasses RLS entirely.** Never ship the service-role key to a browser or mobile app. Edge Functions, CI, and server-side handlers only.
- **Cold starts are real** and dominated by module loading. Large `npm:` deps blow first-invocation latency. Tree-shake aggressively.
- **`EdgeRuntime.waitUntil` is best-effort and bounded.** Don't try to run a long task this way; use a Queue + Cron-invoked worker.
- **No persistent storage** between invocations. Use Postgres or Storage.
- **Deno KV is not available.** Use Postgres + an indexed table or `pgmq` for queue semantics.
- **JWT issuer/audience mismatch** — a JWT from project A won't validate against project B; the `aud` claim is project-scoped.
- **`supabase functions serve --no-verify-jwt`** lets you call functions locally without auth; useful for local testing but obviously not for prod.

## Cross-references

- [Database Functions](/stacks/supabase/database-functions/) — when SQL is the right home
- [Supabase Queues](/stacks/supabase/supabase-queues/) — durable async work
- [Supabase Cron](/stacks/supabase/supabase-cron/) — scheduled Edge Function invocation
- [Database Webhooks](/stacks/supabase/database-webhooks/) — async DB-event → external
- [backend-architect role view](/stacks/supabase/backend-architect/) — full server-side playbook
- [ai-ml-engineer role view](/stacks/supabase/ai-ml-engineer/) — RAG + streaming patterns
- Supabase docs: [Functions guide](https://supabase.com/docs/guides/functions), [Runtime details](https://supabase.com/docs/guides/functions/runtime)
