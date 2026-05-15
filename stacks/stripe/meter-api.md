---
title: Meter API
description: "Stripe's usage-based billing primitive — replaces legacy `usage_records` for new metered subscriptions. Mandatory for net-new usage billing."
product:
  name: Stripe Billing — Meter API
  stack: stripe
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [saas-architect, backend-architect]
  authoritative_url: https://docs.stripe.com/billing/subscriptions/usage-based
  notes: "Replaces legacy `usage_records`; deprecated for new subscriptions late 2024. Migration from legacy non-trivial — proration semantics differ."
---

## What it is

The Meter API is Stripe's modern usage-based billing surface. You define a `billing.meter` (what event name, how to aggregate, which customer to attribute), POST events as usage happens (`billing.meter_events`), and Stripe aggregates the events into invoice line items via `billing.meter_event_summary`.

It replaced legacy `usage_records` for net-new metered subscriptions in late 2024. **For new work, this is the only path.** Existing legacy usage-record subscriptions still function but the old `subscription_item.create_usage_record` endpoint is deprecated for new subscriptions.

Canonical reference: [docs.stripe.com/billing/subscriptions/usage-based](https://docs.stripe.com/billing/subscriptions/usage-based).

## When to use

Any time the [Subscription](/stacks/stripe/stripe-billing/) needs to bill per unit of consumption — API requests, GB stored, jobs run, AI tokens, anything metered.

| Need | Approach |
|------|----------|
| Net-new pure usage subscription | Meter API + metered Price |
| Hybrid (base + usage) | Subscription with flat Price + metered Price linked to a Meter |
| Existing legacy `usage_records` subscriptions | Leave on legacy until planned migration window |
| Complex rating (commitments, drawdown, custom rates) | [Orb](https://www.withorb.com/) or [Metronome](https://metronome.com/) layered on Stripe |

## 2025-2026 currency anchors

- **Mandatory for new metered subscriptions** since late 2024. If your code calls `stripe.subscriptionItems.createUsageRecord(...)` for a brand-new subscription, you're using the deprecated path.
- **Aggregation formulas**: `sum`, `count`, `last`, `max`. Pick at meter creation; cannot change easily later.
- **`customer_mapping`** maps the event payload to a Customer. Standard pattern: include `stripe_customer_id` in the event payload.
- **Backfill window** — events more than a few hours old may not aggregate into the current period. Send promptly; if you batch, batch with small windows.

## Patterns

### Create a meter (one-time)

```typescript
const meter = await stripe.billing.meters.create({
  display_name: 'API requests',
  event_name: 'api_request',
  default_aggregation: { formula: 'sum' },
  customer_mapping: {
    event_payload_key: 'stripe_customer_id',
    type: 'by_id',
  },
  value_settings: {
    event_payload_key: 'value',
  },
});
```

### Create a metered Price linked to the meter

```typescript
const price = await stripe.prices.create({
  product: 'prod_api_usage',
  currency: 'usd',
  unit_amount: 1,  // $0.01 per request
  recurring: {
    interval: 'month',
    usage_type: 'metered',
    meter: meter.id,
  },
});
```

### Send meter events as usage happens

```typescript
await stripe.billing.meterEvents.create({
  event_name: 'api_request',
  payload: {
    stripe_customer_id: customer.id,
    value: '1',  // count this request — or batch with a higher value
  },
  identifier: `req-${requestId}`,  // dedup key
});
```

### Subscription with metered Price

```typescript
const subscription = await stripe.subscriptions.create({
  customer: customer.id,
  items: [
    { price: 'price_base_plan' },       // $20/mo base
    { price: 'price_metered_api' },     // $0.001 per request via Meter
  ],
});
```

### Aggregation formulas — pick the right one

- **`sum`** — total of `value` across events ("total requests this period")
- **`count`** — number of events regardless of value ("number of jobs")
- **`last`** — latest reported value within the period ("storage GB at end of period")
- **`max`** — peak value during the period ("peak concurrent connections")

Choose based on the meaning of the meter — `sum` for additive consumption, `last` for gauge-style state, `max` for peak-pricing.

### Idempotency on meter events

`identifier` is the dedup key. Use a deterministic seed (request ID, job ID, batch ID + index). If your system retries event submission, the same identifier dedupes.

### Buffer pattern for high-volume events

Don't send a meter event per request at high volume. Batch:

1. Per request: write to in-memory or per-tenant Redis counter
2. Periodically (every minute / hour): flush to a single meter event with summed value

Trade-off: short delay between usage and Stripe seeing it. Acceptable for billing (period boundaries are hourly-tolerant); not acceptable for real-time quota enforcement (use a separate mechanism for quotas).

### Hybrid: base + overage

Option 1 — Tiered metered Price: first tier `unit_amount: 0` up to N units, then per-unit rate above. Base Price covers the included quantity; tier handles overage.

Option 2 — Two meters: a "free quota" meter + an "overage" meter. Your app decides which to credit based on current usage. More flexible (variable included quantities per-customer) but more code.

## Anti-patterns

- **Calling `usage_records.create` for a new subscription.** Deprecated for new work. Use Meter API.
- **Random UUIDs as `identifier`.** Defeats dedup if your retry logic re-mints them. Use deterministic IDs.
- **Trying to edit meter events.** They're immutable. To correct overcounting, send a negative event (if your aggregation supports it — `sum` does) or issue a credit note.
- **Sending events long after they occurred.** Outside the backfill window, events attribute to the wrong period or don't count.
- **One meter for everything.** Multiple consumption dimensions get separate meters — easier to price, easier to debug.

## Gotchas

- **Period boundaries are tied to event `timestamp`.** Events sent at period-end with stale timestamps may attribute to the previous period. Be careful with replay during outage recovery.
- **`meter_event_summary` is read-only** — you query it to inspect aggregates, can't write.
- **Migration from legacy `usage_records` is non-trivial.** Proration semantics differ: legacy aggregated via `usage_record` rows tied to `subscription_item`; Meter aggregates events tied to `customer`, attributed to subscriptions via the linked Price's meter. Cutover mid-period requires careful handling of in-flight events.
- **For complex rating (commitments, drawdown, tiered with included quantity per-customer)** — Stripe's Meter API is functional but Orb/Metronome have richer primitives.

## Cross-references

- [Stripe Billing — Subscriptions](/stacks/stripe/stripe-billing/) — the Subscriptions that consume metered Prices
- [Webhooks](/stacks/stripe/webhooks/) — `invoice.created`, `invoice.payment_succeeded` for metered cycles
- [Idempotency Keys](/stacks/stripe/idempotency-keys/) — `identifier` field semantics
- [saas-architect on Stripe](/stacks/stripe/saas-architect/) — pricing model context
- [backend-architect on Stripe](/stacks/stripe/backend-architect/) — Meter event ingestion plumbing
- Authoritative: [docs.stripe.com/billing/subscriptions/usage-based](https://docs.stripe.com/billing/subscriptions/usage-based)
