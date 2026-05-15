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

# Firebase Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Firebase knowledge lives.

## Where the full briefing lives

Per-product and per-role pages are maintained at **[docs.etyb.ai/stacks/firebase](https://docs.etyb.ai/stacks/firebase/)** with `last_verified_on` stamps and authoritative-source URLs. ETYB fetches from those URLs at runtime — see `skills/etyb/core/knowledge-currency.md` for the fetch contract.

- **Stack index:** <https://docs.etyb.ai/stacks/firebase/>
- **Per-product pages:** `https://docs.etyb.ai/stacks/firebase/<product>/`
- **Per-role views:** `https://docs.etyb.ai/stacks/firebase/<role>/` — composed views for each role in `applies_to_roles` above

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first; docs.etyb.ai is the curated fallback.

## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Project IDX is now Firebase Studio** (renamed 2025). Same product surface, new branding, deeper Firebase + Gemini integration. If you say "Project IDX" you're using the old name.
- **Vertex AI in Firebase is now Firebase AI Logic** (renamed 2025). The client-side Gemini SDK that talks to either Vertex AI or the Gemini Developer API behind App Check. The name change matters because the SDK packages were renamed too (`@firebase/ai` replaces `@firebase/vertexai`).
- **Firebase App Hosting GA** (2024) — the SSR-aware successor for Next.js and Angular. Cloud Run + Cloud Build under the hood, GitHub-integrated, replaces the brittle "Hosting + Cloud Functions rewrites" pattern that everyone built circa 2022.
- **Firebase Data Connect GA** (2024-2025) — managed Cloud SQL Postgres + GraphQL with generated, typed clients. Firebase now has a first-class relational option; "Firebase = NoSQL only" is out of date.
- **Cloud Functions Gen 2 is the default** for new functions, backed by Cloud Run with concurrent request handling, better cold-start economics, and a different deploy/runtime model. Gen 1 is on the deprecation roadmap — write all new code on v2 (`firebase-functions/v2`).
- **Firestore multi-database per project** (GA 2024). You can now provision multiple Firestore databases per project (named, distinct rules, distinct locations). This replaces "one project per database scope" workarounds.
- **App Check Replay Protection** (GA 2024) — single-use App Check tokens for callable functions, defending against captured-token replay. Worth enabling on every privileged path.
- **FCM legacy HTTP and XMPP server APIs are deprecated**. Use **HTTP v1 API** or the Admin SDK. Old code calling `fcm.googleapis.com/fcm/send` with a server key will break — that endpoint was sunset.
- **Firebase Authentication ↔ Identity Platform** convergence (2024-2025). The classic Firebase Auth tier and the paid Identity Platform tier (with MFA, SAML/OIDC SSO, advanced security) share the same surface and billing model now; "upgrading to Identity Platform" is a project toggle, not a re-architecture.
- **Modular Web SDK is the only supported shape** for `firebase` v9+. Namespaced v8 imports (`firebase.auth().signInWithEmailAndPassword(...)`) are legacy and tree-shake badly. New code uses tree-shakable modular imports.
- **Genkit JS GA**, with Python, Go, and Dart maturing through 2025-2026. Genkit's flow/tool/prompt API has churned multiple times — any sample older than mid-2024 likely has out-of-date shapes (`defineFlow` → `ai.defineFlow` etc.).

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Fetch the current page from docs.etyb.ai before continuing.

## Standing instructions for every role on a Firebase engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, fetch the relevant docs.etyb.ai page and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **App Check on every privileged backend in production.** Cloud Functions, Firestore, Storage, RTDB, Data Connect, AI Logic. Enable in monitoring/shadow mode first to size the impact; enforce after a clean week.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Firebase | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Firebase alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
