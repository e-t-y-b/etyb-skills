---
name: stack-expo
description: >
  Expo platform knowledge overlay for the ETYB team. Loads when work involves the Expo
  ecosystem — Expo SDK, Expo Router, EAS Build / Submit / Update / Workflows / Hosting,
  expo-dev-client, Expo Modules API, Continuous Native Generation, Hermes, the New
  Architecture (Fabric + TurboModules), Expo DOM Components, Expo API Routes, app.json /
  app.config.js, the `npx expo` CLI, and the wider expo-* package family. This is NOT a
  new team member; it is a context overlay that teaches each existing ETYB role what it
  needs to know to ship production-grade Expo work as of SDK 55 (Spring 2026).
  Triggers: expo, expo go, expo router, expo sdk, expo cli, eas, eas build, eas update,
  eas submit, eas workflows, eas hosting, eas insights, eas cli, expo-dev-client, dev client,
  custom dev client, expo modules, expo modules api, expo dom, dom components, expo api routes,
  app.json, app.config.js, app.config.ts, app config plugin, expo config plugin, prebuild,
  expo prebuild, continuous native generation, cng, hermes, jsc, fabric, turbomodule, turbo
  modules, new architecture, bridgeless, react native, react-native, metro, metro bundler,
  expo-router, expo-image, expo-file-system, expo-secure-store, expo-camera, expo-image-picker,
  expo-notifications, expo-location, expo-auth-session, expo-application, expo-task-manager,
  expo-background-fetch, expo-haptics, expo-linear-gradient, expo-linking, expo-system-ui,
  expo-localization, expo-av, expo-video, expo-audio, expo-asset, expo-constants, expo-updates,
  expo-font, expo-splash-screen, expo-status-bar, expo-screen-orientation, expo-sensors,
  expo-store-review, expo-tracking-transparency, expo-web-browser, expo-clipboard, expo-print,
  expo-sharing, expo-mail-composer, expo-sms, expo-contacts, expo-media-library, expo-calendar,
  expo-doctor, snack, expo snack, eas-cli, ota update, over the air update, otaupdate channels,
  testflight, app store connect, play console, internal distribution, internal testing,
  flashlist, reanimated, react-native-reanimated, react-native-skia, nativewind, tamagui,
  unistyles, gluestack, watermelondb, mmkv, nitro modules, codepush replacement, jest preset,
  react-native-testing-library, maestro, detox, radon ide, react native devtools.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
  last_verified_release: "Expo SDK 55 (React Native 0.83, React 19.2)"
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - mobile-architect
    - frontend-architect
    - devops-engineer
    - qa-engineer
authoritative_sources:
  primary:
    - { name: "Expo Documentation",          url: "https://docs.expo.dev/",                             type: official_docs }
    - { name: "Expo SDK API Reference",       url: "https://docs.expo.dev/versions/latest/",             type: api_reference }
    - { name: "Expo Changelog",               url: "https://expo.dev/changelog",                         type: changelog }
    - { name: "Expo Blog",                    url: "https://blog.expo.dev/",                             type: changelog }
    - { name: "EAS Build Docs",               url: "https://docs.expo.dev/build/introduction/",          type: official_docs }
    - { name: "EAS Update Docs",              url: "https://docs.expo.dev/eas-update/introduction/",     type: official_docs }
    - { name: "EAS Submit Docs",              url: "https://docs.expo.dev/submit/introduction/",         type: official_docs }
    - { name: "EAS Workflows Docs",           url: "https://docs.expo.dev/eas-workflows/get-started/",   type: official_docs }
    - { name: "EAS Hosting Docs",             url: "https://docs.expo.dev/eas/hosting/introduction/",    type: official_docs }
    - { name: "Expo Router Docs",             url: "https://docs.expo.dev/router/introduction/",         type: official_docs }
    - { name: "Expo Modules API",             url: "https://docs.expo.dev/modules/overview/",            type: official_docs }
    - { name: "Expo DOM Components",          url: "https://docs.expo.dev/guides/dom-components/",       type: official_docs }
    - { name: "Continuous Native Generation", url: "https://docs.expo.dev/workflow/continuous-native-generation/", type: official_docs }
    - { name: "Expo GitHub",                  url: "https://github.com/expo",                            type: source_code }
    - { name: "React Native Releases",        url: "https://github.com/facebook/react-native/releases",  type: changelog }
delegate_to_skills:
  # These skills exist in many users' Claude Code environments via Anthropic / Expo plugin
  # packs. ETYB defers to them for the listed surfaces when installed.
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
products_covered:
  - { name: "Expo SDK",                    drift_risk: high,   notes: "Quarterly major releases; SDK 55 (Feb 2026) bundles RN 0.83 + React 19.2; APIs rename ('next' suffix), packages graduate or get retired per release" }
  - { name: "Expo Router",                 drift_risk: high,   notes: "File-based router still adding capabilities (typed routes, data loaders, SSR alpha, API routes); behavior diff each SDK" }
  - { name: "EAS Build",                   drift_risk: high,   notes: "Image releases monthly; iOS precompiled binaries + Apple Silicon machines; cache policy changes; pricing tiers shift" }
  - { name: "EAS Update",                  drift_risk: high,   notes: "Hermes bytecode diffing, phased rollouts, branch/channel mapping evolving; replaces CodePush after App Center retirement (Mar 2025)" }
  - { name: "EAS Submit",                  drift_risk: medium, notes: "App Store Connect + Play Console submission flows; metadata + ASC API key plumbing" }
  - { name: "EAS Workflows",               drift_risk: high,   notes: "YAML CI/CD in .eas/workflows/; new actions added per release; Maestro integration steady" }
  - { name: "EAS Hosting",                 drift_risk: high,   notes: "GA 2025 — Cloudflare-Workers-backed serverless host for Expo Router web + API routes; routing/limits still maturing" }
  - { name: "Expo Go",                     drift_risk: medium, notes: "Dev sandbox; cannot run arbitrary native modules — config-plugin or out-of-tree libs require a dev client" }
  - { name: "expo-dev-client",             drift_risk: medium, notes: "Recommended replacement for Expo Go for any real product; matrix of native modules tied to build, not runtime" }
  - { name: "Expo Modules API",            drift_risk: medium, notes: "Swift/Kotlin module authoring; JSI-backed; consistent surface but evolves with RN architecture" }
  - { name: "Continuous Native Generation (CNG)", drift_risk: medium, notes: "Recommended pattern: do not commit ios/ and android/ folders; regenerate via `npx expo prebuild`" }
  - { name: "Expo DOM Components",         drift_risk: medium, notes: "Run web code (HTML/CSS/React) inside a webview on native; bridges via marshalled props/messages" }
  - { name: "Expo API Routes",             drift_risk: high,   notes: "+api.ts files; runtime is EAS Hosting workers; cold-start, KV, ratelimits diff from Vercel/Node" }
  - { name: "New Architecture (Fabric + TurboModules)", drift_risk: high, notes: "Default in SDK 51+, mandatory in SDK 53+; bridgeless-only in RN 0.82+; many older libs still being ported" }
  - { name: "Hermes",                      drift_risk: low,    notes: "Default and only JS engine in SDK 52+; JSC removed" }
  - { name: "app.json / app.config.js",    drift_risk: medium, notes: "Schema additions per SDK; config plugin contract stable but gains hooks" }
  - { name: "Metro bundler",               drift_risk: medium, notes: "RN's bundler; Expo wraps it; SDK 55 added module-graph improvements + tree-shaking flags" }
  - { name: "expo-doctor",                 drift_risk: low,    notes: "Dependency + native module sanity checker; checks expand per SDK" }
  - { name: "Snack",                       drift_risk: low,    notes: "Browser playground; latest SDK supported within ~2 weeks of release" }
  - { name: "Push notifications (Expo Push)", drift_risk: medium, notes: "Expo Push wraps FCM/APNs; FCMv1 only since Jun 2024; APNs token auth required" }
---

# Expo Stack Pack — Team Briefing

You're working in the **Expo** ecosystem. This is a knowledge overlay, not a new specialist. The ETYB team is doing the work — mobile-architect picks the patterns, frontend-architect handles the web surface and shared component model, devops-engineer wires EAS, qa-engineer drives the test pyramid. This pack teaches each role what the platform expects as of **Expo SDK 55 (Feb 2026, React Native 0.83, React 19.2)**.

**Currency stamp:** verified against Expo SDK 55, EAS pricing & workflow changes through TBD May 2026, and React Native 0.85 release notes. If today's date is more than 6 months past the `last_verified_on` above, the pack is stale — warn the user and consult `https://expo.dev/changelog` before recommending API-level details.

## What changed in 2025–2026 that older training data misses

Critical context. An LLM with a 2024 cutoff will get these wrong:

- **The New Architecture is mandatory.** SDK 51 made Fabric + TurboModules the default; SDK 53 made the old architecture opt-out impossible inside Expo; React Native 0.82 forced bridgeless mode platform-wide. As of SDK 55 / RN 0.83 you cannot opt out. Any answer that says "you can disable the new architecture" is wrong for current SDKs.
- **Hermes is the only JS engine.** JavaScriptCore was removed from React Native; Hermes V1 is default and only. No `jsEngine: 'jsc'` in `app.json`.
- **`expo` CLI replaces `react-native` CLI for everything in managed and prebuild workflows.** `npx expo start`, `npx expo run:ios`, `npx expo prebuild`, `npx expo install`. The old `react-native run-ios` is bare-only and inferior. Do not recommend it for Expo projects.
- **`sf`/`sfdx`-style alias note:** `expo-cli` (the global v0–v6) is dead. Use `npx expo` per-project. Don't `npm i -g expo-cli`.
- **EAS Update replaces CodePush.** Microsoft App Center retired March 2025; for any Expo project, EAS Update with Hermes bytecode diffing + branch-based channels is the answer.
- **EAS Hosting is GA.** Launched 2024-2025, GA in 2025. Expo Router web + API routes deploy here; the runtime is Cloudflare Workers. Plumbing differs from Vercel/Node — see frontend-architect overlay.
- **Continuous Native Generation (CNG) is the recommended workflow.** Do **not** commit `ios/` and `android/` folders. The native projects are regenerated by `npx expo prebuild`, configured by config plugins, and built by EAS Build. If a codebase has committed native projects, that's a "bare workflow" choice with real cost.
- **Expo Router is the default router** in `create-expo-app` since SDK 50, stable since SDK 51. Typed routes are GA. Data loaders (`useLoaderData`, route `loader` exports) are experimental in SDK 55. SSR/static rendering for web is GA; React Server Components is in alpha.
- **Expo DOM Components** (`'use dom'`) let you embed React-DOM components inside a native app via a webview. Useful for migrating web code incrementally or for rich text editors / charting libs that only have web implementations.
- **Expo API Routes** (`+api.ts` files in `app/`) deploy as **EAS Hosting** workers. They are not Node — they're Cloudflare-Workers-compatible. `process.env.NODE_ENV` works; many Node-only packages won't. Plan around this.
- **EAS Build uses Apple Silicon machines** by default (since 2024). M-series build images are ~2× faster than the previous Intel images for iOS clean builds. RN 0.84+ ships precompiled iOS binaries (`.xcframework`) making clean iOS builds another ~8× faster.
- **Expo Push uses FCMv1 only** since June 2024. Legacy FCM HTTP API is retired. APNs must use token auth (`.p8` key) — certificate auth is deprecated.
- **The Expo Go limitations are real.** Expo Go cannot load arbitrary native modules; it ships a fixed set. **Any third-party library with native code that isn't already in Expo Go requires a dev client.** This is the #1 source of "but it worked in Expo Go" surprises. Default new projects to a dev client unless the work is genuinely a throwaway demo.
- **NativeWind v5 + Tailwind v4** is the current target. NativeWind v4 (stable) supports Tailwind v3; v5 (pre-release / RC as of SDK 55) flips to Tailwind v4's CSS-first config.
- **React 19.2 in SDK 55** means: actions, `useFormStatus`, `useOptimistic`, `use()`, server components groundwork, the new `<Activity>` API. React 19 also broke a number of older RN libraries — `expo-doctor` flags them.
- **FlashList v2 requires the New Architecture.** Old FlatList still works but is unfit for production lists.
- **Reanimated 4 is the current major.** Worklets have moved to a separate `react-native-worklets` package — transparent dependency, but `expo-doctor` will mention it. New CSS-compatible declarative API; backward compatible with Reanimated 3 worklet code.
- **MMKV v4 is a Nitro Module.** Requires New Architecture; ~30× faster than AsyncStorage; synchronous via JSI.
- **`expo-av` is split** — `expo-video` (video) + `expo-audio` (audio) are the new package surfaces; `expo-av` remains for legacy compatibility through SDK 56.
- **Several APIs are getting `/next` suffixes** as object-oriented redesigns ship: `expo-contacts/next`, `expo-media-library/next`, `expo-calendar/next` are available in SDK 55 alongside the legacy module-style exports.

If you find yourself recommending CodePush, the global `expo-cli`, `jsEngine: 'jsc'`, "commit your ios/ folder", Expo Go for production-shaped apps, FCM legacy HTTP, certificate-based APNs, or `react-native run-ios` for an Expo project — you're using stale knowledge. Read the references below.

## How this pack plugs in

ETYB's router detects Expo signals via `skills/etyb/core/stack-registry.md` and loads this `SKILL.md` as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement, debugging. The Expo overlay does not relax engineering discipline; it shapes how the discipline is applied on this platform:

- **TDD on Expo** = Jest 30 with `@react-native/jest-preset` + React Native Testing Library for components; Maestro flows for E2E run on EAS Workflows
- **Verification on Expo** = `npx expo-doctor` (dependency + native sanity), `npx expo install --check`, EAS Build logs, EAS Update revert as the rollback discipline
- **Debugging on Expo** = React Native DevTools (Chrome DevTools frontend) for JS, Xcode Instruments / Android Studio Profiler for native, Sentry's Expo plugin for prod stack traces with bundle-sourcemap mapping
- **Branch safety on Expo** = EAS Update branches mirror Git branches; never push an update to `production` channel without a successful EAS Build of the same commit

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `mobile-architect` | [`references/mobile-architect.md`](references/mobile-architect.md) | **The mobile architecture decision** — Expo managed vs prebuild vs bare; New Architecture migration; Expo Modules vs Nitro vs TurboModules; offline + sync (MMKV, SQLite, WatermelonDB); push notifications; deep linking; performance (FlashList, Reanimated, Skia); platform-specific UI; monorepo composition |
| `frontend-architect` | [`references/frontend-architect.md`](references/frontend-architect.md) | Expo Router (file-based routing for native + web); shared component strategy; Expo DOM Components for incremental migration; web target on EAS Hosting; SSR/SSG via static rendering; NativeWind v4→v5 + Tamagui + Unistyles tradeoffs; styling per platform; React 19.2 patterns in RN; web parity discipline |
| `devops-engineer` | [`references/devops-engineer.md`](references/devops-engineer.md) | EAS Build (profiles, caching, credentials, build images); EAS Update (channels, branches, runtime versions, rollouts, rollback); EAS Submit (App Store / Play Store automation); EAS Workflows YAML; CNG via `expo prebuild`; secrets via EAS env vars; monorepo + EAS; pricing tiers + cost levers |
| `qa-engineer` | [`references/qa-engineer.md`](references/qa-engineer.md) | The Expo test pyramid — Jest 30 + RNTL for unit/component; Maestro vs Detox for E2E; running Maestro on EAS Workflows; testing config plugins; testing OTA update flows; preview builds for QA; release-pipeline gating; device matrix selection |

Each overlay assumes the role's general README is loaded first. The overlay is *additive context*, not a replacement.

## Standing instructions for every role on an Expo engagement

1. **Anchor to currency.** Before recommending API shapes, package names, or version-specific behavior, check whether the overlay references your role. If the overlay covers your area, follow it; do not pattern-match from older general-purpose knowledge. If the overlay does not yet cover your area, say so explicitly and consult `https://expo.dev/changelog` plus the SDK version's release notes (e.g., `https://expo.dev/changelog/sdk-55`).

2. **Default to the managed workflow + prebuild.** Expo's managed workflow + `npx expo prebuild` + CNG is the recommended path. Only fall back to the **bare workflow** (committed `ios/` + `android/` projects, no `expo prebuild`) when there's a concrete reason: deeply customized native code that no config plugin expresses, brownfield integration where Expo is one screen of a larger native app, or external SDKs that demand manual native edits. If you propose bare, defend it.

3. **Default to a dev client, not Expo Go.** Any project that will ship to a store or use a third-party native module should start with a dev client (`expo-dev-client`). Expo Go is a sandbox; treat it as a quick-experiment surface, not a baseline.

4. **Honor the New Architecture.** Every native module recommendation must be NA-compatible. If a library hasn't been ported, flag it and look for replacements: `react-native-mmkv` (v4 is a Nitro module, NA-compatible), `@shopify/flash-list` v2, `react-native-reanimated` 3+. Don't recommend `react-native-fast-image` (not NA-ready; recommend `expo-image`), `RNCAsyncStorage` (recommend MMKV), or `react-native-svg` <15 (recommend current).

5. **Respect EAS Hosting's runtime model.** Anything in `app/**/*+api.ts` runs on Cloudflare Workers via EAS Hosting. That means no `fs`, no full Node — Workers runtime only. Use Workers-compatible libraries (`hono`, `@neondatabase/serverless`, `drizzle-orm`, `cloudflare:*` bindings). Treat it like the Cloudflare Stack's Workers, not like a Node Lambda.

6. **Use config plugins for every app.json mutation an SDK doesn't expose.** Anytime you need to add to AndroidManifest, Info.plist, entitlements, gradle, or Podfile, write or import a config plugin (`expo.plugins` in `app.json`). Editing native projects directly fights CNG.

7. **Version-lock the SDK.** `npx expo install` chooses SDK-compatible versions; never `npm install` an Expo-aware package directly without checking compatibility. `expo-doctor` will catch most mismatches; run it in CI.

8. **One update channel per environment.** EAS Update channels (`production`, `preview`, `development`) map to runtime versions, which map to native binaries. Mixing them is how teams ship JS that crashes against the wrong native — don't.

## Top platform gotchas the team must know (named, with consequences)

1. **"It works in Expo Go" trap.** A library may load in Expo Go because Expo Go bundles a curated native module set. The instant you add a config plugin, install a non-bundled module, or open `app.config.ts` and add a `plugins` entry — Expo Go is no longer a valid runtime for that project. Switch to a dev client *before* this happens, not after.

2. **`runtimeVersion` mismatch.** EAS Update will not deliver a JS bundle to a binary whose `runtimeVersion` doesn't match. If you change native code (adding/removing a plugin, bumping a major SDK), bump `runtimeVersion`. Otherwise OTA updates silently stop reaching devices.

3. **Push notifications need real devices.** Expo Push, FCM, and APNs never deliver to simulators/emulators for iOS. Plan QA accordingly: physical iPhone in your device matrix.

4. **`process.env` is build-time on native.** `EXPO_PUBLIC_*` env vars are inlined at bundle time. They are not secret. Anything truly secret must come from EAS Hosting env vars (server-side, API routes) or be fetched from a backend at runtime. Hardcoding `STRIPE_SECRET_KEY` in `EXPO_PUBLIC_STRIPE_SECRET_KEY` is a leak you'll see in logs.

5. **`expo-secure-store` ≠ encrypted at rest by default.** On Android, items are encrypted with Android Keystore (good). On iOS, items are stored in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` by default — but a user with a debugger or jailbreak can read them. Don't store anything you'd refuse to put in `Authorization:` header without TLS.

6. **Hermes + dynamic require + Reanimated worklets.** Worklets run in a separate Hermes runtime. Capturing closures with non-serializable refs (DOM-style refs, native modules) inside worklets will silently fail or crash. Use `runOnJS` to bounce back, and keep worklets minimal.

7. **Metro doesn't tree-shake by default.** Each import drags the module. SDK 55 added experimental tree-shaking (`expo.tools.metro.treeShake`), but until it's stable, importing from barrel files (`import { x } from 'lodash'`) bloats bundles. Use deep imports (`import x from 'lodash/x'`).

8. **`@react-native-async-storage/async-storage` is the legacy store.** New code should use `react-native-mmkv` (Nitro, ~30× faster, synchronous via JSI, NA-compatible). AsyncStorage stays around but isn't a recommendation for new code.

9. **Image caching is `expo-image`'s job, not `Image`'s.** React Native's `Image` component doesn't cache aggressively, doesn't decode off-thread, and doesn't support modern formats well. `expo-image` (powered by SDWebImage on iOS and Glide on Android) is the default; use `Image` only for static local assets.

10. **EAS Build's iOS credentials are a one-time fight, then automatic.** First-time iOS builds prompt for Apple ID + ASC API key + signing certificates. Once stored in EAS, subsequent builds are zero-touch. Document the rotation procedure (annual cert refresh) in the runbook.

## Compliance composition

Stack work that touches a vertical:

- **Healthcare** (PHI in a mobile app) → vertical `healthcare-architect` owns HIPAA, BAAs with Expo (note: Expo does not currently sign HIPAA BAAs; route PHI through your own backend), audit logging discipline. This pack covers `expo-secure-store`, biometric prompts (`expo-local-authentication`), keychain semantics, and binary integrity — not the regulatory frame.

- **Fintech** (cards / banking / payments) → vertical `fintech-architect` owns PCI scope, PSD2/SCA, KYC, AML. This pack covers App Store guidelines around payments (Apple takes 30% on digital goods inside the app; physical goods + payments-as-a-service like Stripe/PayPal use external SDKs), biometric auth UX, and `expo-secure-store` token storage. Don't ship a wallet on `EXPO_PUBLIC_*` keys.

- **B2B SaaS** (multi-tenant) → vertical `saas-architect` owns tenancy. This pack covers per-tenant deep links (`expo-linking`), per-tenant push notifications, SSO via `expo-auth-session` + OIDC, and signing distinct white-label app variants from one repo using EAS profiles + config plugin overlays.

When a vertical is in play, route domain semantics there and keep this pack scoped to **how the Expo platform expresses those decisions**.

## Stack composition

If the user is using Expo **plus** another stack, both overlays load:

- **Expo + Supabase** — common pairing. This pack handles the mobile side (auth session storage, deep linking for magic-link callbacks, RLS-aware data fetching with React Query). Supabase Stack handles Postgres + Auth config.
- **Expo + Cloudflare** — Expo API Routes literally deploy to Cloudflare Workers via EAS Hosting. The Cloudflare Stack overlay applies to the API code; this pack covers the mobile bundle that calls into them.
- **Expo + Vercel** — Expo's web target can deploy to Vercel as a static or SSR site, but the canonical Expo Router web host is **EAS Hosting**. Choose one. Don't fan out to both unless you have a specific reason.
- **Expo + AWS** — backend is yours; this pack stays in the client. If you're using Cognito, `expo-auth-session` is the OIDC client. If you're using Amplify, accept that you're now also in Amplify's mental model on top of Expo's — expect friction.
- **Expo + Stripe** — `@stripe/stripe-react-native` works with the New Architecture; Apple's commission rules apply to digital goods. Use Apple Pay on iOS and Google Pay on Android for physical goods.
- **Expo + Firebase** — `@react-native-firebase/*` requires native modules → must run in a dev client / build, not Expo Go. Add the `@react-native-firebase/app` config plugin to `app.json`. Don't pair `react-native-firebase` with the Firebase JS SDK in the same app unless you've thought about which auth state wins.

Neither pack should pretend to know the other's depth.

## Currency — when this Stack is stale

The `check-currency.sh` validator flags this Stack if `last_verified_on` falls behind the thresholds:

- **90 days** for high-drift products (Expo SDK, Expo Router, EAS Build, EAS Update, EAS Hosting, EAS Workflows, Expo API Routes, New Architecture). These move every quarterly SDK; check `https://expo.dev/changelog` and the latest SDK changelog.
- **180 days** for medium-drift products (Expo Go, expo-dev-client, Expo Modules API, CNG, DOM Components, app.json schema, Metro, Push notifications, EAS Submit).
- **365 days** for low-drift products (Hermes, expo-doctor, Snack).

When refreshing:

1. **Check the latest SDK page** — `https://docs.expo.dev/versions/latest/` (current is SDK 55).
2. **Read the most recent changelog post** — `https://expo.dev/changelog` (filter for "SDK" posts; usually one per quarter).
3. **Skim React Native releases** — `https://github.com/facebook/react-native/releases` (the SDK number in the Expo changelog tells you which RN ships).
4. **Update `products_covered` notes** for any product whose `drift_risk` changed (e.g., a feature graduated from beta → GA).
5. **Re-run `npx expo install --fix` + `npx expo-doctor`** in a reference repo if you have one — surfaces version-mismatch reality cheaply.
6. **Bump `last_verified_on`** in this SKILL.md and every role overlay frontmatter to today's date.

## Migration note (for the maintainer)

This Stack was assembled by extracting Expo-specific content from `skills/etyb/references/specialists/mobile-architect/references/react-native-specialist.md`. After this pack ships:

- **Stays in `react-native-specialist.md`** (platform-neutral RN content): bare workflow patterns, generic RN state management options, generic styling tradeoffs (Tamagui, Unistyles), generic animation library taxonomy, generic monorepo patterns, raw `react-native` CLI usage for bare projects, generic TS patterns, generic deep-link semantics.
- **Moved to this pack** (Expo-specific): Expo SDK + EAS suite (Build/Update/Submit/Workflows/Hosting), Expo Router, Expo Modules API, `expo-dev-client`, Continuous Native Generation, app.json / config plugins, Expo DOM Components, Expo API Routes, Expo Push, `expo-*` package family specifics, NativeWind/Tamagui *as configured for Expo*, Hermes + New Architecture *as the Expo-controlled defaults*.

The specialist file should become a shorter pointer noting: "For Expo-managed and prebuild workflows, the canonical reference is `stacks/expo/`. This file covers bare-workflow React Native patterns that apply regardless of framework."
