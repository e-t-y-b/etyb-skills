---
title: Hyperforce
description: Salesforce's public-cloud infrastructure platform. Regional residency, EU Operating Zone, 20+ regions GA. Default story for in-country data residency.
product:
  name: Hyperforce
  stack: salesforce
  drift_risk: low
  last_verified_on: "2026-05-12"
  applies_to_roles: [system-architect, security-engineer, devops-engineer, healthcare-architect, fintech-architect]
  authoritative_url: https://help.salesforce.com/s/articleView?id=sf.hyperforce_overview.htm
  notes: "Regional infrastructure; deployment topology stable; EU Operating Zone GA Dreamforce '25 as a paid uplift."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26, Dreamforce '25.</div>

## What it is

Hyperforce is Salesforce's public-cloud infrastructure platform, providing regional data residency, scalable compute, and the underlying runtime for Salesforce-hosted services. As of 2026 it spans 20+ regions globally and is the default infrastructure target for new Salesforce orgs.

Canonical reference: [Hyperforce documentation](https://help.salesforce.com/s/articleView?id=sf.hyperforce_overview.htm).

## When this matters

- Any architecture decision involving **data residency** (GDPR, Schrems II, in-country PHI/PII, sovereignty)
- Compliance attestation alignment (HIPAA, GDPR, FedRAMP)
- Cross-region failover, backup residency
- Customer requirements with "data must stay in [country]"

## 2025-2026 currency anchors

- **20+ regions GA** — US, EU, UK, Canada, Australia, Japan, India, Brazil, UAE, KSA, and growing
- **Hyperforce EU Operating Zone** (GA Dreamforce '25, paid uplift) — EU-only support staff + EU-only operations residency, on top of EU data residency. For customers with strict Schrems II / sovereignty requirements.
- **High-risk IP auto-containment** (May 2026 expansion) — anonymizing VPNs / proxies / Tor auto-blocked for connected apps and API by default

## Patterns

- **Default in-country PHI/PII** — pick the regional Hyperforce instance matching your residency requirement
- **EU Operating Zone for strict EU sovereignty** — both data *and* operations stay in the EU
- **BAA scope verification** — Hyperforce regions are HIPAA-eligible for covered products; confirm BAA covers the product mix
- **Failover and backup follow Hyperforce regional rules** — validate residency claims on backup paths, not just primary storage

## Anti-patterns

- **Treating "Hyperforce region" as a marketing claim.** Confirm the org instance, the data residency for backups, and the route for any external service the org calls into.
- **Assuming EU region = full EU sovereignty.** Standard EU region gives data residency. EU Operating Zone (paid uplift) adds operations residency. They are different products.
- **Cross-region service calls without sovereignty review.** A US-region Salesforce calling a EU-region service may move data across borders depending on payload.

## Gotchas

- **Not every SKU is BAA-covered by default.** Add-ons may require explicit BAA addendums.
- **Hyperforce is the *default* for new orgs** but older orgs may be on legacy first-generation infrastructure — verify before quoting residency.
- **High-risk IP auto-containment** is on by default May 2026; verify configuration on older orgs.
- **Region availability for new features lags** — newly GA'd features may not be available in all 20+ regions on day one.

## Cross-references

- Security compliance posture: [security-engineer on Salesforce](/stacks/salesforce/security-engineer/)
- Healthcare residency: [healthcare-architect on Salesforce](/stacks/salesforce/healthcare-architect/), [Health Cloud](/stacks/salesforce/health-cloud/)
- Financial services residency: [fintech-architect on Salesforce](/stacks/salesforce/fintech-architect/), [Financial Services Cloud](/stacks/salesforce/financial-services-cloud/)
- System architecture choice: [system-architect on Salesforce](/stacks/salesforce/system-architect/)
- Authoritative: [Hyperforce documentation](https://help.salesforce.com/s/articleView?id=sf.hyperforce_overview.htm)
