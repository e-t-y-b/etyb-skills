---
title: Stripe
description: Stripe platform knowledge overlay — Payments, Checkout, Elements, Billing, Connect, Treasury, Issuing, Identity, Tax, Radar, Terminal, MCP, webhooks, restricted keys. Current to API 2025-11-15.acacia.
stack:
  vendor: stripe
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - backend-architect
    - security-engineer
    - saas-architect
    - e-commerce-architect
    - fintech-architect
  authoritative_sources:
    - { name: "Stripe Docs",                  url: "https://docs.stripe.com/",                                  type: official_docs }
    - { name: "Stripe API Reference",         url: "https://docs.stripe.com/api",                               type: api_reference }
    - { name: "Stripe Changelog",             url: "https://docs.stripe.com/changelog",                         type: changelog }
    - { name: "Stripe Upgrades Guide",        url: "https://docs.stripe.com/upgrades",                          type: changelog }
    - { name: "Stripe CLI Reference",         url: "https://docs.stripe.com/stripe-cli",                        type: cli_reference }
    - { name: "Stripe Webhooks Guide",        url: "https://docs.stripe.com/webhooks",                          type: official_docs }
    - { name: "Stripe Connect Docs",          url: "https://docs.stripe.com/connect",                           type: official_docs }
    - { name: "Stripe Billing — Meter API",   url: "https://docs.stripe.com/billing/subscriptions/usage-based", type: official_docs }
    - { name: "Stripe MCP Server",            url: "https://docs.stripe.com/mcp",                               type: official_docs }
    - { name: "Stripe Status",                url: "https://status.stripe.com/",                                type: official_docs }
  delegate_to_skills: []
---

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Stripe API version <code>2025-11-15.acacia</code> and docs.stripe.com/changelog.</div>

If today's date is more than 6 months past the last_verified_on above, treat API-level claims (request shapes, parameter names, event payloads) with extra care — bias toward the [authoritative sources](#authoritative-sources) for time-sensitive specifics. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness on this Stack.

## What changed in 2025-2026 that older training data misses

An LLM with a 2024 cutoff will get these wrong:

- **Meter API replaced `usage_records`** (late 2024) — new metered subscriptions must use [`billing.meter`](/stacks/stripe/meter-api/) + [`billing.meter_events`](/stacks/stripe/meter-api/). The legacy `subscription_item.create_usage_record` pattern is deprecated for new subscriptions; existing metered subscriptions continue to work.
- **Connect "Custom" type → `controller` properties** (2024). New connected accounts configure `controller.fees.payer`, `controller.losses.payments`, `controller.stripe_dashboard.type`, `controller.requirement_collection`. Legacy `type: 'custom' | 'express' | 'standard'` shorthand still works but maps internally to controller fields.
- **Stripe Workbench** (2024) — developer surface inside Dashboard. The old "Developers" tab is being absorbed; API logs, events, webhook endpoints, version pin, restricted keys all live in Workbench now.
- **API version auto-pinning** — every Stripe account is auto-pinned to a version on first call. New accounts today get `2025-11-15.acacia`; accounts created in 2019 are still pinned to 2019 versions unless explicitly upgraded. The same code against two accounts can return different JSON.
- **Express Checkout Element** (GA 2024) consolidates Apple Pay, Google Pay, Link, Amazon Pay, PayPal into a single component. Replaces hand-wired Payment Request Button + individual wallet integrations.
- **Payment Element** is the modern unified Element. Legacy **Card Element** should not be used for new builds.
- **Optimized Checkout Suite** (2024-2025) — bundle of Adaptive Pricing, Link, Express Checkout Element, smart payment method ordering, conversion ML. Enabled per Checkout/Payment Element.
- **Stripe Tax** auto-calculation expanded jurisdictions through 2025; Registration-as-a-Service available in 50+ countries.
- **SCA / 3D Secure 2** is mandatory in EU/UK/EEA. PaymentIntents handle it transparently when `automatic_payment_methods.enabled: true` and confirm flow is client-side. Legacy Sources and direct Charges API do NOT handle SCA cleanly.
- **Idempotency Key TTL** — contractually guaranteed at 24 hours since 2024. Long retry chains beyond 24h must mint new keys.
- **Restricted API keys** are GA and recommended. Service-to-Stripe integrations using `sk_live_*` everywhere is now a security finding.
- **Stripe-hosted MCP server** ([docs.stripe.com/mcp](https://docs.stripe.com/mcp)) shipped in 2025 for select operations. AI agents drive Stripe via MCP tools; production usage requires scoped restricted keys + audit logging.
- **Connect onboarding via `account_link`** with `type: account_onboarding` is the modern pattern. Legacy email-based "Connect Onboarding" redirects are being phased out.
- **Treasury** matured 2024-2026 — RTP and FedNow rails for OutboundPayments. Partner-bank-gated (Evolve, Goldman Sachs in US).
- **Tap to Pay on iPhone/Android** expanded geographic availability through 2025.
- **PCI DSS v4.0** enforcement of previously "best practice" controls began March 31, 2024. Requirements 6.4.3 (payment-page script management) and 11.6.1 (tamper detection) materially affect SAQ-A-EP merchants.

If you find yourself recommending `usage_records.create` for a brand-new subscription, `type: 'custom'` for a new Connect account, the legacy Card Element, the legacy Payment Request Button hand-wired, server-side `pi.confirm` for on-session flows, or "just put the secret key in the env var" — you're using stale knowledge.

## Products covered

Per-product pages live under `/stacks/stripe/<product>/`.

### Acceptance plane (server-side primitives)

| Product | Drift risk | Why |
|---|---|---|
| [Payment Intents](/stacks/stripe/payment-intents/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Stable surface; `automatic_payment_methods` + client-side confirm semantics shifted 2024-2025 |
| [Setup Intents](/stacks/stripe/setup-intents/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Required for save-card-now-charge-later; commonly confused with PaymentIntent + `setup_future_usage` |
| [Stripe Checkout](/stacks/stripe/stripe-checkout/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Recommended default for new builds; `ui_mode=embedded` expanded 2024-2025 |
| [Payment Element](/stacks/stripe/payment-element/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Modern unified Element — replaces legacy Card Element for new builds |
| [Express Checkout Element](/stacks/stripe/express-checkout-element/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Single component for Apple Pay, Google Pay, Link, Amazon Pay, PayPal |
| [Link](/stacks/stripe/link/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | 1-click checkout; adoption growing rapidly 2024-2026 |
| [Optimized Checkout Suite](/stacks/stripe/optimized-checkout-suite/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Feature bundle 2024-2025; on by default for new Checkout/Payment Element |
| [Adaptive Pricing](/stacks/stripe/adaptive-pricing/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Localized pricing in Checkout; requires multi-currency + Tax |

### Billing plane

| Product | Drift risk | Why |
|---|---|---|
| [Stripe Billing — Subscriptions](/stacks/stripe/stripe-billing/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Stable but `proration_behavior`, `billing_cycle_anchor`, trial conversions are non-obvious |
| [Meter API](/stacks/stripe/meter-api/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Replaces legacy `usage_records` for new metered subscriptions (late 2024); migration is mandatory for net-new usage billing |
| [Customer Portal](/stacks/stripe/customer-portal/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stripe-hosted; configuration matured 2024-2025 but core surface stable |
| [Stripe Tax](/stacks/stripe/stripe-tax/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Auto-calc expanded through 2025; Registration-as-a-Service available |

### Connect + embedded finance

| Product | Drift risk | Why |
|---|---|---|
| [Stripe Connect](/stacks/stripe/stripe-connect/) | <span class="etyb-drift-badge" data-risk="high">high</span> | `controller` properties replaced legacy `type` in 2024; liability config is now explicit |
| [Stripe Treasury](/stacks/stripe/stripe-treasury/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Financial Accounts, OutboundPayments, RTP/FedNow; partner-bank-gated; expanding 2025-2026 |
| [Stripe Issuing](/stacks/stripe/stripe-issuing/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Card programs expanding internationally 2025-2026; authorization webhook is non-negotiable |
| [Stripe Identity](/stacks/stripe/stripe-identity/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Document + selfie verification; pricing and supported countries shifted 2024-2025 |
| [Stripe Financial Connections](/stacks/stripe/stripe-financial-connections/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Plaid alternative; country support expanded 2024-2025 |
| [Stripe Capital](/stacks/stripe/stripe-capital/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Financing for Connect platforms; underwriting proprietary |

### Risk + audit plane

| Product | Drift risk | Why |
|---|---|---|
| [Stripe Radar](/stacks/stripe/stripe-radar/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | ML models updated continuously; Adaptive Acceptance (2024) shifted block patterns |
| [SCA / 3D Secure 2](/stacks/stripe/sca-3ds2/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Mandatory EU/UK/EEA; PaymentIntents handle by default |
| [Stripe Sigma](/stacks/stripe/stripe-sigma/) | <span class="etyb-drift-badge" data-risk="low">low</span> | In-Dashboard SQL over your Stripe data; surface stable |
| [Stripe Data Pipeline](/stacks/stripe/stripe-data-pipeline/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Warehouse sync to Snowflake/Redshift/BigQuery/Databricks; schema stable |

### In-person + terminal

| Product | Drift risk | Why |
|---|---|---|
| [Stripe Terminal](/stacks/stripe/stripe-terminal/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Reader SDKs evolve quarterly; new hardware in 2023-2024 |
| [Tap to Pay](/stacks/stripe/tap-to-pay/) | <span class="etyb-drift-badge" data-risk="high">high</span> | iPhone (US/UK/CA/AU/etc.) and Android availability expanding 2025-2026 |

### Operational plane (developer + agent surface)

| Product | Drift risk | Why |
|---|---|---|
| [Webhooks](/stacks/stripe/webhooks/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Delivery is at-least-once; ordering NOT guaranteed; signing verification is mandatory |
| [Idempotency Keys](/stacks/stripe/idempotency-keys/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | 24h TTL contractually guaranteed since 2024 |
| [Restricted API Keys](/stacks/stripe/restricted-api-keys/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Least-privilege scoped keys; adoption uneven; flag `sk_live_` everywhere |
| [API Versions + Pinning](/stacks/stripe/api-versions/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Accounts auto-pin on first request; cross-account drift is common 2026 surface |
| [Stripe CLI](/stacks/stripe/stripe-cli/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; `stripe listen` + `stripe trigger` are the dev loop |
| [Stripe Workbench](/stacks/stripe/stripe-workbench/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | 2024 developer surface in Dashboard; absorbing the old "Developers" tab |
| [Stripe Apps](/stacks/stripe/stripe-apps/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Embedded apps in Stripe Dashboard; Stripe Apps SDK + UI Toolkit |
| [Stripe Climate](/stacks/stripe/stripe-climate/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Carbon removal contributions; small API surface, stable |

### Payment-method rails

| Product | Drift risk | Why |
|---|---|---|
| [ACH Direct Debit](/stacks/stripe/ach-debit/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Bank debit; mandate handling, longer settlement, dispute windows differ from cards |
| [SEPA Direct Debit](/stacks/stripe/sepa-debit/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | EU bank debit; 5+ business day settlement; mandate semantics |
| [RTP / FedNow](/stacks/stripe/rtp-fednow/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Real-time rails via Treasury OutboundPayments; corridor support expanding 2025-2026 |
| [BNPL providers](/stacks/stripe/bnpl-providers/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Affirm, Klarna, Afterpay/Clearpay surfaced through Payment Element; eligibility per country, currency, amount |

## Role overlays

Composed views under `/stacks/stripe/<role>/`. Each one stitches together the products that role's work touches.

- [/stacks/stripe/backend-architect/](/stacks/stripe/backend-architect/) — payment primitive choice, webhook architecture, Meter API plumbing, Connect server flows, API version pinning, restricted keys, Stripe CLI dev loop, MCP integration
- [/stacks/stripe/security-engineer/](/stacks/stripe/security-engineer/) — PCI scope (SAQ-A vs SAQ-A-EP vs SAQ-D), webhook signing, key hygiene, 3DS2/SCA, Radar configuration, Connect platform liability, agent + MCP security
- [/stacks/stripe/saas-architect/](/stacks/stripe/saas-architect/) — pricing model on Stripe (flat / per-seat / tiered / usage / hybrid / credits), Meter API for usage billing, subscription lifecycle, Customer Portal, entitlements, revenue recognition
- [/stacks/stripe/e-commerce-architect/](/stacks/stripe/e-commerce-architect/) — checkout architecture, cart-to-PaymentIntent mapping, auth/capture, refunds + disputes, BNPL, wallets, Adaptive Pricing, payment-method curation
- [/stacks/stripe/fintech-architect/](/stacks/stripe/fintech-architect/) — Connect platform liability (controller properties), Treasury Financial Accounts + RTP/FedNow, Issuing card programs, Identity, reconciliation against Sigma/Data Pipeline. Stripe is NOT your ledger of record

## Authoritative sources

For verified-current behavior, see the official Stripe surfaces:

- **[Stripe Docs](https://docs.stripe.com/)** — canonical reference
- **[Stripe API Reference](https://docs.stripe.com/api)** — request/response shapes per version
- **[Stripe Changelog](https://docs.stripe.com/changelog)** — version-by-version release notes
- **[Stripe Upgrades Guide](https://docs.stripe.com/upgrades)** — breaking-change inventory per version
- **[Stripe CLI Reference](https://docs.stripe.com/stripe-cli)**
- **[Stripe Webhooks Guide](https://docs.stripe.com/webhooks)**
- **[Stripe Connect Docs](https://docs.stripe.com/connect)**
- **[Stripe Billing — Meter API](https://docs.stripe.com/billing/subscriptions/usage-based)**
- **[Stripe MCP Server](https://docs.stripe.com/mcp)**
- **[Stripe Status](https://status.stripe.com/)** — incident page

## Delegate skills

Stripe ships a first-party MCP server ([docs.stripe.com/mcp](https://docs.stripe.com/mcp)) that exposes Payments, Billing, Connect, Subscriptions, Customers, Webhooks, and a subset of API operations as MCP tools. It is **not bundled** in every user's environment by default — it ships as a Stripe-provided MCP that users install themselves (npx-style or via Cursor/Claude Desktop config). When bundled or first-party-installable into Claude Code as a built-in plugin, `delegate_to_skills` will be populated with `stripe:mcp` covering Payments, Billing, Connect, Subscriptions, Webhooks, and the API surface.

Until then: ETYB uses this Stack as the opinionated knowledge layer; when high-stakes strict-path is triggered (large refunds, Connect onboarding for regulated platforms, money movement in live mode), agents should fetch from `docs.stripe.com` directly and ground specifics in that fetched content.
