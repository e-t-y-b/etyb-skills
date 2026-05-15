---
title: saas-architect on Supabase
description: Multi-tenancy on RLS, JWT shape via Custom Access Token Hook, Stripe FDW + webhooks, SSO/SCIM, tenant lifecycle, branching for data migrations.
role_overlay:
  role: saas-architect
  stack: supabase
  last_verified_on: "2026-05-14"
  products_covered: [row-level-security, supabase-auth, foreign-data-wrappers, edge-functions, branching, supabase-storage, postgres, database-functions, migrations]
---

## Role briefing

You're saas-architect on a Supabase engagement. The platform is well-suited to multi-tenant B2B SaaS — [RLS](/stacks/supabase/row-level-security/) is the isolation primitive, [Auth](/stacks/supabase/supabase-auth/) handles sign-ups + SSO, [Storage](/stacks/supabase/supabase-storage/) gives you per-tenant file scoping, and [Branching](/stacks/supabase/branching/) gives you preview environments per PR. Your job is to choose the tenancy model, design the JWT shape that lets RLS scale, model billing integration (Stripe FDW for reads + webhooks for writes), and decide when project-per-tenant beats schema-per-tenant beats single-schema.

What's distinctive vs. a generic saas-architect role: you don't have to invent multi-tenancy mechanics — RLS is right there. The work is **modeling tenancy into the JWT** so policies are O(1), choosing which tenancy pattern fits, and designing the Stripe integration that doesn't drive read traffic to the Stripe API on every page load.

## Decision frameworks specific to saas-architect on Supabase

### Tenancy model

```
Start: shared schema + RLS

Does any tenant exceed average by 100x in row count?
  Yes → consider partitioning that tenant's tables; still shared schema.

Compliance / sovereignty rules require "separate databases" semantics?
  Yes → project per tenant.
  No → stay shared.

Tenants need customer-specific schemas (custom fields beyond JSONB)?
  Yes → schema per tenant.
  No → stay shared (JSONB for custom fields).

<100 tenants AND each paying $1k+/mo?
  Yes → project per tenant is viable.
  No → stay shared.
```

The honest answer: **shared schema + RLS, JSONB for custom fields, partition heavy tenants when they hurt**. Most teams over-engineer this early.

### Tenancy comparison

| Pattern | Pros | Cons |
|---------|------|------|
| **Shared schema + RLS** | Single DB to operate; cross-tenant analytics is SQL; cheap up to tens of millions of rows per tenant | All tenants share index hot spots; bad query from one affects all |
| **Schema per tenant** | Stronger isolation; per-tenant `pg_dump`; compliance-friendly | Migrations apply N times; `SET search_path` painful with transaction pooler; cross-tenant analytics is UNION ALL |
| **Project per tenant** | Strongest isolation; per-tenant billing alignment; HIPAA-friendly | Operationally heavy via Management API; no cross-tenant queries; per-project minimum cost |

### Materialize org_id into JWT

Instead of joining through memberships in every RLS policy, inject `org_id` at sign-in via the **Custom Access Token Hook**:

```sql
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb language plpgsql stable as $$
declare
  claims jsonb := event->'claims';
  uid uuid := (event->>'user_id')::uuid;
  v_org_id uuid; v_role text;
begin
  select m.org_id, m.role into v_org_id, v_role
  from public.memberships m
  join public.user_settings us on us.user_id = m.user_id
  where m.user_id = uid and m.org_id = us.active_org_id;

  if v_org_id is not null then
    claims := jsonb_set(claims, '{org_id}', to_jsonb(v_org_id::text));
    claims := jsonb_set(claims, '{org_role}', to_jsonb(v_role));
  end if;

  event := jsonb_set(event, '{claims}', claims);
  return event;
end; $$;

grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
```

Then policies read `(select auth.jwt() ->> 'org_id')` — O(1) instead of join.

**Trade-off**: changing org membership doesn't take effect until next JWT refresh. Force `supabase.auth.refreshSession()` on the client when membership changes, or accept eventual consistency.

### Multi-org users — the active-org switcher

JWT carries one org_id at a time. Switcher pattern:
1. UI shows "Acme Corp ▾" dropdown.
2. User picks → API call to `set_active_org(org_id)`.
3. Backend updates `user_settings.active_org_id`.
4. Client calls `supabase.auth.refreshSession()`.
5. Custom Access Token Hook reads new active_org_id and embeds it.

One extra round-trip on switch beats embedding all orgs into every JWT.

## Product references

- [Row-Level Security](/stacks/supabase/row-level-security/) — the isolation primitive; with org_id materialized into JWT, policies are O(1).
- [Supabase Auth](/stacks/supabase/supabase-auth/) — Custom Access Token Hook for custom claims, MFA, SSO+SCIM (Team/Enterprise).
- [Foreign Data Wrappers](/stacks/supabase/foreign-data-wrappers/) — Stripe FDW for read-side dashboards; not for write paths.
- [Edge Functions](/stacks/supabase/edge-functions/) — Stripe webhook handlers, invite acceptance, tenant provisioning.
- [Branching](/stacks/supabase/branching/) — preview environments for tenant data migrations.
- [Supabase Storage](/stacks/supabase/supabase-storage/) — per-tenant folder scoping `<org_id>/...`.
- [Database Functions](/stacks/supabase/database-functions/) — `handle_new_user` trigger to auto-create profiles.
- [Migrations](/stacks/supabase/migrations/) — branch-then-merge for tenant data migrations.

## Onboarding flow

Canonical sign-up → first-org:
1. User signs up via [Supabase Auth](/stacks/supabase/supabase-auth/). `auth.users` row created.
2. Trigger on `auth.users` insert creates `public.profiles` row.
3. First UI step after sign-up: "Create your organization" → Edge Function → creates `orgs` + `memberships` rows.
4. Active-org-switcher points to the new org.
5. JWT refresh picks up org_id.

```sql
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, new.raw_user_meta_data->>'display_name')
  on conflict do nothing;
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

## Invites

```sql
create table public.invites (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id),
  email text not null,
  role text not null default 'member',
  token text not null unique default encode(gen_random_bytes(32), 'hex'),
  expires_at timestamptz not null default (now() + interval '7 days'),
  used_at timestamptz
);
```

Flow: admin POSTs `/api/invites` → email sent → recipient clicks → signs up/in → `/api/accept-invite` validates token → creates `memberships` row → marks used.

Don't do this in pure Auth Hooks — too multi-step.

## Billing — Stripe integration patterns

### Stripe FDW (read-side)

Read Stripe data as Postgres foreign tables. Use for dashboards joining `orgs` + subscription state.

### Webhook handling (write-side)

Every Stripe webhook → Edge Function:

```ts
import Stripe from "npm:stripe@14.5.0";
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!);
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

Deno.serve(async (req) => {
  const signature = req.headers.get("stripe-signature")!;
  const body = await req.text();
  let event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    return new Response(`Webhook signature verification failed`, { status: 400 });
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  switch (event.type) {
    case "customer.subscription.created":
    case "customer.subscription.updated":
      await admin.from("subscriptions").upsert({
        stripe_subscription_id: event.data.object.id,
        org_id: event.data.object.metadata.org_id,
        status: event.data.object.status,
        current_period_end: new Date(event.data.object.current_period_end * 1000),
      });
      break;
  }
  return new Response("ok");
});
```

Rules:
1. **Always verify the signature.** `stripe.webhooks.constructEvent`.
2. **Idempotent.** Stripe retries; dedupe by `event.id`.
3. **Don't trust metadata blindly.** `metadata.org_id` was set by your code at Checkout time; cross-reference with `customer.id`.
4. **Reply 200 quickly** (<1s). Push heavy work to [Queues](/stacks/supabase/supabase-queues/).

### Entitlements materialized

Don't query Stripe for "can this user do X?" Materialize:

```sql
create table public.entitlements (
  org_id uuid primary key references public.orgs(id),
  plan text not null,
  seats int not null default 1,
  features jsonb not null default '{}',
  active_until timestamptz,
  updated_at timestamptz default now()
);
```

The Stripe webhook updates `entitlements` on subscription change. App reads `entitlements` in RLS or in application code.

### Plan-based RLS gating

```sql
create policy "pro features for pro orgs" on public.advanced_analytics
  for select using (
    org_id in (
      select org_id from public.entitlements
      where org_id = ((select auth.jwt() ->> 'org_id')::uuid)
        and plan in ('pro', 'team', 'enterprise')
    )
  );
```

Or embed plan into the JWT via Custom Access Token Hook for cheaper evaluation.

## SSO and SCIM (Team/Enterprise)

WorkOS-backed (as of 2026). For B2B SaaS targeting enterprises, this is table stakes.

**Domain-bound auto-org-assignment** via a hook:

```sql
create or replace function public.auto_assign_org_by_domain(event jsonb)
returns jsonb language plpgsql stable as $$
declare
  email_domain text := split_part((event->>'email')::text, '@', 2);
  v_org_id uuid;
begin
  select id into v_org_id from public.orgs where sso_email_domain = email_domain limit 1;
  if v_org_id is not null then
    insert into public.memberships (user_id, org_id, role)
    values ((event->>'user_id')::uuid, v_org_id, 'member')
    on conflict (user_id, org_id) do nothing;
  end if;
  return event;
end; $$;
```

Be careful — don't let users self-assign by signing up with the right email if email isn't verified.

## Tenant lifecycle

### Suspending — flag, don't delete

```sql
alter table public.orgs add column suspended_at timestamptz;

create policy "no access for suspended orgs" on public.documents
  as restrictive
  for all using (
    not exists (
      select 1 from public.orgs
      where id = documents.org_id and suspended_at is not null
    )
  );
```

### Deletion (GDPR-compliant)

1. Mark `orgs.deletion_scheduled_at = now() + interval '30 days'`.
2. Confirmation email with "cancel deletion" link.
3. After 30 days, cron job hard-deletes tenant-scoped rows, memberships, Storage files under `<org_id>/`, and `auth.users` for users where this was their only org.
4. Log to a separate audit table that never gets deleted (no PII; just action + timestamp).

## Branching for tenant data migrations

When a schema change affects tenant data (column rename + backfill):
1. Open PR with the migration.
2. Branch created; preview hits new schema.
3. Integration tests against preview.
4. Verify idempotency + zero-downtime.
5. Merge → applies to main.

Destructive changes (drop column, drop table) → two-phase: phase 1 stops using; phase 2 drops in follow-up PR. Never combine.

## Cost model — what scales with tenants

| Cost | Scales with | Notes |
|------|-------------|-------|
| Postgres storage | Total data | One DB; cheap |
| Postgres compute | Concurrent query load | Tier up when CPU pegs |
| Edge Function invocations | Active tenants × usage | Cheap until very high scale |
| Storage (buckets) | Total uploads | Per-GB pricing |
| Bandwidth | Egress | Frontend CDN helps |
| Auth MAU | Monthly active users | Pricing has free + paid tiers |
| Realtime concurrent connections | Active users × subs | Multiplexing helps |

## 2025-2026 platform reset relevant to saas-architect

- **Custom Access Token Hook (since 2024)** — the right place for `org_id`, `role`, `plan` claims.
- **Branching (2024)** — preview branches per PR; merge replays migrations to main.
- **SSO + SCIM** is Team/Enterprise tier.
- **Third-party auth** (Clerk/Auth0/Firebase/Cognito) lets you keep an existing IdP and still get RLS-aware JWTs.
- **Stripe FDW** is mature for read-side dashboards.
- **Anonymous sign-ins** for try-before-signup, with `linkIdentity` to convert.
- **Realtime Authorization** matters when shipping multi-tenant collaboration features.

## Patterns the role applies

### TDD on tenancy

Every multi-tenant feature ships with a multi-user test:

```sql
-- two users in two different orgs
-- Test: user A creates row; user B cannot see it.
-- Test: user A invites user B; user B can now see it.
-- Test: org A suspended; user A cannot read.
```

Pattern lives in `tests/rls/multi_tenant_*.sql`.

### Verification

Before shipping multi-tenant feature: cross-user RLS test passes. Before shipping billing-gated feature: test with mocked entitlements at each plan level. Before suspension logic ships: suspended-org user sees exactly zero rows.

### Debugging

**"Customer's data is leaking to another tenant."** P0. Stop everything.

Hypothesis ladder:
1. RLS disabled (check `pg_tables.rowsecurity`).
2. `SECURITY DEFINER` function bypasses RLS.
3. Edge Function uses service_role + trusts user input for tenant_id.
4. View is `SECURITY DEFINER` (legacy default).
5. JWT `org_id` is wrong (Custom Access Token Hook bug).

Notify customer, file incident, rotate keys touched in remediation.

**"Slow after onboarding a large tenant."**
- Large tenant's query patterns scan indexes poorly.
- `pg_stat_statements` for hot queries.
- Consider partitioning by `org_id`.
- Consider giving large tenant its own project (escalate to project-per-tenant for the outlier).

## Cross-references

- [database-architect](/stacks/supabase/database-architect/) — RLS performance, helper functions, indexes
- [backend-architect](/stacks/supabase/backend-architect/) — Edge Functions for webhooks + workers
- [security-engineer](/stacks/supabase/security-engineer/) — Custom Access Token Hook, MFA, SSO hardening
- [frontend-architect](/stacks/supabase/frontend-architect/) — org switcher + JWT refresh on client
- [Supabase Stack index](/stacks/supabase/) — what changed in 2025-2026
