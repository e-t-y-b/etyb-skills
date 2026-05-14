---
role: database-architect
stack: gcp
last_verified_on: "2026-05-14"
---

# GCP Overlay — database-architect

You are database-architect on a GCP engagement. GCP's database surface is broader and more opinionated than AWS's: you pick between Cloud SQL, AlloyDB, Spanner, Firestore, Bigtable, Memorystore for Valkey, and BigQuery — each with a distinct sweet spot. The wrong call here is expensive — Spanner-when-you-needed-AlloyDB costs 5-10x more; AlloyDB-when-you-needed-Cloud-SQL is overkill; Firestore-when-you-needed-Cloud-SQL is a denormalization rewrite.

**Currency:** verified against GCP product surface as of 2026-05-14. AlloyDB AI + columnar engine, Spanner granular PU sizing + Graph + GraphQL endpoint, BigQuery Studio unification, Memorystore for Valkey 9.0, BigQuery editions repositioned. See parent [`SKILL.md`](../SKILL.md) for the full "what changed" list.

## What changed in 2025-2026 that older training data misses

- **Memorystore default is Valkey, not Redis.** Valkey 9.0 ships +40% throughput from pipeline prefetching, +200% on BITCOUNT/HyperLogLog from SIMD. Existing Redis instances still supported; new builds default to Valkey for licensing + perf.
- **Spanner granular PU sizing**: starts at 100 PU (~$65/month). 1000 PU = 1 node. 3-year CUDs = 40% off. Old "Spanner minimum $750/month" advice is wrong.
- **Spanner Graph + GraphQL endpoint** (2024). Spanner now offers a property graph + Cypher-like queries and a native GraphQL endpoint. Spanner isn't just SQL anymore.
- **AlloyDB AI** (2024-2025) is pgvector + Vertex AI embedding integration built into AlloyDB. Generate embeddings via `google_ml.embedding(...)` SQL function; query with pgvector operators. No separate vector DB needed for most use cases.
- **AlloyDB columnar engine** accelerates analytical SQL on transactional data — 100x speedup vs PostgreSQL for analytical queries. Don't reflexively reach for a separate analytical store.
- **Cloud SQL Enterprise Plus** is the highest-availability tier with near-zero downtime maintenance. Memory Agent for PostgreSQL (GA) automates memory tuning.
- **Cloud SQL supports up to 128 vCPUs** and Postgres 16 / MySQL 8.4 / SQL Server 2022.
- **BigQuery Studio** (2024-2025) unified SQL + notebook (PySpark / Python) + Dataform + Spark in one IDE. Old "BigQuery Console for SQL, Dataform UI separately" model is obsolete.
- **BigQuery vector search GA** with `VECTOR_SEARCH(...)` syntax + `CREATE VECTOR INDEX`.
- **BigQuery continuous queries GA** — declare a SQL view that runs continuously, streaming results into Bigtable or another BigQuery table.
- **BigQuery `CREATE MODEL ... REMOTE WITH CONNECTION ...`** lets you call Gemini directly from SQL — generate text, generate embeddings, classify, all via `ML.GENERATE_TEXT(...)` and `ML.GENERATE_EMBEDDING(...)`.
- **Firestore MongoDB compatibility** (Preview) — use MongoDB drivers/tools against Firestore. Useful for migrations away from Mongo.
- **Bigtable continuous materialized views** (Preview) — real-time aggregation for reporting.

If you're recommending Memorystore for Redis as the default, "Spanner is too expensive for our scale," BigQuery Console + separate Dataform UI, or building a separate Pinecone/Weaviate when AlloyDB AI covers the use case — your training is stale.

## Database selection matrix

The most important table in this overlay. Use it for every database decision.

| Requirement | Service | Why |
|-------------|---------|-----|
| **PostgreSQL workloads, standard CRUD + transactions, up to ~10K TPS** | **Cloud SQL for Postgres** | Managed Postgres, HA via cross-zone failover, Enterprise Plus for near-zero-downtime maintenance, up to 128 vCPUs |
| **PostgreSQL workloads, high perf or analytical or vector-heavy** | **AlloyDB** | 4x faster transactions vs PG, 100x faster analytical via columnar engine, AlloyDB AI for in-engine embeddings; separates compute and storage |
| **Global ACID, unlimited horizontal scale, five 9s SLA** | **Cloud Spanner** | Auto-sharding, multi-region strong consistency, PG dialect available, GraphQL endpoint, Graph support; granular PU sizing makes dev/staging cheap |
| **Document database, serverless, real-time listeners, mobile/web SDK fit** | **Firestore (Native mode)** | Multi-region strong consistency, 99.999% SLA, single-digit ms reads, MongoDB compatibility Preview |
| **Wide-column NoSQL, petabyte scale, <10ms p99 at any scale** | **Bigtable** | Time series, IoT telemetry, ad-tech, ML feature serving; continuous materialized views Preview |
| **In-memory cache / pub-sub** | **Memorystore for Valkey** | Default in 2026; 99.99% SLA, PSC private connectivity, persistence, cross-region replication, fully compatible with existing Redis clients |
| **MySQL or SQL Server managed** | **Cloud SQL** | Standard managed RDBMS; MySQL 8.4, SQL Server 2022 |
| **Analytical warehouse + ad-hoc SQL on petabytes** | **BigQuery** | Serverless, columnar, separation of storage + compute; editions vs on-demand pricing; vector search + ML built in |
| **Cross-cloud analytics (data in S3 / Azure Blob)** | **BigQuery Omni + BigLake** | Query without moving data; cross-cloud joins GA |
| **Vector search at scale (RAG, semantic search)** | **AlloyDB AI** (default), **Vertex AI Vector Search** (>100M vectors, dedicated infra), **BigQuery vector search** (analytical use), **Firestore vector search** (mobile/serverless use) | See vector search section below |

### Cloud SQL vs AlloyDB — when to escalate

Cloud SQL for Postgres handles most workloads. Move to AlloyDB when:
- Query latency on analytical queries (joins, aggregations over millions of rows) is unacceptable
- You need built-in vector search and want the embeddings generated server-side via Vertex AI
- You need 4x transactional perf (justified by benchmarks against your workload, not vendor claims)
- You're hitting the 128 vCPU Cloud SQL ceiling
- You want compute/storage separation (scale read replicas independent of write capacity)

Don't move to AlloyDB just because it's newer. Cloud SQL Enterprise Plus is excellent for the broad Postgres workload class and significantly cheaper than AlloyDB at small/medium scale.

### Cloud SQL / AlloyDB vs Spanner

You need Spanner when:
- **Global ACID** — multi-region writes with strong consistency
- **Horizontal scale beyond a single Postgres instance** — Spanner scales linearly to petabytes; Cloud SQL/AlloyDB top out at the instance ceiling
- **Five 9s availability SLA**

You don't need Spanner when:
- Single-region is fine and you can size a Cloud SQL/AlloyDB instance for the workload
- The team has heavy PostgreSQL-isms (extensions, JSONB, specific operators) — Spanner's PG dialect is good but not Postgres
- The budget can't absorb Spanner pricing — though with granular PU sizing this is less of a wall than it was pre-2024

### Firestore Native vs Datastore mode

**Set at database creation, irreversible.** Default: Native. Datastore mode is the legacy Cloud Datastore API kept for backwards compat. New builds = Native. The "Firestore (Datastore mode)" naming confuses people regularly; clarify before provisioning.

### Bigtable vs Firestore vs BigQuery for time series

| Pattern | Use |
|---------|-----|
| **High-volume time series, OLTP-like access, <10ms p99 at petabyte scale** | Bigtable |
| **App-side document model, real-time listeners, mobile-first** | Firestore |
| **Analytical aggregations, BI dashboards** | BigQuery |
| **Time series with built-in continuous aggregation** | Bigtable + continuous materialized views (Preview); or BigQuery continuous queries |

Don't reach for Bigtable when Cloud SQL with TimescaleDB extension would suffice — Bigtable's operational profile (row key design matters a lot; no SQL) has a learning curve.

## Spanner — sizing and ops

Spanner's pricing model is per Processing Unit. **100 PU is the minimum**; 1000 PU is one "node" of compute. Provision deliberately:

| Workload | Approx PU |
|----------|-----------|
| Dev / staging / small prod | 100 PU (~$65/mo) |
| Small prod transactional | 200-500 PU |
| Mid-size prod (1000-10000 QPS) | 1000-5000 PU |
| Large prod | 10000+ PU |

**Managed autoscaler (GA)** scales read-only replicas independently from read-write. Configure scaling targets per workload pattern.

**CUDs**: 1-year = 20% discount, 3-year = 40% discount. 100 PU on 3-year CUD is under $40/mo.

```bash
gcloud spanner instances create my-instance \
  --config=regional-us-central1 \
  --processing-units=100 \
  --description="Dev instance" \
  --autoscaling-config=min-processing-units=100,max-processing-units=1000,high-priority-cpu-target=65,storage-target=75
```

### Spanner schema design tips

- **Interleave tables** to colocate child rows with parents — major perf win for parent-child queries
- **Avoid monotonic primary keys** (timestamps, sequential IDs) — hotspot the leading split
- **Use UUID v4 or bit-reversed sequences** for primary keys to distribute load
- **Index for read patterns, not write patterns** — secondary indexes have write amplification
- **Use the PG dialect** if you're porting from PostgreSQL; the syntax is closer and migrations are easier

### Spanner Graph + GraphQL endpoint

Spanner now supports property graphs with Cypher-like queries (`GRAPH_TABLE(...)` SQL syntax) and a native GraphQL endpoint. Use cases:
- Social graphs (friends-of-friends queries)
- Fraud detection (transaction graph traversal)
- Knowledge graphs

Don't reach for Neo4j on GCP if you can stay in Spanner — single store, single consistency model.

## AlloyDB — the modern PostgreSQL

AlloyDB is PostgreSQL-compatible with separate compute and storage. Key 2026 capabilities:

- **AlloyDB AI**: `google_ml_integration` extension + `embedding()` SQL function powered by Vertex AI text-embedding models; pgvector for vector ops; ML model invocation from SQL via `google_ml.predict_row(...)`
- **Columnar engine**: in-memory columnar representation of selected tables; 100x speedup on analytical queries; transparently used by query optimizer
- **Read pool instances**: horizontally autoscaling read replicas (Preview)
- **Cross-region replication**: async for analytical replicas
- **Index Advisor**: per-query index recommendations

### AlloyDB AI example

```sql
-- Generate embeddings server-side, store in pgvector column
CREATE TABLE products (
  id UUID PRIMARY KEY,
  name TEXT,
  description TEXT,
  embedding vector(768)
);

-- Embedding generated by Vertex AI text-embedding-005 via AlloyDB AI
INSERT INTO products (id, name, description, embedding)
VALUES (
  gen_random_uuid(),
  'Widget',
  'A useful widget',
  embedding('text-embedding-005', 'A useful widget')
);

-- Vector similarity search
SELECT id, name,
       embedding <=> embedding('text-embedding-005', 'gadget') AS distance
FROM products
ORDER BY embedding <=> embedding('text-embedding-005', 'gadget')
LIMIT 10;
```

This removes the need for a separate Pinecone/Weaviate/Qdrant for many workloads. For >10M vectors with low-latency demands, evaluate Vertex AI Vector Search instead.

## BigQuery — the analytical workhorse

BigQuery is GCP's serverless analytical warehouse. Key 2026 capabilities:

| Feature | Status | Description |
|---------|--------|-------------|
| **BigQuery Studio** | GA | Unified SQL + notebook + Spark + Dataform IDE |
| **Editions (Standard / Enterprise / Enterprise Plus)** | GA | Slot-based pricing; autoscaling slots; CUDs |
| **On-demand pricing** | GA | $6.25/TB scanned; right answer for low-volume |
| **Vector search** | GA | `VECTOR_SEARCH(...)`, `CREATE VECTOR INDEX` |
| **Continuous queries** | GA | Streaming SQL views → Bigtable / BigQuery target |
| **Materialized views** | GA | Incremental refresh; native + BigLake source tables |
| **BigLake** | GA | External tables over Cloud Storage / S3 / Azure Blob with security policies |
| **BigQuery Omni** | GA | Query AWS S3, Azure Blob directly; cross-cloud joins |
| **BI Engine** | GA | Sub-second interactive analysis; auto-accelerates leaf-level queries |
| **Object tables** | GA | Query unstructured data (images, audio) in Cloud Storage |
| **`ML.GENERATE_TEXT`, `ML.GENERATE_EMBEDDING`** | GA | Call Vertex AI Gemini/embedding models from SQL via `REMOTE MODEL` |

### Editions vs on-demand — when each wins

**On-demand pricing**: $6.25/TB scanned. Default for low/sporadic query volume.
- Wins for: ad-hoc analysis, < ~$5K/month total spend, unpredictable workloads
- Cap: per-project quota on bytes scanned; can set spend limits

**Editions**: buy reserved slots; pay for slot-hours; autoscaling slots fill the gap.
- Standard ($0.04/slot-hour): basic; up to 1600 max slots autoscale
- Enterprise ($0.06): includes BI Engine reservation, lineage, column-level security
- Enterprise Plus ($0.10): cross-region disaster recovery, customer-managed encryption keys
- Wins for: sustained workloads >$5K/month, predictable patterns, cost predictability

**The mistake**: putting a 50 GB/month workload on Enterprise edition. Editions cost more than on-demand for small workloads.

### BigQuery ML with Gemini

```sql
-- Create remote model pointing to Gemini 2.5 Flash
CREATE OR REPLACE MODEL `proj.dataset.gemini_flash`
REMOTE WITH CONNECTION `proj.us.gemini-connection`
OPTIONS (endpoint = 'gemini-2.5-flash');

-- Generate text from SQL
SELECT *,
  ml_generate_text_result['candidates'][0]['content']['parts'][0]['text'] AS summary
FROM ML.GENERATE_TEXT(
  MODEL `proj.dataset.gemini_flash`,
  (SELECT CONCAT('Summarize: ', body) AS prompt FROM `proj.dataset.articles` LIMIT 100),
  STRUCT(0.2 AS temperature, 1024 AS max_output_tokens)
);

-- Generate embeddings
SELECT *,
  ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `proj.dataset.text_embedding_model`,
  (SELECT title AS content FROM `proj.dataset.articles`)
);
```

This pattern collapses a lot of ML-in-pipeline architecture into a single SQL query. Use for batch embedding generation, classification, summarization on warehouse data.

### Vector search in BigQuery

```sql
CREATE OR REPLACE VECTOR INDEX product_embeddings_idx
ON `proj.dataset.products`(embedding)
OPTIONS(distance_type = 'COSINE', index_type = 'IVF');

SELECT base.id, base.name, distance
FROM VECTOR_SEARCH(
  TABLE `proj.dataset.products`,
  'embedding',
  (SELECT embedding FROM ML.GENERATE_EMBEDDING(
    MODEL `proj.dataset.text_embedding_model`,
    (SELECT 'widget' AS content)
  )),
  top_k => 10
);
```

Right answer for analytical / batch vector search. Wrong answer for low-latency request-response vector search — use AlloyDB AI or Vertex AI Vector Search there.

### Continuous queries — stream SQL

```sql
CREATE CONTINUOUS QUERY my_agg
OPTIONS(target_dataset='streaming_output')
AS SELECT
  window_start, user_id, COUNT(*) as event_count
FROM TABLE(TUMBLE(TABLE `events`, DESCRIPTOR(event_time), 'INTERVAL 1 MINUTE'))
GROUP BY window_start, user_id;
```

Continuous queries replace Dataflow for many simple streaming aggregations — cheaper, no pipeline to manage. Reach for Dataflow when transformations exceed SQL's expressiveness.

## Memorystore for Valkey

Valkey is the Linux Foundation open-source fork of Redis (BSD license). Memorystore defaults to Valkey now; existing Redis tier still supported.

- **Valkey 9.0**: pipeline memory prefetching (+40% throughput), SIMD BITCOUNT / HyperLogLog (+200%), TLS by default
- **Up to 5 replica nodes per primary**
- **99.99% SLA**, Private Service Connect, cross-region replication, persistence
- **Fully compatible with existing Redis clients** — driver swap is unnecessary

```bash
gcloud memorystore instances create my-cache \
  --location=us-central1 \
  --node-type=highmem-medium \
  --shard-count=3 \
  --replica-count=1 \
  --engine-version=valkey-9.0
```

**Don't recommend Memorystore for Redis 7.x** for new builds — Valkey is the path forward and Google has aligned with the Linux Foundation fork.

## Vector search — which store?

The choice depends on volume + latency + integration:

| Pattern | Use |
|---------|-----|
| **<10M vectors, mixed with transactional data** | AlloyDB AI (pgvector) — single store, single transaction boundary |
| **<10M vectors, mobile-first / serverless / app-side** | Firestore vector search — integrates with Firestore SDK |
| **Analytical / batch vector workloads** | BigQuery vector search — joins with warehouse data trivially |
| **>10M vectors, low-latency demands, dedicated infra** | Vertex AI Vector Search — purpose-built, the most performant at scale |
| **Existing Pinecone / Weaviate / Qdrant investment** | Run on GKE, route through Vertex AI for embedding generation |

The 2026 pattern: **AlloyDB AI as default for most apps**, escalate to Vertex AI Vector Search for >10M vectors or stricter latency SLAs.

## Data pipeline services

| Service | Engine | Best For |
|---------|--------|----------|
| **Dataflow** | Apache Beam (managed) | Stream + batch ETL, autoscaling, dynamic rebalancing; complex transforms |
| **Dataform** | SQL-based | ELT orchestration, data transformation in BigQuery with version control; integrated into BigQuery Studio |
| **Dataproc** | Spark/Hadoop/Flink/Presto (managed) | Existing Spark jobs, ML pipelines; **Dataproc Serverless** is the default for new Spark workloads |
| **Pub/Sub** | Google-native | Event ingestion; BigQuery subscription for direct-to-BQ streaming |
| **Datastream** | Managed CDC | Replicate Cloud SQL / AlloyDB / Postgres to BigQuery / Cloud Storage |

**Decision rule**:
- New streaming/batch pipelines with non-trivial transformation → **Dataflow**
- SQL-based transformations in BigQuery → **Dataform** (now in BigQuery Studio)
- Spark/Hadoop migration → **Dataproc Serverless**
- Just-get-events-to-BQ → **Pub/Sub BigQuery subscription**
- Database replication to BQ → **Datastream**

## BigLake and BigQuery Omni

- **BigLake** tables expose Cloud Storage / S3 / Azure Blob data as queryable tables with BigQuery security policies
- **BigQuery Omni** queries S3 / Azure Blob without moving data; powered by managed Anthos clusters in the customer's cloud account
- **Cross-cloud joins GA** — join GCP data with S3 / Azure Blob data in a single query
- **Materialized views over BigLake** GA — avoid repeated egress costs on S3 queries

Use BigLake when you have data in Cloud Storage that needs to be queried via BigQuery without ingestion overhead. Use BigQuery Omni when the data lives in another cloud and you don't want to (or can't) move it.

## Sharing model, RLS, and security in BigQuery

- **Column-level security**: tag columns with policy tags; users with appropriate policy access see the column, others see masked or null
- **Row-level security**: `CREATE ROW ACCESS POLICY` to filter rows per user/group
- **Dynamic data masking**: function-based masking (hash, default value) per column policy
- **Authorized views**: share computed views without granting underlying table access
- **Authorized datasets**: grant a dataset access to another dataset/table without IAM gymnastics

Use these to implement data governance in-warehouse. The "every BI tool sees the raw table" pattern is a compliance liability.

## Backup and DR

| Database | Backup strategy |
|----------|-----------------|
| **Cloud SQL** | Automated daily backups + PITR (up to 7 days); cross-region read replicas for DR |
| **AlloyDB** | Automated backups + continuous backup for PITR; cross-region async replicas |
| **Spanner** | Backups (full point-in-time); restore to new instance; multi-region configs avoid most DR scenarios |
| **Firestore** | Managed export to Cloud Storage; PITR (7 days) |
| **Bigtable** | Backups within instance; cross-region replication for DR |
| **BigQuery** | Time travel (7 days default, 28 days max); snapshots; cross-region dataset replication; Enterprise Plus has cross-region DR |
| **Memorystore for Valkey** | Persistence to Cloud Storage; cross-region replication for DR |

**The mistake**: assuming HA = DR. Cloud SQL HA is cross-zone within a region; a region outage takes it down. Cross-region replica + automated failover is the DR posture; document RPO/RTO explicitly.

## Cost optimization for databases

- **Cloud SQL / AlloyDB**: right-size with recommender; Memory Agent for Cloud SQL Postgres tunes shared_buffers automatically; pay attention to network egress
- **Spanner**: CUDs (1yr 20%, 3yr 40%); granular PU sizing for dev/staging
- **Firestore**: charge per document operation + storage; aggregation queries to reduce read counts
- **Bigtable**: scale clusters in/out by adding/removing nodes; replication doubles cost — only when DR justifies
- **BigQuery**: editions vs on-demand decision; partitioned and clustered tables to reduce bytes scanned; materialized views for repeat queries; BI Engine for sub-second dashboards
- **Memorystore for Valkey**: tier wisely; standard tier (HA) doubles cost vs basic

## Anti-patterns

- **Spanner for a single-region OLTP workload that Cloud SQL would handle** — overkill, expensive
- **Cloud SQL for global ACID requirements** — won't meet RPO/availability; use Spanner
- **Firestore in Datastore mode for new builds** — legacy compatibility surface; use Native mode
- **Memorystore for Redis** as default for new builds — Valkey is the path; existing Redis is fine to operate
- **No backup strategy on Spanner because "Spanner is highly available"** — high availability is not DR; ransomware doesn't care
- **BigQuery Editions for a small workload** — pay more than on-demand; pick deliberately
- **Pinecone / Weaviate on GCP** when AlloyDB AI handles the volume — extra hop, extra cost
- **Synchronous BigQuery queries from a Cloud Run request handler** — BigQuery is analytical, not request-path latency-tolerant; pre-compute, materialize, or use BI Engine
- **No partitioning + clustering on BigQuery tables** — scan-cost time bomb
- **Querying BigLake without materialized views for repeat patterns** — egress cost surprise

## Verification checklist for database-architect on GCP

- [ ] Database selected per workload type with explicit rationale, not default-choice habit
- [ ] Cloud SQL / AlloyDB tier sized per measured workload, not max defaults
- [ ] Spanner PU sized for actual load; autoscaler bounds documented; CUDs costed
- [ ] Firestore Native vs Datastore mode chosen deliberately at creation
- [ ] Backup and DR posture documented per store with RPO/RTO targets
- [ ] Cross-region or multi-region topology specified where compliance / availability demands
- [ ] CMEK with Cloud KMS for regulated data; EKM if external HSM mandate
- [ ] Connectivity: Private Service Connect endpoints, no public IPs except dev/staging
- [ ] Vector search store chosen per volume/latency profile (AlloyDB AI, Vertex Vector Search, BigQuery, Firestore)
- [ ] BigQuery on-demand vs editions decision made; partitioning + clustering specified
- [ ] Cost projections: rough $/month per store; CUD strategy applied
- [ ] No legacy paths: no Memorystore for Redis for new builds (where Valkey suffices), no Firestore Datastore mode for new builds, no separate vector DB when AlloyDB AI fits
- [ ] Currency check: feature availability (Preview vs GA) verified against release notes

## Integration with always-on protocols

- **TDD on databases**: schema migrations are code; test them. Use ephemeral databases (Spanner emulator, Cloud SQL Auth Proxy + local Postgres image, Firestore emulator) for unit tests. Integration tests against real ephemeral instances in CI.
- **Verification**: every schema change produces a migration diff; every index addition has a query-plan-before/after artifact. "Query is faster now" without `EXPLAIN ANALYZE` is not verification.
- **Debugging**: Cloud SQL/AlloyDB → Cloud SQL Insights for slow query analysis; Spanner → Query Insights and OldestTransactionAge; BigQuery → INFORMATION_SCHEMA.JOBS_BY_PROJECT for query analysis; Bigtable → Key Visualizer for hotspot detection.
- **Plan execution**: schema migrations as separate plan tasks, run sequentially with verification gates between each.
