---
title: Stripe Financial Connections
description: Stripe's Plaid alternative — Stripe-hosted bank-account linking. Verifies ownership, pulls balances/transactions, saves for ACH debit.
product:
  name: Stripe Financial Connections
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, backend-architect, e-commerce-architect]
  authoritative_url: https://docs.stripe.com/financial-connections
  notes: "Country support expanded 2024-2025; Plaid still has broader coverage internationally. Financial Connections integrates tightly with PaymentIntents (for ACH) and Treasury."
---

## What it is

Stripe Financial Connections is Stripe's Plaid alternative — a hosted flow that lets users link their bank account to your platform. The link can be used to:

- **Verify ownership** of a bank account (instant verification vs micro-deposits)
- **Pull balances + transactions** (read-only) for underwriting or financial assessment
- **Save the account for ACH debits** via [PaymentIntents](/stacks/stripe/payment-intents/) or [Stripe Treasury](/stacks/stripe/stripe-treasury/) inbound transfers

Canonical reference: [docs.stripe.com/financial-connections](https://docs.stripe.com/financial-connections).

## When to use

| Need | Financial Connections? |
|------|------------------------|
| ACH debit setup with instant ownership verification | Yes |
| Underwriting / financial assessment (see balances, history) | Yes |
| Account aggregation in a financial tool | Yes |
| Broader international bank coverage | Plaid still has broader coverage internationally |
| Tight integration with Stripe payments/Treasury | Yes — Financial Connections is the Stripe-native option |

## 2025-2026 currency anchors

- **Country support expanded** through 2024-2025; strong in US, EU/UK growing.
- **Plaid coverage is still broader internationally** — verify per-country before committing.
- **Integration with PaymentIntents for ACH** — Financial Connections session can produce a `payment_method` directly usable for ACH debits.

## Patterns

### Create a linking session

```typescript
const session = await stripe.financialConnections.sessions.create({
  account_holder: { type: 'customer', customer: customerId },
  permissions: ['payment_method', 'balances', 'transactions'],
  prefetch: ['balances'],
});

// Send session.client_secret to frontend; mount Financial Connections Element
```

### Use the linked account for ACH

After linking, you can create a PaymentIntent that debits the linked bank account:

```typescript
const pi = await stripe.paymentIntents.create({
  amount: 5000,
  currency: 'usd',
  customer: customerId,
  payment_method: linkedPaymentMethodId,
  payment_method_types: ['us_bank_account'],
  confirm: true,
});
```

### Read-only balance + transactions

Permissions: `balances`, `transactions`, `ownership`. Use case examples — verify the customer has sufficient balance before processing, underwriting/risk assessment, account aggregation.

## Anti-patterns

- **Using Financial Connections in countries where Plaid has better coverage.** Check coverage; pick the right tool.
- **Storing Financial Connections account details in your DB.** Stripe holds the link state; reference by IDs.
- **Skipping permission scoping.** Request only the permissions you need (`payment_method` if you just need ACH; add `balances`/`transactions` only if you'll use them).

## Gotchas

- **OAuth-style flow** — customer authenticates with their bank inside Stripe's iframe; you don't see credentials.
- **Refresh windows** — balances/transactions you pulled can drift; re-fetch when fresh data matters.
- **Permission scope** matters for end-user trust and regulatory exposure.

## Cross-references

- [ACH Debit](/stacks/stripe/ach-debit/) — pull-style bank debits using linked accounts
- [Stripe Treasury](/stacks/stripe/stripe-treasury/) — inbound transfers
- [Payment Intents](/stacks/stripe/payment-intents/) — using linked accounts for charges
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/)
- Authoritative: [docs.stripe.com/financial-connections](https://docs.stripe.com/financial-connections)
