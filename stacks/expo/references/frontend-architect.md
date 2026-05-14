---
role: frontend-architect
stack: expo
last_verified_on: "2026-05-14"
---

# Expo Overlay — frontend-architect

You are frontend-architect on an Expo engagement. On Expo, "frontend" is **three surfaces** — iOS, Android, and web — rendered by mostly the same React tree. Your job is to design the shared component model, the routing surface, the styling strategy, and the web parity discipline so all three render correctly without forking business logic. Expo Router is the unifying primitive: file-based routing that works on native + web with one tree. NativeWind/Tailwind, Tamagui, or Unistyles is the styling primitive. EAS Hosting (Cloudflare Workers) is where the web target deploys.

**Currency:** Expo SDK 55, React 19.2, Expo Router (stable, with experimental data loaders + alpha SSR for web), NativeWind v4 stable / v5 RC (Tailwind v4 / CSS-first), Tamagui current, Unistyles 3.0 on JSI.

## Role briefing — what frontend-architect owns on Expo

1. **Routing model** — Expo Router as the default; file-based; typed routes; nested layouts; native + web from one tree.
2. **Component sharing strategy** — what's truly cross-platform, what forks via `Component.ios.tsx`/`Component.web.tsx`, what lives only on web (Next.js-style admin) or only on native (camera UI).
3. **Styling** — NativeWind v4 (stable) or v5 (Tailwind v4, CSS-first), Tamagui (compiler-based), Unistyles 3.0 (JSI, zero-rerender). One — not three.
4. **Web target** — Static rendering for SEO surfaces (marketing, public pages), client-only for app-shell, alpha SSR via EAS Hosting for dynamic auth-aware pages.
5. **Expo DOM Components** — `'use dom'` directive lets a React-DOM tree run inside a webview on native. Useful for rich-text editors, charting libs, or incremental migration of an existing web codebase.
6. **Expo API Routes** — `+api.ts` files in `app/` are the backend-for-frontend (BFF). Deployed to EAS Hosting on Cloudflare Workers. Auth, rate limiting, server-only env vars live here.
7. **Design system** — Component library (UI primitives) shared across mobile + web; ideally as a `packages/ui` workspace. Defer to design-system specialist for tokens + theming; this overlay is about Expo-specific composition.
8. **Accessibility** — accessibility roles, labels, hints; web ARIA mapping; screen reader testing (VoiceOver on iOS, TalkBack on Android, NVDA/JAWS on web).
9. **Web parity discipline** — When something doesn't work on web (haptics, camera with permissions, native sheets), what does the web fallback look like?
10. **Loading states + transitions** — skeletons, suspense boundaries, shared element transitions across screens.

## Decision frameworks

### 1. Expo Router or raw React Navigation?

| Scenario | Choose |
|----------|--------|
| New Expo project, native + web | **Expo Router** (file-based, default). Typed routes; deep linking automatic; web rendering built in. |
| Brownfield RN app with deep React Navigation customization | **React Navigation 7** directly; migrate to Expo Router incrementally if you want web. |
| App where one screen needs a navigator API Expo Router doesn't expose well | **Expo Router + drop to React Navigation hooks where needed** (Expo Router *is* React Navigation underneath). |
| Pure web (no native) | **Don't use Expo.** Use Next.js + Vercel/EAS Hosting. Expo's value is the cross-platform shared tree. |

In 2026, "raw React Navigation" without Expo Router is the niche choice. The router team's roadmap is delivered through Expo Router.

### 2. What gets shared vs forked across platforms?

A simple mental model:

- **Shared by default**: data fetching, state management, business logic, types, API client, validation, formatters, copy strings.
- **Component-shared with platform overrides** when needed: UI primitives (Button, Text, Input, Card). Use `Component.web.tsx` and `Component.ios.tsx`/`.android.tsx` files when behavior differs.
- **Forked**: navigation chrome (tab bar on native vs sidebar on web), heavy native UI (camera screens, sensors, AR), heavy web UI (admin tables, dashboards with hover states), payments (Apple Pay sheet on iOS, Google Pay on Android, Stripe Elements on web).
- **Native-only**: anything that requires a config plugin or native module.
- **Web-only**: anything where the web is the canonical surface (admin panels, content management, account billing UI).

**Anti-pattern: "we share 100%."** You will hit ceilings — sheet UIs, picker UIs, gesture-heavy flows. Plan for forks early; don't get to the point where you've written a worse-than-native sheet in pure JS to maintain 100% sharing.

### 3. NativeWind vs Tamagui vs Unistyles vs StyleSheet

| Scenario | Choose |
|----------|--------|
| Team knows Tailwind, web parity matters, NativeWind v4 acceptable | **NativeWind v4** (stable). Tailwind v3 config + `className` everywhere; compiles to `StyleSheet.create`. |
| Same as above but want Tailwind v4 + CSS-first config | **NativeWind v5** (RC; production-grade in most projects by mid-2026). |
| Design-system-driven app, single codebase web+native, willing to learn a new DSL | **Tamagui.** Optimizing compiler flattens to the most efficient native form. Components + tokens included. |
| Performance-critical, complex theme switching, willing to skip className APIs | **Unistyles 3.0** (JSI, zero re-renders on theme change). |
| Small app, no themes, want zero deps | **StyleSheet** (built-in). Static only — no responsive, no dark mode utilities. |

For most teams in 2026, the practical choice is **NativeWind v4 stable** until v5 is broadly considered production-grade (likely mid-2026). NativeWind v5 + Tailwind v4 is faster and cleaner once stable; the migration is manageable but not trivial (config moves into CSS, JSX transform replaced by import rewrite — see `expo-tailwind-setup` delegate skill for the playbook).

**Don't use multiple styling systems in one app.** NativeWind + Tamagui in the same tree confuses tooling and doubles bundle size. Pick one.

### 4. Web rendering mode (static vs client vs SSR)

Expo Router's web target supports three modes (configured in `app.json` under `expo.web.output`):

| Mode | When | Notes |
|------|------|-------|
| `single` (SPA) | Default. App-shell, auth-gated tools. No SEO need. | Fast cold start once bundle loads; bad for SEO. |
| `static` | Public pages (marketing, blog, docs). SEO matters. | Pre-renders HTML at build time. Hydrates on the client. Works great on EAS Hosting / Vercel. |
| `server` (SSR) | Auth-aware dynamic pages. SDK 55 alpha. | Renders on EAS Hosting (Cloudflare Workers) per-request. Plan around Workers runtime limits. |

Most apps end up `single` for the app surface + `static` for marketing/landing pages, deployed as two separate Expo Router outputs or split apps. SSR is alpha in SDK 55 — use it for surfaces that genuinely need per-request server rendering, but treat it as experimental.

### 5. Expo DOM Components — when to reach for webview

`'use dom'` at the top of a `.tsx` file makes its export render inside a `WebView` on native (and as-is on web):

```tsx
'use dom';
import { useEffect, useRef } from 'react';
import { Editor } from '@tiptap/react';

export default function RichTextEditor({ initialHtml, onChange }: { initialHtml: string; onChange: (html: string) => void }) {
  // This is real DOM — document, window, CSS, npm web packages all work
  // Communicates with native via props (in) + onChange callback (out)
  return <div contentEditable onInput={(e) => onChange(e.currentTarget.innerHTML)}>{initialHtml}</div>;
}
```

**When to use:**

- Rich text editors (Tiptap, ProseMirror, Lexical) that have no native equivalent
- Chart libraries (Recharts, D3, Chart.js) with mature web implementations
- Migrating an existing web codebase incrementally
- Embedding a web-only third party (Stripe Elements, Plaid Link)

**When not to use:**

- Anything performance-critical (scrolling lists, animations) — webview overhead is real
- Anything that needs deep native integration (camera, GPS) — back to RN
- Things with a great native equivalent (don't `'use dom'` a button)

The bridge is JSON-serializable props + a `postMessage`-style return channel. Don't expect to share refs.

### 6. Expo API Routes architecture

```
app/
├─ (app)/
│  ├─ _layout.tsx
│  ├─ index.tsx               # /
│  └─ profile.tsx             # /profile
├─ api/
│  ├─ users+api.ts            # GET/POST /api/users  (Workers runtime)
│  └─ orders/[id]+api.ts      # GET/POST /api/orders/:id
└─ +not-found.tsx
```

```ts
// app/api/users+api.ts
import type { ExpoRequest, ExpoResponse } from 'expo-router/server';

export async function GET(request: ExpoRequest) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit') ?? '20');
  const users = await db.users.findMany({ limit });
  return Response.json({ users });
}

export async function POST(request: ExpoRequest) {
  const body = await request.json();
  // validate, persist, etc.
  return Response.json({ ok: true }, { status: 201 });
}
```

**Runtime is Cloudflare Workers** when deployed via EAS Hosting. Implications:

- **No `node:fs`, no `node:net`, no full Node API surface.** Workers runtime only.
- **Bindings, not env vars** for KV/D1/R2. Configure via `wrangler.toml` (yes, Cloudflare's config) or EAS Hosting's secrets surface.
- **CPU time limits** (50ms free tier, 30s paid). No long-polling; use WebSockets via Durable Objects or move to a dedicated worker.
- **Web Crypto API** is your friend; `crypto-js` and similar Node-targeted libs may not work.
- **Database** — `@neondatabase/serverless`, `drizzle-orm`, `@prisma/client` (edge mode), or `cloudflare:d1`. Don't reach for `pg` (TCP) or `mysql2` (TCP).

This is identical surface to Cloudflare Workers in the Cloudflare Stack — borrow patterns. ETYB's Cloudflare Stack overlay applies to API Route code.

### 7. Loading + Suspense strategy

React 19.2 + Expo Router supports Suspense in routes:

```tsx
// app/profile.tsx
import { Suspense } from 'react';
import { ProfileSkeleton } from '@/components/skeletons';

export default function ProfileRoute() {
  return (
    <Suspense fallback={<ProfileSkeleton />}>
      <Profile />
    </Suspense>
  );
}
```

With experimental data loaders (SDK 55):

```tsx
// app/profile.tsx
export async function loader() {
  const profile = await fetchProfile();
  return { profile };
}

import { useLoaderData } from 'expo-router';
export default function ProfileRoute() {
  const { profile } = useLoaderData<typeof loader>();
  return <Profile data={profile} />;
}
```

Data loaders run server-side on web (SSR mode) and pre-fetch on native via the router's prefetch system. Use for above-the-fold data; keep below-the-fold data in client-side React Query.

## 2025–2026 platform reset items relevant to frontend-architect

### Expo Router maturity (SDK 55)

- **Stable**: file-based routing, typed routes, deep linking, nested layouts, modals, web static rendering.
- **Experimental**: data loaders, SSR for web.
- **Alpha**: React Server Components.
- **SDK 55 new**: re-written web error overlay, alpha SSR support, experimental data loaders, `Link.preload()` for pre-fetching screens.

The mental model: Expo Router is Next.js App Router for native + web. If you know one, you can read the other; the divergences are at the leaves (no `'use server'` in RN, no `getServerSideProps`).

### NativeWind v4 stable / v5 RC

- **v4**: Tailwind v3 config + `className`. Compiles to `StyleSheet.create` at build time. Stable, broadly adopted.
- **v5**: Tailwind v4 CSS-first config (no `tailwind.config.js`). Replaces JSX transform with import rewrite. RC as of early 2026; broadly considered production-grade by mid-2026.
- Migration cost is real (CSS-first config; some plugin compatibility checks). The `expo-tailwind-setup` skill walks the migration.

### React 19.2 specifics

- **`use()`** unwraps promises/contexts in render. Suspends if the promise isn't ready.
- **`useOptimistic`** for optimistic UI. Works on both web + native.
- **`<Activity>`** (React 19.1+) for off-screen-but-mounted UI. Lets Expo Router pre-render a tab before activation.
- **Server Components** — alpha in Expo Router for web only; RN doesn't have an RSC story yet beyond what the web target offers.
- **React Compiler** — opt-in via Babel plugin. Speeds up renders by auto-memoizing. Most apps see +5–15% in heavy-render scenarios. Not enabled by default in Expo.

### Web target on EAS Hosting

- **Static (`output: 'static'`)** is the default for marketing/SEO. Builds to static HTML + JS, deploys to EAS Hosting's CDN.
- **SSR (`output: 'server'`)** runs on Workers. Per-request render; suspense boundaries flush as HTML streams.
- **Caching**: EAS Hosting honors `Cache-Control` headers from API routes; static pages are cached at the edge by default.
- **Custom domains** + automatic TLS via Cloudflare.
- **No `vercel.json`** — EAS Hosting config is in `app.json` under `expo.web` or in EAS Hosting dashboard.

### Expo DOM Components

- Introduced 2024, stable since SDK 52. `'use dom'` directive at top of file.
- Renders in `react-native-webview` on native, identity on web.
- Props are JSON-serializable; outbound calls are `WebView.postMessage` style.
- Bundle size impact: each DOM component adds the webview footprint (~minor on iOS, larger on Android).
- Common use: rich text editors, chart libraries, third-party widgets (Stripe Elements, Plaid Link).

### NativeWind/Tamagui/Unistyles state of play

- **NativeWind**: dominant for Tailwind-fluent teams. Web-native + cross-platform.
- **Tamagui**: dominant when design-system-as-code is the bar (BMW, Daylight, x.com on RN, etc.). Compiler does heavy work.
- **Unistyles 3.0**: most performant. JSI-backed; no hooks, no context — pure native bindings. Best for theme-heavy apps where every screen reflects user-chosen theme.
- **StyleSheet**: still good for small apps + library code (no end-user theming).

## Patterns and anti-patterns

### Pattern: Cross-platform component with platform overrides

```tsx
// components/Sheet.tsx (default - native)
import BottomSheet from '@gorhom/bottom-sheet';
export function Sheet({ children, isOpen, onClose }: SheetProps) {
  // native bottom sheet
}

// components/Sheet.web.tsx (web override)
import { Dialog } from '@radix-ui/react-dialog';
export function Sheet({ children, isOpen, onClose }: SheetProps) {
  // web modal dialog
}
```

Metro automatically picks `Sheet.web.tsx` on web, `Sheet.tsx` on native. Same import path; different file resolved.

### Pattern: Shared component library in `packages/ui`

```
packages/
└─ ui/
   ├─ src/
   │  ├─ Button/
   │  │  ├─ index.tsx
   │  │  ├─ Button.tsx
   │  │  └─ Button.web.tsx   # optional web fork
   │  ├─ Text/
   │  └─ ...
   ├─ package.json
   └─ tsconfig.json
```

Consumed by `apps/mobile` and `apps/web` alike. NativeWind classes are interpreted on both targets. Tamagui has explicit cross-platform components.

### Pattern: Conditional rendering with `Platform.OS`

```tsx
import { Platform } from 'react-native';

function PaymentButton() {
  if (Platform.OS === 'ios') return <ApplePayButton />;
  if (Platform.OS === 'android') return <GooglePayButton />;
  return <StripeWebButton />; // web
}
```

Acceptable for small platform forks. For larger ones, use `.ios.tsx`/`.android.tsx`/`.web.tsx` files.

### Pattern: Typed routes

```tsx
// app/_layout.tsx
import { Stack } from 'expo-router';
export default function RootLayout() {
  return <Stack />;
}

// app/order/[id].tsx
import { useLocalSearchParams } from 'expo-router';

export default function OrderScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <Order id={id} />;
}
```

```tsx
// somewhere else
import { Link } from 'expo-router';
<Link href={{ pathname: '/order/[id]', params: { id: '123' } }}>Order 123</Link>
```

Enable typed routes in `app.json`:

```json
"plugins": [["expo-router", { "typedRoutes": true }]]
```

Compile-time check: `href="/order/123"` is correctly typed. Don't ship without typed routes in 2026.

### Pattern: Nested layouts

```
app/
├─ _layout.tsx               # root Stack
├─ (auth)/                   # group, no path segment
│  ├─ _layout.tsx           # auth-only Stack
│  ├─ login.tsx
│  └─ register.tsx
├─ (app)/                    # group, no path segment
│  ├─ _layout.tsx           # main Tabs
│  ├─ index.tsx             # /
│  ├─ profile.tsx           # /profile
│  └─ settings/
│     ├─ _layout.tsx       # settings Stack
│     ├─ index.tsx         # /settings
│     └─ security.tsx      # /settings/security
```

Each `_layout.tsx` is a navigator. Groups (`(auth)`, `(app)`) don't appear in URLs but let you swap navigators. Use to gate routes:

```tsx
// app/(app)/_layout.tsx
import { Redirect, Tabs } from 'expo-router';
import { useAuth } from '@/hooks/useAuth';

export default function AppLayout() {
  const { user, loading } = useAuth();
  if (loading) return <Splash />;
  if (!user) return <Redirect href="/login" />;
  return <Tabs />;
}
```

### Pattern: Modals via groups

```
app/
├─ _layout.tsx
├─ index.tsx
└─ (modal)/
   ├─ _layout.tsx           # presentation: 'modal' on native
   └─ compose.tsx           # /compose
```

```tsx
// app/(modal)/_layout.tsx
import { Stack } from 'expo-router';
export default function ModalLayout() {
  return <Stack screenOptions={{ presentation: 'modal' }} />;
}
```

Now `<Link href="/compose">` opens compose as a modal on iOS (sheet) and Android (full-screen with close). On web, it's a regular page — fork via `(modal)/_layout.web.tsx` if you want a dialog.

### Anti-pattern: stateful navigation in business logic

```tsx
// BAD: business hook decides navigation
function useOrderFlow() {
  const router = useRouter();
  const place = async () => {
    await placeOrder();
    router.replace('/order/confirmation');  // 👈 logic owns nav
  };
  return { place };
}
```

```tsx
// BETTER: business hook returns result; route handles nav
function useOrderFlow() {
  const place = async () => {
    return await placeOrder();
  };
  return { place };
}

function CheckoutScreen() {
  const router = useRouter();
  const { place } = useOrderFlow();
  const onSubmit = async () => {
    const result = await place();
    if (result.ok) router.replace('/order/confirmation');
  };
}
```

Navigation in components, not hooks. Routes own routing.

### Anti-pattern: `useEffect` for navigation side effects

```tsx
// BAD
useEffect(() => {
  if (loggedIn) router.replace('/home');
}, [loggedIn]);
```

```tsx
// BETTER (declarative)
if (loggedIn) return <Redirect href="/home" />;
```

`<Redirect>` doesn't depend on render order; `useEffect` race-conditions with screen mount.

### Anti-pattern: `Image` source as inline object

```tsx
// BAD - new object identity every render, defeats Image's diff
<Image source={{ uri: avatarUrl }} />
```

```tsx
// BETTER - useMemo, or use expo-image which handles it better
<ExpoImage source={avatarUrl} />
```

`expo-image` accepts a string `source` directly; `Image` from `react-native` does not.

### Anti-pattern: Web parity for native-only features

```tsx
// BAD: try to fake haptics on web
function tap() {
  if (Platform.OS === 'web') {
    // silent fail with no UX cue
  } else {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  }
}
```

```tsx
// BETTER: explicit, document the platform difference
function tap() {
  if (Platform.OS === 'web') return; // haptics not supported; no-op intentionally
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
}
```

Don't try to invent a haptic experience on web with CSS animations; that's worse than nothing. Accept the platform reality and move on.

### Anti-pattern: Heavy DOM Component for trivial UI

```tsx
'use dom';
export default function Button({ label, onPress }) { return <button onClick={onPress}>{label}</button>; }
```

Don't wrap a button in a webview. DOM Components have overhead. Reserve for genuinely-web-only libraries.

## Tooling specifics

### Styling

- `nativewind` (v4) or `nativewind@next` (v5) + `tailwindcss`
- `@tamagui/babel-plugin` + `tamagui` for the compiler path
- `react-native-unistyles` for the JSI-based system
- `expo-system-ui` for system-level UI (status bar color, navigation bar color on Android)

### Components

- `expo-image` — *always* for remote images
- `expo-blur` — native blur (UIVisualEffectView / RenderEffect on Android 12+)
- `expo-linear-gradient` — gradients
- `expo-symbols` — SF Symbols on iOS (Android fallback via `expo-symbols` `fallback` prop)
- `@gorhom/bottom-sheet` — native bottom sheets
- `react-native-svg` — SVG (current major; older versions break NA)
- `react-native-skia` — GPU drawing
- `lottie-react-native` — Lottie animations
- `@shopify/flash-list` v2 — production lists

### Web

- Expo Router renders to React DOM on web; you don't need separate Next.js for app surfaces
- `react-native-web` is bundled via Metro; CSS classes from NativeWind/Tamagui resolve
- Server-side: API Routes (`+api.ts`) on EAS Hosting Workers
- Static assets: `public/` directory at project root (auto-served)

### A11y

- `accessibilityRole` (button, link, header, image, text, etc.) — RN → ARIA mapping on web
- `accessibilityLabel` (overrides text on screen readers)
- `accessibilityHint` (additional context after the label)
- `accessibilityState` (selected, checked, disabled)
- `accessibilityValue` (for sliders, progress bars)
- `accessibilityLiveRegion` (Android only — for live updates)

Test with:
- iOS: VoiceOver (Settings > Accessibility > VoiceOver)
- Android: TalkBack (Settings > Accessibility > TalkBack)
- Web: NVDA on Windows, VoiceOver on macOS

## Cross-references

- **Stack products from this overlay:** [Expo Router](../SKILL.md), [Expo DOM Components](../SKILL.md), [Expo API Routes](../SKILL.md), [EAS Hosting](../SKILL.md).
- **Other role overlays:** [`mobile-architect.md`](./mobile-architect.md) for native module strategy + animation deep-dive; [`devops-engineer.md`](./devops-engineer.md) for EAS Hosting deploy specifics; [`qa-engineer.md`](./qa-engineer.md) for component testing + visual regression.
- **Composes with:**
  - `stacks/cloudflare/` — API Routes deploy to Workers; the Cloudflare Stack overlay applies to API Route code.
  - `stacks/vercel/` — Alternative web host; the Vercel Stack overlay applies if you ship Expo's web output to Vercel.
  - `stacks/supabase/` — Auth + RLS patterns commonly consumed from Expo Router screens.
- **Delegate to skills when installed:** `building-native-ui` (Expo Router + styling + animations tutorials), `expo-tailwind-setup` (NativeWind setup), `use-dom` (DOM Components), `native-data-fetching` (React Query / data loaders), `expo-api-routes` (API routes + EAS Hosting).

## Integration with always-on protocols

### TDD

- **Unit tests** for pure render logic (utils, formatters, selectors). Same Jest setup as the rest of the team.
- **Component tests** with React Native Testing Library — query by accessibility role / text / testID. Mock `expo-router` via `jest.mock('expo-router', () => ({ useRouter: jest.fn(), Link: jest.fn(({ children }) => children) }))`.
- **Visual regression** — Chromatic or Storybook on the web target. Native visual regression is hard (sim variance); Maestro screenshots are the practical answer.

### Verification

Before claiming a route works:

1. Build runs cleanly on iOS + Android + web (`expo start --web` for web).
2. Typed routes pass tsc (`expo-router` adds route types via `expo-env.d.ts`).
3. Deep link opens the route (`xcrun simctl openurl booted 'myapp://order/123'`).
4. Accessibility scanner shows no errors (Xcode Accessibility Inspector / Android Accessibility Scanner / Lighthouse).
5. Web bundle size doesn't regress (`expo export --platform web` then check `dist/_expo/static/js/web/`).

### Debugging

| Symptom | First move |
|---------|------------|
| "Web build fails with 'document is undefined'" | A package referencing `document` at module-load time is bundled into native. Use `Platform.OS === 'web'` guard or `.web.tsx` file fork. |
| "Web works, native doesn't see the page" | Check the route file extension order — Metro resolves `.ios.tsx` → `.native.tsx` → `.tsx`. A `Page.web.tsx` without a sibling `.tsx`/`.native.tsx` is web-only. |
| "Typed routes fail TypeScript build" | Run `npx expo customize` then `tsc --noEmit`. Sometimes the generated route types lag; restart the TS server. |
| "NativeWind classes don't apply" | Check `tailwind.config.js` content paths include all source files. Restart Metro. |
| "EAS Hosting API route returns 500 with no logs" | `eas-cli` logs are in the EAS dashboard; check Worker logs. Common cause: a Node-only import (`crypto-js`, `pg`, etc.). |
| "DOM Component doesn't render" | Check the file has `'use dom'` at the top. Confirm `react-native-webview` is installed (Expo DOM ships it). |

Three-failure rule applies: if three reasonable hypotheses don't crack it, escalate (Expo Discord `#router` channel, file in `expo/router`).

## Web parity checklist (per release)

- [ ] All app routes load on web without console errors
- [ ] All native-only features have a documented web fallback (no-op, alternative UI, or 'not available on web' notice)
- [ ] Web bundle is split (initial < 250KB gzipped; route chunks < 100KB)
- [ ] SEO surfaces (marketing, blog) use `output: 'static'` and have meta tags via `expo-router` `<Stack.Screen options={{ ... }}>`
- [ ] OG image, favicon, manifest.json present
- [ ] Lighthouse score: Performance ≥ 80, Accessibility ≥ 95, Best Practices ≥ 90, SEO ≥ 90 on static pages
- [ ] All interactive elements reachable by Tab + Enter (keyboard nav)
- [ ] Screen reader tested on at least one full user flow

This is the bar for "frontend-architect signed off on the web target."
