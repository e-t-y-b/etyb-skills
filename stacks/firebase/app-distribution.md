---
title: App Distribution
description: Sideloaded test builds for known tester pools — fast iteration without store review. Pairs with TestFlight / Play internal tracks, doesn't replace them.
product:
  name: App Distribution
  stack: firebase
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, devops-engineer, qa-engineer]
  authoritative_url: https://firebase.google.com/docs/app-distribution
  notes: "Tester management + CI uploads stable; not a substitute for TestFlight/internal Play tracks for store readiness checks."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase App Distribution sideloads pre-release iOS and Android builds to a known tester pool — faster iteration than TestFlight (no review wait), but with no production-readiness gate. iOS uses ad-hoc provisioning profiles; Android distributes APKs/AABs.

Canonical reference: [App Distribution docs](https://firebase.google.com/docs/app-distribution).

## When to use it

**Use App Distribution when:**

- Nightly builds to internal QA
- Weekly builds to wider beta
- Quick share with one tester for a fix verification
- You want an in-app update prompt (the App Distribution SDK supports this)

**Don't substitute it for:**

- **TestFlight / Play internal testing** — they catch store-readiness issues App Distribution doesn't (in-app purchase flows, push entitlements, App Review).
- **[Crashlytics](/stacks/firebase/crashlytics/)** in production — App Distribution testers are a small, biased pool; real users on a real device population stress different paths.

## 2025-2026 currency anchors

Stable product. Notable:
- **CI integration** — `firebase appdistribution:distribute` is the canonical CLI command; works in GitHub Actions, GitLab CI, CircleCI, Bitrise.
- **In-app update prompt SDK** — the app prompts users for available updates without re-installing the App Distribution app.

## Patterns

### CI upload

```bash
firebase appdistribution:distribute path/to/app.aab \
  --app=APP_ID \
  --groups=qa,beta \
  --release-notes-file=RELEASE_NOTES.md
```

Common in CI pipelines after a successful build. Pair with environment-specific Firebase projects (`dev`, `stage`, `prod`).

### In-app update prompt

```kotlin
val appDistribution = FirebaseAppDistribution.getInstance()
appDistribution.updateIfNewReleaseAvailable()
```

Prompts the user when a new build is available. Useful for tight QA loops where testers need to be on the latest build.

### Tester groups

Organize testers into groups (`qa`, `beta`, `engineering`, etc.). Distribute to groups, not individuals — easier rotation.

## Anti-patterns

- **Using App Distribution as a production rollout mechanism** — it's not. Use the stores.
- **Distributing builds without release notes** — testers don't know what to focus on; bug reports are scattershot.
- **Single-test-account distribution** — share builds with a *group*, not one person; otherwise rotation breaks when that person leaves.
- **No version naming convention** — build numbers monotonic; release notes versioned. Otherwise testers can't tell which build they're on.

## Gotchas

- **iOS provisioning** — testers must be in your ad-hoc distribution provisioning profile, or the build won't install. UDID rotation is a real pain at scale.
- **App Distribution does NOT exercise App Review path** — IAP flows, push entitlements, App Review-only behavior are not validated.
- **Android — APK vs AAB** — AAB is the future; for App Distribution AAB works but some legacy testers prefer APKs. Stick with AAB.
- **Tester invite emails sometimes land in spam** — pre-warn testers; rotate invitations on staff churn.

## Cross-references

- [Crashlytics](/stacks/firebase/crashlytics/) — production crash capture, complements App Distribution beta capture
- [Test Lab](/stacks/firebase/firebase-test-lab/) — automated device-matrix testing, complement to human testers
- [Firebase CLI](/stacks/firebase/firebase-cli/) — `appdistribution:distribute` command
- [mobile-architect overlay](/stacks/firebase/mobile-architect/#app-distribution) — mobile QA workflow
- Authoritative: [firebase.google.com/docs/app-distribution](https://firebase.google.com/docs/app-distribution)
