---
title: Log Analytics
description: KQL-based log storage and query. Basic + Auxiliary Logs tiers GA 2024 for cost control. Archive for compliance retention. Workspace-per-environment is the pattern.
product:
  name: Log Analytics
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer, security-engineer]
  authoritative_url: https://learn.microsoft.com/azure/azure-monitor/logs/
  notes: "KQL stable; Basic + Auxiliary Logs tiers GA 2024 for cost-tiered ingestion."
---

## What it is

Log Analytics is the workspace store for structured log data — queried with KQL, retained per tier policy, source for [Application Insights](/stacks/azure/application-insights/), [Sentinel](/stacks/azure/sentinel/), Container Insights, Activity Log, resource diagnostic logs. Canonical reference: [Log Analytics docs](https://learn.microsoft.com/azure/azure-monitor/logs/).

## When to use

Always — every Azure workspace needs at least one Log Analytics workspace. Choices: how many workspaces (one per environment is typical), which tier per table (Analytics / Basic / Auxiliary / Archive), retention policy.

## 2025-2026 currency anchors

- **Analytics tier** (default) — full KQL, normal cost. Use for queried-frequently logs.
- **Basic Logs tier** — cheaper; limited KQL (subset operators, 8-day query window free). Use for low-query, longer retention.
- **Auxiliary Logs tier (2024 GA)** — cheapest; KQL Lite. Use for high-volume firewall / NetFlow / proxy.
- **Archive** — cheapest; restore-to-Analytics for query (paid restore). Use for compliance retention.
- **Commitment tiers** — discount for committed daily ingestion (100, 200, 500, 1000, 2000, 5000 GB/day).

## Patterns + anti-patterns

### Pattern: One workspace per environment, optionally per region

Separate workspaces by environment for retention + RBAC + cost attribution. Cross-workspace queries with `workspace("workspace-id")` for federated views.

### Pattern: Cost-tiered ingestion strategy

```
- App logs / business events → Analytics
- Audit / sign-in logs → Analytics (30d hot) + Archive (1-7y)
- Firewall / NetFlow / proxy → Auxiliary
- Compliance retention → Archive + immutability lock
```

### Pattern: Filtering at agent level

Diagnostic Settings + Data Collection Rules filter logs before ingestion. Reduces volume + cost.

### Pattern: Commitment tier for steady-state

Daily ingestion forecast → commit at the right tier → discount applies.

### Anti-pattern: Single workspace for all environments

Dev / prod / shared resources mixed = mixed retention, mixed RBAC, mixed cost attribution.

### Anti-pattern: Everything in Analytics

Cost explodes. Use Basic / Auxiliary for high-volume low-query.

### Anti-pattern: Only Archive

Forensic investigation requires querying — Archive restore is slow and paid.

## Gotchas

- **Per-GB ingestion cost** is the dominant Log Analytics expense. Track top-N source tables monthly.
- **Retention** per-table — set independently for hot tier vs total retention.
- **KQL parse time** — large queries can be expensive in CPU minutes; Sentinel adds another cost dimension.
- **Workbooks** vs Sentinel Workbooks — slightly different templates.

## Cross-references

- [Azure Monitor](/stacks/azure/azure-monitor/) — umbrella platform
- [Application Insights](/stacks/azure/application-insights/) — workspace-based App Insights writes here
- [Sentinel](/stacks/azure/sentinel/) — SIEM on top
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/) — cost-aware observability
- [Log Analytics docs](https://learn.microsoft.com/azure/azure-monitor/logs/data-platform-logs)
- [Auxiliary Logs](https://learn.microsoft.com/azure/azure-monitor/logs/auxiliary-logs)
