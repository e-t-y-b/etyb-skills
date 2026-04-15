# Data Pipeline Technologies — Deep Reference

**Always use `WebSearch` to verify current versions and features. The data pipeline ecosystem evolves rapidly — this reference covers the landscape as of early 2026.**

## Table of Contents
1. [Apache Kafka](#1-apache-kafka)
2. [Confluent Platform](#2-confluent-platform)
3. [Apache Flink](#3-apache-flink)
4. [Apache Spark Streaming](#4-apache-spark-streaming)
5. [Stream Processing Decision Matrix](#5-stream-processing-decision-matrix)
6. [Change Data Capture (CDC)](#6-change-data-capture-cdc)
7. [ETL vs ELT and Orchestration](#7-etl-vs-elt-and-orchestration)
8. [Data Lakehouse and Table Formats](#8-data-lakehouse-and-table-formats)
9. [Real-Time OLAP Engines](#9-real-time-olap-engines)
10. [Event Sourcing and CQRS](#10-event-sourcing-and-cqrs)
11. [Data Contracts and Schema Management](#11-data-contracts-and-schema-management)
12. [Batch vs Streaming Architectures](#12-batch-vs-streaming-architectures)
13. [Data Quality and Observability](#13-data-quality-and-observability)
14. [Managed Streaming Services](#14-managed-streaming-services)

---

## 1. Apache Kafka

### Version Timeline

| Version | Date | Milestone |
|---------|------|-----------|
| **3.6** | Oct 2023 | Tiered storage (early access) |
| **3.7** | Feb 2024 | KRaft improvements, new consumer group protocol preview |
| **3.8** | Jul 2024 | Dynamic KRaft quorum, consumer protocol improvements |
| **3.9** | Oct 2024 | Last release supporting ZooKeeper. Migration tools finalized |
| **4.0** | Mar 2025 | **ZooKeeper fully removed.** KRaft-only. Share Groups (early access) |
| **4.1** | Mid 2025 | Share Groups preview, consumer protocol refinements |

### KRaft Mode (KIP-500)

Kafka 4.0 is the first major release to operate **entirely without ZooKeeper**. KRaft (Kafka Raft) stores metadata in Kafka's own event log.

**Benefits of KRaft over ZooKeeper:**
- Eliminates the separate ZooKeeper ensemble (fewer processes, simpler ops)
- Metadata operations are O(1) instead of O(partitions) — enables millions of partitions
- Topic creation and partition rebalancing are dramatically faster
- Single security model (no separate ZK ACLs)
- Simpler deployment: one process type instead of two

**Migration path:**
- Kafka 3.x: Run KRaft or ZooKeeper (migration tools available)
- Kafka 3.9: Last version with ZooKeeper support. Complete migration here
- Kafka 4.0+: KRaft only. No ZK mode, no migration from ZK mode

**Production guidance:**
- New clusters: Always KRaft. No reason to start with ZooKeeper
- Existing clusters: Migrate on 3.9 first, then upgrade to 4.0
- Controller quorum: 3 controllers for most clusters, 5 for large-scale

### Tiered Storage

Introduced in Kafka 3.6, tiered storage decouples compute from storage by offloading cold log segments to object storage (S3, GCS, Azure Blob).

**How it works:**
```
Hot data (recent) → Local broker disks (fast, expensive)
Cold data (older) → Remote storage (S3/GCS — cheap, elastic)
```

**Key benefits:**
- Independent scaling of compute and storage
- Retain data for weeks/months without scaling broker disks
- Reduce broker storage costs by 60-80%

**2025-2026 developments:**
- KIP-1254: Consumers read directly from remote storage (bypass broker)
- KIP-1255: Dedicated read-only broker type for tiered reads
- Production-stable for most use cases; test thoroughly for latency-sensitive consumers

### Share Groups (KIP-932) — Queues for Kafka

Share Groups are a new consumer group type introduced in Kafka 4.0 (early access):

**How they differ from consumer groups:**

| Feature | Consumer Groups | Share Groups |
|---------|----------------|--------------|
| Consumer-partition mapping | 1:1 (max consumers = partitions) | Many:many (consumers > partitions) |
| Ordering | Per-partition ordering guaranteed | Unordered |
| Acknowledgment | Offset commit (batch) | Per-record acknowledgment |
| Failed messages | Consumer handles retry | Automatic redelivery |
| Use case | Event streaming, log processing | Task queues, work distribution |

**When to use share groups:**
- Work distribution (task queues) where ordering is not critical
- High fan-out processing with variable consumer counts
- Replacing RabbitMQ/SQS patterns within Kafka
- Workloads where consumer count must scale independently of partitions

**Status:** Early access in 4.0, preview in 4.1, GA target ~4.2 (late 2025)

### New Consumer Rebalance Protocol (KIP-848)

Kafka 4.0 introduces a server-side consumer rebalance protocol replacing the client-side cooperative sticky assignor:

- **Up to 20x faster rebalances** — rebalance time drops from minutes to seconds
- Server-managed assignment eliminates stop-the-world pauses
- Consumers keep processing during rebalance (no revocation window)
- Default in Kafka 4.0 for new consumer groups

### Performance Characteristics

| Metric | Typical Value |
|--------|--------------|
| Throughput (single cluster) | Millions of messages/sec |
| Latency (producer to consumer) | 2-10ms (same-region) |
| Max partitions per cluster (KRaft) | Millions (previously ~200K with ZK) |
| Message size (recommended max) | 1MB default, configurable to 10MB |
| Durability | Configurable: acks=all + min.insync.replicas=2 for strongest |
| Retention | Configurable: time-based, size-based, or both + tiered storage |

---

## 2. Confluent Platform

### Confluent Cloud (2025-2026)

Confluent is the commercial Kafka company (founded by Kafka creators). Key offerings:

**Cluster types:**
- **Basic/Standard**: Multi-tenant, pay-per-use, for dev/test and moderate workloads
- **Dedicated**: Single-tenant, custom networking, 99.99% SLA
- **Enterprise**: Full isolation, BYOK encryption, custom retention
- **Freight** (Q1 2025): Cost-optimized clusters for high-volume, latency-tolerant workloads (batch-like pricing for streaming)

### Tableflow (GA Q1 2025)

Tableflow automatically materializes Kafka topics as Apache Iceberg or Delta Lake tables, bridging streaming and analytics:

```
Kafka Topic → Tableflow → Iceberg/Delta Lake Table → Any Query Engine
              (automatic)   (on your object storage)   (Spark, Trino, Flink, etc.)
```

**Key capabilities:**
- Automatic topic-to-table materialization (no custom pipelines)
- Schema evolution via Confluent Schema Registry as source of truth
- Support for both Apache Iceberg and Delta Lake formats
- Integration with Databricks Unity Catalog (GA 2025)
- Azure support (early access 2025)
- Governance: inherits Stream Governance policies (data quality, lineage)

**When to use Tableflow:**
- Feeding real-time Kafka data into analytics without building custom ETL
- Keeping data warehouses in sync with operational streams
- Unifying streaming and batch analytics on Iceberg/Delta Lake

### Flink Integration

Confluent Cloud for Apache Flink provides managed Flink SQL directly on Confluent Cloud:

- Write Flink SQL against Kafka topics (no separate Flink cluster)
- Transform and enrich streams before materializing to Iceberg via Tableflow
- Serverless scaling (no cluster management)
- Unified billing with Kafka consumption

### Schema Registry and Governance

**Schema Registry** (central schema store):
- Supports Avro, Protobuf, and JSON Schema
- Compatibility enforcement: BACKWARD (default), FORWARD, FULL, NONE
- Schema ID embedded in message header — consumers auto-deserialize
- Data contracts: Define rules, metadata, and migration rules per subject
- Supports schema references (nested schemas, imports)

**Stream Governance:**
- Data lineage: Track data flow across topics and consumers
- Data quality rules: Validate messages on produce/consume
- Business metadata: Tag topics and schemas with business context
- Audit logging: Track who accessed what data and when

---

## 3. Apache Flink

### Version Timeline

| Version | Date | Milestone |
|---------|------|-----------|
| **1.18** | Oct 2023 | Watermark alignment, async I/O improvements |
| **1.19** | Mar 2024 | Materialized tables, async state APIs preview |
| **1.20** | Aug 2024 | Flink SQL enhancements, state backend improvements |
| **2.0** | Mar 2025 | **Major release.** Disaggregated state, async execution model |
| **2.1** | Jul 2025 | Stability and performance refinements |
| **2.2** | Dec 2025 | Biggest leap since 1.0 — production hardening |

### Flink 2.0 — Key Innovations

**Disaggregated State Management (ForSt):**
Flink 2.0 introduces ForSt (Flink on RocksDB over S3) — a disaggregated state backend that streams state to remote object storage:

```
Before (Flink 1.x):
  Task Manager → Local RocksDB (state on local disk)
  Problem: State size limited by local disk, slow recovery

After (Flink 2.0):
  Task Manager → ForSt → Remote Object Storage (S3/GCS)
  Benefit: State scales independently, faster recovery, elastic compute
```

**Benefits:**
- State size no longer limited by local disk
- Faster job recovery — state is already in durable storage
- Elastic compute — add/remove workers without redistributing state
- Out-of-order record processing: decouples state access from computation

**Asynchronous Execution Model:**
- Non-blocking state operations during checkpointing
- Async state APIs for full support of parallel state access
- 7 critical SQL operators reimplemented with async state access
- AsyncScalarFunction: new UDF type enabling non-blocking external calls from SQL

### Flink SQL Enhancements (2.0+)

- Window TVF (Table-Valued Function) aggregation extended to handle changelog/CDC streams
- Mini-batch optimization for regular joins (reduce state writes)
- Improved temporal join semantics
- Better complex event processing (CEP) with SQL
- Materialized tables: query streaming state as regular SQL tables

### Exactly-Once Processing

Flink provides end-to-end exactly-once semantics via:

1. **Checkpointing**: Periodic consistent snapshots of distributed state
2. **Two-phase commit sinks**: Kafka sink, JDBC sink support exactly-once
3. **Aligned/unaligned checkpoints**: Unaligned checkpoints reduce backpressure impact
4. **Idempotent sinks**: Alternative to 2PC for systems that support upsert

**Production settings:**
```
checkpoint.interval: 60s (balance recovery time vs overhead)
checkpoint.timeout: 600s
state.backend: forst (Flink 2.0+) or rocksdb (Flink 1.x)
execution.checkpointing.mode: EXACTLY_ONCE
```

### When to Choose Flink

- Complex stateful event processing at scale (the single best choice)
- Event-time processing with out-of-order data
- Exactly-once guarantees with high throughput
- Real-time CDC processing pipelines
- Large state (TBs) with disaggregated state backend
- Flink SQL for accessible stream processing

---

## 4. Apache Spark Streaming

### Version Timeline

| Version | Date | Milestone |
|---------|------|-----------|
| **3.5** | Sep 2023 | Spark Connect GA, Python DSv2 |
| **4.0** | Apr 2025 | **Major release.** ANSI SQL, transformWithState, Spark Connect enhancements |
| **4.1** | Early 2026 | Stability improvements, zstd protobuf plans, chunked Arrow streaming |

### Spark Connect (GA in 4.0)

Spark Connect enables thin client access to Spark clusters via gRPC + Apache Arrow:

```
Application (any language) → gRPC → Spark Connect Server → Spark Cluster
                             ↑
                        Apache Arrow
                        (columnar, efficient)
```

**Multi-language clients:**
- Python (primary), Scala, Java (mature)
- Go, Swift, Rust (new in 4.0)
- Any language that speaks gRPC + Arrow

**Benefits:**
- Decouple application lifecycle from Spark cluster
- Client stability (no JVM crashes in app process)
- Spark as a service: multiple apps share one cluster
- Migration: `spark.api.mode` setting for gradual transition

### Structured Streaming — transformWithState (Spark 4.0)

The biggest streaming advancement in Spark 4.0. Replaces the older `flatMapGroupsWithState`:

**Capabilities:**
- Object-oriented state definition with composite data types
- Event-driven programming model (timers, TTL)
- State schema evolution (change state shape without restarting)
- Initial state support (bootstrap from existing data)
- Parallel batch execution for multiple state operations
- State Data Source: query streaming state as a DataFrame for debugging

**When to use transformWithState:**
- Custom stateful aggregations (sessionization, complex windowing)
- Pattern detection across event streams
- Stateful enrichment with TTL-based expiration

### Spark vs Flink for Streaming

| Dimension | Spark Structured Streaming | Flink |
|-----------|---------------------------|-------|
| Processing model | Micro-batch (default), continuous mode (1ms) | True per-record streaming |
| Latency | 100ms (micro-batch), ~1ms (continuous) | <10ms typical |
| State management | In-memory + checkpoint | RocksDB/ForSt, disaggregated |
| Max state size | Limited by executor memory | TBs (with ForSt) |
| Batch+streaming unified | Same API for both (strongest) | DataStream + Table API |
| Language support | Python, Scala, Java, R, SQL | Java, Scala, Python, SQL |
| Operational overhead | Lower (reuse existing Spark) | Higher (separate Flink cluster) |
| Best for | Teams already on Spark, moderate latency OK | Latency-critical, large state, complex CEP |

---

## 5. Stream Processing Decision Matrix

### When to Use Each

```
Start Here:
  ├── Already using Kafka, need lightweight processing?
  │   └── Kafka Streams (library, no cluster)
  ├── Already running Spark for batch?
  │   └── Spark Structured Streaming (same cluster, same API)
  ├── Need sub-second latency + complex stateful processing?
  │   └── Apache Flink
  ├── Need managed stream processing on Confluent Cloud?
  │   └── Confluent Cloud for Flink (Flink SQL, serverless)
  └── Simple event routing / filtering?
      └── Kafka Streams or even Kafka Connect SMTs
```

### Detailed Comparison

| Criterion | Kafka Streams | Flink | Spark Streaming |
|-----------|--------------|-------|-----------------|
| **Deployment** | Embedded library (JAR) | Dedicated cluster | Spark cluster |
| **Scaling** | Kafka partition count | Independent parallelism | Executor-based |
| **Latency** | <10ms | <10ms | ~100ms (micro-batch) |
| **State backend** | RocksDB (local) | ForSt/RocksDB (local or remote) | In-memory + checkpoint |
| **Exactly-once** | Yes (Kafka txns) | Yes (checkpoint + 2PC) | Yes (checkpoint + idempotent) |
| **Languages** | Java, Scala only | Java, Scala, Python, SQL | Python, Scala, Java, R, SQL |
| **Windowing** | Tumbling, hopping, sliding, session | All above + custom | All above + custom |
| **Ops overhead** | None (it is your app) | Medium-high (cluster) | Low-medium (reuse Spark) |
| **Best use case** | Kafka-native microservices | Large-scale stateful streaming | Unified batch + stream |

### Kafka Streams Deep Dive

Kafka Streams is a **client library** (not a framework or cluster):

**Strengths:**
- No separate infrastructure — runs inside your Java/Kotlin microservice
- Exactly-once semantics via Kafka transactions
- Interactive queries: query local state stores from REST endpoints
- Automatic rebalancing when instances scale up/down
- Ideal for: enrichment, filtering, aggregation, joins on Kafka topics

**Limitations:**
- Java/Scala only (no Python, no SQL)
- State limited to local RocksDB (no disaggregated state)
- Parallelism capped at Kafka partition count
- No built-in support for event-time processing with late data (manual handling)

**When Kafka Streams is the wrong choice:**
- Processing data from non-Kafka sources
- Need Python/SQL interface
- State exceeds available local disk
- Complex event processing (CEP) with sophisticated pattern matching

---

## 6. Change Data Capture (CDC)

### CDC Architecture Patterns

**Log-based CDC** (recommended):
```
Database WAL/Binlog → CDC Engine → Kafka/Target
                      (Debezium)
```
- Reads the database transaction log (WAL, binlog, redo log)
- Zero impact on source database performance
- Captures all changes including DELETEs
- Sub-second latency from commit to event

**Query-based CDC** (legacy):
```
Database → Periodic SQL poll → Target
           (SELECT WHERE updated_at > ?)
```
- Misses hard DELETEs, higher source load, higher latency
- Only use when log-based CDC is unavailable

### Debezium (Open-Source Standard)

**Current version:** Debezium 3.x (3.4 as of late 2025)

**Supported databases:**
- PostgreSQL (logical decoding)
- MySQL/MariaDB (binlog)
- MongoDB (change streams)
- Oracle (LogMiner / XStream)
- SQL Server (CT / CDC)
- Cassandra, Db2, Vitess, Spanner

**Debezium 3.x features (2025):**
- Exactly-once semantics for all core connectors (3.3+)
- Debezium Server: standalone deployment without Kafka Connect
- Debezium Platform: Kubernetes-native UI for pipeline management
- Embedded engine improvements (Spring Boot integration)
- Quarkus extension for MongoDB (3.4+)

**Deployment modes:**
1. **Kafka Connect** (most common): Debezium runs as Kafka Connect connectors
2. **Debezium Server**: Standalone, sends to Kafka, Pub/Sub, Kinesis, Redis, etc.
3. **Embedded Engine**: Library embedded in your Java application

### The Outbox Pattern

Solves the dual-write problem (write to DB + publish event atomically):

```
1. Application writes domain entity + outbox event in SAME transaction
2. Debezium captures outbox table changes via CDC
3. Debezium transforms payload and routes to Kafka topic
4. Consumers process the event

Database:
┌──────────────────────────────────────────┐
│ BEGIN TRANSACTION                         │
│   INSERT INTO orders (...)                │
│   INSERT INTO outbox (                    │
│     aggregate_type = 'Order',             │
│     aggregate_id = '123',                 │
│     event_type = 'OrderCreated',          │
│     payload = '{"orderId": "123", ...}'   │
│   )                                       │
│ COMMIT                                    │
└──────────────────────────────────────────┘
         │
         ▼ (Debezium reads WAL)
     Kafka topic: order.events
```

**Debezium outbox event router:** Built-in SMT (`io.debezium.transforms.outbox.EventRouter`) that extracts outbox fields and routes to per-aggregate-type topics.

### CDC Tool Comparison

| Tool | Type | Best For | Latency | Source DB Support |
|------|------|----------|---------|-------------------|
| **Debezium** | Open-source, self-hosted | Kafka-centric, full control | Sub-second | All major RDBMS + MongoDB |
| **Fivetran** | Managed SaaS | SaaS source → warehouse (300+ connectors) | Minutes | Broad SaaS + databases |
| **Airbyte** | Open-source + cloud | EL(T), broad connectors, Debezium under hood | Minutes | 400+ connectors |
| **AWS DMS** | Managed (AWS) | AWS-native DB migrations + replication | Seconds | AWS databases + some external |
| **Streamkap** | Managed SaaS | Managed Debezium (lower ops) | Sub-second | Major RDBMS |
| **HVR/Qlik** | Enterprise | Legacy enterprise DB replication | Sub-second | Mainframe, Oracle, SAP |

### CDC Selection Guide

```
Need real-time CDC into Kafka with full control?
  → Debezium on Kafka Connect

Need managed CDC with 300+ SaaS/DB connectors into a warehouse?
  → Fivetran (budget allows) or Airbyte (open-source/self-hosted)

All AWS, doing DB migration or replication?
  → AWS DMS

Want managed Debezium without ops burden?
  → Streamkap or Confluent Cloud connectors
```

---

## 7. ETL vs ELT and Orchestration

### Modern ELT Pattern

The modern data stack follows ELT (Extract-Load-Transform):

```
Sources → Extract + Load → Data Warehouse/Lakehouse → Transform → Serve
          (Fivetran,        (Snowflake, BigQuery,      (dbt)       (BI, ML,
           Airbyte,          Databricks, Redshift)                   APIs)
           CDC)
```

**Why ELT over ETL:**
- Warehouses/lakehouses are powerful enough to handle transformation
- Raw data is preserved (reprocess with new logic anytime)
- dbt makes SQL transformations testable, version-controlled, documented
- Separation of concerns: ingestion team vs analytics engineering team

### dbt (data build tool)

**Current state:** dbt Core 1.9 (late 2024), dbt Cloud with enhanced features

**Key features in dbt 1.9:**
- **Microbatch incremental models**: Process large time-series in configurable batches (day, hour)
  - Automatic parallel batch execution
  - `lookback` parameter for late-arriving data
  - Available on Postgres, Redshift, Snowflake, BigQuery, Spark, Databricks
- **Unit tests** (introduced 1.8): Validate SQL logic on static inputs before production
- **Iceberg table support**: Native Iceberg materialization
- **YAML-based snapshots**: Cleaner SCD Type 2 configuration
- **Saved queries**: Reusable metric definitions

**dbt best practices:**
```
project/
├── models/
│   ├── staging/          # 1:1 with sources, light cleaning
│   │   ├── stg_orders.sql
│   │   └── stg_customers.sql
│   ├── intermediate/     # Business logic building blocks
│   │   └── int_order_items_enriched.sql
│   └── marts/            # Business-facing models
│       ├── fct_orders.sql
│       └── dim_customers.sql
├── tests/
│   └── assert_positive_revenue.sql
├── macros/
└── dbt_project.yml
```

### Orchestration Tools Comparison

| Tool | Architecture | Best For | dbt Integration |
|------|-------------|----------|-----------------|
| **Apache Airflow 3.0** | DAG-based, centralized scheduler | Battle-tested ETL/ELT, large community | `cosmos` provider (native) |
| **Dagster** | Asset-aware, software-defined | Data lineage, dev experience, testing | First-class `dagster-dbt` |
| **Prefect** | Python-native, dynamic | Event-driven, dynamic workflows | `prefect-dbt` |
| **Mage** | Notebook-style, batteries-included | Small teams, rapid development | Built-in |

### Apache Airflow 3.0 (GA 2025)

Major architectural redesign:

**Key features:**
- **Task Execution Interface (AIP-72)**: Client-server architecture. Tasks run in isolated environments
- **Multi-language Task SDK**: Write tasks in Java, Go, R (not just Python)
- **Event-driven scheduling**: React to external events, asset updates, message queues
- **Edge Executor**: Run tasks on remote/regional clusters, IoT, edge devices
- **Assets** (renamed from Datasets): Asset-centric workflow design with partitions
- **Modernized UI**: New React-based interface

**When Airflow 3.0 is the right choice:**
- Large team with existing Airflow DAGs
- Schedule-based ETL/ELT is the primary pattern
- Need multi-language task execution
- Broad community support and managed offerings (MWAA, Astronomer, GCC)

### Dagster

**Key differentiator:** Asset-aware orchestration (software-defined assets)

```python
# Dagster: assets are first-class
@asset
def raw_orders(context):
    return pd.read_sql("SELECT * FROM orders", conn)

@asset
def cleaned_orders(raw_orders):
    return raw_orders.dropna(subset=["customer_id"])

@asset
def daily_revenue(cleaned_orders):
    return cleaned_orders.groupby("date")["amount"].sum()
```

**Strengths:**
- Assets automatically define dependencies and lineage
- Strong local development experience (`dagster dev`)
- Built-in data quality checks on assets
- First-class dbt integration
- Type system for data assets

### Prefect

**Key differentiator:** Python-native, dynamic workflows without rigid DAG constraints

**Strengths:**
- Turn any Python function into a resilient, observable workflow
- Dynamic task generation (runtime-determined DAGs)
- Built-in retries, caching, concurrency limits
- Event-driven triggers
- Hybrid execution (cloud orchestration, self-hosted workers)

### Selection Guide

```
Large org, existing DAGs, need battle-tested reliability?
  → Airflow 3.0

Data platform team, want lineage + quality + dev experience?
  → Dagster

Dynamic Python workflows, event-driven, operational pipelines?
  → Prefect

Small team, rapid development, notebook-style?
  → Mage
```

---

## 8. Data Lakehouse and Table Formats

### The Table Format Wars (2025-2026)

Three open table formats bring ACID transactions, time travel, and schema evolution to data lakes:

| Format | Creator | Current State (2026) | Key Strength |
|--------|---------|---------------------|--------------|
| **Apache Iceberg** | Netflix | De facto standard. V3 spec ratified. Broadest engine support | Open spec, vendor-neutral, partition evolution |
| **Delta Lake** | Databricks | Strong in Databricks ecosystem. UniForm for Iceberg compat | Tight Spark integration, mature tooling |
| **Apache Hudi** | Uber | Specialized in record-level ops and CDC | Incremental pipelines, record-level indexing |

### Apache Iceberg (Recommended Default)

**Iceberg is winning the format war.** Adopted by every major cloud provider, query engine, and data platform. Gartner upgraded lakehouse to "transformational" status with Iceberg as the standard.

**Iceberg V3 (spec ratified 2025):**
- **Deletion vectors**: Bitmap-based row-level deletes — up to 10x faster than copy-on-write
- **Row lineage**: Row ID + sequence number tracks row history across versions
- **New data types**: Variant (semi-structured), geometry, geography
- **REST Catalog spec**: Language-agnostic HTTP API for catalog operations (Python, Rust, Go, JS)
- **Native encryption**: Beginning of built-in encryption support

**Iceberg architecture:**
```
Query Engine (Spark, Trino, Flink, DuckDB, etc.)
    │
    ▼
Catalog (REST Catalog, AWS Glue, Hive Metastore, Nessie)
    │
    ▼
Metadata Layer:
  ├── Metadata File (current snapshot pointer)
  ├── Manifest List (list of manifests per snapshot)
  └── Manifest Files (list of data files + column stats)
    │
    ▼
Data Files (Parquet/ORC/Avro on S3/GCS/ADLS)
```

**Key features:**
- **Partition evolution**: Change partitioning without rewriting data
- **Schema evolution**: Add, drop, rename, reorder columns without rewrite
- **Time travel**: Query any historical snapshot
- **Hidden partitioning**: Users write queries, Iceberg handles partitioning
- **Engine support**: Spark, Flink, Trino, Presto, DuckDB, Dremio, Snowflake, BigQuery, Databricks, AWS Athena

### Delta Lake

**Best in Databricks ecosystem.** Open-sourced under Linux Foundation (Delta Lake 3.x):

- Sequential transaction log (`_delta_log`) for simple versioning
- **UniForm**: Automatic Iceberg/Hudi metadata generation (read Delta tables as Iceberg)
- **Liquid Clustering**: Replaces Z-ordering with automatic data layout optimization
- **Deletion Vectors**: Row-level deletes without full file rewrites
- Tight Spark integration (Delta is the default table format in Databricks)

**When Delta Lake makes sense:**
- All-in on Databricks
- Existing Delta Lake investment
- UniForm bridges to Iceberg consumers

### Apache Hudi

**Specialized for record-level operations and incremental processing:**

- **Record-level indexing**: Efficient upserts without scanning all files
- **Incremental pipelines**: Track all changes (appends, updates, deletes) as change streams
- **Copy-on-Write + Merge-on-Read**: Choose per-table based on read vs write optimization
- Best for: CDC-heavy workloads, high-frequency upserts, incremental ETL

### Format Selection Guide

```
Starting fresh, need broad engine support?
  → Apache Iceberg (V3)

All-in on Databricks?
  → Delta Lake (UniForm for external readers)

High-frequency upserts, CDC-heavy workloads?
  → Apache Hudi

Interoperability requirement?
  → Iceberg + REST Catalog (most engines support it natively)
```

### Databricks Acquired Tabular (2024)

Databricks acquired Tabular (the Iceberg company founded by Iceberg creators) to strengthen Iceberg support. This signaled convergence: Databricks now supports both Delta Lake and Iceberg natively, with UniForm bridging the two.

---

## 9. Real-Time OLAP Engines

### Comparison Matrix

| Engine | Architecture | Ingestion | Query Latency | Best For |
|--------|-------------|-----------|--------------|----------|
| **ClickHouse** | Column-oriented, vectorized | Batch/micro-batch (Kafka connector) | Sub-second for aggregations | Single-table aggregations, log analytics |
| **Apache Druid** | Column-oriented, pre-indexed | Native streaming (Kafka) | Sub-second | Real-time dashboards, high concurrency |
| **Apache Pinot** | Column-oriented, star-tree index | Native streaming (Kafka) | Sub-second | User-facing analytics, high QPS |
| **StarRocks** | Column-oriented, vectorized | Batch + streaming | Sub-second | Unified analytics, Iceberg integration |

### ClickHouse

**Strengths:**
- Fastest for simple aggregations on large single tables
- Vectorized execution engine: processes data in columnar blocks, maximizes CPU efficiency
- **Lightweight updates** (2024): 1,600x faster mutations (60ms vs 100s) — viable for CDC now
- MergeTree engine family: excellent compression and sorting
- Massive open-source community

**Weaknesses:**
- No native streaming ingestion (use Kafka connector or micro-batch inserts)
- JOINs across large tables are expensive (denormalize for performance)
- Cluster management (replication, rebalancing) requires manual setup
- No UPDATE/DELETE historically (lightweight updates improve this significantly)

**ClickHouse Cloud**: Managed offering with auto-scaling, separation of storage and compute

### Apache Druid

**Strengths:**
- Native Kafka ingestion (true streaming, instant data visibility)
- Segment-based architecture: pre-indexed for fast aggregations
- High concurrency (thousands of QPS for dashboards)
- Mature for real-time analytics on time-series data

**Weaknesses:**
- No UPDATE or DELETE support (append-only, use lookups for dimensions)
- Complex architecture (many components: Historical, MiddleManager, Coordinator, Router, Broker)
- Higher operational overhead than ClickHouse

### Apache Pinot

**Strengths:**
- Star-tree indexing: pre-aggregated metrics for sub-second at extreme QPS
- Native Kafka ingestion with upsert support
- Designed for user-facing analytics (LinkedIn, Uber, Stripe)
- Multi-tenancy support

**Weaknesses:**
- Smaller community than ClickHouse/Druid
- Limited JOIN support
- Complex deployment (similar to Druid)

### StarRocks

**Strengths:**
- MySQL-compatible interface (easy adoption)
- Good JOIN performance (no mandatory denormalization)
- First-class Apache Iceberg support (StarRocks 4.0)
- Instant UPDATE/DELETE support
- Easy BI tool integration

**Benchmarks:** In SSB flat-table queries, StarRocks outperformed ClickHouse by ~2.2x and Druid by ~8.9x (though benchmarks vary by workload).

### OLAP Selection Guide

```
Log analytics, single-table aggregations, max raw throughput?
  → ClickHouse

User-facing dashboards, real-time streaming ingestion, high concurrency?
  → Apache Pinot (extreme QPS) or Apache Druid (mature ecosystem)

Unified analytics with JOINs, Iceberg integration, MySQL compatibility?
  → StarRocks

Managed, minimal ops, moderate scale?
  → ClickHouse Cloud or Rockset (now part of OpenAI) or Tinybird (ClickHouse-based)
```

### DuckDB for Lightweight OLAP

**DuckDB** deserves mention as the embedded OLAP engine (SQLite for analytics):
- In-process, zero-configuration
- Reads Parquet, CSV, JSON, Iceberg natively
- Excellent for local development, testing, small-to-medium analytics
- Not a replacement for distributed OLAP — use for single-node / laptop-scale workloads

---

## 10. Event Sourcing and CQRS

### When Event Sourcing Is Worth the Complexity

**Use event sourcing when:**
- Complete audit trail is a hard requirement (finance, healthcare, legal)
- Need to rebuild state at any point in time (debugging, compliance)
- Domain has complex state transitions best modeled as events
- Multiple read models needed from same write stream (CQRS)
- Event replay for analytics, ML training data, new features

**Do NOT use event sourcing when:**
- Simple CRUD is sufficient (most applications)
- Team is not experienced with the pattern (steep learning curve)
- Domain events are hard to define cleanly
- Strong consistency for reads is required without eventual consistency tolerance

### Event Store Selection

| Store | Throughput | Best For |
|-------|-----------|----------|
| **EventStoreDB** | ~15K events/sec | Purpose-built event store, native projections, subscriptions |
| **Apache Kafka** | Millions/sec | High-throughput event streaming, build ES primitives yourself |
| **PostgreSQL** (append-only table) | ~50K events/sec | Simple systems, team knows PostgreSQL, avoid new infrastructure |
| **DynamoDB Streams** | High (per-shard) | AWS-native, serverless event sourcing |

### Snapshotting Strategies

When aggregate event counts grow large, replaying all events becomes slow:

**Strategy 1: Count-based snapshots**
```
Every N events (e.g., 100), create a snapshot of current aggregate state.
Replay: Load latest snapshot + replay events after snapshot.
```

**Strategy 2: Business-boundary snapshots**
```
Create snapshots at business-meaningful boundaries:
- End of day for trading accounts
- Monthly close for financial aggregates
- After specific domain events (OrderCompleted, etc.)
```

**Snapshot hygiene:**
- Keep only latest 2-3 snapshots per aggregate
- Implement retention policy to prune old snapshots
- Store snapshots in same storage as events (co-located)
- Version snapshot schema — old snapshots must remain readable

### Projection Patterns

**Blue-green projections** (recommended for rebuilds):
```
1. Build new projection into separate table (blue)
2. Replay all events into blue table
3. Verify correctness
4. Swap blue → green (atomic rename/pointer switch)
5. Delete old green table
```

**Checkpointing:**
- Store last processed global event position per projection
- Resume from checkpoint on failure (no full replay)
- Separate checkpoint per projection consumer

**Projection rebuilding considerations:**
- Large event stores may take hours/days for full replay
- Parallelize by aggregate ID or partition
- Consider read-replica for replay to avoid impacting writes
- Test projection rebuilds regularly (not just during incidents)

### Event Design Best Practices

1. **Business-meaningful events**: `OrderShipped`, not `FieldUpdated`
2. **Past tense naming**: Events record what happened (`OrderCreated`, `PaymentReceived`)
3. **Include enough context**: Event should be self-contained (consumer should not need to look up related data)
4. **Never delete events**: Append compensating events instead (`OrderCancelled` vs deleting `OrderCreated`)
5. **Version events**: Use `event_version` field for schema evolution
6. **Upcast old events**: Transform old event versions to current version during replay

### CQRS Patterns

```
Commands → Write Model → Event Store → Event Bus → Read Model(s)
           (aggregates)   (append-only)              (projections)

Write side: Enforces business rules, produces events
Read side: Optimized query models, eventually consistent
```

**Read model strategies:**
- **Materialized views** in PostgreSQL (simplest)
- **Dedicated read databases** (Elasticsearch for search, Redis for cache, ClickHouse for analytics)
- **GraphQL layer** over projections (flexible querying)

---

## 11. Data Contracts and Schema Management

### Schema Format Comparison

| Feature | Avro | Protobuf | JSON Schema |
|---------|------|----------|-------------|
| **Encoding** | Binary (compact) | Binary (most compact) | Text (JSON) |
| **Schema location** | Embedded or registry | .proto files (separate) | Separate |
| **Code generation** | Optional | Required | Optional |
| **Schema evolution** | Excellent (best-in-class) | Good (field tags) | Limited |
| **Human readability** | Schema: yes, data: no | Schema: yes, data: no | Both: yes |
| **Null handling** | Union types | Optional fields (proto3) | Nullable types |
| **Performance** | Good | Best | Worst |
| **Ecosystem** | Hadoop/Kafka-centric | gRPC, microservices | REST APIs, web |
| **Default values** | Schema-defined | Type defaults (proto3) | Schema-defined |

### Compatibility Rules

**Backward compatible** (consumers before producers — safest default):
- New schema can read data written by old schema
- Allowed: Add optional field, remove field with default
- Confluent Schema Registry default: BACKWARD

**Forward compatible** (producers before consumers):
- Old schema can read data written by new schema
- Allowed: Remove optional field, add field with default

**Full compatible** (both directions):
- Both old and new schemas can read each other's data
- Most restrictive but safest for independent deployment

**Protobuf-specific guidance:**
- Never reuse field numbers (even after deletion)
- Use `reserved` for removed fields
- Best practice: BACKWARD_TRANSITIVE compatibility
- Adding new message types is NOT forward-compatible

**Avro-specific guidance:**
- Always provide default values for new fields
- Use union types for nullable fields: `["null", "string"]`
- Schema resolution handles missing fields automatically
- Recommended: FULL_TRANSITIVE for critical data contracts

### Data Contracts in Practice

A data contract defines the agreement between data producer and consumer:

```yaml
# Example data contract (YAML)
dataContract:
  name: "order-events"
  version: "2.1.0"
  owner: "order-service-team"
  schema:
    type: "avro"
    registrySubject: "order-events-value"
    compatibility: "BACKWARD_TRANSITIVE"
  quality:
    - rule: "order_id is never null"
    - rule: "total_amount >= 0"
    - rule: "freshness < 5 minutes"
  sla:
    availability: "99.9%"
    latency_p99: "500ms"
  consumers:
    - "analytics-pipeline"
    - "billing-service"
```

### Schema Registry Architecture

```
Producer → Serialize (schema ID in header) → Kafka → Deserialize → Consumer
              │                                            │
              └── Register/validate schema ──→ Schema ←── Fetch schema
                                              Registry
```

**Confluent Schema Registry:**
- Central store for Avro, Protobuf, JSON Schema
- Schema ID encoded in message (5-byte header)
- Compatibility enforcement per subject
- Schema references for nested/shared schemas
- REST API for schema management
- Data contracts: rules, metadata, migration rules

### Format Selection Guide

```
Kafka-centric data pipeline, need best schema evolution?
  → Avro (ecosystem standard for Kafka)

gRPC microservices, maximum performance?
  → Protobuf

REST APIs, web frontends, human-readable?
  → JSON Schema

Internal event bus with strict contracts?
  → Avro or Protobuf with Schema Registry + FULL_TRANSITIVE
```

---

## 12. Batch vs Streaming Architectures

### Architecture Comparison

| Architecture | Description | Complexity | Data Freshness |
|-------------|-------------|-----------|----------------|
| **Batch only** | Periodic ETL jobs | Low | Hours to days |
| **Lambda** | Batch + streaming (dual pipeline) | Very high | Seconds + hours |
| **Kappa** | Streaming only (replay from log) | Medium | Seconds |
| **Delta/Lakehouse** | Unified on lakehouse with ACID | Medium | Minutes to seconds |

### Lambda Architecture (Mostly Discouraged)

```
             ┌── Batch Layer (Spark) ──→ Batch Views ──┐
Raw Data ──→│                                           ├──→ Serving Layer ──→ Queries
             └── Speed Layer (Flink) ──→ Real-time Views┘
```

**Problems:**
- Two codepaths that must produce identical results
- Double the infrastructure, double the bugs
- Schema changes must be synchronized across both paths
- Testing is complex (must validate both paths agree)

**When Lambda is still justified:**
- Regulatory requirement for both real-time and batch-verified results
- Legacy systems where streaming cannot handle full historical reprocessing
- ML training (batch) + ML serving (streaming) with different compute profiles

### Kappa Architecture (Recommended for Streaming-First)

```
Raw Data ──→ Streaming Layer (Flink/Kafka Streams) ──→ Serving Layer ──→ Queries
                    │
                    └── Replay from Kafka for reprocessing
```

**Benefits:**
- Single codebase, single pipeline
- Replay from Kafka log for reprocessing / backfill
- Simpler operations and testing

**Limitations:**
- Kafka retention must cover reprocessing window (cost for long retention)
- Complex analytical queries may be slow on streaming engine
- Not all workloads fit pure streaming (some are inherently batch)

### Delta/Lakehouse Architecture (Modern Default in 2025-2026)

```
Sources ──→ Streaming Ingestion ──→ Lakehouse (Iceberg/Delta) ──→ Query Engines
            (Kafka, CDC, Flink)     (ACID, time travel)            (Spark, Trino, DuckDB)
                                          │
                                          └── Both batch and streaming read/write
                                              from the same tables
```

**Why this is the modern default:**
- Single source of truth with ACID guarantees
- Streaming writes (Flink, Spark Streaming) and batch reads (Spark, Trino) on same tables
- Time travel enables point-in-time queries without separate batch views
- Iceberg V3 makes row-level updates efficient
- No dual-codebase problem

### Decision Framework

```
All data arrives as events, need real-time only?
  → Kappa (Kafka + Flink/Kafka Streams)

Need both real-time AND historical analytics?
  → Delta/Lakehouse (Iceberg + streaming ingestion + batch query engines)

Regulatory requirement for batch-verified results alongside real-time?
  → Lambda (rare, but legitimate)

Simple daily/hourly analytics, no real-time requirement?
  → Batch ETL (Airflow + dbt + warehouse)
```

---

## 13. Data Quality and Observability

### Data Quality Testing Tools

| Tool | Type | Best For | Integration |
|------|------|----------|-------------|
| **dbt tests** | SQL assertions | dbt users, basic quality checks | Native to dbt |
| **Great Expectations (GX)** | Python framework | Complex validations, data profiling | Python pipelines, Airflow |
| **Soda** | YAML-based checks + SaaS | Simple setup, broad warehouse support | dbt, Airflow, Spark |
| **Deequ** | Spark-native (Amazon) | Large-scale Spark pipelines | AWS Glue, EMR |

### dbt Tests (Simplest Starting Point)

```yaml
# schema.yml
models:
  - name: fct_orders
    columns:
      - name: order_id
        tests:
          - not_null
          - unique
      - name: total_amount
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
      - name: customer_id
        tests:
          - relationships:
              to: ref('dim_customers')
              field: customer_id
```

**dbt test categories:**
- **Generic tests**: not_null, unique, accepted_values, relationships
- **Singular tests**: Custom SQL assertions (one-off)
- **Unit tests** (1.8+): Validate transformation logic on static inputs
- **dbt-utils**: Additional tests (recency, equal_rowcount, expression_is_true)
- **dbt-expectations**: Great Expectations-style tests in dbt

### Great Expectations (GX)

Open-source Python framework for data validation:

**Key concepts:**
- **Expectations**: Individual quality checks (e.g., `expect_column_values_to_not_be_null`)
- **Expectation Suites**: Collections of expectations for a dataset
- **Checkpoints**: Run suites against data batches
- **Data Docs**: Auto-generated documentation of quality results

**Best for:** Complex validation logic, data profiling, Python-heavy pipelines

### Data Observability Platforms

| Platform | Type | Key Feature | Pricing |
|----------|------|-------------|---------|
| **Monte Carlo** | SaaS | ML-powered anomaly detection, broad integration | Enterprise ($$$) |
| **Elementary** | Open-source (dbt-native) | dbt integration, anomaly detection, Slack alerts | Free (OSS) + paid cloud |
| **Soda** | Open-source + SaaS | YAML-based checks, SodaCL language | Free (core) + paid cloud |
| **Metaplane** | SaaS | Warehouse-native monitoring, lineage | Mid-market |
| **Bigeye** | SaaS | Automated quality metrics, ML anomaly detection | Enterprise |

### Data Quality Strategy

**Layer 1: Prevention (at write time)**
- Schema Registry with compatibility enforcement
- Input validation in application layer
- Data contracts between producer and consumer teams

**Layer 2: Detection (at transformation time)**
- dbt tests on staging and mart models
- Great Expectations / Soda checks in pipelines
- Unit tests for transformation logic

**Layer 3: Monitoring (continuous)**
- Data observability platform (Monte Carlo, Elementary)
- Freshness monitoring (data arriving on time?)
- Volume monitoring (expected row counts?)
- Schema change detection
- Distribution anomaly detection (ML-based)

**Layer 4: Response**
- Automated alerts (Slack, PagerDuty)
- Circuit breakers (stop pipeline on quality failure)
- Incident response runbook for data issues

---

## 14. Managed Streaming Services

### Cloud-Native Streaming Comparison

| Service | Provider | Model | Throughput | Latency | Ordering |
|---------|----------|-------|-----------|---------|----------|
| **Amazon Kinesis** | AWS | Shard-based | 1MB/sec/shard write | 200ms-1s | Per-shard |
| **Amazon MSK** | AWS | Managed Kafka | Kafka-equivalent | Kafka-equivalent | Per-partition |
| **Google Pub/Sub** | GCP | Serverless | 100MB/sec/topic | Sub-second | No guarantee (ordered mode available) |
| **Azure Event Hubs** | Azure | Partition-based | 1MB/sec/partition | <10ms | Per-partition |
| **Confluent Cloud** | Multi-cloud | Managed Kafka | Kafka-equivalent | Kafka-equivalent | Per-partition |
| **Amazon Kinesis Data Streams** | AWS | Shard-based | 1MB/sec/shard | 200ms-1s | Per-shard |
| **Redpanda Cloud** | Multi-cloud | Managed (Kafka-compatible) | Higher per-node | Lower than Kafka | Per-partition |

### Amazon Kinesis

**Best for:** AWS-native workloads with moderate throughput

- **Kinesis Data Streams**: Custom consumers (KCL), Kafka alternative
- **Kinesis Data Firehose**: Zero-code delivery to S3, Redshift, Elasticsearch
- **Limitations**: 1MB/sec per shard write, 2MB/sec per shard read, 7-day max retention (365 with extended)
- **Scaling**: Must manually split/merge shards (or use on-demand mode)
- **Cost**: Per shard-hour + per PUT payload unit

**When to choose Kinesis:**
- Fully AWS, moderate volume (<100K events/sec)
- Want zero-ops with Firehose for S3/Redshift delivery
- Lambda integration for serverless processing

### Google Pub/Sub

**Best for:** GCP-native, unpredictable spikes, truly serverless

- **Serverless**: No shards, no partitions to manage, no capacity planning
- **Throughput**: Automatically scales to handle spikes
- **Ordering**: Available via ordering keys (optional)
- **Exactly-once delivery**: Supported with Dataflow
- **Global**: Automatic multi-region replication

**When to choose Pub/Sub:**
- GCP-native workloads
- Unpredictable traffic spikes
- Want zero infrastructure management
- Global event distribution

### Azure Event Hubs

**Best for:** Azure-native with Kafka compatibility

- **Kafka-compatible endpoint**: Use Kafka clients without managing Kafka
- **Integration**: Azure Stream Analytics, Azure Functions, Databricks
- **Capture**: Built-in capture to Azure Blob Storage / Data Lake
- **Tiers**: Basic, Standard, Premium, Dedicated

**When to choose Event Hubs:**
- Azure-native workloads
- Want Kafka API compatibility without Kafka ops
- Need tight Azure ecosystem integration

### Amazon MSK (Managed Kafka)

- Full Apache Kafka (not a Kafka-like service)
- MSK Serverless: Auto-scaling, pay-per-use Kafka
- MSK Connect: Managed Kafka Connect connectors
- VPC-native, IAM authentication
- Supports tiered storage

### Selection Decision Tree

```
Which cloud are you primarily on?
├── AWS:
│   ├── Need Kafka ecosystem/API? → Amazon MSK (or MSK Serverless)
│   ├── Moderate volume, simple delivery to S3? → Kinesis Data Firehose
│   └── Custom processing, moderate volume? → Kinesis Data Streams
├── GCP:
│   ├── Unpredictable spikes, truly serverless? → Google Pub/Sub
│   └── Need Kafka API? → Confluent Cloud on GCP
├── Azure:
│   ├── Want Kafka compatibility? → Azure Event Hubs (Kafka endpoint)
│   └── Simple event ingestion? → Azure Event Hubs (native)
└── Multi-cloud or cloud-agnostic:
    ├── Need full Kafka ecosystem? → Confluent Cloud
    ├── Want Kafka-compatible, higher performance? → Redpanda Cloud
    └── Self-managed with maximum control? → Apache Kafka (KRaft)
```

### Cost Considerations

| Service | Pricing Model | Typical Cost (1TB/day) |
|---------|--------------|----------------------|
| **Self-managed Kafka** | EC2/compute + storage | $2K-5K/mo (3-broker cluster) |
| **Amazon MSK** | Broker-hours + storage + throughput | $3K-8K/mo |
| **MSK Serverless** | Cluster-hours + storage + throughput | Variable (good for bursty) |
| **Kinesis** | Shard-hours + PUT units | $1K-3K/mo |
| **Confluent Cloud** | CKU-hours + storage + networking | $3K-10K/mo |
| **Google Pub/Sub** | Per message + storage + egress | $1K-4K/mo |
| **Azure Event Hubs** | Throughput units + capture | $2K-6K/mo |

*Costs vary significantly by region, networking, and exact workload. Always run a proof-of-concept with realistic load.*

---

## Production Architecture Patterns

### Pattern 1: Real-Time Analytics Pipeline

```
Application DBs → Debezium (CDC) → Kafka → Flink (enrich/transform) → ClickHouse → Dashboards
                                     │
                                     └→ Iceberg (via Tableflow or Flink) → Spark/Trino (batch analytics)
```

### Pattern 2: Event-Driven Microservices

```
Service A → Kafka (event bus) → Service B
              │                    │
              ├→ Kafka Streams     ├→ Write to own DB
              │  (lightweight      └→ Publish result events
              │   processing)
              │
              └→ Schema Registry (enforce contracts)
```

### Pattern 3: Modern ELT Data Platform

```
SaaS Sources → Fivetran/Airbyte → Snowflake/BigQuery → dbt (transform) → BI/ML
                                       │
App DBs → Debezium (CDC) → Kafka ─────┘
                                       │
                                       └→ Iceberg (data lake) → Spark/DuckDB (ad-hoc)

Orchestration: Airflow 3.0 or Dagster
Quality: dbt tests + Elementary/Monte Carlo
```

### Pattern 4: Streaming-First Lakehouse

```
Sources → Kafka → Flink → Iceberg Tables (on S3) → Query Engines
                    │                                    │
                    ├→ Real-time aggregations             ├→ Trino (interactive)
                    ├→ CDC processing                     ├→ Spark (batch)
                    └→ Stream enrichment                  └→ DuckDB (ad-hoc)

Catalog: Iceberg REST Catalog (or Nessie for git-like branching)
Quality: Great Expectations + Soda
Observability: Monte Carlo or Elementary
```

---

## Quick Reference: Technology Selection Cheat Sheet

| Need | First Choice | Alternative |
|------|-------------|-------------|
| **Event streaming** | Apache Kafka (KRaft) | Redpanda (simpler ops) |
| **Stream processing (complex)** | Apache Flink | Spark Structured Streaming |
| **Stream processing (lightweight)** | Kafka Streams | Flink SQL |
| **Managed Kafka** | Confluent Cloud | Amazon MSK |
| **CDC from databases** | Debezium | Fivetran (managed) |
| **Data lake table format** | Apache Iceberg | Delta Lake (if Databricks) |
| **SQL transformations** | dbt | Spark SQL |
| **Orchestration** | Airflow 3.0 | Dagster |
| **Real-time OLAP** | ClickHouse | Apache Pinot (user-facing) |
| **Schema management** | Confluent Schema Registry | AWS Glue Schema Registry |
| **Data quality (dbt users)** | dbt tests + Elementary | Soda |
| **Data quality (Python pipelines)** | Great Expectations | Soda Core |
| **Data observability** | Monte Carlo (enterprise) | Elementary (open-source) |
| **Batch analytics** | Spark + Iceberg | Trino + Iceberg |
| **Event sourcing store** | EventStoreDB (dedicated) | PostgreSQL (simple) |
| **Serialization format** | Avro (Kafka) / Protobuf (gRPC) | JSON Schema (REST APIs) |
