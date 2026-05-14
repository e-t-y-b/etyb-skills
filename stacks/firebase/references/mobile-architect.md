---
role: mobile-architect
stack: firebase
last_verified_on: "2026-05-14"
---

# Firebase Overlay — mobile-architect

You are mobile-architect on a Firebase engagement. The mobile surface is where Firebase historically earned its keep — Crashlytics, FCM, App Check, Analytics, Test Lab, App Distribution — and where the integration depth is highest. Most non-trivial mobile apps integrate at least five Firebase SDKs. Get the integration discipline wrong and you ship apps with bad symbolication, dropped pushes, broken App Check on edge devices, or PII leaking through Analytics.

**Currency:** 2026 Q2. iOS 17+ / Android 14+ device baselines, Firebase SDKs current to platform-versioned releases, FCM HTTP v1 only, App Check Replay Protection enabled by default on new project setups.

## What changed in 2025-2026 that older mobile training data misses

- **FCM legacy server APIs are gone.** `fcm.googleapis.com/fcm/send` and the XMPP server API are deprecated. Production traffic must use **FCM HTTP v1** (`fcm.googleapis.com/v1/projects/.../messages:send`) or the Admin SDK. Code referencing "Server Key" in cleartext is legacy — replace with the v1 endpoint + OAuth-scoped service account.
- **App Check Replay Protection** (GA 2024) — single-use tokens for callable functions and other Firebase backends. Mobile SDKs (Play Integrity on Android, App Attest on iOS, DeviceCheck on older iOS) integrate transparently; you turn on `consumeAppCheckToken` server-side.
- **Apple privacy manifests** (mandatory for App Store submission since 2024) require declaring SDK usage of "required reason" APIs. Firebase publishes its own manifests; you still need to incorporate them into your app's combined manifest.
- **Crashlytics on RN + Flutter** now reliably symbolicates JS and Dart stack traces if you upload source maps / obfuscation maps. Pre-2023, this was a known weak spot — fixed.
- **Firebase Analytics is GA4.** The "Firebase Analytics" name persists in SDK class names; the data lives in GA4. Consent Mode v2 (2024) is the current consent integration; older "analytics enabled? yes/no" toggles don't capture the granularity advertisers and regulators now require.
- **Apple ATT (App Tracking Transparency)** controls whether `IDFA` is available to Analytics; without ATT consent, attribution and SKAdNetwork take over. Don't bake IDFA-dependent flows into your app without the consent path.
- **Firebase AI Logic** on-device Gemini Nano (where available) — a 2025 addition for mobile-architect to know about (it lives in the ai-ml-engineer overlay; the mobile-architect dimension is "this is now a Firebase mobile SDK").

If you see code calling FCM with a `Server Key` header, manually setting `userId` in Analytics for IDFA targeting without ATT, uploading dSYMs only on release builds (not all builds), or wiring App Check without Replay Protection — you're on stale knowledge.

## SDK installation discipline across platforms

### iOS (Swift)

Swift Package Manager is the canonical install path. The `firebase-ios-sdk` package exposes one product per SDK:

- `FirebaseCore` (always)
- `FirebaseAuth`
- `FirebaseFirestore` / `FirebaseFirestoreSwift`
- `FirebaseStorage`
- `FirebaseMessaging`
- `FirebaseAnalytics`
- `FirebaseCrashlytics`
- `FirebasePerformance`
- `FirebaseAppCheck`
- `FirebaseRemoteConfig`
- `FirebaseAI` (formerly `FirebaseVertexAI`, renamed with the Firebase AI Logic rebrand)

Initialize once at app start:

```swift
import FirebaseCore
import FirebaseAppCheck

@main
struct MyApp: App {
  init() {
    let providerFactory = AppCheckProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)
    FirebaseApp.configure()
  }
  var body: some Scene { WindowGroup { ContentView() } }
}
```

**Critical**: `AppCheck.setAppCheckProviderFactory(...)` must run **before** `FirebaseApp.configure()`. Otherwise Firebase services initialize without App Check, and the first network calls go out unprotected.

### Android (Kotlin)

Gradle dependencies via the Firebase BoM:

```kotlin
dependencies {
  implementation(platform("com.google.firebase:firebase-bom:33.x.x"))
  implementation("com.google.firebase:firebase-auth-ktx")
  implementation("com.google.firebase:firebase-firestore-ktx")
  implementation("com.google.firebase:firebase-messaging-ktx")
  implementation("com.google.firebase:firebase-analytics-ktx")
  implementation("com.google.firebase:firebase-crashlytics-ktx")
  implementation("com.google.firebase:firebase-perf-ktx")
  implementation("com.google.firebase:firebase-appcheck-playintegrity")
  implementation("com.google.firebase:firebase-config-ktx")
  implementation("com.google.firebase:firebase-ai")
}
```

The BoM pins compatible versions across the SDK family. Don't pin individual SDK versions outside the BoM unless you have a deliberate reason — version skew across Firebase SDKs causes obscure runtime issues. Initialize in `Application.onCreate()`:

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

Apply the `com.google.gms.google-services` Gradle plugin and the `com.google.firebase.crashlytics` Gradle plugin in the app-module `build.gradle.kts`.

### Flutter (Dart)

`flutterfire_cli` is the canonical setup tool:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `firebase_options.dart` per platform. Use:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
  );
  runApp(MyApp());
}
```

### React Native

`@react-native-firebase/*` packages. Native-bridge SDKs — you get the same API across iOS and Android, but you're managing iOS Pods + Android Gradle. Auto-linking handles most of it; verify on each new SDK addition.

Install pattern:

```bash
npm i @react-native-firebase/app @react-native-firebase/auth @react-native-firebase/firestore @react-native-firebase/messaging @react-native-firebase/crashlytics @react-native-firebase/analytics @react-native-firebase/app-check
cd ios && pod install
```

For RN apps, **prefer the `@react-native-firebase/*` packages over the JS Web SDK** — the native SDKs handle background message delivery, native crash reporting, etc. The Web SDK is a fallback for Expo Go / web targets only.

## Crashlytics — the integration that always-almost-works

Crashlytics is the most-used Firebase mobile SDK and the most likely to silently fail. The failure mode is "stack traces show hex addresses instead of source file:line." Cause: symbols not uploaded for that build.

### iOS — dSYM upload discipline

Two paths to upload dSYMs:

1. **Build-phase script** (recommended) — runs on every build, uploads dSYMs to Firebase automatically. Add this Run Script Phase to your app target, after the "Embed Frameworks" phase:

```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

Set `Input Files` to include `$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)`. Set `Output Files` so Xcode doesn't re-run on every clean build.

2. **CI upload via `upload-symbols`** (for cases where you build without Xcode build phases — e.g., archive-only CI flows). Use `firebase crashlytics:symbols:upload --app=<app-id> path/to/dsyms` from `firebase-cli`, or the `upload-symbols` binary directly.

### iOS — Bitcode-stripped dSYMs

If your app uses Bitcode (declining as Apple deprecates Bitcode, but still possible), App Store Connect re-symbolicates after upload and the dSYMs you submit aren't the ones used. You must download the post-processing dSYMs from App Store Connect → Activity → Build Number → Download dSYMs, then upload to Crashlytics. Set this up as a CI step if you use Bitcode.

### Android — NDK symbol upload

Pure Kotlin/Java apps get symbols automatically via the Crashlytics Gradle plugin. **NDK code** (any native `.so` library — your own C/C++ code, or third-party native deps like a video codec) needs its native debug symbols uploaded separately:

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

Without this, NDK crashes (the worst kind to debug) show as raw addresses.

### React Native and Flutter — JS / Dart stack trace symbolication

- **RN with Hermes:** upload `index.android.bundle.map` and `main.jsbundle.map` to Crashlytics for symbolicated JS frames. `@react-native-firebase/crashlytics` exposes a helper; otherwise upload via the Crashlytics CLI.
- **Flutter:** Dart obfuscation maps (`--split-debug-info=...`) must be uploaded for release builds. `flutterfire crashlytics symbols upload` (Flutter-specific) or `firebase crashlytics:symbols:upload` covers it.

### Crashlytics best practices

- **Set userId** to the Firebase Auth UID after sign-in: `Crashlytics.crashlytics().setUserID(uid)`. **Do NOT** set userId to email, phone number, or any direct PII. The UID is opaque.
- **Add breadcrumbs** for state transitions: `crashlytics().log("Entering checkout step \(step)")`. Breadcrumbs are kept in a ring buffer and attached to crashes — they're the difference between "the app crashed" and "the app crashed after the user tried to confirm a $0 payment with no items."
- **Custom keys** for app state: `crashlytics().setCustomValue("subscription_tier", "pro")`. Useful for filtering crash reports.
- **Non-fatal recording**: `crashlytics().recordError(error)` for caught exceptions that you want surfaced for visibility without crashing the app. Use sparingly — every recorded error counts toward the daily Crashlytics quota.
- **Verify symbolicated reports** after every release. Open a recent crash; the stack trace should show `Sources/MyModule/MyFile.swift:42` or `app/src/main/java/com/me/MyFile.kt:42`, not `0x1029384a8`.

## Firebase Cloud Messaging (FCM)

### Architecture refresher

Push notifications on mobile flow through **APNs** (Apple) or **FCM/Android** (Google). Firebase abstracts both behind one API. Sending: server → FCM → APNs/FCM → device. Receiving: device → SDK handler.

### Two message types — get this right

| Type | Body shape | Behavior when app is in background |
|------|------------|-------------------------------------|
| **Notification message** | `notification: { title, body, ... }` | OS displays the notification automatically; your `onMessage` handler does NOT fire. |
| **Data message** | `data: { custom: "fields" }` | OS does NOT display anything; your `onMessage` handler fires (iOS: requires `content-available: true`). |
| **Combined** | Both `notification` + `data` | OS displays notification AND handler fires (sort of — depends on platform). |

**The most common FCM bug:** "Why doesn't my onMessage fire when the app is backgrounded?" Cause: you sent a notification-only message. The OS rendered the notification; your code never ran. Fix: send a data message (or both), and handle display yourself if needed.

### iOS-specific FCM gotchas

- **APNs token registration must complete before FCM can deliver.** `Messaging.messaging().delegate = self` and call `UIApplication.shared.registerForRemoteNotifications()` early.
- **APNs auth key (`.p8`)** is the modern auth method. Upload once to Firebase Console (Cloud Messaging tab); it covers all your apps in the team. Old "APNs certificates" still work but expire annually and are a maintenance burden — migrate to auth keys.
- **`content-available: true`** for silent / background data messages. iOS rate-limits these aggressively (a few per hour per app); FCM won't queue them indefinitely.
- **`mutable-content: true`** if you want a Notification Service Extension to modify the payload (e.g., download an image to display in the notification).
- **`apns_priority: 10`** for user-visible notifications; `apns_priority: 5` for background data messages. Wrong priority → iOS throttles your push.

### Android-specific FCM gotchas

- **Notification channels** (Android 8+) are required for displayed notifications. Create channels at app start; assign each notification to a channel. Without a channel, the notification is silently dropped on Android 8+.
- **POST_NOTIFICATIONS permission** is required on Android 13+. Runtime permission request; without it, notifications don't display.
- **Background work** — if your data message handler does meaningful work, run it via `WorkManager`, not directly in the FCM callback. FCM gives you ~10 seconds before the OS may terminate the process.
- **Power-saving modes (Doze)** can delay non-`high-priority` messages indefinitely. Set `priority: high` in the FCM payload for user-facing notifications.

### Sending FCM messages — the v1 API

```bash
# Get an OAuth access token via your service account
curl -X POST https://fcm.googleapis.com/v1/projects/PROJECT_ID/messages:send \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_TOKEN",
      "notification": { "title": "Hello", "body": "World" },
      "android": { "priority": "high", "notification": { "channel_id": "default" } },
      "apns": {
        "headers": { "apns-priority": "10" },
        "payload": { "aps": { "alert": { "title": "Hello", "body": "World" }, "sound": "default" } }
      }
    }
  }'
```

In Cloud Functions, use `getMessaging().send(message)` from the Admin SDK — it handles auth automatically.

### Topic subscriptions

For broadcast-style messaging:

```kotlin
Firebase.messaging.subscribeToTopic("news-en-us")
```

```ts
await getMessaging().send({ topic: "news-en-us", notification: {...} });
```

Topic sends are great for "all users opted into category X." Limitations: topic sends are best-effort, not guaranteed delivery; subscription propagation can take minutes. For one-to-one critical messages, send to device tokens directly.

### Token management

Device tokens are not stable forever — they rotate when the app is reinstalled, when the user clears app data, when iOS / Android decides. Every app should:

1. Listen for token refresh events
2. Send the new token to your backend, keyed to the current Firebase Auth UID
3. Periodically (e.g., on app start) re-sync the token to handle missed refresh events

Stale tokens cause "we sent the push, the user never saw it" bugs. FCM returns `UNREGISTERED` or `INVALID_ARGUMENT` for stale tokens — clean them up in your DB when you see those error codes.

## App Check

App Check verifies that requests to your Firebase backends are coming from your authentic app (not an unauthorized client, scraper, or emulator). Without App Check, anyone with the project ID can hit your Firestore, Functions, Storage, RTDB, Data Connect, and AI Logic endpoints.

### Provider matrix

| Platform | Production provider | Debug provider |
|----------|---------------------|----------------|
| iOS | **App Attest** (iOS 14+) with **DeviceCheck** fallback (iOS 11-13) | Debug provider for simulator + dev |
| Android | **Play Integrity** | Debug provider for emulator + dev |
| Web | **reCAPTCHA Enterprise** (or v3 legacy) | Debug provider |
| Flutter | Per-platform combo of above | Debug provider |

### Setup pattern

iOS:

```swift
let providerFactory = AppCheckProviderFactory()
AppCheck.setAppCheckProviderFactory(providerFactory)
FirebaseApp.configure()

class AppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    if #available(iOS 14.0, *) {
      return AppAttestProvider(app: app)
    } else {
      return DeviceCheckProvider(app: app)
    }
  }
}
```

Android:

```kotlin
Firebase.appCheck.installAppCheckProviderFactory(
  PlayIntegrityAppCheckProviderFactory.getInstance()
)
```

### Debug providers in dev — get the env-fence right

In development, App Attest and Play Integrity fail (your app isn't signed/distributed through the store). Use the debug provider:

```swift
#if DEBUG
let providerFactory = AppCheckDebugProviderFactory()
#else
let providerFactory = AppCheckProviderFactory()
#endif
AppCheck.setAppCheckProviderFactory(providerFactory)
```

The debug provider logs a debug token to the console on first run; paste it into Firebase Console → App Check → Debug tokens. The console only accepts the token for development apps — production apps with the debug provider enabled fail validation server-side.

**Critical**: ship debug providers behind `#if DEBUG` / `BuildConfig.DEBUG`. A debug provider in a production build is a backdoor.

### Replay Protection (2024)

App Check tokens are normally short-lived but reusable within their validity window. **Replay Protection** makes tokens single-use:

- Client-side: no change needed — the SDK mints a fresh token per request when Replay Protection is enabled server-side.
- Server-side: `consumeAppCheckToken: true` on callable functions. For Firestore / Storage / RTDB / Data Connect, Replay Protection is enforced when the rule expression checks `request.app != null && request.app.app_check_token.replay_protected == true` — but most callers should rely on the SDK's automatic handling.

Enable Replay Protection on every callable function that mutates state or accesses sensitive data. The cost is a minor token-mint overhead per call; the benefit is captured tokens are useless.

### Rolling out App Check — the staged path

1. **Add SDK to mobile clients**, ship a release that has App Check installed but not enforcing.
2. **Enable App Check in Firebase Console** for each service (Firestore, Functions, Storage, RTDB, Data Connect, AI Logic) in **"unenforced" / monitoring mode**. Console will show you valid-vs-invalid request counts.
3. **Wait at least a release cycle** (so users on older app versions update). Watch for clients failing App Check that shouldn't be (e.g., a niche device that doesn't pass Play Integrity).
4. **Enable enforcement** once the unauthorized ratio is consistently near zero.

Skipping the unenforced shadow period is how teams break their own apps. Don't.

## Firebase Analytics + GA4

### The big mental shift

"Firebase Analytics" SDK → events flow to **GA4** for storage, querying, attribution, dashboards. The SDK is a mobile-friendly client; GA4 is the data plane. Don't think of them as two products.

### Event discipline

```swift
Analytics.logEvent(AnalyticsEventBeginCheckout, parameters: [
  AnalyticsParameterCurrency: "USD",
  AnalyticsParameterValue: 42.99,
  AnalyticsParameterItems: items,
])
```

Use the **predefined event names** (`AnalyticsEventBeginCheckout`, `add_to_cart`, etc.) when they fit your domain — they get free GA4 dashboards. Custom events are fine for app-specific actions (`level_completed`, `paywall_shown`).

**Parameter limits:**
- 25 event parameters per event
- 100-character parameter name max
- 100-character string value max
- 50 custom event types per project (the default; can be raised)

### User properties — the privacy-critical surface

```swift
Analytics.setUserProperty("pro", forName: "subscription_tier")
```

User properties persist for the user across sessions. **Never set PII as a user property.** No emails, phone numbers, names, exact location. Use only enums/buckets:

- `subscription_tier`: `free` / `pro` / `enterprise` ✓
- `signup_year`: `2024` ✓
- `email`: `user@example.com` ✗ — GA4 will reject and flag, but the SDK has already transmitted before rejection

Firebase Analytics has built-in PII detection that rejects obvious patterns (email, US SSN, phone numbers). It is not a substitute for not sending PII in the first place.

### Consent Mode v2 (2024 — required for EEA traffic)

```swift
Analytics.setConsent([
  .analyticsStorage: .granted,
  .adStorage: .denied,
  .adUserData: .denied,
  .adPersonalization: .denied,
])
```

Set consent before logging events. With analytics consent granted but ad consent denied, GA4 receives the event but does not use it for ad personalization. Required for compliance with EEA / UK / Swiss privacy regimes.

### Apple ATT (App Tracking Transparency)

If you want IDFA-based attribution / personalization on iOS, request ATT:

```swift
import AppTrackingTransparency

ATTrackingManager.requestTrackingAuthorization { status in
  // ...
}
```

Without ATT consent (`.authorized`), `IDFA` is `00000000-0000-0000-0000-000000000000` and Analytics falls back to **SKAdNetwork** for attribution. Don't gate features on having IDFA — most users won't grant it.

## Performance Monitoring

### Automatic + custom traces

The SDK auto-captures:
- **App start time** (cold/warm/hot)
- **Screen rendering** (slow frames, frozen frames)
- **HTTP/HTTPS network requests** (latency, payload size, success rate)

Custom traces for your own work:

```swift
let trace = Performance.startTrace(name: "checkout_flow")
trace?.incrementMetric("retries", by: 1)
trace?.setValue("pro", forAttribute: "user_tier")
// ... work ...
trace?.stop()
```

Custom traces appear alongside auto traces in the console. Use them for any user-facing critical path you care about latency on (search, checkout, login, etc.).

### Performance Monitoring + Cloud Trace integration

Performance Monitoring traces now flow to **Cloud Trace** (2024-2025), giving you a unified view across mobile, web, and Cloud Functions. A user's slow checkout starting on mobile, hitting your Cloud Function, querying Firestore — you can see the full trace in Cloud Trace UI. Useful for any case where the bottleneck might be server-side, not client-side.

## Test Lab

Real-device test matrix in Google's lab. Use cases:

- **Smoke tests on real devices** before submitting to stores. Robo Test crawls your UI automatically; useful for catching null pointer / null check regressions in lightly-trafficked screens.
- **Instrumentation tests on the device matrix** (Espresso / XCUITest). Use Test Lab when you need to run your existing test suite across a real device matrix.
- **Game Loop tests** for games — your app runs in a loop mode and reports its own metrics.

Device matrix has been narrowing post-2024 — old devices age out faster than they used to. **Check the current device list before committing to a CI device matrix.** A test matrix that worked 12 months ago may include retired devices today.

Test Lab is **not** a substitute for:
- TestFlight / Play internal testing (real human testers)
- Crashlytics in production (real users on a real device population)
- Unit/integration tests (run those in CI, not Test Lab — Test Lab is too slow for fast CI loops)

## App Distribution

Sideloading test builds to a known tester pool. Faster iteration than TestFlight (no review wait); but no production-readiness check.

```bash
firebase appdistribution:distribute path/to/app.aab \
  --app=APP_ID \
  --groups=qa,beta \
  --release-notes-file=RELEASE_NOTES.md
```

Useful for nightly builds to QA, weekly builds to wider beta. Pair with App Distribution iOS/Android SDK if you want the app to prompt for available updates in-app. **Not a replacement** for proper store readiness — TestFlight catches issues App Distribution doesn't (in-app purchase flows, push entitlements, App Review).

## Remote Config + A/B Testing — mobile-side

Remote Config lets you change values in your app without shipping a new build:

```swift
let rc = RemoteConfig.remoteConfig()
let settings = RemoteConfigSettings()
settings.minimumFetchInterval = 3600  // 1h; lower in dev
rc.configSettings = settings
rc.setDefaults([
  "show_new_paywall": false as NSObject,
  "paywall_button_text": "Subscribe" as NSObject,
])

try await rc.fetchAndActivate()

let showNewPaywall = rc.configValue(forKey: "show_new_paywall").boolValue
```

Use cases:
- **Kill switch** for risky features (`feature_x_enabled`)
- **Per-region config** (`payment_methods` differs by user country, served by Remote Config conditions)
- **A/B test variant selection** (paired with A/B Testing in console)
- **Server-driven UI strings** (less common — usually localized in-bundle)

A/B Testing in the console lets you run an experiment: variant A vs variant B, with a target metric tracked via GA4. The Remote Config keys vary by variant; analysis happens in the console.

**Anti-pattern:** treating Remote Config as a database. It's eventually-consistent, has fetch latency, has a quota. For real-time data, use Firestore / RTDB.

## Mobile-specific Firebase footguns

- **dSYMs not uploading silently** — symbolicated reports never appear; verify after every release.
- **`FirebaseApp.configure()` called before `setAppCheckProviderFactory`** — first network calls go unauthenticated.
- **Notification message sent expecting `onMessage` to fire** — won't, when app is backgrounded.
- **Sending raw IDFA / email / phone as a user property** — GA4 rejects; Apple's privacy review flags; remediation is painful.
- **Subscribing to FCM topics from the client without rate limits** — bots can subscribe to your topics if the app's binary leaks. Topic subscription should be gated by an authenticated server call where it matters.
- **Forgetting to register notification channels on Android 8+** — notifications silently dropped.
- **Forgetting to request POST_NOTIFICATIONS permission on Android 13+** — same.
- **Test Lab as your only test environment** — too slow for fast CI, not a substitute for unit tests.
- **App Check enforced before the userbase upgraded to the App Check-enabled build** — older app versions are locked out.
- **Debug App Check provider shipping to production builds** — backdoor.
- **Crashlytics `setUserID(email)`** — PII leak into crash reports.
- **Long-lived `getDownloadURL()`** on user-uploaded images — un-revocable public URLs; use server-signed URLs.
- **Firestore listeners attached without lifecycle awareness** — leak when the user navigates away; battery drain. Detach in `onDisappear` / `onPause`.
- **Firebase JS Web SDK in a RN app** — the native SDK packages (`@react-native-firebase/*`) handle background message delivery and crashes that the Web SDK can't.

## Integration with always-on protocols

### TDD on mobile Firebase

| Layer | Tool |
|-------|------|
| Pure logic (view models, services) | XCTest / JUnit / Dart test / Jest |
| Firebase data layer (against emulator) | Local Emulator Suite + native SDK pointed at emulator |
| End-to-end UI flows | XCUITest / Espresso / integration_test / Detox |
| Device matrix smoke | Test Lab |
| Production canary | App Distribution → beta group → store rollout |

Mobile SDKs all support pointing at the Local Emulator Suite (`Auth.auth().useEmulator(...)`, `Firestore.firestore().useEmulator(...)`, etc.) — wire it up in your test target / debug build. Unit tests that hit Firebase emulators are fast and reliable.

### Verification

- [ ] Crashlytics symbolicated on the latest release build
- [ ] Test Lab device matrix current
- [ ] App Check enforced on production, debug provider not shipping
- [ ] FCM tested with both notification + data + combined payloads, on real device, foreground + background
- [ ] Analytics events match the GA4 schema; no PII in user properties
- [ ] Consent Mode v2 wired for EEA users
- [ ] ATT request flow tested on iOS, with and without consent

### Debugging

- Push not arriving? Check: FCM token registered, APNs auth key valid, payload type (notification vs data), notification channel (Android), POST_NOTIFICATIONS permission (Android 13+), Doze mode, app uninstalled / reinstalled (token rotated).
- Crash not symbolicated? Check: dSYM uploaded, NDK symbols uploaded, RN source map uploaded, Flutter obfuscation map uploaded, App Store re-symbolication accounted for.
- App Check rejecting valid clients? Check: provider matches platform (App Attest on iOS, Play Integrity on Android), debug token registered in dev, app signed correctly, App Attest assertion not consumed (Replay Protection consideration).
- Analytics events not appearing? Check: Consent Mode, ATT (iOS), debug view enabled in console (events show in real time only in debug view), event name conforms to limits.

## Decision frameworks

### Native SDK vs `@react-native-firebase/*` vs Web SDK in a mobile context

| Scenario | Pick |
|----------|------|
| Pure native iOS/Android | Native SDKs (`firebase-ios-sdk`, `com.google.firebase`) |
| React Native, production app | `@react-native-firebase/*` packages |
| Expo (managed workflow) | Native SDKs via Expo modules where available; `@react-native-firebase/*` requires bare workflow or EAS Dev Client |
| Flutter | `firebase_*` packages from FlutterFire |
| RN web target | Web Modular SDK (`firebase` npm package) |

### Firebase Analytics vs a dedicated product analytics tool (Mixpanel, Amplitude, PostHog)

| Use Firebase Analytics if | Use dedicated analytics if |
|---------------------------|----------------------------|
| You already need GA4 (web parity, ad attribution) | Marketing/ad attribution isn't a primary concern |
| Cost-sensitive (free tier is generous) | Product team needs cohort analysis, funnel builders that GA4 doesn't ship strong |
| Mobile-primary audience | You need rich user-property targeting beyond GA4 |
| Compliance simplicity preferred (one DPA) | Compliance team is OK with another vendor |

Many teams ship both — Firebase Analytics for the ads/attribution side, Mixpanel/Amplitude/PostHog for product analytics. Just don't double-instrument every event by hand; pick a shared event schema and route both ways from a single emitter.

### FCM vs OneSignal / Pusher / Airship

FCM is the substrate. OneSignal et al. *use* FCM/APNs under the hood. They add: better targeting UI, automations, in-app messaging, smarter delivery scheduling. The trade is one more vendor + cost vs Firebase native.

For early-stage apps: just use FCM directly. For marketing-led "send 8 push variants with conversion attribution" workflows, evaluate one of the layered services.

## Cross-references

- Backend FCM sending from Cloud Functions: [`backend-architect.md`](backend-architect.md)
- Security Rules + App Check enforcement: [`security-engineer.md`](security-engineer.md)
- Identity Platform MFA on mobile: [`security-engineer.md`](security-engineer.md#identity-platform)
- Genkit + Firebase AI Logic from mobile clients: [`ai-ml-engineer.md`](ai-ml-engineer.md)
- Firebase JS Modular SDK on web targets / RN web: [`frontend-architect.md`](frontend-architect.md)

## Delegate skills

If the user environment has the Firebase skill suite, defer to:

- [`firebase:firebase-basics`](#) — install + setup per platform
- [`firebase:firebase-auth-basics`](#) — Auth UX on mobile
- [`firebase:firebase-firestore`](#) — client-side queries and offline persistence
- [`firebase:firebase-ai-logic-basics`](#) — on-device Gemini + client-side AI

These delegate skills go deeper on platform-specific syntax than this overlay covers.
