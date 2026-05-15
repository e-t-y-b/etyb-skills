---
title: Agentspace
description: Google's enterprise agent application surface — out-of-box AI assistant across Workspace/M365/Salesforce/Confluence/etc. with custom agents from Agent Builder.
product:
  name: Agentspace
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect, saas-architect]
  authoritative_url: https://cloud.google.com/agentspace/docs
  notes: "GA'd 2025; enterprise agent surface; integrations and licensing model still moving."
---

## What it is

Agentspace is Google's enterprise agent application surface (GA 2025). It's distinct from [Vertex AI Agent Builder](/stacks/gcp/agent-builder/) — Agent Builder *builds* agents; **Agentspace deploys them at the enterprise application layer**. Out-of-the-box capabilities:

- Search across enterprise data (Workspace, M365, Salesforce, Confluence, Jira, ServiceNow, GitHub, etc.)
- Agent assistant grounded on enterprise data
- Custom agents authored in Agent Builder, deployed to Agentspace
- Workspace + Chrome integration

Authoritative reference: [cloud.google.com/agentspace/docs](https://cloud.google.com/agentspace/docs).

## When to use

Pick Agentspace when:
- Enterprise-wide AI assistant is the requirement
- Customer wants connectors out of the box (vs building each integration)
- Identity model maps to enterprise SSO (Workspace, Entra ID, Okta)

Don't reach for Agentspace when:
- Single-product use case — build with [Agent Builder](/stacks/gcp/agent-builder/) instead
- Tight control over UX — build custom
- Org has invested heavily in another agent platform (Microsoft Copilot, Glean, etc.)

## 2025-2026 currency anchors

- **GA'd 2025**; enterprise agent application surface.
- **Distinct from Agent Builder** — Agent Builder builds; Agentspace deploys at the enterprise layer.
- **Connectors evolving** — Workspace, M365, Salesforce, Confluence, Jira, ServiceNow, GitHub, more.
- **Licensing model still moving** as of 2026-05; verify with sales for current SKUs.

## Patterns

### Decision: Agentspace vs Agent Builder vs Custom

- **Agentspace** — buy, configure, deploy
- **Agent Builder** — build product-specific agents
- **Custom orchestration** on Cloud Run + Gemini — only when neither fits

### Connectors

Out-of-the-box: Workspace, M365, Salesforce, Confluence, Jira, ServiceNow, GitHub, more. Configure once; agents grounded across all connected sources.

## Anti-patterns

- **Building an enterprise-wide assistant from scratch** when Agentspace fits the use case.
- **Confusing Agentspace with Agent Builder** — they're complementary, not competitive.

## Gotchas

- **Licensing** — per-user pricing; verify with sales.
- **Identity integration** — maps to enterprise SSO; needs admin setup.
- **Data residency** — verify per-region; Workspace data residency considerations apply.

## Cross-references

- Related: [Vertex AI Agent Builder](/stacks/gcp/agent-builder/), [Vertex AI](/stacks/gcp/vertex-ai/), [Gemini](/stacks/gcp/gemini/)
- Roles: [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/), [saas-architect on GCP](/stacks/gcp/saas-architect/)
- Authoritative: [cloud.google.com/agentspace/docs](https://cloud.google.com/agentspace/docs)
