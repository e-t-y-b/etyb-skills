---
title: Application Insights
description: APM, distributed tracing, exception capture, profiler. Classic SDK in maintenance — migrate to Azure Monitor OpenTelemetry Distro.
product:
  name: Application Insights
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, backend-architect, devops-engineer]
  authoritative_url: https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview
  notes: "Classic SDK is in maintenance mode — migrate to Azure Monitor OpenTelemetry Distro for new builds."
---

## What it is

Application Insights is Azure's APM — distributed traces, request telemetry, dependency tracking, exception capture, Profiler, Snapshot Debugger, Live Metrics. Backed by [Log Analytics](/stacks/azure/log-analytics/) workspace; queried with KQL. Canonical reference: [App Insights docs](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview).

## When to use

Always — every production application should send telemetry to App Insights. Use the **Azure Monitor OpenTelemetry Distro** for collection, not the classic SDK.

## 2025-2026 currency anchors

- **Classic Application Insights SDK is in maintenance** — Microsoft has stated no new features, only critical bug fixes.
- **Azure Monitor OpenTelemetry Distro** is the modern collection path:
  - .NET: `Azure.Monitor.OpenTelemetry.AspNetCore`
  - Node: `@azure/monitor-opentelemetry`
  - Python: `azure-monitor-opentelemetry`
  - Java: `applicationinsights-java` 3.x (now OTel-based)
- **Workspace-based App Insights** is the modern resource model — backed by Log Analytics.
- **Live Metrics** — real-time low-cardinality view; doesn't hit KQL budget.
- **Profiler** — on-demand CPU profile in production (.NET, Java).
- **Snapshot Debugger** — process state snapshot on exception (.NET).

## Patterns + anti-patterns

### Pattern: One-line OTel wiring

```csharp
// Program.cs
builder.Services.AddOpenTelemetry().UseAzureMonitor();
```

```python
# main.py
from azure.monitor.opentelemetry import configure_azure_monitor
configure_azure_monitor()
```

Picks up `APPLICATIONINSIGHTS_CONNECTION_STRING` env var. Traces + logs + metrics + exception capture flow.

### Pattern: Application Map for service topology

App Insights Application Map shows service dependencies + latency + error rate per edge. Click a slow edge → see the actual query / HTTP call.

### Pattern: End-to-end Transaction Details

For a failed request, App Insights stitches the trace across services. Click into operation → see Service Bus span, DB span, downstream HTTP span.

### Pattern: Adaptive sampling

Default in App Insights — keeps the signal, reduces volume. Tune per app if budget pressure.

### Anti-pattern: Classic SDK on new builds

Microsoft has stopped feature work. Migrate to OTel Distro.

### Anti-pattern: Logging full request bodies

Inflates ingestion cost; may capture PII / secrets. Log structured properties (request ID, user ID, route, status, duration) — not body.

### Anti-pattern: Debug-level logging in production

Cost. Use Info / Warn / Error.

## Gotchas

- **Workspace-based vs classic App Insights** — workspace-based is the new norm; classic is being retired.
- **Adaptive sampling** affects what's queryable. If you need 100% sampling for forensic reasons, disable sampling for that operation.
- **App Insights instance per service** vs **shared App Insights with role.name dimension** — both work; shared is cheaper but cross-team mixing.
- **Snapshot Debugger** has memory overhead — enable selectively.
- **Custom dimensions** — useful for filtering but explode cardinality if you put high-cardinality fields (e.g., user ID) in them.

## Cross-references

- [Azure Monitor](/stacks/azure/azure-monitor/) — umbrella platform
- [Log Analytics](/stacks/azure/log-analytics/) — backing workspace
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/) — SLO design + distributed tracing
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — OTel wiring
- [App Insights overview](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure Monitor OpenTelemetry Distro](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-overview)
