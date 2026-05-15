---
title: Admin API
description: Programmatic organization, workspace, key, and spend-limit management. Wire into provisioning; don't manually click. The cap is your only line of defense between a bug and a $50K week.
product:
  name: Admin API
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, security-engineer]
  authoritative_url: https://docs.anthropic.com/en/api/admin-api
  notes: "Org/workspace/key/spend-limit management programmatically; availability depends on org tier — verify."
---

## What it is

The Admin API exposes programmatic management of:

- **Organizations** — top-level account.
- **Workspaces** — isolation boundaries (per-tenant, per-environment, per-product).
- **API Keys** — credentials scoped to a workspace; rotate, revoke programmatically.
- **Spend limits** — per-key, per-workspace, organization-wide caps.
- **Usage retrieval** — token usage by key / workspace / model.

Availability depends on org tier — verify against current [Admin API docs](https://docs.anthropic.com/en/api/admin-api).

## When to use

The Admin API is the right path for:

- **Provisioning automation** — per-tenant workspace creation as part of customer onboarding.
- **Key rotation** — scheduled 90-day rotation; immediate rotation on suspected compromise.
- **Spend cap enforcement** — programmatic configuration of per-workspace and per-key caps before production.
- **Usage retrieval for billing / cost attribution** — pull per-workspace usage into your internal cost dashboard.
- **Compliance audit trails** — programmatic record of who created what key when, with what permissions.

Use the [Workbench / Console](/stacks/anthropic-claude/workbench-console/) instead for:

- **One-off interactive ops.** A single new workspace for a personal project. A manual rotation in an emergency.
- **Human investigation** of usage anomalies.

## 2025-2026 currency anchors

- **Admin API tier-gated.** Verify availability for your organization tier against current docs.
- **Webhooks for usage anomalies** — alert on usage 3x normal, daily spend over threshold, cache hit rate drops.
- **Per-key spend cap is the granularity of last resort** — caps stop bleeding at a fixed dollar amount, not at "we noticed the bill."
- **Workspace separation patterns** — by tenant (SaaS), by environment (dev/staging/prod), by product (separate cost owners).

## Patterns + anti-patterns

### Pattern — one workspace per tenant (SaaS)

A multi-tenant SaaS creates a workspace per customer tenant programmatically at onboarding. Isolated billing, rate limits, and incident blast radius. Conflating tenants in one workspace = one bad tenant exhausts the budget for everyone.

### Pattern — programmatic key rotation

```python
# Pseudocode
def rotate_keys():
    for key in admin.list_keys(workspace=workspace_id):
        if key.age_days >= 90:
            new_key = admin.create_key(workspace=workspace_id, name=key.name)
            secrets_manager.update(key.purpose, new_key.value)
            admin.revoke_key(key.id, grace_period_days=7)
```

Schedule via cron / scheduled task. Update your secret store atomically; revoke with grace period to let in-flight requests drain.

### Pattern — spend caps configured at provisioning

When you create a workspace, set its spend cap. When you create a key, set its sub-cap. Don't ship a workspace to production without explicit caps.

```python
admin.create_workspace(name="acme-corp-prod", spend_limit_usd=5000)
admin.create_key(workspace="acme-corp-prod", spend_limit_usd=500, name="api-server")
```

### Pattern — usage-driven cost attribution

Pull per-workspace usage daily; attribute to internal cost owner; surface in your finance dashboard. Without per-tenant attribution, "we spent X on Claude" doesn't help you optimize.

### Pattern — webhook alerts on anomalies

Configure webhooks to fire on:

- **Spend cap breach** (soft and hard).
- **Daily spend > N x rolling average.**
- **Per-hour rate exceeding burst threshold.**
- **Cache hit rate dropping** (suggesting prompt structure broke).

Route to PagerDuty / Slack / your incident tooling.

### Anti-pattern — manual key provisioning via Console

Doesn't scale; doesn't audit cleanly. Every production key should be Admin-API-provisioned with a tracked owner, purpose, and rotation date.

### Anti-pattern — one master key for everything

Loss / compromise = full re-deploy + secret rotation. Per-workspace keys; per-purpose sub-keys.

### Anti-pattern — no caps

A latency bug that retries forever runs through a budget in hours. Workspace and key caps are mandatory pre-production.

### Anti-pattern — caps only at organization level

One tenant or one bug consumes the entire org budget before anyone notices. Cap at every level (org → workspace → key).

### Anti-pattern — no alerting on cap behavior

Caps stop the bleed; you still don't know about the bleed until ops checks the bill. Alert when soft caps trip, when daily spend creeps up, when cache hit rate drops.

## Gotchas

- **Admin API requires admin-tier credentials**, separate from regular API keys. Don't mix purposes.
- **Workspace deletion is destructive** — keys revoked, in-flight requests fail. Soft-deprecate before deleting.
- **Rate limits on the Admin API itself** — bulk operations need pagination + backoff.
- **Cap enforcement granularity** — verify in current docs whether caps are checked synchronously (rejected at request time) or asynchronously (allowed to overshoot then enforce). This affects your safety guarantees.

## Cross-references

- [Workbench / Console](/stacks/anthropic-claude/workbench-console/) — UI alternative
- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — the API keys here authenticate calls
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — wiring Admin API into provisioning
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — key management discipline, spend cap pattern
- [Admin API docs](https://docs.anthropic.com/en/api/admin-api)
