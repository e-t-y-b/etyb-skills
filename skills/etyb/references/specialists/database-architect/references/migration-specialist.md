# Database Migration Specialist — Deep Reference

**Always use `WebSearch` to verify current tool versions, breaking changes, and cloud provider updates before giving migration advice. The migration tooling landscape evolves rapidly.**

## Table of Contents
1. [Migration Tools Comparison](#1-migration-tools-comparison)
2. [Schema Versioning Approaches](#2-schema-versioning-approaches)
3. [Zero-Downtime Migration Patterns](#3-zero-downtime-migration-patterns)
4. [Online Schema Change Tools](#4-online-schema-change-tools)
5. [Large Table Migrations](#5-large-table-migrations)
6. [Data Backfill Strategies](#6-data-backfill-strategies)
7. [Blue-Green Database Deployments](#7-blue-green-database-deployments)
8. [Rollback Strategies](#8-rollback-strategies)
9. [Multi-Database Migrations](#9-multi-database-migrations)
10. [NoSQL Migrations](#10-nosql-migrations)
11. [Testing Migrations](#11-testing-migrations)
12. [Common Pitfalls](#12-common-pitfalls)
13. [PostgreSQL-Specific Guidance](#13-postgresql-specific-guidance)
14. [MySQL-Specific Guidance](#14-mysql-specific-guidance)
15. [Migration Decision Framework](#15-migration-decision-framework)

---

## 1. Migration Tools Comparison

### Tool Selection Matrix (2025-2026)

| Tool | Language/Ecosystem | Approach | DB Support | Best For |
|------|-------------------|----------|------------|----------|
| **Flyway 12** (Redgate) | Java / CLI / Any | Versioned SQL | 50+ databases | Teams wanting SQL-first simplicity |
| **Liquibase 5** | Java / CLI / Any | Versioned (XML/YAML/SQL/JSON) | 50+ databases | Enterprise with audit/compliance needs |
| **Atlas** (Ariga) | Go / CLI / Any | Declarative + Versioned hybrid | PostgreSQL, MySQL, SQLite, SQL Server, ClickHouse, Redshift | Modern teams wanting schema-as-code |
| **Prisma Migrate** | TypeScript/Node.js | Declarative (Prisma DSL) | PostgreSQL, MySQL, SQLite, SQL Server, MongoDB, CockroachDB | TypeScript/Node.js projects using Prisma ORM |
| **Alembic** | Python | Versioned (Python scripts) | Any SQLAlchemy-supported DB | Python projects using SQLAlchemy |
| **golang-migrate** | Go / CLI | Versioned SQL | 20+ (Postgres, MySQL, Mongo, Cassandra, Spanner, etc.) | Go projects needing broad DB driver support |
| **TypeORM Migrations** | TypeScript | Versioned (TypeScript) | PostgreSQL, MySQL, SQLite, etc. | TypeORM-based projects |
| **Atlas + Prisma** | TypeScript + Go | Declarative hybrid | Prisma-supported DBs | Prisma schema with Atlas migration engine |
| **dbmate** | Go / CLI | Versioned SQL | PostgreSQL, MySQL, SQLite, ClickHouse | Lightweight, language-agnostic projects |
| **Sqitch** | Perl / CLI | Versioned SQL (dependency-based) | PostgreSQL, MySQL, SQLite, Oracle, Firebird | Teams wanting dependency-graph ordering |
| **pgroll** (Xata) | Go / CLI | Expand/contract automation | PostgreSQL 14+ | PostgreSQL teams needing automated zero-downtime |
| **Bytebase** | Go / Web UI | GUI + versioned | PostgreSQL, MySQL, many more | Teams wanting a web-based review/approval UI |

### Tool Details

#### Flyway 12 (Redgate) — Current Stable
- **Configuration**: Unified `flyway.toml` format (deprecates older `.conf` and JSON); single file for Desktop and CLI settings
- **Multi-environment**: TOML supports multiple database environments referenced via `--environment` flag
- **New in 2025-2026**: AI-generated migration descriptions in Flyway Desktop 8, SARIF 2.1.0 report generation for GitHub Code Scanning / Azure DevOps, SQLite native connectors, Postgres 18 / SQL Server 2025 / Oracle 26ai support
- **Licensing**: Community (free, Apache 2.0 for CLI) and Teams/Enterprise (paid)
- **Strengths**: Simple mental model (numbered SQL files), massive DB support, mature ecosystem
- **Weaknesses**: No declarative mode, rollback requires separate undo scripts (Teams edition), no built-in drift detection in community

#### Liquibase 5.0 (September 2025)
- **Architecture change**: Two distributions — Liquibase Community (FSL license) and Liquibase Secure (enterprise)
- **New in 5.0**: Integrated Liquibase Package Manager (LPM) via `liquibase lpm`, validate `--strict` mode, SensitiveInfo policy check scanning for PII/PHI in changelogs, AI Changelog Generator via MCP Server
- **Minimum**: Java 17+ required
- **Strengths**: XML/YAML/SQL/JSON changelog formats, fine-grained ordering, database-agnostic changelog syntax, enterprise rollback controls, Flow orchestration
- **Weaknesses**: Heavier than Flyway for simple use cases, FSL license change may concern some teams
- **Licensing change**: Moved from Apache 2.0 to Functional Source License (FSL) for Community — free for direct use but prevents third-party monetization

#### Atlas (Ariga) — Declarative Schema-as-Code
- **Approach**: Define desired state in HCL, SQL, or via ORM schema loaders (GORM, Prisma, Django, SQLAlchemy, Drizzle, TypeORM, Sequelize, Hibernate, EF Core); Atlas computes diff and generates migration plan
- **Hybrid workflow**: Declarative locally (`atlas schema apply` for dev), versioned in CI (`atlas migrate diff` generates migration files for code review)
- **Migration linting**: 50+ automated checks for destructive changes, lock risks, data-dependent changes
- **CI/CD integrations**: GitHub Actions, GitLab CI, Kubernetes Operator, Terraform Provider, ArgoCD
- **Computed rollbacks**: Automatically generates undo migrations alongside forward migrations
- **Strengths**: Most modern DX, ORM integration, automatic plan generation, lint + test built in
- **Weaknesses**: Newer ecosystem, fewer production battle scars than Flyway/Liquibase

#### pgroll (Xata) — PostgreSQL Zero-Downtime Automation
- **What it does**: Automates the expand/contract pattern for PostgreSQL 14+
- **Mechanism**: Creates shadow columns for breaking changes, sets up triggers for dual-write, handles backfill, provides instant rollback by dropping new columns
- **Key feature**: Serves multiple schema versions simultaneously using PostgreSQL schemas — old and new application versions coexist during rollout
- **Written in**: Go, single binary, no external dependencies
- **Compatible with**: RDS, Aurora, self-hosted PostgreSQL
- **Best for**: Teams deploying with rolling updates who need guaranteed backward compatibility during migration windows

### Recommendation by Scenario

| Scenario | Recommended Tool |
|----------|-----------------|
| Greenfield project, want modern DX | Atlas |
| Enterprise with compliance/audit requirements | Liquibase Secure |
| Simple SQL-first, broad DB support | Flyway |
| Python + SQLAlchemy project | Alembic |
| TypeScript + Prisma project | Prisma Migrate or Atlas + Prisma |
| Go project, simple needs | golang-migrate or dbmate |
| PostgreSQL, need automated zero-downtime | pgroll |
| Team wants GUI review/approval workflow | Bytebase |
| Need dependency-graph migration ordering | Sqitch |

---

## 2. Schema Versioning Approaches

### Imperative (Versioned) Migrations

Traditional approach: ordered sequence of migration scripts, each describing a change.

```
migrations/
  001_create_users.sql
  002_add_email_index.sql
  003_create_orders.sql
  004_add_orders_status_column.sql
```

**How it works**: Tool tracks which migrations have been applied in a `schema_migrations` table. To get current schema, replay all migrations from scratch.

**Pros**:
- Explicit, reviewable changes
- Full control over DDL
- Natural audit trail
- Easy to understand

**Cons**:
- Source of truth requires replaying entire history
- Drift detection is hard (prod schema may diverge from migration history)
- Merge conflicts in migration ordering
- Manual rollback scripts needed

### Declarative (State-Based) Migrations

Modern approach: define desired end-state, tool computes diff.

```hcl
# Atlas HCL example
schema "public" {
  table "users" {
    column "id" { type = bigint }
    column "email" { type = varchar(255) }
    column "created_at" { type = timestamptz }
    index "idx_users_email" { columns = [column.email] }
  }
}
```

```prisma
// Prisma schema example
model User {
  id        BigInt   @id @default(autoincrement())
  email     String   @unique @db.VarChar(255)
  createdAt DateTime @default(now()) @map("created_at")
}
```

**How it works**: Tool compares desired state against live database (or previous migration history) and generates migration plan.

**Pros**:
- Schema is always readable as a single file
- Automatic migration plan generation
- Easy drift detection (compare desired vs actual)
- ORM integration (single source of truth)

**Cons**:
- Generated plans may need human review for complex changes (e.g., column rename vs drop+add)
- Less control over exact DDL execution order
- Can be surprising if you don't review generated SQL

### Hybrid Approach (Recommended)

Atlas pioneered the hybrid workflow, now considered best practice:

1. **During development**: Use declarative mode — edit schema file, run `atlas schema apply` against local DB for fast iteration
2. **For shared environments**: Run `atlas migrate diff` to generate a versioned migration file from schema changes
3. **In CI/CD**: Migration files go through code review, linting, and automated testing
4. **In production**: `atlas migrate apply` executes reviewed migration files

This gives you:
- Readable schema definition (declarative)
- Explicit, reviewable migration files (versioned)
- Automatic plan generation (no hand-writing DDL)
- CI/CD safety nets (linting, testing)

---

## 3. Zero-Downtime Migration Patterns

### The Expand/Contract Pattern (Primary Pattern)

The industry-standard approach for zero-downtime schema changes. Break one risky change into multiple safe steps.

#### Phase 1: Expand
Add new schema alongside old schema. Both old and new application versions work.

```sql
-- Example: renaming column "name" to "full_name"
-- Step 1: Add new column (non-breaking)
ALTER TABLE users ADD COLUMN full_name VARCHAR(255);
```

#### Phase 2: Dual Write
Deploy application code that writes to both old and new locations.

```python
# Application writes to both columns
user.name = value
user.full_name = value
```

OR use database triggers:
```sql
CREATE OR REPLACE FUNCTION sync_name_to_full_name()
RETURNS TRIGGER AS $$
BEGIN
  NEW.full_name = COALESCE(NEW.full_name, NEW.name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### Phase 3: Backfill
Copy historical data from old to new format in batches.

```sql
-- Backfill in batches of 1000
UPDATE users SET full_name = name
WHERE full_name IS NULL AND id BETWEEN $start AND $end;
```

#### Phase 4: Read Cutover
Switch application reads to the new column. Use feature flags to enable gradual rollout.

```python
# Behind feature flag
if feature_enabled("read_full_name"):
    return user.full_name
else:
    return user.name
```

#### Phase 5: Contract
Remove old column and dual-write code after verification period (1-2 weeks typical).

```sql
ALTER TABLE users DROP COLUMN name;
```

### Dual-Write Pattern

For migrating between databases or tables:

1. **Start dual-writing** to both old and new locations
2. **Backfill** historical data from old to new
3. **Verify** data consistency (checksums, row counts, sample comparison)
4. **Switch reads** to new location (behind feature flag)
5. **Monitor** for 1-2 weeks
6. **Stop writing** to old location
7. **Decommission** old table/database

**Critical ordering**: Always start dual writes BEFORE backfill — this prevents missing changes that occur during backfill.

### Shadow Table Pattern

Used for major restructuring where in-place modification is impossible:

1. Create shadow table with new schema
2. Set up CDC (Change Data Capture) or triggers to replicate changes
3. Backfill historical data into shadow table
4. Verify shadow table is in sync
5. Atomic swap (RENAME TABLE in MySQL, or pg_repack-style swap in PostgreSQL)

### Key Principles

- **Backward compatibility**: Every intermediate state must work with both old and new application versions
- **Batch operations**: Process backfills in batches (500-5000 rows), commit between batches, add brief sleep to keep p95 latency stable
- **Feature flags**: Use flags to control read/write paths during transition
- **Monitoring**: Track error rates, latency percentiles, and data consistency throughout
- **Cooling period**: Keep dual-write/dual-read active for 1-2 weeks before final cleanup

---

## 4. Online Schema Change Tools

### MySQL Online Schema Change Tools

| Tool | Mechanism | Foreign Keys | Throttling | Cut-over | Best For |
|------|-----------|-------------|------------|----------|----------|
| **gh-ost** (GitHub) | Binlog tailing (triggerless) | No FK support | Yes, dynamic via Unix socket | Atomic rename | Large tables where you need runtime control |
| **pt-online-schema-change** (Percona) | Trigger-based | Partial (limited) | Yes, replica-lag based | Atomic rename | Broad compatibility, simpler setup |
| **Spirit** (Block/Cash App) | Binlog tailing (like gh-ost) | No FK support | Dynamic chunk-time targeting | Atomic rename | Faster than gh-ost, MySQL 8.0+ only |
| **MySQL Online DDL** (native) | InnoDB internal | Yes | No throttling | In-place | Simple operations, INSTANT DDL candidates |

#### gh-ost (GitHub)
- Requires Row-Based Replication (RBR)
- Creates ghost table, copies data in chunks while tailing binlog for concurrent changes
- **Runtime control**: Unix socket interface to reconfigure throttling, get status, manually pause, trigger cut-over while running
- **Auditable**: All operations logged, can inspect state at any time
- **Limitation**: No foreign key support, requires binlog access

#### pt-online-schema-change (Percona)
- Uses DML triggers (INSERT, UPDATE, DELETE) on original table to capture changes
- Synchronous: triggers fire on every write, adding overhead to write operations
- Cut-over: Atomic `RENAME TABLE`
- Better FK support than gh-ost (though still limited)
- Simpler to set up, fewer infrastructure requirements

#### Spirit (Block/Cash App) — New in 2024-2025
- **Modern gh-ost replacement** by MySQL expert Morgan Tocker
- Dynamic chunk sizing: takes target chunk time (e.g., 500ms) and adjusts chunk size automatically — safer for wide tables with many indexes, faster for small tables
- **Instant DDL detection**: Automatically attempts MySQL 8.0 INSTANT DDL before falling back to copy
- **Metadata-only detection**: Recognizes INPLACE operations that only modify metadata and executes directly
- **Limitation**: Read replicas may lag up to 10 seconds behind writer (gh-ost better if tight replica lag required)
- MySQL 8.0+ only

#### When to Use Which

| Situation | Recommended Tool |
|-----------|-----------------|
| MySQL 8.0+, want fastest migration | Spirit |
| Need runtime control and auditability | gh-ost |
| Need FK support or simpler setup | pt-online-schema-change |
| Operation supports INSTANT DDL | Native MySQL Online DDL |
| Table < 10GB, simple ALTER | Native MySQL Online DDL |
| Table > 100GB, complex ALTER | Spirit or gh-ost |

### PostgreSQL Online Schema Change Tools

| Tool | Purpose | Locking | Best For |
|------|---------|---------|----------|
| **pg_repack** | Table/index reorganization, bloat removal | ACCESS EXCLUSIVE only briefly (trigger creation + swap) | Reclaiming space, rewriting tables |
| **pgroll** | Automated expand/contract migrations | Minimal locking | Zero-downtime column changes |
| **CREATE INDEX CONCURRENTLY** | Index creation without write locks | SHARE UPDATE EXCLUSIVE (no write blocking) | Adding indexes to large tables |
| **pg_squeeze** | Table compaction | Brief lock | Alternative to pg_repack |

#### pg_repack
- Removes table bloat without blocking reads/writes during processing
- Creates fresh copy of bloated table, tracks changes during rebuild, briefly locks for atomic swap
- **Requirement**: Table must have PRIMARY KEY or UNIQUE NOT NULL index
- **Supports**: PostgreSQL 9.5 through 18
- Holds ACCESS SHARE lock during most of operation (reads + writes continue)
- ACCESS EXCLUSIVE lock only during trigger creation at start and catalog swap at end

---

## 5. Large Table Migrations

### Strategies for Billion-Row Tables

#### Range-Based Chunking (Most Common)
Split by primary key ranges, process in parallel:

```python
# Pseudocode for batched backfill
BATCH_SIZE = 5000
SLEEP_BETWEEN_BATCHES = 0.1  # seconds

cursor = min_id
while cursor <= max_id:
    execute("""
        UPDATE large_table 
        SET new_column = compute(old_column)
        WHERE id BETWEEN %s AND %s
        AND new_column IS NULL
    """, [cursor, cursor + BATCH_SIZE])
    commit()
    cursor += BATCH_SIZE
    sleep(SLEEP_BETWEEN_BATCHES)
```

**Key tuning parameters**:
- **Batch size**: 500-5000 rows typical; tune based on row width and index count
- **Sleep interval**: 50-200ms between batches; adjust based on p95 latency impact
- **Parallelism**: Multiple workers on non-overlapping key ranges
- **Off-peak hours**: Run heavy backfills during low-traffic windows

#### Shadow Table Strategy
For major restructuring:

1. Create new table with desired schema
2. Disable foreign keys and secondary indexes on new table during initial load
3. Bulk copy data in ranges (faster without indexes)
4. Rebuild indexes after bulk copy completes
5. Set up CDC/triggers to capture changes since copy started
6. Apply captured changes
7. Atomic swap

#### Change Data Capture (CDC) Migration
For cross-database or major restructuring:

1. Set up CDC (Debezium, DMS, etc.) to stream changes from source
2. Initial snapshot load to destination
3. CDC catches up with changes made during snapshot
4. Verify consistency (row counts, checksums)
5. Brief write pause for final sync
6. Cut over reads and writes

#### Pre-Computation Strategy
For complex data transformations:

1. Export relevant data to data warehouse (zero production impact)
2. Compute transformation mapping in warehouse
3. Generate batched UPDATE statements from mapping
4. Apply updates to production in controlled batches

### Critical Rules for Large Table Backfills

1. **Never do schema change + backfill in one migration** — PostgreSQL can freeze writes for 40+ minutes on 300M+ row tables
2. **Add column as nullable first**, backfill in batches, then add NOT NULL constraint with NOT VALID + VALIDATE
3. **Monitor replication lag** if using replicas — throttle backfill if lag increases
4. **Disable autovacuum temporarily** on the target table during heavy backfill (re-enable immediately after)
5. **Use COPY for initial loads** instead of INSERT when possible (10-50x faster)
6. **Checkpoint impact**: Large backfills generate WAL; monitor checkpoint frequency
7. **Test with production-sized data**: An operation completing in ms on a 1K-row dev table may lock for minutes on 100M rows

---

## 6. Data Backfill Strategies

### Strategy Selection Matrix

| Strategy | Latency Impact | Implementation Complexity | Data Consistency | Best For |
|----------|---------------|--------------------------|------------------|----------|
| **Eager (batch)** | Medium (during backfill) | Low | Strong (after completion) | One-time migrations, small-medium tables |
| **Lazy (on-read)** | Per-request overhead | Medium | Eventually consistent | Large tables, gradual rollout |
| **Background job** | Low (off-peak) | Medium | Eventually consistent | Large tables, non-urgent |
| **Dual-read** | Minimal | High | Strong | Critical data, zero-risk tolerance |
| **CDC-based** | Minimal | High | Strong | Cross-database, real-time sync |

### Eager Migration (Batch Backfill)
Run a batch job to update all rows at once (in batches):

```ruby
# Rails example with find_each
User.where(full_name: nil).find_each(batch_size: 1000) do |user|
  user.update_columns(full_name: user.name)
end
```

**Use when**: Table fits in reasonable processing window, consistency needed quickly
**Watch out for**: Lock contention, replication lag, WAL generation

### Lazy Migration (On-Read)
Migrate documents/rows when they're accessed:

```python
def get_user(user_id):
    user = db.users.find_one({"_id": user_id})
    if user.get("schema_version", 1) < CURRENT_VERSION:
        user = migrate_user_document(user)
        db.users.replace_one({"_id": user_id}, user)
    return user
```

**Use when**: Very large datasets, can tolerate mixed schema versions
**Watch out for**: Read latency spike on first access, orphaned old-format records never accessed

### Background Job Backfill
Dedicated workers process records from a queue:

```python
# Fan-out backfill jobs
for chunk_start in range(min_id, max_id, CHUNK_SIZE):
    backfill_queue.enqueue(
        'backfill_chunk',
        start=chunk_start,
        end=chunk_start + CHUNK_SIZE,
        queue='backfill',  # Dedicated queue, don't block priority jobs
        retry=3
    )
```

**Use when**: Large tables, don't want to impact user-facing traffic
**Watch out for**: Queue depth monitoring, retry handling, idempotency

### Dual-Read Pattern
Read from both old and new locations, compare results:

```python
def get_order(order_id):
    old_result = old_db.orders.get(order_id)
    new_result = new_db.orders.get(order_id)
    
    if new_result is None:
        # Not yet migrated, use old
        return old_result
    
    # Compare for verification (log mismatches)
    if old_result != new_result:
        metrics.increment("migration.mismatch")
        log.warning(f"Data mismatch for order {order_id}")
    
    if feature_flag("read_from_new_db"):
        return new_result
    return old_result
```

**Use when**: High-risk migrations where data accuracy is critical (financial, healthcare)
**Watch out for**: Double read latency, comparison logic complexity

### Monitoring During Backfill

Key metrics to track:
- **CDC lag per partition** (if using CDC)
- **Backfill throughput** (rows/second)
- **Write error rate** on destination
- **Read mismatch rate** (dual-read)
- **p95/p99 latency** for user-facing queries
- **Replication lag** on read replicas
- **Disk I/O and CPU** on database servers

---

## 7. Blue-Green Database Deployments

### Architecture

```
                    ┌─────────────┐
                    │  DB Proxy / │
                    │  Load Bal.  │
                    └──────┬──────┘
                           │
                ┌──────────┴──────────┐
                │                     │
         ┌──────▼──────┐       ┌──────▼──────┐
         │  Blue (Prod) │       │ Green (Stage)│
         │  PostgreSQL  │◄─────►│  PostgreSQL  │
         │  Primary     │ Repl  │  Primary     │
         └─────────────┘       └──────────────┘
```

### Process

1. **Blue** is current production
2. **Green** is provisioned as identical replica
3. Apply schema migration to Green
4. Validate Green with new application version
5. Switch proxy/LB to route traffic to Green
6. Blue becomes standby (rollback target)
7. After verification period, decommission Blue

### AWS RDS Blue/Green Deployments (Native Support)

AWS provides managed blue/green for RDS and Aurora:

- **Setup**: Creates green environment as replica of blue via logical replication
- **Schema changes**: Apply DDL to green while blue continues serving traffic
- **Switchover**: Automated promotion of green with connection draining
- **RDS Proxy integration**: Automatically detects topology change and redirects connections without waiting for DNS propagation
- **AWS JDBC Driver plugin** (February 2026): Automatic detection of blue/green deployment phases, intelligent inventory management of both environments, dynamic traffic routing based on switchover status
- **Downtime**: Typically under 1 minute for switchover

### Database Proxy Patterns

| Pattern | Tool | How It Works |
|---------|------|-------------|
| **AWS RDS Proxy** | Managed | Connection pooling + automatic failover + blue/green awareness |
| **PgBouncer** | Self-hosted | Connection pooling, can be reconfigured to point to new primary |
| **ProxySQL** | Self-hosted (MySQL) | Query routing, read/write splitting, backend switching |
| **HAProxy** | Self-hosted | TCP-level routing, health checks, backend switching |
| **Vitess** | Self-hosted (MySQL) | Full database proxy with schema migration built in |

### Key Considerations

- Schema changes MUST be backward-compatible or use expand/contract during switchover
- Replication lag between blue and green must be near-zero before switchover
- Application connection strings should point to proxy/LB, not directly to database
- Test switchover procedure in staging first
- Have a rollback plan (switch back to blue if green has issues)

---

## 8. Rollback Strategies

### Forward-Only vs Reversible Migrations

| Aspect | Forward-Only (Fix Forward) | Reversible (Rollback Scripts) |
|--------|---------------------------|-------------------------------|
| **Philosophy** | Deploy a corrective migration | Undo the failed migration |
| **Speed** | Fast for additive changes | Fast if scripts are tested |
| **Data safety** | No data loss risk from rollback | Risk of data loss if drop/truncate |
| **Effort** | Write fix-forward migration | Write and maintain undo scripts |
| **Testing** | Only test forward path | Must test both forward and backward |
| **Industry trend** | Growing preference (2024-2026) | Still required for regulated industries |

### Decision Matrix

| Change Type | Recommended Strategy |
|-------------|---------------------|
| ADD COLUMN (nullable) | Forward-only — drop column if needed |
| ADD INDEX | Forward-only — drop index if needed |
| DROP COLUMN | Cannot roll back without backup — ALWAYS take backup first |
| RENAME COLUMN | Expand/contract with alias — rollback = keep old column |
| ADD NOT NULL constraint | Forward-only — drop constraint if needed |
| Data transformation | Dual-write + feature flag — rollback = flip flag |
| Table restructuring | Shadow table — rollback = switch back to old table |

### Three Levels of Rollback Strategy

#### Level 1: Migration-Level Rollback
Individual migration undo scripts:

```sql
-- Forward
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Rollback
ALTER TABLE users DROP COLUMN phone;
```

**Limitation**: Cannot recover data from dropped columns.

#### Level 2: Application-Level Rollback
Expand/contract pattern where both old and new schemas work simultaneously:

```
Deploy v1 (writes to old)
Deploy v2 (writes to old + new) ← rollback = redeploy v1
Backfill new from old
Deploy v3 (reads from new) ← rollback = redeploy v2
Remove old column ← NO rollback past this point
```

#### Level 3: Database-Level Rollback
Point-in-time recovery (PITR) to before the migration:

- PostgreSQL: `pg_basebackup` + WAL replay to specific timestamp
- MySQL: Binary log replay to specific position
- Cloud: RDS/Aurora automated backups with PITR

**Rule of thumb**: Always create a pre-migration snapshot or logical backup, regardless of rollback strategy. This is your last-resort safety net.

### Practical Guidance

1. **Additive changes**: Fix forward (add column, add index, add table)
2. **Destructive changes**: Always have a rollback plan and backup
3. **Data transformations**: Use expand/contract with feature flags
4. **Test rollbacks**: If you write rollback scripts, test them in CI against production-sized data
5. **Time limit**: If a migration hasn't been rolled back within 30 minutes, fix forward is usually faster
6. **Atlas computed rollbacks**: Atlas automatically generates undo migrations alongside forward migrations — reduces manual effort

---

## 9. Multi-Database Migrations

### Coordination Challenges

When schema changes span multiple databases (microservices, multi-tenant):

1. **No distributed transactions for DDL** — you cannot atomically change schemas across databases
2. **Ordering matters** — dependent services must migrate in correct order
3. **Partial failure** — one database succeeds, another fails, leaving inconsistent state
4. **Version skew** — during rollout, different services see different schema versions

### Patterns

#### Decoupled Migration (Recommended)
Run migrations as a separate pre-deployment step, not embedded in application startup:

```yaml
# Kubernetes Job — runs before application deployment
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: myapp:latest
        command: ["atlas", "migrate", "apply", "--url", "$(DB_URL)"]
      restartPolicy: OnFailure
```

**Benefits**: Migration failures don't crash application, can retry independently, clear separation of concerns.

#### Schema Registry for Multi-Tenant
For systems with many tenant databases:

```sql
-- Central registry tracks migration state per tenant
CREATE TABLE schema_registry (
    tenant_id    UUID,
    version      INTEGER,
    description  TEXT,
    applied_at   TIMESTAMPTZ,
    script_hash  TEXT,
    PRIMARY KEY (tenant_id, version)
);
```

Each tenant manages its own updates at its own pace. No distributed locks required.

#### Migration Dependency Graph
When services have cross-database dependencies:

```
Service A (users DB)    → migrate first (adds new column)
Service B (orders DB)   → migrate second (references new column via API)
Service C (analytics DB) → migrate last (reads from both)
```

Encode these dependencies in your deployment pipeline (not in the migration tool).

#### Turso/LibSQL Pattern (Million-Database Scale)
For embedded databases (one per user/tenant):
- Client-side migration on database open
- Schema registry tracks current version
- Each database migrates independently when accessed
- No central orchestration needed

### Multi-Database Safety Checklist

- [ ] Each database migration is independently deployable and rollback-safe
- [ ] Cross-database dependencies documented and encoded in pipeline
- [ ] No migration assumes another database has already migrated
- [ ] Each migration is backward-compatible (expand/contract)
- [ ] Monitoring for failed migrations across all databases
- [ ] Automated retry with backoff for transient failures
- [ ] Schema drift detection across tenant databases

---

## 10. NoSQL Migrations

### MongoDB Schema Versioning

#### The Schema Versioning Pattern
Add a `schemaVersion` field to every document:

```javascript
// v1 document
{
  _id: ObjectId("..."),
  schemaVersion: 1,
  name: "Jane Doe",
  address: "123 Main St, Springfield, IL 62701"
}

// v2 document (structured address)
{
  _id: ObjectId("..."),
  schemaVersion: 2,
  name: "Jane Doe",
  address: {
    street: "123 Main St",
    city: "Springfield",
    state: "IL",
    zip: "62701"
  }
}
```

**Application handling**:
```javascript
function getUser(doc) {
  switch (doc.schemaVersion) {
    case 1:
      return { ...doc, address: parseAddress(doc.address) };
    case 2:
      return doc;
    default:
      throw new Error(`Unknown schema version: ${doc.schemaVersion}`);
  }
}
```

#### MongoDB Migration Strategies

| Strategy | When to Use | Downtime |
|----------|------------|----------|
| **Lazy migration** | Large collections, gradual rollout | Zero |
| **Eager migration** | Small collections, need consistency | Possible (if large) |
| **Predictive migration** | Can predict access patterns | Zero |
| **Schema validation** | Enforce shape going forward | Zero |

**Lazy migration**: Migrate documents on read, write back updated version. 45% reduction in deployment errors reported by organizations using this pattern.

**Eager migration**: Batch update all documents. Use `bulkWrite` with batching for large collections.

**MongoDB Schema Validation** (enforce going forward):
```javascript
db.runCommand({
  collMod: "users",
  validator: {
    $jsonSchema: {
      required: ["schemaVersion", "name"],
      properties: {
        schemaVersion: { bsonType: "int", minimum: 2 }
      }
    }
  },
  validationAction: "warn"  // "error" to strictly enforce
});
```

### DynamoDB Migration Strategies

#### Key Design Challenges
- Cannot change partition key or sort key after table creation
- Adding new access patterns may require new Global Secondary Indexes (GSIs)
- Single-table designs are harder to restructure than multi-table

#### Migration Approaches

1. **In-place attribute addition**: Add new attributes to existing items (no migration needed for new optional fields)
2. **GSI addition**: Add new GSI for new access pattern (online, but takes time to backfill)
3. **Table recreation**: Create new table with new key structure, migrate data via DynamoDB Streams + Lambda
4. **Export/transform/import**: Export to S3, transform with Glue/EMR, import to new table

#### DynamoDB Streams for Live Migration

```python
# Lambda triggered by DynamoDB Stream on old table
def handler(event, context):
    for record in event['Records']:
        if record['eventName'] in ['INSERT', 'MODIFY']:
            new_image = record['dynamodb']['NewImage']
            transformed = transform_item(new_image)
            new_table.put_item(Item=transformed)
        elif record['eventName'] == 'REMOVE':
            key = record['dynamodb']['Keys']
            new_table.delete_item(Key=key)
```

### Document Evolution Best Practices

1. **Always include a version field** in documents (schemaVersion, _v, version)
2. **Make application code handle all known versions** — never assume all documents are current
3. **Use validation rules** to enforce shape for new writes while allowing old reads
4. **Prefer additive changes** (new fields with defaults) over destructive changes (field removal/rename)
5. **Background migration jobs** for eventually cleaning up old versions
6. **Test with mixed-version data** — create test fixtures with all schema versions

---

## 11. Testing Migrations

### CI/CD Integration

#### Migration Testing Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Lint    │───►│ Empty DB │───►│ Prod-like│───►│ Staging  │
│  Check   │    │  Test    │    │  Test    │    │  Deploy  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
     │               │               │               │
  Static          Replay all     Test against      Full
  analysis        migrations     snapshot of      integration
  (Atlas lint,    from scratch   production data   test
   Squawk)
```

#### Level 1: Static Analysis / Linting

```yaml
# GitHub Actions — Atlas migration lint
- name: Lint migrations
  run: |
    atlas migrate lint \
      --dev-url "docker://postgres/15" \
      --dir "file://migrations" \
      --latest 1
```

Tools for migration linting:
- **Atlas migrate lint**: 50+ checks for destructive changes, lock risks, data-dependent operations
- **Squawk** (PostgreSQL): Lints SQL migrations for unsafe patterns (missing CONCURRENTLY, lock-heavy operations)
- **strong_migrations** (Rails gem): Catches unsafe migrations at development time
- **django-pg-zero-downtime-migrations** (Django): Enforces safe patterns for PostgreSQL

#### Level 2: Empty Database Testing
Replay all migrations from scratch on an empty database:

```yaml
# CI step
- name: Test migrations from scratch
  run: |
    createdb test_migrations
    atlas migrate apply --url "postgres://localhost/test_migrations"
    # Verify final schema matches expected
    atlas schema inspect --url "postgres://localhost/test_migrations" > actual.hcl
    diff expected.hcl actual.hcl
```

#### Level 3: Production-Snapshot Testing
Test against a copy of production data:

```yaml
# Scheduled CI job (nightly)
- name: Restore production snapshot
  run: |
    # Restore latest sanitized production backup
    pg_restore --no-owner -d test_prod /backups/latest_sanitized.dump
    
- name: Run pending migrations
  run: |
    atlas migrate apply --url "postgres://localhost/test_prod"
    
- name: Verify application works
  run: |
    APP_DATABASE_URL="postgres://localhost/test_prod" npm test
```

**Critical**: Use sanitized snapshots (PII removed) in CI.

#### Level 4: Ephemeral Database Testing
Spin up disposable database instances per CI run:

Tools:
- **Spawn** (Redgate): Provisions ephemeral databases with production data in seconds
- **Neon branching**: Creates copy-on-write database branches from production
- **PlanetScale branching**: MySQL branching with schema diff and deploy requests
- **Docker**: Ephemeral containers with pg_dump restore

### Rollback Testing

```yaml
# Test that rollback scripts work
- name: Apply migration
  run: atlas migrate apply --url $DB_URL
- name: Run rollback
  run: atlas migrate down --url $DB_URL --count 1
- name: Verify schema after rollback
  run: |
    atlas schema inspect --url $DB_URL > after_rollback.hcl
    diff before_migration.hcl after_rollback.hcl
```

### Migration Testing Checklist

- [ ] All migrations pass lint checks (no unsafe patterns)
- [ ] Migrations replay cleanly from empty database
- [ ] Migrations apply successfully against production-sized data
- [ ] Application passes integration tests after migration
- [ ] Rollback scripts tested (if applicable)
- [ ] Migration execution time measured and within acceptable window
- [ ] Lock acquisition time measured on production-sized tables
- [ ] Schema drift detection passes (actual matches expected)

---

## 12. Common Pitfalls

### Locking Issues

#### The Lock Queue Problem (PostgreSQL)
The most dangerous and least understood migration pitfall:

```
Long-running query holds ACCESS SHARE lock on table
    → Migration tries to acquire ACCESS EXCLUSIVE lock
        → Migration WAITS (queued behind long query)
            → ALL NEW QUERIES queue behind the waiting migration
                → Application appears frozen
```

**Solution**: Always set `lock_timeout` before DDL:
```sql
SET lock_timeout = '2s';  -- Fail fast instead of queue
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
```

If the lock times out, retry during a quieter period or cancel long-running queries first.

#### Advisory Locks for Migration Coordination
```sql
-- Prevent concurrent migration runs
SELECT pg_advisory_lock(12345);
-- ... run migrations ...
SELECT pg_advisory_unlock(12345);
```

### NOT NULL on Large Tables

**Problem**: `ALTER TABLE users ALTER COLUMN email SET NOT NULL` scans entire table to verify no NULLs exist while holding ACCESS EXCLUSIVE lock.

**Safe alternative** (PostgreSQL):
```sql
-- Step 1: Add constraint as NOT VALID (instant, no scan)
ALTER TABLE users ADD CONSTRAINT users_email_not_null 
  CHECK (email IS NOT NULL) NOT VALID;

-- Step 2: Validate constraint (scans table but only holds 
-- SHARE UPDATE EXCLUSIVE lock — reads and writes continue)
ALTER TABLE users VALIDATE CONSTRAINT users_email_not_null;

-- Step 3 (optional): Convert to proper NOT NULL
-- In PostgreSQL 12+, the optimizer recognizes CHECK constraints
-- so you may not even need the actual NOT NULL
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
-- This is now instant because PG knows the CHECK already validated it
```

### Index Creation Blocking Writes

**Problem**: `CREATE INDEX` acquires SHARE lock — allows reads but blocks all writes.

**Solution**:
```sql
-- PostgreSQL: Use CONCURRENTLY
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- IMPORTANT: Cannot run inside a transaction block!
-- Framework escape hatches:
--   Rails: disable_ddl_transaction!
--   Django: atomic = False on migration
--   Alembic: op.execute() outside transaction
--   Flyway: Use separate migration file (each file = one transaction)
```

**If concurrent index creation fails** (it can, unlike regular CREATE INDEX):
```sql
-- Check for invalid indexes
SELECT indexname, indexdef FROM pg_indexes 
WHERE schemaname = 'public' AND indexname LIKE '%INVALID%';

-- Drop and retry
DROP INDEX CONCURRENTLY idx_users_email;
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

### Enum Changes (PostgreSQL)

**Problem 1**: Cannot use newly added enum value in the same transaction:
```sql
-- This FAILS inside a transaction:
ALTER TYPE status_enum ADD VALUE 'archived';
UPDATE orders SET status = 'archived' WHERE ...; -- ERROR: unsafe use of new value
```

**Solution**: Add enum value in a separate migration, deployed before code that uses it.

**Problem 2**: Cannot remove enum values — only add:
```sql
ALTER TYPE status_enum ADD VALUE 'archived';  -- Works
ALTER TYPE status_enum DROP VALUE 'archived'; -- DOES NOT EXIST
```

**Workaround for enum removal**: Create new enum type, migrate column, drop old type:
```sql
CREATE TYPE status_enum_v2 AS ENUM ('active', 'inactive');
ALTER TABLE orders ALTER COLUMN status TYPE status_enum_v2 
  USING status::text::status_enum_v2;
DROP TYPE status_enum;
ALTER TYPE status_enum_v2 RENAME TO status_enum;
```

**Recommendation**: Consider using VARCHAR with CHECK constraints instead of enums for frequently-changing value sets.

### Column Rename vs Drop+Add

**Problem**: Declarative migration tools may interpret a rename as "drop old + add new", losing data.

**Solution**: 
- Always review generated migration SQL before applying
- Atlas and Prisma prompt for clarification on ambiguous changes
- For manual migrations, use explicit RENAME:
```sql
ALTER TABLE users RENAME COLUMN name TO full_name;
```

### Default Value Changes on Large Tables

**PostgreSQL 11+**: Adding a column with DEFAULT is instant (stored in catalog, applied on read). No table rewrite needed.

**PostgreSQL < 11 and MySQL (pre-8.0 INSTANT DDL)**: Adding column with DEFAULT rewrites entire table. Use expand/contract: add nullable column, backfill, add constraint.

### Foreign Key with Cascade

**Problem**: Adding FK with `ON DELETE CASCADE` on a large table locks both tables while validating.

**Solution** (PostgreSQL):
```sql
-- Add FK as NOT VALID (instant)
ALTER TABLE orders ADD CONSTRAINT fk_orders_user 
  FOREIGN KEY (user_id) REFERENCES users(id) NOT VALID;

-- Validate separately (non-blocking for new writes)
ALTER TABLE orders VALIDATE CONSTRAINT fk_orders_user;
```

---

## 13. PostgreSQL-Specific Guidance

### Transactional DDL Advantage

PostgreSQL wraps DDL in transactions — if a migration with multiple statements fails partway through, all changes roll back automatically. This is a major advantage over MySQL.

```sql
BEGIN;
  CREATE TABLE new_feature (...);
  ALTER TABLE users ADD COLUMN feature_flag BOOLEAN DEFAULT false;
  CREATE INDEX CONCURRENTLY ...; -- ERROR: cannot run in transaction
ROLLBACK; -- Both CREATE TABLE and ALTER TABLE are rolled back
```

**Exception**: `CREATE INDEX CONCURRENTLY` and `ALTER TYPE ... ADD VALUE` cannot run inside transactions.

### Safe Migration Patterns

#### Adding a column
```sql
-- Safe: nullable column with default (PG 11+ is instant)
ALTER TABLE users ADD COLUMN phone VARCHAR(20) DEFAULT NULL;
```

#### Adding a NOT NULL column
```sql
-- Step 1: Add nullable column
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
-- Step 2: Backfill in batches (separate migration or script)
-- Step 3: Add NOT NULL via CHECK constraint
ALTER TABLE users ADD CONSTRAINT chk_phone_not_null CHECK (phone IS NOT NULL) NOT VALID;
ALTER TABLE users VALIDATE CONSTRAINT chk_phone_not_null;
-- Step 4 (PG 12+): Set NOT NULL (instant because CHECK is validated)
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
ALTER TABLE users DROP CONSTRAINT chk_phone_not_null;
```

#### Creating an index
```sql
-- Always use CONCURRENTLY for production tables
SET statement_timeout = '0';  -- Index creation can take a long time
CREATE INDEX CONCURRENTLY idx_users_phone ON users(phone);
```

#### Adding a foreign key
```sql
ALTER TABLE orders ADD CONSTRAINT fk_user 
  FOREIGN KEY (user_id) REFERENCES users(id) NOT VALID;
ALTER TABLE orders VALIDATE CONSTRAINT fk_user;
```

#### Changing column type
```sql
-- DANGER: Changing column type rewrites the table for most types
-- Safe type changes (no rewrite): varchar(N) → varchar(M) where M > N
-- Safe: removing varchar length limit entirely
ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(500); -- rewrite if shrinking

-- For complex type changes, use expand/contract:
ALTER TABLE users ADD COLUMN new_col NEW_TYPE;
-- backfill new_col from old_col
-- switch reads
ALTER TABLE users DROP COLUMN old_col;
ALTER TABLE users RENAME COLUMN new_col TO old_col;
```

### pg_dump for Schema Management

```bash
# Dump schema only (no data) — useful for schema version control
pg_dump --schema-only --no-owner --no-privileges dbname > schema.sql

# Compare schemas between environments
pg_dump --schema-only prod_db > prod_schema.sql
pg_dump --schema-only staging_db > staging_schema.sql
diff prod_schema.sql staging_schema.sql

# Use with Atlas for drift detection
atlas schema inspect --url "postgres://prod_host/db" > actual.hcl
atlas schema diff --from "file://actual.hcl" --to "file://desired.hcl"
```

### PostgreSQL Lock Reference

| Lock Type | Acquired By | Conflicts With |
|-----------|------------|----------------|
| ACCESS SHARE | SELECT | ACCESS EXCLUSIVE |
| ROW SHARE | SELECT FOR UPDATE | EXCLUSIVE, ACCESS EXCLUSIVE |
| ROW EXCLUSIVE | INSERT, UPDATE, DELETE | SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| SHARE UPDATE EXCLUSIVE | VACUUM, CREATE INDEX CONCURRENTLY, VALIDATE CONSTRAINT | SHARE UPDATE EXCLUSIVE, SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| SHARE | CREATE INDEX (non-concurrent) | ROW EXCLUSIVE, SHARE UPDATE EXCLUSIVE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| ACCESS EXCLUSIVE | ALTER TABLE, DROP TABLE, TRUNCATE, REINDEX | ALL lock types |

**Key insight**: ACCESS EXCLUSIVE (used by most ALTER TABLE operations) blocks everything, including SELECT. SHARE UPDATE EXCLUSIVE (used by CONCURRENTLY and VALIDATE) allows reads AND writes.

### Recommended lock_timeout Settings

```sql
-- For DDL in production
SET lock_timeout = '2s';

-- For batch operations
SET statement_timeout = '30s';

-- For index creation (can take hours)
SET statement_timeout = '0';  -- No timeout
SET lock_timeout = '5s';      -- But fail fast if can't get lock
```

---

## 14. MySQL-Specific Guidance

### DDL Algorithm Hierarchy (MySQL 8.0+)

MySQL tries algorithms in this order: INSTANT → INPLACE → COPY

| Algorithm | Locking | Table Rewrite | Speed | Available Since |
|-----------|---------|---------------|-------|----------------|
| **INSTANT** | Metadata lock only | No | Immediate | MySQL 8.0.12+ |
| **INPLACE** | Varies (often NONE) | Sometimes | Minutes-hours | MySQL 5.6+ |
| **COPY** | Full table lock | Yes | Hours-days | Always |

### INSTANT DDL Operations (MySQL 8.0.12+)

Operations that complete immediately without touching data:
- Add column at end of table (8.0.12+) or any position (8.0.29+)
- Drop column (8.0.29+)
- Add/drop virtual generated column
- Set/drop column default value
- Modify ENUM/SET column (add values to end only)
- Change index type

**INSTANT is the default algorithm in MySQL 8.4+**

### INPLACE DDL Operations

Operations that modify data in-place (no full copy), may allow concurrent DML:
- Add/drop index
- Rename column (8.0+)
- Add/drop foreign key
- Change column type (some cases)
- Convert character set

### Online DDL Limitations

Critical limitations to be aware of:

1. **No throttling mechanism**: Cannot pause or slow down an online DDL operation
2. **FK constraint issue**: `LOCK=NONE` not permitted when `ON...CASCADE` or `ON...SET NULL` exists
3. **Metadata lock timeout**: Long-running transactions holding metadata lock can cause DDL to timeout
4. **Column drop restrictions**: Cannot combine DROP COLUMN with other INSTANT-incompatible operations in same ALTER TABLE
5. **No concurrent index creation**: Unlike PostgreSQL, MySQL does not have CREATE INDEX CONCURRENTLY — use ALGORITHM=INPLACE instead
6. **ROW_FORMAT=COMPRESSED**: Cannot drop columns from compressed tables via INSTANT

### When to Use External Tools vs Native DDL

| Operation | Table Size | Recommendation |
|-----------|-----------|----------------|
| Add column | Any | Native INSTANT DDL |
| Drop column | Any | Native INSTANT DDL (8.0.29+) |
| Add index | < 10GB | Native INPLACE DDL |
| Add index | > 10GB | Spirit or gh-ost (throttling) |
| Change column type | < 1GB | Native INPLACE |
| Change column type | > 1GB | Spirit or gh-ost |
| Any complex ALTER | > 50GB | Spirit or gh-ost |
| Any ALTER with FKs | Any | pt-online-schema-change |

### MySQL Safe Migration Patterns

#### Adding a column
```sql
-- MySQL 8.0.29+: INSTANT, any position
ALTER TABLE users ADD COLUMN phone VARCHAR(20) AFTER email, ALGORITHM=INSTANT;
-- If INSTANT fails, MySQL falls back to INPLACE
```

#### Adding an index (large table)
```sql
-- For small tables: native
ALTER TABLE users ADD INDEX idx_email (email), ALGORITHM=INPLACE, LOCK=NONE;

-- For large tables: use Spirit
spirit --alter "ADD INDEX idx_email (email)" --table users --host db-primary
```

#### Changing column type
```sql
-- WARNING: Most type changes require COPY algorithm, locking the table
-- For large tables, use Spirit or gh-ost instead
ALTER TABLE users MODIFY COLUMN name VARCHAR(500), ALGORITHM=INPLACE, LOCK=NONE;
-- This will error if INPLACE isn't possible — then use external tool
```

### MySQL Does NOT Have Transactional DDL

Unlike PostgreSQL, MySQL DDL is **not transactional**. If a migration with multiple ALTER TABLE statements fails halfway, the completed statements are NOT rolled back.

**Implication**: Each DDL statement should be its own migration. Never combine multiple ALTER TABLE operations expecting atomic behavior.

```sql
-- BAD: If second statement fails, first is NOT rolled back
ALTER TABLE users ADD COLUMN a INT;
ALTER TABLE users ADD COLUMN b INT;  -- Fails
-- users now has column 'a' but not 'b'

-- GOOD: Separate migrations
-- Migration 001: ALTER TABLE users ADD COLUMN a INT;
-- Migration 002: ALTER TABLE users ADD COLUMN b INT;
```

---

## 15. Migration Decision Framework

### Pre-Migration Checklist

Before any production migration:

- [ ] Migration tested against production-sized data in staging
- [ ] Execution time measured and within maintenance window (if applicable)
- [ ] Lock impact analyzed (what locks, for how long)
- [ ] Rollback plan documented and tested
- [ ] Pre-migration backup/snapshot taken
- [ ] Monitoring dashboards ready (latency, errors, replication lag)
- [ ] Team notified and on-call engineer aware
- [ ] Feature flags ready for read/write path changes
- [ ] `lock_timeout` set appropriately in migration

### Decision Tree: How to Migrate

```
Is it a schema-only change (no data transformation)?
├── YES: Is it a simple additive change (add column, add index)?
│   ├── YES: Is the table < 1M rows?
│   │   ├── YES → Direct DDL (with lock_timeout)
│   │   └── NO → Use CONCURRENTLY (PG) or INSTANT/INPLACE (MySQL)
│   └── NO: Is it destructive (drop, rename, type change)?
│       ├── YES → Expand/Contract pattern (multi-step)
│       └── NO → Direct DDL with caution
└── NO: Does it require data backfill?
    ├── YES: How many rows?
    │   ├── < 1M → Batched UPDATE in migration
    │   ├── 1M-100M → Background job with batching
    │   └── > 100M → CDC + shadow table or dedicated backfill pipeline
    └── NO → Evaluate case by case
```

### Migration Timing

| Change Type | Safe During Traffic | Requires Low-Traffic Window | Requires Maintenance Window |
|-------------|--------------------|-----------------------------|----------------------------|
| ADD COLUMN (nullable) | Yes | No | No |
| CREATE INDEX CONCURRENTLY | Yes | Preferred | No |
| ADD FK (NOT VALID + VALIDATE) | Yes | No | No |
| DROP COLUMN | Yes (instant in PG/MySQL 8.0.29+) | No | No |
| Large backfill (>10M rows) | Possible with throttling | Preferred | No |
| Table restructuring | No | No | Yes |
| Column type change (large table) | No | Yes | Preferred |
| Enum type recreation | No | Yes | Preferred |

### Cross-References

- For data modeling decisions, see: `data-architect.md`
- For system architecture decisions that affect migration strategy, see: `solution-architect.md`
- For API changes that may drive schema changes, see: `api-designer.md`
