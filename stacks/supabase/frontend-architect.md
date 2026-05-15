---
title: frontend-architect on Supabase
description: "@supabase/ssr cookie wiring, supabase-js query patterns, Realtime client wiring, generated types, optimistic UI."
role_overlay:
  role: frontend-architect
  stack: supabase
  last_verified_on: "2026-05-14"
  products_covered: [supabase-ssr, supabase-js, supabase-auth, supabase-realtime, supabase-storage]
---

## Role briefing

You're frontend-architect on a Supabase engagement. Your job: the [@supabase/ssr](/stacks/supabase/supabase-ssr/) cookie wiring (so auth survives SSR / server components / middleware), the [supabase-js](/stacks/supabase/supabase-js/) client patterns (query builder, types, optimistic UI), and the [Realtime](/stacks/supabase/supabase-realtime/) client wiring (presence, broadcast, postgres-changes). The backend's job is Edge Functions and server-side data flow; yours is making sure the user sees the right data, fast, with a session that doesn't randomly evaporate.

What's distinctive vs. a generic frontend-architect role: on Supabase, the **client speaks directly to the database** through PostgREST. Auth, queries, realtime, storage — all from the browser, all RLS-bound. The most important thing you do here is keep the auth session alive across SSR boundaries. The cookie adapter is the #1 source of broken auth flows.

## The single most important thing on this overlay

**`@supabase/auth-helpers-nextjs`, `@supabase/auth-helpers-sveltekit`, `@supabase/auth-helpers-remix` are DEAD.** Use [@supabase/ssr](/stacks/supabase/supabase-ssr/) for every framework.

If you find yourself looking at code that imports from `@supabase/auth-helpers-*`, that's a migration target, not a reference point. The cookie semantics changed; you can't lift the old patterns directly.

## Decision frameworks specific to frontend-architect on Supabase

### Browser client vs server client vs middleware client

| Surface | Use |
|---------|-----|
| Browser component (`"use client"`) | `createBrowserClient` from `@supabase/ssr` |
| Server component, Route Handler, Server Action | `createServerClient` from `@supabase/ssr` with cookie adapter |
| Middleware | `createServerClient` in `middleware.ts`, call `getUser()` (NOT `getSession()`) |

### `getUser()` vs `getSession()`

- **`getUser()`** — re-verifies the token against the auth service. Use for auth gates.
- **`getSession()`** — reads from the cookie without verification. Faster but stale. Use only for non-security decisions ("show me the user's name in the navbar").

### Postgres Changes vs Broadcast on the client

If you're listening to DB state changes for a UI that reflects DB rows, [Postgres Changes](/stacks/supabase/supabase-realtime/) with server-side filter. If you're consuming app events (chat, game moves, presence), Broadcast. Don't subscribe to `*` and filter on the client — bandwidth waste and exposure surface.

### Cursor vs offset pagination

Always cursor for infinite scroll. Offset is fine for "page N of M" navigation but degrades on large tables.

## Product references

- [@supabase/ssr](/stacks/supabase/supabase-ssr/) — cookie adapter for Next.js / SvelteKit / Remix / Astro. The canonical shape: `createBrowserClient` for client, `createServerClient` for server, both wired through middleware that calls `getUser()` to refresh sessions.
- [supabase-js](/stacks/supabase/supabase-js/) — query builder, RPC, auth methods, storage methods, realtime API. Generated types via `supabase gen types typescript`.
- [Supabase Auth](/stacks/supabase/supabase-auth/) — client-side sign-in/sign-up flows; `onAuthStateChange` listener.
- [Supabase Realtime](/stacks/supabase/supabase-realtime/) — three primitives (Postgres Changes, Broadcast, Presence); always pair `subscribe()` with `removeChannel()` cleanup.
- [Supabase Storage](/stacks/supabase/supabase-storage/) — direct browser upload, signed URLs, image transforms.

## The middleware shape — THE part that breaks if you skip it

Without middleware, the session won't refresh between server renders and the user gets randomly signed out.

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

  // CRITICAL: refreshes token if expired.
  // Do not delete. Do not move. Do not add code between createServerClient and getUser.
  const { data: { user } } = await supabase.auth.getUser();

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

Why exactly this:
1. **`getAll` / `setAll`** — new cookie API (`@supabase/ssr` 0.5+).
2. **`getUser()` not `getSession()`** in middleware.
3. **No code between `createServerClient` and `getUser()`** — refresh logic runs synchronously.
4. **Response rebuilt after cookies change** — that's why `response =` is reassigned inside `setAll`.

## Realtime — client wiring rules

- **Always pair `subscribe()` with `removeChannel()` in cleanup.** Otherwise channels accumulate, hit limits, duplicate handlers.
- **Use the server-side `filter`** on Postgres Changes; don't filter client-side.
- **Log subscribe status** to diagnose `CHANNEL_ERROR` (usually a Realtime Authorization policy failure):

```ts
channel.subscribe((status, err) => console.log("channel status:", status, err));
```

## 2025-2026 platform reset relevant to frontend-architect

- **`@supabase/auth-helpers-*` is DEAD.** [@supabase/ssr](/stacks/supabase/supabase-ssr/) only.
- **New cookie API** (`getAll`/`setAll`) in `@supabase/ssr` 0.5+. Old `get`/`set`/`remove` deprecated.
- **`cookies()` from `next/headers` is async** in Next.js 14+ — `await cookies()`.
- **Realtime Authorization (2024)** — Broadcast/Presence respect RLS-style policies. `CHANNEL_ERROR` usually means a policy denial.
- **Anonymous sign-ins** — users get a real UUID and RLS can scope policies to them.
- **Generated types via `supabase gen types typescript`** — wire to `predev`, integrate into the createClient generic.
- **JWKS-based JWT verification** for external services (new projects default to RS256 with JWKS rotation).

## Patterns the role applies

### TDD on client code

- Component tests with supabase-js mocked at the module boundary (MSW / vitest).
- E2E tests with Playwright against a `supabase start` local instance — real DB, real auth, fastest signal.
- The most reliable signal: an integration test that boots local Supabase, signs in a test user, performs the flow, asserts the visible result.

### Verification

Before claiming "auth works on the server": demonstrate a hard refresh of a protected route after the token has expired. Without middleware refresh wiring, this fails.

### Debugging

**"Server components see user as null; client sees them logged in."**
- Middleware isn't refreshing cookies properly. Check:
  - Middleware file at project root (not nested).
  - `matcher` includes the route.
  - `getUser()` (not `getSession()`).
  - `setAll` callback rebuilds the response.
  - No code between `createServerClient` and `getUser`.

**"Logged out after some random duration."**
- Refresh token isn't reaching the cookie store. Check middleware's `setAll`, server client's `setAll` in route handlers, and third-party cookie blocking (Safari ITP).

**"Realtime fires once then stops."**
- Channel garbage-collected or `subscribe` returned `CHANNEL_ERROR`. Log the status callback; usually a Realtime Authorization policy failure or token expiry.

## Performance — what the frontend can control

1. **Select only what you need.** `.select("id, name")` not `.select("*")`.
2. **Use cursor pagination.** Offset on large tables is O(n) on the DB.
3. **Don't fetch joined data you don't render.**
4. **Use Realtime server-side filters.**
5. **Generate types and check in CI.** Half of "performance" bugs are "I queried for the wrong thing."
6. **Cache server components / route handlers aggressively** — Next.js fetch cache + revalidation works fine with `supabase-js`.

## Cross-references

- [backend-architect](/stacks/supabase/backend-architect/) — server-side Edge Functions the client calls
- [database-architect](/stacks/supabase/database-architect/) — schema + types + RLS performance
- [security-engineer](/stacks/supabase/security-engineer/) — auth hardening, MFA, session policy
- [ai-ml-engineer](/stacks/supabase/ai-ml-engineer/) — streaming AI endpoints the client consumes
- [Supabase Stack index](/stacks/supabase/) — what changed in 2025-2026
