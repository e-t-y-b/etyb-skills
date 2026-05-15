---
title: Stripe Billing — Subscriptions
description: Recurring billing on Stripe — Subscriptions, Prices, Products, Invoices. Stable surface; proration and lifecycle transitions are non-obvious.
product:
  name: Stripe Billing — Subscriptions
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [saas-architect, backend-architect, e-commerce-architect]
  authoritative_url: https://docs.stripe.com/billing
  notes: "Stable but `proration_behavior`, `billing_cycle_anchor`, trial conversions, and `incomplete` subscription handling trip people up."
---

## What it is

Stripe Billing is the recurring-billing layer over [Payment Intents](/stacks/stripe/payment-intents/). The core objects:

- **Product** — what you're selling ("Pro Plan")
- **Price** — how it costs (currency, interval, tiered/flat/metered)
- **Subscription** — the active recurring relationship between a Customer and one or more Prices
- **Subscription Schedule** — phased plans, scheduled changes, fixed-term contracts
- **Invoice** — the periodic charge document

Canonical reference: [docs.stripe.com/billing](https://docs.stripe.com/billing).

## When to use

Stripe Billing handles all the common SaaS pricing models. Pick the right Price shape for your model:

| Model | Price configuration |
|-------|---------------------|
| Flat subscription | Single Price, `recurring.interval`, no usage |
| Per-seat (B2B norm) | `recurring.usage_type: 'licensed'`, `quantity` = seat count |
| Tiered volume per-seat | Price with `tiers[]`, `tiers_mode: 'volume'` |
| Tiered graduated per-seat | Price with `tiers[]`, `tiers_mode: 'graduated'` |
| Pure usage / metered | `recurring.usage_type: 'metered'` linked to a [Meter](/stacks/stripe/meter-api/) |
| Hybrid (base + usage) | Subscription with flat Price + metered Price |
| Pre-paid credits | External credit ledger; Stripe doesn't have first-party credit semantics |

Decision against alternatives:

- **Stripe Billing alone** — fits up to ~$10M ARR with standard models.
- **[Orb](https://www.withorb.com/) or [Metronome](https://metronome.com/) layered on Stripe** — for complex usage rating, enterprise contracts, credit/drawdown.
- **[Lago](https://www.getlago.com/)** — self-hosted alternative.

## 2025-2026 currency anchors

- **[Meter API replaced `usage_records`](/stacks/stripe/meter-api/)** for new metered subscriptions (late 2024). Legacy metered subscriptions continue to function.
- **[Customer Portal](/stacks/stripe/customer-portal/)** configuration matured 2024-2025 — recommend as default tenant self-service surface for non-enterprise tiers.
- **[Stripe Tax](/stacks/stripe/stripe-tax/)** integrates cleanly with Billing — automatic tax lines on invoices, Customer Portal handles tax-ID collection.
- **Subscription Schedules** got more flexible: phased plans, proration controls, scheduled cancellations/modifications all first-class.
- **[Adaptive Pricing](/stacks/stripe/adaptive-pricing/)** (2024) — Checkout displays local-currency prices on subscription signups.
- **Entitlements API** (Stripe-native entitlements, GA-ish through 2025) — works for simple SaaS; bigger SaaS still rolls own.
- **Pause Subscriptions** with `pause_collection` is the modern equivalent of subscription pause.

## Patterns

### Create subscription with trial

```typescript
const sub = await stripe.subscriptions.create({
  customer: customer.id,
  items: [{ price: 'price_id' }],
  trial_period_days: 14,
  trial_settings: {
    end_behavior: { missing_payment_method: 'cancel' },
  },
});
```

`trial_settings.end_behavior.missing_payment_method`:
- `cancel` — subscription canceled at trial end if no payment method (usually correct)
- `pause` — paused (no invoices, no access)
- `create_invoice` — invoice created, customer is `past_due` (rarely what you want)

### Mid-cycle plan change

```typescript
const sub = await stripe.subscriptions.update(subscriptionId, {
  items: [{ id: currentItemId, price: 'price_new_plan' }],
  proration_behavior: 'create_prorations',  // | 'always_invoice' | 'none'
  billing_cycle_anchor: 'unchanged',         // | 'now' to reset
});
```

`proration_behavior`:
- `create_prorations` — invoice item on next invoice (default; "smooth out at next bill")
- `always_invoice` — invoice immediately (B2B upgrades; charge difference now)
- `none` — skip proration (loses/overcharges the partial period; "free upgrade" promotions)

### Phased pricing (intro → main)

```typescript
const schedule = await stripe.subscriptionSchedules.create({
  customer: customer.id,
  start_date: 'now',
  phases: [
    { items: [{ price: 'price_intro' }], iterations: 3 },   // $10/mo for 3 months
    { items: [{ price: 'price_main' }] },                    // $30/mo thereafter
  ],
});
```

### Pause vs cancel

```typescript
// Pause (keep relationship, stop invoicing)
await stripe.subscriptions.update(subId, {
  pause_collection: { behavior: 'mark_uncollectible' },
});

// Cancel at period end
await stripe.subscriptions.update(subId, { cancel_at_period_end: true });

// Cancel immediately
await stripe.subscriptions.cancel(subId);
```

### Dunning (failed payment recovery)

Stripe Smart Retries attempts failed payments multiple times over ~3 weeks. Configure in Dashboard → Settings → Subscriptions and Emails:
- Retry schedule
- Final action (cancel or mark unpaid)
- Customer emails (toggle off if you send your own)

Wire `invoice.payment_failed` to your in-app dunning UI (banner, email from your system).

### Webhook-driven entitlement sync

The non-negotiable pattern: webhook is the only writer for billing state.

```typescript
async function handleSubscriptionUpdated(event: Stripe.Event) {
  const sub = event.data.object as Stripe.Subscription;
  const tenant = await db.tenants.findUnique({ where: { stripeCustomerId: sub.customer } });
  await db.tenants.update({
    where: { id: tenant.id },
    data: {
      plan: priceToPlan(sub.items.data[0].price.id),
      status: sub.status,
      currentPeriodEnd: new Date(sub.current_period_end * 1000),
    },
  });
  await refreshEntitlements(tenant.id);
}
```

Synchronous `subscriptions.create` response says `status: 'incomplete'`; webhook then fires `subscription.updated` with `status: 'active'`. Don't race — webhook wins.

## Anti-patterns

- **Trial without `trial_settings.end_behavior.missing_payment_method`.** Default creates a failed-charge invoice. Set to `cancel` for trials that don't require card upfront.
- **Granting access on `subscription.created` regardless of status.** `incomplete` means first payment failed; don't grant access until `active`.
- **Storing plan state from the synchronous `subscriptions.create` response.** The response is a snapshot; the webhook is the truth. Race conditions waiting.
- **Relying on `latest_invoice.payment_intent` shape.** Varies by API version; explicitly `expand` and check fields.
- **Calling `usage_records.create` for a new metered subscription.** Deprecated for new work; use [Meter API](/stacks/stripe/meter-api/).
- **Refunding inactive seats by hand.** Per-seat proration with `prorate_immediately: true` produces a credit on next invoice — usually correct for B2B.

## Gotchas

- **Subscription status state machine:** `trialing` → `active` → `past_due` → `unpaid` → `canceled`, with `incomplete` / `incomplete_expired` for initial-payment-failed cases. Each needs handling.
- **`incomplete_expired` after 23 hours** — Stripe expires incomplete subscriptions automatically. Don't keep state assuming they'll convert.
- **`billing_cycle_anchor: 'now'` shifts renewal date.** Use `unchanged` for in-period plan changes; use `now` only when you want to reset the cycle.
- **Annual subscriptions paid upfront** — recognize 1/12 per month (deferred revenue accounting). Stripe Revenue Recognition add-on automates this; otherwise your accounting team handles via [Data Pipeline](/stacks/stripe/stripe-data-pipeline/).
- **Webhook events you MUST handle:** `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`, `customer.subscription.trial_will_end`, `invoice.payment_succeeded`, `invoice.payment_failed`, `invoice.upcoming` (optional, for dunning warnings).

## Cross-references

- [Meter API](/stacks/stripe/meter-api/) — usage-based billing
- [Customer Portal](/stacks/stripe/customer-portal/) — self-service surface for subscriptions
- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — `mode: 'subscription'` signup flow
- [Setup Intents](/stacks/stripe/setup-intents/) — capture card during trial
- [Adaptive Pricing](/stacks/stripe/adaptive-pricing/) — multi-currency on subscriptions
- [Stripe Tax](/stacks/stripe/stripe-tax/) — automatic tax on invoices
- [Webhooks](/stacks/stripe/webhooks/) — subscription event handling
- [Stripe Sigma](/stacks/stripe/stripe-sigma/) — billing analytics
- [saas-architect on Stripe](/stacks/stripe/saas-architect/)
- Authoritative: [docs.stripe.com/billing](https://docs.stripe.com/billing)
