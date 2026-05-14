# Frontend Architecture Patterns — Deep Reference

**Always use `WebSearch` to verify current patterns and tools. The frontend ecosystem evolves rapidly.**

## Table of Contents
1. [Rendering Architectures](#1-rendering-architectures)
2. [Component Architecture](#2-component-architecture)
3. [Performance Optimization](#3-performance-optimization)
4. [State Architecture](#4-state-architecture)
5. [Accessibility (a11y)](#5-accessibility-a11y)
6. [Build and Tooling](#6-build-and-tooling)
7. [Authentication in Frontend](#7-authentication-in-frontend)
8. [API Integration Patterns](#8-api-integration-patterns)
9. [Monitoring and Observability](#9-monitoring-and-observability)

---

## 1. Rendering Architectures

### SPA (Single Page Application)
- Client renders everything. Server sends empty HTML shell + JS bundle.
- **When appropriate**: Authenticated apps (dashboards, admin panels, internal tools), apps where SEO doesn't matter.
- **When NOT**: Public-facing content that needs search indexing.
- **Frameworks**: React (CRA/Vite), Angular, Vue (without SSR).

### MPA (Multi-Page Application) — The Comeback
- Traditional full page reloads per navigation. HTML-first.
- **Resurgence drivers**: Astro, HTMX, Hotwire (Rails). Less JS, better performance.
- **When appropriate**: Content-heavy sites, blogs, docs. Low interactivity needs.

### SSR (Server-Side Rendering)
- Server renders full HTML per request. Client hydrates for interactivity.
- **Best for**: Dynamic SEO content (news, social, search results).
- **Frameworks**: Next.js, Nuxt, Angular Universal, Analog, Remix, SvelteKit.
- **Tradeoff**: Higher server cost, need caching strategy.

### SSG (Static Site Generation)
- Pre-build all pages as HTML at build time. Serve from CDN.
- **Best for**: Blogs, docs, marketing, e-commerce catalogs. Best possible performance.
- **Limitation**: Build time grows with page count.
- **Frameworks**: Astro, Next.js (static export), Gatsby, Hugo, Eleventy.

### ISR (Incremental Static Regeneration)
- Static pages with background revalidation. Next.js pattern.
- `export const revalidate = 3600` — stale-while-revalidate.
- On-demand: `revalidatePath()` / `revalidateTag()` for instant updates.
- **Best for**: Large sites with changing content (e-commerce, CMS).

### Islands Architecture
- Server-renders everything. Only interactive components ("islands") get client JS.
- **Astro**: `client:load`, `client:idle`, `client:visible`, `client:media` directives.
- Ships zero JS by default. Best Core Web Vitals.
- **Best for**: Content sites with interactive pockets.

### Partial Prerendering (PPR)
- Next.js: Static HTML shell from CDN + dynamic parts stream via Suspense.
- Instant TTFB (static) + content completeness (streaming).
- Best of both SSG and SSR per page.

### Resumability (Qwik)
- No hydration at all. Serializes app state in HTML. Events attached lazily.
- Zero JS on initial load. Instant interactivity.
- **Experimental** but promising for performance-critical sites.

### Server Components (React)
- Render on server, send serialized output. Zero client JS for server components.
- `"use client"` boundary marks client interactivity.
- **New paradigm**: Server Component (data) + Client Component (interaction).

### Decision Framework

```
Is the content public and needs SEO?
├── No → SPA (React/Angular/Vue with Vite)
└── Yes → Is the content mostly static?
    ├── Yes → SSG or Islands (Astro, Next.js static)
    └── No → Is it highly dynamic per request?
        ├── Yes → SSR (Next.js, Remix, Angular Universal)
        └── Mix → ISR or PPR (Next.js)
```

---

## 2. Component Architecture

### Atomic Design
- **Atoms**: Smallest units (Button, Input, Label, Icon)
- **Molecules**: Groups of atoms (SearchBar = Input + Button)
- **Organisms**: Complex sections (Header = Logo + Nav + SearchBar)
- **Templates**: Page layouts with placeholder content
- **Pages**: Templates filled with real content

Good mental model for design systems. Don't over-engineer the categorization.

### Headless Components
- Behavior without styling. You bring the design.
- **React**: Radix UI, React Aria (Adobe), Headless UI (Tailwind)
- **Angular**: Angular CDK (Component Dev Kit)
- Build accessible UIs with custom design on top.
- **Recommended approach** for custom design systems.

### Compound Components
- Related components that share state implicitly:
```jsx
<Select>
  <SelectTrigger>
  <SelectContent>
    <SelectItem value="a">Option A</SelectItem>
  </SelectContent>
</Select>
```
- Clean API for consumers. Internal state management hidden.
- Examples: Tabs/TabPanel, Accordion, Select/Option, Dialog.

### Container/Presenter (with Server Components)
- **Classic**: Container (data fetching) + Presenter (rendering).
- **With RSC**: Server Component (async data) + Client Component (interactivity).
- Natural separation: server components handle data, client components handle events.

### Design System Architecture
1. **Design Tokens**: Colors, spacing, typography, shadows as CSS custom properties or JS constants
2. **Primitives**: Base components (Box, Stack, Text, Button) with token-based styling
3. **Components**: Composed from primitives, business-agnostic
4. **Patterns**: Common UI patterns (forms, navigation, cards)

### Micro-Frontends
- Independent frontend applications composed into one user experience.
- **Module Federation** (Webpack 5, Rspack): Share code between independently built apps.
- **single-spa**: Framework-agnostic micro-frontend orchestrator.
- **When to use**: Large organizations (50+ frontend devs), independent teams needing deployment autonomy, migrating from legacy framework.
- **When to AVOID**: Small teams, single product, adds significant complexity.
- **Alternative**: Monorepo with shared packages (simpler, covers most needs).

---

## 3. Performance Optimization

### Bundle Size
- **Tree shaking**: Dead code elimination. ESM imports required.
- **Code splitting**: Dynamic `import()` for route-level and component-level splitting.
- **Lazy loading**: `React.lazy()`, Angular `@defer`, dynamic imports.
- **Analyze**: `@next/bundle-analyzer`, `rollup-plugin-visualizer`, `source-map-explorer`.
- **Target**: < 200KB initial JS (compressed). Each KB of JS costs ~1ms parse time on mobile.

### Image Optimization
- **Modern formats**: WebP (25-35% smaller), AVIF (50% smaller than JPEG)
- **Responsive**: `srcset` + `sizes` for per-device resolution
- **Lazy loading**: `loading="lazy"` on below-fold. NEVER on LCP image.
- **Dimensions**: Always set `width`/`height` for CLS prevention.
- **Framework components**: `next/image`, `NgOptimizedImage` — handle all of the above automatically.
- **CDN processing**: Cloudinary, imgix, Vercel Image Optimization.

### Font Loading
- `font-display: optional` (best CLS) or `swap` (faster text display)
- Preload critical fonts: `<link rel="preload" as="font" crossorigin>`
- Self-host fonts (avoid third-party DNS lookup)
- Variable fonts (one file for all weights)
- Subset to used characters only

### Critical Rendering Path
- Inline critical CSS in `<head>` (< 14KB to fit first TCP roundtrip)
- Defer non-critical CSS
- Preload LCP image, critical fonts
- Minimize render-blocking JS (defer, async, module)

### Service Workers / PWA
- Offline support, background sync, push notifications
- **Workbox**: Google's library for service worker generation
- Cache strategies: cache-first (static), network-first (API), stale-while-revalidate
- App manifest for installability
- **When to use**: Apps needing offline support, repeat visitors, mobile-first

### View Transitions API
- Smooth page transitions without full SPA overhead
- `document.startViewTransition()` for cross-document transitions
- CSS `view-transition-name` for element-level transitions
- Supported in Chrome, Safari (partial). Progressive enhancement — works without JS.

---

## 4. State Architecture

### Server State vs Client State
- **Server state**: Data from APIs (users, posts, products). Cached, refetched, invalidated.
  - Tools: TanStack Query (React), Apollo Client (GraphQL), SWR, Angular HttpClient + signals
- **Client state**: UI state (modals open, form values, theme preference). Local, synchronous.
  - Tools: useState/useReducer, Zustand, Jotai, Angular signals, NgRx ComponentStore
- **Don't mix them**. Most "state management" problems are actually server state problems solved by TanStack Query.

### URL as State
- Search params, routing, filters — use the URL.
- Benefits: shareable, bookmarkable, back-button works, SSR-friendly.
- `useSearchParams()` (Next.js/Remix), `ActivatedRoute` (Angular).

### Optimistic Updates
- Update UI immediately, revert if server fails.
- TanStack Query: `onMutate` for optimistic update, `onError` for rollback.
- Critical for: like buttons, comments, drag-and-drop reordering, real-time collaborative UIs.

### Global vs Local State Decision
```
Does only this component need it? → useState/signal (local)
Do sibling components need it? → Lift state up, or context/signal
Does the whole app need it? → Global store (Zustand, NgRx)
Is it from the server? → TanStack Query / SWR (server state, not global store)
Is it in the URL? → URL params (searchParams, router)
```

---

## 5. Accessibility (a11y)

### WCAG 2.2 AA (Minimum Standard)

**Perceivable:**
- Text alternatives for images (`alt` text)
- Captions for video, transcripts for audio
- Color contrast: 4.5:1 normal text, 3:1 large text (18px+ or 14px+ bold)
- Content reflows at 400% zoom without horizontal scrolling

**Operable:**
- All functionality keyboard-accessible
- Visible focus indicators (never `outline: none` without replacement)
- Skip navigation link
- No keyboard traps
- Touch targets minimum 24x24px (44x44px recommended)

**Understandable:**
- Language attribute (`<html lang="en">`)
- Consistent navigation
- Error identification and suggestion in forms
- Labels on all form inputs

**Robust:**
- Valid HTML
- ARIA used correctly (prefer native HTML semantics)
- Works with assistive technologies

### ARIA Patterns
- Use ARIA only when native HTML semantics are insufficient
- `role`, `aria-label`, `aria-labelledby`, `aria-describedby`
- `aria-live="polite"` for dynamic content announcements
- `aria-expanded`, `aria-selected`, `aria-checked` for interactive widgets
- Follow WAI-ARIA Authoring Practices for complex widgets (combobox, tabs, tree view)

### Focus Management in SPAs
- Announce route changes to screen readers (`aria-live` region or focus management)
- Move focus to main content on navigation (not back to top of page)
- Trap focus in modals/dialogs
- Return focus to trigger element when modal closes
- Manage focus in dynamic lists (add/remove items)

### Testing
- **axe-core**: Automated a11y testing engine. Integrations with Playwright, Cypress, Jest.
- **Lighthouse accessibility audit**: Automated checks for common issues.
- **Screen reader testing**: VoiceOver (Mac), NVDA (Windows), JAWS. Manual testing essential.
- **Keyboard-only testing**: Tab through entire page. Every interactive element reachable.
- **Color contrast checkers**: WebAIM Contrast Checker, browser DevTools.

---

## 6. Build and Tooling

### Vite (Current Standard)
- Dev server: native ESM, instant HMR (< 50ms).
- Production: Rollup-based bundling with optimizations.
- Framework support: React, Vue, Svelte, Preact, Lit, Angular (via Analog).
- Plugins: extensive ecosystem.
- **Default choice** for most new frontend projects.

### Turbopack (Next.js)
- Rust-based bundler by Vercel. Successor to Webpack for Next.js.
- Dev mode: incremental compilation, faster than Vite for large Next.js projects.
- `next dev --turbo`.
- Not usable outside Next.js.

### Rspack / Rsbuild
- Rust-based, Webpack-compatible bundler.
- Drop-in replacement for Webpack with 5-10x faster builds.
- Module Federation support.
- **When to use**: Migrating from Webpack without rewriting config.

### Bundle Analysis
- `@next/bundle-analyzer` for Next.js.
- `rollup-plugin-visualizer` for Vite.
- `source-map-explorer` for any bundler.
- `bundlephobia.com` to check package sizes before adding.

### Monorepo for Frontend
- **Turborepo**: Fast, convention-over-config. Remote caching. Vercel ecosystem.
- **Nx**: Full-featured. Code generators, affected detection, plugins for Angular/React/Next.
- **pnpm workspaces**: Package management only. Combine with Turbo/Nx for orchestration.

```
packages/
  ui/              # Shared component library
  config/          # Shared ESLint, TypeScript configs
  utils/           # Shared utilities
apps/
  web/             # Main web app (Next.js/Angular)
  admin/           # Admin dashboard
  docs/            # Documentation site (Astro)
```

---

## 7. Authentication in Frontend

### Token Storage

| Storage | XSS Risk | CSRF Risk | Best For |
|---------|----------|-----------|----------|
| HTTP-only cookie | Safe | Needs CSRF token | Server-rendered apps |
| localStorage | Vulnerable | Safe | Never (unless PKCE+short-lived) |
| Memory (variable) | Safe | Safe | SPAs with refresh token in cookie |
| sessionStorage | Vulnerable | Safe | Short sessions, less attack surface than localStorage |

**Recommended**: Access token in memory + refresh token in HTTP-only cookie with SameSite=Strict.

### OAuth/OIDC for SPAs
- Authorization Code Flow + PKCE (Proof Key for Code Exchange)
- **Never use Implicit Flow** (deprecated)
- BFF (Backend for Frontend) pattern keeps tokens server-side

### Auth Libraries
- **Auth.js (NextAuth)**: Next.js/SvelteKit/etc. 80+ OAuth providers.
- **Clerk**: Managed auth with UI components. User management dashboard.
- **Supabase Auth**: Integrated with Supabase. Email, OAuth, magic link, phone.
- **Firebase Auth**: Google's managed auth. Broad platform support.

---

## 8. API Integration Patterns

### Data Fetching Architecture

| Pattern | When to Use | Framework |
|---------|-----------|-----------|
| Server Components (async) | SSR data fetching, SEO pages | Next.js App Router |
| TanStack Query | Client-side caching, refetching, pagination | React |
| SWR | Simple client-side data fetching | React |
| tRPC | Full-stack TypeScript monorepo | React + any backend |
| HttpClient + signals | Observable-based data fetching | Angular |
| Loaders | Route-level data fetching | Remix, React Router v7 |

### Error Handling
- **Error Boundaries** (React): Catch rendering errors, show fallback UI.
- `error.tsx` (Next.js): Route-level error boundary.
- Toast notifications for non-blocking errors.
- Retry with exponential backoff for transient failures.

### Loading States
- **Skeleton screens** > spinners (perceived performance).
- `loading.tsx` (Next.js): Route-level loading with Suspense.
- `@defer` (Angular): Lazy load sections with loading/error/placeholder states.
- Suspense boundaries (React): Declarative loading states.

---

## 9. Monitoring and Observability

### Real User Monitoring (RUM)
- **web-vitals**: Measure LCP, INP, CLS in production. Send to analytics.
- **Vercel Analytics**: Speed Insights + Web Analytics. Zero-config for Vercel.
- **SpeedCurve**: RUM + synthetic monitoring. Performance budgets.

### Error Tracking
- **Sentry**: Stack traces, source maps, breadcrumbs, replay sessions.
- **LogRocket**: Session replay + error tracking.
- **Datadog RUM**: Full observability (frontend + backend correlation).

### Feature Flags
- **LaunchDarkly**, **Unleash**, **PostHog**, **Statsig**.
- Gradual rollout, A/B testing, kill switches.
- Client SDK evaluates flags locally (< 1ms).

### A/B Testing
- Feature flags + analytics for experiment tracking.
- **PostHog**: Feature flags + analytics + experimentation in one.
- **Statsig**: Feature gates + metrics correlation.
- Server-side evaluation preferred (avoids flicker). Edge middleware for zero-latency decisions.

---

## Decision Summary

| Decision | Default | Switch When |
|----------|---------|-------------|
| Rendering | SSR/SSG | Authenticated-only → SPA. Content-heavy → Islands (Astro) |
| Components | Headless (Radix/CDK) + custom design | Use component library (MUI/Angular Material) for internal tools |
| Styling | Tailwind CSS | Complex theming → CSS custom properties. RSC-compatible → CSS Modules |
| State (server) | TanStack Query | GraphQL → Apollo/urql. Angular → HttpClient+signals |
| State (client) | Local state (useState/signal) | Global needed → Zustand/Jotai/NgRx |
| Build | Vite | Next.js → Turbopack. Webpack migration → Rspack |
| Monorepo | Turborepo + pnpm | Large enterprise → Nx |
| Auth | HTTP-only cookies + PKCE | Managed → Clerk/Auth.js |
| Images | Framework component (next/image) | CDN processing → Cloudinary/imgix |
| Monitoring | Sentry + web-vitals | Full stack → Datadog RUM |
