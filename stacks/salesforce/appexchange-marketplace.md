---
title: AppExchange + Marketplace
description: Salesforce's ISV distribution. AppExchange Checkout 2.0 + Salesforce Marketplace (2026) replace pre-2026 buyer flow. AgentExchange ships separately for Agentforce.
product:
  name: AppExchange + Marketplace
  stack: salesforce
  drift_risk: medium
  last_verified_on: "2026-05-12"
  applies_to_roles: [saas-architect, security-engineer, system-architect, ai-ml-engineer]
  authoritative_url: https://appexchange.salesforce.com/
  notes: "Checkout 2.0 + Salesforce Marketplace shift in 2026; AgentExchange (Dreamforce '25) for Agentforce ISVs; ECA mandate May 11 2026 applies to ISV packages."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26, Dreamforce '25.</div>

## What it is

**AppExchange** is Salesforce's ISV marketplace — managed-package distribution for products that install into customer orgs. In 2026 it transitioned to a rebuilt buyer experience:

- **AppExchange Checkout 2.0** — credit-card-to-license-record self-serve path, supports multi-tier pricing pages, integrates with Salesforce Marketplace promotion mechanics
- **Salesforce Marketplace** — the broader storefront framing layered over AppExchange
- **AgentExchange** (Dreamforce '25) — separate marketplace for Agentforce Topics, Actions, agent templates. Separate Security Review track.

Canonical reference: [AppExchange](https://appexchange.salesforce.com/).

## When to use it

For any product distributed to other Salesforce customers — paid or free. The decision of *whether* to publish on AppExchange vs. ship Internal SaaS vs. OEM lives in the [saas-architect overlay](/stacks/salesforce/saas-architect/).

## 2025-2026 currency anchors

- **AppExchange Checkout 2.0** (2026) — modernized buyer flow, credit-card-to-license, multi-tier pricing pages, Marketplace promotion integration.
- **Salesforce Marketplace** — broader storefront wrapper. Featured listings, bundled offers.
- **AgentExchange** (Dreamforce '25) — separate ISV surface for Agentforce-shaped products.
- **ECA mandate May 11, 2026** — AppExchange listings must migrate from Connected Apps to [External Client Apps](/stacks/salesforce/external-client-apps/).
- **2GP only for net-new ISV products** — 1GP managed packages are legacy.
- **Subscriber Org Billing / Salesforce-collected billing** increasingly default for new ISVs.

## Patterns

### Distribution decision (high-level)

| Model | Customer experience | Monetization |
|-------|---------------------|--------------|
| **AppExchange Managed Package (2GP)** | "Install AcmeApp from AppExchange" | AppExchange Checkout 2.0, LMA seat tracking, or custom billing |
| **OEM Embedded App** | Customer signs up at acmeproduct.com; never sees Salesforce | Custom billing; OEM royalty back to Salesforce |
| **Embedded App / Salesforce-as-PaaS** | Customer brand; some advanced users may see Salesforce UI | Custom billing |
| **Internal SaaS** | Customers consume via API or Experience Cloud | Custom billing (per-API-call, per-seat) |
| **AgentExchange** (layered) | Customer installs an agent template into their org | AppExchange Checkout 2.0 or custom |

### Billing — Salesforce-managed vs custom

| Concern | Salesforce-managed (Checkout 2.0 + LMA) | Custom billing |
|---------|------------------------------------------|----------------|
| Time to first dollar | Days | Weeks |
| Margin | 85% (Salesforce takes ~15%) | 97%+ minus billing-platform costs |
| Pricing flexibility | Seat-based + simple tiers | Anything you can model |
| Enterprise contracts (multi-year, custom SLAs) | Limited | Full control |
| PCI / revenue rec scope | Salesforce's problem | Your problem |
| Buyer experience | Salesforce-native | You design it |
| Marketplace discoverability boost | Yes | No |

**Default for net-new 2026 ISVs: Salesforce-managed.** Move to custom only when revenue model demands it (usage-based, enterprise contracts).

### Security Review preparation

The review is non-negotiable for monetized AppExchange distribution. Allow:

- **4-5 weeks** initial submission
- **First-pass success rate is low** — plan on second submission, another 3-4 weeks
- **6-8 weeks of buffer** in any product launch timeline

Top recurring findings that fail review:

1. **SOQL injection** — string-concatenated SOQL with user input. Use bind variables.
2. **Sharing violations** — classes defaulting `without sharing`.
3. **Insufficient FLS enforcement** — queries without `WITH USER_MODE` / DML without `AccessLevel.USER_MODE`.
4. **Weak auth on REST endpoints** — `@RestResource` without permission checks.
5. **Hard-coded credentials** — API keys in Apex source, custom metadata, custom settings.
6. **Missing Code Analyzer report.**
7. **XSS in LWC / Visualforce / Aura.**
8. **Open redirects** — `PageReference` with user-supplied URLs without allowlist.
9. **Site / Experience Cloud guest user with broad permissions.**
10. **Insecure deserialization.**

### AgentExchange specifics

Net-new agent-shaped ISV products in 2026 default to AgentExchange. Same 2GP packaging plumbing; separate listing, separate Security Review track tuned for agent-specific concerns (prompt injection, action authorization, grounding-data leakage). Co-listing an agent companion to an existing AppExchange app is also common.

## Anti-patterns

- **1GP managed package for net-new.** Legacy.
- **Reserving namespace too early.** Permanent decision. Defer until product name has shipped to ≥1 paying customer.
- **Connected Apps inside managed packages** post May 11, 2026. Use [ECA](/stacks/salesforce/external-client-apps/).
- **Treating Security Review as "submission week."** It's an 8-week ongoing process.
- **Breaking managed package backwards compatibility** mid-life. Apex `global` methods/classes are part of your contract — subscribers may have built against them.
- **Choosing custom billing when Salesforce-managed would have served.** "We want full control" sounds good in week 1 and costs a sales cycle every customer in year 2.
- **Hard-coded URLs / org-specific assumptions** ("we'll just call https://acme.my.salesforce.com"). Your package will fail in every other customer's org.
- **Skipping the AppExchange Security Review wizard.** It catches ~60% of issues an external reviewer would.

## Gotchas

- **Each major version requires Security Review.** Patch versions can sometimes skip if the diff is scoped tightly, but assume each major is a review event.
- **AppExchange Checkout 2.0 takes ~15%** standard ISV margin take. That's the price of bundled distribution + runtime + identity + integration + trust.
- **License Management App (LMA)** lives in your packaging org and tracks installs/seats. License records sync automatically from AppExchange Checkout.
- **AgentExchange Security Review is tuned for agent concerns** — prompt injection paths, Action authorization, grounding-data leakage. Different checklist than AppExchange.
- **Salesforce Marketplace usage records** (newer 2026 mechanism) — Salesforce-blessed path for reporting usage back for usage-based monetization. Ecosystem still maturing.

## Cross-references

- ISV depth — distribution model decision, 2GP packaging, fleet management: [saas-architect on Salesforce](/stacks/salesforce/saas-architect/)
- Security Review playbook: [security-engineer on Salesforce](/stacks/salesforce/security-engineer/)
- ECA migration for ISVs: [External Client Apps](/stacks/salesforce/external-client-apps/)
- AgentExchange-specific ISV: [Agentforce](/stacks/salesforce/agentforce/), [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/)
- Packaging CI/CD: [sf CLI](/stacks/salesforce/sf-cli/), [devops-engineer on Salesforce](/stacks/salesforce/devops-engineer/)
- Authoritative: [AppExchange](https://appexchange.salesforce.com/)
