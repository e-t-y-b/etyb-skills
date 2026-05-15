# SQL Specialist — Deep Reference

**Always use `WebSearch` to verify version numbers, benchmarks, and features before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [PostgreSQL (16 / 17 / 18)](#1-postgresql-16--17--18)
2. [MySQL (8.4 LTS / 9.x Innovation)](#2-mysql-84-lts--9x-innovation)
3. [SQL Server (2022 / 2025)](#3-sql-server-2022--2025)
4. [Indexing Strategies](#4-indexing-strategies)
5. [Partitioning Strategies](#5-partitioning-strategies)
6. [Replication and High Availability](#6-replication-and-high-availability)
7. [Connection Pooling](#7-connection-pooling)
8. [Schema Design Best Practices](#8-schema-design-best-practices)
9. [Performance Tuning](#9-performance-tuning)
10. [Scaling Patterns](#10-scaling-patterns)
11. [NewSQL and Distributed SQL](#11-newsql-and-distributed-sql)
12. [Vector Search and AI Workloads](#12-vector-search-and-ai-workloads)
13. [Decision Matrices](#13-decision-matrices)

---

## 1. PostgreSQL (16 / 17 / 18)

### Why PostgreSQL Is the Default

PostgreSQL is the default recommendation for most applications because:
- Full ACID compliance with MVCC
- JSONB for semi-structured data (eliminates most MongoDB use cases)
- Extensibility: pgvector, TimescaleDB, Citus, PostGIS, pg_partman
- Transactional DDL (schema changes are atomic and rollbackable)
- Rich type system: arrays, ranges, enums, composites, domains
- Advanced indexing: B-tree, Hash, GIN, GiST, SP-GiST, BRIN, covering indexes
- Mature logical replication for zero-downtime migrations
- Free, open-source, no vendor lock-in

### Version Timeline

| Version | Release | Status | End of Life |
|---------|---------|--------|-------------|
| **PostgreSQL 16** | Sep 2023 | Stable | Nov 2028 |
| **PostgreSQL 17** | Sep 2024 | Stable | Nov 2029 |
| **PostgreSQL 18** | Sep 2025 | Current | Nov 2030 |
| PostgreSQL 19 | Sep 2026 (planned) | Development | -- |

### PostgreSQL 17 Highlights (Sep 2024)

**Vacuum overhaul (the headline feature):**
- New internal `TidStore` memory structure replaces array-based approach
- Up to **20x reduction** in memory usage during VACUUM operations
- Eliminated the previous 1 GB memory usage limit for vacuuming tables
- Optimized storage access and improvements for high-concurrency workloads

**Logical replication improvements:**
- Failover control for logical replication in HA environments
- Hash index support on subscribers (previously btree only)
- Improved logical decoding performance with many subtransactions
- New `pg_createsubscriber` CLI tool: converts physical replica to logical replica
- No longer need to drop logical replication slots during version upgrades

**Performance and SQL:**
- `SQL/JSON JSON_TABLE` command for structured JSON querying (SQL standard)
- Incremental sort improvements
- Speedups in bulk loading (`COPY`) and exports
- Query execution improvements for indexes
- `pg_stat_checkpointer` view for checkpoint monitoring

### PostgreSQL 18 Highlights (Sep 2025)

**Asynchronous I/O subsystem (AIO):**
- New `io_method` setting with options: `worker`, `io_uring`, `sync`
- Up to **3x performance improvement** for sequential scans, bitmap heap scans, and vacuums
- `io_uring` support on Linux for kernel-level async I/O

**Skip scan for B-tree indexes:**
- Multi-column B-tree indexes usable even without restrictions on leading columns
- Eliminates the classic "left-most index column" limitation for many queries
- Significant performance win for queries that previously required separate indexes

**UUIDv7 native support:**
- `uuidv7()` function generates timestamp-ordered UUIDs
- First 48 bits contain timestamp -- much better B-tree index locality than UUIDv4
- Recommended as default for new tables needing globally unique, sortable IDs

**Virtual generated columns:**
- Compute values at read time, not write time (now the default for `GENERATED ALWAYS AS`)
- No storage overhead -- values calculated on the fly
- Useful for computed fields, format transformations, derived values

**Temporal constraints (WITHOUT OVERLAPS):**
- PRIMARY KEY and UNIQUE constraints can enforce non-overlapping ranges
- FOREIGN KEY constraints with `PERIOD` clause for temporal referential integrity
- Addresses scheduling, reservations, employee assignments, versioned data
- Example: `PRIMARY KEY (room_id, booking_period WITHOUT OVERLAPS)`

**OAuth authentication:**
- Native OAuth 2.0 support for client authentication
- Simplifies integration with identity providers (Azure AD, Okta, etc.)

**RETURNING clause enhancements:**
- `OLD` and `NEW` support in RETURNING for INSERT, UPDATE, DELETE, MERGE
- See both before and after values in a single statement

### PostgreSQL Extensions Ecosystem

| Extension | Purpose | When to Use |
|-----------|---------|-------------|
| **pgvector** | Vector similarity search | RAG/AI applications, embedding storage (<10M vectors) |
| **pgvectorscale** | Scaled vector search (Timescale) | 10M-100M+ vectors, production AI workloads |
| **TimescaleDB** | Time-series data | IoT, metrics, financial data (hypertables, compression, continuous aggregates) |
| **Citus** | Distributed PostgreSQL | Multi-tenant SaaS, horizontal scaling, real-time analytics |
| **PostGIS** | Geospatial | Location-based queries, mapping, proximity search |
| **pg_partman** | Partition management | Automated partition creation/maintenance |
| **pg_stat_statements** | Query analytics | Identify slow queries, track query performance over time |
| **pg_cron** | Scheduled jobs | Periodic maintenance tasks (vacuum, aggregation, cleanup) |
| **pgcrypto** | Encryption | Column-level encryption, hashing |
| **pg_repack** | Online table rebuild | Reclaim bloat without exclusive locks |
| **HypoPG** | Hypothetical indexes | Test index impact without creating them |
| **pgaudit** | Audit logging | Compliance (SOC2, HIPAA, PCI-DSS) |
| **pg_hint_plan** | Query hints | Override planner decisions (last resort) |
| **pgMemento** | Audit trail | Schema-versioned transaction logging |

---

## 2. MySQL (8.4 LTS / 9.x Innovation)

### Version Model (introduced 2024)

MySQL now uses a dual-track release model:

| Track | Current Version | Purpose |
|-------|----------------|---------|
| **LTS** | MySQL 8.4 | Stability, 8-year support, bug fixes only |
| **Innovation** | MySQL 9.0 - 9.5+ | New features, shorter support, rapid iteration |

### MySQL 9.0 Key Features (Jul 2024)

**Vector data type:**
- Native vector storage and similarity search
- MySQL's answer to pgvector (less mature, fewer index options)
- Essential for AI, recommendation engines, embedding-based search

**JavaScript stored programs (Enterprise only):**
- Write stored procedures and triggers in JavaScript via GraalVM
- ECMAScript 2023 support
- Enterprise-only feature

**EXPLAIN ANALYZE JSON output:**
- Execution plans in JSON format for easier tooling and automation

### MySQL 9.1+ Improvements

**Crash-safe DDL:**
- `CREATE DATABASE` and `DROP DATABASE` are now fully transactional with InnoDB
- Atomic DDL eliminates partial schema states after crashes

**Trigger optimization:**
- Two-phase trigger handling: metadata read first, parsing deferred until needed
- Significant reduction in resource consumption for read-only queries

**MySQL 9.5 (Oct 2025):**
- `innodb_change_buffering` default changed to `ALL` for better secondary index updates
- Encryption enabled by default for all replication connections
- Enhanced security defaults across the board

### MySQL HeatWave

- In-memory query accelerator for real-time analytics on transactional data
- Eliminates ETL to separate analytics databases
- Single MySQL database service for OLTP, OLAP, and ML
- **99.99% uptime** claim with group replication and automatic failover
- Oracle Cloud managed service (not available self-hosted)

### MySQL vs PostgreSQL Decision

| Factor | PostgreSQL | MySQL |
|--------|-----------|-------|
| **Default recommendation** | Yes -- richer feature set | Only if team expertise is MySQL |
| **Transactional DDL** | Yes (huge advantage for migrations) | No (DDL auto-commits) |
| **JSON support** | JSONB (indexed, efficient) | JSON (functional but less performant) |
| **Full-text search** | Good (tsvector/tsquery) | Basic (InnoDB FTS) |
| **Extensions** | Rich ecosystem (pgvector, Citus, TimescaleDB) | Limited |
| **Replication** | Logical + streaming | Binlog-based, Group Replication |
| **Connection overhead** | Higher (process-per-connection) | Lower (thread-per-connection) |
| **Managed services** | RDS, Cloud SQL, Azure, Neon, Supabase | RDS, Cloud SQL, Azure, PlanetScale |
| **Ecosystem** | Rails, Django, Go, Java | PHP (WordPress, Laravel), Java (legacy) |

### MySQL Optimizer Hints

MySQL has a richer built-in hint system than PostgreSQL:
```sql
SELECT /*+ INDEX(t idx_name) */ * FROM t WHERE ...;
SELECT /*+ NO_INDEX_MERGE(t) */ * FROM t WHERE ...;
SELECT /*+ BNL(t1, t2) */ * FROM t1 JOIN t2 ON ...;
SELECT /*+ SET_VAR(optimizer_switch='mrr=on') */ * FROM t WHERE ...;
```

---

## 3. SQL Server (2022 / 2025)

### SQL Server 2022 (Nov 2022)

**Ledger tables:**
- Cryptographically linked transaction history for tamper-evident data
- Two types: **Updatable** (tracks all changes via history table) and **Append-only** (no UPDATE/DELETE)
- Streamlines audits with cryptographic proof of data integrity
- Use cases: financial records, regulatory compliance, supply chain

**Query Store improvements:**
- Query Store enabled by default for new databases
- Query Store hints (production-safe alternative to plan guides)
- CE feedback, DOP feedback, memory grant feedback

**Other notable features:**
- Contained availability groups (AG-level system databases)
- Parameter-sensitive plan optimization
- Approximate percentile functions
- Always Encrypted with secure enclaves

### SQL Server 2025 (Nov 2025, GA)

**AI-native capabilities:**
- Native **vector data type** and vector indexing (DiskANN-based)
- `VECTOR_SEARCH()` function for semantic search directly in T-SQL
- Support for external AI models
- Copilot in SSMS: natural language to T-SQL, query explanation, data Q&A

**Intelligent Query Processing 3.0:**
- AI-assisted query optimization hints
- Real-time execution plan correction
- Improved index management automation
- Upgraded Columnstore processing for batch mode analytics

**Always On AG improvements:**
- Fast failover for persistent health issues (`RestartThreshold = 0`)
- Better recovery from temporary quorum loss
- Enhanced health-check diagnostics for root cause analysis of unplanned failovers
- Zero-downtime maintenance windows

**OLTP improvements:**
- Reduced transaction contention with optimized locking mechanisms
- Higher throughput for real-time, high-transaction scenarios
- New `PRODUCT` aggregate function; `DATETRUNC` batch mode support

**When to choose SQL Server:**
- .NET ecosystem (Entity Framework, ASP.NET)
- Enterprise environments with existing Microsoft licensing
- Strong BI/reporting needs (SSRS, SSAS, Power BI integration)
- Compliance requirements (Ledger tables, Always Encrypted)
- AI workloads with Copilot integration needs

---

## 4. Indexing Strategies

### Index Type Decision Matrix

| Index Type | Best For | Size | Write Cost | PostgreSQL | MySQL | SQL Server |
|-----------|---------|------|-----------|------------|-------|------------|
| **B-tree** | Equality, range, sorting, most queries | Medium | Low | Default | Default | Default (clustered/non-clustered) |
| **Hash** | Exact equality lookups only | Small | Low | Yes (PG 10+) | Adaptive hash (internal) | No |
| **GIN** | Multi-value: JSONB, arrays, full-text, tsvector | Large | High | Yes | No | No |
| **GiST** | Spatial, range types, full-text, nearest-neighbor | Medium | Medium | Yes | No | Spatial index |
| **SP-GiST** | Non-balanced structures: phone numbers, IP addresses | Medium | Medium | Yes | No | No |
| **BRIN** | Large tables with naturally ordered data (time-series, logs) | Very small | Very low | Yes | No | No |
| **Covering (INCLUDE)** | Index-only scans, avoiding heap fetches | Larger | Medium | Yes (PG 11+) | Yes (8.0+) | Yes |
| **Columnstore** | Analytics, aggregations, OLAP | Compressed | High | No | No | Yes |

### PostgreSQL Index Patterns

**Partial indexes** -- index a subset of rows:
```sql
-- Only index active users (huge space savings if most are inactive)
CREATE INDEX idx_active_users ON users (email) WHERE is_active = true;

-- Only index unprocessed orders
CREATE INDEX idx_pending_orders ON orders (created_at) WHERE status = 'pending';
```

**Expression indexes** -- index computed values:
```sql
-- Case-insensitive email lookups
CREATE INDEX idx_users_email_lower ON users (lower(email));

-- Index JSONB field extraction
CREATE INDEX idx_orders_customer ON orders ((data->>'customer_id'));

-- Index date truncation for daily aggregations
CREATE INDEX idx_events_day ON events (date_trunc('day', created_at));
```

**Covering indexes** (INCLUDE clause) -- enable index-only scans:
```sql
-- Include columns needed by SELECT but not by WHERE/ORDER BY
CREATE INDEX idx_orders_status ON orders (status) INCLUDE (total, customer_id);

-- Query satisfied entirely from index (no heap fetch):
-- SELECT total, customer_id FROM orders WHERE status = 'shipped';

-- Supported by: B-tree, GiST, SP-GiST (not GIN or BRIN)
-- Limitation: expressions not supported as included columns
```

**BRIN indexes** -- for time-series and append-only tables:
```sql
-- Tiny index for billion-row log table (fraction of B-tree size)
CREATE INDEX idx_logs_created ON logs USING brin (created_at);

-- Works because rows are inserted chronologically (physical order correlates with value)
-- NOT effective if data is randomly ordered or frequently updated in place
```

**GIN indexes for JSONB:**
```sql
-- Index all JSONB keys and values (supports @>, ?, ?|, ?& operators)
CREATE INDEX idx_data_gin ON events USING gin (metadata);

-- Targeted: index specific JSONB path for equality
CREATE INDEX idx_data_type ON events USING gin ((metadata->'type'));
```

**Skip scan (PostgreSQL 18+):**
```sql
-- Previously, this query could NOT use a (user_id, created_at) index:
SELECT * FROM orders WHERE created_at > '2025-01-01';

-- PostgreSQL 18 skip scan can now use the multi-column index
-- by "skipping" over distinct values of user_id
-- Eliminates the need for a separate index on created_at alone
```

### Production Index Rules

1. **Always use `CREATE INDEX CONCURRENTLY`** on production PostgreSQL tables to avoid exclusive locks
2. **Monitor with `pg_stat_user_indexes`**: check `idx_scan` -- zero means the index is unused
3. **Watch index bloat**: use `pgstattuple` or `pg_stat_user_indexes` to detect bloated indexes
4. **Composite index column order matters**: most selective column first for equality, range column last
5. **Covering indexes trade write performance for read performance**: only use when reads dominate and query pattern is stable
6. **BRIN is not a silver bullet**: only works when physical row order correlates with column values
7. **Rebuild indexes periodically**: `REINDEX CONCURRENTLY` for heavily-updated tables

### Index Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Index every column** | Slows writes, wastes storage, confuses planner | Index only columns in WHERE, JOIN, ORDER BY |
| **Low-cardinality B-tree** | Boolean or status with 3 values -- full scan often faster | Partial index (`WHERE status = 'active'`) |
| **Missing composite index** | Separate single-column indexes != multi-column query | Create composite index matching query pattern |
| **Wrong column order** | `(a, b)` does not help `WHERE b = ?` | Leading column must match most selective filter |
| **Never VACUUM** | Dead tuples bloat tables and indexes | Tune autovacuum aggressively for write-heavy tables |
| **Unused indexes** | Slow down writes with zero benefit | Check `pg_stat_user_indexes` for `idx_scan = 0` |

---

## 5. Partitioning Strategies

### PostgreSQL Declarative Partitioning

**Partition types:**

| Type | Use Case | Example |
|------|----------|---------|
| **Range** | Time-series, date-based data, sequential IDs | Monthly order partitions |
| **List** | Categorical data, status, region, tenant | Partition by country code |
| **Hash** | Even distribution when no natural range/list exists | Partition by user_id hash |

**Range partitioning example:**
```sql
CREATE TABLE orders (
    id          bigint GENERATED ALWAYS AS IDENTITY,
    created_at  timestamptz NOT NULL,
    total       numeric(10,2),
    status      text
) PARTITION BY RANGE (created_at);

-- Bounds are inclusive lower, exclusive upper
CREATE TABLE orders_2025_q1 PARTITION OF orders
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
CREATE TABLE orders_2025_q2 PARTITION OF orders
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

-- Always create a default partition to catch unmatched rows
CREATE TABLE orders_default PARTITION OF orders DEFAULT;
```

**Multi-level partitioning:**
```sql
-- Range by date, then list by region
CREATE TABLE events (
    id bigint, created_at timestamptz, region text
) PARTITION BY RANGE (created_at);

CREATE TABLE events_2025 PARTITION OF events
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01')
    PARTITION BY LIST (region);

CREATE TABLE events_2025_us PARTITION OF events_2025
    FOR VALUES IN ('us-east', 'us-west');
CREATE TABLE events_2025_eu PARTITION OF events_2025
    FOR VALUES IN ('eu-west', 'eu-central');
```

**Hash partitioning** (even distribution):
```sql
CREATE TABLE sessions (
    id uuid, user_id uuid, data jsonb
) PARTITION BY HASH (user_id);

CREATE TABLE sessions_0 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE sessions_1 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE sessions_2 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE sessions_3 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### When to Partition vs When Not To

**Partition when:**
- Table exceeds **50-100 GB** and queries naturally filter on partition key
- Time-series data with queries bounded by date ranges
- Need efficient bulk data deletion (drop partition vs DELETE)
- Maintenance operations (VACUUM, REINDEX) need to be scoped to subsets
- Multi-tenant data where tenant isolation benefits performance

**Do NOT partition when:**
- Table is under 10-20 GB (indexes handle this fine)
- Queries don't filter on the partition key (no pruning benefit)
- High-frequency cross-partition queries (JOINs across partitions are expensive)
- The partition key changes frequently (row migration between partitions)
- You just want "organization" -- partitioning adds real complexity

### Partition Pruning

- Ensure `enable_partition_pruning = on` (default) in `postgresql.conf`
- The planner eliminates partitions that cannot contain matching rows
- Works at both plan time (static pruning) and execution time (dynamic pruning)
- Verify with `EXPLAIN`: look for `Subplans Removed: N` in the output
- Partition key **must** appear in WHERE clause for pruning to activate

### Partition Management with pg_partman

```sql
-- Automate partition creation and maintenance
CREATE EXTENSION pg_partman;
SELECT create_parent('public.events', 'created_at', 'native', 'monthly');

-- pg_partman automatically:
-- - Creates future partitions ahead of time
-- - Optionally drops/detaches old partitions
-- - Handles default partition overflow
```

### Operational Best Practices

1. **Automate partition creation**: use pg_partman or cron jobs to pre-create future partitions
2. **Create indexes on the partitioned table**: they automatically propagate to all partitions
3. **Cannot convert existing table to partitioned**: must create new partitioned table and migrate data
4. **Default partition**: always create one to catch rows that don't match any partition
5. **Monitor partition count**: hundreds of partitions slow down planning; keep it under ~200 if possible
6. **Detach before drop**: `ALTER TABLE ... DETACH PARTITION` then archive or drop

---

## 6. Replication and High Availability

### PostgreSQL HA Solutions

| Solution | Type | Failover | Complexity | Production Readiness |
|----------|------|----------|-----------|---------------------|
| **Patroni** | Streaming replication + consensus | Automatic | Medium-High | Battle-tested at scale (GitLab, Zalando) |
| **pg_auto_failover** | Streaming replication + monitor | Automatic | Low-Medium | Good for smaller deployments |
| **Stolon** | Streaming replication + etcd/consul | Automatic | Medium | Kubernetes-native |
| **CloudNativePG** | Kubernetes operator | Automatic | Medium | K8s-native PostgreSQL |
| **Native streaming** | Physical replication | Manual | Low | Foundation for all above |
| **Logical replication** | Selective table replication | N/A (not HA) | Medium | Cross-version, selective sync |

### Patroni (Recommended for Production)

Patroni is the industry standard for PostgreSQL HA (used by GitLab, Zalando, and most managed providers).

**Architecture:**
- Requires a distributed consensus store: etcd, Consul, or ZooKeeper
- Manages PostgreSQL streaming replication automatically
- Handles primary election, failover, switchover, and replica rewind
- Copies logical replication slot information to all standby nodes

**Replication modes:**
- **Asynchronous** (default): no write latency impact, potential data loss on failover
- **Synchronous**: zero data loss, higher write latency (at least one replica confirms)
- **Synchronous with quorum**: configurable N-of-M replicas must confirm

**Key operational concerns:**
- Minimum 3 nodes recommended (primary + 2 standbys) to maintain quorum
- 2-node setups need careful handling -- consider pg_auto_failover instead
- Test failover regularly in staging
- Monitor replication lag: `pg_stat_replication.replay_lag`

### pg_auto_failover

- Simpler than Patroni for small clusters (primary + standby)
- Uses a "monitor" node for health checking and failover decisions
- **Caveat**: monitor is a single point of failure for the failover mechanism
- If monitor is down when primary fails, no automatic failover occurs
- Good for: development, staging, smaller production workloads

### Logical Replication (PostgreSQL 17+)

Key improvements in PG 17/18:
- Failover-aware logical replication slots
- `pg_createsubscriber` tool converts physical replica to logical
- Hash index support on subscribers
- Improved performance with many subtransactions

**Use cases for logical replication:**
- Selective table replication (not entire database)
- Cross-version replication (for zero-downtime major upgrades)
- Multi-master with conflict resolution (via extensions like BDR)
- Real-time data integration to analytics systems

```sql
-- Publisher (source)
CREATE PUBLICATION orders_pub FOR TABLE orders, order_lines;

-- Subscriber (target)
CREATE SUBSCRIPTION orders_sub
    CONNECTION 'host=source dbname=mydb'
    PUBLICATION orders_pub;
```

### MySQL HA Architecture

| Solution | Failover | Multi-Primary | Best For |
|----------|----------|--------------|----------|
| **InnoDB Cluster** | Automatic | Yes (multi-primary mode) | Mission-critical apps, e-commerce, payments |
| **InnoDB ClusterSet** | Cross-DC DR | No (primary-primary across DCs) | Multi-region disaster recovery |
| **InnoDB ReplicaSet** | Manual | No | Read scaling, WAN-friendly, simpler setups |
| **Group Replication** | Automatic | Yes | Foundation layer (Cluster builds on this) |

**InnoDB Cluster** = Group Replication + MySQL Router + MySQL Shell. Provides automatic failover, data consistency, and node failure detection.

**InnoDB ReplicaSet** uses async replication, works well over WAN with no write performance impact, but requires manual failover. Best for scaling reads and geo-distributed deployments where automatic failover is not critical.

### SQL Server Always On

SQL Server 2025 enhancements:
- Fast failover for persistent health issues (`RestartThreshold = 0`)
- Better recovery from temporary quorum loss
- Enhanced health-check diagnostics
- Zero-downtime maintenance windows

### HA Strategy by Requirement

| Requirement | PostgreSQL | MySQL | SQL Server |
|-------------|-----------|-------|------------|
| **Automatic failover** | Patroni + etcd | InnoDB Cluster | Always On AG |
| **Zero data loss** | Patroni synchronous mode | Group Replication (sync) | Synchronous-commit AG |
| **Read scaling** | Streaming replicas + PgCat | InnoDB ReplicaSet + ProxySQL | AG readable secondaries |
| **Cross-region DR** | Patroni + async standby | InnoDB ClusterSet | Distributed AG |
| **Simple setup** | pg_auto_failover | InnoDB ReplicaSet | Basic AG |

---

## 7. Connection Pooling

### PostgreSQL Connection Poolers

| Pooler | Language | Threading | Read/Write Split | Sharding | Maturity |
|--------|----------|-----------|-----------------|----------|----------|
| **PgBouncer** | C | Single-threaded | No | No | Very High (since 2007) |
| **PgCat** | Rust | Multi-threaded | Yes (automatic) | Yes | Medium (newer) |
| **Odyssey** | C | Multi-threaded | No | No | Medium-High |
| **Supavisor** | Elixir | Multi-threaded | Yes | No | Medium (newer) |

### PgBouncer (Default Choice)

The most widely deployed PostgreSQL connection pooler. Handles 90% of use cases.

**Pooling modes:**
- **Transaction** (`transaction`): connection returned after each transaction. **Recommended for most apps.** Incompatible with session-level features (prepared statements, LISTEN/NOTIFY, SET).
- **Session** (`session`): connection returned when client disconnects. Safest, least efficient. Required for LISTEN/NOTIFY, prepared statements, temp tables.
- **Statement** (`statement`): connection returned after each statement. Rarely useful; breaks multi-statement transactions.

**Key settings:**
```ini
[pgbouncer]
pool_mode = transaction
max_client_conn = 10000      # client-facing limit
default_pool_size = 20        # connections per user/database pair
reserve_pool_size = 5         # extra connections for burst
reserve_pool_timeout = 3      # seconds before using reserve pool
server_idle_timeout = 600     # close idle server connections after 10 min
query_wait_timeout = 120      # max time client waits for a connection
```

**Limitations:**
- Single-threaded: one CPU core handles all connections
- No built-in read/write splitting
- No query routing or sharding
- Session-mode features break in transaction pooling mode

### PgCat (Modern Alternative)

Choose PgCat when you need features PgBouncer lacks:
- **Automatic read/write splitting**: SELECTs routed to replicas, writes to primary
- **Multi-threaded**: scales across CPU cores
- **Sharding support**: route queries to different backends
- **PgBouncer-compatible**: management API compatibility for migration

**When to choose PgCat over PgBouncer:**
- Read-heavy workloads that benefit from automatic replica routing
- High connection counts that saturate PgBouncer's single thread
- Need sharding at the proxy level

### MySQL: ProxySQL

ProxySQL is the standard connection pooler for MySQL:
- Query routing (read/write splitting)
- Query caching
- Connection multiplexing
- Query firewall and rewriting
- Works with Group Replication, InnoDB Cluster, Galera

### Sizing Guidelines

**Target**: `default_pool_size` = 2-3x the number of CPU cores on the database server.

A PostgreSQL instance with 16 cores typically performs best with **30-50 active connections**. Adding more connections **decreases** throughput due to context switching and lock contention. The pooler's job is to multiplex thousands of application connections into this smaller pool.

Formula: `max_connections` (PostgreSQL) = `default_pool_size` * number_of_pools + overhead

### Connection Pooler Selection

| Need | Choose | Why |
|------|--------|-----|
| **Simple, proven, low resources** | PgBouncer | Battle-tested since 2007, minimal CPU/memory |
| **Read/write splitting** | PgCat (PG) / ProxySQL (MySQL) | Automatic query routing |
| **High connection count (10K+)** | PgCat or Odyssey | Multi-threaded, scales across cores |
| **Cloud-native / Kubernetes** | PgCat or Supavisor | Modern architecture, better observability |
| **MySQL** | ProxySQL | Industry standard for MySQL |

---

## 8. Schema Design Best Practices

### Primary Key Strategy

| Strategy | Size | Sortable | Distributed-Safe | Index Performance | Recommendation |
|----------|------|----------|------------------|-------------------|----------------|
| **SERIAL / BIGSERIAL** | 4-8 bytes | Yes (insert order) | No (sequence gaps in multi-node) | Excellent (sequential) | Single-node OLTP, internal IDs |
| **UUIDv4** | 16 bytes | No (random) | Yes | Poor (random I/O, page splits) | **Avoid for new projects** |
| **UUIDv7** | 16 bytes | Yes (timestamp-ordered) | Yes | Good (sequential-ish) | **Recommended default for new projects** |
| **ULID** | 16 bytes | Yes (timestamp-ordered) | Yes | Good | Alternative to UUIDv7 |
| **Snowflake ID** | 8 bytes | Yes | Yes (with machine ID) | Excellent | High-throughput, Twitter-style |
| **NanoID** | Variable | No | Yes | Variable | URL slugs, user-facing IDs only |

**PostgreSQL 18+ recommendation:** Use `uuidv7()` native function for new tables:
```sql
CREATE TABLE orders (
    id uuid DEFAULT uuidv7() PRIMARY KEY,
    -- ...
);
```

**When to stick with BIGSERIAL:**
- Internal tables not exposed via API
- High-throughput inserts where 8 bytes vs 16 bytes matters
- Single-node deployments with no distributed requirements

**Dual-ID pattern (internal + external):**
```sql
CREATE TABLE users (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- internal
    public_id uuid DEFAULT uuidv7() UNIQUE NOT NULL,      -- external/API
    email text NOT NULL
);
-- Use `id` for JOINs (compact), `public_id` for API responses (opaque)
```

### Soft Deletes

**Approach: `deleted_at` timestamp (not boolean):**
```sql
ALTER TABLE users ADD COLUMN deleted_at timestamptz;

-- Partial index for active records (most queries)
CREATE INDEX idx_users_active ON users (email) WHERE deleted_at IS NULL;

-- "Delete" a user
UPDATE users SET deleted_at = now() WHERE id = $1;

-- View for convenience
CREATE VIEW active_users AS SELECT * FROM users WHERE deleted_at IS NULL;
```

**When soft deletes are appropriate:**
- User-facing trash/recycle bin with short retention (30 days)
- Very low deletion rate (under 1% of operations)
- Temporary holds or reversible actions

**When to avoid soft deletes (use archive tables instead):**
- Deletion rate exceeds 5% of operations
- Tables have UNIQUE constraints (soft-deleted rows still occupy unique slots)
- GDPR compliance requires actual data removal
- Large tables where deleted rows bloat indexes

**Archive table pattern (preferred alternative):**
```sql
CREATE TABLE users_archive (LIKE users INCLUDING ALL, archived_at timestamptz DEFAULT now());

CREATE FUNCTION archive_user() RETURNS trigger AS $$
BEGIN
    INSERT INTO users_archive SELECT OLD.*, now();
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_archive_user BEFORE DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION archive_user();
```

### Temporal Tables and Audit Trails

**SQL Server (native support since 2016):**
```sql
CREATE TABLE employees (
    id int PRIMARY KEY,
    name nvarchar(100),
    salary decimal(10,2),
    SysStartTime datetime2 GENERATED ALWAYS AS ROW START,
    SysEndTime   datetime2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
) WITH (SYSTEM_VERSIONING = ON);

-- Query as of a point in time
SELECT * FROM employees FOR SYSTEM_TIME AS OF '2025-01-15';
```

**PostgreSQL (no native system-versioned tables yet):**
Options for audit trails:
1. **temporal_tables extension**: system-period data versioning with automatic history table
2. **Trigger-based audit logging**: custom triggers that write to an audit table
3. **pgMemento**: extension that tracks all changes with schema versioning
4. **pgAudit**: extension for SQL statement-level audit logging

**PostgreSQL 18 temporal constraints** help with application-time temporal data but are NOT system-versioned tables. They enforce non-overlapping time ranges:
```sql
CREATE TABLE room_bookings (
    room_id int,
    booking_period tstzrange,
    guest text,
    PRIMARY KEY (room_id, booking_period WITHOUT OVERLAPS)
);
```

### Multi-Tenant Schema Design

| Pattern | Isolation | Complexity | Best For |
|---------|-----------|-----------|----------|
| **Shared table** (tenant_id column) | Low | Low | SaaS with many small tenants |
| **Schema per tenant** | Medium | Medium | Moderate isolation needs |
| **Database per tenant** | High | High | Regulated industries, large tenants |
| **Citus distributed** | Medium | Medium | Shared table + horizontal scaling |

**Shared table with Row-Level Security:**
```sql
CREATE TABLE orders (
    id uuid DEFAULT uuidv7() PRIMARY KEY,
    tenant_id uuid NOT NULL,
    total numeric(10,2)
);

-- Enforce tenant isolation
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Every table gets tenant_id as the leading index column
CREATE INDEX idx_orders_tenant ON orders (tenant_id, created_at DESC);
```

### Normalization Guidelines

| Scenario | Strategy | Reason |
|----------|----------|--------|
| OLTP (default) | 3NF | Data integrity, minimal redundancy |
| Read-heavy with complex JOINs | Selective denormalization | Avoid expensive joins on hot paths |
| Analytics / reporting | Star schema (denormalized) | Query performance over write efficiency |
| Multi-tenant SaaS | 3NF + tenant_id column | Shared schema, row-level security |
| Event sourcing | Append-only event log | Immutable events, derive state |

---

## 9. Performance Tuning

### EXPLAIN ANALYZE Patterns

**Reading EXPLAIN output -- key metrics:**
```
Seq Scan on orders  (cost=0.00..1234.00 rows=50000 width=64) (actual time=0.015..45.123 rows=50000 loops=1)
  ^^^^                ^^^^               ^^^^^                 ^^^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^
  Scan type           Planner estimate   Estimated rows        Actual timing              Actual rows
```

**Critical patterns to identify:**

| Pattern | Symptom | Fix |
|---------|---------|-----|
| **Seq Scan on large table** | Full table scan when index expected | Add appropriate index, check predicate types |
| **Nested Loop with high loops** | O(n*m) performance | Ensure inner table has index, consider hash/merge join |
| **Rows estimate wildly wrong** | Planner chooses bad plan | Run `ANALYZE`, check for correlated columns, update statistics target |
| **Sort + Limit without index** | Sorting entire table for top-N | Add index matching ORDER BY |
| **Bitmap Heap Scan + Recheck** | Index scan with lossy blocks | Normal for GIN/BRIN; check if B-tree would be better |
| **Hash Join + temp written** | Join spills to disk | Increase `work_mem` or reduce result set |
| **Index Scan with Filter** | Index used but many rows filtered post-scan | Index doesn't cover WHERE clause; adjust index |

**Advanced EXPLAIN options:**
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT YAML) SELECT ...;
-- BUFFERS: shows shared/local block hits/reads (I/O patterns)
-- FORMAT YAML/JSON: machine-parseable output
-- WAL: shows WAL bytes generated (PG 13+)
-- SETTINGS: shows non-default settings affecting the query (PG 15+)
```

### Index-Only Scans

For an index-only scan, the visibility map must be mostly up-to-date:
```sql
-- Check visibility map coverage
SELECT relname, n_tup_mod, last_vacuum, last_autovacuum
FROM pg_stat_user_tables WHERE relname = 'orders';

-- If Heap Fetches is high relative to rows, VACUUM is needed
EXPLAIN (ANALYZE, BUFFERS) SELECT total, status FROM orders WHERE id = 42;
-- Look for: "Heap Fetches: 0" (ideal) vs "Heap Fetches: 12345" (VACUUM needed)
```

### Materialized Views

```sql
CREATE MATERIALIZED VIEW monthly_revenue AS
    SELECT date_trunc('month', created_at) AS month,
           sum(total) AS revenue,
           count(*) AS order_count
    FROM orders
    GROUP BY 1;

CREATE UNIQUE INDEX idx_monthly_revenue ON monthly_revenue (month);

-- Refresh strategies:
REFRESH MATERIALIZED VIEW monthly_revenue;                -- blocks reads during refresh
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_revenue;   -- allows reads, requires unique index
```

**Refresh patterns:**
- **Periodic**: pg_cron for hourly/daily refresh
- **On-demand**: trigger refresh after batch loads
- **Concurrent refresh**: `CONCURRENTLY` keyword prevents read blocking (requires unique index on the materialized view)

### pg_hint_plan (Query Hints for PostgreSQL)

PostgreSQL has no built-in query hints, but `pg_hint_plan` extension provides them via SQL comments:
```sql
/*+ SeqScan(orders) */ SELECT * FROM orders WHERE id = 42;     -- force seq scan
/*+ IndexScan(orders idx_orders_pkey) */ SELECT * FROM orders;  -- force specific index
/*+ HashJoin(orders customers) */ SELECT ...;                    -- force hash join
/*+ NestLoop(t1 t2) MergeJoin(t3 t4) */ SELECT ...;            -- multiple hints
```

**Hint table** (modify plans without changing SQL):
- Store hints in `hint_plan.hints` table keyed by query hash
- No application code changes needed
- `pg_stat_statements` groups queries with different hints together (ignores comments)

### Key PostgreSQL Tuning Parameters

| Parameter | Default | Recommendation | Impact |
|-----------|---------|---------------|--------|
| `shared_buffers` | 128 MB | 25% of RAM | Buffer cache size |
| `effective_cache_size` | 4 GB | 50-75% of RAM | Planner's estimate of OS cache |
| `work_mem` | 4 MB | 16-256 MB (depends on concurrency) | Per-operation sort/hash memory |
| `maintenance_work_mem` | 64 MB | 512 MB - 2 GB | VACUUM, CREATE INDEX memory |
| `random_page_cost` | 4.0 | 1.1 (SSD) / 4.0 (HDD) | Index scan cost estimate |
| `effective_io_concurrency` | 1 | 200 (SSD) / 2 (HDD) | Concurrent I/O for bitmap scans |
| `max_parallel_workers_per_gather` | 2 | 2-4 (per CPU cores) | Parallel query workers |
| `jit` | on (PG 12+) | off for OLTP, on for analytics | JIT compilation |
| `wal_compression` | off | `zstd` (PG 15+) | Reduces WAL size 50-70% |
| `default_statistics_target` | 100 | 200-500 for complex queries | Planner estimate accuracy |
| `io_method` | sync | `io_uring` (PG 18+, Linux) | Async I/O subsystem |

### pg_stat_statements (Essential Monitoring)

```sql
-- Top 10 queries by total execution time
SELECT query, calls, total_exec_time, mean_exec_time,
       rows, shared_blks_hit, shared_blks_read
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 10;

-- Queries with worst cache hit ratio
SELECT query, shared_blks_hit, shared_blks_read,
       round(shared_blks_hit::numeric / nullif(shared_blks_hit + shared_blks_read, 0), 3) AS hit_ratio
FROM pg_stat_statements
WHERE calls > 100
ORDER BY hit_ratio ASC LIMIT 10;

-- Find unused indexes
SELECT schemaname, tablename, indexname, idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## 10. Scaling Patterns

### Scaling Decision Framework

| Stage | Data Size | Strategy | Tools |
|-------|-----------|----------|-------|
| **Start** | < 100 GB | Vertical scaling, index tuning | Single PostgreSQL/MySQL instance |
| **Growth** | 100 GB - 1 TB | Read replicas + connection pooling | Streaming replication, PgBouncer |
| **Scale** | 1 TB - 10 TB | Partitioning + selective denormalization | Declarative partitioning, materialized views |
| **High Scale** | 10 TB+ | Horizontal sharding | Citus, Vitess, application-level sharding |
| **Global Scale** | Multi-region, strong consistency | Distributed SQL | CockroachDB, YugabyteDB, Spanner |

### Vertical Scaling (Do This First)

Before distributing, optimize the single instance:
1. **Upgrade hardware**: bigger instance, more RAM, faster SSDs (NVMe)
2. **Tune configuration**: shared_buffers, work_mem, effective_cache_size
3. **Optimize queries**: indexes, EXPLAIN ANALYZE, eliminate N+1s
4. **Add connection pooling**: PgBouncer / ProxySQL
5. **Use materialized views**: pre-compute expensive aggregations

Stack Overflow handles massive traffic on a single SQL Server instance with aggressive caching and optimization.

### Read Replicas

**When read replicas help:**
- Read/write ratio > 80/20
- Reporting queries that would block OLTP
- Geographic read distribution

**When read replicas do not help:**
- Write-heavy workloads (writes still go to single primary)
- Queries requiring strong consistency (replica lag)
- Complex transactions mixing reads and writes

**Implementation:**
- PostgreSQL: streaming replication, route reads via PgCat or application
- MySQL: InnoDB ReplicaSet + ProxySQL for automatic routing
- SQL Server: Always On AG readable secondaries

### Citus (PostgreSQL Horizontal Sharding)

Citus is the leading PostgreSQL extension for horizontal sharding, now part of Microsoft Azure.

**Architecture:**
- Coordinator node: receives queries, plans distribution
- Worker nodes: store distributed shards
- Table types: **distributed** (sharded), **reference** (replicated to all workers), **local** (coordinator only)

**Shard key selection (critical):**
```sql
-- Good: tenant_id for multi-tenant SaaS (co-locates all tenant data)
SELECT create_distributed_table('orders', 'tenant_id');

-- Good: user_id for user-centric applications
SELECT create_distributed_table('activities', 'user_id');

-- Bad: created_at (time-based causes hot partition on recent shard)
-- Bad: id (random distribution prevents co-located joins)
```

**Best fit for Citus:**
- Multi-tenant SaaS (data never joins between tenants)
- High data volume analytics (100 GB+ per tenant)
- Real-time dashboards on distributed data

**Not ideal for Citus:**
- Small databases (under 100 GB)
- Complex cross-shard joins on unrelated keys
- Workloads with no natural shard key

### Application-Level Sharding

When extensions and tools are insufficient, shard at the application level:

**Shard key selection rules:**
1. High cardinality (many distinct values)
2. Even distribution (no hot shards)
3. Present in most queries (avoid cross-shard queries)
4. Stable (do not need to re-shard when value changes)

Common shard keys: tenant_id, user_id, geographic region.

**Challenges:**
- Cross-shard queries require scatter-gather
- Resharding (adding/removing shards) is complex
- Distributed transactions (2PC) add latency
- Schema migrations must coordinate across all shards

---

## 11. NewSQL and Distributed SQL

### Platform Comparison

| Platform | Compatibility | Consistency | Best For | License |
|----------|--------------|-------------|----------|---------|
| **CockroachDB** | PostgreSQL wire protocol | Serializable (default) | Multi-region, strong consistency OLTP | BSL (source-available) |
| **YugabyteDB** | PostgreSQL (reuses PG query layer) | Serializable / Snapshot | PostgreSQL-compatible distributed SQL | Apache 2.0 |
| **TiDB** | MySQL wire protocol | Snapshot isolation | HTAP (hybrid transactional + analytical) | Apache 2.0 |
| **Neon** | Full PostgreSQL | Same as PostgreSQL | Serverless Postgres, branching, AI agents | Proprietary (managed) |
| **PlanetScale** | MySQL (Vitess-based) | Eventual to strong | Auto-scaling MySQL, non-blocking migrations | Proprietary (managed) |
| **AlloyDB** | Google-managed PostgreSQL | Strong | Analytics on OLTP data (columnar engine) | Proprietary (managed) |

### CockroachDB

- Raft consensus for distributed transactions
- Range-based partitioning with automatic rebalancing
- **Serializable isolation** by default (strongest level)
- Multi-region: pin data to specific regions, geo-partition for compliance
- Latency: expect 2-10x higher than single-node PostgreSQL for single-row operations
- Best for: global applications, multi-region strong consistency, regulatory compliance

### YugabyteDB

- Reuses PostgreSQL query layer code for highest PG compatibility
- DocDB storage engine (LSM-tree based, inspired by Google Spanner)
- Supports both YSQL (PostgreSQL-compatible) and YCQL (Cassandra-compatible) APIs
- Open-source under Apache 2.0
- Best for: teams wanting distributed SQL with maximum PostgreSQL compatibility

### TiDB

- MySQL-compatible distributed database
- Separates compute (TiDB) from storage (TiKV for OLTP, TiFlash for OLAP)
- **HTAP**: run analytics on real-time transactional data without ETL
- Strong in China/Asia ecosystem
- Best for: HTAP workloads, MySQL shops needing horizontal scaling

### Neon (Acquired by Databricks, May 2025, ~$1B)

- Serverless PostgreSQL with storage-compute separation
- **Instant branching**: O(1) copy-on-write database forks (< 1 second)
- Scale to zero: compute spins down when idle, cold start ~500ms
- Full PostgreSQL compatibility (light Postgres codebase modifications)
- **AI agent adoption**: 80%+ of Neon databases now created by AI agents
- Post-acquisition pricing: storage reduced from $1.75 to $0.35/GB, compute costs down 15-25%
- Best for: development/staging branches, serverless workloads, AI agent databases

### PlanetScale

- Built on Vitess (YouTube's MySQL sharding framework)
- Non-blocking schema changes (online DDL without locks)
- Auto-scaling: handled Black Friday 2024 surge without configuration changes
- No foreign key support at database level (application-enforced)
- Near-linear scalability up to 1M+ QPS
- Best for: MySQL-heavy teams, high-write applications, safe schema changes

### When to Use Distributed SQL vs Traditional

**Use traditional PostgreSQL/MySQL when:**
- Data fits on one node (< 1-2 TB active data)
- Single-region deployment
- Need lowest possible latency (< 5ms P99)
- Team expertise is in traditional RDBMS
- Budget-conscious (distributed SQL is more expensive to operate)

**Use distributed SQL when:**
- Multi-region active-active requirements
- Data volume exceeds single-node capacity
- Regulatory requirement for data residency
- Need horizontal write scaling (not just read scaling)
- Can tolerate 2-10x latency overhead vs single-node

---

## 12. Vector Search and AI Workloads

### pgvector (PostgreSQL)

pgvector is the standard PostgreSQL extension for vector similarity search.

**Current state (pgvector 0.8.0, 2025):**
- Up to **9x faster** query processing vs 0.7.x on Aurora PostgreSQL
- **5.7x improvement** for specific query patterns vs 0.7.4
- Iterative scan (`iterative_scan`) for improved recall on filtered ANN queries
- Better cost estimation for choosing between ANN index and traditional index

**Index types:**

| Index | Algorithm | Build Time | Query Time | Recall | Memory |
|-------|-----------|-----------|------------|--------|--------|
| **IVFFlat** | Inverted file with flat quantization | Fast | Moderate | Moderate | Low |
| **HNSW** | Hierarchical navigable small world | Slow | Fast | High | High |

```sql
-- Enable pgvector
CREATE EXTENSION vector;

-- Create table with vector column
CREATE TABLE documents (
    id bigint PRIMARY KEY,
    content text,
    embedding vector(1536)  -- OpenAI text-embedding-3-small dimension
);

-- HNSW index (recommended for most cases)
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Query: find 10 nearest neighbors
SELECT id, content, embedding <=> '[0.1, 0.2, ...]'::vector AS distance
FROM documents
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 10;
```

**pgvectorscale (Timescale extension):**
- StreamingDiskANN index: **471 QPS at 99% recall** on 50M vectors
- 11.4x better than Qdrant, competitive with Pinecone at **79% lower cost**
- 1.4x lower latency than Pinecone p2
- Better for large-scale (10M+ vectors) production workloads

**When to use pgvector:**
- Already running PostgreSQL (avoid new infrastructure)
- Under 10M vectors (sweet spot for single-node pgvector)
- Need SQL JOINs with vector search (hybrid queries)
- Want transactional consistency between vectors and relational data

**When to use a dedicated vector database:**
- Over 100M vectors
- Need specialized features (hybrid search, metadata filtering at scale)
- Vector search is the primary workload (not a secondary feature)

### SQL Server 2025 Vector Support

- Native `vector` data type
- Vector indexing (DiskANN-based)
- `VECTOR_SEARCH()` function for semantic search in T-SQL
- Integration with Azure OpenAI for embedding generation

### MySQL 9.0 Vector Support

- Native vector data type (introduced in 9.0)
- Less mature than pgvector; limited index options
- Suitable for basic similarity search within MySQL ecosystem

---

## 13. Decision Matrices

### Database Selection by Workload

| Workload | First Choice | Second Choice | Avoid |
|----------|-------------|---------------|-------|
| **General OLTP** | PostgreSQL 18 | MySQL 8.4 LTS | Distributed SQL (overkill) |
| **Multi-tenant SaaS** | PostgreSQL + Citus | CockroachDB | MySQL (less partitioning) |
| **Global multi-region** | CockroachDB | YugabyteDB | Single-node anything |
| **MySQL migration** | PlanetScale | TiDB | CockroachDB (wire protocol mismatch) |
| **Serverless / dev** | Neon | PlanetScale | Self-hosted (operational overhead) |
| **HTAP (OLTP + OLAP)** | TiDB | PostgreSQL + ClickHouse (polyglot) | Single OLTP database |
| **Enterprise / Microsoft** | SQL Server 2025 | Azure SQL | PostgreSQL (ecosystem mismatch) |
| **AI / vector workloads** | PostgreSQL + pgvector | SQL Server 2025 | MySQL (immature vector support) |
| **Time-series** | TimescaleDB (on PG) | QuestDB | General RDBMS (not optimized) |

### Overall Decision Framework

| Decision | Default | Switch When |
|----------|---------|-------------|
| **Database engine** | PostgreSQL | MySQL (existing expertise/stack), SQL Server (.NET enterprise) |
| **Primary key** | UUIDv7 (PG 18+) or BIGINT + UUID dual-ID | Snowflake ID (high throughput distributed) |
| **Indexing** | B-tree | GIN (JSONB, arrays, FTS), BRIN (time-series large tables), partial (filtered workloads) |
| **Partitioning** | Don't (until >50-100 GB or need time-based cleanup) | Range by date (events), list by tenant, hash for even distribution |
| **Connection pooling** | PgBouncer (transaction mode) | PgCat (need query routing), ProxySQL (MySQL) |
| **Replication** | Streaming + read replicas | Logical (migrations, selective), synchronous (zero data loss) |
| **HA** | Patroni (self-managed), managed service HA (cloud) | CloudNativePG (K8s native), pg_auto_failover (small clusters) |
| **Scaling** | Vertical first, then read replicas, then Citus | Application sharding (extreme scale), CockroachDB/YugabyteDB (multi-region) |
| **Serverless PG** | Neon | Supabase (need full backend), Aurora Serverless (AWS-native) |

---

*Last verified: April 2026. Database versions and features change rapidly. Always confirm with official documentation and `WebSearch` before advising on specific version capabilities.*
