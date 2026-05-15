---
title: Salesforce-Hosted MCP
description: First-party MCP server surface on Salesforce. GA April 2026 with 60+ tools — external agent clients drive the org without custom integration.
product:
  name: Salesforce-Hosted MCP
  stack: salesforce
  drift_risk: high
  last_verified_on: "2026-05-12"
  applies_to_roles: [system-architect, backend-architect, ai-ml-engineer]
  authoritative_url: https://developer.salesforce.com/docs/einstein/genai/overview
  notes: "GA April 2026; tool surface still expanding rapidly; Headless 360 architecture is genuinely new."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against TDX 2026 (April), Salesforce Spring '26.</div>

## What it is

**Salesforce-Hosted MCP Servers** are first-party MCP (Model Context Protocol) servers that expose Salesforce capabilities — CRM data, Flow execution, Data 360 queries, Slack canvas operations — as MCP tools. External agent clients (Claude Code, Cursor, Codex, Windsurf) can drive Salesforce end-to-end via the protocol without custom integration code.

This is the foundation of **Headless 360** (TDX 2026) — the pattern where every layer of Salesforce (data, workflow, business logic, governance) is exposed as APIs, MCP tools, or CLI commands. Agent clients drive the org; the Salesforce UI never has to appear.

Canonical reference: [Agentforce Developer Docs](https://developer.salesforce.com/docs/einstein/genai/overview).

## When to use it

**Use Salesforce-Hosted MCP when:**

- The user-facing surface is a chat / agent client, not Salesforce LEX
- Salesforce becomes the system of record + action plane, not the UI
- You want third-party agent clients (Claude Code, Cursor, Codex) driving the org
- You need to expose custom Apex as MCP tools for external consumption

**Don't use it for:**

- Chatbot-style help inside Salesforce LEX — that's the regular [Agentforce](/stacks/salesforce/agentforce/) agent shape
- Internal agent → external service consumption — that's the agent *consuming* MCP, not exposing it

## 2025-2026 currency anchors

- **GA April 2026** (Enterprise+). 60+ MCP tools shipped at TDX 2026.
- **Headless 360 architecture** (TDX 2026) — the foundational pattern.
- **Custom Apex auto-exposed as MCP tools** via annotation → OpenAPI spec → tool registration.
- **Agentforce Experience Layer** — outputs render natively as cards/UI in Slack, Mobile, ChatGPT, Claude, Gemini, Teams.
- **Agentforce Vibes 2.0** (TDX 2026) — Salesforce's in-IDE agent can drive the org via MCP (not just generate code).

## Patterns

### Headless 360 — the agent-client architecture

When the user-facing surface is an external agent client:

- Salesforce becomes the **system of record + action plane**, not the UI
- Salesforce-Hosted MCP exposes 60+ tools — every Enterprise+ org has them out of the box
- Custom Apex auto-exposed as MCP tools via annotation
- Outputs render natively as cards/UI in Slack, Mobile, ChatGPT, Claude, Gemini, Teams via the Agentforce Experience Layer

Right pattern when: the org wants to embed Salesforce *into* an existing AI client experience rather than ask users to switch to Salesforce.

Anti-pattern when: the user just wants chatbot-style help inside Salesforce LEX — that's regular [Agentforce](/stacks/salesforce/agentforce/).

### Custom Apex as MCP tool

```apex
public class CaseHelper {
    @InvocableMethod(
        label='Get Case Details'
        description='Returns case summary including priority, account, and recent activity'
        category='Customer Service'
    )
    public static List<Output> getCaseDetails(List<Input> inputs) {
        // bulk-safe implementation honoring WITH USER_MODE
    }
    public class Input { @InvocableVariable(required=true) public Id caseId; }
    public class Output { @InvocableVariable public String summary; @InvocableVariable public String priority; }
}
```

The Salesforce-Hosted MCP Server picks up annotated Apex with no further work — the OpenAPI spec is auto-generated from the `@InvocableMethod` metadata. For custom MCP servers you host, use `@AuraEnabled` or `@RestResource` and register via the OpenAPI spec.

### MCP consumption patterns (Salesforce *consuming* external MCP)

Agentforce agents can be Actions that call external MCP servers. Don't write custom OpenAPI integrations when an MCP server exists for the target service. **The OpenAPI route was the right answer in 2025; MCP is the right answer in 2026.**

## Anti-patterns

- **Writing custom OpenAPI integrations** for services that already have an MCP server. Wasted effort.
- **Exposing Apex actions that bypass `WITH USER_MODE`.** Every MCP call runs as a user; if the action queries in SYSTEM_MODE, you've leaked records.
- **Returning unbounded result sets** from MCP tools. Cap. The agent's context window is finite.
- **No PII masking on outputs going to external models.** Same [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/) discipline applies — the agent on the other end may not have the Trust Layer.
- **Treating MCP exposure as "just an API."** It is — but the prompt-readable `description=` is what the agent uses to pick the tool. Write descriptions like API doc strings.

## Gotchas

- **Tool surface is changing weekly.** Verify against current release notes before assuming a specific tool exists.
- **Enterprise+ only.** Salesforce-Hosted MCP is not on lower editions.
- **Audit trail goes through Einstein Trust Layer** — confirm logging is on; this is your forensic record.
- **MCP tools obey user-mode permissions** — the user authenticated to the MCP server is the user running the Apex action. Test sharing/FLS at the MCP boundary.
- **Vibes vs ETYB.** An ETYB user on Claude Code working on Salesforce can drive their org via Salesforce's MCP server — you may not need Vibes if you're an ETYB user already.

## Cross-references

- Agent design that uses MCP: [Agentforce](/stacks/salesforce/agentforce/), [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/)
- Apex plumbing for MCP authoring: [Apex](/stacks/salesforce/apex/), [backend-architect on Salesforce](/stacks/salesforce/backend-architect/)
- Architecture decision (when to go Headless 360): [system-architect on Salesforce](/stacks/salesforce/system-architect/)
- Trust Layer routing: [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/)
- Authoritative: [Agentforce Developer Docs](https://developer.salesforce.com/docs/einstein/genai/overview)
