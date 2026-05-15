---
title: Redshift
description: AWS managed data warehouse — Serverless for variable load, RA3 provisioned for steady, Spectrum reads from S3 via Glue Catalog. Zero-ETL from DynamoDB and Aurora matures the analytics path.
product:
  name: Redshift
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer]
  authoritative_url: https://docs.aws.amazon.com/redshift/
  notes: "Serverless mature; RA3 + Spectrum stable; zero-ETL integrations from DynamoDB and Aurora reduce ETL custom code."
---

## What it is

Amazon Redshift is AWS's managed data warehouse — Postgres-derived SQL, columnar storage, MPP architecture. Available as **Redshift Serverless** (pay-per-query, no cluster sizing) or **Redshift Provisioned** (always-on, RA3 nodes with Redshift Managed Storage). Spectrum extends queries to S3.

Canonical surface: [docs.aws.amazon.com/redshift](https://docs.aws.amazon.com/redshift/).

## When to use

| Need | Use Redshift? |
|---|---|
| Always-on BI / dashboards | Yes — Provisioned RA3 |
| Ad-hoc / dev / variable load | Yes — Serverless |
| Complex JOINs, materialized views | Yes |
| Lakehouse / open table format | Use S3 Tables + Athena ([Glue](/stacks/aws/glue/)) |
| Multi-cloud or already-there teams | Snowflake / Databricks |
| Small datasets (<100 GB) | Athena + S3 + Glue is cheaper |

## 2025-2026 currency anchors

- **Redshift Serverless** mature — pay-per-query, no cluster sizing.
- **RA3 nodes** with Redshift Managed Storage (RMS) — separate compute and storage scaling.
- **Spectrum** queries S3 directly via Glue Catalog.
- **Zero-ETL** from [DynamoDB](/stacks/aws/dynamodb/) and [Aurora](/stacks/aws/aurora/) (and others) eliminate custom replication.
- **Concurrency scaling** for spiky workloads.
- **Data sharing** across Redshift clusters without copying.

## Patterns

### Serverless vs Provisioned

| | Serverless | Provisioned (RA3) |
|---|---|---|
| **Sizing** | Auto-scale RPUs | Manual cluster sizing |
| **Pricing** | Per-query + storage | Per-node hour + RMS storage |
| **Cold start** | Seconds (first query) | None (always on) |
| **Use** | Variable / ad-hoc | Steady BI / dashboards |

Default for new analytics: **Serverless** until query volume justifies the always-on cost of Provisioned.

### Spectrum (S3 external tables)

```sql
-- Create external schema pointing at Glue Catalog
CREATE EXTERNAL SCHEMA spectrum_schema
FROM DATA CATALOG
DATABASE 'my_glue_db'
IAM_ROLE 'arn:aws:iam::123456:role/SpectrumRole';

-- Query S3 data alongside Redshift-stored data
SELECT r.customer_id, SUM(s.total) AS s3_total
FROM redshift_table r
JOIN spectrum_schema.orders s ON r.customer_id = s.customer_id
WHERE s.year = '2026'
GROUP BY r.customer_id;
```

Use for hot data in Redshift + cold data in S3 — Spectrum joins them transparently.

### Zero-ETL

DynamoDB → Redshift and Aurora → Redshift zero-ETL eliminates custom replication. Set up via console or SDK; data flows continuously with minute-scale latency.

### Concurrency scaling

For periodic spikes, concurrency scaling clusters absorb the burst — pay per second when active. Configure via WLM.

### Workload Management (WLM)

```json
{
  "auto_wlm": true,  // Default for most workloads
  "query_concurrency_scaling": "auto",
  "query_priority_levels": ["highest", "high", "normal", "low", "lowest"]
}
```

Auto WLM is the modern default — manual WLM is needed only for tight tuning.

### Materialized views

Pre-computed query results that auto-refresh on underlying changes. Use for frequently-queried aggregations.

## Anti-patterns

- **Redshift for OLTP.** It's a data warehouse; latency for single-row lookup is much higher than [Aurora](/stacks/aws/aurora/).
- **Redshift for small datasets.** Athena + S3 + Glue is cheaper for <100 GB ad-hoc.
- **`SELECT *` in production queries.** Specify columns; columnar storage benefits from narrow projections.
- **No DISTKEY / SORTKEY strategy** for large tables. Affects query performance dramatically.
- **Hand-built DynamoDB / Aurora replication Lambda.** Use zero-ETL.
- **Provisioned cluster sized for peak** when traffic is bursty. Concurrency scaling + Serverless handles bursts better.

## Gotchas

- **Redshift Postgres dialect** is similar but not identical to Aurora Postgres — verify queries.
- **Cross-region replication** requires snapshot + restore, not native replication.
- **Spectrum query cost** is per-TB scanned — same partition pruning discipline as Athena.
- **RA3 storage** is per-TB, separate from compute — node sizing decoupled from data volume.
- **Vacuum** is largely managed in modern Redshift, but heavy update/delete workloads benefit from periodic checks.

## Cross-references

- [`/stacks/aws/s3/`](/stacks/aws/s3/) — Spectrum source
- [`/stacks/aws/glue/`](/stacks/aws/glue/) — Glue Catalog metastore
- [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) — zero-ETL source
- [`/stacks/aws/aurora/`](/stacks/aws/aurora/) — zero-ETL source
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — role view; analytics tier
- [Redshift pricing](https://aws.amazon.com/redshift/pricing/)
