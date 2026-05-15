---
title: Azure Functions
description: Azure Functions — Flex Consumption (new default), isolated worker .NET, Durable Functions v3 + Durable Task Scheduler. In-process .NET retired late 2026.
product:
  name: Azure Functions
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, system-architect]
  authoritative_url: https://learn.microsoft.com/azure/azure-functions/
  notes: "Flex Consumption GA changed the production default; in-process .NET sunset late 2026; Durable v3 + new scheduler."
---

## What it is

Azure Functions is the event-driven serverless platform — HTTP, Service Bus, Event Grid, Event Hubs, Timer, Cosmos Change Feed, Storage Blob/Queue triggers run your code with per-invocation billing. Canonical reference: [Functions docs](https://learn.microsoft.com/azure/azure-functions/).

## When to use

Pick Functions when:

- **Event-driven, short-lived (< 10 minutes)** — HTTP API, queue worker, event consumer, scheduled task.
- **Strong native Azure trigger integration** — Cosmos Change Feed, Event Grid, Service Bus.
- **Variable load** where scale-to-zero matters.
- **Sub-200ms code paths** where Flex Consumption's always-ready instances eliminate cold start.

Don't use Functions for:

- **Long-running** work (> 10 min) — use [Container Apps Jobs](/stacks/azure/container-apps/) or Durable Functions orchestrations.
- **Websockets** — use [App Service](/stacks/azure/app-service/) with SignalR Service.
- **Always-on user-facing API on the classic Consumption plan** — cold starts ruin P99.

## 2025-2026 currency anchors

- **Flex Consumption** (GA 2024) — pay-per-execution + always-ready instances + VNet integration + zone redundancy. **The new default for production serverless.** Premium Plan is legacy for new builds.
- **In-process .NET retirement** — phasing out through late 2026. New Functions projects MUST use the **isolated worker model**. Migration is non-trivial (different SDK packages, different DI, different HTTP types).
- **Durable Functions v3** + **Durable Task Scheduler** — managed backend lower-latency than Azure Storage Tables. Use for new builds on Flex Consumption.
- **Functions Core Tools v4** (`func@4`) — local dev runtime.
- **.NET 10 Native AOT support** — sub-50ms startup, 60-80% memory reduction in isolated worker. Closes the cold-start gap with in-process.
- **Python v2 programming model** (decorator-based) is current; v1 is retiring.
- **Azure Monitor OpenTelemetry Distro** wired via `Microsoft.Azure.Functions.Worker.OpenTelemetry`.

## Patterns + anti-patterns

### Pattern: Flex Consumption with always-ready instances for HTTP APIs

Classic Consumption has cold starts that ruin user-facing P99. Flex Consumption with N always-ready instances eliminates cold start for warm paths while still scaling to zero idle hours.

### Pattern: Isolated worker .NET from day one

Don't start a new project on in-process .NET. The migration deadline is real. Project SDK: `Microsoft.NET.Sdk.Worker`. Packages: `Microsoft.Azure.Functions.Worker.*`. HTTP type: `HttpRequestData`.

### Pattern: Durable Functions for orchestration

Long-running workflows (saga, fan-out/fan-in, human approval, polling) use Durable Functions v3 with Durable Task Scheduler:

| Pattern | Use case |
|---------|----------|
| Function chaining | Sequential steps with checkpoints |
| Fan-out / fan-in | Parallel work + aggregation |
| Async HTTP API | Long-running request → 202 + status URL |
| Monitor | Poll until external state changes |
| Human interaction | Wait for external event with timeout |

### Pattern: Cosmos Change Feed trigger for outbox

Service writes to Cosmos (business doc + outbox sub-doc) → Cosmos Change Feed trigger → Function publishes domain event to Service Bus. Eliminates dual-write problem.

### Pattern: Idempotent triggers

Every Service Bus / Event Grid trigger is at-least-once. Handler must dedupe on `MessageId` against a Cosmos / Redis dedup store with TTL > max retry window.

### Anti-pattern: HTTP API on classic Consumption

Cold starts make P99 unpredictable. Move to Flex Consumption or shift to App Service / Container Apps.

### Anti-pattern: In-process .NET on a new project

Will need migration before late 2026. Start isolated worker.

### Anti-pattern: Long-running work in Functions

10-minute timeout. Use Durable Functions for orchestration or Container Apps Jobs for batch.

### Anti-pattern: Hot-loop polling

Don't `while(true) { await GetMessages() }`. Use SDK processor abstractions (`ServiceBusProcessor`, `EventProcessorClient`).

## Gotchas

- **In-process → isolated worker migration is real work.** Different SDK, different DI, different HTTP types, different middleware model. Plan it; don't paper over.
- **Functions on Aspire skips event-driven scaling currently.** .NET Aspire deploys default to Container Apps; Functions integration is evolving.
- **Functions Java cold starts are worst-in-class.** Prefer Flex Consumption with always-ready, or shift to Container Apps for Java.
- **Storage account dependency** — Functions requires a backing Storage account for state. Don't put it on a public endpoint in production.
- **Durable Functions on Storage Tables vs Durable Task Scheduler** — Tables backing is legacy; new builds choose Durable Task Scheduler for lower latency.

## Cross-references

- [Backend Architect on Azure](/stacks/azure/backend-architect/) — isolated worker migration, idempotency patterns
- [Container Apps](/stacks/azure/container-apps/) — Container Apps Jobs for long batch
- [Service Bus](/stacks/azure/service-bus/) — at-least-once delivery semantics
- [Cosmos DB](/stacks/azure/cosmos-db/) — Change Feed trigger source
- [Functions .NET isolated worker migration](https://learn.microsoft.com/azure/azure-functions/migrate-dotnet-to-isolated-model)
- [Flex Consumption plan](https://learn.microsoft.com/azure/azure-functions/flex-consumption-plan)
- [Durable Functions](https://learn.microsoft.com/azure/azure-functions/durable/)
