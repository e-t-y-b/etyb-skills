---
title: Crashlytics
description: Crash + non-fatal error reporting for iOS, Android, Flutter, React Native — symbolicated stack traces, breadcrumbs, custom keys, with strict symbol-upload discipline.
product:
  name: Crashlytics
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect, sre-engineer]
  authoritative_url: https://firebase.google.com/docs/crashlytics
  notes: "Native + RN + Flutter SDKs stable; Apple privacy manifest + dSYM upload discipline non-negotiable."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Crashlytics captures and groups app crashes (and recorded non-fatal errors) with symbolicated stack traces, breadcrumbs, custom keys, and device/OS metadata. It's the most-used Firebase mobile SDK and the most likely to silently fail — the failure mode is "stack traces show hex addresses instead of source `file:line`." Cause: symbols not uploaded for that build.

Canonical reference: [Crashlytics docs](https://firebase.google.com/docs/crashlytics).

## When to use it

**Use Crashlytics when:**

- Mobile apps (iOS, Android, Flutter, RN) — the primary use case
- You want zero-config crash capture with reasonable defaults
- You want recorded non-fatal errors surfaced for visibility

**Use Sentry / Bugsnag / Rollbar when:**

- You want a unified crash + error tool across web + backend + mobile
- You need release-health dashboards beyond Crashlytics
- You're not on Firebase

## 2025-2026 currency anchors

- **RN + Flutter symbolication now reliably works** when source maps / obfuscation maps are uploaded. Pre-2023, this was weak — fixed.
- **Apple Privacy Manifest** (mandatory since 2024) — Firebase publishes its own manifest; incorporate into your app's combined manifest.
- **Cloud Trace integration** (2024-2025) — Performance + Crashlytics + backend now correlate.

## Patterns

### Best practices

- **Set userId** to the Firebase Auth UID after sign-in: `Crashlytics.crashlytics().setUserID(uid)`. **Do NOT** set userId to email, phone, or any direct PII. The UID is opaque.
- **Add breadcrumbs** for state transitions: `crashlytics().log("Entering checkout step \(step)")`. Breadcrumbs are kept in a ring buffer and attached to crashes — they're the difference between "the app crashed" and "the app crashed after the user tried to confirm a $0 payment with no items."
- **Custom keys** for app state: `crashlytics().setCustomValue("subscription_tier", "pro")`. Useful for filtering crash reports.
- **Non-fatal recording**: `crashlytics().recordError(error)` for caught exceptions you want surfaced. Use sparingly — every recorded error counts toward the daily Crashlytics quota.
- **Verify symbolicated reports** after every release. The stack trace should show `Sources/MyModule/MyFile.swift:42`, not `0x1029384a8`.

### iOS — dSYM upload

Two paths:

1. **Build-phase script** (recommended) — runs on every build, uploads dSYMs automatically. Add this Run Script Phase to your app target, after "Embed Frameworks":

   ```bash
   "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
   ```

   Set `Input Files` to include `$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)`.

2. **CI upload via `upload-symbols`** — for archive-only CI flows. Use `firebase crashlytics:symbols:upload --app=<app-id> path/to/dsyms`.

### iOS — Bitcode-stripped dSYMs

If your app uses Bitcode (declining as Apple deprecates Bitcode), App Store Connect re-symbolicates after upload. Download the post-processing dSYMs from App Store Connect → Activity → Build Number → Download dSYMs, then upload to Crashlytics. CI step if you use Bitcode.

### Android — NDK symbol upload

Pure Kotlin/Java apps get symbols via the Crashlytics Gradle plugin automatically. NDK code (`.so` libraries) needs native symbols uploaded separately:

```bash
./gradlew app:uploadCrashlyticsSymbolFileRelease
```

Configure in `build.gradle.kts`:

```kotlin
android {
  buildTypes {
    release {
      firebaseCrashlytics {
        nativeSymbolUploadEnabled = true
        unstrippedNativeLibsDir = file("build/intermediates/cmake/release/obj")
      }
    }
  }
}
```

Without this, NDK crashes show as raw addresses.

### RN with Hermes

Upload `index.android.bundle.map` and `main.jsbundle.map` to Crashlytics for symbolicated JS frames. `@react-native-firebase/crashlytics` exposes a helper; otherwise upload via the Crashlytics CLI.

### Flutter

Dart obfuscation maps (`--split-debug-info=...`) must be uploaded for release builds. `flutterfire crashlytics symbols upload` or `firebase crashlytics:symbols:upload` covers it.

## Anti-patterns

- **`setUserID(email)` or any PII** — leaks PII into crash reports.
- **dSYMs not uploaded** — symbolicated reports never appear. Verify after every release.
- **Recording every caught exception** — burns daily quota; obscures the signal.
- **No verification step** — assuming dSYMs upload silently is how the bug ships to prod.

## Gotchas

- **dSYM upload silently fails in CI** more often than any other Firebase integration. Build a smoke check.
- **Bitcode causes re-symbolication** — you must upload the post-processing dSYMs from App Store Connect.
- **NDK crashes** (the worst kind) need separate native symbol upload.
- **Crashlytics breadcrumb ring buffer** is limited — older breadcrumbs drop. Don't rely on it for full history; log critical state separately.
- **Daily non-fatal quota** — `recordError` calls count. Sparingly.

## Cross-references

- [Performance Monitoring](/stacks/firebase/performance-monitoring/) — perf sibling, both integrate with Cloud Trace
- [Firebase Analytics (GA4)](/stacks/firebase/firebase-analytics/) — crash-free user metrics flow here
- [mobile-architect overlay](/stacks/firebase/mobile-architect/#crashlytics--the-integration-that-always-almost-works) — full mobile playbook
- Authoritative: [firebase.google.com/docs/crashlytics](https://firebase.google.com/docs/crashlytics)
