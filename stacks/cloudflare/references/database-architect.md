---
role: database-architect
stack: cloudflare
last_verified_on: "2026-05-14"
---

# Cloudflare overlay for `database-architect`

You own schema design, indexes, query patterns, and data-residency on Cloudflare's data primitives:

- **D1** — distributed SQLite with global read replication and the Sessions API.
- **R2** — S3-compatible object storage, zero egress, with R2 SQL for table-like analytics.
- **KV** — eventually-consistent global key-value, read-heavy.
- **Durable Object SQLite** — per-DO SQLite, strong consistency, alarms.
- **Hyperdrive** — connection-pool + cache layer in front of Postgres/MySQL.
- **Vectorize V2** — managed vector store with metadata indexes.
- **Analytics Engine** — append-only time-series datapoints with SQL queries.
- **Pipelines** — HTTP-ingest → R2 (Parquet/JSON).

The original `database-architect` reference covers SQL/NoSQL/cache/search/data-pipeline principles generally. This overlay is the Cloudflare-specific where-data-lives picture for 2026.

## Role briefing — data on Cloudflare

Two mental shifts from a traditional cloud-DBA view:

1. **You don't pick a region for D1 the way you pick a region for RDS.** D1 has a primary region (for writes) and you opt into replicas. Workers run everywhere. Reads come from replicas; writes round-trip to primary; the Sessions API gives you read-your-writes.
2. **Object storage is the default analytics surface, not a backup target.** R2 + R2 SQL means "drop Parquet here, query it later" is a first-class workflow. You don't have to spin up Athena, BigQuery, or Snowflake to do this.

Two Cloudflare-specific limits you'll hit:

1. **Subrequest budget (50 free, 1000 paid)** caps the number of DB calls per Worker invocation. Batch and prepared-statement pipelines are not nice-to-haves; they're required.
2. **Per-database / per-DO size limits.** D1 (per database) and DO (per object) have caps that move over time; check current docs. Don't design a schema that mortgages future migration.

## Decision frameworks

### Where does this entity live?

| Entity shape | Use |
|--------------|-----|
| Relational with joins, indexes, transactions | **D1** |
| One-to-many per tenant, strict isolation, transactional | **DO SQLite per tenant** |
| Key-value, read-heavy, eventual OK | **KV** |
| Large blobs, immutable | **R2** |
| Time-series, high write rate, append-only | **Analytics Engine** + **R2 (Pipelines)** for retention |
| Vectors (embeddings) | **Vectorize V2** |
| Existing Postgres/MySQL schema | **Hyperdrive** in front of the existing DB |
| Graph (deep traversals, paths) | External (Neo4j, FalkorDB) accessed via Hyperdrive or Worker `fetch` |

### D1 vs DO SQLite

| Property | D1 | DO SQLite |
|----------|----|-----------|
| Scope | Global (single DB shared by many Workers) | Per-DO instance |
| Consistency | Read-your-writes via Sessions API; otherwise eventual on replicas | Strong (single-writer per DO instance) |
| Transactions | Single-statement and batch | Full SQLite, multi-statement |
| Migrations | Wrangler migrations command | Code-managed (run DDL in DO `constructor`) |
| Cross-row queries | Yes (full SQL) | Yes within the DO; no across DOs |
| Cross-tenant queries | Yes | No (queries scoped to one DO at a time) |
| Size | Up to plan limit per DB | Up to plan limit per DO |
| Failure mode | D1 region down → reads to replicas, writes fail | DO instance down → that one ID unavailable |
| Use when | Shared catalog, users, orders, analytics | Per-room state, per-user wallets, per-doc collab, per-tenant isolation |

D1 for the catalog. DO for per-entity strong consistency. Often both in the same app — D1 owns the cross-entity facts, DO owns the per-entity hot writes.

### D1 with Sessions API: when to use bookmarks

| Request kind | Sessions handling |
|--------------|-------------------|
| Login (just-set the session cookie) | Issue bookmark, persist in cookie |
| Read-after-write within the same user's flow | Use bookmark from cookie; advance after writes |
| Pure read for another user's public profile | No bookmark needed; replica reads are fine |
| Admin panel cross-tenant queries | Probably no bookmark; OK to read from replicas |
| Strong consistency required (banking, voting) | Use bookmark **and** verify post-write |

The bookmark is just a string; treat it as opaque. Bookmark management lives in your auth/session layer.

### Hyperdrive: yes / no / which database

| Situation | Recommend |
|-----------|-----------|
| New project, no existing DB | **D1** (Hyperdrive not needed) |
| Existing Postgres < 100GB, want to keep | **Hyperdrive** |
| Postgres requires extensions Workers can't reach | **Hyperdrive** (the DB still runs where it ran; you're proxying) |
| MySQL existing schema | **Hyperdrive** (supports MySQL) |
| Database needs to stay on a private network | **Hyperdrive + Tunnel** (private DB exposed via cloudflared) |
| Postgres with heavy write throughput on hot rows | Hyperdrive helps reads; writes still go to primary — sizing the primary matters |

### Hyperdrive cache: enable / disable per query

Hyperdrive caches reads by default. Cache hits return instantly; cache misses pool through to Postgres. **Cache-correctness is your responsibility:**

- **Cache OK:** lookups, list pages, anything you can tolerate up to TTL stale.
- **Cache wrong:** read-after-write in the same flow, transactional reads, anything where the user just changed the data.

Per-query disable via the `hyperdrive_disable` driver hint or per-query SQL comment depending on driver. Check current docs.

### KV TTL discipline

KV supports TTL on writes (`expirationTtl` option). Use TTLs for:
- Sessions (auto-expire after inactivity).
- Cached transformations (e.g., a Worker that fetches → transforms → caches).
- Rate-limit counters with a fixed window.

Don't use TTLs as your sole "delete" mechanism for sensitive data — TTL is "best effort." For hard-delete with audit, use D1 + explicit DELETE.

### R2: bucket layout for multi-tenant

```
my-bucket/
├── tenant-1/uploads/...
├── tenant-1/exports/...
├── tenant-2/uploads/...
└── public/static/...
```

Tenants prefixed in keys, IAM scoped at the bucket level. For stronger isolation: one bucket per tenant (cost: bucket count adds up at large tenant count).

Alternatively, R2 SQL queries can be tenant-scoped if your Parquet files have `tenant_id` column and you partition by it.

### Vectorize V2 index layout

| Pattern | Layout |
|---------|--------|
| Single-tenant, many topics | One index per topic; query by index |
| Multi-tenant, same schema | One index, tenant_id metadata, **metadata index on tenant_id**, filter every query |
| Multi-tenant with namespaces | One index, namespace per tenant — strict partition at index level |
| Different embedding dimensions per use case | Separate indexes (you can't mix dimensions in one) |

Set up metadata indexes at index-create time for every field you'll filter on (tenant_id, source, doc_type, language). Without metadata index, the filter scans more vectors.

### Analytics Engine vs D1 inserts vs R2 Pipelines

| Need | Use |
|------|-----|
| Online dashboards over recent metrics (last hour, last day) | Analytics Engine |
| Audit trail with cross-row queries | D1 (with reasonable insert rate) |
| Firehose of events for later analysis | Pipelines → R2 → R2 SQL |
| Trace logs from Workers | Workers Logs (queryable) + Logpush for fan-out |

Don't insert into D1 from a high-volume endpoint without thinking. D1 has rate ceilings; inserts compete with reads. Use Analytics Engine for "how many of X happened" and D1 for "what exactly did user Y do."

## Critical 2025-2026 platform reset for database-architects

### D1 GA + global replication + Sessions API

D1 went GA in 2024. Replication + Sessions API in 2025. Per-database size grew. Indexes work; foreign keys work; `EXPLAIN QUERY PLAN` works. **D1 is a real relational store now**, not a toy.

What it still isn't:
- A drop-in for very large Postgres datasets (sub-100GB sweet spot as of 2026-Q2).
- A home for arbitrary Postgres extensions (no PostGIS, pgvector, etc. — that's Hyperdrive territory).
- A queue (it's a DB, don't `SELECT WHERE processed=0 LIMIT 1 FOR UPDATE` your way to a queue).

### Hyperdrive supports MySQL + private DBs

- MySQL drivers: `mysql2`, `mysql2/promise` work via the Hyperdrive connection string.
- Private DBs: pair Hyperdrive with a Cloudflare Tunnel pointing at your private Postgres. The Worker → Hyperdrive → Tunnel → DB; the DB never sees a public IP.

### Vectorize V2

Already covered in the AI overlay. From a data-design view:
- Plan metadata fields up front; metadata indexes are set at index creation.
- Embedding dimension matters — match to your embedding model (bge-base 768, bge-large 1024, OpenAI ada-002 1536, etc.).
- Use namespaces for hard tenant partition when needed.

### Durable Object SQLite

The shift from KV-style DO storage to SQL-backed DO storage (default 2025) changes per-DO schema design:

- You can now use indexes, foreign keys, multi-statement transactions.
- Migrations are code-managed — run `CREATE TABLE IF NOT EXISTS` in the DO constructor or in a dedicated migration RPC method.
- Migration tag in `wrangler.toml`: `new_sqlite_classes` (not `new_classes`).
- Each DO has its own SQLite DB; ~10GB ceiling (varies by plan).

### R2 SQL

Query Parquet/CSV in R2 with SQL (no need for Athena/Snowflake for one-off analytics).

```sql
SELECT user_id, COUNT(*) AS events
FROM 'r2://my-bucket/events/year=2026/month=05/'
WHERE event_type = 'click'
GROUP BY user_id
ORDER BY events DESC
LIMIT 100;
```

Cost is per-query (data scanned + compute). Suitable for ad-hoc analytics; not for high-QPS workloads.

### Workers Logs as a queryable store

Workers Logs is structured-log-storage with SQL-like queries in the dashboard. Plays nicely with Analytics Engine for custom metrics. **For "what happened on this Worker yesterday" you want Workers Logs**, not Logpush + external SIEM.

## Patterns and anti-patterns

### Pattern: D1 schema with explicit migrations

```bash
wrangler d1 migrations create my-db init
# creates migrations/0001_init.sql
```

```sql
-- migrations/0001_init.sql
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_cents INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled')),
  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_created ON orders(status, created_at);
```

```bash
wrangler d1 migrations apply my-db                  # local
wrangler d1 migrations apply my-db --remote          # production
```

D1 migrations are forward-only by default. **Make them idempotent** (`CREATE TABLE IF NOT EXISTS`, `ALTER TABLE` guarded by checks). Test migrations against a copy of prod data before applying to prod.

### Pattern: prepared statements + batch

```ts
// Bad: per-iteration queries (counts against subrequests)
for (const item of items) {
  await env.DB.prepare("INSERT INTO orders (id, total) VALUES (?, ?)").bind(item.id, item.total).run();
}

// Good: batch
await env.DB.batch(items.map(item =>
  env.DB.prepare("INSERT INTO orders (id, total) VALUES (?, ?)").bind(item.id, item.total)
));
```

D1 batch is a single subrequest. Use it for any multi-statement work — the latency win is real.

### Pattern: indexes for the hot queries, not all queries

```sql
-- Hot query: list user's orders by status, newest first
SELECT * FROM orders WHERE user_id = ? AND status = 'pending' ORDER BY created_at DESC LIMIT 20;

-- Right index: composite (user_id, status, created_at DESC)
CREATE INDEX idx_orders_user_status_ts ON orders(user_id, status, created_at DESC);
```

Use `EXPLAIN QUERY PLAN` to confirm the index is used. SQLite is a good citizen — it'll use an index if you have one, but you have to have the right one.

### Pattern: D1 Sessions API in handlers

```ts
async function withSession<T>(req: Request, env: Env, fn: (s: D1DatabaseSession) => Promise<T>) {
  const bookmark = req.headers.get("X-Bookmark") ?? "first-unconstrained";
  const session = env.DB.withSession(bookmark);
  const result = await fn(session);
  return { result, bookmark: session.getBookmark() };
}

export default {
  async fetch(req, env) {
    const { result, bookmark } = await withSession(req, env, async (db) => {
      // ... use db.prepare(), db.batch(), db.exec()
    });
    return Response.json(result, {
      headers: bookmark ? { "X-Bookmark": bookmark } : {}
    });
  }
}
```

Pattern the bookmark passing as middleware. Don't hand-roll it in every handler.

### Pattern: per-tenant DO with SQLite

```ts
export class Tenant extends DurableObject {
  sql: SqlStorage;
  constructor(state, env) {
    super(state, env);
    this.sql = state.storage.sql;
    this.migrate();
  }

  migrate() {
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS schema_version (v INTEGER PRIMARY KEY);
      INSERT OR IGNORE INTO schema_version (v) VALUES (0);

      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY, email TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL DEFAULT (unixepoch())
      );
    `);
    const v = this.sql.exec("SELECT v FROM schema_version").one().v as number;
    if (v < 1) {
      this.sql.exec("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'member'");
      this.sql.exec("UPDATE schema_version SET v = 1");
    }
  }
}
```

DO schema migration: code-driven, idempotent, runs on every wake. Fast — `CREATE TABLE IF NOT EXISTS` is cheap.

### Pattern: R2 + signed URLs

```ts
// Worker generates a signed URL for direct browser upload
const url = await env.R2.createPresignedUrl({
  bucket: "user-uploads",
  key: `tenant-${tenantId}/${userId}/${crypto.randomUUID()}`,
  method: "PUT",
  expiresIn: 3600
});
return Response.json({ url });
```

Direct browser → R2 upload, skip the Worker for the bytes. Workers stay cheap; R2 handles the upload.

For downloads, signed URLs work the same way — useful for time-limited links to private objects.

### Pattern: Hyperdrive in a Worker

```ts
// wrangler.toml
// [[hyperdrive]]
// binding = "HYPERDRIVE"
// id = "..."

import { Pool } from "pg";   // or @neondatabase/serverless

async function getDb(env) {
  return new Pool({ connectionString: env.HYPERDRIVE.connectionString, max: 5 });
}

async function getUser(env, id) {
  const db = await getDb(env);
  const { rows } = await db.query("SELECT * FROM users WHERE id = $1", [id]);
  // Don't pool.end() — let Hyperdrive manage pool lifecycle
  return rows[0];
}
```

Don't open a fresh pool on every request — module-scope pool is fine, but in V8 isolates the lifecycle is "as long as the isolate lives." Hyperdrive handles the actual upstream pool to your DB.

### Pattern: Vectorize with metadata index

```bash
wrangler vectorize create my-index --dimensions=1024 --metric=cosine
wrangler vectorize create-metadata-index my-index --property-name=tenant_id --type=string
wrangler vectorize create-metadata-index my-index --property-name=doc_type --type=string
```

```ts
// Insert with metadata
await env.VECTORS.upsert([
  { id: "doc1", values: emb1, metadata: { tenant_id: "t1", doc_type: "policy", title: "Refund Policy" } },
  { id: "doc2", values: emb2, metadata: { tenant_id: "t1", doc_type: "faq",    title: "How returns work" } }
]);

// Query
const r = await env.VECTORS.query(queryEmb, {
  topK: 5,
  filter: { tenant_id: { $eq: "t1" }, doc_type: { $in: ["policy", "faq"] } },
  returnMetadata: "all"
});
```

Without the metadata index, the filter still works but scans more vectors.

### Pattern: Analytics Engine for metrics

```ts
// Wrangler.toml: [[analytics_engine_datasets]] binding = "AE" dataset = "..."
env.AE.writeDataPoint({
  indexes: ["api-events"],
  doubles: [response_time_ms, response_size_bytes],
  blobs: [tenant_id, endpoint, status_code.toString()]
});
```

Query via SQL-over-HTTP:
```sql
SELECT
  blob1 AS tenant_id,
  blob2 AS endpoint,
  COUNT(*) AS calls,
  AVG(double1) AS avg_latency_ms
FROM api_events
WHERE timestamp > NOW() - INTERVAL '1' HOUR
GROUP BY blob1, blob2
ORDER BY calls DESC;
```

Limits: 25 indexes/doubles/blobs total per datapoint, 5KB per datapoint. Plan field assignments up front.

### Pattern: Pipelines → R2 for high-volume ingest

```ts
// Worker pushes events into Pipelines binding
await env.PIPELINE.send({
  user_id: ctx.user.id,
  event: "view",
  timestamp: Date.now(),
  url: req.url
});
```

Pipelines batches by time/size, writes Parquet to R2. Later you query R2 SQL for offline analytics. Use case: clickstream, audit logs, IoT events.

### Anti-pattern: D1 as a queue

```sql
-- BAD
SELECT * FROM tasks WHERE processed = 0 ORDER BY created_at LIMIT 1;
UPDATE tasks SET processed = 1 WHERE id = ?;
```

Race conditions, hot indexes, hot rows. Use **Queues** for queues.

### Anti-pattern: KV as transactional state

KV writes are eventually consistent + per-key rate limited (~1/sec). Using KV for "increment counter on each request" or "track inflight payment state" → broken.

### Anti-pattern: storing PII in KV without TTL

Once written, KV objects persist until deleted or TTL. If you write user data without TTL and don't have a delete cron, GDPR DSAR/deletion gets ugly. Use TTLs for transient PII (sessions); use D1 for persistent PII so you can `DELETE FROM users WHERE id = ?` cleanly.

### Anti-pattern: cross-tenant Vectorize queries

```ts
const r = await env.VECTORS.query(queryEmb, { topK: 10 });   // no filter → cross-tenant
```

Always filter by tenant. Set up metadata index on tenant ID.

### Anti-pattern: D1 without indexes

D1 will table-scan happily. A 100K-row table with no indexes will respond in tens of ms per query — until you have 10M rows. **Add indexes for the hot queries from day one.** `EXPLAIN QUERY PLAN` is your friend.

### Anti-pattern: Hyperdrive caching writes-then-reads

```ts
await pool.query("UPDATE users SET name = $1 WHERE id = $2", [name, id]);
const { rows } = await pool.query("SELECT * FROM users WHERE id = $1", [id]);
// rows may be stale if cache hit
```

Either disable caching on the read after a write, or design around the staleness (only read after delay, or use direct DB connection for the read-after-write case).

## Tooling specifics

### `wrangler d1`

```bash
wrangler d1 create my-db
wrangler d1 list
wrangler d1 info my-db                          # see config, replicas, size
wrangler d1 execute my-db --command="SELECT COUNT(*) FROM users"
wrangler d1 execute my-db --file=./query.sql
wrangler d1 execute my-db --command="..." --remote     # against prod, not local
wrangler d1 migrations create my-db description
wrangler d1 migrations apply my-db
wrangler d1 migrations apply my-db --remote
wrangler d1 export my-db --output=backup.sql
wrangler d1 time-travel info my-db
wrangler d1 time-travel restore my-db --timestamp="2026-05-01T00:00:00Z"
```

D1 has **time-travel** restore for the last 30 days. Disaster-recovery is included; you don't need separate backups for that window.

### Drizzle ORM with D1

```ts
import { drizzle } from "drizzle-orm/d1";
import * as schema from "./schema";

export default {
  async fetch(req, env) {
    const db = drizzle(env.DB, { schema });
    const users = await db.query.users.findMany({ where: eq(schema.users.email, email) });
    return Response.json(users);
  }
}
```

Drizzle is the most-used D1 ORM. Type-safe queries, schema migrations via `drizzle-kit`. Recommended over hand-writing every query for non-trivial schemas.

### R2 S3 compatibility

```ts
import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";

const s3 = new S3Client({
  region: "auto",
  endpoint: `https://${env.ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: { accessKeyId: env.R2_KEY, secretAccessKey: env.R2_SECRET }
});
```

Works for most S3 clients. Some less-common S3 operations (specific lifecycle rules, replication features) may not be implemented; check [R2 S3 compatibility](https://developers.cloudflare.com/r2/api/s3/api/).

For Workers, prefer the native R2 binding (`env.R2.get/put/list`) — faster, no signing, types-aware.

### Vectorize tooling

```bash
wrangler vectorize create my-index --dimensions=1024 --metric=cosine
wrangler vectorize list
wrangler vectorize info my-index
wrangler vectorize insert my-index --file=./vectors.ndjson   # batch insert
wrangler vectorize get my-index --ids=id1,id2
wrangler vectorize delete-vectors my-index --ids=id1,id2
wrangler vectorize query my-index --vector-file=q.json --top-k=5
wrangler vectorize create-metadata-index my-index --property-name=field --type=string|number|boolean
wrangler vectorize list-metadata-indexes my-index
```

`vectorize insert` is the right batch path; don't loop `upsert` from a Worker for bulk ingest.

### Analytics Engine query API

Workers Analytics Engine SQL API: POST SQL to `https://api.cloudflare.com/client/v4/accounts/<id>/analytics_engine/sql` with API token.

```bash
curl -X POST \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"query": "SELECT blob1 AS tenant, COUNT(*) FROM api_events WHERE timestamp > NOW() - INTERVAL \"1\" DAY GROUP BY blob1"}' \
  https://api.cloudflare.com/client/v4/accounts/<id>/analytics_engine/sql
```

## Cross-references to products_covered

- **D1** → schema, indexes, migrations, Sessions API; [D1 docs](https://developers.cloudflare.com/d1/).
- **R2** → object storage + R2 SQL; [R2 docs](https://developers.cloudflare.com/r2/).
- **KV** → semantics + TTL; [KV docs](https://developers.cloudflare.com/kv/).
- **Durable Object SQLite** → per-tenant patterns; runtime details in `backend-architect.md`.
- **Hyperdrive** → sizing + cache; [Hyperdrive docs](https://developers.cloudflare.com/hyperdrive/).
- **Vectorize V2** → index layout; AI-side details in `ai-ml-engineer.md`; [Vectorize docs](https://developers.cloudflare.com/vectorize/).
- **Analytics Engine** → custom metrics; [Analytics Engine docs](https://developers.cloudflare.com/analytics/analytics-engine/).
- **Pipelines** → ingest → R2 path; [Pipelines docs](https://developers.cloudflare.com/pipelines/).

## Integration with always-on protocols

### TDD on D1 and DO SQLite

`@cloudflare/vitest-pool-workers` gives you a real D1 (isolated per test) and real DO instances. Write tests against the schema; assert query plans for hot queries (`EXPLAIN QUERY PLAN`).

```ts
import { env } from "cloudflare:test";

it("orders index is hit for user+status lookup", async () => {
  await env.DB.prepare("INSERT INTO orders ...").run();
  const plan = await env.DB.prepare("EXPLAIN QUERY PLAN SELECT * FROM orders WHERE user_id=? AND status=?").bind("u1", "pending").all();
  expect(JSON.stringify(plan.results)).toContain("USING INDEX idx_orders_user_status_ts");
});
```

### Verification for database-architect on Cloudflare

Before declaring data design ready:

- [ ] Every D1 hot query has an index that `EXPLAIN QUERY PLAN` confirms.
- [ ] Migrations are idempotent and tested against a copy of prod schema.
- [ ] Sessions API bookmark handling is wired for read-your-writes flows.
- [ ] DO migrations are code-managed and run on construct.
- [ ] R2 bucket policies / IAM tokens are scoped per env.
- [ ] KV usage doesn't include data that requires write linearizability.
- [ ] Vectorize metadata indexes are created for every filterable field.
- [ ] Multi-tenant data has tenant_id in every relevant index / metadata.
- [ ] Analytics Engine field assignments are documented (which blob is which dimension).
- [ ] Hyperdrive caching policy is documented per query (which cached, which not).
- [ ] Backup / restore plan exists (D1 time-travel + R2 versioning + external backups for paranoia).
- [ ] Data-residency requirements (Region: Earth restrictions) are configured.

### Debugging data issues

When data layer misbehaves:

1. **D1 slow query** → `EXPLAIN QUERY PLAN`; check D1 dashboard for query analytics; add or fix index.
2. **D1 stale read** → check Sessions API bookmark usage; verify it's being passed.
3. **DO write contention** → DO is bottlenecking; shard.
4. **KV stale read** → it's KV, it's eventually consistent. Move to D1 or DO if you need linearizable.
5. **Vectorize bad recall** → metadata filter wrong? embedding model mismatch? Index dimensions wrong?
6. **Hyperdrive timeout** → check upstream DB health; check pool size; check cache hit ratio.
7. **Analytics Engine missing data** → confirm writeDataPoint succeeded; check field type mismatches (blob vs index vs double).

### Escalation paths

- **Schema-level patterns and table layout** → original `database-architect` reference for cross-cutting principles.
- **Worker code interacting with DB** → `backend-architect` overlay.
- **CI for migrations, secret rotation** → `devops-engineer` overlay.
- **Vector design for retrieval quality** → `ai-ml-engineer` overlay.
- **Compliance for data residency / PII handling** → vertical (healthcare-architect, fintech-architect).

## Standing rules for database-architect on a Cloudflare engagement

1. **Pick the primitive that matches the access pattern.** D1 for shared relational, DO for per-entity strong consistency, KV for read-heavy eventual, R2 for blobs, Vectorize for vectors.
2. **Indexes for hot queries from day one.** D1 doesn't auto-create them.
3. **Sessions API for read-your-writes on D1.** Pass the bookmark.
4. **Migrations idempotent and forward-only.** Test against prod-shaped data.
5. **Multi-tenant data tagged with tenant_id and indexed accordingly.** Including Vectorize metadata indexes.
6. **No queues in D1.** Use Queues. No transactional state in KV. Use D1 or DO.
7. **Hyperdrive caching deliberate per query.** Default cache on; opt-out for read-after-write.
8. **Plan around the subrequest budget.** Batch D1 / batch R2 list / batch Vectorize upsert.
9. **Time-travel restore is part of DR for D1.** R2 versioning for objects. External backups for paranoia.
10. **`EXPLAIN QUERY PLAN` before shipping a hot query.**
