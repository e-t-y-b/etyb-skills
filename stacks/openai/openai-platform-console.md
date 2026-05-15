---
title: OpenAI Platform Console
description: The primary control plane at platform.openai.com — Org / Project / API key hierarchy, usage, billing, Eval + Distillation + Agents Platform surfaces, audit logs.
product:
  name: OpenAI Platform Console
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, security-engineer, backend-architect]
  authoritative_url: https://platform.openai.com
  notes: "Primary OpenAI operations surface; UI evolves regularly with new Console products (Eval, Distillation, Agents); structural hierarchy is stable."
---

## What it is

`platform.openai.com` is OpenAI's operations console. The primary surface for:

- **Org / Project / API key management** — see [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/).
- **Usage + billing** — per-project + per-model spend.
- **Console-side products** — [Eval Platform](/stacks/openai/eval-platform/), [Distillation Platform](/stacks/openai/distillation-platform/), [Agents Platform](/stacks/openai/agents-platform/).
- **Platform Logs** — per-request inspection for debugging.
- **[Audit Logs](/stacks/openai/audit-logs/)** — org-level audit trail.
- **Model + capability allowlists** — gate which models a project can call.
- **ZDR + DPA settings** — data retention configuration.

This is the operational hub. Programmatic surfaces (API keys, project management, audit logs) also have API access — the console is the human-facing version.

## When to use

**Use the console for:**

- Org + project setup.
- API key creation + rotation.
- Per-request debugging via Platform Logs.
- Eval / Distillation / Agents Platform operations.
- Reviewing usage + cost reports.
- Managing members + RBAC roles.
- Auditing (when AUDIT LOGS API isn't your daily driver).

**Use the API for:**

- Programmatic key management at scale.
- CI / CD integration.
- Audit log export to SIEM.

## 2025-2026 currency anchors

- **Org / Project / API key hierarchy** is the stable production pattern — see [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/).
- **Project-scoped keys (`sk-proj-…`)** are the production default, replacing legacy user-scoped keys.
- **New Console products** keep landing — [Eval Platform](/stacks/openai/eval-platform/), [Distillation Platform](/stacks/openai/distillation-platform/), [Agents Platform](/stacks/openai/agents-platform/) all live here.
- **Platform Logs** — per-request inspection at the org/project level.
- **Service accounts** — non-human identities for production keys.
- **UI evolves** alongside product launches; structural hierarchy is stable.

## Patterns

### Pattern: production-grade setup

- **One org per company.**
- **One project per environment + service** — dev / staging / prod × service.
- **Per-project model allowlist** — restrict prod to the models actually used.
- **Per-project rate limits** — cap dev/staging at a fraction of prod.
- **Service-account keys** for production — decoupled from any individual.
- **Org Reader role** for security auditors — read-only.
- **Audit logs polled to SIEM** daily — see [Audit Logs](/stacks/openai/audit-logs/).

### Pattern: console for incident response

When an incident hits OpenAI:

1. Check [status.openai.com](https://status.openai.com).
2. Console Platform Logs for the failed `request_id`.
3. Console Usage view for cost / token anomalies.
4. Console Audit Logs for unexpected key creation / settings change.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Single project for all environments | Per-environment projects. |
| User-scoped keys in production | [Project-scoped keys](/stacks/openai/organization-project-hierarchy/) + service accounts. |
| Console-only access for production keys | Programmatic key management via API; console as the audit view. |
| Production project access for every engineer | Least privilege. Prod-write access is small. |
| No Org Reader role for auditors | Add it; read-only visibility is necessary. |
| Skipping per-project rate-limit + model allowlist | Set them; defense-in-depth. |
| Console Logs as long-term observability | Use Langfuse / Helicone / Braintrust for that; console for per-request debugging. |

## Gotchas

- **Console UI changes alongside product launches** — verify against current screens.
- **Org-level vs project-level settings** — some settings are org-wide (audit logs, ZDR toggles), others project-scoped (model allowlist, rate limits). Confirm before changing.
- **Console permissions** map to Org + Project RBAC roles — see [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/).
- **API access for some Console products** lags UI features — verify per-product API availability.
- **Multiple orgs** — large companies have multiple orgs (e.g., one per product line). Plan SSO + audit accordingly.

## Cross-references

### Related products in this Stack

- [Organization + Project hierarchy](/stacks/openai/organization-project-hierarchy/) — the structural model.
- [Audit Logs](/stacks/openai/audit-logs/) — surfaced in console.
- [Eval Platform](/stacks/openai/eval-platform/) / [Distillation Platform](/stacks/openai/distillation-platform/) / [Agents Platform](/stacks/openai/agents-platform/) — Console products.

### Role overlays

- [system-architect](/stacks/openai/system-architect/) — operational topology.
- [security-engineer](/stacks/openai/security-engineer/) — RBAC + audit + access posture.
- [backend-architect](/stacks/openai/backend-architect/) — programmatic API alongside console.

### Authoritative sources

- [OpenAI Platform Console](https://platform.openai.com)
- [OpenAI Status](https://status.openai.com/)
