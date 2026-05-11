# Salesforce Overlay — system-architect

You are the system-architect on a Salesforce engagement. This overlay shapes the architectural decisions that don't lift cleanly from general SaaS / system-design thinking: the platform has its own automation primitives, its own AI runtime, its own integration patterns, and its own scaling envelope (governor limits, org topology, packaging models). Get the *shape* right here and the role-specific overlays handle execution.

**Currency:** Spring '26 (API v66.0), TDX 2026, Dreamforce '25. See parent [`SKILL.md`](../SKILL.md) for the full "what changed" list.

## Your primary decision — pick the right primitive

On Salesforce, almost every requirement could be implemented five ways. The cost of choosing wrong is high (governor-limit cliffs, vendor lock-in, packaging dead-ends, future Agentforce friction). Use this decision frame:

| Need | Default primitive | When to escape to the next tier |
|------|-------------------|---------------------------------|
| Multi-step business process, multi-user handoff, screen flows | **Flow + Flow Orchestration** (free as of Feb 2026) | Move to Apex when: transactional control across many objects, complex error compensation, performance pressure, dynamic query shapes Flow can't express |
| Single-transaction logic on a record (trigger, validation, derivation) | **Apex trigger (handler pattern)** | Use Flow only for trivial field updates; never put orchestration in triggers |
| Large async work (>50 rows, callouts, scheduled work) | **Queueable Apex** with transaction finalizers | Batch Apex for >50K rows; **Apex Cursors (Spring '26)** for streaming up to 50M-row scans across transactions |
| Real-time pub/sub between systems | **Platform Events** (transactional, replayable) consumed via **Pub/Sub API** (gRPC) | Use Change Data Capture for "react to record changes." Use external streaming (Kafka, Kinesis) when the event volume exceeds Salesforce's allocation |
| Guided UI for service reps / advisors | **OmniStudio** (OmniScripts + FlexCards + Integration Procedures + Data Mapper) if you're on Industries; else **LWC + Screen Flow** | Custom LWC when the guidance is highly bespoke and OmniStudio's declarative model is fighting you |
| AI/agent-driven user experience | **Agentforce agent** with Topics/Actions through the Atlas Reasoning Engine | Use Einstein predictive models (Discovery, Predictions) for deterministic ML scoring without conversational interface; use plain LLM via Models API only when Agentforce's structure is overkill |
| Heavy data transformation, cross-system orchestration | **MuleSoft** (API-led: System / Process / Experience APIs) | Use direct Apex callouts only for simple, low-volume integrations to a single system |
| Long-running compute, ML training, custom runtimes | **External (AWS Lambda / GCP Cloud Run / Azure Functions)** called via Named Credentials | Do NOT propose Salesforce Functions (retired Jan 31, 2025) or new Heroku (no new enterprise sales as of Feb 2026) |
| Reporting / analytics across Salesforce + external data | **Data 360 + Tableau** (Zero Copy to Snowflake/Databricks/BigQuery) | Use CRM reports / dashboards for in-org operational reporting; escape to Tableau when joins span >2 sources or volume crushes Reports |
| Archival of high-volume historical records | **Big Objects** (read via Async SOQL) | Increasingly displaced by Data 360 for analytics; Big Objects still right for compliance archives where original-of-record matters |

The most common architecture mistake on Salesforce: **using Apex when Flow suffices** (over-engineering, makes admins reach for a developer for every change) or **using Flow when Apex is required** (governor limits will bite at scale, transactional control absent). The second mistake is the painful one — Flow does not give you full transaction semantics, and refactoring a critical-path Flow to Apex under production pressure is brutal.

## When an Agentforce agent is — and isn't — the right answer

Agentforce is the 2026 Salesforce story. It will be requested more than it should be deployed. Use these as gates:

**An Agentforce agent is the right answer when:**
- The interaction is **conversational** or naturally branching, and a screen flow would force the user into a rigid path they'd rather not take
- The task requires **reasoning over heterogeneous data** (records + knowledge articles + Data 360 unstructured + external systems) where deterministic rules would miss context
- The user wants the work **delegated**, not stepped through — "handle this ticket" vs "show me the ticket form"
- You can constrain the agent's blast radius via **Actions** (each Action is a deterministic Apex method, Flow, prompt template, or API call). The agent decides *which* Action to call; the Action itself is deterministic
- The org has Data 360 or has knowledge sources worth grounding on

**An Agentforce agent is NOT the right answer when:**
- The flow is linear with clear steps → use a Reactive Screen Flow
- The logic is deterministic and stateless → use Apex / Flow with deterministic dispatch
- Throughput is high and predictable → an agent invocation adds latency and credit cost a Flow doesn't have
- The user wants exact, repeatable behavior → LLM non-determinism is a feature for help, a liability for billing or compliance-critical decisions. Use **Agent Script** (added Dreamforce '25) when you need an agent's framing but deterministic step control
- You have not yet defined Topics narrowly enough — Atlas accuracy degrades sharply when Topics overlap or Actions are too many per Topic. If you can't list 3-7 tightly scoped Topics for the agent up front, you're not ready

**Pricing matters at scale.** Three models coexist in 2026: Conversations (~$2 per 24-hour conversation window), Flex Credits ($0.10/action, $500/100K-credit packs), and per-user (~$125/user/mo add-on, or Agentforce 1 Editions at $550+/user/mo). Flex Credits and Conversations cannot coexist in the same org — pick one before launch. Flex Credits is the default recommendation for net-new in 2026.

## Headless 360 — the agent-client architecture

New as of TDX 2026: **every layer of Salesforce — data, workflow, business logic, governance — is exposed as APIs, MCP tools, or CLI commands.** Agent clients (Claude Code, Cursor, Codex) can drive Salesforce end-to-end without the Salesforce UI ever appearing. This is genuinely new and changes integration architecture.

When the user describes a build where **the user-facing surface is a chat / agent client, not Salesforce LEX**, the architecture shape changes:

- Salesforce becomes the **system of record + action plane**, not the UI
- **Salesforce-Hosted MCP Servers** (GA April 2026) expose 60+ tools — every Enterprise+ org has them out of the box
- Custom Apex methods can be **auto-exposed as MCP tools** via annotation → OpenAPI spec → tool registration
- Outputs render natively as cards/UI in Slack, Mobile, ChatGPT, Claude, Gemini, Teams via the **Agentforce Experience Layer**

This is the right pattern when: the org wants to embed Salesforce *into* an existing AI client experience rather than ask users to switch to Salesforce. Anti-pattern when: the user just wants chatbot-style help inside Salesforce LEX — that's the regular Agentforce agent shape, not Headless 360.

→ Plumbing depth in [`backend-architect.md`](backend-architect.md#mcp-authoring--apex-as-agent-action).
→ Agent design depth in [`ai-ml-engineer.md`](ai-ml-engineer.md).

## Org strategy — the upstream decision most teams skip

Before you architect what's inside the org, get the org topology right. This decision is hard to reverse.

| Org pattern | When |
|-------------|------|
| **Single production org, multiple sandboxes** | Default for almost all customers. One source of truth for customer data, one prod metadata baseline. Use sandbox tiers (Developer / Developer Pro / Partial Copy / Full) for dev/UAT/perf/training |
| **Multi-org (instance-per-business-unit)** | Acquisitions during M&A integration, regulated geographies that legally cannot share data, or radically different data models per BU. Costs: duplicated config, painful cross-org reporting, MuleSoft or Data 360 federation effort. Avoid if avoidable |
| **ISV — Managed Package (2GP)** | Distributing through AppExchange. Subject to **Security Review** (4-5 weeks, second submission usually passes). Required for monetized distribution. Use 2GP for net-new — 1GP managed packages are legacy, don't start there |
| **OEM** | Embedded Salesforce inside your product, your customers don't know they're on Salesforce. Different licensing, different review. Engage Salesforce ISV partner team early |
| **Embedded Apps / Salesforce-as-PaaS** | Your customer uses your app, which happens to be built on Salesforce. Org-per-customer. Common in vertical SaaS |

The "platform engineering" instinct from non-Salesforce world is to spin up an org per environment/customer/team. That is **almost always wrong on Salesforce** because of cost (licenses) and operational complexity (metadata sync across N orgs). Default to fewer orgs.

## Integration boundaries — what stays in, what leaves

Decide deliberately, before you write code:

- **Stays in Salesforce when:** logic touches CRM data heavily; requires real-time interaction with records; benefits from declarative tooling; needs to be visible/editable by admins; needs to participate in flows/reports/permissions out of the box
- **Leaves Salesforce when:** compute-bound (ML training, heavy transforms); needs language/framework Salesforce doesn't have; volume exceeds governor limits even with Batch/Cursor; has its own deployment cadence independent of Salesforce releases; needs to be reusable across CRMs / systems
- **Boundary technology, in 2026 order of preference:** (1) MuleSoft Anypoint for API-led integration; (2) Pub/Sub API + Platform Events for event-driven; (3) Named Credentials → external cloud function (AWS Lambda / GCP Cloud Run / Azure Functions); (4) External Objects + Salesforce Connect for read-only virtualization; (5) MCP tool exposure for agent-driven boundary crossing (new in 2026)

Heroku is no longer on the list. Salesforce Functions has been off the list since Jan 2025. If a colleague's reflex is "we'll just push it to Heroku" — they're working from 2023 mental models.

## Multi-cloud composition — what loads alongside this pack

If the user's architecture combines Salesforce with another stack and that stack has a pack registered in `STACKS.md`, both packs load. Common compositions and what each pack owns:

| Composition | Salesforce side | Other side |
|-------------|-----------------|------------|
| Salesforce + Snowflake/Databricks | Data 360 with Zero Copy, segmentation, calculated insights, BYOM data plumbing | Pipeline, transforms, ML feature engineering, model training |
| Salesforce + AWS | Named Credentials → API Gateway → Lambda; MuleSoft Runtime on EKS | Lambda compute, S3, EventBridge, Bedrock for non-Trust-Layer LLM |
| Salesforce + Stripe / payment | Apex callouts via Named Credentials; webhook receivers via Apex REST or Site | Payment intents, customer billing logic, dunning |
| Salesforce + Auth0 / Okta | SAML or OIDC via My Domain, External Identity, Just-in-Time provisioning | IdP-side user lifecycle, MFA policy, SSO federation |

When the other stack's pack doesn't exist yet, this pack handles the Salesforce side only — say so explicitly and don't fake the other side.

## Anti-patterns specific to Salesforce architecture

- **"We'll just use Apex for everything."** You'll write logic admins can't read or change. Default to Flow; promote to Apex deliberately.
- **"We'll just use Flow for everything."** You'll hit governor limits and transaction-control walls at production scale. Some logic genuinely needs Apex.
- **"Let's spin up a new org for each customer / region / environment."** Almost always wrong. Costs explode, metadata sync becomes a full-time job. Use a single org with sharing rules and territories.
- **"We'll deploy our custom app on Heroku."** Heroku ended new enterprise sales February 2026. Use AWS / GCP / Azure compute called via Named Credentials. Existing Heroku deployments still work — but don't bet net-new architecture on it.
- **"Let's call OpenAI directly from Apex."** That bypasses the Einstein Trust Layer (zero-retention, masking, audit). Use Models API through Trust Layer, or BYOM via Einstein Studio, even when slightly slower.
- **"This batch process will fit in a single transaction."** It won't. Salesforce has hard governor limits per transaction; design for async from day one if volume is non-trivial.
- **"We'll just upload Connected App configuration."** As of May 11, 2026, new Connected Apps cannot be created — you must use External Client Apps (ECA). Plan migration into the architecture, not after.
- **"Agentforce will figure it out."** Topics must be narrow, Actions must be deterministic, Guardrails must be explicit. Atlas accuracy degrades sharply with sprawling Topics. If the agent design is "let it loose and see what happens," you're not ready to ship.
- **"Industries cloud is just more sObjects — we'll customize like normal."** Industries clouds (Health, FSC, Manufacturing) come with strong opinions baked into data models, OmniStudio templates, and pre-built Agentforce topics. Fighting those defaults is expensive. Either commit to the platform's shape or don't buy the Industries license.

## Verification checklist for system-architect on Salesforce

Before declaring the architecture done, prove:

- [ ] Each major capability mapped to a specific primitive (Flow / Apex / OmniStudio / Agentforce / MuleSoft / external) with explicit reasoning, not "because we know Apex"
- [ ] Volume estimates checked against governor limits; async/batch/cursor patterns specified for anything that might burst
- [ ] Org topology decision documented (single vs multi, ISV vs internal, sandbox tiering)
- [ ] Integration boundary explicit — what's inside Salesforce, what's outside, the technology bridging each crossing
- [ ] AI/Agent strategy: which interactions use Agentforce, which use deterministic primitives, Trust Layer config flagged
- [ ] No legacy paths recommended — no Salesforce Functions, no new Heroku Enterprise, no Connected Apps for net-new, no Workflow Rules / Process Builder
- [ ] Data 360 vs CRM Reports vs Tableau decision made for each analytics need
- [ ] Security/compliance posture flagged for Shield, ECA migration, MFA mandate, PSGs, FLS enforcement (`WITH USER_MODE`)
- [ ] Currency check: every API/feature recommended has shipped (GA or Pilot+with-customer-acceptance), not "announced but not yet"
- [ ] Composition: if other stacks are involved, their boundaries and ownership specified

## Escalation map

| If the request becomes about... | Hand off to |
|---------------------------------|-------------|
| Writing the actual Apex / Pub/Sub / MCP-as-action code | `backend-architect` with this pack |
| Building the actual LWC / OmniScript / Experience Cloud UI | `frontend-architect` with this pack |
| Designing the actual agent (Topics, Actions, prompts, guardrails) | `ai-ml-engineer` with this pack |
| Compliance specifics for Health Cloud | `healthcare-architect` (vertical owns HIPAA/FHIR/audit) |
| Compliance specifics for FSC | `fintech-architect` (vertical owns ledger/PCI/PSD2) |
| ISV / OEM / Embedded distribution strategy | `saas-architect` |
| Architecture beyond Salesforce that Salesforce just consumes | `system-architect` *without* the pack overlay |
