# React Native — Platform-Neutral Patterns + Expo Stack Pointer

This file used to be a 660-line single-specialist reference covering React Native + Expo together. As of v4.0.0 (2026-05-14), **Expo-specific content has migrated to the Expo Stack Pack**; this file retains the bare-workflow React Native patterns and platform-neutral mobile principles.

## Expo content lives in the Expo Stack

[`stacks/expo/SKILL.md`](../../../../../../stacks/expo/SKILL.md) and `stacks/expo/references/mobile-architect.md` cover:

- **Expo SDK** (current major version) and the SDK version → React Native version → JS engine version mapping
- **Expo Router** — file-based routing for native + web with shared route definitions
- **EAS suite** — EAS Build (cloud build with Apple Silicon machines), EAS Submit (App Store + Play Store submission), EAS Update (OTA updates), EAS Workflows, EAS Hosting (Cloudflare Workers-backed for API Routes)
- **Custom Dev Clients** as the production replacement for Expo Go
- **Continuous Native Generation** (CNG) via `expo prebuild` — no committed `ios/` and `android/` folders
- **Expo Modules API** — authoring native modules without touching Xcode/Android Studio config
- **Expo DOM Components** — running web code in a webview alongside native
- **Expo API Routes** — server-side routes that run on EAS Hosting (Cloudflare Workers-backed)
- **New Architecture** (Fabric + TurboModules) as the default in SDK 51+ and mandatory in 53+
- **Hermes** as the default JS engine; JSC removed
- **The Expo CLI** replacing the legacy `react-native` CLI for everything
- **Common companions** — NativeWind v5 (Tailwind v4 for RN), Reanimated 3, Skia, FlashList, MMKV — as Expo's recommended stack
- **Push notifications** — FCM HTTPv1 mandate (legacy server keys deprecated June 2024), APNs token auth, Expo Push Notifications service
- **Crashlytics + Sentry** integration via Expo config plugins

## What stays in the platform-neutral surface (this file)

The Mobile Architect specialist still owns these patterns, applicable to bare React Native and to React Native projects not using Expo:

- **The bare workflow** — when you need full control over `ios/` and `android/` folders, custom native module integration that requires hand-edited Xcode targets, or CI requirements Expo Cloud doesn't support. The bare workflow trades convenience for control
- **Generic state management taxonomy** — Zustand (lightweight, hooks-first), Jotai (atomic, suspense-friendly), Legend State (signals, fast diffs), Redux Toolkit (RTK Query for server state). When each fits, regardless of Expo vs bare
- **Generic styling library taxonomy** — StyleSheet (built-in, performant), styled-components (CSS-in-JS, mature), Tamagui (cross-platform with web), NativeWind (Tailwind), Restyle (Shopify, type-safe themes). Tradeoffs around bundle size, runtime cost, theming flexibility
- **Monorepo patterns** — Nx, Turborepo, pnpm workspaces, Yarn 4 workspaces. Sharing code between RN apps + RN package(s) + web frontend; module-resolution gotchas; Metro `resolver.disableHierarchicalLookup`
- **Deep linking semantics** — URL scheme vs Universal Links / App Links, multi-platform routing, deferred deep links (post-install attribution). Expo Router uses these primitives but the protocol itself is platform-neutral
- **Performance patterns** — list virtualization (FlatList vs FlashList vs LegendList), image caching strategies, memoization, navigation cost, native-driver animations, JSI direct calls, list-item recycling
- **TypeScript patterns in RN** — module declaration shims for non-TS native modules, navigation typing, theme typing, asset typing via `*.d.ts`
- **Native module authoring (bare)** — Objective-C/Swift binding patterns for iOS, Kotlin/Java for Android, TurboModule + Codegen, JSI for performance-critical paths. (Expo wraps a lot of this — see Expo Stack for the Expo Modules API path)
- **Testing strategy** — Jest for unit, React Native Testing Library for component, Detox for E2E on real devices, Maestro for declarative UI tests, Storybook for component dev. Vendor-neutral; covered in `qa-engineer/references/` for the test-strategy lens
- **iOS-specific concerns** — code signing, provisioning profiles, TestFlight, App Store Connect, ATT/SKAdNetwork, iOS 18+ features (Live Activities, Widgets), entitlements
- **Android-specific concerns** — keystore management, AAB vs APK, Play Console release tracks, Android 14+ exact alarms, foreground service types, Play Integrity API

## How ETYB uses both layers

When a request mentions Expo, EAS, expo-* packages, `app.json`, dev clients, OTA updates, or any Expo SDK feature, ETYB's router loads the Expo Stack alongside this specialist. When the request is about bare workflow, native module integration without Expo, or platform-neutral mobile patterns, this specialist alone suffices.
