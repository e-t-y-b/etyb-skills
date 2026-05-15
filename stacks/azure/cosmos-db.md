---
title: Cosmos DB
description: Multi-model NoSQL — NoSQL (DiskANN vector), MongoDB vCore (Azure DocumentDB), Cassandra, Gremlin, Table. Cosmos for PostgreSQL is RETIRING — migrate to Postgres Flex + Citus.
product:
  name: Cosmos DB
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, ai-ml-engineer, system-architect]
  authoritative_url: https://learn.microsoft.com/azure/cosmos-db/
  notes: "DiskANN vector GA 2024-25; MongoDB vCore = Azure DocumentDB rebrand; Cosmos for PostgreSQL retiring."
---

## What it is

Cosmos DB is Azure's multi-model NoSQL platform with five APIs — NoSQL (native), MongoDB (RU + vCore), Cassandra, Gremlin (graph), Table. Global writes, partition-key-based scale, SLA-backed P99 latency. The 2024-25 currency anchor is **DiskANN vector search** (NoSQL API) and the **rebrand of MongoDB vCore as Azure DocumentDB**. Canonical reference: [Cosmos DB docs](https://learn.microsoft.com/azure/cosmos-db/).

## When to use

Pick Cosmos DB **for NoSQL** when:

- **Document NoSQL with global writes** — multi-region active-active.
- **Operational data + vector search** — DiskANN handles billions of vectors alongside business data.
- **Predictable single-digit-ms latency at scale** — partition-aware queries hit P99 < 10ms.

Pick **MongoDB vCore (Azure DocumentDB)** when:

- Migrating from MongoDB Atlas / self-hosted Mongo.
- Team has Mongo expertise; provisioned compute pricing model preferred.

Pick **Cassandra / Gremlin / Table** when:

- You have an existing workload on the corresponding wire protocol.

**Do not pick Cosmos for PostgreSQL** — it's retiring. Use [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/) with Elastic Clusters (Citus).

## 2025-2026 currency anchors

- **DiskANN vector search** GA 2024-25 (NoSQL API) — Microsoft Research's billion-scale vector index, predictable latency at millions of QPS.
- **MongoDB vCore = Azure DocumentDB** rebrand — open-source DocumentDB engine, MongoDB 6.0+ wire protocol, `$vectorSearch` (HNSW / IVF), provisioned compute pricing.
- **Cosmos for PostgreSQL retiring** — replacement is [PostgreSQL Flexible Server with Elastic Clusters](/stacks/azure/postgresql-flexible-server/) (Citus extension). Same Citus underneath; migrate plans must consider Citus version compatibility.
- **Hierarchical partition keys** (partial GA / preview) — up to 3 levels.
- **Continuous backup (PITR up to 30 days)** + periodic backup options.
- **Multi-region writes** with configurable conflict resolution (LWW default).
- **Serverless** caps at 1 TB and 5000 RU/s burst.

## Patterns + anti-patterns

### Pattern: Partition key from the dominant read pattern

Once you create a container, the partition key is permanent. Pick from read pattern (high cardinality, even distribution, ≤ 20 GB per logical partition). See [Database Architect on Azure](/stacks/azure/database-architect/) for the full rules.

### Pattern: Cosmos DiskANN as the vector store

When vectors live alongside operational data and you want global multi-region writes: declare vector embedding policy + DiskANN index policy; filter by partition before vector distance to control RU.

### Pattern: Change Feed processor for downstream events

```csharp
var processor = container.GetChangeFeedProcessorBuilder<MyDoc>("processor", HandleChangesAsync)
    .WithInstanceName("instance1")
    .WithLeaseContainer(leaseContainer)
    .Build();
await processor.StartAsync();
```

Lease-based; multiple workers share. Replaces homegrown polling. Common pattern: Change Feed → Function → Service Bus for cross-service domain events.

### Pattern: Provisioned Autoscale for unpredictable load

Set max RU/s; Cosmos scales between 10% and 100% within the hour. Avoids 429s at peak without paying for peak 24/7.

### Anti-pattern: Cross-partition query as the dominant pattern

If most queries lack a partition key in `WHERE`, the partition key is wrong. Re-design (and migrate) before scale becomes the problem.

### Anti-pattern: Timestamp or monotonic ID as partition key

All writes hit current partition → hot partition. Use high-cardinality natural key (`tenantId`, `userId`) or synthetic (`tenantId + bucket`).

### Anti-pattern: Cosmos serverless for unpredictable production load

Caps at 1 TB and 5000 RU/s burst. If you might exceed either, start provisioned with autoscale.

### Anti-pattern: Vector search across all partitions

Combine vector distance with a `WHERE c.tenantId = @t` filter — much cheaper than full-index search.

### Anti-pattern: Cosmos for PostgreSQL on a new build

Retiring. Migrate plans to PostgreSQL Flex + Elastic Clusters.

## Gotchas

- **Partition key is permanent.** Renaming requires data migration.
- **Cosmos serverless and provisioned are not interchangeable in-place** — requires new account + migration.
- **Multi-region writes default to LWW conflict resolution** — if "two regions both decrementing inventory" is a thing, you need custom conflict resolution (merge stored procedure) or single-region writes for that partition.
- **DiskANN supports vector quantization** — use it for embedding sizes > 1536 to control storage.
- **`RequestCharge` per operation** is the cost signal — log it in dev/staging to catch expensive queries before prod.
- **Index update on write doubles or triples write cost** — review the indexing policy; exclude paths you don't query.

## Cross-references

- [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/) — replacement for Cosmos for PostgreSQL
- [Azure AI Search](/stacks/azure/ai-search/) — alternative vector store for doc search
- [Database Architect on Azure](/stacks/azure/database-architect/) — partition design, RU sizing, vector indexing
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — RAG retrieval design
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — SDK patterns
- [Cosmos DB partitioning](https://learn.microsoft.com/azure/cosmos-db/partitioning-overview)
- [Cosmos DB vector search](https://learn.microsoft.com/azure/cosmos-db/nosql/vector-search)
- [Cosmos DB for MongoDB vCore](https://learn.microsoft.com/azure/cosmos-db/mongodb/vcore/)
