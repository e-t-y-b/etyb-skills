---
title: Durable Objects
description: Cloudflare's strong-consistency primitive — single-instance routing per ID, SQLite-backed storage by default, alarms, WebSockets with the Hibernation API.
product:
  name: Durable Objects
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, database-architect]
  authoritative_url: https://developers.cloudflare.com/durable-objects/
  notes: "SQLite-backed DOs went GA in 2024 and became default class type in 2025; migration tag is new_sqlite_classes, not new_classes."
---

## What it is

Durable Objects (DOs) are Cloudflare's strong-consistency primitive. Each DO **instance** has a stable identity (by name or auto-generated ID), routes all requests for that ID to a single isolate in a single region, and exposes per-instance state. As of 2025, the default storage backend is **SQLite** — each DO gets its own SQLite database with full SQL, transactions, indexes, foreign keys, and ~10GB per instance.

Authoritative reference: [developers.cloudflare.com/durable-objects](https://developers.cloudflare.com/durable-objects/).

## When to use

- **Per-entity strict serialization** — user wallet, chat room, document collaboration, game lobby. Two requests to the same DO ID run on the same instance, in-order.
- **Per-tenant isolation** in multi-tenant apps — each tenant gets a DO with its own SQLite database. Up to ~10GB per tenant.
- **WebSocket-heavy real-time** — DO + Hibernation API handles many idle connections cheaply.
- **Per-entity scheduled work** — `state.storage.setAlarm()` is one-alarm-per-DO, cheaper than cron for entity-scoped tasks.

Don't use DO for:

- **General-purpose key-value** — use [KV](/stacks/cloudflare/kv/) for read-heavy eventually-consistent data.
- **Cross-entity queries** — DO scopes queries to one instance. Use [D1](/stacks/cloudflare/d1/) for cross-row, cross-entity SQL.
- **High-throughput writes through a single ID** — single-instance routing means single-instance bottleneck. Shard.

## 2025-2026 currency anchors

- **SQLite-backed by default.** New DO classes get a per-DO SQLite database, not the legacy KV-style storage. Old `this.state.storage.put/get` API still works but new code should use SQL.
- **Migration tag is `new_sqlite_classes`** in `wrangler.toml`, not the legacy `new_classes` — using the wrong tag gives you the old storage backend.
- **WebSocket Hibernation API** (`this.state.acceptWebSocket(server)`) is the cost-controlling primitive. Old "always-running" WebSockets are still supported but Hibernation should be the default for many-idle-connection apps (chat, realtime).
- **Alarms** are stable; one alarm per DO, setting a new one replaces the previous. Use [Workflows](/stacks/cloudflare/workflows/) if you need branching schedule logic.

## Patterns

### SQLite-backed DO with schema migration in constructor

```ts
export class Room extends DurableObject {
  sql: SqlStorage;

  constructor(state: DurableObjectState, env: Env) {
    super(state, env);
    this.sql = state.storage.sql;
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author TEXT NOT NULL,
        body TEXT NOT NULL,
        ts INTEGER NOT NULL
      )
    `);
  }

  async postMessage(author: string, body: string): Promise<number> {
    const ts = Date.now();
    const result = this.sql.exec(
      "INSERT INTO messages (author, body, ts) VALUES (?, ?, ?) RETURNING id",
      author, body, ts
    ).one();
    return Number(result.id);
  }
}
```

`wrangler.toml`:

```toml
[[durable_objects.bindings]]
name = "ROOM"
class_name = "Room"

[[migrations]]
tag = "v1"
new_sqlite_classes = ["Room"]   # <-- new_sqlite_classes, not new_classes
```

### Alarms — scheduled per-entity work

```ts
export class Reminder extends DurableObject {
  async schedule(userId: string, dueAt: number) {
    await this.state.storage.put("user_id", userId);
    await this.state.storage.setAlarm(dueAt);  // replaces any prior alarm
  }
  async alarm() {
    const userId = await this.state.storage.get<string>("user_id");
    await this.env.QUEUE.send({ type: "remind", userId });
  }
}
```

One alarm per DO. Setting a new alarm replaces the previous.

### WebSocket Hibernation API

```ts
export class Chat extends DurableObject {
  async fetch(request: Request) {
    const { 0: client, 1: server } = new WebSocketPair();
    this.state.acceptWebSocket(server);  // Hibernation API
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    for (const client of this.state.getWebSockets()) {
      if (client !== ws) client.send(message);
    }
  }
}
```

Hibernation lets DO instances evict from memory while idle WebSockets remain connected — billed only for actual message handling. Critical for cost on chat/realtime apps.

### Hot-DO sharding

```ts
// Bad: every write goes through one DO
const id = env.COUNTER.idFromName("global-counter");

// Better: shard across N DOs, sum on read
const shard = Math.floor(Math.random() * 32);
const id = env.COUNTER.idFromName(`counter-shard-${shard}`);
```

Anti-pattern: centralizing high-throughput writes through one DO ID.

### Per-tenant DO

Each tenant gets a Durable Object with their own SQLite DB. Up to ~10GB per tenant. Total isolation. Strong consistency per tenant. Alarms scoped to the tenant.

```ts
const id = env.TENANT.idFromName(`tenant-${tenantId}`);
const tenant = env.TENANT.get(id);
const result = await tenant.someOperation(args);
```

When this fits: multi-tenant apps with clear per-tenant data boundaries. When it doesn't: cross-tenant queries needed (use D1 alongside), or single tenant has hot enough writes to bottleneck the instance.

## Anti-patterns

- **Using `new_classes` migration tag for SQLite-backed DOs** — gives you the legacy KV-style storage.
- **Centralizing all writes through one DO ID** — single-instance contention. Shard by entity.
- **Treating DO storage as eventually consistent like KV** — it's strongly consistent within the instance, that's the whole point.
- **Always-running WebSockets when Hibernation would do** — pay for every idle connection.

## Gotchas

1. **Single-instance routing per ID** ≠ global serialization. The DO serializes within itself; you'll bottleneck at the DO's CPU and message dispatch rate.
2. **`sql.exec()` is synchronous** and returns a cursor; spread into array if you need all rows.
3. **Use parameterized queries** — SQLite-injection is real.
4. **No point-in-time restore for DO SQLite** as of 2026-Q2. If DO state is critical, mirror to D1 via a [Queue](/stacks/cloudflare/queues/).
5. **DO has a home region** initially placed by access pattern; not user-selectable.
6. **Transactions:** `state.storage.transaction(async (txn) => { ... })`. The whole DO runs single-threaded, so most code doesn't need explicit transactions — but for multi-statement atomicity across alarm + RPC, wrap.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime context; DOs are accessed from a Worker
- [Workers RPC](/stacks/cloudflare/workers-rpc/) — DO method calls use the RPC primitive
- [D1](/stacks/cloudflare/d1/) — cross-entity queries; often paired with DOs for materialized views
- [Workflows](/stacks/cloudflare/workflows/) — when you need durable multi-step orchestration with branching, not just one alarm
- [Realtime](/stacks/cloudflare/realtime/) — DO + WebSockets composes with Realtime for SFU/TURN scenarios
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [database-architect on Cloudflare](/stacks/cloudflare/database-architect/)
- Authoritative: [developers.cloudflare.com/durable-objects](https://developers.cloudflare.com/durable-objects/), [SQL storage API](https://developers.cloudflare.com/durable-objects/api/storage-api/)
