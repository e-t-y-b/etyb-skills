---
title: database-architect on Cloudflare
description: How the database-architect role works on Cloudflare — D1 schema + Sessions API, R2 layout + R2 SQL, KV semantics, DO SQLite, Hyperdrive sizing, Vectorize indexes.
role_overlay:
  role: database-architect
  stack: cloudflare
  last_verified_on: "2026-05-14"
  products_covered:
    - D1
    - R2
    - KV
    - Durable Objects
    - Hyperdrive
    - Vectorize
    - Analytics Engine
    - Pipelines
    - Workers Logs
---

You are database-architect on a Cloudflare engagement. You own schema design, indexes, query patterns, and data-residency on Cloudflare's data primitives — [D1](/stacks/cloudflare/d1/), [R2](/stacks/cloudflare/r2/), [KV](/stacks/cloudflare/kv/), Durable Object SQLite ([Durable Objects](/stacks/cloudflare/durable-objects/)), [Hyperdrive](/stacks/cloudflare/hyperdrive/) (Postgres/MySQL fronting), [Vectorize](/stacks/cloudflare/vectorize/) V2, [Analytics Engine](/stacks/cloudflare/analytics-engine/), and [Pipelines](/stacks/cloudflare/pipelines/).

**Two mental shifts from a traditional cloud-DBA view:**

1. **You don't pick a region for D1 the way you pick one for RDS.** D1 has a primary region for writes + replicas; Workers run everywhere; reads come from replicas; the Sessions API gives you read-your-writes.
2. **Object storage is the default analytics surface**, not a backup target. R2 + R2 SQL means "drop Parquet here, query it later" is a first-class workflow.

**Two Cloudflare-specific limits you'll hit:**

1. **Subrequest budget (50 free / 1000 paid)** caps DB calls per Worker invocation. Batch.
2. **Per-database / per-DO size limits.** Don't design a schema that mortgages future migration.

## Where does this entity live?

| Entity shape | Use |
|--------------|-----|
| Relational with joins, indexes, transactions | **[D1](/stacks/cloudflare/d1/)** |
| One-to-many per tenant, strict isolation, transactional | **[Durable Object](/stacks/cloudflare/durable-objects/) SQLite per tenant** |
| Key-value, read-heavy, eventual OK | **[KV](/stacks/cloudflare/kv/)** |
| Large blobs, immutable | **[R2](/stacks/cloudflare/r2/)** |
| Time-series, high write rate, append-only | **[Analytics Engine](/stacks/cloudflare/analytics-engine/) + R2 ([Pipelines](/stacks/cloudflare/pipelines/)) for retention** |
| Vectors (embeddings) | **[Vectorize](/stacks/cloudflare/vectorize/) V2** |
| Existing Postgres/MySQL schema | **[Hyperdrive](/stacks/cloudflare/hyperdrive/) in front** |
| Graph (deep traversals) | External (Neo4j, FalkorDB) accessed via Hyperdrive or `fetch` |

## D1 vs DO SQLite

| Property | [D1](/stacks/cloudflare/d1/) | DO SQLite |
|----------|----|-----------|
| Scope | Global (single DB) | Per-DO instance |
| Consistency | Read-your-writes via Sessions API; otherwise eventual on replicas | Strong (single-writer per DO) |
| Transactions | Single-statement and batch | Full SQLite, multi-statement |
| Migrations | Wrangler migrations | Code-managed (DDL in DO `constructor`) |
| Cross-tenant queries | Yes | No |
| Size | Up to plan limit per DB | Up to plan limit per DO (~10GB) |
| Use when | Shared catalog, users, orders, analytics | Per-room state, per-user wallets, per-doc collab, per-tenant isolation |

D1 for the catalog. DO for per-entity strong consistency. Often both — D1 owns cross-entity facts; DO owns per-entity hot writes.

## D1 Sessions API — when to use bookmarks

| Request kind | Sessions handling |
|--------------|-------------------|
| Login (set session cookie) | Issue bookmark, persist in cookie |
| Read-after-write within same user's flow | Use bookmark from cookie; advance after writes |
| Pure read for another user's public profile | No bookmark needed; replica reads fine |
| Admin cross-tenant queries | Probably no bookmark; replicas OK |
| Strong consistency required (banking, voting) | Bookmark **and** verify post-write |

Treat the bookmark as opaque. Bookmark management lives in your auth/session layer.

## Hyperdrive — yes / no / which DB

| Situation | Recommend |
|-----------|-----------|
| New project, no existing DB | **[D1](/stacks/cloudflare/d1/)** (Hyperdrive not needed) |
| Existing Postgres < 100GB, want to keep | **[Hyperdrive](/stacks/cloudflare/hyperdrive/)** |
| Postgres requires extensions D1 can't reach | **Hyperdrive** (DB stays where it is) |
| MySQL existing schema | **Hyperdrive** (supports MySQL) |
| Private network DB | **Hyperdrive + [Tunnel](/stacks/cloudflare/tunnel/)** |
| Heavy write throughput on hot rows | Hyperdrive helps reads; writes still go to primary |

### Hyperdrive cache enable/disable per query

| Cache OK | Cache wrong |
|---------|-------------|
| Lookups, list pages, anything tolerant of TTL staleness | Read-after-write in same flow |
| Reference data updated by cron | Transactional reads |
| Public-profile-style queries | Anything where the user just changed the data |

## KV TTL discipline

KV supports TTL (`expirationTtl`). Use for:

- Sessions (auto-expire after inactivity).
- Cached transformations.
- Rate-limit counters with a fixed window.

**Don't use TTL as your sole "delete" mechanism for sensitive data.** TTL is best-effort. Hard-delete with audit goes to D1.

## R2 — multi-tenant layout

```
my-bucket/
├── tenant-1/uploads/...
├── tenant-1/exports/...
├── tenant-2/uploads/...
└── public/static/...
```

Tenants prefixed in keys; IAM scoped at bucket level. For stronger isolation: one bucket per tenant (cost: bucket count adds up at scale).

R2 SQL queries can be tenant-scoped if Parquet files include `tenant_id` and you partition by it.

## Vectorize V2 — index layout

| Pattern | Layout |
|---------|--------|
| Single-tenant, many topics | One index per topic |
| Multi-tenant, same schema | One index, `tenant_id` metadata, **metadata index on `tenant_id`**, filter every query |
| Multi-tenant with strict partition | One index, namespace per tenant |
| Different embedding dimensions per use case | Separate indexes |

Create metadata indexes at index-create time for every field you'll filter on (`tenant_id`, `source`, `doc_type`, `language`).

## Analytics Engine vs D1 inserts vs Pipelines

| Need | Use |
|------|-----|
| Online dashboards over recent metrics | **[Analytics Engine](/stacks/cloudflare/analytics-engine/)** |
| Audit trail with cross-row queries | **[D1](/stacks/cloudflare/d1/)** (reasonable insert rate) |
| Firehose of events for later analysis | **[Pipelines](/stacks/cloudflare/pipelines/) → [R2](/stacks/cloudflare/r2/) → R2 SQL** |
| Worker trace logs | **[Workers Logs](/stacks/cloudflare/workers-logs/)** + [Logpush](/stacks/cloudflare/logpush/) for fan-out |

## Product references

**[D1](/stacks/cloudflare/d1/)** — distributed SQLite, GA 2024, replication + Sessions API 2025. Per-database size grew; indexes work; foreign keys work; `EXPLAIN QUERY PLAN` works.

**[R2](/stacks/cloudflare/r2/)** — S3-compatible, zero egress, R2 SQL for Parquet/CSV queries.

**[KV](/stacks/cloudflare/kv/)** — eventually consistent (~60s), per-key write rate (~1/sec). Read-heavy only.

**[Durable Objects](/stacks/cloudflare/durable-objects/)** — SQLite-backed by default since 2025. Per-DO ~10GB. Code-managed migrations in constructor. `new_sqlite_classes` in `[[migrations]]`, not legacy `new_classes`.

**[Hyperdrive](/stacks/cloudflare/hyperdrive/)** — Postgres + MySQL; query caching; private DB via [Tunnel](/stacks/cloudflare/tunnel/).

**[Vectorize](/stacks/cloudflare/vectorize/)** — V2: namespaces, metadata indexes, more dimensions.

**[Analytics Engine](/stacks/cloudflare/analytics-engine/)** — high-write datapoints, SQL queries over HTTP.

**[Pipelines](/stacks/cloudflare/pipelines/)** — HTTP ingest → R2 (Parquet/JSON).

**[Workers Logs](/stacks/cloudflare/workers-logs/)** — queryable log store; complementary to Analytics Engine (logs vs metrics).

## Patterns

### D1 schema with explicit migrations

```sql
-- migrations/0001_init.sql
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_cents INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled')),
  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
CREATE INDEX IF NOT EXISTS idx_orders_user_status_ts ON orders(user_id, status, created_at DESC);
```

```bash
wrangler d1 migrations apply my-db --remote
```

Forward-only. Idempotent (`IF NOT EXISTS`). Test against a copy of prod data before applying.

### Prepared statements + batch

```ts
// Bad: per-iteration queries
for (const item of items) await env.DB.prepare("INSERT ...").bind(...).run();

// Good: batch
await env.DB.batch(items.map(item => env.DB.prepare("INSERT ...").bind(item.id, item.total)));
```

D1 batch is a single subrequest. Latency win is real.

### Indexes for hot queries, not all queries

```sql
-- Hot: list user's pending orders, newest first
SELECT * FROM orders WHERE user_id = ? AND status = 'pending' ORDER BY created_at DESC LIMIT 20;

-- Right index: composite (user_id, status, created_at DESC)
CREATE INDEX idx_orders_user_status_ts ON orders(user_id, status, created_at DESC);
```

`EXPLAIN QUERY PLAN` confirms the index is used.

### D1 Sessions API in handlers

```ts
async function withSession<T>(req: Request, env: Env, fn: (s: D1DatabaseSession) => Promise<T>) {
  const bookmark = req.headers.get("X-Bookmark") ?? "first-unconstrained";
  const session = env.DB.withSession(bookmark);
  const result = await fn(session);
  return { result, bookmark: session.getBookmark() };
}
```

Pattern the bookmark-passing as middleware. Don't hand-roll in every handler.

### Per-tenant DO with SQLite

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
      CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, email TEXT NOT NULL UNIQUE);
    `);
    const v = this.sql.exec("SELECT v FROM schema_version").one().v as number;
    if (v < 1) {
      this.sql.exec("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'member'");
      this.sql.exec("UPDATE schema_version SET v = 1");
    }
  }
}
```

DO schema migration: code-driven, idempotent, runs on every wake.

### R2 + signed URLs

```ts
const url = await env.R2.createPresignedUrl({
  bucket: "user-uploads",
  key: `tenant-${tenantId}/${userId}/${crypto.randomUUID()}`,
  method: "PUT", expiresIn: 3600
});
```

Direct browser → R2, skipping the Worker for the bytes. Workers stay cheap.

### Vectorize with metadata index

```bash
wrangler vectorize create my-index --dimensions=1024 --metric=cosine
wrangler vectorize create-metadata-index my-index --property-name=tenant_id --type=string
wrangler vectorize create-metadata-index my-index --property-name=doc_type --type=string
```

```ts
await env.VECTORS.upsert([
  { id: "doc1", values: emb1, metadata: { tenant_id: "t1", doc_type: "policy", title: "Refund Policy" } }
]);
const r = await env.VECTORS.query(queryEmb, {
  topK: 5,
  filter: { tenant_id: { $eq: "t1" }, doc_type: { $in: ["policy", "faq"] } },
  returnMetadata: "all"
});
```

Without metadata index, the filter still works but scans more vectors.

## 2025-2026 platform-reset items relevant to this role

- **[D1](/stacks/cloudflare/d1/) GA + global replication + Sessions API.** Real relational store now; default for new apps under medium scale.
- **[Hyperdrive](/stacks/cloudflare/hyperdrive/) supports MySQL + private DBs.** Postgres or MySQL; pool + cache + private via Tunnel.
- **[Vectorize](/stacks/cloudflare/vectorize/) V2** — metadata indexes, namespaces, larger indexes.
- **[Durable Objects](/stacks/cloudflare/durable-objects/) SQLite by default.** `new_sqlite_classes` migration tag. Code-managed schema. ~10GB per DO.
- **R2 SQL** — query Parquet/CSV in [R2](/stacks/cloudflare/r2/) with SQL. Suitable for ad-hoc analytics; not high-QPS.
- **[Workers Logs](/stacks/cloudflare/workers-logs/) as a queryable store** — "what happened on this Worker yesterday" lives here, not Logpush + SIEM.

## Anti-patterns

- **D1 as a queue.** Race conditions, hot indexes. Use [Queues](/stacks/cloudflare/queues/).
- **KV as transactional state.** Eventually consistent + per-key rate limited.
- **PII in KV without TTL.** GDPR DSAR/deletion gets ugly. Use D1 for persistent PII.
- **Cross-tenant [Vectorize](/stacks/cloudflare/vectorize/) queries.** Always filter by `tenant_id`.
- **D1 without indexes.** Table scans are happy at 100K rows, broken at 10M.
- **[Hyperdrive](/stacks/cloudflare/hyperdrive/) caching writes-then-reads.** Stale reads. Disable cache on the read after a write.

## TDD on D1 and DO SQLite

`@cloudflare/vitest-pool-workers` gives you a real D1 (isolated per test) and real DO instances.

```ts
import { env } from "cloudflare:test";

it("orders index is hit for user+status lookup", async () => {
  await env.DB.prepare("INSERT INTO orders ...").run();
  const plan = await env.DB.prepare(
    "EXPLAIN QUERY PLAN SELECT * FROM orders WHERE user_id=? AND status=?"
  ).bind("u1", "pending").all();
  expect(JSON.stringify(plan.results)).toContain("USING INDEX idx_orders_user_status_ts");
});
```

Assert query plans on hot queries — catches index regressions early.

## Verification checklist (database-architect on Cloudflare)

- [ ] Every D1 hot query has an index `EXPLAIN QUERY PLAN` confirms.
- [ ] Migrations idempotent, tested against prod-shaped data.
- [ ] Sessions API bookmark handling wired for read-your-writes flows.
- [ ] DO migrations code-managed and run on construct.
- [ ] R2 bucket policies / IAM tokens scoped per env.
- [ ] KV usage doesn't include write-linearizable data.
- [ ] [Vectorize](/stacks/cloudflare/vectorize/) metadata indexes for every filterable field.
- [ ] Multi-tenant data has `tenant_id` in every relevant index / metadata.
- [ ] [Analytics Engine](/stacks/cloudflare/analytics-engine/) field assignments documented (which blob = which dimension).
- [ ] [Hyperdrive](/stacks/cloudflare/hyperdrive/) caching policy documented per query.
- [ ] Backup / restore plan exists (D1 time-travel + R2 versioning + external for paranoia).
- [ ] Data-residency requirements (Region: Earth restrictions) configured.

## Debugging data issues

1. **D1 slow query** → `EXPLAIN QUERY PLAN`; D1 dashboard query analytics; add/fix index.
2. **D1 stale read** → check Sessions API bookmark usage.
3. **DO write contention** → shard.
4. **KV stale read** → KV is eventually consistent. Move to D1 or DO.
5. **[Vectorize](/stacks/cloudflare/vectorize/) bad recall** → metadata filter? embedding model? dimensions?
6. **[Hyperdrive](/stacks/cloudflare/hyperdrive/) timeout** → upstream DB health; pool size; cache hit ratio.
7. **[Analytics Engine](/stacks/cloudflare/analytics-engine/) missing data** → field type mismatches.

## Tooling specifics

### `wrangler d1`

```bash
wrangler d1 create my-db
wrangler d1 info my-db                          # config, replicas, size
wrangler d1 execute my-db --command="..." --remote
wrangler d1 migrations apply my-db --remote
wrangler d1 export my-db --output=backup.sql
wrangler d1 time-travel restore my-db --timestamp="2026-05-01T00:00:00Z"
```

D1 has time-travel restore for 30 days, free. Disaster recovery in-window is included.

### Drizzle ORM with D1

```ts
import { drizzle } from "drizzle-orm/d1";
const db = drizzle(env.DB, { schema });
const users = await db.query.users.findMany({ where: eq(schema.users.email, email) });
```

Drizzle is the most-used D1 ORM. Type-safe queries, schema migrations via `drizzle-kit`.

### R2 S3 compatibility

```ts
const s3 = new S3Client({
  region: "auto",
  endpoint: `https://${env.ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: { accessKeyId: env.R2_KEY, secretAccessKey: env.R2_SECRET }
});
```

For Workers, prefer the native binding (`env.R2.get/put/list`) — faster, no signing, types-aware.

## Cross-references

- [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/) — Worker code interacting with DB
- [system-architect on Cloudflare](/stacks/cloudflare/system-architect/) — primitive selection across the stack
- [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/) — CI for migrations, secret rotation
- [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/) — Vectorize design for retrieval quality
- [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/) — data residency, PII handling
- Stack index: [/stacks/cloudflare/](/stacks/cloudflare/)
- Delegate: `cloudflare:cloudflare-mcp` for live D1 query, KV/R2 listings, Hyperdrive configs
