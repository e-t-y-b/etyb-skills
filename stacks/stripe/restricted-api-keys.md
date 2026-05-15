---
title: Restricted API Keys
description: "Least-privilege scoped Stripe keys (`rk_live_*`, `rk_test_*`). Recommended for any service-to-Stripe integration that doesn't need full secret-key power."
product:
  name: Restricted API Keys
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect]
  authoritative_url: https://docs.stripe.com/keys#limit-access-with-restricted-api-keys
  notes: "Service-to-Stripe integrations should use restricted keys. The `sk_live_*`-everywhere pattern is a security finding in 2026."
---

## What it is

Restricted Keys (`rk_live_*`, `rk_test_*`) are scoped Stripe API keys. They authenticate like secret keys but only grant the specific resource permissions you configure — read-only on charges, write on refunds up to $50, etc.

Canonical reference: [docs.stripe.com/keys#limit-access-with-restricted-api-keys](https://docs.stripe.com/keys#limit-access-with-restricted-api-keys).

## When to use

The 2024-2026 best practice: **any non-full-trust service should use a restricted key.**

| Service | Use |
|---------|-----|
| Internal analytics jobs (read charges/invoices/customers) | Restricted, read-only on those resources |
| Reconciliation workers (read-only comparison) | Restricted, read-only |
| Webhook handlers that fetch additional data | Restricted with read on Customers, etc. |
| Third-party SaaS integrations (Zapier, Make, n8n) | Restricted, scoped to operations they need |
| AI agents calling Stripe MCP | Restricted, scoped to read + approved writes |
| "Publish to Slack" workers listening to webhooks | Restricted, read access to charges/payouts |

The secret key (`sk_live_*`) is the all-powerful root credential. Almost no service-to-Stripe integration needs it. **Pasting `rk_live_*` into a Zapier integration is the kind of thing that costs $200k when it leaks.**

## When you actually need the secret key

- Creating PaymentIntents, SetupIntents, Subscriptions (full write to payments primitives)
- Connect platform-level operations (creating accounts, transfers, application fees)
- Anything in production that writes core money state

Even then: **per-service secret keys** if possible. Stripe allows multiple secret keys per account; one per service makes rotation easier.

## 2025-2026 currency anchors

- **GA + recommended** through 2024-2026. Adoption is uneven; flag teams still doing "one secret key for everything."
- **Restricted key UI in Workbench** — scoping is straightforward.
- **Stripe MCP for agents** — restricted keys are mandatory; production agent operations should not use the secret key.

## Patterns

### Scoping pattern

Start with "no permissions," add the minimum to make the service work, test, lock down. Don't start with "everything" and try to remove.

For an analytics job reading charges + invoices + customers:
- `charges: 'read'`
- `invoices: 'read'`
- `customers: 'read'`
- everything else: none

For a refund bot allowed to refund up to a cap:
- `refunds: 'write'`
- `charges: 'read'` (to look up before refunding)
- Application-level cap on amount (Stripe scoping doesn't have monetary caps; enforce in your code or proxy)

### Rotation

- **Restricted keys**: rotate quarterly minimum. Workbench surface makes it straightforward.
- **Secret keys**: rotate when an employee with access leaves; rotate on suspicion of leak; scheduled annual rotation for high-privilege keys.

Stripe allows multiple keys simultaneously, so zero-downtime rotation: create new, roll to one service at a time, verify, expire old.

### MCP / agent pattern

```typescript
// Production agent — restricted key, scoped tight
const stripe = new Stripe(process.env.STRIPE_AGENT_RESTRICTED_KEY!, {
  apiVersion: '2025-11-15.acacia',
});
```

The MCP/agent runs against the restricted key; cannot do anything not in scope. Add audit logging on every tool invocation.

## Anti-patterns

- **`sk_live_*` for everything.** Catastrophic if leaked. Use restricted keys for non-trust services.
- **`NEXT_PUBLIC_STRIPE_SECRET_KEY`** — does not exist as a concept. If you see it, rotate immediately. Only the publishable key belongs in client-side code.
- **Sharing keys across environments.** Test mode `rk_test_*` for staging; live mode `rk_live_*` per service for live.
- **Wide permissions "to make sure it works."** Start tight, add what's needed.

## Gotchas

- **No monetary caps in Stripe scoping.** Enforce dollar caps in your application or via a proxy. Restricted keys are resource-scoped, not amount-scoped.
- **Some operations require the secret key.** Connect platform-level operations, certain account-management calls. Test your restricted key against the operations your service actually needs.
- **Per-service rotation** — multiple `sk_live_*` keys per account allow per-service rotation without taking everything down.

## Cross-references

- [Stripe Workbench](/stacks/stripe/stripe-workbench/) — key management UI
- [Webhooks](/stacks/stripe/webhooks/) — signing secret is distinct from API keys
- [backend-architect on Stripe](/stacks/stripe/backend-architect/)
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — full key hygiene framework
- Authoritative: [docs.stripe.com/keys](https://docs.stripe.com/keys)
