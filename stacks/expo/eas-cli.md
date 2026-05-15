---
title: EAS CLI
description: "`npx eas` (formerly `eas-cli`) — build, update, submit, workflows, deploy, env, credentials. The day-to-day devops driver for Expo apps."
product:
  name: EAS CLI
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, mobile-architect, qa-engineer]
  authoritative_url: https://docs.expo.dev/eas/
  notes: "`npx eas` (formerly `eas-cli`) — build, update, submit, workflows, deploy, env, credentials"
---

## What it is

**EAS CLI** is the command-line driver for Expo Application Services. Subcommands cover:

- `eas build` — cloud builds (iOS / Android)
- `eas update` — OTA JS bundle publishing
- `eas submit` — store submission
- `eas workflow:run` — CI/CD chains
- `eas deploy` — EAS Hosting deploy
- `eas env` — environment variables management
- `eas credentials` — signing certs, keystores, ASC API keys
- `eas channel:*` — OTA channel ↔ branch mapping
- `eas update:list` / `eas update:republish` — rollback

Usage: `npx eas <subcommand>` or `npm i -g eas-cli` (global install is fine here, unlike `expo-cli`).

Canonical surface: [EAS overview](https://docs.expo.dev/eas/).

## When to use

For every interaction with EAS services. Combined with `npx expo` (project CLI) and `npx expo-doctor` (sanity check), these three CLIs cover the entire dev → build → ship loop.

## 2025-2026 currency anchors

- **Global install acceptable** (unlike `expo-cli`) — `npm i -g eas-cli`, then `eas login`. Per-project pin via `cli.version` in `eas.json`.
- **`eas build:run`** — install an EAS Build artifact directly to a simulator/emulator.
- **`eas update:republish --group <id>`** — instant rollback to a prior update group.
- **`eas env:create`** — set per-profile / per-environment env vars.
- **`eas credentials`** — interactive credential management; replaces `fastlane match` for most teams.
- **`eas workflow:view`** — see workflow status / re-run failed steps.
- **`eas channel:edit`** — change channel → branch mapping dynamically.

## Patterns + anti-patterns

### Pattern: Standard daily commands

```bash
# Build a dev client for engineers
eas build --profile development --platform all

# Push a JS-only update to preview
eas update --branch preview --message "fix: typo in welcome screen"

# Promote preview build to TestFlight internal
eas submit --platform ios --profile preview --latest
```

### Pattern: Rollback an update

```bash
eas update:list --branch production
# Find the prior group ID
eas update:republish --group <id> --branch production
# Devices fetch on next launch; sub-30-min rollback
```

### Pattern: Local build for debugging

```bash
eas build --local --profile production --platform ios
# Same image as cloud, runs locally; for diagnosing build issues
```

### Pattern: Credentials inspection

```bash
eas credentials --platform ios
# Interactive: view, rotate, replace credentials
```

### Anti-pattern: Production publishes from a laptop

```bash
eas update --branch production --message "..."   # 👈 from your laptop
```

Use CI. Provenance, audit, test gating. Laptop publishes belong to dev/preview at most.

### Anti-pattern: Manual `eas-cli` updates without checking versions

`eas-cli` is updated frequently. If `eas.json` declares `"cli": { "version": ">=10.0.0" }`, you may need to update. Run `eas --version` and compare.

## Gotchas

- **`eas login`** — authenticates via web browser; token stored in `~/.expo/state.json`.
- **CI auth** — use `EXPO_TOKEN` env var (generated via `eas auth:create-token`).
- **`eas-cli` vs `npx eas`** — both work; global install is a personal preference. `eas.json` `cli.version` constrains the version per-project.
- **Project ID** — `eas init` connects local repo to EAS project; auto-creates if needed. Project ID lives in `app.json` `extra.eas.projectId`.
- **Confusing subcommands** — `eas update:edit` modifies an existing update's metadata (rollout %, etc.); `eas update --branch X` publishes a new one. Read carefully.

## Cross-references

- [EAS Build](/stacks/expo/eas-build/), [EAS Update](/stacks/expo/eas-update/), [EAS Submit](/stacks/expo/eas-submit/), [EAS Workflows](/stacks/expo/eas-workflows/), [EAS Hosting](/stacks/expo/eas-hosting/) — what the CLI drives
- [Expo CLI](/stacks/expo/expo-cli/) — project-side commands
- Role overlays: [devops-engineer](/stacks/expo/devops-engineer/)
- [EAS overview](https://docs.expo.dev/eas/)
