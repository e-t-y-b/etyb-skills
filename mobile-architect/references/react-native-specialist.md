# React Native / Expo — Deep Reference

**Always use `WebSearch` to verify version numbers and features. React Native and Expo release new SDKs every few months, and the ecosystem evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [New Architecture](#1-new-architecture)
2. [Expo SDK and Services](#2-expo-sdk-and-services)
3. [Hermes Engine](#3-hermes-engine)
4. [Expo Router and Navigation](#4-expo-router-and-navigation)
5. [State Management](#5-state-management)
6. [Styling](#6-styling)
7. [UI Component Libraries](#7-ui-component-libraries)
8. [Data Fetching and Offline](#8-data-fetching-and-offline)
9. [Animation](#9-animation)
10. [Native Modules](#10-native-modules)
11. [Testing](#11-testing)
12. [Build and Deployment](#12-build-and-deployment)
13. [Performance Optimization](#13-performance-optimization)
14. [Monorepo Patterns](#14-monorepo-patterns)
15. [Cross-Platform and Web](#15-cross-platform-and-web)
16. [TypeScript Patterns](#16-typescript-patterns)
17. [Push Notifications](#17-push-notifications)
18. [Deep Linking](#18-deep-linking)
19. [Developer Tooling](#19-developer-tooling)
20. [App Store Guidelines](#20-app-store-guidelines)

---

## 1. New Architecture

### Status: Fully Mandatory (April 2026)

The old bridge is gone. The New Architecture is the only architecture:

- **React Native 0.76** (late 2024): New Architecture became the default
- **React Native 0.82**: Old architecture permanently disabled (`RCT_REMOVE_LEGACY_ARCH` forced ON)
- **React Native 0.85** (April 2026, latest stable): "Post-bridge era" — 604+ commits from 58 contributors

### Three Pillars

**Fabric Renderer**: C++ renderer driving both iOS and Android from a single implementation. Eliminates platform-specific rendering bugs, enables concurrent rendering, offloads work to GPU thread. Delivers 55-60fps animations vs legacy 30-45fps.

**TurboModules**: Type-safe, lazily loaded native modules built on JSI. Lazy loading cuts cold-start memory by ~40%. Direct synchronous JS-to-native calls with sub-2ms interop latency (vs hundreds of ms on old bridge).

**Bridgeless Mode**: Now the only mode. All communication goes through JSI. No opt-out.

### Migration

- All `expo-*` packages in SDK 53+ support New Architecture including bridgeless mode
- RN 0.84 ships precompiled iOS binaries (`.xcframework`), making clean iOS builds ~8x faster on Apple Silicon
- Legacy `NativeModules` API no longer works — all modules must be TurboModules or Expo Modules
- Node.js v22.11+ is required as of RN 0.84

---

## 2. Expo SDK and Services

### SDK Versions

| SDK | React Native | React | Release |
|-----|-------------|-------|---------|
| **SDK 55** (latest) | 0.83 | 19.2 | Feb 2026 |
| SDK 54 | 0.81 | — | Late 2025 |
| SDK 53 | 0.79 | 19 | Mid 2025 |
| **SDK 56** (planned) | 0.85 | — | Q2 2026 |

### SDK 55 Highlights

- Legacy architecture removed entirely from codebase
- EAS Build caching: up to 30% faster subsequent builds (free for all users)
- Re-written web error overlay, alpha SSR support, experimental data loaders
- New object-oriented APIs: `expo-contacts/next`, `expo-media-library/next`, `expo-calendar/next`

### EAS (Expo Application Services)

| Service | Purpose |
|---------|---------|
| **EAS Build** | Cloud-based native builds for iOS and Android. SDK 55 adds build caching (~30% faster) |
| **EAS Update** | OTA JavaScript bundle updates without app store review. Hermes bytecode diffing, phased rollouts, rollback |
| **EAS Submit** | Automated submission to App Store and Google Play |
| **EAS Workflows** | YAML-defined CI/CD pipelines in `.eas/workflows/` |
| **EAS Hosting** | Deploy Expo Router web apps and API routes |

### Pricing

- Free tier: limited low-priority builds
- Starter: $19/month with $45 build credit
- Production: $99/month with larger quotas

---

## 3. Hermes Engine

### Hermes V1 (Default since RN 0.84)

Hermes is the only supported JS engine for React Native on both iOS and Android:

- **30% less memory** usage vs previous Hermes versions
- **Faster cold starts** via bytecode pre-compilation (JS compiled at build time, not runtime)
- **10-15% improvement** in Time to Interactive (TTI) for complex views
- Better ES6+ support (classes, const/let, async/await improvements)
- WebAssembly support (groundwork for on-device AI inference)

For Expo: Hermes is the default and only engine in SDK 52+. Configuration is automatic via `expo-build-properties`.

---

## 4. Expo Router and Navigation

### Expo Router (Recommended)

File-based routing built on React Navigation, shipped by default in new Expo projects:

- **Automatic deep linking** for all routes (zero manual configuration)
- **Typed routes** with full TypeScript support
- **API routes** (`+api.ts` files) for server-side logic
- **Static rendering** on web for SEO
- **Lazy/deferred bundling** in development
- **SplitView support** for tablet two-pane layouts
- Dynamic routes, nested layouts, groups, modals

### React Navigation 7 (Underlying Layer)

- Version 7.2.2 (latest)
- Static API for simpler TypeScript and deep linking
- Screen preloading for perceived performance
- `useSyncExternalStore`: 40-60% reduction in navigation-related re-renders

### Comparison

| Feature | Expo Router | React Navigation |
|---------|------------|-----------------|
| Routing model | File-based (convention) | Component-based (configuration) |
| Deep linking | Automatic | Manual setup |
| Type safety | Built-in typed routes | Manual typing |
| Web support | Static rendering, SSR | Basic web support |
| API routes | Yes (+api files) | No |
| Learning curve | Lower (Next.js-like) | Higher (more flexible) |

**Recommendation**: Expo Router for all new Expo projects. Use raw React Navigation only for brownfield apps or projects where file-based routing creates friction.

---

## 5. State Management

### The 2026 Consensus: Separate Server State from Client State

**Recommended stack**: TanStack Query (server state) + Zustand (client state) + MMKV (persistence)

### Zustand 5.x (Client State)

- ~1KB bundle, ~4M weekly downloads
- No providers, no boilerplate, async actions built-in
- Persistence via `zustand/middleware` + MMKV or AsyncStorage
- Use `useShallow` for performance, slice pattern for scalability
- **When to use**: App-wide client state (auth, UI toggles, settings, feature flags)

### TanStack Query v5 (Server State)

- ~5M weekly downloads
- Automatic caching, background refetching, optimistic updates
- Offline persistence: `@tanstack/query-async-storage-persister` + `PersistQueryClientProvider`
- Requires manual `onlineManager` setup with NetInfo for React Native
- **When to use**: Any API data fetching, server state caching

### Jotai 2.19.x (Atomic State)

- ~2.5KB bundle
- Atom-based model — build state bottom-up
- `atomWithStorage` for persistence
- Extensions: tRPC, Immer, XState, Query
- **When to use**: Complex derived state graphs, atom-level granularity

### Legend State 2.x (Signal-Based)

- ~4KB bundle, signal-based fine-grained reactivity
- Built-in sync engine with plugins for Supabase, Keel, TanStack Query
- Persistence via MMKV, works with React Compiler
- **When to use**: Performance-critical apps needing fine-grained reactivity and built-in sync

### MMKV 4.3.x (Key-Value Storage)

- 30x faster than AsyncStorage, fully synchronous via JSI
- Supports strings, booleans, numbers, ArrayBuffers
- Requires New Architecture (RN 0.74+) — now a Nitro Module
- **When to use**: Any persistent key-value storage, Zustand/Legend State persistence layer

### Redux Toolkit

- ~4M weekly downloads but rarely chosen for new projects in 2026
- ~15KB bundle — significantly larger than alternatives
- Still dominant in large enterprise codebases with existing investment

---

## 6. Styling

### NativeWind v4 (Stable — Recommended for Production)

Tailwind CSS for React Native. Compiles Tailwind classes to `StyleSheet.create` objects at build time. Supports media queries, container queries, custom values.

### NativeWind v5 (Pre-release)

- Uses **Tailwind CSS v4** with CSS-first configuration (no `tailwind.config.js`)
- Replaces JSX transform with import rewrite system
- Not yet recommended for production

### Unistyles 3.0 (Maximum Performance)

- C++ core communicating with Fabric via JSI, bypasses bridge entirely
- **Zero re-renders**: No hooks, no context — pure JSI bindings
- Smart recalculation: only recalculates styles affected by changes
- Requires New Architecture (RN 0.78+)
- **When to use**: Maximum performance, complex theme switching without re-renders

### Tamagui (Design System + Compiler)

- Full UI kit + styling system + optimizing compiler
- Design tokens, themes, responsive props
- Compiler flattens styles to most efficient native code
- **When to use**: Design-system-driven apps, single codebase for web+native

### StyleSheet (Built-in)

- Zero dependencies, best raw performance for static styles
- No theme support, no responsive utilities out of the box
- **When to use**: Simple apps, performance-critical components

**Production recommendation**: NativeWind v4 (stable) or Unistyles 3.0 (if on New Architecture).

---

## 7. UI Component Libraries

### Gluestack-UI (Recommended for New Projects)

- Successor to NativeBase (same team, NativeBase is deprecated)
- Headless core + accessible components, inspired by shadcn/ui and Radix
- Works with React Native and web
- Compatible with React 19 and React Compiler

### React Native Paper 5.15.x

- Material Design 3 (Material You) support
- 50+ pre-built components following Google's guidelines
- Dynamic theming, improved accessibility
- **Best for**: Material Design apps, Android-first apps

### Tamagui

- Optimizing compiler flattens styles to most efficient native code
- Full component library + styling system
- Higher setup complexity

### shadcn-react-native

- Port of shadcn/ui for React Native, works with Gluestack under the hood
- Copy-paste component model (you own the code)
- **Best for**: Teams familiar with shadcn/ui from web

---

## 8. Data Fetching and Offline

### Recommended Stack

TanStack Query (API fetching) + MMKV (key-value) + WatermelonDB or expo-sqlite (relational offline data)

### TanStack Query v5

- Automatic caching, background refetching, optimistic updates
- Offline mutations via `queryClient.setMutationDefaults()`
- Offline persistence via `@tanstack/query-async-storage-persister`

### WatermelonDB (Large Offline Datasets)

- SQLite backend, optimized for React Native
- Handles 50k+ records efficiently with lazy loading
- Sync primitives for backend synchronization
- **When to use**: Complex offline-first apps with large datasets

### expo-sqlite

- Lightweight relational storage included in Expo SDK
- Nitro SQLite (`react-native-nitro-sqlite`) from Margelo for maximum performance
- **When to use**: Structured relational data, complex queries

### PowerSync / RxDB

- Emerging alternatives for offline-first architectures
- PowerSync: Postgres-backed offline-first sync
- RxDB: Offline apps needing production sync to any backend

---

## 9. Animation

### Reanimated 4.3.x (Primary Animation Library)

- New declarative, CSS-compatible animation API (aims to replace worklets in many cases)
- Works ONLY with New Architecture
- Worklets moved to separate `react-native-worklets` package (transparent dependency)
- Backward-compatible with Reanimated 3 — no code changes needed when upgrading
- **When to use**: All performance-critical animations, gesture-driven interactions

### React Native 0.85 Shared Animation Backend

- New unified engine powers both built-in `Animated` API and Reanimated
- Layout props (width, height, flex, position) can now be animated with native driver
- Core React Native feature, not a separate library

### Moti

- Declarative animation library powered by Reanimated 3
- Simplifies common animations with clean API
- Used by Shopify in production
- **When to use**: Quick declarative animations without manual worklet code

### Lottie (lottie-react-native 6.x)

- Renders After Effects animations exported as JSON
- Controllable by Animated or Reanimated
- **When to use**: Designer-created complex animations, loading states, onboarding

**Recommendation**: Reanimated 4 for interactive animations, Moti for declarative simplicity, Lottie for designer animations.

---

## 10. Native Modules

### Expo Modules API (Recommended for Expo Projects)

- Write Swift and Kotlin to add native capabilities
- Performance comparable to TurboModules (both use JSI)
- Consistent API across iOS and Android, minimal boilerplate
- **When to use**: Adding native functionality in Expo projects

### Nitro Modules (Margelo — Maximum Performance)

- Supports C++, Swift, Kotlin
- Built on `jsi::NativeState` (more efficient than `jsi::HostObject`)
- Type-safe via `nitrogen` code generator (TypeScript specs as source of truth)
- Used by react-native-mmkv v4, react-native-nitro-sqlite
- **When to use**: High-performance native modules, standalone libraries

### TurboModules (React Native Core)

- Official React Native native module system
- Type-safe, lazy-loaded, built on JSI
- **When to use**: C++-heavy native modules, non-Expo projects

### JSI (JavaScript Interface)

- Underlying layer all three approaches are built on
- Enables synchronous JS-to-native communication
- Not typically used directly by app developers

**Recommendation**: Expo Modules API for Expo projects. Nitro for standalone libraries. TurboModules for C++-heavy non-Expo modules.

---

## 11. Testing

### Jest 30 (Unit & Integration)

- Default test runner for React Native
- Pre-configured in Expo projects
- RN 0.85 ships new `@react-native/jest-preset`

### React Native Testing Library (Component Tests)

- The definitive component testing solution for React Native
- User-centric approach: query by text, accessibility role, testID
- Replaces deprecated `react-test-renderer`

### Maestro (E2E — Recommended for Most Teams)

- YAML-based declarative test flows, no package installation needed
- Used by Meta's core React Native team for framework testing
- Maestro Studio Desktop: free visual test designer
- MaestroGPT: AI-assisted test authoring
- Integrates with EAS Workflows for CI

### Detox (E2E — Advanced)

- Gray-box testing by Wix
- Synchronizes with JS thread to eliminate timing flakiness
- Tests in JavaScript/TypeScript
- Deepest React Native integration of any E2E tool

**Recommended Stack**: Jest 30 (unit) → React Native Testing Library (component) → Maestro (E2E, most teams) or Detox (advanced E2E)

---

## 12. Build and Deployment

### EAS Build

- Cloud-native iOS and Android builds
- SDK 55 adds build caching (~30% faster)
- RN 0.84 precompiled iOS binaries (~8x faster clean builds on Apple Silicon)

### EAS Update (OTA)

- Over-the-air JavaScript bundle updates without store review
- SDK 55: Hermes bytecode diffing, phased rollouts, rollback support
- Updates only JavaScript and assets (no native code changes)
- Compliant with Apple Guideline 2.5.2

### CodePush Alternatives (Post-App Center Retirement March 2025)

| Solution | Key Feature | Best For |
|----------|------------|----------|
| **EAS Update** | Hermes bytecode diffing, rollouts | Expo projects (primary choice) |
| **Revopush** | Drop-in CodePush replacement | Easiest migration from CodePush |
| **Stallion** | 98% smaller patches (binary diffing) | Maximum patch efficiency |
| **Self-hosted CodePush** | Full control | Teams with DevOps capacity |

### EAS Workflows

YAML-defined CI/CD pipelines in `.eas/workflows/`. Automate builds, submissions, updates, and E2E tests (Maestro integration).

---

## 13. Performance Optimization

### FlashList v2 (Shopify)

- **Production-ready, New Architecture only**
- Complete rewrite from v1 — no item size estimates required (uses synchronous layout measurements)
- Masonry layout support (Pinterest-style)
- Maintains 60fps with complex items
- **Breaking**: Does NOT work on old architecture

### React Native Skia 2.6.x

- GPU-accelerated 2D graphics (same engine as Chrome, Flutter)
- Moved to Fabric reconciler: ~50% faster on iOS, ~200% faster on Android
- SkiaList renders at consistent 120fps with no blank spaces
- Capabilities: shaders, image filters, SVG, path operations, text layouts
- **When to use**: Custom graphics, charts, data visualization, gaming-style UIs

### Key Performance Practices

1. FlashList v2 for all scrollable lists (never use FlatList for production)
2. Reanimated 4 worklets for animations (keeps JS thread free)
3. `useNativeDriver: true` on all Animated animations
4. React Native Skia for GPU-accelerated custom rendering
5. Avoid inline styles and anonymous functions in render methods
6. Use `React.memo`, `useMemo`, `useCallback` strategically (avoid premature optimization)
7. Use Hermes V1 (default) for fastest cold starts and lowest memory
8. Profile with React Native DevTools Performance panel

---

## 14. Monorepo Patterns

### Turborepo + pnpm (Most Common)

- Turborepo handles task running and caching
- pnpm workspaces for package management

### Recommended Structure

```
apps/
  mobile/          # Expo app
  web/             # Next.js app (optional)
packages/
  ui/              # Shared component library
  api/             # API client / data fetching
  shared/          # Business logic, types, utils
  config/          # ESLint, TypeScript configs
```

### Expo Monorepo Configuration

- Expo has [official monorepo documentation](https://docs.expo.dev/guides/monorepos/)
- `metro.config.js` needs to be configured to resolve workspaces
- Use `expo-env-info` and Expo's environment variables for Metro caching

### Key Templates

- [byCedric/expo-monorepo-example](https://github.com/byCedric/expo-monorepo-example) — fast pnpm monorepo
- [Vercel Turborepo React Native Starter](https://vercel.com/templates/next.js/turborepo-react-native)

---

## 15. Cross-Platform and Web

### Expo Universal Apps

Expo is the officially recommended framework for React Native. Meta's React Native team: "the only recommended community framework for React Native is Expo."

- First-class web support with static rendering (SSR/SSG for SEO) or client-rendered (SPA)
- Expo Router handles routing across all platforms uniformly
- API routes deploy to EAS Hosting

### DOM Components (expo/dom)

- Run web code in a WebView on native and as-is on web
- Enables incremental migration of web code to native

### Cross-Platform Code Sharing

- **Platform-specific files**: `Component.ios.tsx`, `Component.android.tsx`, `Component.web.tsx`
- **`Platform.select()`**: Inline platform branching
- **Shared packages in monorepo**: Business logic, types, API clients

---

## 16. TypeScript Patterns

### Strict TypeScript API (RN 0.80+)

- Stronger, more future-proof types for the `react-native` package
- Opt-in via `reactNativeStrictTypes: true` in tsconfig
- Enable `"strict": true` in `tsconfig.json` (Expo projects come pre-configured)

### Key Patterns

1. **Discriminated unions** for screen params, API responses, UI states
2. **Branded types** for IDs (`UserId`, `OrderId`) to prevent mixing
3. **Typed navigation** via Expo Router's typed routes
4. **Type-safe storage** wrappers around MMKV
5. **Optional chaining (`?.`)** for safe nested property access
6. **`as const` assertions** for literal types

### Expo Router Type Safety

- Routes automatically typed based on file structure
- `useLocalSearchParams<{id: string}>()` for typed route params
- `Link` component accepts typed `href` prop

---

## 17. Push Notifications

### expo-notifications

Works with Expo Push Service, FCM, and APNs:

- **ExpoPushToken**: For Expo Push Service (wraps FCM/APNs, handles credentials)
- **Native device push token**: For direct FCM/APNs communication
- Push notifications do NOT work on emulators/simulators — real device required

### Expo Push Service (Recommended)

- Automatic APNs credential management and FCM configuration
- Simple API: POST to Expo Push API with ExpoPushToken
- Handles delivery, receipts, error reporting

### Setup

1. Install `expo-notifications`
2. Request permissions with `requestPermissionsAsync()`
3. Get token with `getExpoPushTokenAsync()` or `getDevicePushTokenAsync()`
4. Register token with your backend
5. Handle incoming with `addNotificationReceivedListener()`

---

## 18. Deep Linking

### Expo Router (Recommended)

Deep links automatically enabled for ALL routes — zero manual configuration. File-system convention eliminates `linking.ts` and nested state objects.

### Universal Links (iOS) and App Links (Android)

- Standard `https://` URLs — open app if installed, website/store if not
- Require domain verification:
  - **iOS**: AASA file at `/.well-known/apple-app-site-association`
  - **Android**: Asset Links at `/.well-known/assetlinks.json`
- **Expo**: Configure in `app.json` under `expo.ios.associatedDomains` and `expo.android.intentFilters`
- Expo's CNG (Continuous Native Generation) handles native configuration automatically

### Custom URL Schemes

- Format: `myapp://path/to/screen`
- No verification required but susceptible to hijacking
- Configure in `app.json` under `expo.scheme`
- Less recommended in 2026 — prefer App Links / Universal Links

---

## 19. Developer Tooling

### React Native DevTools (Core)

- Stable since RN 0.76, based on Chrome DevTools frontend
- Tabs: Console, Sources, Network (Expo only), Memory, Components, Profiler
- RN 0.85: Supports multiple simultaneous CDP connections (DevTools + VS Code + AI agents)

### Radon IDE (Software Mansion)

- VS Code / Cursor / Windsurf extension
- Embeds simulator/emulator preview directly in editor
- Built-in breakpoint debugging (zero configuration)
- Network Inspector, Redux DevTools, React Query DevTools
- Commercial license (free trial)

### Expo Dev Tools Plugins

- React Navigation history/state viewer
- Apollo Client cache/query inspector
- Available in development builds and Expo Go

### VS Code Integration

- "Expo: Debug" command attaches VS Code to running app
- TypeScript IntelliSense works out of the box

---

## 20. App Store Guidelines

### OTA Update Rules

**Apple App Store (Strict)**:
- Guideline 2.5.2: OTA updates must not "significantly change the app"
- Only update JavaScript bundles and assets — never native code
- Do NOT create new storefronts or compromise system security

**Google Play Store (More Permissive)**:
- JavaScript bundle updates are generally allowed
- Must not update in ways that bypass Google services for native code

### Review Process Tips

1. Test on physical devices, not just simulators
2. Screenshots must accurately represent the app
3. Privacy Policy required and must be accessible within the app
4. Only request permissions your app actively uses
5. Provide test credentials and explain non-obvious features in review notes
6. Common rejections: crashes, placeholder content, broken links, incomplete features, misleading descriptions

### Submission Timeline

- Apple: Typically 24-48 hours
- Google: Usually same-day
- Expedited review available from Apple for critical bug fixes

## Version Quick Reference (April 2026)

| Technology | Version |
|------------|---------|
| React Native | 0.85 |
| Expo SDK | 55 (RN 0.83, React 19.2) |
| Hermes | V1 |
| React Navigation | 7.2.2 |
| Reanimated | 4.3.0 |
| Zustand | 5.0.12 |
| TanStack Query | v5 |
| MMKV | 4.3.1 |
| FlashList | v2 |
| React Native Skia | 2.6.2 |
| NativeWind | v4 stable / v5 pre-release |
| Maestro | latest |
| Expo Router | latest (SDK 55) |
