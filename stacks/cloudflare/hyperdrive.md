---
title: Hyperdrive
description: Connection-pool + query cache + private connectivity layer in front of Postgres or MySQL — the standard way to put a relational DB behind Workers.
product:
  name: Hyperdrive
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect, system-architect, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/hyperdrive/
  notes: "Postgres + MySQL; query plan + connection pooling behavior evolves; supports private DBs over Tunnel."
---

## What it is

Hyperdrive is Cloudflare's edge-side connection pool + query cache + private-connectivity layer for Postgres and MySQL. It exposes a binding (`env.HYPERDRIVE.connectionString`) that your Worker uses with standard drivers (`pg`, `mysql2`, `@neondatabase/serverless`); Hyperdrive handles the actual upstream pool to your DB.

Authoritative reference: [developers.cloudflare.com/hyperdrive](https://developers.cloudflare.com/hyperdrive/).

## When to use

- **Existing Postgres or MySQL you don't want to migrate** — Hyperdrive sits in front.
- **Postgres with extensions [D1](/stacks/cloudflare/d1/) can't provide** (PostGIS, pgvector, custom types).
- **Private databases** — pair Hyperdrive with [Cloudflare Tunnel](/stacks/cloudflare/tunnel/); your Postgres never sees a public IP.
- **Reduce connection pressure** on your DB — Workers don't open one connection each; Hyperdrive pools.

Don't use Hyperdrive when:

- **New project, no existing DB** — use D1.
- **Workload is mostly writes with strict linearizability** — Hyperdrive helps reads (pool + cache); writes still go to primary, so sizing the primary still matters.
- **You're caching writes-then-reads in the same flow** — cache makes that hazardous unless you've thought through query hints.

## 2025-2026 currency anchors

- **MySQL support landed** alongside Postgres — `mysql2` works via the Hyperdrive connection string.
- **Private DBs over Tunnel** — Hyperdrive can target databases routed through [Cloudflare Tunnel](/stacks/cloudflare/tunnel/), eliminating public IPs.
- **Query caching is opt-in per query** with TTL — cache hits return instantly, misses pool through to Postgres.
- **Hyperdrive is the standard way** to put a relational DB behind Workers as of 2025-26 (connection pooling + query caching + private connectivity in one binding).

## Patterns

### Basic usage with `pg`

```ts
import { Pool } from "pg";   // or @neondatabase/serverless

async function getDb(env) {
  return new Pool({ connectionString: env.HYPERDRIVE.connectionString, max: 5 });
}

async function getUser(env, id) {
  const db = await getDb(env);
  const { rows } = await db.query("SELECT * FROM users WHERE id = $1", [id]);
  return rows[0];
}
```

```toml
[[hyperdrive]]
binding = "HYPERDRIVE"
id = "your-hyperdrive-id"  # create via `wrangler hyperdrive create ...`
```

Don't open a fresh pool on every request — module-scope pool is fine. Don't `pool.end()` — let Hyperdrive manage the upstream pool lifecycle.

### MySQL

```ts
import mysql from "mysql2/promise";

const conn = await mysql.createConnection(env.HYPERDRIVE.connectionString);
const [rows] = await conn.query("SELECT * FROM users WHERE id = ?", [id]);
```

### Private DB via Tunnel

```bash
cloudflared tunnel create my-pg-tunnel
cloudflared tunnel route ip add 10.0.1.0/24 my-pg-tunnel
cloudflared tunnel run my-pg-tunnel

# Create Hyperdrive pointing at the tunnel-routed DB
wrangler hyperdrive create my-hyperdrive --connection-string="postgres://user:pass@10.0.1.42:5432/db"
```

DB never has a public IP; Tunnel handles connectivity. Combine with origin firewall rules to deny everything except Cloudflare IPs.

### Cache discipline per query

Hyperdrive caches reads by default. Cache-correctness is your responsibility:

- **Cache OK:** lookups, list pages, anything you can tolerate up to TTL stale.
- **Cache wrong:** read-after-write in the same flow, transactional reads, anything where the user just changed the data.

Per-query disable via the `hyperdrive_disable` driver hint or per-query SQL comment depending on driver. Check current docs.

## Anti-patterns

- **Disabling caching globally and then complaining about latency.** Tune per-query.
- **Using Hyperdrive for transactional writes that must be linearizable** with caching enabled — staleness creates phantom reads.
- **Pooling end-of-life** — calling `pool.end()` after every request. Hyperdrive handles the upstream; trust it.
- **Forgetting Tunnel for private DBs** — Hyperdrive connection string with public IP defeats the purpose if your security model expects no inbound.

## Gotchas

1. **Hyperdrive caches reads but you must opt in per query.** By default queries are pooled but not cached. Cache invalidation is TTL-based.
2. **Cache hits don't touch your DB** — if you cache writes-followed-by-reads you'll see stale data.
3. **Connection string changes** require recreating the Hyperdrive resource — credential rotation is non-trivial.
4. **Treat Hyperdrive cache like a CDN over your DB** — it's read-aside, not write-through.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime that consumes Hyperdrive bindings
- [D1](/stacks/cloudflare/d1/) — alternative when no existing DB and no Postgres extensions needed
- [Tunnel](/stacks/cloudflare/tunnel/) — private-DB connectivity
- [Smart Placement](/stacks/cloudflare/smart-placement/) — align Worker with backend DB region
- Role overlay: [database-architect on Cloudflare](/stacks/cloudflare/database-architect/), [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/hyperdrive](https://developers.cloudflare.com/hyperdrive/)
