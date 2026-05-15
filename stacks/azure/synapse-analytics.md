---
title: Synapse Analytics
description: Legacy analytics platform. Stagnant — new analytics work shifts to Microsoft Fabric. Dedicated SQL pools still supported but not where Microsoft is investing.
product:
  name: Synapse Analytics
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, system-architect]
  authoritative_url: https://learn.microsoft.com/azure/synapse-analytics/
  notes: "Maintenance mode; investment shifting to Microsoft Fabric for new analytics work."
---

## What it is

Azure Synapse Analytics is the previous-generation unified analytics platform — SQL pools (dedicated + serverless), Spark pools, pipelines (similar to ADF), Synapse Link (one-way replication from operational stores). Canonical reference: [Synapse docs](https://learn.microsoft.com/azure/synapse-analytics/).

## When to use

**Don't pick Synapse for new analytics work.** Microsoft is investing in [Fabric](/stacks/azure/microsoft-fabric/).

Use Synapse only when:

- **Existing Synapse investment** — keep operating; migrate to Fabric when worth doing.
- **Synapse Link** is the established CDC path to lakehouse for a specific workload (Fabric mirroring is the equivalent for new builds).

## 2025-2026 currency anchors

- **Stagnant** — new analytics work shifts to Fabric.
- **Dedicated SQL pools** still supported.
- **Serverless SQL pools** still useful for ad-hoc query over ADLS.
- **Synapse Link** for operational-to-analytical replication is being subsumed by Fabric mirroring patterns.

## Patterns + anti-patterns

### Pattern: Keep existing Synapse workspaces operating

If your org has Synapse in production, don't rush migration. Document the migration path; do it when there's business justification.

### Pattern: Synapse Link as the existing CDC path

For workloads already using Synapse Link from Cosmos / SQL → Synapse, keep until migration. For new CDC-to-lakehouse, use Fabric mirroring + OneLake.

### Anti-pattern: New Synapse workspace in 2026

Use [Fabric](/stacks/azure/microsoft-fabric/) instead.

### Anti-pattern: Treating Synapse as future-proof

Maintenance mode. Plan exits over time.

## Gotchas

- **Dedicated vs serverless SQL pools** — different cost models; different sizing.
- **Migration path to Fabric** is evolving; check current docs before committing.

## Cross-references

- [Microsoft Fabric](/stacks/azure/microsoft-fabric/) — successor platform
- [Data Factory](/stacks/azure/data-factory/) — ETL orchestrator
- [Storage Account](/stacks/azure/storage-account/) — ADLS Gen2 foundation
- [Database Architect on Azure](/stacks/azure/database-architect/) — analytics platform selection
- [Synapse Analytics docs](https://learn.microsoft.com/azure/synapse-analytics/)
