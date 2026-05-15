---
title: Expo
description: Expo platform knowledge overlay — Expo SDK 55, Expo Router, EAS Build/Update/Submit/Workflows/Hosting, Expo Modules, CNG, Hermes, New Architecture. Current to SDK 55 (Feb 2026).
stack:
  vendor: expo
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - mobile-architect
    - frontend-architect
    - devops-engineer
    - qa-engineer
  authoritative_sources:
    - { name: "Expo Documentation",           url: "https://docs.expo.dev/",                                         type: official_docs }
    - { name: "Expo SDK API Reference",       url: "https://docs.expo.dev/versions/latest/",                         type: api_reference }
    - { name: "Expo Changelog",               url: "https://expo.dev/changelog",                                     type: changelog }
    - { name: "Expo Blog",                    url: "https://blog.expo.dev/",                                         type: changelog }
    - { name: "EAS Build Docs",               url: "https://docs.expo.dev/build/introduction/",                      type: official_docs }
    - { name: "EAS Update Docs",              url: "https://docs.expo.dev/eas-update/introduction/",                 type: official_docs }
    - { name: "EAS Submit Docs",              url: "https://docs.expo.dev/submit/introduction/",                     type: official_docs }
    - { name: "EAS Workflows Docs",           url: "https://docs.expo.dev/eas-workflows/get-started/",               type: official_docs }
    - { name: "EAS Hosting Docs",             url: "https://docs.expo.dev/eas/hosting/introduction/",                type: official_docs }
    - { name: "Expo Router Docs",             url: "https://docs.expo.dev/router/introduction/",                     type: official_docs }
    - { name: "Expo Modules API",             url: "https://docs.expo.dev/modules/overview/",                        type: official_docs }
    - { name: "Expo DOM Components",          url: "https://docs.expo.dev/guides/dom-components/",                   type: official_docs }
    - { name: "Continuous Native Generation", url: "https://docs.expo.dev/workflow/continuous-native-generation/",   type: official_docs }
    - { name: "React Native Releases",        url: "https://github.com/facebook/react-native/releases",              type: changelog }
  delegate_to_skills:
    - { skill: "expo-dev-client",            covers: ["expo-dev-client", "custom dev clients", "TestFlight distribution"] }
    - { skill: "expo-api-routes",            covers: ["Expo Router API routes", "EAS Hosting"] }
    - { skill: "expo-deployment",            covers: ["App Store submission", "Play Store submission", "EAS Submit", "web hosting"] }
    - { skill: "expo-cicd-workflows",        covers: ["EAS Workflows", "Expo CI/CD"] }
    - { skill: "expo-tailwind-setup",        covers: ["NativeWind v5", "Tailwind v4 in Expo"] }
    - { skill: "use-dom",                    covers: ["Expo DOM Components", "webview embedding"] }
    - { skill: "upgrading-expo",             covers: ["SDK upgrades", "Expo dependency migration"] }
    - { skill: "building-native-ui",         covers: ["Expo Router fundamentals", "styling", "navigation", "animations", "native tabs"] }
    - { skill: "native-data-fetching",       covers: ["fetch", "React Query", "SWR", "Expo Router data loaders"] }
    - { skill: "vercel-react-native-skills", covers: ["React Native + Expo performance", "lists", "animations", "native modules"] }
---

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Expo SDK 55 (React Native 0.83, React 19.2), EAS pricing & workflow changes through May 2026, and React Native 0.85 release notes.</div>

If today's date is more than 6 months past the last_verified_on above, treat platform specifics with extra care — bias toward the [authoritative sources](#authoritative-sources) for time-sensitive claims. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness. High-drift surfaces (SDK, Router, EAS Build/Update/Hosting/Workflows, API Routes, New Architecture) must be re-verified every 90 days; medium-drift every 180; low every 365.

## What changed in 2025-2026 that older training data misses

- **New Architecture is mandatory** — SDK 53+ removed the opt-out; RN 0.82 deleted the old architecture from the repo. Any answer that says "set `newArchEnabled: false`" is wrong.
- **Hermes is the only JS engine** — JSC was removed from RN. `jsEngine: 'jsc'` in `app.json` is dead.
- **`expo-cli` (global v0–v6) is dead** — use `npx expo` per-project for everything (start, prebuild, install, doctor). Don't `npm i -g expo-cli`.
- **App Center retired March 2025** — CodePush is replaced by **EAS Update** with Hermes bytecode diffing and branch-based channels. App Center Crashes → Sentry. App Center Build → EAS Build.
- **EAS Hosting is GA** (2025) — Cloudflare-Workers-backed serverless host for Expo Router web + API routes. Different runtime from Vercel/Node.
- **Continuous Native Generation (CNG) is the recommended workflow** — do not commit `ios/` and `android/` folders; regenerate via `npx expo prebuild`. Use config plugins for native edits.
- **Expo Router is the default router** since SDK 50; stable since SDK 51; typed routes GA; web static rendering GA; SSR alpha + data loaders experimental in SDK 55.
- **Expo DOM Components** (`'use dom'`) — run React-DOM trees inside a webview on native; stable since SDK 52.
- **Expo API Routes** (`+api.ts`) deploy to **EAS Hosting** Workers — Cloudflare Workers runtime, not Node. No `node:fs`/`node:net`; use Workers-compatible libs.
- **EAS Build runs on Apple Silicon** (since 2024); RN 0.84+ precompiled iOS binaries (`.xcframework`) cut clean iOS builds another ~8×.
- **Build caching is free** since SDK 55 (was paid in 2024); subsequent builds ~30% faster.
- **EAS Update Hermes bytecode diffing** (SDK 55) — typo-fix updates can be <50KB instead of ~3MB whole-bundle.
- **Expo Push uses FCMv1 only** since June 2024; APNs token auth (`.p8`) required, certificate auth deprecated.
- **NativeWind v4 stable / v5 RC** — v5 flips to Tailwind v4 CSS-first config; production-grade adoption expected mid-2026.
- **React 19.2 in SDK 55** — `use()`, `useOptimistic`, `<Activity>` API; React Compiler still opt-in (not on by default).
- **FlashList v2 requires the New Architecture**; old FlatList still works but is unfit for production.
- **Reanimated 4** is current; worklets moved to `react-native-worklets` (transparent dep).
- **MMKV v4 is a Nitro Module** — synchronous via JSI, ~30× faster than AsyncStorage.
- **`expo-av` is split** into `expo-video` + `expo-audio`; legacy `expo-av` remains compatible through SDK 56.
- **`/next` API suffixes** — `expo-file-system/next`, `expo-contacts/next`, `expo-media-library/next`, `expo-calendar/next`, `expo-sqlite/next` are the modern object-oriented surfaces; old exports graduate in SDK 56.
- **Android target API 34+** mandatory in 2026; API 35 by August 2026.

## Products covered

Canonical per-product pages under `/stacks/expo/<product>/`.

| Product | Drift risk | Why |
|---|---|---|
| [Expo SDK](/stacks/expo/expo-sdk/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Quarterly major releases; SDK 55 bundles RN 0.83 + React 19.2; APIs rename, packages graduate or retire per release |
| [Expo Router](/stacks/expo/expo-router/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Still adding capabilities (typed routes, data loaders, SSR alpha, API routes); behavior diff each SDK |
| [Expo Go](/stacks/expo/expo-go/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Dev sandbox; cannot run arbitrary native modules — config plugin or non-bundled libs force a dev client |
| [Custom Dev Clients](/stacks/expo/custom-dev-clients/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Recommended replacement for Expo Go for any real product; matrix of native modules tied to build, not runtime |
| [EAS Build](/stacks/expo/eas-build/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Image releases monthly; iOS precompiled binaries + Apple Silicon machines; cache policy + pricing tiers shift |
| [EAS Submit](/stacks/expo/eas-submit/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | App Store Connect + Play Console flows; ASC API key + Play service account plumbing |
| [EAS Update](/stacks/expo/eas-update/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Hermes bytecode diffing, phased rollouts, branch/channel mapping evolving; replaced CodePush after App Center retired |
| [EAS Workflows](/stacks/expo/eas-workflows/) | <span class="etyb-drift-badge" data-risk="high">high</span> | YAML CI/CD in `.eas/workflows/`; new actions added per release; Maestro integration steady |
| [EAS Hosting](/stacks/expo/eas-hosting/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2025 — Cloudflare-Workers-backed host for Expo Router web + API routes; routing/limits still maturing |
| [expo-dev-client](/stacks/expo/expo-dev-client/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | The `expo-dev-client` package itself — installs the dev menu, OTA debug client, etc. |
| [expo-image](/stacks/expo/expo-image/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | SDWebImage/Glide-backed; non-negotiable for remote images on RN; replaces `react-native-fast-image` |
| [expo-file-system](/stacks/expo/expo-file-system/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | `/next` (object-API) shipped SDK 54; legacy exports through SDK 56 |
| [expo-secure-store](/stacks/expo/expo-secure-store/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Keychain (iOS) / Keystore-backed encrypted prefs (Android); stable API |
| [expo-camera](/stacks/expo/expo-camera/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | New `CameraView` API in SDK 51; legacy `Camera` deprecated; permission UX is platform-specific |
| [expo-notifications](/stacks/expo/expo-notifications/) | <span class="etyb-drift-badge" data-risk="high">high</span> | FCMv1 mandatory; Android channels required; iOS foreground handler shape changed; APNs token auth required |
| [expo-location](/stacks/expo/expo-location/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Background mode permissions are Apple/Google's biggest review pain points |
| [expo-auth-session](/stacks/expo/expo-auth-session/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | OIDC/OAuth client; PKCE mandatory; redirect URI conventions stable |
| [Expo Modules API](/stacks/expo/expo-modules/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Swift/Kotlin module authoring; JSI-backed; surface evolves with RN architecture |
| [Expo DOM Components](/stacks/expo/expo-dom-components/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Run web code inside a webview on native; bridge via marshalled props/messages |
| [Expo API Routes](/stacks/expo/expo-api-routes/) | <span class="etyb-drift-badge" data-risk="high">high</span> | `+api.ts` files run on EAS Hosting Workers (Cloudflare runtime) — diff from Vercel/Node |
| [Hermes](/stacks/expo/hermes/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Default and only JS engine in SDK 52+; JSC removed |
| [New Architecture](/stacks/expo/new-architecture/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Mandatory in SDK 53+; bridgeless-only in RN 0.82+; older libs still being ported |
| [Continuous Native Generation](/stacks/expo/continuous-native-generation/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Recommended pattern: don't commit native projects; regenerate via `npx expo prebuild` |
| [app.json / app.config.js](/stacks/expo/app-config/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Schema additions per SDK; config plugin contract stable but gains hooks |
| [Metro Bundler](/stacks/expo/metro-bundler/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | RN's bundler; Expo wraps it; SDK 55 added experimental tree-shaking + module-graph improvements |
| [Expo CLI (`npx expo`)](/stacks/expo/expo-cli/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Per-project CLI; global `expo-cli` is dead. `start`, `prebuild`, `install`, `run:*`, `export`. |
| [expo-doctor](/stacks/expo/expo-doctor/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Dependency + native module sanity checker; checks expand per SDK |
| [Snack](/stacks/expo/snack/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Browser playground; latest SDK supported within ~2 weeks of release |
| [EAS CLI](/stacks/expo/eas-cli/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | `npx eas` (formerly `eas-cli`) — build, update, submit, workflows, deploy, env, credentials |

## Role overlays

Composed views under `/stacks/expo/<role>/`. Each one stitches together the products that role's work touches.

- [mobile-architect on Expo](/stacks/expo/mobile-architect/)
- [frontend-architect on Expo](/stacks/expo/frontend-architect/)
- [devops-engineer on Expo](/stacks/expo/devops-engineer/)
- [qa-engineer on Expo](/stacks/expo/qa-engineer/)

## Authoritative sources

For verified-current behavior, see the official Expo surfaces:

- **[Expo Documentation](https://docs.expo.dev/)** — canonical reference
- **[Expo SDK API Reference (latest)](https://docs.expo.dev/versions/latest/)** — current is SDK 55
- **[Expo Changelog](https://expo.dev/changelog)** — quarterly SDK posts + intra-quarter platform changes
- **[Expo Blog](https://blog.expo.dev/)** — narrative posts on major releases
- **[EAS Build Docs](https://docs.expo.dev/build/introduction/)** — cloud builds, profiles, credentials
- **[EAS Update Docs](https://docs.expo.dev/eas-update/introduction/)** — OTA, channels, rollouts, rollback
- **[EAS Submit Docs](https://docs.expo.dev/submit/introduction/)** — store submission flows
- **[EAS Workflows Docs](https://docs.expo.dev/eas-workflows/get-started/)** — YAML CI/CD
- **[EAS Hosting Docs](https://docs.expo.dev/eas/hosting/introduction/)** — Workers-backed web host
- **[Expo Router Docs](https://docs.expo.dev/router/introduction/)** — file-based router
- **[Expo Modules API](https://docs.expo.dev/modules/overview/)** — Swift/Kotlin module authoring
- **[Expo DOM Components](https://docs.expo.dev/guides/dom-components/)** — `'use dom'` directive
- **[Continuous Native Generation](https://docs.expo.dev/workflow/continuous-native-generation/)** — managed-workflow contract
- **[React Native Releases](https://github.com/facebook/react-native/releases)** — RN version that ships with each SDK

## Delegate skills

When the user's environment has these Expo / Anthropic skills installed, ETYB defers to them for the listed surfaces:

- **`expo-dev-client`** — dev client builds, distribution flows (TestFlight Internal, EAS Internal Distribution)
- **`expo-api-routes`** — `+api.ts` files + EAS Hosting deploy specifics
- **`expo-deployment`** — App Store + Play Store submission, web hosting
- **`expo-cicd-workflows`** — EAS Workflows YAML authoring patterns
- **`expo-tailwind-setup`** — NativeWind v4→v5 setup, Tailwind v4 config
- **`use-dom`** — Expo DOM Components patterns
- **`upgrading-expo`** — SDK upgrade procedures
- **`building-native-ui`** — Expo Router fundamentals, styling, animations, native tabs
- **`native-data-fetching`** — fetch / React Query / SWR / Expo Router data loaders
- **`vercel-react-native-skills`** — performance, lists, native modules

When one of these skills is installed and the user's request matches its `covers` list, ETYB hands off the implementation specifics while keeping the platform overlay context loaded.
