---
title: Test Lab
description: Real-device matrix in Google's lab — Robo Test crawls, instrumentation tests on iOS/Android, Game Loop tests for games. Device coverage narrowing post-2024.
product:
  name: Test Lab
  stack: firebase
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, qa-engineer, devops-engineer]
  authoritative_url: https://firebase.google.com/docs/test-lab
  notes: "Real-device matrix narrowing post-2024; check current device coverage before committing CI matrix."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Test Lab runs your iOS and Android apps on a matrix of real devices in Google's data centers. Three test types:

- **Robo Test** — automatic UI crawler that exercises your app without any test code. Good for smoke / regression-shaped catches.
- **Instrumentation tests** — your existing Espresso (Android) or XCUITest (iOS) test suite, run across the device matrix.
- **Game Loop tests** — your app runs in a loop mode and reports its own metrics.

Canonical reference: [Test Lab docs](https://firebase.google.com/docs/test-lab).

## When to use it

**Use Test Lab when:**

- Smoke tests on real devices before submitting to stores (Robo Test catches null-pointer / null-check regressions in lightly-trafficked screens)
- Running existing instrumentation tests across a device matrix you can't maintain in-house
- Game loop perf testing on real GPUs

**Don't use Test Lab as:**

- **Your only test environment** — it's too slow for fast CI loops. Use unit/integration tests for the iteration loop; Test Lab as a pre-release gate.
- **A replacement for TestFlight / Play internal testing** — those expose real humans to your build.
- **A replacement for [Crashlytics](/stacks/firebase/crashlytics/) in production** — Test Lab devices are limited; real users surface different paths.

## 2025-2026 currency anchors

- **Device matrix narrowing post-2024** — old devices age out faster than they used to. A test matrix that worked 12 months ago may include retired devices today.
- **Check the current device list before committing to a CI device matrix.** Don't assume historical matrices are still available.
- **Cost** — Test Lab charges per device-minute. A 10-device matrix running a 5-minute test suite = 50 device-minutes per CI run.

## Patterns

### Robo Test for smoke

`firebase test android run --type robo --app app-debug.apk` runs Robo Test against an APK. No test code required. Robo Test attempts to exercise every UI element; reports crashes + screenshots.

Useful as a low-effort "did anything break catastrophically on this build?" gate.

### Instrumentation test matrix

`firebase test android run --type instrumentation --app app-debug.apk --test app-androidTest.apk --device model=Pixel7,version=33,locale=en,orientation=portrait` runs your Espresso tests on a specific device. Scale via multiple `--device` flags.

For iOS, `firebase test ios run --test app.xctestrun.zip --device model=iphone14pro,version=17.4,locale=en_US`.

### Game Loop tests

Implement an intent / activity that runs your app in a deterministic loop mode (reproducing gameplay), reports metrics. Test Lab launches it; collects the metrics. Useful for "did our frame rate drop?" gates.

## Anti-patterns

- **Running Test Lab on every commit** — too slow, too expensive. Use it for nightly / pre-release gates.
- **Test Lab as the only QA layer** — Robo Test catches catastrophic regressions, not subtle UI bugs. Pair with human testing via [App Distribution](/stacks/firebase/app-distribution/).
- **Committing to an obsolete device matrix** — the matrix changes; CI fails when a model disappears.
- **No flaky-test handling** — real-device tests are noisier than emulators. Build retries and quarantine.

## Gotchas

- **Device retirement** post-2024 happens faster than before. Audit your matrix quarterly.
- **iOS provisioning** — your `xctestrun` and signing must match the test devices. Wildcard certs help.
- **Network conditions** in Test Lab are real cloud-network — tests that assume LAN-fast network may behave differently.
- **Cost scales with matrix breadth** — a 20-device matrix for a 10-minute suite is 200 device-minutes. Tier matrices: smoke on 1 device per OS version; full matrix nightly.
- **No state persists between test runs** — every run starts fresh.

## Cross-references

- [App Distribution](/stacks/firebase/app-distribution/) — human-tester complement to Test Lab automation
- [Crashlytics](/stacks/firebase/crashlytics/) — production crash capture pairs with Test Lab pre-release captures
- [mobile-architect overlay](/stacks/firebase/mobile-architect/#test-lab) — full mobile QA strategy
- Authoritative: [firebase.google.com/docs/test-lab](https://firebase.google.com/docs/test-lab)
