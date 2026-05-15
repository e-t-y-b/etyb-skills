---
title: DynamoDB
description: Managed NoSQL key-value store on AWS — single-table design is the only good design. Zero-ETL to OpenSearch and Redshift eliminates custom replication. On-demand pricing dropped ~25% in 2025.
product:
  name: DynamoDB
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, system-architect, saas-architect]
  authoritative_url: https://docs.aws.amazon.com/dynamodb/
  notes: "API stable; zero-ETL to OpenSearch/Redshift the main 2024-2025 addition; on-demand pricing model unchanged in fundamentals."
---

## What it is

Amazon DynamoDB is AWS's managed serverless NoSQL key-value (and document) database — single-digit-millisecond reads/writes at any scale, on-demand or provisioned capacity, multi-region via Global Tables, ACID across items in the same region via `TransactWriteItems`.

Canonical surface: [docs.aws.amazon.com/dynamodb](https://docs.aws.amazon.com/dynamodb/).

## When to use

| Workload | Use DynamoDB? |
|---|---|
| Key-value, single-digit ms, predictable access patterns | Yes |
| Joinful relational queries | No — use [Aurora](/stacks/aws/aurora/) |
| Multi-region active-active KV | Yes — DynamoDB Global Tables |
| Idempotency / dedup store | Yes — with TTL |
| Session store | Yes — sub-ms reads, TTL cleanup |
| Time-series with append-mostly access | Yes — with hierarchical sort keys |
| Search (full-text, fuzzy) | No — Zero-ETL to [OpenSearch](/stacks/aws/opensearch/) |
| Analytics with complex JOINs | No — Zero-ETL to [Redshift](/stacks/aws/redshift/) |

## 2025-2026 currency anchors

- **DynamoDB Zero-ETL to OpenSearch and Redshift** (2024-2025) eliminates custom replication Lambdas for search/analytics over DynamoDB data.
- **On-demand pricing dropped ~25% in 2025** — v2 on-demand is the new default for unpredictable workloads.
- **DynamoDB Streams** stable; pair with [EventBridge Pipes](/stacks/aws/eventbridge/) for cleaner downstream wiring.
- **Global Tables** mature — multi-region active-active KV.
- **PITR retention** is 35-day rolling window.

## Patterns

### Single-table design

The most consequential pattern. **DynamoDB is not Postgres.** It's a KV store with optional secondary indexes. Multi-table-per-entity is the relational-modeling reflex; it's wrong.

Model access patterns first, then derive table structure. For an e-commerce order system:

```
Access patterns:
1. Get customer by id
2. Get all orders for customer
3. Get order by id
4. Get all items in an order
5. Get all orders in date range (admin reporting)

Table: AppTable
  Partition key: pk (string)
  Sort key: sk (string)

Item shapes:
  pk=CUSTOMER#c123, sk=CUSTOMER#c123    -> customer record
  pk=CUSTOMER#c123, sk=ORDER#o456       -> order summary
  pk=ORDER#o456,    sk=ORDER#o456       -> order detail
  pk=ORDER#o456,    sk=ITEM#i789        -> order line item

GSI1: pk=GSI1PK, sk=GSI1SK
  Order records project:
    GSI1PK=ORDER#STATUS#PENDING, GSI1SK=ORDER#2026-05-14T10:00:00Z#o456
  Supports query #5
```

The pk is high-cardinality; sk supports range queries (`begins_with`, `between`). One table holds many entity types; application code knows the shape from prefix.

### GSI strategy

- **Up to 20 GSIs per table** (soft limit). Most workloads need 1-3.
- **Sparse indexes** — only include items with the indexed attribute. Cheap way to model "find me all orders where status=PENDING" without a hot key.
- **Eventual consistency** on GSIs — read-after-write may not see the new GSI entry for milliseconds.
- **Cost**: GSI writes are charged separately (full WCU per GSI write). Sparse indexes minimize this.

### Capacity modes

| Mode | Use when |
|---|---|
| **On-demand** | Unpredictable traffic, new workloads, or steady traffic <50% of provisioned would buy |
| **Provisioned + auto-scaling** | Predictable steady traffic where Reserved Capacity (1yr/3yr) saves money |

In 2026, on-demand is the default for net-new — the price gap closed and unpredictable spikes don't break the table. Provisioned wins when you can commit and traffic is genuinely steady.

### Optimistic concurrency

```typescript
import { ConditionalCheckFailedException } from '@aws-sdk/client-dynamodb';

try {
  await doc.send(new UpdateCommand({
    TableName: 'Orders',
    Key: { pk: 'ORDER#abc', sk: 'ORDER#abc' },
    UpdateExpression: 'SET #status = :new, version = :v_new',
    ConditionExpression: 'version = :v_old',
    ExpressionAttributeNames: { '#status': 'status' },
    ExpressionAttributeValues: {
      ':new': 'CONFIRMED',
      ':v_old': 3,
      ':v_new': 4,
    },
  }));
} catch (err) {
  if (err instanceof ConditionalCheckFailedException) {
    throw new ConflictError('Order was modified by another writer');
  }
  throw err;
}
```

Version attribute + ConditionExpression is the canonical optimistic concurrency pattern. Without it, last-writer-wins eats data.

### Transactions

`TransactWriteItems` — up to 100 items, ACID across items in one or more tables in the same region. 2x the cost of regular writes. Use for multi-item writes that must succeed or fail together.

`TransactGetItems` — up to 100 items in one transactional read.

Reserve transactions for truly atomic-required operations (debit-credit, idempotent claim); 2x cost for "safety" is wrong.

### Hot partition mitigation

A `pk=DATE#2026-05-14` is a recipe for a hot partition when all writes for the day land there.

- **Write sharding**: `pk=DATE#2026-05-14#SHARD#<random 0-9>`. Increases pk cardinality; reads must query all shards.
- **Hierarchical timestamps**: `pk=HOUR#2026-05-14T10`, `sk=EVENT#<id>` — one partition per hour, queryable.
- **Adaptive capacity** (automatic) — DynamoDB rebalances hot partitions over minutes; relies on this for spiky-but-recoverable hot keys.

### Zero-ETL

```typescript
const table = new dynamodb.Table(this, 'Orders', {
  partitionKey: { name: 'pk', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'sk', type: dynamodb.AttributeType.STRING },
  pointInTimeRecovery: true,  // Required for zero-ETL
  stream: dynamodb.StreamViewType.NEW_AND_OLD_IMAGES,  // Required for real-time sync
});

// Pipe set up via DynamoDB → OpenSearch zero-ETL integration in console or SDK
```

Eliminates custom replication Lambda for:
- **Full-text search** on DynamoDB items via OpenSearch.
- **Vector search** if embeddings are stored.
- **Fuzzy / phrase / typo-tolerant search** that DynamoDB can't do natively.
- **Analytics** via Redshift.

### Backup + PITR

- **PITR** — 35-day rolling window. Enable on every production table. Cost: 20% of storage cost.
- **On-demand backups** — full snapshots, retained until deleted.
- **AWS Backup** orchestrates cross-region, cross-account DynamoDB backups via a single policy.

### Global Tables

Multi-region active-active KV. Last-writer-wins conflict resolution per-attribute (DynamoDB Global Tables v2). Use when you need writes in multiple regions with eventual consistency tolerated.

For strong-consistency multi-region writes, use [Aurora DSQL](/stacks/aws/aurora/) instead.

### SDK usage

```typescript
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, QueryCommand, BatchWriteCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const doc = DynamoDBDocumentClient.from(client, {
  marshallOptions: { removeUndefinedValues: true, convertClassInstanceToMap: true },
});

const items = await doc.send(new QueryCommand({
  TableName: 'Orders',
  KeyConditionExpression: 'pk = :pk AND begins_with(sk, :prefix)',
  ExpressionAttributeValues: { ':pk': 'CUSTOMER#123', ':prefix': 'ORDER#' },
  Limit: 50,
}));
```

`DynamoDBDocumentClient` auto-marshals JS objects to DynamoDB attribute-value format. Always use it; never write `{ S: 'value' }` shapes by hand.

## Anti-patterns

- **Multi-table-per-entity** (relational reflex). Single-table design is the right shape.
- **Scans on hot tables.** Scans are full-table reads, $$ at scale. Design GSIs.
- **DynamoDB transactions "to be safe".** 2x cost; reserve for truly atomic-required.
- **Custom Lambda replicating DynamoDB → OpenSearch.** Use Zero-ETL.
- **`Never Expire` log retention** on the [CloudWatch](/stacks/aws/cloudwatch/) log group attached to DDB-triggered Lambdas.
- **High-cardinality dimensions on emitted metrics** (userId, requestId). That's logs, not metrics.
- **No idempotency table** for at-least-once async invocations.
- **`pk=DATE` partition key** for time-series. Hot partition guarantee.

## Gotchas

- **40K WCU / 40K RCU per-table default quota; 80K per account.** Request increase before launch.
- **Item size cap = 400 KB.** Larger payloads go to S3 with a pointer in DynamoDB.
- **`ProvisionedThroughputExceededException`** on provisioned tables; switch to on-demand or scale up.
- **GSI throttling separate from base table** — a hot GSI key can throttle even when the table isn't.
- **Streams retention = 24 hours.** Consumers must keep up or lose events.
- **Adaptive capacity takes minutes to rebalance** — sustained hot keys still throttle initially.
- **PITR isn't backup** for compliance retention — PITR is rolling 35-day; longer retention via on-demand backups + AWS Backup.

## Cross-references

- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — Lambda + DynamoDB idempotency pattern
- [`/stacks/aws/eventbridge/`](/stacks/aws/eventbridge/) — Pipes for DynamoDB Streams → downstream
- [`/stacks/aws/opensearch/`](/stacks/aws/opensearch/) — Zero-ETL target for search
- [`/stacks/aws/redshift/`](/stacks/aws/redshift/) — Zero-ETL target for analytics
- [`/stacks/aws/aurora/`](/stacks/aws/aurora/) — alternative for relational + transactional needs
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — role view; selection matrix
- [DynamoDB Service Quotas](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ServiceQuotas.html)
