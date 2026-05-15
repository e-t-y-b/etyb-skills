---
title: Database Architect on AWS
description: Aurora DSQL vs Aurora Serverless v2 vs RDS, DynamoDB single-table design, vector search choices (pgvector vs OpenSearch vs Knowledge Bases), S3 Tables (Iceberg), zero-ETL.
role_overlay:
  role: database-architect
  stack: aws
  last_verified_on: "2026-05-14"
  products_covered: [aurora, rds, dynamodb, elasticache, opensearch, redshift, glue, s3]
---

## Role briefing — database-architect on AWS

You make the call between [Aurora DSQL](/stacks/aws/aurora/), Aurora Serverless v2, Aurora Limitless, [RDS](/stacks/aws/rds/), [DynamoDB](/stacks/aws/dynamodb/), [ElastiCache](/stacks/aws/elasticache/), MemoryDB, [OpenSearch](/stacks/aws/opensearch/), [Redshift](/stacks/aws/redshift/), Athena + S3 Tables, Timestream. You design schemas, access patterns, indexes, partitions, replication, backup posture.

Distinct from the principle-level role: AWS has its own primitives, its own scaling envelope, its own replication contracts. **Aurora DSQL is a 2025 release** that changes the multi-region active-active math for Postgres. **DynamoDB Zero-ETL** changes the search/analytics math. **Aurora Serverless v1 is EOL**.

## The database selection matrix

| Workload shape | Default | When to escape |
|---|---|---|
| **OLTP, single-region, Postgres or MySQL** | **Aurora Serverless v2** | RDS Multi-AZ DB cluster for explicit instance sizing; Aurora Limitless when write volume exceeds single-writer ceiling |
| **OLTP, multi-region active-active, Postgres** | **Aurora DSQL** (GA May 2025) | Aurora Global Database for read-from-region + manual failover |
| **Horizontal write scaling, single DB semantics** | **Aurora Limitless** | DynamoDB if access patterns are KV |
| **Key-value, single-digit ms** | **DynamoDB** (on-demand) | DocumentDB only if existing MongoDB clients + migration heavier than rewrite |
| **Caching, <1ms, no durability requirement** | **ElastiCache Serverless (Valkey)** | Self-managed Redis on EC2 only for unusual customization (rare) |
| **Durable in-memory, multi-region** | **MemoryDB** | Aurora Serverless v2 if "in-memory" turns out to mean "fast Postgres" |
| **Full-text + vector search, log analytics** | **OpenSearch Serverless** (variable) or OpenSearch managed (steady) | Aurora pgvector for vector-only at small-medium scale; Pinecone/Weaviate/Qdrant if AWS isn't where workload lives |
| **Analytics, columnar, complex JOINs** | **Redshift Serverless** (variable) or RA3 (steady) | Athena + S3 Tables when no always-on warehouse; Snowflake/Databricks if data stack is already there |
| **Lakehouse / open table format** | **S3 Tables (Apache Iceberg)** + Athena/Spark/Trino | Glue Catalog + S3 Parquet for legacy; Delta Lake on Databricks |
| **Time-series, IoT, monitoring** | **Timestream for InfluxDB** or **Timestream for LiveAnalytics** | CloudWatch Metrics for AWS-native ops metrics; AMP for Prometheus ecosystem |
| **Graph, social, fraud rings** | **Neptune** | Aurora with recursive CTEs for small-scale graph |
| **Ledger, cryptographic verifiability** | **Aurora DSQL + app-level hash chains** (QLDB is maintenance mode) | AWS Managed Blockchain if compliance demands actual blockchain |

**QLDB status**: maintenance mode — AWS steers customers to Aurora Postgres + application-level append-only patterns for new builds.

## Aurora DSQL — the post-cutoff database

The most consequential 2025 database release on AWS. Older training data won't know it.

- **Postgres wire-compatible** — existing drivers connect.
- **Serverless** — no instance sizing.
- **Multi-region active-active** with strong consistency, 99.999% multi-region / 99.99% single-region.
- **Express configuration** (Mar 2026) — two clicks to a working DB.

**Use DSQL when**: multi-region OLTP without app-level sharding; net-new serverless Postgres without connection-pool headaches; previously considering Spanner / CockroachDB / YugabyteDB.

**Don't use DSQL when**:
- Long-running transactions (DSQL is short-OLTP-shaped).
- Heavy stored-procedure workloads.
- Background workers / cron extensions (use [EventBridge Scheduler](/stacks/aws/eventbridge/)).
- Postgres extensions DSQL doesn't yet support.
- Tight cost optimization for steady load — Aurora Serverless v2 + Savings Plans may win.

See [`/stacks/aws/aurora/`](/stacks/aws/aurora/) for DSQL connection pattern, schema considerations, and the no-RDS-Proxy rule.

## Product references

### [DynamoDB](/stacks/aws/dynamodb/)

**Single-table design is the only good design.** Multi-table-per-entity is the relational reflex; wrong on KV. Model access patterns first. **GSI strategy** — sparse indexes minimize cost, eventual consistency on GSIs. **On-demand is the default in 2026.** Hot-partition mitigation: write sharding, hierarchical timestamps. **Zero-ETL to OpenSearch / Redshift** eliminates custom replication Lambdas.

### [Aurora](/stacks/aws/aurora/)

Aurora Serverless v2 for variable; Aurora DSQL for multi-region active-active; Aurora Limitless for horizontal write scaling; Aurora Global Database for active-passive multi-region read scaling. **Aurora Serverless v1 EOL Dec 2024.** Blue/Green for major-version upgrades.

### [RDS](/stacks/aws/rds/)

For engines Aurora doesn't cover (Oracle, SQL Server, MariaDB) or existing Postgres/MySQL without migration motivation. Multi-AZ DB cluster (1 writer + 2 readers) is the modern shape. Extended Support is last-resort.

### [ElastiCache](/stacks/aws/elasticache/) (Valkey) vs MemoryDB

ElastiCache when data is recoverable from source of truth (cache). MemoryDB when data must not be lost across node failures (primary KV with Redis API). **Valkey 7.2 is 33% cheaper than Redis OSS** — net-new caches: Valkey.

### Vector search

| Choice | Use when |
|---|---|
| **Aurora pgvector / DSQL pgvector** | <10M vectors, embeddings live with relational data |
| **OpenSearch Serverless (VECTORSEARCH)** | Heavy hybrid search, AWS-native ML stack |
| **Bedrock Knowledge Bases** (managed) | "Just make it work" for RAG |
| **Pinecone / Qdrant / Weaviate** | Outgrew pgvector, want vendor-specific features |

Default for new RAG on AWS: [Bedrock Knowledge Bases](/stacks/aws/bedrock/) (uses OpenSearch Serverless or Aurora pgvector underneath).

### Analytics

| | [Redshift](/stacks/aws/redshift/) | Athena + S3 Tables | Snowflake/Databricks |
|---|---|---|---|
| **Compute** | Always-on or Serverless | Pay-per-query | External SaaS |
| **Best for** | Always-on BI | Ad-hoc, dev/test | Multi-cloud or already-there teams |

Default for new AWS-native analytics: **Athena + S3 Tables (Iceberg)**. Promote to Redshift when query volume / latency demands always-on warehouse.

### [S3 Tables (Iceberg)](/stacks/aws/s3/)

Fully managed Iceberg tables; AWS handles compaction, snapshot management, time-travel. Query from Athena, Redshift Spectrum, EMR, [Glue Catalog](/stacks/aws/glue/). Schema evolution; time-travel queries.

### Streaming

| | Kinesis | MSK | DynamoDB Streams |
|---|---|---|---|
| **API** | Kinesis SDK | Kafka clients | DynamoDB Streams API |
| **Retention** | Up to 365 days | Unlimited | 24 hours |
| **Pick when** | AWS-native | Kafka ecosystem / multi-cloud portability | DynamoDB-derived events |

Compose with [EventBridge Pipes](/stacks/aws/eventbridge/) for downstream wiring.

### EBS

| Type | Use case |
|---|---|
| **gp3** | Default for everything (80K IOPS, 64 TiB) |
| **io2 Block Express** | Tier-1 OLTP, latency-critical (256K IOPS, 4 GiB/s) |
| **st1** | Sequential (logs, data lakes) |
| **sc1** | Cold, infrequent |

gp3 default; io2 BX for self-managed tier-1 OLTP databases.

## 2025-2026 platform-reset items relevant to this role

- **Aurora DSQL** GA — multi-region active-active Postgres at 99.999%.
- **DynamoDB Zero-ETL** to OpenSearch and Redshift.
- **S3 Tables (Iceberg)** — the lakehouse default.
- **Valkey 7.2** — 33% cheaper than Redis OSS.
- **MemoryDB Multi-Region** active-active.
- **Aurora pgvector** mature; DSQL pgvector region-dependent.
- **OpenSearch Serverless workload types** (SEARCH / TIME_SERIES / VECTORSEARCH).
- **DynamoDB on-demand pricing dropped ~25% in 2025**.
- **Aurora Serverless v1 EOL Dec 2024**.

If proposing Aurora Serverless v1, custom DynamoDB → OpenSearch Lambda, Redis OSS engine for new caches, QLDB for new ledger, or `glacier:*` for new archives — your training is stale.

## Patterns the role applies

### Backup, DR, recovery

- **AWS Backup** with tag-based selection — single policy, broad coverage.
- **PITR** on every production DynamoDB table.
- **Aurora cross-region replicas** + Global Database for tier-1/2 DR.
- **Quarterly DR drills** — untested backups don't exist.

### TDD on databases

- **Schema migrations** — Liquibase, Flyway, Alembic, Atlas. Forward + rollback. Tested in CI against clean DB.
- **DynamoDB access patterns are testable** — integration tests that exercise every access pattern.
- **Aurora DSQL schema migrations** behave like Postgres but must be tested in a separate DSQL cluster.
- **Data integrity tests** — row counts, FK consistency, constraint enforcement.

### Verification on AWS data tier

Claims must cite:
- "DynamoDB on-demand has 40K WCU / 40K RCU per-table default" → docs.
- "Aurora Serverless v2 ACU range is 0.5-256" → Aurora docs.
- "DSQL provides 99.999% multi-region availability" → DSQL service-level statement.

### Debugging data issues

1. Reproduce on a clone, not production.
2. CloudTrail for control-plane, CloudWatch Logs for engine logs, Performance Insights for query-level.
3. **Aurora Performance Insights + RDS Enhanced Monitoring** on every Aurora / RDS production cluster.
4. **DynamoDB Contributor Insights** for hot keys.
5. Athena query history + Workgroup metrics for analytics performance.

## Cross-references

- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — SDK usage + connection patterns
- [`/stacks/aws/ai-ml-engineer/`](/stacks/aws/ai-ml-engineer/) — vector search for RAG
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — encryption at rest, IAM auth
- [`/stacks/aws/`](/stacks/aws/) — Stack index
