---
title: Database Architect on Azure
description: Data tier design, partition keys, indexing, replication, migration. Cosmos DiskANN, Hyperscale Elastic Pools, PostgreSQL Flex + Citus, Azure Managed Redis, Fabric / OneLake.
role_overlay:
  role: database-architect
  stack: azure
  last_verified_on: "2026-05-14"
  products_covered:
    - cosmos-db
    - azure-sql
    - postgresql-flexible-server
    - azure-managed-redis
    - storage-account
    - microsoft-fabric
    - synapse-analytics
    - data-factory
    - ai-search
    - microsoft-purview
    - event-hubs
---

## Role briefing

You pick the data tier, the schema, the indexing, the partitioning, the replication, the migration path. This view tells you what Azure 2026 provides, where the sharp edges are, and what migrations are happening underneath you.

You don't write SDK code ([backend-architect](/stacks/azure/backend-architect/)) or IaC ([devops-engineer](/stacks/azure/devops-engineer/)) — you own the data design and the operational discipline around it.

## Decision frameworks specific to this role's lens on Azure

### Database selection

| Workload | Pick |
|----------|------|
| OLTP, single/paired region, T-SQL | [Azure SQL Database Hyperscale](/stacks/azure/azure-sql/) |
| OLTP, multi-tenant SaaS, many small DBs | [Azure SQL Hyperscale Elastic Pools](/stacks/azure/azure-sql/) |
| OLTP, PostgreSQL preferred | [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/) |
| Horizontally scalable Postgres | [PostgreSQL Flex + Elastic Clusters (Citus)](/stacks/azure/postgresql-flexible-server/) — replaces retiring Cosmos for PG |
| Document NoSQL, global, vector | [Cosmos DB for NoSQL (DiskANN)](/stacks/azure/cosmos-db/) |
| MongoDB-compatible | [Cosmos DB for MongoDB vCore (Azure DocumentDB)](/stacks/azure/cosmos-db/) |
| Cassandra-compatible | Cosmos DB for Cassandra (CQL wire) |
| Graph DB | Cosmos DB for Gremlin (Apache Gremlin + TinkerPop) |
| Cache / session | [Azure Managed Redis](/stacks/azure/azure-managed-redis/) |
| Time-series / log / IoT analytics | Azure Data Explorer (Kusto) |
| Data lake | ADLS Gen2 (HNS on [Storage Account](/stacks/azure/storage-account/)) |
| Unified analytics | [Microsoft Fabric + OneLake](/stacks/azure/microsoft-fabric/) |
| Vector / embedding store for search | [Azure AI Search](/stacks/azure/ai-search/) |
| FHIR R4 healthcare | Azure Health Data Services (see [healthcare-architect on Azure](/stacks/azure/healthcare-architect/)) |

### Cosmos DB partition key design

**Most important decision you'll make.** Once you create a container, the partition key is permanent — renaming requires data migration.

Rules:

1. **Distribute writes evenly** — avoid hot partitions.
2. **Co-locate read patterns** — single-partition queries are 10-100× cheaper than cross-partition fan-out.
3. **Pick from dominant read pattern**, not write pattern.
4. **High cardinality** — avoid `region` (~5 values); prefer `userId` / `tenantId` / `accountId`.
5. **Max 20 GB per logical partition.** Exceeding → wrong partition key.

**Synthetic partition keys** when natural keys don't fit: `userId + monthBucket` or `hash(userId) % 100`. Document the formula.

**Hierarchical partition keys** (preview / partial GA) — up to 3 levels.

Anti-patterns: timestamp as partition key (hot partition); monotonically increasing ID; single tenant ID when one tenant is 80% of traffic.

See [Cosmos DB](/stacks/azure/cosmos-db/) for full coverage.

### Cosmos DB RU/s sizing

| Mode | When |
|------|------|
| Manual provisioned | Known steady-state, predictable cost |
| Autoscale provisioned | Roughly known, want elasticity (up to 10× burst within 1h) |
| Serverless | Dev / test / low-traffic. Caps: 1 TB, 5K RU/s burst |

Rough heuristics (validate with [capacity calculator](https://cosmos.azure.com/capacitycalculator/)):

- 1 KB doc insert: ~5 RU
- 1 KB point read by PK: ~1 RU
- 1 KB cross-partition query: ~10-30 RU
- 1 KB DiskANN vector query (top-10): ~10-50 RU
- Index update on write: doubles or triples write cost

### Cosmos DB vector search with DiskANN

Index types:

| Type | When |
|------|------|
| `flat` | < 10K vectors, exact search |
| `quantizedFlat` | 10K-1M, compressed, faster |
| `diskANN` | 1M+, production scale, predictable latency |

Container vector embedding policy + indexing policy declare path + dimensions + distance + type. See [Cosmos DB](/stacks/azure/cosmos-db/) for the JSON specs.

**Always filter by partition before vector distance.** Searching across all partitions is expensive; filtered search within is cheap.

### Azure SQL Database tier selection

| Tier | When |
|------|------|
| General Purpose serverless | Dev/test, intermittent (auto-pause supported) |
| General Purpose provisioned | Predictable, cost-sensitive |
| Business Critical | High HA / low-latency (in-memory tier, AG always-on) |
| Hyperscale | Large (100 TB), fast scale-out (4 read replicas), fast backups |
| Hyperscale Elastic Pool | Multi-tenant SaaS with many DBs |

**Hyperscale serverless does NOT auto-pause.** Only General Purpose serverless does.

**Anti-pattern: defaulting to Business Critical for "best performance"** — Hyperscale usually outperforms BC for large DBs at lower cost.

### PostgreSQL Flexible Server sizing + scaling

**Single Server retired March 2025.** Only Flex is current. Zone-redundant HA, up to 5 async read replicas, Premium SSD v2, built-in PgBouncer, 50+ extensions including pgvector + PostGIS + pg_cron.

**Elastic Clusters (Citus)** horizontal scale-out. Distribute tables by sharding column:

```sql
SELECT create_distributed_table('orders', 'tenant_id');
```

Queries with `tenant_id` in WHERE → single-shard. Without → fan out (expensive).

**Anti-pattern: pgvector without HNSW or IVFFlat index.** Sequential scan is O(N). Always:

```sql
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

### Azure Managed Redis vs Azure Cache for Redis

**New build → [Azure Managed Redis](/stacks/azure/azure-managed-redis/).** Classic Azure Cache for Redis is in migration tooling rollout (Basic/Standard/Premium Nov 2025; Enterprise/EnterpriseFlash March 2026).

No first-party managed Valkey on Azure. Self-host on AKS if Valkey is required.

### SQL Managed Instance — SQL Server 2025 update policy (GA March 2026)

Choose:

- **Rolling latest engine features** — always newest.
- **Fixed SQL Server 2022 feature set** — pinned, manual upgrade.
- **Fixed SQL Server 2025 feature set** — pinned to 2025.

SQL Server 2025 features: vector data type, optimized locking default-on, Change Event Streaming → Event Hubs, `sp_invoke_external_rest_endpoint`, UNISTR syntax.

### Storage tier selection (Blob)

| Tier | Min retention | Use case |
|------|---------------|----------|
| Premium | None | Performance-sensitive, low-latency |
| Hot | None | Frequently accessed |
| Cool | 30 days | Infrequent (>30 days between access) |
| Cold | 90 days | Rare access |
| Archive | 180 days | Compliance / backup |

Lifecycle Management policies automate tier transitions. Immutable storage (WORM) for compliance — SEC 17a-4(f) / CFTC 1.31 / FINRA 4511. See [Storage Account](/stacks/azure/storage-account/).

### ADLS Gen2

**HNS at create only — cannot enable retroactively.** Foundation for Fabric / Synapse / Databricks. ABFS driver `abfss://container@account.dfs.core.windows.net/path`.

### Microsoft Fabric

**Default for new analytics work in 2026.** [Synapse Analytics](/stacks/azure/synapse-analytics/) is maintenance. See [Microsoft Fabric](/stacks/azure/microsoft-fabric/).

### Vector store: AI Search vs Cosmos DiskANN vs pgvector

| | [Azure AI Search](/stacks/azure/ai-search/) | [Cosmos DB DiskANN](/stacks/azure/cosmos-db/) | [pgvector](/stacks/azure/postgresql-flexible-server/) |
|---|---|---|---|
| Primary use | Doc search + RAG | Operational doc store + vectors | Operational RDBMS + vectors |
| Hybrid retrieval | Yes (semantic ranker) | Yes (with SQL filters) | Yes (with SQL filters) |
| Index | HNSW + semantic | DiskANN / flat / quantized | HNSW / IVFFlat |
| Scale | Billions | Billions native | Tens of millions |
| Integrated vectorization | Yes (auto-embed via Azure OpenAI) | No | No |

**Anti-pattern: standalone Pinecone / Qdrant on Azure when one of the above fits.**

### Backup + restore policy

Every production DB needs documented RPO + RTO + retention + restore drill (quarterly minimum).

- **Azure SQL**: PITR built-in (1-35 days), LTR (10 years), geo-restore.
- **Cosmos DB**: continuous (PITR 30 days) or periodic (4h, retention 30 days).
- **PostgreSQL Flex**: PITR up to 35 days, geo-redundant backups option.
- **Managed Redis**: snapshot to Storage (RDB / AOF).
- **Blob**: soft delete + versioning + immutable storage as defense in depth.

**Tested backup is the only kind that matters.**

### CDC / Change feed patterns

| Source | Mechanism |
|--------|-----------|
| [Cosmos DB](/stacks/azure/cosmos-db/) | Change Feed (`ChangeFeedProcessorBuilder` SDK) |
| Azure SQL | CDC or Change Tracking |
| SQL MI 2025 | Change Event Streaming → [Event Hubs](/stacks/azure/event-hubs/) |
| [PostgreSQL Flex](/stacks/azure/postgresql-flexible-server/) | Logical replication → Debezium → Event Hubs / Kafka |
| Blob | Event Grid (`Microsoft.Storage.BlobCreated`) |

## 2025-2026 platform-reset items relevant to this role

- **Cosmos DB for PostgreSQL retiring** — migrate to Postgres Flex + Citus.
- **PostgreSQL Single Server retired March 2025** — Flex only.
- **Cosmos DB DiskANN GA** — billion-scale vector index native.
- **Cosmos DB for MongoDB vCore = Azure DocumentDB** rebrand.
- **Azure SQL Hyperscale Elastic Pools GA** — SaaS pattern formalized.
- **SQL MI 2025 update policy GA March 2026** — vector data type, optimized locking, Change Event Streaming.
- **Azure Managed Redis** rollout; classic in migration.
- **Microsoft Fabric + OneLake** default for new analytics.
- **Azure AI Search integrated vectorization** GA.
- **Premium SSD v2** — direct conversion + instant access snapshots.

## Patterns the role applies

### Pattern: Partition-per-tenant on Cosmos

Multi-tenant SaaS — partition key = `tenantId`. Large tenants: synthetic key (`tenantId + bucket`). See [SaaS Architect on Azure](/stacks/azure/saas-architect/).

### Pattern: Outbox + Cosmos Change Feed for cross-service events

Service A writes business doc + outbox sub-doc to Cosmos; Change Feed → Functions → Service Bus → downstream. Avoids dual-write.

### Pattern: Read replicas for analytics on OLTP

Hyperscale 4 read replicas; PostgreSQL Flex 5 async replicas. `ApplicationIntent=ReadOnly` (SQL) or read-only routing (Postgres) for reporting.

### Pattern: Always Encrypted with secure enclaves for PII

Azure SQL Always Encrypted (Intel SGX) — server-side query on encrypted columns. Key in Key Vault / Managed HSM.

### Pattern: Premium SSD v2 for tier-1 production VMs

Independent IOPS + throughput, dynamic resize, instant snapshots. Cost-efficient vs Ultra Disk for most workloads.

### Anti-pattern: Cross-partition query as the dominant Cosmos pattern

Re-design before scale becomes the problem.

### Anti-pattern: Mixing OLTP and analytics on the same Azure SQL

OLTP queries get starved. Named read replicas, Azure Synapse Link, or export to Fabric.

### Anti-pattern: Files in DB as BLOB

Files in Blob Storage; DB stores URL + metadata.

### Anti-pattern: pgvector without index

Always HNSW or IVFFlat.

### Anti-pattern: Single-region database for "production"

Production = paired-region geo-replication minimum.

### Anti-pattern: Skipping the restore drill

A backup that hasn't been tested is a hope.

## Integration with always-on protocols

### TDD on data layer

- **Migrations as code** — `dotnet ef`, Flyway, Liquibase, Alembic, Atlas under VCS.
- **Test migrations forward + rollback** in staging before prod.
- **Integration tests against ephemeral DB** — Testcontainers (Postgres / SQL); Cosmos Emulator.

### Verification

- `EXPLAIN ANALYZE` (Postgres) or execution plan (SQL Server) — verify planner uses expected index.
- Cosmos `PopulateIndexMetrics = true` — verify partition efficiency.
- pgvector query: verify HNSW used.
- Restore drill quarterly; document time-to-restore.

### Review

Push back on:

- Cosmos partition keys with cardinality < 100.
- Cosmos cross-partition queries as dominant.
- Azure SQL Business Critical chosen for "performance" without specific reason vs Hyperscale.
- New PostgreSQL on Single Server (retired).
- New build on Cosmos DB for PostgreSQL (retiring).
- Vector search without HNSW / DiskANN / IVFFlat.
- PII in DB without Always Encrypted / column-level.
- Production DBs without geo-replication.
- Backups without documented restore drill.

### Debugging

- **Cosmos**: diagnostic logs, `RequestCharge`, `IndexingMetrics`, partition heatmap.
- **Azure SQL**: Query Performance Insight, automatic tuning, missing index recommendations.
- **PostgreSQL**: `pg_stat_statements`, slow query log, `pg_stat_activity`.
- **Managed Redis**: slow log, `LATENCY DOCTOR`.

## Cross-references

- [Backend Architect on Azure](/stacks/azure/backend-architect/) — SDK patterns
- [System Architect on Azure](/stacks/azure/system-architect/) — data tier selection in context
- [SaaS Architect on Azure](/stacks/azure/saas-architect/) — multi-tenant data design
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — vector store selection
- [Healthcare Architect on Azure](/stacks/azure/healthcare-architect/) — FHIR data design
- [Azure Stack index](/stacks/azure/)
- [Cosmos DB partitioning](https://learn.microsoft.com/azure/cosmos-db/partitioning-overview)
- [SQL Managed Instance update policies](https://learn.microsoft.com/azure/azure-sql/managed-instance/update-policy)
- [PostgreSQL Flexible Server](https://learn.microsoft.com/azure/postgresql/flexible-server/)
