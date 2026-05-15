---
title: BNPL Providers (Affirm / Klarna / Afterpay)
description: Buy-now-pay-later surfaced through Payment Element / Checkout. Eligibility per country, currency, amount. Provider takes credit risk; you receive full payment.
product:
  name: BNPL Providers via Stripe
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, saas-architect]
  authoritative_url: https://docs.stripe.com/payments/buy-now-pay-later
  notes: "Affirm/Klarna/Afterpay (Clearpay in UK) via Payment Element / Checkout. Settlement is full at auth; provider takes consumer credit risk. Fees higher than card."
---

## What it is

Stripe supports BNPL ("buy-now-pay-later") providers via [Payment Element](/stacks/stripe/payment-element/) and [Stripe Checkout](/stacks/stripe/stripe-checkout/). The major providers:

- **Affirm** — US (USD); installment loans
- **Klarna** — global per-market; pay-in-3/4 or pay-later
- **Afterpay / Clearpay** (Clearpay is UK name) — US, UK, AU; pay-in-4

Canonical reference: [docs.stripe.com/payments/buy-now-pay-later](https://docs.stripe.com/payments/buy-now-pay-later).

## When to use

| Scenario | BNPL? |
|----------|-------|
| AOV > $100, consumer-facing (apparel, electronics, home goods, travel) | Yes — lifts conversion at higher tickets |
| Customer demographic younger (millennial, Gen Z) | Yes |
| AOV < $50 | No — fees eat margin, providers may reject below minimums |
| B2B | No — consumer-only; B2B uses invoicing/net terms |

## 2025-2026 currency anchors

- **Surfaced through Payment Element / Checkout** automatically when amount/currency/country match eligibility.
- **Eligibility per provider** is automatic — Stripe shows BNPL methods only when the buyer + cart qualifies.
- **Settlement is full at auth** — BNPL provider pays you in full immediately; they take consumer credit risk.
- **Fees**: 6-8% to the BNPL provider via Stripe (varies by method + volume). Higher than card.

## Patterns

### Enable in Dashboard

Dashboard → Payment Methods → enable Affirm, Klarna, Afterpay/Clearpay individually per market. Stripe surfaces eligible methods at checkout time.

### Eligibility logic (automatic)

A BNPL method renders when:
- Currency + country matches the provider's corridor (Affirm = US/USD, Klarna = per-market, etc.)
- Cart total is within method limits (each has min/max)
- Buyer-side check passes (Affirm runs soft credit check on its page)

You don't need to wire eligibility yourself — let Stripe handle it.

### Refunds

Refund via Stripe as normal. The BNPL provider handles their side; the consumer's installment plan adjusts.

```typescript
await stripe.refunds.create({
  payment_intent: pi.id,
  amount: 1000,
});
```

### Customer support boundary

Consumer queries about their installment plan go to the BNPL provider, not to you. Make this clear in customer-facing copy.

## Anti-patterns

- **Hardcoding "show BNPL" logic.** Stripe's eligibility handles it. Manual logic gets stale.
- **Enabling BNPL for low-AOV items.** Fees eat margin; provider minimums also block.
- **B2B BNPL.** Consumer products. B2B uses invoicing, ACH, net terms.
- **Surfacing BNPL prominently on B2B SaaS subscriptions.** Wrong vertical.

## Gotchas

- **Per-country availability varies** — verify the corridor before promising BNPL to a specific market.
- **Provider min/max amount limits** apply per transaction. Carts below the minimum won't see the option.
- **Refunds don't return Stripe processing fees** (BNPL fee retained on the gross). Cost of refunds is real.
- **Disputes** — BNPL providers handle consumer-side disputes differently than cards; review per provider.

## Cross-references

- [Payment Element](/stacks/stripe/payment-element/) — primary surface
- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — hosted alternative
- [Payment Intents](/stacks/stripe/payment-intents/) — underlying primitive
- [Webhooks](/stacks/stripe/webhooks/) — `payment_intent.succeeded`, `charge.refunded`
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/payments/buy-now-pay-later](https://docs.stripe.com/payments/buy-now-pay-later)
