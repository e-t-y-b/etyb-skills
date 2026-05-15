---
title: Cloud Functions for Firebase
description: Serverless compute for Firebase — Cloud Run-backed gen 2 functions for callable RPCs, HTTPS handlers, event triggers, scheduled jobs.
product:
  name: Cloud Functions for Firebase
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, ai-ml-engineer, security-engineer]
  authoritative_url: https://firebase.google.com/docs/functions
  notes: "Gen 2 (Cloud Run-backed) is the default for new functions; Gen 1 on the deprecation roadmap; cold-start + concurrency model differ."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Cloud Functions for Firebase is the serverless compute layer of Firebase. Functions are short-lived (or long-lived, with concurrency), event- or HTTP-triggered, and integrated with Firebase Auth, App Check, Security Rules, and the wider GCP event ecosystem (Eventarc, Pub/Sub, Cloud Scheduler).

Two generations coexist:

- **Gen 2** (default for new code, 2024+) — Cloud Run-backed, concurrent requests per instance, per-function service accounts, structured Eventarc envelopes for events. `firebase-functions/v2/*` imports.
- **Gen 1** (legacy, on the deprecation roadmap) — single-request-per-instance, the original Firebase functions runtime. Namespaced `firebase-functions` imports.

Canonical reference: [Cloud Functions for Firebase docs](https://firebase.google.com/docs/functions).

## When to use it

**Use Cloud Functions when:**

- Event-triggered work (Firestore/Storage/Pub-Sub/Auth/Schedule)
- HTTPS callable RPC from a Firebase client (`onCall`)
- Webhook receivers (`onRequest`)
- Scheduled cron-like work (`onSchedule`)

**Use a different surface when:**

- Long-running request (>9 min), WebSockets, finer Cloud Run control → drop to **Cloud Run** directly
- Next.js or Angular SSR app → [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/)
- HTTP API that's part of a larger Node/Go service → Cloud Run with the Firebase Admin SDK

Cloud Functions gen 2 *is* Cloud Run under the hood with Firebase ergonomics layered on. Drop to bare Cloud Run when you outgrow the Firebase ergonomics.

## 2025-2026 currency anchors

- **Gen 2 is the default.** New code uses `firebase-functions/v2/*` subpath imports. If you see `import * as functions from "firebase-functions"` without a `/v2/...` subpath in new 2026 code, that's legacy.
- **Eventarc under the hood for event triggers** — uniform CloudEvents envelope, ordered-per-key for Firestore, retryable via `retry: true`.
- **`enforceAppCheck` + `consumeAppCheckToken` (Replay Protection)** — non-negotiable on production callable functions.
- **`defineSecret` integrates with Cloud Secret Manager**. The legacy `functions.config()` is deprecated.
- **CPU and memory configured explicitly per function.** Defaults: 1 vCPU, 256MiB. Bump for real work.
- **Concurrent requests per instance** — set `concurrency: <n>` (Cloud Run's default is 80). Stateless HTTPS handlers benefit massively.

## Patterns

### Callable function — the modern client-server pattern

```ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

export const createOrder = onCall(
  {
    region: "us-central1",
    cors: true,
    enforceAppCheck: true,
    consumeAppCheckToken: true,
    minInstances: 1,
    memory: "512MiB",
    concurrency: 80,
  },
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError("unauthenticated", "Sign in.");
    const { items } = request.data ?? {};
    if (!Array.isArray(items) || items.length === 0) {
      throw new HttpsError("invalid-argument", "items[] required.");
    }
    const db = getFirestore();
    const orderRef = await db.collection("orders").add({
      userId: request.auth.uid, items, status: "pending", createdAt: new Date(),
    });
    return { orderId: orderRef.id };
  }
);
```

Callable functions auto-deserialize `request.data`, auto-attach verified `request.auth` (Firebase ID token, server-validated), and auto-attach an `app` claim when App Check is enforced. Use them for any client → server RPC. Use raw `onRequest` only when you need custom HTTP control (custom headers, streaming responses, webhook receivers).

### Event-triggered functions

```ts
import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { onObjectFinalized } from "firebase-functions/v2/storage";
import { onMessagePublished } from "firebase-functions/v2/pubsub";

export const onOrderCreated = onDocumentCreated(
  { document: "orders/{orderId}", region: "us-central1" },
  async (event) => {
    const order = event.data?.data();
    if (!order) return;
    // ...send email, enqueue task, etc.
  }
);
```

Set `retry: true` to opt into retries; failures otherwise drop. Set `maxRetrySeconds` — infinite retries on a poison message are an outage.

### Scheduled functions

```ts
import { onSchedule } from "firebase-functions/v2/scheduler";

export const dailyCleanup = onSchedule(
  { schedule: "every day 03:00", timeZone: "America/Los_Angeles", region: "us-central1" },
  async () => { /* ... */ }
);
```

Cloud Scheduler + Pub/Sub under the hood. The Firebase CLI provisions both.

### Secrets and config

```ts
import { defineSecret } from "firebase-functions/params";

const STRIPE_SECRET = defineSecret("STRIPE_SECRET");

export const chargeCard = onCall(
  { secrets: [STRIPE_SECRET], enforceAppCheck: true },
  async (request) => {
    const stripe = new Stripe(STRIPE_SECRET.value());
    // ...
  }
);
```

```bash
firebase functions:secrets:set STRIPE_SECRET
```

`defineSecret` integrates with Cloud Secret Manager. The function only loads the secret when invoked; secrets aren't baked into deploy artifacts.

### Cold-start mitigation

Gen 2 cold starts are Cloud Run cold starts. The toolkit:

1. **`minInstances`** — number one lever for latency-critical handlers (~$0.40/instance/month per warm instance at minimal CPU/memory).
2. **`concurrency` > 1** — a single warm instance can serve many concurrent requests.
3. **Trim dependencies** — each MB of `node_modules` is ~10-50ms of additional cold start.
4. **Lazy-init heavy clients at first request, not at module load.**
5. **CPU boost during startup** option — enable for handlers with heavy init.
6. **Pick fast runtimes** — Node 20+, Python 3.12+, Go 1.22+, Java 17+.

If a function genuinely cannot afford cold starts, the answer is `minInstances >= 1`, not "warm-up cron" hacks — those don't reliably keep gen 2 instances warm.

## Anti-patterns

- **`import * as functions from "firebase-functions"` for new handlers** — gen 1 namespace import. Use `firebase-functions/v2/...`.
- **`functions.config()`** — deprecated. Migrate to `defineSecret` / `defineString`.
- **Module-scope side effects in Cloud Functions** — heavy imports, top-level `await`, expensive client init at module load. Pay on every cold start.
- **Calling other Cloud Functions HTTP-to-HTTP** — works, but you're paying for two invocations and incurring round-trip latency. Prefer direct function-to-function via the Admin SDK or extract shared logic to a library.
- **Not setting `retry: true` on critical Firestore triggers** — failure drops the event. Then setting `retry: true` without idempotency, causing duplicate processing.
- **Pub/Sub message handlers without ack discipline** — exceptions = redelivery. Idempotency key required.
- **Service account JSON in git** — total compromise. Use Secret Manager + WIF.
- **Treating Firestore triggers as a queue** — write a `tasks/{id}` doc to "queue work." Use Cloud Tasks for that. Firestore triggers are for *data* events.

## Gotchas

- **Firestore region must match function region** to avoid cross-region latency on reads/writes.
- **`firebase.json` rewrites pointing to a region the function isn't deployed in** — silent 404 or cross-region latency. Pin.
- **Eventarc events for Firestore are ordered-per-key, NOT global ordering.** Don't assume cross-document order.
- **Cold start cost scales with image size.** Multi-stage Docker builds, slim base images.
- **`onRequest` has a 9-minute max duration**; Cloud Run direct supports longer.
- **Gen 2 region semantics** — set per function or via `setGlobalOptions`. Mismatched regions cause hidden cross-region latency.
- **CPU/memory defaults are minimal** — bump to 1GiB+ for anything that does meaningful work.

## Cross-references

- [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/) — SSR alternative for Next.js/Angular
- [App Check](/stacks/firebase/app-check/) — Replay Protection on callables
- [Security Rules](/stacks/firebase/security-rules/) — `request.auth` validation in rules vs in functions
- [Local Emulator Suite](/stacks/firebase/emulator-suite/) — `firebase-functions-test` + emulator integration tests
- [backend-architect overlay](/stacks/firebase/backend-architect/) — function architecture deep dive
- [security-engineer overlay](/stacks/firebase/security-engineer/) — Replay Protection, secrets, service accounts
- Authoritative: [firebase.google.com/docs/functions](https://firebase.google.com/docs/functions)
