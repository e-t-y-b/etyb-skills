---
role: fintech-architect
stack: stripe
last_verified_on: "2026-05-14"
last_verified_api_version: "2025-11-15.acacia"
---

# Stripe Overlay — fintech-architect

You are fintech-architect on a Stripe engagement. Stripe gives you platform infrastructure for embedded finance: marketplaces (Connect), embedded banking (Treasury), card issuing (Issuing), KYC (Identity), bank linking (Financial Connections). **Stripe is NOT your ledger of record, and Stripe is NOT a substitute for fintech-architect judgment.** This overlay tells you what Stripe's primitives are, where the platform liability lines are, and what to defer to the broader fintech-architect specialist for. Compliance reasoning (PSD2, PCI, AML, MTL/MSB, OFAC) stays in the fintech-architect specialist; mechanics of Connect / Treasury / Issuing stays here.

**Currency:** Stripe API `2025-11-15.acacia`. Controller properties replaced the legacy `type: 'custom' | 'express' | 'standard'` shorthand in 2024; Treasury matured 2024-2026 with RTP/FedNow; Issuing expanded internationally through 2025. Verify [docs.stripe.com/connect](https://docs.stripe.com/connect), [docs.stripe.com/treasury](https://docs.stripe.com/treasury), [docs.stripe.com/issuing](https://docs.stripe.com/issuing) if more than 6 months past `last_verified_on`.

## What changed in 2025-2026 that older training data misses

| Change | Effective | Implication |
|--------|-----------|-------------|
| **Connect `controller` properties replace `type`** | 2024 | New accounts use granular `controller.fees`, `controller.losses`, `controller.requirement_collection`, `controller.stripe_dashboard` config. Legacy `type: 'standard'/'express'/'custom'` still accepted but maps to controller fields. Document accounts in controller-property terms; legacy `type` recommendations are dated. |
| **Treasury** matured | 2024-2026 | Financial Accounts, OutboundPayments, RTP/FedNow rails available to approved platforms. Partner banks: Evolve Bank (most US flows), Goldman Sachs (some flows). Eligibility is partner-bank gated. |
| **Stripe Issuing** international expansion | 2025-2026 | Card programs available in more countries. Authorization webhooks + spend controls are platform's responsibility. |
| **RTP + FedNow** through Treasury | 2024 onward | Real-time push payments. Eligibility per-corridor; not all OutboundPayments are real-time. |
| **Stripe Identity** evolved | 2024-2025 | Document + selfie verification; supported countries expanded; pricing model shifted. Useful but not a complete KYC solution at enterprise scale. |
| **Stripe Capital** | Continuous | Financing program available to Connect platforms and direct merchants in eligible countries. Underwriting model is proprietary; platforms surface offers via Capital API. |
| **Stripe Financial Connections** | Expanded 2024-2025 | Plaid alternative. Stripe-hosted bank account linking. Country support expanded but still behind Plaid in coverage. |
| **Connect Embedded Components** | 2024 | UI components (onboarding, account management, payouts dashboard) that platforms can embed instead of redirecting to Stripe-hosted pages. Better UX, more integration effort. |

## Stripe-shaped problems vs fintech-architect-shaped problems

Before writing any code, separate the two:

| Problem | Owner |
|---------|-------|
| "How do I create a Connect account?" | This overlay |
| "How do I move funds from buyer → platform → seller?" | This overlay |
| "What's our regulatory status? Are we an MTL? An MSB?" | fintech-architect specialist |
| "How do I issue a virtual card with spend controls?" | This overlay (mechanics) |
| "Are we compliant with US/EU AML rules issuing this card program?" | fintech-architect specialist |
| "How do I set up a Treasury Financial Account?" | This overlay |
| "Can we offer 'wallet' features in jurisdiction X?" | fintech-architect specialist (regulatory) |
| "How do I sync Stripe data to our double-entry ledger?" | This overlay (Stripe side) + fintech-architect (ledger design) |
| "What's our chargeback recovery process?" | This overlay (Stripe primitives) + fintech-architect (dispute strategy) |

**Stripe gives you mechanisms. fintech-architect specialist gives you the regulatory framework that determines what mechanisms you can use, in what way, in which jurisdiction.**

## Connect — the platform decision

You are building a platform. There are three buyer-merchant relationships:

1. **You are the merchant**, sellers/contractors are paid by you. (Stripe is not the right primitive — just pay them via OutboundPayment / ACH / Treasury.)
2. **Sellers are the merchant**, you facilitate their transactions, take a fee. (Connect.)
3. **You are the merchant for some transactions, sellers for others** (hybrid marketplace). (Connect, with the platform charge model varying per transaction.)

### Connect account type — the controller properties decision

The 2024+ way to create a connected account uses `controller` properties. Map your business to these:

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

### What each controller property means

**`controller.stripe_dashboard.type`** — does the connected account get a Stripe-hosted dashboard?

| Value | What seller sees |
|-------|------------------|
| `full` | Full Stripe Dashboard (standard accounts) |
| `express` | Stripe Express Dashboard (lightweight) |
| `none` | No Stripe dashboard; you build the UI |

**`controller.fees.payer`** — who pays Stripe's processing fees on charges?

| Value | Behavior |
|-------|----------|
| `application` | Platform pays Stripe fees, separately from `application_fee_amount` |
| `account` | Connected account pays Stripe fees from their gross |

**`controller.losses.payments`** — who's on the hook for chargebacks and recovery?

| Value | Behavior |
|-------|----------|
| `application` | Platform takes losses. Stripe may debit your platform balance on chargebacks against connected accounts. |
| `stripe` | Stripe takes losses (limited to certain config combos) |

**`controller.requirement_collection`** — who collects KYC requirements?

| Value | Behavior |
|-------|----------|
| `stripe` | Stripe-hosted onboarding (account_link). Stripe collects requirements via the hosted UI. |
| `application` | Platform collects requirements and submits via API. Most complex; requires deeper compliance integration. |

### Mapping to legacy account types

The legacy shorthand maps as follows:

- **`type: 'standard'`** ≈ `{ stripe_dashboard.type: 'full', fees.payer: 'account', losses.payments: 'stripe', requirement_collection: 'stripe' }`
- **`type: 'express'`** ≈ `{ stripe_dashboard.type: 'express', fees.payer: 'application', losses.payments: 'stripe' (default; configurable), requirement_collection: 'stripe' }`
- **`type: 'custom'`** ≈ `{ stripe_dashboard.type: 'none', fees.payer: 'application', losses.payments: 'application', requirement_collection: 'application' }`

For new builds, **prefer the explicit controller properties form** — it makes liability and config decisions explicit at account creation time.

### Choosing the controller configuration

| Scenario | Recommended config |
|----------|-------------------|
| You want to onboard sellers quickly with minimal compliance burden, Stripe takes losses, sellers see Stripe Dashboard | Standard-equivalent: `{ stripe_dashboard.type: 'full', fees.payer: 'account', losses.payments: 'stripe', requirement_collection: 'stripe' }` |
| You want an embedded-feel UX but Stripe-hosted onboarding + dashboards | Express-equivalent: `{ stripe_dashboard.type: 'express', fees.payer: 'application', losses.payments: 'stripe', requirement_collection: 'stripe' }` |
| You want full white-label, you've built KYC + dashboards, you've accepted the loss exposure | Custom-equivalent: `{ stripe_dashboard.type: 'none', fees.payer: 'application', losses.payments: 'application', requirement_collection: 'application' }` |
| Embedded Components for a polished in-app feel but with Stripe handling backend | `{ stripe_dashboard.type: 'none', fees.payer: 'application', losses.payments: <your choice>, requirement_collection: 'stripe' }` + Connect Embedded Components in your UI |

### Connect Embedded Components

(2024 GA) — UI components you embed in your platform that surface Connect functionality:
- Account onboarding component (replaces redirect-to-Stripe-hosted onboarding)
- Payouts dashboard component
- Account management component
- Documents component

```typescript
// Server: create a session with permissions for the components
const session = await stripe.accountSessions.create({
  account: connectedAccountId,
  components: {
    account_onboarding: { enabled: true },
    payouts: { enabled: true },
    account_management: { enabled: true },
  },
});
// Send session.client_secret to frontend
```

```javascript
// Frontend: mount the components
const stripeConnect = await loadConnectAndInitialize({
  publishableKey: 'pk_live_xxx',
  fetchClientSecret: async () => clientSecret,
});
const onboarding = stripeConnect.create('account-onboarding');
document.getElementById('container').appendChild(onboarding);
```

Use Embedded Components when:
- You want Stripe to handle backend complexity but your in-app UX to be cohesive
- You're using `controller.stripe_dashboard.type: 'none'` and need to surface the underlying functionality yourself

## Charge models — moving money on Connect

Three models for how money flows in a Connect platform:

### Direct charges

```typescript
const pi = await stripe.paymentIntents.create(
  {
    amount: 10000,  // $100
    currency: 'usd',
    application_fee_amount: 200,  // platform takes $2
  },
  { stripeAccount: connectedAccountId },  // charge happens on the connected account
);
```

- Customer's card statement shows the **connected account's** business name
- Funds settle to the connected account's Stripe balance, less the application fee (which goes to platform)
- Connected account holds the charge on their books
- Connected account is the merchant of record for the transaction

Use when each seller is an independent merchant from the customer's perspective (think classic marketplace, à la Etsy / Shopify).

### Destination charges

```typescript
const pi = await stripe.paymentIntents.create({
  amount: 10000,
  currency: 'usd',
  application_fee_amount: 200,
  transfer_data: { destination: connectedAccountId },
  // Note: NO stripeAccount header — charge happens on platform's account
});
```

- Customer's card statement shows the **platform's** business name
- Funds settle initially to platform's balance, then auto-transfer to connected account
- Platform is the merchant of record
- Useful when buyers know your platform but not your sellers (Lyft, Uber, DoorDash model)

### Separate charges and transfers

```typescript
// Step 1: charge on platform
const pi = await stripe.paymentIntents.create({
  amount: 10000,
  currency: 'usd',
  // No transfer_data; no application_fee_amount
});

// Step 2: later, transfer to connected account
const transfer = await stripe.transfers.create({
  amount: 9800,
  currency: 'usd',
  destination: connectedAccountId,
  source_transaction: pi.latest_charge as string,
});
```

- Most flexible — platform decides when, how much, and to whom to transfer
- Useful for:
  - Split-pay (one charge → multiple recipients)
  - Delayed payouts (charge now, transfer after fulfillment)
  - Complex marketplace logic (escrow-like patterns)

### Decision

| Need | Use |
|------|-----|
| Each seller is a distinct merchant to the buyer | Direct charges |
| Platform is the merchant; sellers are paid out | Destination charges |
| Complex split or delayed transfer | Separate charges + transfers |
| Escrow-like hold ("release funds when buyer accepts delivery") | Separate charges + transfers, with manual capture for the auth/hold |

## Connect onboarding

Modern pattern uses `account_link`:

```typescript
// Create account
const account = await stripe.accounts.create({
  controller: { /* ... */ },
  country: 'US',
  email: seller.email,
});

// Generate onboarding link
const accountLink = await stripe.accountLinks.create({
  account: account.id,
  refresh_url: `${BASE_URL}/connect/refresh?account=${account.id}`,
  return_url: `${BASE_URL}/connect/return?account=${account.id}`,
  type: 'account_onboarding',
});

// Redirect seller to accountLink.url
```

The seller completes onboarding (KYC, bank info, etc.) on Stripe-hosted pages, then returns to `return_url`. Your code then:

1. Checks `account.details_submitted` — true means seller finished the flow
2. Listens for `account.updated` webhook — capability changes (transfers, card_payments going active or inactive) come through here
3. Doesn't allow seller to take charges until the relevant capabilities are `active`

### Capabilities

| Capability | What it enables | Common gotcha |
|------------|----------------|---------------|
| `transfers` | Receiving transfers from the platform | Required for destination charges and separate transfers |
| `card_payments` | Accepting card payments directly | Required for direct charges |
| `treasury` | Holding Treasury balance | Limited availability; partner-bank gated |
| `card_issuing` | Issuing cards | Limited availability; per-program approval |
| `legacy_payments` | Older payment methods | Don't request for new accounts |
| `tax_reporting_us_1099_k` / `tax_reporting_us_1099_misc` | US tax form generation | Required if you're issuing 1099s |

### The `account.updated` webhook contract

You MUST listen for `account.updated`. The event fires when:
- Onboarding requirements are completed (or new ones are added)
- A capability transitions state (e.g., `transfers` from `pending` to `active`)
- Stripe pauses an account (e.g., for compliance review)

Pattern:
```typescript
async function handleAccountUpdated(event: Stripe.Event) {
  const account = event.data.object as Stripe.Account;
  
  // Sync to local state
  await db.connectedAccounts.update({
    where: { stripeAccountId: account.id },
    data: {
      detailsSubmitted: account.details_submitted,
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
      capabilities: account.capabilities,
      requirementsCurrentlyDue: account.requirements?.currently_due ?? [],
      requirementsPastDue: account.requirements?.past_due ?? [],
    },
  });
  
  // Take action if capabilities went inactive
  if (!account.charges_enabled) {
    await pauseSellerCharges(account.id);
  }
}
```

`account.requirements.disabled_reason` is informative — it tells you why an account is in a problematic state ("requirements.past_due", "rejected.fraud", "platform_paused"). Surface this to the seller.

## Treasury — embedded finance

Stripe Treasury (GA via partner banks since 2021, matured 2024-2026) lets your platform offer:
- **Financial Accounts** (bank-account-like balance with routing + account number)
- **OutboundPayments** (ACH, RTP, FedNow, wire)
- **InboundTransfers** (move money in)
- **Issued Cards** (with Issuing)
- **Statements** (downloadable monthly statements)

### Eligibility

Treasury is partner-bank-gated. In the US, Evolve Bank & Trust and Goldman Sachs are the partner banks (depending on the flow). Your platform must be approved for Treasury — there's an underwriting process. Programs in non-US countries are limited (verify current support).

### Architecture

```
                    ┌───────────────────────────┐
Platform's customer │                           │
(e.g., business     │  Your platform UI         │
that uses your      │                           │
SaaS)               └──────────┬────────────────┘
                               │
                               │ API calls
                               ▼
                    ┌───────────────────────────┐
                    │   Stripe (Connect +       │
                    │   Treasury + Issuing)     │
                    └──────────┬────────────────┘
                               │
                               │ Underlying bank
                               ▼
                    ┌───────────────────────────┐
                    │  Partner bank             │
                    │  (Evolve, Goldman Sachs)  │
                    └───────────────────────────┘
```

Your platform's customer holds a Financial Account; Stripe + partner bank holds the actual funds. From the customer's perspective, it's "a bank account inside your SaaS."

### Financial Accounts

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

The financial account has:
- A routing number + account number (the "financial address") — others can send money to it via ACH/wire
- A balance (in Stripe's accounting; ultimately at the partner bank)
- Optionally a deposit insurance feature (FDIC pass-through, partner-bank-dependent)

### OutboundPayments — RTP and FedNow

OutboundPayments are how the financial account pushes money out. Rails:

| Rail | Speed | Limits | Use |
|------|-------|--------|-----|
| **ACH** | 1-3 business days | $25M+ but slow | Bulk payouts, low-urgency |
| **Same-day ACH** | Hours (cut-off times apply) | Lower per-transaction limits | When ACH speed matters |
| **US Domestic Wire** | Hours, expensive | High | Large transactions, urgent |
| **RTP (The Clearing House)** | Real-time (seconds) | $1M cap (Nov 2024+) | Real-time push payments |
| **FedNow** | Real-time (seconds) | $500k initial cap, scaling | Real-time push, growing rail |

```typescript
const op = await stripe.treasury.outboundPayments.create(
  {
    financial_account: financialAccountId,
    amount: 50000,  // $500
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

Network selection is largely automatic — Stripe picks ACH by default; specify the network if you need RTP/FedNow specifically.

### Treasury and the ledger

Critical point: **Treasury balances are not a substitute for your own double-entry ledger.**

Stripe's Treasury balance is one account in your ledger (think: "Stripe Treasury Holdings"). You still need a ledger that records:
- Customer balance owed/held
- Platform revenue from fees
- Liabilities to customers (their balance you hold)
- Settlements (when money moves from Treasury → your operational account or to a customer)

Stripe gives you reports (transactions, balance changes); your ledger team consumes those into a proper double-entry general ledger. See the fintech-architect specialist's `ledger-systems.md` for design.

## Issuing — card programs

Stripe Issuing lets you issue physical or virtual cards (Visa or Mastercard) backed by a Stripe balance or Treasury financial account.

### Use cases

- **Corporate cards** — your B2B SaaS issues cards to its customers' employees (Ramp, Brex, Mercury style)
- **Expense cards** — single-use or limited-use cards for specific spend categories
- **Marketplace payout cards** — push earnings to a card the seller can spend
- **On-demand virtual cards** — generated for a specific purchase (instant gift cards, fuel cards)

### Card object

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
      allowed_categories: undefined,  // empty = all except blocked
    },
  },
  { stripeAccount: connectedAccountId },
);
```

### Authorization webhooks — non-negotiable

`issuing_authorization.request` (synchronous) — fires when the cardholder swipes the card. Stripe asks YOUR platform: do you approve this charge?

```typescript
async function handleAuthorizationRequest(event: Stripe.Event) {
  const auth = event.data.object as Stripe.Issuing.Authorization;
  
  // Your business logic: check internal balance, spend policies, etc.
  const allowed = await canSpend(auth.amount, auth.card.cardholder, auth.merchant_data);
  
  if (allowed) {
    await stripe.issuing.authorizations.approve(auth.id);
  } else {
    await stripe.issuing.authorizations.decline(auth.id);
  }
}
```

**You have ~2 seconds to respond.** If you don't respond, Stripe applies the default (configured per Issuing program — usually "approve" with the configured spending controls).

`issuing_authorization.created` (async) — for record-keeping after auth is approved.
`issuing_transaction.created` — actual capture (auth → settled).

### Spend controls

Stripe-native spend controls (`spending_controls.spending_limits`, `blocked_categories`, `allowed_merchants`) handle simple rules. For complex rules (per-employee, per-trip, per-project), implement in your authorization webhook handler.

### Physical cards

`type: 'physical'` cards require:
- A cardholder with verified PII
- A shipping address
- Stripe ships the card (or partner ships); ~7-10 days delivery
- Activation flow before first use

For virtual-first card programs (most modern), issue virtual at signup and let cardholder request physical separately.

## Identity (KYC)

Stripe Identity provides document + selfie verification. Used for:
- KYC of Connect platform sellers (alternative to Stripe-hosted onboarding's built-in KYC)
- Account opening verification (you operate a service that requires verifying users are real)
- Step-up verification on high-value transactions

```typescript
const session = await stripe.identity.verificationSessions.create({
  type: 'document',  // or 'id_number' for SSN-style
  options: {
    document: {
      allowed_types: ['driving_license', 'passport', 'id_card'],
      require_id_number: true,
      require_live_capture: true,
      require_matching_selfie: true,
    },
  },
  metadata: { user_id: userId },
});

// Send session.url to user (or use the embedded JS SDK)
```

Outcome: `identity.verification_session.verified` webhook fires with `last_verification_report` containing the extracted info.

### When Stripe Identity is NOT enough

- Enterprise KYC at scale (use Persona, Jumio, Onfido)
- Multi-step KYB (business verification, beneficial owners) — Stripe handles some via Connect onboarding, but for non-Connect KYB use a specialized vendor
- Ongoing periodic re-verification (annual KYC refresh)
- Countries Stripe Identity doesn't support — check the current list
- Custom document types Stripe doesn't recognize

For Connect platforms, the built-in Connect onboarding KYC is usually sufficient; Stripe Identity is for non-Connect use cases.

## Financial Connections — bank linking

Stripe Financial Connections is Stripe's Plaid alternative. Lets users link their bank account to your platform:
- Verify ownership of a bank account
- Pull balances / transactions (read-only)
- Save the account for ACH debits

```typescript
// Create a session for linking
const session = await stripe.financialConnections.sessions.create({
  account_holder: { type: 'customer', customer: customerId },
  permissions: ['payment_method', 'balances', 'transactions'],
  prefetch: ['balances'],
});

// Send session.client_secret to frontend; mount the Financial Connections Element
```

### Country support

Strong in US, expanding in EU/UK through 2024-2025. Plaid still has broader coverage internationally; Financial Connections is the Stripe-native option that integrates more tightly with PaymentIntents (for ACH) and Treasury.

### Use cases

- ACH debit setup with verified ownership (instant verification vs micro-deposits)
- Underwriting / financial assessment (see balances, transaction history)
- Account aggregation in a financial tool

## Stripe Capital — financing

Stripe Capital offers loans to merchants and Connect platform sellers, underwritten by Stripe based on Stripe-side payment history.

For Connect platforms, your sellers can be offered Capital. The platform surfaces offers via API:
- `capital.financing_offers` — list offers available to a connected account
- `capital.financing_offer.accept` — mark an offer as accepted
- Loan repayment happens automatically via deductions from the seller's Stripe payouts

Eligibility is Stripe's algorithm based on transaction history; you don't underwrite.

When to surface Capital:
- Your platform has connected accounts with consistent transaction history
- Capital is available in your sellers' country
- Sellers might want working capital and you want to differentiate vs other platforms

## Sigma + Data Pipeline — reconciliation

Stripe Sigma (in-Dashboard SQL) and Data Pipeline (warehouse sync) are the reconciliation tools.

### Sigma

SQL queries over your Stripe data in Dashboard. Tables include `balance_transactions`, `charges`, `payouts`, `transfers`, `application_fees`, `disputes`, `subscriptions`, `invoices`, `customers`, `connected_accounts` (for Connect platforms).

For Connect platforms, the most important Sigma query is the daily reconciliation:

```sql
-- Daily reconciliation: charges + application fees + transfers per connected account
SELECT
  date_trunc('day', c.created) AS day,
  c.destination AS connected_account,
  SUM(c.amount) AS gross_charges,
  SUM(c.application_fee_amount) AS platform_fees,
  SUM(c.amount - c.application_fee_amount) AS transferred_to_account
FROM charges c
WHERE c.status = 'succeeded'
  AND c.created >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY 1, 2
ORDER BY 1, 2;
```

### Data Pipeline

Schedule-driven sync of Stripe data to Snowflake / BigQuery / Redshift / Databricks. Schema mirrors Sigma's tables. Use for:
- Long-term retention (Sigma has Dashboard-side retention limits)
- Joining Stripe data with your operational data (orders, users, ledger entries)
- Powering BI dashboards (Looker, Mode, Hex)
- Feeding the double-entry ledger

For any platform doing serious volume, Data Pipeline + a warehouse is the right setup. Don't build your own ETL by polling the Stripe API.

## Reconciliation — Stripe is NOT the ledger

Stripe gives you payment data. Your ledger of record is yours. Reconciliation pattern:

1. **Daily**: pull `balance_transactions` for the previous day from Stripe (or it's in your warehouse via Data Pipeline). Each balance transaction is a money movement (charge, refund, transfer, application_fee, dispute, payout).
2. **Map each balance transaction to ledger entries**: e.g., a `charge` is a credit to "Stripe Balance" and a debit to "Accounts Receivable Stripe"; a `payout` is a credit to "Stripe Balance" and a debit to "Operating Bank Account".
3. **Verify**: at the end of the day, sum of Stripe-Balance changes from your ledger should equal Stripe's reported daily balance change. Discrepancies indicate a missing entry or a misclassification.
4. **Handle Connect**: for Connect platforms, you have both your platform's balance AND each connected account's balance. Reconciliation needs to track both.

The fintech-architect specialist's `ledger-systems.md` has the double-entry design. From Stripe's side: pull the data, map to your ledger, reconcile daily.

## Decision frameworks

### Connect controller configuration

| Concern | Recommendation |
|---------|----------------|
| Minimize platform compliance burden | `stripe_dashboard.type: 'full' or 'express'`, `requirement_collection: 'stripe'`, `losses.payments: 'stripe'` |
| Maximize platform UX integration | `stripe_dashboard.type: 'none'`, use Connect Embedded Components |
| Platform wants to take losses (deliberate underwriting strategy) | `losses.payments: 'application'` — but be sure you have the capital + monitoring to support it |
| Platform doesn't want to take losses | `losses.payments: 'stripe'` — Stripe sets the underwriting bar |

### When to use Treasury

| Need | Use Treasury? |
|------|---------------|
| Hold customer balances inside your SaaS | Yes (if eligible) |
| Issue cards backed by a balance | Yes (Issuing + Treasury) |
| Just pay out to sellers without holding | No — Connect payouts handle this |
| Real-time push payments (RTP/FedNow) | Yes (via Treasury OutboundPayments) |
| Need to be a bank | No — you're not a bank; Treasury makes you a quasi-bank backed by partner bank |

### When to issue cards

| Need | Use Stripe Issuing? |
|------|--------------------|
| Corporate card program for your B2B customers | Yes |
| Per-employee or per-project spend control | Yes |
| Marketplace seller payouts as a spendable card | Yes |
| Consumer prepaid cards (gift cards, etc.) | Generally yes; regulatory differs |
| Credit cards (unsecured lending) | No — Issuing is debit/prepaid |

### When to use Stripe Identity vs Persona/Jumio/Onfido

| Concern | Stripe Identity | Persona/Jumio/Onfido |
|---------|-----------------|----------------------|
| Volume | Light-to-medium | Heavy / enterprise |
| Workflow complexity | Single-step | Multi-step with branching |
| Geographic coverage | US + expanding | Global, often deeper per-country |
| Compliance reporting | Basic | Detailed |
| Integration depth with Connect | Native | Bolt-on |

For Connect platforms: built-in Connect onboarding KYC. For non-Connect KYC at low/medium volume: Stripe Identity. For enterprise KYC: dedicated vendor.

## Patterns and anti-patterns

### Pattern: capability-gated seller features

```typescript
async function canSellerAcceptPayments(sellerId: string): Promise<boolean> {
  const account = await db.connectedAccounts.findUnique({ where: { sellerId } });
  return account?.capabilities?.card_payments === 'active';
}
```

Source of truth: your local DB, hydrated from `account.updated` webhooks. Check capability state before allowing seller-facing actions that require it.

### Pattern: idempotent Connect onboarding

If your "create account" flow can be retried, dedupe by seller ID:

```typescript
async function ensureConnectedAccount(seller: Seller): Promise<string> {
  if (seller.stripeAccountId) {
    return seller.stripeAccountId;
  }
  const account = await stripe.accounts.create(
    {
      controller: { /* ... */ },
      country: seller.country,
      email: seller.email,
      metadata: { internal_seller_id: seller.id },
    },
    { idempotencyKey: `account-create-${seller.id}` },
  );
  await db.sellers.update({
    where: { id: seller.id },
    data: { stripeAccountId: account.id },
  });
  return account.id;
}
```

### Pattern: Treasury balance + double-entry ledger

Stripe's Treasury balance is **one** account in your ledger. Customer balances (what your platform owes its users) are separate ledger accounts. Don't conflate.

```
Treasury Balance: $100,000 (held at partner bank)
  ├── Customer A liability: $40,000 (we owe A)
  ├── Customer B liability: $35,000 (we owe B)
  ├── Customer C liability: $20,000 (we owe C)
  └── Platform revenue: $5,000 (our take from fees)
```

When customer A withdraws $10k: Treasury balance goes down by $10k AND customer A liability goes down by $10k. Both legs in your ledger.

### Pattern: Issuing authorization with deferred decision

Sometimes 2 seconds isn't enough to make an authorization decision. Pattern:
- Approve in the webhook handler (within 2 seconds)
- Async, perform deeper checks
- If deeper checks fail, reverse the authorization (`issuing.authorizations.update` with `metadata` marking fraud + manual review queue)

Trade-off: false positives let some bad spend through. Worth it for legitimate spend not being denied at the register.

### Anti-pattern: Stripe as the ledger

"Our ledger is our Stripe balance plus our connected accounts' balances." No. Stripe is a payment processor. Your ledger needs:
- Customer-side liabilities (we owe X to user Y)
- Revenue recognition (we earned Z this period)
- Platform-side assets and liabilities
- Accrual vs cash accounting distinctions

Stripe gives you cash-side data. The accrual side is yours.

### Anti-pattern: missing `account.updated` handler

Connect platforms without `account.updated` handling will not know when a connected account's capabilities change. Stripe pauses an account for fraud review → your platform happily takes orders → all orders fail → you have a UX disaster. Handle `account.updated`.

### Anti-pattern: `controller.losses.payments: 'application'` without capital + monitoring

If you take losses, you must:
- Hold capital reserves (you can be net-negative on a connected account if disputes exceed their balance — you're on the hook)
- Monitor connected accounts for risk signals (high dispute rate, unusual transaction patterns)
- Have an offboarding process for problematic sellers
- Have a recovery process for negative balances

Don't take losses unless your fintech-architect specialist has built the underwriting, monitoring, and recovery framework.

### Anti-pattern: ignoring `capability.updated`

`capability.updated` is more granular than `account.updated` — it tells you which specific capability changed. Use it to react: if `transfers` goes inactive, you can't pay this seller; pause their payouts UI immediately.

## Tooling specifics

- **Stripe Workbench** — Connect view shows connected accounts, capabilities, requirements. Use for individual-account debugging.
- **Stripe CLI** — `stripe trigger account.updated` for testing Connect webhook handlers. `stripe trigger issuing_authorization.request` for Issuing.
- **Connect Embedded Components** — for white-label UX backed by Stripe.
- **Stripe Sigma** — reconciliation queries.
- **Stripe Data Pipeline** — sync Stripe data to your warehouse for the double-entry ledger ETL.
- **Stripe Tax** — for marketplaces, handle marketplace tax obligations (varies by jurisdiction). Some jurisdictions require platforms to collect on behalf of sellers; Stripe Tax handles this if configured.
- **Test mode** — full Connect / Treasury / Issuing flows work in test mode with test cards and test bank accounts.

## Integration with always-on protocols

### TDD on Connect handlers

Red: test that `account.updated` with `charges_enabled: false` pauses seller-facing checkout UI. Test that an Issuing `authorization.request` with amount > spending_control is declined.

Green: implement.

Refactor: extract account-state and authorization-decision logic into pure functions tested independently.

### Verification on Connect platform state

Reconciliation must be daily. Sum of platform balance + sum of connected account balances + sum of Treasury balances should match Stripe's reported total. Discrepancies are findings.

For seller-level disputes, verify the full chain: charge → application_fee → transfer → dispute → debit → recovery (or write-off). The chain must close out cleanly.

### Debugging Connect platform issues

A seller says "I can't take payments." Workflow:
1. Workbench → Connect → find the account. Check `charges_enabled`, `payouts_enabled`, `requirements.currently_due`.
2. Trace recent `account.updated` events for this account in Events.
3. Check capability statuses — what's inactive, why?
4. Compare local DB state to Stripe state — is your handler current?

Don't guess. The data is there; trace it.

### Branch safety on Connect / Treasury / Issuing code

Money-platform code requires:
- Two reviews (this overlay + backend-architect)
- Test-mode E2E test for the full flow (onboard, charge, transfer, payout)
- Live-mode smoke test post-deploy
- Reconciliation check on day-1 post-deploy

For Issuing card programs: a failed authorization webhook outage means customers can't spend. Have an alerting + runbook for webhook handler health.

## Cross-references

- [Webhook architecture mechanics → backend-architect.md](backend-architect.md)
- [PCI scope + key hygiene + Connect liability framing → security-engineer.md](security-engineer.md)
- [Marketplace-billing model context (Connect + subscriptions) → saas-architect.md](saas-architect.md)
- [Checkout patterns for Connect-aware flows → e-commerce-architect.md](e-commerce-architect.md)
- [Fintech compliance (PSD2, PCI, AML), ledger systems, payment processing patterns → `skills/etyb/references/verticals/fintech-architect/`](../../../skills/etyb/references/verticals/fintech-architect/)

## Products covered relevant to this role

Stripe Connect (Standard / Express / Custom / controller-property-configured), Connect Embedded Components, Stripe Treasury (Financial Accounts, OutboundPayments, RTP, FedNow), Stripe Issuing (cards, authorization webhooks, spend controls), Stripe Identity, Stripe Financial Connections, Stripe Capital, Webhooks (Connect-specific events), Stripe Sigma (reconciliation queries), Stripe Data Pipeline (warehouse sync for ledger ETL), API versions + pinning (especially for Connect events — version drift hits Connect platforms hardest).
