---
title: Event Hubs
description: High-throughput streaming, Kafka-compatible. Premium / Dedicated tiers; Event Hubs Capture for cheap retention. Millions of events/sec, replay supported.
product:
  name: Azure Event Hubs
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, database-architect, ai-ml-engineer]
  authoritative_url: https://learn.microsoft.com/azure/event-hubs/
  notes: "Kafka surface stable; Premium tier capacity model unchanged; new uses for SQL MI Change Event Streaming."
---

## What it is

Event Hubs is Azure's high-throughput streaming platform — partitioned log, Kafka-compatible surface, replay-aware consumers, Event Hubs Capture for cheap long-term retention to Blob/ADLS. Canonical reference: [Event Hubs docs](https://learn.microsoft.com/azure/event-hubs/).

## When to use

Pick Event Hubs when:

- **Throughput is dominant** — millions of events/sec.
- **Telemetry, IoT, logs, CDC** — high-volume time-series ingest.
- **Replay history** — consumers re-read from offsets / timestamps.
- **Kafka-compatible client** — your code uses Kafka producers/consumers.
- **Landing data for analytics** — Event Hubs Capture writes to ADLS Gen2 / Blob in Avro for downstream Spark / Fabric / Databricks.

Pick [Service Bus](/stacks/azure/service-bus/) for: transactional queue, ordered sessions, dead-letter. Pick [Event Grid](/stacks/azure/event-grid/) for: reactive event broker, push, many subscribers.

## 2025-2026 currency anchors

- **Kafka surface stable** — Kafka 1.0+ wire protocol; works with most Kafka clients.
- **Premium tier capacity model unchanged** — Throughput Units / Processing Units for cost-effective dedicated capacity.
- **Event Hubs Capture** writes Avro / Parquet to Blob / ADLS Gen2 — cheap retention without consumer code.
- **SQL Server 2025 Managed Instance Change Event Streaming** → Event Hubs as the modern CDC path for SQL.
- **Schema Registry** for Avro / JSON Schema / Protobuf evolution.

## Patterns + anti-patterns

### Pattern: Event Hubs as the streaming spine

Producers (IoT, app telemetry, CDC) → Event Hubs → fan-out to multiple consumer groups (Functions, Stream Analytics, Fabric Real-Time Intelligence, custom Kafka consumers). Replay capability decouples publishers from consumer pace.

### Pattern: EventProcessorClient with Storage checkpoint

```csharp
var processor = new EventProcessorClient(checkpointStore, consumerGroup, eventHubsConnectionString, eventHubName);
processor.ProcessEventAsync += async (args) => {
    await HandleEventAsync(args.Data);
    await args.UpdateCheckpointAsync();
};
await processor.StartProcessingAsync();
```

Multiple workers share processing via lease-based checkpointing. Failed workers' partitions reassigned automatically.

### Pattern: Event Hubs Capture for cheap retention

Enable Capture on the hub → events auto-write to ADLS Gen2 / Blob as Avro/Parquet on time/size window. Downstream Spark / Fabric reads from storage without consumer code.

### Pattern: Kafka surface for portability

If your code uses Kafka clients (`kafka-python`, Confluent JAR), point the producer/consumer at Event Hubs Kafka endpoint — works without code changes. Useful for multi-cloud teams.

### Anti-pattern: Event Hubs as a queue

It's a log, not a queue. No per-message ack; consumers track offsets. For queue semantics, use [Service Bus](/stacks/azure/service-bus/).

### Anti-pattern: Single-partition hub at high throughput

Partition is the parallelism unit. One partition caps at ~1 MB/s ingress. Plan partition count for expected throughput.

### Anti-pattern: Ignoring Schema Registry

Schema-less producers + multiple consumers = schema drift surfaces in production. Use Schema Registry for Avro / JSON Schema / Protobuf.

## Gotchas

- **Partition count is fixed at hub creation** (Standard tier). Premium / Dedicated allow more flexibility.
- **Consumer group max** — Standard tier caps consumer groups; Premium expands.
- **Capture format** — Avro is default; Parquet preferable for analytics. Configure per hub.
- **Throughput Units / Processing Units** — Standard uses TU (auto-inflate optional); Premium uses PU (purchased).

## Cross-references

- [Service Bus](/stacks/azure/service-bus/) — transactional queue
- [Event Grid](/stacks/azure/event-grid/) — reactive push
- [Microsoft Fabric](/stacks/azure/microsoft-fabric/) — Fabric Real-Time Intelligence consumes Event Hubs
- [Azure SQL](/stacks/azure/azure-sql/) — Managed Instance Change Event Streaming source
- [Event Hubs overview](https://learn.microsoft.com/azure/event-hubs/event-hubs-about)
- [Event Hubs Kafka surface](https://learn.microsoft.com/azure/event-hubs/azure-event-hubs-kafka-overview)
