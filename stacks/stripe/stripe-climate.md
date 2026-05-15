---
title: Stripe Climate
description: Programmatic carbon removal contributions — Climate Orders API. Small, stable surface.
product:
  name: Stripe Climate
  stack: stripe
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, saas-architect]
  authoritative_url: https://docs.stripe.com/climate
  notes: "Small API surface (Climate Orders), stable. Outside core engineering scope for most teams."
---

## What it is

Stripe Climate lets businesses contribute a percentage of revenue to carbon removal projects vetted by Stripe. The API surface is small — Climate Orders — and stable.

Canonical reference: [docs.stripe.com/climate](https://docs.stripe.com/climate).

## When to use

For most engineering teams, Climate is configured in Dashboard ("contribute X% of revenue") and doesn't require code. The API exists for programmatic orders if you want per-transaction contributions visible to your customers ("this purchase removed X tons of carbon").

## 2025-2026 currency anchors

- **Surface stable.** Climate Orders + reporting endpoints. No major shifts.

## Patterns

### Dashboard-configured contribution

Most teams: enable in Dashboard, Stripe automatically deducts the configured percentage from each charge. No code changes.

### Programmatic orders

```typescript
const order = await stripe.climate.orders.create({
  amount: 100,  // $1.00 contribution
  currency: 'usd',
  metadata: { related_charge: chargeId },
});
```

Surface the result in your UI ("you removed X tons of carbon").

## Anti-patterns

- **Building elaborate Climate integration without a real product reason.** It's a small surface; don't over-engineer.

## Gotchas

- **Contributions are non-refundable** to your account in most cases — they fund the project.
- **Reporting** — Stripe provides aggregate impact reports in Dashboard.

## Cross-references

- Authoritative: [docs.stripe.com/climate](https://docs.stripe.com/climate)
