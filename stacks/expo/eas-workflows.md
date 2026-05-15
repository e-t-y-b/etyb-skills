---
title: EAS Workflows
description: YAML-defined CI/CD for Expo. Build, test, submit, update, Maestro E2E in one chain. Replaces App Center Build and most GitHub Actions complexity.
product:
  name: EAS Workflows
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, qa-engineer]
  authoritative_url: https://docs.expo.dev/eas-workflows/get-started/
  notes: "YAML CI/CD in .eas/workflows/; new actions added per release; Maestro integration steady; GA late 2024"
---

## What it is

**EAS Workflows** is YAML-defined CI/CD that runs on EAS infrastructure. You write workflow files in `.eas/workflows/*.yml`, each defining jobs that can build, submit, update, run Maestro tests, or execute arbitrary `linux-*` runner steps. Jobs declare dependencies (`needs: [other_job]`) and pass outputs between steps.

Trigger from git push, manual `eas workflow:run`, or webhook.

Canonical surface: [EAS Workflows — Get Started](https://docs.expo.dev/eas-workflows/get-started/).

## When to use

For any non-trivial Expo project shipping to production. EAS Workflows replaces:

- **App Center Build** (retired) — completely
- **Fastlane** for build + submit chains — mostly
- **GitHub Actions** for Expo-native concerns (build, update, submit) — usually

You may still run GitHub Actions for non-Expo concerns (lint, type-check, PR comment automation) and trigger EAS Workflows from there.

## 2025-2026 currency anchors

- **GA late 2024**; built-in action types include `build`, `submit`, `update`, `maestro_test`, and generic `linux-*` runners.
- **Reusable workflows** + job outputs (`needs.<job>.outputs.build_id`).
- **Per-step env vars**; secrets from EAS env var store (scoped per-environment).
- **Approval gates** — `type: approval` pauses for designated approvers.
- **Maestro integration** — `eas/maestro_test` action runs against an EAS Build artifact directly; no separate device farm needed.
- **Workflow versioning** — YAML files are committed to repo; changes go through PR review like code.

## Patterns + anti-patterns

### Pattern: Standard release workflow

```yaml
# .eas/workflows/release.yml
name: Release
on:
  push:
    branches: ["release/*"]

jobs:
  test:
    name: Unit + Component Tests
    runs_on: linux-medium
    steps:
      - uses: eas/checkout
      - run: npm ci
      - run: npm test
      - run: npx expo-doctor

  build_ios:
    needs: [test]
    type: build
    params: { platform: ios, profile: production }

  build_android:
    needs: [test]
    type: build
    params: { platform: android, profile: production }

  e2e_ios:
    needs: [build_ios]
    type: maestro_test
    params:
      build_id: ${{ needs.build_ios.outputs.build_id }}
      flow_path: .maestro/

  submit_ios:
    needs: [e2e_ios]
    type: submit
    params:
      build_id: ${{ needs.build_ios.outputs.build_id }}
      profile: production

  submit_android:
    needs: [build_android]
    type: submit
    params:
      build_id: ${{ needs.build_android.outputs.build_id }}
      profile: production
```

Run via `eas workflow:run release` or auto-trigger on push.

### Pattern: Manual gate before production OTA

```yaml
# .eas/workflows/update.yml
jobs:
  test:
    runs_on: linux-medium
    steps:
      - run: npm test

  publish_preview:
    needs: [test]
    type: update
    params:
      channel: preview
      message: ${{ github.event.head_commit.message }}

  approve_production:
    needs: [publish_preview]
    type: approval
    params:
      approvers: ["@release-captains"]

  publish_production:
    needs: [approve_production]
    type: update
    params:
      channel: production
      rollout_percentage: 25
```

`approval` pauses until a designated approver clicks "approve" in the EAS dashboard. Use for production OTAs.

### Pattern: Maestro E2E gating

```yaml
e2e:
  needs: [build_ios]
  type: maestro_test
  params:
    build_id: ${{ needs.build_ios.outputs.build_id }}
    flow_path: .maestro/
    devices:
      - { platform: ios, model: "iPhone 15", os_version: "17.5" }
```

Tests fail → submission blocked. The cost: ~5-15 min per workflow run depending on flow count.

### Anti-pattern: Workflow without test gating

```yaml
jobs:
  build:
    type: build
  submit:
    needs: [build]
    type: submit
```

No tests run. A build that compiles is not a build that works. Always have `test` (Jest) and `e2e` (Maestro) gates before submit.

### Anti-pattern: Triggering workflows from a laptop CLI

```bash
eas workflow:run release   # from local
```

Acceptable for the *first* test of a new workflow; otherwise use git push triggers for provenance.

## Gotchas

- **Workflow files are YAML** — indentation matters; mis-indented `needs:` is the most common error.
- **Outputs are typed** — `${{ needs.build_ios.outputs.build_id }}` only resolves if the upstream job declared the output. Read action docs for available outputs.
- **`linux-medium` is the default runner**; `linux-large` and `macos-*` runners are available but cost more.
- **EAS secrets vs workflow env vars** — secrets are encrypted, env vars are plaintext (don't put tokens in `env:`). Use EAS env var store for sensitive values.
- **Approval timeout** — `approval` step has a configurable timeout (default 7 days); after that the workflow fails.
- **Re-running a failed step** is possible from the EAS dashboard; entire workflow re-run is also supported.

## Cross-references

- [EAS Build](/stacks/expo/eas-build/) — `type: build` action
- [EAS Submit](/stacks/expo/eas-submit/) — `type: submit` action
- [EAS Update](/stacks/expo/eas-update/) — `type: update` action
- [EAS CLI](/stacks/expo/eas-cli/) — `eas workflow:run`, `eas workflow:view`
- `expo-cicd-workflows` skill (delegate) — workflow authoring patterns
- Role overlays: [devops-engineer](/stacks/expo/devops-engineer/), [qa-engineer](/stacks/expo/qa-engineer/)
- [EAS Workflows — Get Started](https://docs.expo.dev/eas-workflows/get-started/)
