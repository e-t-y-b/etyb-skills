---
title: "@supabase/ssr"
description: The cookie adapter for server-side Supabase auth. Replaces deprecated @supabase/auth-helpers-*. Cookie handling is the #1 SSR auth bug.
product:
  name: "@supabase/ssr"
  stack: supabase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect]
  authoritative_url: https://supabase.com/docs/guides/auth/server-side
  notes: "Replaces deprecated @supabase/auth-helpers-nextjs/sveltekit/remix. New cookie API (getAll/setAll) in 0.5+. Middleware wiring is the most fragile piece."
---

## What it is

`@supabase/ssr` is the official cookie adapter for server-side Supabase auth. It wraps `supabase-js` with `createBrowserClient` and `createServerClient` helpers that handle session cookies correctly across the middleware → server → client boundary.

Source: [`@supabase/ssr` guide](https://supabase.com/docs/guides/auth/server-side).

## When to use

**Always**, for any SSR-capable app (Next.js, SvelteKit, Remix, Astro, Nuxt).

- **`@supabase/auth-helpers-nextjs`, `-sveltekit`, `-remix`, `-shared` are DEPRECATED.** Every reference in older training data is wrong for new builds.
- The old helpers will steer you into broken middleware and cookie bugs.

If you're reading code that imports from `@supabase/auth-helpers-*`, that's a migration target, not a reference point.

## 2025-2026 currency anchors

- **New cookie API** (`getAll` / `setAll`) in `@supabase/ssr` 0.5+. Older `get`/`set`/`remove` is deprecated.
- **`createBrowserClient`** for client-side; **`createServerClient`** for server-side; **`createServerClient` in middleware** for session refresh.
- **`getUser()` in middleware** — re-verifies the token; **`getSession()`** reads cookie without verification. For auth gates, use `getUser()`.
- **PKCE flow for OAuth + magic link** — callback route exchanges code for session via `exchangeCodeForSession`.

## Patterns and anti-patterns

### Patterns

**Browser client:**

```ts
// utils/supabase/client.ts
import { createBrowserClient } from "@supabase/ssr";
export const createClient = () =>
  createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
```

**Server client (Next.js App Router):**

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
            // Server Component (read-only cookies); middleware handles refresh.
          }
        },
      },
    },
  );
};
```

**Middleware — THE part that breaks if you skip it:**

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

  // CRITICAL: refreshes the token if expired.
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

Why this exact shape:
1. **`getAll` / `setAll`** — new cookie API.
2. **`getUser()` not `getSession()`** — re-verifies.
3. **No code between `createServerClient` and `getUser()`** — the refresh-cookie logic must run synchronously.
4. **Response is rebuilt after cookies change** — that's why `response = NextResponse.next({ request })` is re-assigned inside `setAll`.

**OAuth callback route** (exchange code for session):

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

**SvelteKit pattern** lives in `src/hooks.server.ts` with `safeGetSession` baked into `locals`; **Remix pattern** uses `parseCookieHeader`/`serializeCookieHeader` and loaders return both data + headers. See the [frontend-architect role view](/stacks/supabase/frontend-architect/) for full code.

### Anti-patterns

- **`@supabase/auth-helpers-nextjs` (or any helpers package) in new code.** Migration target only.
- **Missing middleware.** Sessions don't refresh; user randomly signs out after token expiry.
- **Code between `createServerClient` and `getUser()` in middleware.** Token refresh skipped.
- **Old cookie API** (`get`/`set`/`remove`). Use `getAll`/`setAll`.
- **`getSession()` for auth gates.** Doesn't re-verify; replay attacks work.
- **Importing `createBrowserClient` into a server component.** Wrong client; cookies broken.

## Gotchas

- **`cookies()` from `next/headers` is async** in Next.js 14+ — `await cookies()`.
- **Server Components have read-only cookies.** The `setAll` callback throws in that context; wrap in try/catch and let middleware handle refresh.
- **Middleware must rebuild the response after setting cookies.** Forgetting this means new cookies never reach the browser.
- **Third-party cookie blocking** (Safari ITP) can cause "logs out randomly in prod" symptoms. Configure your Supabase project domain to match your app domain.
- **`emailRedirectTo` / `redirectTo` URLs must be in the allow-list** in Studio.
- **The `matcher` config** determines which routes the middleware runs on. Too narrow = unauthenticated routes don't refresh; too broad = unnecessary auth checks.

## Cross-references

- [Supabase Auth](/stacks/supabase/supabase-auth/) — the auth service this client talks to
- [supabase-js](/stacks/supabase/supabase-js/) — the underlying SDK
- [Edge Functions](/stacks/supabase/edge-functions/) — server-side handlers using the same patterns
- [frontend-architect role view](/stacks/supabase/frontend-architect/) — full Next.js / SvelteKit / Remix recipes
- Supabase docs: [Server-side Auth](https://supabase.com/docs/guides/auth/server-side)
