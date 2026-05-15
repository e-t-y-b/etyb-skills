---
title: Stripe Issuing
description: Issue virtual or physical Visa/Mastercard cards backed by a Stripe or Treasury balance. Authorization webhooks are non-negotiable infrastructure.
product:
  name: Stripe Issuing
  stack: stripe
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, backend-architect, security-engineer]
  authoritative_url: https://docs.stripe.com/issuing
  notes: "Card programs expanding internationally 2025-2026; authorization webhook handler must respond within ~2 seconds or Stripe applies the default."
---

## What it is

Stripe Issuing lets your platform issue physical or virtual Visa or Mastercard cards, backed by a Stripe balance or a [Treasury](/stacks/stripe/stripe-treasury/) Financial Account. The platform owns the program; cardholders are your customers (or their employees, or your platform's connected accounts).

Use cases:
- **Corporate cards** — your B2B SaaS issues cards to its customers' employees (Ramp/Brex/Mercury style)
- **Expense cards** — single-use or limited-use for specific spend categories
- **Marketplace payout cards** — push earnings to a spendable card
- **On-demand virtual cards** — generated for a specific purchase (instant gift cards, fuel cards)

Canonical reference: [docs.stripe.com/issuing](https://docs.stripe.com/issuing).

## When to use

| Need | Use Issuing? |
|------|--------------|
| Corporate card program for B2B customers | Yes |
| Per-employee, per-project spend control | Yes |
| Marketplace seller payouts as a spendable card | Yes |
| Consumer prepaid cards (gift cards) | Generally yes; regulatory differs |
| Credit cards (unsecured lending) | **No** — Issuing is debit/prepaid only |

## 2025-2026 currency anchors

- **International expansion** through 2025-2026 — more countries supported. Verify per-country support for your program.
- **Tap to Pay terminal complement** — Issuing pairs with [Stripe Terminal](/stacks/stripe/stripe-terminal/) for in-person accept + issue closed loops.
- **Spend control framework matured** — `spending_limits[]`, `blocked_categories`, `allowed_merchants` cover most rules natively; complex per-employee or per-trip rules go in your authorization webhook handler.

## Patterns

### Create a card

```typescript
const card = await stripe.issuing.cards.create(
  {
    cardholder: cardholderId,
    currency: 'usd',
    type: 'virtual',  // or 'physical'
    financial_account: financialAccountId,
    spending_controls: {
      spending_limits: [
        { amount: 100000, interval: 'monthly' },  // $1000/month cap
        { amount: 10000, interval: 'daily' },     // $100/day cap
      ],
      blocked_categories: ['gambling'],
    },
  },
  { stripeAccount: connectedAccountId },
);
```

### Authorization webhook — the most critical handler

`issuing_authorization.request` fires synchronously when the cardholder swipes. Stripe asks: do you approve?

```typescript
async function handleAuthorizationRequest(event: Stripe.Event) {
  const auth = event.data.object as Stripe.Issuing.Authorization;
  
  const allowed = await canSpend(auth.amount, auth.card.cardholder, auth.merchant_data);
  
  if (allowed) {
    await stripe.issuing.authorizations.approve(auth.id);
  } else {
    await stripe.issuing.authorizations.decline(auth.id);
  }
}
```

**You have ~2 seconds to respond.** If you don't, Stripe applies the default (configured per Issuing program — usually "approve" with the configured spending controls).

Other events:
- `issuing_authorization.created` — async record-keeping after approval
- `issuing_transaction.created` — actual capture (auth → settled)

### Spend controls

Stripe-native controls handle simple rules:
- `spending_limits[]` — per-interval caps (monthly, weekly, daily, per_authorization, all_time)
- `blocked_categories` — Visa/MC MCC categories to block
- `allowed_merchants` / `blocked_merchants` — by merchant data

For complex rules (per-employee, per-trip, per-project, per-budget): implement in the `issuing_authorization.request` webhook handler.

### Deferred decision pattern

When 2 seconds isn't enough:
1. Approve in the webhook handler (within 2 seconds, applying conservative limit)
2. Async, perform deeper checks
3. If deeper checks fail, reverse the authorization (`issuing.authorizations.update` with metadata marking fraud + manual review)

Trade-off: false positives let some bad spend through. Worth it for legitimate spend not being denied at the register.

### Physical cards

```typescript
const card = await stripe.issuing.cards.create({
  type: 'physical',
  cardholder: cardholderId,
  currency: 'usd',
  shipping: {
    address: { /* shipping address */ },
    name: cardholder.name,
  },
});
```

- Requires verified PII on cardholder
- Stripe (or partner) ships; ~7-10 days
- Activation flow before first use

For virtual-first card programs (most modern), issue virtual at signup and let cardholders request physical separately.

## Anti-patterns

- **No authorization webhook handler.** Stripe applies the default → all in-program spend goes through with only the static spending controls. If you wanted dynamic policy, it didn't run.
- **Synchronous heavy work in the authorization handler.** 2-second budget is total — Stripe → your handler → your response. If your handler does a SQL join + a Redis call + a vendor API call, you'll miss the window. Cache decision-relevant state locally.
- **Approving without checking internal balance.** Cards backed by Treasury balance can overdraft if your handler approves spend that exceeds the underlying balance. Check balance + holds before approving.
- **Stripe-native spending controls as the only enforcement.** Fine for "no gambling, $1000/month cap." For per-employee budgets, per-project codes, your webhook handler does the work.
- **Issuing without [Connect](/stacks/stripe/stripe-connect/) capability `card_issuing: 'active'`** — fails silently or blocks the program.

## Gotchas

- **Authorization timeout is firm.** Stripe doesn't extend.
- **`issuing_authorization.request` fires before the cardholder sees a result.** Time pressure is real — even a 1.5-second handler is risky during a busy hour.
- **Transaction vs authorization** — an authorization can be reversed before it becomes a transaction (cardholder cancels, auth expires). The lifecycle is auth → maybe transaction.
- **International card support varies by program.** Some programs are US-only; verify before promising international issue.
- **Webhook events you MUST handle:** `issuing_authorization.request` (synchronous decision), `issuing_authorization.created`, `issuing_authorization.updated`, `issuing_transaction.created`, `issuing_card.created`, `issuing_card.updated`, `issuing_dispute.*`.

## Cross-references

- [Stripe Treasury](/stacks/stripe/stripe-treasury/) — Financial Account backing the cards
- [Stripe Connect](/stacks/stripe/stripe-connect/) — Issuing typically runs on connected accounts
- [Stripe Terminal](/stacks/stripe/stripe-terminal/) — accept side; pair with Issuing for closed loops
- [Webhooks](/stacks/stripe/webhooks/) — authorization handler is in this surface
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — card program compliance + AML
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — issuing program security
- Authoritative: [docs.stripe.com/issuing](https://docs.stripe.com/issuing)
