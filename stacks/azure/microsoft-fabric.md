---
title: Microsoft Fabric
description: Unified analytics SaaS (GA 2024). OneLake unified data lake. Subsumes Power BI Premium + parts of Synapse / Data Factory for new builds. Synapse is in maintenance.
product:
  name: Microsoft Fabric
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer, system-architect]
  authoritative_url: https://learn.microsoft.com/fabric/
  notes: "GA 2024; default for new analytics work; Synapse Analytics is in maintenance mode."
---

## What it is

Microsoft Fabric is the unified SaaS analytics platform — OneLake (single tenant-scoped data lake), Data Engineering (Spark), Data Factory (pipelines), Real-Time Intelligence (eventstreams + KQL), Data Warehouse (T-SQL), Power BI (semantic model + reports), Data Science (ML on Spark), Databases (preview). GA 2024. Canonical reference: [Fabric docs](https://learn.microsoft.com/fabric/).

## When to use

Pick Fabric when:

- **New analytics work** — BI, data engineering, data science.
- **Unified platform** — one billing, one identity, one storage (OneLake).
- **Power BI workloads** — semantic models + reports + data flows.
- **Real-time intelligence** — eventstreams from Event Hubs + KQL queries (replaces standalone Stream Analytics for new builds).

Don't pick Fabric for:

- **Operational data store** — Fabric is analytics, not OLTP.
- **Existing Synapse investment** — keep it; just don't build new on Synapse.

## 2025-2026 currency anchors

- **GA 2024.**
- **OneLake** — one Lake per tenant, replicated logical view.
- **Subsumes Power BI Premium** + parts of [Synapse Analytics](/stacks/azure/synapse-analytics/) and [Data Factory](/stacks/azure/data-factory/) for new builds.
- **Synapse Analytics** is in maintenance — dedicated SQL pools still supported but Microsoft is investing in Fabric.
- **OneLake shortcuts** — point at data in [ADLS Gen2](/stacks/azure/storage-account/) / S3 / GCS without copy.
- **Fabric Data Factory** experience converges with Azure Data Factory.
- **Real-Time Intelligence** (eventstreams + KQL) replaces standalone Stream Analytics for new builds.

## Patterns + anti-patterns

### Pattern: Default for new analytics

New BI / DE / DS work starts on Fabric, not Synapse.

### Pattern: OneLake shortcuts for federated data

Point at data in ADLS Gen2 / S3 / GCS without copying. Useful for multi-cloud + on-prem federated views.

### Pattern: Real-Time Intelligence for streaming analytics

Eventstreams from Event Hubs → KQL queries → live dashboards. Replaces standalone Stream Analytics for new builds.

### Pattern: Fabric Data Factory for new ETL

If starting fresh, Fabric Data Factory is where Microsoft is investing. Existing Azure Data Factory pipelines can migrate to Fabric when worth doing.

### Anti-pattern: New Synapse workspace in 2026

Microsoft is investing in Fabric. Synapse is maintenance.

### Anti-pattern: Building a new lakehouse without OneLake

If you're on Azure and starting fresh, OneLake is the canonical lake.

### Anti-pattern: Treating Fabric as operational store

Analytics platform, not OLTP. Use [Azure SQL](/stacks/azure/azure-sql/) / [Cosmos DB](/stacks/azure/cosmos-db/) / [PostgreSQL Flex](/stacks/azure/postgresql-flexible-server/) for operational.

## Gotchas

- **Capacity model** — Fabric capacities (F2-F2048) are the billing unit; sizing affects performance.
- **OneLake shortcut latency** vs copy — federated reads have network cost.
- **Power BI Premium subsumed** — existing Premium workloads migrate to Fabric capacities.
- **Fabric vs Azure Databricks on Azure** — both are valid; choice depends on team skills + Lakehouse Federation needs.

## Cross-references

- [Synapse Analytics](/stacks/azure/synapse-analytics/) — legacy analytics platform
- [Data Factory](/stacks/azure/data-factory/) — ETL orchestrator
- [Storage Account](/stacks/azure/storage-account/) — ADLS Gen2 foundation
- [Event Hubs](/stacks/azure/event-hubs/) — eventstreams source
- [Database Architect on Azure](/stacks/azure/database-architect/) — analytics tier selection
- [Microsoft Fabric docs](https://learn.microsoft.com/fabric/)
