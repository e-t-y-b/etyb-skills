---
role: backend-architect
stack: cloudflare
last_verified_on: "2026-05-14"
---

# Cloudflare overlay for `backend-architect`

You write the Workers. You design the bindings graph. You decide whether a piece of state lives in a Durable Object, D1, KV, R2, or Hyperdrive'd Postgres. You pick the handler types, the compatibility flags, and the error-handling model. This overlay teaches you what the Workers platform expects in 2026.

The original `backend-architect` reference covers REST/GraphQL/gRPC, microservices, auth patterns — that's all still valid. This overlay specializes those principles to the Workers runtime and the bindings model.

## Role briefing — backend on Workers

Cloudflare Workers is **not Node.js, not a traditional FaaS, not a long-running server**. It is:
- V8 isolates (the workerd runtime) that wake up on a request, run for some milliseconds, and may be recycled at any time.
- A web-standards runtime (Fetch, Streams, Crypto, URLPattern, Web Sockets) extended with Cloudflare bindings.
- Distributed by default: every Worker runs in every Cloudflare data center; routing happens automatically.
- Limited to a CPU budget per request (10ms free, 30s paid) and a subrequest budget (50 free, 1000 paid).
- Authored in JavaScript, TypeScript, Python (limited beta), or anything that compiles to Wasm. Default and best-supported is TypeScript.

What this means for backend design:
- **You don't run a server.** You write request handlers. State is externalized.
- **You design the bindings graph first.** Bindings are the runtime contract; the code is implementation detail.
- **You can't keep secrets in memory across requests.** Use `env.SECRET_NAME` from Wrangler secrets or env vars.
- **You can't open arbitrary TCP sockets** (with one exception: the `connect()` API from `cloudflare:sockets`, used by Hyperdrive and a handful of approved drivers).
- **You will hit CPU/subrequest/wall-clock limits long before you hit memory limits.** Design for the right limit.

## Decision frameworks

### Where does this piece of state live?

| Need | Use | Don't use | Why |
|------|-----|-----------|-----|
| Read-heavy config, feature flags, sessions (stale-by-60s OK) | **KV** | D1, DO | KV is eventually consistent (~60s globally), free reads from edge cache; D1 is overkill for blob-keyed configs |
| Read-your-writes relational data | **D1 + Sessions API** | KV, plain D1 without bookmarks | KV eventual; D1 without Sessions can read from a stale replica |
| Per-entity strict serialization (user, room, document, game) | **Durable Object (SQLite)** | D1 row-level, KV CAS | DO routes all writes to a single instance per ID; SQL local to that instance; alarms for scheduled work |
| Object storage (assets, uploads, logs, large blobs) | **R2** | DO storage, KV | R2 is S3-compatible, zero egress, designed for big objects |
| Append-only events / time-series | **Analytics Engine + R2 (or Pipelines → R2)** | KV, D1 inserts | KV/D1 will hit limits; Analytics Engine is built for high-volume writes + SQL queries |
| Vector search (embeddings) | **Vectorize V2** | DIY in DO | Managed ANN; metadata filters; up to millions of vectors per index |
| Existing Postgres / MySQL data | **Hyperdrive** in front of it | Direct connect from Worker | Hyperdrive does the pooling + cache + private connectivity; raw connections from a Worker burn pool capacity |
| Short-lived cache (memoized API response, rate-limit counter) | **Cache API** (`caches.default`) or **Workers Rate Limiting binding** | KV (writes cost money) | Cache API is free reads/writes within a colo; rate-limit binding has its own semantics |

### Which handler do I write?

Workers have a small set of entrypoint handlers. Pick the one that matches the trigger; don't try to multiplex:

| Handler | Triggered by | Notable limits |
|---------|--------------|----------------|
| `fetch(request, env, ctx)` | HTTP request to a route/domain | CPU 10ms/30s; subrequest 50/1000; body 100MB streamed |
| `scheduled(controller, env, ctx)` | Cron Triggers (UTC, 1-min granularity) | Same CPU as fetch; `controller.cron` tells you which schedule fired |
| `queue(batch, env, ctx)` | Queues consumer | Up to 100 messages per batch (configurable); batch-level retry |
| `email(message, env, ctx)` | Email Routing → Email Worker | Inbound only; forward, drop, or process |
| `tail(events, env, ctx)` | Tail Worker on another Worker | Process logs from another Worker (Workers for Platforms pattern) |
| `alarm()` (on a DO) | `state.storage.setAlarm()` | Single alarm per DO; replaces last one on set |
| `connect(ws)` / `webSocketMessage` | WebSocket upgrade in a DO | DO Hibernation API for many idle WebSockets |
| `RPC method` (on a `WorkerEntrypoint`) | Service binding / DO binding RPC call | Method args/return must be RPC-serializable |

### Inter-worker communication: RPC, Service Bindings, HTTP

As of 2024-2025, the canonical pattern is **Workers RPC** with `WorkerEntrypoint` classes. Use this decision tree:

- **Two Workers in your own account that need to call each other → RPC (service binding).** Free, internal, no HTTP overhead.
- **A Worker calling a Durable Object → DO binding + RPC method.** `env.MY_DO.idFromName("user-42").someMethod(args)`.
- **A Worker calling a public API (Stripe, OpenAI, your own non-CF service) → `fetch()`.** Counts as a subrequest.
- **A Worker calling a customer's Worker (Workers for Platforms) → Dispatch Namespace binding.** Routes by namespace.
- **You need fire-and-forget across Workers → Queues** (decouple, retries, batching).

Legacy: `env.OTHER.fetch(request)` style service bindings. Still works, still supported, but new code should declare `WorkerEntrypoint` classes and call methods.

### Sync compute vs Workflows vs Queues vs DO Alarms

Async work patterns:

| Pattern | Use | Why |
|---------|-----|-----|
| Background work that must finish before isolate recycle | `ctx.waitUntil(promise)` inside the handler | Extends the isolate's lifetime up to 30s (longer for some triggers) past the response |
| Decoupled producer/consumer, batch processing, retries with backoff | **Queues** | Built-in retries, dead-letter, batch consumption; up to 4500 msg/sec per queue |
| Long-running, durable, sleepable, multi-step orchestration | **Workflows** | Durable execution; sleeps don't burn compute; survives Worker restarts; resumable |
| Per-entity scheduled task ("remind me about user 42 in 1 hour") | **DO alarm** | One alarm per DO; replaces last; cheap |
| Periodic batch ("every 5 minutes, do X") | **Cron Trigger** (`scheduled` handler) | UTC, 1-min granularity, free |
| Stream processing / data ingestion → R2 | **Pipelines** | HTTP → buffer → R2 in Parquet/JSON; managed schema |

**Don't reach for Queues + DO state + cron when Workflows fit.** Workflows GA'd in 2025 specifically to replace that 3-piece pattern for orchestration.

### Static assets: Workers Static Assets vs Pages vs R2 + Worker

| Scenario | Recommend |
|----------|-----------|
| New static-asset-heavy site (Next.js, Astro, SvelteKit, plain HTML) | **Workers Static Assets** (`assets` binding in `wrangler.toml`) |
| Existing Pages project, working fine | Leave on Pages; migrate when adding non-trivial logic |
| Existing Pages project, want Workers features (RPC, full bindings) | **Migrate to Workers Static Assets** ([migration guide](https://developers.cloudflare.com/workers/static-assets/migration-guides/migrate-from-pages/)) |
| Large media library, user-uploaded files | **R2** directly (signed URLs or fronted by a Worker for auth) |
| Hybrid (some static, some served by a function) | Workers Static Assets with `run_worker_first` for specific routes |

Pages is in maintenance mode as of 2024-2025; new Cloudflare platform features land in Workers Static Assets first.

## Critical 2025-2026 platform reset for backend-architects

What changed since your last Workers project:

### Workers RPC and `WorkerEntrypoint`

Old pattern (still works, do not use for new code):
```ts
// Worker A
export default {
  async fetch(req, env) {
    return env.OTHER.fetch(new Request("https://service/foo", { body }));
  }
}
```

New pattern (canonical as of 2024-25):
```ts
// Worker B — exports an entrypoint class
import { WorkerEntrypoint } from "cloudflare:workers";

export class MyService extends WorkerEntrypoint {
  async getUser(userId: string): Promise<User> {
    return this.env.DB.prepare("SELECT * FROM users WHERE id=?").bind(userId).first<User>();
  }
}

// Worker A — calls a method directly
export default {
  async fetch(req, env) {
    const user = await env.OTHER.getUser("u_42");
    return Response.json(user);
  }
}
```

In `wrangler.toml`:
```toml
[[services]]
binding = "OTHER"
service = "worker-b"
entrypoint = "MyService"
```

RPC method args/returns can be primitives, `ArrayBuffer`, `Request`/`Response`, `ReadableStream`, `Map`/`Set`, dates, errors, or other RPC-serializable types. Callable stubs and disposable resources are supported (see [RPC docs](https://developers.cloudflare.com/workers/runtime-apis/rpc/)).

### Durable Objects: SQLite by default

DO classes now declare a SQLite-backed storage backend. Migrations from KV-style storage are documented but not automatic.

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

  async recent(n: number): Promise<Message[]> {
    return [...this.sql.exec(
      "SELECT id, author, body, ts FROM messages ORDER BY ts DESC LIMIT ?",
      n
    )] as Message[];
  }
}
```

In `wrangler.toml`:
```toml
[[durable_objects.bindings]]
name = "ROOM"
class_name = "Room"

[[migrations]]
tag = "v1"
new_sqlite_classes = ["Room"]   # <-- new_sqlite_classes, not new_classes, for SQLite backend
```

Hard rules:
- Each DO instance has its own SQLite DB, up to ~10GB (varies by plan; check current docs).
- `sql.exec()` is synchronous and returns a cursor; spread into array if you need all rows.
- Use parameterized queries; SQLite-injection is real here.
- Transactions: `state.storage.transaction(async (txn) => { ... })`. The whole DO runs single-threaded, so most code doesn't need explicit transactions — but for multi-statement atomicity across alarm + RPC, wrap them.

### Alarms: scheduled work per DO

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

One alarm per DO. Setting a new alarm replaces the previous. Use Workflows if you need branching schedule logic.

### WebSockets + Hibernation API

```ts
export class Chat extends DurableObject {
  async fetch(request: Request) {
    const { 0: client, 1: server } = new WebSocketPair();
    this.state.acceptWebSocket(server);  // <-- Hibernation API
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    // ws.serializeAttachment(attachmentObj) to persist per-WS state across hibernations
    for (const client of this.state.getWebSockets()) {
      if (client !== ws) client.send(message);
    }
  }

  async webSocketClose(ws: WebSocket, code: number, reason: string, wasClean: boolean) {
    ws.close(code, "Durable Object is closing WebSocket");
  }
}
```

**Use the Hibernation API**, not the old "always-running" pattern. Hibernation lets DO instances evict from memory while idle WebSockets remain connected — billed only for actual message handling. Critical for cost on chat/realtime apps with many idle connections.

### D1 with Sessions API (read-your-writes across replicas)

```ts
export default {
  async fetch(req, env) {
    // Get or create session bookmark from cookie/header
    const bookmark = req.headers.get("X-D1-Bookmark") ?? "first-unconstrained";
    const session = env.DB.withSession(bookmark);

    // Read uses replica if bookmark allows; falls back to primary if needed
    const user = await session.prepare("SELECT * FROM users WHERE id=?")
      .bind(userId)
      .first();

    // Write goes to primary; bookmark advances
    await session.prepare("UPDATE users SET seen_at=? WHERE id=?")
      .bind(Date.now(), userId)
      .run();

    // Pass new bookmark back to client to use on next request
    return Response.json(user, {
      headers: { "X-D1-Bookmark": session.getBookmark() ?? "" }
    });
  }
}
```

Without Sessions, a read after write may hit a replica that hasn't caught up. The pattern: persist the bookmark per-user (cookie, JWT claim, header) and pass it on subsequent requests.

### Workflows: durable execution

```ts
import { WorkflowEntrypoint, WorkflowStep, WorkflowEvent } from "cloudflare:workers";

type OrderParams = { orderId: string };

export class FulfillOrder extends WorkflowEntrypoint<Env, OrderParams> {
  async run(event: WorkflowEvent<OrderParams>, step: WorkflowStep) {
    const { orderId } = event.payload;

    const order = await step.do("load-order", async () => {
      return this.env.DB.prepare("SELECT * FROM orders WHERE id=?").bind(orderId).first();
    });

    await step.do("charge-card", { retries: { limit: 3, delay: "10 seconds", backoff: "exponential" } }, async () => {
      await fetch("https://api.stripe.com/v1/charges", { ... });
    });

    await step.sleep("wait-before-ship", "1 hour");

    await step.do("dispatch-warehouse", async () => {
      await this.env.WAREHOUSE.dispatch(orderId);
    });
  }
}
```

Each `step.do()` is durable: result is checkpointed, retried independently, survives Worker restarts. `step.sleep()` doesn't burn CPU — the workflow is suspended until the time elapses. **This is the right primitive for any multi-step async business process.** ([Workflows docs](https://developers.cloudflare.com/workflows/))

### Hyperdrive

```ts
import { Pool } from "@neondatabase/serverless"; // or pg, mysql2 with hyperdrive

export default {
  async fetch(req, env) {
    const pool = new Pool({ connectionString: env.HYPERDRIVE.connectionString });
    const { rows } = await pool.query("SELECT * FROM users WHERE id=$1", [userId]);
    // Don't end the pool; let Hyperdrive manage connections
    return Response.json(rows[0]);
  }
}
```

In `wrangler.toml`:
```toml
[[hyperdrive]]
binding = "HYPERDRIVE"
id = "your-hyperdrive-id"  # create via `wrangler hyperdrive create ...`
```

Hyperdrive (as of 2025-26) supports Postgres and MySQL. It does:
- Connection pooling on Cloudflare's edge (your DB sees a small, stable pool).
- Query caching (TTL-configurable, opt-in per query).
- Private DB connectivity over Cloudflare Tunnel — your Postgres doesn't need a public IP.

Don't disable caching globally and then complain about latency. Don't use Hyperdrive for transactional writes that must be linearizable — caching makes that hazardous unless you've thought through query hints.

### Vectorize V2

```ts
export default {
  async fetch(req, env) {
    const query = await env.AI.run("@cf/baai/bge-base-en-v1.5", { text: ["search query"] });

    const results = await env.VECTOR_INDEX.query(query.data[0], {
      topK: 10,
      returnMetadata: "all",
      filter: { tenant_id: { $eq: "tenant_42" } }  // metadata filtering, V2 feature
    });

    return Response.json(results);
  }
}
```

V2 adds metadata indexes (filter at query time without scanning), more dimensions, and namespace partitioning for multi-tenancy. Define metadata indexes at index-creation time via Wrangler.

### Queues — producer / consumer patterns

```ts
// Producer Worker
async fetch(req, env, ctx) {
  // ... handle request
  ctx.waitUntil(env.JOBS.send({
    type: "send_welcome_email",
    userId,
    at: Date.now()
  }, { contentType: "json", delaySeconds: 60 }));
  return new Response("queued");
}
```

```ts
// Consumer Worker
export default {
  async queue(batch: MessageBatch<Job>, env: Env, ctx: ExecutionContext) {
    for (const msg of batch.messages) {
      try {
        await processJob(msg.body, env);
        msg.ack();
      } catch (e) {
        msg.retry({ delaySeconds: 30 });
      }
    }
  }
}
```

```toml
[[queues.producers]]
binding = "JOBS"
queue = "jobs-prod"

[[queues.consumers]]
queue = "jobs-prod"
max_batch_size = 25
max_batch_timeout = 5
max_retries = 3
dead_letter_queue = "jobs-prod-dlq"
```

Per-message `ack` / `retry` / `retryAll` / `ackAll` lets you handle batch-with-partial-failure correctly. Always set a DLQ — silent message loss is hard to debug.

### Cron Triggers

```ts
export default {
  async scheduled(controller: ScheduledController, env: Env, ctx: ExecutionContext) {
    if (controller.cron === "*/5 * * * *") {
      ctx.waitUntil(fiveMinutelyJob(env));
    } else if (controller.cron === "0 2 * * *") {
      ctx.waitUntil(dailyJob(env));
    }
  }
}
```

```toml
[[triggers.crons]]
cron = "*/5 * * * *"

[[triggers.crons]]
cron = "0 2 * * *"
```

UTC, one-minute granularity, multiple crons per Worker. `ctx.waitUntil` extends lifetime up to 15min for cron handlers (verify current limit). For longer-running scheduled work, kick a Workflow.

### Workers AI inference

```ts
const r = await env.AI.run("@cf/meta/llama-4-scout-17b-16e-instruct", {
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "..." }
  ],
  stream: true
});
return new Response(r, { headers: { "content-type": "text/event-stream" } });
```

The catalog churns weekly. **Don't hardcode model IDs in code without an env var indirection.** When a model is deprecated you want to swap with a deploy, not a code change.

For production: route Workers AI calls through **AI Gateway** as well, even for first-party Workers AI models — gives you cache, fallback, evals, and unified analytics.

### AI Gateway

```ts
const gateway = "https://gateway.ai.cloudflare.com/v1/<account>/<gateway>/openai";
const response = await fetch(`${gateway}/chat/completions`, {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${env.OPENAI_API_KEY}`,
    "content-type": "application/json"
  },
  body: JSON.stringify({ model: "gpt-4o", messages: [...] })
});
```

AI Gateway sits in front of any LLM provider. Features:
- **Cache** (configurable TTL, including semantic cache).
- **Fallback** chain across providers.
- **Rate limiting** per-gateway.
- **Guardrails** (prompt-injection detection, content classification).
- **Evals** + **logging** (every call captured).
- **BYOK** (managed keys, rotation).

For inbound from Workers: use the binding form (`env.AI_GATEWAY.run(...)`) or `fetch()` to the gateway URL. Both work; binding is cheaper and faster.

## Patterns and anti-patterns

### Pattern: bindings-first design

Before writing code, declare bindings in `wrangler.toml`. The bindings list **is** the architecture diagram for the Worker:

```toml
name = "orders-api"
main = "src/index.ts"
compatibility_date = "2026-05-01"
compatibility_flags = ["nodejs_compat_v2"]

[[d1_databases]]
binding = "DB"
database_name = "orders-prod"
database_id = "..."

[[kv_namespaces]]
binding = "SESSIONS"
id = "..."

[[r2_buckets]]
binding = "RECEIPTS"
bucket_name = "orders-receipts"

[[durable_objects.bindings]]
name = "ORDER"
class_name = "Order"

[[migrations]]
tag = "v1"
new_sqlite_classes = ["Order"]

[[queues.producers]]
binding = "FULFILLMENT_QUEUE"
queue = "fulfillment"

[[queues.consumers]]
queue = "fulfillment"
max_batch_size = 25
max_batch_timeout = 5

[[services]]
binding = "AUTH"
service = "auth-worker"
entrypoint = "AuthService"

[ai]
binding = "AI"

[[hyperdrive]]
binding = "ANALYTICS_PG"
id = "..."

[vars]
ENV = "production"

# Secrets are set via `wrangler secret put`, not in this file
```

Anti-pattern: dynamic discovery / configuration of "where does data live". Bindings are static; that's a feature.

### Pattern: handler thin, logic in modules, DB calls behind repos

```ts
// src/index.ts — thin handler
import { Hono } from "hono";
import { ordersRouter } from "./routes/orders";

const app = new Hono<{ Bindings: Env }>();
app.route("/orders", ordersRouter);

export default app;

// src/routes/orders.ts
import { Hono } from "hono";
import { OrderRepo } from "../repos/order";
import { createOrder, getOrder } from "../use-cases/orders";

export const ordersRouter = new Hono<{ Bindings: Env }>()
  .post("/", async (c) => {
    const repo = new OrderRepo(c.env.DB);
    const order = await createOrder(repo, await c.req.json());
    c.executionCtx.waitUntil(c.env.FULFILLMENT_QUEUE.send({ orderId: order.id }));
    return c.json(order, 201);
  })
  .get("/:id", async (c) => {
    const repo = new OrderRepo(c.env.DB);
    const order = await getOrder(repo, c.req.param("id"));
    if (!order) return c.notFound();
    return c.json(order);
  });
```

Anti-pattern: 800-line `fetch` handler with inline SQL, inline auth checks, inline business logic. Hard to test, hard to change, hard to review.

### Pattern: explicit `ctx.waitUntil` for background work

```ts
async fetch(req, env, ctx) {
  const response = await handle(req, env);
  ctx.waitUntil(logToAnalytics(req, response, env));
  return response;
}
```

The response is returned **before** `logToAnalytics` runs. The isolate stays alive until `waitUntil` resolves (up to 30s). **This is how you do "fire and forget" without breaking latency.**

Anti-pattern: `logToAnalytics(...)` (no `await`, no `waitUntil`). Promise gets garbage-collected when the response returns; the work never happens.

### Pattern: idempotency keys for everything externally-observable

A Worker can be retried (Queues retry, client retries, even the runtime can replay in some cases). Anything that touches an external system (charge a card, send an email, write to a DB without `INSERT OR REPLACE`) needs an idempotency strategy:

```ts
const idempotencyKey = req.headers.get("Idempotency-Key") ?? crypto.randomUUID();
const existing = await env.DB.prepare("SELECT * FROM payment_attempts WHERE idem_key=?").bind(idempotencyKey).first();
if (existing) return Response.json(existing.result);

const result = await stripe.charges.create({ ... }, { idempotencyKey });
await env.DB.prepare("INSERT INTO payment_attempts (idem_key, result) VALUES (?, ?)").bind(idempotencyKey, JSON.stringify(result)).run();
return Response.json(result);
```

### Pattern: hot-DO sharding

```ts
// Bad: every write goes through one DO
const id = env.COUNTER.idFromName("global-counter");

// Better: shard across N DOs, sum on read
const shard = Math.floor(Math.random() * 32);
const id = env.COUNTER.idFromName(`counter-shard-${shard}`);
```

Anti-pattern: centralizing high-throughput writes through one DO ID. The DO serializes; you'll bottleneck at the DO's CPU and the message dispatch rate.

### Pattern: streaming responses for long generations

```ts
async fetch(req, env) {
  const stream = await env.AI.run("@cf/meta/llama-4-...", { messages, stream: true });
  return new Response(stream, {
    headers: { "content-type": "text/event-stream", "cache-control": "no-store" }
  });
}
```

V8 isolates can stream out a response while still running. Wall-clock isn't bound by CPU time. This is what makes Workers a good fit for LLM-streaming APIs.

### Anti-pattern: in-memory cache as if it persists

```ts
// BROKEN — isolate can be recycled between requests
const cache = new Map();
async fetch(req, env) {
  const key = req.url;
  if (cache.has(key)) return cache.get(key);
  // ...
}
```

It "works" for a single isolate but breaks across the global fleet. Use the Cache API or KV:

```ts
async fetch(req, env, ctx) {
  const cache = caches.default;
  let res = await cache.match(req);
  if (res) return res;

  res = await origin(req);
  ctx.waitUntil(cache.put(req, res.clone()));
  return res;
}
```

### Anti-pattern: writing through KV under load

KV writes are eventually consistent and have per-key write rate limits (~1/sec/key). If a Worker increments a KV counter on every request, you'll hit rate limits at modest traffic. Use:
- **DO with SQL counter** if you need exact and ordered.
- **Rate Limiting binding** (`env.RATE_LIMIT.limit({ key })`) for rate-limit counters.
- **Analytics Engine** for high-volume append-only counters.

### Anti-pattern: subrequest fan-out in a loop

```ts
// BROKEN at 1000+ users
for (const user of users) {
  await fetch(`https://api/notify/${user.id}`);  // subrequest each
}
```

50 subrequest limit on free tier, 1000 on paid. At 1001 users you're done. Patterns:
- Push the users to a Queue, consume in batches.
- Use a Workflow with a per-user step (each step counts as its own invocation, gets its own budget).
- Batch into a single bulk endpoint if the destination supports it.

### Anti-pattern: blocking on `crypto` for big payloads

```ts
const hash = await crypto.subtle.digest("SHA-256", massiveArrayBuffer);  // CPU-bound, will hit limit
```

For big-payload hashing/encryption: stream through (chunk + incremental hash) or push the work to R2 (R2's server-side checksum) or to a Worker that's allowed more CPU (paid plan).

## Tooling specifics

### Project bootstrap

```bash
# C3 (create-cloudflare) is the official bootstrap
npm create cloudflare@latest -- my-worker --type=hello-world --ts --git --deploy=false
cd my-worker
```

For Hono/router projects:
```bash
npm create cloudflare@latest -- my-api --framework=hono
```

For Workers + Static Assets (new Pages alternative):
```bash
npm create cloudflare@latest -- my-site --framework=next-on-pages  # or astro, sveltekit, etc.
```

### Wrangler v4 essentials

```bash
# Local dev (Miniflare-based; full bindings emulation)
wrangler dev

# Local dev hitting real bindings (live D1, KV, R2 in prod)
wrangler dev --remote

# Generate TypeScript types from your bindings
wrangler types

# Deploy
wrangler deploy
wrangler deploy --env staging
wrangler deploy --dry-run --outdir=dist  # CI-friendly, builds without deploying

# Secrets
wrangler secret put OPENAI_API_KEY
echo $OPENAI_API_KEY | wrangler secret put OPENAI_API_KEY
wrangler secret bulk .secrets.json  # batch upload
wrangler secret list

# Logs
wrangler tail                          # live tail
wrangler tail --format=pretty
wrangler tail --status=error           # filter

# Database
wrangler d1 create my-db
wrangler d1 execute my-db --command="SELECT 1"
wrangler d1 migrations create my-db init
wrangler d1 migrations apply my-db
wrangler d1 migrations apply my-db --remote  # apply to prod
wrangler d1 export my-db --output backup.sql

# Vectorize
wrangler vectorize create my-index --dimensions=1024 --metric=cosine
wrangler vectorize create-metadata-index my-index --property-name=tenant_id --type=string

# R2
wrangler r2 bucket create my-bucket
wrangler r2 object put my-bucket/key --file=./file.txt

# KV
wrangler kv namespace create SESSIONS
wrangler kv key put --binding=SESSIONS my-key "value"

# Queues
wrangler queues create my-queue
wrangler queues consumer add my-queue my-worker
```

`wrangler publish` is **deprecated**; use `wrangler deploy`. The error message will tell you, but if you see code recommending `publish` — it's stale.

### TypeScript types

Run `wrangler types` after every `wrangler.toml` change. It writes `worker-configuration.d.ts` with the full `Env` interface populated from your bindings:

```ts
// worker-configuration.d.ts (generated)
interface Env {
  DB: D1Database;
  SESSIONS: KVNamespace;
  RECEIPTS: R2Bucket;
  ORDER: DurableObjectNamespace<Order>;
  FULFILLMENT_QUEUE: Queue;
  AUTH: Fetcher;          // service binding without WorkerEntrypoint
  // or: AUTH: Service<AuthService>;  if WorkerEntrypoint
  AI: Ai;
  HYPERDRIVE: Hyperdrive;
}
```

Commit this file or regenerate in CI. Either works; pick one and document.

### Testing: `@cloudflare/vitest-pool-workers`

```ts
// vitest.config.ts
import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.toml" }
      }
    }
  }
});

// src/orders.test.ts
import { describe, it, expect } from "vitest";
import { env, SELF } from "cloudflare:test";
import { createOrder } from "./orders";

describe("orders", () => {
  it("creates an order in D1", async () => {
    // Tests run against a real workerd runtime with all bindings working
    const order = await createOrder(env.DB, { ... });
    expect(order.id).toBeDefined();
  });

  it("end-to-end fetch handler", async () => {
    const res = await SELF.fetch("https://example.com/orders", { method: "POST", body: "..." });
    expect(res.status).toBe(201);
  });
});
```

This is the only testing primitive worth recommending. Don't mock `D1Database` or `R2Bucket` — they're complex enough that mocks lie. `vitest-pool-workers` runs your tests against actual workerd with bindings configured.

### Hono — the framework most teams should use

Hono is the de-facto router for Workers. Reasons:
- Web-standards-first (Request/Response, not Express idioms).
- Fast (minimal overhead on top of fetch handler).
- First-class TypeScript (typed env, typed params).
- Built-in middleware for auth, validation (zod), CORS, JWT.
- Adapters for Node, Bun, Deno if portability matters.

```ts
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";

const app = new Hono<{ Bindings: Env }>();

const createOrderSchema = z.object({
  items: z.array(z.object({ sku: z.string(), qty: z.number().int().positive() }))
});

app.post("/orders", zValidator("json", createOrderSchema), async (c) => {
  const body = c.req.valid("json");
  // ...
});

export default app;
```

Itty Router is an alternative for very lightweight cases; for anything that grows past a few routes, use Hono.

### MCP servers on Workers

Cloudflare ships an `agents/mcp` package for authoring MCP servers on Workers. Pattern (as of 2025-26, when authoring MCP servers for the broader ecosystem):

```ts
import { McpAgent } from "@cloudflare/workers-mcp";
// or import { McpAgent } from "agents/mcp"; depending on which library version you're on

export class MyMcp extends McpAgent {
  async listTools() {
    return [{ name: "lookup_user", description: "..." }];
  }

  async callTool(name: string, args: unknown) {
    if (name === "lookup_user") {
      return this.env.DB.prepare("SELECT * FROM users WHERE id=?").bind(args.id).first();
    }
  }
}

export default {
  fetch: MyMcp.serveSSE("/sse"),
}
```

Cloudflare also hosts an account-introspection MCP that the `cloudflare:cloudflare-mcp` skill in `delegate_to_skills` points to. When working on MCP-server authoring (vs MCP-server consumption), the Cloudflare Workers MCP starter and Workers Agents SDK are the references.

## Cross-references to products_covered

- **Workers Runtime** → handler types, bindings model, compat dates: see decision frameworks above; authoritative source [Workers runtime APIs](https://developers.cloudflare.com/workers/runtime-apis/).
- **Durable Objects** → SQLite, alarms, WebSockets, Hibernation: see "Durable Objects: SQLite by default" + "WebSockets + Hibernation API"; auth source [Durable Objects docs](https://developers.cloudflare.com/durable-objects/).
- **D1** → schema, Sessions API, migrations: see "D1 with Sessions API"; coordinate with `database-architect` overlay for index strategy and schema design; [D1 docs](https://developers.cloudflare.com/d1/).
- **Workflows** → durable execution: see "Workflows: durable execution"; [Workflows docs](https://developers.cloudflare.com/workflows/).
- **Queues** → batch consumption, retries, DLQ: see "Sync compute vs Workflows vs Queues vs DO Alarms"; [Queues docs](https://developers.cloudflare.com/queues/).
- **Hyperdrive** → Postgres/MySQL in front of Workers: see "Hyperdrive"; coordinate with `database-architect` for sizing; [Hyperdrive docs](https://developers.cloudflare.com/hyperdrive/).
- **Vectorize V2** → metadata indexes, namespaces: see "Vectorize V2"; coordinate with `ai-ml-engineer` overlay for retrieval design; [Vectorize docs](https://developers.cloudflare.com/vectorize/).
- **Workers AI / AI Gateway** → see "Workers AI inference" + "AI Gateway"; depth lives in `ai-ml-engineer.md`.
- **Workers Static Assets** → see "Static assets" decision framework; [Static Assets docs](https://developers.cloudflare.com/workers/static-assets/).
- **Workers RPC, Service Bindings** → see "Workers RPC and `WorkerEntrypoint`"; [RPC docs](https://developers.cloudflare.com/workers/runtime-apis/rpc/).

## Integration with always-on protocols

### TDD on Workers

The cycle is the same; the tooling is `@cloudflare/vitest-pool-workers`. Red-green-refactor against actual workerd.

- **Red:** write a failing test against `SELF.fetch(...)` or against an exported function with `env.DB` injected.
- **Green:** write the minimum handler/RPC method to pass.
- **Refactor:** extract logic into `src/use-cases/`, keep handlers thin.

Don't mock bindings. Use the real D1, KV, R2 from vitest-pool-workers — they reset per test (the pool gives you isolated namespaces) and they exercise the actual binding semantics.

### Verification protocol for backend-architect on Cloudflare

Before marking work complete:

- [ ] `wrangler types` regenerated and committed.
- [ ] Tests pass via `npm test` (vitest-pool-workers).
- [ ] `wrangler deploy --dry-run --outdir=dist` succeeds — catches bundling errors.
- [ ] CPU budget verified: hit the handler with realistic payload, check `wrangler tail` for CPU time (`event.cpuTime`).
- [ ] Subrequest count verified for typical request: no unbounded loops, no per-iteration fetches.
- [ ] Compatibility date is set to a recent value (within the last 90 days), or pinned with rationale.
- [ ] `nodejs_compat_v2` flag is set if any code imports `node:*` modules.
- [ ] DO migrations have `new_sqlite_classes` (not the legacy `new_classes`) for new DO classes.
- [ ] D1 migrations are idempotent (re-running them is safe).
- [ ] Workers Logs are configured (`observability.logs.enabled = true` in wrangler.toml) so production has queryable logs.

### Debugging on Workers

When a Worker misbehaves in production:

1. **`wrangler tail`** for live logs — most issues surface here.
2. **Workers Logs** for after-the-fact querying (filter by request ID, status, etc.).
3. **Error events** — wrap your handler with a top-level try/catch that logs and re-throws; alternatively use the [Tail Worker](https://developers.cloudflare.com/workers/observability/logs/tail-workers/) pattern.
4. **`wrangler dev --remote`** to reproduce against production-like bindings without deploying.
5. **`@cloudflare/vitest-pool-workers`** to write a regression test against the reproduced state.

Common failure modes:
- **"CPU time exceeded"** → tail will show it; profile, push CPU work to Workers AI / R2 transformations / containers / batch.
- **"subrequest limit exceeded"** → tail will show it; refactor to batch or Queues.
- **"Durable Object overloaded"** → DO is bottlenecking; shard or move state out.
- **"D1_ERROR"** → check D1 dashboard for query errors; the Sessions API for stale reads.
- **"Hyperdrive ECONNREFUSED"** → check Hyperdrive config matches your DB; check Tunnel if private.
- **Cold-start spikes** → almost always Wasm modules or large dependencies; check bundle size with `wrangler deploy --dry-run --outdir=dist` and inspect.

### Escalation paths from backend-architect on Cloudflare

- **Topology / "should this be one Worker or three?"** → `system-architect` overlay for Cloudflare.
- **Workers CI/CD, multi-env config, secret rotation, branch deploys, IaC** → `devops-engineer` overlay.
- **D1 schema, indexes, migrations strategy, Hyperdrive sizing** → `database-architect` overlay.
- **Model selection, prompt patterns, AI Gateway tuning, Vectorize index design** → `ai-ml-engineer` overlay.
- **WAF rules, Access policies, Tunnel, mTLS, Turnstile** → `security-engineer` overlay.

## Advanced patterns

### Pattern: per-Worker `WorkerEntrypoint` for clean public APIs

Instead of `fetch` returning JSON, expose a typed RPC surface:

```ts
import { WorkerEntrypoint } from "cloudflare:workers";

export class OrdersService extends WorkerEntrypoint<Env> {
  async createOrder(input: CreateOrderInput): Promise<Order> {
    return createOrder(new OrderRepo(this.env.DB), input);
  }

  async getOrder(id: string): Promise<Order | null> {
    return new OrderRepo(this.env.DB).get(id);
  }

  async listForUser(userId: string, opts: ListOpts): Promise<Order[]> {
    return new OrderRepo(this.env.DB).listForUser(userId, opts);
  }
}

// Default export still handles HTTP — for browsers / external callers
export default {
  async fetch(req, env, ctx) {
    return app.fetch(req, env, ctx);
  }
}
```

Other Workers in your account call `OrdersService` via RPC bindings. External callers hit the HTTP routes. **Same service, two surfaces** — RPC for internal type-safety, HTTP for external. The class is the source of truth.

### Pattern: WebSocket message queueing for slow handlers

```ts
export class Chat extends DurableObject {
  // ...
  async webSocketMessage(ws, message) {
    // Don't await heavy work in-line — it blocks other messages
    this.state.waitUntil(this.processMessage(ws, message));
  }

  private async processMessage(ws, message) {
    const parsed = JSON.parse(message as string);
    // ... possibly call external APIs, persist to D1, etc.
    ws.send(JSON.stringify({ ack: parsed.id }));
  }
}
```

`state.waitUntil` extends the DO's lifetime for that piece of work. The handler returns immediately; the DO continues processing.

### Pattern: graceful degradation across bindings

```ts
async function summarize(text: string, env: Env): Promise<string> {
  try {
    return await env.AI.run(env.LLM_MODEL, { messages: [{ role: "user", content: `Summarize: ${text}` }] });
  } catch (e) {
    console.error({ event: "ai_fail", error: e });
    // Fallback: return first 200 chars
    return text.slice(0, 200) + "...";
  }
}
```

When a binding fails (AI offline, D1 region down, KV slow), have a fallback. The system should degrade gracefully, not crash globally.

### Pattern: Workflow as the seam for external orchestrators

If you need to integrate Cloudflare with Temporal / AWS Step Functions / GCP Workflows:

- Wrap each Cloudflare-side operation as a Workflow.
- Expose Workflow's `instances.create` as your contract.
- External orchestrator triggers Workflow instances by ID; queries status; subscribes to events.

You can build complex distributed orchestration where Cloudflare handles a slice and an external system handles another, with Workflows as the durable boundary.

### Pattern: per-route compatibility flags

```toml
# wrangler.toml
compatibility_date = "2026-05-01"
compatibility_flags = ["nodejs_compat_v2"]

[env.staging]
compatibility_date = "2026-05-14"   # bleeding-edge in staging
```

Staging can test future compatibility dates ahead of prod. Catch breaking changes before they hit users.

### Pattern: SignalRoom DO for distributed coordination

When you need a "lobby" or "coordination point" that's not naturally owned by an entity:

```ts
const id = env.SIGNAL_ROOM.idFromName(`feature-flag-broadcasts`);
const room = env.SIGNAL_ROOM.get(id);
await room.broadcast({ flag: "new-checkout", value: true });
```

Every consumer Worker has a WebSocket to this DO; flag changes broadcast in milliseconds. **Beats polling KV.**

## Standing rules for backend-architect on a Cloudflare engagement

1. **The bindings list in `wrangler.toml` is the source of truth for where state lives.** Don't write code that reaches for state not declared in bindings.
2. **`compatibility_date` is part of the design.** Set it, don't bump it casually, and document the rationale on changes.
3. **Use RPC for inter-Worker calls.** `WorkerEntrypoint` and method invocation, not `env.X.fetch(request)`.
4. **DO is for serialized writes per entity; not a general key-value store.** Match the primitive to the access pattern.
5. **Pages is in maintenance; recommend Workers Static Assets for new projects.**
6. **Every async call out has a budget.** Plan subrequest count per request before writing the loop.
7. **Stream responses for LLM and large payload handlers.** Don't buffer.
8. **Test with `vitest-pool-workers` against real workerd**; don't mock bindings.
9. **Wrangler v4 commands only.** `deploy`, not `publish`. `tail`, not legacy tail. `types`, not hand-written.
10. **AI calls go through AI Gateway** even when the model is Workers AI — for cache, fallback, eval, analytics.
