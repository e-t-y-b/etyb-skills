# Vue Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features. Vue ecosystem releases frequently.**

## Table of Contents
1. [Vue 3 (Current)](#1-vue-3-current)
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
12. [Ecosystem Tools](#12-ecosystem-tools)

---

## 1. Vue 3 (Current)

### Composition API (Standard)
- `setup()` function or `<script setup>` (recommended SFC sugar)
- Replaces Options API for new projects
- Better TypeScript support, composable reuse, tree-shakeable
- `ref()`, `reactive()`, `computed()`, `watch()`, `watchEffect()` as core primitives

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'

const count = ref(0)
const doubled = computed(() => count.value * 2)
const increment = () => count.value++
</script>

<template>
  <button @click="increment">{{ count }} ({{ doubled }})</button>
</template>
```

### Vue 3.3+ Features
- **`defineModel()`**: Two-way binding macro — simplifies v-model on custom components
- **Generic components**: `<script setup lang="ts" generic="T">`
- **`defineOptions()`**: Set component name, inheritAttrs without separate script block
- **Improved TypeScript**: Better type inference for props, emits, slots

### Vue 3.4+ Features
- **`defineModel()` stable**: No longer experimental
- **Improved reactivity performance**: More efficient dependency tracking
- **`v-bind` shorthand**: `:prop` can be written as just `:prop` when prop name matches variable name
- **Faster template parser**: 2x faster SFC compilation

### Vue 3.5+ Features
- **Reactive Props Destructure** (stable): `const { modelValue } = defineProps<{ modelValue: string }>()`
- **`useTemplateRef()`**: Type-safe template refs
- **`useId()`**: SSR-safe unique ID generation
- **Deferred Teleport**: `<Teleport defer>` for deferred rendering
- **`onWatcherCleanup()`**: Cleanup function for watchers
- **Lazy Hydration** (experimental): `defineAsyncComponent({ hydrate: ... })` strategies for SSR

### Vue 3.6 (Beta — December 2025)
- **Vapor Mode**: The headline feature — eliminates Virtual DOM overhead entirely. Compiles templates to imperative DOM operations (similar to Solid.js). Can mount 100,000 components in ~100ms. Base framework size under 10KB. Opt-in per component — mix Vapor and VDOM components in same app.
- **Alien Signals**: New signal-based reactivity system. 14% memory reduction over Vue 3.5. Faster state change processing.
- **Status**: Beta — verify production readiness with `WebSearch` before recommending

### `<script setup>` (Standard SFC Pattern)
```vue
<script setup lang="ts">
// Props
const props = defineProps<{
  title: string
  count?: number
}>()

// Emits
const emit = defineEmits<{
  (e: 'update', value: number): void
}>()

// v-model
const modelValue = defineModel<string>()

// Expose to parent
defineExpose({ publicMethod })

// Slots type
defineSlots<{
  default(props: { item: Item }): any
}>()
</script>
```

### Composables (Reusable Logic)
```typescript
// composables/useCounter.ts
import { ref, computed } from 'vue'

export function useCounter(initial = 0) {
  const count = ref(initial)
  const doubled = computed(() => count.value * 2)
  const increment = () => count.value++
  const decrement = () => count.value--
  return { count, doubled, increment, decrement }
}
```
- Extract reactive logic into reusable functions
- Vue's equivalent of React hooks, but more flexible (no call-order rules)
- Naming convention: `use` prefix (e.g., `useAuth`, `useFetch`, `useLocalStorage`)
- **VueUse**: 200+ production-ready composables (see Ecosystem Tools section)

---

## 2. Meta-Frameworks

### Nuxt 3 (Current Standard)
- **Full-stack Vue framework**: SSR, SSG, ISR, API routes, auto-imports, file-based routing
- **Nitro engine**: Universal server engine — deploy to Node, Deno, Cloudflare Workers, Vercel, Netlify, AWS Lambda
- **Auto-imports**: Components, composables, utilities imported automatically (no explicit imports needed)
- **File-based routing**: `pages/index.vue`, `pages/users/[id].vue`
- **Layouts**: `layouts/default.vue` — persistent across navigations
- **Middleware**: Route middleware for auth guards, redirects
- **Server routes**: `server/api/` directory for API endpoints (powered by Nitro)
- **Hybrid rendering**: Configure SSR, SSG, SPA, or ISR per route with `routeRules`
- **SEO**: `useHead()`, `useSeoMeta()`, automatic meta tags, OG image generation
- **DevTools**: Nuxt DevTools — inspect routes, components, composables, state, API calls in browser

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  routeRules: {
    '/': { prerender: true },           // SSG
    '/dashboard/**': { ssr: false },    // SPA
    '/blog/**': { isr: 3600 },          // ISR (revalidate every hour)
    '/api/**': { cors: true },          // API routes
  },
})
```

**When to choose Nuxt**: Most Vue projects. SSR/SSG/ISR needs. SEO-critical apps. Full-stack Vue development.

### Nuxt 4 (Stable — July 2025)
- **New directory structure**: Application code moves to `app/` directory
- **Improved data fetching**: Smarter `useAsyncData`/`useFetch` with automatic data sharing, auto-cleanup on unmount, reactive keys with automatic refetch
- **Server Components**: Server-render individual components within client-side apps
- **Lazy Hydration** (Nuxt 3.16+/4): `<LazyMyComponent hydrate-on-visible />` — defer component hydration until needed
  - Strategies: `hydrate-on-visible`, `hydrate-on-idle`, `hydrate-on-interaction`, `hydrate-on-media-query`
- **vue-router v5 integration** (Nuxt 4.4): Typed routes progressing toward stable
- **NuxtLabs acquired by Vercel** (July 2025)
- **Nuxt 5**: Expected with Nitro v3, H3 v2, Rolldown-powered builds

### Astro (with Vue)
- Content-first framework. Ships zero JS by default.
- Vue components as "islands": `<VueComponent client:load />`
- **When to choose**: Content-heavy sites with some Vue interactivity (blogs, docs, marketing).

### VitePress
- Static site generator powered by Vue + Vite
- Markdown-centric with Vue components in markdown
- **When to choose**: Documentation sites, technical blogs, knowledge bases
- Used by Vue, Vite, Pinia, VueUse official docs

### Quasar Framework
- Full Vue 3 UI framework with SSR, PWA, mobile (Capacitor/Cordova), desktop (Electron)
- 70+ Material Design components
- **When to choose**: Cross-platform from single codebase, Material Design aesthetic OK

---

## 3. State Management

### The Decision Framework
```
Server data (API responses)? → TanStack Query for Vue / Nuxt useFetch
Form state? → VeeValidate or FormKit
URL state (filters, search)? → useRoute().query / useRouter()
UI state (modals, toggles)? → ref() / reactive()
Shared UI state (theme, auth)? → Pinia
Complex client state? → Pinia
```

### Pinia 3 (Official Store) — Recommended
- Official Vue state management (replaced Vuex). Pinia 3 dropped Vue 2 support.
- Lightweight (~1KB), TypeScript-first, Composition API native
- Devtools integration with time-travel debugging, SSR support, HMR
- **Pinia 3 new features**: Signal-based architecture integration, native Subscription Stores (WebSocket/SSE as reactive state), isolated scoping for micro-frontends

```typescript
// stores/user.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useUserStore = defineStore('user', () => {
  const users = ref<User[]>([])
  const loading = ref(false)

  const activeUsers = computed(() => users.value.filter(u => u.active))

  async function fetchUsers() {
    loading.value = true
    users.value = await $fetch('/api/users')
    loading.value = false
  }

  return { users, loading, activeUsers, fetchUsers }
})
```

- **Plugins**: `pinia-plugin-persistedstate` (localStorage/sessionStorage persistence)
- **Devtools**: Full inspection of stores, time-travel debugging
- **SSR**: Works with Nuxt out of the box
- **Use for**: Any global client state (auth, theme, cart, preferences)

### TanStack Query for Vue
- Server state management (caching, refetching, invalidation)
- `useQuery()`, `useMutation()`, `useInfiniteQuery()`
- Same API as React Query, ported for Vue
- **Use for**: Client-side API data fetching with caching

### Vuex — Legacy
- **Do not use for new projects**. Migrate to Pinia.
- Vuex 4 supports Vue 3 but is in maintenance mode
- Pinia is the official successor

---

## 4. Styling

### Scoped Styles (Built-in)
```vue
<style scoped>
.card { padding: 1rem; }
/* :deep() for child components */
.card :deep(.title) { font-weight: bold; }
/* :slotted() for slot content */
:slotted(.item) { margin: 0.5rem; }
/* :global() for global styles in scoped block */
:global(.modal-open) { overflow: hidden; }
</style>
```
- Scoped by default in SFCs — styles only apply to current component
- Uses data attribute selectors under the hood

### CSS v-bind (Dynamic Styles)
```vue
<script setup>
const color = ref('red')
</script>
<style scoped>
.text { color: v-bind(color); }
</style>
```
- Bind reactive values to CSS properties directly
- Uses CSS custom properties under the hood — reactive updates

### Tailwind CSS (v4) — Recommended
- Full support with Vue SFCs
- Works with SSR (no runtime JS)
- v4: CSS-first configuration, Lightning CSS engine, automatic content detection
- **Ecosystem**: tailwindcss-animate, tailwind-merge, clsx

### UnoCSS
- Atomic CSS engine — faster than Tailwind in compilation
- Preset system: Tailwind compat, Attributify mode, pure CSS icons
- First-class Vue/Nuxt integration via `@unocss/nuxt`
- **When to use**: Teams wanting Tailwind-like utility classes with more flexibility

### CSS Modules
- `<style module>` in Vue SFCs
- Access via `$style.className` in template or `useCssModule()` in setup
- Good for: component-scoped styles without scoped attribute limitations

---

## 5. Component Libraries

### PrimeVue — Most Comprehensive
- 90+ components (DataTable, TreeSelect, Editor, Charts, etc.)
- Unstyled mode (headless) + Tailwind presets
- Themes: Aura, Lara, Nora (customizable via design tokens)
- Figma UI kit available
- **When to use**: Enterprise apps needing rich data components (grids, trees, charts)

### Reka UI (formerly Radix Vue — rebranded 2025)
- Headless, unstyled, accessibility-first primitives (40+ components)
- WAI-ARIA compliant with keyboard navigation and focus management
- Foundation for shadcn-vue and Nuxt UI v3
- **When to use**: Custom design systems, accessibility-critical applications

### shadcn-vue
- Port of shadcn/ui for Vue — copy-paste components
- Built on **Reka UI** (since v2) + Tailwind CSS
- Full ownership: customize freely
- CLI: `npx shadcn-vue@latest add button`
- **Recommended for**: Custom-designed apps with Vue

### Nuxt UI v3
- Official Nuxt component library: 54 core + 50 Pro + 42 Prose components
- Built on Reka UI + Tailwind CSS v4
- Now **fully open-source** (Pro features made free after Vercel acquisition)
- **When to use**: Nuxt projects wanting integrated, first-party UI solution

### Vuetify 3
- Material Design 3 component library for Vue 3
- Rich component set with built-in theming
- **When to use**: Internal tools, admin panels, Material Design aesthetic

### Naive UI
- Vue 3 component library with TypeScript
- 80+ components, tree-shakeable, good documentation
- **When to use**: Teams wanting a modern, lightweight alternative to Vuetify

### Element Plus
- Vue 3 version of Element UI
- Enterprise-focused, popular in Chinese ecosystem
- **When to use**: Enterprise applications, particularly teams familiar with Element UI

### Headless UI (Vue)
- Unstyled, accessible components from Tailwind Labs
- Vue version: Menu, Listbox, Combobox, Dialog, Disclosure, Tabs, Transition
- **When to use**: Tailwind-based projects needing accessible primitives

---

## 6. Forms and Validation

### VeeValidate — Recommended
- Composition API-first form validation
- `useForm()`, `useField()` composables
- Schema validation with Zod, Yup, Valibot
- Field-level and form-level validation

```vue
<script setup>
import { useForm } from 'vee-validate'
import { z } from 'zod'
import { toTypedSchema } from '@vee-validate/zod'

const schema = toTypedSchema(z.object({
  email: z.string().email(),
  name: z.string().min(2),
}))

const { handleSubmit, errors } = useForm({ validationSchema: schema })

const onSubmit = handleSubmit((values) => {
  console.log(values) // typed!
})
</script>
```

### FormKit
- Opinionated form framework with built-in UI, validation, and generation
- Schema-driven form generation (JSON → forms)
- Accessibility built-in
- **When to use**: Rapid form development, dynamic/generated forms, teams wanting batteries-included

### Zod for Validation
- Define schema once — use for form validation + API validation + TypeScript types
- Integrates with VeeValidate via `@vee-validate/zod`
- Integrates with Nuxt server routes for shared validation

### Valibot
- Lightweight alternative to Zod (smaller bundle)
- Similar API, tree-shakeable by design
- Growing adoption in Vue ecosystem

---

## 7. Testing

### Vitest — Recommended
- Vite-powered, fast, ESM-native
- Vue component testing via `@vue/test-utils` or Vue Testing Library
- Jest-compatible API (easy migration)
- Built-in TypeScript, code coverage, snapshot testing

### Vue Testing Library
- Test components from user perspective
- Uses `@testing-library/vue`
- Queries by role, label, text (accessible selectors)
- **Philosophy**: Test behavior, not implementation details

```typescript
import { render, screen, fireEvent } from '@testing-library/vue'
import Counter from './Counter.vue'

test('increments counter', async () => {
  render(Counter)
  const button = screen.getByRole('button')
  await fireEvent.click(button)
  expect(screen.getByText('1')).toBeTruthy()
})
```

### Vue Test Utils (Official)
- Lower-level component testing
- `mount()`, `shallowMount()`, `wrapper.find()`, `wrapper.trigger()`
- Direct access to component internals
- **When to use**: When you need to test component internals, emitted events, or slots

### Playwright — E2E
- Cross-browser testing (Chromium, Firefox, WebKit)
- Auto-waiting, tracing, screenshots, video
- Component testing mode available
- **When to use**: Critical user flows, integration tests

### Nuxt Testing
- `@nuxt/test-utils` for Nuxt-specific testing
- SSR rendering tests, API route testing
- Auto-import resolution in tests
- Mocking `$fetch`, `useFetch`, and other Nuxt composables

### Storybook for Vue
- Component development and documentation
- CSF (Component Story Format) support for Vue 3
- Visual regression testing with Chromatic
- Accessibility addon (axe-core)
- **When to use**: Design system development, component catalog

---

## 8. Performance

### Vue Compiler Optimizations
Vue 3's compiler performs static analysis at build time:
- **Static hoisting**: Static VNodes created once, reused across re-renders
- **Patch flags**: Mark dynamic bindings so runtime only diffs what changed
- **Tree flattening**: Skip static subtrees during diffing
- **Block tree**: Reduce VDOM tree traversal to only dynamic nodes
- Result: Vue 3 is significantly faster than Vue 2 with minimal developer effort

### Lazy Loading
- `defineAsyncComponent()` for component-level code splitting
- Route-level lazy loading: `() => import('./views/Dashboard.vue')`
- Nuxt: automatic route-level code splitting

```typescript
import { defineAsyncComponent } from 'vue'

const HeavyChart = defineAsyncComponent({
  loader: () => import('./HeavyChart.vue'),
  loadingComponent: LoadingSpinner,
  delay: 200,
  timeout: 10000,
})
```

### `v-once` and `v-memo`
- `v-once`: Render content once, skip all future updates
- `v-memo`: Memoize subtree, re-render only when dependencies change

```html
<!-- Only re-render when item.id changes -->
<div v-for="item in list" :key="item.id" v-memo="[item.id]">
  <ExpensiveComponent :data="item" />
</div>
```

### Virtual Scrolling
- `@tanstack/vue-virtual` for large lists
- Renders only visible items in the viewport
- Essential for lists with 100+ items

### Keep-Alive
- `<KeepAlive>` caches component instances for tabbed interfaces
- Avoids re-mounting/re-fetching when switching tabs
- `include`/`exclude` props to control what gets cached
- `max` prop to limit cache size

### Nuxt Performance Features
- **Payload extraction**: Reduce transferred data in SSR
- **Islands mode**: `<NuxtIsland>` for server-only components
- **Image optimization**: `<NuxtImg>` with automatic optimization
- **Route rules**: Per-route ISR, prerendering, caching

---

## 9. Build Tools

### Vite — Default for Vue
- Vue's official recommended build tool
- Dev: Native ESM, instant HMR (< 50ms)
- Production: Rollup bundling
- `@vitejs/plugin-vue` for SFC support
- `@vitejs/plugin-vue-jsx` for JSX support

### unplugin Ecosystem
- **unplugin-auto-import**: Auto-import Vue/Nuxt/Pinia APIs (no explicit imports)
- **unplugin-vue-components**: Auto-register components on use
- **unplugin-icons**: Use any icon set as Vue components
- Reduces boilerplate and import statements significantly

### Nuxt Build System
- Powered by Vite + Nitro
- Nitro: Universal server engine — one codebase, deploy anywhere
- Build output adapters: Node, Cloudflare Workers, Vercel, Netlify, Deno, Bun
- Automatic chunk splitting and optimization

### Monorepo
- **Turborepo**: Fast, convention-over-config. Works well with Vue/Nuxt.
- **Nx**: Full-featured with Vue plugin support.
- **pnpm workspaces**: Simple package management for Vue monorepos.

---

## 10. Routing

### Vue Router 4 (Official)
```typescript
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: () => import('./views/Home.vue') },
    { path: '/users/:id', component: () => import('./views/User.vue') },
    {
      path: '/admin',
      component: () => import('./views/Admin.vue'),
      beforeEnter: [authGuard],
      children: [
        { path: 'settings', component: () => import('./views/Settings.vue') },
      ],
    },
  ],
})
```

### Key Features
- **Composition API**: `useRouter()`, `useRoute()` composables
- **Navigation guards**: `beforeEach`, `beforeEnter`, `beforeRouteLeave`
- **Lazy loading**: Dynamic import for route components (automatic code splitting)
- **Named views**: Multiple `<router-view>` outlets on same page
- **Scroll behavior**: Custom scroll position on navigation
- **Dynamic routing**: `router.addRoute()` for runtime route registration

### Nuxt File-Based Routing
```
pages/
  index.vue          → /
  about.vue          → /about
  users/
    index.vue        → /users
    [id].vue         → /users/:id
  [...slug].vue      → catch-all
```
- Automatic route generation from file structure
- `<NuxtPage>` replaces `<router-view>`
- `<NuxtLink>` replaces `<router-link>` with prefetching
- Typed routes with `NuxtLink` and `navigateTo()`

---

## 11. Data Fetching

### Nuxt Data Fetching (SSR)
```vue
<script setup>
// useFetch — auto-deduplication, SSR-friendly, caching
const { data: users, status, error, refresh } = await useFetch('/api/users')

// useAsyncData — more control over the fetch function
const { data } = await useAsyncData('users', () => {
  return $fetch('/api/users', { query: { page: 1 } })
})

// useLazyFetch — non-blocking (doesn't await, loads in background)
const { data: posts, pending } = useLazyFetch('/api/posts')
</script>
```

### Key Differences
| Composable | SSR Blocking | Caching | Best For |
|-----------|-------------|---------|----------|
| `useFetch` | Yes (awaitable) | Auto-cached key | Most API calls |
| `useLazyFetch` | No | Auto-cached key | Non-critical data (below fold) |
| `useAsyncData` | Yes (awaitable) | Manual key | Complex fetch logic, transformations |
| `useLazyAsyncData` | No | Manual key | Non-critical complex data |
| `$fetch` | No SSR payload | None | Client-only calls, event handlers |

### TanStack Query for Vue
```vue
<script setup>
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'

const { data, isLoading, error } = useQuery({
  queryKey: ['users'],
  queryFn: () => $fetch('/api/users'),
})

const queryClient = useQueryClient()
const { mutate } = useMutation({
  mutationFn: (user) => $fetch('/api/users', { method: 'POST', body: user }),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
})
</script>
```
- Automatic caching, background refetching, optimistic updates
- **Use for**: Complex client-side caching needs beyond what Nuxt composables provide

### ofetch
- Nuxt's underlying fetch library (by UnJS)
- Auto-parsing JSON, error handling, interceptors, retry
- Works in Node, browser, Workers
- `$fetch` in Nuxt is powered by ofetch

---

## 12. Ecosystem Tools

### VueUse — Essential Utility Library
- 200+ composables for common tasks
- Categories: Browser, Sensors, Animation, State, Network, Utilities
- Key composables:
  - `useLocalStorage()`, `useSessionStorage()` — reactive storage
  - `useDark()`, `useColorMode()` — dark mode management
  - `useIntersectionObserver()` — lazy loading, scroll detection
  - `useFetch()` — standalone data fetching (outside Nuxt)
  - `useMediaQuery()` — responsive breakpoints
  - `useClipboard()` — clipboard API
  - `useEventListener()` — auto-cleanup event listeners
  - `useWebSocket()` — reactive WebSocket connection
  - `useDebounceFn()`, `useThrottleFn()` — performance utilities
- **Always check VueUse before writing a custom composable**

### Vue DevTools
- Browser extension for Vue 3
- Inspect component tree, state, events, performance
- Pinia store inspection and time-travel
- Route inspection and navigation tracking

### Nuxt DevTools
- In-browser DevTools panel for Nuxt 3
- Inspect routes, components, composables, plugins, modules
- API playground for server routes
- Component inspector with source links
- **Highly recommended** for Nuxt development

### Internationalization
- **Vue I18n**: Official i18n library for Vue 3
- **@nuxtjs/i18n**: Nuxt module with auto-detection, lazy loading per locale, SEO (hreflang)
- Supports Composition API: `useI18n()` composable

### Icon Libraries
- **unplugin-icons**: Use 100,000+ icons from Iconify as Vue components
- **@iconify/vue**: Runtime icon loading from Iconify
- **Lucide Vue**: SVG icon set with Vue components

---

## Recommended Vue Stack (2025)

| Layer | Recommended | Alternative |
|-------|------------|-------------|
| Framework | Nuxt 3 | Vue 3 + Vite (SPA only) |
| Routing | Nuxt file-based | Vue Router 4 (manual) |
| Server data | `useFetch` / `useAsyncData` (Nuxt) | TanStack Query (complex caching) |
| Client state | Pinia | `ref()` / `reactive()` (simple) |
| Styling | Tailwind CSS v4 | UnoCSS, Scoped styles |
| Components | shadcn-vue (Reka UI + Tailwind) | Nuxt UI v3, PrimeVue (enterprise), Vuetify 3 (Material) |
| Forms | VeeValidate + Zod | FormKit (batteries-included) |
| Testing | Vitest + Vue Testing Library + Playwright | Vue Test Utils (internals testing) |
| Build | Vite (Vue) / Nitro (Nuxt) | — |
| Utilities | VueUse | Custom composables |
| Docs site | VitePress | Nuxt Content |
| Monitoring | Sentry + web-vitals | Vercel Analytics |
