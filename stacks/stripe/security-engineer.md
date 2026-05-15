---
title: security-engineer on Stripe
description: Security lens on Stripe — PCI scope (SAQ-A vs SAQ-A-EP vs SAQ-D), webhook signing, key hygiene, 3DS2/SCA, Radar, Connect liability, agent + MCP security.
role_overlay:
  role: security-engineer
  stack: stripe
  last_verified_on: "2026-05-14"
  products_covered:
    - payment-intents
    - setup-intents
    - stripe-checkout
    - payment-element
    - stripe-billing
    - customer-portal
    - stripe-connect
    - stripe-treasury
    - stripe-issuing
    - stripe-identity
    - stripe-tax
    - stripe-radar
    - restricted-api-keys
    - webhooks
    - api-versions
    - stripe-workbench
    - sca-3ds2
    - stripe-sigma
    - stripe-data-pipeline
---

## Role briefing

You are security-engineer on a Stripe engagement. The Stripe surface in 2026 has three security planes that all need attention:

1. **PCI scope reduction** — which integration path you pick changes your audit burden by orders of magnitude
2. **Key + credential hygiene** — publishable / secret / restricted / webhook signing secret have different threat models
3. **Fraud + authentication** — [Radar](/stacks/stripe/stripe-radar/) configuration, [3DS2/SCA](/stacks/stripe/sca-3ds2/) compliance, [Connect](/stacks/stripe/stripe-connect/) platform liability

Get these wrong and the consequences range from a failed SAQ to material customer harm.

What's distinctive vs. the principle-level security-engineer role: on Stripe, **PCI scope is determined by your integration choice, not by Stripe**. Picking Stripe doesn't make you SAQ-A; picking Stripe **a certain way** can.

## 2025-2026 platform-reset items relevant to this role

| Change | Effective | Implication |
|--------|-----------|-------------|
| **PCI DSS v4.0 enforcement** | March 31, 2024 → fully enforced 2025 | Targeted risk analyses, anti-phishing controls, account-data inventory all required |
| **PCI DSS v4.0 req 6.4.3** — payment page script management | Enforced 2025 | All scripts on the payment page inventoried, authorized, integrity-monitored. Heavy SAQ-A-EP burden |
| **PCI DSS v4.0 req 11.6.1** — tamper detection on payment pages | Enforced 2025 | Real-time detection of payment-page modifications |
| **[SCA enforcement](/stacks/stripe/sca-3ds2/)** in EU/UK/EEA | Continuous 2024-2026 | Mandatory; non-compliant flows silently declining at the issuer |
| **[Stripe Radar](/stacks/stripe/stripe-radar/)** Adaptive Acceptance | Ongoing | Block patterns shifted; re-tune rules annually |
| **[Restricted API keys](/stacks/stripe/restricted-api-keys/)** GA + recommended | 2024-2026 | `sk_live_*` everywhere is now a finding |
| **[Stripe-hosted MCP](https://docs.stripe.com/mcp)** for agents | 2025 | Prompt injection that triggers Stripe ops is a real threat; mandatory restricted keys + audit logging |
| **[Connect](/stacks/stripe/stripe-connect/) controller properties** | 2024 | `controller.losses.payments` makes liability explicit — misconfigured platforms have a clear field to point at |
| **3DS1 sunset** | 2024 | If you see 3DS1 code, it's dead. Use 3DS2 via PaymentIntents |

## PCI scope — the dominating decision

Your PCI scope is determined by **how cardholder data enters and traverses your environment**:

| Integration | What touches your servers | PCI scope | SAQ |
|-------------|---------------------------|-----------|-----|
| **[Stripe Checkout](/stacks/stripe/stripe-checkout/)** (hosted/embedded) | Customer is redirected (or embedded iframe) to Stripe-hosted page. Cardholder data never enters your DOM or servers. | Lowest | SAQ-A (~22 questions) |
| **[Payment Element](/stacks/stripe/payment-element/)** | Card inputs are Stripe-hosted iframes embedded in your page. You style the surrounding form; Stripe owns the inputs. | Low, but page-level | SAQ-A-EP (~197 questions) |
| **Raw API + custom card form** | Your page captures card data into your form, you POST to Stripe. Cardholder data in your DOM + briefly in your network. | Highest | SAQ-D (~330 requirements) |

The decision rule:

```
Net-new build, no special UX → Stripe Checkout (SAQ-A). Stop here.
Constraint: own form layout, standard inputs → Payment Element (SAQ-A-EP). Plan for v4.0 6.4.3 + 11.6.1.
Constraint: multi-PSP / vault → multi-PSP territory; this overlay isn't the right reference.
Constraint: phone orders → Terminal SDK or MOTO Payment Element.
"Custom card form sending to Stripe" → push back. Justify the SAQ-D scope or use Elements.
```

Teams routinely pick Elements expecting SAQ-A; it's SAQ-A-EP. ~197 questions vs ~22.

### PCI v4.0 controls specific to SAQ-A-EP

**6.4.3 — Payment page scripts.** Every script element on the payment page (or pages hosting the iframe) must be:
- Authorized — documented approval
- Justified — business reason
- Integrity-protected — SRI hash OR CSP pinning script sources to known origins

In practice: keep the payment page minimal. Don't load analytics SDKs, chat widgets, A/B test frameworks, or marketing pixels. If you must, inventory + SRI.

```html
<script
  src="https://js.stripe.com/v3/"
  integrity="sha384-<hash>"
  crossorigin="anonymous"
></script>
```

Always load Stripe.js from `js.stripe.com` directly with SRI + CSP pin. Never self-host or proxy — breaks the iframe boundary AND PCI guidance.

**11.6.1 — Tamper / change detection.** Real-time monitoring of payment-page modifications. Options: DOM mutation observers, commercial CSP integrity services (Akamai Page Integrity Manager, Jscrambler), or Stripe's published guidance + CSP report-uri.

## Key + credential hygiene

| Key | Lives where | Threat if leaked |
|-----|-------------|------------------|
| **Publishable (`pk_*`)** | Client-side | Low — limited to Stripe.js / Mobile SDK operations |
| **Secret (`sk_live_*`, `sk_test_*`)** | Server-side env vars | Catastrophic. Full account access |
| **[Restricted](/stacks/stripe/restricted-api-keys/) (`rk_*`)** | Server-side, less-trusted services | Scope-limited; threat depends on scope |
| **Webhook signing secret (`whsec_*`)** | Server-side, in handler | Forged events; severity depends on handler logic |
| **Connect OAuth tokens** | Platform | Catastrophic for the platform — impersonate to all connected accounts |

### Practices

- **Publishable key** — safe to expose. That's its job. Don't over-defensive-vault it.
- **Secret key** — server-side only, per-environment, per-service if possible. Never `NEXT_PUBLIC_STRIPE_SECRET_KEY` (the concept doesn't exist; if you see it, rotate immediately).
- **[Restricted keys](/stacks/stripe/restricted-api-keys/)** — start with "no permissions," add minimum, lock down. Quarterly rotation minimum.
- **Webhook signing secret** — one per endpoint. Hardcoding "the" secret breaks the moment you add a second endpoint.

### Deploy-time mode check

```typescript
const key = process.env.STRIPE_SECRET_KEY;
if (process.env.NODE_ENV === 'production' && !key?.startsWith('sk_live_')) {
  throw new Error('Production using test mode Stripe key');
}
if (process.env.NODE_ENV !== 'production' && key?.startsWith('sk_live_')) {
  throw new Error('Non-production using live mode Stripe key');
}
```

Catches the most common deployment-misconfiguration class.

## Webhook signature verification

The single most common security mistake in Stripe integrations: skipping or weakening signature verification. See [Webhooks](/stacks/stripe/webhooks/) for the canonical handler shape.

Common silent failures:
- Parsing `req.json()` then passing parsed-and-re-stringified back as a "string" — bytes differ
- Frameworks that JSON-parse all POSTs by default (Next.js App Router needs `req.text()`; Express needs `bodyParser.raw`)
- Hardcoding `STRIPE_WEBHOOK_SECRET` when you have multiple endpoints
- Trusting `Stripe-Signature` header existence without `constructEvent`

When verification fails, return **400, not 401 or 500**. 400 = malformed event (Stripe stops retrying). 401/500 = "delivery failed" (Stripe retries forever, log spam).

## 3DS2 / SCA

See [SCA / 3D Secure 2](/stacks/stripe/sca-3ds2/) for the full mechanism.

From security's perspective:
- Mandatory in EU/UK/EEA — non-compliant flows silently decline
- [PaymentIntents](/stacks/stripe/payment-intents/) handle it transparently when configured with `automatic_payment_methods: { enabled: true }` + client-side `stripe.confirmPayment`
- Don't disable 3DS to "improve conversion." Doesn't work in EEA/UK; decline rates spike.

## Radar configuration

See [Stripe Radar](/stacks/stripe/stripe-radar/) for the product.

Discipline:
- **Don't disable Radar without a replacement.** Net-negative for fraud rate.
- **Tune threshold based on dispute rate** — not on intuition.
- **Custom rules**: minimal, business-specific (compliance, known-fraudster patterns, velocity). Don't recreate Radar's ML signal.
- **Allow-lists for VIP customers** — high-value repeat buyers tripping blocks.
- **Handle [Early Fraud Warnings](/stacks/stripe/stripe-radar/)** — `radar.early_fraud_warning.created`. Most become disputes.

## Connect platform liability

See [Stripe Connect](/stacks/stripe/stripe-connect/) for the controller-properties surface.

From security's perspective:
- **Know which liability model you're on** before designing seller monitoring, fraud signals, suspension workflows.
- **If `controller.losses.payments: 'application'`**: platform is on hook for unrecovered chargebacks. Must hold reserves, monitor connected accounts, build offboarding.
- **Even if Stripe takes losses**, monitor `account.updated`, `capability.updated`, `payout.failed`, `application_fee.refunded`, sudden refund spikes. Build internal dashboards over [Sigma](/stacks/stripe/stripe-sigma/) / [Data Pipeline](/stacks/stripe/stripe-data-pipeline/).

## Agent + MCP security posture

[Stripe-hosted MCP](https://docs.stripe.com/mcp) lets AI agents drive Stripe operations. New threat surface:

| Threat | Mitigation |
|--------|-----------|
| Prompt injection triggering a Stripe operation | [Restricted key](/stacks/stripe/restricted-api-keys/) scoped read-only OR tightly scoped write surface |
| Agent acting on stale context (refunding wrong order) | Multi-step confirmation; summary + human approval before write |
| Audit trail gap | Log every MCP tool invocation: operator, agent session ID, tool, params, response |
| Credentials leak via agent debug output | Don't put secrets in MCP config the agent can echo; use ephemeral tokens / proxy MCP through your service |

**Typical setups:**
- Dev/debug agents → test-mode restricted key, wide scope (read-everything, write-customer)
- Production analytics → live-mode restricted key, read-only
- Production write agents (refund bot) → live-mode restricted key, scoped to ONLY the approved operations, with rate limits

**Proxy MCP through your own service** for high-stakes use: your service holds Stripe creds, enforces additional checks (op allow-list, value caps, approval flows), logs every call with full context. Defense in depth vs direct Stripe-hosted MCP.

## Data residency + GDPR

- **Stripe data residency** — most customer data lives in US (or EU per account home). No single-region EU-only data residency for the core API as of 2026. Schrems II-sensitive customers may need to architect around it (minimize PII in Stripe; store PII in EU-resident DB; use Stripe customer ID as linkage).
- **GDPR DPA** — sign Stripe's standard DPA.
- **Right to erasure** — `stripe.customers.del` soft-deletes / anonymizes; PaymentIntents + Charges retained for regulatory periods.
- **Data minimization in metadata** — don't pile PII into PaymentIntent/Subscription metadata. Reconciliation hints only (order ID, tenant ID).

## Audit logging

What Stripe gives you:
- **[Workbench](/stacks/stripe/stripe-workbench/) → API logs** — every API request (90-day retention)
- **Workbench → Events** — every webhook event Stripe fired (30-day UI, export via API or [Data Pipeline](/stacks/stripe/stripe-data-pipeline/))
- **Dashboard activity logs** — team-member-action audit

What you should add:
- Every webhook event received → your own append-only log (S3, BigQuery, Snowflake)
- Every outbound Stripe API call → application log with request ID, status, idempotency key
- Every [restricted-key](/stacks/stripe/restricted-api-keys/) creation/rotation → infra audit log
- Every MCP tool invocation → application + agent audit log

Reconciliation: monthly, verify Stripe's events log matches your application's record of received events. Gaps = webhook delivery failures or handler drops.

## Patterns this role applies

### TDD on signature verification

- **Red**: tampered body returns 400; stale timestamp (>5min) returns 400; valid event processes once; replay of same event ID acks without reprocessing.
- **Green**: implement.
- **Refactor**: extract verification middleware shared across webhook routes.

### Verification on PCI claims

Don't claim "we're SAQ-A" because you picked Checkout. Verify by running through the SAQ-A questionnaire and signing it. The integration choice qualifies you; the questionnaire is the artifact.

### Debugging Stripe security issues

- Failed signature → raw body handling, secret matches endpoint's secret in Workbench, timestamp tolerance. One variable at a time.
- Failed 3DS → `automatic_payment_methods` enabled, confirmation client-side, issuer's decline reason.
- Radar over-blocking → tune threshold, add specific allow-list entries.

### Branch safety

Stripe code touches money. Two reviews mandatory (this overlay + [backend-architect](/stacks/stripe/backend-architect/) overlay) before merge for any change touching: webhook handlers, key handling, restricted key scopes, payment flow logic, Connect liability config.

## Cross-references

- [backend-architect on Stripe](/stacks/stripe/backend-architect/) — webhook + integration mechanics
- [saas-architect on Stripe](/stacks/stripe/saas-architect/) — billing + entitlements security model
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/) — checkout UX (PCI choices live here)
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — Connect liability framework
- [Stripe Stack index](/stacks/stripe/)
- Authoritative: [docs.stripe.com/security](https://docs.stripe.com/security), [docs.stripe.com/security/guide](https://docs.stripe.com/security/guide)
