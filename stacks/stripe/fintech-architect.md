---
title: fintech-architect on Stripe
description: Fintech lens on Stripe — Connect platform liability (controller properties), Treasury Financial Accounts + RTP/FedNow, Issuing programs, Identity, reconciliation. Stripe is NOT your ledger.
role_overlay:
  role: fintech-architect
  stack: stripe
  last_verified_on: "2026-05-14"
  products_covered:
    - stripe-connect
    - stripe-treasury
    - stripe-issuing
    - stripe-identity
    - stripe-financial-connections
    - stripe-capital
    - rtp-fednow
    - ach-debit
    - sepa-debit
    - webhooks
    - stripe-sigma
    - stripe-data-pipeline
    - api-versions
---

## Role briefing

You are fintech-architect on a Stripe engagement. Stripe gives you platform infrastructure for embedded finance: marketplaces ([Connect](/stacks/stripe/stripe-connect/)), embedded banking ([Treasury](/stacks/stripe/stripe-treasury/)), card issuing ([Issuing](/stacks/stripe/stripe-issuing/)), KYC ([Identity](/stacks/stripe/stripe-identity/)), bank linking ([Financial Connections](/stacks/stripe/stripe-financial-connections/)).

**Stripe is NOT your ledger of record, and Stripe is NOT a substitute for fintech-architect judgment.** This overlay tells you what Stripe's primitives are, where the platform liability lines are, and what to defer to the broader fintech-architect specialist for. Compliance reasoning (PSD2, PCI, AML, MTL/MSB, OFAC) stays in the principle-level fintech-architect role; mechanics of Connect / Treasury / Issuing stays here.

## 2025-2026 platform-reset items relevant to this role

| Change | Effective | Implication |
|--------|-----------|-------------|
| **[Connect](/stacks/stripe/stripe-connect/) `controller` properties replace `type`** | 2024 | New accounts use granular `controller.fees`, `controller.losses`, `controller.requirement_collection`, `controller.stripe_dashboard`. Legacy `type` still accepted but maps to controller fields |
| **[Treasury](/stacks/stripe/stripe-treasury/)** matured | 2024-2026 | Financial Accounts, OutboundPayments, RTP/FedNow available to approved platforms. Partner banks Evolve, Goldman Sachs |
| **[Stripe Issuing](/stacks/stripe/stripe-issuing/)** international expansion | 2025-2026 | More countries; authorization webhooks + spend controls are platform's responsibility |
| **[RTP + FedNow](/stacks/stripe/rtp-fednow/)** through Treasury | 2024 onward | Real-time push; per-corridor eligibility |
| **[Stripe Identity](/stacks/stripe/stripe-identity/)** evolved | 2024-2025 | Supported countries expanded; pricing shifted |
| **[Stripe Capital](/stacks/stripe/stripe-capital/)** | Continuous | Financing for Connect platforms; underwriting proprietary |
| **[Stripe Financial Connections](/stacks/stripe/stripe-financial-connections/)** | Expanded 2024-2025 | Plaid alternative; country support expanded but still behind Plaid internationally |
| **Connect Embedded Components** | 2024 GA | UI components platforms embed instead of redirecting |

## Stripe-shaped problems vs fintech-architect-shaped problems

| Problem | Owner |
|---------|-------|
| "How do I create a Connect account?" | This overlay |
| "How do I move funds buyer to platform to seller?" | This overlay |
| "What's our regulatory status? MTL? MSB?" | Principle-level fintech-architect |
| "How do I issue a virtual card with spend controls?" | This overlay (mechanics) |
| "Are we compliant with US/EU AML rules for this card program?" | Principle-level fintech-architect |
| "How do I set up a Treasury Financial Account?" | This overlay |
| "Can we offer 'wallet' features in jurisdiction X?" | Principle-level fintech-architect (regulatory) |
| "How do I sync Stripe data to our double-entry ledger?" | This overlay (Stripe side) + principle-level (ledger design) |
| "What's our chargeback recovery process?" | This overlay (Stripe primitives) + principle-level (dispute strategy) |

**Stripe gives you mechanisms. The principle-level fintech-architect gives you the regulatory framework that determines what mechanisms you can use, how, in which jurisdiction.**

## Connect — the platform decision

You are building a platform. Three buyer-merchant relationships:

1. **You are the merchant**, sellers/contractors are paid by you. (Stripe is not the right primitive — just pay them via [Treasury](/stacks/stripe/stripe-treasury/) OutboundPayment.)
2. **Sellers are the merchant**, you facilitate, take a fee. ([Connect](/stacks/stripe/stripe-connect/).)
3. **Hybrid marketplace.** (Connect, with charge model varying per transaction.)

### Controller configuration

See [Stripe Connect](/stacks/stripe/stripe-connect/) for the full controller-property decision. Quick map:

| Scenario | Config |
|----------|--------|
| Onboard quickly, Stripe takes losses | Standard-equivalent |
| Embedded-feel UX, Stripe-hosted onboarding | Express-equivalent |
| Full white-label, you've built KYC + dashboards, accepted loss exposure | Custom-equivalent — but read prerequisites |
| Polished in-app feel + Stripe handling backend | Embedded Components |

### Charge models

| Need | Use |
|------|-----|
| Each seller is a distinct merchant to the buyer (Etsy/Shopify model) | Direct charges |
| Platform is the merchant; sellers are paid out (Lyft/DoorDash model) | Destination charges |
| Complex split or delayed transfer | Separate charges + transfers |
| Escrow-like hold | Separate charges + transfers with manual capture |

### Capability gating

```typescript
async function canSellerAcceptPayments(sellerId: string): Promise<boolean> {
  const account = await db.connectedAccounts.findUnique({ where: { sellerId } });
  return account?.capabilities?.card_payments === 'active';
}
```

Source of truth: local DB hydrated from `account.updated` webhooks. Check capability state before allowing seller-facing actions.

## Treasury — embedded finance

See [Stripe Treasury](/stacks/stripe/stripe-treasury/) for the full surface.

### Architecture

Platform's customer to your platform UI to Stripe (Connect + Treasury + Issuing) to partner bank.

Your platform's customer holds a [Financial Account](/stacks/stripe/stripe-treasury/); Stripe + partner bank holds the actual funds. From the customer's perspective, it's "a bank account inside your SaaS."

### Treasury balance is ONE ledger account

```
Treasury Balance: $100,000 (held at partner bank)
  - Customer A liability: $40,000 (we owe A)
  - Customer B liability: $35,000 (we owe B)
  - Customer C liability: $20,000 (we owe C)
  - Platform revenue:      $5,000 (our take from fees)
```

When customer A withdraws $10k: Treasury balance goes down by $10k AND customer A liability goes down by $10k. **Both legs in your ledger.** See ledger discussion below.

### [RTP / FedNow](/stacks/stripe/rtp-fednow/)

Real-time push payments. Eligibility per corridor; RTP $1M cap (Nov 2024+), FedNow $500k initial cap scaling. Network selection largely automatic — specify only if you need a specific rail.

## Issuing — card programs

See [Stripe Issuing](/stacks/stripe/stripe-issuing/) for the surface.

### Authorization webhook is non-negotiable

`issuing_authorization.request` fires synchronously when a cardholder swipes. **~2 seconds to respond** with approve or decline. If you don't, Stripe applies the configured default — which means your dynamic policy didn't run.

### Deferred decision pattern

Sometimes 2 seconds isn't enough:
1. Approve in the webhook (within 2 seconds, applying conservative limits)
2. Async, perform deeper checks
3. If checks fail, reverse the authorization

Trade-off: false positives let some bad spend through. Worth it for legitimate spend not denied at the register.

### Spend controls

Stripe-native (`spending_limits[]`, `blocked_categories`, `allowed_merchants`) handle simple rules. Complex rules (per-employee, per-trip, per-project, per-budget) go in your `issuing_authorization.request` handler.

## Identity (KYC)

See [Stripe Identity](/stacks/stripe/stripe-identity/).

For Connect platforms: built-in Connect onboarding KYC (via `account_link`) is usually sufficient. Identity supplements when verification needed outside Connect onboarding flow.

NOT enough for:
- Enterprise KYC at scale (Persona, Jumio, Onfido)
- Multi-step KYB / beneficial owners
- Ongoing periodic re-verification
- Countries Stripe Identity doesn't support

## Financial Connections — bank linking

See [Stripe Financial Connections](/stacks/stripe/stripe-financial-connections/).

Strong in US; expanding EU/UK. Plaid still has broader international coverage. Pair with [ACH Direct Debit](/stacks/stripe/ach-debit/) for instant ownership verification.

## Sigma + Data Pipeline — reconciliation

See [Stripe Sigma](/stacks/stripe/stripe-sigma/) (in-Dashboard SQL) and [Stripe Data Pipeline](/stacks/stripe/stripe-data-pipeline/) (warehouse sync).

For Connect platforms, the most important Sigma query is daily reconciliation:

```sql
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

For long-term retention + warehouse joins with operational data, use [Data Pipeline](/stacks/stripe/stripe-data-pipeline/).

## Reconciliation — Stripe is NOT the ledger

Stripe gives you payment data. Your ledger of record is yours.

```
1. Daily: pull `balance_transactions` for previous day (from Stripe or warehouse)
2. Map each balance transaction to ledger entries:
   - charge = credit "Stripe Balance" + debit "Accounts Receivable Stripe"
   - payout = credit "Stripe Balance" + debit "Operating Bank Account"
3. Verify: sum of Stripe-Balance changes in your ledger = Stripe's reported daily balance change
4. For Connect: track platform balance AND each connected account's balance
```

The principle-level fintech-architect's ledger-systems doc has the double-entry design. From Stripe's side: pull, map, reconcile daily.

## Product references

- **[Stripe Connect](/stacks/stripe/stripe-connect/)** — controller properties, charge models, onboarding, capabilities, Embedded Components
- **[Stripe Treasury](/stacks/stripe/stripe-treasury/)** — Financial Accounts, OutboundPayments
- **[Stripe Issuing](/stacks/stripe/stripe-issuing/)** — card programs, authorization webhook, spend controls
- **[Stripe Identity](/stacks/stripe/stripe-identity/)** — supplemental KYC
- **[Stripe Financial Connections](/stacks/stripe/stripe-financial-connections/)** — bank linking
- **[Stripe Capital](/stacks/stripe/stripe-capital/)** — financing for connected sellers
- **[RTP / FedNow](/stacks/stripe/rtp-fednow/)** — real-time push payments
- **[ACH Debit](/stacks/stripe/ach-debit/)** / **[SEPA Debit](/stacks/stripe/sepa-debit/)** — bank-debit rails
- **[Webhooks](/stacks/stripe/webhooks/)** — Connect/Treasury/Issuing event handling
- **[Stripe Sigma](/stacks/stripe/stripe-sigma/)** + **[Data Pipeline](/stacks/stripe/stripe-data-pipeline/)** — reconciliation
- **[API Versions + Pinning](/stacks/stripe/api-versions/)** — version drift hits Connect platforms hardest

## Patterns this role applies

### TDD on Connect handlers

- **Red**: `account.updated` with `charges_enabled: false` pauses seller-facing checkout UI. Issuing `authorization.request` with amount over spending_control is declined.
- **Green**: implement.
- **Refactor**: extract account-state + authorization-decision logic into pure functions.

### Verification on Connect platform state

Reconciliation must be daily. Sum of platform balance + sum of connected account balances + sum of Treasury balances should match Stripe's reported total. Discrepancies are findings.

For seller-level disputes, verify the full chain: charge to application_fee to transfer to dispute to debit to recovery (or write-off). The chain must close out cleanly.

### Debugging Connect platform issues

Seller says "I can't take payments":
1. Workbench → Connect → find the account. Check `charges_enabled`, `payouts_enabled`, `requirements.currently_due`.
2. Trace recent `account.updated` events in Events.
3. Check capability statuses — what's inactive, why?
4. Compare local DB state to Stripe state — is your handler current?

Don't guess. The data is there; trace it.

### Branch safety on Connect / Treasury / Issuing

Money-platform code requires:
- Two reviews (this overlay + [backend-architect](/stacks/stripe/backend-architect/))
- Test-mode E2E test for the full flow (onboard, charge, transfer, payout)
- Live-mode smoke test post-deploy
- Reconciliation check on day-1 post-deploy

For Issuing card programs: failed authorization webhook outage means customers can't spend. Have alerting + runbook for webhook handler health.

## Anti-patterns specific to this role

- **Stripe as the ledger.** Stripe is a payment processor. Your ledger needs customer-side liabilities (we owe X to user Y), revenue recognition, platform-side assets, accrual-vs-cash distinctions. Stripe gives you cash-side data; the accrual side is yours.
- **Missing `account.updated` handler.** Connect platforms without this won't know when capabilities change.
- **`controller.losses.payments: 'application'` without capital + monitoring + recovery.** You're on the hook for unrecovered chargebacks.
- **Ignoring `capability.updated`.** More granular than `account.updated`.
- **Stripe Treasury as the ledger of customer balances.** Treasury is one ledger account; customer liabilities are separate.

## Cross-references

- [backend-architect on Stripe](/stacks/stripe/backend-architect/) — webhook architecture mechanics
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — PCI + key hygiene + Connect liability framing
- [saas-architect on Stripe](/stacks/stripe/saas-architect/) — marketplace billing model context
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/) — Connect-aware checkout
- [Stripe Stack index](/stacks/stripe/)
- Authoritative: [docs.stripe.com/connect](https://docs.stripe.com/connect), [docs.stripe.com/treasury](https://docs.stripe.com/treasury), [docs.stripe.com/issuing](https://docs.stripe.com/issuing)
