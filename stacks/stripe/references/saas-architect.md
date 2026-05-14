---
role: saas-architect
stack: stripe
last_verified_on: "2026-05-14"
last_verified_api_version: "2025-11-15.acacia"
---

# Stripe Overlay — saas-architect

You are saas-architect on a Stripe engagement. Your job is the **billing model**, not the Stripe API mechanics. Backend-architect writes the code; security-engineer scopes the keys; you decide whether the product charges flat, per-seat, per-usage, or hybrid, and you map that decision onto Stripe Billing primitives (Products, Prices, Subscriptions, Invoices, Meters). Get this wrong and you'll be paying down billing-debt for years; get it right and Stripe Billing handles the lifecycle, dunning, and revenue side reasonably well for the price.

**Currency:** Stripe Billing as of 2026-05-14, API version `2025-11-15.acacia`. Verify [docs.stripe.com/billing](https://docs.stripe.com/billing) and the changelog if more than 6 months past `last_verified_on`.

## What changed in 2025-2026 that older training data misses

- **Meter API replaced `usage_records` for new metered subscriptions** (announced late 2024, default for new work through 2025). Legacy metered subscriptions continue to function, but **new metered subscriptions should use `billing.meter` + `billing.meter_events`**. The semantic differences are non-trivial — see below.
- **Customer Portal** configuration matured 2024-2025. Self-serve plan changes, pause subscription, update payment method, view invoices all available. Configurable feature toggles. Recommend it as the default tenant self-service surface for any non-enterprise tier.
- **Tax** integration tightened. Stripe Tax + Stripe Billing now interoperate cleanly: invoices get automatic tax lines, Customer Portal handles tax-ID collection, registration-as-a-service available in 50+ jurisdictions.
- **Subscription Schedules** got more flexible: phased plans (intro pricing → main pricing), proration controls, scheduled cancellations and modifications all first-class.
- **Adaptive Pricing** (2024) — Checkout displays prices in the buyer's local currency on subscription signups. Requires multi-currency Prices and Tax to be configured coherently.
- **Entitlements API** (Stripe's native entitlements, GA-ish through 2025) — Stripe can now answer "does customer X have feature Y?" based on subscription state. Useful for simple SaaS; bigger SaaS still rolls own entitlements engine. See below.
- **Pause Subscriptions** with `pause_collection` is the modern equivalent of "subscription pause." Different from canceling — keeps the subscription record, just stops creating invoices.

## The pricing model decision (drives everything else)

The billing model is a product decision before it's a Stripe decision. Stripe can implement any of these; the wrong choice creates the wrong incentive structure for your business and customers.

| Model | When | Stripe primitive |
|-------|------|------------------|
| **Flat subscription** | Predictable cost, simple proposition ("$29/mo for the app") | Subscription with a single Price (`recurring`, no usage) |
| **Per-seat** | Cost scales with team size; B2B SaaS norm | Subscription Price with `recurring.usage_type: 'licensed'`, `quantity` = seat count |
| **Tiered (volume) per-seat** | Per-seat with discounts at scale | Subscription Price with `tiers[]`, `tiers_mode: 'volume'` |
| **Tiered (graduated) per-seat** | Different per-unit price for each band ("first 10 seats at $20, next 90 at $15, rest at $10") | Subscription Price with `tiers[]`, `tiers_mode: 'graduated'` |
| **Pure usage** | "Pay for what you use" (API calls, GB stored, jobs run) | Subscription with metered Price linked to a `billing.meter` |
| **Hybrid (base + usage)** | Predictable floor + usage above ("$50/mo includes 1000 calls, $0.001 each thereafter") | Subscription with a flat Price + a metered Price with included quantity |
| **Pre-paid credits** | Customer buys credits upfront, draws down with usage | Custom — combine PaymentIntents (top-up) + Meter events for drawdown; or use a billing platform like Orb/Metronome layered on Stripe |
| **One-time + ongoing** | License fee + maintenance | PaymentIntent for one-time + Subscription for ongoing |

### Per-seat: the most common SaaS model, the most common Stripe mistake

Per-seat sounds simple. The wrinkles in Stripe:

1. **Quantity changes mid-cycle generate proration.** When a customer adds a seat on day 20 of a 30-day cycle, Stripe creates an invoice item for the prorated 10 days. Default behavior: invoice item is generated, charged on next invoice. Configurable via `proration_behavior: 'create_prorations' | 'always_invoice' | 'none'`.

2. **`always_invoice` immediately invoices on quantity change** — good for B2B where customers expect a charge for adding seats, surprising for customers who expected the next bill to roll up changes.

3. **`none` skips proration** — looks neat, but you're giving away (or overcharging) the partial period.

4. **Decreasing seats** — typically you don't refund, you let the seat decrease take effect at the next renewal. Proration with `prorate_immediately: true` produces a credit on next invoice; this is usually correct for B2B.

5. **Seat sync from your app to Stripe** — needs to be bulletproof. Source of truth: your app's user table. Sync to Stripe on add/remove. Subscribe to `customer.subscription.updated` to verify the sync (and to catch admin Dashboard edits if you allow them).

### Pure usage: the hardest model

Usage-based billing in Stripe (2026):

1. Create a `billing.meter` per consumption dimension (API calls, GB stored, jobs run, etc.).
2. Create Prices with `recurring.usage_type: 'metered'` and `recurring.meter: <meter_id>`.
3. As usage happens, POST events to `billing.meter_events`.
4. Stripe aggregates the events into meter_event_summaries; at period end, applies the Price's rating logic and generates invoice items.

```typescript
// One-time setup: create the meter
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

// One-time setup: create the metered Price
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

// Per-request: send a meter event
await stripe.billing.meterEvents.create({
  event_name: 'api_request',
  payload: {
    stripe_customer_id: customer.id,
    value: '1',  // count of requests, or a numeric value to sum
  },
  identifier: `req-${requestId}`,  // dedup key
});
```

Gotchas:

- **Idempotency on meter events** is the `identifier` field. Use the request ID or job ID — something deterministic.
- **Late events have a backfill window** — events more than a few hours old may not aggregate into the current period. Send promptly.
- **Meter events are immutable.** You can't "edit" a meter event. To correct overcounting, send a *negative* event (if your meter aggregation supports it — `sum` does) or issue a credit note.
- **Aggregation formulas**: `sum`, `count`, `last`, `max`. `sum` for "total requests"; `count` for "number of events" regardless of value; `last` for "the latest gauge reading" (storage used at end of period); `max` for "peak usage during period."
- **Period boundaries**: meter events are attributed to the period containing their timestamp. Closing the books for a period: events sent up to a small grace window after period end can still attribute back; events later attribute to the new period.

### Hybrid: base + usage

The most common monetization model for usage SaaS. Architectural pattern:

```typescript
// Subscription with a flat base + a metered overage
const sub = await stripe.subscriptions.create({
  customer: customer.id,
  items: [
    { price: 'price_base_plan' },         // $50/mo, includes 1000 calls
    { price: 'price_overage_per_call' },  // $0.001 per call beyond 1000
  ],
});
```

To implement "includes N free" semantics:

- **Option 1 — Tiered metered Price**: a metered Price with `tiers[]` where the first tier is `unit_amount: 0` up to N units, then the per-unit rate after. The base plan covers the included quantity; the overage tier handles excess.
- **Option 2 — Two meters**: a "free quota" meter that tracks usage up to the threshold, an "overage" meter that tracks usage above it. Your app decides which meter to credit based on the customer's current usage. More flexible but more code.

Tiered is simpler; two-meter is more flexible (lets you change the included quantity per-customer without re-tier-ing the Price).

### Credit-based / pre-paid

Stripe doesn't have first-party credit semantics (as of API `2025-11-15.acacia`). Patterns:

- **External credit ledger**: your DB stores credit balance per customer. Customer tops up via PaymentIntent. Usage decrements the balance. When balance ≤ 0, deny service or trigger an auto-top-up PaymentIntent.
- **Stripe Invoice items as credit memos**: less common, harder to reason about. Generally avoid.
- **Use a billing platform layered on Stripe**: Orb or Metronome have native credit/drawdown semantics. They use Stripe as the payment processor but own the credit ledger.

For volume credit/drawdown at scale: Orb (used by Vercel, Stytch, Replit, Perplexity) or Metronome (used by OpenAI, Databricks, Cloudflare). Stripe's native primitives don't cover this well in 2026.

## Subscription lifecycle — states and transitions

The subscription state machine:

```
       create ────────► trialing ───── trial ends ─────┐
          │              │ (if trial_period_days)        │
          │              ▼                                ▼
          └────────► active ──── payment fails ──► past_due ──┐
                       │                                       │
                       │                                       ▼
                       ▼                                  unpaid ──► canceled
                  pause_collection                              │
                       │                                       │
                       ▼                                       │
                  active (resumed)                             │
                       │                                       │
                       ▼                                       │
                    canceled ◄─────────────────────────────────┘
                       │
                       ▼
                  ended/deleted
```

States to handle:

| Status | Meaning | Action |
|--------|---------|--------|
| `trialing` | Trial period active | Grant access; remember to handle `trial_will_end` (3-day-out warning) |
| `active` | Paid and current | Full access |
| `past_due` | Payment failed but retries pending | Continue access during retry window; show warning to user |
| `unpaid` | All retries exhausted; final state before cancel | Revoke access (or downgrade); show urgent payment-failed message |
| `canceled` | Subscription canceled | Revoke access at period end (if `cancel_at_period_end: true`) or immediately |
| `incomplete` | First payment failed (initial creation) | Don't grant access; customer hasn't actually paid |
| `incomplete_expired` | First payment failed and abandoned | No access; subscription is dead |

### Trial conversions

```typescript
const sub = await stripe.subscriptions.create({
  customer: customer.id,
  items: [{ price: 'price_id' }],
  trial_period_days: 14,
  trial_settings: {
    end_behavior: {
      missing_payment_method: 'cancel',  // or 'pause' or 'create_invoice'
    },
  },
});
```

`trial_settings.end_behavior.missing_payment_method`:
- `cancel` — subscription canceled at trial end if no payment method
- `pause` — subscription paused (no invoices, no access) at trial end
- `create_invoice` — invoice created and customer is `past_due` (rarely what you want)

For freemium-to-trial flows: cancel is usually correct. The customer can always re-subscribe.

For self-serve trials where you want to capture the payment method upfront: collect via SetupIntent or PaymentIntent setup-mode at signup, then `default_payment_method` is set before trial ends.

### Dunning (failed payment recovery)

Stripe has built-in smart retries (Stripe Smart Retries) that attempt failed payments multiple times over several days. Configurable in Dashboard → Settings → Subscriptions and Emails.

| Setting | Default | Notes |
|---------|---------|-------|
| Retry schedule | Up to 4 retries over ~3 weeks | Customize based on your customer base — B2B can tolerate longer, B2C usually wants faster resolution or cancel |
| Final action | Cancel subscription | Or mark `unpaid` and require manual reactivation |
| Customer emails | Sent by Stripe | Toggle off if you want to send your own dunning emails with your branding |
| In-app notifications | Your responsibility | Webhook `invoice.payment_failed` → show banner / send email from your system |

### Pause vs cancel

`subscription.pause_collection`:
- Stripe stops creating invoices for the subscription
- Subscription stays in `active` status (with `pause_collection` populated)
- Customer can resume without re-onboarding

Use pause for:
- Seasonal customers (gym memberships paused over summer)
- Voluntary pause requests (Customer Portal supports this)
- Hold-on-account flows where you want to retain the customer rather than cancel

Use cancel for:
- Customer has clearly left
- Account-closure flows
- Compliance-driven offboarding

## Customer Portal — the self-service surface

Stripe-hosted portal at `billing.stripe.com/p/login/<id>`. Configurable features:
- Update payment method
- View invoices and payment history
- Cancel subscription (immediately or at period end)
- Pause subscription
- Change plan / quantity (within configured allowed plans)
- Update billing info (address, tax ID)
- Apply promotion codes

Setup:

```typescript
// One-time: configure the portal (Dashboard or API)
const config = await stripe.billingPortal.configurations.create({
  business_profile: { headline: 'Manage your subscription' },
  features: {
    payment_method_update: { enabled: true },
    subscription_cancel: { enabled: true, mode: 'at_period_end' },
    subscription_pause: { enabled: true },
    subscription_update: {
      enabled: true,
      default_allowed_updates: ['quantity', 'price'],
      products: [/* allowed product/price combinations */],
    },
    invoice_history: { enabled: true },
  },
});

// Per-session: create a portal session and redirect
const session = await stripe.billingPortal.sessions.create({
  customer: customer.id,
  return_url: `${BASE_URL}/billing-return`,
});
// redirect customer to session.url
```

**Recommend Customer Portal as the default for any non-enterprise tier.** Building your own billing UI is a year of work that doesn't differentiate your product. Enterprise customers may want in-app billing UI for SSO/compliance reasons; everyone else uses the portal.

Limitations:
- Branding is limited (logo + colors; no custom CSS)
- Can't show in-app entitlement details — only Stripe-side state
- Can't trigger custom flows in your app — you can only redirect to portal and capture return

## Plan migrations and proration

Plan changes mid-cycle are the trickiest part of billing.

```typescript
// Upgrade customer to a more expensive plan
const sub = await stripe.subscriptions.update(subscriptionId, {
  items: [
    { id: currentItemId, price: 'price_new_plan' },
  ],
  proration_behavior: 'create_prorations',  // 'always_invoice' | 'create_prorations' | 'none'
  billing_cycle_anchor: 'unchanged',  // or 'now' to reset the cycle
});
```

`proration_behavior`:
- `create_prorations` — invoice item created on next invoice. Default. Good for "smooth out the difference at next bill."
- `always_invoice` — invoice immediately. Good when you want the customer to pay the difference now (upgrades to higher tier).
- `none` — no proration. Simplest, but loses (or overcharges) the partial period. Sometimes appropriate for "free upgrade" promotions.

`billing_cycle_anchor`:
- `unchanged` — keep the same renewal date. Default. Customer's bill date doesn't shift.
- `now` — reset the cycle. Customer's next renewal is one period from now. Useful for "give me a full new period when I upgrade."

### Downgrades

Downgrading usually defers to next period: schedule the downgrade for period end rather than immediate. Use Subscription Schedules:

```typescript
const schedule = await stripe.subscriptionSchedules.create({
  customer: customer.id,
  start_date: 'now',
  phases: [
    {
      items: [{ price: 'price_current_plan', quantity: 5 }],
      end_date: currentPeriodEnd,
    },
    {
      items: [{ price: 'price_lower_plan', quantity: 5 }],
    },
  ],
});
```

Phased pricing also handles introductory pricing ("first 3 months at $10/mo, then $30/mo"):

```typescript
const schedule = await stripe.subscriptionSchedules.create({
  customer: customer.id,
  start_date: 'now',
  phases: [
    {
      items: [{ price: 'price_intro' }],  // $10/mo
      iterations: 3,
    },
    {
      items: [{ price: 'price_main' }],  // $30/mo
    },
  ],
});
```

## Tax handling

Stripe Tax automatically calculates sales tax / VAT / GST per jurisdiction. Setup:

1. **Configure tax** in Dashboard → Tax. Set your tax registrations (or use Stripe Tax Registrations-as-a-Service in supported countries).
2. **Enable on Subscriptions/Checkout**: `automatic_tax: { enabled: true }`.
3. **Customer tax info**: Stripe needs the customer's address. Collect via Checkout (`billing_address_collection: 'required'`) or pre-fill on the Customer.
4. **Tax IDs**: B2B customers may have reverse-charge / VAT-ID treatment. Collect via Customer Portal or `customer.tax_ids.create`.

```typescript
const sub = await stripe.subscriptions.create({
  customer: customer.id,
  items: [{ price: 'price_id' }],
  automatic_tax: { enabled: true },
});
```

The invoice gets a tax line automatically. Stripe handles the calculation, the jurisdiction logic, and tax registration if you're using Registrations-as-a-Service.

**Reverse-charge / VAT-exempt B2B**: when the customer has a valid VAT ID and is in the EU buying from a different EU country, the invoice is reverse-charge (zero VAT, customer self-assesses). Stripe handles this automatically if `automatic_tax` is enabled and the tax ID is valid.

**Where this falls short**: Stripe Tax doesn't cover every jurisdiction. Some emerging markets (Brazil, India for certain transaction types) need separate handling. For complex international operations: Avalara or TaxJar may still be needed, layered on Stripe.

## Adaptive Pricing (multi-currency display)

Adaptive Pricing (2024) shows checkout prices in the buyer's local currency, with Stripe handling the conversion and absorbing the FX cost (with a markup). To enable:

1. Create Prices in multiple currencies (`stripe.prices.create` with `currency_options[]`).
2. Enable Adaptive Pricing per Checkout session or Payment Element.
3. Stripe presents the price in the local currency at checkout.

When to use:
- B2C with global customer base — conversion lifts measurably from showing local prices
- D2C subscriptions where the customer cares about the round number ($9.99 → €9.99 → £8.99 round numbers, not direct FX conversions)

When NOT to use:
- B2B enterprise pricing — invoiced in your billing currency regardless
- Low-margin businesses where the Adaptive Pricing markup eats into margin

## Entitlements: Stripe-native vs your own

Stripe has an Entitlements API (introduced 2024, evolved 2025). Lightweight model:
- Define `features` per Product
- Customer's active subscription grants those features
- Query `customer.entitlements` to check what they have

```typescript
const entitlements = await stripe.entitlements.activeEntitlements.list({
  customer: customer.id,
});
// entitlements.data is the array of feature IDs the customer has access to
```

When to use Stripe Entitlements:
- Simple SaaS with feature gates ("pro plan has feature_X")
- You want to avoid building an entitlements engine for v1
- Subscription state is the only thing that grants entitlements

When to roll your own entitlements:
- Entitlements depend on more than subscription (admin overrides, custom contracts, seats with different roles)
- High-traffic feature checks (you don't want to hit Stripe API on every request — though caching helps)
- Multi-product cross-grants ("Plan A buyer also gets feature from Product B")
- Detailed quota tracking, usage caps, fine-grained permissions

Most SaaS at scale builds its own — a `feature_flags` or `entitlements` table keyed by tenant, hydrated from Stripe state via webhooks. Use Stripe entitlements for v1 / prototypes; graduate to your own when complexity demands.

## Revenue recognition

Stripe Billing produces the data; recognition is your accounting team's responsibility. Stripe Revenue Recognition (an add-on) automates the recognition schedule for common patterns (deferred revenue on annual subscriptions, recognition on usage).

For most SaaS:
- Monthly subscriptions: recognize monthly as invoiced
- Annual subscriptions: collect upfront, recognize 1/12 per month (deferred revenue accounting)
- Usage: recognize as accrued (at end of billing period, on invoice creation)
- One-time setup fees: recognize at time of service delivery (varies)

Stripe Data Pipeline → your warehouse → your BI tool / GL system. For mid-size SaaS this is enough; large SaaS uses dedicated tools (Ordway, Maxio/SaaSOptics, NetSuite SuiteBilling) for recognition.

## Webhook architecture for billing

The events your billing system MUST handle (this list is the saas-architect's responsibility to ensure backend-architect wires up):

| Event | Action |
|-------|--------|
| `customer.subscription.created` | Provision tenant; grant initial entitlements |
| `customer.subscription.updated` | Sync plan / quantity / status; re-evaluate entitlements |
| `customer.subscription.deleted` | Revoke entitlements (or schedule revocation if cancel-at-period-end) |
| `customer.subscription.trial_will_end` | Send 3-day-out trial reminder |
| `invoice.payment_succeeded` | Mark period as paid; record revenue |
| `invoice.payment_failed` | Start dunning UI; show banner to admin |
| `invoice.upcoming` | Optional: preview upcoming invoice for dunning warnings |
| `customer.updated` | Sync customer info (email, address) |
| `payment_method.attached` | Update default payment method if applicable |
| `payment_method.detached` | Clean up; warn if it was the default |
| `invoice.created` | Note: this fires BEFORE payment; don't grant access on this |
| `invoice.finalized` | Invoice is finalized and will be charged |

Backend-architect overlay has the mechanical detail on signature verification, idempotency, queue-fronting. From the saas-architect's perspective: ensure every state change you care about has a webhook handler.

## Multi-tenant patterns

### One Stripe customer per tenant

For B2B SaaS: tenant ↔ Stripe customer is the right cardinality. Users within the tenant don't have their own Stripe customers. The tenant's billing admin manages payment method via Customer Portal.

Schema:

```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY,
  name TEXT,
  stripe_customer_id TEXT UNIQUE,  -- cus_*
  stripe_subscription_id TEXT,      -- sub_*
  plan TEXT,                         -- denormalized for quick reads
  status TEXT,                       -- denormalized: active, past_due, canceled
  current_period_end TIMESTAMP,      -- denormalized
  -- ...
);

CREATE TABLE stripe_events_processed (
  event_id TEXT PRIMARY KEY,         -- evt_*
  type TEXT,
  processed_at TIMESTAMP,
  raw_payload JSONB                  -- optional: keep for debugging
);

CREATE TABLE tenant_entitlements (
  tenant_id UUID REFERENCES tenants(id),
  feature TEXT,
  granted_at TIMESTAMP,
  expires_at TIMESTAMP,
  source TEXT,                        -- 'subscription', 'override', 'trial'
  PRIMARY KEY (tenant_id, feature)
);
```

### Per-tenant usage tracking

For metered billing, your app records usage per tenant; you POST meter events to Stripe keyed by `stripe_customer_id`. Schema:

```sql
CREATE TABLE usage_events (
  id UUID PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id),
  meter_name TEXT,                    -- 'api_request', 'storage_gb', etc.
  value NUMERIC,
  occurred_at TIMESTAMP,
  reported_to_stripe BOOLEAN DEFAULT FALSE,
  reported_at TIMESTAMP,
  stripe_meter_event_id TEXT,         -- the identifier we sent
  -- ...
);
```

Report to Stripe asynchronously (batched or per-event). Track `reported_to_stripe` so you can retry stuck events.

### Billing admin role

In multi-tenant SaaS, define a "billing admin" role per tenant. Only this role can:
- Access Customer Portal
- Change plan
- Update payment method
- Cancel subscription

Regular users see "your plan: Pro" but can't modify billing.

## Decision frameworks

### When to use Stripe Billing vs a billing platform (Orb, Metronome, Lago)

**Use Stripe Billing alone** when:
- Pricing model is flat / per-seat / simple tiered with optional usage
- You don't have complex commitments / drawdown / credits
- You want one vendor for payments + billing
- You're under $10M ARR — Stripe Billing's surface scales fine to this point

**Layer Orb or Metronome on Stripe** when:
- Pricing is usage-heavy with complex rating (tiered + included + overage + commitments)
- You have enterprise contracts with custom rates per customer
- You need credit/drawdown models (pre-paid, contract commits)
- You're > $10M ARR with diverse pricing models
- Examples: API companies (OpenAI uses Metronome, Vercel uses Orb)

**Use Lago** when:
- You need self-hosted billing (data sovereignty, compliance)
- You want open-source and willing to operate it
- Your model is complex and you want code-level control

### When to use Subscription Schedule vs Subscription

**Subscription** for:
- Standard flat / per-seat / metered
- No phased pricing
- One renewal cycle (e.g., monthly forever or annual forever)

**Subscription Schedule** for:
- Phased pricing (intro pricing → main pricing → discount renewal)
- Scheduled plan changes (upgrade at end of period)
- Fixed-term contracts that auto-cancel after N periods
- Complex enterprise contracts

### When to use Stripe Entitlements vs your own

**Stripe Entitlements** for:
- v1, simple feature gates, single subscription = single set of features
- Small SaaS where building an entitlements engine isn't worth it

**Own entitlements** for:
- Override-able entitlements (admin grants, custom contracts)
- High-frequency checks (cache from Stripe via webhook, query your own table)
- Multi-product / cross-grant logic
- Fine-grained quotas

### When to use Customer Portal vs build your own billing UI

**Customer Portal** for:
- All self-serve SaaS tiers
- Standard billing operations (payment method, invoices, cancel, pause)
- Minimal engineering investment

**Build your own** for:
- Enterprise tier where customers need SSO into your billing UI
- Tight integration with admin features (e.g., "manage billing alongside team management")
- Custom workflows Stripe doesn't support (approval flows for plan changes, multi-step renewal negotiation)

Pragmatic default: Customer Portal for all tiers initially; build custom UI only when a specific enterprise customer demands it.

## Patterns and anti-patterns

### Pattern: webhook-driven entitlement sync

Webhook receives `customer.subscription.updated` → look up tenant by stripe_customer_id → re-derive entitlements from new subscription state → update `tenant_entitlements` table → invalidate any cached entitlements in your app.

This way, your app reads entitlements from a fast local table; Stripe is the source of truth, hydrated via webhook.

### Pattern: explicit entitlement record per source

Don't just have `tenant.plan = 'pro'`. Have a `tenant_entitlements` table with a `source` column. Examples:
- `('tenant-x', 'feature_api', 'subscription')` — granted by their Pro subscription
- `('tenant-x', 'feature_beta', 'override')` — manual grant by support
- `('tenant-x', 'feature_extra', 'trial')` — temporary trial of premium feature

When the subscription changes, you only delete entries with `source = 'subscription'` — overrides and trials persist correctly.

### Pattern: usage event buffer

Don't send a meter event for every operation. Batch usage events:
- Per request: write to local buffer (in-memory or per-tenant counter in Redis)
- Periodically (every minute / hour): flush buffer to Stripe meter events

Reduces meter API calls dramatically. Trade-off: short delay between usage and Stripe seeing it. Acceptable for billing (the period boundary is hourly-tolerant); not acceptable for real-time quota enforcement (use a different mechanism for quotas).

### Anti-pattern: storing plan state from synchronous API responses

You create a subscription, the response says `status: 'incomplete'`. You write that to your DB. Webhook then fires `customer.subscription.created` with `status: 'active'`. Race condition — your write may overwrite the webhook update.

Pattern: webhook is the only writer. The synchronous response is for redirect logic (e.g., "redirect to portal" or "show next-action page"), not for persistence.

### Anti-pattern: trial without trial_settings

`trial_period_days: 14` with no `trial_settings.end_behavior.missing_payment_method` defaults to creating an invoice (and going `past_due`). Customers who didn't add a card during trial then get a failed-charge email. Awful UX.

Set `trial_settings.end_behavior.missing_payment_method: 'cancel'` for any trial that doesn't require a card upfront.

### Anti-pattern: relying on `latest_invoice.payment_intent` shape

The Subscription object includes `latest_invoice` which includes `payment_intent` (in some API versions). The exact shape and whether it's expanded by default varies by API version. Don't hardcode "the path is `sub.latest_invoice.payment_intent.client_secret`" — explicitly expand and check.

### Anti-pattern: not handling `incomplete` subscriptions

When the first invoice payment fails, subscription is `incomplete`. If the customer never completes payment, it goes to `incomplete_expired`. Your code should:
- NOT grant access while `incomplete`
- Either prompt the customer to complete payment OR clean up after 23 hours (Stripe expires after 23h)

Lots of teams grant access on `subscription.created` regardless of status — leads to free service for failed payments until eventually `subscription.deleted` fires.

## Tooling specifics

- **Stripe Workbench** — Subscription view shows lifecycle, invoice history, retry status. Use this for debugging customer-specific billing issues.
- **Stripe CLI** — `stripe trigger customer.subscription.created`, `stripe trigger invoice.payment_failed` for local dev.
- **Stripe Sigma** — SQL queries for billing analytics ("revenue by plan this month," "churn cohort"). Saves building your own analytics on Stripe data.
- **Stripe Data Pipeline** — sync to Snowflake/BigQuery/Redshift for deeper analysis, BI dashboards, exec reporting.
- **Stripe-hosted MCP** — agents can read subscription state, list invoices, etc. For dev/debug workflows it's faster than navigating Dashboard.
- **Orb / Metronome / Lago** — layered billing platforms when Stripe Billing's surface isn't enough.

## Integration with always-on protocols

### TDD on billing flows

Red: test that creating a subscription with `trial_period_days` results in tenant `status = 'trialing'` and entitlements granted. Test that `customer.subscription.deleted` webhook revokes entitlements.

Green: implement webhook handler + entitlement sync.

Refactor: extract entitlement derivation into a pure function tested independently.

### Verification on billing state

When a customer says "I should have access to feature X" — don't trust the in-app cache. Verify:
1. What does Stripe say their subscription is? (`stripe.subscriptions.retrieve`)
2. What does your `tenants` table say their plan is?
3. What does your `tenant_entitlements` table say they have?
4. Are all three consistent? If not, which is wrong and why?

Usually webhook drift — a webhook was missed or your handler errored. Reprocess from Workbench → Events → resend.

### Debugging billing issues — root cause discipline

Customer charged wrong amount: check the invoice in Workbench. Check the subscription items at the time of the invoice. Check any proration that fired. Check if a Subscription Schedule modified the items mid-period.

Customer says they canceled and were still charged: check `customer.subscription.deleted` event in Events. If absent, the cancellation didn't go through. If present, check timing relative to the invoice.

Don't refund first and ask questions later — investigate, then resolve. The audit trail matters.

### Branch safety on billing code

Billing code touches money + customer trust. Two reviews mandatory (this overlay + backend-architect overlay) before merge. Test-mode integration test mandatory. For changes that affect existing customer subscriptions: explicit migration plan, rollback plan, communication plan if customer-visible.

## Cross-references

- [Webhook mechanics + signature verification → backend-architect.md](backend-architect.md)
- [Meter API mechanical detail → backend-architect.md](backend-architect.md#meter-api-for-usage-based-billing)
- [PCI scope for the checkout flow you build → security-engineer.md](security-engineer.md)
- [Checkout UX patterns → e-commerce-architect.md](e-commerce-architect.md)
- [Connect platform billing (marketplace, multi-tenant with seller billing) → fintech-architect.md](fintech-architect.md)
- [General billing platform comparison + non-Stripe patterns → `skills/etyb/references/verticals/saas-architect/references/billing-subscriptions.md`](../../../skills/etyb/references/verticals/saas-architect/references/billing-subscriptions.md)

## Products covered relevant to this role

Stripe Billing — Subscriptions, Meter API (replaces legacy metered subscriptions), Customer Portal, Stripe Checkout (subscription mode for signup), Setup Intents (for save-card-during-trial), Subscription Schedules, Adaptive Pricing, Stripe Tax (in billing context), Stripe Entitlements API, Webhooks (billing events), Stripe Sigma + Data Pipeline (billing analytics), Stripe Connect (Connect-billed marketplaces — overlap with fintech-architect).
