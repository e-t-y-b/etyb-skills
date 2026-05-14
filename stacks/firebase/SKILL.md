---
name: stack-firebase
description: >
  Firebase platform knowledge overlay for the ETYB team. Loads when work involves the Firebase ecosystem — Firebase Authentication, Identity Platform, Cloud Firestore, Realtime Database, Cloud Storage for Firebase, Cloud Functions for Firebase (gen 2), Firebase Hosting, Firebase App Hosting (Next.js + Angular SSR), Cloud Messaging (FCM), Remote Config, A/B Testing, Performance Monitoring, Crashlytics, Firebase Analytics / GA4, App Distribution, Test Lab, Firebase Extensions, Firebase Studio, Genkit, Firebase AI Logic, Firebase Data Connect, Security Rules, App Check, Firebase CLI, Local Emulator Suite. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Firebase work as of 2026 Q2.
  Triggers: firebase, firebase auth, firebase authentication, identity platform, gcip, google identity platform, firebase admin sdk, firebase-admin, firebase cli, firebase.json, firebase init, firebase deploy, firebaserc, firestore, cloud firestore, firestore rules, firestore.rules, firestore security rules, multi-database, datastore mode, datastore, realtime database, rtdb, firebase rtdb, cloud storage for firebase, storage.rules, cloud functions for firebase, functions.firebase, onCall, onRequest, onDocumentCreated, onDocumentUpdated, onObjectFinalized, firebase functions v2, gen 2 functions, firebase hosting, firebase hosting channels, preview channel, firebase app hosting, apphosting, apphosting.yaml, app hosting backend, cloud messaging, fcm, firebase cloud messaging, fcm http v1, fcm legacy api, remote config, remote config server, firebase a/b testing, performance monitoring, perf mon, crashlytics, firebase analytics, ga4, google analytics for firebase, firebase event, app distribution, firebase app distribution, test lab, firebase test lab, robo test, firebase extensions, firebase extension, firebase studio, project idx, genkit, genkit flow, defineFlow, defineTool, ai.defineFlow, firebase ai logic, vertex ai in firebase, gemini in firebase, firebase data connect, data connect, fdc, app check, app check token, appcheck, replay protection, recaptcha enterprise, play integrity, device check, app attest, firebase emulator, firebase local emulator suite, emulators, custom claims, id token, custom token, idtoken, refresh token, modular sdk, web modular sdk, firebase-admin python, firebase-admin node, firebase-admin go, firebase-admin java, getAuth, getFirestore, getMessaging, callable function, scheduled function, eventarc, pubsub, gcp pubsub trigger, firebase cli login:ci, firebase functions:secrets, firebase login, fdc generated sdk, dataconnect.yaml, firestore.indexes.json, .firebaserc.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
  last_verified_release: "2026 Q2"
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - backend-architect
    - frontend-architect
    - mobile-architect
    - ai-ml-engineer
    - security-engineer
authoritative_sources:
  primary:
    - { name: "Firebase Documentation",            url: "https://firebase.google.com/docs",                              type: official_docs }
    - { name: "Firebase CLI Reference",            url: "https://firebase.google.com/docs/cli",                          type: cli_reference }
    - { name: "Firebase Release Notes",            url: "https://firebase.google.com/support/release-notes",             type: changelog }
    - { name: "Firebase GitHub Organization",      url: "https://github.com/firebase",                                   type: source }
    - { name: "Firebase Blog",                     url: "https://firebase.blog/",                                        type: blog }
    - { name: "Genkit Documentation",              url: "https://firebase.google.com/docs/genkit",                       type: official_docs }
    - { name: "Firebase Data Connect Docs",        url: "https://firebase.google.com/docs/data-connect",                 type: official_docs }
    - { name: "Firebase AI Logic Docs",            url: "https://firebase.google.com/docs/ai-logic",                     type: official_docs }
    - { name: "Firebase App Hosting Docs",         url: "https://firebase.google.com/docs/app-hosting",                  type: official_docs }
    - { name: "Firebase Status Dashboard",         url: "https://status.firebase.google.com/",                           type: status_page }
    - { name: "Google Cloud Security Bulletins",   url: "https://cloud.google.com/support/bulletins",                    type: security_advisories }
delegate_to_skills:
  - { skill: "firebase:firebase-basics",                covers: [Firebase overview, project setup, CLI] }
  - { skill: "firebase:firebase-auth-basics",           covers: [Firebase Authentication, Identity Platform, MFA, custom claims] }
  - { skill: "firebase:firebase-firestore",             covers: [Cloud Firestore, data modeling, queries] }
  - { skill: "firebase:firebase-hosting-basics",        covers: [Firebase Hosting (static)] }
  - { skill: "firebase:firebase-app-hosting-basics",    covers: [Firebase App Hosting, Next.js SSR, Angular SSR] }
  - { skill: "firebase:firebase-data-connect-basics",   covers: [Firebase Data Connect, Postgres-backed GraphQL] }
  - { skill: "firebase:firebase-security-rules-auditor", covers: [Firestore Rules, Realtime DB Rules, Storage Rules audit] }
  - { skill: "firebase:firebase-ai-logic-basics",       covers: [Firebase AI Logic, Vertex AI in Firebase, Gemini integration] }
  - { skill: "firebase:developing-genkit-js",           covers: [Genkit JavaScript/TypeScript] }
  - { skill: "firebase:developing-genkit-python",       covers: [Genkit Python] }
  - { skill: "firebase:developing-genkit-go",           covers: [Genkit Go] }
  - { skill: "firebase:developing-genkit-dart",         covers: [Genkit Dart/Flutter] }
products_covered:
  - { name: "Firebase Authentication",        drift_risk: high,   notes: "Identity Platform tier convergence (2025); MFA + SSO + custom claims surfaces evolving; passkeys/WebAuthn on the roadmap" }
  - { name: "App Check",                      drift_risk: high,   notes: "Replay Protection GA 2024; required for production-grade hardening of every Firebase backend service" }
  - { name: "Cloud Firestore",                drift_risk: medium, notes: "Multi-database per project GA 2024; Datastore-mode persistence option; vector search GA; new index/query semantics" }
  - { name: "Realtime Database",              drift_risk: low,    notes: "Stable legacy; still recommended for true real-time presence + sub-100ms fan-out; otherwise prefer Firestore" }
  - { name: "Cloud Storage for Firebase",     drift_risk: low,    notes: "Stable; security rules surface largely unchanged; download URL behavior and CORS still the recurring gotcha" }
  - { name: "Cloud Functions for Firebase",   drift_risk: high,   notes: "Gen 2 (Cloud Run-backed) is the default; Gen 1 deprecation roadmap in motion; cold-start and concurrency model differ" }
  - { name: "Firebase Hosting",               drift_risk: medium, notes: "Static-first; preview channels stable; SSR via App Hosting now preferred for new SSR apps" }
  - { name: "Firebase App Hosting",           drift_risk: high,   notes: "GA 2024 for Next.js + Angular SSR (Cloud Run + Cloud Build under the hood); roll-forward replaces Hosting + Functions stitching" }
  - { name: "Cloud Messaging (FCM)",          drift_risk: high,   notes: "Legacy HTTP/XMPP server APIs deprecated; HTTP v1 + Admin SDK only; APNs auth key rotation discipline matters" }
  - { name: "Remote Config",                  drift_risk: medium, notes: "Server-side Remote Config GA 2024; integrates with A/B Testing; AI personalization via Remote Config + Firebase AI Logic" }
  - { name: "A/B Testing",                    drift_risk: medium, notes: "Integrated with Remote Config; goal metrics now via GA4; experiment infra steady" }
  - { name: "Performance Monitoring",         drift_risk: medium, notes: "Cloud Trace integration; custom traces + network monitoring; web JS support stable" }
  - { name: "Crashlytics",                    drift_risk: medium, notes: "Native + RN + Flutter SDKs stable; Apple privacy manifest + dSYM upload discipline non-negotiable" }
  - { name: "Firebase Analytics (GA4)",       drift_risk: medium, notes: "Now the same SKU as GA4; consent mode v2 + Apple ATT compliance evolving" }
  - { name: "App Distribution",               drift_risk: low,    notes: "Tester management + CI uploads stable; not a substitute for TestFlight/internal Play tracks for store readiness checks" }
  - { name: "Test Lab",                       drift_risk: low,    notes: "Real-device matrix narrowing post-2024; check current device coverage before committing CI matrix" }
  - { name: "Firebase Extensions",            drift_risk: medium, notes: "Marketplace expanded; v1 spec stable; some popular extensions (e.g., Stripe payments) now community-maintained" }
  - { name: "Firebase Studio",                drift_risk: high,   notes: "Rebranded from Project IDX 2025; AI-first dev environment; surface still evolving" }
  - { name: "Genkit",                         drift_risk: high,   notes: "JS GA; Python/Go/Dart maturing through 2025-2026; API shape has churned — anchor to current docs not training data" }
  - { name: "Firebase AI Logic",              drift_risk: high,   notes: "Rebranded from Vertex AI in Firebase 2025; client-side Gemini access with App Check; on-device Gemini Nano option" }
  - { name: "Firebase Data Connect",          drift_risk: high,   notes: "Postgres-backed managed schema + generated GraphQL clients; GA 2024-2025; competing surface with Firestore for relational use cases" }
  - { name: "Security Rules",                 drift_risk: medium, notes: "Firestore + RTDB + Storage rules; rules unit testing via emulator; deny-by-default discipline non-negotiable" }
  - { name: "Firebase CLI",                   drift_risk: medium, notes: "Active development; Data Connect + App Hosting + Studio commands all added 2024-2025" }
  - { name: "Local Emulator Suite",           drift_risk: medium, notes: "Auth, Firestore, RTDB, Storage, Functions, Pub/Sub, Eventarc, Hosting, Data Connect, Extensions all emulated; the only sanctioned way to TDD Firebase" }
---

# Firebase Stack Pack — Team Briefing

You're working on the Firebase platform — Google's app development platform that wraps a curated slice of Google Cloud under a developer-friendly surface. This is a **knowledge overlay**, not a new specialist. The existing ETYB team is doing the work — backend-architect writes the Cloud Functions and Data Connect schema, frontend-architect wires the modular Web SDK, mobile-architect ships Crashlytics + FCM + App Check, ai-ml-engineer composes Genkit flows, security-engineer enforces Rules + App Check + Identity Platform. This pack teaches each role what the platform expects in 2026.

**Currency stamp:** verified against Firebase 2026 Q2 — Firebase Studio (renamed from Project IDX), Firebase AI Logic (renamed from Vertex AI in Firebase), Cloud Functions gen 2 default, Firebase App Hosting GA, Firebase Data Connect GA, Genkit JS 1.x. If today's date is more than 6 months past `last_verified_on`, the pack is stale — warn the user and consult [Firebase Release Notes](https://firebase.google.com/support/release-notes) before recommending API-level details.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2024 cutoff will get most of these wrong:

- **Project IDX is now Firebase Studio** (renamed 2025). Same product surface, new branding, deeper Firebase + Gemini integration. If you say "Project IDX" you're using the old name.
- **Vertex AI in Firebase is now Firebase AI Logic** (renamed 2025). The client-side Gemini SDK that talks to either Vertex AI or the Gemini Developer API behind App Check. The name change matters because the SDK packages were renamed too (`@firebase/ai` replaces `@firebase/vertexai`).
- **Firebase App Hosting GA** (2024) — the SSR-aware successor for Next.js and Angular. Cloud Run + Cloud Build under the hood, GitHub-integrated, replaces the brittle "Hosting + Cloud Functions rewrites" pattern that everyone built circa 2022.
- **Firebase Data Connect GA** (2024-2025) — managed Cloud SQL Postgres + GraphQL with generated, typed clients. Firebase now has a first-class relational option; "Firebase = NoSQL only" is out of date.
- **Cloud Functions Gen 2 is the default** for new functions, backed by Cloud Run with concurrent request handling, better cold-start economics, and a different deploy/runtime model. Gen 1 is on the deprecation roadmap — write all new code on v2 (`firebase-functions/v2`).
- **Firestore multi-database per project** (GA 2024). You can now provision multiple Firestore databases per project (named, distinct rules, distinct locations). This replaces "one project per database scope" workarounds.
- **Firestore Datastore mode** is its own persistence mode — same wire protocol, different consistency/index/scaling characteristics. Don't confuse "Firestore" with "Firestore in Datastore mode" in an architecture doc; they're not interchangeable.
- **App Check Replay Protection** (GA 2024) — single-use App Check tokens for callable functions, defending against captured-token replay. Worth enabling on every privileged path.
- **FCM legacy HTTP and XMPP server APIs are deprecated**. Use **HTTP v1 API** or the Admin SDK. Old code calling `fcm.googleapis.com/fcm/send` with a server key will break — that endpoint was sunset.
- **Firebase Authentication ↔ Identity Platform** convergence (2024-2025). The classic Firebase Auth tier and the paid Identity Platform tier (with MFA, SAML/OIDC SSO, advanced security) share the same surface and billing model now; "upgrading to Identity Platform" is a project toggle, not a re-architecture.
- **Modular Web SDK is the only supported shape** for `firebase` v9+ (and we're well past that). Namespaced v8 imports (`firebase.auth().signInWithEmailAndPassword(...)`) are legacy and tree-shake badly. New code uses tree-shakable modular imports (`import { getAuth, signInWithEmailAndPassword } from 'firebase/auth'`).
- **Genkit JS GA**, with Python, Go, and Dart maturing through 2025-2026. Genkit's flow/tool/prompt API has churned multiple times — any sample older than mid-2024 likely has out-of-date shapes (`defineFlow` → `ai.defineFlow` etc.). Anchor to current docs.
- **Firebase Hosting preview channels** are still the canonical preview workflow for static hosting, with per-PR URLs and automatic GitHub Action integration. Pair with App Hosting for SSR previews.
- **Crashlytics + Performance Monitoring** are now wired through **Cloud Trace**, giving you a unified observability story across mobile, web, and Cloud Functions / Cloud Run.

If you find yourself recommending Project IDX, Vertex AI in Firebase, FCM legacy server keys, namespaced v8 imports, Cloud Functions v1 for new code, or "use Firestore for everything" without considering Data Connect — you're using stale knowledge. Read the role overlay below.

## How this pack plugs in

ETYB's router detects Firebase signals via `skills/etyb/core/stack-registry.md` (keywords: `firebase`, `firestore`, `firebase-admin`, `app check`, `genkit`, `apphosting.yaml`, `firestore.rules`, etc.) and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement. The Firebase overlay does not relax engineering discipline; it shapes how the discipline is applied on this platform:

- **TDD on Cloud Functions** = `firebase-functions-test` + the Local Emulator Suite, not deploying-and-poking.
- **TDD on Security Rules** = `@firebase/rules-unit-testing` against the emulator, with deny-by-default tests for every collection.
- **TDD on Firestore data layers** = emulator-backed integration tests, not mocks of the SDK — the SDK behavior matters too much.
- **TDD on Genkit flows** = Genkit's eval harness with golden datasets, not just unit tests on the surrounding TypeScript.

**Delegate skills exist.** A user environment with the `firebase:*` skills installed (see `delegate_to_skills` above) gets deeper, product-specific guidance for the heavy products — Firestore, App Hosting, Data Connect, AI Logic, Genkit per language, Security Rules auditing. This Stack Pack is the orchestrator briefing; for product-level depth, defer to the delegate skill the user has loaded. If no delegate is available, this Stack still has enough opinionated content to ship correctly.

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | **The heaviest overlay.** Cloud Functions gen 2 architecture (callable / HTTPS / event-triggered / scheduled / Pub/Sub / Eventarc), cold-start mitigation, secrets and config, Admin SDK patterns, Firestore data modeling, multi-database, transactions/batched writes, **Firebase Data Connect** (Postgres + GraphQL), Cloud Tasks, integration boundaries between Firebase and the rest of GCP |
| `frontend-architect` | [`references/frontend-architect.md`](references/frontend-architect.md) | Modular Web SDK v9+, Firebase App Hosting for Next.js + Angular SSR, Firebase Hosting + preview channels, client-side Auth UX, Firestore real-time listeners + offline persistence, App Check on the web (reCAPTCHA Enterprise), Performance Monitoring web SDK, Analytics + consent mode v2 |
| `mobile-architect` | [`references/mobile-architect.md`](references/mobile-architect.md) | iOS + Android + Flutter + React Native SDK integration; **Crashlytics** (symbols, breadcrumbs, NDK crashes); **FCM** (HTTP v1 + APNs auth keys + notification vs data messages + topic subs); **App Check** with Play Integrity / App Attest / DeviceCheck; **Test Lab** matrix selection; offline persistence; Firebase Analytics + ATT/IDFA; App Distribution for internal QA |
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | **Genkit** (flows, tools, prompts, RAG, eval) across JS/Python/Go/Dart; **Firebase AI Logic** for client-side Gemini with App Check enforcement; on-device Gemini Nano via AI Logic; Firestore vector search; Firebase Extensions for AI; Remote Config–driven prompt iteration; AI personalization patterns |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | **Security Rules** (Firestore + RTDB + Storage) — deny-by-default, request.auth claims, rules unit testing; **App Check** with Replay Protection on every privileged path; **Identity Platform** MFA + SAML/OIDC SSO + custom claims; secret management via Cloud Secret Manager (not env vars); ID token vs custom token semantics; least-privilege Admin SDK service accounts; GDPR + COPPA considerations on Analytics |

`system-architect`, `database-architect`, `devops-engineer`, `qa-engineer`, `sre-engineer`, and vertical roles (saas-, fintech-, healthcare-, real-time-) operate on the platform-neutral references when Firebase is in scope, with this SKILL.md as the platform briefing. If demand warrants, dedicated overlays for those roles can be added in a future iteration — for v4.0.0, the five listed above are where Firebase work concentrates.

## Top platform gotchas the team must know

Opinionated, named, with consequences:

1. **Security Rules are public** (Firestore, RTDB, Storage). Anyone with the project ID can read them. Treat them as an enforcement layer, not a secrecy layer — sensitive logic belongs in callable Cloud Functions with `request.auth` and App Check, not in client-readable rule expressions. Rules failing-open via permissive `if true` patterns is the #1 production Firebase incident class.
2. **App Check is not optional in 2026.** Without App Check, your callable functions, Firestore, RTDB, Storage, Data Connect, AI Logic, and FCM endpoints can be hit by any client claiming to be your app. The cost of enabling App Check is hours; the cost of not is whatever your most expensive Gemini prompt is, times whatever a botnet decides to send. Enable enforcement after a soft-launch shadow period — never never never just leave it off.
3. **Cloud Functions cold starts on gen 2 are mostly Cloud Run cold starts**, which are sensitive to deploy region, min-instances, container image size, language runtime, and concurrency setting. The mitigation toolkit is different from gen 1 — set `minInstances`, configure `concurrency` > 1 where state is stateless, watch your image cold-start size, and prefer Node 20+ / Python 3.12+ runtimes. See backend-architect for the playbook.
4. **Firestore is not a relational database.** Reach for Firebase Data Connect (managed Postgres + GraphQL) when you have referential integrity, joins, aggregations, or transactions across heterogeneous types that Firestore makes painful. Don't bend Firestore into a relational shape with array-of-IDs + N+1 queries; you'll pay in cost, latency, and maintainability.
5. **FCM "notification" vs "data" messages are not the same thing.** Notification messages render automatically when the app is backgrounded; data messages always invoke your handler. Mobile teams often ship "why does my onMessage not fire when backgrounded?" bugs because they used the wrong payload type. iOS adds APNs priority + content-available + mutable-content semantics on top.
6. **Firebase Hosting alone won't run your Next.js app.** Hosting is static + rewrites. SSR requires either Firebase App Hosting (the modern path) or Hosting-rewrites-to-Cloud-Functions (the 2022 path — works, but App Hosting is purpose-built and worth migrating to for new apps).
7. **The Admin SDK has root access** in your project — it bypasses Security Rules. A leaked Admin SDK service account JSON is a total compromise. Never check service account JSON into git, never bake it into a client bundle, never email it. Use **Cloud Secret Manager** or Workload Identity Federation. The Firebase CLI's `firebase login:ci` token gives broad deploy rights — rotate it on staff churn.
8. **Modular Web SDK tree-shakes; namespaced v8 doesn't.** A v8-style app ships ~150kb of Firebase JS unconditionally. The modular v9+ shape lets bundlers drop unused services, often pulling a typical app under 30kb. Migration is mechanical but real — don't recommend v8 patterns to anyone.
9. **Firestore reads cost money per document, not per query.** A `where` that returns 50,000 docs costs 50,000 reads. Composite indexes don't help cost — they help latency and avoidance of "this query requires an index" errors. Design data shapes to bound read counts: aggregate counters via Cloud Functions, denormalize for query-by-key, paginate aggressively.
10. **Crashlytics on iOS needs dSYMs** for symbolicated stack traces, and the dSYM upload step silently fails in CI more often than any other Firebase integration. Verify symbolicated reports in the console after every release. Android's NDK crash reporting has its own native symbol upload path. Mobile-architect overlay covers the discipline.
11. **Firebase Auth ID tokens expire after 1 hour**; the SDK refreshes them automatically for users with an active refresh token. Custom claims in the ID token only update after the token refreshes — so when you change custom claims server-side, the user sees the new claim only after `getIdToken(true)` is forced or after the next auto-refresh. Don't gate UI on stale claims; security-engineer overlay covers this.
12. **Genkit's API has churned.** Code from early 2024 that used module-scope `defineFlow(...)` and 2025 code that uses `ai.defineFlow(...)` on an `ai` instance look different and are not interchangeable. Always check the current docs (linked in delegate skills) before recommending an API shape.

## Compliance composition — when verticals stack

The Firebase platform itself has BAA-eligible products (Firestore, Cloud Functions, Cloud Storage, Auth, FCM, Hosting, App Hosting under Google Cloud's HIPAA-compliant SKUs), but enabling a BAA does not make your *application* HIPAA-compliant — only the underlying services. Compliance work composes with the vertical specialists:

| Vertical | Firebase-side scope (this pack) | Vertical-side scope (defer) |
|----------|--------------------------------|------------------------------|
| **healthcare-architect (HIPAA)** | Which Firebase products are under the GCP BAA, App Check + Identity Platform MFA configuration, audit logging via Cloud Logging | FHIR data modeling, PHI handling discipline, breach notification process, BAA contracting |
| **fintech-architect (PCI, PSD2, banking)** | Firestore + Functions are NOT a ledger; use Cloud SQL via Data Connect or a dedicated ledger service. Auth flows for SCA. App Check for fraud control | Ledger semantics, PCI scope reduction, KYC/AML flows, PSD2 SCA compliance |
| **saas-architect** | Multi-tenancy patterns on Firestore (per-tenant subcollection vs multi-database), Identity Platform tenants, per-tenant Custom Claims, Remote Config segmentation | Pricing/packaging, billing, tenant lifecycle, ISV distribution |
| **real-time-architect** | Realtime Database vs Firestore listener fan-out vs FCM push semantics, App Hosting + Cloud Run WebSockets boundaries | Pub/sub architecture, presence systems, ordering guarantees beyond Firebase primitives |

When a Firebase engagement crosses one of these verticals, both overlays load. Don't restate compliance content here; route to the vertical for the depth.

## Standing instructions for every role on a Firebase engagement

1. **Anchor to currency.** Before recommending API shapes, SDK imports, or product names, check the role overlay. If you find yourself typing `firebase.auth().currentUser`, `import * as functions from 'firebase-functions'` (v1 namespace import for new code), or `Vertex AI in Firebase` — stop and read the appropriate overlay. The platform's names and shapes have changed.

2. **Use the Local Emulator Suite for development.** Auth, Firestore, RTDB, Storage, Functions, Pub/Sub, Eventarc, Hosting, Data Connect, and Extensions all emulate locally. Connecting client SDKs to emulators is one-line (`connectAuthEmulator`, `connectFirestoreEmulator`, etc.). The emulator suite is the only sanctioned way to TDD Firebase. Running tests against a live project burns quota and racing real users.

3. **Security Rules are not optional.** Every collection in Firestore, every path in RTDB, every bucket in Storage gets explicit rules. Deny-by-default at the top of every rules file. Rules unit tests (`@firebase/rules-unit-testing`) for every collection. Rules are part of the codebase — they ship in `firestore.rules`, `database.rules.json`, `storage.rules`, deployed via `firebase deploy --only firestore:rules,storage:rules,database`.

4. **App Check on every privileged backend in production.** Cloud Functions, Firestore, Storage, RTDB, Data Connect, AI Logic. Enable in monitoring/shadow mode first to size the impact; enforce after a clean week. Skip App Check only on truly public read endpoints (e.g., a public marketing landing page reading a `public/` collection), and document why.

5. **Service accounts are credentials, not config.** Never check `service-account.json` into git. Use Cloud Secret Manager for runtime secrets, Workload Identity Federation for CI, and scoped service accounts (read-only for read-only workloads). The Firebase CLI's `firebase login:ci` token deserves the same treatment as any other long-lived deploy credential.

6. **Gen 2 Functions are the default for new code.** `import { onCall } from 'firebase-functions/v2/https'`. The v1 namespace import (`import * as functions from 'firebase-functions'`) signals legacy code. Reasons to *intentionally* stay on v1 are rare and worth a comment in the code.

7. **Pick the right database for the shape of the data.** Firestore for document-shaped, real-time-listened, sharded-by-key data. Realtime Database for presence + low-latency tiny-payload fan-out. Data Connect for relational + GraphQL with typed clients. Cloud Storage for blobs. Mixing them in one app is normal; bending one into another's shape is a smell.

8. **Bill awareness.** Firestore charges per document read/write, per GB stored, per GB egress. Cloud Functions charges per invocation + per CPU/memory-second. FCM is free. Crashlytics is free. App Hosting is Cloud Run + Cloud Build pricing. Before recommending a "listen to a 50k-doc collection in real time" pattern, do the math. If the user is building a side project, the free tier accommodates a lot; for production, model the per-user cost.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Generic GCP IAM / VPC / networking patterns beyond Firebase's slice | `stack-gcp` overlay (separate pack) |
| Deep mobile architecture not specific to Firebase | `mobile-architect` core reference |
| Compliance specifics for healthcare / fintech / regulated work | `healthcare-architect` / `fintech-architect` verticals |
| Non-Firebase backend service that integrates with Firebase | `backend-architect` core reference (without this overlay) |
| Search beyond Firestore vector search (e.g., Algolia, Typesense) | `database-architect` core reference |
| Streaming + windowing analytics pipelines | `database-architect` / GCP overlay (BigQuery + Dataflow) |
| Email / SMS delivery (Firebase doesn't own these) | Firebase Extensions for trigger email; otherwise route to `backend-architect` for SendGrid/Twilio/Resend integration |

## Stack composition

If the user is using Firebase **plus** GCP directly (e.g., BigQuery, Pub/Sub, Cloud Tasks beyond Firebase's slice, dedicated VPCs), both `stack-firebase` and `stack-gcp` overlays load. This pack handles the Firebase surface (Auth, Firestore, Functions, Hosting, FCM, Genkit, AI Logic, etc.); the GCP pack handles the broader cloud (BigQuery analytics warehouse, Dataflow pipelines, Cloud SQL administration deeper than what Data Connect surfaces, VPC + IAM at scale). Don't pretend to know the other pack's depth; cross-reference and route.

Common multi-stack compositions:

- **Firebase + Stripe** — Firebase Extensions has community-maintained Stripe payment extensions; for production you typically write your own Cloud Functions to call the Stripe API with webhooks. Stripe overlay (if registered) handles the Stripe surface.
- **Firebase + Algolia/Typesense** — Firebase has community-maintained extensions; for production-grade search you typically run a Cloud Function on Firestore writes that mirrors to the search index. Route search architecture to `database-architect`.
- **Firebase + Vercel/Cloudflare** — common for monorepos that ship a Next.js app on Vercel/Cloudflare and back it with Firestore + Functions. App Hosting is the Google-native alternative.

## Currency — when this pack is stale

This pack's `last_verified_on` is `2026-05-14`. If today's date is more than 6 months past that, the pack is stale and you should:

1. Warn the user that the Firebase overlay is past its verification window.
2. Cross-check any time-sensitive claim against the [Firebase Release Notes](https://firebase.google.com/support/release-notes), [Firebase Blog](https://firebase.blog/), and the relevant delegate skill's docs.
3. Treat product names with elevated suspicion — Firebase has renamed three products in a 12-month window (Project IDX → Firebase Studio, Vertex AI in Firebase → Firebase AI Logic, ongoing Identity Platform tier rebrands).
4. For Cloud Functions runtime versions, check the active list — Node.js and Python runtimes deprecate on a rolling schedule.

The drift-check protocol lives in `skills/etyb/core/knowledge-currency.md`; this pack feeds into it.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- No dedicated `system-architect` overlay for Firebase. The decision frameworks (Firebase vs raw GCP vs Vercel; App Hosting vs Hosting+Functions; Firestore vs Data Connect; Firebase Auth vs Identity Platform vs WorkOS/Auth0) are scattered across the five role overlays. A dedicated `system-architect.md` overlay is a reasonable v4.1 addition.
- No dedicated `qa-engineer` overlay. Emulator-based testing patterns appear in backend-architect, mobile-architect, and security-engineer overlays — a dedicated QA overlay would consolidate them.
- No dedicated `devops-engineer` overlay. CI/CD via GitHub Actions + Firebase CLI service tokens, App Hosting rollouts, Functions canaries, environment isolation across `dev`/`stage`/`prod` projects — currently summarized in backend-architect and mobile-architect overlays.
- No Firebase Extensions authoring depth. The pack covers Extensions as a consumer; authoring an Extension for the marketplace is a separate discipline (ISV-side) and would warrant `saas-architect` overlay work.
- No Crashlytics / Performance Monitoring deep-dive on Web JS. Mobile is well covered; web observability is touched lightly in frontend-architect.

If a user's request hits any of these gaps, say so explicitly and proceed with the closest available role overlay plus the relevant delegate skill.

## Stack glossary — names you must get right

| Old name (training data may say this) | Current name (2026) |
|---------------------------------------|---------------------|
| Project IDX | **Firebase Studio** |
| Vertex AI in Firebase | **Firebase AI Logic** |
| `@firebase/vertexai` | **`@firebase/ai`** |
| Firebase Cloud Functions v1 (namespace import) | **Cloud Functions gen 2** (`firebase-functions/v2/...`) |
| FCM legacy HTTP / `fcm.googleapis.com/fcm/send` | **FCM HTTP v1** (`fcm.googleapis.com/v1/projects/...`) |
| Namespaced Web SDK v8 (`firebase.auth()`) | **Modular Web SDK v9+** (`getAuth(app)`) |
| Cloud Datastore | **Firestore in Datastore mode** (when you mean the persistence option) |
| GA for Firebase | **GA4** (the same product line) |
| Identity Platform (as a separate product) | **Firebase Authentication with Identity Platform** (a project-level upgrade toggle) |

Use the current names. Anchor product references to the current docs URLs from `authoritative_sources` above.
