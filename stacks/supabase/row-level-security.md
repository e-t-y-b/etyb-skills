---
title: Row-Level Security (RLS)
description: The authorization primitive on Supabase. The database itself enforces access control — wrong RLS means wrong data, period.
product:
  name: Row-Level Security
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, database-architect, backend-architect, saas-architect]
  authoritative_url: https://supabase.com/docs/guides/database/postgres/row-level-security
  notes: "Primitive is stable, but performance idioms (wrap auth.uid in subselect, index policy columns, SECURITY INVOKER views) keep being added to the docs."
---

## What it is

Row-Level Security is Postgres's mechanism for filtering rows inside the database based on the caller's identity. On Supabase, **RLS is the security perimeter**. There is no API gateway in front of the database — PostgREST exposes every table directly. If RLS is wrong, data is wrong.

Source: [Supabase RLS guide](https://supabase.com/docs/guides/database/postgres/row-level-security).

## When to use

**Always.** Every table in the `public` schema must have RLS enabled. The Supabase linter (`supabase db lint`) flags any that doesn't.

The only legitimate exception is reference data that's intentionally world-readable (list of countries, currency codes). Even then, revoke INSERT/UPDATE/DELETE from `anon` and `authenticated` and document the choice in a SQL comment:

```sql
-- RLS intentionally NOT enabled: read-only public reference data.
alter table public.countries disable row level security;
revoke insert, update, delete on public.countries from anon, authenticated;
```

Prefer RLS over:
- **Application-layer filters.** App filters are for UX (show only relevant data); RLS is for security. A buggy app filter without RLS leaks data; with RLS, it just shows nothing.
- **API gateway authorization.** Adds a layer that can be bypassed if anyone connects directly to PostgREST.
- **`SECURITY DEFINER` functions wrapping queries.** Those bypass RLS by design; use them for legitimate admin operations only.

## 2025-2026 currency anchors

- **`(select auth.uid())` wrapping** is the documented and benchmarked performance fix. On a 1M-row table the difference is approximately 100x. See [RLS performance](https://supabase.com/docs/guides/database/postgres/row-level-security#performance).
- **`SECURITY INVOKER` views** (PG15+) — the right default for views that should respect underlying RLS. The legacy `SECURITY DEFINER` view runs as owner and bypasses RLS. Audit every view.
- **Realtime Authorization** (2024) — RLS-style policies now apply to `realtime.messages` for Broadcast/Presence. Not the same as table RLS; configured separately. See [Supabase Realtime](/stacks/supabase/supabase-realtime/).
- **`FORCE ROW LEVEL SECURITY`** — applies RLS even to the table owner. Use sparingly; breaks maintenance scripts running as `postgres`.

## Patterns and anti-patterns

### Patterns

**The four policy commands, with WITH CHECK where it matters:**

```sql
-- SELECT
create policy "users see own orders" on public.orders
  for select using ( user_id = (select auth.uid()) );

-- INSERT — only WITH CHECK
create policy "users create own orders" on public.orders
  for insert with check ( user_id = (select auth.uid()) );

-- UPDATE — USING for visibility, WITH CHECK for post-state
create policy "users update own orders" on public.orders
  for update using ( user_id = (select auth.uid()) )
  with check ( user_id = (select auth.uid()) );

-- DELETE
create policy "users delete own orders" on public.orders
  for delete using ( user_id = (select auth.uid()) );
```

**The `(select auth.uid())` rule** — wrap every per-request constant in a scalar subselect so the planner caches it. Apply to `auth.jwt()`, `auth.role()`, and any helper function:

```sql
-- BAD: auth.uid() re-evaluated per row
using ( user_id = auth.uid() )

-- GOOD: planner caches the scalar subquery
using ( user_id = (select auth.uid()) )
```

**Index every column a policy references.** A policy that filters by `org_id` is only as fast as the index on `org_id`. Multi-tenant patterns that join through a membership table need indexes on both sides:

```sql
create index documents_org_id_idx on public.documents (org_id);
create index memberships_user_org_idx on public.memberships (user_id, org_id);
```

**Refactor repeated auth logic into `stable` `SECURITY DEFINER` functions with `SET search_path = ''`.** See [Database Functions](/stacks/supabase/database-functions/) for the hardening rules.

**Permissive vs Restrictive policies:**
- Permissive (default) — any matching policy grants access (OR'd).
- Restrictive — AND'd into the result; use for "always-true" filters like soft-delete or tenant-suspension gates.

**Test policies via impersonation** before they ship:

```sql
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
  select * from public.orders;  -- what would Alice see?
rollback;
```

Bundle these into `tests/rls/*.sql` and run in CI against a `supabase start` instance.

### Anti-patterns

- **`USING (true)` on SELECT "temporarily."** Easy to forget; ships to prod.
- **`USING` instead of `WITH CHECK` on INSERT.** USING is meaningless on INSERT — no existing row to filter — and the policy will be permissive by accident.
- **Update policy with USING but no WITH CHECK.** User can update their own row and set `user_id = <someone else>` — the row leaves their visibility but the update succeeds.
- **App-layer filter + permissive RLS.** When the app filter is wrong, RLS doesn't save you because the policy is wide-open.
- **Forgetting RLS on `storage.objects`.** Uploads to a bucket are world-readable unless you write SELECT policies on the storage rows. See [Supabase Storage](/stacks/supabase/supabase-storage/).
- **Joining through a table that has its own RLS that filters out the inner SELECT.** The outer policy looks right; the inner query returns empty under the same JWT, so the outer returns empty.
- **Service-role to "just get past RLS."** Almost always the policy is wrong. Fix the policy.

## Gotchas

- **`auth.uid()` called when user is not authenticated returns NULL.** `null = null` is false → empty result, not an error. Looks like "RLS isn't working"; really, "no user."
- **Default-deny.** RLS enabled + no policies = no rows visible to anyone except service_role. This is the safe default; if you forget a policy, the table is locked, not leaking.
- **The table owner (`postgres`) bypasses RLS unless you `FORCE ROW LEVEL SECURITY`.** Migration scripts running as `postgres` see everything. Service-role JWTs run as `postgres`.
- **Views default to `SECURITY DEFINER` semantics** unless you opt into `WITH (security_invoker = true)`. Older Supabase advisor will flag this; new views should opt-in by default.
- **Restrictive policy with no permissive sibling = total denial.** Restrictive AND-combines with whatever permissive policies grant; if no permissive policy matches, the row is invisible.
- **Performance: a missing `(select ...)` wrap and a missing index on the policy column are the two highest-leverage misses.** Together they can take an RLS table from "fine" to "unusable" as it grows.

## Cross-references

- [security-engineer role view](/stacks/supabase/security-engineer/) — full hardening playbook
- [database-architect role view](/stacks/supabase/database-architect/) — performance + indexing
- [saas-architect role view](/stacks/supabase/saas-architect/) — multi-tenancy on RLS
- [Database Functions](/stacks/supabase/database-functions/) — `SECURITY DEFINER` + `search_path` rules
- [Supabase Realtime](/stacks/supabase/supabase-realtime/) — Realtime Authorization (separate but similar)
- [Supabase Storage](/stacks/supabase/supabase-storage/) — RLS on `storage.objects`
- Supabase docs: [RLS guide](https://supabase.com/docs/guides/database/postgres/row-level-security), [RLS performance](https://supabase.com/docs/guides/database/postgres/row-level-security#performance)
