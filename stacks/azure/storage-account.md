---
title: Storage Account
description: Foundation for Blob, Queue, Table, Files, ADLS Gen2. ZRS/GZRS replication; v1 retired. Enable HNS at creation for ADLS Gen2 — cannot be enabled retroactively.
product:
  name: Storage Account
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, devops-engineer, backend-architect, security-engineer]
  authoritative_url: https://learn.microsoft.com/azure/storage/
  notes: "ZRS/GZRS replication stable; v1 retired; immutability + versioning stable; HNS gates ADLS Gen2."
---

## What it is

Azure Storage Account is the umbrella resource for object (Blob), file (Files), message (Queue), and key-value (Table) storage. Hierarchical Namespace (HNS) enabled at creation makes it an [ADLS Gen2](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction) data lake. Canonical reference: [Azure Storage docs](https://learn.microsoft.com/azure/storage/).

## When to use

Always — Storage Accounts back essentially every Azure workload. The decisions are: which services (Blob / Files / Queue / Table / ADLS Gen2), which replication (LRS / ZRS / GRS / GZRS / RA-GZRS), and which performance tier (Standard / Premium).

## 2025-2026 currency anchors

- **v1 Storage Accounts retired** — only v2 (general-purpose, BlockBlob, FileStorage) is current.
- **ZRS / GZRS** replication stable — synchronous zone replication; GZRS adds async cross-region.
- **Premium BlockBlob** for low-latency Blob access.
- **Azure Files Premium SSD v2 backing** — NFS 4.1 + SMB stable.
- **Cold tier (Blob)** GA — between Cool and Archive.
- **Immutability + versioning** stable — SEC 17a-4(f), CFTC 1.31, FINRA 4511 compliant.
- **Hierarchical Namespace (HNS)** must be enabled at create — **cannot be added retroactively**.

## Patterns + anti-patterns

### Pattern: Private Endpoint by default in production

Storage Account public network access = disabled. Private Endpoint for `blob` / `file` / `queue` / `table` / `dfs` (ADLS Gen2) sub-resources. Enforce via Azure Policy.

### Pattern: Lifecycle management for Blob tiering

Rule: move blobs to Cool after 30 days, Cold after 90, Archive after 180, delete after 7 years. Reduces storage cost on aging data without app changes.

### Pattern: Immutable storage for compliance

Time-based retention policy on container — blobs cannot be modified/deleted for X days. Legal holds for indefinite (until removed). Combine with versioning + soft delete for defense in depth.

### Pattern: Managed Identity + Azure RBAC for access

Apps authenticate via Managed Identity; RBAC roles (`Storage Blob Data Reader`, `Storage Blob Data Contributor`, etc.) grant data-plane access. Eliminate Storage Account Keys from production code.

### Anti-pattern: Public network access on production storage

A classic root cause for "we accidentally left port 443 open to the storage account holding production data." Private Endpoint, period.

### Anti-pattern: Storage Account Keys in app code or config

Rotate to Managed Identity. If you must use SAS, generate short-lived user-delegation SAS via Entra (`az storage container generate-sas --auth-mode login --as-user`).

### Anti-pattern: Hot tier for archival data

Lifecycle policy → Cool / Cold / Archive after N days. Hot pricing on year-old logs is a budget event.

### Anti-pattern: Forgetting HNS at create

If you might bring Spark / Databricks / Fabric to this data later, enable HNS at creation. Can't be added later.

## Gotchas

- **`Set Blob Tier`** works even with locked immutability policies, but `Delete` is blocked.
- **GRS / GZRS failover** is customer-initiated for "manual" replication; auto-failover only for specific replication types.
- **Soft delete + versioning + immutability** layer differently — read the matrix; defense in depth.
- **ABFS driver** (`abfss://`) is the right driver for ADLS Gen2 from Spark / Databricks — not WASB.

## Cross-references

- [Database Architect on Azure](/stacks/azure/database-architect/) — tier selection, ADLS Gen2 design
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — lifecycle policies, cost guardrails
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — Private Link posture, immutability for forensics
- [Event Grid](/stacks/azure/event-grid/) — Blob events
- [Azure Storage docs](https://learn.microsoft.com/azure/storage/)
- [Blob access tiers](https://learn.microsoft.com/azure/storage/blobs/access-tiers-overview)
- [Lifecycle management](https://learn.microsoft.com/azure/storage/blobs/lifecycle-management-overview)
- [ADLS Gen2](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction)
