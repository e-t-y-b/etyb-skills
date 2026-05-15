---
title: RTP / FedNow
description: US real-time push rails via Stripe Treasury OutboundPayments. RTP $1M cap (Nov 2024+), FedNow $500k initial cap scaling. Eligibility per corridor.
product:
  name: RTP / FedNow (via Treasury)
  stack: stripe
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, backend-architect]
  authoritative_url: https://docs.stripe.com/treasury/moving-money/outbound-payments
  notes: "Real-time rails through Treasury OutboundPayments. Eligibility and supported corridors expanding 2025-2026."
---

## What it is

RTP (The Clearing House) and FedNow are the two US real-time payment rails. Both deliver funds in seconds to participating banks. Stripe surfaces both via [Stripe Treasury](/stacks/stripe/stripe-treasury/) OutboundPayments.

Canonical reference: [docs.stripe.com/treasury/moving-money/outbound-payments](https://docs.stripe.com/treasury/moving-money/outbound-payments).

## When to use

Real-time push payments — payouts where the recipient needs the money immediately:

- Marketplace seller instant payout
- Gig worker on-demand earnings access
- Insurance claim payout
- B2B same-second settlement

Compared to other rails:

| Rail | Speed | Limits | Use |
|------|-------|--------|-----|
| ACH | 1-3 business days | $25M+ but slow | Bulk payouts, low-urgency |
| Same-day ACH | Hours (cut-off times) | Lower per-transaction | When ACH speed matters |
| US Domestic Wire | Hours, expensive | High | Large urgent transactions |
| **RTP** | Real-time (seconds) | $1M cap (Nov 2024+) | Real-time push |
| **FedNow** | Real-time (seconds) | $500k initial cap, scaling | Real-time push, growing rail |

## 2025-2026 currency anchors

- **RTP cap raised to $1M** in November 2024 (The Clearing House).
- **FedNow** scaling — $500k initial cap, growing.
- **Per-corridor eligibility** — not every RTP/FedNow OutboundPayment is real-time. Confirm before promising real-time.
- **Treasury matured 2024-2026** with both rails generally available to approved platforms.

## Patterns

### OutboundPayment via RTP/FedNow

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
    // For RTP/FedNow, specify the network if you want one specifically
    customer: customerId,
  },
  { stripeAccount: connectedAccountId },
);
```

Network selection is largely automatic — Stripe picks ACH by default; specify the network if you need RTP/FedNow specifically.

### Handle the webhook outcome

```typescript
// treasury.outbound_payment.posted - settled
// treasury.outbound_payment.failed - failed
// treasury.outbound_payment.returned - returned (rare for RTP)
```

## Anti-patterns

- **Promising real-time without checking eligibility per corridor.** Recipient bank must support RTP/FedNow for real-time settlement.
- **Real-time for non-urgent payouts.** ACH is cheaper for bulk.
- **Hardcoding RTP** when FedNow is cheaper for the corridor; let Stripe choose unless you specifically need one.

## Gotchas

- **Recipient bank support varies.** Not every US bank supports RTP. FedNow coverage growing but still incomplete.
- **Real-time means real-time** — you can't claw back. Verify before sending.
- **Per-rail limits** — RTP $1M, FedNow $500k (and rising). If your amount exceeds, fall back to wire.
- **Eligibility is platform + corridor.** Approved Stripe Treasury platforms get access; per-corridor eligibility is checked at payment time.

## Cross-references

- [Stripe Treasury](/stacks/stripe/stripe-treasury/) — Treasury is the carrier
- [Webhooks](/stacks/stripe/webhooks/) — `treasury.outbound_payment.*`
- [ACH Debit](/stacks/stripe/ach-debit/) — inbound (distinct flow)
- [Stripe Connect](/stacks/stripe/stripe-connect/) — Treasury runs on connected accounts
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/)
- Authoritative: [docs.stripe.com/treasury/moving-money/outbound-payments](https://docs.stripe.com/treasury/moving-money/outbound-payments)
