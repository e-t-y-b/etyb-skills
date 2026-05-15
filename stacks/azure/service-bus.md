---
title: Service Bus
description: Transactional message broker — queues, topics, sessions, dead-lettering. Premium tier is the production default. CMK encryption, geo-DR, 100 MB messages.
product:
  name: Azure Service Bus
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, devops-engineer]
  authoritative_url: https://learn.microsoft.com/azure/service-bus-messaging/
  notes: "Mature; Premium tier featureset stable; geo-DR matured; new features rare."
---

## What it is

Service Bus is Azure's transactional message broker — queues for point-to-point, topics for pub/sub with subscriptions, sessions for ordered delivery, dead-letter queues for retry exhaustion. Premium tier adds VNet integration, large message support (100 MB), CMK encryption, geo-DR. Canonical reference: [Service Bus docs](https://learn.microsoft.com/azure/service-bus-messaging/).

## When to use

Pick Service Bus when:

- You need **guaranteed ordering** (sessions).
- You need **transactions** (multi-message commits within the broker).
- You need **dead-lettering with re-processing**.
- You need **scheduled delivery** (deliver at a future time).
- "Service A sends a command to Service B" — pull-based consumer model.

Pick [Event Grid](/stacks/azure/event-grid/) instead for: reactive event broker, push-based, many subscribers, "things happened" events. Pick [Event Hubs](/stacks/azure/event-hubs/) for: high-throughput streaming, replay, Kafka surface.

Many systems use all three. That's normal.

## 2025-2026 currency anchors

- **Premium tier featureset is stable** — geo-DR (paired namespaces with auto-failover), VNet integration, CMK, large messages, partitioned namespaces.
- **Sessions** for ordered processing — single-threaded per session ID; useful for per-entity ordering.
- **At-least-once delivery** — your handler must be idempotent.
- **Service Bus Explorer** in portal for inspecting queues/topics/dead-letter.

## Patterns + anti-patterns

### Pattern: Topic + subscription per consumer service

Each downstream service has its own subscription filtered by message properties. Failure handling is per-subscription via dead-letter queue + retry policy. Adding new consumers doesn't impact existing.

### Pattern: Idempotent handler with dedup store

```csharp
public async Task ProcessMessage(ProcessMessageEventArgs args)
{
    var msg = args.Message;
    if (await _dedupStore.IsProcessedAsync(msg.MessageId))
    {
        await args.CompleteMessageAsync(msg);
        return;
    }
    try
    {
        await _handler.HandleAsync(msg);
        await _dedupStore.MarkProcessedAsync(msg.MessageId);
        await args.CompleteMessageAsync(msg);
    }
    catch (Exception ex) when (ShouldDeadLetter(ex))
    {
        await args.DeadLetterMessageAsync(msg, "non-retryable", ex.Message);
    }
}
```

### Pattern: Sessions for ordered processing per entity

Set `SessionId = customerId` on producer. Consumer with `ProcessSession` callback processes one session at a time; messages within a session deliver in order. Use when "order matters within a partition but parallelism across partitions is fine."

### Pattern: Premium + geo-DR for production

Premium namespaces support paired geo-DR namespaces with auto-failover. Plan failover triggers + DNS routing.

### Anti-pattern: Standard tier in production at high throughput

Standard tier lacks VNet integration, large message support, geo-DR. Production = Premium.

### Anti-pattern: Non-idempotent handlers

At-least-once delivery means duplicates happen. Dedup on `MessageId`.

### Anti-pattern: Service Bus for streaming logs / IoT telemetry

Throughput-dominant workloads → [Event Hubs](/stacks/azure/event-hubs/). Service Bus is queue semantics; Event Hubs is stream semantics.

## Gotchas

- **Lock duration** — default 60s, max 5 min. If your handler takes longer, renew the lock (`renewLock`) or shorten the work.
- **DLQ doesn't auto-retry** — moving to DLQ ends the redelivery loop. Operator action (or a DLQ processor app) re-enqueues.
- **Message size** — Standard tier caps at 256 KB; Premium 100 MB. For larger payloads, use claim-check pattern (write to Blob, pass URL in message).
- **Session-enabled queues** require all messages have `SessionId`.

## Cross-references

- [Event Grid](/stacks/azure/event-grid/) — reactive push alternative
- [Event Hubs](/stacks/azure/event-hubs/) — streaming alternative
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — idempotency patterns
- [Functions](/stacks/azure/functions/) — Service Bus trigger consumer
- [Service Bus messaging overview](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-messaging-overview)
