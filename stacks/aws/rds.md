---
title: RDS
description: Managed relational databases on AWS — Multi-AZ DB cluster the modern shape, Blue/Green deployments mature, Extended Support a last-resort. Aurora is the upgrade path for Postgres/MySQL.
product:
  name: RDS
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, system-architect]
  authoritative_url: https://docs.aws.amazon.com/rds/
  notes: "Mature surface; Blue/Green deployments + Multi-AZ DB cluster (1 writer + 2 readers) are the main 2023-2026 evolution."
---

## What it is

Amazon RDS is the managed relational database service for engines AWS doesn't have an Aurora variant for, or where Aurora isn't the right fit: Oracle, SQL Server, MariaDB, plus RDS for Postgres and RDS for MySQL (alternatives to Aurora's Postgres/MySQL).

Canonical surface: [docs.aws.amazon.com/rds](https://docs.aws.amazon.com/rds/).

## When to use

| Need | Use RDS? |
|---|---|
| Postgres or MySQL workload starting fresh | No — use [Aurora](/stacks/aws/aurora/) |
| Existing Postgres/MySQL workload with no migration motivation | RDS for Postgres/MySQL is fine |
| Oracle, SQL Server, MariaDB | Yes — Aurora doesn't cover these engines |
| Specific Postgres/MySQL extensions Aurora doesn't support | Yes |
| Predictable steady load with Reserved Instance commitment | Either RDS or Aurora Provisioned works |

## 2025-2026 currency anchors

- **Multi-AZ DB cluster** (1 writer + 2 readers across 3 AZs) is the modern shape for RDS workloads needing read scaling without going to Aurora.
- **Blue/Green deployments** matured 2023-2025 — clone the production DB, apply schema changes, swap. Use for major-version upgrades and schema migrations with downtime sensitivity.
- **RDS Extended Support** lets you stay on EOL engine versions for a per-vCPU-hour fee. Use as a last resort — staying on Extended Support permanently is a financial mistake.
- **IAM database authentication** mature.
- **RDS Proxy** is the canonical Lambda-to-RDS connection layer.

## Patterns

### Engine selection

| Engine | Use when |
|---|---|
| **RDS for Postgres** | You need extensions Aurora doesn't support (rare in 2026); existing Postgres workload not justifying Aurora migration |
| **RDS for MySQL** | Same logic — existing MySQL with no Aurora migration motive |
| **MariaDB** | Existing MariaDB workloads; Aurora doesn't cover MariaDB beyond what Aurora MySQL provides |
| **Oracle** | Enterprise Oracle workloads with licensing — verify BYOL vs LI |
| **SQL Server** | Existing SQL Server workloads — verify Express/Web/Standard/Enterprise licensing edition |

### Multi-AZ DB cluster

The modern shape for RDS workloads needing read scaling: 1 writer + 2 reader instances across 3 AZs. Reader endpoints route reads; writer endpoint routes writes. Better than legacy Multi-AZ instance (1 writer + 1 standby) when you need read scaling.

### Blue/Green deployments

```bash
aws rds create-blue-green-deployment \
  --blue-green-deployment-name upgrade-to-pg16 \
  --source arn:aws:rds:us-east-2:123456:cluster:my-cluster \
  --target-engine-version 16.1
```

Standard flow:
1. Create the green environment (clone of blue).
2. Apply schema changes / major version upgrade on green.
3. Test against green.
4. Switch over (DNS swap, ~1 min).
5. Decommission blue after retention window.

### Backup + PITR

- **Automated backups** with 7-35 day retention.
- **PITR (Point-in-Time Recovery)** within retention window.
- **Manual snapshots** for long-term retention.
- **AWS Backup** can orchestrate cross-region, cross-account RDS backups via a single policy.

### Connection pooling

[RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html) in front of Lambda → RDS. Lambda makes a single connection to the proxy; proxy maintains the pool. Without proxy, you'll exhaust DB connections at Lambda scale.

ECS/EKS workloads typically use app-level pooling (PgBouncer sidecar or in-process pool).

### IAM auth + Secrets Manager rotation

- **IAM database authentication** — short-lived tokens, no long-lived DB passwords. Postgres/MySQL/MariaDB supported.
- **[Secrets Manager](/stacks/aws/secrets-manager/) managed rotation** — single-user (downtime during rotation) or multi-user (zero-downtime).

## Anti-patterns

- **RDS for Postgres/MySQL for net-new** when Aurora fits. Aurora's storage layer, replication, and failover are better.
- **Single-AZ for production.** Always Multi-AZ (instance) or Multi-AZ DB cluster.
- **Major version upgrades in-place under traffic.** Use Blue/Green.
- **Staying on Extended Support indefinitely.** Use the 1-2 quarter window to plan migration, then migrate.
- **Plaintext DB credentials.** Use Secrets Manager with rotation.
- **No PITR.** Default retention should be 14+ days for production.
- **Self-managed Postgres/MySQL on EC2 because "we want control".** You don't want the operational tax — patch cadence, replication, failover, backups all need re-implementing.

## Gotchas

- **RDS storage cannot be reduced** in-place. To shrink, migrate to a new instance.
- **RDS encryption** must be set at create time; can't add later (must do snapshot + restore).
- **Failover takes 60-120s** typically; in-flight transactions fail.
- **RDS Proxy session pinning** kills efficiency — avoid `SET`, named prepared statements, temp tables.
- **Cross-region read replicas** have replication lag (seconds-to-minutes); not synchronous.
- **Per-region instance count quota** is 40 by default; check before scaling out.

## Cross-references

- [`/stacks/aws/aurora/`](/stacks/aws/aurora/) — upgrade path for Postgres/MySQL
- [`/stacks/aws/secrets-manager/`](/stacks/aws/secrets-manager/) — managed rotation
- [`/stacks/aws/kms/`](/stacks/aws/kms/) — encryption at rest
- [`/stacks/aws/iam/`](/stacks/aws/iam/) — IAM database authentication
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — role view; selection matrix
- [RDS Proxy docs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html)
