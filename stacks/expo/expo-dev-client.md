---
title: expo-dev-client
description: "The `expo-dev-client` npm package — installs the dev menu, OTA debug runtime, and EAS Update branch picker into custom development builds."
product:
  name: expo-dev-client
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, devops-engineer]
  authoritative_url: https://docs.expo.dev/develop/development-builds/introduction/
  notes: "The package that, when installed and built, produces a Custom Dev Client; ships dev menu + EAS Update branch picker"
---

## What it is

The **`expo-dev-client`** npm package is what transforms a regular Expo build into a *development build* (a "[Custom Dev Client](/stacks/expo/custom-dev-clients/)"). Installing it adds:

- The **dev menu** (shake gesture / Cmd+D / hardware key) — reload, inspect element, performance monitor, network inspector, EAS Update branch picker
- **OTA dev runtime** — load JS from `npx expo start` over LAN or tunnel
- **Multi-CDP** — multiple debugger connections at once (VS Code + Chrome DevTools + AI agent), since v5

```bash
npx expo install expo-dev-client
# then build a dev profile:
eas build --profile development --platform all
```

Canonical surface: [Development builds — Introduction](https://docs.expo.dev/develop/development-builds/introduction/).

## When to use

For every Expo project beyond hello-world. The package itself is small; what makes it valuable is the development build that includes it. See [Custom Dev Clients](/stacks/expo/custom-dev-clients/) for the broader workflow.

## 2025-2026 currency anchors

- **v5.x (SDK 55)** — multi-CDP support, branch picker for EAS Update, improved log streaming, dev menu redesign.
- **New Architecture by default** in SDK 53+ dev clients.
- **`developmentClient: true`** in eas.json activates it for a build profile.
- **`distribution: "internal"`** delivers via EAS Internal Distribution (QR code from dashboard) — no TestFlight wait.

## Patterns + anti-patterns

### Pattern: Branch picker for QA

In the dev menu, "EAS Update" lets a QA engineer switch update branches without rebuilding. The dev client fetches the latest update from that branch and reloads.

### Pattern: Stripped from production

The package is auto-stripped from `production` profile builds. Verify with `eas build --profile production` output — `expo-dev-client` should not appear in the bundle.

### Anti-pattern: Shipping `expo-dev-client` to the store

Don't include it in `production` builds. The dev menu in production is a security + UX leak. The default behavior already strips it; confirm if your eas.json deviates.

## Gotchas

- **Startup overhead** — measurable; SHK-style apps will show ~50-150ms cold start cost in dev. Production strips it.
- **Branch picker requires `expo-updates`** installed and configured.
- **`npx expo start --dev-client`** is the local dev command — opens the dev server in dev-client mode (vs Expo Go mode).

## Cross-references

- [Custom Dev Clients](/stacks/expo/custom-dev-clients/) — the broader workflow
- [Expo Go](/stacks/expo/expo-go/) — what dev clients replace
- [EAS Build](/stacks/expo/eas-build/) — builds them
- `expo-dev-client` skill (delegate) — dev client distribution patterns
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [devops-engineer](/stacks/expo/devops-engineer/)
- [Development builds — Introduction](https://docs.expo.dev/develop/development-builds/introduction/)
