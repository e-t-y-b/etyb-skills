---
title: ACH Direct Debit
description: US bank-debit payment rail via PaymentIntents. Longer settlement (3-5 business days), mandate handling, dispute windows differ from cards.
product:
  name: ACH Direct Debit
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, backend-architect, fintech-architect]
  authoritative_url: https://docs.stripe.com/payments/ach-direct-debit
  notes: "Bank debit; mandate handling, 3-5 business day settlement, dispute windows differ from cards. Pair with Financial Connections for instant ownership verification."
---

## What it is

ACH Direct Debit is the US bank-debit payment rail accessible through Stripe. You debit a customer's US checking/savings account directly via the ACH network. Slower than cards (3-5 business days for settlement), cheaper, longer dispute windows.

Distinct from [Treasury OutboundPayment via ACH](/stacks/stripe/stripe-treasury/) — that's pushing money OUT; this is pulling money IN.

Canonical reference: [docs.stripe.com/payments/ach-direct-debit](https://docs.stripe.com/payments/ach-direct-debit).

## When to use

| Need | ACH Direct Debit? |
|------|-------------------|
| B2B recurring payments (lower fees than cards) | Yes |
| B2C bills with customer consent | Yes |
| Anything time-sensitive (next-day fulfillment) | No — settlement takes 3-5 days |
| One-time consumer purchases | Usually no — cards are faster and better UX |
| Marketplace customer-to-platform money in | Yes (slower but cheaper) |

## 2025-2026 currency anchors

- **Pair with [Financial Connections](/stacks/stripe/stripe-financial-connections/)** for instant ownership verification — much better than micro-deposits.
- **Settlement window**: 3-5 business days for the funds to actually arrive.
- **`payment_intent.processing`** state lasts the settlement window. Don't fulfill on `processing`.
- **Mandate handling** — required per NACHA rules; Stripe collects via the verification flow.

## Patterns

### ACH with Financial Connections (instant verify)

```typescript
// 1. Customer links bank via Financial Connections (instant ownership verification)
// (See /stacks/stripe/stripe-financial-connections/)

// 2. Create PaymentIntent debiting the linked account
const pi = await stripe.paymentIntents.create({
  amount: 5000,
  currency: 'usd',
  customer: customerId,
  payment_method: linkedPaymentMethodId,
  payment_method_types: ['us_bank_account'],
  confirm: true,
});

// 3. PaymentIntent enters 'processing'. Don't fulfill yet.
// 4. Webhook payment_intent.succeeded fires 3-5 business days later. Fulfill then.
```

### ACH via [Payment Element](/stacks/stripe/payment-element/)

Enable `us_bank_account` in Dashboard → Payment Methods. Payment Element will surface "Pay via bank account" when amount/currency/country match. Stripe handles micro-deposit or Financial Connections verification.

### Returned ACH

ACH returns can happen up to 60 days post-debit for unauthorized debits (R10 return code). Returns of administrative kind (R01, insufficient funds) are typically 2 days. Handle `charge.failed` and `charge.refunded` events with the return reason.

## Anti-patterns

- **Fulfilling digital goods on `payment_intent.processing`.** Money hasn't moved. Wait for `succeeded`.
- **No mandate flow.** NACHA requires mandate; Stripe collects via the verification flow, but make sure the customer-facing copy is clear.
- **Skipping `payment_intent.payment_failed` handling.** ACH can fail post-`processing`; surface to customer.
- **ACH for time-sensitive transactions.** 3-5 day settlement is real; don't expect next-day delivery.

## Gotchas

- **Settlement window is calendar-day-based.** Holidays + weekends extend.
- **Returns can be days or weeks after `payment_intent.succeeded`.** Build for late returns affecting fulfilled orders — this is why physical-goods e-commerce often avoids ACH for retail.
- **Dispute windows differ from cards.** ACH disputes (unauthorized debits) have a 60-day window for consumers.
- **Test mode ACH "settles" instantly** — live mode takes 3-5 business days. Don't write code that depends on test mode's speed.

## Cross-references

- [Payment Intents](/stacks/stripe/payment-intents/) — underlying primitive
- [Stripe Financial Connections](/stacks/stripe/stripe-financial-connections/) — instant ownership verification
- [SEPA Debit](/stacks/stripe/sepa-debit/) — EU equivalent
- [Webhooks](/stacks/stripe/webhooks/) — `payment_intent.processing`, `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.refunded`
- [Stripe Treasury](/stacks/stripe/stripe-treasury/) — outbound ACH (distinct flow)
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/payments/ach-direct-debit](https://docs.stripe.com/payments/ach-direct-debit)
