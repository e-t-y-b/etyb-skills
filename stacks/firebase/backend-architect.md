---
title: backend-architect on Firebase
description: Composed role view — Cloud Functions gen 2, Admin SDK, Firestore data modeling, Data Connect, secrets, integration boundaries on Firebase.
role_overlay:
  role: backend-architect
  stack: firebase
  last_verified_on: "2026-05-14"
  products_covered: [cloud-functions-firebase, cloud-firestore, firebase-data-connect, firebase-storage, realtime-database, fcm, firebase-auth, emulator-suite, app-check]
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## Role briefing

You are backend-architect on a Firebase engagement. Your runtime is **[Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) gen 2** — Cloud Run-backed serverless containers — plus the **Firebase Admin SDK** for privileged data access, **[Firestore](/stacks/firebase/cloud-firestore/) / [Realtime Database](/stacks/firebase/realtime-database/) / [Firebase Data Connect](/stacks/firebase/firebase-data-connect/)** for persistence, and **Cloud Tasks / Pub/Sub / Eventarc** for async dispatch.

There is no long-running server you SSH into. There is no shared filesystem. There is no in-process database. Designs that assume otherwise will fail.

What's distinctive vs. principle-level backend-architect:

- **Everything is serverless-by-default.** Cold starts are part of the architecture, not a bug.
- **Three databases are first-class.** Firestore, RTDB, and Data Connect coexist; mixing them in one app is normal.
- **Security Rules are part of the codebase**, deployed via CI alongside functions.
- **The Admin SDK has root access** — service account hygiene is non-negotiable.

## Decision frameworks specific to backend-architect on Firebase

### Cloud Functions vs Cloud Run vs App Hosting backend

| Need | Pick |
|------|------|
| Event-triggered work (Firestore/Storage/Pub-Sub/Auth/Schedule) | Cloud Functions gen 2 |
| HTTPS callable RPC from a Firebase client | Cloud Functions `onCall` |
| Long-running request (>9 min), WebSockets, finer Cloud Run features | Cloud Run directly |
| Next.js or Angular SSR app | [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/) |
| HTTP API that's part of a larger Node/Go service | Cloud Run with the Firebase Admin SDK |

Cloud Functions gen 2 *is* Cloud Run under the hood with Firebase ergonomics layered on. Drop to bare Cloud Run when you outgrow the Firebase ergonomics or need a Cloud Run feature Firebase doesn't expose.

### Firestore vs Data Connect vs Cloud SQL direct

| Need | Pick |
|------|------|
| Document-shaped data, real-time listeners, ad-hoc client queries | [Firestore](/stacks/firebase/cloud-firestore/) |
| Relational data with joins, aggregations, FK constraints, GraphQL clients | [Data Connect](/stacks/firebase/firebase-data-connect/) |
| Existing Postgres workload, custom SQL, full Postgres surface | Cloud SQL Postgres directly |
| Analytics warehouse | BigQuery (defer to GCP stack) |

### Realtime Database vs Firestore for real-time

| Need | Pick |
|------|------|
| Sub-100ms presence / typing / cursor sync, JSON tree, small payloads | [RTDB](/stacks/firebase/realtime-database/) |
| Rich queries, transactions, larger documents, server-side aggregation | [Firestore](/stacks/firebase/cloud-firestore/) with `onSnapshot` |
| Mixed: presence in RTDB, canonical data in Firestore | Both (legitimate pattern) |

### Cloud Tasks vs Pub/Sub vs Eventarc

| Need | Pick |
|------|------|
| One delayed job, may cancel before execution | Cloud Tasks |
| Multi-subscriber durable stream, replay needed | Pub/Sub |
| First-party event between Cloud Functions with structured envelope | Eventarc |
| Cron / recurring | `onSchedule` (Cloud Scheduler → Pub/Sub) |

Common anti-pattern: **using a Firestore trigger as a queue.** Don't write a `tasks/{id}` doc to "queue work" — use Cloud Tasks. Firestore triggers are for *data* events.

## Product references

### [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/)

**Your primary runtime.** Gen 2 is the default — Cloud Run-backed, concurrent requests per instance, different cold-start economics. Use `firebase-functions/v2/*` imports for new code; `import * as functions from "firebase-functions"` (gen 1 namespace) signals legacy code.

Cold-start mitigation playbook: `minInstances`, `concurrency > 1`, trim dependencies, lazy-init heavy clients at first request not module load, CPU boost during startup, fast runtimes (Node 20+, Python 3.12+).

Callable functions auto-handle Auth and App Check; use them for client RPC. Raw `onRequest` for webhook receivers and streaming.

### [Cloud Firestore](/stacks/firebase/cloud-firestore/)

Document database with real-time listeners. Design rules: denormalize for reads, bound query result sets with `.limit()`, use subcollections for unbounded children, shard hot counters. Transactions auto-retry on contention — keep them fast and idempotent.

Multi-database (GA 2024) for tenant isolation, workload separation, compliance fencing. Vector search (GA 2024-2025) for small-to-moderate RAG corpora.

### [Firebase Data Connect](/stacks/firebase/firebase-data-connect/)

**The 2024-2025 addition that materially changes architectural choice.** Managed Cloud SQL Postgres + generated, typed GraphQL clients with pre-compiled operations. Reach for this when you have joins, aggregations, FK constraints, or transactions across heterogeneous types. **Don't bend Firestore into a relational shape** with array-of-IDs + N+1 queries.

### [Realtime Database](/stacks/firebase/realtime-database/)

Legacy but supported. Right call for **sub-100ms presence + small-payload fan-out** when Firestore's listener cost would be prohibitive. Many production apps use Firestore + RTDB hybrid (canonical data in Firestore, ephemeral presence in RTDB).

### [Cloud Storage for Firebase](/stacks/firebase/firebase-storage/)

Server-signed upload URLs are the standard pattern for client-direct uploads. Apply Storage Security Rules to enforce path and metadata. Run `onObjectFinalized` Cloud Functions to scan/transcode/extract metadata after upload — **never trust client-asserted metadata**.

For downloads, prefer signed read URLs (short-lived) over `getDownloadURL()` (long-lived, hard to revoke).

### [Firebase Authentication](/stacks/firebase/firebase-auth/)

The Admin SDK validates client tokens via `verifyIdToken`. Custom claims (`setCustomUserClaims`) are the canonical mechanism for server-set authorization data. Custom tokens (`createCustomToken`) bridge from external auth systems.

### [Cloud Messaging (FCM)](/stacks/firebase/fcm/)

Server-side sending via `getMessaging().send(...)` from the Admin SDK. HTTP v1 only — legacy server APIs are dead.

### [App Check](/stacks/firebase/app-check/)

Non-negotiable in production. `enforceAppCheck: true` on every callable; `consumeAppCheckToken: true` for Replay Protection on mutating endpoints.

### [Local Emulator Suite](/stacks/firebase/emulator-suite/)

**Your TDD environment.** Auth, Firestore, RTDB, Storage, Functions, Pub/Sub, Eventarc, Hosting, Data Connect, Extensions all emulate locally. `firebase emulators:exec "npm test"` runs your test suite against ephemeral emulators in CI.

## 2025-2026 platform-reset items

- **Gen 2 is the default.** Use `firebase-functions/v2/...` subpath imports.
- **`functions.config()` is deprecated.** Migrate to `defineSecret` / `defineString` parameterized config.
- **Cloud Functions cold starts on gen 2 are Cloud Run cold starts** — different mitigation toolkit from gen 1.
- **Firestore multi-database** unlocks isolation patterns that previously required separate projects.
- **Firestore vector search GA** changes the small-corpus RAG calculus — Firestore can be your vector store.
- **Data Connect GA** adds a relational option — "Firebase = NoSQL only" is out of date.
- **App Check Replay Protection** (GA 2024) — toggle on every mutating callable.
- **FCM HTTP v1 only.** Legacy server APIs gone.
- **Workload Identity Federation** for CI replaces long-lived `firebase login:ci` tokens.

## Patterns specific to backend-architect

### TDD on Cloud Functions

1. **Red:** write a failing test against the emulator before writing the function. For a callable: assert the function rejects an unauthenticated caller, asserts the data shape it returns.
2. **Green:** implement the function. `firebase emulators:exec "npm test"`.
3. **Refactor:** extract helpers; verify tests still pass.

Tooling:
- `firebase-functions-test` — unit testing for function handlers (mocked context)
- `@firebase/rules-unit-testing` — Security Rules integration tests
- `firebase emulators:exec` — emulator-backed integration tests
- `firebase deploy --only functions:myFunction` — single function canary
- `gcloud run services traffic` — Cloud Run-level traffic splitting

### Verification checklist

- [ ] Unit tests pass (`firebase-functions-test` mocks)
- [ ] Integration tests pass against the emulator
- [ ] Security Rules tests pass against the emulator
- [ ] Function deployed to staging and exercised end-to-end
- [ ] App Check enforced (or explicitly documented as exempt)
- [ ] Cold-start latency measured on staging (real values)
- [ ] Idempotency verified for retryable triggers
- [ ] Secrets pulled from Cloud Secret Manager
- [ ] Service account scoped to needed IAM roles, not project owner

### Secrets and config

```ts
import { defineSecret } from "firebase-functions/params";

const STRIPE_SECRET = defineSecret("STRIPE_SECRET");

export const chargeCard = onCall(
  { secrets: [STRIPE_SECRET], enforceAppCheck: true, consumeAppCheckToken: true },
  async (request) => {
    const stripe = new Stripe(STRIPE_SECRET.value());
    // ...
  }
);
```

`defineSecret` integrates with Cloud Secret Manager. The function only loads the secret when invoked; secrets aren't baked into deploy artifacts. **Never** put secrets in `.env`, `functions.config()` (deprecated), or hard-code in source.

### Debugging on Firebase

- **Cloud Logging** ([logs explorer](https://console.cloud.google.com/logs)) — `logger.info/warn/error` from `firebase-functions/v2` writes structured logs auto-correlated with the function name and execution ID. Filter logs by execution ID to trace a single invocation.
- **Firestore query plan output** (`.explain()` on a query) — see indexes used and read counts.
- **Cloud Trace** integration shows cold-start breakdown for Functions.

Root-cause first, one variable at a time. Don't shotgun `region` + `concurrency` + `minInstances` + `memory` changes simultaneously.

## Common backend footguns on Firebase

- **`firebase.json` rewrites pointing to a region the function isn't deployed in** — silent 404 or cross-region latency.
- **Module-scope side effects in Cloud Functions** — heavy imports, top-level `await`, expensive client init at module load. Pay on every cold start.
- **Calling other Cloud Functions HTTP-to-HTTP** — works, but you're paying for two invocations and incurring round-trip latency. Extract shared logic to a library.
- **Treating Firestore as a relational DB** — N+1 queries on referenced docs, array-of-IDs lookups. Denormalize or use Data Connect.
- **`getDownloadURL()` for sensitive blobs** — long-lived public URL. Signed URLs with short expiry.
- **Not setting `retry: true` on critical Firestore triggers** — failure drops the event. Then setting it without idempotency causes duplicate processing.
- **Service account JSON in git** — total compromise. Use Secret Manager + WIF.
- **Firestore transaction with external API calls inside** — replays on retry. Mutate-only inside; external calls outside.
- **A `where()` query without `.limit()`** — cost time bomb.

## Cross-references

- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — Genkit flows inside Cloud Functions
- [security-engineer overlay](/stacks/firebase/security-engineer/) — Admin SDK service account hygiene, secret management
- [frontend-architect overlay](/stacks/firebase/frontend-architect/) — SSR Admin SDK pattern in App Hosting
- [mobile-architect overlay](/stacks/firebase/mobile-architect/) — FCM server-side sending
- [Firebase stack index](/stacks/firebase/) — products + role overlay map
