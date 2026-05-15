---
title: frontend-architect on Firebase
description: Composed role view — Modular Web SDK, Firebase App Hosting + Hosting, client Auth UX, real-time Firestore + offline, App Check on the web, Analytics + Consent Mode v2.
role_overlay:
  role: frontend-architect
  stack: firebase
  last_verified_on: "2026-05-14"
  products_covered: [firebase-hosting, firebase-app-hosting, firebase-auth, cloud-firestore, firebase-storage, app-check, firebase-analytics, performance-monitoring, remote-config, firebase-ai-logic, emulator-suite]
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## Role briefing

You are frontend-architect on a Firebase engagement. Your surface is the **Firebase JavaScript Modular SDK** (`firebase` v10+ npm package), **[Firebase Hosting](/stacks/firebase/firebase-hosting/)** for static apps, and **[Firebase App Hosting](/stacks/firebase/firebase-app-hosting/)** for SSR (Next.js, Angular). The platform expects modern, tree-shakable, edge-aware web apps — not 2018-era namespaced bundles.

What's distinctive vs. principle-level frontend-architect:

- **Modular SDK or bust.** Namespaced v8 (`firebase.auth()`) is dead for new code — doesn't tree-shake, adds ~150kb unconditionally.
- **App Hosting handles SSR**, not Hosting + Function rewrites for new apps.
- **App Check on the web** is reCAPTCHA Enterprise, initialized before any other Firebase service.
- **SSR + Admin SDK** is the server-side pattern; client uses JS SDK.

## Decision frameworks specific to frontend-architect on Firebase

### Hosting vs App Hosting

| Pick [Hosting](/stacks/firebase/firebase-hosting/) if | Pick [App Hosting](/stacks/firebase/firebase-app-hosting/) if |
|----------------|---------------------|
| Static SPA | Next.js or Angular SSR |
| Marketing site / docs | App needs per-request HTML rendering |
| Mostly static, few APIs (use Functions rewrites) | App needs streaming SSR / WebSockets |
| Free tier matters | App needs GitHub-native CI flow |

### Firebase Auth UI: pre-built vs custom

| | Pre-built (FirebaseUI / drop-in) | Custom |
|--|----------------------------------|--------|
| **Time to ship** | Hours | Days+ |
| **Brand consistency** | Limited | Full control |
| **MFA UX** | Out of box | You build it |
| **Best for** | Internal tools, MVPs | Consumer-facing apps with brand requirements |

### Client-side Firestore vs server-rendered initial state

| | Client-side | Server-rendered |
|--|-------------|------------------|
| **Time to first paint** | After client JS loads + Firestore round trip | Immediate |
| **SEO** | Bad | Good |
| **Reactivity** | Real-time via `onSnapshot` | Static (or re-fetch on action) |
| **Best for** | Live-updating dashboards, chat | Public pages, content-heavy |

Hybrid is common: SSR the initial state with Admin SDK on App Hosting; subscribe to updates from the client.

### App Hosting vs Vercel

App Hosting is comparable to Vercel for Next.js — auto SSR, ISR, preview deployments, image optimization. App Hosting wins when your stack centers on Firebase / GCP; Vercel wins for Vercel-specific features (Edge Config, OG generation, deep middleware).

## Product references

### [Firebase Hosting](/stacks/firebase/firebase-hosting/)

Static + edge serving with custom domains, free TLS, rewrites, preview channels. Use for SPAs and static sites. Preview channels share Firebase Auth state with production (same project) — social sign-in works on previews without OAuth juggling.

### [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/)

SSR-first deployment for Next.js + Angular. Cloud Run + Cloud Build backed, GitHub-integrated. `apphosting.yaml` configures `runConfig` (minInstances, maxInstances, concurrency, CPU, memory) and env vars / secrets. **Pin App Hosting region to match Firestore region** — cross-region latency adds up.

### [Firebase Authentication](/stacks/firebase/firebase-auth/) — client-side UX

Standard combo for consumer web: **Google + Email/Password + Apple** (Apple mandatory on iOS with third-party sign-in). Pop-up vs redirect: detect mobile, use redirect; pop-up on desktop. Render auth-dependent UI only after `onAuthStateChanged` initial state has been determined to avoid flash of signed-out UI.

### [Cloud Firestore](/stacks/firebase/cloud-firestore/) — client-side

Real-time listeners via `onSnapshot`. **Detach on component unmount** — leaked listeners cost reads continuously. Offline persistence via `persistentLocalCache` for PWAs and offline-first apps. Pagination via `startAfter(documentSnapshot)`, never offset.

Cost discipline:
- Every `where()` is a fan-out
- Every `onSnapshot` callback fires on every changed doc
- For dashboards with many widgets, prefer SSR initial state + client subscriptions only for live-updating widgets

### [Cloud Storage for Firebase](/stacks/firebase/firebase-storage/)

Client uploads via the Web Modular SDK; server-signed URLs for sensitive downloads. CORS must be configured on the bucket via `gsutil cors set` — most common Storage bug on the web.

### [App Check](/stacks/firebase/app-check/) on the web

reCAPTCHA Enterprise is the production-grade provider. Initialize **before any other Firebase service**:

```ts
const app = initializeApp(firebaseConfig);

if (typeof window !== "undefined") {
  initializeAppCheck(app, {
    provider: new ReCaptchaEnterpriseProvider(RECAPTCHA_KEY),
    isTokenAutoRefreshEnabled: true,
  });
}
```

Debug provider gated to dev only — never ship in prod code paths.

### [Firebase Analytics (GA4)](/stacks/firebase/firebase-analytics/) on the web

Same SDK as mobile but web-flavored. **Consent Mode v2** is required for EEA traffic — `setConsent(...)` before logging events. No PII in user properties or event parameters.

### [Performance Monitoring](/stacks/firebase/performance-monitoring/) — web

Auto-captures page load (LCP-like) and network requests. Custom traces for user-critical paths (checkout, search, login).

### [Remote Config](/stacks/firebase/remote-config/) — client + server

Client-side fetch via `fetchAndActivate` for feature flags. Server-side Remote Config (2024 GA) usable in SSR / server components for per-request flag evaluation.

### [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) — client-side Gemini

`@firebase/ai` package (not `@firebase/vertexai` — old name). Direct client-to-Gemini with App Check enforcement. Use for client-driven prompts where data isn't server-secret.

## 2025-2026 platform-reset items relevant to frontend-architect

- **Namespaced v8 SDK is dead** for new code. Migrate v8 sites on sight.
- **App Hosting GA** — preferred SSR deployment.
- **Vertex AI in Firebase → Firebase AI Logic** rebrand. `@firebase/ai` replaces `@firebase/vertexai`.
- **Firestore vector search GA** — `findNearest` from the Web SDK.
- **App Check via reCAPTCHA Enterprise** is the production standard.
- **Server-side Remote Config GA** (2024) — Next.js server components / Angular SSR for per-request flag evaluation.
- **Consent Mode v2** for EEA Analytics traffic.

## Patterns

### Tree-shakable modular imports

```ts
import { initializeApp } from "firebase/app";
import { getAuth, onAuthStateChanged, signInWithEmailAndPassword } from "firebase/auth";
import { getFirestore, collection, query, where, onSnapshot, addDoc } from "firebase/firestore";
import { getStorage, ref, uploadBytes } from "firebase/storage";
```

A typical app on modular imports ships ~30kb of Firebase JS. A v8-style app ships ~150kb. **Migrate v8 on sight.**

### Bundle-size hygiene

- Use `firestore-lite` if you only need CRUD (no real-time, no offline)
- Lazy-load Analytics, Performance, Remote Config — initialize on demand
- Init App Check **before** other services
- Init Analytics last

### SSR + Admin SDK pattern

The Firebase JS SDK is browser-centric — many APIs assume `window`. For SSR contexts (Next.js server components, Angular SSR):

- **Server side:** use Firebase Admin SDK (`firebase-admin/*`) with the runtime service account
- **Client side:** use the regular Firebase JS Modular SDK

Auth flow: client signs in via JS SDK → client gets ID token → client sets a signed, secure, HttpOnly cookie → server validates the cookie via Admin SDK `verifyIdToken`.

### TDD on the frontend with Firebase

1. **Unit tests** for components don't touch Firebase — mock the data layer.
2. **Integration tests** point at the [Local Emulator Suite](/stacks/firebase/emulator-suite/):
   ```ts
   if (window.location.hostname === "localhost") {
     connectAuthEmulator(auth, "http://localhost:9099");
     connectFirestoreEmulator(db, "localhost", 8080);
   }
   ```
3. **E2E tests** (Playwright / Cypress) run against the emulator suite.

### Verification checklist

- [ ] Bundle size measured; Firebase JS under ~50kb
- [ ] App Check init before any service call
- [ ] Listeners detach on unmount
- [ ] Auth state cookies sized + signed correctly for SSR
- [ ] Hosting headers (CSP, Cache-Control, X-Frame-Options) set
- [ ] App Hosting `apphosting.yaml` reviewed for region, secrets, min-instances
- [ ] Analytics events match the GA4 schema; no PII
- [ ] Consent Mode v2 wired for EEA users
- [ ] Performance traces on critical paths

### Debugging

- **Firebase Web SDK debug logging:** `setLogLevel("debug")` from `firebase/app`.
- **Firestore listeners not firing:** check rules first (rules failures are silent on the client; the request just gets `permission-denied`).
- **App Check failures:** browser console shows `appCheck/recaptcha-error`; check that the reCAPTCHA Enterprise key is for the right project and the right domains.
- **Auth redirect loops:** check `authDomain` in `firebaseConfig` matches the actual serving domain.

## Frontend footguns on Firebase

- **Namespaced v8 imports** — 150kb of Firebase JS for no reason.
- **Listeners not detached on unmount** — read costs continue, connection stays open.
- **App Check not initialized before other services** — first calls go unprotected.
- **Debug App Check provider shipping to production** — backdoor.
- **`getDownloadURL()` for sensitive content** — long-lived, hard-to-revoke public URL.
- **Auth state-dependent UI rendered before initial auth check completes** — flash of wrong content.
- **Firestore queries without `.limit()`** — cost time bomb.
- **`onSnapshot` on hot queries** — cost + render thrash.
- **PII in Analytics user properties** — GA4 rejects, but only after transmission.
- **Hosting CSP that allows `unsafe-eval`** — Firebase doesn't need it. Tight CSP.
- **SSR + JS SDK calling `signIn*` server-side** — those APIs need `window`. Use Admin SDK on server.
- **App Hosting backend in a different region from Firestore** — hidden cross-region latency.
- **`firebase deploy` from a developer laptop** — no CI gating. Use CI with WIF.

## Cross-references

- [backend-architect overlay](/stacks/firebase/backend-architect/) — SSR Admin SDK patterns, Cloud Functions integration
- [mobile-architect overlay](/stacks/firebase/mobile-architect/) — mobile Auth UX parity
- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — calling AI Logic from the client
- [security-engineer overlay](/stacks/firebase/security-engineer/) — App Check + reCAPTCHA Enterprise hygiene
- [Firebase stack index](/stacks/firebase/) — products + role overlay map
