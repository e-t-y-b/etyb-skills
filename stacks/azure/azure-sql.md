---
title: Azure SQL
description: Azure SQL Database + Managed Instance — Hyperscale, Hyperscale Elastic Pools, SQL Server 2025 update policy on MI (GA March 2026). Hyperscale serverless does NOT auto-pause.
product:
  name: Azure SQL Database
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, saas-architect, system-architect]
  authoritative_url: https://learn.microsoft.com/azure/azure-sql/
  notes: "Hyperscale Elastic Pools GA; SQL Server 2025 on MI default March 2026; Single Server retired."
---

## What it is

Azure SQL is Microsoft's family of managed SQL Server services: **Azure SQL Database** (PaaS), **Azure SQL Managed Instance** (lift-and-shift compat), and **SQL Server on Azure VMs** (full control). Canonical reference: [Azure SQL docs](https://learn.microsoft.com/azure/azure-sql/).

## When to use

Pick **Azure SQL Database (Hyperscale)** when:

- OLTP, T-SQL preferred.
- Storage may grow to 100 TB.
- Need fast scale-out (up to 4 named read replicas) and fast backups.

Pick **Azure SQL Hyperscale Elastic Pools** when:

- Multi-tenant SaaS with many small tenant DBs.
- Want zone-redundant pool with per-DB autonomy.

Pick **Managed Instance** when:

- Lift-and-shift from on-prem SQL Server with feature parity needs (SQL Agent, CLR, cross-DB queries, Service Broker).
- Need SQL Server 2025 features (vector data type, optimized locking, Change Event Streaming).

Pick **PostgreSQL** instead when team is Postgres-native — use [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/).

## 2025-2026 currency anchors

- **Hyperscale Elastic Pools GA** (2025-26) — pool Hyperscale DBs, share compute, zone-redundant, PRMS/MOPRMS premium hardware. Sweet spot for B2B SaaS.
- **SQL Server 2025 update policy on Managed Instance** GA March 2026 — choose: latest engine features (rolling), fixed SQL Server 2022, or fixed SQL Server 2025 feature set per instance.
- **SQL Server 2025 features on MI**: native **vector data type + functions**, **optimized locking** default-on, **Change Event Streaming** to Event Hubs, `sp_invoke_external_rest_endpoint`, UNISTR syntax.
- **Managed Instance Link** (GA) — distributed availability group from on-prem SQL Server (2022 / 2025) to MI for hybrid DR + reporting offload.
- **Hyperscale serverless does NOT auto-pause.** Only General Purpose serverless auto-pauses. Verify tier before recommending serverless for intermittent load.
- **Always Encrypted with secure enclaves** (Intel SGX) for PII column-level encryption with server-side query.

## Patterns + anti-patterns

### Pattern: Hyperscale for default OLTP

Storage auto-grow to 100 TB, near-instant backups, up to 4 named read replicas. Generally outperforms Business Critical for large DBs at lower cost.

### Pattern: Hyperscale Elastic Pool for SaaS DB-per-tenant

```bicep
resource pool 'Microsoft.Sql/servers/elasticPools@2023-08-01-preview' = {
  parent: server
  name: 'tenant-pool'
  sku: { name: 'HyperscaleElasticPool', tier: 'Hyperscale', capacity: 8 }
  properties: {
    perDatabaseSettings: { minCapacity: 0.25, maxCapacity: 4 }
    zoneRedundant: true
  }
}
```

Per-tenant Hyperscale DB inside pool; shared compute; per-DB autonomy. See [SaaS Architect on Azure](/stacks/azure/saas-architect/).

### Pattern: Read replicas for read-heavy reporting

`ApplicationIntent=ReadOnly` connection string routes to a read replica. Keep primary for transactions.

### Pattern: Managed Identity auth

`Server=...;Database=...;Authentication=Active Directory Default;` with `Microsoft.Data.SqlClient`. App's Managed Identity gets a Entra token; no SQL auth password to rotate.

### Pattern: Retry with backoff via EF Core

```csharp
opts.UseSqlServer(connectionString, sqlOpts => {
    sqlOpts.EnableRetryOnFailure(maxRetryCount: 5, maxRetryDelay: TimeSpan.FromSeconds(30), errorNumbersToAdd: null);
});
```

Transient SQL failures (connection drops, throttling) auto-retry.

### Anti-pattern: Hyperscale serverless expecting auto-pause

Only General Purpose serverless auto-pauses. Hyperscale doesn't. Confirm tier before recommending serverless for intermittent workloads.

### Anti-pattern: Defaulting to Business Critical for "best performance"

Hyperscale generally outperforms BC for large DBs and is cost-efficient. Use BC for: in-memory OLTP, sub-ms storage latency, AG-style explicit replicas.

### Anti-pattern: SQL Auth in production

Entra authentication; eliminate password rotation chore.

### Anti-pattern: PII in databases without column-level encryption

Always Encrypted with secure enclaves supports server-side queries on encrypted columns. Cost is minimal vs the audit benefit.

## Gotchas

- **Backup retention** — PITR (1-35 days default), LTR (up to 10 years), geo-restore from geo-redundant backups. Configure per environment.
- **Single Server retired March 2025** — but that's PostgreSQL Single Server, not Azure SQL Single Database. Azure SQL DB itself is fine.
- **Old Azure SQL DB tiers** (Web / Business) retired long ago — verify you're on current Service Tier model (DTU or vCore).
- **Hyperscale Elastic Pool max DB count** — check current limits; > 5000 per pool is a planning event.
- **Read replicas** in Hyperscale are asynchronous; small replication lag.

## Cross-references

- [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/) — Postgres alternative
- [Cosmos DB](/stacks/azure/cosmos-db/) — NoSQL alternative
- [Event Hubs](/stacks/azure/event-hubs/) — SQL MI Change Event Streaming target
- [Database Architect on Azure](/stacks/azure/database-architect/) — tier selection, sizing
- [SaaS Architect on Azure](/stacks/azure/saas-architect/) — Hyperscale Elastic Pool for tenant DBs
- [Azure SQL purchasing models](https://learn.microsoft.com/azure/azure-sql/database/purchasing-models)
- [SQL Managed Instance update policies](https://learn.microsoft.com/azure/azure-sql/managed-instance/update-policy)
