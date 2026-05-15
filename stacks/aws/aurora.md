---
title: Aurora
description: AWS Aurora — Aurora DSQL (GA May 2025) for multi-region active-active Postgres at 99.999%, Aurora Serverless v2 for auto-scaling OLTP, Aurora Limitless for horizontal write scaling. Aurora Serverless v1 EOL Dec 2024.
product:
  name: Aurora
  stack: aws
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, system-architect, fintech-architect]
  authoritative_url: https://docs.aws.amazon.com/aurora/
  notes: "DSQL GA May 2025; multi-region active-active patterns and pricing post-cutoff for most LLMs; Express config (Mar 2026) brand-new; Aurora Serverless v1 EOL."
---

## What it is

Amazon Aurora is AWS's purpose-built MySQL- and Postgres-compatible relational database. Three deployment modes matter in 2026:

- **Aurora Serverless v2** — auto-scaling OLTP, 0.5–256 ACUs, multi-AZ implicit.
- **Aurora DSQL** — Postgres-compatible, serverless, multi-region active-active, 99.999% availability.
- **Aurora Limitless** — automated horizontal scaling for Aurora Postgres, petabyte-scale, single-database semantics.

Aurora **Provisioned** (committed sizing) is still a valid choice for steady predictable workloads with Reserved/Savings Plans.

Canonical surface: [docs.aws.amazon.com/aurora](https://docs.aws.amazon.com/aurora/).

## When to use

| Workload | Choose |
|---|---|
| OLTP, single-region, Postgres or MySQL, variable load | **Aurora Serverless v2** |
| OLTP, multi-region active-active, Postgres | **Aurora DSQL** (GA May 2025) |
| Horizontal write scaling, single database semantics | **Aurora Limitless** |
| Cross-region read scaling + manual failover DR | **Aurora Global Database** |
| Predictable steady OLTP with committed pricing | Aurora **Provisioned** + Reserved Instances |

## 2025-2026 currency anchors

- **Aurora DSQL GA May 2025** — Postgres wire-compatible, serverless, multi-region active-active, 99.999% multi-region SLA / 99.99% single-region. Replaces large swathes of "we need a global Postgres" architectures previously requiring CockroachDB, Spanner, or YugabyteDB.
- **DSQL Express configuration** (Mar 2026) — two-clicks-to-working-DB shortcut.
- **Aurora Serverless v1 EOL Dec 2024.** Migrate to Serverless v2 or DSQL.
- **Aurora Limitless** — petabyte-scale, single-database semantics, no app-level sharding.
- **Blue/Green deployments** for major-version upgrades and schema migrations. **Aurora Global Database supports Blue/Green** as of Nov 2025.
- **RDS Extended Support** lets you stay on EOL engine versions (per-vCPU-hour fee). Last-resort, not strategy.
- **Aurora pgvector** mature for vector search at small-medium scale; **Aurora DSQL pgvector** availability varies by region.

## Patterns

### Aurora DSQL — the new multi-region default

```python
import boto3, psycopg

client = boto3.client('dsql', region_name='us-east-2')
token = client.generate_db_connect_admin_auth_token(
    Hostname='abc123.dsql.us-east-2.on.aws',
    Region='us-east-2',
)
conn = psycopg.connect(
    host='abc123.dsql.us-east-2.on.aws',
    dbname='postgres',
    user='admin',
    password=token,
    sslmode='verify-full',
)
```

Key DSQL differences from RDS Postgres:
- **No connection limit** in the traditional sense — DSQL multiplexes connections at the protocol layer. **Don't put RDS Proxy in front of DSQL.**
- **No background workers / cron extensions** — use [EventBridge Scheduler](/stacks/aws/eventbridge/) for periodic work.
- **No long-lived transactions** — DSQL is tuned for short OLTP transactions (web request shape). Hour-long ETL inside a single transaction is wrong.
- **No PL/pgSQL stored procedures** (as of GA; check current state). Move logic to the application layer.
- **No materialized views** as of GA.
- **No foreign data wrappers** for federating across DSQL clusters.
- **IAM auth default** — connection string includes a short-lived token (15-min default). Refresh per connection establishment.
- **Same isolation levels as Postgres** (READ COMMITTED, REPEATABLE READ); SERIALIZABLE works but uses optimistic concurrency under the hood — expect more `serialization_failure` exceptions. **Retry on serialization failure is mandatory.**
- **No `serial`/`bigserial` sequences** with traditional monotonic guarantees — use `IDENTITY` columns or UUID/ULID generated at the application layer.

### When to pick DSQL vs Serverless v2 vs Provisioned

| Need | Pick |
|---|---|
| Multi-region active-active OLTP | **DSQL** |
| Net-new app, serverless Postgres, unpredictable load | DSQL or **Serverless v2** — DSQL if multi-region; Serverless v2 if single-region and you want full Postgres feature set |
| Postgres extensions DSQL doesn't yet support (`pg_partman`, `pg_cron`, advanced PostGIS) | **Serverless v2** or **Provisioned** |
| Long-running transactions, stored procedures, materialized views | **Serverless v2** or **Provisioned** |
| Predictable steady load with cost optimization | **Provisioned** with Reserved Instances |

### Aurora Serverless v2 quirks

- **Scale unit = 0.5 ACU** (~2 GB RAM + corresponding CPU/network). Min capacity matters: 0.5 ACU min means scale-to-near-zero, but cold response after idle has a brief lag.
- **Scaling is fast** (seconds), but **not instant**. Burst-heavy with large idle gaps may want a higher min capacity.
- **Storage scales independently** — Aurora storage grows in 10 GB increments.
- **Multi-AZ is implicit** — Aurora replicates across 3 AZs, 6 copies. Multi-AZ failover <30s typically.

### Aurora Global Database

For active-passive multi-region:
- Primary region accepts writes; secondaries are read replicas.
- Cross-region replication lag <1s typical.
- Manual / Aurora-managed switchover promotes secondary.

Use when you need cross-region read scaling + regional DR but **not** active-active. If you need active-active, **Aurora DSQL is the answer**, not Global Database + custom routing.

### Connection pooling

| Workload | Pooling |
|---|---|
| [Lambda](/stacks/aws/lambda/) → Aurora (non-DSQL) | **RDS Proxy** — Lambda holds one connection to the proxy; proxy maintains the pool |
| Lambda → Aurora DSQL | No proxy needed; DSQL multiplexes natively |
| [ECS](/stacks/aws/ecs/) / [EKS](/stacks/aws/eks/) → Aurora | App-level pool (PgBouncer sidecar or in-process driver pool); 10-20 connections per pod typical |
| ECS / EKS → DSQL | App-level pool — DSQL handles many more connections than RDS, size accordingly |

**RDS Proxy gotcha:** session pinning kills efficiency. Avoid `SET`, prepared statements with names, temp tables — they pin connections.

### Blue/Green deployments

Clone the production DB, apply schema changes, swap. Use for major-version upgrades, schema migrations with downtime sensitivity. Aurora Global Database supports Blue/Green as of Nov 2025.

### IAM auth + Secrets Manager rotation

- **IAM database authentication** — short-lived tokens, no long-lived DB passwords.
- **[Secrets Manager](/stacks/aws/secrets-manager/) managed rotation** for RDS/Aurora — single-user or multi-user rotation (multi-user is zero-downtime).

## Anti-patterns

- **Aurora Serverless v1 for new builds.** EOL Dec 2024.
- **Aurora Global Database when you actually need active-active.** Use DSQL.
- **RDS Proxy in front of DSQL.** DSQL multiplexes natively; the proxy adds latency for no benefit.
- **`SELECT *` from Aurora in OLTP code.** Specify columns.
- **Long-running transactions on DSQL.** DSQL is OLTP-shaped; move ETL out.
- **No retry on `serialization_failure` for DSQL.** SERIALIZABLE in DSQL is optimistic; retries are part of the contract.
- **Self-managed PostgreSQL on EC2 "because we want control".** You don't want the operational tax.

## Gotchas

- **Aurora storage cost** is per-GB-month for actual data + I/O charges (unless on Aurora I/O-optimized configuration). At scale, I/O-optimized can be cheaper despite higher base price.
- **Aurora failover** preserves connections via the cluster endpoint, but in-flight queries may fail; application must retry transient errors.
- **Aurora Limitless requires specific Postgres compatibility versions** — verify before assuming an existing Aurora cluster can convert.
- **DSQL regions** — DSQL is not yet available in every region; verify against the [Aurora DSQL Regions page](https://docs.aws.amazon.com/aurora-dsql/) before designing.
- **DSQL pricing** is post-cutoff for most training data — verify the current DPU pricing in your region.
- **Aurora encryption** must be set at create time; can't add later (must do snapshot + restore).

## Cross-references

- [`/stacks/aws/rds/`](/stacks/aws/rds/) — non-Aurora RDS for engines Aurora doesn't support
- [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) — alternative for KV access patterns
- [`/stacks/aws/secrets-manager/`](/stacks/aws/secrets-manager/) — managed credential rotation
- [`/stacks/aws/kms/`](/stacks/aws/kms/) — encryption at rest
- [`/stacks/aws/iam/`](/stacks/aws/iam/) — IAM database authentication
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — role view; selection matrix
- [`/stacks/aws/fintech-architect/`](/stacks/aws/fintech-architect/) — DSQL for ledger-adjacent (not ledger) workloads
- [Aurora DSQL docs](https://docs.aws.amazon.com/aurora-dsql/)
