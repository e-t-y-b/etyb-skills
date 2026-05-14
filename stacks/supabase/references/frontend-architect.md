---
role: frontend-architect
stack: supabase
last_verified_on: "2026-05-14"
---

# Supabase Overlay — frontend-architect

You are frontend-architect on a Supabase engagement. Your job is the **`@supabase/ssr` cookie wiring** (so auth survives SSR/server components/middleware), the **`supabase-js` client patterns** (query builder, types, optimistic UI), and the **Realtime client wiring** (presence, broadcast, postgres-changes). The backend's job is Edge Functions and server-side data flow; yours is making sure the user sees the right data, fast, with a session that doesn't randomly evaporate.

**Currency:** verified against `@supabase/ssr` docs and supabase-js v2.x reference through **2026-05-14**. `@supabase/auth-helpers-*` packages are **DEPRECATED** — every reference to them in older training data is wrong for new builds.

## The single most important thing on this overlay

**`@supabase/auth-helpers-nextjs`, `@supabase/auth-helpers-sveltekit`, `@supabase/auth-helpers-remix` are DEAD.** Use `@supabase/ssr` for every framework. The migration is straightforward but the cookie semantics changed — you can't lift the old patterns directly.

If you find yourself looking at code that imports from `@supabase/auth-helpers-*`, that's a migration target, not a reference point. Source: [@supabase/ssr docs](https://supabase.com/docs/guides/auth/server-side).

## `@supabase/ssr` — Next.js (App Router) canonical setup

This is the right shape as of 2026 for Next.js 14/15. The same pattern (createBrowserClient + createServerClient + cookie adapter) works across SvelteKit / Remix / Astro with minor adjustments.

### Browser client

```ts
// utils/supabase/client.ts
import { createBrowserClient } from "@supabase/ssr";

export const createClient = () =>
  createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
```

Use anywhere on the client (client components, browser code). It reads/writes session cookies that the server can also see.

### Server client (server components, route handlers)

```ts
// utils/supabase/server.ts
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export const createClient = async () => {
  const cookieStore = await cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Called from a Server Component (read-only cookies).
            // The middleware handles refresh; ignore here.
          }
        },
      },
    },
  );
};
```

### Middleware — THE part that breaks if you skip it

This is where sessions get refreshed. Without middleware, a stale session won't refresh between server renders and the user gets randomly signed out.

```ts
// middleware.ts
import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // CRITICAL: this call refreshes the token if expired.
  // Do not delete this line. Do not move it. Do not add code between createServerClient and getUser.
  const { data: { user } } = await supabase.auth.getUser();

  // Optional: redirect unauth users
  if (!user && !request.nextUrl.pathname.startsWith("/login")) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
```

### Why this exact shape

1. **`getAll` / `setAll`** — `@supabase/ssr` 0.5+ uses the new cookie API. The older `get`/`set`/`remove` shape is deprecated.
2. **`getUser()` not `getSession()`** in middleware. `getUser()` re-verifies the token; `getSession()` reads it from the cookie without re-verification (faster, but stale). For auth gates, use `getUser()`.
3. **No code between `createServerClient` and `getUser`** — middleware must perform the auth check immediately so the refresh-cookie logic runs synchronously.
4. **The middleware ALWAYS rebuilds the response after cookies change** — that's why `response = NextResponse.next({ request })` is re-assigned inside `setAll`.

If any of these are missing, the symptom is "user is signed in on the client but server components see them as signed out" or "session randomly logs out after 1 hour."

### Using the server client in a Server Component / Route Handler

```tsx
// app/dashboard/page.tsx (Server Component)
import { createClient } from "@/utils/supabase/server";

export default async function Dashboard() {
  const supabase = await createClient();
  const { data: orders } = await supabase
    .from("orders")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(20);
  // orders is fetched server-side with the user's session; RLS applies.
  return <OrdersList orders={orders} />;
}
```

```ts
// app/api/orders/route.ts (Route Handler)
import { createClient } from "@/utils/supabase/server";

export async function POST(request: Request) {
  const supabase = await createClient();
  const body = await request.json();
  const { data, error } = await supabase
    .from("orders")
    .insert({ ...body, user_id: (await supabase.auth.getUser()).data.user?.id })
    .select()
    .single();
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json(data);
}
```

## SvelteKit

```ts
// src/hooks.server.ts
import { createServerClient } from "@supabase/ssr";
import { type Handle, redirect } from "@sveltejs/kit";
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from "$env/static/public";

export const handle: Handle = async ({ event, resolve }) => {
  event.locals.supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
    cookies: {
      getAll: () => event.cookies.getAll(),
      setAll: (cookiesToSet) => {
        cookiesToSet.forEach(({ name, value, options }) =>
          event.cookies.set(name, value, { ...options, path: "/" }),
        );
      },
    },
  });

  event.locals.safeGetSession = async () => {
    const { data: { session } } = await event.locals.supabase.auth.getSession();
    if (!session) return { session: null, user: null };
    const { data: { user }, error } = await event.locals.supabase.auth.getUser();
    if (error) return { session: null, user: null };
    return { session, user };
  };

  return resolve(event, {
    filterSerializedResponseHeaders: (name) => name === "content-range" || name === "x-supabase-api-version",
  });
};
```

The SvelteKit pattern bakes the safe-get-session pattern into `locals` so every `+page.server.ts` can call `await locals.safeGetSession()` without re-running the validation.

## Remix

```ts
// app/utils/supabase.server.ts
import { createServerClient, parseCookieHeader, serializeCookieHeader } from "@supabase/ssr";

export const createClient = (request: Request) => {
  const headers = new Headers();
  const supabase = createServerClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => parseCookieHeader(request.headers.get("Cookie") ?? ""),
        setAll: (cookies) => {
          cookies.forEach(({ name, value, options }) => {
            headers.append("Set-Cookie", serializeCookieHeader(name, value, options));
          });
        },
      },
    },
  );
  return { supabase, headers };
};
```

Loaders return both data and headers:

```ts
export async function loader({ request }: LoaderFunctionArgs) {
  const { supabase, headers } = createClient(request);
  const { data: orders } = await supabase.from("orders").select("*");
  return json({ orders }, { headers });
}
```

## supabase-js — query patterns

### Select with joins

```ts
const { data, error } = await supabase
  .from("orders")
  .select(`
    id,
    total,
    status,
    customer:customers (id, email, name),
    items:order_items (
      qty,
      price,
      product:products (id, name)
    )
  `)
  .eq("status", "active")
  .order("created_at", { ascending: false })
  .limit(50);
```

The relationship syntax (`customer:customers (...)`) requires an FK to exist in the schema. The alias (`customer:`) is what the field is called in the result.

For many-to-many through a join table:

```ts
// posts has many tags via post_tags(post_id, tag_id)
const { data } = await supabase
  .from("posts")
  .select(`
    id, title,
    tags:post_tags (
      tag:tags (id, name)
    )
  `);
// Result: posts[i].tags[j].tag.name — flatten in JS if needed.
```

### Filters

```ts
.eq("col", val)         // =
.neq("col", val)        // !=
.gt(...), .gte(...)     // >, >=
.lt(...), .lte(...)     // <, <=
.like("col", "%foo%")   // LIKE
.ilike(...)             // ILIKE (case-insensitive)
.in("col", [a, b, c])   // IN
.contains("arr", [a])   // array @> [a]
.containedBy(...)       // <@
.is("col", null)        // IS NULL  (don't use .eq for null)
.or("col1.eq.1,col2.eq.2") // OR
.match({ col1: v1, col2: v2 }) // AND of equalities
```

The `or` filter takes a comma-separated string of conditions; awkward but documented. For complex predicates, prefer an RPC.

### Pagination — range vs limit/offset

```ts
// Offset-based (familiar but unstable under inserts):
.range(0, 49)   // rows 0..49 inclusive

// Cursor-based (recommended for stable pagination):
.lt("created_at", lastSeenCreatedAt)
.order("created_at", { ascending: false })
.limit(50);
```

Always cursor for "infinite scroll" UX; offset is fine for "page N of M" navigation.

### Optimistic UI

```ts
const newOrder = { id: crypto.randomUUID(), user_id, total, status: "pending" };

// 1. Optimistically update local state
setOrders((prev) => [newOrder, ...prev]);

// 2. Send to server
const { data, error } = await supabase
  .from("orders")
  .insert(newOrder)
  .select()
  .single();

// 3. Reconcile
if (error) {
  setOrders((prev) => prev.filter((o) => o.id !== newOrder.id));
  toast.error(error.message);
} else {
  setOrders((prev) => prev.map((o) => o.id === newOrder.id ? data : o));
}
```

Generate IDs client-side (UUIDs) so the optimistic row matches the server-confirmed row. Don't try to reconcile by index.

### Generated types — wire them up

```bash
supabase gen types typescript --linked > types/database.ts
```

Then:

```ts
import type { Database } from "@/types/database";
import { createBrowserClient } from "@supabase/ssr";

const supabase = createBrowserClient<Database>(URL, KEY);

// Now:
const { data } = await supabase.from("orders").select("id, total");
// data is typed: { id: string; total: number }[] | null
```

Wire into:
- A `predev` npm script: `"predev": "supabase gen types typescript --linked > types/database.ts"`.
- A CI check that fails if the committed types don't match the live schema.
- A post-migration step in your deploy pipeline.

### Common pitfalls

1. **Forgetting to `await` the server client factory.** `await createClient()` in Next.js server components — the `cookies()` import is async.
2. **Mixing browser + server clients in the same module.** Don't import `createBrowserClient` in a server component; it'll either error or quietly use empty cookies.
3. **Calling `.single()` when you meant `.maybeSingle()`.** `.single()` errors on 0 rows; `.maybeSingle()` returns null.
4. **Mutating filters in an array of chained calls.** Each `.eq()` returns a new query builder; chain in a single expression.
5. **Trusting `getSession()` for auth gates.** Use `getUser()` — it re-verifies.

## Realtime — client wiring

### Postgres Changes (CDC)

```ts
useEffect(() => {
  const channel = supabase
    .channel("orders-changes")
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "orders", filter: `user_id=eq.${userId}` },
      (payload) => {
        if (payload.eventType === "INSERT") {
          setOrders((prev) => [payload.new, ...prev]);
        } else if (payload.eventType === "UPDATE") {
          setOrders((prev) => prev.map((o) => o.id === payload.new.id ? payload.new : o));
        } else if (payload.eventType === "DELETE") {
          setOrders((prev) => prev.filter((o) => o.id !== payload.old.id));
        }
      },
    )
    .subscribe();

  return () => { supabase.removeChannel(channel); };
}, [userId]);
```

The `filter` clause is a PostgREST-style filter that limits which rows the channel receives. Use it — without a filter, every row change in `orders` is sent to the client and filtered locally (waste of bandwidth and exposure surface).

### Broadcast (app events)

```ts
const channel = supabase.channel(`room-${roomId}`);

// Send:
await channel.send({
  type: "broadcast",
  event: "message",
  payload: { user: userId, text: "hello" },
});

// Receive:
channel.on("broadcast", { event: "message" }, ({ payload }) => {
  setMessages((prev) => [...prev, payload]);
});

channel.subscribe();
```

Realtime Authorization (see [security-engineer overlay](security-engineer.md)) is what scopes who can subscribe to which channels. Without authorization config, broadcast is a leak.

### Presence

```ts
const channel = supabase.channel(`room-${roomId}`, {
  config: { presence: { key: userId } },
});

channel
  .on("presence", { event: "sync" }, () => {
    const state = channel.presenceState();
    setOnlineUsers(Object.keys(state));
  })
  .on("presence", { event: "join" }, ({ key, newPresences }) => {
    // user joined
  })
  .on("presence", { event: "leave" }, ({ key, leftPresences }) => {
    // user left
  })
  .subscribe(async (status) => {
    if (status === "SUBSCRIBED") {
      await channel.track({ user: userId, status: "online" });
    }
  });
```

Use for: collaboration cursors, live user counts, "X is typing." Don't use for: authoritative state (it's eventually consistent across subscribers).

### Cleanup is non-negotiable

Every `supabase.channel(...)` must be paired with a `supabase.removeChannel(channel)` in the cleanup phase. Otherwise channels accumulate, and you'll hit channel limits or duplicate handlers. In React, do this in `useEffect`'s cleanup; in Svelte, in `onDestroy`; in Vue, in `onBeforeUnmount`.

## Auth flows on the client

### Email + password sign-up

```ts
const { data, error } = await supabase.auth.signUp({
  email,
  password,
  options: {
    emailRedirectTo: `${location.origin}/auth/confirm`,
    data: { display_name: name }, // becomes raw_user_meta_data on auth.users
  },
});
```

### Sign-in

```ts
const { error } = await supabase.auth.signInWithPassword({ email, password });
```

### Magic link

```ts
const { error } = await supabase.auth.signInWithOtp({
  email,
  options: { emailRedirectTo: `${location.origin}/auth/callback` },
});
```

### OAuth

```ts
const { error } = await supabase.auth.signInWithOAuth({
  provider: "google",
  options: { redirectTo: `${location.origin}/auth/callback` },
});
```

### Sign-out

```ts
await supabase.auth.signOut();
// or to sign out everywhere:
await supabase.auth.signOut({ scope: "global" });
```

### Auth state changes — listen on the client

```tsx
useEffect(() => {
  const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
    if (event === "SIGNED_IN") refetch();
    if (event === "SIGNED_OUT") clearState();
  });
  return () => { subscription.unsubscribe(); };
}, []);
```

### The auth callback route

For OAuth + magic link, you need a callback route to exchange the code for a session:

```ts
// app/auth/callback/route.ts
import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/";

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(`${origin}${next}`);
  }

  return NextResponse.redirect(`${origin}/auth/error`);
}
```

`exchangeCodeForSession` is the PKCE flow. The browser handles the redirect-with-code part; this server-side exchange is what sets the cookie.

## Storage — client uploads

### Direct upload from the browser

```ts
const file = event.target.files[0];
const filePath = `${userId}/${crypto.randomUUID()}-${file.name}`;
const { data, error } = await supabase.storage
  .from("user-uploads")
  .upload(filePath, file, {
    contentType: file.type,
    upsert: false,
  });
```

Storage RLS on `storage.objects` decides whether the upload succeeds. Make sure the bucket's INSERT policy allows it for the authenticated user (typically scoped by folder = user ID).

### Resumable upload (TUS) for large files

```ts
const { data, error } = await supabase.storage
  .from("user-uploads")
  .uploadToSignedUrl(uploadUrl, token, file);
```

Get the signed upload URL from an Edge Function that calls `storage.createSignedUploadUrl(...)`. The browser then PUTs to the signed URL in chunks. Necessary for files >50MB.

### Display an image with transforms

```ts
const { data } = supabase.storage
  .from("avatars")
  .getPublicUrl("user-123/avatar.png", {
    transform: { width: 200, height: 200, resize: "cover" },
  });
// data.publicUrl is a transform-baked URL.
```

For private buckets, use `createSignedUrl(path, expiresIn, { transform: {...} })`.

## Performance — what the frontend can control

1. **Select only what you need.** `.select("id, name")` not `.select("*")`. Smaller payloads, faster parse.
2. **Use cursor pagination.** Offset pagination on large tables is O(n) on the database.
3. **Don't fetch joined data you don't render.** If the UI shows order ID + total but loads customer + items, you're paying for both round-trip latency and bandwidth.
4. **Use Realtime filters.** Don't subscribe to `*` and filter on the client.
5. **Generate types and check them in CI.** Half of "performance" bugs are actually "I queried for the wrong thing."
6. **Cache route handlers / server components aggressively.** Next.js fetch cache + revalidation works fine with `supabase-js`; pass `{ next: { revalidate: 60 } }`.

## Cross-references

- **Edge Functions that the client calls** → [backend-architect overlay](backend-architect.md)
- **Schema + types + RLS** → [database-architect overlay](database-architect.md)
- **Auth hardening, MFA, session policy** → [security-engineer overlay](security-engineer.md)
- **pgvector + AI features the client triggers** → [ai-ml-engineer overlay](ai-ml-engineer.md)

## Integration with always-on protocols

### TDD on client code

- Component tests with the supabase-js client mocked at the module boundary (use MSW or vitest mocks).
- E2E tests with Playwright against a `supabase start` local instance — real DB, real auth.
- The fastest signal: an integration test that boots a local Supabase, signs in a test user, performs the user flow, asserts the visible result.

### Verification

Before claiming "auth works on the server": demonstrate a hard refresh of a protected route after the token has expired. Without middleware refresh wiring, this fails.

### Debugging

Symptom: "Server components see user as null; client sees them logged in."

The middleware isn't refreshing the cookies properly. Check:
1. The middleware file exists at the project root (not nested).
2. The `matcher` config includes the route.
3. `getUser()` is called (not just `getSession()`).
4. The `setAll` callback rebuilds the response.
5. No code runs between `createServerClient` and `getUser`.

Symptom: "I get logged out after some random duration."

The refresh token isn't reaching the cookie store. Check:
- The middleware's `setAll` is wired (most common cause).
- The server client's `setAll` is wired (for Server Action / Route Handler paths that perform auth ops).
- No third-party cookie blocking (check Safari ITP in production).

Symptom: "Realtime fires once then stops."

The channel was garbage-collected or the subscription returned `CHANNEL_ERROR`. Log the `subscribe` status:

```ts
channel.subscribe((status, err) => {
  console.log("channel status:", status, err);
});
```

Look for `CHANNEL_ERROR` (usually a Realtime Authorization policy failure) or `CLOSED` (network or token issue).
