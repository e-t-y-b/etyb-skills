---
title: Stripe Workbench
description: The developer view inside the Stripe Dashboard — API logs, events, webhook endpoints, version pin, restricted keys. 2024 surface absorbing the old "Developers" tab.
product:
  name: Stripe Workbench
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, security-engineer, qa-engineer]
  authoritative_url: https://dashboard.stripe.com/workbench
  notes: "2024 developer view in Dashboard. Replaces parts of the old Developers tab. API logs, events, webhooks, version pin, restricted keys all here."
---

## What it is

Stripe Workbench is the developer surface inside the Stripe Dashboard. It consolidates:

- **API logs** — every API request your account made (request body, response body, status; ~90-day retention)
- **Events** — every webhook event Stripe fired (delivery attempts, responses)
- **Webhook endpoints** — manage endpoints, signing secrets, per-endpoint API version
- **API version pin** — what version your account is pinned to
- **API keys** — secret keys, restricted keys, rotation
- **Logs tail** — real-time streaming

Released 2024; absorbing parts of the old "Developers" tab.

Canonical reference: [dashboard.stripe.com/workbench](https://dashboard.stripe.com/workbench).

## When to use

- **Debugging** — every Stripe debugging chain starts in Workbench.
- **Rotating keys** — secret + restricted key rotation lives here.
- **Adjusting webhook endpoints** — adding/removing endpoints, rotating signing secrets, setting per-endpoint API version.
- **Checking the account's API version pin** — critical when the same code produces different JSON across accounts.
- **Audit + forensics** — API log retention provides the audit trail for what your code did.

## 2025-2026 currency anchors

- **Workbench is the modern surface.** Old "Developers" tab is being absorbed.
- **Per-endpoint API version pinning** is here — each webhook endpoint can pin separately from the account.
- **Restricted Keys** management lives here — see [Restricted API Keys](/stacks/stripe/restricted-api-keys/).
- **Test mode + live mode** switch at the top — Workbench shows the current mode's data.

## Patterns

### Debugging chain — always starts here

When something doesn't work:

1. **Events tab** — was a webhook fired? Did it arrive at your endpoint? What response code?
2. **API logs** — what did your code actually send? What did Stripe return?
3. **API version pin** — does it match your code's pin? Mismatch = silent failure mode.
4. **Webhook endpoints** — is the right endpoint pointed at the right URL with the right secret?

Don't shotgun fixes. The data is here; read it.

### Rotating signing secrets

Workbench → Webhooks → endpoint → Reveal/Roll. Brief window where both old + new secrets are valid during rotation; deploy code with new secret, then expire the old.

### Account API version pin

Workbench → Developers → API version. Surfaces what the account is pinned to. When you upgrade pin, choose a target version; Stripe walks you through breaking changes. Don't auto-upgrade silently via SDK.

### Per-endpoint API version

Each webhook endpoint has its own `api_version` field. Set this to match your handler's code. Otherwise the account-level pin governs and you can get a different event shape than expected.

## Anti-patterns

- **Debugging Stripe without checking Workbench.** Wasted time.
- **Multiple endpoints sharing one signing secret.** Different endpoints, different secrets.
- **Forgetting to pin webhook endpoints to a specific API version.** Account-level pin governs; can drift independently.
- **Treating Workbench API logs as your only audit trail.** ~90-day retention; for longer retention sync to your warehouse via [Data Pipeline](/stacks/stripe/stripe-data-pipeline/).

## Gotchas

- **Test mode and live mode** are completely separate Workbench surfaces. The mode switcher at the top changes what you see.
- **Connect events** for connected accounts appear in the platform's Workbench with `account` context. Per-account dashboards (Express, Standard) have their own Workbench-equivalent surfaces.
- **API logs retention** is ~90 days; for forensics beyond that, mirror to a warehouse.

## Cross-references

- [Webhooks](/stacks/stripe/webhooks/) — endpoints managed in Workbench
- [API Versions + Pinning](/stacks/stripe/api-versions/) — pin surface
- [Restricted API Keys](/stacks/stripe/restricted-api-keys/) — key management
- [Stripe CLI](/stacks/stripe/stripe-cli/) — local-dev counterpart
- [Stripe Data Pipeline](/stacks/stripe/stripe-data-pipeline/) — long-term audit retention
- [backend-architect on Stripe](/stacks/stripe/backend-architect/)
- [security-engineer on Stripe](/stacks/stripe/security-engineer/)
- Authoritative: [dashboard.stripe.com/workbench](https://dashboard.stripe.com/workbench)
