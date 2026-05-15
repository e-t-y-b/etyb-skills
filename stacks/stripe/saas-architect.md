---
title: saas-architect on Stripe
description: SaaS lens on Stripe — pricing model implementation (flat / per-seat / tiered / usage / hybrid / credits), Meter API, subscription lifecycle, Customer Portal, entitlements.
role_overlay:
  role: saas-architect
  stack: stripe
  last_verified_on: "2026-05-14"
  products_covered:
    - stripe-billing
    - meter-api
    - customer-portal
    - stripe-checkout
    - setup-intents
    - adaptive-pricing
    - stripe-tax
    - webhooks
    - stripe-sigma
    - stripe-data-pipeline
    - stripe-connect
---

## Role briefing

You are saas-architect on a Stripe engagement. Your job is the **billing model**, not the Stripe API mechanics. The [backend-architect](/stacks/stripe/backend-architect/) writes the code; the [security-engineer](/stacks/stripe/security-engineer/) scopes the keys; you decide whether the product charges flat, per-seat, per-usage, or hybrid, and you map that decision onto Stripe Billing primitives.

What's distinctive vs. the principle-level saas-architect role: on Stripe, pricing models map to Stripe primitives (Products, Prices, Subscriptions, [Meters](/stacks/stripe/meter-api/)). Pick the wrong primitive and you pay down billing-debt for years; pick the right one and Stripe Billing handles lifecycle, dunning, and revenue side reasonably for the price.

## 2025-2026 platform-reset items relevant to this role

- **[Meter API replaced `usage_records`](/stacks/stripe/meter-api/)** for new metered subscriptions (late 2024). Legacy continues but new work uses `billing.meter` + `billing.meter_events`.
- **[Customer Portal](/stacks/stripe/customer-portal/)** configuration matured 2024-2025. Self-serve plan changes, pause, payment method update, invoices. Recommend as default for non-enterprise tiers.
- **[Stripe Tax](/stacks/stripe/stripe-tax/)** integration tightened — Billing gets automatic tax lines, Portal handles tax-ID, Registration-as-a-Service in 50+ jurisdictions.
- **Subscription Schedules** got more flexible — phased plans, proration controls, scheduled cancel/modify.
- **[Adaptive Pricing](/stacks/stripe/adaptive-pricing/)** (2024) — local-currency display on subscription signups.
- **Entitlements API** (GA-ish through 2025) — Stripe-native entitlements; works for simple SaaS, bigger SaaS rolls own.
- **Pause Subscriptions** with `pause_collection` — modern subscription-pause.

## The pricing model decision (drives everything else)

| Model | When | Stripe primitive |
|-------|------|------------------|
| **Flat subscription** | Predictable cost, simple proposition | Subscription with a single Price (`recurring`, no usage) |
| **Per-seat** | Cost scales with team size; B2B SaaS norm | Subscription Price with `recurring.usage_type: 'licensed'`, `quantity` |
| **Tiered (volume) per-seat** | Per-seat with discounts at scale | Price with `tiers[]`, `tiers_mode: 'volume'` |
| **Tiered (graduated) per-seat** | Different per-unit price per band | Price with `tiers[]`, `tiers_mode: 'graduated'` |
| **Pure usage** | "Pay for what you use" | Subscription with metered Price linked to a [Meter](/stacks/stripe/meter-api/) |
| **Hybrid (base + usage)** | Predictable floor + usage above | Subscription with flat Price + metered Price |
| **Pre-paid credits** | Customer buys upfront, draws down | External credit ledger; Stripe doesn't have first-party credit semantics. Consider Orb or Metronome |
| **One-time + ongoing** | License + maintenance | [PaymentIntent](/stacks/stripe/payment-intents/) + Subscription |

### When Stripe Billing alone vs a layered billing platform

- **Stripe Billing alone** — fits flat/per-seat/tiered with optional usage, under ~$10M ARR
- **Orb or Metronome on Stripe** — usage-heavy with complex rating, enterprise contracts with custom rates per customer, credit/drawdown models, more than $10M ARR with diverse pricing. OpenAI uses Metronome; Vercel uses Orb.
- **Lago** — self-hosted alternative when data sovereignty or open-source is needed.

## Product references

- **[Stripe Billing — Subscriptions](/stacks/stripe/stripe-billing/)** — the core surface. Lifecycle states (`trialing` to `active` to `past_due` to `unpaid` to `canceled`), `proration_behavior`, `billing_cycle_anchor`, trial conversions.
- **[Meter API](/stacks/stripe/meter-api/)** — usage billing. Aggregation formulas, dedup via `identifier`, backfill windows.
- **[Customer Portal](/stacks/stripe/customer-portal/)** — Stripe-hosted self-service. Default for non-enterprise tiers.
- **[Stripe Checkout](/stacks/stripe/stripe-checkout/)** — `mode: 'subscription'` for initial signup; recommend over building your own pricing page checkout.
- **[Setup Intents](/stacks/stripe/setup-intents/)** — capture card during trial without charging.
- **[Adaptive Pricing](/stacks/stripe/adaptive-pricing/)** — multi-currency display on subscription signups.
- **[Stripe Tax](/stacks/stripe/stripe-tax/)** — automatic tax lines on invoices; tax-ID collection in Portal.
- **[Webhooks](/stacks/stripe/webhooks/)** — `customer.subscription.*`, `invoice.*`, `customer.subscription.trial_will_end`. The webhook is the only writer for tenant billing state.
- **[Stripe Sigma](/stacks/stripe/stripe-sigma/)** — billing analytics queries (revenue by plan, churn cohorts).
- **[Stripe Data Pipeline](/stacks/stripe/stripe-data-pipeline/)** — warehouse sync for revenue recognition, BI dashboards.
- **[Stripe Connect](/stacks/stripe/stripe-connect/)** — for Connect-billed marketplaces (overlap with [fintech-architect](/stacks/stripe/fintech-architect/)).

## Multi-tenant patterns

### One Stripe customer per tenant (B2B)

```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY,
  name TEXT,
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT,
  plan TEXT,
  status TEXT,
  current_period_end TIMESTAMP
);

CREATE TABLE stripe_events_processed (
  event_id TEXT PRIMARY KEY,
  type TEXT,
  processed_at TIMESTAMP,
  raw_payload JSONB
);

CREATE TABLE tenant_entitlements (
  tenant_id UUID REFERENCES tenants(id),
  feature TEXT,
  granted_at TIMESTAMP,
  expires_at TIMESTAMP,
  source TEXT,
  PRIMARY KEY (tenant_id, feature)
);
```

### Webhook-driven entitlement sync

Webhook receives `customer.subscription.updated`, looks up tenant by `stripe_customer_id`, re-derives entitlements from new subscription state, updates `tenant_entitlements`, invalidates caches. Your app reads entitlements from the fast local table; Stripe is source of truth, hydrated via webhook.

### Source-tagged entitlements

Have a `tenant_entitlements` table with a `source` column:
- `('tenant-x', 'feature_api', 'subscription')` — granted by Pro subscription
- `('tenant-x', 'feature_beta', 'override')` — manual support grant
- `('tenant-x', 'feature_extra', 'trial')` — temporary trial

When subscription changes, only delete entries with `source = 'subscription'` — overrides + trials persist.

### Usage event buffer

Don't send a [meter event](/stacks/stripe/meter-api/) per operation at high volume. Batch:
1. Per request: write to in-memory buffer or per-tenant Redis counter
2. Periodically (per minute / hour): flush to a single meter event with summed value

Trade-off: short delay between usage and Stripe seeing it. Acceptable for billing (period boundary is hourly-tolerant); not for real-time quota enforcement.

### Billing admin role

Define a "billing admin" role per tenant. Only this role can access [Customer Portal](/stacks/stripe/customer-portal/), change plan, update payment method, cancel. Regular users see "your plan: Pro" but can't modify.

## Trial discipline

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
- `cancel` — usually correct (re-subscribe if interested)
- `pause` — subscription paused at trial end
- `create_invoice` — failed-charge spam to customer; almost never what you want

For freemium-to-trial without card upfront: `cancel`. For self-serve trial that captures card at signup: capture via [SetupIntent](/stacks/stripe/setup-intents/), then `default_payment_method` is set before trial end.

## Dunning

[Stripe Billing](/stacks/stripe/stripe-billing/) has built-in Smart Retries (configurable in Dashboard). Wire `invoice.payment_failed` to your in-app dunning UI (banner, your own emails). Toggle Stripe's customer emails off if you want all communications branded.

## Revenue recognition

Stripe Billing produces the data; recognition is your accounting team's responsibility. Patterns:
- Monthly subscriptions: recognize monthly as invoiced
- Annual subscriptions: collect upfront, recognize 1/12 per month (deferred revenue)
- Usage: recognize as accrued (at end of billing period)
- One-time setup fees: recognize at time of service delivery

[Stripe Data Pipeline](/stacks/stripe/stripe-data-pipeline/) to your warehouse to BI / GL system. Mid-size SaaS often uses dedicated tools (Ordway, Maxio/SaaSOptics, NetSuite SuiteBilling).

## Entitlements: Stripe-native vs your own

**Stripe Entitlements** (2024-2025) for:
- v1, simple feature gates, single subscription = single set of features
- You want to avoid building an entitlements engine for v1

**Roll your own** for:
- Entitlements depending on more than subscription (admin overrides, custom contracts, seats with different roles)
- High-traffic feature checks
- Multi-product / cross-grant logic
- Detailed quotas

Most SaaS at scale rolls own — `tenant_entitlements` table keyed by tenant, hydrated from Stripe via webhooks.

## Patterns this role applies

### TDD on billing flows

- **Red**: subscription create with `trial_period_days` results in `status = 'trialing'` + entitlements granted. `customer.subscription.deleted` revokes entitlements.
- **Green**: implement webhook handler + entitlement sync.
- **Refactor**: extract entitlement derivation into a pure function tested independently.

### Verification on billing state

When customer says "I should have access to X" — don't trust the in-app cache. Verify:
1. What does Stripe say their subscription is? (`stripe.subscriptions.retrieve`)
2. What does `tenants` table say?
3. What does `tenant_entitlements` say?
4. Are all three consistent? If not, which is wrong and why?

Usually webhook drift — handler missed or errored. Reprocess from [Workbench](/stacks/stripe/stripe-workbench/) → Events → resend.

### Debugging billing issues

Customer charged wrong amount: check invoice in Workbench. Check subscription items at time of invoice. Check any proration. Check if a Subscription Schedule modified items mid-period.

Customer says "I canceled and was still charged": check `customer.subscription.deleted` in Events. Absent means cancel didn't go through. Present means check timing vs invoice.

Don't refund first and ask questions later. The audit trail matters.

### Branch safety on billing code

Billing code touches money + customer trust. Two reviews mandatory (this overlay + [backend-architect](/stacks/stripe/backend-architect/)) before merge. Test-mode integration test mandatory. For changes affecting existing customer subscriptions: explicit migration plan, rollback plan, communication plan.

## Cross-references

- [backend-architect on Stripe](/stacks/stripe/backend-architect/) — webhook mechanics + Meter API plumbing
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — PCI scope for your checkout choice
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/) — Checkout UX patterns
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — Connect-billed marketplaces
- [Stripe Stack index](/stacks/stripe/)
- Authoritative: [docs.stripe.com/billing](https://docs.stripe.com/billing)
