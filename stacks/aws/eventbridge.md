---
title: EventBridge
description: Event bus, Pipes, and Scheduler on AWS — Pipes eliminates Lambda glue for source-filter-enrich-target patterns; one custom bus per bounded context; Scheduler for periodic work.
product:
  name: EventBridge
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, devops-engineer]
  authoritative_url: https://docs.aws.amazon.com/eventbridge/
  notes: "Pipes mature; Scheduler GA; partner event buses expanded. Schema Registry auto-discovery stable."
---

## What it is

Amazon EventBridge is the event bus + routing layer — AWS service events, custom application events, and partner SaaS events flow through buses, get matched by rules, and route to ~30 target service types. **Pipes** is the source-filter-enrich-target connector that replaces "Lambda glue." **Scheduler** is the modern cron primitive.

Canonical surface: [docs.aws.amazon.com/eventbridge](https://docs.aws.amazon.com/eventbridge/).

## When to use

| Need | Use EventBridge? |
|---|---|
| Pub/sub fan-out with routing rules | Yes — custom event bus |
| AWS service events (S3, EC2 state, etc.) | Yes — default bus |
| Cross-account / cross-region event flow | Yes — bus targets across accounts |
| Partner SaaS event ingest (Stripe, Shopify, Auth0) | Yes — partner event bus |
| Periodic / cron jobs | Yes — EventBridge Scheduler |
| Source → filter → enrich → target without Lambda | Yes — Pipes |
| Strict in-order processing with replay | No — use [Kinesis](#cross-references) or MSK |

## 2025-2026 currency anchors

- **EventBridge Pipes** mature — eliminates Lambda-as-glue for `source → filter → enrich → target` patterns.
- **EventBridge Scheduler** is the modern shape for cron / one-shot scheduling (replaces CloudWatch Events Rules with schedule). Universal target support, group-based management, configurable retry.
- **Partner event buses** expanded — Stripe, Shopify, Auth0, Datadog, PagerDuty, MongoDB Atlas among many.
- **Schema Registry** auto-discovers schemas; code-binding generation for TypeScript, Java, Python.

## Patterns

### Default vs custom event bus

| Bus | Use for |
|---|---|
| **Default bus** | AWS service events (S3 events, EC2 state changes, IAM Access Analyzer findings, etc.) |
| **Custom bus** | Application events with custom event schema |
| **Partner event bus** | Third-party SaaS integration |

Default for new app events: **one custom bus per bounded context** (microservice, team, domain). Bus-per-microservice creates organic blast-radius isolation.

### EventBridge Pipes — eliminate Lambda glue

Pipes connect source → optional filter → optional enrichment → target without Lambda in the middle:

```typescript
import * as pipes from 'aws-cdk-lib/aws-pipes-alpha';

new pipes.Pipe(this, 'OrdersToWorkflow', {
  source: new pipes.SqsSource(ordersQueue),
  filter: new pipes.Filter([
    pipes.FilterPattern.fromObject({ 'body.orderType': ['premium'] })
  ]),
  enrichment: new pipes.LambdaEnrichment(enrichFn),
  target: new pipes.SfnStateMachine(workflow, {
    invocationType: pipes.StateMachineInvocationType.FIRE_AND_FORGET,
  }),
});
```

Pipes replaces these Lambda-glue patterns:
- [SQS](/stacks/aws/sqs/) → [Step Functions](/stacks/aws/step-functions/) (no Lambda needed)
- [DynamoDB](/stacks/aws/dynamodb/) Streams → EventBridge (no Lambda needed)
- Kinesis → Lambda with prior filtering/enrichment (Lambda still in path, but less glue)
- Kafka → Lambda

Every "Lambda that does nothing but forward" is a code smell — replace with a Pipe.

### EventBridge rules — pattern matching

```json
{
  "source": ["com.mycorp.orders"],
  "detail-type": ["OrderPlaced"],
  "detail": {
    "tier": ["premium", "enterprise"],
    "total": [{ "numeric": [">", 1000] }]
  }
}
```

Rules match events on `source`, `detail-type`, and `detail` content. Powerful primitives:
- Exact match (string, number, boolean, null).
- Numeric comparison (`>`, `<`, `=`, `!=`, range).
- Prefix match.
- IP range / CIDR match.
- Suffix / exists / anything-but.

### EventBridge Scheduler

```bash
aws scheduler create-schedule \
  --name nightly-cleanup \
  --schedule-expression "rate(1 day)" \
  --target '{
    "Arn": "arn:aws:lambda:us-east-2:123456:function:cleanup",
    "RoleArn": "arn:aws:iam::123456:role/scheduler-invoke"
  }' \
  --flexible-time-window '{ "Mode": "FLEXIBLE", "MaximumWindowInMinutes": 15 }'
```

Use over CloudWatch Events Rules with `schedule` expressions — universal target support, group-based management, flexible windows that smooth load.

### Schema Registry

Auto-discovers schemas from events; generates code bindings (TypeScript, Java, Python) for publishers/consumers. Treat event schemas like API contracts — version explicitly, evolve additively, never break consumers without a major version bump.

### Cross-account event flow

EventBridge supports cross-account event bus targets — events emitted in Account A can route to a bus in Account B. Use for org-wide event integration.

### Archive + replay

- **Event archive** captures all events on a bus for a configured retention period.
- **Replay** sends archived events back to the bus (or to specific rules). Use for backfill after a consumer bug, or to populate a new consumer from history.

## Anti-patterns

- **Lambda-as-glue** between two AWS services when [Pipes](#eventbridge-pipes--eliminate-lambda-glue) can replace it.
- **Single shared bus for everything.** Hard to evolve schemas, blast radius too wide.
- **No archive on production buses.** Lost messages can't be replayed.
- **CloudWatch Events rules with schedule expressions for new cron.** Use EventBridge Scheduler.
- **No DLQ on critical targets.** Failures disappear silently. Configure `DeadLetterConfig` on the rule.
- **Synchronous user-facing flows depending on EventBridge.** EB is async; latency is seconds, not ms.

## Gotchas

- **At-least-once delivery** — use idempotency tokens; assume duplicates.
- **128 KB max event size.** Larger payloads go to [S3](/stacks/aws/s3/) with reference in the event.
- **EventBridge → Lambda has the standard 256 KB async invoke limit.**
- **Pipes filter cost** — Pipes are billed per event processed; heavy filtering done in the source (SQS / DynamoDB Streams) saves money.
- **Rule limit per bus** is 300 by default; per account is 100,000 — verify quotas before designing.

## Cross-references

- [`/stacks/aws/sqs/`](/stacks/aws/sqs/) — queue-based decoupling
- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — common EventBridge target
- [`/stacks/aws/step-functions/`](/stacks/aws/step-functions/) — workflow target; pair with Pipes
- [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) — Streams source for Pipes
- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — role view; event-driven idioms
- [Kinesis Data Streams](https://docs.aws.amazon.com/streams/) — when ordering + replay matters more than routing
