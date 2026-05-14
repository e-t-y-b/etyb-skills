---
name: stack-salesforce
description: >
  Salesforce platform knowledge overlay for the ETYB team. Loads when work involves the Salesforce ecosystem — orgs, Apex, LWC, Flow, Data 360, Agentforce, MuleSoft, Heroku, Industries clouds, Trailhead, sfdx/sf CLI, AppExchange, OmniStudio, Trust Layer, Hyperforce. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Salesforce work as of Spring '26.
  Triggers: salesforce, sfdc, apex, lwc, lightning web component, lightning, visualforce, aura, flow builder, flow orchestration, agentforce, einstein, atlas reasoning, atlas reasoning engine, prompt builder, trust layer, einstein trust layer, model gateway, data cloud, data 360, zero copy, hyperforce, sales cloud, service cloud, marketing cloud, commerce cloud, experience cloud, health cloud, financial services cloud, fsc, manufacturing cloud, public sector solutions, omnistudio, omniscript, integration procedure, data mapper, dataraptor, mulesoft, anypoint, heroku, salesforce functions, named credential, external credential, external client app, eca, connected app, mfa enforcement, scratch org, sandbox, unlocked package, 2gp, sf cli, sfdx, salesforce cli, devops center, copado, gearset, autorabit, code analyzer, apex guru, apexguru, lwc jest, einstein bot, einstein copilot, agentforce vibes, agentforce builder, agent script, soql, sosl, pub/sub api, platform event, change data capture, big object, salesforce connect, tableau, slack canvas, mcp server salesforce, agentexchange, appexchange, security review, trailhead, trailblazer, dreamforce, tdx, trailblazerdx, salesforce admin, salesforce architect, ctas, certified technical architect, agentforce specialist.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
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

# Salesforce Stack Pack — Team Briefing

You're working on the Salesforce platform. This is a **knowledge overlay**, not a new specialist. The existing ETYB team is doing the work — backend-architect writes the Apex, frontend-architect writes the LWC, system-architect picks the patterns, security-engineer enforces the Trust Layer. This pack teaches each role what the platform expects in 2026.

**Currency stamp:** verified against Salesforce Spring '26 (API v66.0), TrailblazerDX 2026 (April), Dreamforce 2025. If today's date is more than 6 months past `verified_on` above, the pack is stale — warn the user and consult release notes before recommending API-level details.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2024 cutoff will get these wrong:

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
- **Lightning Out 2.0** GA (Winter '26).
- **LWC TypeScript types + `lightning/graphql` module** (Spring '26).

If you find yourself recommending Einstein Copilot, `sfdx force:source:push`, Connected Apps for new orgs, Salesforce Functions, or Heroku for net-new compute — you're using stale knowledge. Read the references below.

## How this pack plugs in

ETYB's router detects Salesforce signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement, debugging. The Salesforce overlay does not relax engineering discipline; it shapes how the discipline is applied on this platform (e.g., TDD on Apex = Apex test classes; TDD on LWC = Jest with `@salesforce/sfdx-lwc-jest`).

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `system-architect` | [`references/system-architect.md`](references/system-architect.md) | **The architectural decision** — when an Agentforce agent is the answer vs Flow vs Apex vs MuleSoft vs external compute; multi-cloud composition; Headless 360 patterns; integration boundaries |
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | Modern Apex idioms (Cursors, user-mode SOQL, transaction finalizers, Queueable patterns); Platform Events / Pub/Sub API / CDC; Named & External Credentials; **MCP authoring + Apex-as-Agent-Action plumbing**; bulkification & trigger handler pattern |
| `frontend-architect` | [`references/frontend-architect.md`](references/frontend-architect.md) | LWC 2026 (TypeScript types, `lightning/graphql`, reactive screen flows, LWR for Experience Cloud, Lightning Out 2.0); wire-first data; Aura → LWC migration |
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | **Agent design** — Topics/Actions/Guardrails, Atlas Reasoning, Prompt Builder, Agent Script, Einstein Trust Layer config, BYOM via Einstein Studio, Data 360 grounding & vector search, Voice agents |
| `database-architect` | [`references/database-architect.md`](references/database-architect.md) | Data 360, Zero Copy with Snowflake/Databricks/BigQuery, BYOM via Einstein Studio, Big Objects vs Data 360, calculated insights, sharing model from data architect's view, LDV patterns, query plan & selectivity |
| `devops-engineer` | [`references/devops-engineer.md`](references/devops-engineer.md) | `sf` CLI (sfdx alias), scratch orgs, 2GP unlocked/managed packaging, source format, DevOps Center vs Copado/Gearset/AutoRABIT, **smart test selection (Spring '26)**, CI/CD patterns, Agentforce Vibes IDE |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | Einstein Trust Layer (deep), **ECA migration deadline May 11 2026**, **MFA enforcement June–Aug 2026**, Shield (Platform Encryption / Event Monitoring / FAT), permission sets and PSGs, FLS/CRUD enforcement (`WITH USER_MODE`), AppExchange Security Review prep |
| `qa-engineer` | [`references/qa-engineer.md`](references/qa-engineer.md) | Apex tests (75% min, target ≥85% with assertions), LWC Jest, Salesforce Code Analyzer + Graph Engine, ApexGuru, **smart test selection (Spring '26)**, integration / E2E (UTAM, Provar) |
| `saas-architect` | [`references/saas-architect.md`](references/saas-architect.md) | Multi-tenant patterns *on* Salesforce — ISV 2GP managed packaging, OEM, Embedded Apps, AppExchange Checkout 2.0, Salesforce Marketplace, internal SaaS via Experience Cloud + APIs |
| `healthcare-architect` | [`references/healthcare-architect.md`](references/healthcare-architect.md) | **Thin overlay.** Health Cloud data model + Industries adapters (FHIR R4 / HL7 v2) + Agentforce Health agents. Defers to healthcare-architect for HIPAA/FHIR semantics/audit discipline |
| `fintech-architect` | [`references/fintech-architect.md`](references/fintech-architect.md) | **Thin overlay.** Financial Services Cloud data model + MuleSoft Banking Accelerator + Open Banking + Agentforce FSC. **Salesforce is NOT the ledger.** Defers to fintech-architect for ledger/PCI/PSD2/AML |

**v1.1.0 ships all 11 references.** All highest-value 2026 surfaces are now covered.

## Standing instructions for every role on a Salesforce engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, or product names, check whether the overlay references your role. If the overlay covers your area, follow it; do not pattern-match from older general-purpose knowledge. If the overlay does not yet cover your area (v1 has gaps — see table above), say so explicitly and consult release notes before asserting specifics.

2. **Defer to verticals on domain compliance.** Salesforce Health Cloud uses Patient/CarePlan/EncounterParticipant objects — that's a platform fact, in this pack's scope. HIPAA compliance for those records — that's healthcare-architect's territory, in healthcare-architect's scope. Same split for FSC and fintech-architect. Don't restate compliance content from this pack; route to the vertical.

3. **Respect Salesforce-specific governor limits.** Every recommendation that involves Apex, async, queries, or DML must consider: 100 sync SOQL per transaction, 150 DML, 6MB heap (12MB async), 10s CPU sync (60s async). If the user's request implies volumes that don't fit, recommend Batch Apex, Queueable, Apex Cursors, Pub/Sub API, or MuleSoft escalation — don't just write the code and hope.

4. **Honor the Trust Layer.** Any AI/agent work must run through Einstein Trust Layer (zero retention, data masking, FLS in grounding, audit trail). Never recommend direct LLM calls bypassing it for customer data — even when the user asks.

5. **Stay specific about platforms within Salesforce.** "Salesforce" is not one thing. Lightning Experience vs Experience Cloud, Sales vs Service vs Industries, multi-org vs single-org, ISV (managed package) vs internal — these differ materially. Ask if it's unclear.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics for Health Cloud / FSC | `healthcare-architect` / `fintech-architect` |
| Org strategy for ISV / OEM / Embedded distribution | `saas-architect` |
| External system architecture beyond Salesforce | `system-architect` (without the pack overlay) |
| Generic web frontend not touching LWC | `frontend-architect` (without the pack overlay) |
| Non-Salesforce backend service that Salesforce calls into | `backend-architect` (without the pack overlay) |

## Stack composition

If the user is using Salesforce **plus** another stack (Snowflake, AWS, Databricks, Stripe), and that other stack has its own pack registered in `STACKS.md`, both overlays load. The Salesforce pack handles Salesforce-side patterns (Zero Copy from Data 360 → Snowflake, Named Credentials → AWS Lambda, etc.); the other pack handles its side. Neither pack should pretend to know the other's depth.

## Open gaps in v1.1.0

Explicit so future iterations know what's missing:

- No Marketing Cloud / Commerce Cloud coverage (these are large enough to warrant their own sub-references; deferred — separate stack candidate).
- No Slack Canvas / Slack platform development coverage (deferred — minimal current request signal).
- No Tableau / CRM Analytics deep dive (Tableau Semantics is referenced from Data 360 + Agentforce; full Tableau platform is a separate stack candidate).
- No Trailhead / certification study-guide coverage (out of scope; this pack is for production work, not exam prep).
- No Manufacturing Cloud, Public Sector Solutions, Net Zero, Education Cloud, Consumer Goods, Auto, Comms, Media specifics (Industries clouds beyond Health + FSC). Patterns transfer from Health/FSC overlays; deep coverage if demand justifies.
- No Slack / MuleSoft as separate packs (currently treated as integration surfaces within this pack).

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation.
