---
title: SEPA Direct Debit
description: EU bank debit via PaymentIntents. 5+ business day settlement, mandate semantics required, dispute windows differ from cards.
product:
  name: SEPA Direct Debit
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, backend-architect, fintech-architect]
  authoritative_url: https://docs.stripe.com/payments/sepa-debit
  notes: "EU bank debit; 5+ business day settlement; mandate semantics; longer dispute window than US ACH (8 weeks unauthorized return)."
---

## What it is

SEPA Direct Debit is the EU bank-debit equivalent of [ACH Direct Debit](/stacks/stripe/ach-debit/). Debits a SEPA-zone bank account directly. Slower settlement than cards, mandate-required, longer dispute windows.

Canonical reference: [docs.stripe.com/payments/sepa-debit](https://docs.stripe.com/payments/sepa-debit).

## When to use

| Need | SEPA Debit? |
|------|-------------|
| EU B2B recurring | Yes |
| EU B2C bills with consent | Yes |
| Time-sensitive (next-day fulfillment) | No — 5+ day settlement |
| One-time consumer purchases | Usually no — cards faster |

## 2025-2026 currency anchors

- **Settlement: 5+ business days** typically.
- **Mandate-required** — Stripe collects via Payment Element / Checkout.
- **8-week unauthorized return window** for consumers (longer than US ACH 60-day for unauthorized).
- **B2B mandate variant** (SEPA B2B Direct Debit) has shorter dispute window but separate mandate flow.

## Patterns

### SEPA via Payment Element

Enable `sepa_debit` in Dashboard → Payment Methods. Payment Element surfaces "Pay via SEPA" for EU buyers in EUR. Stripe handles the IBAN collection + mandate display.

### Webhook handling

```typescript
// payment_intent.processing - SEPA in flight (days)
// payment_intent.succeeded - settled
// payment_intent.payment_failed - bounce or return
// charge.refunded - includes returns
```

Same shape as ACH. Don't fulfill on `processing`.

## Anti-patterns

- **Fulfilling digital goods on `processing`.** Money hasn't moved yet.
- **No mandate display.** Stripe handles via UI; ensure you don't suppress.
- **SEPA for non-EU buyers.** Doesn't work; restrict by country.
- **B2C SEPA for one-off consumer purchases.** UX worse than card; settlement risk on returns.

## Gotchas

- **8-week unauthorized return window** is long. Build for late returns affecting completed orders.
- **B2B vs B2C SEPA** are different rails with different rules. Pick correctly.
- **IBAN validation** — Stripe handles structural validation; some banks reject for issuer-specific reasons that only manifest at debit time.

## Cross-references

- [Payment Intents](/stacks/stripe/payment-intents/) — underlying primitive
- [ACH Debit](/stacks/stripe/ach-debit/) — US equivalent
- [Payment Element](/stacks/stripe/payment-element/) — collection surface
- [Webhooks](/stacks/stripe/webhooks/) — `payment_intent.*`, `charge.refunded`
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/payments/sepa-debit](https://docs.stripe.com/payments/sepa-debit)
