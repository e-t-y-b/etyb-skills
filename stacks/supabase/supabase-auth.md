---
title: Supabase Auth
description: The identity layer — sign-in methods, JWT, Auth Hooks, MFA, SSO/SCIM, custom claims. GoTrue under the hood.
product:
  name: Supabase Auth
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect, frontend-architect, saas-architect]
  authoritative_url: https://supabase.com/docs/guides/auth
  notes: "Auth Hooks (Send Email/SMS, Custom Access Token, MFA, Password), anonymous sign-ins, third-party auth (Clerk/Auth0/Firebase/Cognito), MFA factor types, and JWKS/RS256 verification all expanded 2024-2026."
---

## What it is

Supabase Auth is a managed identity service (GoTrue under the hood) that issues JWTs, manages sessions, and handles sign-up/sign-in/recovery flows. It writes to the `auth.*` schema, which you never modify directly. The JWT it issues is what RLS evaluates against.

Source: [Supabase Auth docs](https://supabase.com/docs/guides/auth).

## When to use

Supabase Auth is the default for any project on Supabase. Reach for an alternative IdP only when:

- **You already invested in Clerk / Auth0 / Cognito / Firebase.** Use **third-party auth** — Supabase still issues a JWT bound to the third-party identity, and RLS works as expected.
- **You need WorkOS-style enterprise features (SAML SSO + SCIM) before Team tier.** WorkOS-direct may be cheaper at low scale.
- **You're building a B2C app where the IdP is the OS (Apple/Google).** Use OAuth providers, not separate identity.

For B2B SaaS with Supabase Auth: it scales from email/password through SSO + SCIM as you tier up.

## 2025-2026 currency anchors

- **Anonymous sign-ins** (`signInAnonymously()`) — users get a real UUID and can be scoped by RLS like any other user. Convert to permanent account via `linkIdentity`.
- **Auth Hooks** (since 2024) — five hook points:
  - **Custom Access Token Hook** — modify JWT claims at issue time. The right place to inject `org_id`, `role`, `plan`.
  - **Send Email Hook** — replace Supabase's default email sender with your own SMTP or Edge Function.
  - **Send SMS Hook** — same for SMS.
  - **MFA Verification Attempt Hook** — observe/audit MFA attempts.
  - **Password Verification Attempt Hook** — observe password attempts (lockout on N failures).
- **MFA factor types**: TOTP, SMS, **WebAuthn/Passkey** (the right strong factor).
- **AAL (Authenticator Assurance Level)** in the JWT — `aal1` (single factor) vs `aal2` (MFA verified). Use in RLS for step-up auth.
- **Third-party auth** (Clerk, Auth0, Firebase, Cognito) — Supabase issues an RLS-aware JWT bound to an external IdP.
- **JWKS / RS256** — new projects default to RS256 with rotation via JWKS. Verify externally via `https://<project>.supabase.co/auth/v1/.well-known/jwks.json`.
- **SSO + SCIM** is **Team / Enterprise tier**. SAML config via Studio; WorkOS-backed.

## Patterns and anti-patterns

### Patterns

**Use `getUser()` not `getSession()` for auth gates.** `getUser()` re-verifies the token against the auth service; `getSession()` reads from the cookie without verification (faster, but stale).

**Custom Access Token Hook for multi-tenant context:**

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
  select m.org_id, m.role
  into v_org_id, v_role
  from public.memberships m
  join public.user_settings us on us.user_id = m.user_id
  where m.user_id = uid and m.org_id = us.active_org_id;

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

Then RLS reads `(select auth.jwt() ->> 'org_id')` — O(1) instead of joining through memberships.

**Step-up auth via AAL claim:**

```sql
create policy "AAL2 required for billing" on public.billing
  for all using ( (select auth.jwt() ->> 'aal') = 'aal2' );
```

Browse at AAL1, mutate at AAL2.

**Profile auto-create on `auth.users` insert:**

```sql
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

**Enable leaked-password protection** in Studio → Authentication → Policies. Supabase checks Have-I-Been-Pwned on sign-up and sign-in. Set the response to **reject**, not warn.

**Always configure custom SMTP for production.** The default sender is dev-only, rate-limited, and trains users to expect a generic Supabase domain.

### Anti-patterns

- **`getSession()` for auth gates.** It reads from the cookie without verifying; replay attacks work.
- **SMS as the only second factor.** SIM swap is real. Pair with WebAuthn/TOTP for any real MFA.
- **Storing role / org membership in client state instead of the JWT.** Anyone can change client state; the JWT is signed.
- **Adding columns to `auth.users`.** Forbidden — the table is managed. Use `public.profiles` linked by FK.
- **`SECURITY DEFINER` triggers on `auth.users` without `SET search_path = ''`.** Same privilege escalation risk as any other definer function.
- **Trusting `metadata` blindly in webhooks.** Stripe metadata, for example, was set by your code at Checkout time; cross-reference with the customer ID, not just `metadata.org_id`.

## Gotchas

- **JWT lifetime defaults to 1 hour.** Custom claims (org_id, role) are stale until next refresh. Force a session refresh on the client when membership changes, or shorten the token lifetime.
- **`emailRedirectTo` / `redirectTo` must be in the allow-list** in Studio → Authentication → URL Configuration. Otherwise OAuth and magic-link callbacks fail silently.
- **OAuth callback exchanges a code, not a token.** Implement the `/auth/callback` route that calls `exchangeCodeForSession(code)` server-side. See [@supabase/ssr](/stacks/supabase/supabase-ssr/).
- **`auth.uid()` in a non-authenticated context returns NULL.** Anonymous sign-ins return a real UUID; truly unauthenticated requests are NULL.
- **`signOut()` is local by default.** Use `{ scope: "global" }` to revoke all sessions across devices.
- **CAPTCHA on sign-up is not on by default.** Enable hCaptcha or Turnstile in Studio — the sign-up flow is a spam vector without it.
- **Custom Access Token Hook runs on every token issue, including refresh.** Keep it cheap (single join, indexed) — slow hooks degrade every refresh latency.
- **SSO/SCIM is Team/Enterprise.** Don't promise SSO to enterprise customers on a free or Pro tier.

## Cross-references

- [@supabase/ssr](/stacks/supabase/supabase-ssr/) — cookie-based session handling
- [supabase-js](/stacks/supabase/supabase-js/) — client-side auth flows
- [security-engineer role view](/stacks/supabase/security-engineer/) — hardening playbook
- [saas-architect role view](/stacks/supabase/saas-architect/) — onboarding, invites, SSO, tenancy
- [Row-Level Security](/stacks/supabase/row-level-security/) — the consumer of every JWT claim
- Supabase docs: [Auth guide](https://supabase.com/docs/guides/auth), [Auth Hooks](https://supabase.com/docs/guides/auth/auth-hooks), [MFA](https://supabase.com/docs/guides/auth/auth-mfa)
