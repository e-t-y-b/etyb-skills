---
title: Expo Router
description: File-based router for Expo apps — one tree renders iOS, Android, and web. Typed routes, nested layouts, deep linking, web static rendering all built in.
product:
  name: Expo Router
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect, qa-engineer]
  authoritative_url: https://docs.expo.dev/router/introduction/
  notes: "Still adding capabilities (typed routes, data loaders, SSR alpha, API routes); behavior diff each SDK"
---

## What it is

**Expo Router** is the file-based router for Expo apps. Files in `app/` map to URLs; nested folders create nested navigators. The same tree renders iOS, Android, and web. Under the hood it's React Navigation, but the routing surface is declarative: drop a file in `app/profile.tsx`, get a `/profile` route everywhere.

It's the default router in `create-expo-app` since SDK 50, stable since SDK 51. Typed routes are GA. Web static rendering is GA. SSR for web is alpha in SDK 55. Experimental data loaders (`loader` exports + `useLoaderData`) shipped in SDK 55. React Server Components are alpha for web only.

Canonical surface: [Expo Router Docs](https://docs.expo.dev/router/introduction/).

## When to use

Default choice for any new Expo project that needs more than one screen. The mental model: **Expo Router is Next.js App Router for native + web**. If you know one, you can read the other.

Use raw React Navigation directly only for brownfield RN apps with deep navigation customization or for niche cases where Expo Router doesn't expose what you need. You can drop to React Navigation hooks inside an Expo Router app — Expo Router *is* React Navigation underneath.

Don't use Expo (and Expo Router) for **pure web** with no native target. Use Next.js + Vercel/EAS Hosting. Expo's value is the cross-platform shared tree.

## 2025-2026 currency anchors

- **SDK 51** — Expo Router stable; typed routes GA.
- **SDK 53** — web static rendering GA.
- **SDK 55 (Feb 2026)** — alpha SSR for web; experimental data loaders (`loader` export + `useLoaderData`); re-written web error overlay; `Link.preload()` for screen pre-fetching.
- **Typed routes** require enabling: `plugins: [["expo-router", { "typedRoutes": true }]]` in `app.json`. Compile-time URL checks via TS types in `expo-env.d.ts`. Don't ship without this in 2026.
- **API Routes** (`+api.ts`) deploy to **EAS Hosting** Workers (Cloudflare runtime). See [Expo API Routes](/stacks/expo/expo-api-routes/).
- **React Server Components** alpha (web only in Expo Router). Not for production. RN doesn't have an RSC story beyond what the web target offers.

## Patterns + anti-patterns

### Pattern: Nested layouts + groups

```
app/
├─ _layout.tsx               # root Stack
├─ (auth)/                   # group, no path segment
│  ├─ _layout.tsx            # auth Stack
│  ├─ login.tsx
│  └─ register.tsx
├─ (app)/                    # group, no path segment
│  ├─ _layout.tsx            # main Tabs
│  ├─ index.tsx              # /
│  ├─ profile.tsx            # /profile
│  └─ settings/
│     ├─ _layout.tsx         # settings Stack
│     └─ security.tsx        # /settings/security
└─ +not-found.tsx
```

Groups (`(auth)`, `(app)`) don't appear in URLs but let you swap navigators. Use to gate routes:

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

### Pattern: Typed routes

```tsx
import { Link } from 'expo-router';
<Link href={{ pathname: '/order/[id]', params: { id: '123' } }}>Order 123</Link>
```

With `typedRoutes: true`, `href` is statically checked.

### Pattern: Modal presentation via groups

```
app/
├─ index.tsx
└─ (modal)/
   ├─ _layout.tsx           # presentation: 'modal'
   └─ compose.tsx           # /compose
```

```tsx
// app/(modal)/_layout.tsx
import { Stack } from 'expo-router';
export default function ModalLayout() {
  return <Stack screenOptions={{ presentation: 'modal' }} />;
}
```

`<Link href="/compose">` opens compose as a modal (iOS sheet, Android full-screen). On web, it's a regular page — fork via `(modal)/_layout.web.tsx` for a dialog.

### Pattern: Declarative redirects

```tsx
// BETTER
if (loggedIn) return <Redirect href="/home" />;
```

```tsx
// BAD — race conditions with mount
useEffect(() => {
  if (loggedIn) router.replace('/home');
}, [loggedIn]);
```

`<Redirect>` is order-independent; `useEffect` competes with first render.

### Pattern: Suspense in routes (React 19.2)

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

### Pattern: Data loaders (experimental, SDK 55)

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

Loaders run server-side on web (SSR mode) and pre-fetch on native via the router's prefetch system. Use for above-the-fold data; keep below-the-fold data in client-side React Query.

### Anti-pattern: Navigation in business hooks

```tsx
// BAD
function useOrderFlow() {
  const router = useRouter();
  const place = async () => {
    await placeOrder();
    router.replace('/order/confirmation');
  };
  return { place };
}
```

Routes own routing; hooks return results. The screen decides where to go next.

## Gotchas

- **`runtimeVersion` matters** — Expo Router updates ship as OTA JS bundles. If you add a config plugin or bump a native dep, fingerprint changes, OTAs no longer reach the old binary. See [EAS Update](/stacks/expo/eas-update/).
- **Typed routes lag occasionally** — after adding a route, run `npx expo customize` + restart the TS server if types don't appear.
- **`document` undefined on native** — a web-only package imported into a shared component will crash native bundles. Use `Platform.OS === 'web'` guards or `.web.tsx` file forks.
- **Route file extension precedence** — Metro resolves `.ios.tsx` → `.native.tsx` → `.tsx`. A `Page.web.tsx` without a `.tsx` sibling is web-only and crashes native.
- **API Routes are a different runtime** — `+api.ts` files run on Cloudflare Workers (EAS Hosting). No Node API; use Workers-compatible libs.

## Cross-references

- [Expo API Routes](/stacks/expo/expo-api-routes/) — `+api.ts` files
- [EAS Hosting](/stacks/expo/eas-hosting/) — where web + API routes deploy
- [Expo SDK](/stacks/expo/expo-sdk/) — Router is bundled with the SDK
- [building-native-ui](https://docs.expo.dev/) skill (delegate) — Router fundamentals tutorial
- Role overlays: [frontend-architect](/stacks/expo/frontend-architect/), [mobile-architect](/stacks/expo/mobile-architect/)
- [Expo Router Docs](https://docs.expo.dev/router/introduction/)
