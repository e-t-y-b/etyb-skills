---
title: Salesforce
description: Salesforce platform knowledge overlay — orgs, Apex, LWC, Flow, Data 360, Agentforce, MuleSoft, Heroku, Industries clouds, Trailhead, sfdx/sf CLI, AppExchange, OmniStudio, Trust Layer, Hyperforce. Current to Spring '26.
stack:
  vendor: salesforce
  last_verified_on: "2026-05-12"
  drift_risk_default: medium
  applies_to_roles:
    - system-architect
    - backend-architect
    - frontend-architect
    - ai-ml-engineer
    - database-architect
    - devops-engineer
    - security-engineer
    - qa-engineer
    - saas-architect
    - healthcare-architect
    - fintech-architect
  authoritative_sources:
    - { name: "Salesforce Developer Docs",      url: "https://developer.salesforce.com/docs", type: official_docs }
    - { name: "Spring '26 Release Notes",        url: "https://help.salesforce.com/s/articleView?id=release-notes.salesforce_release_notes.htm", type: release_notes }
    - { name: "sf CLI Command Reference",        url: "https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/", type: cli_reference }
    - { name: "Apex Developer Guide",            url: "https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/", type: api_reference }
    - { name: "Lightning Web Components Dev",    url: "https://developer.salesforce.com/docs/component-library/documentation/en/lwc", type: official_docs }
    - { name: "Agentforce Developer Docs",       url: "https://developer.salesforce.com/docs/einstein/genai/overview", type: official_docs }
    - { name: "Data 360 (Data Cloud) Docs",      url: "https://developer.salesforce.com/docs/data/data-cloud-int/guide/", type: official_docs }
    - { name: "External Client Apps Migration",  url: "https://help.salesforce.com/s/articleView?id=sf.connected_apps_eca_migration.htm", type: official_docs }
  delegate_to_skills: []
---

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26 (API v66.0), TDX 2026 (April), Dreamforce '25.</div>

If today's date is more than 6 months past the last_verified_on above, treat platform specifics with extra care — bias toward the [authoritative sources](#authoritative-sources) for time-sensitive claims. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness.

## What changed in 2025-2026 that older training data misses

- **Einstein Copilot → Agentforce** (Jan 2025) — agent product complete rebrand, with Atlas Reasoning Engine, Topics, Actions, Guardrails, Agent Script
- **Data Cloud → Data 360** (Dreamforce '25)
- **Apex Cursors** (Spring '26) — pagination over large query results
- **LWC `lightning/graphql` + TypeScript types** (Spring '26)
- **Salesforce-Hosted MCP Servers** (GA April 2026)
- **Headless 360** (TDX 2026) — Data 360 + Agentforce composable
- **External Client Apps migration** — mandatory by May 11, 2026; old Connected Apps deprecated
- **MFA enforcement** — phased June-August 2026
- **Flow Orchestration** went free (Feb 2026)
- **Heroku** — end-of-new-enterprise-sales (Feb 2026)
- **Salesforce Functions** — retired Jan 2025 (flag if user mentions)
- **Smart Test Selection** (Spring '26) — only runs tests affected by changes

## Products covered

Each product has its own canonical page below. Drift risk is the per-product refresh threshold (see [Knowledge Currency](/conventions/knowledge-currency/)).

| Product | Drift risk | Why |
|---|---|---|
| [Agentforce](/stacks/salesforce/agentforce/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Renamed from Einstein Copilot Jan 2025; Atlas Reasoning + pricing model shifted twice in 2025-2026 |
| [Data 360](/stacks/salesforce/data-360/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Renamed from Data Cloud at Dreamforce '25; Zero Copy adapters expanded TDX 2026 |
| [Apex](/stacks/salesforce/apex/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Spring '26 added Cursors and user-mode SOQL; transaction finalizers GA'd 2025 |
| [Lightning Web Components](/stacks/salesforce/lwc/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Spring '26: TypeScript types, lightning/graphql, reactive screen flows |
| [Flow](/stacks/salesforce/flow/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Flow Orchestration went free Feb 2026 |
| [Salesforce-Hosted MCP](/stacks/salesforce/salesforce-hosted-mcp/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA April 2026; surface is new and changing |
| [External Client Apps](/stacks/salesforce/external-client-apps/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Mandatory migration deadline May 11 2026 |
| [MFA Enforcement](/stacks/salesforce/mfa-enforcement/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Phased enforcement June-August 2026 |
| [sf CLI](/stacks/salesforce/sf-cli/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Replaces deprecated sfdx alias; smart test selection added Spring '26 |
| [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Architecture documented; provider list expands per Agentforce model gateway |
| [Health Cloud](/stacks/salesforce/health-cloud/) | <span class="etyb-drift-badge" data-risk="low">low</span> | FHIR R4 + HL7 v2 stable; OmniStudio integration steady |
| [Financial Services Cloud](/stacks/salesforce/financial-services-cloud/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Data model stable; defers to fintech-architect for ledger/PCI/PSD2 |
| [Hyperforce](/stacks/salesforce/hyperforce/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Regional infrastructure; deployment topology stable |
| [AppExchange + Marketplace](/stacks/salesforce/appexchange-marketplace/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Checkout 2.0 + Salesforce Marketplace shift in 2026 |
| [Heroku](/stacks/salesforce/heroku/) | <span class="etyb-drift-badge" data-risk="high">high</span> | End-of-new-enterprise-sales Feb 2026; recommend off-platform for new builds |
| [Salesforce Functions](/stacks/salesforce/salesforce-functions/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Retired Jan 2025 — flag immediately if user mentions |

## Role overlays

Composed views under `/stacks/salesforce/<role>/`. Each stitches together the products that role's work touches; depth lives in the product pages.

- [system-architect on Salesforce](/stacks/salesforce/system-architect/) — primitive selection, agent vs Flow vs Apex, Headless 360, org topology
- [backend-architect on Salesforce](/stacks/salesforce/backend-architect/) — modern Apex, Pub/Sub, Named Credentials, MCP-as-Action
- [frontend-architect on Salesforce](/stacks/salesforce/frontend-architect/) — LWC, `lightning/graphql`, LWR, Lightning Out 2.0, Aura migration
- [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/) — Agentforce design, Atlas, Trust Layer, Prompt Builder, BYOM
- [database-architect on Salesforce](/stacks/salesforce/database-architect/) — Data 360, Zero Copy, Big Objects, sharing, LDV
- [devops-engineer on Salesforce](/stacks/salesforce/devops-engineer/) — `sf` CLI, 2GP packaging, scratch orgs, smart test selection
- [security-engineer on Salesforce](/stacks/salesforce/security-engineer/) — Trust Layer, ECA migration, MFA mandate, Shield
- [qa-engineer on Salesforce](/stacks/salesforce/qa-engineer/) — Apex tests, LWC Jest, Code Analyzer, ApexGuru, smart selection
- [saas-architect on Salesforce](/stacks/salesforce/saas-architect/) — ISV/OEM/Embedded/Internal, 2GP, AppExchange Checkout 2.0, AgentExchange
- [healthcare-architect on Salesforce](/stacks/salesforce/healthcare-architect/) — Health Cloud data model, FHIR adapters, Agentforce Health
- [fintech-architect on Salesforce](/stacks/salesforce/fintech-architect/) — FSC data model, money-movement gates, MuleSoft Banking Accelerator

## Authoritative sources

For verified-current behavior, see the official Salesforce surfaces:

- **[Developer Docs](https://developer.salesforce.com/docs)** — canonical reference
- **[Spring '26 Release Notes](https://help.salesforce.com/s/articleView?id=release-notes.salesforce_release_notes.htm)** — current release
- **[sf CLI Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)**
- **[Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)**
- **[LWC Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)**
- **[Agentforce Developer Docs](https://developer.salesforce.com/docs/einstein/genai/overview)**
- **[Data 360 Docs](https://developer.salesforce.com/docs/data/data-cloud-int/guide/)**
- **[External Client Apps Migration](https://help.salesforce.com/s/articleView?id=sf.connected_apps_eca_migration.htm)** — mandatory pre-May-11-2026

## Delegate skills

No first-party Salesforce-hosted MCP server is generally available in user environments as of the last verification date. **Salesforce-Hosted MCP Servers** GA'd April 2026 — once an installable MCP client surface ships with a known skill identifier, it will be added to `delegate_to_skills` and ETYB will defer to it for matching products.
