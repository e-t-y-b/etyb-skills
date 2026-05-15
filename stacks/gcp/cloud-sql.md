---
title: Cloud SQL
description: Managed Postgres / MySQL / SQL Server on GCP — Enterprise Plus near-zero-downtime maintenance, up to 128 vCPUs, cross-region read replicas for DR.
product:
  name: Cloud SQL
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, devops-engineer]
  authoritative_url: https://cloud.google.com/sql/docs
  notes: "Mature. Enterprise Plus near-zero-downtime maintenance; Postgres 16, MySQL 8.4, SQL Server 2022; Memory Agent for Postgres GA."
---

## What it is

Cloud SQL is GCP's managed relational database service — Postgres, MySQL, SQL Server. HA via cross-zone failover (regional), backups + PITR built in, IAM database authentication, Private Service Connect for private networking.

Cloud SQL is the **default Postgres/MySQL choice on GCP** for standard CRUD + transactional workloads up to ~10K TPS. Escalate to [AlloyDB](/stacks/gcp/alloydb/) for higher perf, analytical workloads, or in-engine vector search. Escalate to [Spanner](/stacks/gcp/spanner/) for global ACID, horizontal scale beyond a single instance, or five-9s availability.

Authoritative reference: [cloud.google.com/sql/docs](https://cloud.google.com/sql/docs).

## When to use

Pick Cloud SQL when:
- Standard Postgres / MySQL / SQL Server workload
- < ~10K TPS on a single instance
- HA via cross-zone failover is enough (Enterprise Plus for near-zero-downtime maintenance)
- Team has Postgres / MySQL fluency and doesn't need exotic extensions

Escalate to:
- **AlloyDB** when analytical perf or vector search matter, or you hit the 128 vCPU Cloud SQL ceiling — see [AlloyDB](/stacks/gcp/alloydb/)
- **Spanner** for global ACID or horizontal scale — see [Spanner](/stacks/gcp/spanner/)

Don't use Cloud SQL when:
- You need global ACID — Cloud SQL HA is regional only
- The workload is analytical / OLAP — use [BigQuery](/stacks/gcp/bigquery/)
- The workload is document/JSON-heavy with mobile/real-time access — [Firestore](/stacks/gcp/firestore/)

## 2025-2026 currency anchors

- **Cloud SQL Enterprise Plus** is the highest-availability tier — near-zero-downtime maintenance via in-place upgrades.
- **Postgres 16 / MySQL 8.4 / SQL Server 2022** supported.
- **Up to 128 vCPUs** per instance.
- **Memory Agent for Postgres** (GA) tunes `shared_buffers` and related memory params automatically.
- **IAM database authentication** matured; pair with WIF for keyless app-to-DB auth.
- **Cross-region read replicas + automated failover** is the standard DR pattern.
- **Private Service Connect (PSC)** is the preferred private connectivity path — replaces the older "Cloud SQL Auth Proxy" requirement for many cases.

## Patterns

### Create a regional HA Postgres instance with CMEK + private IP

```bash
gcloud sql instances create prod-postgres \
  --database-version=POSTGRES_16 \
  --tier=db-custom-4-16384 \
  --region=us-central1 \
  --availability-type=REGIONAL \
  --backup \
  --enable-point-in-time-recovery \
  --network=projects/proj/global/networks/prod-vpc \
  --no-assign-ip \
  --disk-encryption-key=projects/proj/locations/us-central1/keyRings/prod/cryptoKeys/cloudsql
```

### Cross-region read replica for DR

```bash
gcloud sql instances create prod-postgres-dr \
  --master-instance-name=prod-postgres \
  --region=us-east1 \
  --tier=db-custom-4-16384
```

In a regional outage, promote the replica to primary. RPO depends on replication lag (typically seconds).

### Connectivity from Cloud Run

Three patterns in 2026 order of preference:
1. **Direct VPC egress + Private Service Connect** — cleanest; supported on Cloud Run gen2
2. **Cloud SQL Auth Proxy sidecar** — when you need IAM database authentication and per-request rotation
3. **Public IP + authorized networks** — only for dev / non-prod

## Anti-patterns

- **Public IP + 0.0.0.0/0 authorized networks** in production — exposing the database to the internet.
- **HA = DR mistake** — Cloud SQL HA is cross-zone within a region; a regional outage takes it down. Use cross-region replica + automated failover for DR.
- **No PITR enabled** — accidental drop loses you data; PITR up to 7 days is cheap insurance.
- **Over-provisioning tier** without measuring — Memory Agent + recommender will tell you the right size.
- **Service account JSON key for app auth** — use IAM database authentication or runtime SA + Secret Manager password.
- **Cloud SQL for global ACID requirements** — won't meet RPO/availability; use [Spanner](/stacks/gcp/spanner/).

## Gotchas

- **Maintenance windows** apply even on Enterprise; configure to your traffic trough.
- **Connection pooling** is your responsibility — use PgBouncer / proxysql / app-level pooling. Cloud SQL doesn't pool.
- **Storage auto-grow** is on by default; can't be shrunk. Watch for runaway log tables.
- **Postgres extension support** is a defined list — verify your required extensions are supported; AlloyDB has a broader list.

## Cross-references

- Related: [AlloyDB](/stacks/gcp/alloydb/) (upgrade path), [Spanner](/stacks/gcp/spanner/), [Cloud KMS](/stacks/gcp/cloud-kms/), [Secret Manager](/stacks/gcp/secret-manager/), [VPC](/stacks/gcp/vpc/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [backend-architect on GCP](/stacks/gcp/backend-architect/)
- Authoritative: [cloud.google.com/sql/docs](https://cloud.google.com/sql/docs)
