---
name: stack-stripe
description: >
  Stripe platform knowledge overlay for the ETYB team. Loads when work involves the Stripe ecosystem — Payments, Checkout, Elements, Billing, Subscriptions, Meter API, Customer Portal, Connect, Treasury, Issuing, Identity, Tax, Radar, Terminal, Climate, Atlas, Sigma, Data Pipeline, Capital, Financial Connections, Link, Tap to Pay, BNPL (Affirm/Klarna/Afterpay), ACH/SEPA/RTP/FedNow, Stripe CLI, Workbench, Stripe Apps, Stripe-hosted MCP, webhooks, restricted API keys, idempotency. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Stripe work as of Q2 2026.
  Triggers: stripe, stripe.com, stripe api, payment intent, payment_intent, setup intent, setup_intent, checkout session, stripe checkout, stripe elements, payment element, express checkout element, link button, stripe link, pay with link, stripe billing, stripe subscription, subscription schedule, recurring invoice, invoice item, customer portal, stripe-hosted portal, billing portal, meter api, stripe meter, meter event, billing meter, usage record, metered subscription, stripe connect, connect account, account onboarding, account link, express dashboard, standard account, custom account, connect express, connect custom, controller properties, connected account, platform fee, application fee, destination charge, separate charges and transfers, stripe treasury, financial account, issued card, stripe issuing, card program, authorization, cardholder, stripe identity, identity verification, kyc stripe, stripe tax, automatic tax, tax rates, stripe radar, radar rule, fraud signal, 3d secure, 3ds2, sca, strong customer authentication, psd2, stripe atlas, stripe terminal, tap to pay, terminal reader, stripe climate, stripe apps, stripe sigma, sigma query, stripe data pipeline, stripe capital, stripe-hosted mcp, stripe mcp, stripe workbench, stripe cli, stripe listen, restricted api key, restricted key, webhook signing secret, idempotency key, idempotency-key, api version, api-version, version pinning, webhook endpoint, webhook event, account.updated, invoice.payment_succeeded, payment_intent.succeeded, ach debit, sepa debit, us bank account, sepa_debit, financial connections, plaid alternative, optimized checkout suite, adaptive pricing, link authentication element, address element, klarna, afterpay, clearpay, affirm, bnpl, rtp, fednow, push to card.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "5.0.0-dev"
  category: stack-pack
  last_verified_api_version: "2025-11-15.acacia"
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - backend-architect
    - security-engineer
    - saas-architect
    - e-commerce-architect
    - fintech-architect
authoritative_sources:
  primary:
    - { name: "Stripe Docs",                        url: "https://docs.stripe.com/",                          type: official_docs }
    - { name: "Stripe API Reference",               url: "https://docs.stripe.com/api",                       type: api_reference }
    - { name: "Stripe Changelog",                   url: "https://docs.stripe.com/changelog",                 type: changelog }
    - { name: "Stripe Upgrades Guide",              url: "https://docs.stripe.com/upgrades",                  type: changelog }
    - { name: "Stripe CLI Reference",               url: "https://docs.stripe.com/stripe-cli",                type: cli_reference }
    - { name: "Stripe Webhooks Guide",              url: "https://docs.stripe.com/webhooks",                  type: official_docs }
    - { name: "Stripe Connect Docs",                url: "https://docs.stripe.com/connect",                   type: official_docs }
    - { name: "Stripe Billing — Meter API",         url: "https://docs.stripe.com/billing/subscriptions/usage-based",  type: official_docs }
    - { name: "Stripe MCP Server",                  url: "https://docs.stripe.com/mcp",                       type: official_docs }
    - { name: "Stripe Engineering Blog",            url: "https://stripe.com/blog/engineering",               type: blog }
    - { name: "Stripe GitHub",                      url: "https://github.com/stripe",                         type: source_code }
    - { name: "Stripe Status",                      url: "https://status.stripe.com/",                        type: status_page }
delegate_to_skills:
  # Stripe ships a first-party MCP server (https://docs.stripe.com/mcp) that exposes
  # Payments, Billing, Connect, Subscriptions, Customers, Webhooks, and a subset of
  # API operations as MCP tools. We do not list it here because it is not bundled
  # in every user's environment by default — it ships as a Stripe-provided MCP that
  # users install themselves (npx-style or via Cursor/Claude Desktop config). When
  # bundled or first-party-installable into Claude Code as a built-in plugin, add:
  # - { skill: "stripe:mcp", covers: [Payments, Billing, Connect, Subscriptions, Webhooks, API] }
  []
products_covered:
  - { name: "Payment Intents API",         drift_risk: medium, notes: "Stable surface but confirmation flow + automatic_payment_methods semantics shifted 2024-2025; off-session vs on-session distinctions still trip people up" }
  - { name: "Setup Intents API",           drift_risk: medium, notes: "Required for saving cards under SCA — common mistake is using PaymentIntent for save-and-charge-later" }
  - { name: "Charges API (legacy)",        drift_risk: low,    notes: "Functional but legacy. Don't propose for new integrations — PaymentIntents has been default since 2019" }
  - { name: "Stripe Checkout (hosted)",    drift_risk: medium, notes: "Recommended default for most new integrations as of 2024; ui_mode=custom and embedded mode expanded 2024-2025" }
  - { name: "Stripe Elements / Payment Element", drift_risk: medium, notes: "Payment Element is the modern unified Element — legacy Card Element should not be used for new builds" }
  - { name: "Express Checkout Element",    drift_risk: medium, notes: "Single component that surfaces Apple Pay, Google Pay, Link, Amazon Pay, PayPal — replaces individual wallet buttons" }
  - { name: "Stripe Link",                 drift_risk: medium, notes: "1-click checkout; adoption growing rapidly 2024-2026; Link Authentication Element is the dedicated surface" }
  - { name: "Stripe Billing — Subscriptions", drift_risk: medium, notes: "Stable but proration_behavior, billing_cycle_anchor, trial conversions are non-obvious" }
  - { name: "Stripe Billing — Meter API",  drift_risk: high,   notes: "Replaces legacy metered subscriptions / usage_records (deprecated 2024 for new subscriptions). Migration is mandatory for net-new usage-based billing" }
  - { name: "Customer Portal",             drift_risk: low,    notes: "Stripe-hosted; configuration options expanded 2024-2025 but core surface stable" }
  - { name: "Stripe Connect (Standard)",   drift_risk: medium, notes: "Auto-onboarding via account_link is the modern pattern; Connect Onboarding (legacy redirect) is being phased out" }
  - { name: "Stripe Connect (Express)",    drift_risk: medium, notes: "Express dashboard remains; Custom-controller-style features merged in 2024 — see controller properties" }
  - { name: "Stripe Connect (Custom)",     drift_risk: high,   notes: "Replaced by configurable `controller` properties (2024). Legacy `type: custom` still accepted but new accounts should use controller fields" }
  - { name: "Stripe Treasury",             drift_risk: high,   notes: "Embedded finance — Financial Accounts, OutboundPayments, RTP/FedNow; partner-bank-dependent eligibility; B2B SaaS adoption expanding 2025-2026" }
  - { name: "Stripe Issuing",              drift_risk: high,   notes: "Card issuing programs expanding internationally 2025-2026; authorization webhooks are critical and easy to miss" }
  - { name: "Stripe Identity",             drift_risk: medium, notes: "Document + selfie verification; pricing and supported countries shifted 2024-2025" }
  - { name: "Stripe Tax",                  drift_risk: medium, notes: "Automatic tax calculation expanded jurisdictions through 2025; registration-as-a-service available" }
  - { name: "Stripe Radar",                drift_risk: medium, notes: "ML models updated continuously; Radar for Fraud Teams adds rules engine. Block-list patterns shifted with Adaptive Acceptance (2024)" }
  - { name: "Stripe Atlas",                drift_risk: low,    notes: "Incorporation product; surface stable. Mostly out-of-engineering scope" }
  - { name: "Stripe Terminal",             drift_risk: medium, notes: "In-person payments + Tap to Pay on iPhone/Android; reader SDKs evolve quarterly" }
  - { name: "Tap to Pay",                  drift_risk: high,   notes: "iPhone (US/UK/CA/AU/etc) and Android availability expanding 2025-2026; entitlement gates and merchant requirements differ by country" }
  - { name: "Stripe Climate",              drift_risk: low,    notes: "Carbon removal contributions; small API surface (Climate Orders), stable" }
  - { name: "Stripe Apps",                 drift_risk: medium, notes: "Embedded apps in Stripe Dashboard; Stripe Apps SDK + Stripe UI Toolkit. Distribution via Stripe App Marketplace" }
  - { name: "Stripe Sigma",                drift_risk: low,    notes: "SQL queries over your Stripe data inside the Dashboard. Stable surface" }
  - { name: "Stripe Data Pipeline",        drift_risk: low,    notes: "Native warehouse sync to Snowflake / Redshift / BigQuery. Schema stable, frequency configurable" }
  - { name: "Stripe Capital",              drift_risk: medium, notes: "Financing program; available to Connect platforms and direct merchants in eligible countries. Underwriting model proprietary" }
  - { name: "Stripe Financial Connections", drift_risk: medium, notes: "ACH/bank-link product — Stripe's Plaid alternative; expanded country support 2024-2025" }
  - { name: "Stripe CLI",                  drift_risk: low,    notes: "Stable; `stripe listen` is the standard webhook dev loop. `stripe trigger` produces synthetic events for tests" }
  - { name: "Stripe Workbench",            drift_risk: medium, notes: "Developer view in Dashboard (2024) — replaces parts of the old Developers tab. API logs, events, webhooks, version pin all here" }
  - { name: "Webhooks",                    drift_risk: high,   notes: "Delivery ordering is NOT guaranteed; signing secret verification is mandatory; replay-tolerant idempotency is the team's responsibility, not Stripe's" }
  - { name: "Connect Webhooks",            drift_risk: high,   notes: "Distinct from platform webhooks — account.updated, capability.updated, person.* must be wired for compliant onboarding flows" }
  - { name: "Restricted API Keys",         drift_risk: medium, notes: "Least-privilege scoped keys — adoption is uneven. Public-secret-key-everywhere is still common; flag it" }
  - { name: "Idempotency Keys",            drift_risk: medium, notes: "TTL guaranteed at 24 hours since 2024; some users still mint UUIDs that don't survive client retries — see backend-architect overlay" }
  - { name: "API versions + pinning",      drift_risk: high,   notes: "Stripe auto-pins a version to the account at first request; rolling forward requires explicit upgrade. Common 2026 surface: stuck on a 2019 version and unaware" }
  - { name: "Stripe-hosted MCP",           drift_risk: high,   notes: "GA-ish in 2025 for select operations; surface is new and growing. Agents that drive Stripe via MCP need scoped restricted keys and audit trail" }
  - { name: "Optimized Checkout Suite",    drift_risk: medium, notes: "Bundle (2024-2025): Adaptive Pricing, Link, Express Checkout Element, smart payment method ordering. Enabled per Checkout/Payment Element" }
  - { name: "Adaptive Pricing",            drift_risk: medium, notes: "Localized pricing display in Checkout (2024); requires multi-currency support and Tax configuration to be coherent" }
  - { name: "SCA / 3D Secure 2",           drift_risk: medium, notes: "Mandatory in EU/UK/EEA; PaymentIntents handle by default if `automatic_payment_methods` is enabled and confirm flow used correctly" }
  - { name: "BNPL via Stripe (Affirm/Klarna/Afterpay)", drift_risk: medium, notes: "Surfaced through Payment Element / Checkout; eligibility differs by country, amount, currency" }
  - { name: "ACH / SEPA Debit",            drift_risk: medium, notes: "Bank debits require mandate handling, longer settlement, dispute windows differ from cards" }
  - { name: "RTP / FedNow (via Treasury)", drift_risk: high,   notes: "Real-time rails; available through Treasury OutboundPayments. Eligibility and supported corridors expanding 2025-2026" }
---

# Stripe Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Stripe knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/stripe/index.md`](index.md)
- **Per-product pages:** `stacks/stripe/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/stripe/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/stripe/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Meter API replaced `usage_records`** for net-new usage-based billing. The old `subscription_item.create_usage_record` pattern is **deprecated for new subscriptions** (announced late 2024). New work uses `/v1/billing/meter_events` and a `billing.meter` object that prices via the new `billing.meter_event_summary` aggregation. Existing legacy usage-record subscriptions still work; new ones must use Meters.
- **Connect "Custom" type is now controller properties.** Account creation in 2024+ uses `controller` configuration (controller.fees.payer, controller.losses.payments, controller.stripe_dashboard.type, controller.requirement_collection) rather than the older `type: 'custom' | 'express' | 'standard'` shorthand. The legacy shorthands still work but are mapped internally to controller properties.
- **Stripe Workbench** (2024) is the developer surface inside Dashboard. The old "Developers" tab is being phased into Workbench — API logs, events, webhook endpoints, version pin all live there.
- **API version pinning** — every Stripe account is **auto-pinned** to a version on first call. A new account today gets `2025-11-15.acacia` (or whatever is current). An account created in 2019 is still pinned to a 2019 version unless someone upgrades it. **The same code against two accounts can return different JSON.**
- **Express Checkout Element** (GA 2024) consolidates Apple Pay, Google Pay, Link, Amazon Pay, PayPal into a single button row. Replaces hand-wired Payment Request Button + individual wallet integrations.
- **Payment Element** (the unified Element) is the modern default; the legacy **Card Element** should not be used for new builds.
- **SCA / 3D Secure 2** is mandatory in EU/UK/EEA. PaymentIntents handle this automatically when `automatic_payment_methods.enabled: true` and you use the confirmation flow correctly. The legacy Sources API and direct Charges flow do NOT handle SCA cleanly.
- **Idempotency Key TTL** is contractually guaranteed at **24 hours** since 2024. Earlier guidance treated it as "best effort" — now it's a real guarantee, but only for 24 hours. Long-running retry chains beyond 24h must mint new keys.
- **Restricted API keys** with scoped permissions are GA and recommended for any service-to-Stripe integration that doesn't need full secret-key power. The "one secret key for everything" pattern is a security smell in 2026.
- **Stripe-hosted MCP server** (docs.stripe.com/mcp) shipped in 2025 for select operations. AI agents (Claude, Cursor, Codex) can drive Stripe via MCP tools. Production usage requires a scoped restricted key and full audit logging.
- **Stripe Connect onboarding via `account_link`** with `type: account_onboarding` is the modern pattern. Legacy email-based "Connect Onboarding" redirects are being phased out.
- **Treasury** matured in 2025-2026 with RTP and FedNow rails for OutboundPayments; eligibility is partner-bank-dependent and gated to approved platforms.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on a Stripe engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Treat webhooks as the source of truth, not API responses.** A PaymentIntent's status in the response to your `create` call is a snapshot. The webhook `payment_intent.succeeded` is the event. Update your database from the webhook, not the synchronous response. Always verify webhook signatures and use idempotency keys on every state-changing call.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Stripe | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Stripe alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
