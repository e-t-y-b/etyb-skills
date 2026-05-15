---
title: Stripe Tax
description: Automatic sales tax, VAT, GST calculation per jurisdiction. Expanded through 2025; Registration-as-a-Service in supported countries.
product:
  name: Stripe Tax
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [saas-architect, e-commerce-architect, backend-architect]
  authoritative_url: https://docs.stripe.com/tax
  notes: "Auto-calc expanded through 2025; Registration-as-a-Service available in 50+ jurisdictions. Doesn't cover every market (Brazil, India edge cases)."
---

## What it is

Stripe Tax automatically calculates sales tax, VAT, GST per jurisdiction at checkout or invoice creation, applies the right rate, and stores the tax line on the resulting Charge/Invoice. Integrates with [Checkout](/stacks/stripe/stripe-checkout/), [Payment Element](/stacks/stripe/payment-element/), and [Subscriptions](/stacks/stripe/stripe-billing/).

Canonical reference: [docs.stripe.com/tax](https://docs.stripe.com/tax).

## When to use

For most new builds in covered jurisdictions, don't roll your own tax tables. Stripe Tax handles:

- Sales tax for US states (varies by state)
- VAT for EU, UK, Norway, Switzerland, etc.
- GST for Canada, Australia, New Zealand, India, Singapore
- Sales tax for Mexico, Brazil (partial), and a growing list

For markets Stripe Tax doesn't fully cover — Brazil for certain transaction types, complex India transactions — Avalara or TaxJar layered on Stripe may still be needed.

## 2025-2026 currency anchors

- **Expanded jurisdictions** through 2025 — verify current coverage list.
- **Registration-as-a-Service** available in 50+ countries — Stripe registers your business in jurisdictions where you have nexus.
- **Reverse-charge / VAT-exempt B2B** handled automatically when customer has a valid VAT ID.
- **Adaptive Pricing integration** — when [Adaptive Pricing](/stacks/stripe/adaptive-pricing/) is enabled, Tax handles the local-currency line correctly.

## Patterns

### Enable on Subscription

```typescript
const sub = await stripe.subscriptions.create({
  customer: customer.id,
  items: [{ price: 'price_id' }],
  automatic_tax: { enabled: true },
});
```

### Enable on Checkout

```typescript
const session = await stripe.checkout.sessions.create({
  // ...
  automatic_tax: { enabled: true },
  billing_address_collection: 'required',  // tax calc needs customer address
});
```

### Customer tax info

Tax calc needs the customer's address. Either:
- Pre-fill via `customer` with `address` set
- Collect via Checkout (`billing_address_collection: 'required'`)
- Collect via [Customer Portal](/stacks/stripe/customer-portal/)

For B2B with reverse charge: collect VAT ID via Portal (`tax_id_collection.enabled: true`) or API (`customer.tax_ids.create`).

### Reverse charge

When a B2B customer in the EU has a valid VAT ID and is buying from a different EU country, the invoice should be reverse-charge (zero VAT; customer self-assesses). Stripe handles this automatically if `automatic_tax` is enabled and the tax ID is valid.

## Anti-patterns

- **Rolling your own tax tables for covered jurisdictions.** Slow, error-prone, regulatory risk.
- **`automatic_tax` without customer address.** Calc fails or defaults; invoice may have wrong tax.
- **Assuming full coverage.** Brazil (partial), India edge cases need supplementing. Verify per market.
- **Storing tax rates in your DB.** They change. Stripe tracks current rates per jurisdiction.

## Gotchas

- **Tax IDs aren't validated automatically for all jurisdictions** — verify on submission, but Stripe handles common ones.
- **Marketplace tax obligations** — some jurisdictions require platforms to collect on behalf of sellers; Stripe Tax handles this if configured. See [Connect](/stacks/stripe/stripe-connect/) docs.
- **Mid-period plan changes**: tax recalculates per invoice. A prorated mid-period change recalculates the prorated portion.
- **Refunds**: tax is refunded proportionally to the refunded amount.

## Cross-references

- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — `automatic_tax` integration
- [Stripe Billing](/stacks/stripe/stripe-billing/) — Subscription tax
- [Adaptive Pricing](/stacks/stripe/adaptive-pricing/) — multi-currency tax handling
- [Customer Portal](/stacks/stripe/customer-portal/) — tax-ID collection
- [Stripe Connect](/stacks/stripe/stripe-connect/) — marketplace tax obligations
- [saas-architect on Stripe](/stacks/stripe/saas-architect/)
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/tax](https://docs.stripe.com/tax)
