---
title: Expo CLI (`npx expo`)
description: "Per-project CLI for Expo. `start`, `prebuild`, `install`, `run:*`, `export`, `customize`. Global `expo-cli` (v0-v6) is dead — never `npm i -g expo-cli`."
product:
  name: Expo CLI
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect, devops-engineer]
  authoritative_url: https://docs.expo.dev/more/expo-cli/
  notes: "Per-project CLI; global `expo-cli` is dead. start, prebuild, install, run:*, export"
---

## What it is

**`npx expo`** is the per-project CLI for Expo. Every project has its own version (declared via the `expo` package), invoked via `npx expo <command>`. The old global `expo-cli` (v0-v6, ~2017-2023) is **dead** and should never be installed (`npm i -g expo-cli`).

Common commands:

```bash
npx expo start              # dev server (Metro)
npx expo prebuild           # regenerate ios/ + android/ from app.json
npx expo install <pkg>      # install Expo-compatible version
npx expo run:ios            # local build + run on simulator
npx expo run:android        # local build + run on emulator
npx expo export             # bundle for production
npx expo customize          # eject specific config files
npx expo config             # print resolved config
npx expo-doctor             # dependency + native sanity check
```

Canonical surface: [Expo CLI reference](https://docs.expo.dev/more/expo-cli/).

## When to use

For every Expo project. Replaces:

- The old global `expo-cli` (dead)
- Most `react-native` CLI commands for Expo projects (`react-native run-ios` etc.)

You'll use `npx expo` daily as the primary entry point. For builds and OTAs, switch to [EAS CLI](/stacks/expo/eas-cli/).

## 2025-2026 currency anchors

- **Per-project CLI** — version locked to the `expo` package in your project.
- **`npx expo install`** consults the SDK compat matrix.
- **`npx expo install --fix`** auto-fixes drift.
- **`npx expo install --check`** flags but doesn't fix; CI-friendly.
- **`npx expo customize`** ejects specific files (`metro.config.js`, `babel.config.js`, `expo-env.d.ts`) you want to customize.
- **`npx expo prebuild --clean`** is the nuke option — blows away ios/ + android/ and regenerates.

## Patterns + anti-patterns

### Pattern: Daily dev loop

```bash
npx expo start --dev-client    # start Metro pointing at your dev client
# Scan QR with the dev client; bundle loads
# Edit code → hot reload
```

### Pattern: Install Expo-aware packages

```bash
npx expo install expo-image react-native-reanimated @shopify/flash-list
```

Reads SDK compat matrix; picks versions known to work. Never `npm install` Expo-aware packages.

### Pattern: CI dependency check

```yaml
# .github/workflows/check.yml
- run: npx expo install --check
- run: npx expo-doctor
```

`--check` fails CI on version drift; `expo-doctor` catches deeper issues.

### Pattern: Prebuild for inspection

```bash
npx expo prebuild --platform ios --no-install
# Generates ios/ but doesn't run pod install
# Useful for inspecting what plugin output looks like
```

### Anti-pattern: Global `expo-cli`

```bash
# Dead, do not install
npm i -g expo-cli
```

The global v0-v6 hasn't shipped since ~2022. The new CLI is per-project via `npx expo`.

### Anti-pattern: `react-native run-ios` for Expo projects

```bash
# Wrong for Expo
react-native run-ios
```

Use `npx expo run:ios` — it handles the Expo prebuild + run flow correctly. `react-native run-ios` is bare-workflow only.

## Gotchas

- **`npx expo start` vs `npx expo start --dev-client`** — the former opens Expo Go mode; the latter dev client mode. Choose based on what's installed on the device.
- **`--tunnel`** mode is slower but bypasses LAN issues (corporate networks); `--lan` (default) is fastest.
- **`npx expo customize`** writes the file to disk — committed and editable from then on. Once customized, you own keeping it in sync with SDK updates.
- **`npx expo doctor`** vs `npx expo-doctor` — the latter is the separate `expo-doctor` package, more thorough. Prefer it in CI.
- **Cache** — `npx expo start --clear` clears Metro cache.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — `npx expo install` reads the SDK compat matrix
- [EAS CLI](/stacks/expo/eas-cli/) — for build/update/submit commands
- [expo-doctor](/stacks/expo/expo-doctor/) — deeper sanity check
- [Continuous Native Generation](/stacks/expo/continuous-native-generation/) — `prebuild` is core to CNG
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [devops-engineer](/stacks/expo/devops-engineer/)
- [Expo CLI reference](https://docs.expo.dev/more/expo-cli/)
