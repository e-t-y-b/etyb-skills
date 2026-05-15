---
title: Event Grid
description: Reactive event broker — Azure resource events, custom events, partner events. MQTT broker GA + Namespaces (pull delivery) reshape patterns. CloudEvents 1.0 native.
product:
  name: Azure Event Grid
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, devops-engineer]
  authoritative_url: https://learn.microsoft.com/azure/event-grid/
  notes: "MQTT broker + Namespaces (pull delivery) GA changed integration patterns; CloudEvents 1.0 native."
---

## What it is

Event Grid is Azure's reactive event broker — push-based delivery with retry, filtering at broker, many subscribers, CloudEvents 1.0 native. Use System Topics for Azure resource events (Blob uploaded, resource group changed); custom topics for your own domain events. **Namespaces** add MQTT broker + pull-style delivery. Canonical reference: [Event Grid docs](https://learn.microsoft.com/azure/event-grid/).

## When to use

Pick Event Grid when:

- You're reacting to **"things happening"** — Blob upload, resource changed, partner webhook, custom domain event.
- **Push-based delivery** to many subscribers with broker-level filtering.
- **CloudEvents 1.0** is required.
- **MQTT** broker for IoT (via Namespaces).

Pick [Service Bus](/stacks/azure/service-bus/) for: command/queue, transactions, ordered sessions, pull-based consumer. Pick [Event Hubs](/stacks/azure/event-hubs/) for: high-throughput streaming, replay history.

## 2025-2026 currency anchors

- **Namespaces** (GA) — namespace-scoped resources with MQTT broker support and pull-style delivery (not just push).
- **MQTT broker** support for IoT scenarios — devices publish via MQTT 3.1.1 / 5.0.
- **CloudEvents 1.0** native — events are CloudEvents-formatted out of the box.
- **System Topics** for Azure resource events (e.g., `Microsoft.Storage.BlobCreated`, `Microsoft.Resources.ResourceWriteSuccess`) — subscribe directly without provisioning a custom topic.
- **Partner Topics** — third-party SaaS partners (Salesforce, Auth0, etc.) emit events into Event Grid.
- **Webhook + Functions + Logic Apps + Service Bus + Event Hubs + Storage Queue** as delivery destinations.

## Patterns + anti-patterns

### Pattern: System Topic for Blob upload → Function

Storage account emits `Microsoft.Storage.BlobCreated` events to the System Topic; Functions subscribes; Function processes the upload. Filtering by `subject` (path prefix) at the broker level keeps the Function from being invoked for irrelevant blobs.

### Pattern: Custom Topic for domain events

Service publishes domain events to a custom topic. Subscribers (other services, monitoring, audit logs) filter and consume. Eliminates pub/sub plumbing in the publisher.

### Pattern: Namespaces with MQTT for IoT

Devices publish telemetry via MQTT to a Namespace; Event Grid routes to subscribers. Pull delivery available where push retry semantics aren't a fit.

### Pattern: CloudEvents schema everywhere

Event Grid native; downstream consumers (Functions, Logic Apps, custom webhooks) consistently see CloudEvents 1.0 envelopes. Standardizes event metadata across producers.

### Anti-pattern: Event Grid for ordered command processing

Push delivery, no ordering guarantees, many subscribers. Use [Service Bus](/stacks/azure/service-bus/) for commands.

### Anti-pattern: Event Grid for replaying historical events

No replay — Event Grid retains events for retry (max 24h) but isn't a log. For replay, use [Event Hubs](/stacks/azure/event-hubs/) Capture.

## Gotchas

- **Push delivery max retry** — 24h then dead-letter (configurable). Configure dead-letter destination on every subscription.
- **Endpoint validation** — Event Grid requires the webhook endpoint to validate ownership on subscription (subscription validation event). Functions / Logic Apps handle this automatically.
- **Throughput at broker level** is high but **per-subscription delivery rate** can throttle.
- **MQTT broker is Namespace-only** — not the classic Event Grid topic resource type.

## Cross-references

- [Service Bus](/stacks/azure/service-bus/) — transactional queue alternative
- [Event Hubs](/stacks/azure/event-hubs/) — streaming alternative
- [Functions](/stacks/azure/functions/) — common subscriber
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — messaging design
- [Event Grid overview](https://learn.microsoft.com/azure/event-grid/overview)
- [Event Grid Namespaces](https://learn.microsoft.com/azure/event-grid/concepts-namespaces)
