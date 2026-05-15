---
title: Agentforce
description: Salesforce's agent platform — Atlas Reasoning Engine, Topics/Actions/Guardrails, Trust Layer, Prompt Builder. Renamed from Einstein Copilot Jan 2025.
product:
  name: Agentforce
  stack: salesforce
  drift_risk: high
  last_verified_on: "2026-05-12"
  applies_to_roles: [system-architect, backend-architect, ai-ml-engineer, security-engineer, healthcare-architect, fintech-architect]
  authoritative_url: https://developer.salesforce.com/docs/einstein/genai/overview
  notes: "Renamed Jan 2025; pricing model shifted twice in 2025-2026; agent surface still evolving."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26, Dreamforce '25, TDX 2026.</div>

## What it is

Agentforce is Salesforce's AI-agent platform. It was named **Einstein Copilot** until January 2025; pre-2025 references and training data will use the old name. The platform comprises:

- **Atlas Reasoning Engine** — Salesforce's proprietary System-2 deliberative inference layer
- **Topics / Actions / Guardrails** — the agent decomposition model
- **Prompt Builder** — declarative prompt template authoring
- **Agent Script** — deterministic agent control flow (added Dreamforce '25)
- **Einstein Model Gateway** — model-agnostic routing (OpenAI, Anthropic, Google, BYOM)
- **Einstein Trust Layer** — the only sanctioned path for AI on customer data (see [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/))

Canonical reference: [Agentforce Developer Docs](https://developer.salesforce.com/docs/einstein/genai/overview).

## When to use it (and when not to)

**Use Agentforce when:**

- The interaction is conversational or naturally branching — a screen flow would force a rigid path
- The task requires reasoning over heterogeneous data (records + knowledge + Data 360 unstructured + external systems)
- The user wants the work delegated, not stepped through — "handle this ticket" vs "show me the ticket form"
- You can constrain blast radius via Actions (deterministic Apex/Flow/API/MCP) — Atlas chooses *which* Action; the Action itself is deterministic
- You have Data 360 or knowledge sources worth grounding on

**Do NOT use Agentforce when:**

- The flow is linear with clear steps → use a [Reactive Screen Flow](/stacks/salesforce/flow/)
- The logic is deterministic and stateless → use [Apex](/stacks/salesforce/apex/) or Flow
- Throughput is high and predictable — agent invocations add latency and credit cost
- You need exact, repeatable behavior (billing, compliance-critical) → use **Agent Script** when you want agent framing with deterministic step control
- You can't list 3-7 tightly scoped Topics up front — Atlas accuracy degrades with overlapping Topics

## 2025-2026 currency anchors

- **Einstein Copilot → Agentforce** (Jan 2025). Same product. Old name is wrong on every reference.
- **Atlas Reasoning Engine** — the deliberative loop (Intent → Plan → Retrieve → Execute → Verify → Respond). **Hybrid reasoning** (Dreamforce '25) mixes LLM-driven planning with deterministic dispatch.
- **Topics + Actions + Guardrails + Channels** is the model. Each decomposes further into Role/Persona, Data Sources, Topics, Actions, Guardrails, Channels.
- **Agent Script** (Dreamforce '25) — deterministic control flow for steps where LLM judgment is unacceptable.
- **Agentforce Voice** (GA Dreamforce '25) — speech-to-speech agents integrated with Service Cloud Voice.
- **Agentforce Builder** (Dreamforce '25) — the authoring surface; ships with shipped templates for service, sales, marketing, FSC, Health.
- **Agentforce Vibes / Vibes IDE 2.0** (TDX 2026) — Salesforce's in-IDE coding agent. Default model: Claude Sonnet 4.5. Reads org metadata before generating.
- **Pricing model coexists in three shapes in 2026** — see Pricing below. **Flex Credits and Conversations cannot coexist in the same org.** Pick before launch.
- **AgentExchange** (Dreamforce '25) — ISV marketplace for distributing Topics, Actions, agent templates (separate Security Review track from AppExchange).
- **Model gateway expanded** — OpenAI (Azure), Anthropic Claude (Bedrock — Sonnet 4.5 is the Vibes default), Google Gemini (Dreamforce '25), customer BYOM via Einstein Studio.

## Patterns

### The Role → Topics → Actions → Guardrails decomposition

Every Agentforce agent has:

- **Role / Persona** — single-sentence purpose + tone + scope boundaries
- **Data sources / Libraries** — knowledge articles, [Data 360](/stacks/salesforce/data-360/) objects, file libraries, external sources via MCP, retrieval indexes
- **Topics** — functional domains (e.g., "Order Returns," "Account Updates," "Knowledge Lookup"). 3-7 tightly scoped Topics per agent.
- **Actions** — deterministic capabilities (Apex methods, Flow invocations, prompt templates, API calls, MCP tools). 3-10 Actions per Topic with clear non-overlapping purpose.
- **Guardrails** — instructions, constraints, escalation rules, tone, output formats
- **Channels** — Slack, Web (Service Cloud Voice / chat), Mobile, embedded clients, agent clients via MCP, ChatGPT/Claude/Gemini via Experience Layer

### Prompt template patterns (Prompt Builder)

Templates are first-class metadata — versioned, deployable, testable. Binds:

- **Record merge fields** — `{!$Input:Account.Name}` — typed, FLS-honored
- **Data 360 fields** — calculated insights, segments, related external data
- **Related list iteration** — show the last 5 cases for this account
- **Flow output** — invoke a Flow, bind its return values
- **Apex output** — call an `@InvocableMethod`, bind the result

Template types: **Sales Email**, **Field Generation**, **Record Summary**, **Flex** (general purpose). Pick the specific type when it matches.

### Agent Script — deterministic flow

Use when the branching must be exact (compliance, billing, refunds, identity verification, money movement) or when the same input must always produce the same output. See [fintech-architect](/stacks/salesforce/fintech-architect/) for the money-movement deterministic-gate pattern.

```
when topic == "Order Returns" {
  call getOrderDetails(orderId: $context.orderId) -> order
  if order.status == "Delivered" and daysSince(order.deliveredDate) < 30 {
    call createReturnRecord(orderId: order.id, reason: $userInput.reason) -> returnRecord
    respond "Return $returnRecord.number created."
  } else if order.status == "Delivered" {
    respond "Outside 30-day window."
    escalate to "human-agent"
  }
}
```

### Pricing — design for it, not just deliver against it

Three coexisting models in 2026. **Flex Credits and Conversations cannot coexist in the same org.**

| Model | Cost | Best for |
|-------|------|----------|
| **Conversations** | ~$2 per 24-hour conversation window | High volume, predictable per-interaction cost |
| **Flex Credits** (default for net-new in 2026) | $0.10 per action; $500 / 100K-credit packs | Per-action billing — pay for what you use |
| **Per-user** | ~$125/user/mo add-on, or Agentforce 1 Editions at $550+/user/mo | Internal-facing agents with bounded user count |

Implications:

- Every Action call has a cost — don't chain 12 when 3 will do
- Cache where safe — repeated reads of the same record in one conversation should hit cache
- Internal vs external agents have different math (per-user vs Flex/Conversations)
- Tell the customer about the pricing-mode lock-in before launch; switching modes later is painful

## Anti-patterns

- **Topics that overlap.** "Order Help" and "Returns" both touching `Order__c` — Atlas can't choose. Split into mutually exclusive Topics.
- **Actions returning unbounded data.** "Get all cases for account" with no limit returns 10K rows and crashes the context window. Always cap.
- **Free-form merge from user input into a prompt.** Classic prompt injection. Use structured merge fields and the platform's input handling.
- **Calling external LLMs directly from Apex for customer data.** Bypasses [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/) → compliance hole. Use Models API through the gateway or BYOM via Einstein Studio.
- **Designing for "Einstein Copilot" in 2026.** Renamed product. Get the name right.
- **Agent has every possible Action attached "just in case."** Atlas precision degrades. Trim aggressively; each Action should justify its inclusion.
- **Skipping Trust Layer audit review before launch.** Run sample conversations through the audit trail; confirm masking, citations, FLS are working as designed.
- **Templates that hard-code instructions only relevant to one model.** Templates should be model-portable. "Respond in JSON" is OK; "Use Claude's XML thinking tags" is not.
- **Templates without grounding.** A prompt that's "just text + the user's question" gets generic LLM output. Ground every prompt in Data 360, related records, or knowledge libraries.

## Gotchas

- **`description=` on `@InvocableMethod` is read by Atlas** to decide whether to call your Action. Write descriptions like API doc strings — what it does, when to use it, what comes back.
- **All Action queries must use `WITH USER_MODE`.** The agent inherits the running user's permissions; queries must enforce them. See [Apex](/stacks/salesforce/apex/).
- **No PII in agent action outputs without Trust Layer masking.** The output goes to the model. Return raw SSN/PHI/payment info and you've leaked.
- **Return deterministic, schema-stable output.** The agent's prompt template binds to your output shape. Breaking output structure breaks every prompt that uses it.
- **Voice agents have a tight latency budget.** Every Action call adds round-trip time the user hears as silence. Pre-fetch likely data when the call starts. No tables, bullet lists, or markdown — output is spoken.

## Cross-references

- Agent design depth: [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/)
- Action plumbing: [Apex](/stacks/salesforce/apex/), [backend-architect on Salesforce](/stacks/salesforce/backend-architect/)
- Trust Layer architecture: [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/)
- Grounding substrate: [Data 360](/stacks/salesforce/data-360/)
- MCP exposure: [Salesforce-Hosted MCP](/stacks/salesforce/salesforce-hosted-mcp/)
- Architecture decision (agent vs Flow vs Apex): [system-architect on Salesforce](/stacks/salesforce/system-architect/)
- Authoritative: [Agentforce Developer Docs](https://developer.salesforce.com/docs/einstein/genai/overview)
