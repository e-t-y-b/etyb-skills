---
title: security-engineer on Supabase
description: RLS as the security primitive, Auth hardening, Vault, JWT verification, network controls, audit, Storage RLS, MCP agent boundaries.
role_overlay:
  role: security-engineer
  stack: supabase
  last_verified_on: "2026-05-14"
  products_covered: [row-level-security, supabase-auth, supabase-vector, supabase-storage, supabase-realtime, supabase-mcp, database-functions, postgres]
---

## Role briefing

You're security-engineer on a Supabase engagement. The defining property of Supabase from your seat: **the database itself enforces authorization**. There is no API gateway you can hide policy violations behind. RLS is the security primitive. If RLS is wrong, the data is wrong, end of story. Everything else — [Auth hardening](/stacks/supabase/supabase-auth/), secrets, network controls, audit — composes on top.

What's distinctive vs. a generic security-engineer role: you don't review API authz code. You review RLS policies. You don't worry about API tokens as the only auth — you worry about whether the service-role JWT ever leaks. You don't tell developers "validate input" so much as "model your data so RLS enforces validity."

## Threat model — what an attacker has

Ranked by blast radius:

1. **The `service_role` JWT.** Unrestricted access. Compromise = full database, full Storage, full Auth admin. Treat as a root key.
2. **A misconfigured RLS policy.** Direct path to other tenants' data. Most production breaches in Supabase deployments trace here.
3. **An exposed `SECURITY DEFINER` function without `search_path` lockdown.** Privilege escalation via object shadowing.
4. **A weak Auth flow.** Account takeover via phishable second factor, leaked-password reuse, magic-link interception.
5. **A leaky Edge Function** forwarding user-supplied input to an admin client, bypassing RLS.
6. **A misconfigured Storage policy.** Bucket world-readable, uploads to other users' folders.
7. **A leaked anon key** combined with a weak RLS policy.

Harden in that order.

## Decision frameworks specific to security-engineer on Supabase

### Service role: yes or no

Default: **no**. Every potential `service_role` use is reframed: "could RLS model this so the user-role gets what it needs?" Most "I need service role" cases are "my RLS policy is wrong."

Service role only when:
- Operation is intentionally admin-scoped (tenant provisioning, system jobs).
- Caller's authority has been independently verified (Stripe webhook signature, internal CI).

Service role never:
- In a browser, mobile app, or any client.
- Combined with user-supplied target IDs (catastrophic).

### MFA factor choice

| Factor | Use |
|--------|-----|
| **TOTP** | Solid default for most users |
| **WebAuthn / Passkey** | Strongest; phishing-resistant. The right primary for B2B / admin. |
| **SMS** | Fallback only. Never as the only second factor — SIM swap risk. |

For B2B / admin users: **require WebAuthn or TOTP**.

### AAL-based step-up

```sql
create policy "AAL2 required for billing" on public.billing
  for all using ( (select auth.jwt() ->> 'aal') = 'aal2' );
```

Browse at AAL1, mutate at AAL2.

### Network controls (Pro+)

- IP allow-list for direct DB connection — restrict to office / VPN / CI.
- Network restrictions on API surface — rare for most apps.
- Custom domain with managed TLS for white-label.

## Product references

- [Row-Level Security](/stacks/supabase/row-level-security/) — the perimeter. The `(select auth.uid())` rule, indexed policy columns, helper functions with `SECURITY DEFINER` + `SET search_path = ''`, `SECURITY INVOKER` views.
- [Supabase Auth](/stacks/supabase/supabase-auth/) — MFA, AAL, Auth Hooks, leaked-password protection, CAPTCHA, custom SMTP, Custom Access Token Hook for custom claims.
- [Supabase Vault](/stacks/supabase/supabase-vector/) — pgsodium-backed encrypted secrets for things called from Postgres (`pg_net` signing keys, FDW credentials).
- [Supabase Storage](/stacks/supabase/supabase-storage/) — RLS on `storage.objects` is non-negotiable; bucket-level config (public, MIME, size limit); signed URLs short-lived.
- [Supabase Realtime](/stacks/supabase/supabase-realtime/) — Realtime Authorization on `realtime.messages` for Broadcast/Presence.
- [Supabase MCP](/stacks/supabase/supabase-mcp/) — agent access controls; `--read-only` flag, PAT scope, branch-only writes.
- [Database Functions](/stacks/supabase/database-functions/) — `SECURITY DEFINER` + `SET search_path = ''` is the only hardened pattern.
- [Postgres](/stacks/supabase/postgres/) — `pgaudit` for session/object audit logging.

## RLS hardening — the rulebook

### Enable on every table

```sql
alter table public.orders enable row level security;
```

Exceptions for reference data must be documented in a SQL comment.

### Four-policy template — get the WITH CHECK right

```sql
create policy "users see own orders" on public.orders for select using ( user_id = (select auth.uid()) );
create policy "users create own orders" on public.orders for insert with check ( user_id = (select auth.uid()) );
create policy "users update own orders" on public.orders for update using ( user_id = (select auth.uid()) ) with check ( user_id = (select auth.uid()) );
create policy "users delete own orders" on public.orders for delete using ( user_id = (select auth.uid()) );
```

A common bug: UPDATE policy with `USING` but no `WITH CHECK` — user can update their own row and set `user_id = <someone else>`. The row leaves their visibility but the update succeeds.

### Helper functions — locked search_path

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

Three required properties: `stable` (planner caches), `security definer` (runs as owner), `set search_path = ''` (blocks object shadowing).

### View security — opt into `security_invoker`

```sql
create view public.active_orders
with (security_invoker = true)
as
  select * from public.orders where status = 'active';
```

Audit every view. The legacy default (`SECURITY DEFINER`) bypasses underlying RLS.

### Realtime Authorization

```sql
create policy "receive org broadcasts" on realtime.messages
  for select using (
    (select auth.role()) = 'authenticated'
    and substring(realtime.topic() from '^org:(.+)') in (
      select org_id::text from public.memberships
      where user_id = (select auth.uid())
    )
  );
```

Without this, anyone subscribed to a predictable channel sees every message.

### Storage RLS

```sql
create policy "users read own invoices" on storage.objects
  for select using (
    bucket_id = 'invoices'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
```

Forgetting Storage RLS leaves uploaded files world-readable.

## Auth Hooks for custom claims

**Custom Access Token Hook** — inject `org_id`, `role`, `plan` at sign-in:

```sql
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb language plpgsql stable as $$
declare
  claims jsonb := event->'claims';
  uid uuid := (event->>'user_id')::uuid;
  v_org_id uuid; v_role text;
begin
  select org_id, role into v_org_id, v_role
  from public.memberships where user_id = uid limit 1;

  claims := jsonb_set(claims, '{org_id}', to_jsonb(v_org_id::text));
  claims := jsonb_set(claims, '{user_role}', to_jsonb(v_role));
  event := jsonb_set(event, '{claims}', claims);
  return event;
end; $$;

grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
```

Then RLS reads `(select auth.jwt() ->> 'org_id')` — O(1) instead of joining through memberships.

Trade-off: stale until next JWT refresh on membership change.

## JWT verification — outside Supabase

```ts
import { jwtVerify, createRemoteJWKSet } from "jose";
const JWKS = createRemoteJWKSet(new URL("https://<project>.supabase.co/auth/v1/.well-known/jwks.json"));
const { payload } = await jwtVerify(token, JWKS, {
  audience: "authenticated",
  issuer: "https://<project>.supabase.co/auth/v1",
});
```

JWKS / RS256 is the modern default (new projects). Verify via JWKS; never hard-code the JWT secret.

## MCP agent boundaries

Hardening rules for [Supabase MCP](/stacks/supabase/supabase-mcp/):

1. **`--read-only` flag** for any non-trusted use.
2. **PAT scoped to one project.**
3. **Never write scope on production.** Use a [branch](/stacks/supabase/branching/) or staging.
4. **Treat agent SQL as untrusted.** Even with write scope, human review + preview branch before main.

## 2025-2026 platform reset relevant to security-engineer

- **`(select auth.uid())` performance rule** is documented; missing it is also a performance bug, not just a stylistic one.
- **`SECURITY INVOKER` views** (PG15+) — audit existing views; new views should opt-in by default.
- **Realtime Authorization (2024)** — Broadcast/Presence respect policies on `realtime.messages`.
- **Auth Hooks (since 2024)** — Custom Access Token, Send Email, Send SMS, MFA Verification Attempt, Password Verification Attempt.
- **WebAuthn / Passkey** as a built-in MFA factor; the right strong primary.
- **JWKS / RS256** for external verification on new projects.
- **Anonymous sign-ins** — real UUID; can be RLS-scoped.
- **MCP server** is a new attack surface; harden access from the start.
- **SSO + SCIM** are Team / Enterprise tier; don't promise on Pro.

## A reviewer's checklist for a Supabase PR

1. Every new table has RLS enabled and at least one policy.
2. Every policy referencing `auth.uid()` wraps in `(select auth.uid())`.
3. Every policy column is indexed.
4. Every `SECURITY DEFINER` function has `SET search_path = ''`.
5. Every view that filters via RLS is `WITH (security_invoker = true)` (or documented as definer with rationale).
6. No `service_role` key in client-bundled code (search `NEXT_PUBLIC_`, `EXPO_PUBLIC_`, `VITE_`).
7. Storage buckets have policies AND bucket config.
8. Realtime channels carrying user data have authorization policies.
9. Auth Hook changes are tested with fresh JWT issuance.
10. Migrations are append-only — no edits to previously-applied files.

## Patterns the role applies

### TDD on policies

Every policy ships with an impersonation test (see [database-architect](/stacks/supabase/database-architect/)). Cases:
1. Anonymous user — sees nothing on private tables.
2. Authenticated user A — sees only A's rows.
3. Authenticated user B — does NOT see A's rows.
4. Service role — sees everything (sanity check that policy isn't accidentally restricting service role).
5. (Multi-tenant) — user in a different org doesn't see this org's rows.

### Verification

Before claiming "RLS works": policy + failing-then-passing impersonation test. Before claiming "the function is hardened": `SET search_path = ''` + a test that proves shadowing doesn't work.

### Debugging

**"User can see another user's data."** Hypothesis ranked:
1. RLS disabled on the table.
2. Policy uses `auth.uid()` directly (rare planner edge cases).
3. `SECURITY DEFINER` function bypasses RLS.
4. View is `SECURITY DEFINER` (legacy default) — switch to invoker.
5. Query path uses `service_role`.
6. Policy logic bug (wrong join).

Impersonate the affected user with `set local request.jwt.claims = ...` and re-run. The result is the truth.

## Cross-references

- [backend-architect](/stacks/supabase/backend-architect/) — service-role discipline in Edge Functions
- [database-architect](/stacks/supabase/database-architect/) — RLS performance + helper functions
- [frontend-architect](/stacks/supabase/frontend-architect/) — cookie session handling
- [saas-architect](/stacks/supabase/saas-architect/) — multi-tenancy modeling on RLS
- [Supabase Stack index](/stacks/supabase/) — what changed in 2025-2026
