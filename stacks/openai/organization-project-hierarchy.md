---
title: Organization + Project hierarchy
description: "Org → Project → API keys with per-project RBAC, rate limits, model allowlists. Project-scoped keys (`sk-proj-…`) are the production pattern."
product:
  name: Organization + Project hierarchy
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, security-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/production-best-practices
  notes: "Hierarchical structure stable; tier auto-promotion + model gating + project-scoped keys are the current production-grade discipline."
---

## What it is

OpenAI's structural hierarchy:

```
Organization (org_…)
  └── Project (proj_…)
        ├── API keys (sk-proj-…)
        ├── Model allowlist
        ├── Rate limits
        ├── Members (RBAC roles)
        └── Usage / billing
```

Every account has at least one **Organization**. Inside an org, you create **Projects** — each project carries its own API keys, RBAC roles, rate limits, and model allowlists. The **usage tier** (Tier 1 → Tier 5) lives at the org level and gates which models a project can call.

This is the production-grade discipline that replaced the legacy user-keys model.

## When to use

You use this all the time. The question is **how to map it to your topology**.

| Topology | Org / Project pattern |
|---|---|
| Single product, single team | One org, one project per environment (dev / staging / prod). |
| Multi-product platform | One org per product line, OR one org + one project per product. |
| Multi-tenant SaaS | One org, projects shared across tenants; cost attribution at app layer. Or one project per large tenant for hard cost isolation. |
| Internal tools + customer-facing app | Separate orgs (or projects) — different threat models. |

**Minimum production discipline:** one project per environment, with prod having stricter rate limits + tighter member access + tighter model allowlist + ZDR enabled.

## 2025-2026 currency anchors

- **Project-scoped keys (`sk-proj-…`)** are the production default. User-scoped keys (`sk-…` legacy) tie to a human and are an audit / rotation risk.
- **Usage tiers ladder from Tier 1 → Tier 5.** Auto-promotion on cumulative spend + age.
- **Tier-gating** — Tier 1 cannot access GPT-5 / o-series / Realtime / Computer Use even with a valid key. Confirm tier before promising features.
- **Service accounts** — non-human project-scoped identities. Use for production keys; decoupled from any individual.
- **Per-project model allowlist** — restrict prod to models in use. Drift-protects against accidental migration.
- **Per-project rate limits** — set lower than tier ceiling for dev/staging. Defends against runaway features eating prod headroom.

## Patterns

### Pattern: per-environment projects

- `prod-customer-api` project — tight model allowlist + tight rate limit + ZDR + service-account key.
- `staging-customer-api` project — same model allowlist, lower rate limit.
- `dev-customer-api` project — wider model allowlist, lowest rate limit.

Per-environment project keys are deployed independently; rotating one doesn't touch the others.

### Pattern: per-service projects

For multi-service architectures: each service gets its own project + its own service account + its own key. Cross-service access requires explicit grants. Rotation per-service.

### Pattern: tenant isolation (enterprise SaaS)

For enterprise SaaS with hard isolation contractual requirements:
- One project per enterprise tenant.
- Per-tenant API key.
- Per-tenant rate limits + model allowlist + audit log.
- Per-tenant Vector Stores.

Operational overhead is real (many projects); justified for enterprise tenants paying for isolation.

### Pattern: Computer Use isolation

[Computer Use](/stacks/openai/computer-use/) is dangerous enough that a separate project with explicit gating is the right architecture. Main app project does not have `computer_use_preview` allowlisted; a dedicated Computer-Use project does, with stricter access controls.

### Pattern: tier capacity planning

- Estimate average prompt + completion size.
- Multiply by traffic.
- Check against your tier's TPM (tokens per minute).
- If you'll hit 80% of TPM at peak, request tier promotion via support, or split traffic across projects.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Single key shared across dev + staging + prod | One project per environment; one key per service. |
| User-scoped key (`sk-…`) in production | Project-scoped + service account (`sk-proj-…`). |
| All engineers with Project Owner on prod | Least privilege. Prod owners are few; production keys are rotated by automation. |
| No per-project rate limits | Set them; defense-in-depth against runaway features. |
| No per-project model allowlist | Set it; drift-protects against accidental model migration. |
| Promising GPT-5 / Computer Use without checking tier | Confirm tier first. Tier 1 can't access. |
| Sharing keys across services | One key per service. Easier to rotate; smaller blast radius if leaked. |
| Computer Use in the main app project | Dedicated Computer-Use project with explicit gating. |

## Gotchas

- **Tier-gating** is the most common deploy-time surprise. New project starts at Tier 1.
- **Tier auto-promotion** needs cumulative spend + age. You can't fast-track via console.
- **Rate-limit headers** (`x-ratelimit-*`) tell you which limit (RPM or TPM) is binding.
- **Org-wide settings** (audit log, some ZDR toggles) — confirm scope when changing.
- **Project deletion** — can be hard-disabled with significant guardrails; verify before relying on quick teardown.
- **Per-project audit logs** — surface in console + via Audit Logs API. See [Audit Logs](/stacks/openai/audit-logs/).
- **Billing** is org-level by default; project-level cost attribution requires per-project key usage.

## Cross-references

### Related products in this Stack

- [OpenAI Platform Console](/stacks/openai/openai-platform-console/) — the operations surface for managing this hierarchy.
- [Audit Logs](/stacks/openai/audit-logs/) — org-level audit trail.
- [Computer Use](/stacks/openai/computer-use/) — typically isolated to its own project.

### Role overlays

- [system-architect](/stacks/openai/system-architect/) — topology mapping.
- [security-engineer](/stacks/openai/security-engineer/) — keys, RBAC, least privilege enforcement.
- [backend-architect](/stacks/openai/backend-architect/) — SDK setup using project keys.

### Authoritative sources

- [Production best practices](https://platform.openai.com/docs/guides/production-best-practices)
- [OpenAI Platform Console](https://platform.openai.com)
