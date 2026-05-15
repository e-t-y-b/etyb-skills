---
title: Stripe Treasury
description: Embedded finance — Financial Accounts, OutboundPayments, RTP/FedNow rails. Partner-bank-gated, available to approved platforms.
product:
  name: Stripe Treasury
  stack: stripe
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, backend-architect, security-engineer]
  authoritative_url: https://docs.stripe.com/treasury
  notes: "Matured 2024-2026 with RTP/FedNow rails. Eligibility is partner-bank-dependent (Evolve, Goldman Sachs in US). B2B SaaS adoption expanding 2025-2026."
---

## What it is

Stripe Treasury provides embedded-finance primitives that let your platform offer bank-account-like functionality to its customers:

- **Financial Accounts** — balance with routing + account number; customers can receive and hold funds
- **OutboundPayments** — push payments via ACH, Same-day ACH, US Domestic Wire, **RTP**, **FedNow**
- **InboundTransfers** — move money in from external accounts
- **Issued Cards** — pair with [Stripe Issuing](/stacks/stripe/stripe-issuing/) for spending against the balance
- **Statements** — downloadable monthly statements

Underneath, the actual funds sit at a partner bank (Evolve Bank & Trust or Goldman Sachs in the US, depending on the flow). Stripe provides the API and orchestration; the partner bank holds the deposits.

Canonical reference: [docs.stripe.com/treasury](https://docs.stripe.com/treasury).

## When to use

| Need | Use Treasury? |
|------|---------------|
| Hold customer balances inside your SaaS | Yes (if eligible) |
| Issue cards backed by a balance | Yes (Issuing + Treasury) |
| Just pay out to sellers without holding | No — [Connect](/stacks/stripe/stripe-connect/) payouts handle this |
| Real-time push payments (RTP/FedNow) | Yes (via OutboundPayments) |
| Need to be a bank | No — you're not a bank; Treasury makes you a quasi-bank backed by partner bank |

Eligibility is gated: your platform goes through Stripe's Treasury underwriting before getting access. Programs in non-US countries are limited (verify current support).

## 2025-2026 currency anchors

- **Matured 2024-2026** — Financial Accounts, OutboundPayments, RTP/FedNow rails generally available to approved platforms.
- **RTP cap raised** to $1M in November 2024 (The Clearing House).
- **FedNow** scaling — $500k initial cap, growing.
- **Partner banks**: Evolve Bank & Trust for most US flows; Goldman Sachs for some. Per-corridor eligibility.
- **Embedded Components** (2024 GA) include payouts dashboard surfaces for connected accounts using Treasury.

## Patterns

### Create a Financial Account

```typescript
const financialAccount = await stripe.treasury.financialAccounts.create(
  {
    supported_currencies: ['usd'],
    features: {
      card_issuing: { requested: true },
      deposit_insurance: { requested: true },
      financial_addresses: { aba: { requested: true } },
      inbound_transfers: { ach: { requested: true } },
      outbound_payments: {
        ach: { requested: true },
        us_domestic_wire: { requested: true },
      },
      outbound_transfers: {
        ach: { requested: true },
        us_domestic_wire: { requested: true },
      },
    },
  },
  { stripeAccount: connectedAccountId },
);
```

The account exposes:
- A **financial address** (routing + account number) others can push to via ACH/wire
- A **balance** (Stripe accounting; ultimately at the partner bank)
- Optional **FDIC deposit insurance** pass-through (partner-bank-dependent)

### OutboundPayments — pick the rail

| Rail | Speed | Limits | Use |
|------|-------|--------|-----|
| **ACH** | 1-3 business days | $25M+ but slow | Bulk payouts |
| **Same-day ACH** | Hours (cut-off times) | Lower per-transaction | When ACH speed matters |
| **US Domestic Wire** | Hours, expensive | High | Large urgent transactions |
| **RTP** (The Clearing House) | Real-time (seconds) | $1M cap (Nov 2024+) | Real-time push payments |
| **FedNow** | Real-time (seconds) | $500k initial cap, scaling | Real-time push, growing rail |

```typescript
const op = await stripe.treasury.outboundPayments.create(
  {
    financial_account: financialAccountId,
    amount: 50000,
    currency: 'usd',
    destination_payment_method_data: {
      type: 'us_bank_account',
      us_bank_account: {
        routing_number: '110000000',
        account_number: '000123456789',
      },
    },
    customer: customerId,
  },
  { stripeAccount: connectedAccountId },
);
```

Network selection is largely automatic — Stripe picks ACH by default; specify the network if you need RTP/FedNow.

### Treasury balance + double-entry ledger

Critical: **Treasury balances are NOT a substitute for your own ledger.**

Stripe's Treasury balance is one account in your ledger:

```
Treasury Balance: $100,000 (held at partner bank)
  ├── Customer A liability: $40,000 (we owe A)
  ├── Customer B liability: $35,000 (we owe B)
  ├── Customer C liability: $20,000 (we owe C)
  └── Platform revenue:      $5,000 (our take from fees)
```

When customer A withdraws $10k: Treasury balance goes down by $10k AND customer A liability goes down by $10k. Both legs in your ledger. See [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) for the broader ledger design.

## Anti-patterns

- **Stripe Treasury as the ledger.** Treasury gives you the cash side; the accrual side (customer-side liabilities, revenue recognition, platform-side assets) is your ledger of record.
- **Designing for RTP/FedNow without eligibility check.** Both rails are partner-bank-gated per corridor. Confirm before promising real-time to customers.
- **Assuming deposit insurance covers all cases.** FDIC pass-through depends on partner bank + program; verify the actual coverage applies to your customers' balances.
- **Skipping the OutboundPayment webhook handling.** Failures, returns, recalls all flow through events. Don't poll.

## Gotchas

- **Per-corridor eligibility** for RTP/FedNow. Not every OutboundPayment is real-time even with the rail requested.
- **Partner bank ACH return windows** are 60 days (unauthorized return) to 2 days (admin returns). Holds and reversals affect your ledger.
- **Treasury features must be requested + approved.** A new Financial Account doesn't have all features active immediately.
- **InboundTransfer reversals** can happen days after settlement if the source side disputes — design your customer-facing UX with this latency in mind.
- **Webhook events you MUST handle:** `treasury.financial_account.*`, `treasury.outbound_payment.*`, `treasury.outbound_transfer.*`, `treasury.inbound_transfer.*`, `treasury.received_credit.*`, `treasury.received_debit.*`, `treasury.credit_reversal.*`, `treasury.debit_reversal.*`.

## Cross-references

- [Stripe Connect](/stacks/stripe/stripe-connect/) — Treasury runs on top of connected accounts
- [Stripe Issuing](/stacks/stripe/stripe-issuing/) — cards backed by Treasury balance
- [RTP / FedNow](/stacks/stripe/rtp-fednow/) — real-time rail details
- [ACH Debit](/stacks/stripe/ach-debit/) — pull-style bank debit (different from OutboundPayment)
- [Webhooks](/stacks/stripe/webhooks/) — Treasury event handling
- [Stripe Sigma](/stacks/stripe/stripe-sigma/) — reconciliation queries
- [Stripe Data Pipeline](/stacks/stripe/stripe-data-pipeline/) — warehouse sync for ledger ETL
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — ledger design + regulatory context
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — Treasury data security
- Authoritative: [docs.stripe.com/treasury](https://docs.stripe.com/treasury)
