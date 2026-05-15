# React Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features. React ecosystem moves fast.**

## Table of Contents
1. [React 18 & 19](#1-react-18--19)
2. [Meta-Frameworks](#2-meta-frameworks)
3. [State Management](#3-state-management)
4. [Styling](#4-styling)
5. [Component Libraries](#5-component-libraries)
6. [Forms and Validation](#6-forms-and-validation)
7. [Testing](#7-testing)
8. [Performance](#8-performance)
9. [Build Tools](#9-build-tools)
10. [Routing](#10-routing)
11. [Data Fetching](#11-data-fetching)

---

## 1. React 18 & 19

### React 18 (Stable)
- **Concurrent Rendering**: Automatic batching, `useTransition`, `useDeferredValue`
- **Suspense for data**: `<Suspense fallback={...}>` with streaming SSR
- **Server Components**: Initial support (via frameworks like Next.js)
- **Streaming SSR**: `renderToPipeableStream` for progressive HTML delivery
- **Selective Hydration**: Prioritize hydrating interactive parts first

### React 19 Features
- **Server Components (RSC)**: Render on server, zero client JS. Default in Next.js App Router.
- **Server Actions**: `"use server"` functions called from client components. Form mutations without API routes.
- **`use()` hook**: Unwrap promises and context in render. Replaces some useEffect patterns.
- **`useFormStatus`**: Track pending state of form submissions.
- **`useOptimistic`**: Optimistic UI updates during mutations.
- **`useActionState`**: Manage action state (replaces some reducer patterns).
- **React Compiler (React Forget)**: Auto-memoization. No more manual `useMemo`/`useCallback`. Opt-in, framework-integrated.
- **Document Metadata**: `<title>`, `<meta>`, `<link>` in components hoisted to `<head>` automatically.
- **Asset Loading**: Preload stylesheets, fonts, scripts with Suspense integration.
- **`ref` as prop**: No more `forwardRef` — ref is a regular prop.
- **Context as provider**: `<Context>` instead of `<Context.Provider>`.

### Server Components Paradigm
```
Server Component (async, no hooks, no browser APIs)
├── Fetches data directly (database, API)
├── Renders HTML
├── Zero client JS bundle
└── Can contain Client Components

Client Component ("use client")
├── Has hooks (useState, useEffect, etc.)
├── Browser APIs (DOM, events)
├── Adds to client JS bundle
└── Cannot import Server Components (but can receive them as children/props)
```

**Mental model**: Server Components for data + layout, Client Components for interactivity.

---

## 2. Meta-Frameworks

### Next.js (App Router — Current Standard)
- **Server Components by default**: Every component is a server component unless marked `"use client"`
- **File-based routing**: `app/page.tsx`, `app/about/page.tsx`, `app/users/[id]/page.tsx`
- **Layouts**: `layout.tsx` — persistent across navigations, nested layouts
- **Loading**: `loading.tsx` — automatic Suspense boundary per route
- **Error handling**: `error.tsx` — route-level error boundary
- **Server Actions**: `"use server"` for form mutations
- **Metadata API**: `export const metadata = {}` or `generateMetadata()` for dynamic SEO
- **ISR**: `export const revalidate = 3600` per route (legacy pattern)
- **Cache Components** (Next.js 16+): `'use cache'` directive with `cacheLife()` and `cacheTag()` — replaces ISR/revalidate patterns as default caching model
- **PPR (Partial Prerendering)**: Static shell + streamed dynamic content — now default rendering model in Next.js 16+
- **Image Optimization**: `next/image` — auto WebP/AVIF, srcset, lazy loading, blur placeholder
- **Middleware**: Edge middleware for auth, redirects, A/B testing
- **Turbopack**: `next dev --turbo` for faster dev server

**When to choose Next.js**: Most React projects. SSR/SSG/ISR needs. SEO-critical apps. Full-stack with Server Actions.

### React Router v7 / Remix (v7.13+)
Remix has **merged into React Router v7**. Three operating modes:

1. **Framework Mode** (full Remix replacement): File-based routing, loaders/actions, SSR, route modules
2. **Data Mode**: Manual route config with loader/action support via `createBrowserRouter`
3. **Declarative Mode**: Traditional `<BrowserRouter>`/`<Routes>` for simple SPAs

- **Loaders**: Route-level data fetching (server or client)
- **Actions**: Form submission handling with progressive enhancement
- **Nested routing**: Parent layouts with `<Outlet>`, parallel data loading
- **View Transitions**: `useViewTransitionState` hook
- **Vite-based**: Fast dev server, future `v8_viteEnvironmentApi`

**When to choose**: Progressive enhancement priority. Form-heavy apps. Lighter than Next.js.

### TanStack Start
- Full-stack React framework from TanStack (TanStack Router + Query + Form)
- File-based routing with full type safety
- Server functions for data fetching
- **When to choose**: Teams heavily invested in TanStack ecosystem.

### Astro (with React)
- Content-first framework. Ships zero JS by default.
- React components as "islands": `<ReactComponent client:load />`
- **When to choose**: Content-heavy sites (blogs, docs, marketing) with some React interactivity.

### Gatsby — Dead
- Acquired by Netlify (Feb 2023), Gatsby Cloud shut down.
- No significant releases since Gatsby 5 (Nov 2022). Repository barely maintained.
- **Do not use for new projects**. Migrate existing to Astro or Next.js.

---

## 3. State Management

### The Decision Framework
```
Server data (API responses)? → TanStack Query
Form state? → React Hook Form or useActionState
URL state (filters, search)? → useSearchParams
UI state (modals, toggles)? → useState
Shared UI state (theme, auth)? → Context or Zustand
Complex client state? → Zustand or Jotai
```

### TanStack Query (Server State) — Recommended
- Cache, refetch, invalidate, paginate server data
- `useQuery`, `useMutation`, `useInfiniteQuery`
- Automatic background refetching, stale-while-revalidate
- Optimistic updates via `onMutate`
- Devtools for debugging cache state
- **Use for**: Any API data fetching. Replaces most Redux use cases.

### Zustand (Client State) — Recommended
- Minimal, hook-based store. No boilerplate.
- `const useStore = create((set) => ({ count: 0, inc: () => set(s => ({ count: s.count + 1 })) }))`
- Middleware: persist (localStorage), immer (immutable updates), devtools
- **Use for**: Global client state (theme, sidebar open, user preferences).

### Jotai (Atomic State)
- Bottom-up atomic state model. Each atom is independent.
- `const countAtom = atom(0)` → `const [count, setCount] = useAtom(countAtom)`
- Derived atoms: `const doubleAtom = atom(get => get(countAtom) * 2)`
- **Use for**: When state is naturally atomic/independent. Fine-grained updates.

### Redux Toolkit — Still Relevant?
- Still used in large existing codebases.
- RTK Query handles server state (similar to TanStack Query).
- **For new projects**: TanStack Query + Zustand covers most needs with less boilerplate.
- **Use when**: Large team with Redux expertise, complex client-side state machines.

### Recoil — Abandoned
- Meta deprioritized; never reached 1.0. Team reassigned.
- **Do not use for new projects**. Use Jotai (similar atomic model, actively maintained).

---

## 4. Styling

### Tailwind CSS (v4) — Recommended Default
- Utility-first CSS. No context-switching between component and style files.
- v4: CSS-first configuration, Lightning CSS engine, automatic content detection
- Works with Server Components (no runtime JS)
- **Ecosystem**: tailwindcss-animate, tailwind-merge, clsx/cva for variants

### CSS Modules
- Scoped CSS by default. `.module.css` files.
- Works with Server Components (no runtime)
- Good for: teams preferring traditional CSS, component-scoped styles

### CSS-in-JS — Status in RSC Era
- **styled-components, Emotion**: Require client-side runtime. **Incompatible with Server Components** in streaming SSR.
- **Vanilla Extract**: Zero-runtime, compile-time CSS-in-JS. Works with RSC.
- **Panda CSS**: Build-time CSS-in-JS from Chakra team. RSC-compatible.
- **StyleX (Meta)**: Atomic CSS-in-JS, compile-time. Used at Meta. RSC-compatible.
- **Recommendation**: Tailwind CSS or CSS Modules for new projects. Avoid runtime CSS-in-JS with Server Components.

### UnoCSS
- Atomic CSS engine (like Tailwind but more flexible/extensible)
- Preset system: Tailwind compat, Windi CSS, pure CSS icons
- Faster than Tailwind in compilation

---

## 5. Component Libraries

### shadcn/ui — Recommended
- Not a library — copy-paste components into your project
- Built on Radix UI (headless) + Tailwind CSS
- Full ownership: customize freely, no version lock-in
- Components: Button, Dialog, Dropdown, Form, Table, Toast, etc.
- CLI: `npx shadcn@latest add button`

### Radix UI (Headless)
- Unstyled, accessible primitives
- Focus management, keyboard navigation, ARIA built-in
- Components: Dialog, Dropdown, Tooltip, Tabs, Accordion, etc.
- Foundation for shadcn/ui

### React Aria (Adobe)
- Comprehensive accessibility hooks and components
- Internationalization built-in
- RAC (React Aria Components) for pre-built accessible components
- **When to use**: Maximum accessibility compliance, complex widget patterns

### MUI (Material UI)
- Largest React component library. Material Design based.
- **When to use**: Internal tools, dashboards, admin panels where custom design isn't needed.
- Heavier bundle, less customizable than headless approaches.

### Headless UI (Tailwind Labs)
- Unstyled, accessible components designed for Tailwind CSS
- Fewer components than Radix but tightly integrated with Tailwind
- Menu, Listbox, Combobox, Dialog, Disclosure, Tabs, Transition

---

## 6. Forms and Validation

### React Hook Form — Recommended
- Uncontrolled forms for performance (no re-render per keystroke)
- `useForm()`, `register`, `handleSubmit`
- Zod integration via `@hookform/resolvers/zod`
- Works with any component library
- DevTools for form state inspection

### Conform (Server Actions)
- Progressive enhancement for forms with Server Actions
- Works without JS (native form submission)
- Zod/Yup validation on both client and server
- **When to use**: Next.js/Remix with Server Actions, progressive enhancement

### TanStack Form
- Headless form management with type safety
- Framework-agnostic (React, Vue, Angular, Solid, Lit)
- Async validation, field-level validation
- **When to use**: Complex forms with TanStack ecosystem

### Zod for Validation
- Define schema once, use for form validation + API validation + TypeScript types
- `z.infer<typeof schema>` for type derivation
- Works with React Hook Form, Conform, TanStack Form, Server Actions

---

## 7. Testing

### Vitest — Recommended
- Vite-powered, fast, ESM-native
- Jest-compatible API (drop-in migration)
- Built-in TypeScript, code coverage, snapshot testing
- Watch mode with instant re-runs

### React Testing Library
- Test components from user perspective (not implementation)
- `render`, `screen.getByRole`, `fireEvent`, `waitFor`
- Queries by role, label, text (accessible selectors)
- **Philosophy**: The more tests resemble usage, the more confidence they give

### Playwright — E2E
- Cross-browser (Chromium, Firefox, WebKit)
- Auto-waiting, tracing, screenshots, video recording
- Component testing mode (render individual components)
- **When to use**: Critical user flows, checkout, auth, multi-step forms

### Storybook
- Component development and documentation tool
- Visual testing with Chromatic (screenshot comparison)
- Interaction testing within stories
- Accessibility testing addon (axe-core)
- **When to use**: Design system development, component catalog

### MSW (Mock Service Worker)
- Network-level API mocking. Intercepts fetch/XHR.
- Works in tests AND browser (dev mode)
- Realistic mock behavior (delays, errors)

---

## 8. Performance

### React Compiler (React Forget)
- Auto-memoization — no manual `useMemo`/`useCallback`
- Compiler analyzes component and inserts memoization where needed
- Opt-in, integrated with Next.js
- **Impact**: Simpler code, fewer bugs from missing dependency arrays

### Code Splitting
- Route-level: Each page is a separate chunk (automatic in Next.js, Remix)
- Component-level: `React.lazy(() => import('./HeavyComponent'))`
- Library-level: Dynamic import for heavy libraries (chart libs, editors)

### Suspense Boundaries
- Declarative loading states: `<Suspense fallback={<Skeleton />}>`
- Streaming SSR: content streams as it becomes available
- Nested Suspense for granular loading states
- `loading.tsx` in Next.js: automatic Suspense per route segment

### Selective Hydration
- React 18: Prioritizes hydrating components the user is interacting with
- Components wrapped in `<Suspense>` can hydrate independently
- Improves INP by not blocking on full-page hydration

### View Transitions API
- Smooth page transitions in multi-page or SPA navigation
- `document.startViewTransition()` for same-document
- Cross-document view transitions (Chrome)
- Next.js: experimental `viewTransition` support

---

## 9. Build Tools

### Vite — Default Choice
- Dev: Native ESM, instant HMR (< 50ms)
- Production: Rollup bundling with optimizations
- React plugin: `@vitejs/plugin-react` (Babel) or `@vitejs/plugin-react-swc` (SWC, faster)

### Turbopack (Next.js)
- Rust-based. Faster than Vite for large Next.js projects.
- `next dev --turbo`. Production builds still use Webpack (migrating).

### SWC
- Rust-based JS/TS compiler. Replaces Babel.
- 20x faster than Babel for transforms.
- Used by Next.js, Vite (via plugin-react-swc), Turbopack.

### Rspack / Rsbuild
- Webpack-compatible Rust bundler. 5-10x faster.
- Module Federation support.
- **When to use**: Migrating from Webpack without config rewrite.

---

## 10. Routing

### Next.js App Router
- File-based: `app/page.tsx`, `app/users/[id]/page.tsx`
- Layouts: `layout.tsx` persists across navigations
- Parallel routes: `@modal/page.tsx` for simultaneous views
- Intercepting routes: `(..)photo/[id]/page.tsx` for modal-over-page patterns
- Route groups: `(marketing)/` and `(app)/` for organization without URL impact

### React Router v7
- **Framework mode** (formerly Remix): Loaders, actions, nested routes, server rendering
- **Library mode**: Client-side routing (SPA)
- Type-safe routes with `defineRoute`
- Lazy loading route modules

### TanStack Router
- **Fully type-safe**: Route params, search params, loaders all typed
- File-based or code-based routing
- Built-in search param state management
- Devtools for route inspection
- **When to use**: Maximum type safety for routing, TanStack ecosystem

---

## 11. Data Fetching

### Server Components (Next.js App Router)
```tsx
// Server Component — runs on server, no client JS
async function UserPage({ params }) {
  const user = await db.user.findUnique({ where: { id: params.id } });
  return <UserProfile user={user} />;
}
```
- Direct database/API access in components
- No loading spinners — Suspense + streaming handles it
- Cached by default (`fetch` uses request deduplication + caching)

### TanStack Query (Client Components)
```tsx
function UserList() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
  });
  if (isLoading) return <Skeleton />;
  return <ul>{data.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```
- Automatic caching, refetching, invalidation
- Background refetch on window focus, stale-while-revalidate
- Infinite queries, paginated queries
- Optimistic updates, mutation lifecycle hooks

### SWR (Vercel)
- Simpler than TanStack Query, fewer features
- `useSWR(key, fetcher)` — stale-while-revalidate
- **When to use**: Simple data fetching needs where TanStack Query is overkill

### `use()` Hook (React 19)
- Unwrap promises in render: `const data = use(fetchPromise)`
- Works with Suspense for loading states
- Simplifies data fetching patterns

---

## Recommended React Stack (2025)

| Layer | Recommended | Alternative |
|-------|------------|-------------|
| Framework | Next.js (App Router) | Remix, Astro+React |
| Routing | Next.js file-based | TanStack Router (max type safety) |
| Server data | Server Components + fetch | TanStack Query (client), SWR |
| Client state | Zustand | Jotai (atomic), Context (simple) |
| Styling | Tailwind CSS v4 | CSS Modules, Vanilla Extract |
| Components | shadcn/ui (Radix + Tailwind) | React Aria (max a11y) |
| Forms | React Hook Form + Zod | Conform (Server Actions) |
| Testing | Vitest + RTL + Playwright | MSW for API mocking |
| Build | Vite or Turbopack (Next.js) | Rspack (Webpack migration) |
| Monitoring | Sentry + web-vitals | Vercel Analytics |
