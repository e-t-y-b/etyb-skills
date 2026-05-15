---
title: Microsoft Sentinel
description: Cloud-native SIEM + SOAR. Unified SecOps portal merges Sentinel + Defender XDR (2024-25). Auxiliary Logs + Basic Logs tiers GA 2024 for cost control.
product:
  name: Microsoft Sentinel
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, sre-engineer]
  authoritative_url: https://learn.microsoft.com/azure/sentinel/
  notes: "Unified SecOps portal merges Sentinel + Defender XDR (2024-25); SOAR + UEBA stable; Auxiliary Logs GA 2024."
---

## What it is

Microsoft Sentinel is Azure's cloud-native SIEM/SOAR — data connectors → Log Analytics workspace (Sentinel-enabled) → KQL analytics rules → incidents → Logic Apps playbooks (SOAR). Canonical reference: [Sentinel docs](https://learn.microsoft.com/azure/sentinel/).

## When to use

Pick Sentinel when:

- **Centralized SIEM** for Azure + M365 + multi-cloud + on-prem.
- **SOAR** — auto-response playbooks for known incident patterns.
- **Threat hunting** — KQL across logs at scale.
- **Compliance** evidence collection — long-term audit retention.

## 2025-2026 currency anchors

- **Unified SecOps portal** (2024-25) merges Sentinel + Defender XDR — one pane for security operations.
- **Auxiliary Logs tier (2024 GA)** — cheapest ingestion for high-volume low-query (firewall, NetFlow, proxy logs). Limited KQL (KQL Lite).
- **Basic Logs tier** — cheaper than Analytics; 8-day query window for free, archive after.
- **Analytics tier** (default) — full KQL, normal cost.
- **Archive** — compliance retention; restore-to-Analytics for query (paid).
- **Fusion ML rules** — cross-source correlation.
- **NRT (near real-time) rules** — KQL evaluated every 1 minute.
- **CAE alerts** in Sentinel — real-time identity signals.

## Patterns + anti-patterns

### Pattern: Standard data connector inventory

Common connectors:

- Azure Activity Log
- Entra ID sign-in / audit logs
- Defender XDR alerts
- Azure resource diagnostic settings
- M365 / SharePoint / Exchange
- Cloud App Security
- Third-party: Palo Alto, Cisco, Okta, AWS CloudTrail, GCP, Salesforce

### Pattern: Cost-tiered ingestion

| Data | Tier |
|------|------|
| App logs / business events | Analytics (queried frequently) |
| Audit / sign-in logs | Analytics hot (30 days), Archive (1-7 years) |
| Firewall / NetFlow / proxy | Auxiliary (high volume, rare query) |
| Compliance retention | Archive + immutability lock |

### Pattern: Alert → Playbook chain

Sentinel alert fires → playbook (Logic App) auto-responds: isolate VM, disable user, post to Teams, file ticket in ServiceNow. Tune for which alerts merit auto-response vs human triage.

### Pattern: Threat hunting queries

Custom KQL based on org-specific threat model. Run on-demand or schedule. Workbooks dashboard the results.

### Anti-pattern: Everything in Analytics tier

Cost explodes. Use Basic/Auxiliary for high-volume low-query.

### Anti-pattern: Out-of-box rules only

Tune to your environment; build org-specific hunting queries.

### Anti-pattern: Alerts without playbooks

If an alert fires and no one is paged or auto-response runs, it's not an alert — it's a log.

### Anti-pattern: One Log Analytics workspace for all environments

Dev / prod / shared in one workspace = mixed retention + RBAC. Separate workspaces; cross-workspace KQL for federated query.

## Gotchas

- **Auxiliary Logs has limited KQL** — designed for SIEM ingest, not deep analysis.
- **Sentinel cost is Log Analytics ingestion + Sentinel surcharge** — both lines matter.
- **Workbooks vs Azure Monitor Workbooks** — Sentinel-specific authoring; some templates only available in one.
- **Sentinel-enabled vs standard Log Analytics workspace** — once enabled, can't easily disable; plan workspace strategy.
- **Data Export rules** archive to Storage for cheap long-term retention.

## Cross-references

- [Defender for Cloud](/stacks/azure/defender-for-cloud/) — alert source
- [Log Analytics](/stacks/azure/log-analytics/) — backing workspace
- [Entra ID](/stacks/azure/entra-id/) — sign-in / audit log source
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — SecOps workflow
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/) — observability + security overlap
- [Sentinel docs](https://learn.microsoft.com/azure/sentinel/)
- [Auxiliary Logs](https://learn.microsoft.com/azure/azure-monitor/logs/auxiliary-logs)
