---
title: Server Actions
description: "`'use server'` functions invoked from forms and client components. The mutation primitive on App Router — and a public HTTP endpoint you must secure."
product:
  name: Server Actions
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect]
  authoritative_url: https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations
  notes: "Stable, but 2025 security hardening guidance shifted: taint APIs, default forbidden methods, encryption keys per deployment. Old `streamUI`-era examples are stale."
---

## What it is

A Server Action is a server-side function declared with `'use server'` that can be called directly from a Client Component (via form `action={fn}` or programmatically). The framework hides the URL, wires the POST endpoint, and serializes args + return value. See [nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations).

**Critical:** every Server Action is a public HTTP endpoint with a hidden POST body. The framework hides the URL but does not hide the fact that anyone with the action ID can call it. Treat each action as a public API endpoint.

## When to use

- **App-internal mutations** — forms, button clicks, state changes. Default to Server Actions.
- **Cache invalidation flows** — Server Action does the work and calls `revalidateTag()` to invalidate Cache Components.

Use [Route Handlers](/stacks/vercel/vercel-functions/#route-handlers) instead when:

- An external system needs to call it (webhook, mobile client, third-party).
- The response needs custom headers/status the action contract doesn't support.
- You're building a versioned public API.
- You need to stream a non-RSC response (Server Actions return promises, not streams; AI streaming belongs in Route Handlers).

## 2025-2026 currency anchors

- **Security hardening guidance shifted in 2025.** Taint APIs (`taintObjectReference` / `taintUniqueValue`) are the canonical guard against accidentally returning secrets.
- **`NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`** pins the encryption key across deployments/regions; required for stable action IDs in multi-region or sticky rollouts.
- **`useActionState`** (React 19) is the form-state primitive — `[state, action, isPending]`.
- **`useFormStatus`** (React DOM 19) reads pending state from inside a `<form>`'s subtree.
- **`useOptimistic`** rolls back automatically if the action throws.

## Mandatory checklist per Server Action

```ts
'use server';
import { auth } from '@/lib/auth';
import { rateLimit } from '@/lib/rate-limit';
import { z } from 'zod';
import { revalidateTag } from 'next/cache';

const Schema = z.object({
  postId: z.string().uuid(),
  body: z.string().min(1).max(2000),
});

export async function addComment(formData: FormData) {
  // 1. AUTHENTICATE — every action, every call.
  const user = await auth();
  if (!user) throw new Error('Unauthorized');

  // 2. RATE LIMIT — by user, by IP, or both.
  const allowed = await rateLimit(`add-comment:${user.id}`, { rpm: 30 });
  if (!allowed) throw new Error('Rate limited');

  // 3. VALIDATE — never trust formData shape.
  const parsed = Schema.safeParse({
    postId: formData.get('postId'),
    body: formData.get('body'),
  });
  if (!parsed.success) throw new Error('Invalid input');

  // 4. AUTHORIZE — does this user have permission?
  const post = await db.query.posts.findFirst({ where: eq(posts.id, parsed.data.postId) });
  if (!post || (post.private && post.authorId !== user.id)) throw new Error('Forbidden');

  // 5. DO THE WORK.
  await db.insert(comments).values({ ...parsed.data, userId: user.id });

  // 6. INVALIDATE CACHE TAGS.
  revalidateTag(`comments:${parsed.data.postId}`);

  // 7. RETURN SHAPE — never raw DB rows; map to a client-safe shape.
  return { ok: true };
}
```

## Patterns + anti-patterns

**Pattern: Form + `useActionState` + `useFormStatus`.** Server Action receives `(prevState, formData)`; client gets `[state, action, isPending]` for the form and `useFormStatus()` for pending inside the form subtree.

**Pattern: Optimistic UI.** `useOptimistic` lets you reflect the mutation immediately and roll back on error.

**Pattern: Idempotency keys for high-value actions.** The client generates a UUID per submit; retries pass the same key; the server checks before doing work.

**Anti-pattern: Returning raw DB rows.** Map to a `ClientSafe<X>` shape; or `experimental_taintObjectReference` the sensitive object.

**Anti-pattern: Long-running Server Action.** > 5s to return is wrong design — either trigger a Workflow from the action and return early, or use `after()` for the slow part. Slow actions starve the form's UX and burn function time.

**Anti-pattern: Calling Server Actions from `useEffect`.** Almost always a sign you wanted a Route Handler with TanStack Query, or you wanted to fetch on the server.

**Anti-pattern: Trusting `formData` shape.** Use Zod (or valibot) on every parse. The action's caller can pass anything.

## Gotchas

- **Action IDs rotate per deployment.** If you don't pin `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`, a client cached from deployment A might POST an action ID deployment B doesn't recognize. Pin it once, rotate intentionally.
- **CSRF risk on session-bound actions.** Origin is enforced (same-origin by default), but for high-value actions (changing email/password, financial), require re-auth or a CSRF token.
- **Server Action streaming is not supported** — actions return promises, not streams. AI streaming belongs in Route Handlers.
- **Don't log the action's return.** If the return contains tainted values, the logger will trip.

## Cross-references

- [App Router](/stacks/vercel/app-router/)
- [Server Components](/stacks/vercel/server-components/) — taint APIs for the boundary
- [Cache Components](/stacks/vercel/cache-components/) — `revalidateTag` from actions
- [Vercel Functions](/stacks/vercel/vercel-functions/) — Route Handlers for the cases Server Actions don't fit
- [backend-architect on Vercel](/stacks/vercel/backend-architect/) — full security surface
- Authoritative: [Server Actions docs](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
- Delegate: `vercel:nextjs`, `vercel:auth`
