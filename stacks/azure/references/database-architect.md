---
role: database-architect
stack: azure
last_verified_on: "2026-05-14"
---

# Azure — database-architect overlay

You're picking the data tier, the schema, the indexing, the partitioning, the replication, and the migration path on Azure. This overlay tells you what Azure 2026 provides, where the sharp edges are, and what migrations are happening underneath you.

You don't write the application SDK code (backend-architect) or the IaC (devops-engineer) — you own the data design and the operational discipline around it.

## What this role does on Azure

- Picks the **right DB service** for each workload (Cosmos DB / Azure SQL / PostgreSQL Flex / Managed Redis / ADLS Gen2 / Fabric).
- Designs **partition keys**, **indexes**, **sharding strategies**.
- Sets **RU/s** (Cosmos) or **DTU/vCore** (SQL) or **compute tier** (Postgres / Redis) based on workload.
- Designs **replication / HA / geo-DR** strategy per workload.
- Designs **backup + restore** policy and runs **restore drills**.
- Plans **migration paths** from legacy services (Cosmos PG → Postgres Flex; SQL Single Server → MI / Flex; Azure Cache for Redis classic → Managed Redis).
- Designs **vector indexing strategy** when AI/RAG is in scope (Cosmos DiskANN vs Azure AI Search vs pgvector).
- Owns the **data lake / OneLake / lakehouse** landing pattern (Fabric / Synapse / Databricks).
- Owns **CDC / outbox / change feed** patterns for downstream consumers.
- Defines **PII / sensitive data** classification with Purview.

## Decision frameworks

### Database selection on Azure

| Workload | Pick | Why |
|----------|------|-----|
| OLTP, single-region or paired-region, T-SQL preferred | **Azure SQL Database (Hyperscale)** | 100 TB storage auto-grow, near-instant backups, up to 4 named read replicas |
| OLTP, multi-tenant SaaS, many small tenant DBs | **Azure SQL Hyperscale Elastic Pools** (GA) | Pool DBs share compute; zone-redundant; PRMS/MOPRMS premium-series hardware |
| OLTP, PostgreSQL preferred | **Azure Database for PostgreSQL Flexible Server** | Single Server retired Mar 2025; Flex is the only current option |
| Horizontally scalable Postgres | **PostgreSQL Flex + Elastic Clusters (Citus)** | Replacement for retiring Cosmos DB for PostgreSQL |
| Document NoSQL, global, vector | **Cosmos DB for NoSQL (DiskANN)** | DiskANN GA 2024-25; multi-region writes |
| MongoDB-compatible workload | **Cosmos DB for MongoDB vCore (Azure DocumentDB)** | Open-source DocumentDB engine; provisioned compute; built-in vector search |
| MongoDB workload already on Cosmos RU API | **Cosmos DB for MongoDB (RU)** | Legacy; recommend vCore for new builds |
| Cassandra-compatible | **Cosmos DB for Cassandra** | CQL wire protocol |
| Graph DB | **Cosmos DB for Gremlin** | Apache Gremlin + TinkerPop |
| Key-value (legacy Azure Table Storage migration) | **Cosmos DB for Table** | Cheaper alternative: Azure Table Storage (but losing mindshare) |
| Cache / session | **Azure Managed Redis** | Successor service; Azure Cache for Redis classic retiring |
| Time-series / log / IoT analytics | **Azure Data Explorer (Kusto)** | High-cardinality time-series; KQL |
| Data lake (raw + structured files) | **ADLS Gen2** | HNS enabled at create; foundation for Fabric/Synapse/Databricks |
| Unified analytics (BI + DE + DS) | **Microsoft Fabric + OneLake** | New analytics work; Synapse maintenance |
| Vector / embedding store (managed AI search) | **Azure AI Search** | Hybrid retrieval, semantic ranker, integrated vectorization |
| FHIR R4 healthcare records | **Azure Health Data Services FHIR service** | Azure API for FHIR retired |

### Cosmos DB — partition key design

**The single most important decision you'll make.** Once you create a container, the partition key is permanent — renaming requires a data migration. Get it right.

Rules:

1. **Distribute writes evenly** — avoid hot partitions (one key with 10× the traffic of others).
2. **Co-locate read patterns** — single-partition queries are 10-100× cheaper than cross-partition fan-out.
3. **Pick from the dominant read pattern**, not the dominant write pattern (since you'll read more than you write usually).
4. **Cardinality should be high** — avoid `region` (only ~5 values); prefer `userId` / `tenantId` / `accountId`.
5. **Maximum 20 GB per logical partition** in Cosmos NoSQL. If your data per partition value exceeds 20 GB, your partition key is wrong.

**Synthetic partition keys** when natural keys don't fit: combine fields (`userId + monthBucket`) or hash (`hash(userId) % 100`). Document the formula in the schema.

**Hierarchical partition keys** (preview / partial GA depending on API): up to 3 levels (`tenantId`/`userId`/`sessionId`). Useful when you want partition-level isolation at the top with sub-partitioning beneath.

**Anti-pattern: timestamp as partition key.** All writes hit the current partition → hot partition.

**Anti-pattern: monotonically increasing ID.** Same problem.

**Anti-pattern: a single tenant ID when one tenant is 80% of traffic.** That tenant's partition is hot. Synthetic key: `tenantId + hash(documentId) % 100`.

Cite: [Cosmos DB partitioning](https://learn.microsoft.com/azure/cosmos-db/partitioning-overview).

### Cosmos DB — RU/s sizing

| Mode | When |
|------|------|
| **Manual provisioned** | You know your steady-state load and want predictable cost |
| **Autoscale provisioned** | You know roughly but want elasticity (up to 10× burst within a 1-hour window) |
| **Serverless** | Dev / test / low-traffic apps. Caps: 1 TB storage, 5000 RU/s burst |

Pricing sizing (rough heuristics, validate with [Cosmos DB capacity calculator](https://cosmos.azure.com/capacitycalculator/)):

- 1 KB document insert: ~5 RU
- 1 KB point read by PK: ~1 RU
- 1 KB cross-partition query (small): ~10-30 RU
- 1 KB vector query (DiskANN, top-10): ~10-50 RU depending on dataset
- Index update on write: doubles or triples the write cost

**Anti-pattern: starting at 400 RU/s and hoping**. 400 RU/s is enough for ~100 small reads/sec. If your throughput is higher, autoscale will save you from 429 (rate limited) errors but at variable cost. Plan with the capacity calculator.

**Anti-pattern: switching from serverless to provisioned**. Not supported in-place — requires creating a new account and migrating.

### Cosmos DB — vector search with DiskANN

DiskANN GA in 2024-25 on Cosmos NoSQL — Microsoft Research's billion-scale vector index. Predictable latency at millions of QPS.

Index types:

| Type | When |
|------|------|
| **`flat`** | Small datasets (<10K vectors), exact search, simple |
| **`quantizedFlat`** | Medium datasets (10K-1M), compressed vectors, faster |
| **`diskANN`** | Large datasets (1M+ vectors), production scale, predictable latency |

Container vector embedding policy:

```json
{
  "vectorEmbeddings": [
    {
      "path": "/embedding",
      "dataType": "float32",
      "distanceFunction": "cosine",
      "dimensions": 1536
    }
  ]
}
```

Indexing policy:

```json
{
  "vectorIndexes": [
    { "path": "/embedding", "type": "diskANN" }
  ]
}
```

Query:

```sql
SELECT TOP 10 c.id, c.title, VectorDistance(c.embedding, @queryVector) AS score
FROM c
ORDER BY VectorDistance(c.embedding, @queryVector)
```

**Anti-pattern: storing 4096-dim vectors with diskANN at scale without quantization**. DiskANN supports quantization; use it for embedding sizes >1536 to control storage cost.

**Anti-pattern: vector search across partitions without a filter**. Combine vector distance with a `WHERE c.tenantId = @tenantId` filter to limit search space — much cheaper.

Cite: [Cosmos DB vector search](https://learn.microsoft.com/azure/cosmos-db/nosql/vector-search), [DiskANN paper](https://www.microsoft.com/research/publication/diskann-fast-accurate-billion-point-nearest-neighbor-search-on-a-single-node/).

### Cosmos DB for MongoDB vCore (Azure DocumentDB)

Rebrand of Cosmos DB for MongoDB vCore in 2025 — now built on **open-source DocumentDB engine**.

| | Cosmos NoSQL | Cosmos Mongo vCore (DocumentDB) |
|---|--------------|----------------------------------|
| API | Native REST / Cosmos SDK | MongoDB 6.0+ wire protocol |
| Pricing | RU-based | Provisioned compute + storage |
| Vector search | DiskANN (native) | `$vectorSearch` operator (HNSW / IVF) |
| Mongo client compatibility | No | Yes (mongosh, drivers) |
| Multi-region writes | Yes (NoSQL) | Cluster-level (regional) |
| Best for | New apps, polyglot, when Mongo isn't required | Migrations from MongoDB Atlas / self-hosted; teams with Mongo expertise |

Cite: [Cosmos DB for MongoDB vCore](https://learn.microsoft.com/azure/cosmos-db/mongodb/vcore/).

### Azure SQL Database — tier selection

| Tier | When |
|------|------|
| **General Purpose serverless** | Dev/test, intermittent workloads (auto-pause supported) |
| **General Purpose provisioned** | Predictable load, cost-sensitive |
| **Business Critical** | High HA / low-latency (in-memory storage tier, AG always-on) |
| **Hyperscale** | Large data (up to 100 TB), fast scale-out (4 read replicas), fast backups |
| **Hyperscale Elastic Pool** | Multi-tenant SaaS with many DBs |

**Hyperscale serverless does NOT auto-pause**. Only General Purpose serverless auto-pauses. Confirm before recommending.

**Hyperscale Elastic Pools** (GA 2025-26): zone-redundant, PRMS/MOPRMS premium-series hardware, configurable maintenance windows. Best for SaaS workloads with varying demands across tenant DBs.

**Anti-pattern: defaulting to Business Critical for "best performance"**. Hyperscale generally outperforms BC for large databases and is more cost-efficient. Use BC for: in-memory OLTP requirements, sub-ms storage latency requirements, AG-style explicit replicas.

**Anti-pattern: not enabling Always Encrypted with secure enclaves for PII**. Azure SQL supports it; the cost is minimal vs the audit trail benefit.

Cite: [Azure SQL purchasing models](https://learn.microsoft.com/azure/azure-sql/database/purchasing-models).

### PostgreSQL Flexible Server — sizing + scaling

**Single Server retired March 2025**. Flexible Server is the only current managed PostgreSQL.

| Feature | Notes |
|---------|-------|
| Versions | PostgreSQL 13, 14, 15, 16 supported |
| HA | Zone-redundant HA (synchronous replica in different AZ + automatic failover) |
| Read replicas | Up to 5 async read replicas |
| Storage | Premium SSD v2 backed — configurable IOPS + throughput |
| Connection pooling | Built-in PgBouncer (transaction or session mode) |
| Extensions | pgvector, PostGIS, pg_cron, pg_stat_statements, 50+ others |
| Backups | Geo-redundant backup support |
| Maintenance | Custom maintenance windows configurable |

**Elastic Clusters (Citus)**: horizontal scale-out via Citus extension. Distribute tables by a sharding column. Replaces Cosmos DB for PostgreSQL.

```sql
SELECT create_distributed_table('orders', 'tenant_id');
```

Queries that include `tenant_id` in WHERE execute on a single shard. Queries without it fan out — expensive.

**Anti-pattern: pgvector without an HNSW or IVFFlat index**. Sequential scan over vectors is O(N) — fine for thousands, ruinous for millions. Create the index:

```sql
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

Cite: [PostgreSQL Flexible Server](https://learn.microsoft.com/azure/postgresql/flexible-server/), [Elastic Clusters (Citus)](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-elastic-clusters).

### Azure Managed Redis vs Azure Cache for Redis

The picture:

- **Azure Cache for Redis (classic)**: Basic, Standard, Premium, Enterprise, EnterpriseFlash tiers. **In migration** to Azure Managed Redis. Tooling rollout:
  - Basic/Standard/Premium: tooling from Nov 2025
  - Enterprise/EnterpriseFlash: tooling from March 2026
  - Expect brief DNS blip (seconds) during migration

- **Azure Managed Redis (new, GA)**: Redis Ltd. enterprise technology. Tiers:
  - **Compute Optimized** — burst workloads
  - **Balanced** — general-purpose
  - **Memory Optimized** — large datasets, in-memory
  - **Flash Optimized** — auto-tier cold data to NVMe; large cache at lower cost
  - SKU sizes 150 and 250 GA at Ignite 2025
  - Reserved Instances: 35% (1y) / 55% (3y) in 30+ regions
  - Features: active geo-replication, RediSearch, RedisJSON, RedisTimeSeries, RedisBloom

**Decision: new build → Azure Managed Redis.** Migrating existing classic → use Microsoft's migration tooling on its rollout schedule.

**Valkey on Azure**: no first-party managed Valkey. If license / strategic concerns require Valkey, self-host on AKS or VMs. AWS has ElastiCache Valkey; Azure does not.

Cite: [Azure Managed Redis docs](https://learn.microsoft.com/azure/azure-managed-redis/).

### Azure SQL Managed Instance

**SQL Server 2025 update policy** (GA March 2026) lets you choose:

- **Rolling latest engine features** — always on the newest
- **Fixed SQL Server 2022 feature set** — pinned, manual upgrade
- **Fixed SQL Server 2025 feature set** — pinned to 2025

SQL Server 2025 becomes the default policy in Azure portal March 2026.

Key SQL Server 2025 features on Managed Instance:

- **Vector data type + functions** — native vector ops for AI workloads
- **Optimized locking** — enabled by default for all user DBs
- **Change Event Streaming** — DML changes to Azure Event Hubs in near real-time
- **`sp_invoke_external_rest_endpoint`** — call HTTPS REST from T-SQL
- **UNISTR syntax** — Unicode string literal support

**Managed Instance Link** (GA): distributed availability group from on-prem SQL Server (2022 / 2025) to MI for hybrid DR + offload reporting. Manual failover, fail back after mitigation.

Cite: [SQL Managed Instance update policies](https://learn.microsoft.com/azure/azure-sql/managed-instance/update-policy).

### Storage tier selection (Blob)

| Tier | Min retention | Use case |
|------|---------------|----------|
| Premium (block blobs) | None | Performance-sensitive, low-latency reads |
| Hot | None | Frequently accessed |
| Cool | 30 days | Infrequent (>30 days between access) |
| Cold | 90 days | Rare access |
| Archive | 180 days | Compliance / backup |

**Lifecycle Management policies**: rules to move blobs between tiers based on `lastAccessTime` or `creationTime`; also automated deletion.

**Immutable storage (WORM)**: time-based retention policies (cannot modify/delete for X days) or legal holds (indefinite until removed). SEC 17a-4(f), CFTC 1.31, FINRA 4511 compliant. Once locked, retention can only be extended.

**Important**: `Set Blob Tier` works even with locked immutability policies (rehydration allowed), but `Delete` is blocked.

**Anti-pattern: Hot tier for archival data**. You're paying storage premium for data accessed once a year. Lifecycle policy → move to Cool / Cold / Archive after N days.

**Anti-pattern: Archive tier for data accessed monthly**. Rehydration costs + 180-day minimum retention. Cool / Cold are better.

Cite: [Blob storage access tiers](https://learn.microsoft.com/azure/storage/blobs/access-tiers-overview), [Blob lifecycle management](https://learn.microsoft.com/azure/storage/blobs/lifecycle-management-overview).

### ADLS Gen2 — when and how

Azure Data Lake Storage Gen2 = Blob Storage + Hierarchical Namespace (HNS). HNS gives you file system semantics (directories, atomic rename, POSIX ACLs).

**Critical: enable HNS at storage account creation. Cannot be enabled retroactively.**

When to use ADLS Gen2:

- Big data analytics (Spark, Databricks, Synapse, Fabric)
- Petabyte-scale data lakes
- Workloads needing POSIX ACLs + Azure RBAC
- ABFS driver target

ABFS driver: `abfss://container@account.dfs.core.windows.net/path` — optimized for big data workloads, supports recursive directory ops natively.

**Anti-pattern: standard Blob account when the workload is "we'll bring Spark to it later"**. Add HNS now; can't add later.

Cite: [ADLS Gen2](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction).

### Microsoft Fabric — when and how

GA 2024. Unified SaaS analytics platform:

- **OneLake** — unified data lake (one Lake per tenant, replicated logical view)
- **Data Engineering** — Spark notebooks
- **Data Factory** — pipelines (converging with Azure Data Factory)
- **Real-Time Intelligence** — eventstreams + KQL queries (replaces standalone Stream Analytics for new builds)
- **Data Warehouse** — T-SQL DW experience
- **Power BI** — semantic model + reports
- **Data Science** — ML on Spark
- **Databases** (preview / various) — operational data alongside analytics

**Default for new analytics work in 2026**. Synapse dedicated SQL pools still supported but stagnant; new investment in Fabric.

**OneLake shortcuts** — point at data in ADLS Gen2 / S3 / GCS without copy.

**Anti-pattern: building a new Synapse workspace in 2026**. Microsoft is investing in Fabric. Synapse maintenance only.

Cite: [Microsoft Fabric docs](https://learn.microsoft.com/fabric/).

### Azure AI Search vs Cosmos DiskANN vs pgvector

When you need vector search, pick based on the surrounding data architecture:

| | Azure AI Search | Cosmos DB DiskANN | pgvector |
|---|------------------|--------------------|----------|
| Primary use | Document search + RAG | Operational doc store + vectors | Operational RDBMS + vectors |
| Hybrid retrieval | Yes (semantic ranker) | Yes (combine with SQL filters) | Yes (combine with SQL filters) |
| Index types | HNSW + semantic | DiskANN / flat / quantized flat | HNSW / IVFFlat |
| Scale | Indexes to billions | Billions native (DiskANN) | Tens of millions practical |
| Integrated vectorization | Yes (auto-embed via Azure OpenAI) | No (compute in app) | No (compute in app) |
| Best when | Pure search / RAG over docs | Vectors alongside operational data | Vectors alongside Postgres workload |

**Decision**: if your app is "documents in, search out, RAG over them" → Azure AI Search. If your app is "we have operational data in Cosmos and want vector search on it" → Cosmos DiskANN. If your app is "we have Postgres and want vector search" → pgvector with HNSW.

**Anti-pattern: standing up a separate Pinecone / Qdrant / Weaviate on Azure when one of the above fits**. You're paying for a separate service when the platform has the capability.

### Backup + restore policy

Every production database needs a documented:

- **RPO** (Recovery Point Objective) — max acceptable data loss
- **RTO** (Recovery Time Objective) — max acceptable downtime
- **Backup retention** period
- **Restore drill** schedule (quarterly minimum)

Azure defaults to backup-aware:

- **Azure SQL**: PITR built-in (1-35 days), LTR (up to 10 years), geo-restore from geo-redundant backups.
- **Cosmos DB**: continuous backup (PITR 30 days max) or periodic (every 4h, retention 30 days).
- **PostgreSQL Flex**: PITR up to 35 days, geo-redundant backups option.
- **Managed Redis**: snapshot to Storage (RDB or AOF).
- **Blob**: soft delete + versioning + immutable storage as defense-in-depth.

**Always run a restore drill**. Tested backup is the only kind that matters.

### CDC / Change feed patterns

| Source | Mechanism |
|--------|-----------|
| Cosmos DB | Change Feed (`ChangeFeedProcessorBuilder` SDK) |
| Azure SQL | Change Data Capture (CDC) or Change Tracking |
| SQL Managed Instance 2025 | Change Event Streaming → Event Hubs |
| PostgreSQL Flex | Logical replication → Debezium → Event Hubs / Kafka |
| Blob Storage | Event Grid (`Microsoft.Storage.BlobCreated`) |

**Pattern: Cosmos Change Feed → Functions → Service Bus** — downstream consumers get domain events without coupling to Cosmos. Built-in lease management.

**Pattern: Debezium on AKS → Event Hubs Kafka surface** — for Postgres / MySQL / SQL Server CDC into a Kafka-compatible stream.

## 2025-2026 platform reset items relevant to this role

- **Cosmos DB for PostgreSQL retiring** — migrate to PostgreSQL Flex + Elastic Clusters (Citus).
- **PostgreSQL Single Server retired March 2025** — Flex only.
- **Cosmos DB DiskANN GA** — billion-scale vector index, native.
- **Cosmos DB for MongoDB vCore = Azure DocumentDB** rebrand — open-source DocumentDB engine.
- **Azure SQL Hyperscale Elastic Pools GA** — multi-tenant SaaS pattern formalized.
- **SQL Managed Instance 2025 update policy GA March 2026** — vector data type, optimized locking, Change Event Streaming.
- **Azure Managed Redis** — successor service in rollout; classic in migration.
- **Microsoft Fabric + OneLake** — default for new analytics.
- **Azure AI Search integrated vectorization** — auto-embed via Azure OpenAI without writing pipeline code.
- **Premium SSD v2** — direct conversion from Standard / Premium SSD GA; instant access snapshots.
- **Azure NetApp Files large volumes 7.2 PiB** — SAP HANA / Oracle / large analytics scale.

## Patterns and anti-patterns

### Pattern: Partition-per-tenant on Cosmos

Multi-tenant SaaS: partition key = `tenantId`. Each tenant's data co-located in a partition; queries with `WHERE tenantId = @t` are single-partition.

Limits: 20 GB per logical partition. Large tenants exceed this → use synthetic key (`tenantId + bucket`) or sharded design.

### Pattern: Outbox + Cosmos Change Feed for cross-service events

Domain events flow:

```
Service A: write to Cosmos (business doc + outbox sub-doc)
         ↓ (Cosmos change feed)
Functions / Worker → publish to Service Bus → downstream services
```

Avoids dual-write problem; events guaranteed published if the write succeeded.

### Pattern: Read replicas for read-heavy analytical queries on OLTP

Azure SQL Hyperscale supports up to 4 named read replicas. Route read-only traffic via `ApplicationIntent=ReadOnly`. PostgreSQL Flex supports up to 5 async replicas. Keep OLTP primary for transactions.

### Pattern: Cosmos serverless for unpredictable dev / test loads

Dev / test environments with low traffic — Cosmos serverless billing model fits better than provisioned. Caps at 1 TB and 5K RU/s burst, fine for dev.

### Pattern: Always Encrypted with secure enclaves for PII columns

Azure SQL Always Encrypted with secure enclaves (Intel SGX) — query encrypted columns server-side without revealing plaintext. Key custody in Key Vault or Managed HSM.

### Pattern: Premium SSD v2 for tier-1 production VMs

Independent IOPS + throughput tuning, dynamic resize, instant access snapshots. Cost-efficient vs Ultra Disk for most workloads.

### Anti-pattern: Cross-partition query as the dominant pattern

If most queries are cross-partition (no PK in WHERE), your partition key is wrong. Re-design (and migrate) before scale becomes the problem.

### Anti-pattern: Mixing OLTP and analytics on the same Azure SQL

OLTP queries get starved by analytics scans. Either: (a) named read replicas, (b) Azure Synapse Link (one-way replication to lakehouse), (c) export to Fabric for analytics.

### Anti-pattern: Storing files in DB as BLOB

Files go in Blob Storage. DB stores the URL + metadata. Otherwise: DB cost balloons, backup time balloons, query plans degrade.

### Anti-pattern: pgvector without index

Sequential scan over thousands of vectors works in dev; production scale breaks. Always create HNSW or IVFFlat index.

### Anti-pattern: Cosmos throughput at one container level when one collection is hot

Container-level RUs are shared across all logical partitions. If one container has hot + cold partitions, you over-provision. Consider database-level shared throughput when ≤25 containers and budget-sensitive; container-level when a single container needs predictable allocation.

### Anti-pattern: ADLS Gen2 without lifecycle policy

Without lifecycle rules, dev data + raw landed files accumulate forever at Hot tier. Set automated Cool/Cold/Archive transitions on raw zones.

### Anti-pattern: Single-region database for "production"

Production = paired-region geo-replication minimum. Cosmos multi-region; Azure SQL geo-replication / auto-failover groups; PostgreSQL geo-redundant backups + read replicas; Blob GRS / RA-GRS.

### Anti-pattern: Skipping the restore drill

A backup that hasn't been tested is a hope, not a strategy. Quarterly restore drill is the discipline.

## Tooling specifics

- **Azure Data Studio** — cross-platform SQL client (SQL Server, Azure SQL, Cosmos, Postgres).
- **Azure Storage Explorer** — browse Blob / Queue / Table / Cosmos / ADLS Gen2.
- **`mongosh`** — for Cosmos MongoDB vCore (Azure DocumentDB).
- **`psql`** + **pgAdmin** — for PostgreSQL Flex.
- **`redis-cli`** + **RedisInsight** — for Managed Redis.
- **Cosmos DB Migration Tool** — for source-target migrations.
- **Azure Database Migration Service (DMS)** — managed DMS for SQL → Azure SQL / MI; Oracle → Postgres; MySQL → Azure MySQL; MongoDB → Cosmos.
- **`az cosmosdb sql container throughput update`** — change RU/s without downtime.
- **`az sql db tde set`** — Transparent Data Encryption settings.
- **DataFactory + Synapse Pipelines** for batch movement; **Fabric Data Factory** for new builds.
- **dbt-azuresynapse-adapter / dbt-fabric / dbt-postgres** for transformation-as-code.

## Integration with always-on protocols

### TDD on data layer

- **Migrations as code** — use `dotnet ef`, `Flyway`, `Liquibase`, `Alembic`, or `Atlas` for schema migrations under VCS.
- **Test migrations forward + rollback** in a staging environment before prod.
- **Seed data + test data** committed alongside migrations.
- **Integration tests against ephemeral DB** (Testcontainers for Postgres / SQL; Cosmos Emulator for Cosmos).

### Verification

- `EXPLAIN` / `EXPLAIN ANALYZE` (Postgres) or `SET STATISTICS IO ON` + execution plan (SQL Server) — verify the planner uses the expected index.
- Cosmos `GetItemQueryIterator` with `PopulateIndexMetrics = true` — verify the query is partition-efficient.
- `EXPLAIN ANALYZE` on pgvector queries with the index — verify HNSW is used.
- Restore drill verification — quarterly, document the time-to-restore.

### Review

Push back on:

- Cosmos partition keys with cardinality < 100
- Cosmos cross-partition queries as the dominant pattern
- Azure SQL Business Critical chosen for "performance" without specific reason vs Hyperscale
- New PostgreSQL workload on Single Server (retired)
- New build on Cosmos DB for PostgreSQL (retiring)
- Vector search without an appropriate index (HNSW / DiskANN / IVFFlat)
- PII in databases without Always Encrypted / column-level encryption
- Production DBs without geo-replication
- Backups without a documented restore drill

### Debugging

- **Cosmos**: enable diagnostic logs, look at `RequestCharge`, `IndexingMetrics`, partition heatmap in Azure Monitor.
- **Azure SQL**: Query Performance Insight, automatic tuning, missing index recommendations.
- **PostgreSQL**: `pg_stat_statements`, slow query log, `pg_stat_activity` for blocking sessions.
- **Managed Redis**: slow log, latency commands (`LATENCY DOCTOR`, `LATENCY HISTORY`).

Root cause workflow:

1. Identify the slow query / hot partition / failing migration via metrics.
2. Reproduce in dev with realistic data shape.
3. Hypothesize one cause (partition key, missing index, statistics out of date).
4. Test with one change.
5. Confirm in metrics.

## Cross-references to products_covered

| Product | Role usage |
|---------|------------|
| `Cosmos DB for NoSQL` | Document NoSQL + vector |
| `Cosmos DB for MongoDB vCore` | Mongo-compatible workloads |
| `Cosmos DB for PostgreSQL` | RETIRING — push migration |
| `Azure SQL Database` | OLTP + Hyperscale + Elastic Pools |
| `Azure SQL Managed Instance` | Lift-and-shift SQL Server |
| `PostgreSQL Flexible Server` | Managed Postgres + Citus Elastic |
| `Azure Managed Redis` | Cache / session |
| `Storage Accounts` / `Blob Storage` | Object storage with tiers |
| `ADLS Gen2` | Data lake for analytics |
| `Azure NetApp Files` | High-perf NAS, SAP HANA |
| `Microsoft Fabric` | Unified analytics |
| `Synapse Analytics` | Legacy analytics |
| `Azure Data Factory` | ETL orchestration |
| `Azure Databricks` | Lakehouse / advanced analytics |
| `Azure AI Search` | Vector + hybrid retrieval for RAG |
| `Microsoft Purview` | Data classification + lineage |

## When to refresh this overlay

- Cosmos DB feature GA (DiskANN evolution, hierarchical PK)
- New PostgreSQL Flex version support
- SQL Managed Instance update policy default change
- Azure Managed Redis tier expansion or Azure Cache for Redis migration phase
- Fabric workload expansion (new GA experiences)
- New AI Search retrieval features (semantic ranker, integrated vectorization)
- Backup / restore feature change

Target refresh cadence: every 6 months; sooner on Cosmos / SQL feature GAs.
