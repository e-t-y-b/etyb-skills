---
title: Adaptive Pricing
description: Localized pricing display in Checkout — Stripe handles the FX conversion. Requires multi-currency Prices and Tax configured coherently.
product:
  name: Adaptive Pricing
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, saas-architect]
  authoritative_url: https://docs.stripe.com/payments/checkout/adaptive-pricing
  notes: "Released 2024 as part of Optimized Checkout Suite; FX markup applies. Use for B2C global conversion lift; avoid for B2B enterprise pricing."
---

## What it is

Adaptive Pricing displays checkout prices in the buyer's local currency, with Stripe handling the FX conversion (and absorbing the cost, with a markup). Released 2024 as part of the [Optimized Checkout Suite](/stacks/stripe/optimized-checkout-suite/).

Canonical reference: [docs.stripe.com/payments/checkout/adaptive-pricing](https://docs.stripe.com/payments/checkout/adaptive-pricing).

## When to use

| Scenario | Adaptive Pricing? |
|----------|-------------------|
| B2C with global customer base | Yes — conversion lifts measurably from local pricing |
| D2C subscriptions where round numbers matter ($9.99 → €9.99 → £8.99) | Yes |
| B2B enterprise pricing — invoiced in your billing currency regardless | No |
| Low-margin businesses | Maybe — Adaptive Pricing markup eats into margin |

## 2025-2026 currency anchors

- **Released 2024**, part of Optimized Checkout Suite.
- **Requires multi-currency [Prices](/stacks/stripe/stripe-billing/)** — define `currency_options` per Price.
- **Requires coherent [Stripe Tax](/stacks/stripe/stripe-tax/) configuration** for tax to compute correctly in the displayed currency.

## Patterns

### Define multi-currency Prices

```typescript
const price = await stripe.prices.create({
  product: 'prod_xyz',
  unit_amount: 1000,  // $10.00 USD baseline
  currency: 'usd',
  currency_options: {
    eur: { unit_amount: 950 },   // €9.50
    gbp: { unit_amount: 800 },   // £8.00
    cad: { unit_amount: 1400 },  // CAD 14.00
  },
});
```

### Enable on Checkout

```typescript
const session = await stripe.checkout.sessions.create({
  // ...
  adaptive_pricing: { enabled: true },
});
```

Stripe presents the price in the buyer's local currency. Settlement is in your chosen currency (or in the buyer's currency if you've enabled multi-currency settlement).

### Manual override

For pure manual control instead of Adaptive Pricing, set the currency on the Checkout Session or PaymentIntent explicitly per locale. More work; needed only when you want to override Adaptive Pricing's defaults.

## Anti-patterns

- **Adaptive Pricing without multi-currency Prices defined.** Falls back to base currency; no localization.
- **Adaptive Pricing with low-margin SKUs.** Markup eats margin; manual currency control may be better.
- **Adaptive Pricing for B2B enterprise contracts.** Enterprise invoices use contracted billing currency; don't FX silently.
- **Adaptive Pricing without [Stripe Tax](/stacks/stripe/stripe-tax/) coherence.** Tax must compute in the displayed currency; otherwise customers see weird totals.

## Gotchas

- **FX rates with markup** — Stripe sets the rate; can be slightly worse than spot. Verify margin impact.
- **Multi-currency settlement is a separate feature.** Adaptive Pricing changes display; settlement is configured separately.
- **Currency options must be defined per Price** — Stripe doesn't infer from the base currency.
- **Rounding** — displayed prices round to local norms (€9.50 rather than €9.7634); ensure your `currency_options` reflects desired round numbers.

## Cross-references

- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — Adaptive Pricing enabled here
- [Stripe Billing](/stacks/stripe/stripe-billing/) — Subscriptions can use Adaptive Pricing on signup
- [Stripe Tax](/stacks/stripe/stripe-tax/) — must be coherent with displayed currency
- [Optimized Checkout Suite](/stacks/stripe/optimized-checkout-suite/) — Adaptive Pricing is part of the bundle
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- [saas-architect on Stripe](/stacks/stripe/saas-architect/)
- Authoritative: [docs.stripe.com/payments/checkout/adaptive-pricing](https://docs.stripe.com/payments/checkout/adaptive-pricing)
