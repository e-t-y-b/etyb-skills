---
title: Custom Dev Clients
description: Per-project replacements for Expo Go that bundle exactly your native dependencies, plus the dev menu. The production-shaped dev runtime for serious Expo work.
product:
  name: Custom Dev Clients
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, devops-engineer, qa-engineer]
  authoritative_url: https://docs.expo.dev/develop/development-builds/introduction/
  notes: "Recommended replacement for Expo Go for any real product; matrix of native modules tied to build, not runtime"
---

## What it is

A **custom dev client** is a development build of *your* app that includes the `expo-dev-client` package (which provides the dev menu, OTA updater, log streaming) and *all* the native modules your project actually depends on — not Expo Go's curated set. You build it via EAS Build with the `developmentClient: true` profile, install it on real devices or simulators/emulators, and it loads JS bundles like Expo Go does — except now `react-native-mmkv`, `@react-native-firebase/*`, custom Expo Modules, or anything else you've added actually works.

Canonical surface: [Development builds — Introduction](https://docs.expo.dev/develop/development-builds/introduction/).

## When to use

Default for **any project past hello-world**. Specifically:

- The project will ship to App Store / Play Store
- The project uses any third-party native module not in Expo Go's bundled set (`react-native-firebase`, `react-native-mmkv`, `react-native-mlkit`, etc.)
- The project uses any config plugin (`expo-build-properties`, `@stripe/stripe-react-native`, any custom plugin)
- The project has distinct dev/preview/prod bundle IDs

If any of the above is true, you need a dev client. Don't fight this.

## 2025-2026 currency anchors

- **`expo-dev-client` 5.x (SDK 55)** — supports New Architecture by default, multi-CDP debugging (multiple DevTools sessions concurrently), better dev menu with EAS Update branch picker.
- **EAS Build `internal` distribution** delivers dev clients via QR code from the EAS dashboard — no TestFlight / Play Console wait. Engineers and designers scan and install in minutes.
- **`distribution: "internal"`** in eas.json + `developmentClient: true` is the standard development profile.
- **iOS simulator builds** ship as `.app` archives installable via `xcrun simctl` or `eas build:run` — no Apple Developer account needed for simulator-only dev clients.
- **Android dev clients are APK** (not `.aab`) — `buildType: "apk"` in eas.json.

## Patterns + anti-patterns

### Pattern: Standard `development` profile in eas.json

```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "env": { "APP_VARIANT": "development" },
      "ios": { "simulator": true, "resourceClass": "m-medium" },
      "android": { "buildType": "apk", "gradleCommand": ":app:assembleDebug" }
    }
  }
}
```

Run `eas build --profile development --platform all`. EAS produces:

- `.apk` for Android (sideload via QR or `adb install`)
- `.app` for iOS simulator (load via `eas build:run`)
- `.ipa` for iOS device (sideload via QR if signed for internal distribution)

### Pattern: One dev client per major native change

Adding a new native module means a new dev client build. JS-only changes hot-reload as before. The build cadence on a healthy project is ~weekly for native; daily for JS.

### Pattern: Distinct bundle IDs for dev/preview/prod

```js
// app.config.js — see mobile-architect overlay for full example
const variant = process.env.APP_VARIANT ?? 'development';
const variants = {
  development: { bundleIdentifier: 'com.acme.app.dev', name: 'Acme (Dev)' },
  preview:     { bundleIdentifier: 'com.acme.app.preview', name: 'Acme (Preview)' },
  production:  { bundleIdentifier: 'com.acme.app', name: 'Acme' },
};
```

Three apps coexist on a tester's phone — instant clarity which build they're on.

### Anti-pattern: Skipping dev client because "Expo Go works for now"

Then you add Firebase, or MMKV, or a config plugin — and Expo Go silently stops working for your app. Now you're context-switching to "fix the dev environment" mid-feature. Build the dev client up front.

### Anti-pattern: Distributing dev clients via TestFlight

TestFlight has review latency (24h external; instant internal). Use EAS Internal Distribution for dev clients (QR code from EAS dashboard); reserve TestFlight for `preview` builds intended for broader stakeholder review.

## Gotchas

- **JDK / Xcode versions** — local dev needs Xcode + Android Studio installed if you want `npx expo run:ios` / `run:android`. EAS Build handles this in the cloud, but local builds still need toolchains.
- **Apple Silicon iOS simulator builds** are larger than device builds; that's normal.
- **Dev client + EAS Update** — dev clients can subscribe to any EAS Update branch via the dev menu's branch picker (5.x feature). Useful for QA to test a preview channel update on a dev client without rebuilding.
- **`expo-dev-client` adds startup overhead** — measurable in cold start metrics. Strip it from `production` profile (it's auto-stripped by default; verify with `eas build --profile production` output).

## Cross-references

- [expo-dev-client](/stacks/expo/expo-dev-client/) — the package itself
- [Expo Go](/stacks/expo/expo-go/) — what dev clients replace
- [EAS Build](/stacks/expo/eas-build/) — produces dev client artifacts
- [EAS Update](/stacks/expo/eas-update/) — dev clients can subscribe to branches
- `expo-dev-client` skill (delegate) — dev client distribution patterns
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [devops-engineer](/stacks/expo/devops-engineer/)
- [Development builds — Introduction](https://docs.expo.dev/develop/development-builds/introduction/)
