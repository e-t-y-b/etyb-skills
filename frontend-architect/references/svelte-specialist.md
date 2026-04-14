# Svelte Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features. Svelte 5 runes are stable. Svelte 6 is in planning. Last verified: April 2026.**

## Table of Contents
1. [Svelte 5 (Current)](#1-svelte-5-current)
2. [SvelteKit](#2-sveltekit)
3. [State Management](#3-state-management)
4. [Styling](#4-styling)
5. [Component Libraries](#5-component-libraries)
6. [Forms and Validation](#6-forms-and-validation)
7. [Testing](#7-testing)
8. [Performance](#8-performance)
9. [Build Tools](#9-build-tools)
10. [Routing](#10-routing)
11. [Data Fetching](#11-data-fetching)
12. [Ecosystem](#12-ecosystem)

---

## 1. Svelte 5 (Current)

### The Runes Revolution
Svelte 5 replaced Svelte 4's implicit reactivity (`let x = 0` is reactive) with **Runes** — explicit reactive primitives. This is the biggest change in Svelte's history.

### Core Runes

#### `$state` — Reactive State
```svelte
<script>
  let count = $state(0)
  let user = $state({ name: 'Alice', age: 30 })
  // Deep reactivity: user.name = 'Bob' triggers updates
</script>

<button onclick={() => count++}>{count}</button>
```
- Replaces `let x = 0` implicit reactivity from Svelte 4
- Deep reactivity for objects and arrays (uses Proxy under the hood)
- `$state.raw()` for non-deep reactivity (plain objects, better for large immutable data)

#### `$derived` — Computed Values
```svelte
<script>
  let count = $state(0)
  let doubled = $derived(count * 2)
  // For complex derivations:
  let filtered = $derived.by(() => {
    return items.filter(i => i.active)
  })
</script>
```
- Replaces `$: doubled = count * 2` reactive declarations
- Lazy evaluation — only computed when read
- Automatically tracks dependencies

#### `$effect` — Side Effects
```svelte
<script>
  let count = $state(0)

  $effect(() => {
    console.log(`Count is ${count}`)
    // Cleanup function (optional):
    return () => console.log('cleanup')
  })

  // Pre-effect (runs before DOM updates):
  $effect.pre(() => {
    // Useful for scroll position preservation
  })
</script>
```
- Replaces `$: { sideEffect() }` reactive statements
- Runs after DOM updates by default
- Automatic dependency tracking
- Cleanup function for teardown

#### `$props` — Component Props
```svelte
<script>
  let { name, count = 0, ...rest } = $props()
</script>
```
- Replaces `export let name` prop declarations
- Destructuring with defaults
- Rest props with `...rest`

#### `$bindable` — Two-Way Binding
```svelte
<script>
  let { value = $bindable('') } = $props()
</script>

<!-- Parent can bind: -->
<!-- <Input bind:value={name} /> -->
```
- Marks a prop as bindable from parent
- Explicit opt-in for two-way binding

#### `$inspect` — Debugging
```svelte
<script>
  let count = $state(0)
  $inspect(count) // logs when count changes (dev only, stripped in production)
</script>
```

### Snippets (Replace Slots)
```svelte
<!-- Defining a snippet -->
{#snippet row(item)}
  <tr>
    <td>{item.name}</td>
    <td>{item.value}</td>
  </tr>
{/snippet}

<!-- Using it -->
<Table data={items} {row} />

<!-- In Table.svelte -->
<script>
  let { data, row } = $props()
</script>
<table>
  {#each data as item}
    {@render row(item)}
  {/each}
</table>
```
- Replaces slots for most use cases
- More flexible — pass as props, use conditionally
- Typed snippet props with TypeScript

### Event Handling Changes
```svelte
<!-- Svelte 5: standard HTML event attributes -->
<button onclick={() => count++}>Click</button>
<input oninput={(e) => name = e.target.value} />

<!-- Svelte 4 (legacy): on:directive -->
<button on:click={() => count++}>Click</button>
```
- `onclick` instead of `on:click`
- No more `createEventDispatcher()` — use callback props instead
- Standard DOM event names (lowercase)

### Migration from Svelte 4
- `npx sv migrate svelte-5` — automated migration tool
- `legacy.componentApi` compatibility flag for gradual migration
- Key changes: let → $state, $: → $derived/$effect, export let → $props, slots → snippets
- Most projects can migrate incrementally

---

## 2. SvelteKit

### The Full-Stack Svelte Framework
SvelteKit is to Svelte what Next.js is to React — the default way to build Svelte applications.

### Core Concepts
- **File-based routing**: `src/routes/+page.svelte`
- **Server-side rendering**: SSR by default, configurable per route
- **Adapters**: Deploy to any platform (Node, Vercel, Cloudflare, Netlify, static)
- **Form actions**: Progressive enhancement for form submissions
- **Load functions**: Data fetching at route level

### File Structure
```
src/
  routes/
    +page.svelte          → / (page component)
    +page.server.ts       → / (server-side load function)
    +page.ts              → / (universal load function)
    +layout.svelte        → persistent layout
    +layout.server.ts     → layout data
    +error.svelte         → error page
    +server.ts            → API endpoint
    about/
      +page.svelte        → /about
    users/
      [id]/
        +page.svelte      → /users/:id
        +page.server.ts   → server load for user
    (app)/                → route group (no URL impact)
      dashboard/
        +page.svelte      → /dashboard
    [[lang]]/             → optional param
      +page.svelte
```

### Load Functions
```typescript
// +page.server.ts — runs ONLY on server (access DB, secrets)
import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async ({ params, fetch, cookies }) => {
  const user = await db.user.findUnique({ where: { id: params.id } })
  return { user }
}

// +page.ts — runs on server AND client (universal)
import type { PageLoad } from './$types'

export const load: PageLoad = async ({ fetch, params }) => {
  const res = await fetch(`/api/users/${params.id}`)
  return { user: await res.json() }
}
```

### Form Actions
```typescript
// +page.server.ts
import type { Actions } from './$types'

export const actions: Actions = {
  create: async ({ request }) => {
    const data = await request.formData()
    const name = data.get('name')

    if (!name) return fail(400, { name, missing: true })

    await db.user.create({ data: { name } })
    throw redirect(303, '/users')
  },
  delete: async ({ params }) => {
    await db.user.delete({ where: { id: params.id } })
  },
}
```
```svelte
<!-- +page.svelte -->
<form method="POST" action="?/create" use:enhance>
  <input name="name" />
  <button>Create</button>
</form>
```
- Progressive enhancement: works without JavaScript
- `use:enhance` adds client-side enhancement (no full reload)
- Multiple named actions per page

### Rendering Modes
```typescript
// +page.ts or +page.server.ts
export const prerender = true    // SSG — build-time rendering
export const ssr = true          // SSR (default)
export const csr = true          // CSR hydration (default)

// Disable SSR for SPA routes:
export const ssr = false

// Per-route control:
export const prerender = 'auto'  // prerender if no dynamic data
```

### Error Boundaries (Stable) and Async SSR (Experimental)
```svelte
<!-- svelte:boundary — error and loading boundaries -->
<svelte:boundary>
  <MyComponent />
  {#snippet pending()}
    <p>Loading...</p>
  {/snippet}
  {#snippet failed(error, reset)}
    <p>Error: {error.message}</p>
    <button onclick={reset}>Retry</button>
  {/snippet}
</svelte:boundary>
```
- **`svelte:boundary`** is **stable and production-ready** — error boundaries now work on both client and server (server-side error boundaries added in SvelteKit 2.57+)
- **Async SSR** (experimental): Allows `await` anywhere in components. Opt-in via `experimental.async` in SvelteKit config. Expected stable in **Svelte 6**.
- **Svelte 6**: In planning (GitHub milestone exists). Will stabilize async SSR and further mature the runes system. No release date confirmed yet.

### API Routes
```typescript
// src/routes/api/users/+server.ts
import { json } from '@sveltejs/kit'
import type { RequestHandler } from './$types'

export const GET: RequestHandler = async ({ url }) => {
  const page = url.searchParams.get('page') ?? '1'
  const users = await db.user.findMany({ take: 20, skip: (Number(page) - 1) * 20 })
  return json(users)
}

export const POST: RequestHandler = async ({ request }) => {
  const body = await request.json()
  const user = await db.user.create({ data: body })
  return json(user, { status: 201 })
}
```

### Hooks
```typescript
// src/hooks.server.ts
import type { Handle } from '@sveltejs/kit'

export const handle: Handle = async ({ event, resolve }) => {
  // Runs on every request — auth, logging, response modification
  const session = await getSession(event.cookies)
  event.locals.user = session?.user

  const response = await resolve(event)
  return response
}
```

---

## 3. State Management

### Svelte 5 Runes (Built-in) — Recommended
- `$state()` for reactive values
- `$derived()` for computed values
- `$effect()` for side effects
- For shared state, create module-level state in `.svelte.ts` files:

```typescript
// lib/stores/counter.svelte.ts
class Counter {
  count = $state(0)
  doubled = $derived(this.count * 2)

  increment() { this.count++ }
  decrement() { this.count-- }
}

export const counter = new Counter()
```

### Svelte Stores (Still Valid)
```typescript
import { writable, derived, readable } from 'svelte/store'

const count = writable(0)
const doubled = derived(count, $count => $count * 2)

// In component: $count (auto-subscribe), count.set(5), count.update(n => n + 1)
```
- Still work in Svelte 5 but runes are preferred for new code
- `readable` for read-only stores (timers, geolocation)
- Custom stores: any object with a `subscribe` method

### When to Use What
```
Component-local state → $state
Computed values → $derived
Side effects → $effect
Shared state (module) → .svelte.ts files with $state
Complex async state → TanStack Query for Svelte
Form state → Superforms
URL state → SvelteKit $page.url.searchParams
```

---

## 4. Styling

### Scoped Styles (Built-in, Default)
```svelte
<style>
  /* Scoped to this component automatically */
  p { color: red; }

  /* Global escape hatch */
  :global(.external-class) { color: blue; }
</style>
```
- All `<style>` blocks are scoped by default
- Uses class-based scoping (like CSS Modules)
- No extra configuration needed

### Tailwind CSS Integration
- Full support via `@sveltejs/vite-plugin-svelte` + Tailwind CSS
- `@tailwindcss/vite` plugin for Tailwind v4
- Works with SSR, scoped styles, and SvelteKit

### UnoCSS
- `@unocss/svelte-scoped` for scoped utility classes
- Faster compilation than Tailwind
- First-class SvelteKit support

### CSS Custom Properties for Theming
```svelte
<!-- Pass CSS variables as component props -->
<Component --primary="blue" --spacing="1rem" />

<!-- In Component.svelte -->
<style>
  .box {
    color: var(--primary, black);
    padding: var(--spacing, 0.5rem);
  }
</style>
```
- Built-in CSS variable passing between components
- Powerful theming without external libraries

---

## 5. Component Libraries

### shadcn-svelte (Latest: 1.2.5) — Recommended
- Port of shadcn/ui for Svelte — copy-paste components
- Built on Bits UI (headless) + Tailwind CSS v4
- Requires Svelte 5 + Tailwind v4
- Full ownership and customization
- CLI: `npx shadcn-svelte@latest add button`
- Active development, growing ecosystem

### Bits UI (Latest: 2.17.3) — Headless
- Headless, accessible component primitives for Svelte
- Foundation for shadcn-svelte
- Components: Dialog, Dropdown, Tooltip, Tabs, Select, etc.
- ARIA patterns built-in

### Skeleton UI
- Full component library for Svelte + Tailwind CSS
- Themes, design tokens, utility classes
- Components: AppShell, Table, Pagination, Toast, etc.
- **When to use**: Rapid development with opinionated design

### Melt UI
- Headless component builder library for Svelte
- Lower-level than Bits UI — builder pattern for maximum control
- **When to use**: Building custom component library from scratch

### DaisyUI
- Tailwind CSS component classes (framework-agnostic)
- Works with Svelte + Tailwind
- 50+ component classes, themes
- **When to use**: Quick prototyping, less customization needed

---

## 6. Forms and Validation

### Superforms (Latest: 2.30.1) — Recommended for SvelteKit
- SvelteKit-native form handling with Zod/Valibot/TypeBox validation
- **Zod 4 adapter** with discriminated union support
- Progressive enhancement (works without JS)
- Client + server validation from single schema
- Flash messages, rate limiting, file uploads

```svelte
<script>
  import { superForm } from 'sveltekit-superforms'
  import { zod } from 'sveltekit-superforms/adapters'
  import { z } from 'zod'

  const schema = z.object({
    name: z.string().min(2),
    email: z.string().email(),
  })

  const { form, errors, enhance, submitting } = superForm(data.form, {
    validators: zod(schema),
  })
</script>

<form method="POST" use:enhance>
  <input name="name" bind:value={$form.name} />
  {#if $errors.name}<span>{$errors.name}</span>{/if}

  <input name="email" bind:value={$form.email} />
  {#if $errors.email}<span>{$errors.email}</span>{/if}

  <button disabled={$submitting}>Submit</button>
</form>
```

### SvelteKit Form Actions (Built-in)
- Native form handling with progressive enhancement
- `use:enhance` for client-side enhancement
- Works without external libraries for simple forms
- **When to use**: Simple forms that don't need complex validation

### Felte
- Form management library for Svelte
- Validator integrations (Zod, Yup, Superstruct)
- **When to use**: Non-SvelteKit Svelte projects needing form validation

---

## 7. Testing

### Vitest — Recommended
- Vite-powered, fast, ESM-native
- Svelte component testing via `@testing-library/svelte`
- Jest-compatible API
- Built-in TypeScript support

### Svelte Testing Library
```typescript
import { render, screen, fireEvent } from '@testing-library/svelte'
import Counter from './Counter.svelte'

test('increments count', async () => {
  render(Counter, { props: { initial: 0 } })
  const button = screen.getByRole('button')
  await fireEvent.click(button)
  expect(screen.getByText('1')).toBeTruthy()
})
```
- Test from user perspective
- Queries by role, label, text
- **Recommended** for component testing

### Playwright — E2E
- Cross-browser testing
- Component testing mode for Svelte
- Auto-waiting, tracing, screenshots
- **When to use**: Critical user flows, integration tests

### SvelteKit Testing
- `@sveltejs/kit` provides testing utilities
- Test load functions, form actions, API routes
- Mock `fetch`, `cookies`, `locals`

---

## 8. Performance

### Compile-Time Advantage
Svelte's core performance advantage is that it compiles components to optimized imperative DOM operations at build time:

- **No virtual DOM**: Direct DOM mutations — no diffing overhead
- **No runtime framework code**: Only ships the specific code each component needs
- **Smaller bundles**: Typical Svelte app ships 30-50% less JS than React equivalent
- **Faster updates**: Direct property assignments instead of reconciliation

### Bundle Size Comparison (Approximate)
| Framework | Runtime Size (min+gzip) |
|-----------|----------------------|
| Svelte 5 | ~3KB (shared runtime) |
| Vue 3 | ~33KB |
| React 18 | ~42KB (+ ReactDOM) |
| Angular 17+ | ~60KB |

### Hydration
- SvelteKit hydrates by default (SSR → client takes over)
- Smaller hydration cost than React/Vue due to less runtime code
- Static pages: `export const csr = false` to skip hydration entirely

### Lazy Loading
- Route-level: automatic in SvelteKit (each route is a separate chunk)
- Component-level: dynamic `import()` in `{#await}` blocks
- `$effect` for deferred/lazy operations

### Transitions and Animations
```svelte
<script>
  import { fade, fly, slide } from 'svelte/transition'
  import { flip } from 'svelte/animate'
  let visible = $state(true)
</script>

{#if visible}
  <div transition:fade={{ duration: 300 }}>Fading content</div>
  <div in:fly={{ y: 200 }} out:fade>Fly in, fade out</div>
{/if}

{#each items as item (item.id)}
  <div animate:flip={{ duration: 300 }}>{item.name}</div>
{/each}
```
- Built-in transition directives: fade, fly, slide, scale, blur, draw
- CSS-based transitions (hardware-accelerated)
- FLIP animations for list reordering
- Custom transitions with `tick` function

---

## 9. Build Tools

### Vite 8 (March 2026) — Default
- SvelteKit is built on Vite (Vite 8 support since SvelteKit 2.53.0)
- **Vite 8** powered by Rolldown (Rust-based bundler) — 10-30x faster builds
- `@sveltejs/vite-plugin-svelte` for standalone Svelte projects
- Instant HMR, preserving component state

### SvelteKit Adapters
| Adapter | Deploy Target |
|---------|--------------|
| `@sveltejs/adapter-auto` | Auto-detect platform (default) |
| `@sveltejs/adapter-node` | Node.js server |
| `@sveltejs/adapter-vercel` | Vercel |
| `@sveltejs/adapter-cloudflare` | Cloudflare Pages/Workers |
| `@sveltejs/adapter-netlify` | Netlify |
| `@sveltejs/adapter-static` | Static site / SPA |

### sv CLI (v0.12.6)
- `npx sv create my-app` — scaffold new SvelteKit project
- `npx sv add` — add integrations (Tailwind, Drizzle, Better Auth, Paraglide, Cloudflare Workers, etc.)
- `npx sv migrate svelte-5` — migrate Svelte 4 → 5
- Supports Svelte MCP via OpenCode configuration

---

## 10. Routing

### SvelteKit File-Based Routing
```
src/routes/
  +page.svelte              → /
  +layout.svelte            → root layout
  about/+page.svelte        → /about
  blog/
    +page.svelte            → /blog
    [slug]/+page.svelte     → /blog/:slug
  (marketing)/              → group (no URL segment)
    pricing/+page.svelte    → /pricing
  [[lang]]/                 → optional param
    +page.svelte            → / or /:lang
  [...rest]/+page.svelte    → catch-all
```

### Key Features
- **Layouts**: `+layout.svelte` wraps child routes, persists across navigation
- **Layout groups**: `(name)/` for grouping without URL impact
- **Error pages**: `+error.svelte` at any level
- **Loading states**: Loading indicators via `$navigating` store
- **Preloading**: `data-sveltekit-preload-data` on links
- **Shallow routing**: Push URL without full navigation
- **Route params**: Typed via `$types` auto-generated types

### Navigation
```svelte
<script>
  import { goto, invalidate, invalidateAll } from '$app/navigation'
  import { page } from '$app/state'
</script>

<a href="/about">About</a>

<button onclick={() => goto('/dashboard')}>Dashboard</button>

<!-- Prefetch on hover -->
<a href="/heavy-page" data-sveltekit-preload-data="hover">Heavy Page</a>
```

---

## 11. Data Fetching

### Load Functions (Primary Pattern)
```typescript
// +page.server.ts — server-only data loading
import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async ({ params, fetch, depends }) => {
  depends('app:users') // register dependency for invalidation

  const user = await fetch(`/api/users/${params.id}`)
  return { user: await user.json() }
}
```

```svelte
<!-- +page.svelte — receive data from load -->
<script>
  let { data } = $props()
</script>

<h1>{data.user.name}</h1>
```

### Streaming
```typescript
// +page.server.ts
export const load: PageServerLoad = async ({ fetch }) => {
  return {
    // Streamed (non-blocking): returned as promise, resolved when ready
    comments: fetch('/api/comments').then(r => r.json()),
    // Immediate: awaited before page renders
    post: await fetch('/api/post').then(r => r.json()),
  }
}
```
```svelte
<!-- +page.svelte -->
{#await data.comments}
  <p>Loading comments...</p>
{:then comments}
  {#each comments as comment}
    <p>{comment.text}</p>
  {/each}
{/await}
```

### Invalidation
```typescript
import { invalidate, invalidateAll } from '$app/navigation'

// Invalidate specific dependency
invalidate('app:users')

// Invalidate by URL
invalidate('/api/users')

// Invalidate everything
invalidateAll()
```

### API Routes
```typescript
// src/routes/api/users/+server.ts
import { json, error } from '@sveltejs/kit'

export async function GET({ url }) {
  const users = await db.user.findMany()
  return json(users)
}

export async function POST({ request }) {
  const body = await request.json()
  if (!body.name) throw error(400, 'Name required')
  const user = await db.user.create({ data: body })
  return json(user, { status: 201 })
}
```

---

## 12. Ecosystem

### Authentication
- **Lucia** — **DEPRECATED** (March 2025). Now an educational resource for building auth from scratch, no longer an installable package.
- **Auth.js (SvelteKit)**: `@auth/sveltekit` — 80+ OAuth providers. **Recommended replacement** for OAuth/social login.
- **Arctic**: Lightweight OAuth client library supporting 50+ providers. Recommended by Lucia's creator for OAuth flows.
- **Better Auth** (18K+ GitHub stars): Now an **official SvelteKit addon** via `npx sv add`. Rising fast with multiple releases per week. Supports email/password, social OAuth, MFA, organizations, and more. Growing alternative to Auth.js.
- **Supabase Auth**: Supabase client for SvelteKit

### Internationalization
- **Paraglide 2.0**: Compile-time i18n — zero runtime overhead, up to 70% smaller i18n bundles vs runtime libraries
  - Fully typed translations
  - Tree-shakeable (only ships used translations)
  - SvelteKit's official i18n integration
  - v2.0 is a major step forward with improved developer experience
- **svelte-i18n**: Runtime i18n library
- **typesafe-i18n**: Lightweight, type-safe i18n

### Database / ORM
- **Drizzle**: TypeScript ORM, SQL-like query builder
  - `npx sv add drizzle` for SvelteKit integration
- **Prisma**: Full-featured ORM
- **Supabase**: PostgreSQL + real-time + auth + storage

### Icons
- **unplugin-icons**: 100,000+ icons as Svelte components
- **Lucide Svelte**: SVG icon set for Svelte
- **svelte-radix**: Radix icons for Svelte

### Dev Tools
- **Svelte DevTools**: Browser extension for component inspection
- **SvelteKit DevTools** (experimental): In-app DevTools panel

---

## Recommended Svelte Stack (2026)

| Layer | Recommended | Alternative |
|-------|------------|-------------|
| Framework | SvelteKit 2.57+ | Svelte 5 + Vite 8 (SPA only) |
| Routing | SvelteKit file-based | — |
| Server data | Load functions (+page.server.ts) | API routes (+server.ts) |
| Client state | Runes ($state, $derived) | Svelte stores (svelte/store) |
| Styling | Tailwind CSS v4 | Scoped styles, UnoCSS |
| Components | shadcn-svelte 1.2+ (Bits UI + Tailwind) | Skeleton UI, Melt UI (headless) |
| Forms | Superforms 2.30+ + Zod | SvelteKit form actions (simple) |
| Testing | Vitest + Svelte Testing Library + Playwright | — |
| Build | Vite 8 (Rolldown) + SvelteKit adapters | — |
| Auth | Auth.js (`@auth/sveltekit`) | Better Auth (official addon), Arctic, Supabase Auth |
| i18n | Paraglide 2.0 | svelte-i18n |
| Monitoring | Sentry + web-vitals | Vercel Analytics |

### When to Choose Svelte/SvelteKit

**Svelte excels when:**
- Bundle size is critical (mobile, low-bandwidth)
- Runtime performance matters (animations, frequent updates)
- Developer experience is a priority (less boilerplate than React/Angular)
- Team is small and can move fast with convention-over-configuration
- Building content sites, blogs, SaaS apps, dashboards

**Consider alternatives when:**
- Need largest possible ecosystem (React wins)
- Enterprise with existing Angular investment
- Need React Native / mobile equivalent (no Svelte Native production story)
- Team is large (50+) and needs strict conventions (Angular wins)
- Need bleeding-edge features like AI streaming (React Server Components lead)
