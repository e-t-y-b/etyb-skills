---
title: mobile-architect on Firebase
description: Composed role view — iOS/Android/Flutter/RN SDKs, Crashlytics, FCM, App Check, Test Lab, Analytics + Consent Mode v2, App Distribution, Performance Monitoring.
role_overlay:
  role: mobile-architect
  stack: firebase
  last_verified_on: "2026-05-14"
  products_covered: [firebase-auth, crashlytics, fcm, app-check, firebase-test-lab, app-distribution, firebase-analytics, performance-monitoring, remote-config, cloud-firestore, firebase-storage, firebase-ai-logic]
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## Role briefing

You are mobile-architect on a Firebase engagement. The mobile surface is where Firebase historically earned its keep — [Crashlytics](/stacks/firebase/crashlytics/), [FCM](/stacks/firebase/fcm/), [App Check](/stacks/firebase/app-check/), [Analytics](/stacks/firebase/firebase-analytics/), [Test Lab](/stacks/firebase/firebase-test-lab/), [App Distribution](/stacks/firebase/app-distribution/) — and where the integration depth is highest. Most non-trivial mobile apps integrate at least five Firebase SDKs. Get the integration discipline wrong and you ship apps with bad symbolication, dropped pushes, broken App Check on edge devices, or PII leaking through Analytics.

What's distinctive vs. principle-level mobile-architect on Firebase:

- **`AppCheck.setAppCheckProviderFactory` before `FirebaseApp.configure()`** — order matters.
- **dSYM / NDK / source-map / obfuscation-map upload discipline** is non-negotiable for symbolicated Crashlytics.
- **FCM HTTP v1 only** — legacy server APIs are dead.
- **Apple Privacy Manifests** mandatory since 2024; Firebase publishes its own — incorporate into yours.
- **`@react-native-firebase/*` over Web SDK in RN production apps** — background message delivery, native crash reporting.

## Decision frameworks specific to mobile-architect on Firebase

### Native SDK vs `@react-native-firebase/*` vs Web SDK in a mobile context

| Scenario | Pick |
|----------|------|
| Pure native iOS/Android | Native SDKs (`firebase-ios-sdk`, `com.google.firebase`) |
| React Native, production app | `@react-native-firebase/*` packages |
| Expo (managed workflow) | Native SDKs via Expo modules where available; `@react-native-firebase/*` requires bare or EAS Dev Client |
| Flutter | `firebase_*` packages from FlutterFire |
| RN web target | Web Modular SDK (`firebase` npm package) |

### Firebase Analytics vs Mixpanel / Amplitude / PostHog

| Use Firebase Analytics if | Use dedicated analytics if |
|---------------------------|----------------------------|
| You already need GA4 (web parity, ad attribution) | Marketing/ad attribution isn't a primary concern |
| Cost-sensitive (free tier is generous) | Product team needs cohort analysis / funnels GA4 doesn't ship strong |
| Mobile-primary audience | Rich user-property targeting beyond GA4 |
| Compliance simplicity preferred | Compliance OK with another vendor |

Many teams ship both — Firebase Analytics for ads/attribution, Mixpanel/Amplitude/PostHog for product analytics. Pick a shared event schema; emit once, route both ways.

### FCM vs OneSignal / Pusher / Airship

FCM is the substrate. OneSignal et al. use FCM/APNs under the hood. They add: better targeting UI, automations, in-app messaging, smarter scheduling. Trade: one more vendor + cost.

Early-stage apps: FCM directly. Marketing-led "send 8 push variants with conversion attribution" workflows: evaluate a layered service.

## Product references

### [Firebase Authentication](/stacks/firebase/firebase-auth/) on mobile

Standard combo: email/password + Google + Apple. iOS apps shipping third-party sign-in must offer Apple sign-in (Apple's policy). MFA enrollment via Identity Platform; pair with [security-engineer overlay](/stacks/firebase/security-engineer/) for the privileged-role MFA discipline.

### [Crashlytics](/stacks/firebase/crashlytics/)

**The integration that always-almost-works.** The failure mode is "stack traces show hex addresses instead of source file:line." Cause: symbols not uploaded for that build.

- **iOS:** dSYM upload via build-phase script (recommended) or CI `firebase crashlytics:symbols:upload`. Bitcode-stripped dSYMs need download-from-App-Store-Connect handling.
- **Android NDK:** native symbol upload via `./gradlew app:uploadCrashlyticsSymbolFileRelease` after configuring `nativeSymbolUploadEnabled = true`.
- **RN with Hermes:** upload `index.android.bundle.map` and `main.jsbundle.map` to Crashlytics.
- **Flutter:** Dart obfuscation maps via `flutterfire crashlytics symbols upload`.

Best practices: `setUserID(uid)` (NOT email/phone — PII), breadcrumbs for state transitions, custom keys for app state, sparing non-fatal `recordError`, verify symbolicated reports after every release.

### [FCM (Cloud Messaging)](/stacks/firebase/fcm/)

HTTP v1 only. Notification messages vs data messages — the most common bug is "why doesn't my onMessage fire when backgrounded?" because the team sent notification-only. Use data or combined.

iOS gotchas: APNs auth key (`.p8`) over certificates, `content-available: true` for silent data messages, `mutable-content: true` for Notification Service Extensions, `apns-priority` 10 (visible) vs 5 (background).

Android gotchas: notification channels required Android 8+, POST_NOTIFICATIONS permission Android 13+, `WorkManager` for non-trivial background work, `priority: high` to defeat Doze on user-facing notifications.

Token management: tokens rotate (reinstall, data clear, OS); listen for refresh, send to backend keyed to UID, periodically re-sync. Clean up on `UNREGISTERED` / `INVALID_ARGUMENT` errors.

### [App Check](/stacks/firebase/app-check/) on mobile

App Attest (iOS 14+) with DeviceCheck fallback; Play Integrity on Android. Debug provider gated behind `#if DEBUG` / `BuildConfig.DEBUG`. Replay Protection (`consumeAppCheckToken: true`) on every mutating callable.

Staged rollout: install in clients → enable in console as unenforced → wait a release cycle → enforce. Skipping the shadow period locks out older app versions.

### [Test Lab](/stacks/firebase/firebase-test-lab/)

Real-device matrix. Robo Test for smoke. Instrumentation tests for full coverage. Game Loop for games. **Device matrix narrowing post-2024** — check current device list before committing a CI matrix. Not a substitute for TestFlight / Play internal testing.

### [App Distribution](/stacks/firebase/app-distribution/)

Sideloaded test builds. Pair with TestFlight / Play internal tracks. CI integration via `firebase appdistribution:distribute`.

### [Firebase Analytics (GA4)](/stacks/firebase/firebase-analytics/)

**Same SKU as GA4.** Use predefined event names for free dashboards. **No PII** in user properties (subscription_tier, signup_year — yes; email, phone — no). Consent Mode v2 required for EEA. Apple ATT governs IDFA availability; without consent, falls back to SKAdNetwork.

### [Performance Monitoring](/stacks/firebase/performance-monitoring/)

Auto-captures app start, screen rendering, network. Custom traces for critical user paths. Cloud Trace integration shows end-to-end mobile → backend.

### [Remote Config](/stacks/firebase/remote-config/) + [A/B Testing](/stacks/firebase/ab-testing/)

Feature flags, kill switches, paywall variants. Server-driven UI strings (occasionally). NOT a database — eventually-consistent + fetch latency + quotas.

### [Cloud Firestore](/stacks/firebase/cloud-firestore/) + [Cloud Storage](/stacks/firebase/firebase-storage/)

Client SDK with offline persistence. Detach listeners in `onDisappear` / `onPause`. Storage uploads via the native SDK; consume via the URL pattern in backend overlays.

### [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) on-device Gemini Nano

Where the platform supports it — newer Android with AICore service; Apple Intelligence-capable devices for some flows. Sub-100ms latency, free per call, on-device privacy. Smaller model, shorter context. Pattern: try on-device first, fall back to cloud.

## 2025-2026 platform-reset items relevant to mobile-architect

- **FCM legacy server APIs are gone.** HTTP v1 + OAuth-scoped service account.
- **App Check Replay Protection GA.** Enable on every mutating callable.
- **Apple Privacy Manifests** required since 2024 — Firebase publishes its own; incorporate.
- **Crashlytics RN/Flutter symbolication** reliably works in 2026 when maps uploaded.
- **Firebase Analytics = GA4** — same data plane. Consent Mode v2 + ATT compliance.
- **Vertex AI in Firebase → Firebase AI Logic.** iOS class `FirebaseAI` replaces `FirebaseVertexAI`.
- **Firestore vector search** is in mobile SDKs — `findNearest` from iOS / Android / Flutter / RN.

## Patterns

### SDK init order (iOS Swift)

```swift
@main
struct MyApp: App {
  init() {
    let providerFactory = AppCheckProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)   // BEFORE configure
    FirebaseApp.configure()
  }
  var body: some Scene { WindowGroup { ContentView() } }
}
```

### SDK init (Android Kotlin)

```kotlin
class MyApp : Application() {
  override fun onCreate() {
    super.onCreate()
    Firebase.appCheck.installAppCheckProviderFactory(
      PlayIntegrityAppCheckProviderFactory.getInstance()
    )
  }
}
```

### Flutter setup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
  );
  runApp(MyApp());
}
```

### TDD on mobile Firebase

| Layer | Tool |
|-------|------|
| Pure logic (view models, services) | XCTest / JUnit / Dart test / Jest |
| Firebase data layer (against emulator) | [Local Emulator Suite](/stacks/firebase/emulator-suite/) + native SDK pointed at emulator |
| End-to-end UI flows | XCUITest / Espresso / `integration_test` / Detox |
| Device matrix smoke | [Test Lab](/stacks/firebase/firebase-test-lab/) |
| Production canary | [App Distribution](/stacks/firebase/app-distribution/) → beta group → store rollout |

Mobile SDKs all support pointing at the emulators (`Auth.auth().useEmulator(...)`, `Firestore.firestore().useEmulator(...)`).

### Verification checklist

- [ ] Crashlytics symbolicated on the latest release build (verified in console)
- [ ] Test Lab device matrix current
- [ ] App Check enforced on production; debug provider gated
- [ ] FCM tested with notification + data + combined payloads on real device, foreground + background
- [ ] Analytics events match GA4 schema; no PII in user properties
- [ ] Consent Mode v2 wired for EEA users
- [ ] ATT request flow tested on iOS, with and without consent

### Debugging

- **Push not arriving?** Check: FCM token registered, APNs auth key valid, payload type (notification vs data), notification channel (Android), POST_NOTIFICATIONS permission (Android 13+), Doze mode, token rotation.
- **Crash not symbolicated?** Check: dSYM uploaded, NDK symbols, RN source map, Flutter obfuscation map, App Store re-symbolication.
- **App Check rejecting valid clients?** Check: provider matches platform, debug token registered in dev, app signed correctly.
- **Analytics events not appearing?** Check: Consent Mode, ATT, debug view enabled, event name limits.

## Mobile-specific Firebase footguns

- **dSYMs not uploading silently** — symbolicated reports never appear.
- **`FirebaseApp.configure()` before `setAppCheckProviderFactory`** — first calls unauthenticated.
- **Notification message expecting `onMessage` to fire** when backgrounded — won't.
- **IDFA / email / phone as user property** — GA4 rejects; Apple flags.
- **Topic subscription from client without rate limits** — binary leak = bot subscription.
- **Forgetting notification channels on Android 8+** — silently dropped.
- **Forgetting POST_NOTIFICATIONS on Android 13+** — same.
- **Test Lab as your only test environment** — too slow for fast CI; not a unit-test substitute.
- **App Check enforced before users upgraded** — older versions locked out.
- **Debug App Check provider shipping to prod** — backdoor.
- **`setUserID(email)`** — PII leak into crash reports.
- **Long-lived `getDownloadURL()`** for user uploads — un-revocable.
- **Firestore listeners attached without lifecycle awareness** — leak when the user navigates away; battery drain.
- **Firebase JS Web SDK in a production RN app** — `@react-native-firebase/*` handles background message delivery and crashes the Web SDK can't.

## Cross-references

- [backend-architect overlay](/stacks/firebase/backend-architect/) — server-side FCM sending; Cloud Functions integration
- [frontend-architect overlay](/stacks/firebase/frontend-architect/) — web Auth UX parity
- [security-engineer overlay](/stacks/firebase/security-engineer/) — App Check + Identity Platform MFA discipline
- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — Genkit + AI Logic from mobile clients
- [Firebase stack index](/stacks/firebase/) — products + role overlay map
