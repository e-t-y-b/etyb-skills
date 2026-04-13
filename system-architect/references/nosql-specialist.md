# NoSQL Specialist — Deep Reference

**Always use `WebSearch` to verify current database versions, pricing changes, and benchmark claims before giving advice. The NoSQL landscape evolves rapidly — version numbers below were accurate as of early 2026.**

## Table of Contents
1. [MongoDB (v8.0 / v8.2)](#1-mongodb-v80--v82)
2. [Amazon DynamoDB](#2-amazon-dynamodb)
3. [Cassandra 5.0 and ScyllaDB](#3-cassandra-50-and-scylladb)
4. [Document Modeling Patterns](#4-document-modeling-patterns)
5. [Partition Key Design](#5-partition-key-design)
6. [Consistency Tradeoffs](#6-consistency-tradeoffs)
7. [Wide-Column Databases](#7-wide-column-databases)
8. [Graph Databases](#8-graph-databases)
9. [Time-Series Databases](#9-time-series-databases)
10. [Vector Databases](#10-vector-databases)
11. [Multi-Model Databases](#11-multi-model-databases)
12. [Decision Framework](#12-decision-framework)

---

## 1. MongoDB (v8.0 / v8.2)

### Version Timeline

| Version | GA Date | Key Theme |
|---------|---------|-----------|
| **7.0** | 2023 | Queryable Encryption (preview), sharding improvements |
| **8.0** | Oct 2024 | Performance overhaul, block processing for time series, vector quantization |
| **8.2** | Sep 2025 | Hybrid search, Vector Search in Community Edition, new QE query types |

### Performance Benchmarks (v8.0 vs v7.0)

- **36% better read throughput** on general workloads
- **56% faster bulk writes** via batch INSERT/UPDATE/DELETE processing
- **20% faster concurrent writes** during replication
- **2-3x throughput improvement** for time-series bulk inserts (cache usage reduced 10-20x)
- **v8.2 adds**: up to 195% improved throughput for time-series bulk insertions, 49% faster unindexed queries, ~3x throughput for time-series bulk inserts over v8.0

### Queryable Encryption

Queryable Encryption (QE) allows clients to encrypt sensitive fields before sending them to the server, run equality queries on encrypted data without the server ever seeing plaintext. The server performs operations on ciphertext.

**v8.0 additions**: Range queries on encrypted fields (preview).
**v8.2 additions**: Prefix, suffix, and substring query types (preview). MongoDB recommends not using new QE features for production until GA (expected 2026).

```javascript
// Client-side field-level encryption setup
const encryptedClient = new MongoClient(uri, {
  autoEncryption: {
    keyVaultNamespace: "encryption.__keyVault",
    kmsProviders: { aws: { accessKeyId, secretAccessKey } },
    encryptedFieldsMap: {
      "mydb.patients": {
        fields: [
          { path: "ssn", bsonType: "string", queries: [{ queryType: "equality" }] },
          { path: "salary", bsonType: "int", queries: [{ queryType: "range" }] }  // v8.0+
        ]
      }
    }
  }
});
```

**When to use**: PII/PHI fields in regulated industries (HIPAA, PCI-DSS, GDPR). Eliminates need to decrypt at the application layer for queries.

### Atlas Vector Search

Atlas Vector Search uses the same query interface as standard MongoDB queries. Key improvements:

- **Vector quantization** (v8.0): Scalar, binary, and auto-quantization reduce memory 73-96% while preserving accuracy
- **v8.2**: Vector Search available in Community Edition and Enterprise Server (no longer Atlas-only)
- **$scoreFusion** aggregation stage for hybrid search combining vector + full-text results

```javascript
// Atlas Vector Search with quantization (v8.0+)
db.collection.createSearchIndex({
  name: "vector_index",
  type: "vectorSearch",
  definition: {
    fields: [{
      type: "vector",
      numDimensions: 1536,
      path: "embedding",
      similarity: "cosine",
      quantization: "scalar"  // 73% less memory
    }]
  }
});

// Hybrid search with $scoreFusion (v8.2+)
db.collection.aggregate([
  { $search: { text: { query: "machine learning", path: "content" } } },
  { $vectorSearch: { queryVector: embedding, path: "embedding", limit: 20 } },
  { $scoreFusion: { strategy: "rrf" } },  // Reciprocal Rank Fusion
  { $limit: 10 }
]);
```

### Time-Series Collections (v8.0+)

v8.0 introduces **block processing** — time-series data is written directly into column-compressed format instead of converting from row-based BSON:

```javascript
db.createCollection("sensor_readings", {
  timeseries: {
    timeField: "timestamp",
    metaField: "sensor_id",
    granularity: "seconds",
    bucketMaxSpanSeconds: 3600,
    bucketRoundingSeconds: 3600
  },
  expireAfterSeconds: 2592000  // 30-day retention
});
```

**Production pattern**: Use `metaField` for the dimension you query most (device ID, region). Set granularity to match your ingest frequency. Combine with TTL for automatic retention.

### Atlas Stream Processing

GA as of 2024. Processes continuous data streams using the aggregation pipeline — no separate streaming framework needed.

```javascript
// Stream processor definition
sp.createStreamProcessor("clickstream_processor", {
  pipeline: [
    { $source: { connectionName: "kafka_cluster", topic: "clickstream" } },
    { $match: { "event_type": "purchase" } },
    { $group: {
      _id: { $tumblingWindow: { size: { unit: "minute", value: 5 } } },
      totalRevenue: { $sum: "$amount" },
      count: { $sum: 1 }
    }},
    { $emit: {
      connectionName: "atlas_cluster",
      db: "analytics",
      coll: "revenue_5min",
      timeseries: { timeField: "window_start" }
    }}
  ]
});
```

Key operators: `$sessionWindow` (activity-based windows), `$cachedLookup` (caching slow-changing lookups with TTL), `$function` (custom JavaScript in pipeline).

---

## 2. Amazon DynamoDB

### 2025-2026 Feature Updates

| Feature | Date | Impact |
|---------|------|--------|
| **Multi-Region Strong Consistency (MRSC)** | Jun 2025 | Global tables can now guarantee strong reads across regions |
| **Multi-attribute composite GSI keys** | Nov 2025 | Up to 4 attributes per GSI partition/sort key — eliminates synthetic key hacks |
| **Zero-ETL to Redshift/SageMaker Lakehouse** | 2024-2025 | Automatic replication to analytics without ETL pipelines |
| **Zero-ETL to S3 Tables (via Glue)** | Jul 2025 | DynamoDB changes replicated to Iceberg tables on S3 |
| **Configurable PITR** | 2025 | Recovery window adjustable from 1 to 35 days (was fixed at 35) |
| **Database Savings Plans** | Dec 2025 | Commitment-based discount layer on top of on-demand or provisioned |

### Global Tables: MREC vs MRSC

```
MREC (Multi-Region Eventual Consistency) — default:
  ┌─────────┐    async replication    ┌─────────┐
  │ Region A │ ──────────────────────→ │ Region B │
  │  (write) │ ←────────────────────── │  (write) │
  └─────────┘    eventual (~1s)       └─────────┘

MRSC (Multi-Region Strong Consistency) — new in 2025:
  ┌─────────┐    synchronous commit    ┌─────────┐
  │ Region A │ ←─────────────────────→ │ Region B │
  │  (write) │   consistent reads OK   │  (write) │
  └─────────┘                          └─────────┘
```

MRSC uses active-active replication where every replica has equal standing. Trade-off: higher write latency (cross-region round trip) for guaranteed consistent reads from any region.

### Cost Optimization Patterns

**Capacity Mode Decision**:

| Signal | Choose | Why |
|--------|--------|-----|
| Peak-to-average ratio > 4x | On-demand | Provisioned headroom would be wasted |
| Utilization consistently < 35% | On-demand | You're paying for unused capacity |
| Steady, predictable traffic | Provisioned + auto-scaling | 5-7x cheaper than on-demand at scale |
| Mixed: stable baseline + spikes | Provisioned baseline + on-demand overflow | Hybrid approach |

**Commitment discounts (stackable)**:

| Mechanism | Savings | Commitment | Notes |
|-----------|---------|-----------|-------|
| **Provisioned (standard)** | Baseline | None | Pay per hour of provisioned RCU/WCU |
| **Reserved Capacity** | ~40% (1yr), ~60% (3yr) | 1 or 3 years, 100 RCU/WCU blocks | Best for rock-steady baseline |
| **Database Savings Plans** | Up to 25% | 1 or 3 years, $/hr commitment | Covers variable usage, on-demand tables, multiple services |

**Production cost pattern**: Reserved Capacity for steady baseline, Database Savings Plans for variable overflow, on-demand for dev/test environments.

**Item-level cost reduction**:
- Keep items small (aim for < 4KB for reads, < 1KB for writes to minimize consumed capacity units)
- Use projection expressions to read only needed attributes
- Use sparse GSIs (only index items that have the attribute)
- Compress large attribute values with gzip before storing

### Single-Table vs Multi-Table Design (2025-2026 State)

The community debate has matured significantly. AWS's official position: **minimize the number of tables; in most cases use a single table**. But the 2025-2026 nuance:

**Use single-table design when**:
- Access patterns are well-known and stable
- You need transactional writes across entity types (TransactWriteItems)
- You want to minimize GSI count (cost savings)
- Team has DynamoDB expertise

**Use multi-table design when**:
- Access patterns are still evolving (startup phase)
- Different entity types have wildly different throughput profiles
- Team is new to DynamoDB (single-table has a steep learning curve)
- You need different backup/TTL/encryption settings per entity type

**2025 hybrid approach** (increasingly popular):
- Group entities by access pattern affinity, not by "everything in one table"
- Use 2-5 tables for a medium-complexity application
- The Nov 2025 multi-attribute composite GSI keys reduce the need for synthetic key gymnastics that made single-table painful

### DynamoDB Streams

```
DynamoDB Table → DynamoDB Streams → Lambda / Kinesis Data Streams
                                          │
                    ┌─────────────────────┼──────────────────────┐
                    ↓                     ↓                      ↓
              Search index          Analytics sink         Event bus
              (OpenSearch)          (Redshift, S3)         (EventBridge)
```

Stream record types: `KEYS_ONLY`, `NEW_IMAGE`, `OLD_IMAGE`, `NEW_AND_OLD_IMAGES`. Use `NEW_AND_OLD_IMAGES` for CDC use cases. Retention: 24 hours. For longer, pipe to Kinesis Data Streams (7 days, extendable to 365).

---

## 3. Cassandra 5.0 and ScyllaDB

### Cassandra 5.0 — Major Features

Released in 2024, the biggest update since 4.0.

**Storage-Attached Indexing (SAI)**:
SAI replaces the fragile legacy secondary indexes. SAI indexes are attached to SSTables (hence the name), sharing the SSTable lifecycle (compaction, streaming, cleanup).

```cql
-- SAI index creation
CREATE CUSTOM INDEX ON sensor_data (location)
  USING 'StorageAttachedIndex';

-- Numeric range query (not possible with old 2i)
SELECT * FROM sensor_data
  WHERE location = 'us-east-1'
  AND temperature > 30.0
  AND temperature < 45.0;
```

SAI advantages over legacy 2i: numeric range queries, OR queries, lower storage overhead, no tombstone issues, built-in for vector search.

**Trie-Based Storage Engine**:
- **Trie Memtables**: Store keys by shared prefixes instead of full key per entry. Lower object count, better CPU cache locality, faster flushes.
- **Trie-Indexed SSTables (BTI)**: Replace Bloom filters + partition index with trie structures. Result: ~50% less memory for index structures, faster point lookups.

Enable with:
```yaml
# cassandra.yaml
memtable:
  class: TrieMemtable
sstable:
  format: bti
```

**Vector Search**:
Built on SAI. Supports ANN (Approximate Nearest Neighbor) search using JVector library (DiskANN-inspired).

```cql
CREATE TABLE documents (
  id UUID PRIMARY KEY,
  content TEXT,
  embedding VECTOR<FLOAT, 1536>
);

CREATE CUSTOM INDEX ON documents (embedding)
  USING 'StorageAttachedIndex';

-- ANN search
SELECT id, content, similarity_cosine(embedding, ?) AS score
  FROM documents
  ORDER BY embedding ANN OF ?
  LIMIT 10;
```

**Other 5.0 features**: Unified compaction strategy (UCS), dynamic data masking, virtual tables improvements, JDK 17 support.

### ScyllaDB vs Cassandra — Production Comparison

**Benchmark data (2025-2026)**:

| Metric | Cassandra 4.x | ScyllaDB | Factor |
|--------|---------------|----------|--------|
| Throughput (same hardware) | Baseline | 3-8x higher | Architecture |
| Cluster size needed | 40 nodes | 4 nodes (equivalent throughput) | 10x smaller |
| Cost for same throughput | Baseline | 2.5x less expensive | Fewer nodes |
| Tablet scaling speed | vNode-based | 7.2x faster (9x with cleanup) | Tablets vs vNodes |
| P99 tail latency | GC spikes | No GC (C++, shard-per-core) | Predictable |
| Compaction impact | Latency spikes during compaction | Built-in scheduler prioritizes reads/writes | Transparent |

**ScyllaDB architecture advantages**:
- **Shard-per-core**: Each CPU core owns its own memory and data. No locking, no GC pauses.
- **Userspace I/O scheduling**: Prioritizes client reads/writes over background tasks.
- **Automatic tuning**: No need to manually tune JVM heap, memtable sizes, etc.
- **CQL compatible**: Same drivers, same data model, same CQL.

**When to choose Cassandra over ScyllaDB**:
- Decades of production battle-testing at scale (Apple, Netflix, Discord all run Cassandra)
- Larger community, more third-party tooling and consultants
- Cassandra 5.0 features (SAI, vector search, trie engine) not yet in ScyllaDB
- Lower migration risk for existing Cassandra deployments
- Apache 2.0 license vs ScyllaDB's AGPL (enterprise license required for some use cases)

**When to choose ScyllaDB over Cassandra**:
- Predictable low-latency requirements (no GC pauses)
- Want to reduce cluster size (and operational costs) by 5-10x
- High-throughput workloads where Cassandra's JVM is the bottleneck
- Team wants less operational tuning overhead

---

## 4. Document Modeling Patterns

### Embedded vs Referenced — Decision Matrix

| Factor | Embed | Reference |
|--------|-------|-----------|
| **Read pattern** | Data always read together | Data read independently |
| **Cardinality** | 1:1 or 1:few | 1:many or many:many |
| **Document size** | Combined < 16MB (MongoDB limit) | Risk of exceeding document size |
| **Write frequency** | Related data changes infrequently | Related data changes independently and frequently |
| **Atomicity** | Need atomic updates across related data | Can tolerate non-atomic cross-document updates |
| **Data duplication** | Acceptable (denormalized) | Unacceptable (normalized) |

**Hybrid approach** (production-recommended for most cases):
Embed a summary/subset, reference the full data.

```javascript
// User document with embedded recent orders (hybrid)
{
  _id: "user_123",
  name: "Jane Doe",
  email: "jane@example.com",
  recentOrders: [               // Embedded subset (last 3)
    { orderId: "ord_789", total: 59.99, status: "delivered", date: "2025-12-01" },
    { orderId: "ord_790", total: 124.50, status: "shipped", date: "2025-12-10" }
  ],
  orderCount: 47                // Computed field
}

// Full order in separate collection (referenced)
{
  _id: "ord_789",
  userId: "user_123",
  items: [ /* full line items */ ],
  shipping: { /* full shipping details */ },
  // ... complete order data
}
```

### Polymorphic Pattern

Store entities with different shapes in a single collection, distinguished by a type discriminator.

```javascript
// Single "vehicles" collection with polymorphic documents
{ type: "car", make: "Toyota", model: "Camry", doors: 4, mpg: 32 }
{ type: "truck", make: "Ford", model: "F-150", payload_tons: 1.5, bed_length: 6.5 }
{ type: "motorcycle", make: "Honda", model: "CBR600", engine_cc: 599 }
```

**When to use**: Content management systems (articles, videos, podcasts in one collection), product catalogs (different product types), event logging (different event shapes), insurance policies (different policy types).

**Production tip**: Always include a `schema_version` field alongside the type discriminator to handle evolution.

### Bucket Pattern

Group time-series or high-frequency data into fixed-size "bucket" documents.

```javascript
// Instead of one document per reading:
{ sensor_id: "s1", timestamp: ISODate("2025-12-01T00:00:01"), temp: 22.1 }
{ sensor_id: "s1", timestamp: ISODate("2025-12-01T00:00:02"), temp: 22.2 }
// ... millions of documents

// Bucket by hour (1 document per sensor per hour):
{
  sensor_id: "s1",
  bucket_start: ISODate("2025-12-01T00:00:00"),
  bucket_end: ISODate("2025-12-01T01:00:00"),
  count: 3600,
  readings: [
    { t: ISODate("2025-12-01T00:00:01"), v: 22.1 },
    { t: ISODate("2025-12-01T00:00:02"), v: 22.2 },
    // ... up to 3600 readings
  ],
  stats: { min: 21.8, max: 23.4, avg: 22.3, sum: 80280 }  // Pre-computed
}
```

**Benefits**: Reduces document count by orders of magnitude, reduces index size, enables pre-computed aggregates. **Trade-off**: Complex update logic, need to handle bucket overflow.

**Note**: For MongoDB specifically, prefer native time-series collections (v5.0+) over manual bucketing. The bucket pattern remains relevant for other document databases.

### Outlier Pattern

Most entities have a bounded number of related items, but rare outliers can have thousands. Separate the outlier handling to avoid penalizing the common case.

```javascript
// Normal book (fits in one document)
{
  _id: "book_1",
  title: "Niche Technical Book",
  reviews: [
    { user: "u1", rating: 5, text: "Great!" },
    { user: "u2", rating: 4, text: "Useful." }
  ],
  has_overflow: false
}

// Bestseller with 50,000 reviews (outlier)
{
  _id: "book_2",
  title: "Bestselling Novel",
  reviews: [ /* first 50 reviews only */ ],
  has_overflow: true,
  review_count: 50000
}

// Overflow collection
{ book_id: "book_2", page: 1, reviews: [ /* reviews 51-100 */ ] }
{ book_id: "book_2", page: 2, reviews: [ /* reviews 101-150 */ ] }
```

**When to use**: Social media (most users have 200 followers, some have 50M), e-commerce (most products have 10 reviews, bestsellers have 100K), any 1:many where the "many" has extreme variance.

### Schema Versioning Pattern

Enable zero-downtime schema evolution by versioning documents.

```javascript
// Version 1 (original)
{ _id: "u1", schema_version: 1, name: "Jane Doe", address: "123 Main St, NY" }

// Version 2 (structured address)
{ _id: "u2", schema_version: 2, name: "Jane Doe",
  address: { street: "123 Main St", city: "New York", state: "NY", zip: "10001" } }

// Application code handles both versions
function getAddress(user) {
  if (user.schema_version === 1) {
    return parseAddressString(user.address);  // Legacy format
  }
  return user.address;  // Current format
}

// Background migration job upgrades v1 → v2 over time
```

**Production strategy**: 
1. Deploy code that reads both v1 and v2
2. Deploy code that writes v2 only
3. Run background migration for existing v1 documents
4. Once all documents are v2, remove v1 handling code

---

## 5. Partition Key Design

### DynamoDB Partition Fundamentals

Each partition supports: **3,000 RCU** (read capacity units) and **1,000 WCU** (write capacity units). No amount of table-level capacity can fix a hot partition.

### Hot Partition Patterns and Fixes

| Anti-Pattern | Why It's Hot | Fix |
|-------------|-------------|-----|
| Sequential IDs as PK | All writes hit newest partition | Use UUIDs or hash-prefix |
| Timestamp as PK | Rolling hot partition on current time bucket | Compound key: `(sensor_id, date_bucket)` |
| Low-cardinality PK | Status field with 3 values | Add high-cardinality prefix |
| Celebrity/viral item | Single item gets 100x normal traffic | Write sharding with shard suffix |

### Write Sharding

When a single logical entity receives disproportionate write traffic:

```
Without sharding:
  PK: "counter#page_views"  →  all writes to ONE partition  →  HOT

With write sharding (N=10):
  PK: "counter#page_views#0"  →  ╮
  PK: "counter#page_views#1"  →  │  writes distributed
  PK: "counter#page_views#2"  →  │  across 10 partitions
  ...                              │
  PK: "counter#page_views#9"  →  ╯

  Read: scatter-gather across all 10 shards, sum results
```

```python
import hashlib

def get_sharded_key(base_key: str, entity_id: str, num_shards: int = 10) -> str:
    """Deterministic shard assignment based on entity ID"""
    shard = int(hashlib.md5(entity_id.encode()).hexdigest(), 16) % num_shards
    return f"{base_key}#{shard}"

# Write: single partition
pk = get_sharded_key("counter#page_views", user_id)

# Read: scatter-gather
total = sum(
    get_item(f"counter#page_views#{i}")["count"]
    for i in range(num_shards)
)
```

### GSI Design Principles

**GSI throttling propagates to the base table.** When a GSI throttles, it blocks the base table write.

| GSI Anti-Pattern | Problem | Solution |
|-----------------|---------|----------|
| Low-cardinality GSI PK (e.g., `status`) | 80% of items have `status=ACTIVE` = hot GSI partition | Add high-cardinality prefix or use sparse GSI |
| Too many GSIs | Each write pays WCU for base + all GSIs | Max 5 GSIs per table; remove unused ones |
| Projecting ALL attributes | GSI storage cost doubles table cost | Use `KEYS_ONLY` or `INCLUDE` with only needed attributes |
| Not using sparse GSIs | Indexing items that don't need to be queried via GSI | Only add the GSI attribute when the item should be indexed |

**Multi-attribute composite keys (Nov 2025)**: GSI partition and sort keys can now combine up to 4 attributes each. This eliminates the `PK = "STATUS#REGION"` concatenation hack:

```
// Before (synthetic composite key):
GSI PK: "ACTIVE#us-east-1"    // manual string concatenation
GSI SK: "2025-12-01#order_123"

// After (native composite key, Nov 2025):
GSI PK: [status, region]       // DynamoDB handles composition
GSI SK: [order_date, order_id]
```

### Adaptive Capacity and Split-for-Heat

DynamoDB automatically detects hot partitions and splits them:

1. **Adaptive Capacity**: Borrows unused capacity from cool partitions (within 5 minutes)
2. **Split-for-Heat**: If a partition consistently exceeds limits, DynamoDB splits it by sort key range into two partitions

This is automatic and invisible. However, **do not rely on it as your primary strategy** — it has limits and takes minutes to activate. Design for even distribution first.

### Capacity Planning Formula

```
Reads:
  RCU = (reads_per_second × item_size_KB / 4) × consistency_factor
  consistency_factor: 1.0 for eventually consistent, 2.0 for strongly consistent

Writes:
  WCU = writes_per_second × item_size_KB  (rounded up to nearest 1KB)

GSI overhead:
  Total WCU = base_table_WCU + SUM(gsi_wcu for each GSI that indexes the item)
```

---

## 6. Consistency Tradeoffs

### Comparison Across Major NoSQL Systems

| Database | Default | Tunable? | Strongest Available | Weakest Available |
|----------|---------|----------|--------------------|--------------------|
| **MongoDB** | Strong (single-doc, within replica set) | Yes (read preference + write concern) | `w: "majority"` + `readConcern: "linearizable"` | `readPreference: "nearest"` + `w: 1` |
| **DynamoDB** | Strong writes, eventual reads | Limited | Strong consistent reads (single-region) or MRSC (multi-region) | Eventually consistent reads |
| **Cassandra** | Eventual | Yes (per-query) | `ALL` (read + write) | `ONE` / `ANY` |
| **ScyllaDB** | Eventual | Yes (same as Cassandra) | `ALL` | `ONE` / `ANY` |

### MongoDB Read/Write Concerns

```javascript
// Strongest: linearizable (blocks until majority-committed, no stale reads)
db.accounts.findOne(
  { _id: "acct_123" },
  { readConcern: { level: "linearizable" } }
);

// Production default: majority read + majority write
db.accounts.updateOne(
  { _id: "acct_123" },
  { $inc: { balance: -100 } },
  { writeConcern: { w: "majority", j: true, wtimeout: 5000 } }
);

// Performance-optimized: read from nearest replica (may be stale)
db.analytics.find({ date: today }).readPref("nearest");
```

**Read preference options**: `primary` (default, strongest), `primaryPreferred`, `secondary`, `secondaryPreferred`, `nearest` (lowest latency).

**Write concern options**: `w: 0` (fire-and-forget), `w: 1` (primary ack), `w: "majority"` (majority ack), `j: true` (journaled).

### Cassandra Tunable Consistency

The quorum formula: **R + W > N** guarantees strong consistency (R = read CL, W = write CL, N = replication factor).

| Consistency Level | Nodes Required | Latency | Use Case |
|-------------------|---------------|---------|----------|
| `ONE` | 1 | Lowest | Logging, metrics, non-critical reads |
| `QUORUM` | ⌊N/2⌋ + 1 | Medium | Default for most workloads |
| `LOCAL_QUORUM` | Majority in local DC | Medium | Multi-DC with local strong reads |
| `EACH_QUORUM` | Majority in each DC | Highest | Financial data, cross-DC consistency |
| `ALL` | N | Highest | Rarely used (availability killer) |

```cql
-- Write at QUORUM, read at QUORUM = strong consistency (RF=3)
CONSISTENCY QUORUM;
INSERT INTO orders (id, user_id, total) VALUES (uuid(), 'u123', 99.99);
SELECT * FROM orders WHERE id = ?;

-- Write at ONE, read at ONE = eventual consistency (fastest)
CONSISTENCY ONE;
INSERT INTO pageviews (url, ts, count) VALUES ('/home', toTimestamp(now()), 1);
```

**Production pattern**: `LOCAL_QUORUM` for reads and writes in multi-DC deployments. This gives strong consistency within a datacenter while maintaining availability if a remote DC goes down.

### DynamoDB Consistency Model

- **Writes**: Always strongly consistent (acknowledged after written to majority of storage nodes)
- **Reads (default)**: Eventually consistent — may not reflect writes from last ~1 second. Costs 0.5 RCU per 4KB.
- **Reads (strong)**: Returns most recent write. Costs 1.0 RCU per 4KB (2x cost).
- **Transactions**: `TransactGetItems` and `TransactWriteItems` — ACID within and across tables. Costs 2x normal RCU/WCU.
- **Global tables (MRSC, 2025)**: Strong consistent reads across regions. Higher write latency due to cross-region synchronous commit.

---

## 7. Wide-Column Databases

### When to Use Each

| Database | Architecture | Best For | Avoid When |
|----------|-------------|----------|------------|
| **Apache Cassandra** | Peer-to-peer, JVM | Massive write-heavy workloads, multi-DC active-active, known stable schema | Complex queries, small datasets, need JOINs |
| **ScyllaDB** | Peer-to-peer, C++ (shard-per-core) | Same as Cassandra but need predictable P99 latency, want fewer nodes | Need Cassandra 5.0 features (SAI, vector search), Apache license required |
| **Apache HBase** | Master-worker on HDFS | Hadoop ecosystem integration, strong consistency requirement, random read/write on HDFS | No Hadoop in your stack, need multi-DC, want simple operations |
| **Google Bigtable** | Managed, GCP-native | Petabyte-scale time-series, IoT telemetry, Google Cloud native, need managed service | Multi-cloud, small datasets, need SQL, budget-constrained |

### Architecture Comparison

```
Cassandra / ScyllaDB (peer-to-peer):
  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
  │ Node 1 │──│ Node 2 │──│ Node 3 │──│ Node 4 │
  │ (equal)│  │ (equal)│  │ (equal)│  │ (equal)│
  └────────┘  └────────┘  └────────┘  └────────┘
  All nodes handle reads + writes. No single point of failure.

HBase (master-worker on HDFS):
  ┌──────────────┐
  │  HBase Master │  ← coordinates region assignment
  └──────┬───────┘
    ┌────┴────┐────────┐────────┐
    │ Region  │ Region │ Region │  ← each handles a key range
    │ Server  │ Server │ Server │
    └────┬────┘────┬───┘────┬───┘
    ┌────┴─────────┴────────┴───┐
    │          HDFS              │  ← underlying distributed storage
    └───────────────────────────┘

Bigtable (managed):
  Same architecture as HBase conceptually, fully managed by Google.
  Auto-splits tablets, auto-rebalances, integrated with GCP ecosystem.
```

### Data Model (Shared Across Wide-Column)

```
Row Key   │ Column Family: metrics          │ Column Family: metadata
          │ cpu:user │ cpu:sys │ mem:used   │ host:name │ host:region
──────────┼──────────┼─────────┼────────────┼───────────┼────────────
ts#host1  │ 45.2     │ 12.1    │ 8192      │ web-01    │ us-east-1
ts#host2  │ 78.9     │ 23.4    │ 16384     │ web-02    │ eu-west-1
```

**Design principles** (apply to all wide-column stores):
1. **Design for your queries first** — model the data to serve your read patterns
2. **Denormalize aggressively** — no JOINs, duplicate data across query tables
3. **Row key is the most critical design decision** — determines data distribution and query capability
4. **Column families should group data accessed together** — each column family is stored separately on disk

---

## 8. Graph Databases

### Landscape (2025-2026)

| Database | Query Language | Deployment | Best For |
|----------|---------------|------------|----------|
| **Neo4j** | Cypher (GQL-compliant) | Self-hosted, Aura (managed) | Pure graph workloads, graph data science, knowledge graphs |
| **Amazon Neptune** | Gremlin, openCypher, SPARQL | AWS managed only | AWS-native, hybrid semantic (RDF + property graph), compliance |
| **ArangoDB** | AQL (native) | Self-hosted, ArangoGraph (managed) | Multi-model (graph + document + key-value in one engine) |
| **Memgraph** | Cypher | Self-hosted, managed | Real-time streaming graph analytics, Cypher compatibility |
| **TigerGraph** | GSQL | Self-hosted, managed | Deep-link analytics (10+ hops), massive parallel graph queries |

### Neo4j 5.x (2025 State)

- **10x faster complex pattern matching** over 4.x
- **Cypher 25**: GQL-compliant, walk semantics (`REPEATABLE ELEMENTS`), conditional queries (`WHEN/ELSE`), `FILTER` clause, `LET` clause
- **Graph Data Science (GDS) Library**: 70+ algorithms (PageRank, community detection, node embedding, link prediction), ML pipelines for supervised graph learning
- **GraphRAG**: Combines knowledge graphs with LLM retrieval — emerging pattern for more accurate RAG

```cypher
// Find fraud rings: accounts sharing devices and IP addresses
MATCH (a1:Account)-[:USED_DEVICE]->(d:Device)<-[:USED_DEVICE]-(a2:Account),
      (a1)-[:FROM_IP]->(ip:IPAddress)<-[:FROM_IP]-(a2)
WHERE a1 <> a2
  AND a1.created_at > datetime('2025-01-01')
RETURN a1, a2, d, ip
ORDER BY d.risk_score DESC
LIMIT 50;

// Graph Data Science: run PageRank
CALL gds.pageRank.stream('social-graph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC LIMIT 10;
```

### When Graph vs Relational

| Signal | Use Graph DB | Stick with Relational |
|--------|-------------|----------------------|
| **Relationship depth** | Queries traverse 3+ hops (friend-of-friend-of-friend) | 1-2 JOIN depth |
| **Relationship variety** | Many relationship types, evolving over time | Fixed, well-known relationships |
| **Query pattern** | "Find all paths", "shortest path", "who is connected to" | CRUD on entities with simple foreign keys |
| **Schema flexibility** | New relationship types added frequently | Schema is stable and well-defined |
| **Performance** | JOINs degrade at depth (exponential in relational) | Joins on 2-3 tables perform fine |

**Common graph use cases**: Fraud detection (transaction networks), recommendation engines (collaborative filtering), knowledge graphs (entity resolution), network management (dependency mapping), identity resolution, social networks, supply chain tracing.

**Anti-pattern**: Using a graph DB for simple CRUD with 1:many relationships (an RDBMS is simpler and faster for this).

### Query Language Comparison

| Language | Used By | Style | Strengths |
|----------|---------|-------|-----------|
| **Cypher** | Neo4j, Memgraph, Neptune (openCypher) | Declarative, ASCII-art patterns | Intuitive for graph patterns, ISO GQL standard |
| **Gremlin** | Neptune, JanusGraph, Azure Cosmos DB | Imperative, traversal-based | Fine-grained control, wide database support |
| **SPARQL** | Neptune, Blazegraph | Declarative, RDF triple patterns | Semantic web, linked data, ontology queries |
| **AQL** | ArangoDB | SQL-like, multi-model | Graph + document queries in one language |

---

## 9. Time-Series Databases

### 2025-2026 Comparison

| Database | Architecture | Query Language | Best For | Compression |
|----------|-------------|---------------|----------|-------------|
| **InfluxDB 3.0** | Rust rewrite, Apache Arrow, Parquet | SQL + InfluxQL + Flux | High-frequency monitoring, metrics, IoT alerting | Columnar (Parquet) |
| **TimescaleDB** | PostgreSQL extension | SQL (full PostgreSQL) | Time-series with relational context, transactional guarantees | 10-15x |
| **QuestDB** | Zero-GC Java, column-oriented | SQL (PostgreSQL wire protocol) | Ultra-fast ingestion, financial data, real-time analytics | Column-native |
| **ClickHouse** | C++, columnar OLAP | SQL (ClickHouse dialect) | Analytical queries on massive time-series, log analytics | 15-30x |

### Performance Benchmarks (2025-2026)

| Benchmark | Winner | Details |
|-----------|--------|---------|
| **Ingestion throughput** | QuestDB | 12-36x faster than InfluxDB 3, 6-13x faster than TimescaleDB |
| **Complex analytical queries** | ClickHouse | 3-10x faster than TimescaleDB, 43-418x faster than InfluxDB 3 for complex queries |
| **Ordered aggregations** | TimescaleDB | Outperforms others on groupby-orderby-limit queries |
| **Data compression** | ClickHouse | 15-30x compression vs TimescaleDB's 10-15x |
| **Sub-second P95 latency at high concurrency** | ClickHouse | Dominant in analytics workloads |

### When to Choose Each

**InfluxDB 3.0**: Real-time monitoring and alerting. Best if your primary use case is dashboards and threshold-based alerts on streaming metrics. The 3.0 rewrite (Rust + Apache Arrow) fixes the high-cardinality problem that plagued 2.x.

**TimescaleDB**: When you need time-series capabilities AND full PostgreSQL (JOINs, transactions, extensions like PostGIS). The only option if you need ACID guarantees on time-series data. Continuous aggregates for pre-computed rollups.

```sql
-- TimescaleDB: create hypertable
SELECT create_hypertable('sensor_data', 'time');

-- Continuous aggregate for 1-hour rollups
CREATE MATERIALIZED VIEW sensor_hourly
WITH (timescaledb.continuous) AS
  SELECT time_bucket('1 hour', time) AS bucket,
         sensor_id,
         avg(temperature) AS avg_temp,
         max(temperature) AS max_temp
  FROM sensor_data
  GROUP BY bucket, sensor_id;
```

**QuestDB**: When ingestion speed is the primary requirement. Financial tick data, high-frequency IoT. SQL-compatible (PostgreSQL wire protocol). Lacks mature ecosystem and extensions of TimescaleDB.

**ClickHouse**: When you need analytical queries on massive historical time-series data (billions of rows). Log analytics, observability backends (Grafana, Signoz use it). Not great for point lookups or transactional workloads.

### Production Hybrid Pattern (2025-2026 Trend)

```
Real-time alerting    →  InfluxDB (streaming metrics, threshold alerts)
Historical analytics  →  ClickHouse (massive aggregations, dashboards)
Transactional context →  TimescaleDB (time-series + relational data)
```

Many organizations use 2 of these 3, with ClickHouse + TimescaleDB being the most common pairing.

---

## 10. Vector Databases

### 2025-2026 Landscape

The vector database market has matured from pure hype to production adoption. Key categories:

| Category | Databases | When to Choose |
|----------|-----------|---------------|
| **PostgreSQL extension** | pgvector | Already use PostgreSQL, < 10M vectors, want transactional consistency |
| **Managed SaaS** | Pinecone | Zero operational overhead, serverless scaling, production RAG |
| **Open-source, high-performance** | Qdrant (Rust), Milvus (Go/C++) | Self-hosted control, high throughput, filtered search |
| **Hybrid/multi-modal search** | Weaviate (Go) | Hybrid vector + keyword search, built-in vectorization modules |
| **Embedded/edge** | Chroma, LanceDB | Prototyping, embedded in application, edge AI |
| **Integrated in existing DB** | MongoDB Atlas Vector Search, Cassandra 5.0, pgvector | Avoid adding another database to your stack |

### pgvector (v0.8.0, 2025)

The default recommendation for teams already running PostgreSQL.

**Key improvements in 0.8**:
- **Iterative index scans**: Solves the filtered vector search problem. Previously, combining `WHERE` clause with vector search could miss results. Iterative scans keep searching until enough filtered results are found.
- **Faster HNSW index building and search**

**Index comparison**:
| Index | Build Speed | Query Speed | Memory | Best For |
|-------|-------------|-------------|--------|----------|
| **HNSW** | Slower | Faster, better recall | Higher | Production queries, < 10M vectors |
| **IVFFlat** | Faster | Slower at high recall | Lower | Large datasets where build time matters |

**Scale guideline**: Under 10M vectors with moderate query volume, pgvector handles it well. Beyond that, evaluate dedicated vector databases.

```sql
-- pgvector 0.8: filtered vector search (iterative scan)
SET hnsw.iterative_scan = strict_order;

SELECT id, title, 1 - (embedding <=> $1) AS similarity
FROM documents
WHERE category = 'technology'         -- filter first
  AND published_date > '2025-01-01'
ORDER BY embedding <=> $1             -- then vector search
LIMIT 10;
```

### Pinecone

Fully managed, serverless. No infrastructure to manage. Strengths:
- **Serverless index**: Pay per query, auto-scales to zero
- **Pod-based index**: Dedicated compute for consistent low latency
- **Namespace isolation**: Multi-tenant by namespace within a single index
- Scale to billions of vectors

**Best for**: Teams that want production vector search without operational overhead. Startups to large enterprises running RAG in production.

### Qdrant

Open-source, written in Rust. Strengths:
- **ACORN algorithm**: Solved filtered HNSW — competitive on selective filtered queries
- **Named vectors**: Multiple vector types per point (e.g., title embedding + content embedding)
- **Hybrid search** (v1.9+): Native support for combining sparse (BM25) + dense vectors
- **Quantization**: Scalar and binary quantization for memory reduction

**Best for**: Teams that want self-hosted control with production-grade performance. Strong filtering capabilities.

### Milvus

Open-source, distributed architecture. Strengths:
- **Billion-vector scale**: Designed for massive datasets from the ground up
- **GPU acceleration**: GPU-based indexing and search
- **Milvus 2.5+**: Native sparse-BM25 for hybrid search
- **Zilliz Cloud**: Managed Milvus with leading low-latency benchmarks

**Best for**: Large-scale AI workloads (recommender systems, image search) with billions of vectors.

### Weaviate

Open-source, Go-based. Strengths:
- **Built-in vectorization**: Modules for OpenAI, Cohere, HuggingFace — Weaviate can vectorize on ingest
- **BlockMax WAND + RSF**: State-of-the-art hybrid search (2026)
- **GraphQL API**: Native GraphQL for queries
- **Multi-tenancy**: Built-in tenant isolation

**Best for**: Teams that want hybrid search (vector + keyword) and don't want to manage a separate embedding pipeline.

### Chroma and LanceDB (Embedded)

**Chroma**: Default vector store in LangChain/LlamaIndex. Ideal for prototyping RAG applications. Now offers a distributed cloud service. Simple API, low overhead.

**LanceDB**: Embedded, serverless, built on Lance format (100x faster than Parquet for vector ops). Runs from disk with near in-memory performance. Native multimodal support. Best for edge AI and applications where you can't run a separate database process.

### Vector Database Decision Matrix

```
Need vector search?
├── Already have PostgreSQL + < 10M vectors? → pgvector
├── Want zero ops? → Pinecone (serverless)
├── Need filtered search + self-hosted? → Qdrant
├── Need billions of vectors? → Milvus / Zilliz Cloud
├── Need built-in hybrid search + vectorization? → Weaviate
├── Prototyping a RAG app? → Chroma
├── Edge/embedded AI? → LanceDB
└── Already using MongoDB/Cassandra? → Their native vector search
```

---

## 11. Multi-Model Databases

### Landscape (2025-2026)

| Database | Models Supported | License | Status |
|----------|-----------------|---------|--------|
| **SurrealDB** | Document, graph, key-value, time-series, vector | BSL 1.1 | v2.x, raised $44M total, active development |
| **ArangoDB** | Document, graph, key-value, search | BSL 1.1 (changed from Apache 2.0 in 2024) | Mature, free tier capped at 100GB |
| **FaunaDB/Fauna** | Document, relational, graph | Proprietary | **SHUTTING DOWN May 30, 2025. Do not choose.** |
| **Azure Cosmos DB** | Document, graph, key-value, column-family, table | Proprietary (managed) | Mature, Azure-native, multi-model via APIs |
| **ArcadeDB** | Document, graph, key-value, time-series | Apache 2.0 | Open-source alternative to Neo4j + ArangoDB |

### SurrealDB (v2.x)

SQL-like syntax with native graph traversal and vector search:

```surql
-- Define schema
DEFINE TABLE user SCHEMAFULL;
DEFINE FIELD name ON user TYPE string;
DEFINE FIELD email ON user TYPE string ASSERT string::is::email($value);

-- Graph relationship (arrow syntax)
RELATE user:alice -> follows -> user:bob SET since = time::now();

-- Graph traversal in queries
SELECT ->follows->user.name AS following FROM user:alice;

-- Vector similarity search
SELECT id, vector::similarity::cosine(embedding, $query_vector) AS score
  FROM documents
  ORDER BY score DESC
  LIMIT 10;
```

**Strengths**: Single database for document + graph + vector + real-time subscriptions. SurrealQL is approachable for SQL-fluent developers. Real-time LIVE queries (websocket push on data changes). Built-in auth and permissions.

**Weaknesses**: Young ecosystem, smaller community, limited production battle-testing at scale, performance not yet matching specialized databases.

### ArangoDB

Mature multi-model with AQL (ArangoDB Query Language):

```aql
// Document query
FOR doc IN products
  FILTER doc.price < 100
  RETURN doc

// Graph traversal
FOR v, e, p IN 1..3 OUTBOUND 'users/alice' follows
  RETURN { user: v.name, depth: LENGTH(p.edges) }

// Combine document + graph in one query
FOR order IN orders
  FILTER order.status == 'pending'
  FOR v IN 1..1 OUTBOUND order placed_by
  RETURN { order: order._key, customer: v.name }
```

**Strengths**: Mature (10+ years), proven at scale, combines graph + document elegantly. SmartGraphs for distributed graph sharding.

**Weaknesses**: AQL is proprietary (no Cypher/Gremlin/SQL), BSL 1.1 license change in 2024 alienated some open-source users, free tier now capped at 100GB.

### When Multi-Model vs Polyglot Persistence

| Signal | Multi-Model (One DB) | Polyglot (Specialized DBs) |
|--------|---------------------|---------------------------|
| **Team size** | Small team, limited ops capacity | Dedicated platform/infra team |
| **Query complexity** | Queries cross model boundaries (graph + document in one query) | Each workload fits cleanly into one model |
| **Performance requirements** | "Good enough" across all models | Need best-in-class for specific model |
| **Operational complexity** | Want to minimize (one backup, one monitoring, one upgrade) | Can handle multiple database operations |
| **Data consistency** | Need transactions across models | Can tolerate eventual consistency between stores |
| **Scale** | Moderate (multi-model DBs have scaling ceiling per model) | Each store scales independently |

**Production recommendation**: For most teams, **start with PostgreSQL** (which is itself multi-model: relational + JSONB + pgvector + full-text search + PostGIS). Only introduce specialized databases when PostgreSQL demonstrably can't handle a specific workload. This is the least-regret path.

---

## 12. Decision Framework

### NoSQL Database Selection Flowchart

```
What is your primary access pattern?
│
├── Key-value lookups (simple get/put)
│   ├── Need persistence? → DynamoDB, Redis (with AOF)
│   └── Cache only? → Redis, Memcached, Valkey
│
├── Document storage (flexible schema, nested objects)
│   ├── Need transactions + flexible schema? → MongoDB
│   ├── Need serverless + AWS-native? → DynamoDB (document mode)
│   └── Need multi-model (doc + graph)? → ArangoDB, SurrealDB
│
├── Wide-column (massive write throughput, time-series-like)
│   ├── Need predictable P99 latency? → ScyllaDB
│   ├── Need largest community + battle-tested? → Cassandra
│   ├── Need strong consistency? → HBase
│   └── Need fully managed on GCP? → Bigtable
│
├── Graph (relationship traversals, 3+ hops)
│   ├── Need graph data science / ML? → Neo4j (GDS library)
│   ├── AWS-native + RDF/SPARQL? → Neptune
│   └── Need graph + document in one DB? → ArangoDB
│
├── Time-series (metrics, IoT, telemetry)
│   ├── Need PostgreSQL compatibility + ACID? → TimescaleDB
│   ├── Need fastest ingestion? → QuestDB
│   ├── Need analytical queries on billions of rows? → ClickHouse
│   └── Need real-time alerting + monitoring? → InfluxDB 3.0
│
├── Vector similarity search (embeddings, RAG, AI)
│   ├── Already use PostgreSQL + < 10M vectors? → pgvector
│   ├── Want zero ops, serverless? → Pinecone
│   ├── Need self-hosted + best filtered search? → Qdrant
│   ├── Need billion-vector scale? → Milvus
│   └── Need hybrid search + auto-vectorization? → Weaviate
│
└── Multiple models needed
    ├── Small team, want one DB? → PostgreSQL (JSONB + pgvector + PostGIS)
    ├── Need graph + document queries? → ArangoDB
    ├── Need real-time + graph + vector? → SurrealDB (evaluate maturity)
    └── Large team, can operate multiple DBs? → Polyglot persistence
```

### Cost-Performance Quick Reference

| Database | Managed Option | Free Tier | Cost Model |
|----------|---------------|-----------|------------|
| **MongoDB** | Atlas | 512MB shared | Per-hour cluster + storage + transfer |
| **DynamoDB** | Fully managed (only option) | 25 RCU + 25 WCU + 25GB | Per RCU/WCU + storage |
| **Cassandra** | DataStax Astra, Instaclustr | Astra: 5GB | Per-hour node + storage |
| **ScyllaDB** | ScyllaDB Cloud | None | Per-hour node |
| **Neo4j** | Aura | AuraDB Free: 1 instance | Per-hour instance + storage |
| **TimescaleDB** | Timescale Cloud | 25GB, 1 month trial | Per-hour compute + storage |
| **ClickHouse** | ClickHouse Cloud | 10GB | Per-compute + storage |
| **Pinecone** | Fully managed (only option) | Serverless: 2GB | Per-query (serverless) or per-pod |
| **Qdrant** | Qdrant Cloud | 1GB free cluster | Per-node |
| **pgvector** | Any managed PostgreSQL | Via Supabase, Neon, etc. | Part of PostgreSQL cost |

### Cross-Reference to Other Skills

- For **relational data modeling** and PostgreSQL patterns, see `references/data-architect.md` sections 2-3
- For **event-driven integration** with NoSQL (CDC, streams), see `references/integration-architect.md`
- For **API design** patterns with NoSQL backends, see `references/api-designer.md`
- For **system-level tradeoffs** (CAP theorem, consistency models in system design), see `references/solution-architect.md`
