---
title: Server Components
description: React components that render on the server with direct access to data, files, and secrets — no client bundle, no hydration. The App Router default.
product:
  name: Server Components
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, backend-architect]
  authoritative_url: https://react.dev/reference/rsc/server-components
  notes: "React 19 stable; `use()` hook, `taintObjectReference`, `taintUniqueValue`, and `import 'server-only'` are the 2026 boundary contract."
---

## What it is

Server Components are React components that render on the server and serialize their output to the client. They can `await` data directly, import server-only modules (DB clients, secret keys), and pass results as props to Client Components. They cost nothing in the client bundle — only the rendered output crosses the wire.

Every component in `app/` is a Server Component unless marked `'use client'`. See [react.dev/reference/rsc/server-components](https://react.dev/reference/rsc/server-components) for the React-side reference; [nextjs.org/docs/app/building-your-application/rendering/server-components](https://nextjs.org/docs/app/building-your-application/rendering/server-components) for the Next.js integration.

## When to use

Default to Server Components. Reach for `'use client'` only when you need:

- `useState` / `useReducer` / `useRef` for local UI state
- Event handlers (`onClick`, `onChange`)
- Browser APIs (`window`, `localStorage`, `IntersectionObserver`, `matchMedia`)
- React lifecycle (`useEffect`, `useLayoutEffect`)
- Third-party React libraries that internally use hooks (Framer Motion, Radix primitives, most form libs)

Don't reach for `'use client'` because you "want a UI library" — Server Components can render most of shadcn/ui, Radix Server Components, and Tailwind perfectly.

## 2025-2026 currency anchors

- **React 19+ stable.** `use()` for unwrapping promises in render, `Actions` for form submissions, `useActionState`, `useOptimistic`, `useFormStatus`, `ref` as a regular prop, Document Metadata in components.
- **React Compiler (Forget)** is stable opt-in and on by default in Next.js with `experimental.reactCompiler` — auto-memoization drops most manual `useMemo`/`useCallback`.
- **`taintObjectReference` / `taintUniqueValue`** (React experimental) are the canonical guard against accidental client serialization of sensitive objects/secrets.
- **`import 'server-only'`** throws at build time if imported into a Client Component; pair with `import 'client-only'` for the inverse.
- **`params` is a Promise** in Server Components in Next.js 15+. Await it.

## Patterns + anti-patterns

**Pattern: Fetch on the server, pass as props.**

```tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const product = await db.query.products.findFirst({ where: eq(products.id, id) });
  if (!product) notFound();
  return <ProductView product={product} />;
}
```

**Pattern: "Pass server tree as children" trick.** A Client Component wrapper renders `{children}` that is itself a Server Component subtree — the inner tree stays on the server without shipping to the client bundle.

```tsx
// Server Component
export default async function Page() {
  const user = await getUser();
  return (
    <ClientSidebar>
      <ServerUserCard user={user} />  {/* Renders on server, embedded inside client */}
    </ClientSidebar>
  );
}
```

**Pattern: Guard sensitive objects with `taintObjectReference`.**

```ts
import { experimental_taintObjectReference, experimental_taintUniqueValue } from 'react';

export async function getUser() {
  const user = await db.query.users.findFirst({...});
  experimental_taintObjectReference(
    'Do not pass user object to Client Components; pass only what you need.',
    user,
  );
  experimental_taintUniqueValue('Do not log auth token.', user, user.sessionToken);
  return user;
}
```

If a Client Component renders a tainted object, React throws at serialization time.

**Anti-pattern: Returning raw DB rows.** A Server Component fetches a User row with `passwordHash`, `stripeCustomerId`, `internalNotes` — all serialized to the browser if you pass it down. Map to a `ClientSafeUser` shape before crossing the boundary.

**Anti-pattern: Putting `useState`/`useEffect` near the top of a tree.** Promotes the entire subtree to a Client Component. Push interactivity to leaf components.

## Gotchas

- **Server Components can't use hooks.** No `useState`, no `useEffect`, no Context.
- **Server Components can't be imported into Client Components directly** (only passed as `children` or props). The bundler enforces this.
- **`console.log` in a Server Component** goes to the function log (Vercel dashboard), not the browser console.
- **Hydration mismatches** come from non-deterministic rendering: `Date.now()`, `Math.random()`, locale-dependent output that differs between server render and client hydration.
- **Suspense at the right level.** Wrap async Server Components in `<Suspense>` so the rest of the tree can stream independently.

## Cross-references

- [App Router](/stacks/vercel/app-router/) — where Server Components live
- [Server Actions](/stacks/vercel/server-actions/) — server-side mutation primitive
- [Cache Components](/stacks/vercel/cache-components/) — `'use cache'` on Server Components
- [frontend-architect on Vercel](/stacks/vercel/frontend-architect/)
- Authoritative: [react.dev RSC](https://react.dev/reference/rsc/server-components), [Next.js rendering](https://nextjs.org/docs/app/building-your-application/rendering)
- Delegate: `vercel:nextjs`, `vercel:react-best-practices`
