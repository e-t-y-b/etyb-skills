---
title: backend-architect on Supabase
description: Edge Functions, server-side supabase-js, Database Functions, Realtime publishers, Queues, Cron, pooler decisions, ORM compatibility.
role_overlay:
  role: backend-architect
  stack: supabase
  last_verified_on: "2026-05-14"
  products_covered: [edge-functions, supabase-js, database-functions, supabase-realtime, supabase-queues, supabase-cron, supavisor, database-webhooks, pg-net, supabase-storage, pg-graphql]
---

## Role briefing

You're backend-architect on a Supabase engagement. Your surface is **everything between the database and the client**: [Edge Functions](/stacks/supabase/edge-functions/) (Deno), server-side [supabase-js](/stacks/supabase/supabase-js/), [Database Functions](/stacks/supabase/database-functions/) when SQL is the right home, the [Realtime](/stacks/supabase/supabase-realtime/) publish-side, the [Queues](/stacks/supabase/supabase-queues/) + [Cron](/stacks/supabase/supabase-cron/) orchestration plane, and the [Supavisor](/stacks/supabase/supavisor/) pooler-mode decisions that determine whether your service has stable production behavior.

What you don't own here: schema and RLS performance belong to [database-architect](/stacks/supabase/database-architect/); auth hardening to [security-engineer](/stacks/supabase/security-engineer/); client wiring to [frontend-architect](/stacks/supabase/frontend-architect/). Your job is making the server-side code correct, fast, and operationally sound.

What's distinctive vs. a generic backend-architect role: on Supabase, **PostgREST is your default API**. Every table is an endpoint via supabase-js; every RPC is a Database Function. You don't reflexively build a Node API in front of Postgres — you reach for an Edge Function only where PostgREST is insufficient.

## Decision frameworks specific to backend-architect on Supabase

### Edge Function vs Database Function vs external service

| Use a [Database Function](/stacks/supabase/database-functions/) when | Use an [Edge Function](/stacks/supabase/edge-functions/) when | Use an external service (Lambda/Worker) when |
|--------------------------------------------------------------------|-------------------------------------------------------------|---------------------------------------------|
| The work is set-based SQL | The work calls external APIs (Stripe, OpenAI, SendGrid) | You need GPU compute |
| You want transactional guarantees with surrounding DML | You need npm packages | You need a long-running process |
| You'll expose via `supabase.rpc(...)` | The work is webhook-triggered | You're already heavily invested in another runtime |
| The function is a trigger | You need streaming responses, SSE | You need a specific region not in Supabase's grid |
| Performance matters (no network hop) | You need `EdgeRuntime.waitUntil` | |

### Service role vs anon (with forwarded auth)

Default to **anon key + forwarded Authorization header** in Edge Functions. RLS applies; users see what they should. Reach for [service-role](/stacks/supabase/supabase-auth/) only when the operation is intentionally admin-scoped:
- Provisioning a new tenant.
- Processing a verified webhook from Stripe.
- Cron jobs operating on system data.

Never forward a caller's intent (`target_user_id`) to a service-role client. That's a catastrophic RLS-bypass anti-pattern.

### Postgres Changes vs Broadcast vs Presence

If the source-of-truth is a DB row change AND the consumer needs the full row → [Postgres Changes](/stacks/supabase/supabase-realtime/). If the source is an app event OR you can shape a smaller payload → Broadcast. Default to Broadcast in most apps. Reserve Postgres Changes for true CDC dashboards.

Publish-side pattern: a Postgres trigger calls `realtime.send(...)` rather than letting clients subscribe to raw table changes. Cleaner authorization, smaller payloads, app-level semantics.

### Database Webhook vs Queue + worker

[Database Webhooks](/stacks/supabase/database-webhooks/) for fire-and-forget (Slack notification, analytics sync). [Supabase Queues](/stacks/supabase/supabase-queues/) for anything that needs retry semantics or DLQ — payment settlement, cross-system state machines.

### Pooler mode

Reflex rule:
- Serverless / Edge / Lambda / Workers → **transaction pooler** (`:6543`), ORM configured to disable prepared statements.
- Long-lived Node/Bun/Rails → **session pooler**.
- Migrations / `LISTEN/NOTIFY` / advisory locks → **session pooler**.
- Studio / `psql` debug → **direct**.

See [Supavisor](/stacks/supabase/supavisor/) for the ORM compatibility matrix.

## Product references

- [Edge Functions](/stacks/supabase/edge-functions/) — Deno runtime, JSR imports, background tasks, ephemeral storage, structured logging, cold-start hygiene. The canonical shape: `Deno.serve` + JSR supabase-js + forwarded `Authorization` header + `persistSession: false`. Background tasks via `EdgeRuntime.waitUntil` for fire-and-forget; Queues for durable async.
- [supabase-js](/stacks/supabase/supabase-js/) — server-side patterns: anon-with-forwarded-JWT for caller-scoped operations, admin client for admin work. Cookie-bound auth on server-side routes via [@supabase/ssr](/stacks/supabase/supabase-ssr/).
- [Database Functions](/stacks/supabase/database-functions/) — RPC pattern (`security invoker` default), trigger pattern, the broadcast-from-trigger pattern, `SECURITY DEFINER` + `SET search_path = ''` discipline.
- [Supabase Realtime](/stacks/supabase/supabase-realtime/) — publish side: `realtime.send` from triggers, Broadcast authorization, the three primitives and when each fits.
- [Supabase Queues](/stacks/supabase/supabase-queues/) — managed `pgmq`; the worker pattern is an Edge Function on Cron reading a batch, processing, archiving, with DLQ on retry exhaustion.
- [Supabase Cron](/stacks/supabase/supabase-cron/) — `pg_cron` wrapped; the typical schedule is `*/1 * * * *` invoking an Edge Function worker.
- [Database Webhooks](/stacks/supabase/database-webhooks/) — async via `pg_net`; idempotent receivers; not for transactional flows.
- [pg_net](/stacks/supabase/pg-net/) — never call synchronously from a trigger.
- [Supavisor](/stacks/supabase/supavisor/) — transaction vs session mode determines which Postgres features work. ORM config matters.
- [Supabase Storage](/stacks/supabase/supabase-storage/) — server-side uploads, signed URLs, TUS for large files. RLS on `storage.objects`.
- [pg_graphql](/stacks/supabase/pg-graphql/) — auto-generated GraphQL; rarely the right primary API for internal apps.

## 2025-2026 platform reset relevant to backend-architect

- **JSR specifier for supabase-js**: `jsr:@supabase/supabase-js@2`, not esm.sh URLs.
- **Edge Functions support `EdgeRuntime.waitUntil`** for background tasks bounded by overall execution budget.
- **Supavisor replaced PgBouncer** as default pooler in 2024 — every old "PgBouncer port 6432" reference is wrong; use `6543` transaction or pooler hostname for session.
- **Supabase Queues (2025)** is the managed surface on `pgmq`; **Supabase Cron (late 2024)** wraps `pg_cron`. Stop using `pg_cron` directly from the SQL editor for new work.
- **Realtime Authorization (2024)** — Broadcast/Presence respect RLS-style policies on `realtime.messages`. Configure or don't ship.
- **Database Webhooks are async via `pg_net`** and back-pressure under load — not transactional.
- **PostgREST is your API**; reach for an Edge Function only where it's insufficient (orchestration, external APIs, streaming).

## Patterns the role applies

### TDD on Edge Functions

`deno test` against a local Supabase instance:

```ts
import { assertEquals } from "jsr:@std/assert";

Deno.test("process-order returns 400 on missing user", async () => {
  const res = await fetch("http://localhost:54321/functions/v1/process-order", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });
  assertEquals(res.status, 400);
});
```

```bash
supabase start
supabase functions serve --no-verify-jwt
deno test --allow-net supabase/functions/_tests/
```

CI: spin up a Supabase container, run migrations, deploy functions locally, run `deno test`.

### TDD on Database Functions

`pgTAP`-style tests in `tests/db/*.sql`; run via `psql -f` against `supabase start`.

### Verification

Every Edge Function change ships with:
- `deno test` pass on local instance.
- Successful test deploy to a [preview branch](/stacks/supabase/branching/).
- `EXPLAIN ANALYZE` for any DB query the function executes.

Don't claim "the function works" because the dashboard returned 200. Assert the side effects: row written, message enqueued, email landed in the test inbox.

### Debugging

**"Edge Function returns 401 for authenticated users."**
- 90%: `Authorization` header isn't being forwarded into the supabase-js client constructor.
- 5%: JWT expired (client didn't refresh).
- 5%: JWT `aud` claim is for a different project.

**"Writes succeed but queries return empty."**
- The function is using anon key without forwarding the `Authorization` header → queries as anonymous → RLS returns nothing.

**"Intermittent `prepared statement "xxx" does not exist`."**
- ORM issuing prepared statements over the transaction pooler. Fix ORM config (`prepare: false` / `?pgbouncer=true`).

## Cross-references

- [database-architect](/stacks/supabase/database-architect/) — schema, RLS performance, indexes, migrations
- [frontend-architect](/stacks/supabase/frontend-architect/) — client-side supabase-js + `@supabase/ssr`
- [security-engineer](/stacks/supabase/security-engineer/) — RLS, service-role discipline, Vault
- [ai-ml-engineer](/stacks/supabase/ai-ml-engineer/) — Edge Functions for AI orchestration
- [saas-architect](/stacks/supabase/saas-architect/) — multi-tenant patterns the backend implements
- [Supabase Stack index](/stacks/supabase/) — what changed in 2025-2026
