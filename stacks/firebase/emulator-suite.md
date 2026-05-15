---
title: Local Emulator Suite
description: Local emulators for Auth, Firestore, RTDB, Storage, Functions, Pub/Sub, Eventarc, Hosting, Data Connect, Extensions — the only sanctioned way to TDD Firebase.
product:
  name: Local Emulator Suite
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect, mobile-architect, qa-engineer, security-engineer]
  authoritative_url: https://firebase.google.com/docs/emulator-suite
  notes: "Auth, Firestore, RTDB, Storage, Functions, Pub/Sub, Eventarc, Hosting, Data Connect, Extensions all emulated; the only sanctioned way to TDD Firebase."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

The Firebase Local Emulator Suite runs Firebase services locally for development and testing — Auth, Firestore, Realtime Database, Cloud Storage for Firebase, Cloud Functions, Pub/Sub, Eventarc, Hosting, Data Connect, and Extensions all emulate locally. Client SDKs (native iOS, Android, Flutter, RN, Web Modular) all support pointing at the emulators via `connectAuthEmulator`, `connectFirestoreEmulator`, etc.

The emulator suite is **the only sanctioned way to TDD Firebase.** Running tests against a live project burns quota, races real users, and pollutes production data.

Canonical reference: [Local Emulator Suite docs](https://firebase.google.com/docs/emulator-suite).

## When to use it

**Use the Emulator Suite for:**

- Unit tests of Cloud Functions handlers
- Integration tests against Firestore / Storage / Auth / FCM
- Security Rules unit tests (via `@firebase/rules-unit-testing`)
- E2E tests of client apps without prod data risk
- Local dev with hot reload of functions

**Don't use the Emulator Suite for:**

- Load testing — the emulator's perf isn't representative
- Validating IAM / cross-region behavior — only the live project does that
- Validating App Check enforcement — App Check requires real tokens; for emulator dev, App Check is debug-token-mode

## 2025-2026 currency anchors

- **Data Connect emulator** added 2024-2025.
- **Extensions emulator** supports local install + run of extensions.
- **Eventarc emulator** added for `onCustomEventPublished` triggers.
- **`firebase emulators:exec`** is the canonical CI pattern.

## Patterns

### `firebase.json` emulators config

```json
{
  "emulators": {
    "auth":      { "port": 9099 },
    "firestore": { "port": 8080 },
    "functions": { "port": 5001 },
    "storage":   { "port": 9199 },
    "pubsub":    { "port": 8085 },
    "dataconnect": { "port": 9399 },
    "hosting":   { "port": 5000 },
    "ui":        { "enabled": true, "port": 4000 },
    "singleProjectMode": true
  }
}
```

### Start emulators

```bash
firebase emulators:start
firebase emulators:start --only auth,firestore,functions
firebase emulators:exec "npm test"           # run tests against ephemeral emulators
```

### Connect client SDK to emulator

```ts
import { connectAuthEmulator } from "firebase/auth";
import { connectFirestoreEmulator } from "firebase/firestore";

if (window.location.hostname === "localhost") {
  connectAuthEmulator(auth, "http://localhost:9099");
  connectFirestoreEmulator(db, "localhost", 8080);
}
```

Mobile SDKs (iOS, Android, Flutter, RN) all support the equivalent:

```swift
Auth.auth().useEmulator(withHost: "localhost", port: 9099)
Firestore.firestore().useEmulator(withHost: "localhost", port: 8080)
```

### Rules unit testing

```ts
import { initializeTestEnvironment } from "@firebase/rules-unit-testing";

const env = await initializeTestEnvironment({
  projectId: "demo-project",
  firestore: { rules: readFileSync("firestore.rules", "utf8") },
});

const alice = env.authenticatedContext("alice", { role: "admin" }).firestore();
const bob = env.unauthenticatedContext().firestore();
```

See [Security Rules](/stacks/firebase/security-rules/#rules-unit-testing) for full pattern.

### Functions unit + integration

- **`firebase-functions-test`** — unit test function handlers without the emulator (mocked context).
- **`firebase emulators:exec`** — integration tests against running emulators.

```ts
import { initializeTestEnvironment } from "@firebase/rules-unit-testing";
// or
import firebaseFunctionsTest from "firebase-functions-test";

const test = firebaseFunctionsTest();
const wrapped = test.wrap(myCallableFunction);
const result = await wrapped({ data: { ... }, auth: { uid: "alice" } });
```

### Importing/exporting emulator state

```bash
firebase emulators:start --import=./test-fixtures --export-on-exit=./test-fixtures
```

Useful for seed data: capture once, replay on every test run.

## Anti-patterns

- **Running tests against the live project** — burns quota, races prod users, contaminates data.
- **Mocking the Firebase SDK in unit tests** instead of using the emulator — the SDK's behavior matters too much (real-time listeners, offline persistence, rules evaluation).
- **Not connecting client to emulators in test builds** — tests silently hit prod.
- **`firebase emulators:start` in CI without `--export-on-exit`** when test state should persist — fresh emulator every run, fresh failures.
- **Emulator UI port (4000) exposed to the public internet** in dev environments — it's an admin surface.

## Gotchas

- **Emulator perf isn't production perf.** Don't load-test against emulators.
- **App Check is debug-mode in emulator** — real attestation doesn't run.
- **Cloud Functions emulator hot-reloads** on source changes — useful, but state-stateful tests may need restart between runs.
- **`firebase.json` `singleProjectMode: true`** uses the project alias for all emulators; multi-project setups can confuse the emulator.
- **Auth emulator has its own user pool** — accounts created in emulator don't exist in the live project.
- **Storage emulator stores data in the emulator's temp dir** — clears on restart unless you `--export-on-exit`.

## Cross-references

- [Firebase CLI](/stacks/firebase/firebase-cli/) — `firebase emulators:start` and friends
- [Security Rules](/stacks/firebase/security-rules/) — rules unit testing pattern
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — `firebase-functions-test` + emulator integration tests
- [Cloud Firestore](/stacks/firebase/cloud-firestore/) — emulator-backed data layer tests
- [backend-architect overlay](/stacks/firebase/backend-architect/#local-emulator-suite--your-tdd-environment) — TDD discipline on Firebase
- Authoritative: [firebase.google.com/docs/emulator-suite](https://firebase.google.com/docs/emulator-suite)
