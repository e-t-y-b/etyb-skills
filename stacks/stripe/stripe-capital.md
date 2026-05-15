---
title: Stripe Capital
description: Financing program for Connect platform sellers and direct merchants. Stripe underwrites; repayment via automatic deduction from payouts.
product:
  name: Stripe Capital
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, saas-architect]
  authoritative_url: https://docs.stripe.com/capital
  notes: "Available to Connect platforms and direct merchants in eligible countries. Underwriting model proprietary — platforms don't underwrite."
---

## What it is

Stripe Capital is a financing program — Stripe offers loans to merchants and Connect platform sellers based on Stripe-side payment history. For [Connect](/stacks/stripe/stripe-connect/) platforms, your sellers can be offered Capital, and you surface the offers via API. Loan repayment happens automatically via deductions from the seller's Stripe payouts.

Eligibility is determined by Stripe's algorithm based on transaction history. **The platform does not underwrite.**

Canonical reference: [docs.stripe.com/capital](https://docs.stripe.com/capital).

## When to use

| Need | Capital? |
|------|----------|
| Your platform has connected accounts with consistent transaction history | Yes (eligible markets) |
| Sellers might want working capital | Yes — differentiator vs other platforms |
| You want to underwrite loans yourself | No — Capital is Stripe-underwritten |
| Consumer lending | No |

## 2025-2026 currency anchors

- **Continuous eligibility expansion** — supported countries grow; underwriting model is proprietary and tunes.
- **Connect platform integration** — surface offers via API; platforms don't bear loan risk.

## Patterns

### List + accept offers

```typescript
// List offers available to a connected account
const offers = await stripe.capital.financingOffers.list({
  connected_account: connectedAccountId,
});

// Accept an offer
await stripe.capital.financingOffers.markDelivered(offerId);
// (or whatever the current accept flow is — verify against current API)
```

Surface offers in your platform's UI when they're available; users accept inside Stripe's flow.

## Anti-patterns

- **Promising specific terms.** You don't underwrite — Stripe does. Surface eligibility + offer details without prescribing terms.
- **Trying to underwrite yourself.** Capital is Stripe's program; don't build your own underwriting on top.
- **Surfacing Capital where it's not available.** Region/eligibility-check before showing the option to sellers.

## Gotchas

- **Repayment is automatic via payout deduction.** Connected accounts see reduced payouts during loan repayment; communicate this clearly.
- **Eligibility opaque** — Stripe's underwriting is proprietary. Don't promise eligibility without the offer object.
- **Default behavior** — non-payment scenarios are handled by Stripe; platform isn't on the hook (unlike Connect losses with `controller.losses.payments: 'application'`).

## Cross-references

- [Stripe Connect](/stacks/stripe/stripe-connect/) — Capital lives on top of Connect
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — broader fintech context
- Authoritative: [docs.stripe.com/capital](https://docs.stripe.com/capital)
