# Multi-Tenancy Architecture — Deep Reference

**Always use `WebSearch` to verify multi-tenancy platform features, database capabilities, and cloud provider SaaS patterns before giving advice. The multi-tenant database space is evolving rapidly with new entrants like Nile, Turso, and Tursodb. Last verified: April 2026.**

## Table of Contents
1. [Multi-Tenancy Models Deep Dive](#1-multi-tenancy-models-deep-dive)
2. [Database Multi-Tenancy Strategies](#2-database-multi-tenancy-strategies)
3. [PostgreSQL Row-Level Security (RLS)](#3-postgresql-row-level-security-rls)
4. [Schema-Per-Tenant Pattern](#4-schema-per-tenant-pattern)
5. [Multi-Tenant Data Modeling](#5-multi-tenant-data-modeling)
6. [Tenant Routing](#6-tenant-routing)
7. [Tenant Context Propagation](#7-tenant-context-propagation)
8. [Multi-Tenant Database Platforms](#8-multi-tenant-database-platforms)
9. [Tenant Lifecycle Management](#9-tenant-lifecycle-management)
10. [Cloud Provider SaaS Patterns](#10-cloud-provider-saas-patterns)
11. [Migration: Single-Tenant to Multi-Tenant](#11-migration-single-tenant-to-multi-tenant)
12. [Multi-Tenancy Anti-Patterns](#12-multi-tenancy-anti-patterns)

---

## 1. Multi-Tenancy Models Deep Dive

### Pool Model (Shared Everything)

All tenants share the same database, tables, compute, and storage. Isolation is enforced at the application layer and optionally at the database layer (RLS).

**Architecture:**
```
┌─────────────────────────────┐
│        Application          │
│   (tenant_id in context)    │
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│      Shared Database        │
│  ┌────────────────────────┐ │
│  │  users (tenant_id FK)  │ │
│  │  projects (tenant_id)  │ │
│  │  documents (tenant_id) │ │
│  └────────────────────────┘ │
│        + RLS policies       │
└─────────────────────────────┘
```

**When to use:**
- High tenant count (1,000+), small-to-medium data per tenant
- PLG products with self-serve signup (most signups are free/small)
- Cost-sensitive startups that need to move fast
- Tenants are homogeneous (similar data patterns, similar usage)

**When to avoid:**
- Tenants require dedicated infrastructure (contractual or regulatory)
- One tenant could have 100x the data of others (data skew)
- Regulatory requirements demand physical data separation (some HIPAA, FedRAMP)
- Tenants need independent scaling or maintenance windows

**Production examples:** Linear, Notion, most early-stage B2B SaaS

### Bridge Model (Logical Isolation)

Tenants share the database server but have separate schemas or logical databases. Provides stronger isolation than pool without full silo cost.

**Architecture:**
```
┌─────────────────────────────┐
│        Application          │
│  (tenant → schema mapping)  │
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│    Shared Database Server   │
│  ┌──────┐ ┌──────┐ ┌─────┐ │
│  │Schema│ │Schema│ │Sche.│ │
│  │Acme  │ │Beta  │ │Gam. │ │
│  │      │ │      │ │     │ │
│  │users │ │users │ │users│ │
│  │docs  │ │docs  │ │docs │ │
│  └──────┘ └──────┘ └─────┘ │
└─────────────────────────────┘
```

**When to use:**
- 100-10,000 tenants with moderate data per tenant
- Need stronger isolation than pool but not full silo cost
- Enterprise customers asking for "dedicated database" but budget doesn't justify it
- Per-tenant schema migrations are acceptable

**When to avoid:**
- Very high tenant count (schema creation overhead)
- Need infrastructure-level isolation for compliance
- Schema management across thousands of tenants is a maintenance nightmare

### Silo Model (Dedicated Everything)

Each tenant gets their own database, compute, and potentially their own VPC/network. Maximum isolation.

**Architecture:**
```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Tenant: Acme│  │  Tenant: Beta│  │ Tenant: Gamma│
│  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │
│  │  App   │  │  │  │  App   │  │  │  │  App   │  │
│  └───┬────┘  │  │  └───┬────┘  │  │  └───┬────┘  │
│  ┌───▼────┐  │  │  ┌───▼────┐  │  │  ┌───▼────┐  │
│  │   DB   │  │  │  │   DB   │  │  │  │   DB   │  │
│  └────────┘  │  │  └────────┘  │  │  └────────┘  │
└──────────────┘  └──────────────┘  └──────────────┘
```

**When to use:**
- Regulatory mandate (HIPAA with BAA, FedRAMP, some government contracts)
- Contractual single-tenancy requirements (enterprise deals)
- Tenants with wildly different data volumes or workloads
- Maximum blast-radius containment required
- < 100 tenants (operational cost scales linearly)

**When to avoid:**
- More than a few hundred tenants (operational overhead)
- Cost-sensitive environments (duplicated infrastructure)
- Rapid tenant provisioning needed (infrastructure spinup takes minutes-hours)

**Production examples:** Salesforce Government Cloud, some healthcare SaaS

### Hybrid Model (Tiered Isolation)

Different tenants get different isolation levels based on their plan, regulatory needs, or size.

**Architecture:**
```
┌─────────────────────────────────────────────┐
│              Control Plane                   │
│  (tenant registry, routing, provisioning)    │
└──────┬───────────────┬──────────────┬───────┘
       │               │              │
┌──────▼──────┐ ┌──────▼──────┐ ┌────▼────────┐
│  Pool Tier  │ │ Bridge Tier │ │  Silo Tier  │
│  (Free/Pro) │ │ (Business)  │ │(Enterprise) │
│             │ │             │ │             │
│ Shared DB   │ │ Schema/DB   │ │ Dedicated   │
│ Shared K8s  │ │ Namespace   │ │ VPC + DB    │
│ RLS         │ │ K8s ns      │ │ Full infra  │
└─────────────┘ └─────────────┘ └─────────────┘
```

**When to use:**
- Serving both SMB and enterprise on the same platform
- Want to offer isolation as an upsell (premium feature)
- Gradually growing into enterprise without rebuilding from scratch
- Different regulatory requirements for different customer segments

**Production examples:** Slack (free = pool, Enterprise Grid = enhanced isolation), Salesforce (standard multi-tenant, Shield for enhanced security)

---

## 2. Database Multi-Tenancy Strategies

### Strategy Comparison

| Strategy | Isolation | Query Safety | Schema Flexibility | Ops Complexity | Cost | Max Tenants |
|----------|-----------|-------------|-------------------|----------------|------|-------------|
| `tenant_id` column (pool) | Application + RLS | Needs enforcement | Shared schema | Lowest | Lowest | 100,000+ |
| Schema per tenant (bridge) | Schema-level | Natural by schema | Independent per tenant | Medium | Medium | ~10,000 |
| Database per tenant (silo) | Database-level | Natural by DB | Fully independent | High | High | ~1,000 |
| Citus distributed tables | Shard-level | Automatic by shard key | Shared schema | Medium | Medium-High | 100,000+ |
| Nile virtual tenant DBs | Virtual DB per tenant | Automatic | Shared underlying | Low-Medium | Medium | 100,000+ |

### PostgreSQL: The SaaS Default Database

PostgreSQL is the most common database for multi-tenant SaaS because of:
- Row-Level Security (RLS) — native tenant isolation at the DB level
- Schema support — schema-per-tenant isolation without separate DB instances
- Mature connection pooling (PgBouncer, Supavisor) — essential for high tenant counts
- Rich extension ecosystem (Citus for sharding, pgvector for AI, PostGIS for geo)
- Managed options everywhere (RDS, Cloud SQL, Neon, Supabase, Crunchy Bridge)

---

## 3. PostgreSQL Row-Level Security (RLS)

RLS is the single most important database feature for multi-tenant SaaS. It enforces tenant isolation at the database level, providing defense-in-depth even if the application layer has bugs.

### Basic RLS Setup

```sql
-- 1. Add tenant_id to every table
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create index on tenant_id (critical for performance)
CREATE INDEX idx_projects_tenant_id ON projects(tenant_id);

-- 3. Enable RLS
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- 4. Create policy — rows visible only to the current tenant
CREATE POLICY tenant_isolation ON projects
    USING (tenant_id = current_setting('app.current_tenant_id')::UUID);

-- 5. Force RLS even for table owner (important!)
ALTER TABLE projects FORCE ROW LEVEL SECURITY;
```

### Setting Tenant Context Per Request

```sql
-- Option A: Session variable (set at connection/transaction start)
SET app.current_tenant_id = 'tenant-uuid-here';

-- Option B: Transaction-scoped (resets after transaction)
SET LOCAL app.current_tenant_id = 'tenant-uuid-here';

-- Option C: Using a function for cleaner API
CREATE OR REPLACE FUNCTION set_tenant(tenant_uuid UUID)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant_id', tenant_uuid::TEXT, true);
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT set_tenant('550e8400-e29b-41d4-a716-446655440000');
```

### RLS with Connection Pooling (Critical for Production)

Connection poolers (PgBouncer, Supavisor) share connections across tenants. You MUST set tenant context per transaction, not per connection:

```sql
-- WRONG: Set per connection (will leak between tenants with pooling)
SET app.current_tenant_id = 'tenant-a';

-- CORRECT: Set per transaction with SET LOCAL
BEGIN;
SET LOCAL app.current_tenant_id = 'tenant-a';
-- ... all queries in this transaction are scoped to tenant-a ...
COMMIT;  -- tenant context is cleared
```

**PgBouncer configuration for RLS:**
```ini
; pgbouncer.ini
[pgbouncer]
pool_mode = transaction    ; MUST be transaction mode, not session mode
server_reset_query = DISCARD ALL   ; Clear any leftover session state
```

### Advanced RLS Patterns

**Multi-column policies (tenant + role):**
```sql
-- Only tenant admins can see deleted items
CREATE POLICY admin_sees_deleted ON items
    USING (
        tenant_id = current_setting('app.current_tenant_id')::UUID
        AND (
            NOT is_deleted
            OR current_setting('app.current_user_role') = 'admin'
        )
    );
```

**RLS for INSERT (prevent inserting into wrong tenant):**
```sql
CREATE POLICY tenant_insert ON projects
    FOR INSERT
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id')::UUID);
```

**RLS for cross-tenant admin access (support/super-admin):**
```sql
CREATE POLICY admin_bypass ON projects
    USING (
        tenant_id = current_setting('app.current_tenant_id')::UUID
        OR current_setting('app.is_super_admin', true)::BOOLEAN = true
    );
```

### RLS Performance Considerations

1. **Always index `tenant_id`** — without an index, every query does a full table scan filtered by RLS
2. **Composite indexes** — for frequent queries, create `(tenant_id, other_column)` indexes
3. **Partition by tenant_id** — for very large tables, range or hash partitioning on tenant_id improves query planning
4. **Monitor query plans** — use `EXPLAIN (ANALYZE, BUFFERS)` to verify RLS isn't causing sequential scans
5. **RLS overhead is minimal** — typically < 5% query overhead with proper indexing

```sql
-- Composite index for common queries
CREATE INDEX idx_projects_tenant_status ON projects(tenant_id, status);

-- Partitioned table for large datasets
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
) PARTITION BY HASH (tenant_id);

-- Create partitions
CREATE TABLE events_p0 PARTITION OF events FOR VALUES WITH (MODULUS 16, REMAINDER 0);
CREATE TABLE events_p1 PARTITION OF events FOR VALUES WITH (MODULUS 16, REMAINDER 1);
-- ... up to p15
```

---

## 4. Schema-Per-Tenant Pattern

### When to Use Schema-Per-Tenant

Schema-per-tenant is a strong choice when:
- You need stronger isolation than RLS but don't want separate databases
- Tenants need somewhat different configurations (custom fields, extensions)
- You have 100-5,000 tenants
- Some tenants need independent backup/restore

### Implementation

```sql
-- Create tenant schema
CREATE SCHEMA tenant_acme;

-- Create tables in tenant schema
CREATE TABLE tenant_acme.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Set search_path per connection/transaction
SET search_path TO tenant_acme, public;
-- Now all queries hit tenant_acme tables by default
```

### Schema Management at Scale

```python
# Python example: Tenant schema provisioning
import psycopg2

def provision_tenant_schema(conn, tenant_slug: str):
    """Create a new schema for a tenant from template."""
    with conn.cursor() as cur:
        # Create schema
        cur.execute(f"CREATE SCHEMA IF NOT EXISTS tenant_{tenant_slug}")

        # Apply migrations (from a template schema or migration files)
        cur.execute(f"""
            CREATE TABLE tenant_{tenant_slug}.projects (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                name TEXT NOT NULL,
                description TEXT,
                created_at TIMESTAMPTZ DEFAULT now(),
                updated_at TIMESTAMPTZ DEFAULT now()
            )
        """)

        # Create indexes
        cur.execute(f"""
            CREATE INDEX idx_projects_created
            ON tenant_{tenant_slug}.projects(created_at DESC)
        """)

    conn.commit()

def route_to_tenant(conn, tenant_slug: str):
    """Set search_path for the current transaction."""
    with conn.cursor() as cur:
        cur.execute(
            "SET LOCAL search_path TO %s, public",
            (f"tenant_{tenant_slug}",)
        )
```

### Schema Migration Challenges

The biggest downside of schema-per-tenant is migration complexity. With 1,000 tenants, you need to run every migration 1,000 times:

```python
# Migration runner for schema-per-tenant
async def run_migration_across_tenants(migration_sql: str, batch_size: int = 50):
    """Run a migration across all tenant schemas in batches."""
    tenants = await get_all_tenant_slugs()

    for batch in chunk(tenants, batch_size):
        tasks = [
            apply_migration(tenant_slug, migration_sql)
            for tenant_slug in batch
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Handle failures — some tenants may fail while others succeed
        for tenant_slug, result in zip(batch, results):
            if isinstance(result, Exception):
                log.error(f"Migration failed for {tenant_slug}: {result}")
                await mark_tenant_migration_failed(tenant_slug, str(result))
```

**Best practices for schema migrations:**
- Run migrations in batches (50-100 at a time) to avoid overwhelming the database
- Track migration state per tenant (which tenants have which migration version)
- Support partial rollback (some tenants migrated, some not)
- Use online DDL (`CREATE INDEX CONCURRENTLY`) to avoid locking
- Test migrations against your largest tenant's data volume

---

## 5. Multi-Tenant Data Modeling

### The `tenant_id` Column Pattern

Every table that stores tenant data must have a `tenant_id` column. No exceptions.

```sql
-- Base pattern: tenant_id on every table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    title TEXT NOT NULL,
    content TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- CRITICAL: Index on tenant_id for every table
CREATE INDEX idx_documents_tenant ON documents(tenant_id);

-- Composite unique constraint (name unique per tenant, not globally)
ALTER TABLE documents ADD CONSTRAINT uq_documents_tenant_title
    UNIQUE (tenant_id, title);
```

### Composite Primary Keys vs UUID Primary Keys

**UUID primary keys (recommended for most SaaS):**
```sql
-- Globally unique IDs — simpler, works with pool model
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    title TEXT NOT NULL
);
```

**Composite primary keys (useful for bridge/silo with Citus):**
```sql
-- Tenant-scoped IDs — required for Citus distributed tables
CREATE TABLE tasks (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    title TEXT NOT NULL,
    PRIMARY KEY (tenant_id, id)  -- tenant_id first for co-location
);
```

### Cross-Tenant Query Prevention

**Application-level enforcement (middleware):**
```typescript
// Express middleware: inject tenant_id into every DB query
export function tenantMiddleware(req: Request, res: Response, next: NextFunction) {
    const tenantId = extractTenantId(req);  // from subdomain, JWT, or header
    if (!tenantId) {
        return res.status(401).json({ error: 'Tenant not identified' });
    }

    // Attach to request context — all downstream queries MUST use this
    req.tenantId = tenantId;

    // Set RLS context in database
    req.db.query('SET LOCAL app.current_tenant_id = $1', [tenantId]);

    next();
}
```

**ORM-level enforcement (Prisma example):**
```typescript
// Prisma middleware: automatically filter by tenant_id
import { PrismaClient } from '@prisma/client';

function createTenantPrisma(tenantId: string): PrismaClient {
    const prisma = new PrismaClient();

    prisma.$use(async (params, next) => {
        // Automatically add tenant_id to WHERE clauses
        if (params.action === 'findMany' || params.action === 'findFirst') {
            params.args.where = {
                ...params.args.where,
                tenant_id: tenantId,
            };
        }

        // Automatically set tenant_id on CREATE
        if (params.action === 'create') {
            params.args.data.tenant_id = tenantId;
        }

        // Prevent update/delete without tenant_id filter
        if (params.action === 'update' || params.action === 'delete') {
            params.args.where = {
                ...params.args.where,
                tenant_id: tenantId,
            };
        }

        return next(params);
    });

    return prisma;
}
```

**Drizzle ORM example:**
```typescript
// Drizzle: tenant-scoped query builder
import { eq, and } from 'drizzle-orm';

function tenantQuery<T>(table: T, tenantId: string) {
    return {
        where: (conditions: any) => and(
            eq(table.tenantId, tenantId),
            conditions
        ),
        findMany: () => db.select().from(table).where(eq(table.tenantId, tenantId)),
    };
}

// Usage
const projects = await tenantQuery(projectsTable, req.tenantId).findMany();
```

### Partitioning Strategies for Large Multi-Tenant Tables

```sql
-- Hash partitioning by tenant_id (good for even distribution)
CREATE TABLE events (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
) PARTITION BY HASH (tenant_id);

-- Range partitioning by time + tenant (for time-series data)
CREATE TABLE usage_events (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    meter_name TEXT NOT NULL,
    quantity BIGINT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (recorded_at);

CREATE TABLE usage_events_2026_q1 PARTITION OF usage_events
    FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');
CREATE TABLE usage_events_2026_q2 PARTITION OF usage_events
    FOR VALUES FROM ('2026-04-01') TO ('2026-07-01');
```

---

## 6. Tenant Routing

### Subdomain-Based Routing

The most common pattern for multi-tenant SaaS. Each tenant gets `{tenant}.app.com`.

```typescript
// Next.js middleware: extract tenant from subdomain
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
    const hostname = request.headers.get('host') || '';
    const subdomain = hostname.split('.')[0];

    // Skip for main domain, API, and static assets
    if (['www', 'api', 'app'].includes(subdomain)) {
        return NextResponse.next();
    }

    // Look up tenant by subdomain
    const response = NextResponse.next();
    response.headers.set('x-tenant-slug', subdomain);
    return response;
}
```

**DNS setup:**
```
*.app.com.    A     <load-balancer-ip>
*.app.com.    AAAA  <load-balancer-ipv6>
```

**Custom domains (white-label):**
```typescript
// Tenant custom domain mapping
// Store in DB: { tenant_id: 'acme', custom_domain: 'projects.acme.com' }

// Vercel: Add custom domain via API
const response = await fetch('https://api.vercel.com/v10/projects/{projectId}/domains', {
    method: 'POST',
    headers: { Authorization: `Bearer ${VERCEL_TOKEN}` },
    body: JSON.stringify({ name: 'projects.acme.com' }),
});

// Cloudflare: Add custom hostname via API
const response = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/custom_hostnames`,
    {
        method: 'POST',
        headers: { Authorization: `Bearer ${CF_TOKEN}` },
        body: JSON.stringify({
            hostname: 'projects.acme.com',
            ssl: { method: 'http', type: 'dv' },
        }),
    }
);
```

### Path-Based Routing

Simpler to set up, doesn't require wildcard DNS. Each tenant accessible at `app.com/{tenant}/`.

```typescript
// Path-based tenant extraction
function extractTenantFromPath(url: string): string | null {
    const match = url.match(/^\/t\/([a-z0-9-]+)\//);
    return match ? match[1] : null;
}

// Route pattern: /t/{tenant-slug}/projects, /t/{tenant-slug}/settings
```

**When to use path-based routing:**
- Simpler setup (no wildcard DNS or custom domains)
- Internal tools where branding doesn't matter
- Development and staging environments
- API-first products where the tenant is in the URL

### Header-Based Routing

Tenant identified via HTTP header or JWT claim. Common for API-first products.

```typescript
// API gateway: extract tenant from header or JWT
function extractTenantFromRequest(req: Request): string {
    // Option 1: Custom header (set by API gateway)
    const headerTenant = req.headers.get('x-tenant-id');
    if (headerTenant) return headerTenant;

    // Option 2: JWT claim
    const token = req.headers.get('authorization')?.replace('Bearer ', '');
    if (token) {
        const decoded = verifyJWT(token);
        return decoded.org_id;  // tenant ID in JWT claims
    }

    throw new Error('Tenant not identified');
}
```

### Routing Decision Matrix

| Pattern | Setup Complexity | White-label Support | API-friendly | SEO Impact |
|---------|-----------------|--------------------|--------------|-----------| 
| Subdomain | Medium (wildcard DNS) | Excellent with CNAME | Good | Neutral |
| Path-based | Low | Poor | Excellent | Positive (shared domain authority) |
| Header-based | Low | N/A | Excellent | N/A (API only) |
| Custom domain | High (cert management) | Best | Good | Positive (own domain) |

---

## 7. Tenant Context Propagation

### The Tenant Context Problem

Every layer of your application must know which tenant the current request belongs to — from HTTP middleware to database queries to background jobs to logging. Missing tenant context is the #1 cause of cross-tenant data leaks.

### Request-Scoped Context (Node.js/AsyncLocalStorage)

```typescript
import { AsyncLocalStorage } from 'node:async_hooks';

interface TenantContext {
    tenantId: string;
    tenantSlug: string;
    plan: string;
}

const tenantStore = new AsyncLocalStorage<TenantContext>();

// Middleware: set tenant context for the entire request lifecycle
export function tenantMiddleware(req: Request, res: Response, next: NextFunction) {
    const tenant = resolveTenant(req);
    tenantStore.run(tenant, () => next());
}

// Anywhere in request handling: get current tenant
export function getCurrentTenant(): TenantContext {
    const tenant = tenantStore.getStore();
    if (!tenant) {
        throw new Error('No tenant context — this is a bug');
    }
    return tenant;
}

// Database layer: automatically uses tenant context
export async function findProjects() {
    const { tenantId } = getCurrentTenant();
    return db.query('SELECT * FROM projects WHERE tenant_id = $1', [tenantId]);
}
```

### Background Jobs and Tenant Context

Background jobs (queues, cron, event handlers) don't have HTTP request context. You must explicitly pass and restore tenant context:

```typescript
// Enqueuing: serialize tenant context into the job payload
async function enqueueJob(jobType: string, data: any) {
    const tenant = getCurrentTenant();
    await queue.add(jobType, {
        tenantId: tenant.tenantId,
        tenantSlug: tenant.tenantSlug,
        ...data,
    });
}

// Processing: restore tenant context before executing
async function processJob(job: Job) {
    const tenant = await lookupTenant(job.data.tenantId);

    // Run job within tenant context
    tenantStore.run(tenant, async () => {
        // Set database tenant context
        await db.query('SET LOCAL app.current_tenant_id = $1', [tenant.tenantId]);

        // Execute job logic — all queries are now tenant-scoped
        await executeJobLogic(job);
    });
}
```

### Logging with Tenant Context

Every log entry should include tenant information for debugging and audit:

```typescript
import pino from 'pino';

const logger = pino({
    mixin() {
        const tenant = tenantStore.getStore();
        return tenant ? { tenantId: tenant.tenantId, tenantSlug: tenant.tenantSlug } : {};
    },
});

// All log entries automatically include tenant context
logger.info('Project created');
// Output: {"level":30,"tenantId":"uuid","tenantSlug":"acme","msg":"Project created"}
```

---

## 8. Multi-Tenant Database Platforms

### Nile (Multi-Tenant PostgreSQL)

Nile is purpose-built for multi-tenant SaaS on PostgreSQL. It provides virtual tenant databases on top of shared PostgreSQL infrastructure.

**Key features:**
- Virtual tenant databases — each tenant appears to have its own database
- Automatic tenant isolation at the query level
- Tenant-aware connection pooling
- Built-in tenant management APIs
- PostgreSQL compatible — works with existing ORMs and tools

**When to use:** Starting a new multi-tenant SaaS and want built-in tenancy without manual RLS setup

### Citus (Distributed Multi-Tenant PostgreSQL)

Citus (now part of Azure Cosmos DB for PostgreSQL) distributes tables across multiple nodes using a distribution column (typically `tenant_id`).

**Key features:**
- Distribute tables by `tenant_id` — queries for one tenant hit one shard
- Co-location: related tables distributed by the same key are on the same shard
- Reference tables: small shared tables replicated to all nodes
- Scale out by adding nodes — transparent to the application
- Works with standard PostgreSQL queries

```sql
-- Distribute tables by tenant_id
SELECT create_distributed_table('projects', 'tenant_id');
SELECT create_distributed_table('tasks', 'tenant_id');

-- Co-locate tasks with projects (both on same shard)
SELECT create_distributed_table('tasks', 'tenant_id',
    colocate_with := 'projects');

-- Reference table (shared data, replicated everywhere)
SELECT create_reference_table('plans');

-- Queries automatically routed to correct shard
SELECT * FROM projects WHERE tenant_id = 'acme-uuid';
-- This hits only the shard containing acme's data
```

**When to use:** 1,000+ tenants, large data volume, need horizontal scaling while keeping PostgreSQL compatibility

### Neon (Serverless PostgreSQL)

Neon offers database branching and per-tenant database instances with serverless scaling.

**Key features:**
- Instant database branching (useful for per-tenant databases)
- Scale-to-zero (cost savings for inactive tenants)
- Autoscaling compute
- Connection pooling built-in

**When to use:** Database-per-tenant model where many tenants are inactive (scale-to-zero saves cost)

### Turso (Edge Multi-Tenancy)

Turso uses libSQL (SQLite fork) to provide per-tenant databases at the edge.

**Key features:**
- Per-tenant SQLite database (strong isolation by default)
- Edge replication — databases close to users globally
- Embedded replicas — read replicas in your application process
- Schema management across tenant databases

**When to use:** Per-tenant database model, globally distributed tenants, read-heavy workloads, edge computing

**Comparison table:**

| Feature | Nile | Citus | Neon | Turso |
|---------|------|-------|------|-------|
| Model | Virtual tenant DBs | Distributed sharding | Serverless PostgreSQL | Per-tenant SQLite |
| Isolation | Virtual DB per tenant | Shard-level | Database-level | Database-level |
| PostgreSQL compat | Full | Full | Full | libSQL (partial) |
| Scaling | Managed | Add shards | Autoscale | Edge replication |
| Scale-to-zero | Yes | No | Yes | Yes |
| Best for | New SaaS products | High-scale PostgreSQL | Variable-load tenants | Edge-first, per-tenant DB |

---

## 9. Tenant Lifecycle Management

### Tenant Provisioning

```typescript
interface TenantProvisioningPipeline {
    steps: [
        'create_tenant_record',      // Insert into tenants table
        'setup_database',            // Create schema/DB or initialize RLS
        'create_admin_user',         // First user for the tenant
        'configure_billing',         // Create Stripe customer + subscription
        'setup_defaults',            // Default settings, sample data, templates
        'configure_integrations',    // SSO, webhooks, API keys
        'send_welcome',              // Welcome email, onboarding trigger
    ];
}

// Idempotent provisioning (critical for retries)
async function provisionTenant(input: TenantInput): Promise<Tenant> {
    const idempotencyKey = `provision:${input.email}:${input.slug}`;

    return withIdempotency(idempotencyKey, async () => {
        const tenant = await db.transaction(async (tx) => {
            // 1. Create tenant record
            const tenant = await tx.tenants.create({
                slug: input.slug,
                name: input.name,
                plan: 'free',
                status: 'provisioning',
            });

            // 2. Setup database isolation
            if (TENANCY_MODEL === 'bridge') {
                await tx.raw(`CREATE SCHEMA tenant_${tenant.slug}`);
                await runMigrations(`tenant_${tenant.slug}`);
            }

            // 3. Create admin user
            await tx.users.create({
                tenant_id: tenant.id,
                email: input.email,
                role: 'admin',
            });

            return tenant;
        });

        // 4. External integrations (outside DB transaction)
        await stripe.customers.create({
            email: input.email,
            metadata: { tenant_id: tenant.id },
        });

        // 5. Mark as active
        await db.tenants.update(tenant.id, { status: 'active' });

        // 6. Emit event
        await events.emit('tenant.provisioned', { tenantId: tenant.id });

        return tenant;
    });
}
```

### Tenant Offboarding and Data Deletion

```typescript
async function offboardTenant(tenantId: string): Promise<void> {
    // 1. Soft-delete: mark as inactive, stop billing
    await db.tenants.update(tenantId, {
        status: 'deactivating',
        deactivated_at: new Date(),
    });

    // 2. Cancel subscription
    await stripe.subscriptions.cancel(tenant.stripeSubscriptionId);

    // 3. Export data for tenant (GDPR compliance)
    const exportUrl = await exportTenantData(tenantId);
    await sendEmail(tenant.adminEmail, 'data-export', { url: exportUrl });

    // 4. Grace period (30 days) before permanent deletion
    await queue.add('permanent-tenant-deletion', { tenantId }, {
        delay: 30 * 24 * 60 * 60 * 1000,  // 30 days
    });
}

async function permanentlyDeleteTenant(tenantId: string): Promise<void> {
    // Delete all tenant data
    if (TENANCY_MODEL === 'bridge') {
        await db.raw(`DROP SCHEMA tenant_${tenant.slug} CASCADE`);
    } else {
        // Pool model: delete rows from all tables
        const tables = await getTenantTables();
        for (const table of tables) {
            await db.raw(`DELETE FROM ${table} WHERE tenant_id = $1`, [tenantId]);
        }
    }

    // Delete external resources
    await stripe.customers.del(tenant.stripeCustomerId);
    await s3.deletePrefix(`tenants/${tenantId}/`);

    // Delete tenant record
    await db.tenants.delete(tenantId);

    await events.emit('tenant.deleted', { tenantId });
}
```

### Tenant Migration Between Tiers

When a tenant upgrades from pool to bridge or silo:

```typescript
async function migrateTenantToSilo(tenantId: string): Promise<void> {
    // 1. Create dedicated infrastructure
    const siloDb = await createDedicatedDatabase(tenantId);

    // 2. Export tenant data from shared pool
    const data = await exportTenantData(tenantId);

    // 3. Import into dedicated database
    await importTenantData(siloDb, data);

    // 4. Verify data integrity
    const verification = await verifyMigration(tenantId, siloDb);
    if (!verification.success) {
        throw new Error(`Migration verification failed: ${verification.errors}`);
    }

    // 5. Update routing (atomically switch traffic)
    await updateTenantRouting(tenantId, {
        model: 'silo',
        connectionString: siloDb.connectionString,
    });

    // 6. Clean up old data from pool (after verification period)
    await queue.add('cleanup-pool-data', { tenantId }, {
        delay: 7 * 24 * 60 * 60 * 1000,  // 7 days
    });
}
```

---

## 10. Cloud Provider SaaS Patterns

### AWS SaaS Factory & SaaS Lens

AWS provides the SaaS Lens for Well-Architected reviews and SaaS Factory for reference architectures.

**Key AWS SaaS patterns:**
- **Tenant isolation with IAM**: Dynamic IAM policies scoped to tenant resources
- **Silo with dedicated accounts**: AWS Organizations + dedicated accounts per tenant
- **Pool with Lambda layers**: Shared Lambda functions with tenant context in JWT
- **Control plane / Application plane separation**: Control plane manages tenants, app plane runs workloads
- **Tenant-aware metrics**: CloudWatch dimensions for per-tenant monitoring

**AWS services commonly used:**
- Cognito user pools for tenant identity
- API Gateway with Lambda authorizers for tenant routing
- DynamoDB with partition key = tenant_id
- S3 with prefix-based isolation + IAM policies
- ECS/EKS with namespace per tenant tier

### Azure SaaS Dev Kit

**Key Azure SaaS patterns:**
- Azure B2C for multi-tenant identity
- Azure SQL elastic pools for shared database resources
- Azure API Management for tenant routing
- Per-tenant App Service plans or shared with deployment slots

### GCP SaaS Solutions

**Key GCP patterns:**
- Identity Platform for multi-tenant auth
- Cloud Spanner with interleaved tables (natural co-location)
- Cloud Run services with tenant context headers
- BigQuery with row-level access controls for analytics

---

## 11. Migration: Single-Tenant to Multi-Tenant

### Migration Strategy

Converting a single-tenant application to multi-tenant is one of the hardest architectural migrations. Here's a phased approach:

**Phase 1: Add `tenant_id` everywhere (pool model)**
1. Add `tenant_id` column to every table (nullable initially, with a default)
2. Backfill `tenant_id` for all existing data with a "default" tenant
3. Update all queries to include `tenant_id` filter
4. Add RLS policies
5. Make `tenant_id` NOT NULL once backfill is complete

**Phase 2: Tenant routing and context**
1. Add tenant resolution middleware
2. Propagate tenant context through the entire stack
3. Update background jobs to carry tenant context
4. Add tenant-scoped logging

**Phase 3: Billing and onboarding**
1. Integrate billing platform
2. Build tenant provisioning pipeline
3. Build self-serve signup

**Phase 4: Isolation hardening**
1. Add comprehensive integration tests for cross-tenant isolation
2. Implement rate limiting per tenant
3. Add noisy neighbor protections

### The `tenant_id` Backfill Pattern

```sql
-- Step 1: Add nullable column
ALTER TABLE projects ADD COLUMN tenant_id UUID;

-- Step 2: Create default tenant for existing data
INSERT INTO tenants (id, name, slug) VALUES
    ('default-tenant-uuid', 'Default', 'default');

-- Step 3: Backfill in batches (avoid locking entire table)
UPDATE projects SET tenant_id = 'default-tenant-uuid'
WHERE tenant_id IS NULL
LIMIT 10000;  -- Repeat until all rows are updated

-- Step 4: Make NOT NULL after backfill
ALTER TABLE projects ALTER COLUMN tenant_id SET NOT NULL;

-- Step 5: Add foreign key and index
ALTER TABLE projects ADD CONSTRAINT fk_projects_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id);
CREATE INDEX idx_projects_tenant_id ON projects(tenant_id);
```

---

## 12. Multi-Tenancy Anti-Patterns

### 1. Missing `tenant_id` on Any Table

**Problem:** Any table without `tenant_id` is a potential cross-tenant data leak.
**Fix:** Every table that stores tenant data MUST have `tenant_id`. Use a linter/pre-commit hook to check new migrations.

### 2. Relying Only on Application-Layer Isolation

**Problem:** A single missed `WHERE tenant_id = ?` leaks data. Application bugs happen.
**Fix:** Use RLS as defense-in-depth. Even if the app has a bug, the database blocks cross-tenant queries.

### 3. Global Sequences/Auto-Increment for Tenant-Visible IDs

**Problem:** Sequential IDs leak information about other tenants (how many exist, growth rate).
**Fix:** Use UUIDs or tenant-scoped IDs (e.g., `ACME-001`, `ACME-002`).

### 4. Shared Caches Without Tenant Scoping

**Problem:** Redis/Memcached keys like `user:123` might return data from the wrong tenant.
**Fix:** Always prefix cache keys with tenant: `tenant:{tenant_id}:user:{user_id}`.

```typescript
// WRONG
await redis.get(`user:${userId}`);

// CORRECT
await redis.get(`tenant:${tenantId}:user:${userId}`);
```

### 5. Background Jobs Without Tenant Context

**Problem:** A background job processes data without knowing which tenant it belongs to, or processes data from the wrong tenant.
**Fix:** Always serialize tenant context into job payloads. Restore tenant context before processing.

### 6. Logs and Errors Leaking Tenant Data

**Problem:** Error messages, stack traces, or logs contain data from one tenant and are visible to support staff handling another tenant's issue.
**Fix:** Tenant-scoped error tracking. Support tools should filter by tenant.

### 7. Cross-Tenant Joins in Reporting

**Problem:** Analytics queries that aggregate across tenants without proper authorization.
**Fix:** Reporting queries should be tenant-scoped by default. Cross-tenant analytics should only be accessible to platform admins.

### 8. DNS/Subdomain Enumeration

**Problem:** Attackers can discover all tenants by brute-forcing subdomains.
**Fix:** Don't return different errors for "tenant not found" vs "invalid credentials". Use rate limiting on tenant resolution endpoints.
