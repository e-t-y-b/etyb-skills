---
title: EAS Update
description: Over-the-air JS bundle delivery for Expo apps. Hermes bytecode diffing, phased rollouts, branch/channel mapping, instant rollback. Replaces CodePush.
product:
  name: EAS Update
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, mobile-architect, qa-engineer]
  authoritative_url: https://docs.expo.dev/eas-update/introduction/
  notes: "Hermes bytecode diffing, phased rollouts, branch/channel mapping evolving; replaced CodePush after App Center retired Mar 2025"
---

## What it is

**EAS Update** is the OTA (over-the-air) delivery service for Expo JS bundles. Publish a new JS bundle, and devices fetch + apply it on next launch — no App Store / Play Store review for JS-only changes.

The mental model:

- **Builds** are binaries with a `runtimeVersion` (fingerprint of native config). One channel maps to many builds (different versions over time).
- **Channels** (`production`, `preview`, `development`) are what the binary points to.
- **Branches** are what publishes go to. A channel maps to a branch via the EAS dashboard or `eas channel:edit`.
- **Update groups** are individual publishes; each can be republished to roll back.

```
Binary --channel--> "production" -mapping-> Branch "production" -has-> Updates [u1, u2, u3, ...]
```

Canonical surface: [EAS Update Introduction](https://docs.expo.dev/eas-update/introduction/).

## When to use

For every Expo project. CodePush is dead (App Center retired March 2025). The drop-in alternatives — Revopush (CodePush API shape), Stallion (binary diffing) — exist but EAS Update is the first-party path.

Use EAS Update for:

- JS-only bug fixes (typos, logic fixes, copy changes)
- A/B experiments via update groups
- Feature flags (data-driven, JS-side)
- Rapid iteration on `preview` channel for internal users

Do **not** use EAS Update for:

- Native code changes (config plugins, new native modules) — those require a new binary
- Apple Guideline-skirting (don't ship features that weren't reviewed; Apple watches)

## 2025-2026 currency anchors

- **Hermes bytecode diffing** (SDK 55) — incremental updates can be **<50KB** for small changes vs ~3MB whole-bundle. Massive bandwidth + download-speed win.
- **Phased rollouts** — `eas update --rollout-percentage 25` or set in EAS dashboard. Ship to 10% → 50% → 100% over hours/days.
- **Rollback via `eas update:republish`** — instant; reverts to a prior update group. Clients fetch on next launch.
- **`runtimeVersion` policy `fingerprint`** (SDK 51+) is the default — hashes your native config so OTAs only ship to compatible binaries.
- **Branch ↔ git branch convention** — `production` git → `production` update branch; `preview` git → `preview` update branch.
- **App Center retired March 2025** — CodePush projects must migrate. EAS Update is the recommended path; Revopush + Stallion are CodePush-shape alternatives.

## Patterns + anti-patterns

### Pattern: `fingerprint` runtime version

```json
// app.json
"runtimeVersion": { "policy": "fingerprint" }
```

The fingerprint is a hash of your native config (config plugins, native modules, native build settings). When a native dep changes, fingerprint changes → OTAs don't ship to old binaries. Apple/Google compliant: you're not shipping native code via OTA.

### Pattern: One channel per environment

```json
// eas.json
"build": {
  "production": { "channel": "production" },
  "preview":    { "channel": "preview" },
  "development": { "channel": "development" }
}
```

Never share channels — `eas update --branch main` hitting both prod and preview is how you ship a buggy preview to production users.

### Pattern: Publish from CI, never from a laptop

```bash
# In CI (EAS Workflows):
eas update --branch production --message "fix: order total calculation"

# Never from your laptop for production
```

Provenance, audit trail, test gating. Laptop publishes are fine for `development` channel; never for `production`.

### Pattern: Phased rollout

```bash
eas update --branch production --rollout-percentage 25 --message "..."
# Wait 2 hours, monitor Sentry
eas update:edit --rollout-percentage 50
# Wait 4 hours
eas update:edit --rollout-percentage 100
```

Or via EAS dashboard UI. For high-risk releases, slower phases. For typo fixes, jump faster.

### Pattern: Instant rollback

```bash
eas update:list --branch production    # find the prior update group ID
eas update:republish --group <id>      # republish; clients fetch on next start
```

Sub-30-minute resolution for OTA bugs. Compare to "submit hotfix binary, wait 24-48h for Apple review" — order of magnitude faster.

### Pattern: Sentry release tagging with EAS Update

```ts
import * as Sentry from '@sentry/react-native';
import * as Updates from 'expo-updates';

Sentry.init({
  dsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
  release: Updates.runtimeVersion,
  dist: Updates.updateId ?? 'embedded',
});
```

Crashes get tagged with both runtime version (binary) and update ID (OTA bundle). You can pinpoint "this bug only affects update group X" without guesswork.

### Anti-pattern: OTAing native config changes

You added a config plugin → fingerprint changed → OTAs don't ship to the old binary. If you don't bump `runtimeVersion`, OTAs silently stop reaching devices. This is by design — but if you forget the rule, you'll waste an afternoon wondering why updates don't appear.

### Anti-pattern: Sharing one channel across environments

```json
// BAD
"production": { "channel": "main" },
"preview":    { "channel": "main" }
```

Now an `eas update --branch main` hits both prod and preview binaries. Always one channel per environment.

### Anti-pattern: Forgetting to upload sourcemaps after OTA

Sentry shows minified Hermes bytecode unless you upload sourcemaps for *each* OTA group:

```bash
npx eas-cli update --branch production --message "..." \
  && npx sentry-expo-upload-sourcemaps --release "$EAS_UPDATE_GROUP_ID"
```

Without this, your OTA crash reports are unreadable.

## Gotchas

- **`runtimeVersion` mismatch** is the #1 silent failure — OTAs target binaries by fingerprint; mismatched binaries never get the update.
- **`expo-updates` must be in production mode** to fetch — in dev/dev client, you may need to toggle via the dev menu or set environment flags.
- **Phased rollout percentage is cumulative**, not stepped — 25 → 50 means 50% total, not 50% of the remaining 75%.
- **Update group vs branch** — each `eas update` publishes a *group* to a branch. A branch is a stream; a group is one publish. You roll back to a group.
- **Channel→branch mapping is dynamic** — change in EAS dashboard or via `eas channel:edit`. Existing binaries pick up the new mapping on next launch.
- **Update fetching** is async on app start — first launch after publish shows the old bundle; second launch shows new. You can force-sync with `Updates.fetchUpdateAsync()` + `Updates.reloadAsync()`, but that adds startup latency.

## Cross-references

- [EAS Build](/stacks/expo/eas-build/) — produces binaries with `runtimeVersion`
- [EAS Workflows](/stacks/expo/eas-workflows/) — orchestrate publish gates
- [EAS CLI](/stacks/expo/eas-cli/) — `eas update`, `eas update:list`, `eas update:republish`
- [Continuous Native Generation](/stacks/expo/continuous-native-generation/) — what `fingerprint` policy hashes
- [Hermes](/stacks/expo/hermes/) — bytecode runtime that diffing operates on
- Role overlays: [devops-engineer](/stacks/expo/devops-engineer/), [qa-engineer](/stacks/expo/qa-engineer/)
- [EAS Update Introduction](https://docs.expo.dev/eas-update/introduction/)
