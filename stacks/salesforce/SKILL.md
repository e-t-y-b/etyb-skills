---
name: stack-salesforce
description: >
  Salesforce platform knowledge overlay for the ETYB team. Loads when work involves the Salesforce ecosystem — orgs, Apex, LWC, Flow, Data 360, Agentforce, MuleSoft, Heroku, Industries clouds, Trailhead, sfdx/sf CLI, AppExchange, OmniStudio, Trust Layer, Hyperforce. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Salesforce work as of Spring '26.
  Triggers: salesforce, sfdc, apex, lwc, lightning web component, lightning, visualforce, aura, flow builder, flow orchestration, agentforce, einstein, atlas reasoning, atlas reasoning engine, prompt builder, trust layer, einstein trust layer, model gateway, data cloud, data 360, zero copy, hyperforce, sales cloud, service cloud, marketing cloud, commerce cloud, experience cloud, health cloud, financial services cloud, fsc, manufacturing cloud, public sector solutions, omnistudio, omniscript, integration procedure, data mapper, dataraptor, mulesoft, anypoint, heroku, salesforce functions, named credential, external credential, external client app, eca, connected app, mfa enforcement, scratch org, sandbox, unlocked package, 2gp, sf cli, sfdx, salesforce cli, devops center, copado, gearset, autorabit, code analyzer, apex guru, apexguru, lwc jest, einstein bot, einstein copilot, agentforce vibes, agentforce builder, agent script, soql, sosl, pub/sub api, platform event, change data capture, big object, salesforce connect, tableau, slack canvas, mcp server salesforce, agentexchange, appexchange, security review, trailhead, trailblazer, dreamforce, tdx, trailblazerdx, salesforce admin, salesforce architect, ctas, certified technical architect, agentforce specialist.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.2"
  category: stack-pack
  last_verified_release: "Spring '26"
  last_verified_on: "2026-05-12"
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
  primary:
    - { name: "Salesforce Developer Docs",      url: "https://developer.salesforce.com/docs",                                   type: official_docs }
    - { name: "Spring '26 Release Notes",        url: "https://help.salesforce.com/s/articleView?id=release-notes.salesforce_release_notes.htm", type: release_notes }
    - { name: "sf CLI Command Reference",        url: "https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/", type: cli_reference }
    - { name: "Apex Developer Guide",            url: "https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/",  type: api_reference }
    - { name: "Lightning Web Components Dev",    url: "https://developer.salesforce.com/docs/component-library/documentation/en/lwc", type: official_docs }
    - { name: "Agentforce Developer Docs",       url: "https://developer.salesforce.com/docs/einstein/genai/overview",            type: official_docs }
    - { name: "Data 360 (Data Cloud) Docs",      url: "https://developer.salesforce.com/docs/data/data-cloud-int/guide/",         type: official_docs }
    - { name: "Salesforce Architects",           url: "https://architect.salesforce.com/",                                        type: official_docs }
    - { name: "Trailblazer Community Releases",  url: "https://trailhead.salesforce.com/trailblazer-community",                   type: community }
    - { name: "External Client Apps Migration",  url: "https://help.salesforce.com/s/articleView?id=sf.connected_apps_eca_migration.htm", type: official_docs }
delegate_to_skills:
  # No first-party Salesforce-hosted MCP server is generally available as of last_verified_on.
  # Salesforce-Hosted MCP Servers GA'd April 2026 — when an MCP client surface ships in users'
  # environments, add it here.
  []
products_covered:
  - { name: "Agentforce",              drift_risk: high,   notes: "Renamed from Einstein Copilot Jan 2025; Atlas Reasoning Engine + Topics + Actions + Guardrails; pricing model shifted twice in 2025-2026" }
  - { name: "Data 360",                drift_risk: high,   notes: "Renamed from Data Cloud at Dreamforce '25; Zero Copy adapters expanded TDX 2026" }
  - { name: "Apex",                    drift_risk: medium, notes: "Spring '26 added Cursors and user-mode SOQL; transaction finalizers GA'd 2025" }
  - { name: "Lightning Web Components", drift_risk: medium, notes: "Spring '26: TypeScript types, lightning/graphql, reactive screen flows" }
  - { name: "Flow",                    drift_risk: medium, notes: "Flow Orchestration went free Feb 2026" }
  - { name: "Salesforce-Hosted MCP",   drift_risk: high,   notes: "GA April 2026; surface is new and changing" }
  - { name: "External Client Apps",    drift_risk: high,   notes: "Mandatory migration deadline May 11 2026; old Connected Apps deprecated" }
  - { name: "MFA Enforcement",         drift_risk: high,   notes: "Phased enforcement June-August 2026" }
  - { name: "sf CLI",                  drift_risk: medium, notes: "Replaces deprecated sfdx alias; smart test selection added Spring '26" }
  - { name: "Einstein Trust Layer",    drift_risk: medium, notes: "Architecture documented; provider list expands per Agentforce model gateway updates" }
  - { name: "Health Cloud",            drift_risk: low,    notes: "FHIR R4 + HL7 v2 stable; OmniStudio integration steady" }
  - { name: "Financial Services Cloud", drift_risk: low,   notes: "Data model stable; defers to fintech-architect for ledger/PCI/PSD2" }
  - { name: "Hyperforce",              drift_risk: low,    notes: "Regional infrastructure; deployment topology stable" }
  - { name: "AppExchange + Marketplace", drift_risk: medium, notes: "Checkout 2.0 + Salesforce Marketplace shift in 2026" }
  - { name: "Heroku",                  drift_risk: high,   notes: "End-of-new-enterprise-sales Feb 2026; recommend off-platform for new builds" }
  - { name: "Salesforce Functions",    drift_risk: high,   notes: "Retired Jan 2025 — flag immediately if user mentions" }
---

# Salesforce Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Salesforce knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/salesforce/index.md`](index.md)
- **Per-product pages:** `stacks/salesforce/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/salesforce/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/salesforce/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Einstein Copilot is now Agentforce** (renamed Jan 2025). Same product. Old names are wrong.
- **Data Cloud is now Data 360** (renamed Dreamforce '25). CRM Analytics is now Tableau Cloud-integrated.
- **Headless 360** (TDX 2026) — the whole platform is exposed as APIs/MCP/CLI. Agent clients (Claude Code, Cursor, Codex) can drive Salesforce directly.
- **Salesforce Hosted MCP Servers** went GA in April 2026 (Enterprise+). 60+ MCP tools shipped.
- **Agentforce Vibes 2.0** (TDX 2026) — Salesforce's in-IDE coding agent. Default model is Claude Sonnet 4.5.
- **Salesforce Functions was retired** (Jan 31, 2025). **Heroku ended new enterprise sales** (Feb 2026). Don't propose either for new architecture.
- **`sf` CLI** is current; `sfdx` is a deprecated alias.
- **External Client Apps (ECA)** replace Connected Apps — mandatory migration deadline **May 11, 2026**.
- **MFA mandate** for all UI logins phases in **June–August 2026**. Phishing-resistant MFA required for admins.
- **Apex Cursors** GA in Spring '26 — iterate 50M-row result sets across transactions.
- **Flow Orchestration is free** (Feb 2026) — no longer a paid add-on.
- **Lightning Out 2.0** GA (Winter '26). **LWC TypeScript types + `lightning/graphql` module** (Spring '26).

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on a Salesforce engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Honor the Trust Layer for all AI/agent work.** Any AI/agent work must run through Einstein Trust Layer (zero retention, data masking, FLS in grounding, audit trail). Never recommend direct LLM calls bypassing it for customer data — even when the user asks.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Salesforce | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Salesforce alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
