---
title: Link
description: Stripe's 1-click checkout — returning Link users prefill payment method and skip the form. Link Authentication Element is the dedicated surface.
product:
  name: Link
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, saas-architect]
  authoritative_url: https://docs.stripe.com/payments/link
  notes: "1-click checkout; adoption growing rapidly 2024-2026. Link Authentication Element is the dedicated component."
---

## What it is

Link is Stripe's 1-click identity + payment product. Buyers who have a Link account (email + verified payment method, stored at Stripe) can complete checkout in one tap on any Stripe-integrated site. The buyer's payment method, address, and contact info auto-fill.

Adoption has grown rapidly through 2024-2026 — Link is now mainstream rather than a feature.

Canonical reference: [docs.stripe.com/payments/link](https://docs.stripe.com/payments/link).

## When to use

Enable Link by default on any consumer checkout. It's free, adoption is high, and returning users complete checkout meaningfully faster.

Components:
- **Link Authentication Element** — dedicated email input that recognizes Link users and triggers Link login flow
- **Link button** in [Express Checkout Element](/stacks/stripe/express-checkout-element/) — wallet-style 1-click for returning users
- **Link surface inside [Stripe Checkout](/stacks/stripe/stripe-checkout/)** — built-in

## 2025-2026 currency anchors

- **Adoption mainstream** through 2024-2026 — Link is now a primary wallet alongside Apple Pay and Google Pay.
- **Link Authentication Element** is the dedicated surface; it doubles as your email input on Payment Element forms.
- **Pay with Link button** in Express Checkout Element handles the wallet-style entry point.

## Patterns

### Link Authentication Element

```typescript
const elements = stripe.elements({ clientSecret });
const linkAuthElement = elements.create('linkAuthentication');
linkAuthElement.mount('#link-auth');
```

This IS the email input. Don't add a separate email field — replace your existing one with Link Authentication Element. Returning Link users see "Welcome back" and skip the form; new users get a passive nudge to save info for next time.

### Link in Express Checkout Element

Link renders as one of the buttons in [Express Checkout Element](/stacks/stripe/express-checkout-element/) automatically when enabled. No separate wiring needed.

### Link in Stripe Checkout

Enabled by default in [Stripe Checkout](/stacks/stripe/stripe-checkout/) when Link is on in Dashboard. Customers see "Pay with Link" if they're recognized.

## Anti-patterns

- **Disabling Link without a reason.** Conversion lift on returning users is real.
- **Adding a separate email input next to Link Authentication Element.** Link Authentication Element IS the email field. Duplication confuses users.
- **Custom Link button hand-wired.** Use Express Checkout Element or the built-in Checkout integration.

## Gotchas

- **Link only renders for recognized users or Link-eligible buyers.** Don't assume universal availability.
- **Link account ownership** is by email; same email across sites means the same Link account.
- **Link Authentication Element is for Link-enabled checkout pages** — not a general email validator.

## Cross-references

- [Express Checkout Element](/stacks/stripe/express-checkout-element/) — wallet button row including Link
- [Payment Element](/stacks/stripe/payment-element/) — pair with Link Authentication Element
- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — Link built in
- [Optimized Checkout Suite](/stacks/stripe/optimized-checkout-suite/) — Link is part of the bundle
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/payments/link](https://docs.stripe.com/payments/link)
