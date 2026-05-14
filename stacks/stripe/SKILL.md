---
name: stack-stripe
description: >
  Stripe platform knowledge overlay for the ETYB team. Loads when work involves the Stripe ecosystem — Payments, Checkout, Elements, Billing, Subscriptions, Meter API, Customer Portal, Connect, Treasury, Issuing, Identity, Tax, Radar, Terminal, Climate, Atlas, Sigma, Data Pipeline, Capital, Financial Connections, Link, Tap to Pay, BNPL (Affirm/Klarna/Afterpay), ACH/SEPA/RTP/FedNow, Stripe CLI, Workbench, Stripe Apps, Stripe-hosted MCP, webhooks, restricted API keys, idempotency. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Stripe work as of Q2 2026.
  Triggers: stripe, stripe.com, stripe api, payment intent, payment_intent, setup intent, setup_intent, checkout session, stripe checkout, stripe elements, payment element, express checkout element, link button, stripe link, pay with link, stripe billing, stripe subscription, subscription schedule, recurring invoice, invoice item, customer portal, stripe-hosted portal, billing portal, meter api, stripe meter, meter event, billing meter, usage record, metered subscription, stripe connect, connect account, account onboarding, account link, express dashboard, standard account, custom account, connect express, connect custom, controller properties, connected account, platform fee, application fee, destination charge, separate charges and transfers, stripe treasury, financial account, issued card, stripe issuing, card program, authorization, cardholder, stripe identity, identity verification, kyc stripe, stripe tax, automatic tax, tax rates, stripe radar, radar rule, fraud signal, 3d secure, 3ds2, sca, strong customer authentication, psd2, stripe atlas, stripe terminal, tap to pay, terminal reader, stripe climate, stripe apps, stripe sigma, sigma query, stripe data pipeline, stripe capital, stripe-hosted mcp, stripe mcp, stripe workbench, stripe cli, stripe listen, restricted api key, restricted key, webhook signing secret, idempotency key, idempotency-key, api version, api-version, version pinning, webhook endpoint, webhook event, account.updated, invoice.payment_succeeded, payment_intent.succeeded, ach debit, sepa debit, us bank account, sepa_debit, financial connections, plaid alternative, optimized checkout suite, adaptive pricing, link authentication element, address element, klarna, afterpay, clearpay, affirm, bnpl, rtp, fednow, push to card.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
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

# Stripe Stack Pack — Team Briefing

You're working on the Stripe platform. This is a **knowledge overlay**, not a new specialist. The existing ETYB team is doing the work — backend-architect writes the webhook handlers and idempotent server-side flows, security-engineer enforces PCI scope reduction and key hygiene, saas-architect picks the billing model, e-commerce-architect designs the checkout surface, fintech-architect handles Connect/Treasury/Issuing platform liability. This pack teaches each role what the platform expects in 2026.

**Currency stamp:** verified against Stripe API version `2025-11-15.acacia` and the docs/changelog as of 2026-05-14. If today's date is more than 6 months past `last_verified_on` above, the pack is stale — warn the user and consult [docs.stripe.com/changelog](https://docs.stripe.com/changelog) before asserting API-level details.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2024 cutoff will get these wrong:

- **Meter API replaced `usage_records`** for net-new usage-based billing. The old `subscription_item.create_usage_record` pattern is **deprecated for new subscriptions** (announced late 2024). New work uses [`/v1/billing/meter_events`](https://docs.stripe.com/billing/subscriptions/usage-based) and a `billing.meter` object that prices via the new `billing.meter_event_summary` aggregation. Existing legacy usage-record subscriptions still work; new ones must use Meters.
- **Connect "Custom" type is now controller properties.** Account creation in 2024+ uses `controller` configuration (controller.fees.payer, controller.losses.payments, controller.stripe_dashboard.type, controller.requirement_collection) rather than the older `type: 'custom' | 'express' | 'standard'` shorthand. The legacy shorthands still work but are mapped internally to controller properties. Reference: [`docs.stripe.com/connect/account-types`](https://docs.stripe.com/connect/accounts).
- **Stripe Workbench** (2024) is the developer surface inside Dashboard. The old "Developers" tab is being phased into Workbench — API logs, events, webhook endpoints, version pin all live there.
- **API version pinning** — every Stripe account is **auto-pinned** to a version on first call. A new account today gets `2025-11-15.acacia` (or whatever is current). An account created in 2019 is still pinned to a 2019 version unless someone upgrades it. **The same code against two accounts can return different JSON.** Check the pin under Workbench → API version before debugging "but my code is right."
- **Express Checkout Element** (GA 2024) consolidates Apple Pay, Google Pay, Link, Amazon Pay, PayPal into a single button row. Replaces hand-wired Payment Request Button + individual wallet integrations. Use this for new builds; don't compose Payment Request Button by hand.
- **Payment Element** (the unified Element) is the modern default; the legacy **Card Element** should not be used for new builds. Payment Element renders all enabled payment methods (cards, wallets, BNPL, bank debits) dynamically based on country/currency/amount.
- **Optimized Checkout Suite** (2024-2025) — feature bundle including Adaptive Pricing, Link, Express Checkout Element, smart payment method ordering, and ML-driven conversion optimizations. Enabled per Checkout/Payment Element configuration.
- **Stripe Tax** auto-calculation expanded jurisdictions through 2025 and offers Registration-as-a-Service in supported countries. Don't roll your own tax tables for new builds in covered jurisdictions.
- **SCA / 3D Secure 2** is mandatory in EU/UK/EEA. PaymentIntents handle this automatically when `automatic_payment_methods.enabled: true` and you use the confirmation flow correctly. The legacy Sources API and direct Charges flow do NOT handle SCA cleanly — another reason to avoid Charges API for new work.
- **Idempotency Key TTL** is contractually guaranteed at **24 hours** since 2024. Earlier guidance treated it as "best effort" — now it's a real guarantee, but only for 24 hours. Long-running retry chains beyond 24h must mint new keys.
- **Restricted API keys** with scoped permissions are GA and recommended for any service-to-Stripe integration that doesn't need full secret-key power. The "one secret key for everything" pattern is a security smell in 2026.
- **Stripe-hosted MCP server** ([docs.stripe.com/mcp](https://docs.stripe.com/mcp)) shipped in 2025 for select operations. AI agents (Claude, Cursor, Codex) can drive Stripe via MCP tools. Production usage requires a scoped restricted key and full audit logging — see security-engineer overlay.
- **Stripe Connect onboarding via `account_link`** with `type: account_onboarding` is the modern pattern. Legacy email-based "Connect Onboarding" redirects are being phased out.
- **Treasury** matured in 2025-2026 with RTP and FedNow rails for OutboundPayments; eligibility is partner-bank-dependent (Evolve Bank, Goldman Sachs depending on flow) and gated to approved platforms.
- **Tap to Pay on iPhone/Android** expanded to more countries through 2025. Requires Stripe Terminal SDK + Apple/Google entitlements + merchant eligibility.
- **Link** (Stripe's 1-click identity + payment) adoption is now mainstream. The dedicated **Link Authentication Element** captures email and lets returning Link users skip the form. Use it on Checkout Element forms; don't ignore it.
- **Adaptive Pricing** (2024) — Checkout can display localized prices in the buyer's currency with the conversion handled by Stripe. Requires multi-currency Prices and Stripe Tax to be coherent.

If you find yourself recommending `usage_records.create` for a brand-new subscription, `type: 'custom'` for a new Connect account without controller properties, the legacy Card Element, Payment Request Button hand-wired, or "just put the secret key in the env var and call it a day" — you're using stale knowledge. Read the references below.

## How this pack plugs in

ETYB's router detects Stripe signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement, debugging. The Stripe overlay does not relax engineering discipline; it shapes how the discipline is applied. TDD on a webhook handler = `stripe trigger <event>` against `stripe listen --forward-to localhost`, plus signature verification under test, plus idempotent replay test.

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | The heaviest overlay. Payment Intents vs Setup Intents vs Checkout decision; webhook architecture (signing, replay, idempotency, ordering); Meter API for usage billing; Connect platform server flow (onboarding, transfers, payouts); restricted keys; API version pinning + upgrade discipline; Stripe CLI dev loop; Stripe MCP integration; testing strategy with `stripe trigger` |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | PCI scope reduction (Stripe-hosted Checkout vs Elements vs raw API — the SAQ-A vs SAQ-A-EP vs SAQ-D split); webhook signature verification; key hygiene (publishable / secret / restricted); 3DS2 + SCA mandate; Radar configuration; Connect platform liability shifts; agent + MCP security posture; data residency considerations |
| `saas-architect` | [`references/saas-architect.md`](references/saas-architect.md) | Pricing model implementation on Stripe (flat, per-seat, tiered, usage, hybrid, credits); Meter API for usage-based; subscription lifecycle (trials, conversions, dunning, cancellations, pauses); Customer Portal config; proration and plan migrations; entitlements (Stripe-native vs your own); revenue recognition with Stripe |
| `e-commerce-architect` | [`references/e-commerce-architect.md`](references/e-commerce-architect.md) | Checkout architecture (hosted vs Elements vs custom UI); cart-to-payment-intent state mapping; auth vs capture; refunds and disputes; BNPL surfacing (Affirm/Klarna/Afterpay); wallets (Apple Pay, Google Pay, Link, Amazon Pay); Adaptive Pricing + multi-currency; international/local payment methods; abandoned cart recovery |
| `fintech-architect` | [`references/fintech-architect.md`](references/fintech-architect.md) | **Stripe as platform infrastructure for embedded finance.** Connect platform liability (Standard vs Express vs Custom/controller properties); Treasury Financial Accounts + OutboundPayments + RTP/FedNow; Issuing card programs; Identity (KYC) and Financial Connections; reconciliation against Stripe Reports + Sigma + Data Pipeline. **Stripe is NOT your ledger of record.** Defers to fintech-architect for double-entry, regulatory capital, PSD2/PCI/AML semantics |

## The Stripe surface, in one map

```
                    ┌─────────────────────────────────────────────────────────────┐
                    │                          STRIPE                              │
                    │                                                              │
   Acceptance       │ Payments       │ Billing         │ Connect      │ Embedded   │
   plane            │ ───────────    │ ─────────────   │ ──────────   │ Finance    │
                    │ Checkout       │ Subscriptions   │ Standard     │ ────────   │
                    │ Payment Elem.  │ Meter API       │ Express      │ Treasury   │
                    │ Express CO     │ Customer Portal │ Custom       │ Issuing    │
                    │ Link           │ Invoicing       │ Embedded UI  │ Capital    │
                    │ Terminal       │ Tax             │ Components   │ Identity   │
                    │ Tap to Pay     │ Adaptive Pricing│              │ Financial  │
                    │                │                  │              │ Connections│
                    │ Payment Intents (the underlying primitive for all of these)   │
                    │                                                              │
   Operational      │ Webhooks       │ Idempotency     │ Restricted   │ API        │
   plane            │ Workbench      │ keys            │ keys         │ versions   │
                    │ Stripe CLI     │                  │              │ + pinning  │
                    │                                                              │
   Risk & Audit     │ Radar          │ Disputes        │ Sigma        │ Data       │
   plane            │ 3DS2 / SCA     │ EFWs            │ (SQL)        │ Pipeline   │
                    │                                                              │
   Agent plane      │ Stripe-hosted MCP (2025+) — agents drive Stripe via tools    │
                    │                                                              │
   Marketplace      │ Stripe Apps (Dashboard apps) │ Stripe App Marketplace        │
                    └─────────────────────────────────────────────────────────────┘
```

The roles map onto this surface like so:

- **backend-architect** owns the Acceptance plane (server side) + the Operational plane + Connect server flows + Meter API plumbing.
- **security-engineer** owns the Risk & Audit plane + key hygiene across the Operational plane + PCI scope for the Acceptance plane.
- **saas-architect** owns Billing (Subscriptions, Meter API, Customer Portal, Tax).
- **e-commerce-architect** owns the Acceptance plane (UX side) + Adaptive Pricing + payment-method curation.
- **fintech-architect** owns Connect (platform + liability) + Embedded Finance (Treasury / Issuing / Identity / Capital / Financial Connections).

The Agent plane crosses all roles — agents that drive Stripe inherit your security posture, idempotency discipline, and audit trail.

## Top platform gotchas the team must know

These are the named ones that bite in production. Read these before writing the first line of Stripe code:

1. **API version drift between accounts.** Each Stripe account is pinned to a version on first request. Your dev account, staging account, and production account can be on three different versions. Code that round-trips one shape of JSON in dev can fail in production. **Pin explicitly in the SDK constructor** (`apiVersion: '2025-11-15.acacia'`) and check the Workbench pin on every account. Upgrade via Dashboard → Workbench → API version, never silently via SDK auto-detection.

2. **Webhook ordering is NOT guaranteed.** `invoice.payment_succeeded` can arrive before `invoice.created` in pathological cases. Stripe sends events in roughly creation order but does not guarantee strict ordering. **Make every handler order-independent and idempotent.** Use the event's `created` timestamp + your own event-id-seen table to deduplicate. Don't assume "this event implies that one already arrived."

3. **Webhooks are at-least-once.** Stripe retries on non-2xx. You will see the same event multiple times. The event ID (`evt_*`) is the dedup key; the idempotency token is for *outbound* calls to Stripe, not inbound. Mix these up and you'll either double-process or fail to retry.

4. **`PaymentIntent.confirm` vs `automatic_payment_methods`.** The 2024+ default flow is: create PI with `automatic_payment_methods: { enabled: true }`, return `client_secret` to the frontend, let Payment Element confirm with `stripe.confirmPayment({ clientSecret, ... })`. Old flows that called `pi.confirm` server-side without redirect handling broke SCA. **Don't confirm server-side unless you specifically need server-side confirmation** (off-session merchant-initiated transactions).

5. **`SetupIntent` is for save-card-now-charge-later.** Common mistake: using `PaymentIntent` with `setup_future_usage` for the save-card flow when no immediate charge is needed. If you're not charging now, use `SetupIntent`. If you're charging now AND saving, use `PaymentIntent` with `setup_future_usage: 'off_session'`. Mixing these breaks SCA exemptions and creates phantom charges.

6. **Connect platforms are liable for connected-account compliance.** Standard, Express, Custom (now controller properties) — different liability levels. Platforms must implement `account.updated` and `capability.updated` webhooks and pause activity when capabilities go inactive. Missing this is a regulatory exposure, not just a UX bug. See fintech-architect overlay for the full table.

7. **Restricted Keys, not the secret key.** Service-to-Stripe integrations (analytics jobs, reconciliation workers, third-party SaaS) should use a **Restricted Key** scoped to only the resources they need. Pasting the rk_live_* secret key into a Zapier integration is the kind of thing that costs $200k when it leaks.

8. **Meter API is the only path for new usage billing.** Legacy `usage_records` still works for existing metered subscriptions, but new subscriptions billing per-unit consumption use **billing.meter** + meter events. Migration from legacy is non-trivial — proration changes, summary semantics differ. See saas-architect overlay.

9. **`automatic_payment_methods` requires careful country/currency matching.** The dynamic payment-method rendering only shows methods enabled in Dashboard AND eligible for the buyer's country + currency + amount. A US customer in USD will see different methods than an EU customer in EUR. Don't hard-code expectations.

10. **PCI scope is determined by your integration, not Stripe.** Stripe-hosted Checkout = SAQ-A (lowest scope). Elements / Payment Element with iframes = SAQ-A-EP. Raw API + your form submitting card data = SAQ-D (full PCI). Many teams pick Elements thinking it's SAQ-A; it's not. See security-engineer overlay.

## Test mode discipline — non-negotiable

Stripe ships every account with a fully-functional **Test mode** that mirrors live but uses test credentials, test cards, and test bank accounts. **Every Stripe integration in this stack must have a green test-mode E2E test before any live-mode work.** Specifics:

- Test mode is a separate set of keys (`pk_test_*`, `sk_test_*`, `rk_test_*`, `whsec_test_*`). Don't share keys across modes.
- Test cards from [docs.stripe.com/testing](https://docs.stripe.com/testing) — `4242 4242 4242 4242` is the canonical success card; `4000 0027 6000 3184` is the SCA challenge card; `4000 0000 0000 9995` is insufficient funds. Each test card has a documented outcome.
- Test bank accounts (`000123456789` / `110000000`) for ACH and Treasury flows.
- Test mode webhooks have their own signing secrets. `stripe listen` generates a temporary test secret for local dev.
- `stripe trigger <event>` produces real test-mode resources and fires real webhooks against your forwarded endpoint. Use this for E2E.

What test mode does NOT do:
- It does not connect to real bank rails. Test mode ACH "settles" instantly; live mode takes 3-5 business days. Don't write code that depends on test mode's faster settlement.
- It does not run the real Radar ML model. Test mode Radar uses simplified rules. Production fraud signal will differ.
- It does not invoke real partner banks for Treasury / Issuing. Some edge cases (real-world delivery delays, bank rejection codes) only show up in live.

For live-mode launches: pre-launch smoke test in live mode with a small real charge (refunded immediately) to verify the full live flow. Test mode catches ~95% of issues; the remaining 5% are real-rail-only.

## How TDD, verification, and debugging look on Stripe

### TDD

The Stripe-specific TDD cycle:

1. **Red**: write a test that fails. For webhook handlers, the test uses `Stripe.webhooks.generateTestHeaderString` to forge a valid signature on a fixture event, POSTs to the handler, and asserts the side effect.
2. **Green**: implement the handler.
3. **Refactor**: extract dedup, extract event-type dispatch, extract domain logic.

For server-side flows (PaymentIntent creation, Connect onboarding, Meter event ingestion):
- Test against `stripe-mock` for fast unit tests (fixture-only, no real Stripe call).
- Test against test mode via `stripe trigger` for integration tests.
- Record cassettes with VCR / nock for deterministic CI without hitting Stripe.

### Verification

The fundamental verification question on Stripe: **does our local state agree with Stripe's state?** Three layers:

1. **Synchronous response** — what the create/update API call returned.
2. **Webhook event** — what Stripe fired asynchronously.
3. **Resource retrieval** — what `stripe.<resource>.retrieve` returns now.

These can disagree if a webhook was missed, your handler errored, your local cache is stale, or you're hitting different accounts (test vs live, platform vs connected). For high-confidence verification:

```typescript
const stripeView = await stripe.subscriptions.retrieve(localTenant.stripeSubscriptionId);
assertEqual(stripeView.status, localTenant.subscriptionStatus, 'state drift');
```

When state drifts: don't paper over with a sync job. Investigate why. Usually a webhook handler bug or a missed event.

### Debugging

Stripe gives you the tools to debug almost any issue from the Workbench:
- **Events** — every webhook Stripe fired, including delivery attempts and responses
- **API logs** — every API request from your account (request body, response body, status)
- **Logs tail** — `stripe logs tail` for real-time streaming

The disciplined debugging chain:
1. What did the user expect to happen?
2. What does Stripe say happened? (Workbench events + API logs)
3. What does our DB say happened?
4. Where do (2) and (3) disagree?
5. Fix the disagreement at the root, not at the symptom.

Common Stripe-specific debugging pitfalls:
- "The PaymentIntent succeeded but my handler didn't run" → check Events for the webhook delivery, check your endpoint's signing secret, check `stripe-signature` parsing.
- "Stripe says succeeded, my DB says failed" → check webhook receipt, check handler logic for the event type, check event-id dedup.
- "The response shape is different than I expected" → check API version pin on the account vs your SDK pin.
- "Connect transfer succeeded but seller balance unchanged" → check capability state on the connected account, check that the transfer landed in the right destination.

## Stripe-on-Stripe — when one Stripe primitive depends on another

The most complex Stripe integrations chain primitives. Examples that come up often:

- **Subscription with usage** = Stripe Billing (Subscription) + Meter API (usage) + Customer + PaymentMethod. The Subscription's metered Price references the Meter. Meter events flow to `meter_event_summary` which produces the invoice line.

- **Connect platform billing its connected accounts** = Connect Standard account for the customer + Subscription on the platform account billing the customer for platform fees + Direct charges flowing from the customer to the connected account separately. Multiple layered relationships.

- **Marketplace with Treasury balance** = Connect account for seller + Treasury Financial Account for seller's balance + Issuing card backed by Treasury balance + Outbound payments out of Treasury to settle elsewhere. Stripe is doing four jobs simultaneously.

- **SaaS with embedded finance for its customers** = Stripe Billing for SaaS subscription + Connect (Standard / Express) for the SaaS's customers' transactions + Treasury for customer balance holding + Issuing for cards the customer issues. Five products.

For these layered architectures, **draw the data model first.** Which Stripe object is parent of which? Which webhook events impact which side of the ledger? Where is the source of truth for each piece of state? You can lose a week to debugging without a clean data model.

## Compliance composition

When Stripe work touches a vertical:

- **fintech-architect** owns: double-entry ledger semantics, regulatory capital, KYC/AML beyond what Stripe Identity provides, PSD2 SCA logic beyond what PaymentIntents handle, MTL/MSB licensing implications, FedNow/RTP corridor rules at the bank level. Stripe gives you primitives; fintech-architect tells you what to do with them.
- **e-commerce-architect** owns: cart state machine, inventory holds at auth/capture, refund/RMA flows, order-to-payment reconciliation semantics, multi-PSP failover (if Stripe is one of several PSPs).
- **saas-architect** owns: pricing model selection (per-seat vs usage vs hybrid vs credit), churn metrics, entitlements engine, multi-tenant billing data model. Stripe Billing is the implementation; saas-architect picks the model.
- **security-engineer** owns: PCI scope determination, key rotation, webhook signing, restricted-key scoping, audit logging. This pack tells security-engineer what Stripe-specific controls exist; security-engineer enforces them.
- **healthcare-architect** owns: HIPAA implications if PHI is being passed through Stripe (Stripe is NOT HIPAA-covered out of the box — escalate immediately if PHI is in play).

Don't restate compliance content from this pack inside the vertical; route the question.

## Currency — when this pack is stale

This pack is verified to API version `2025-11-15.acacia` as of 2026-05-14. The Stripe API ships a versioned release on a rolling basis (typically every 2-4 months for a named version, with smaller changelog entries weekly).

**Refresh trigger:** if today's date is > 6 months past `last_verified_on`, before recommending API shapes or product names:
1. Open [docs.stripe.com/changelog](https://docs.stripe.com/changelog) — note the latest version date.
2. Check for breaking changes in `2026-*` versions affecting the surface you're using.
3. Verify Meter API surface, Connect controller properties, and Checkout Element configuration — these moved most recently.
4. Note any product renames (Stripe has a habit: "Connect Custom" → controller properties, "metered subscriptions" → "Meter API", "Developers tab" → "Workbench").

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| PSP selection (Stripe vs Adyen vs Braintree) | `e-commerce-architect` or `fintech-architect` without the pack overlay — selection is platform-agnostic |
| Tax compliance beyond what Stripe Tax handles | Tax specialist / accountant (out of ETYB scope); flag and route |
| Ledger of record — double-entry, GAAP/IFRS recognition | `fintech-architect` (Stripe Sigma/Data Pipeline can *feed* the ledger but is not it) |
| HIPAA / PHI passing through payment metadata | `healthcare-architect` — Stripe is not HIPAA-covered by default |
| Multi-PSP orchestration (Primer, Spreedly, Gr4vy) | `e-commerce-architect` without this pack — orchestration is cross-PSP |
| Custom card networks / banking license / direct bank integrations | `fintech-architect` — Stripe is one option among rails |

## Stack composition

If the user is using Stripe **plus** another stack (Vercel, AWS, Supabase, Salesforce), and that other stack has its own pack registered in `STACKS.md`, both overlays load. The Stripe pack handles Stripe-side patterns (webhook handlers, restricted keys, Meter API ingestion, Connect flows); the other pack handles its side (Vercel route handlers, AWS Lambda webhook ingress, Supabase row-level security on the `payments` table, Salesforce Named Credentials to Stripe). Neither pack should pretend to know the other's depth.

## Standing instructions for every role on a Stripe engagement

1. **Currency-check the API version first.** Before recommending an endpoint shape, parameter name, or returned field, confirm whether the user's account is on a recent version. The single fastest way to mis-debug a Stripe issue is to assume the request shape your code is sending matches the response shape the user's account is producing. Check Workbench.

2. **Treat webhooks as the source of truth, not API responses.** A PaymentIntent's status in the response to your `create` call is a *snapshot*. The webhook `payment_intent.succeeded` is the *event*. Update your database from the webhook, not the synchronous response. Yes, even for "obvious" cases.

3. **Verify webhook signatures. Always. With the test-mode secret in test, the live-mode secret in live.** Mixing keys silently fails verification and the webhook handler returns 400. The handler must also verify *the right endpoint's* secret — accounts often have multiple endpoints (one for billing events, one for Connect events) with different secrets.

4. **Idempotency on every state-changing API call to Stripe.** `POST /v1/charges`, `POST /v1/payment_intents`, `POST /v1/transfers`, etc. — include `Idempotency-Key` header (24h TTL). Without it, network retries from your side double-charge.

5. **Restricted keys for everything that isn't full-trust.** The secret key is for first-party server code you control. Anything else — analytics scrapers, reconciliation jobs, AI agents calling Stripe MCP, third-party tools — gets a restricted key scoped to the minimum permissions.

6. **Defer to verticals on compliance semantics.** Stripe gives you mechanisms; PSD2/PCI/AML semantics belong to fintech-architect or security-engineer (PCI scope) or healthcare-architect (PHI). Don't restate compliance reasoning inside a Stripe how-to.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- No Marketing Cloud / commerce platform deep dive (Stripe is a payment layer; specific shopfront frameworks like Medusa/Saleor/Shopify integration belong in their own stacks).
- No deep coverage of Stripe Atlas legal/incorporation flows (mostly out-of-engineering).
- No frontend-architect overlay specifically — frontend payment work is covered inside e-commerce-architect overlay (Checkout, Elements, Express Checkout, Link). When a Stripe-frontend-only engagement gets common enough to merit its own role, add `frontend-architect.md`.
- No mobile-architect overlay — Stripe iOS/Android SDKs, Apple Pay/Google Pay native integration, Tap to Pay device SDKs. Currently covered as a thin section inside e-commerce-architect. Promote to its own overlay if mobile-only Stripe work becomes a common pattern.
- No devops-engineer overlay — webhook ingress patterns (queue-fronted webhook handlers, dead-letter queues, replay tools) are covered in backend-architect. Promote if infra-side Stripe work becomes its own engagement type.
- No qa-engineer overlay — testing patterns are inside backend-architect (`stripe trigger`, `stripe-mock`, fixture cassettes). Promote if test infra becomes its own engagement.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-changelog validation.
