---
title: EAS Build
description: Cloud-hosted iOS + Android builds for Expo projects — profiles, credentials, build images, caching. Apple Silicon machines, precompiled binaries, free cache.
product:
  name: EAS Build
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, mobile-architect, qa-engineer]
  authoritative_url: https://docs.expo.dev/build/introduction/
  notes: "Image releases monthly; iOS precompiled binaries + Apple Silicon machines; cache policy changes; pricing tiers shift"
---

## What it is

**EAS Build** is Expo's cloud build service for iOS + Android. You define build profiles in `eas.json`, run `eas build --profile <name> --platform <ios|android|all>`, and EAS:

1. Uploads your repo (respecting `.easignore`)
2. Runs `npx expo prebuild` to regenerate native projects
3. Builds on the appropriate image (macOS Apple Silicon for iOS; Linux for Android)
4. Manages credentials (signing certs, provisioning profiles, keystores) in encrypted storage
5. Produces a downloadable artifact (`.ipa`, `.apk`, `.aab`) and a dashboard build record

Canonical surface: [EAS Build Introduction](https://docs.expo.dev/build/introduction/).

## When to use

For any Expo project that's beyond "hello world." Local builds (`npx expo run:ios` / `run:android`) work but require Xcode + Android Studio installed and don't give you reproducibility across the team. EAS Build:

- Is reproducible (pinned images)
- Manages credentials centrally
- Integrates with `eas submit`, `eas update`, `eas workflows`
- Runs on faster hardware than most laptops (Apple Silicon, precompiled binaries)
- Doesn't tie up your machine for 25 minutes per build

Local builds are still useful for fast iteration on native code; EAS Build is for everything else.

## 2025-2026 currency anchors

- **Apple Silicon (M-series) build machines** are default since 2024 — iOS clean builds ~40% faster than the previous Intel images.
- **RN 0.84+ precompiled iOS binaries** (`.xcframework`) — iOS clean builds another ~8× faster than 2023 (~25 min → ~3 min on `m-medium`).
- **Build caching free for all users** since SDK 55 (was paid in 2024) — subsequent builds ~30% faster.
- **Custom build images** via `eas.json` `image` field; pin for reproducibility (e.g., `macos-sonoma-14.5-xcode-15.4`). Images rotate monthly otherwise.
- **`appVersionSource: "remote"`** (in cli block) lets EAS manage version numbers entirely server-side — recommended for teams that don't want versioning in git.
- **2026 toolchain requirements**: Xcode 15.4+ for App Store submissions; Android target API 34+ minimum, API 35 mandatory by August 2026.

## Patterns + anti-patterns

### Pattern: Three-profile eas.json

```json
{
  "cli": { "version": ">=10.0.0", "appVersionSource": "remote" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "env": { "APP_VARIANT": "development" },
      "ios": { "simulator": true, "resourceClass": "m-medium" },
      "android": { "buildType": "apk" }
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview",
      "env": { "APP_VARIANT": "preview" },
      "ios": { "resourceClass": "m-medium" },
      "android": { "buildType": "apk" }
    },
    "production": {
      "channel": "production",
      "autoIncrement": true,
      "env": { "APP_VARIANT": "production" },
      "ios": { "resourceClass": "m-large" },
      "android": { "buildType": "app-bundle" }
    }
  }
}
```

Why three: dev clients for engineers (internal), preview for stakeholders (internal TestFlight + Play Internal), production for the store.

### Pattern: Pin build images

```json
"production": {
  "ios": { "image": "macos-sonoma-14.5-xcode-15.4" },
  "android": { "image": "linux-ubuntu-22.04-jdk-17" }
}
```

EAS rotates images monthly; a floating image may upgrade Xcode mid-release and break a previously-green build. Pin, refresh deliberately each quarter.

### Pattern: `autoIncrement`

```json
"production": { "autoIncrement": true }
```

Bumps `iosBuildNumber` and `androidVersionCode` per build automatically. Without it, the second submission fails with "duplicate build number." Alternative: `appVersionSource: "remote"`.

### Pattern: Resource class right-sizing

| Tier | When | Cost |
|------|------|------|
| `m-medium` (default) | Most builds | Free quota covers a few; paid ~$25/build credit |
| `m-large` | Heavy Cocoapods, Skia, large monorepo | ~2× cost |
| `large` (Linux for Android) | Same | Same scaling |

Default to `m-medium` and measure. The marginal speedup of `m-large` is usually 30-50% — only worth it if builds genuinely block work.

### Anti-pattern: Building production from a laptop

```bash
eas build --profile production --platform all   # from your laptop
```

Works, but no Git commit attribution, no test gating, no audit trail. Build production from CI ([EAS Workflows](/stacks/expo/eas-workflows/) or GitHub Actions invoking `eas-cli`) every time.

### Anti-pattern: Skipping `expo-doctor` before build

`expo-doctor` runs cheap. Run it in CI before `eas build`. Catches version drift, missing peer deps, plugin order issues — much faster than waiting 15 min for a build to die in linker errors.

## Gotchas

- **`Podfile.lock` drift** — local builds may regenerate `Podfile.lock` from a different CocoaPods version than EAS. Either commit the file from EAS's regeneration or set `EAS_BUILD_DISABLE_NPM_INSTALL_AUDIT=1` and accept some non-determinism.
- **Monorepo upload size** — EAS uploads the whole workspace; use `.easignore` aggressively (`apps/web/`, `dist/`, test snapshots, `.maestro/`).
- **iOS signing on first build** — prompts for Apple ID, ASC API Key, signing cert. Save the `.p8` once — Apple only lets you download it once.
- **Provisioning profile expiry** — iOS distribution certs expire annually; `eas credentials` to renew.
- **Local repro of EAS build** — `eas build --local` runs the same image locally if you need to debug a build-time issue without the round-trip.

## Cross-references

- [EAS Submit](/stacks/expo/eas-submit/) — post-build store submission
- [EAS Update](/stacks/expo/eas-update/) — OTA after binary ships
- [EAS Workflows](/stacks/expo/eas-workflows/) — orchestrate build + test + submit
- [Continuous Native Generation](/stacks/expo/continuous-native-generation/) — `prebuild` runs inside EAS Build
- [app.json / app.config.js](/stacks/expo/app-config/) — what `prebuild` reads
- [EAS CLI](/stacks/expo/eas-cli/) — `eas build`, `eas credentials`, `eas build:view`
- Role overlays: [devops-engineer](/stacks/expo/devops-engineer/)
- [EAS Build Introduction](https://docs.expo.dev/build/introduction/)
