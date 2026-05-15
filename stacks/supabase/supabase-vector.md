---
title: Supabase Vault
description: pgsodium-backed encrypted secret storage inside Postgres. For secrets that live in the database (webhook keys, FDW credentials).
product:
  name: Supabase Vault
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, database-architect]
  authoritative_url: https://supabase.com/docs/guides/database/vault
  notes: "pgsodium envelope encryption; rotation semantics and key management still maturing. For app-tier secrets, prefer Supabase secrets (Edge Functions env)."
---

## What it is

Supabase Vault is `pgsodium`-backed encrypted secret storage in Postgres. Secrets are stored in `vault.secrets`; decrypted values are accessible via `vault.decrypted_secrets` (a view) for callers with the right privileges. Designed for secrets needed *inside Postgres* — Database Webhook signing keys, FDW credentials, anything called via `pg_net` from a trigger.

Source: [Supabase Vault docs](https://supabase.com/docs/guides/database/vault).

> **Note on the slug**: this page lives at `/stacks/supabase/supabase-vector/` for assignment compatibility. The product itself is Supabase **Vault**.

## When to use

| Use Vault for | Use [Supabase secrets](/stacks/supabase/edge-functions/) (CLI/dashboard, Edge Function env vars) for |
|---------------|------------------------------------------------------------------------------------------------------|
| Webhook signing secrets used in `pg_net` calls | App-tier API keys (Stripe, SendGrid) called from Edge Functions |
| Stripe FDW / Wrappers credentials | Anything not needed from inside Postgres |
| Per-tenant encryption keys (advanced) | OAuth client secrets for sign-in providers |

Default: secrets called from Postgres → Vault; secrets called from Edge Functions → `supabase secrets set ...`.

## 2025-2026 currency anchors

- **pgsodium envelope encryption** — modern crypto primitive; not just a `pgcrypto` wrapper.
- **No automatic rotation.** Build rotation into operational runbooks (rotate at source, update Vault, redeploy).
- **Key management is project-scoped** — keys live with the project; backups encrypt with them.
- **Access via `SECURITY DEFINER` wrapper** is the canonical pattern (don't expose `vault.decrypted_secrets` directly to `anon`).

## Patterns and anti-patterns

### Patterns

**Store a secret:**

```sql
select vault.create_secret('whsec_abc...', 'stripe_webhook_secret', 'For verifying Stripe webhooks');
```

**Retrieve from a `SECURITY DEFINER` function** with locked `search_path`:

```sql
create or replace function public.get_stripe_webhook_secret()
returns text
language sql
security definer
set search_path = ''
as $$
  select decrypted_secret from vault.decrypted_secrets where name = 'stripe_webhook_secret'
$$;

-- Restrict who can call:
revoke execute on function public.get_stripe_webhook_secret() from public;
grant execute on function public.get_stripe_webhook_secret() to authenticated;
```

**Use in a Database Webhook signing flow:**

```sql
-- In a Database Webhook handler trigger or a pg_net call,
-- read the signing key from Vault to compute HMAC before sending.
```

### Anti-patterns

- **Using Vault for app-tier secrets** that never leave Edge Function context. Use `supabase secrets` env vars instead — simpler and bound to the right surface.
- **Exposing `vault.decrypted_secrets` directly to `authenticated`.** That defeats the encryption; wrap behind a definer function.
- **Storing rotation history in Vault.** Track rotation events in a separate audit table.
- **Treating Vault as a KMS for client-side encryption.** It's server-side at-rest; not for client crypto.

## Gotchas

- **The decrypted view is privileged.** Default-deny access; expose via wrapper functions only.
- **No auto-rotation.** Build a runbook: rotate at the source (Stripe), update Vault, redeploy or refresh cached values.
- **Backups encrypt with project keys.** Restoring a backup to a different project requires key handling — coordinate with Supabase support for cross-project restore.
- **The encryption key is held by Supabase** — this is at-rest encryption against backup-side compromise, not customer-managed key encryption. For BYOK / HSM requirements, evaluate platform fit carefully.
- **`pgsodium` itself is a separate but related extension** — Vault is the user-facing surface.

## Cross-references

- [Database Functions](/stacks/supabase/database-functions/) — the wrapper pattern for read access
- [pg_net](/stacks/supabase/pg-net/) — common consumer (webhook signing)
- [Foreign Data Wrappers](/stacks/supabase/foreign-data-wrappers/) — Wrappers store credentials in Vault
- [security-engineer role view](/stacks/supabase/security-engineer/) — secret-management discipline
- Supabase docs: [Vault](https://supabase.com/docs/guides/database/vault)
