---
title: Optimized Checkout Suite
description: Bundle of conversion features (2024-2025) — Adaptive Pricing, Link, Express Checkout Element, smart payment method ordering, conversion ML. Enabled per Checkout/Payment Element.
product:
  name: Optimized Checkout Suite
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, saas-architect]
  authoritative_url: https://docs.stripe.com/payments/checkout/optimized-checkout-suite
  notes: "Bundle (2024-2025): Adaptive Pricing, Link, Express Checkout Element, smart payment method ordering. Enabled per Checkout/Payment Element."
---

## What it is

Optimized Checkout Suite is Stripe's bundle of conversion-optimization features layered into [Stripe Checkout](/stacks/stripe/stripe-checkout/) and [Payment Element](/stacks/stripe/payment-element/) implementations. Released as a coherent bundle through 2024-2025.

Components:
- **[Adaptive Pricing](/stacks/stripe/adaptive-pricing/)** — local-currency display in Checkout
- **[Link](/stacks/stripe/link/)** — 1-click checkout for returning Stripe users
- **[Express Checkout Element](/stacks/stripe/express-checkout-element/)** — wallet button row (Apple Pay, Google Pay, Link, Amazon Pay, PayPal)
- **Smart payment method ordering** — ML-driven re-ordering of methods based on conversion likelihood per buyer context
- **Connection prompts** — surfaces that nudge returning users to save info for next time

Canonical reference: [docs.stripe.com/payments/checkout/optimized-checkout-suite](https://docs.stripe.com/payments/checkout/optimized-checkout-suite).

## When to use

Default for new Checkout / Payment Element integrations. The conversion lift is meaningful and the setup cost is minimal once Checkout/Payment Element is in place.

## 2025-2026 currency anchors

- **Bundle introduced 2024-2025.** Features compose together; enabling Checkout/Payment Element gets you most of them.
- **Smart payment method ordering** is ML-driven — Stripe re-ranks methods based on observed conversion patterns per buyer context.
- **For new builds, this is the expected baseline.** If you find yourself recommending custom payment method ordering or hand-wired wallet buttons, you're under-using the Suite.

## Patterns

### On Stripe Checkout

Most Suite features are on by default. Verify in Dashboard → Settings → Payment Methods and per-Session config. [Adaptive Pricing](/stacks/stripe/adaptive-pricing/) requires multi-currency [Prices](/stacks/stripe/stripe-billing/) + Tax setup.

### On Payment Element

Compose:
1. [Link Authentication Element](/stacks/stripe/link/) (email + Link login)
2. [Express Checkout Element](/stacks/stripe/express-checkout-element/) (wallets above the form)
3. [Payment Element](/stacks/stripe/payment-element/) (main form with smart ordering)

The composition delivers the Suite's full effect on conversion.

## Anti-patterns

- **Composing hand-wired wallet buttons + Card Element** — bypasses the entire Suite. Use modern Elements.
- **Hardcoding payment method order.** ML-driven ordering outperforms manual most of the time.
- **Picking Suite-incompatible configurations** (e.g., disabling `automatic_payment_methods`) just to gain "control."

## Gotchas

- **Eligibility for some Suite features depends on country + currency + amount.** Test with realistic combinations.
- **[Adaptive Pricing](/stacks/stripe/adaptive-pricing/)** absorbs an FX markup; verify margin if you're low-margin.
- **Smart ordering is opaque** — you can't force a specific order; trust the ML or A/B test specific configurations.

## Cross-references

- [Stripe Checkout](/stacks/stripe/stripe-checkout/)
- [Payment Element](/stacks/stripe/payment-element/)
- [Express Checkout Element](/stacks/stripe/express-checkout-element/)
- [Link](/stacks/stripe/link/)
- [Adaptive Pricing](/stacks/stripe/adaptive-pricing/)
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/payments/checkout/optimized-checkout-suite](https://docs.stripe.com/payments/checkout/optimized-checkout-suite)
