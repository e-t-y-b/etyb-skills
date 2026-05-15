---
title: PostgreSQL Flexible Server
description: Managed Postgres on Azure. Single Server retired March 2025. Elastic Clusters (Citus) GA replaces retiring Cosmos DB for PostgreSQL. pgvector native. PgBouncer built-in.
product:
  name: PostgreSQL Flexible Server
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, saas-architect, ai-ml-engineer]
  authoritative_url: https://learn.microsoft.com/azure/postgresql/flexible-server/
  notes: "Single Server retired Mar 2025; Elastic Clusters (Citus) GA replaces retiring Cosmos DB for PostgreSQL."
---

## What it is

Azure Database for PostgreSQL Flexible Server is Microsoft's current managed PostgreSQL — Postgres 13-16, zone-redundant HA, async read replicas, built-in PgBouncer, 50+ extensions including pgvector, PostGIS, pg_cron. **Elastic Clusters (Citus)** add horizontal scale-out via the Citus extension. Canonical reference: [PostgreSQL Flexible Server docs](https://learn.microsoft.com/azure/postgresql/flexible-server/).

## When to use

Pick PostgreSQL Flexible Server when:

- **OLTP relational with Postgres preferred** — team is Postgres-native; ecosystem of extensions and tooling matters.
- **pgvector** for AI workloads with vectors alongside operational data.
- **Citus Elastic Clusters** for horizontal scale-out (replaces retiring [Cosmos DB for PostgreSQL](/stacks/azure/cosmos-db/)).

Pick [Azure SQL](/stacks/azure/azure-sql/) when team is SQL Server-native or you need SQL Server feature parity.

## 2025-2026 currency anchors

- **Single Server retired March 2025.** Only Flexible Server is current.
- **Elastic Clusters (Citus)** GA — distribute tables by sharding column; replaces retiring **Cosmos DB for PostgreSQL**.
- **PostgreSQL versions supported (2026-Q2)**: 13, 14, 15, 16.
- **Zone-redundant HA** — synchronous standby in different AZ + automatic failover.
- **Up to 5 async read replicas.**
- **Storage**: Premium SSD v2 backed — independent IOPS + throughput tuning.
- **Built-in PgBouncer** — `pooler_mode = transaction` for short-lived high-concurrency connections.
- **pgvector** native — supports HNSW + IVFFlat indexes.
- **Custom maintenance windows** configurable.
- **Geo-redundant backups** option (separate from HA).
- **Entra authentication** — eliminates password rotation chore.

## Patterns + anti-patterns

### Pattern: Citus Elastic Cluster for tenant-sharded distribution

```sql
SELECT create_distributed_table('orders', 'tenant_id');
```

Queries that include `tenant_id` in WHERE execute on a single shard. Queries without it fan out — expensive.

### Pattern: pgvector with HNSW index

```sql
CREATE EXTENSION vector;
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);

SELECT id, content
FROM documents
WHERE tenant_id = $1
ORDER BY embedding <=> $2
LIMIT 10;
```

HNSW for large datasets (tens of millions); IVFFlat for medium with periodic re-index. **Always** create the index — sequential scan is O(N).

### Pattern: PgBouncer transaction mode for high-concurrency apps

App connections → PgBouncer (transaction mode) → small pool to Postgres. Avoid connection exhaustion under burst.

### Pattern: Entra authentication

`psql` with `Authentication=ActiveDirectoryDefault` connection params; app uses Managed Identity. No password to rotate.

### Pattern: Read replicas for read-heavy reporting

Up to 5 async replicas. Route read-only traffic via `target_session_attrs=read-only` (libpq) or app-level routing.

### Anti-pattern: Cosmos DB for PostgreSQL on new build

Retiring. Use Postgres Flex + Elastic Clusters (Citus). Same Citus extension underneath.

### Anti-pattern: pgvector without an index

Sequential scan over thousands works in dev; production scale breaks. Always HNSW or IVFFlat.

### Anti-pattern: Postgres Single Server

Retired March 2025. Migrate.

### Anti-pattern: Long-lived connections without PgBouncer

App opens 1000 connections; Postgres caps; idle ones starve real work. PgBouncer transaction mode pools.

## Gotchas

- **Single Server vs Flexible Server vs Cosmos for PostgreSQL** — three separate Azure offerings. Single Server is retired (March 2025); Cosmos for PostgreSQL is retiring; **Flexible Server** is the future. Clarify which service is in scope.
- **Citus distribution column choice is critical** — all queries should include it in WHERE for single-shard execution. Cross-shard is expensive.
- **pgvector dimension limits** — practical caps depend on extension version; verify for your embedding model.
- **Maintenance windows** — configurable; don't accept defaults blindly for production.
- **Server-level vs database-level Entra admins** — distinct roles; configure both for access.

## Cross-references

- [Cosmos DB](/stacks/azure/cosmos-db/) — what to migrate FROM (Cosmos for PostgreSQL retiring)
- [Azure SQL](/stacks/azure/azure-sql/) — SQL Server alternative
- [Azure AI Search](/stacks/azure/ai-search/) — alternative vector store
- [Database Architect on Azure](/stacks/azure/database-architect/) — sizing + scaling
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — connection management
- [SaaS Architect on Azure](/stacks/azure/saas-architect/) — schema-per-tenant + Citus distribution patterns
- [PostgreSQL Flexible Server](https://learn.microsoft.com/azure/postgresql/flexible-server/)
- [Elastic Clusters (Citus)](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-elastic-clusters)
