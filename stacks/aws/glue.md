---
title: Glue
description: AWS managed serverless ETL on Spark — Glue Catalog as the canonical metastore for Athena and Redshift Spectrum, Crawlers for schema discovery, dbt-athena for modern transformation.
product:
  name: Glue
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer]
  authoritative_url: https://docs.aws.amazon.com/glue/
  notes: "Mature serverless ETL; Glue Catalog the canonical metastore; Glue Studio visual editor; integration with Lake Formation."
---

## What it is

AWS Glue is managed serverless ETL on Spark — the canonical metastore (Glue Catalog) used by Athena, Redshift Spectrum, EMR, and Lake Formation. Glue Jobs run Spark scripts (PySpark or Scala); Crawlers auto-discover schemas in S3.

Canonical surface: [docs.aws.amazon.com/glue](https://docs.aws.amazon.com/glue/).

## When to use

| Need | Use Glue? |
|---|---|
| Serverless ETL on Spark | Yes |
| Schema discovery over S3 | Yes — Crawlers |
| Glue Catalog as metastore | Yes — default |
| Big-data with tight Spark control / custom versions | No — use EMR or EMR Serverless |
| Modern SQL-driven transformation | Use dbt-athena or dbt-glue |
| Stream processing | EMR or Kinesis Analytics |

## 2025-2026 currency anchors

- **Glue Studio** visual editor for ETL pipelines.
- **Glue Catalog** is the canonical metastore — used by Athena, [Redshift](/stacks/aws/redshift/) Spectrum, EMR.
- **dbt-glue + dbt-athena** for SQL-driven transformation pipelines.
- **Lake Formation** for fine-grained data lake permissions on top of Glue Catalog.
- **Apache Iceberg via [S3 Tables](/stacks/aws/s3/)** — Glue Crawlers and Jobs support Iceberg.

## Patterns

### Glue Job structure

```python
import sys
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'source_path', 'target_path'])
sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args['JOB_NAME'], args)

source = glue_context.create_dynamic_frame.from_options(
    connection_type='s3',
    connection_options={'paths': [args['source_path']]},
    format='parquet',
)
# Transformations...
glue_context.write_dynamic_frame.from_options(
    frame=source,
    connection_type='s3',
    connection_options={'path': args['target_path']},
    format='parquet',
)
job.commit()
```

### Glue Catalog as metastore

```sql
-- Athena query against Glue Catalog
SELECT * FROM my_database.orders
WHERE year='2026' AND month='05'
LIMIT 100;
```

Partition pruning is the dominant Athena performance lever. Always partition by `year`, `month`, `day` for time-series.

### Crawler vs schema-first

- **Crawler-discovered**: fast to start; risk of unexpected schema drift.
- **Schema-first**: reliable; required for strict schemas.

For production data lakes, schema-first via CDK / Terraform; crawlers for exploration.

### Athena workgroups

Per-workgroup cost controls: per-query data scanned limits, CloudWatch metrics, result location enforcement.

### dbt on Glue / Athena

`dbt-athena` is the canonical modern transformation tool on AWS — materializations (view/table/incremental/ephemeral), Iceberg support, native Glue Catalog integration.

## Anti-patterns

- **Glue for tight latency requirements.** Spark startup is minutes.
- **No partition strategy on S3 sources.** Athena scans everything; partitioning prunes.
- **Crawler-everywhere.** Production schemas should be defined intentionally.
- **`SELECT *` in Athena.** Athena bills by data scanned.
- **Hand-rolled Spark on EMR** for jobs Glue handles. Operational tax for no gain unless you need tight Spark control.
- **No workgroup cost limits** on Athena. Runaway queries cost $$$.

## Gotchas

- **Glue Crawler runs are billed** (per DPU-hour). Schedule sparingly.
- **DPU sizing** — start with auto-scaling DPUs; tune from job history.
- **Spark version compatibility** — Glue 4.0 uses Spark 3.3+; verify before lifting EMR scripts.
- **Glue Catalog cross-account access** requires resource-based policies on the catalog + IAM on consumers.
- **Iceberg compaction** — S3 Tables auto-compacts; raw Athena+Glue+Parquet does not.

## Cross-references

- [`/stacks/aws/s3/`](/stacks/aws/s3/) — data source, S3 Tables for Iceberg
- [`/stacks/aws/redshift/`](/stacks/aws/redshift/) — Spectrum reads from Glue Catalog
- [`/stacks/aws/sagemaker/`](/stacks/aws/sagemaker/) — ML lifecycle integration
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — role view; analytics tier
- [Athena docs](https://docs.aws.amazon.com/athena/)
- [dbt-athena](https://github.com/dbt-athena/dbt-athena)
