---
title: supabase-js
description: The official JavaScript/TypeScript client SDK. v2 stable, v3 stabilizing through 2026. Query builder, auth, storage, realtime.
product:
  name: supabase-js
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect, ai-ml-engineer]
  authoritative_url: https://supabase.com/docs/reference/javascript
  notes: "v2 stable through 2026; v3 stabilizing with auth client splits and improved type inference. Query builder shape stable across both."
---

## What it is

`supabase-js` is the official JavaScript/TypeScript client SDK for Supabase. It wraps the PostgREST query API, Auth, Storage, Realtime, and Functions surfaces in a unified client. Browser, server, Node, Bun, Deno, Edge — all supported.

Source: [supabase-js reference](https://supabase.com/docs/reference/javascript).

## When to use

Use `supabase-js` for:
- **Every browser/mobile data path** to a Supabase project.
- **Server-side data access** in Edge Functions, route handlers, server components.
- **Auth flows** — sign-in, sign-up, magic link, OAuth, MFA, session refresh.
- **Storage operations** — uploads, signed URLs, image transforms.
- **Realtime subscriptions** — Postgres Changes, Broadcast, Presence.

For SSR cookie-bound auth, use [@supabase/ssr](/stacks/supabase/supabase-ssr/) which wraps `supabase-js` with cookie adapters.

Reach for a raw Postgres client (postgres-js, Drizzle, Prisma) only when:
- You need SQL that PostgREST can't express (window functions, complex CTEs).
- You're on a long-running server with its own connection budget.
- You're building a migration tool or CLI.

## 2025-2026 currency anchors

- **v2 is stable.** v3 is stabilizing through Q1-Q2 2026 with auth client splits and improved type inference. The query builder shape is stable across both — code written for v2 query-builder will work on v3.
- **JSR distribution** for Deno/Edge Functions: `jsr:@supabase/supabase-js@2` is preferred over `https://esm.sh/...`.
- **Generated TypeScript types** (`supabase gen types typescript`) integrate via `createClient<Database>(...)`.
- **Auth state listener** (`onAuthStateChange`) — pair with cleanup; subscriptions leak.
- **Improved relationship-typing** in v3 — joined-query results are correctly typed without manual annotations.

## Patterns and anti-patterns

### Patterns

**Two clients, two purposes:**

```ts
// Anon — RLS-bound, safe for browsers + caller-scoped server use
const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Admin — service role, bypasses RLS, NEVER ship to browser
const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
```

**Query builder essentials:**

```ts
const { data, error } = await supabase
  .from("orders")
  .select(`
    id, total, status,
    user:user_id (id, email),
    items:order_items (product_id, qty, price)
  `)
  .eq("status", "pending")
  .gte("created_at", lastWeek)
  .order("created_at", { ascending: false })
  .limit(50);
```

- **Relationship syntax** (`user:user_id (...)`) joins via FK; the FK must exist.
- **`.maybeSingle()`** for "0 or 1"; **`.single()`** for "exactly 1" (errors otherwise).
- **`.throwOnError()`** chained for an exception-style flow.
- **`.select("*", { count: "exact" })`** for total count alongside rows (costs an extra query).

**Upsert with conflict target:**

```ts
const { data, error } = await supabase
  .from("user_preferences")
  .upsert({ user_id, theme: "dark" }, { onConflict: "user_id" })
  .select().single();
```

**RPC for stored procedures:**

```ts
const { data, error } = await supabase.rpc("create_order_with_items", {
  p_user_id: user.id,
  p_items: items,
});
```

RPC respects RLS through the underlying function's `security invoker` / `security definer` declaration.

**Generated types — wire to your client:**

```ts
import type { Database } from "@/types/database";
const supabase = createClient<Database>(URL, KEY);
```

Set up `predev` to regenerate types automatically.

**Cursor pagination** for infinite scroll:

```ts
.lt("created_at", lastSeenCreatedAt)
.order("created_at", { ascending: false })
.limit(50);
```

**Auth state listener with cleanup:**

```ts
useEffect(() => {
  const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
    if (event === "SIGNED_IN") refetch();
    if (event === "SIGNED_OUT") clearState();
  });
  return () => { subscription.unsubscribe(); };
}, []);
```

### Anti-patterns

- **Service-role JWT in browser code.** Never. The `service_role` bypasses RLS — leaking it = full DB read/write.
- **Mixing browser + server clients in one module.** `createBrowserClient` vs `createServerClient` from `@supabase/ssr` are not interchangeable.
- **`.single()` when you meant `.maybeSingle()`.** `.single()` errors on 0 rows; common bug source.
- **Offset pagination** on large tables. O(n) on the database. Use cursor pagination.
- **No `removeChannel`** after `supabase.channel(...).subscribe()`. Channels accumulate; handlers duplicate.
- **`getSession()` for auth gates** — reads from cookie without re-verification. Use `getUser()`.
- **Trusting `.select("*")`** everywhere. Pick specific columns; smaller payloads, faster parse, less RLS surface.

## Gotchas

- **Each `.eq()` returns a new query builder.** Don't mutate in an array of chained calls.
- **`.or("col1.eq.1,col2.eq.2")`** uses comma-separated string syntax. For complex predicates, prefer RPC.
- **Realtime filter is server-side** — `filter: \`user_id=eq.${userId}\`` limits which rows the channel receives. Use it.
- **Relationship-typed results depend on FK existence.** No FK = no inference.
- **`is("col", null)` not `.eq("col", null)`** — `eq` won't match nulls.
- **The query builder doesn't auto-`select()` after insert/update/upsert.** Chain `.select()` if you want the row back.
- **TypeScript types reflect the schema at gen-time.** Drift between live schema and generated types causes silent runtime bugs.

## Cross-references

- [@supabase/ssr](/stacks/supabase/supabase-ssr/) — cookie-bound auth wrapper
- [Supabase Auth](/stacks/supabase/supabase-auth/) — auth methods exposed via `.auth.*`
- [Supabase Storage](/stacks/supabase/supabase-storage/) — storage methods via `.storage.*`
- [Supabase Realtime](/stacks/supabase/supabase-realtime/) — `.channel(...)` API
- [frontend-architect role view](/stacks/supabase/frontend-architect/) — query patterns and optimistic UI
- [backend-architect role view](/stacks/supabase/backend-architect/) — server-side client patterns
- Supabase docs: [supabase-js reference](https://supabase.com/docs/reference/javascript)
