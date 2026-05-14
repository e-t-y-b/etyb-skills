---
role: backend-architect
stack: supabase
last_verified_on: "2026-05-14"
---

# Supabase Overlay — backend-architect

You are backend-architect on a Supabase engagement. Your surface is everything between the database and the client: **Edge Functions (Deno)**, **server-side `supabase-js`**, **Database Functions** (when SQL is the right home), the **Realtime fan-out plane**, the **Queues + Cron orchestration plane**, and the **connection-pooling decisions** that determine whether your service has stable production behavior. The database schema and RLS belong to database-architect; auth hardening belongs to security-engineer; the client wiring belongs to frontend-architect. Your job is to make the server-side code correct, fast, and operationally sound.

**Currency:** verified against Supabase docs + `supabase-js` v2.x reference + Edge Functions runtime notes through **2026-05-14**. Deno is the Edge Functions runtime; npm-spec imports are stable; background tasks (`EdgeRuntime.waitUntil`) and ephemeral storage are GA.

## What this overlay is for

When ETYB routes backend work into Supabase, you make these calls:

- Edge Function vs Database Function vs external service (Lambda/Cloudflare Worker).
- `supabase-js` with anon key (RLS-bound) vs service role (RLS-bypass).
- Transaction pooler vs session pooler vs direct connection for any given workload.
- Postgres Changes vs Broadcast vs Presence for any given real-time need.
- Database Webhook vs Queue + worker for any "DB event → external" path.
- ORM choice + pooler compatibility (Prisma/Drizzle/Kysely/postgres-js).

The rest of this overlay is your playbook for each.

## Edge Functions — Deno runtime, 2026 idioms

Edge Functions live in `supabase/functions/<name>/index.ts`. They run on Supabase's globally distributed Deno-based runtime. Source: [Edge Functions docs](https://supabase.com/docs/guides/functions).

### Canonical function shape

```ts
// supabase/functions/hello/index.ts
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  // 1. Build a client scoped to the caller's JWT (so RLS applies).
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      auth: { persistSession: false },
    },
  );

  // 2. Do work — every query goes through RLS as the caller.
  const { data, error } = await supabase.from("orders").select("*").limit(10);
  if (error) return new Response(error.message, { status: 400 });

  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" },
  });
});
```

The five rules baked into this shape:

1. **Use `Deno.serve`** — the modern entrypoint. Older `import { serve } from "std/http/server.ts"` is deprecated.
2. **JSR specifier for `supabase-js`** (`jsr:@supabase/supabase-js@2`) — preferred over `https://esm.sh/...` URLs because JSR resolves faster and is the recommended distribution as of 2025.
3. **Forward the caller's `Authorization` header** so RLS evaluates against the actual user. Without this, the Edge Function operates as anonymous.
4. **`persistSession: false`** — Edge Functions are stateless; don't try to maintain auth state.
5. **Return a `Response`** — Edge Functions are pure HTTP handlers.

### When to use service role (and when not to)

```ts
const adminClient = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, // bypasses RLS
  { auth: { persistSession: false } },
);
```

Service role bypasses RLS entirely. Use it when:
- The operation is *intentionally* admin-scoped: provisioning a new tenant, processing a webhook from Stripe that needs to mutate another user's data, sending password resets.
- You've validated the request authority *yourself* before constructing the admin client (e.g., the Edge Function verifies a Stripe webhook signature before doing anything).

Do **not** use service role when:
- The caller is a regular authenticated user. They should hit RLS-bound endpoints.
- You're trying to "just get past" an RLS issue. The RLS issue is the design fault — fix it.
- The data flow is "user asks for X, we give them X with admin privileges." Almost always wrong.

Anti-pattern (catastrophic): forwarding the caller's intent to a service-role client without re-authorizing:

```ts
// DON'T:
const userId = await getUserFromJwt(req); // OK so far
const target = req.url.searchParams.get("target_user_id"); // SUPPLIED BY CALLER
await adminClient.from("private_data").select("*").eq("user_id", target); // CATASTROPHE
```

The caller chose `target_user_id`; the admin client gave them anyone's data. RLS would have caught this; you opted out.

### Background tasks (`EdgeRuntime.waitUntil`)

For "respond fast, finish work after" patterns:

```ts
Deno.serve(async (req: Request) => {
  const body = await req.json();

  // Queue async work; response goes out immediately.
  EdgeRuntime.waitUntil((async () => {
    await sendEmailViaSendgrid(body);
    await logToAnalytics(body);
  })());

  return new Response("queued", { status: 202 });
});
```

Use for: notifications, analytics, non-critical side effects. Don't use for: anything the user needs confirmation of (use a Queue + dedicated worker function for that).

Limits: background tasks are best-effort and bounded by the function's overall execution budget (typically 30-60s on Pro plans, longer on Team/Enterprise). Don't try to run a 5-minute task this way.

### Ephemeral storage

```ts
const tempPath = await Deno.makeTempFile();
await Deno.writeTextFile(tempPath, csvContents);
// ...process file...
await Deno.remove(tempPath);
```

Files written under `/tmp` (or via `Deno.makeTempFile()`) live only for the duration of the invocation. Use for: CSV processing, PDF generation, image manipulation. Don't use for: persistence across requests (use Storage or Postgres).

### Cold-start hygiene

Cold-start is dominated by module loading. To minimize:

- **Keep functions small.** Each function is a separate cold-start surface. A monolithic function isn't better; it's just one big slow start.
- **Prefer JSR + std for stdlib stuff.** `jsr:@std/...` packages are tree-shaken efficiently.
- **Pin npm versions.** `npm:stripe@14.5.0`, not `npm:stripe@latest`. Floating versions blow the cache.
- **Avoid synchronous I/O at module scope.** Imports are awaited at cold-start; if a module's top-level fetches a config, that's added to your cold-start.
- **Warm the latency-critical functions.** A Supabase Cron entry that pings the function every 5 minutes keeps a warm instance around in each region. Cost is minimal.

### Regional invocation

Edge Functions run in every region. The runtime picks the closest. If you need pinned-region behavior (e.g., data residency), use the `--region` flag at deploy or pin via project-level settings. For most apps, let the runtime decide.

### Logging

`console.log` in an Edge Function writes to the project's Logs Explorer. Structure your logs:

```ts
console.log(JSON.stringify({
  level: "info",
  function: "process-order",
  order_id: orderId,
  duration_ms: durationMs,
}));
```

Structured JSON is parseable in Logs Explorer's filter. Free-text logs are nearly worse than nothing at scale.

### Secrets

Set via `supabase secrets set MY_KEY=value` (or the dashboard). Access via `Deno.env.get("MY_KEY")`. Never commit secrets to the function code; never read from `vault.secrets` over the wire for every invocation (read once at module scope if you must, but prefer env secrets for app-tier).

## Database Functions vs Edge Functions

The decision matrix:

| Use a **Database Function** when | Use an **Edge Function** when |
|----------------------------------|-------------------------------|
| The work is set-based SQL | The work calls external APIs |
| You want transactional guarantees with surrounding DML | You need npm packages or Deno-style imports |
| You'll expose it via `select * from rpc_my_function(...)` from `supabase-js` | The work is webhook-triggered (Stripe, Slack, GitHub) |
| The function is a **trigger** | The work is request-response with HTTP semantics |
| You want to chain it from `pg_cron` | You need streaming responses, server-sent events |
| Performance matters (no network hop) | You need access to `EdgeRuntime.waitUntil` |

### Database Function — RPC pattern

```sql
create or replace function public.create_order_with_items(
  p_user_id uuid,
  p_items jsonb
)
returns table(order_id uuid, total numeric)
language plpgsql
security invoker -- runs as the caller, respects RLS
set search_path = ''
as $$
declare
  v_order_id uuid;
  v_total numeric := 0;
  v_item jsonb;
begin
  insert into public.orders (user_id, status)
  values (p_user_id, 'pending')
  returning id into v_order_id;

  for v_item in select jsonb_array_elements(p_items) loop
    insert into public.order_items (order_id, product_id, qty, price)
    values (
      v_order_id,
      (v_item->>'product_id')::uuid,
      (v_item->>'qty')::int,
      (v_item->>'price')::numeric
    );
    v_total := v_total + ((v_item->>'qty')::int * (v_item->>'price')::numeric);
  end loop;

  update public.orders set total = v_total where id = v_order_id;
  return query select v_order_id, v_total;
end;
$$;

-- Expose to PostgREST via grant:
grant execute on function public.create_order_with_items(uuid, jsonb) to authenticated;
```

Call from `supabase-js`:

```ts
const { data, error } = await supabase.rpc("create_order_with_items", {
  p_user_id: user.id,
  p_items: items,
});
```

Use `security invoker` (the default) so RLS applies to the inserted rows the same as if the user inserted them directly. Use `security definer` only when you need to perform operations the user can't (e.g., reading from a privileged table to validate something) — and always with `set search_path = ''` (see security overlay).

### Trigger functions

See database-architect overlay for the canonical pattern. Backend-architect's concern: never call `pg_net` synchronously from a trigger (it serializes the transaction on an HTTP roundtrip). Either rely on Database Webhooks (which `pg_net` async) or push the side effect to a Queue.

## supabase-js v2 (and v3 transition)

Source: [supabase-js reference](https://supabase.com/docs/reference/javascript). v2 is stable through 2026; v3 is stabilizing through Q1-Q2 2026 with auth client splits and improved type inference. The query builder shape is stable across both.

### Two clients, two purposes

```ts
// Anon client — RLS-bound, safe for browsers + caller-scoped server use.
const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Admin client — service role, bypasses RLS, NEVER ship to browser.
const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
```

In Edge Functions, browser, mobile, anywhere the user is the principal — anon client + forward the user's JWT. In server-side admin paths (cron jobs, webhook handlers, migration scripts) — admin client.

### Query patterns

```ts
// SELECT with filters + relationships
const { data, error } = await supabase
  .from("orders")
  .select(`
    id,
    total,
    user:user_id (id, email),
    items:order_items (product_id, qty, price)
  `)
  .eq("status", "pending")
  .gte("created_at", lastWeek)
  .order("created_at", { ascending: false })
  .limit(50);
```

Things worth knowing:
- **Relationship syntax** (`user:user_id (id, email)`) joins via FK. The FK must exist in the schema; supabase-js doesn't infer joins from naming.
- **`select("*", { count: "exact" })`** returns the total count alongside the rows. Costs an extra query (head + count).
- **`.maybeSingle()`** vs **`.single()`** — `.single()` errors if 0 or >1 rows; `.maybeSingle()` returns null for 0 rows. Pick deliberately.
- **`.throwOnError()`** — chain to throw instead of returning an `error`. Good for cases where you'd just `if (error) throw error` anyway.

### Inserts and upserts

```ts
const { data, error } = await supabase
  .from("orders")
  .insert({ user_id: userId, total: 100 })
  .select() // return the inserted row
  .single();

// Upsert
const { data, error } = await supabase
  .from("user_preferences")
  .upsert({ user_id: userId, theme: "dark" }, { onConflict: "user_id" })
  .select()
  .single();
```

`onConflict` references the unique constraint name or column list. The column list version is more readable but requires the constraint to exist.

### RPC (calling a Database Function)

```ts
const { data, error } = await supabase.rpc("create_order_with_items", {
  p_user_id: userId,
  p_items: items,
});
```

RPC respects RLS through the underlying function's `security invoker` / `security definer` declaration. Don't expect supabase-js to do anything magic — it's a thin wrapper around PostgREST.

### Generated types

```bash
supabase gen types typescript --linked > types/database.ts
```

Then:

```ts
import type { Database } from "./types/database";
const supabase = createClient<Database>(URL, KEY);

// Now selects and inserts are fully typed against the live schema.
```

Wire this into a `predev` script and a CI check; type drift is a real bug source.

### Cookie-based auth on server-side (Next.js, SvelteKit, Remix)

See [frontend-architect overlay](frontend-architect.md) for the full `@supabase/ssr` setup. From a backend perspective: in any server-side request handler, the client *must* read/write cookies for session refresh to work. The pattern:

```ts
// Next.js route handler
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function POST(request: Request) {
  const cookieStore = await cookies();
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookies) => cookies.forEach((c) => cookieStore.set(c.name, c.value, c.options)),
      },
    },
  );
  // ... use supabase ...
}
```

The middleware path is more involved; see the frontend overlay for the canonical Next.js / SvelteKit / Remix wiring.

## ORM selection on Supabase

ORM compatibility with Supavisor transaction mode is where most teams trip. As of 2026:

| ORM | Transaction pooler compatibility | Notes |
|-----|----------------------------------|-------|
| **`supabase-js` (PostgREST)** | N/A — it's HTTP | The default. Use this unless you have a reason not to. Works with RLS naturally. |
| **postgres-js** | Yes — set `prepare: false` | Tied for fastest pure-PG client; the recommended raw-SQL choice for Edge Functions. |
| **node-postgres (`pg`)** | Yes — set `prepare: false`, use `pg-pool` carefully | Works but feel less elegant than postgres-js. |
| **Drizzle** | Yes — pick the postgres-js driver and pass `prepare: false` | Type-safe SQL builder; works well with the Supabase generated types if you migrate them. |
| **Prisma** | Yes — append `?pgbouncer=true&connection_limit=1` to the URL | The connection_limit=1 is the gotcha — Prisma's internal pool conflicts with Supavisor's pool. |
| **Kysely** | Yes — pick a postgres-js dialect, `prepare: false` | Lightweight; works well with generated types. |
| **TypeORM** | Yes with extra care — `prepareStatements: false` | Heavier; less common on Supabase. |

**The general rule**: if your code path is browser-or-Edge-Function and you have RLS on, **use `supabase-js`**. It speaks PostgREST, handles auth tokens, respects RLS, and integrates with Realtime / Storage. Reach for a raw ORM only when:
- You need to write SQL that PostgREST can't express (complex CTEs, window functions, certain joins).
- You're on a long-running Node/Bun/Edge server with its own connection budget.
- You're building a migration tool or CLI.

When you do reach for an ORM, route through **session pooler** for long-lived servers, **transaction pooler with `prepare: false`** for serverless.

## Realtime — Postgres Changes vs Broadcast vs Presence

Three primitives with different cost profiles and consistency models.

### Postgres Changes — real CDC

```ts
const channel = supabase
  .channel("orders-changes")
  .on(
    "postgres_changes",
    { event: "INSERT", schema: "public", table: "orders" },
    (payload) => console.log("new order:", payload.new),
  )
  .subscribe();
```

Properties:
- Driven by Postgres logical replication.
- Every replicated row passes through the Realtime worker.
- Respects RLS on the Realtime authorization config (since 2024).
- **Cost scales with table write rate, not with subscriber count for a given table** — every write costs once; subscribers split that cost.
- Latency: typically <100ms but no SLA.

Use for: dashboards reflecting DB state, live tables, "see new rows as they come in" UX.

Don't use for: high-write tables that don't need real-time UI exposure (audit logs, telemetry). The cost is wasted.

### Broadcast — pub/sub, app-defined messages

```ts
// Publisher (Edge Function or client):
const channel = supabase.channel("game-room-42");
await channel.send({
  type: "broadcast",
  event: "move",
  payload: { player: "alice", from: "e2", to: "e4" },
});

// Subscriber:
channel.on("broadcast", { event: "move" }, ({ payload }) => {
  applyMove(payload);
});
channel.subscribe();
```

Properties:
- App publishes explicit events. No coupling to DB writes.
- **Realtime Authorization** (since 2024) — RLS-like policies on `realtime.messages` decide who can read what.
- Cost scales with message count + subscriber count.
- Best for game state, chat, presence-driven UI.

Pattern: use a Postgres trigger to call `supabase_realtime.send()` (the broadcast API from inside Postgres) for "DB write → app event." Cleaner than Postgres Changes for app-level semantics:

```sql
create or replace function public.broadcast_order_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('order_id', new.id, 'status', new.status),
    'order_updated',
    'org:' || new.org_id::text -- channel/topic
  );
  return new;
end;
$$;

create trigger orders_broadcast_on_update
  after update of status on public.orders
  for each row execute function public.broadcast_order_update();
```

### Presence — who's online

```ts
const channel = supabase.channel("room-42", {
  config: { presence: { key: userId } },
});
channel.on("presence", { event: "sync" }, () => {
  const state = channel.presenceState();
  // { userId1: [{...}], userId2: [{...}] }
});
channel.subscribe(async (status) => {
  if (status === "SUBSCRIBED") {
    await channel.track({ user: userId, cursor: { x: 0, y: 0 } });
  }
});
```

For collaborative cursors, online indicators, live counts. Presence is reconciled across subscribers; you write a state, it's broadcast to everyone on the channel.

Use for: collaboration UI (cursors, presence indicators), live counts ("3 people viewing this").

### Decision: Postgres Changes vs Broadcast

If the source-of-truth event is a DB row change AND the consumer needs the full row, use Postgres Changes. If the source is an app event OR you can shape a smaller payload, use Broadcast. Defaulting to Broadcast is correct in most apps; default-to-Postgres-Changes is correct for true CDC dashboards.

## Queues + Cron — orchestration patterns

### Cron — scheduled work

Supabase Cron is `pg_cron` wrapped in a dashboard UI with auth-bound auditability. Two flavors:

```sql
-- Pure SQL job:
select cron.schedule(
  'cleanup-stale-sessions',
  '0 * * * *', -- every hour
  $$ delete from public.sessions where expires_at < now() $$
);

-- Edge Function invocation:
select cron.schedule(
  'process-queue-orders',
  '*/1 * * * *', -- every minute
  $$
    select net.http_post(
      url := 'https://<project>.supabase.co/functions/v1/process-queue',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('supabase.functions.invoke_key')
      ),
      body := '{}'::jsonb
    )
  $$
);
```

Patterns:
- **Hourly housekeeping** (cleanup, retention) — pure SQL job.
- **Worker poll** (drain a queue) — Edge Function invocation every N seconds/minutes.
- **Scheduled exports** — Edge Function that runs a query, builds a CSV, uploads to Storage.

Don't:
- Schedule a job for every second (pg_cron's minimum is once per minute via standard cron, though Supabase Cron may offer sub-minute via dashboard). For sub-second, use Realtime/Queues.
- Hard-code service-role keys into job bodies. Use `current_setting` or Vault.

### Queues — async work with retries

Supabase Queues (2025, managed `pgmq`). Operations covered in [database-architect overlay](database-architect.md). The backend pattern:

```ts
// supabase/functions/process-orders/index.ts
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async () => {
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Read up to 10 messages, with 60s visibility timeout
  const { data: messages, error } = await admin.rpc("pgmq_read", {
    queue_name: "order_processing",
    vt: 60,
    qty: 10,
  });
  if (error || !messages?.length) return new Response("nothing to do");

  for (const msg of messages) {
    try {
      await processOrder(msg.message);
      await admin.rpc("pgmq_archive", { queue_name: "order_processing", msg_id: msg.msg_id });
    } catch (err) {
      // Let visibility timeout expire; pgmq will re-deliver.
      // After N retries (track read_ct), move to DLQ:
      if (msg.read_ct >= 5) {
        await admin.rpc("pgmq_send", {
          queue_name: "order_processing_dlq",
          msg: { original: msg.message, error: err.message },
        });
        await admin.rpc("pgmq_delete", { queue_name: "order_processing", msg_id: msg.msg_id });
      }
    }
  }
  return new Response(`processed ${messages.length}`);
});
```

Schedule this with Cron every minute (or as fast as your throughput needs).

### Database Webhooks — when they're OK

Use for fire-and-forget side effects:
- Slack/Discord notification on a row change.
- Sync to a third-party analytics tool.
- Trigger a CI job on a deploy row.

Don't use for:
- Payment settlement.
- Cross-system state machines.
- Anything where you need retry semantics.

For those, use a Queue + worker.

## HTTP API design — PostgREST is your API by default

Supabase exposes every table + RPC function via **PostgREST** at `https://<project>.supabase.co/rest/v1/<table>`. This is a free API. You don't have to build a Node server to talk to your DB.

The implications:

- **Schema design IS API design.** Every table is an endpoint. Column names are field names. Views are read-only resources.
- **RLS is your authorization.** Authentication is the JWT; authorization is RLS.
- **Stored procedures (`security definer` functions) are your "POST /verb" actions.** Call via `supabase.rpc(...)`.

When PostgREST is not enough:
- Complex multi-step orchestration (use an Edge Function).
- Streaming responses / SSE / WebSocket (use an Edge Function or Realtime).
- Non-Postgres data sources (use an Edge Function calling out).
- Custom URL routing / multi-tenancy via subdomains (handle at the CDN / Vercel layer; the Supabase API itself is project-scoped).

The mistake is reflexively building a Node API in front of Supabase "to have a backend." If your data flow is CRUD + auth + RLS, PostgREST is the right answer. Build a thin Edge Function layer only where PostgREST is insufficient.

## GraphQL via pg_graphql — when to use it

`pg_graphql` auto-generates a GraphQL endpoint from your schema. It exists; it works; it's rarely the right primary API choice because:

- The default-generated schema follows the DB shape, which is rarely the shape clients want.
- Authorization (RLS) is more naturally expressed against table+row, not against a graph.
- Edge Functions + REST give you finer control.

Where it shines:
- Public-facing GraphQL endpoints (you're a content platform with a GraphQL spec).
- LLM/agent use cases where the introspective schema is a useful affordance.

Where it doesn't:
- Internal app APIs (use PostgREST or Edge Functions).
- Complex authorization rules that don't map to RLS.

## Connection pooling — when each mode bites you

Recap from the database-architect overlay, restated for backend code:

### Transaction pooler (`:6543`) — your default

For everything serverless / Edge / Lambda / Cloudflare Workers. Constraints:

- No prepared statements unless ORM config disables them.
- No long-running transactions across statements.
- No session-level state (`SET`, advisory locks, `LISTEN`).

ORM checklists:

| ORM | Required config for transaction pooler |
|-----|----------------------------------------|
| postgres-js | `postgres(url, { prepare: false })` |
| pg | `new Client({ ..., statement_timeout: 5000 })` + don't call `client.prepare()` |
| Prisma | URL: `?pgbouncer=true&connection_limit=1` |
| Drizzle (postgres-js) | Inherits from postgres-js — `prepare: false` |
| Kysely (postgres-js dialect) | Same — `prepare: false` |
| supabase-js | N/A — uses PostgREST over HTTPS |

### Session pooler

For migrations, ETL jobs, anything that needs session state. Use the pooler hostname with port 5432.

### Direct connection (no pooler)

For Studio, replication tools, debug `psql`. Connection budget is small (typically 60-200 depending on project size) — keep direct connections short-lived.

## Storage — backend patterns

Storage is `storage.objects` (rows) backed by S3-compatible object storage. Source: [Storage docs](https://supabase.com/docs/guides/storage).

### Uploading from an Edge Function

```ts
const file = await req.arrayBuffer();
const { data, error } = await adminClient.storage
  .from("invoices")
  .upload(`org-123/2026-05-invoice.pdf`, new Uint8Array(file), {
    contentType: "application/pdf",
    upsert: false,
  });
```

### Signed URLs

For "generate a temporary download link":

```ts
const { data, error } = await supabase.storage
  .from("invoices")
  .createSignedUrl("org-123/2026-05-invoice.pdf", 3600); // 1 hour
```

Use for: serving private files to authenticated users without proxying through your function.

### Resumable uploads (TUS)

For files >50MB, use the TUS protocol. `supabase-js` v2 supports `uploadToSignedUrl` for chunked uploads; the resumable surface is wired through the Storage REST API.

### Storage RLS — non-negotiable

See [security-engineer overlay](security-engineer.md). Storage policies live on `storage.objects` and follow the same RLS rules as any other table. Forgetting them = world-readable buckets.

## Cross-references

- **Schema, RLS, indexes, migrations, pooler config** → [database-architect overlay](database-architect.md)
- **`@supabase/ssr` cookie wiring + client-side query builder** → [frontend-architect overlay](frontend-architect.md)
- **RLS as security primitive + service-role discipline + Vault** → [security-engineer overlay](security-engineer.md)
- **pgvector + Edge Function AI patterns** → [ai-ml-engineer overlay](ai-ml-engineer.md)
- **Multi-tenancy + billing via Stripe FDW** → [saas-architect overlay](saas-architect.md)

## Integration with always-on protocols

### TDD on Edge Functions

`deno test` against a local Supabase instance:

```ts
// supabase/functions/_tests/process-order.test.ts
import { assertEquals } from "jsr:@std/assert";

Deno.test("process-order returns 400 on missing user", async () => {
  const res = await fetch("http://localhost:54321/functions/v1/process-order", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });
  assertEquals(res.status, 400);
});
```

```bash
supabase start
supabase functions serve --no-verify-jwt
deno test --allow-net supabase/functions/_tests/
```

CI: spin up a Supabase service container, run migrations, deploy functions to local, run `deno test`.

### TDD on Database Functions

Use `pgTAP`-style tests in `tests/db/*.sql`. Run via `psql -f` against `supabase start`.

### Verification

Every Edge Function change ships with:
- The `deno test` pass on the local instance.
- A successful test deploy to a preview branch.
- An `EXPLAIN ANALYZE` for any DB query the function executes.

Don't claim "the function works" because the dashboard returned 200 — assert the side effects (row written, message enqueued, email sent in the test inbox).

### Debugging

Symptom: "the Edge Function returns 401 for authenticated users."
- 90% of the time: the `Authorization` header is not being forwarded into the supabase-js client constructor. Confirm with `console.log(req.headers.get("Authorization"))`.
- 5%: the JWT is expired (client didn't refresh). Confirm with the JWT's `exp` claim.
- 5%: the function is checked into a region where the JWT was issued for a different project. Confirm the `aud` claim.

Symptom: "writes from the function succeed but queries return empty."
- The function is constructed with the *anon* key but no `Authorization` header forwarded — so it queries as anonymous, which RLS blocks.

Symptom: "intermittent `prepared statement \"xxx\" does not exist`."
- The function uses an ORM that issues prepared statements over the transaction pooler. Fix the ORM config (`prepare: false`).
