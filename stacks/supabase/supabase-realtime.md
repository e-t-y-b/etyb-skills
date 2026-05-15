---
title: Supabase Realtime
description: Three primitives — Postgres Changes, Broadcast, Presence. As of 2024, Realtime Authorization applies RLS-style policies to Broadcast/Presence.
product:
  name: Supabase Realtime
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect, security-engineer]
  authoritative_url: https://supabase.com/docs/guides/realtime
  notes: "Realtime Authorization for Broadcast + Presence (2024) replaced the listen-everything model. Postgres Changes vs Broadcast tradeoffs shifted accordingly."
---

## What it is

Supabase Realtime is a WebSocket service that delivers three kinds of events:

- **Postgres Changes** — CDC stream driven by Postgres logical replication. RLS-aware.
- **Broadcast** — app-defined pub/sub messages on named channels. Realtime Authorization gates who can read/write.
- **Presence** — eventually-consistent reconciled state across subscribers ("who's online").

Source: [Realtime docs](https://supabase.com/docs/guides/realtime).

## When to use

| Need | Use |
|------|-----|
| Reflect DB state changes in UI (live tables, dashboards) | **Postgres Changes** |
| Send app-level events (game moves, chat, "X is typing") | **Broadcast** |
| Show who's online / collaborative cursors / live counts | **Presence** |
| High-write CDC for analytics | **Neither** — use a dedicated CDC pipeline (Debezium → Kafka) |

**Default to Broadcast** for app-level semantics. Reserve Postgres Changes for true CDC dashboards where you genuinely need every row.

## 2025-2026 currency anchors

- **Realtime Authorization** (2024) — Broadcast and Presence channels now respect RLS-style policies on `realtime.messages`. The old "anyone on the channel sees everything" model is **wrong** for any production app touching customer data.
- **`realtime.send()` from inside Postgres** — call from a trigger to publish an app event without the round-trip through an Edge Function. The cleanest "DB write → app event" pattern.
- **Postgres Changes respects table RLS** as the subscribing user.
- **Cost shape**: Postgres Changes scales with table write rate (every replicated row passes through Realtime). Broadcast scales with message count × subscribers. Presence scales with active members on a channel.

## Patterns and anti-patterns

### Patterns

**Broadcast from a trigger** for clean "DB write → app event":

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
    'org:' || new.org_id::text  -- channel/topic
  );
  return new;
end;
$$;

create trigger orders_broadcast_on_update
  after update of status on public.orders
  for each row execute function public.broadcast_order_update();
```

**Realtime Authorization policy on `realtime.messages`:**

```sql
create policy "receive org broadcasts" on realtime.messages
  for select using (
    (select auth.role()) = 'authenticated'
    and substring(realtime.topic() from '^org:(.+)') in (
      select org_id::text from public.memberships
      where user_id = (select auth.uid())
    )
  );
```

**Postgres Changes — always use server-side filters:**

```ts
const channel = supabase
  .channel("orders-changes")
  .on(
    "postgres_changes",
    { event: "*", schema: "public", table: "orders", filter: `user_id=eq.${userId}` },
    handler,
  )
  .subscribe();
```

Without `filter`, every row change passes to the client and is filtered locally — bandwidth and exposure waste.

**Presence subscribe + track pattern:**

```ts
const channel = supabase.channel(`room-${roomId}`, {
  config: { presence: { key: userId } },
});

channel
  .on("presence", { event: "sync" }, () => {
    setOnlineUsers(Object.keys(channel.presenceState()));
  })
  .subscribe(async (status) => {
    if (status === "SUBSCRIBED") {
      await channel.track({ user: userId, cursor: { x: 0, y: 0 } });
    }
  });
```

**Always clean up channels:**

```ts
useEffect(() => {
  const channel = supabase.channel(/* ... */);
  channel.subscribe();
  return () => { supabase.removeChannel(channel); };
}, []);
```

### Anti-patterns

- **Postgres Changes on busy tables** (audit logs, telemetry). Every replicated row costs; subscribers split the cost but the write tax is constant. Use Broadcast from a trigger if you need only a subset of events.
- **Broadcast without Realtime Authorization.** Anyone subscribed to a predictable channel name (`org:123`) sees every message.
- **Presence as authoritative state.** It's eventually consistent across subscribers; don't drive business logic off it.
- **No filter on Postgres Changes.** Sends every row of the table to every subscriber.
- **Forgetting `removeChannel` in cleanup.** Channels accumulate; you hit limits or duplicate handlers.

## Gotchas

- **Postgres Changes requires logical replication on the table.** Most public tables have it; if a table doesn't show events, check Studio → Database → Replication.
- **`CHANNEL_ERROR` status in `subscribe()` usually means a Realtime Authorization policy failed.** Log the status callback: `channel.subscribe((status, err) => console.log(status, err))`.
- **Channel limits per connection.** Hundreds, not thousands. Multiplex many topics through one channel by design rather than one channel per topic.
- **Tokens for Realtime are passed via WebSocket; expired tokens cause silent disconnect.** Hook auth state changes to refresh the channel.
- **Realtime is not durable.** A disconnected client misses events while disconnected. For "show all events since X" semantics, query the table after reconnect.
- **`realtime.send()` is best-effort** — don't treat it as transactional with the row write.

## Cross-references

- [Row-Level Security](/stacks/supabase/row-level-security/) — the perimeter Postgres Changes inherits
- [Database Functions](/stacks/supabase/database-functions/) — trigger-driven Broadcast publishers
- [frontend-architect role view](/stacks/supabase/frontend-architect/) — client subscription patterns
- [security-engineer role view](/stacks/supabase/security-engineer/) — Realtime Authorization design
- Supabase docs: [Realtime guide](https://supabase.com/docs/guides/realtime), [Authorization](https://supabase.com/docs/guides/realtime/authorization)
