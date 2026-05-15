---
title: Firebase
description: Firebase platform overlay — Auth/Identity Platform, Firestore, RTDB, Cloud Functions gen 2, App Hosting, FCM, Genkit, Firebase AI Logic, Data Connect, App Check. Current to 2026 Q2.
stack:
  vendor: firebase
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - backend-architect
    - frontend-architect
    - mobile-architect
    - ai-ml-engineer
    - security-engineer
  authoritative_sources:
    - { name: "Firebase Documentation",            url: "https://firebase.google.com/docs",                              type: official_docs }
    - { name: "Firebase CLI Reference",            url: "https://firebase.google.com/docs/cli",                          type: cli_reference }
    - { name: "Firebase Release Notes",            url: "https://firebase.google.com/support/release-notes",             type: changelog }
    - { name: "Firebase Blog",                     url: "https://firebase.blog/",                                        type: community }
    - { name: "Genkit Documentation",              url: "https://firebase.google.com/docs/genkit",                       type: official_docs }
    - { name: "Firebase Data Connect Docs",        url: "https://firebase.google.com/docs/data-connect",                 type: official_docs }
    - { name: "Firebase AI Logic Docs",            url: "https://firebase.google.com/docs/ai-logic",                     type: official_docs }
    - { name: "Firebase App Hosting Docs",         url: "https://firebase.google.com/docs/app-hosting",                  type: official_docs }
    - { name: "Google Cloud Security Bulletins",   url: "https://cloud.google.com/support/bulletins",                    type: security_advisories }
  delegate_to_skills:
    - { skill: "firebase:firebase-basics",                 covers: ["Firebase overview", "project setup", "CLI"] }
    - { skill: "firebase:firebase-auth-basics",            covers: ["Firebase Authentication", "Identity Platform", "MFA", "custom claims"] }
    - { skill: "firebase:firebase-firestore",              covers: ["Cloud Firestore", "data modeling", "queries"] }
    - { skill: "firebase:firebase-hosting-basics",         covers: ["Firebase Hosting (static)"] }
    - { skill: "firebase:firebase-app-hosting-basics",     covers: ["Firebase App Hosting", "Next.js SSR", "Angular SSR"] }
    - { skill: "firebase:firebase-data-connect-basics",    covers: ["Firebase Data Connect", "Postgres-backed GraphQL"] }
    - { skill: "firebase:firebase-security-rules-auditor", covers: ["Firestore Rules", "Realtime DB Rules", "Storage Rules audit"] }
    - { skill: "firebase:firebase-ai-logic-basics",        covers: ["Firebase AI Logic", "Vertex AI in Firebase", "Gemini integration"] }
    - { skill: "firebase:developing-genkit-js",            covers: ["Genkit JavaScript/TypeScript"] }
    - { skill: "firebase:developing-genkit-python",        covers: ["Genkit Python"] }
    - { skill: "firebase:developing-genkit-go",            covers: ["Genkit Go"] }
    - { skill: "firebase:developing-genkit-dart",          covers: ["Genkit Dart/Flutter"] }
---

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2 — Firebase Studio (renamed from Project IDX), Firebase AI Logic (renamed from Vertex AI in Firebase), Cloud Functions gen 2 default, Firebase App Hosting GA, Firebase Data Connect GA, Genkit JS 1.x.</div>

If today's date is more than 6 months past the last_verified_on above, treat platform specifics with extra care — bias toward the [authoritative sources](#authoritative-sources) for time-sensitive claims. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness.

## What changed in 2025-2026 that older training data misses

- **Project IDX → Firebase Studio** (2025 rename). Same AI-first dev environment, deeper Firebase + Gemini integration. If you say "Project IDX" you're on stale knowledge.
- **Vertex AI in Firebase → Firebase AI Logic** (2025 rename). SDK package `@firebase/ai` replaces `@firebase/vertexai`. Mobile SDK class names rename to `FirebaseAI`.
- **Firebase App Hosting GA** (2024) — SSR-first deployment for Next.js + Angular on Cloud Run + Cloud Build. Replaces brittle "Hosting + Cloud Functions rewrites" stitching for SSR.
- **Firebase Data Connect GA** (2024-2025) — managed Cloud SQL Postgres + generated, typed GraphQL clients. Firebase now has a first-class relational option.
- **Cloud Functions gen 2 is the default** for new functions; Cloud Run-backed, concurrent requests per instance, different cold-start economics. Gen 1 on the deprecation roadmap.
- **Firestore multi-database per project** (GA 2024). Named DBs with independent rules, indexes, locations.
- **Firestore vector search** (GA 2024-2025) — `findNearest` for k-NN queries against `FieldValue.vector()` fields.
- **App Check Replay Protection** (GA 2024) — single-use tokens via `consumeAppCheckToken: true` on callable functions.
- **FCM legacy server APIs deprecated**. `fcm.googleapis.com/fcm/send` + Server Key headers are gone. Use HTTP v1 + OAuth-scoped service account or Admin SDK.
- **Firebase Auth ↔ Identity Platform convergence** (2024-2025). Same surface, project-level upgrade toggle for MFA + SAML/OIDC SSO + blocking functions.
- **Modular Web SDK v9+ is the only supported shape**. Namespaced v8 (`firebase.auth().*`) is legacy and tree-shakes badly.
- **Genkit JS GA** with `ai.defineFlow(...)` shape. Pre-1.0 module-scope `defineFlow(...)` is out of date.
- **Server-side Remote Config** (GA 2024) — per-request flag evaluation in SSR / Cloud Functions, not just client-side.
- **Apple Privacy Manifests** mandatory since 2024 — Firebase publishes its own; you incorporate into your app's combined manifest.

## Products covered

(Per-product pages link below.)

| Product | Drift risk | Why |
|---|---|---|
| [Firebase Authentication](/stacks/firebase/firebase-auth/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Identity Platform tier convergence; MFA + SSO + custom claims surfaces evolving; passkeys/WebAuthn on roadmap |
| [Identity Platform](/stacks/firebase/identity-platform/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Paid tier reachable from the same Auth surface; blocking functions + multi-tenancy + advanced security |
| [Cloud Firestore](/stacks/firebase/cloud-firestore/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Multi-database GA 2024; vector search GA; Datastore-mode option; new index/query semantics |
| [Realtime Database](/stacks/firebase/realtime-database/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable legacy; still right for true real-time presence + sub-100ms fan-out |
| [Cloud Storage for Firebase](/stacks/firebase/firebase-storage/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; rules surface unchanged; download URL + CORS still the recurring gotcha |
| [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Gen 2 (Cloud Run-backed) is the default; Gen 1 deprecation in motion; cold-start + concurrency model differ |
| [Firebase Hosting](/stacks/firebase/firebase-hosting/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Static-first; preview channels stable; SSR via App Hosting now preferred |
| [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2024 for Next.js + Angular SSR (Cloud Run + Cloud Build); roll-forward path |
| [Cloud Messaging (FCM)](/stacks/firebase/fcm/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Legacy HTTP/XMPP server APIs deprecated; HTTP v1 + Admin SDK only; APNs auth key rotation |
| [Remote Config](/stacks/firebase/remote-config/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Server-side Remote Config GA 2024; integrates with A/B Testing; drives prompt iteration |
| [A/B Testing](/stacks/firebase/ab-testing/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Integrated with Remote Config; goal metrics via GA4; experiment infra steady |
| [Performance Monitoring](/stacks/firebase/performance-monitoring/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Cloud Trace integration 2024-2025; custom traces + network monitoring; web SDK stable |
| [Crashlytics](/stacks/firebase/crashlytics/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Native + RN + Flutter SDKs stable; Apple privacy manifest + dSYM upload discipline non-negotiable |
| [Firebase Analytics (GA4)](/stacks/firebase/firebase-analytics/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Same SKU as GA4; Consent Mode v2 + Apple ATT compliance evolving |
| [App Distribution](/stacks/firebase/app-distribution/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Tester management + CI uploads stable; not a substitute for TestFlight/Play internal tracks |
| [Test Lab](/stacks/firebase/firebase-test-lab/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Real-device matrix narrowing post-2024; check current device coverage before committing |
| [Firebase Extensions](/stacks/firebase/firebase-extensions/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Marketplace expanded; v1 spec stable; some popular extensions community-maintained |
| [Firebase Studio](/stacks/firebase/firebase-studio/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Rebranded from Project IDX 2025; AI-first dev environment; surface still evolving |
| [Genkit](/stacks/firebase/genkit/) | <span class="etyb-drift-badge" data-risk="high">high</span> | JS GA; Python/Go/Dart maturing 2025-2026; API shape churned — anchor to current docs |
| [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Rebranded from Vertex AI in Firebase 2025; client-side Gemini with App Check; on-device Gemini Nano |
| [Firebase Data Connect](/stacks/firebase/firebase-data-connect/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Postgres-backed managed schema + generated GraphQL clients; GA 2024-2025 |
| [Security Rules](/stacks/firebase/security-rules/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Firestore + RTDB + Storage rules; rules unit testing via emulator; deny-by-default non-negotiable |
| [App Check](/stacks/firebase/app-check/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Replay Protection GA 2024; required production hardening of every Firebase backend |
| [Firebase CLI](/stacks/firebase/firebase-cli/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Active development; Data Connect + App Hosting + Studio commands added 2024-2025 |
| [Local Emulator Suite](/stacks/firebase/emulator-suite/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Auth, Firestore, RTDB, Storage, Functions, Pub/Sub, Eventarc, Hosting, Data Connect, Extensions emulated; the only sanctioned way to TDD Firebase |

## Role overlays

(Composed views — each stitches the products that role touches.)

- [`/stacks/firebase/backend-architect/`](/stacks/firebase/backend-architect/) — Cloud Functions gen 2, Admin SDK, Firestore data modeling, Data Connect, secrets, integration boundaries
- [`/stacks/firebase/frontend-architect/`](/stacks/firebase/frontend-architect/) — Modular Web SDK, App Hosting, Hosting + preview channels, App Check on the web, client Auth UX, Analytics + Consent Mode v2
- [`/stacks/firebase/mobile-architect/`](/stacks/firebase/mobile-architect/) — iOS/Android/Flutter/RN SDK integration, Crashlytics, FCM, App Check, Test Lab, Analytics, App Distribution
- [`/stacks/firebase/ai-ml-engineer/`](/stacks/firebase/ai-ml-engineer/) — Genkit (flows/tools/prompts/RAG/eval), Firebase AI Logic, on-device Gemini Nano, Firestore vector search
- [`/stacks/firebase/security-engineer/`](/stacks/firebase/security-engineer/) — Security Rules, App Check + Replay Protection, Identity Platform MFA/SSO/blocking functions, secrets management, OWASP mapping

## Authoritative sources

For verified-current behavior, defer to the official Firebase surfaces:

- **[Firebase Documentation](https://firebase.google.com/docs)** — canonical reference
- **[Firebase Release Notes](https://firebase.google.com/support/release-notes)** — current release log
- **[Firebase CLI Reference](https://firebase.google.com/docs/cli)** — command surface
- **[Firebase Blog](https://firebase.blog/)** — product announcements
- **[Genkit Documentation](https://firebase.google.com/docs/genkit)** — flows/tools/prompts/eval
- **[Firebase Data Connect Docs](https://firebase.google.com/docs/data-connect)** — schema + generated clients
- **[Firebase AI Logic Docs](https://firebase.google.com/docs/ai-logic)** — client-side Gemini surface
- **[Firebase App Hosting Docs](https://firebase.google.com/docs/app-hosting)** — Next.js/Angular SSR deployment
- **[Google Cloud Security Bulletins](https://cloud.google.com/support/bulletins)** — CVE / advisory feed

## Delegate skills

A user environment with the `firebase:*` skills installed gets deeper, product-specific guidance for the heavy products — Firestore, App Hosting, Data Connect, AI Logic, Genkit per language, Security Rules auditing. This Stack overlay is the orchestrator briefing; for product-level depth, defer to the delegate skill the user has loaded.

When delegate skills are present, ETYB routes:

- **`firebase:firebase-basics`** — project setup, CLI commands
- **`firebase:firebase-auth-basics`** — Auth flows, MFA, custom claims
- **`firebase:firebase-firestore`** — data modeling, queries, indexes, vector search
- **`firebase:firebase-hosting-basics`** — static Hosting deep dive
- **`firebase:firebase-app-hosting-basics`** — Next.js / Angular SSR deployment
- **`firebase:firebase-data-connect-basics`** — schema authoring, generated SDKs
- **`firebase:firebase-security-rules-auditor`** — rules audit + unit testing
- **`firebase:firebase-ai-logic-basics`** — AI Logic SDK, Gemini integration, App Check
- **`firebase:developing-genkit-js`** / **`-python`** / **`-go`** / **`-dart`** — Genkit per language

If no delegate is available, this Stack has enough opinionated content to ship correctly.

## Stack composition

Firebase is a curated slice of Google Cloud. If the user is also using GCP directly (BigQuery, Pub/Sub beyond Firebase's slice, dedicated VPCs, Cloud SQL administration deeper than Data Connect surfaces), both the Firebase and GCP Stack overlays load — this Stack handles Firebase products; GCP handles the broader cloud.

Common cross-Stack compositions:

- **Firebase + Stripe** — Firebase Extensions has community-maintained Stripe payment extensions; production typically uses your own Cloud Functions + Stripe webhooks.
- **Firebase + Algolia / Typesense** — community extensions exist; production search typically mirrors Firestore writes to the search index.
- **Firebase + Vercel / Cloudflare** — common for monorepos shipping Next.js on Vercel/Cloudflare backed by Firestore + Functions. App Hosting is the Google-native alternative.

## Compliance composition — when verticals stack

The Firebase platform has BAA-eligible products (Firestore, Cloud Functions, Cloud Storage, Auth, FCM, Hosting, App Hosting under Google Cloud's HIPAA-compliant SKUs), but enabling a BAA does not make your *application* HIPAA-compliant — only the underlying services. Compliance work composes with the vertical specialists:

| Vertical | Firebase-side (this stack) | Vertical-side (defer) |
|----------|----------------------------|------------------------|
| **healthcare-architect (HIPAA)** | Which products under GCP BAA; App Check + Identity Platform MFA; audit logging via Cloud Logging | FHIR data modeling, PHI discipline, breach notification, BAA contracting |
| **fintech-architect (PCI, PSD2, banking)** | Firestore + Functions are NOT a ledger; use Cloud SQL via Data Connect or dedicated ledger. Auth flows for SCA. App Check for fraud | Ledger semantics, PCI scope reduction, KYC/AML flows, PSD2 SCA |
| **saas-architect** | Multi-tenancy patterns on Firestore; Identity Platform tenants; per-tenant Custom Claims; Remote Config segmentation | Pricing/packaging, billing, tenant lifecycle, ISV distribution |
| **real-time-architect** | RTDB vs Firestore listener fan-out vs FCM push; App Hosting + Cloud Run WebSockets boundaries | Pub/sub architecture, presence systems, ordering beyond Firebase primitives |

When a Firebase engagement crosses one of these verticals, both overlays load.

## Stack glossary — names you must get right

| Old name (training data may say this) | Current name (2026) |
|---------------------------------------|---------------------|
| Project IDX | **Firebase Studio** |
| Vertex AI in Firebase | **Firebase AI Logic** |
| `@firebase/vertexai` | **`@firebase/ai`** |
| Cloud Functions v1 (namespace import) | **Cloud Functions gen 2** (`firebase-functions/v2/...`) |
| FCM legacy HTTP / `fcm.googleapis.com/fcm/send` | **FCM HTTP v1** (`fcm.googleapis.com/v1/projects/...`) |
| Namespaced Web SDK v8 (`firebase.auth()`) | **Modular Web SDK v9+** (`getAuth(app)`) |
| Cloud Datastore | **Firestore in Datastore mode** (when you mean the persistence option) |
| GA for Firebase | **GA4** (the same product line) |
| Identity Platform as a separate product | **Firebase Authentication with Identity Platform** (project-level toggle) |

Use the current names. Anchor product references to the current docs URLs from the [authoritative sources](#authoritative-sources) list.
