---
title: Einstein Trust Layer
description: The only sanctioned path for AI on Salesforce customer data. Masking, zero retention, dynamic grounding, audit trail.
product:
  name: Einstein Trust Layer
  stack: salesforce
  drift_risk: medium
  last_verified_on: "2026-05-12"
  applies_to_roles: [security-engineer, ai-ml-engineer, healthcare-architect, fintech-architect]
  authoritative_url: https://developer.salesforce.com/docs/einstein/genai/overview
  notes: "Architecture stable; masking config and provider list expand per Agentforce model gateway updates; PII type customization expanded Spring '26."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26, Dreamforce '25.</div>

## What it is

The **Einstein Trust Layer** sits between the [Atlas Reasoning Engine](/stacks/salesforce/agentforce/) and the Einstein Model Gateway. It is the *only* sanctioned path for AI on Salesforce customer data. The architectural choice is binary: route through the Trust Layer, or you have left compliance behind.

Canonical reference: [Agentforce / Trust Layer documentation](https://developer.salesforce.com/docs/einstein/genai/overview).

## When this matters

For any AI/LLM call where customer data is the input. That includes:

- All [Agentforce](/stacks/salesforce/agentforce/) agent prompts (every channel: Slack, Web, Voice, MCP)
- Prompt Builder template invocations from Flow / Apex / record actions
- BYOM models routed via Einstein Studio model registry
- Models API direct calls (still routes through the gateway)

**What it does NOT cover** (and where you've left compliance behind):

- Direct Apex `HttpRequest` to `api.openai.com` / `api.anthropic.com` / vendor REST endpoints. **Compliance hole.** No masking, no zero-retention contract, no audit trail.
- Heroku apps making outbound LLM calls. Not Salesforce-resident.
- MuleSoft flows calling LLM APIs without routing back through Einstein Model Gateway. Mule can call any HTTP endpoint; nothing forces it through Trust Layer.

**Rule:** If customer data is the input to an LLM call, the call must originate from Agentforce / Prompt Builder / Models API. Anything else routes around the controls and the auditor will say so.

## Architecture

| Component | What it does | Failure mode if absent |
|-----------|--------------|------------------------|
| **Secure Data Retrieval** | Runs all grounding queries in `USER_MODE`, honoring FLS / CRUD / sharing on the running user | Agent surfaces records the user can't legitimately see — sharing violation, GDPR Article 32 exposure |
| **Dynamic Grounding** | Injects records / Data 360 context via structured merge fields, never free-form string concat | Prompt injection via untrusted user input |
| **Data Masking** | PII/PHI detection + token substitution before egress (e.g., SSN → `[SSN_TOKEN_1]`) | Raw PII transmitted to model — HIPAA / GDPR violation |
| **Toxicity Detection** | Inbound and outbound content moderation | Brand-damaging or unsafe output |
| **Zero Retention** | Contractual with OpenAI (Azure), Anthropic (Bedrock), Google (Vertex). Prompts not stored, not used for training | Customer data into third-party training corpus |
| **Audit Trail** | Full prompt + masked input + raw model output + final rendered response, keyed to user + Topic + Action + timestamp | No forensic record |

## 2025-2026 currency anchors

- **Trust Layer evolution** — Dynamic Grounding hardening, expanded toxicity model, **custom PII type support** (Dreamforce '25 → Spring '26).
- **Provider list expands** per Agentforce model gateway updates — OpenAI (Azure), Anthropic (Bedrock — Sonnet 4.5 is Vibes default), Google Gemini (added Dreamforce '25), BYOM via Einstein Studio.
- **PHI types** (MRN, ICD, NPI) are a separate toggle from default PII.

## Patterns

### Masking configuration

- **Masking rules are configured per prompt template** in Prompt Builder. Default PII covers SSN, credit-card-like numbers, phone, email, address, names (toggleable), DOB, IP.
- **Health-context PHI** (MRN, ICD, NPI) is a separate toggle.
- **Custom PII types** can be added (customer-specific account number patterns, internal employee IDs).
- **Runtime view** in Prompt Builder lets you debug a prompt without ever seeing the underlying PII. You see "the SSN was `[SSN_TOKEN_1]`" — the token-substituted view is the only debug surface.
- **Re-audit after template changes.** Adding a new merge field can route unmasked PII through if you forget to enable the relevant rule. There is no global "mask everything" switch.

### Verification cadence

- Run sample conversations through the audit log **weekly for the first month** after any agent / connected-app launch.
- Confirm masking, citations, FLS are working as designed.
- Most issues surface in production traffic patterns, not staging.

## Anti-patterns

- **Direct Apex `HttpRequest` to `api.openai.com` for customer data.** Compliance hole. Use Models API through the gateway, or BYOM via Einstein Studio.
- **Free-form merge of long unfiltered text into a prompt.** Classic prompt injection vector. Use structured merge fields, not concatenation.
- **Skipping Trust Layer audit review before agent launch.** Issues surface in production traffic patterns, not staging.
- **Templates without grounding.** A prompt that's "just text + user question" gets generic LLM output and breaches the citation requirement.
- **Custom audit pipelines that ignore the Trust Layer audit trail.** The Trust Layer's audit log is part of your HIPAA / SOX / GDPR forensic story — pair with [Field Audit Trail](/stacks/salesforce/security-engineer/) and Event Monitoring, but don't try to replace it.
- **Letting an Apex action call OpenAI/Anthropic directly "for speed."** Always Models API or Agentforce.
- **No PII masking on outputs going to non-Salesforce models** via BYOM. BYOM models still route through the Trust Layer for masking/audit — verify the routing is in place.

## Gotchas

- **Masking is per-template.** No global switch. After every prompt template change, re-verify masking against the changed merge fields.
- **Zero retention is contractual with provider** (OpenAI Azure, Anthropic Bedrock, Google Vertex) — confirm provider before quoting "zero retention" to a customer.
- **BYOM goes through Trust Layer** — the platform proxies the call. Don't bypass.
- **Voice channel masking** — voice transcription happens before masking applies; verify the audit trail captures pre-mask transcript handling.
- **Trust Layer audit alone is not full HIPAA evidence** — pair with Field Audit Trail + Event Monitoring for the complete forensic story.

## Cross-references

- Agent design that uses Trust Layer: [Agentforce](/stacks/salesforce/agentforce/), [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/)
- Security depth (Trust Layer + ECA + MFA + Shield): [security-engineer on Salesforce](/stacks/salesforce/security-engineer/)
- Healthcare PHI specifics: [healthcare-architect on Salesforce](/stacks/salesforce/healthcare-architect/), [Health Cloud](/stacks/salesforce/health-cloud/)
- Financial PII specifics: [fintech-architect on Salesforce](/stacks/salesforce/fintech-architect/), [Financial Services Cloud](/stacks/salesforce/financial-services-cloud/)
- Apex callout discipline: [Apex](/stacks/salesforce/apex/)
- Authoritative: [Agentforce / Trust Layer Documentation](https://developer.salesforce.com/docs/einstein/genai/overview)
