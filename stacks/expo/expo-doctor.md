---
title: expo-doctor
description: Dependency + native config sanity checker for Expo apps. Catches version drift, NA incompatibility, plugin order issues. Run in CI.
product:
  name: expo-doctor
  stack: expo
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, devops-engineer, qa-engineer]
  authoritative_url: https://docs.expo.dev/develop/development-builds/use-development-builds/#expo-doctor
  notes: "Dependency + native module sanity checker; checks expand per SDK"
---

## What it is

**`expo-doctor`** is the Expo project linter. It checks:

- Package versions against the SDK compat matrix (`react-native`, `react`, all `expo-*`, common third-party libs)
- New Architecture compatibility for installed native modules
- Plugin ordering and known plugin conflicts
- Common config mistakes (missing permissions strings, mismatched bundle IDs)
- Peer-dep / Node version warnings

```bash
npx expo-doctor
```

Canonical surface: [Use development builds — expo-doctor](https://docs.expo.dev/develop/development-builds/use-development-builds/#expo-doctor) and `npx expo-doctor --help`.

## When to use

In every CI run. Always. Costs <30s; catches issues that would otherwise take 30 min to debug after a build fails.

```yaml
# .github/workflows/check.yml or .eas/workflows/test.yml
- run: npx expo-doctor
```

Also run locally before opening a PR.

## 2025-2026 currency anchors

- **Checks expand per SDK** — expect occasional new warnings on SDK upgrade.
- **NA compatibility checks** — flags libraries known to not work on the New Architecture.
- **React 19 compat checks** added in SDK 53+.
- **`/next` API warnings** when both legacy and `/next` are used in the same project.
- **Plugin ordering warnings** — known bad orderings (e.g., `expo-build-properties` after `expo-router`).

## Patterns + anti-patterns

### Pattern: Run in CI

```yaml
- name: Doctor
  run: npx expo-doctor
```

Fails the build on errors; warnings are non-fatal.

### Pattern: Accept known warnings explicitly

```bash
npx expo-doctor --skip-pnpm-warnings  # if your monorepo uses pnpm intentionally
```

Document accepted warnings in your repo's `CLAUDE.md` or contributor docs so the team doesn't keep re-investigating them.

### Pattern: Pair with `expo install --check`

```yaml
- run: npx expo install --check
- run: npx expo-doctor
```

`--check` catches version drift in the SDK matrix; `expo-doctor` catches the rest. Together they cover the surface.

### Anti-pattern: Skipping doctor because "warnings are noisy"

Warnings get noisy if you ignore them for months. Triage them as they arrive: either fix, accept (with rationale), or file an upstream issue. Don't accumulate.

### Anti-pattern: Suppressing all warnings

Don't pass `--silent` to hide signals. If there's a warning, decide what to do with it.

## Gotchas

- **False positives** for some custom monorepo setups — read the warning carefully before changing config.
- **NA compat checks** rely on library metadata — newer-than-database libraries may show "unknown."
- **Network access** — `expo-doctor` checks online for known package issues; in air-gapped CI you may need to skip those checks.
- **Exit codes** — non-zero on errors; zero on warnings. CI gating is straightforward.

## Cross-references

- [Expo CLI](/stacks/expo/expo-cli/) — `npx expo install --check` complementary command
- [Expo SDK](/stacks/expo/expo-sdk/) — compat matrix source
- [New Architecture](/stacks/expo/new-architecture/) — NA compat checks
- Role overlays: [qa-engineer](/stacks/expo/qa-engineer/), [devops-engineer](/stacks/expo/devops-engineer/)
- [Use development builds — expo-doctor](https://docs.expo.dev/develop/development-builds/use-development-builds/#expo-doctor)
