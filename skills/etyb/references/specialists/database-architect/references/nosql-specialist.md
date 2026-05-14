# NoSQL Specialist — Deep Reference

**Always use `WebSearch` to verify current database versions, managed service features, and pricing before giving advice. The NoSQL landscape evolves rapidly with frequent major releases.**

## Table of Contents
1. [When to Choose NoSQL](#1-when-to-choose-nosql)
2. [MongoDB Deep Dive](#2-mongodb-deep-dive)
3. [DynamoDB Deep Dive](#3-dynamodb-deep-dive)
4. [Cassandra and ScyllaDB](#4-cassandra-and-scylladb)
5. [Graph Databases](#5-graph-databases)
6. [Time-Series Databases](#6-time-series-databases)
7. [Vector Databases](#7-vector-databases)
8. [Multi-Model Databases](#8-multi-model-databases)
9. [NoSQL Data Modeling Patterns](#9-nosql-data-modeling-patterns)
10. [Real-World Case Studies](#10-real-world-case-studies)

---

## 1. When to Choose NoSQL

### The SQL-First Principle

Start with PostgreSQL unless you have a specific reason not to. Reach for NoSQL when:

| Access Pattern | NoSQL Choice | Why Not PostgreSQL |
|---------------|-------------|-------------------|
| **Key-value at massive scale** (>100K reads/sec) | DynamoDB, Redis | Connection limits, vertical scaling ceiling |
| **Flexible schema with rapid iteration** | MongoDB | Schema changes require migrations (though JSONB mitigates this) |
| **Massive write throughput** (>50K writes/sec) | Cassandra, ScyllaDB | WAL bottleneck, single-writer architecture |
| **Graph traversals** (friend-of-friend, recommendations) | Neo4j, Neptune | Recursive CTEs work but don't scale for deep traversals |
| **Time-series at scale** (millions of data points/sec) | TimescaleDB, InfluxDB | TimescaleDB is PostgreSQL-based (best of both worlds) |
| **Vector similarity search at scale** (>10M vectors) | Qdrant, Pinecone, Milvus | pgvector works for <10M vectors |
| **Event log / streaming** | Kafka, Redpanda | Not a database use case — stream processing |

### The Polyglot Persistence Tax

Every additional database engine adds operational cost:
- Separate backup/restore procedures
- Different monitoring and alerting
- Team expertise spread thin
- Data synchronization complexity

**Rule of thumb**: PostgreSQL + Redis covers 90% of applications. Add a third database only when the access pattern is clearly a poor fit for both.

---

## 2. MongoDB Deep Dive

### MongoDB 7.x / 8.x Features

- **Queryable Encryption**: Encrypted field operations — query encrypted data without decrypting server-side. Equality and range queries on encrypted fields.
- **Atlas Vector Search**: Native vector search with kNN and approximate nearest neighbor. Supports hybrid search (vector + full-text).
- **Atlas Stream Processing**: Real-time data processing with aggregation pipelines on change streams.
- **Time Series Collections**: Optimized storage for time-stamped data with automatic bucketing and compression.
- **Aggregation Pipeline improvements**: `$setWindowFields`, `$fill`, `$densify` for analytics
- **Cluster-to-Cluster Sync**: Continuous bidirectional sync between clusters (multi-cloud, migration)
- **Column Store Indexes**: Columnar indexes for analytical queries on operational data

### Document Modeling Patterns

**Embed vs Reference Decision:**

```
Embed when:
- Data is always accessed together (1:1 or 1:few)
- Child data doesn't change independently
- Document stays under 16MB limit
- No need to query children independently

Reference when:
- Data accessed independently (1:many, many:many)
- Child data changes frequently
- Need to query children without parent context
- Avoiding document bloat
```

**Pattern: Subset (Partial Embed)**
Embed a subset; reference the rest:
```json
// Order document — embed recent line items, reference all
{
  "_id": "order_123",
  "customer_id": "cust_456",
  "recent_items": [  // Embedded subset (last 3)
    {"product_id": "prod_1", "name": "Widget", "qty": 2, "price": 9.99}
  ],
  "total_items": 47,
  "total_amount": 1234.56
}
// Full line items in separate collection
```

**Pattern: Bucket**
Group time-series data into fixed-size documents:
```json
{
  "sensor_id": "temp_001",
  "bucket_start": "2025-03-15T10:00:00Z",
  "bucket_end": "2025-03-15T11:00:00Z",
  "readings": [
    {"ts": "2025-03-15T10:00:05Z", "value": 22.5},
    {"ts": "2025-03-15T10:00:10Z", "value": 22.6}
    // ... up to 60 readings per document
  ],
  "count": 60,
  "avg": 22.55,
  "min": 22.1,
  "max": 23.0
}
```

**Pattern: Outlier**
Handle outliers differently from typical documents:
```json
// Typical user: friends array is small
{"_id": "user_1", "name": "Alice", "friends": ["user_2", "user_3"], "has_overflow": false}

// Celebrity user: too many friends to embed
{"_id": "celeb_1", "name": "Celebrity", "friends": [], "has_overflow": true}
// Overflow stored in separate collection
{"user_id": "celeb_1", "friends_page": 1, "friends": ["user_100", "user_101", ...]}
```

**Pattern: Computed**
Pre-compute on write to avoid expensive reads:
```json
{
  "_id": "product_789",
  "name": "Widget Pro",
  "reviews_count": 1247,       // Incremented on each review
  "average_rating": 4.3,       // Recalculated on write
  "rating_distribution": {     // Updated on each review
    "5": 523, "4": 412, "3": 187, "2": 89, "1": 36
  }
}
```

### MongoDB Indexing

```javascript
// Compound index (order matters — ESR rule: Equality, Sort, Range)
db.orders.createIndex({ status: 1, created_at: -1, total: 1 });
// Supports: {status: "active"} sorted by created_at with range on total

// Partial index (index only matching documents)
db.orders.createIndex(
  { customer_id: 1, created_at: -1 },
  { partialFilterExpression: { status: { $ne: "cancelled" } } }
);

// Wildcard index (for querying arbitrary JSONB-like fields)
db.products.createIndex({ "attributes.$**": 1 });

// Text index (basic full-text search)
db.articles.createIndex({ title: "text", body: "text" });

// TTL index (auto-expire documents)
db.sessions.createIndex({ created_at: 1 }, { expireAfterSeconds: 3600 });
```

### MongoDB Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Unbounded arrays** | Document grows past 16MB, slow updates | Bucket pattern, separate collection |
| **Modeling like SQL** | References everywhere, joins in app code | Embed related data, denormalize |
| **No schema validation** | Data quality degrades over time | Use JSON Schema validation |
| **Missing indexes** | Collection scans on every query | Profile slow queries, add compound indexes |
| **$lookup in hot paths** | Joins are expensive and can't use indexes effectively | Denormalize or embed |

---

## 3. DynamoDB Deep Dive

### Single-Table vs Multi-Table Design

The "single-table design" debate has evolved:

**Single-table design** (original Alex DeBrie recommendation):
- All entities in one table with composite keys
- Optimize for access patterns, not entity relationships
- Maximum query efficiency (single query gets everything needed)
- **Drawback**: Complex, hard to understand, difficult to evolve

**Multi-table design** (gaining traction in 2025-2026):
- One table per entity type
- Simpler to understand and maintain
- Use DynamoDB transactions for cross-table consistency
- **Drawback**: Multiple queries for related data (but often acceptable with batch gets)

**Recommendation**: Use single-table for read-heavy access patterns where query efficiency is paramount. Use multi-table when simplicity and maintainability matter more, and the additional queries are acceptable.

### Partition Key Design

The partition key is the most important DynamoDB design decision:

```
Rules:
1. High cardinality — many distinct values (user_id: good, status: bad)
2. Even distribution — uniform request rate across partitions
3. Present in every query — you MUST provide the partition key
4. Stable — shouldn't need to change after creation
```

**Hot partition mitigation:**
```
Problem: One partition key gets 80% of traffic (e.g., popular product)

Solutions:
1. Write sharding: Append random suffix to partition key
   PK: "PRODUCT#123#shard_0" through "PRODUCT#123#shard_9"
   Read: Scatter-gather across all 10 shards

2. Caching: Put a cache (ElastiCache/Redis) in front of hot items

3. DAX (DynamoDB Accelerator): Managed caching layer for DynamoDB
```

### DynamoDB Access Pattern Modeling

```
Step 1: List all access patterns
  - Get user profile by user_id
  - Get orders by user_id, sorted by date
  - Get order details with line items
  - Get all orders by status (admin view)

Step 2: Design keys to support patterns

  Entity    | PK           | SK               | GSI1PK    | GSI1SK
  ----------|--------------|------------------|-----------|---------
  User      | USER#<id>    | PROFILE          |           |
  Order     | USER#<uid>   | ORDER#<date>#<id>| STATUS#<s>| ORDER#<date>
  OrderLine | ORDER#<oid>  | LINE#<num>       |           |

Step 3: Validate each access pattern against the design
  - User profile: Query PK=USER#123, SK=PROFILE ✓
  - User orders: Query PK=USER#123, SK begins_with ORDER# ✓
  - Order details: Query PK=ORDER#456, SK begins_with LINE# ✓
  - Orders by status: Query GSI1PK=STATUS#pending ✓
```

### DynamoDB Cost Optimization

| Strategy | Savings | Tradeoff |
|----------|---------|----------|
| **On-demand → Provisioned** (stable workloads) | 50-70% | Requires capacity planning |
| **Reserved capacity** (1-year commitment) | 53% | Upfront commitment |
| **Standard-IA table class** (infrequent access) | 60% on storage | Higher read/write cost |
| **TTL for ephemeral data** | Variable | Data deleted automatically |
| **Item size optimization** | Variable | Shorter attribute names, compression |
| **DynamoDB Streams → Kinesis** | Variable | Avoid expensive scans for change capture |

---

## 4. Cassandra and ScyllaDB

### Cassandra 5.0 Features

- **Storage Attached Indexes (SAI)**: More efficient secondary indexes than the legacy 2i
- **Trie-based memtable and SSTable format**: Improved write performance and compression
- **Vector Search**: Native vector similarity search for AI/ML workloads
- **Unified Compaction Strategy (UCS)**: Replaces STCS/LCS/TWCS with a single adaptive strategy
- **Dynamic Data Masking**: Column-level data masking for security/compliance
- **JDK 17 support**: Modern JVM with better garbage collection

### ScyllaDB vs Cassandra

| Factor | Cassandra | ScyllaDB |
|--------|-----------|----------|
| **Language** | Java (JVM) | C++ (no GC pauses) |
| **Throughput** | Baseline | 5-10x higher (same hardware) |
| **Tail latency** | p99 can spike (GC) | Consistent low latency |
| **Compatibility** | Original | CQL + driver compatible |
| **Lightweight transactions** | Paxos | Raft (faster) |
| **Operational** | Mature, large community | Growing community, enterprise support |
| **Cost** | Open-source | Open-source + enterprise |

**When to choose ScyllaDB over Cassandra**: Latency-sensitive workloads where GC pauses are unacceptable (gaming, ad tech, real-time bidding). When you need Cassandra's data model but with better performance.

### Cassandra Data Modeling

```cql
-- Model tables around queries, not entities
-- One table per query pattern

-- Query: Get user's posts, sorted by time
CREATE TABLE user_posts (
    user_id UUID,
    posted_at TIMESTAMP,
    post_id UUID,
    content TEXT,
    PRIMARY KEY ((user_id), posted_at, post_id)
) WITH CLUSTERING ORDER BY (posted_at DESC);

-- Query: Get posts by tag
CREATE TABLE posts_by_tag (
    tag TEXT,
    posted_at TIMESTAMP,
    post_id UUID,
    user_id UUID,
    content TEXT,
    PRIMARY KEY ((tag), posted_at, post_id)
) WITH CLUSTERING ORDER BY (posted_at DESC);
```

**Partition sizing guidelines:**
- Target: 10MB-100MB per partition (100K-100K rows)
- Monitor: Use `nodetool tablehistograms` to check partition sizes
- Too large: Add time bucket to partition key (`(user_id, month)`)
- Too small: Remove unnecessary partition key components

---

## 5. Graph Databases

### When to Use a Graph Database

Graph databases excel when:
- **Relationship queries dominate**: "friends of friends who like X"
- **Variable-length paths**: "shortest path between A and B"
- **Pattern matching**: "find all cycles in this network"
- **Recommendation engines**: Collaborative filtering based on graph structure

Don't use when:
- Simple foreign key relationships (SQL is fine)
- Depth-1 relationships only (JOINs work)
- Primarily filtering/aggregating (tabular data)

### Graph Database Landscape

| Database | Query Language | Hosting | Best For |
|----------|---------------|---------|----------|
| **Neo4j** | Cypher | Self-hosted, AuraDB (cloud) | General purpose, largest community, GDS library |
| **Amazon Neptune** | Gremlin, SPARQL, openCypher | AWS managed | AWS-native, knowledge graphs, RDF |
| **Memgraph** | Cypher | Self-hosted, Cloud | Real-time analytics, streaming graph processing |
| **ArangoDB** | AQL | Self-hosted, Cloud | Multi-model (graph + document + key-value) |
| **TigerGraph** | GSQL | Self-hosted, Cloud | Deep link analytics, massive scale |

### Neo4j Cypher Patterns

```cypher
// Find friends of friends who like the same products
MATCH (me:User {id: 'user_123'})-[:FRIENDS]->(friend)-[:FRIENDS]->(fof)
WHERE NOT (me)-[:FRIENDS]->(fof) AND me <> fof
WITH fof, COUNT(friend) AS mutual_friends
ORDER BY mutual_friends DESC
LIMIT 10
RETURN fof.name, mutual_friends;

// Shortest path
MATCH path = shortestPath(
  (a:User {id: 'user_1'})-[:FRIENDS*..6]-(b:User {id: 'user_2'})
)
RETURN path;

// Recommendation: products bought by users who bought similar products
MATCH (u:User {id: 'user_123'})-[:BOUGHT]->(p:Product)<-[:BOUGHT]-(other:User)
      -[:BOUGHT]->(rec:Product)
WHERE NOT (u)-[:BOUGHT]->(rec)
RETURN rec.name, COUNT(other) AS score
ORDER BY score DESC LIMIT 5;
```

---

## 6. Time-Series Databases

### Time-Series Database Comparison

| Database | Architecture | Best For | Key Feature |
|----------|-------------|----------|-------------|
| **TimescaleDB** | PostgreSQL extension | When you already use PostgreSQL | Full SQL, hypertables, compression, continuous aggregates |
| **InfluxDB 3.x** | Rust engine, Apache Arrow | Pure time-series (metrics, IoT) | InfluxQL + SQL, columnar storage, Parquet-based |
| **QuestDB** | Custom engine (Java/C++) | Ultra-high ingest rate | Ingestion up to millions rows/sec, SQL |
| **ClickHouse** | Columnar OLAP | Analytics on time-series | Not just time-series — general analytical workloads too |
| **VictoriaMetrics** | Custom engine (Go) | Prometheus long-term storage | High compression, Prometheus-compatible |

### TimescaleDB (Recommended Default)

If you already use PostgreSQL, TimescaleDB is the obvious choice — it's a PostgreSQL extension, so you get time-series features without another database engine:

```sql
-- Create a hypertable (automatically partitions by time)
CREATE TABLE metrics (
    time TIMESTAMPTZ NOT NULL,
    device_id TEXT NOT NULL,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION
);
SELECT create_hypertable('metrics', 'time');

-- Continuous aggregate (materialized view that updates automatically)
CREATE MATERIALIZED VIEW metrics_hourly
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', time) AS bucket,
       device_id,
       AVG(temperature) AS avg_temp,
       MIN(temperature) AS min_temp,
       MAX(temperature) AS max_temp
FROM metrics
GROUP BY bucket, device_id;

-- Compression (10-20x storage reduction)
ALTER TABLE metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id'
);
SELECT add_compression_policy('metrics', INTERVAL '7 days');

-- Retention policy
SELECT add_retention_policy('metrics', INTERVAL '90 days');
```

---

## 7. Vector Databases

### Vector Database Landscape (2025-2026)

The vector database space has matured significantly with the RAG (Retrieval-Augmented Generation) boom:

| Database | Type | Scale | Best For |
|----------|------|-------|----------|
| **pgvector** | PostgreSQL extension | <10M vectors | Simplest path if using PostgreSQL. Full SQL + vector in one DB. |
| **Qdrant** | Purpose-built, Rust | 10M-1B vectors | Best performance/filtering combo. Rich metadata filtering. |
| **Pinecone** | Managed SaaS | Any scale | Zero ops. Serverless pricing. Production RAG. |
| **Weaviate** | Purpose-built, Go | 10M-1B vectors | Multi-modal (text, image, video). Built-in vectorizers. |
| **Milvus** | Purpose-built, distributed | 1B+ vectors | Massive scale. GPU acceleration. |
| **Chroma** | Embedded, Python | <1M vectors | Prototyping, local development. |

### pgvector Deep Dive

```sql
-- Enable extension
CREATE EXTENSION vector;

-- Choose the right dimension for your embedding model
-- OpenAI text-embedding-3-small: 1536
-- Cohere embed-v3: 1024
-- nomic-embed-text: 768
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB DEFAULT '{}'
);

-- HNSW index (recommended — faster queries, more memory)
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- IVFFlat index (alternative — less memory, slower queries)
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);  -- sqrt(num_rows) is a good starting point

-- Similarity search with metadata filter
SELECT id, content, 1 - (embedding <=> $1::vector) AS similarity
FROM documents
WHERE metadata->>'category' = 'engineering'
ORDER BY embedding <=> $1::vector
LIMIT 10;

-- Hybrid search: combine vector similarity with full-text
SELECT id, content,
    (0.7 * (1 - (embedding <=> $1::vector))) +
    (0.3 * ts_rank(to_tsvector('english', content), plainto_tsquery('english', $2))) AS score
FROM documents
WHERE to_tsvector('english', content) @@ plainto_tsquery('english', $2)
ORDER BY score DESC
LIMIT 10;
```

### RAG Architecture Patterns

```
Naive RAG:
  Query → Embed → Vector Search → Top-K → LLM → Response

Advanced RAG:
  Query → Query Rewriting → Embed → Vector Search → Top-K
       → Reranking (cross-encoder) → Top-N → Context Window Management
       → LLM (with system prompt + retrieved context) → Response

Key Design Decisions:
  - Chunk size: 256-512 tokens (smaller = more precise, larger = more context)
  - Chunk overlap: 10-20% (avoid losing context at boundaries)
  - Embedding model: Match your use case (multilingual, code, general)
  - Distance metric: Cosine (normalized), L2 (unnormalized), Inner Product (pre-normalized)
  - Top-K: 5-20 chunks (more = better recall, higher cost)
  - Reranking: Cross-encoder reranker improves precision significantly
```

---

## 8. Multi-Model Databases

### When Multi-Model Makes Sense

Multi-model databases offer multiple data models (document, graph, key-value, search) in one engine:

| Database | Models | Consistency | Best For |
|----------|--------|-------------|----------|
| **ArangoDB** | Document, Graph, Key-Value, Search | ACID | Applications needing both document and graph |
| **SurrealDB** | Document, Graph, Key-Value, Time-series | ACID | Developer-friendly, real-time subscriptions |
| **FaunaDB (Fauna)** | Document, Relational, Graph | Serializable | Serverless, globally distributed |
| **Couchbase** | Document, Key-Value, Search, Analytics | Tunable | Mobile sync (Couchbase Lite), edge computing |

**The tradeoff**: Multi-model databases are good at multiple things but rarely best-in-class at any one. Compare against purpose-built databases for your most critical access pattern.

---

## 9. NoSQL Data Modeling Patterns

### Schema Versioning

NoSQL databases don't enforce schemas, so documents evolve over time:

```json
// Version 1
{"_id": "user_1", "name": "Alice", "email": "alice@example.com"}

// Version 2 (added field)
{"_id": "user_2", "name": "Bob", "email": "bob@example.com", "phone": "+1234567890",
 "schema_version": 2}

// Application handles both versions
function normalizeUser(doc) {
  if (!doc.schema_version || doc.schema_version < 2) {
    doc.phone = null;  // Default for old documents
    doc.schema_version = 2;
  }
  return doc;
}
```

**Strategies:**
1. **Lazy migration**: Upgrade documents when read/written (simplest, gradual)
2. **Eager migration**: Batch update all documents (clean, but expensive for large collections)
3. **Application-level**: Handle all schema versions in code (flexible, but adds complexity)

### Denormalization Strategies

| Pattern | Trade-off | When to Use |
|---------|-----------|-------------|
| **Eager denormalization** | Write amplification, strong read performance | Read-heavy, rarely-updated reference data |
| **Lazy denormalization** | Read computes denormalized view | Write-heavy, acceptable read latency |
| **Materialized views** | Background process maintains denormalized copies | Complex queries on denormalized data |
| **Event-driven** | Emit events, downstream services denormalize | Microservices, eventual consistency acceptable |

---

## 10. Real-World Case Studies

### Airbnb: DynamoDB for Search Impressions

**Context**: Airbnb uses DynamoDB to store search impression data — billions of records per day.
**Design**: Partition by session_id with TTL for automatic cleanup. Sorted by impression_rank.
**Lesson**: DynamoDB excels for high-throughput, TTL-driven data with simple access patterns.

### Uber: Docstore (MySQL-based Document Store)

**Context**: Uber built Docstore on top of MySQL with application-level sharding.
**Design**: Shard by city/region for geographic isolation. Document model on top of MySQL tables.
**Lesson**: You can build NoSQL-like features on top of relational databases if you need SQL's operational maturity.

### Discord: MongoDB → Cassandra → ScyllaDB

**Context**: Discord migrated messages from MongoDB → Cassandra → ScyllaDB over several years.
**Journey**: MongoDB hit scaling limits → Cassandra handled scale but had GC-related latency spikes → ScyllaDB provided Cassandra compatibility with C++ performance.
**Lesson**: NoSQL databases are not interchangeable — each has specific performance characteristics. Migration is possible when wire protocols are compatible.

---

## Decision Framework Summary

| Decision | Default | Switch When |
|----------|---------|-------------|
| **Document DB** | PostgreSQL JSONB | MongoDB (need full document model, flexible schema, rapid prototyping) |
| **Key-value at scale** | Redis | DynamoDB (need durability + scale), Cassandra (need write throughput) |
| **Wide-column** | Cassandra | ScyllaDB (need lower latency), DynamoDB (want managed) |
| **Graph** | PostgreSQL recursive CTEs | Neo4j (complex traversals, GDS algorithms), Neptune (AWS native) |
| **Time-series** | TimescaleDB (PG extension) | InfluxDB (pure time-series), ClickHouse (analytics) |
| **Vector** | pgvector (<10M vectors) | Qdrant (performance), Pinecone (managed), Milvus (massive scale) |
| **Multi-model** | Don't (use purpose-built DBs) | ArangoDB (genuinely need document + graph in one engine) |
| **DynamoDB design** | Multi-table (simpler) | Single-table (performance-critical, well-defined access patterns) |
