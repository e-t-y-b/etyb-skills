---
title: API Versions + Pinning
description: Every Stripe account is auto-pinned to a version on first request. Same code against two accounts can return different JSON. Pin explicitly.
product:
  name: API Versions + Pinning
  stack: stripe
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, security-engineer, fintech-architect]
  authoritative_url: https://docs.stripe.com/api/versioning
  notes: "Common 2026 production debugging surface — accounts stuck on 2019 versions, unaware. Pin in SDK constructor; pin webhook endpoints per-endpoint."
---

## What it is

Stripe's API is versioned by date (e.g., `2025-11-15.acacia`). Every Stripe account is **auto-pinned** to a version on its first API call. The version determines:

- The shape of API request/response JSON
- The shape of webhook event payloads delivered to webhook endpoints (unless an endpoint specifies its own `api_version`)
- Default behavior for fields like `payment_method_types` vs `automatic_payment_methods`

**The same SDK code can produce different JSON depending on the account's pin.** A new account today gets `2025-11-15.acacia`; an account created in 2019 is still pinned to a 2019 version unless someone explicitly upgraded.

Canonical reference: [docs.stripe.com/api/versioning](https://docs.stripe.com/api/versioning). Upgrades guide: [docs.stripe.com/upgrades](https://docs.stripe.com/upgrades).

## When to use

Always pin explicitly in code, regardless of the account's pin. The pin in the SDK constructor decouples your code from per-account version drift.

## 2025-2026 currency anchors

- **`2025-11-15.acacia`** is current as of this Stack's last verification.
- **Versions ship every 2-4 months** as named releases, with smaller changelog entries weekly.
- **2026 common debugging surface**: accounts stuck on 2019 versions, the same code returning different JSON in dev vs prod.

## Patterns

### Pin explicitly in the SDK constructor

```typescript
import Stripe from 'stripe';
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-11-15.acacia',
});
```

```python
stripe.api_version = '2025-11-15.acacia'
```

```ruby
Stripe.api_version = '2025-11-15.acacia'
```

When pinned in code, your code's expected request/response shape is fixed. If the account is on a newer version, Stripe down-converts to your pinned version. If older, Stripe up-converts (can fail in subtle ways — missing fields you expect).

### Check the account's pin

[Workbench](/stacks/stripe/stripe-workbench/) → Developers → API version. Shows what the account is pinned to. Critical when debugging "but my code is right" — your dev account, staging account, and production account can be on three different versions.

### Pin webhook endpoints per-endpoint

Each webhook endpoint has its own `api_version` field in Dashboard → Workbench → Webhooks. Set this to match your handler's code. Otherwise the account-level pin governs and you can get a different event shape than your handler expects.

### Upgrade discipline

Treat upgrades like a database migration:

1. Read changelog entries between current pin and target version ([docs.stripe.com/upgrades](https://docs.stripe.com/upgrades))
2. Build a list of breaking changes affecting your code
3. Upgrade in a sandbox account first (or test mode of the upgrade flow)
4. Roll out to staging account, run integration tests
5. Pin webhook endpoints to new version, deploy code, then promote account pin

Don't upgrade for cosmetic reasons. Upgrade when:
- A feature you need is gated to a newer version
- You're far enough behind that customer-support help requires it
- A security or behavior fix requires the newer version

## Anti-patterns

- **Not pinning in code, relying on the account pin.** Means your code's expected shape varies by account. Test mode account on one version, live on another, support team finds it differs across customers.
- **Upgrading "silently" via SDK auto-detection.** No — pin explicitly.
- **Forgetting to pin webhook endpoints.** Code's apiVersion is `2025-11-15.acacia`; endpoint defaults to the account pin. Events arrive in older shape; handler fails on missing fields.
- **Hardcoding "the path is `sub.latest_invoice.payment_intent.client_secret`"** — the exact shape depends on version. Explicitly `expand` and check.
- **Upgrading without reading the changelog.** Breaking changes are documented.

## Gotchas

- **Three pin layers**: SDK constructor pin, account-level pin, per-webhook-endpoint pin. All can differ. Source of "but my code is right" mysteries.
- **Stripe's auto-conversion** between versions handles most differences, but subtle ones (field renames, type changes) can produce surprising output.
- **Old accounts on old versions** — common in 2026. Account created in 2019 is still on a 2019 pin unless someone explicitly upgraded.
- **Connect accounts** can inherit the platform's version pin or have their own — verify.

## Cross-references

- [Stripe Workbench](/stacks/stripe/stripe-workbench/) — where to check the account's pin
- [Webhooks](/stacks/stripe/webhooks/) — per-endpoint version pinning
- [Payment Intents](/stacks/stripe/payment-intents/) — JSON shape varies by version
- [Stripe Billing](/stacks/stripe/stripe-billing/) — Subscription response shape varies (especially `latest_invoice.payment_intent`)
- [Stripe Connect](/stacks/stripe/stripe-connect/) — version drift hits Connect platforms hardest
- [backend-architect on Stripe](/stacks/stripe/backend-architect/)
- Authoritative: [docs.stripe.com/api/versioning](https://docs.stripe.com/api/versioning), [docs.stripe.com/upgrades](https://docs.stripe.com/upgrades)
