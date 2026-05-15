---
title: Expo SDK
description: Quarterly-released bundle of React Native + React + curated expo-* packages with a single tested compatibility matrix per version.
product:
  name: Expo SDK
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect, devops-engineer, qa-engineer]
  authoritative_url: https://docs.expo.dev/versions/latest/
  notes: "Quarterly major releases; SDK 55 (Feb 2026) bundles RN 0.83 + React 19.2; APIs rename and packages graduate or retire each release"
---

## What it is

The **Expo SDK** is the version-pinned bundle of React Native, React, Hermes, and the curated `expo-*` package family that ship together as a tested compatibility matrix. SDK 55 (Feb 2026) bundles React Native 0.83, React 19.2, Hermes V1, the New Architecture as the mandatory runtime, and the latest `expo-*` packages aligned to those versions.

You install Expo-aware packages with `npx expo install <pkg>`, which consults the SDK's compatibility matrix and pins the right version. Direct `npm install` of an Expo-aware package risks pulling an incompatible version — `expo-doctor` will flag the drift in CI.

Canonical surface: [Expo SDK API Reference](https://docs.expo.dev/versions/latest/). Quarterly release posts at [expo.dev/changelog](https://expo.dev/changelog).

## When to use

If you're shipping React Native, use Expo SDK. As of 2026, Meta's React Native team officially calls Expo "the only recommended community framework for React Native." Bare RN (`react-native init`) is the escape hatch — used when you have a brownfield native app embedding RN, a custom RN fork, or third-party SDKs that demand direct native edits a config plugin can't express.

The SDK gives you:

- A locked React Native + React + Hermes + native-module matrix that's been tested together
- `npx expo install` for compatible package versions
- `expo-doctor` to surface drift in CI
- Quarterly updates with documented breaking changes

If you fight the SDK (`npm install` random RN versions, modify native projects directly without config plugins), you'll spend more time fixing build breakage than shipping.

## 2025-2026 currency anchors

- **SDK 55 (Feb 2026)** — RN 0.83, React 19.2, experimental Metro tree-shaking, Hermes bytecode diffing for OTAs, alpha SSR for web, experimental data loaders, `Link.preload()`.
- **SDK 53 (mid-2025)** — New Architecture opt-out fully removed from Expo; React 19; JSC fully removed.
- **SDK 52 (early 2025)** — JSC deprecated → removed; Hermes mandatory; `newArchEnabled: false` ignored.
- **SDK 51 (mid-2024)** — `runtimeVersion: { policy: "fingerprint" }` introduced; New Architecture became default; Expo Router stable.
- **SDK 50 (early 2024)** — Expo Router shipped as the default router for new projects.
- **Support window**: Expo officially supports the current SDK (N) and the previous (N-1) for hotfixes. N-2 is out of support within ~6-9 months. Don't run a 2-major-old SDK in production past the support window.

## Patterns + anti-patterns

### Pattern: `npx expo install` for every Expo-aware package

```bash
# Right
npx expo install expo-image react-native-reanimated @shopify/flash-list

# Wrong — risks pinning an incompatible version
npm install expo-image
```

`expo install` reads the SDK's compat matrix and picks the validated version. `npm install` does not.

### Pattern: One SDK upgrade per sprint

Budget one engineering sprint per quarter for the SDK bump. Read the release blog post, bump in a feature branch, run `expo install --fix`, fix `expo-doctor` warnings, smoke test, ship to `preview` channel for 1-2 weeks, then promote.

### Pattern: Don't skip majors

`SDK 50 → SDK 51 → SDK 52 → SDK 53` in sequence over a few weeks is safer than `SDK 50 → SDK 53` in one jump. Each major has its own breaking-change checklist; compounding three sets at once is how teams stall for a month.

### Anti-pattern: `npm install` for Expo-aware packages

Yields version drift. `expo-doctor` will flag; tests in CI will fail. Fix by `npx expo install --fix`.

### Anti-pattern: pinning to an old SDK to keep one library working

If a library hasn't been updated for the new SDK, replace the library, fork it, or wrap it in an Expo Module. Don't freeze the whole app on an unsupported SDK.

## Gotchas

- **`npx expo install --check`** in CI catches version drift, but you have to run it; it's not automatic.
- **React 19** broke some older RN libraries (older `react-native-reanimated` 2.x, some animation libs). `expo-doctor` flags them.
- **APIs with `/next` suffix** ship alongside legacy exports in the same SDK. Use `/next` for new code (object-oriented, async). Old exports graduate in the SDK after `/next` lands.
- **The SDK does not pin web-only packages** (Next.js, anything web-only in a monorepo). It pins RN + Expo + Hermes + curated `expo-*`.

## Cross-references

- [Expo CLI](/stacks/expo/expo-cli/) — the `npx expo` tooling that drives `install`, `start`, `prebuild`, `export`
- [expo-doctor](/stacks/expo/expo-doctor/) — checks compat against the SDK matrix
- [New Architecture](/stacks/expo/new-architecture/) — mandatory in SDK 53+; gating constraint for many libraries
- [Hermes](/stacks/expo/hermes/) — the SDK's JS engine
- [Expo Changelog](https://expo.dev/changelog) — quarterly SDK posts
- [Expo SDK API Reference](https://docs.expo.dev/versions/latest/) — canonical version reference
- Role overlays touching SDK choices: [mobile-architect](/stacks/expo/mobile-architect/), [devops-engineer](/stacks/expo/devops-engineer/)
