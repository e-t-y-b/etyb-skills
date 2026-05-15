---
title: Stripe Connect
description: "Platform infrastructure for marketplaces and multi-party payments. `controller` properties replaced legacy `type` in 2024 — liability config is now explicit."
product:
  name: Stripe Connect
  stack: stripe
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, backend-architect, security-engineer, saas-architect]
  authoritative_url: https://docs.stripe.com/connect
  notes: "Controller properties (2024) replaced legacy `type: 'custom' | 'express' | 'standard'`. Legacy still works but maps internally. Connect Embedded Components also 2024 GA."
---

## What it is

Stripe Connect is the platform infrastructure for moving money between multiple parties — marketplaces (Etsy/Airbnb-style), platforms that facilitate seller transactions (Lyft/DoorDash-style), and SaaS platforms that embed payments for their customers' customers. Connect handles:

- **Connected account creation + KYC** (sellers, providers, sub-merchants)
- **Charge models** — direct, destination, separate charges and transfers
- **Onboarding** — Stripe-hosted account_link, or Connect Embedded Components, or fully custom
- **Capabilities** — what each connected account is approved to do (card_payments, transfers, treasury, card_issuing)
- **Platform-level webhooks** — `account.updated`, `capability.updated`, `person.*`, `payout.*`, `transfer.*`, `application_fee.*`

Canonical reference: [docs.stripe.com/connect](https://docs.stripe.com/connect).

## When to use

You're building a platform. There are three relationships to choose between:

1. **You are the merchant**, sellers/contractors are paid by you — not Connect; just pay them via [Treasury](/stacks/stripe/stripe-treasury/) OutboundPayment or ACH.
2. **Sellers are the merchant**, you facilitate transactions and take a fee — **Connect**.
3. **Hybrid marketplace** — Connect with charge model varying per transaction.

## 2025-2026 currency anchors

- **`controller` properties replaced `type`** (2024). New accounts configure `controller.fees.payer`, `controller.losses.payments`, `controller.stripe_dashboard.type`, `controller.requirement_collection`. Legacy `type: 'custom' | 'express' | 'standard'` shorthand still works but maps internally.
- **Connect Embedded Components** (2024 GA) — UI components platforms embed instead of redirecting to Stripe-hosted pages. Onboarding, payouts dashboard, account management, documents.
- **Onboarding via `account_link`** with `type: account_onboarding` is the modern pattern. Legacy email-based "Connect Onboarding" redirects are phasing out.
- **Capability state changes** still flow through `account.updated` and `capability.updated` webhooks — wire both.

## The controller properties decision

The 2024+ way to create a connected account:

```typescript
const account = await stripe.accounts.create({
  controller: {
    stripe_dashboard: { type: 'express' | 'full' | 'none' },
    fees: { payer: 'application' | 'account' },
    losses: { payments: 'application' | 'stripe' },
    requirement_collection: 'stripe' | 'application',
  },
  country: 'US',
  email: seller.email,
  capabilities: {
    card_payments: { requested: true },
    transfers: { requested: true },
  },
});
```

### What each property means

| Property | Value | Behavior |
|----------|-------|----------|
| `stripe_dashboard.type` | `full` | Full Stripe Dashboard (standard-equivalent) |
| | `express` | Stripe Express Dashboard (lightweight) |
| | `none` | No Stripe dashboard; you build the UI |
| `fees.payer` | `application` | Platform pays Stripe fees separately from `application_fee_amount` |
| | `account` | Connected account pays Stripe fees from their gross |
| `losses.payments` | `application` | **Platform takes losses** on chargebacks |
| | `stripe` | Stripe takes losses (limited config combos) |
| `requirement_collection` | `stripe` | Stripe-hosted onboarding via `account_link` |
| | `application` | Platform collects requirements via API |

### Legacy shorthand mapping

- `type: 'standard'` ≈ `{ stripe_dashboard.type: 'full', fees.payer: 'account', losses.payments: 'stripe', requirement_collection: 'stripe' }`
- `type: 'express'` ≈ `{ stripe_dashboard.type: 'express', fees.payer: 'application', losses.payments: 'stripe', requirement_collection: 'stripe' }`
- `type: 'custom'` ≈ `{ stripe_dashboard.type: 'none', fees.payer: 'application', losses.payments: 'application', requirement_collection: 'application' }`

For new builds: **prefer the explicit controller properties form.** Makes liability decisions explicit at account creation time.

### Choosing the configuration

| Scenario | Config |
|----------|--------|
| Onboard sellers quickly, Stripe takes losses, sellers see Stripe Dashboard | Standard-equivalent |
| Embedded-feel UX, Stripe-hosted onboarding + dashboards | Express-equivalent |
| Full white-label, built KYC + dashboards, accepted loss exposure | Custom-equivalent — but read [fintech-architect](/stacks/stripe/fintech-architect/) on liability prerequisites |
| Polished in-app feel with Stripe handling backend | `stripe_dashboard.type: 'none'` + Connect Embedded Components |

## Patterns

### Modern onboarding

```typescript
const account = await stripe.accounts.create({
  controller: { /* ... */ },
  country: 'US',
  email: seller.email,
  metadata: { internal_seller_id: seller.id },
}, { idempotencyKey: `account-create-${seller.id}` });

const accountLink = await stripe.accountLinks.create({
  account: account.id,
  refresh_url: `${BASE_URL}/connect/refresh?account=${account.id}`,
  return_url: `${BASE_URL}/connect/return?account=${account.id}`,
  type: 'account_onboarding',
});
// Redirect to accountLink.url
```

The seller completes KYC on Stripe-hosted pages. After return, listen for `account.updated` with `details_submitted: true` and `capabilities.*` transitioning to `active`.

### Connect Embedded Components

```typescript
// Server: account session with component permissions
const session = await stripe.accountSessions.create({
  account: connectedAccountId,
  components: {
    account_onboarding: { enabled: true },
    payouts: { enabled: true },
    account_management: { enabled: true },
  },
});

// Frontend: mount
const stripeConnect = await loadConnectAndInitialize({
  publishableKey: 'pk_live_xxx',
  fetchClientSecret: async () => session.client_secret,
});
const onboarding = stripeConnect.create('account-onboarding');
document.getElementById('container').appendChild(onboarding);
```

### Direct charges

```typescript
const pi = await stripe.paymentIntents.create(
  { amount: 10000, currency: 'usd', application_fee_amount: 200 },
  { stripeAccount: connectedAccountId },
);
```

Customer statement shows the connected account; funds settle to them less the fee. Use when each seller is a distinct merchant to the buyer (Etsy/Shopify model).

### Destination charges

```typescript
const pi = await stripe.paymentIntents.create({
  amount: 10000,
  currency: 'usd',
  application_fee_amount: 200,
  transfer_data: { destination: connectedAccountId },
});
```

Statement shows the platform; funds auto-transfer. Platform is merchant of record. Lyft/Uber/DoorDash model.

### Separate charges and transfers

```typescript
const pi = await stripe.paymentIntents.create({ amount: 10000, currency: 'usd' });
// later:
const transfer = await stripe.transfers.create({
  amount: 9800,
  currency: 'usd',
  destination: connectedAccountId,
  source_transaction: pi.latest_charge as string,
});
```

Most flexible — split-pay across multiple recipients, delayed payouts, escrow-like holds (combine with manual capture).

### Capability gating

```typescript
async function canSellerAcceptPayments(sellerId: string): Promise<boolean> {
  const account = await db.connectedAccounts.findUnique({ where: { sellerId } });
  return account?.capabilities?.card_payments === 'active';
}
```

Source of truth: local DB hydrated from `account.updated` webhooks. Check capability state before allowing seller-facing actions.

## Anti-patterns

- **Missing `account.updated` handler.** Connect platforms without this won't know when capabilities change. Stripe pauses for fraud review → your platform happily takes orders → all orders fail.
- **`controller.losses.payments: 'application'` without capital + monitoring + recovery.** You're on the hook for unrecovered chargebacks. Don't take losses without the underwriting framework.
- **Ignoring `capability.updated`.** More granular than `account.updated`. Use it: if `transfers` goes inactive, pause that seller's payouts UI immediately.
- **Custom Connect onboarding redirect logic when `account_link` does the job.** Stripe's hosted onboarding handles KYC, document collection, verification. Don't roll your own.
- **Forgetting `stripeAccount` header on connected-account operations.** Most Connect API calls run "as" the connected account; missing the header queries the platform's resources instead.
- **Stripe as the ledger.** Stripe is a payment processor. See [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) for ledger design.

## Gotchas

- **Webhook delivery for connected accounts** — events can flow to the platform's main endpoint (with `account` field set), or to per-account endpoints (with `Stripe-Account` header set). Wire both styles deliberately.
- **`account.requirements.disabled_reason`** tells you why an account is in trouble (`requirements.past_due`, `rejected.fraud`, `platform_paused`). Surface to the seller.
- **Capability state isn't binary.** Possible states: `inactive`, `pending`, `active`. Treat anything other than `active` as "can't do this yet."
- **Webhook events you MUST handle (Connect):** `account.updated`, `capability.updated`, `person.created`, `person.updated`, `payout.created`, `payout.paid`, `payout.failed`, `transfer.created`, `transfer.reversed`, `application_fee.created`, `application_fee.refunded`, `account.application.deauthorized`.

## Cross-references

- [Webhooks](/stacks/stripe/webhooks/) — Connect-specific events
- [Stripe Treasury](/stacks/stripe/stripe-treasury/) — financial accounts for connected accounts
- [Stripe Issuing](/stacks/stripe/stripe-issuing/) — cards backed by Treasury
- [Stripe Identity](/stacks/stripe/stripe-identity/) — supplemental KYC
- [Stripe Capital](/stacks/stripe/stripe-capital/) — financing for connected sellers
- [Stripe Sigma](/stacks/stripe/stripe-sigma/) — reconciliation queries across connected accounts
- [Stripe Data Pipeline](/stacks/stripe/stripe-data-pipeline/) — warehouse sync for ledger ETL
- [Payment Intents](/stacks/stripe/payment-intents/) — underlying charge primitive
- [API Versions + Pinning](/stacks/stripe/api-versions/) — version drift hits Connect platforms hardest
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — liability framework + ledger
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — platform liability + connected account monitoring
- Authoritative: [docs.stripe.com/connect](https://docs.stripe.com/connect)
