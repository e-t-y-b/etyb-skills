---
title: Data Factory
description: Azure Data Factory — still primary orchestrator outside Fabric. Fabric Data Factory experience converging. ETL/ELT pipelines, mapping data flows, 90+ connectors.
product:
  name: Azure Data Factory
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, devops-engineer]
  authoritative_url: https://learn.microsoft.com/azure/data-factory/
  notes: "Primary ETL orchestrator outside Fabric; Fabric Data Factory experience converging."
---

## What it is

Azure Data Factory (ADF) is the managed ETL/ELT orchestrator — pipelines, mapping data flows (Spark-based transformations), 90+ connectors to cloud + on-prem data sources, integration runtimes. Canonical reference: [Data Factory docs](https://learn.microsoft.com/azure/data-factory/).

## When to use

Pick ADF when:

- **Existing ADF investment** — keep operating; mature ETL platform.
- **Operational orchestration outside Fabric** — your data lands somewhere else (Snowflake, on-prem, third-party warehouse).
- **Mapping data flows** for visual ELT transformations.

For new analytics work, the **Fabric Data Factory experience** is converging — same workflow author can run in either; prefer Fabric for new analytics-platform-resident work.

## 2025-2026 currency anchors

- **Still primary orchestrator outside Fabric.**
- **Fabric Data Factory experience converging** — author once, run in either.
- **Self-Hosted Integration Runtime** for on-prem source/sink.
- **Managed VNet Integration Runtime** for private-network sinks.
- **Linked services with Managed Identity** auth — eliminate SP secrets.
- **Mapping data flows** scale via Spark cluster behind the scenes.

## Patterns + anti-patterns

### Pattern: Managed Identity for all linked services

Default auth model. Eliminates per-pipeline secrets.

### Pattern: Self-Hosted IR for on-prem sources

When source is on-prem and can't reach Azure directly. Install SHIR on a domain-joined Windows server with reach to the source DB.

### Pattern: ADF as the orchestrator, Spark as the executor

Pipeline triggers a Synapse / Databricks / Fabric notebook for heavy lift; ADF orchestrates the schedule, dependencies, error handling.

### Anti-pattern: Re-implementing mapping data flow logic in code

Visual data flows are productive; don't translate to code unless you've outgrown them.

### Anti-pattern: Pipelines with hardcoded credentials

Linked services with Managed Identity. Key Vault for any external creds.

## Gotchas

- **Integration Runtime billing** — Self-Hosted IR is licensed per node-hour; Managed VNet IR has its own cost.
- **Mapping data flow Spark spin-up** — adds latency; design for warm-pool where supported.
- **Triggers** — scheduled, tumbling window, event-based (Storage Event Grid).
- **CI/CD via ARM templates** is mature; new builds use Bicep or Terraform.

## Cross-references

- [Microsoft Fabric](/stacks/azure/microsoft-fabric/) — converging successor experience
- [Synapse Analytics](/stacks/azure/synapse-analytics/) — legacy analytics target
- [Storage Account](/stacks/azure/storage-account/) — common source/sink
- [Database Architect on Azure](/stacks/azure/database-architect/) — ETL design
- [Data Factory docs](https://learn.microsoft.com/azure/data-factory/)
