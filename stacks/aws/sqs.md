---
title: SQS
description: Managed message queue on AWS — at-least-once delivery, partial batch failure pattern, FIFO high-throughput mode for ordered queues, long polling defaults to set on every queue.
product:
  name: SQS
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect]
  authoritative_url: https://docs.aws.amazon.com/sqs/
  notes: "Mature; FIFO high-throughput mode (3000 msg/sec per group), partial batch failure pattern (ReportBatchItemFailures) stable."
---

## What it is

Amazon SQS is AWS's managed message queue — fully durable, at-least-once delivery, decouples producers from consumers. Two queue types: Standard (best-effort ordering, near-unlimited throughput) and FIFO (strict ordering per message group, throughput capped per group or 3000 msg/sec with high-throughput mode).

Canonical surface: [docs.aws.amazon.com/sqs](https://docs.aws.amazon.com/sqs/).

## When to use

| Need | Use SQS? |
|---|---|
| Decouple producer / consumer, at-least-once delivery | Yes — SQS Standard |
| Strict FIFO ordering within partition | Yes — SQS FIFO |
| Pub/sub fan-out without ordering | No — use [SNS](#cross-references) or [EventBridge](/stacks/aws/eventbridge/) |
| Ordered stream with replay | No — use Kinesis or MSK |
| Routing with rules across services/accounts | No — use [EventBridge](/stacks/aws/eventbridge/) |
| Worker pool consuming from a single queue | Yes — Lambda or ECS consumers |

## 2025-2026 currency anchors

- **SQS FIFO high-throughput mode** — up to 3000 msg/sec per message group. Stable.
- **Partial batch failure pattern** (`ReportBatchItemFailures`) is the modern shape for Lambda consumers — return failed message IDs; SQS keeps them in the queue.
- **EventBridge Pipes** can replace SQS → Lambda → next-step glue. See [EventBridge](/stacks/aws/eventbridge/).
- **SSE-KMS** supported; encryption at rest with customer-managed key.

## Patterns

### Standard vs FIFO

| Property | Standard | FIFO |
|---|---|---|
| **Ordering** | Best-effort | Strict per message group |
| **Delivery** | At-least-once | Exactly-once (with `MessageDeduplicationId`) |
| **Throughput** | Near-unlimited | 300 msg/sec; 3000 with high-throughput mode |
| **Use** | Default | When order matters |

### Visibility timeout

Critical to get right with Lambda consumers:
- **Must exceed Lambda max execution time** — otherwise message becomes visible again mid-processing.
- **Default = 30s.** Increase for long-running consumers.
- **Retried messages** become visible after `VisibilityTimeout`; reset per failed receive.

### Long polling

```bash
aws sqs receive-message \
  --queue-url ... \
  --wait-time-seconds 20  # Long polling
```

Set `ReceiveMessageWaitTimeSeconds=20` on every queue (default is 0 = short polling). Reduces empty receives, lowers cost, lowers latency for sporadic messages.

### Partial batch failure (Lambda consumer)

```typescript
import type { SQSBatchResponse, SQSEvent } from 'aws-lambda';

export const handler = async (event: SQSEvent): Promise<SQSBatchResponse> => {
  const failures: { itemIdentifier: string }[] = [];

  for (const record of event.Records) {
    try {
      await processMessage(record);
    } catch (err) {
      failures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures: failures };
};
```

Without this, a single failed message in a batch retries the entire batch. With it, only failed messages are retried.

### DLQ pattern

```
[Producer] → [SQS Main Queue] → [Lambda consumer]
                                  ↓ after maxReceiveCount retries
                                 [SQS DLQ] → [Inspector Lambda / manual replay]
```

Every async queue should have a DLQ. **Alarm on DLQ depth > 0.** Without it, failures disappear silently.

### Dedup keys (FIFO)

```typescript
await sqs.send(new SendMessageCommand({
  QueueUrl: ...,
  MessageBody: JSON.stringify(payload),
  MessageDeduplicationId: orderId,
  MessageGroupId: customerId,
}));
```

`MessageDeduplicationId` provides exactly-once semantics within a 5-minute window. `MessageGroupId` defines FIFO partitions.

### Lambda + SQS scaling

Lambda scales SQS consumption based on backlog. Tune:
- **`batchSize`** — messages per invocation (1-10000).
- **`maximumBatchingWindowInSeconds`** — wait this long to fill the batch.
- **`reportBatchItemFailures`** — partial batch failure semantics.
- **`maximumConcurrency`** — cap on concurrent Lambda invocations from this queue.

## Anti-patterns

- **Short polling (`WaitTimeSeconds=0`)** — empty receives at full rate burn money + quota. Always 20.
- **DLQ-less queue.** Failures silently disappear.
- **Visibility timeout < Lambda max execution.** Messages reappear mid-processing.
- **No idempotency on consumers.** At-least-once means duplicates; design for it.
- **Standard queue when order matters.** Use FIFO.
- **FIFO queue with one MessageGroupId** when you need throughput beyond 3000 msg/sec.
- **No alarm on DLQ depth or queue age.** Critical signals.

## Gotchas

- **`MessageDeduplicationId` is 5-minute scoped.** Duplicates older than 5 min get through.
- **Maximum message size = 256 KB.** Larger via [S3](/stacks/aws/s3/) with reference in message.
- **Per-queue throttling defaults** — Standard 3000 transactions/sec, FIFO 300/sec (3000 high-throughput). Quota-bumpable.
- **Cross-region queues** require explicit cross-region replication; no native multi-region SQS.
- **`SendMessageBatch` cap** = 10 messages per call.

## Cross-references

- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — SQS consumer patterns
- [`/stacks/aws/eventbridge/`](/stacks/aws/eventbridge/) — Pipes can replace SQS → Lambda glue
- [`/stacks/aws/step-functions/`](/stacks/aws/step-functions/) — wait-for-callback uses SQS
- [`/stacks/aws/cloudwatch/`](/stacks/aws/cloudwatch/) — DLQ depth alarms
- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — role view; queue/topic selection
- [SNS docs](https://docs.aws.amazon.com/sns/) — pub/sub fan-out
