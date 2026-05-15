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
  version: "4.0.2"
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

# Expo Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Expo knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/expo/index.md`](index.md)
- **Per-product pages:** `stacks/expo/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/expo/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/expo/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **The New Architecture is mandatory.** SDK 51 made Fabric + TurboModules the default; SDK 53 made the old architecture opt-out impossible inside Expo; React Native 0.82 forced bridgeless mode platform-wide. As of SDK 55 / RN 0.83 you cannot opt out. Any answer that says "you can disable the new architecture" is wrong for current SDKs.
- **Hermes is the only JS engine.** JavaScriptCore was removed from React Native; Hermes V1 is default and only. No `jsEngine: 'jsc'` in `app.json`.
- **`expo` CLI replaces `react-native` CLI for everything in managed and prebuild workflows.** `npx expo start`, `npx expo run:ios`, `npx expo prebuild`, `npx expo install`. The old `react-native run-ios` is bare-only and inferior. Do not recommend it for Expo projects.
- **`expo-cli` (the global v0–v6) is dead.** Use `npx expo` per-project. Don't `npm i -g expo-cli`.
- **EAS Update replaces CodePush.** Microsoft App Center retired March 2025; for any Expo project, EAS Update with Hermes bytecode diffing + branch-based channels is the answer.
- **EAS Hosting is GA.** Launched 2024-2025, GA in 2025. Expo Router web + API routes deploy here; the runtime is Cloudflare Workers. Plumbing differs from Vercel/Node.
- **Continuous Native Generation (CNG) is the recommended workflow.** Do **not** commit `ios/` and `android/` folders. The native projects are regenerated by `npx expo prebuild`, configured by config plugins, and built by EAS Build.
- **Expo Router is the default router** in `create-expo-app` since SDK 50, stable since SDK 51. Typed routes are GA. Data loaders are experimental in SDK 55. SSR/static rendering for web is GA.
- **Expo API Routes** (`+api.ts` files in `app/`) deploy as **EAS Hosting** workers. They are not Node — they're Cloudflare-Workers-compatible. Many Node-only packages won't work.
- **Expo Push uses FCMv1 only** since June 2024. Legacy FCM HTTP API is retired. APNs must use token auth (`.p8` key) — certificate auth is deprecated.
- **The Expo Go limitations are real.** Expo Go cannot load arbitrary native modules; it ships a fixed set. Any third-party library with native code that isn't already in Expo Go requires a dev client. Default new projects to a dev client unless the work is genuinely a throwaway demo.
- **React 19.2 in SDK 55** means: actions, `useFormStatus`, `useOptimistic`, `use()`, server components groundwork, the new `<Activity>` API. React 19 also broke a number of older RN libraries.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on an Expo engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Default to a dev client, not Expo Go.** Any project that will ship to a store or use a third-party native module should start with a dev client (`expo-dev-client`). Expo Go is a sandbox; treat it as a quick-experiment surface, not a baseline.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Expo | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Expo alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
