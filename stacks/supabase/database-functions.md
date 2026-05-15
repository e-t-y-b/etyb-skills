---
title: Database Functions
description: plpgsql / SQL functions in Postgres. RPC entrypoints, trigger bodies, RLS helpers. SECURITY DEFINER + search_path discipline is the only moving part.
product:
  name: Database Functions
  stack: supabase
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect, security-engineer]
  authoritative_url: https://supabase.com/docs/guides/database/functions
  notes: "Stable Postgres feature; the only Supabase-specific shift is the documented SECURITY DEFINER + SET search_path = '' hardening pattern."
---

## What it is

Database Functions are SQL or plpgsql functions stored in the database. On Supabase they serve three roles:

1. **RPC endpoints** — exposed via PostgREST and callable from supabase-js with `supabase.rpc("name", {...})`.
2. **Trigger bodies** — fire on row events to maintain invariants or publish realtime broadcasts.
3. **RLS helpers** — `stable SECURITY DEFINER` functions that encode shared auth logic.

Source: [Functions docs](https://supabase.com/docs/guides/database/functions).

## When to use

| Use a Database Function when | Use an [Edge Function](/stacks/supabase/edge-functions/) when |
|------------------------------|---------------------------------------------------------------|
| The whole operation is set-based SQL | The work calls external APIs |
| You want transactional guarantees with surrounding DML | You need npm packages or TypeScript |
| You'd call it via `supabase.rpc(...)` | The work is webhook-triggered |
| The function is a trigger | You need streaming responses |
| Performance matters (no network hop) | You need `EdgeRuntime.waitUntil` |
| You're chaining from `pg_cron` | Logic is hard to express in SQL |

Prefer Database Functions for in-DB orchestration; reach for Edge Functions when you cross out of the database.

## 2025-2026 currency anchors

- **`SECURITY DEFINER` + `SET search_path = ''`** is the only hardened pattern. Without `search_path`, the function is a privilege-escalation path.
- **`security invoker` is the default** — the function runs as the caller and RLS applies normally.
- **`stable` keyword** — lets the planner cache results within a statement. Critical for RLS helper performance.
- **`plv8` (JavaScript in Postgres)** exists but is rarely the right choice — Edge Functions cover the JS use cases better.
- **PG17 features** (since 2025) — JSON_TABLE, MERGE improvements, incremental sort. Available in plpgsql normally.

## Patterns and anti-patterns

### Patterns

**RPC endpoint with `security invoker`** so RLS applies:

```sql
create or replace function public.create_order_with_items(
  p_user_id uuid,
  p_items jsonb
)
returns table(order_id uuid, total numeric)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_order_id uuid;
  v_total numeric := 0;
begin
  insert into public.orders (user_id, status)
  values (p_user_id, 'pending')
  returning id into v_order_id;

  insert into public.order_items (order_id, product_id, qty, price)
  select
    v_order_id,
    (item->>'product_id')::uuid,
    (item->>'qty')::int,
    (item->>'price')::numeric
  from jsonb_array_elements(p_items) as item;

  select sum(qty * price) into v_total
  from public.order_items where order_id = v_order_id;

  update public.orders set total = v_total where id = v_order_id;
  return query select v_order_id, v_total;
end;
$$;

grant execute on function public.create_order_with_items(uuid, jsonb) to authenticated;
```

Call from supabase-js:

```ts
const { data, error } = await supabase.rpc("create_order_with_items", {
  p_user_id: user.id,
  p_items: items,
});
```

**RLS helper — `stable security definer` with locked `search_path`:**

```sql
create or replace function public.user_orgs()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select org_id from public.memberships
  where user_id = (select auth.uid())
$$;
```

Three required properties:
- `stable` — planner caches within a statement.
- `security definer` — runs as owner so it can read `public.memberships` regardless of caller.
- `set search_path = ''` — every reference schema-qualified to block shadowing.

**Trigger pattern — single-purpose, BEFORE for mutation, AFTER for side effects:**

```sql
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger orders_touch_updated_at
  before update on public.orders
  for each row execute function public.touch_updated_at();
```

**Trigger that publishes a Realtime broadcast** (see [Supabase Realtime](/stacks/supabase/supabase-realtime/)):

```sql
create or replace function public.broadcast_order_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('order_id', new.id, 'status', new.status),
    'order_updated',
    'org:' || new.org_id::text
  );
  return new;
end;
$$;
```

### Anti-patterns

- **`SECURITY DEFINER` without `SET search_path = ''`.** Attacker creates `public.memberships` view in their schema; function runs against attacker's view.
- **Synchronous `pg_net` calls from a trigger.** Serializes the transaction on an HTTP roundtrip. Use Database Webhooks (async) or push to a Queue.
- **Trigger functions piling six side effects together.** One trigger, one purpose. Composition through multiple triggers is cleaner.
- **`SECURITY DEFINER` RPC functions that take user-controlled input and use it without re-validating.** The whole RLS-bypass point of `definer` becomes a vulnerability.
- **`plv8` for business logic.** It introduces a JS runtime in Postgres for marginal benefit; Edge Functions are the right home.

## Gotchas

- **Function overloading by signature.** Postgres allows `fn(int)` and `fn(text)`; PostgREST exposes both. Be explicit in the `grant execute on function fn(<args>)`.
- **`returns trigger` functions don't return data to the caller.** Their return value (`NEW`, `OLD`, `NULL`) controls the row operation, not the API response.
- **`stable` vs `immutable` vs `volatile`** affects planner caching:
  - `volatile` (default) — re-run every call.
  - `stable` — same input → same output within a statement. Use for RLS helpers.
  - `immutable` — same input → same output globally. Use for pure functions.
- **`security definer` functions ignore RLS on the tables they read.** That's the point; don't be surprised when the caller "sees" rows they couldn't see directly.
- **Recursive triggers** can fire trigger → function → trigger → … Watch for cycles.

## Cross-references

- [Row-Level Security](/stacks/supabase/row-level-security/) — the consumer of `stable security definer` helpers
- [Edge Functions](/stacks/supabase/edge-functions/) — the alternative when SQL isn't the right home
- [Supabase Realtime](/stacks/supabase/supabase-realtime/) — trigger-driven Broadcast publishers
- [database-architect role view](/stacks/supabase/database-architect/) — schema-side patterns
- [backend-architect role view](/stacks/supabase/backend-architect/) — choosing-vs-Edge-Functions
- Supabase docs: [Database Functions](https://supabase.com/docs/guides/database/functions)
