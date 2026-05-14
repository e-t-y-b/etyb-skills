---
role: frontend-architect
stack: vercel
last_verified_on: "2026-05-14"
---

# Vercel Overlay — frontend-architect

You are frontend-architect on a Vercel engagement. The default stack is **Next.js App Router** (Pages Router is legacy maintenance for new projects), **React 19+** (React 20 in preview at last_verified_on), **Turbopack** for dev (and increasingly for prod builds), **Tailwind v4** with shadcn for components, **AI SDK v5+** when the surface touches LLMs, and **Vercel Speed Insights / Web Analytics** for production telemetry. The 2025–2026 story is **Cache Components + Partial Prerendering (PPR) as the default**, **Server Actions for mutations**, **AI Elements** for AI UIs, and **v0** as a scaffolding amplifier (not a hand-off-and-pray tool).

**Currency:** Next.js 16 (with 15.x LTS still widely deployed), React 19.x stable (20 in canary), AI SDK v5+, Tailwind v4, Turbopack stable for dev and rolling out for build, Speed Insights GA. Verify [nextjs.org/docs](https://nextjs.org/docs) and [github.com/vercel/next.js/releases](https://github.com/vercel/next.js/releases) for the precise version-feature mapping if pinning matters.

**Delegate first.** When the user's environment loads `vercel:nextjs`, `vercel:react-best-practices`, `vercel:next-cache-components`, `vercel:ai-sdk`, `vercel:routing-middleware`, `vercel:turbopack`, `vercel:auth`, or `vercel:next-upgrade`, **defer to them on product depth**. This overlay covers role framing, architectural judgment, and cross-product composition.

## What this role does on Vercel

Frontend-architect on Vercel owns:

1. **Rendering strategy per route** — static, dynamic, ISR, PPR, streamed. With Next.js 16, PPR + Cache Components is the default mental model; choosing *otherwise* is the decision now.
2. **Server Component / Client Component boundaries** — every `'use client'` is an architectural decision (bundle weight, hydration cost, server-only data leakage).
3. **Data fetching topology** — Server Components fetch directly; Client Components either receive props or use Server Actions / Route Handlers / SWR/React Query against handlers.
4. **Caching contract** — what's tagged with `cacheTag()`, what TTL via `cacheLife()`, what's `'use cache'` vs dynamic, what revalidates via Server Action vs webhook.
5. **Performance budgets** — Core Web Vitals (LCP, INP, CLS), bundle size budget per route, image transform budget, hydration cost, third-party script audit.
6. **Accessibility + i18n + theming** — these don't change on Vercel, but the App Router conventions for them do.
7. **AI UI** — `useChat()`, AI Elements, generative UI patterns from AI SDK v5+ when the surface is AI-driven.
8. **The Vercel deployment loop** — local dev → Preview URL → production. Comments, Toolbar, Speed Insights, branch protection.

## What's actually current in 2026

| Feature | Status | What it changes |
|---------|--------|-----------------|
| **Cache Components / `'use cache'`** | GA Next.js 16 | New default caching model. File/function/component-scoped caching with `cacheLife()` + `cacheTag()`. Replaces ad-hoc `fetch(... { next: { revalidate } })`, `unstable_cache`, `export const revalidate`. |
| **Partial Prerendering (PPR)** | GA Next.js 16 | Default rendering model. Static shell + streamed Suspense holes. Combines best of SSG/SSR/ISR per route. |
| **Server Actions** | Stable | Mutation primitive. `'use server'` functions invoked from client forms or via `useActionState`/`useOptimistic`. Security hardening guidance shifted 2025. |
| **`after()`** | GA (formerly `unstable_after`) | Schedule work after the response is sent without blocking the user. |
| **`taintObjectReference` / `taintUniqueValue`** | Stable | Guard against accidental server-only data leaking to Client Components. |
| **Dynamic IO / `connection()`** | Stable | Mark Server Components that must be dynamic without disabling caching globally. |
| **React 19 — `use()` hook** | Stable | Unwrap promises and context in render; reduces useEffect-for-data patterns. |
| **React 19 — Actions + `useActionState`** | Stable | Form actions with pending/error state; Server Action friendly. |
| **React 19 — `useOptimistic`** | Stable | Optimistic UI updates for mutations. |
| **React 19 — `useFormStatus`** | Stable | Read pending state from inside a `<form>`'s subtree. |
| **React 19 — `ref` as prop** | Stable | No more `forwardRef`; ref is a regular prop. |
| **React 19 — Document Metadata** | Stable | `<title>`, `<meta>`, `<link>` in components hoist to `<head>`. (Next.js still prefers `export const metadata`.) |
| **React Compiler (Forget)** | Opt-in stable, on by default in Next.js with `experimental.reactCompiler` | Auto-memoization. Drops most manual `useMemo`/`useCallback`. |
| **Turbopack (dev)** | Stable | `next dev` default in Next.js 15+. Faster HMR. |
| **Turbopack (build)** | Rolling out stable | `next build --turbopack`. Verify before flipping production. |
| **`next/image`** | Stable | Watch transform quota; `sizes` matters; consider Blob+CDN for static catalogs. |
| **`next/font`** | Stable | Self-hosted fonts; zero CLS; subset properly. |
| **Speed Insights** | GA | `<SpeedInsights />` component; real-user Core Web Vitals + INP. |
| **AI SDK v5+** | Stable | `streamText`, `generateText`, `streamObject`, `generateObject`, `tool()`, `useChat()` v2. v3 `streamUI` is deprecated. |
| **AI Elements** | New (2025) | shadcn-layered AI UI component library. |
| **v0 / v0.app** | Active | Chat-driven Next.js + Tailwind + shadcn scaffolding. Output quality moves monthly. |
| **Pages Router** | Legacy | Maintain existing, don't start new. |
| **`getServerSideProps` / `getStaticProps`** | Pages Router only | Replaced by Server Components + Cache Components in App Router. |
| **`unstable_cache`** | Superseded | Cache Components is the replacement for new code. |

## The mental model: PPR + Cache Components + Server Actions

If you internalize three things, the rest follows:

### 1. Every route is a tree of cached + dynamic

With PPR (default in Next.js 16), one route can ship a **static shell** that's prerendered at build time, with **dynamic holes** wrapped in `<Suspense>` that stream in per request. Within those dynamic holes, individual components can be **cached** (with `'use cache'`) at their own TTL/tag.

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react';
import { ProfileHeader } from './profile-header';
import { LiveMetrics } from './live-metrics';
import { TopProductsCached } from './top-products-cached';

export default function Page() {
  return (
    <>
      <ProfileHeader />              {/* Static — prerendered */}
      <Suspense fallback={<TopProductsSkeleton />}>
        <TopProductsCached />        {/* Cached server component, streamed */}
      </Suspense>
      <Suspense fallback={<MetricsSkeleton />}>
        <LiveMetrics />              {/* Dynamic per request, streamed */}
      </Suspense>
    </>
  );
}
```

```tsx
// app/dashboard/top-products-cached.tsx
'use cache';
import { cacheLife, cacheTag } from 'next/cache';

export async function TopProductsCached() {
  cacheLife('hours');             // TTL bucket: revalidate every hour-ish
  cacheTag('top-products');       // Invalidatable tag
  const products = await db.query.topProducts();
  return <ProductList items={products} />;
}
```

Then in a Server Action elsewhere:

```ts
// app/admin/actions.ts
'use server';
import { revalidateTag } from 'next/cache';

export async function refreshTopProducts() {
  // ... do work ...
  revalidateTag('top-products');
}
```

This is the 2026 default. Everything else (raw `fetch(..., { next: { revalidate } })`, `unstable_cache`, `export const revalidate = N`) still works in 15.x and as a fallback in 16, but Cache Components is what you reach for first.

### 2. Server Component by default, Client Component on demand

Every component in `app/` is a Server Component unless you mark it `'use client'`. **The cost of `'use client'`** is real: it ships the component (and its imports) in the client bundle, hydrates, and re-runs on the client. You pay it for **interactivity, browser APIs, hooks, and event handlers** — not for "I want to use a UI library."

Wrong:
```tsx
// app/products/page.tsx
'use client';  // ❌ — added because someone reached for useState in a child
import { ProductCard } from './product-card';
```

Right:
```tsx
// app/products/page.tsx — Server Component
import { ProductGridClient } from './product-grid-client';

export default async function Page() {
  const products = await db.query.products();
  return <ProductGridClient products={products} />;  // ✅ pass data in
}
```

The rule: **Server Components fetch and shape; Client Components react and animate.** The boundary is one component, not one tree. A Server Component can render a Client Component, which can render a Server Component (passed as a `children` prop), which can render a Client Component. Compose the boundary deliberately.

### 3. Server Actions are how mutations happen

Forget API routes for app-internal mutations. Server Actions are functions you call directly from a client form or button, with the framework wiring up the POST endpoint:

```tsx
// app/comments/actions.ts
'use server';
import { auth } from '@/lib/auth';
import { z } from 'zod';
import { revalidateTag } from 'next/cache';

const CommentSchema = z.object({
  postId: z.string().uuid(),
  body: z.string().min(1).max(2000),
});

export async function addComment(formData: FormData) {
  const user = await auth();
  if (!user) throw new Error('Unauthorized');

  const parsed = CommentSchema.parse({
    postId: formData.get('postId'),
    body: formData.get('body'),
  });

  await db.insert(comments).values({ ...parsed, userId: user.id });
  revalidateTag(`comments:${parsed.postId}`);
}
```

```tsx
// app/comments/comment-form.tsx
'use client';
import { useActionState } from 'react';
import { addComment } from './actions';

export function CommentForm({ postId }: { postId: string }) {
  const [state, action, isPending] = useActionState(addComment, null);
  return (
    <form action={action}>
      <input type="hidden" name="postId" value={postId} />
      <textarea name="body" required />
      <button disabled={isPending}>Post</button>
    </form>
  );
}
```

**Critical:** Every Server Action is a public HTTP endpoint with a hidden POST body. **Authorize inside every action.** Validate input. Rate-limit any action that creates state. Never trust formData shape — Zod or equivalent on every parse. See `references/backend-architect.md` for the full Server Action security checklist.

## Rendering strategy decision matrix

Pick the rendering model from the constraints, not the habit. As of Next.js 16:

| Page type | Pick | Why |
|-----------|------|-----|
| Marketing site, blog, docs (data changes via deploy or webhook) | **Cache Components with `cacheLife('weeks')` + on-demand `revalidateTag`** in a webhook handler | Cheap, fast, invalidatable. Old advice was SSG + `revalidatePath`; both work, but Cache Components is more flexible. |
| Public product page with prices that change daily | **PPR — static shell + `<Suspense>` around price block with `'use cache'` + `cacheLife('hours')`** | LCP from static shell; price block updates without rebuilding the whole page. |
| Logged-in dashboard | **Default dynamic (no `'use cache'` on the page) + `'use cache'` on read-heavy components** | Per-user data can't be cached at the page level; cache shared subqueries (e.g., feature flags from Edge Config). |
| Real-time data (chat, live scores, collaborative editing) | **Dynamic + Server-Sent Events / WebSockets from a Client Component / Pusher / Liveblocks / Vercel Realtime** | PPR + Cache Components doesn't make sense; full dynamic, push from server. |
| Admin tool used by 5 people | **Skip Cache Components entirely.** Dynamic everywhere. | Caching cost > value at this volume. |
| AI chat UI | **Dynamic page; AI SDK `streamText` from a Route Handler; `useChat()` on the client** | Streaming is the whole point. Don't cache LLM responses at the route level. Cache at the AI Gateway / prompt layer instead. |
| Static export (no server) | **`output: 'export'` in next.config.ts** | Vercel hosts the export as plain static; you lose Server Components/Actions. Only for genuinely static sites without Vercel's compute. |

**Anti-pattern:** SSR for everything just because it works. Pages that are 95% identical for all users have no business being rendered per request. Use PPR + Cache Components and stream the dynamic 5%.

## Server Component patterns

### Fetching data

```tsx
// app/products/[id]/page.tsx — Server Component
import { notFound } from 'next/navigation';
import { db } from '@/lib/db';

export default async function ProductPage({
  params,
}: {
  params: Promise<{ id: string }>;  // params is a Promise in Next.js 15+
}) {
  const { id } = await params;
  const product = await db.query.products.findFirst({ where: eq(products.id, id) });
  if (!product) notFound();
  return <ProductView product={product} />;
}
```

Notes:
- `params` and `searchParams` are **Promises** in Next.js 15+. Await them. Old `{ params: { id } }` shape is wrong for new code.
- `notFound()` triggers the nearest `not-found.tsx`.
- For dynamic-but-cacheable data, slap `'use cache'` at the top of the file or function and tag it.

### Streaming with Suspense

```tsx
import { Suspense } from 'react';

export default function Page() {
  return (
    <>
      <PageHeader />  {/* Renders immediately */}
      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews />   {/* Async server component, streamed */}
      </Suspense>
      <Suspense fallback={<RecsSkeleton />}>
        <Recommendations />  {/* Parallel — streams independently */}
      </Suspense>
    </>
  );
}
```

Parallel Suspense boundaries stream independently. Don't nest a slow component inside a fast one; flatten so each `<Suspense>` is at the latency boundary you care about.

### Guarding server-only modules

```ts
// lib/server-only-stripe.ts
import 'server-only';  // ❌ throws at build time if imported into a Client Component
import Stripe from 'stripe';
export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
```

```ts
// lib/client-only-analytics.ts
import 'client-only';  // ❌ throws if imported into a Server Component
import { initAnalytics } from 'some-browser-sdk';
```

Combine with `taintUniqueValue` for secrets and `taintObjectReference` for sensitive objects:

```ts
// lib/auth.ts
import 'server-only';
import { experimental_taintUniqueValue, experimental_taintObjectReference } from 'react';

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

If a Client Component renders a tainted object, React throws at serialization time. This is the canonical defense against PII/secret leakage.

## Client Component patterns

### When to reach for `'use client'`

- You need `useState`/`useReducer`/`useRef` for local UI state.
- You need event handlers (`onClick`, `onChange`).
- You need browser APIs (`window`, `localStorage`, `IntersectionObserver`, `matchMedia`).
- You need React lifecycle (`useEffect`, `useLayoutEffect`).
- You need third-party React libraries that internally use hooks (Framer Motion, Radix primitives, most form libs).

### When *not* to

- You "want a UI library." Server Components can render shadcn/ui (most of it), Radix Server Components, and Tailwind perfectly.
- You're rendering static text or layout.
- You're fetching data — fetch on the server, pass as props.

### The "pass server tree as children" trick

```tsx
// Server Component
export default async function Page() {
  const user = await getUser();
  return (
    <ClientShell>
      <ServerUserCard user={user} />  {/* Renders on server, embedded inside client */}
    </ClientShell>
  );
}

// 'use client' shell
'use client';
export function ClientShell({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  return <Sidebar open={open}>{children}</Sidebar>;
}
```

`<ServerUserCard>` stays on the server (no client bundle hit), even though it sits inside `<ClientShell>`. This is the pattern when you need a client wrapper (sidebar, dialog, theme provider) around mostly-server content.

### Optimistic updates

```tsx
'use client';
import { useOptimistic } from 'react';
import { likePost } from './actions';

export function LikeButton({ post }: { post: Post }) {
  const [optimisticLikes, addOptimistic] = useOptimistic(
    post.likes,
    (current, delta: number) => current + delta,
  );

  async function handleClick() {
    addOptimistic(1);
    await likePost(post.id);  // Server Action
  }

  return <button onClick={handleClick}>{optimisticLikes} likes</button>;
}
```

`useOptimistic` rolls back automatically if the Server Action throws.

## Cache Components — the full mental model

`'use cache'` is to Server Components what `'use server'` is to Server Actions: a directive that changes how the function executes.

```tsx
// app/products/list.tsx
'use cache';
import { cacheLife, cacheTag } from 'next/cache';

export async function ProductList({ category }: { category: string }) {
  cacheLife('hours');                       // TTL bucket
  cacheTag(`products:${category}`);         // Invalidation tag
  const items = await db.query.products({ category });
  return <Grid items={items} />;
}
```

Key rules:

1. **`cacheLife` takes a profile string** (`'seconds'`, `'minutes'`, `'hours'`, `'days'`, `'weeks'`, `'max'`) or an explicit `{ stale, revalidate, expire }` object. Tune profiles in `next.config.ts` if you need custom buckets.
2. **`cacheTag` is freeform.** Use shape `kind:id` or `kind:slug` so revalidation is targeted. Avoid global tags like `'all'`.
3. **Cached components MUST be deterministic in their args.** If a function uses `headers()`, `cookies()`, `searchParams`, or any per-request thing, it can't be cached at that scope. Push the dynamic dependency up (to a Suspense boundary that calls a cached child) or use `connection()` to mark the boundary explicitly.
4. **Revalidate via Server Action.** `revalidateTag('products:electronics')` from any Server Action invalidates and triggers re-renders of cached components with that tag on next request.
5. **Don't `'use cache'` a page-level Server Component that depends on per-user data.** That's a slow leak waiting to happen. Cache the underlying shared queries (feature flags, top-level navigation), not the page itself.
6. **`'use cache'` at file scope caches the whole module's exports.** At function scope caches that function. At component scope caches the component's render. Pick the smallest scope that works.

When to use Cache Components vs alternatives:

| Need | Pick |
|------|------|
| Cache a server function's return for an hour, tag-invalidate | `'use cache'` + `cacheLife` + `cacheTag` |
| Cache a `fetch()` result inline | `fetch(url, { next: { revalidate: 3600, tags: ['x'] } })` — still supported; lighter |
| Cache something not from `fetch()` (DB call, computation) | `'use cache'` (was `unstable_cache` pre-16) |
| Route-level revalidation on a timer | `export const revalidate = 3600` (legacy; still works) |
| Force a route to be dynamic | `export const dynamic = 'force-dynamic'` or `connection()` inside the page |

## Data fetching summary

| Pattern | Use case |
|---------|----------|
| Server Component `await db.query.x()` | Default for any data the server can fetch directly. |
| Server Component `await fetch(url, { next: { revalidate, tags }})` | External APIs you want cached. |
| `'use cache'` function | Anything you want cached that isn't a `fetch`. |
| Server Action (mutation) | All writes. |
| Route Handler (`app/api/.../route.ts`) | External callers (webhooks, mobile clients, third-party integrations). Not for app-internal mutations. |
| SWR / TanStack Query / React Query from Client Component → Route Handler | Real-time-ish polling, infinite scroll, manual refetch UX. |
| `useChat()` (AI SDK) | Streaming AI conversations. |

Don't reach for SWR/Query when a Server Component + Suspense gives you the same UX for free. Reach for them when you need polling, infinite scroll, or client-driven invalidation that doesn't have a clean Server Action shape.

## Forms + Server Actions

The end-state form pattern in Next.js 16:

```tsx
// app/contact/page.tsx — Server Component
import { ContactForm } from './contact-form';
export default function Page() {
  return <ContactForm />;
}
```

```tsx
// app/contact/contact-form.tsx — Client Component
'use client';
import { useActionState } from 'react';
import { useFormStatus } from 'react-dom';
import { submitContact } from './actions';

export function ContactForm() {
  const [state, action] = useActionState(submitContact, { ok: false });
  return (
    <form action={action}>
      <input name="email" type="email" required />
      <textarea name="message" required />
      {state.error && <p className="text-red-600">{state.error}</p>}
      {state.ok && <p className="text-green-600">Sent.</p>}
      <SubmitButton />
    </form>
  );
}

function SubmitButton() {
  const { pending } = useFormStatus();
  return <button disabled={pending}>{pending ? 'Sending...' : 'Send'}</button>;
}
```

```ts
// app/contact/actions.ts
'use server';
import { z } from 'zod';

const Schema = z.object({
  email: z.string().email(),
  message: z.string().min(10).max(5000),
});

export async function submitContact(_prev: any, formData: FormData) {
  const parsed = Schema.safeParse({
    email: formData.get('email'),
    message: formData.get('message'),
  });
  if (!parsed.success) return { ok: false, error: 'Invalid input' };

  // ... send email, write DB ...

  return { ok: true };
}
```

`useActionState` gives you `[state, action, isPending]`; `useFormStatus` works from any descendant of the form. Together they handle pending/error/success without a single `useState`.

## Route Handlers — when and how

`app/api/.../route.ts` exposes HTTP endpoints. Use them when:

- A **third-party caller** (webhook, mobile app, integration partner, CLI) needs to hit your domain.
- You need **non-JSON responses** (binary streams, SSE, file downloads).
- You're building a **public API** versioned independently of the app.
- You need a **manual response shape** (custom status codes, headers) the Server Action machinery doesn't expose.

Don't use them for app-internal mutations Server Actions handle better.

```ts
// app/api/webhook/stripe/route.ts
import { headers } from 'next/headers';
import { stripe } from '@/lib/server-only-stripe';
import { after } from 'next/server';

export async function POST(req: Request) {
  const sig = (await headers()).get('stripe-signature')!;
  const body = await req.text();
  const event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!);

  // Return ACK fast; do work after the response is sent.
  after(async () => {
    await handleStripeEvent(event);
  });

  return Response.json({ received: true });
}
```

Note `after()` (formerly `unstable_after`) — schedule post-response work in webhook handlers, on-page logging, etc., without blocking the user.

## Performance budget

The metrics that matter on Vercel:

- **LCP** — largest contentful paint. Aim < 2.5s. Driven by image optimization, font loading, server response time, render-blocking JS.
- **INP** — interaction to next paint (replaced FID in 2024). Aim < 200ms. Driven by main-thread work, hydration cost, third-party scripts.
- **CLS** — cumulative layout shift. Aim < 0.1. Driven by image dimensions, font swap, late-loaded ads/iframes.
- **TTFB** — time to first byte. PPR's static shell crushes this for cached pages.

The big levers on Vercel:

1. **`next/font` for all webfonts.** Self-hosted, swap-optimized, zero CLS from font load.
2. **`next/image` with sizes.** Specifying `sizes` lets Vercel pick the right transform; default `sizes="100vw"` overserves on mobile.
3. **Server Components by default** to avoid client bundle bloat.
4. **Dynamic imports for heavy client components** — `next/dynamic` or `React.lazy()` for things below the fold.
5. **`<Script>` with `strategy="afterInteractive"` or `"lazyOnload"`** for third-party tags. Never use plain `<script>` in App Router.
6. **Speed Insights** — `<SpeedInsights />` in root layout. Real-user metrics, not just lab.
7. **Bundle analyzer** — `@next/bundle-analyzer` in `next.config.ts`; run periodically.
8. **React Compiler** — turn on `experimental.reactCompiler` in `next.config.ts` (verify stability for your version); auto-memoizes and drops most `useMemo`/`useCallback`.

```tsx
// app/layout.tsx
import { Inter } from 'next/font/google';
import { SpeedInsights } from '@vercel/speed-insights/next';
import { Analytics } from '@vercel/analytics/next';

const inter = Inter({ subsets: ['latin'], display: 'swap' });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.className}>
      <body>
        {children}
        <SpeedInsights />
        <Analytics />
      </body>
    </html>
  );
}
```

## Image Optimization — the budget conversation

`next/image` does WebP/AVIF transcoding + multi-size srcset + lazy loading. **Each transform counts against your plan quota.** Easy to blow.

**Defenses:**

1. **Set `sizes` realistically.** A grid image at `w-1/3` on desktop and `w-full` on mobile should be `sizes="(min-width: 768px) 33vw, 100vw"`, not the default `100vw`.
2. **Configure `images.deviceSizes` and `images.imageSizes`** in `next.config.ts` to limit the transform matrix. Defaults generate ~16 sizes per image; you probably need 4-6.
3. **Use `priority` only for above-the-fold LCP-critical images.** Everything else lazy-loads.
4. **For high-volume catalogs (1M+ user-uploaded images), use Cloudflare Images or imgix at the source** and serve via `next/image` with `unoptimized` (or skip `next/image` entirely). Pay them, not Vercel transform quota.
5. **For app icons, logos, decorative imagery — host on Vercel Blob with cache headers**, serve as plain `<img>` or `next/image unoptimized`. Static assets that don't need responsive sizing don't need optimization.
6. **`placeholder="blur"` needs `blurDataURL`.** For user uploads, generate at upload time (Plaiceholder, `sharp`); don't request `placeholder="blur"` without it.

## AI UI patterns

When the surface includes LLM streaming, defer to the AI SDK and AI Elements:

```tsx
// app/chat/page.tsx
import { ChatUI } from './chat-ui';
export default function Page() {
  return <ChatUI />;
}
```

```tsx
// app/chat/chat-ui.tsx
'use client';
import { useChat } from '@ai-sdk/react';
import { Message } from '@ai-elements/message';
import { Composer } from '@ai-elements/composer';

export function ChatUI() {
  const { messages, sendMessage, status } = useChat({
    api: '/api/chat',
  });
  return (
    <div className="flex flex-col h-screen">
      <div className="flex-1 overflow-y-auto">
        {messages.map(m => <Message key={m.id} role={m.role} parts={m.parts} />)}
      </div>
      <Composer onSubmit={text => sendMessage({ text })} disabled={status !== 'ready'} />
    </div>
  );
}
```

```ts
// app/api/chat/route.ts
import { streamText, convertToModelMessages } from 'ai';
import { gateway } from '@ai-sdk/gateway';

export async function POST(req: Request) {
  const { messages } = await req.json();
  const result = streamText({
    model: gateway('anthropic/claude-sonnet-4.7'),
    messages: convertToModelMessages(messages),
  });
  return result.toUIMessageStreamResponse();
}
```

For deeper patterns (tool use, structured outputs with `generateObject`, generative UI with streamUI's modern successor, RAG), see [`references/ai-ml-engineer.md`](ai-ml-engineer.md). For the AI SDK's full surface, delegate to `vercel:ai-sdk` when loaded.

**AI UI rules of thumb:**

- Don't cache LLM responses at the route level (`'use cache'` on the chat page = same response for every user). Cache at the prompt level (AI Gateway prompt cache, Anthropic prompt caching) instead.
- Stream to keep INP low — first token in < 1s matters more than total response time.
- Use AI Elements for `<Message>`, `<Composer>`, `<Reasoning>`, `<Source>`, `<Artifact>` etc. — don't roll your own; they handle accessibility + markdown + tool-call rendering.
- Show pending/streaming state explicitly; "is the AI thinking or is it broken" is a real UX failure mode.

## Routing patterns

- **Static routes:** `app/about/page.tsx` → `/about`.
- **Dynamic segments:** `app/posts/[slug]/page.tsx`. `params` is a Promise.
- **Catch-all:** `app/docs/[...path]/page.tsx`. `params.path` is `string[]`.
- **Route groups:** `app/(marketing)/about/page.tsx` → `/about`. Groups don't affect URL; they let you scope layouts.
- **Parallel routes:** `app/@modal/(.)photo/[id]/page.tsx` — intercepting routes for modals over a list.
- **Loading UI:** `loading.tsx` at any segment → automatic `<Suspense>` boundary.
- **Error UI:** `error.tsx` → segment-level error boundary. Must be Client Component.
- **Not found:** `not-found.tsx` → triggers via `notFound()`.
- **Layouts:** `layout.tsx` persists across navigations; nested layouts compose.
- **Templates:** `template.tsx` re-mounts on navigation (use sparingly — kills perf).
- **Middleware:** `middleware.ts` at the project root. Runs on every matched request *before* the cache. Keep it ruthless. See `vercel:routing-middleware` skill for matcher patterns.

## Metadata + SEO

Server Component metadata is API-driven, not React-driven:

```tsx
// app/posts/[slug]/page.tsx
import type { Metadata } from 'next';

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);
  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      images: [post.coverImage],
    },
    alternates: {
      canonical: `https://example.com/posts/${slug}`,
    },
  };
}
```

- **Static metadata** for static pages: `export const metadata: Metadata = {...}`.
- **Dynamic metadata** via `generateMetadata`.
- **Sitemap:** `app/sitemap.ts` exporting a `MetadataRoute.Sitemap`.
- **Robots:** `app/robots.ts` exporting `MetadataRoute.Robots`.
- **Open Graph images:** `app/opengraph-image.tsx` (or `.png`) per route segment.
- **Structured data:** render `<script type="application/ld+json">` directly in Server Components.
- **`llms.txt`:** put it at `app/llms.txt/route.ts` or as a static file — see the technical-writer / SEO content for current best practices.

## Accessibility

The platform doesn't change a11y; the App Router conventions for it do:

- **Skip Radix/Headless UI defaults** — these handle ARIA correctly. Don't reinvent.
- **Use `next/link`'s `prefetch` deliberately** — `prefetch={true}` (default) prefetches on hover for in-viewport links; can over-fetch on long lists. `prefetch={false}` for low-priority links.
- **Manage focus across navigations** — Next.js handles announcement and focus reset, but custom transitions need manual focus management.
- **Test with Lighthouse + axe** in CI. Vercel Speed Insights doesn't cover a11y.

## i18n

- **App Router i18n is not built-in**; pick `next-intl` (most active) or `next-i18next` (Pages-era, ported).
- **Locale segment pattern:** `app/[locale]/...` plus middleware to detect/redirect.
- **Defer to `next-intl` docs for the current pattern**; the API has shifted with Server Components + Server Actions.

## Testing the frontend layer

| Layer | Tool | What you test |
|-------|------|---------------|
| Unit (utilities, hooks) | Vitest | Pure functions, custom hooks |
| Component (Client Components) | Vitest + React Testing Library | Rendering, event handlers, optimistic UI |
| Server Components | Vitest + RTL (with `@testing-library/react` 16+) or Playwright Component Test | Render output, but most are tested via E2E |
| Server Actions | Vitest — call the action directly | Auth, validation, side effects (mock DB) |
| Route Handlers | Vitest — `await POST(new Request(...))` | Status, body, side effects |
| E2E | Playwright against Preview Deployment URL | Critical user flows |
| Visual regression | Playwright + Argos / Chromatic | Per-PR visual diff |
| Accessibility | Playwright + axe-core | a11y violations gate the PR |

For Vercel-specific patterns (Preview URL E2E, Comments-driven testing), see [`references/devops-engineer.md`](devops-engineer.md).

## v0 — how to use it without regret

v0 (v0.dev / v0.app) generates Next.js + Tailwind + shadcn components and full pages from chat prompts. As of 2026 it's good enough to do real work, but not good enough to ignore:

**Use it for:**
- Initial UI scaffolds (landing page, dashboard layout, form skeleton).
- Component variations ("a card component, three variants, with these props").
- Translating Figma/screenshots into a working starting point.
- Iterating on copy + visual variants quickly.

**Don't use it for:**
- Production data fetching (it'll write naive client-side fetches you don't want).
- Server Actions + Cache Components topology (it's getting better, but architecture is still on you).
- Security-sensitive forms (validation, auth, taint).
- Final accessibility polish (review every output for focus order, semantic HTML, ARIA correctness).

**Workflow:** generate with v0 → import into the codebase → wire up real data via Server Components/Actions → audit a11y + perf → ship.

## Preview Deployments — the dev loop

Every PR/branch gets a Vercel Preview URL. The frontend-architect loop:

1. **Push to branch** → Vercel builds + comments the Preview URL on the PR.
2. **Open the Preview URL** → use the Vercel Toolbar to inspect:
   - Speed Insights real-user data (if anyone's hit it).
   - Comments to leave inline feedback on specific elements.
   - "Open in v0" for AI-assisted iteration.
   - Edit Mode (where supported) for quick text fixes.
3. **Run E2E** against the Preview URL in CI (Playwright `BASE_URL=<preview>`).
4. **Visual regression** vs the previous deployment.
5. **Merge** → production deploy is one git operation; rollback is one click.

**Tip:** wire `vercel:deployments-cicd` skill (when loaded) for branch protection / required checks; or use GitHub Actions with `vercel deploy` + comment-style report. Don't let "the Preview URL looks fine" be the only gate.

## Patterns and anti-patterns

### Pattern: Streaming-first data shape

Design pages so the *static shell* loads in < 200ms TTFB, *fast dynamic* (auth check, top nav) streams in < 500ms, *slow dynamic* (recs, analytics) streams in < 2s. PPR + Suspense gives you the structure; your job is wrapping the slow bits.

### Pattern: Cache at the right granularity

Cache the **shared subqueries** (feature flags, top-level navigation, public catalog), not the **per-user page**. Server Component pages stay dynamic; their cached child components carry the cache.

### Pattern: Server Action + revalidateTag

Mutations from the client are Server Actions. Server Actions call `revalidateTag('thing')`. Reads are Server Components with `'use cache'` + `cacheTag('thing')`. The loop is closed without any client-side cache management.

### Pattern: Edge Config for hot-path config

Feature flags, allowlists, A/B test variants, geo-routing rules — anything that's read on every request — go to Edge Config (ultra-low-latency, <15ms read globally). Read in middleware or Server Components via `@vercel/edge-config`. Don't put these in the DB.

### Anti-pattern: `'use client'` at the page root

A whole page being a Client Component means zero static shell, zero streaming benefit, full client bundle. If a page has *any* interactivity, isolate the interactive parts into Client Component children; keep the page itself a Server Component.

### Anti-pattern: Fetching in `useEffect`

`useEffect` + `fetch` + `setState` in a Client Component is almost always wrong in 2026. Fetch on the server, pass as props. Or use TanStack Query against a Route Handler if you need polling. Only reach for `useEffect`-fetch when the data is truly client-only (e.g., reading IndexedDB).

### Anti-pattern: Caching everything

"I'll just put `'use cache'` on everything to make it fast." Then you can't invalidate (you forgot `cacheTag`), the cache is full of stale data, and you have no idea what's coming from where. Cache deliberately, tag everything you cache, prefer shorter TTLs.

### Anti-pattern: Middleware that hits a DB

Edge Middleware is on the hot path of *every* matched request. A DB query in middleware multiplies your DB load by your request volume. Keep middleware to: cookie reads, Edge Config reads, geo lookups, simple redirects. Push DB-dependent logic into the page/action.

### Anti-pattern: Pages Router for new code

`pages/api/` and `getServerSideProps` work. They're not future. Every new feature goes App Router; existing Pages Router code gets migrated when the next significant change touches it. Mixed-router codebases are a tax on every engineer's mental model.

### Anti-pattern: `useEffect` to call a Server Action

Server Actions are designed to be called from forms, buttons, and `useTransition`. Calling one from `useEffect` is almost always a sign you wanted a Route Handler with TanStack Query, or you wanted to fetch on the server.

### Anti-pattern: Returning sensitive DB objects from Server Components

A Server Component fetches a `User` row, passes it as a prop to a Client `<UserCard>`. The User has `passwordHash`, `stripeCustomerId`, `internalNotes` — all serialized to the browser. **Map to a `ClientSafeUser` shape before crossing the boundary.** Or `experimental_taintObjectReference(user)` to make the boundary cross throw.

## Tooling specifics

| Tool | Use |
|------|-----|
| **`pnpm` / `bun`** | Recommended package managers. `npm` works; `yarn` is fine. |
| **`next dev --turbopack`** (default in 15+) | Local dev with HMR. |
| **`next build`** / `next build --turbopack` | Production build. Turbopack build is rolling out; verify stability for your version. |
| **`vercel dev`** | Run the whole Vercel emulator locally — useful for Functions outside Next.js or testing `vercel.json` rewrites. |
| **`vercel deploy`** | CLI deploy. CI usually integrates via Git; manual deploy for one-offs. |
| **`vercel env pull`** | Sync env vars into `.env.local`. |
| **`vercel link`** | Link a local repo to a Vercel project. |
| **`@vercel/speed-insights`** | RUM Core Web Vitals. |
| **`@vercel/analytics`** | First-party privacy-friendly analytics. |
| **`@vercel/edge-config`** | Edge Config client. |
| **`@vercel/blob`** | Blob storage client. |
| **`@neondatabase/serverless`** | Recommended Postgres client when on Marketplace Neon. |
| **`@ai-sdk/react`, `@ai-sdk/gateway`, `ai`** | AI SDK packages. |
| **shadcn CLI** | Component scaffolding; v2 schema includes Vercel + Tailwind v4 setup. |
| **Vitest + React Testing Library** | Unit + component tests. |
| **Playwright** | E2E + visual regression. |
| **`@next/bundle-analyzer`** | Bundle size auditing. |
| **`eslint-config-next`** | Linting; pairs with the team's general ESLint config. |
| **TypeScript strict mode** | Always on. `noUncheckedIndexedAccess` is recommended; expect a few `[]?.` patterns. |
| **v0 (v0.app)** | UI scaffolding from prompts. |

## Cross-references

- **`vercel:nextjs` skill** — definitive Next.js depth when loaded; delegate.
- **`vercel:react-best-practices` skill** — React + Next.js performance patterns; delegate for perf depth.
- **`vercel:next-cache-components` skill** — Cache Components deep dive; delegate.
- **`vercel:ai-sdk` skill** — AI SDK depth; delegate for AI UI specifics.
- **`vercel:routing-middleware` skill** — middleware + routing patterns; delegate.
- **`vercel:turbopack` skill** — Turbopack config; delegate.
- **`vercel:auth` skill** — auth patterns (NextAuth-style); delegate.
- **`vercel:next-upgrade` skill** — version migrations; delegate.
- **`references/backend-architect.md`** — Server Action security, Route Handlers, Functions topology, Workflow, Queues, Sandbox.
- **`references/ai-ml-engineer.md`** — AI SDK depth on the server side, AI Gateway, Vercel Agent, RAG patterns.
- **`references/devops-engineer.md`** — deployment loop, Preview URLs, env vars, monitoring.
- **`references/system-architect.md`** — when to choose Vercel as the whole platform vs frontend-only.

## Integration with always-on protocols

- **TDD on the frontend layer:** Vitest + RTL for Client Components and pure functions. Server Components and Server Actions are tested by direct call in Vitest plus E2E in Playwright against a Preview URL. The TDD cycle for a new feature: failing Playwright E2E → failing component test → failing action unit test → minimal Server Action → minimal Server Component + Client wrapper → all green → refactor.
- **Verification:** before claiming a feature works, you must have (a) the Preview URL link, (b) a Playwright E2E that exercises the flow, (c) Speed Insights showing LCP/INP within budget, (d) a screen-reader walkthrough (manual or axe-core). Saying "it works locally" is not verification on Vercel.
- **Debugging:** Server Component issues show in the *server* log (Vercel Functions log + your terminal in dev), not the browser console. `console.log` in a Server Component goes to the function log. Network tab shows the streamed RSC payload; install React DevTools (browser + RSC inspector). For "hydration mismatch" — find the suspect Client Component, log on server + client, look for `Date.now()`/`Math.random()`/locale-dependent rendering.
- **Plan execution:** for any feature spanning a Server Component + Client Component + Server Action + Cache Components + Migration, write the gates: schema migration → action with tests → Server Component with tests → Client Component with tests → E2E green → Preview URL review → merge. Don't skip steps to "just ship the UI" — Cache Components mistakes are hard to debug later.
- **Branch safety:** rely on Preview Deployments for review. Every PR has its own URL. Wire required checks (lint, test, Playwright E2E against Preview URL, Speed Insights threshold) to block merge. Vercel's GitHub integration surfaces the Preview status; pair with branch protection rules.
- **Review:** before merging UI changes, do the four-screen review: desktop / mobile / dark mode / reduced motion. Plus screen reader pass. Plus throttled network. Vercel Toolbar makes this easier on the Preview URL.

## Common migration: Pages Router → App Router

If you inherit a Pages Router codebase and need to land on the 2026 Vercel surface, plan in waves rather than as a big-bang. The skill `vercel:next-upgrade` (when loaded) drives the mechanics; this is the strategic shape:

### Wave 1: Make the App Router runnable alongside

- Both routers coexist in the same project. Existing `pages/` keeps working.
- Add `app/layout.tsx` + `app/page.tsx` for one new route. Verify dev + Preview Deployment.
- Stand up the shared shell (Header, Footer, Theme provider as Client Component).

### Wave 2: Migrate leaf routes first

- Move new feature work to App Router.
- Migrate existing low-traffic Pages routes (about, contact, marketing) — they're easy: replace `getStaticProps` with a Server Component that fetches directly + `'use cache'`.
- Migrate Pages API routes used by only one Pages route at a time: turn them into Server Actions or Route Handlers; update callers.

### Wave 3: Migrate the dashboard / authenticated surface

- This is where the Server Components vs Client Components decision is real. Audit each page: what's data fetching (Server Component), what's interactive (Client Component).
- Auth: move from `getServerSideProps(ctx)` + cookie reading to `cookies()` + a server-side `auth()` helper.
- Migrate `getServerSideProps` data fetch → Server Component `await db.query.X()`.
- Migrate mutations from Pages API routes + `fetch()` calls to Server Actions.

### Wave 4: Adopt Cache Components + PPR

- Once App Router is the default, opt into Cache Components on per-route or per-component basis. Don't blanket-enable.
- Set `experimental.ppr = 'incremental'` and add `experimental_ppr = true` on routes you've validated.
- Update CI to run E2E + visual regression at each opt-in step.

### Wave 5: Retire Pages

- Remove `pages/` directory entirely.
- Remove Pages-era dependencies (e.g., `next-i18next` → `next-intl`, custom `_app.tsx`/`_document.tsx` shells).
- Update lint rules to enforce App Router-only patterns.

Common gotchas:

- **`useRouter`** — `next/router` (Pages) vs `next/navigation` (App). Imports differ. `router.push` semantics differ slightly.
- **`getServerSideProps` → Server Component** — same idea (server-side fetch), but no `ctx`; use `cookies()`, `headers()`, `searchParams` (Promise).
- **API routes → Server Actions or Route Handlers** — decide per case based on caller type.
- **`_app.tsx` → `app/layout.tsx`** — wraps every route; Client Component if it has providers.
- **`_document.tsx` → root layout** — `<html>` and `<body>` go in root layout.
- **`getStaticPaths` → `generateStaticParams`** — same idea, different signature.
- **`Link` is the same** — but `legacyBehavior` prop is gone in 14+.
- **Image import** — same `next/image`.
- **CSS modules + Tailwind** — same.

## Streaming details — what users actually see

PPR + Suspense gives you streaming, but the **shape** of the stream affects perceived performance.

### Use a meaningful skeleton

A blank `<Suspense fallback={null}>` gives users zero feedback. Better:

```tsx
<Suspense fallback={
  <div className="grid grid-cols-3 gap-4">
    {Array.from({ length: 6 }).map((_, i) => (
      <div key={i} className="aspect-square bg-muted animate-pulse rounded" />
    ))}
  </div>
}>
  <ProductGrid />
</Suspense>
```

The skeleton should *match the eventual layout* — same grid columns, same approximate height — to avoid CLS when content arrives.

### Avoid nested waterfalls

```tsx
// ❌ Waterfall — Reviews don't start until Header finishes
<Suspense fallback={<HeaderSkeleton />}>
  <Header />
  <Suspense fallback={<ReviewsSkeleton />}>
    <Reviews />
  </Suspense>
</Suspense>
```

```tsx
// ✅ Parallel — both stream independently
<Suspense fallback={<HeaderSkeleton />}><Header /></Suspense>
<Suspense fallback={<ReviewsSkeleton />}><Reviews /></Suspense>
```

If a component genuinely depends on another's data, fetch in parallel inside the parent server component and pass results down — don't nest Suspense for sequential awaits.

### Stream order matters less than you'd think

Vercel's streaming sends boundaries in declaration order, but React's renderer dispatches as soon as a child resolves. Users see content fill in roughly as fast as the slowest of each branch. Optimize for the longest pole, not the average.

## Routing transitions + `useTransition`

Client-side navigation in App Router is async — clicking a `<Link>` triggers a server render of the next page, streams it back, then the URL updates. During the transition, the framework shows the current page (not a flash of nothing).

Sometimes you want to know transition is happening:

```tsx
'use client';
import { useTransition } from 'react';
import { useRouter } from 'next/navigation';

export function TabButton({ href, label }: { href: string; label: string }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  function handleClick() {
    startTransition(() => router.push(href));
  }

  return (
    <button onClick={handleClick} disabled={isPending}>
      {isPending ? 'Loading...' : label}
    </button>
  );
}
```

For form submissions, `useFormStatus` (inside a `<form>`) and `useActionState`'s pending flag are usually what you want; `useTransition` is for non-form transitions like programmatic navigation or filter changes.

## Search params + dynamic data without breaking caching

`searchParams` in App Router is a Promise in 15+. Reading it inside a Server Component opts that component out of static rendering — it becomes dynamic for that request. That's fine for a search page; not fine if you wanted the rest of the page cached.

The 2026 pattern:

```tsx
// app/search/page.tsx
import { Suspense } from 'react';

export default function Page({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  return (
    <>
      <SearchHeader />  {/* Cacheable; doesn't read searchParams */}
      <Suspense fallback={<ResultsSkeleton />}>
        <SearchResults searchParams={searchParams} />  {/* Reads searchParams; dynamic */}
      </Suspense>
    </>
  );
}

async function SearchResults({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q = '' } = await searchParams;
  const results = await search(q);
  return <ResultsList items={results} />;
}
```

Wrap the dynamic-on-searchParams part in a Suspense boundary so the rest of the page can prerender.

## Dark mode + theming

Theming pattern that works with Server Components:

1. **Server-side detect from cookie** (e.g., `theme=dark` cookie set by Client Component on toggle).
2. **Set class on `<html>`** in root layout.
3. **CSS variables for theme tokens.**

```tsx
// app/layout.tsx
import { cookies } from 'next/headers';

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const theme = (await cookies()).get('theme')?.value ?? 'light';
  return (
    <html lang="en" className={theme === 'dark' ? 'dark' : ''}>
      <body>{children}</body>
    </html>
  );
}
```

```tsx
// components/theme-toggle.tsx
'use client';
import { useState } from 'react';

export function ThemeToggle({ initial }: { initial: 'light' | 'dark' }) {
  const [theme, setTheme] = useState(initial);
  function toggle() {
    const next = theme === 'light' ? 'dark' : 'light';
    document.cookie = `theme=${next}; path=/; max-age=31536000`;
    document.documentElement.classList.toggle('dark');
    setTheme(next);
  }
  return <button onClick={toggle}>{theme === 'dark' ? 'Light' : 'Dark'} mode</button>;
}
```

`next-themes` is the popular library; same pattern. The Server Component sets the initial class to avoid a flash on first render.

## Localization (i18n)

`next-intl` is the actively maintained pick for App Router. Pattern:

```
app/
  [locale]/
    layout.tsx          ← reads locale, sets <html lang=...>
    page.tsx
    products/
      [id]/
        page.tsx
  globals.css
middleware.ts           ← detects locale, redirects /xx → /en/xx if no match
messages/
  en.json
  fr.json
  ja.json
```

```tsx
// app/[locale]/layout.tsx
import { NextIntlClientProvider } from 'next-intl';
import { getMessages } from 'next-intl/server';

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const messages = await getMessages();
  return (
    <html lang={locale}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
```

Server Components get translations via `getTranslations('namespace')`; Client Components via `useTranslations('namespace')`.

Don't ship every locale to the client — only the active locale's messages. `next-intl` handles this; verify your config.

## Error handling

Three levels:

1. **Route-level**: `error.tsx` at any segment is a Client Component that wraps the segment. Catches render errors below it. Pair with a `reset` button that re-renders.
2. **Component-level**: classic React error boundaries. `react-error-boundary` lib gives a Client Component wrapper.
3. **Global**: `app/global-error.tsx` for catastrophic crashes (rare).

```tsx
// app/products/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="p-8">
      <h2>Something went wrong loading products.</h2>
      <button onClick={reset} className="btn-primary">Try again</button>
    </div>
  );
}
```

`error.digest` is the Vercel-side error ID — log it; users can include it in support requests.

Don't `console.error` to console only; ship errors to Sentry (Marketplace) or Datadog (Marketplace) with structured context. Server-side errors go to function logs + log drain; client-side errors need explicit `Sentry.captureException` or similar.

## Quick reference: the 2026 frontend-architect checklist

Every Vercel frontend feature should clear this list before merge:

- [ ] Page is App Router (`app/`), not Pages Router (`pages/`).
- [ ] Components default to Server Component; `'use client'` is justified per file.
- [ ] Server-only modules import `'server-only'`; client-only import `'client-only'`.
- [ ] Sensitive server objects use `experimental_taintObjectReference`.
- [ ] Mutations go through Server Actions; auth + validation inside every action.
- [ ] Read-heavy server data is in a `'use cache'` block with `cacheTag()` + `cacheLife()`.
- [ ] Server Actions that mutate cached data call `revalidateTag()` for the right tag.
- [ ] Loading + error UI exists (`loading.tsx` / `error.tsx`) per significant segment.
- [ ] Suspense boundaries wrap independently slow components.
- [ ] Forms use `useActionState` + `useFormStatus`, not manual `useState` for pending.
- [ ] Images use `next/image` with realistic `sizes`; LCP image has `priority`.
- [ ] Fonts use `next/font` with `display: 'swap'`.
- [ ] Bundle analyzer run recently; no unexpected heavy dependencies on first paint.
- [ ] `<SpeedInsights />` and `<Analytics />` in root layout.
- [ ] Metadata via `generateMetadata` or `export const metadata`; OG image + canonical set.
- [ ] Middleware is lean — no DB queries; matcher is scoped.
- [ ] Preview URL has been opened, scrolled, dark-moded, screen-readered.
- [ ] Playwright E2E covers the critical path on the Preview URL.
- [ ] No `console.log` left in code (or wrapped in `process.env.NODE_ENV !== 'production'`).
- [ ] If AI SDK in use: streaming works, error states are shown, no PII in client-side prompts.
- [ ] Server Action encryption key (`NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`) is set in production env if cross-region or rollover-sensitive.
- [ ] If new feature requires env var, it's set in all three environments (Production, Preview, Development) on Vercel.
