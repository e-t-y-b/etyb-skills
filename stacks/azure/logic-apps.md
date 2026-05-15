---
title: Logic Apps
description: Workflow orchestration with 400+ SaaS connectors. Standard tier preferred over Consumption for new builds (VNet, stateful, local dev).
product:
  name: Azure Logic Apps
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, backend-architect, devops-engineer]
  authoritative_url: https://learn.microsoft.com/azure/logic-apps/
  notes: "Standard tier on Functions runtime is the modern default; Consumption is legacy for new builds."
---

## What it is

Azure Logic Apps is workflow orchestration with 400+ pre-built SaaS connectors (Salesforce, SAP, Office 365, ServiceNow, Slack, etc.) and Azure-native triggers/actions. Standard tier runs on the Azure Functions runtime — stateful, VNet-integrated, local-debuggable. Canonical reference: [Logic Apps docs](https://learn.microsoft.com/azure/logic-apps/).

## When to use

Pick Logic Apps when:

- You need a **SaaS connector** Microsoft maintains (Salesforce → Cosmos sync, SharePoint → Service Bus, etc.).
- You're building a **business workflow** (approval flows, document routing, alert escalation) where low-code DAG composition is faster than writing code.
- You need **stateful long-running workflows** with built-in retry, dead-lettering, durable state.

Don't pick Logic Apps for:

- **Code-first workflow orchestration** — use Durable Functions or [Container Apps Jobs](/stacks/azure/container-apps/).
- **High-throughput event processing** — use [Functions](/stacks/azure/functions/) or [Event Hubs](/stacks/azure/event-hubs/) with a worker.

## 2025-2026 currency anchors

- **Standard tier** is the recommended default. Runs on Functions runtime — VNet integration, stateful workflows, local dev with VS Code.
- **Consumption tier** is legacy for new builds — multi-tenant, per-action billing, no VNet integration. Migrate when complexity grows.
- **400+ connectors** maintained by Microsoft; community + custom connectors via Power Platform.
- **B2B integration** — AS2, EDI, X12, EDIFACT trading partner messaging available in Integration Account.

## Patterns + anti-patterns

### Pattern: Standard tier for production

VNet integration + stateful workflows + local debugging with VS Code Logic Apps extension. Predictable pricing (App Service Plan model).

### Pattern: SaaS connector as the integration boundary

When Microsoft maintains the connector, use it. Salesforce, Dynamics, SAP, Workday — these connectors handle auth refresh, schema evolution, retry, and pagination so you don't have to.

### Pattern: Logic Apps + Service Bus for orchestration with reliable retry

Logic Apps triggers on Service Bus message; orchestrates downstream calls; dead-letters via Service Bus DLQ on permanent failure.

### Anti-pattern: Consumption tier for production at scale

Multi-tenant; no VNet integration; per-action billing can balloon. Standard tier is the modern default.

### Anti-pattern: Code-first developers reaching for Logic Apps

If your team is code-first, Durable Functions or a custom worker on Container Apps is more maintainable than a 50-step Logic App.

### Anti-pattern: Logic Apps for high-throughput streaming

Use Event Hubs + a Functions consumer or Stream Analytics for throughput-dominant workloads.

## Gotchas

- **Connectors have rate limits** — Microsoft-managed quotas vary per connector. Plan around them.
- **State storage** for Standard tier requires a storage account; pick the right SKU + region for latency.
- **Designer vs Code view** — designer JSON is structured; editing in code view is precise but error-prone.

## Cross-references

- [Service Bus](/stacks/azure/service-bus/) — common trigger source
- [Event Grid](/stacks/azure/event-grid/) — alternative event source
- [Functions](/stacks/azure/functions/) — code-first alternative for orchestration
- [Logic Apps Standard overview](https://learn.microsoft.com/azure/logic-apps/single-tenant-overview-compare)
