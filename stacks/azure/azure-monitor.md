---
title: Azure Monitor
description: Unified observability platform — Metrics + Logs (Log Analytics) + App Insights + Alerts + Action Groups. The umbrella over the Azure observability stack.
product:
  name: Azure Monitor
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer, backend-architect]
  authoritative_url: https://learn.microsoft.com/azure/azure-monitor/
  notes: "Unified platform; Metrics + Logs + App Insights + Alerts; OpenTelemetry Distro is the modern collection path."
---

## What it is

Azure Monitor is the unified observability umbrella — platform metrics, custom metrics, logs ([Log Analytics](/stacks/azure/log-analytics/)), traces ([Application Insights](/stacks/azure/application-insights/)), Prometheus metrics (Managed Prometheus), Grafana dashboards (Managed Grafana), alerts + Action Groups. Canonical reference: [Azure Monitor docs](https://learn.microsoft.com/azure/azure-monitor/).

## When to use

Always — every Azure workload emits to Azure Monitor by default (platform metrics, Activity Log). Add Log Analytics + App Insights + Managed Prometheus per the observability strategy.

## 2025-2026 currency anchors

- **Three data planes**: Logs (KQL), Metrics (PromQL or Azure Monitor query), Traces (OTel spans).
- **Azure Monitor OpenTelemetry Distro** is the modern collection path — replaces classic App Insights SDK.
- **Azure Monitor Workspace** for Prometheus metrics (separate from Log Analytics).
- **Action Groups** route alerts — email, SMS, voice, webhook, Function, Logic App, ITSM, Event Hubs.
- **Workbooks** — KQL-based dashboards with parameters.

## Patterns + anti-patterns

### Pattern: Standard observability wiring

```
App code → Azure Monitor OpenTelemetry Distro
              ↓
   ┌──────────┴──────────┐
   ↓                     ↓
Application Insights   Azure Managed Prometheus
(traces, logs, deps)   (Prometheus metrics)
   ↓                     ↓
Log Analytics Workspace  Azure Monitor Workspace
   ↓                     ↓
        Azure Managed Grafana
              ↓
   Alert Rules → Action Groups
              ↓
        PagerDuty / Slack / Teams
```

### Pattern: Three alert types

- **Metric alerts** — threshold on platform / custom metric; low latency.
- **Log alerts (scheduled query)** — KQL on schedule; flexible.
- **Activity Log alerts** — control plane events (resource deleted, service health).

### Pattern: Action Group per severity

| Severity | Sink |
|----------|------|
| Sev 0 | Page everyone + PagerDuty |
| Sev 1 | Page on-call + PagerDuty + #incident |
| Sev 2 | Ticket + Slack #ops |
| Sev 3 | Daily digest |

### Anti-pattern: Alert on infrastructure metric only

"CPU > 80%" doesn't tell you the user is affected. Alert on symptoms (latency / error rate / saturation).

### Anti-pattern: Alerts without runbooks

Every alert has a `description` field linking to the runbook.

## Gotchas

- **Action Group cost** — voice calls have per-call cost; webhooks generally free.
- **Alert evaluation frequency** — log alerts cheaper at lower frequency; metric alerts are near-real-time.
- **Diagnostic Settings vs Resource Logs** — older vs newer naming; same concept (per-resource log streaming).
- **Cross-workspace queries** — supported via `workspace("workspace-id")` in KQL; useful for federation but adds latency.

## Cross-references

- [Log Analytics](/stacks/azure/log-analytics/) — log queries
- [Application Insights](/stacks/azure/application-insights/) — APM
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/) — full observability design
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — alert routing + Action Groups
- [Azure Monitor overview](https://learn.microsoft.com/azure/azure-monitor/overview)
