---
title: Expo Go
description: Sandbox app for quick Expo experimentation — bundles a curated native module set, cannot load arbitrary native modules. Not a production runtime.
product:
  name: Expo Go
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect, qa-engineer]
  authoritative_url: https://docs.expo.dev/get-started/expo-go/
  notes: "Sandbox — cannot run arbitrary native modules; config plugin or non-bundled libs force a dev client"
---

## What it is

**Expo Go** is the iOS + Android app you download from the App Store / Play Store that loads JS bundles from any Expo project. It ships with a *fixed, curated set of native modules*. You write JS, scan a QR code with the camera (iOS) or Expo Go itself (Android), and the bundle loads — no build step, no Xcode, no Android Studio.

Canonical surface: [Get started with Expo Go](https://docs.expo.dev/get-started/expo-go/).

## When to use

Use Expo Go for:

- **Quick demos** — sharing a Snack or a small repro
- **Learning** — early "hello world" exploration of Expo Router, RN, the SDK
- **Throwaway prototypes** — code without real native dependencies

**Do not use Expo Go as a baseline for any project that will ship to a store** or use a third-party native module. The moment you add a config plugin, install a non-bundled native module, or open `app.config.ts` and add a `plugins` entry — Expo Go is no longer a valid runtime for that project. Switch to a **[Custom Dev Client](/stacks/expo/custom-dev-clients/)** *before* this happens, not after.

In 2026, the default new-project pattern is: scaffold with `npx create-expo-app`, immediately build a dev client (`eas build --profile development`), install on physical devices, and develop against that. Expo Go is the quick-experiment lane only.

## 2025-2026 currency anchors

- **Expo Go's native module set updates per SDK** — when a new SDK ships, Expo Go is updated within ~2 weeks. The set is curated; it's not "everything in npm."
- **SDK 53+ Expo Go runs the New Architecture by default.** Old NA-incompatible libs no longer work even in Expo Go.
- **Snack ↔ Expo Go integration** is still the standard for repros (paste a URL into Snack, scan QR with Expo Go on device).
- **Expo Go on simulator** still works; on Android, you must install Expo Go via Play Store or APK manually.

## Patterns + anti-patterns

### Pattern: Default new projects to a dev client

```bash
npx create-expo-app my-app
cd my-app
npx expo install expo-dev-client
eas build --profile development --platform all
```

Install the resulting dev clients on real iOS + Android. Now you can use any native module, write config plugins, do anything Expo Go can't.

### Pattern: Use Expo Go for Snack / quick repro

Snack uploads to Expo Go on your phone. Use Snack to file a minimal repro on GitHub or in Discord — much faster than scaffolding a project.

### Anti-pattern: "I'll switch to a dev client when I need to"

By the time you need to, you've usually committed to an architecture that assumes some things "work" because they worked in Expo Go. Switching mid-project is painful. Default to dev client from day one.

### Anti-pattern: Production-shaped app on Expo Go

If the app has auth, push notifications, deep links, payments, or any custom native — Expo Go is wrong for it. The bundled module set won't cover what you need, and you'll discover that two weeks into the project.

## Gotchas

- **The "it works in Expo Go" trap** — a library may load in Expo Go because Expo Go bundles a curated native module set. Add a non-bundled module → no longer valid. The #1 source of "but it worked in Expo Go" surprises.
- **Push notifications in Expo Go** — limited; you can register for tokens but production push delivery requires a dev client / store build.
- **Deep links** — custom schemes work via `exp://`; production scheme requires a built app.
- **Expo Go doesn't honor your `app.config.js` `ios.bundleIdentifier` / `android.package`** — it runs as Expo Go itself. Distinct dev/preview/prod bundle IDs require a dev client.

## Cross-references

- [Custom Dev Clients](/stacks/expo/custom-dev-clients/) — the production-shaped replacement
- [expo-dev-client](/stacks/expo/expo-dev-client/) — the package that builds them
- [Snack](/stacks/expo/snack/) — browser playground that loads into Expo Go
- [Expo SDK](/stacks/expo/expo-sdk/) — Expo Go's bundled module set
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/) for project-architecture defaults
- [Get started with Expo Go](https://docs.expo.dev/get-started/expo-go/)
