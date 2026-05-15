---
title: App Check
description: Per-request attestation that traffic comes from your authentic app — App Attest (iOS), Play Integrity (Android), reCAPTCHA Enterprise (web). Replay Protection GA 2024.
product:
  name: App Check
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, frontend-architect, mobile-architect, backend-architect]
  authoritative_url: https://firebase.google.com/docs/app-check
  notes: "Replay Protection GA 2024; required for production-grade hardening of every Firebase backend service."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

App Check verifies that requests to your Firebase backends come from your authentic app — not an unauthorized client, scraper, or emulator. Without App Check, anyone with your project ID can hit your Firestore, Functions, Storage, RTDB, Data Connect, and AI Logic endpoints. **The project ID is not a secret.**

App Check is the second leg of the Firebase security stool ([Security Rules](/stacks/firebase/security-rules/) being the first). Rules enforce auth + authorization; App Check enforces "this is my app talking, not a script."

Canonical reference: [App Check docs](https://firebase.google.com/docs/app-check).

## When to use it

**Use App Check on every privileged backend in production:**

- Cloud Functions (callable functions)
- Cloud Firestore
- Realtime Database
- Cloud Storage for Firebase
- Firebase Data Connect
- Firebase AI Logic
- Firebase Authentication (anti-abuse for sign-up/sign-in)
- Cloud Messaging (FCM) — for token registration

Skip App Check only on **truly public read endpoints** (e.g., a public marketing landing page reading a `public/` collection), and document why.

## 2025-2026 currency anchors

- **Replay Protection GA** (2024) — single-use App Check tokens via `consumeAppCheckToken: true` on callable functions. Defends against captured-token replay.
- **App Attest + DeviceCheck** for iOS (App Attest is iOS 14+; DeviceCheck for older).
- **Play Integrity** for Android (replaces SafetyNet, which is now sunset).
- **reCAPTCHA Enterprise** is the production-grade web provider; v3 still works but Enterprise has adaptive thresholds and better fraud signals.

## Provider matrix

| Platform | Production provider | Debug provider |
|----------|---------------------|----------------|
| iOS | **App Attest** (iOS 14+) with **DeviceCheck** fallback | Debug provider for simulator |
| Android | **Play Integrity** | Debug provider for emulator |
| Web | **reCAPTCHA Enterprise** (or v3 legacy) | Debug provider |
| Flutter | Per-platform combo | Debug provider |

## Enforcement modes

| Mode | What it does | When to use |
|------|--------------|-------------|
| **Disabled** | No checking | Never in production |
| **Monitoring** (unenforced) | Tokens validated; failures logged but not blocked | Initial rollout; size impact |
| **Enforced** | Failures blocked | Production target |

## Patterns

### iOS setup

```swift
import FirebaseCore
import FirebaseAppCheck

@main
struct MyApp: App {
  init() {
    #if DEBUG
    let providerFactory = AppCheckDebugProviderFactory()
    #else
    let providerFactory = AppCheckProviderFactory()
    #endif
    AppCheck.setAppCheckProviderFactory(providerFactory)
    FirebaseApp.configure()
  }
}

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

**Critical:** `setAppCheckProviderFactory` must run **before** `FirebaseApp.configure()`. Otherwise Firebase services init without App Check; first network calls go out unprotected.

### Android setup

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

### Web setup

```ts
import { initializeAppCheck, ReCaptchaEnterpriseProvider } from "firebase/app-check";

initializeAppCheck(app, {
  provider: new ReCaptchaEnterpriseProvider("RECAPTCHA_ENTERPRISE_KEY"),
  isTokenAutoRefreshEnabled: true,
});
```

### Debug providers — gate them

```swift
#if DEBUG
let providerFactory = AppCheckDebugProviderFactory()
#else
let providerFactory = AppCheckProviderFactory()
#endif
```

```ts
if (process.env.NODE_ENV === "development") {
  // @ts-ignore
  self.FIREBASE_APPCHECK_DEBUG_TOKEN = true;
}
```

The debug provider mints a token; paste it into Firebase Console → App Check → Debug tokens for development. **A debug provider in a production build is a backdoor.**

### Replay Protection on callable functions

```ts
export const charge = onCall(
  { enforceAppCheck: true, consumeAppCheckToken: true },
  async (req) => { /* ... */ }
);
```

`consumeAppCheckToken: true` makes the token single-use — captured tokens can't be replayed. Enable on every callable that mutates state, charges money, or calls expensive backends (Gemini, search).

### Staged rollout

1. **Add SDK to clients**, ship a release with App Check installed but not enforcing.
2. **Enable App Check in console** for each service in **"unenforced" / monitoring mode**. Watch valid-vs-invalid request counts.
3. **Wait at least a release cycle** (so users update). Watch for clients failing App Check that shouldn't be.
4. **Enable enforcement** once unauthorized ratio is consistently near zero.

Skipping the unenforced shadow period is how teams break their own apps.

### App Check on AI Logic specifically

[Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) exposes Gemini directly to clients. Each call costs real money. Without App Check, a leaked client config + a botnet = a five-figure Gemini bill in hours. **Enforce App Check on AI Logic before going to production. Always.**

## Anti-patterns

- **App Check off "until we figure out the rollout"** — the rollout is a release-cycle problem, not a security-architecture problem. Plan it.
- **Debug provider not gated** — a debug App Check token is forgeable; if production accepts them, you have no App Check.
- **Enforcement enabled before users upgraded** — older app versions locked out.
- **No monitoring period** — you discover edge-case failures in prod outage form.
- **Skipping App Check on "internal-only" endpoints** — internal endpoints leak; project IDs leak; assume hostile.

## Gotchas

- **App Attest assertions can be consumed once** (when Replay Protection is on) — the client SDK handles minting fresh tokens automatically.
- **`setAppCheckProviderFactory` before `FirebaseApp.configure()`** — order matters on iOS.
- **Debug tokens are per-device + per-install** — re-paste after reinstall.
- **reCAPTCHA Enterprise key is bound to specific domains** — preview channels need their domains added.
- **Play Integrity quota** — high-traffic apps may need a quota increase from Google Play.
- **Niche devices may fail Play Integrity** — monitor the failure rate; whitelist if needed.

## Cross-references

- [Security Rules](/stacks/firebase/security-rules/) — `request.app != null` checks
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — `enforceAppCheck` + `consumeAppCheckToken`
- [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) — App Check critical for Gemini billing protection
- [security-engineer overlay](/stacks/firebase/security-engineer/#app-check) — full setup checklist
- [mobile-architect overlay](/stacks/firebase/mobile-architect/#app-check) — mobile-specific rollout
- Authoritative: [firebase.google.com/docs/app-check](https://firebase.google.com/docs/app-check)
