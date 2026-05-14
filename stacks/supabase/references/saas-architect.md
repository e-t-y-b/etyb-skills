---
role: saas-architect
stack: supabase
last_verified_on: "2026-05-14"
---

# Supabase Overlay — saas-architect

You are saas-architect on a Supabase engagement. The platform is well-suited to multi-tenant B2B SaaS — RLS is the isolation primitive, Auth handles sign-ups + SSO, Storage gives you per-tenant file scoping, and Branching gives you preview environments per PR. Your job is to choose the tenancy model, design the JWT shape that lets RLS scale, model billing integration (Stripe FDW for reads + webhooks for writes), and decide when project-per-tenant beats schema-per-tenant beats single-schema.

**Currency:** verified against Supabase docs (Auth Hooks, Branching, SSO/SCIM availability, Custom Access Token Hook) through **2026-05-14**. SSO + SCIM is **Team / Enterprise tier** as of 2026.

## Decision framework — tenancy model

Three patterns; pick one per app, not one per feature.

### Pattern A: Shared schema + RLS (the default)

Every table carries a `tenant_id` (or `org_id`); RLS scopes queries to tenants the user belongs to.

```sql
create table public.documents (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.orgs(id),
  -- ...other columns
);

alter table public.documents enable row level security;

create policy "members access org documents" on public.documents
  for select using (
    org_id = ((select auth.jwt() ->> 'org_id')::uuid)
  );
```

**Pros:**
- Single database to operate, back up, migrate, monitor.
- Cross-tenant analytics is a SQL query, not a federation problem.
- Cheap up to tens of millions of rows per tenant.

**Cons:**
- All tenants share index hot spots.
- A bad query from one tenant affects all (until you isolate workloads).
- Compliance reviewers sometimes don't love it.

**When it fits:** 95% of B2B SaaS. Default. Switch only if a concrete reason forces a switch.

### Pattern B: Schema per tenant

Each tenant gets its own Postgres schema (`tenant_acme.documents`, `tenant_globex.documents`).

```sql
-- Provisioning a new tenant:
create schema if not exists tenant_acme;
-- Copy table DDL from template; or use pg_dump-style replication.
```

**Pros:**
- Stronger isolation at the data-layer level. A bug in app code that forgets a `tenant_id` filter has less blast radius.
- Per-tenant backup/restore is a `pg_dump` of the schema.
- Some compliance reviewers prefer it.

**Cons:**
- Migrations apply N times (once per tenant schema). Drift is real.
- Connection pooler interaction: on transaction pooler, `SET search_path` doesn't persist — you must qualify every reference or use `SET LOCAL` inside a transaction.
- Cross-tenant analytics requires UNION ALL across schemas, which is operationally annoying.

**When it fits:** mid-to-large B2B where tenants have noticeably different data shapes (one tenant has 1000 rows, another has 100M) AND compliance / sovereignty pushes for harder isolation.

### Pattern C: Project per tenant

Each tenant is a separate Supabase project — its own Auth, DB, Storage, billing.

**Pros:**
- Strongest isolation. Each tenant is a separate database, separate API surface.
- HIPAA / financial-sovereignty cases that demand "tenant data never co-locates" are satisfied.
- Per-tenant billing aligns with per-project cost.

**Cons:**
- Operationally heavy. Migrations applied N times via the Management API. Schema drift is a real concern.
- No native cross-tenant queries.
- Per-project minimum cost adds up; not viable for free-tier SaaS.

**When it fits:** enterprise / ISV / white-label where each "tenant" is genuinely a separate customer environment AND the customer count is in dozens-to-hundreds, not thousands.

### The decision tree

```
Start: shared schema + RLS

Does any tenant exceed the average by 100x (in row count)?
  Yes → consider partitioning that tenant's tables; still shared schema.

Do compliance / sovereignty rules require "separate databases" semantics?
  Yes → project per tenant.
  No → stay shared.

Will tenants have customer-specific schemas (custom fields beyond a JSONB column)?
  Yes → schema per tenant.
  No → stay shared (use JSONB for custom fields).

Are there <100 tenants AND each is paying $1k+/mo?
  Yes → project per tenant is viable.
  No → stay shared.
```

The honest answer is **shared schema + RLS, JSONB for custom fields, partition heavy tenants when they hurt**. Most teams over-engineer this early.

## RLS-based multi-tenancy in practice

### Get the org_id into the JWT

Don't make every query do a `select org_id from memberships where user_id = (select auth.uid())`. Materialize it into the JWT at sign-in via the Custom Access Token Hook:

```sql
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
as $$
declare
  claims jsonb := event->'claims';
  uid uuid := (event->>'user_id')::uuid;
  v_org_id uuid;
  v_role text;
begin
  -- For users with a single org, just inject it.
  -- For multi-org users, pick the "active" org (could be stored in a user_settings table).
  select m.org_id, m.role
  into v_org_id, v_role
  from public.memberships m
  join public.user_settings us on us.user_id = m.user_id
  where m.user_id = uid
    and m.org_id = us.active_org_id;

  if v_org_id is not null then
    claims := jsonb_set(claims, '{org_id}', to_jsonb(v_org_id::text));
    claims := jsonb_set(claims, '{org_role}', to_jsonb(v_role));
  end if;

  event := jsonb_set(event, '{claims}', claims);
  return event;
end;
$$;

grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
```

Then every RLS policy reads `(select auth.jwt() ->> 'org_id')` instead of joining through memberships. The result: O(1) policy evaluation.

**Trade-off**: changing org membership doesn't take effect until next JWT refresh. Mitigations:
- Force a session refresh on the affected user when their memberships change (`supabase.auth.refreshSession()` on the client).
- Accept eventual consistency for a 1-hour token lifetime.
- Shorten the token lifetime if instant propagation matters.

### Multi-org users — the "active org" switcher

For users who belong to multiple orgs, the JWT only carries one `org_id` at a time. The switcher pattern:

1. UI shows "Acme Corp ▾" with a dropdown.
2. User picks "Globex Corp" → API call to `set_active_org(org_id)`.
3. The backend updates `user_settings.active_org_id`.
4. Client calls `supabase.auth.refreshSession()` to get a new JWT.
5. The Custom Access Token Hook reads the updated active_org_id and embeds the new org_id.

The friction (one extra round-trip on org switch) is worth it to avoid embedding all orgs into every JWT (privacy + size + churn).

### Cross-org access — when admins need it

Some users (your own staff support agents, customer admins) need to operate across orgs.

**For your internal support team**: don't use the same Auth surface. Run a separate admin tool that uses service_role with strict audit logging. Every admin query is logged + reviewed.

**For customer-level admins (a user who legitimately belongs to multiple orgs)**: handle in the application UI — they see all orgs, pick one, the active-org flow above kicks in.

Don't try to model "super admin" in RLS. The cost is policy complexity for everyone.

## Onboarding flow

The canonical sign-up → first-org flow:

1. **User signs up via Supabase Auth.** Insert handled by Supabase; an `auth.users` row is created.
2. **Trigger on `auth.users` insert** creates a `public.profiles` row.
3. **First UI step after sign-up**: "Create your organization" → POST to an Edge Function → creates `orgs` row + `memberships` row binding user as `owner`.
4. **Active-org-switcher** points to the new org.
5. **JWT refresh** picks up the org_id.

```sql
-- Profile auto-create on auth.users insert
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, new.raw_user_meta_data->>'display_name')
  on conflict do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

The org-create step is a separate Edge Function call so you can validate org name uniqueness, kick off Stripe customer creation, send welcome email, etc.

### Inviting users to an org

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

create index invites_token_idx on public.invites (token);
```

Flow:
1. Org admin POSTs to `/api/invites` → row inserted → email sent (via Edge Function + your email provider).
2. Recipient clicks link with `?token=...`.
3. They sign up (if new) or sign in (if existing).
4. Frontend POSTs `/api/accept-invite` with the token.
5. Edge Function verifies the token, creates `memberships` row, marks invite used.

Don't try to do this in pure Auth Hooks. The flow is too multi-step and the failure modes (expired tokens, wrong email, etc.) deserve explicit handling.

## Billing — Stripe integration patterns

Supabase + Stripe is the dominant pairing. Two integration surfaces:

### Stripe FDW (read-side)

Source: [Wrappers framework](https://supabase.com/docs/guides/database/extensions/wrappers/stripe). Read Stripe data as Postgres foreign tables.

```sql
create extension if not exists wrappers;

create foreign data wrapper stripe_wrapper
  handler stripe_fdw_handler
  validator stripe_fdw_validator;

create server stripe_server
  foreign data wrapper stripe_wrapper
  options (
    api_key_id (select id from vault.secrets where name = 'stripe_secret_key'),
    api_url 'https://api.stripe.com/v1/'
  );

create foreign table stripe.customers (
  id text,
  email text,
  name text,
  created timestamp,
  attrs jsonb
)
  server stripe_server
  options ( object 'customers' );

create foreign table stripe.subscriptions (
  id text,
  customer text,
  status text,
  current_period_end timestamp,
  cancel_at_period_end bool,
  attrs jsonb
)
  server stripe_server
  options ( object 'subscriptions' );
```

Use for: dashboards joining your `orgs` table with Stripe subscription state. Don't use for: webhook event processing (latency is too high; rate limits hit you).

### Webhook handling (write-side)

For every Stripe webhook (subscription changes, payments succeeded/failed), use an Edge Function:

```ts
// supabase/functions/stripe-webhook/index.ts
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
    return new Response(`Webhook signature verification failed: ${err.message}`, { status: 400 });
  }

  // Use service role here because the user isn't the principal.
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
    case "invoice.payment_failed":
      // Mark org as past-due, notify admins
      break;
  }
  return new Response("ok");
});
```

Critical rules:
1. **Always verify the signature.** Stripe's `constructEvent` does this.
2. **Make webhook handling idempotent.** Stripe retries on non-2xx; you'll see duplicate events. Use the event's `id` as a dedupe key.
3. **Don't trust the metadata blindly.** The `metadata.org_id` was set by your code at Checkout time; if a user can manipulate it, you have a problem. Cross-reference with the customer's `email` or `customer.id` on file.
4. **Reply 200 quickly.** Push heavy work to a Queue + worker; the webhook handler should be <1s. Stripe times out at ~20s.

### Tying customers to orgs

The right shape: `orgs.stripe_customer_id` is the durable link. On org creation:

```ts
const customer = await stripe.customers.create({
  email: ownerEmail,
  name: orgName,
  metadata: { org_id: org.id, supabase_user_id: user.id },
});
await admin.from("orgs").update({ stripe_customer_id: customer.id }).eq("id", org.id);
```

Then a `subscriptions` table tracks current subscription state — populated by webhooks.

### Entitlements

Don't query Stripe for "can this user do X?" on every request. Materialize entitlements into Postgres:

```sql
create table public.entitlements (
  org_id uuid primary key references public.orgs(id),
  plan text not null,                  -- 'free', 'pro', 'team', 'enterprise'
  seats int not null default 1,
  features jsonb not null default '{}',  -- per-feature flags
  active_until timestamptz,
  updated_at timestamptz default now()
);
```

The Stripe webhook updates `entitlements` on subscription change. The app reads `entitlements` in RLS or in application code. The Stripe FDW is for dashboards, not real-time gating.

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

Or for cheaper evaluation, embed plan into the JWT via the Custom Access Token Hook.

## SSO and SCIM

Supabase Team/Enterprise tier ships SAML SSO + SCIM (via WorkOS under the hood, as of 2026). For B2B SaaS targeting enterprises, this is table stakes.

### SAML SSO setup (conceptual)

1. In Supabase Studio → Authentication → Providers → SAML.
2. Add the customer's SAML config (IdP metadata URL or XML).
3. Generate a Supabase entity ID + ACS URL; send to customer for their IdP config.
4. Test sign-in: customer's user hits `https://<project>.supabase.co/auth/v1/sso/saml?domain=customer.com` → redirected to their IdP → returns with SAML assertion → Supabase issues a JWT.

### SCIM provisioning

When a customer's IdP creates a user, SCIM events flow to Supabase Auth. Wire your Custom Access Token Hook to pick up SCIM-provisioned users and bind them to the right org (typically based on email domain or SCIM `groups`).

### Domain-bound auto-org-assignment

```sql
-- When a user with email @customer.com signs in, auto-add them to the customer org:
create or replace function public.auto_assign_org_by_domain(event jsonb)
returns jsonb
language plpgsql
stable
as $$
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
end;
$$;
```

Trigger as a Custom Access Token Hook (with care — don't let users self-assign to other orgs by signing up with the right email if the email isn't verified).

## Edge Functions per tenant

Generally: **don't have per-tenant Edge Functions**. One function with tenant-id-aware logic is cleaner.

Exceptions where you might:
- Customer-specific business logic in regulated industries (one customer's processing pipeline differs materially from another's).
- White-label brand styling that's deeply baked into the function output.

If you go this route, deploy via the CLI from a multi-project repo, or use the Management API to deploy functions to a per-tenant project.

## Branching for tenant data migrations

When you ship a schema change that affects tenant data (e.g., a column rename + backfill), use a database branch:

1. Open PR with the migration.
2. Branch is created; preview environment has the new schema.
3. Run integration tests against the preview.
4. Verify the migration is idempotent and zero-downtime.
5. Merge → migration applies to main.

For destructive changes (drop column, drop table), use a two-phase deploy:
- Phase 1: ship code that stops using the column.
- Phase 2 (later): drop the column.

Never combine in one PR.

## Cost model — what scales with tenants

Per-tenant costs to track:

| Cost | Scales with | Notes |
|------|-------------|-------|
| Postgres storage | Total data | One DB; not per-tenant. Cheap. |
| Postgres compute | Concurrent query load | Tier up when CPU pegs. |
| Edge Function invocations | Active tenants × usage | Cheap until very high scale. |
| Storage (Buckets) | Total uploads | Per-GB pricing. |
| Bandwidth | Egress | Frontend asset CDNs help. |
| Auth MAU | Monthly active users | Pricing has free + paid tiers. |
| Realtime concurrent connections | Active users × subscriptions | Multiplexing helps; many channels per connection. |

For Pro plan: budget against Postgres compute + bandwidth as the dominant costs at scale. Auth and Storage are typically smaller.

## Tenant lifecycle — onboarding, suspending, deleting

### Onboarding

Covered above. Include:
- Welcome email.
- Default seed data (one demo project, one sample document).
- Stripe customer creation (if billing).
- Email verification gate.

### Suspending

Don't delete — flag.

```sql
alter table public.orgs add column suspended_at timestamptz;
alter table public.orgs add column suspended_reason text;

-- Add a restrictive policy on every table:
create policy "no access for suspended orgs" on public.documents
  as restrictive
  for all using (
    not exists (
      select 1 from public.orgs
      where id = documents.org_id and suspended_at is not null
    )
  );
```

Then suspending is a single update; no data is lost; restoration is an update back.

### Deletion (GDPR-compliant)

When a customer asks to delete their data:

1. Mark `orgs.deletion_scheduled_at = now() + interval '30 days'`. Soft-delete window.
2. Send a confirmation email with a "cancel deletion" link.
3. After 30 days, a cron job hard-deletes:
   - All rows where `org_id = ?` across every tenant-scoped table.
   - The membership rows.
   - The `auth.users` rows for users where this was their only org.
   - Storage files under `<org_id>/`.
4. Log the deletion to a separate audit table that never gets deleted (you need to prove you complied).

The audit table doesn't contain PII; it contains the action + timestamp.

## Cross-references

- **RLS performance + helper functions** → [database-architect overlay](database-architect.md)
- **Edge Functions for webhook handling + worker pools** → [backend-architect overlay](backend-architect.md)
- **Custom Access Token Hook, MFA, SSO hardening** → [security-engineer overlay](security-engineer.md)
- **Frontend org switcher + JWT refresh** → [frontend-architect overlay](frontend-architect.md)

## Integration with always-on protocols

### TDD on tenancy

Every multi-tenant feature ships with a multi-user test:

```sql
-- Setup: two users in two different orgs
-- Test: user A creates a row; user B cannot see it.
-- Test: user A invites user B to org A; user B can now see it.
-- Test: org A is suspended; user A cannot read.
```

The pattern lives in `tests/rls/multi_tenant_*.sql`, run via `psql` against `supabase start`.

### Verification

Before shipping any multi-tenant feature: run the cross-user RLS test. Before shipping a billing-gated feature: run with mocked entitlements at each plan level. Before suspending logic ships: verify a suspended org's users see exactly zero rows.

### Debugging

Symptom: "Customer's data is leaking to another tenant."

Stop everything. The hypothesis ladder:
1. RLS is disabled on the affected table (run `select * from pg_tables where rowsecurity = false and schemaname = 'public';`).
2. A `SECURITY DEFINER` function bypasses RLS.
3. The Edge Function uses service_role and trusts user input for tenant_id.
4. A view is `SECURITY DEFINER` (default) and joins through tenant-scoped tables.
5. The JWT's `org_id` claim is wrong (e.g., the Custom Access Token Hook has a bug).

This is a P0 by default. Notify the customer, file an incident, rotate any keys touched in remediation.

Symptom: "Slow performance after onboarding a large tenant."

The large tenant's query patterns are scanning indexes that fit poorly. Diagnose:
- `pg_stat_statements` for that tenant's hot queries.
- Consider partitioning the affected tables by `org_id`.
- Consider giving the large tenant a project of their own (escalate to project-per-tenant for the one outlier).

The fix isn't usually "throw bigger compute at it" — it's understanding which query pattern broke and addressing it specifically.
