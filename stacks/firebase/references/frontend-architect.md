---
role: frontend-architect
stack: firebase
last_verified_on: "2026-05-14"
---

# Firebase Overlay — frontend-architect

You are frontend-architect on a Firebase engagement. Your surface is the **Firebase JavaScript Modular SDK** (`firebase` v10+ npm package, v9 was the original modular release; current major versions ship monthly-ish), **Firebase Hosting** for static apps, and **Firebase App Hosting** for SSR (Next.js, Angular). The platform expects modern, tree-shakable, edge-aware web apps — not 2018-era namespaced bundles.

**Currency:** 2026 Q2. Firebase JS SDK v10+ (modular only; namespaced v8 is legacy), Firebase App Hosting GA for Next.js + Angular, Firebase Hosting preview channels stable, App Check via reCAPTCHA Enterprise standard.

## What changed in 2025-2026 that older training data misses

- **Namespaced v8 SDK is dead** for new code. `import firebase from "firebase/app"; firebase.auth().signInWithEmailAndPassword(...)` is the v8 shape — it doesn't tree-shake, it adds ~150kb of unused services unconditionally, and the docs no longer feature it. **All new code uses modular imports.**
- **Firebase App Hosting GA** (2024) — SSR-first deployment for Next.js + Angular. Cloud Run + Cloud Build backed, GitHub-integrated, framework-aware. Replaces the brittle "Hosting + Cloud Functions rewrites" pattern for SSR apps.
- **Vertex AI in Firebase → Firebase AI Logic** (2025 rebrand). Package `@firebase/ai` replaces `@firebase/vertexai`. The Web SDK supports client-side Gemini with App Check enforcement.
- **Firestore vector search** is a Web SDK feature (2024) — clients can issue `findNearest` queries.
- **App Check via reCAPTCHA Enterprise** is standard for web; reCAPTCHA v3 still works but Enterprise gives better fraud signals and adaptive thresholds.
- **Server-side Remote Config** (2024) — usable from Next.js server components / Angular SSR for per-request flag evaluation, not just client-side.
- **Consent Mode v2** for Google Analytics — EEA traffic requires it; consent state affects what events GA4 stores.

If you find yourself recommending namespaced v8 imports, Hosting + Function rewrites for a new Next.js SSR app, or AI Logic without App Check on the client — read on.

## Firebase JS SDK — modular discipline

### Tree-shakable imports

```ts
// MODERN — tree-shakable
import { initializeApp } from "firebase/app";
import { getAuth, onAuthStateChanged, signInWithEmailAndPassword } from "firebase/auth";
import { getFirestore, collection, query, where, onSnapshot, addDoc } from "firebase/firestore";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { getFunctions, httpsCallable } from "firebase/functions";

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
```

```ts
// LEGACY — don't write new code here
import firebase from "firebase/app";
import "firebase/auth";
import "firebase/firestore";

firebase.initializeApp(firebaseConfig);
firebase.auth().signInWithEmailAndPassword(...);
```

A typical app on modular imports ships ~30kb of Firebase JS. A v8-style app ships ~150kb regardless of what it uses. **Migrate v8 code on sight.**

### Bundle-size hygiene

- **Don't import `firebase/firestore` if you only need `firestore-lite`** — `firestore-lite` is a smaller package (no real-time listeners, no offline persistence) for apps that only need CRUD.
- **Lazy-load Firebase services** that aren't needed on first render. Auth + the data layer typically need to load early; Storage / Functions / Analytics / Performance / Remote Config can dynamic-import on demand.
- **Init order matters.** Initialize App Check before any other service. Initialize Analytics last (it's deferrable).

```ts
// Critical-path init
const app = initializeApp(firebaseConfig);

if (typeof window !== "undefined") {
  initializeAppCheck(app, {
    provider: new ReCaptchaEnterpriseProvider(RECAPTCHA_KEY),
    isTokenAutoRefreshEnabled: true,
  });
}

const auth = getAuth(app);
const db = getFirestore(app);

// Lazy
const loadFunctions = () => import("firebase/functions").then(m => m.getFunctions(app));
const loadAnalytics = () => import("firebase/analytics").then(m => m.getAnalytics(app));
```

### SSR considerations

The Firebase JS SDK is **browser-centric** — many APIs assume `window`. When you run it in a Node server context (Next.js server components, Angular SSR), you have two paths:

1. **Use the Firebase Admin SDK** (`firebase-admin/*`) for privileged server-side work. Bypasses Security Rules. Use the runtime service account.
2. **Use the regular Firebase JS SDK** for unauthenticated public reads or for SSR where you want rules-enforced access. Pass the user's ID token explicitly to authenticate server-side reads in a multi-tenant SSR context.

Don't mix them blindly. Server components on App Hosting often use Admin SDK; client components use the JS SDK.

For Auth specifically in SSR contexts: the Firebase JS SDK's `signInWith*` APIs **require `window`** — they can't run server-side. The pattern is: client signs in via JS SDK → client gets ID token → client sends ID token to your server (as a cookie or header) → server validates with Admin SDK `verifyIdToken`.

### Web SDK in different framework runtimes

| Framework | Firebase SDK usage |
|-----------|-------------------|
| **Next.js (App Router)** | Modular Web SDK in client components; Admin SDK in server components / route handlers / server actions |
| **Next.js (Pages Router)** | Same; Admin SDK in `getServerSideProps`/`API routes` |
| **Remix** | Modular Web SDK in client; Admin SDK in loaders/actions |
| **Angular (with SSR)** | `@angular/fire` wraps modular SDK; Admin SDK in server-side rendering layer |
| **SvelteKit** | Modular Web SDK in `+page.svelte`; Admin SDK in `+page.server.ts` |
| **Astro / Vite SSR** | Modular Web SDK in client islands; Admin SDK in server endpoints |
| **Plain Vite/React/Vue/Svelte SPA** | Modular Web SDK only |

`@angular/fire` and `react-firebase-hooks` (community) wrap the modular SDK in idiomatic framework patterns; both are reasonable choices if you're on Angular / React respectively.

## Firebase Hosting — static + edge

### What it is

Firebase Hosting serves static files (HTML/JS/CSS/images) from a CDN, with custom domain, free TLS, and rewrites. Edge points-of-presence worldwide. Free tier covers most small apps.

`firebase.json`:

```json
{
  "hosting": {
    "public": "dist",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      { "source": "/api/**", "function": "api" },
      { "source": "**", "destination": "/index.html" }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [{ "key": "Cache-Control", "value": "max-age=31536000, immutable" }]
      },
      {
        "source": "**/*.html",
        "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
      }
    ]
  }
}
```

Deploy: `firebase deploy --only hosting`.

### Preview channels — every PR gets a URL

```bash
firebase hosting:channel:deploy preview-pr-42 --expires 7d
```

Auto-generated URL like `https://my-project--preview-pr-42-abc123.web.app`. Use the [Firebase Hosting GitHub Action](https://github.com/marketplace/actions/deploy-to-firebase-hosting) to automate per-PR previews; comment URLs back on the PR.

Preview channels share Firebase Auth state with production (same project), so social sign-in works on previews without OAuth redirect URL juggling. Channels expire automatically (7d default); cleanup is handled.

### When Hosting alone is the right answer

- Static site (marketing, blog, docs)
- Single-page app with a separate API (the API can be Cloud Functions, Cloud Run, or any backend)
- PWA shell + Firestore-driven content (no SSR needed)

When you need SSR (per-request HTML rendering from server-side data), **use App Hosting**, not Hosting + Function rewrites.

## Firebase App Hosting — SSR for Next.js + Angular

### Architecture

App Hosting connects to a GitHub repository, builds your Next.js / Angular app on Cloud Build, deploys to a Cloud Run service (the "backend"), and fronts it with a Firebase Hosting CDN for static assets. Per-request SSR hits the Cloud Run service; static assets are served from the CDN.

### Setup

```bash
firebase init apphosting
```

This creates `apphosting.yaml` and (after answering questions about the repo) configures a backend in the Firebase Console connected to a branch. Pushes to the connected branch trigger Cloud Build → deploy.

`apphosting.yaml`:

```yaml
runConfig:
  minInstances: 1
  maxInstances: 100
  concurrency: 80
  cpu: 1
  memoryMiB: 512
env:
  - variable: NEXT_PUBLIC_FIREBASE_API_KEY
    value: AIza...
    availability: [BUILD, RUNTIME]
  - variable: STRIPE_SECRET
    secret: STRIPE_SECRET
    availability: [RUNTIME]
```

Secrets come from Cloud Secret Manager (`secret: STRIPE_SECRET`). Public env vars (`NEXT_PUBLIC_*`) can be inline. Sensitive runtime secrets are referenced, never inlined.

### App Hosting backends are Cloud Run services

Implications:

- **Cold starts apply.** Set `minInstances: 1` for latency-critical apps. Cloud Run cold-start economics — see backend-architect for the playbook.
- **Region matters.** Pick the same region as your Firestore database to avoid cross-region latency.
- **Custom domains** are managed in App Hosting console; TLS handled.
- **Rollouts** are versioned — every deploy creates a new revision; traffic can be split or rolled back via the console.
- **Build logs** are in Cloud Build; runtime logs in Cloud Logging.

### App Hosting vs Hosting + Function rewrites

| | App Hosting | Hosting + Function rewrites |
|--|-------------|------------------------------|
| **SSR** | First-class | Manual stitching |
| **Streaming SSR (Next.js)** | Supported | Limited |
| **Build process** | Cloud Build, framework-aware | Local build, manual upload |
| **GitHub integration** | Native | Via custom CI |
| **WebSocket support** | Yes (Cloud Run feature) | No (Functions don't do WebSockets) |
| **Cold start affects user-perceived latency** | Yes (mitigate with `minInstances`) | Yes (each function invocation) |
| **Best for** | Next.js, Angular SSR | Static SPA + API |

If you're on Next.js or Angular SSR and starting new, use App Hosting. Existing Hosting + Functions apps can stay until App Hosting parity covers their setup.

### App Hosting + Vercel parity question

App Hosting is broadly comparable to Vercel for Next.js — automatic SSR, ISR support, preview deployments on PRs, image optimization. Differences:

- App Hosting is GCP-native — natural fit if your data is in Firebase / GCP, your auth is Firebase Auth, your AI is on Vertex.
- Vercel has a richer DX around middleware, edge functions, and Next.js-specific features (Vercel makes Next.js).
- Cost models differ — App Hosting is Cloud Run + Cloud Build billing; Vercel is Vercel's pricing.

Pick App Hosting when your stack centers on Firebase. Pick Vercel when Next.js + Vercel-specific features (edge config, OG image generation, observability) are the priority.

## Firestore from the client — real-time and offline

### Real-time listeners

```ts
import { collection, query, where, orderBy, onSnapshot } from "firebase/firestore";

const q = query(
  collection(db, "messages"),
  where("roomId", "==", roomId),
  orderBy("createdAt", "desc"),
  limit(50)
);

const unsubscribe = onSnapshot(q, (snapshot) => {
  setMessages(snapshot.docs.map(d => ({ id: d.id, ...d.data() })));
});

// Detach when component unmounts!
return () => unsubscribe();
```

**Critical:** detach listeners on component unmount. Leaked listeners cost reads continuously and keep the user's connection open.

### Offline persistence

```ts
import { initializeFirestore, persistentLocalCache, persistentMultipleTabManager } from "firebase/firestore";

const db = initializeFirestore(app, {
  localCache: persistentLocalCache({
    tabManager: persistentMultipleTabManager(),
  }),
});
```

Persistent cache uses IndexedDB; survives page reloads. Multi-tab manager coordinates across tabs (one elected leader handles syncing). Without persistent cache, the client cache is in-memory only and dies on refresh.

For PWAs and offline-first apps, persistent cache is non-negotiable. The trade-off: IndexedDB has size limits (~50MB free, more with permission); your data should fit.

### Pagination — cursor-based

```ts
const first = query(collection(db, "posts"), orderBy("createdAt", "desc"), limit(20));
const firstSnap = await getDocs(first);
const last = firstSnap.docs[firstSnap.docs.length - 1];

const next = query(
  collection(db, "posts"),
  orderBy("createdAt", "desc"),
  startAfter(last),
  limit(20)
);
```

`startAfter(documentSnapshot)` is the canonical pattern. Don't paginate via offset (Firestore doesn't support efficient offsets); use cursors.

### Writing — atomic operations

```ts
import { runTransaction, doc, increment } from "firebase/firestore";

await runTransaction(db, async (tx) => {
  const snap = await tx.get(doc(db, "counters", "global"));
  tx.update(doc(db, "counters", "global"), { count: (snap.data()?.count ?? 0) + 1 });
});
```

Or batched writes for non-contention atomicity:

```ts
import { writeBatch } from "firebase/firestore";

const batch = writeBatch(db);
batch.set(doc(db, "orders", id), order);
batch.update(doc(db, "inventory", sku), { count: increment(-1) });
await batch.commit();
```

`FieldValue.increment(-1)` (or `increment` from modular SDK) atomically decrements server-side without read-modify-write contention. Use for counters.

### Cost discipline from the client

- **Every `where()` is a fan-out.** A query returning 1000 docs = 1000 reads.
- **Every `onSnapshot` callback fires on every changed doc.** A query watching 1000 docs where each doc updates once per second = 1000 reads/second per client.
- **`getDocs()` from a previously-cached query still counts.** Cache-only reads exist (`getDocFromCache`); use them when freshness isn't required.
- **`get()` for navigation routing** that re-fetches the same docs on every page change wastes reads. Cache in state management (React Query, Pinia, etc.); selectively invalidate.

For dashboards with many widgets, prefer **server-rendered initial state** (via SSR + Admin SDK) and **client-side subscriptions only for live-updating widgets**.

## Authentication UX — what to actually build

### Sign-in methods on the web

```ts
import { GoogleAuthProvider, signInWithPopup, signInWithRedirect } from "firebase/auth";

const provider = new GoogleAuthProvider();
provider.setCustomParameters({ prompt: "select_account" });
const result = await signInWithPopup(auth, provider);
```

```ts
// Email/password
import { createUserWithEmailAndPassword, signInWithEmailAndPassword, sendEmailVerification } from "firebase/auth";
```

Standard combo for consumer web: **Google + Email/Password**. Add Apple if you also ship iOS. Add SAML/OIDC for enterprise (Identity Platform).

### Pop-up vs redirect

| | Pop-up | Redirect |
|--|--------|----------|
| **Mobile browsers** | Often blocked or awkward | Works |
| **Embedded webviews** | Fails | Works |
| **iOS PWA** | Limited | Works |
| **Multi-tab UX** | OK | Disrupts page state |
| **Default for web** | Reasonable | Better fallback |

Detect mobile + use redirect; pop-up on desktop. Some apps just always use redirect for consistency.

### Auth state observation

```tsx
import { onAuthStateChanged } from "firebase/auth";

useEffect(() => {
  return onAuthStateChanged(auth, (user) => {
    setUser(user);
    setLoading(false);
  });
}, []);
```

Render auth-dependent UI only after the initial auth state has been determined (`loading` flag). Otherwise you get a flash of signed-out UI before the cached session is restored.

### Token freshness for SSR / Admin SDK validation

```ts
const idToken = await user.getIdToken();        // current
const fresh = await user.getIdToken(true);      // force refresh (e.g., after custom claim change)
```

Cookie pattern for SSR:

```ts
// On sign-in / token refresh, set a cookie
document.cookie = `idToken=${idToken}; path=/; secure; samesite=strict; max-age=3600`;
```

Server reads cookie, validates with Admin SDK:

```ts
import { getAuth } from "firebase-admin/auth";
const decoded = await getAuth().verifyIdToken(cookies.idToken, /* checkRevoked */ true);
```

For Next.js App Router, this pattern lives in middleware + server actions.

## App Check on the web

```ts
import { initializeAppCheck, ReCaptchaEnterpriseProvider } from "firebase/app-check";

initializeAppCheck(app, {
  provider: new ReCaptchaEnterpriseProvider("YOUR_RECAPTCHA_ENTERPRISE_KEY"),
  isTokenAutoRefreshEnabled: true,
});
```

reCAPTCHA Enterprise is the production-grade provider for web. v3 still works but Enterprise has adaptive thresholds, better fraud signals, and the SDK ecosystem matches modern web app shapes.

In development, use the debug provider:

```ts
if (process.env.NODE_ENV === "development") {
  // @ts-ignore
  self.FIREBASE_APPCHECK_DEBUG_TOKEN = true;
}
```

This logs a debug token to the console on first run; add it to Firebase Console → App Check → Debug tokens. **Never** ship this in production code paths.

App Check on the web protects:
- Firestore reads/writes from the JS SDK
- Realtime Database connections
- Cloud Storage uploads/downloads
- Cloud Functions callable invocations
- AI Logic Gemini calls
- Authentication anti-abuse (sign-up rate limiting)

Enable in **monitoring mode** in Firebase Console first; watch failure rates; enforce after a clean week.

## Performance Monitoring — web

```ts
import { getPerformance, trace } from "firebase/performance";

const perf = getPerformance(app);

const t = trace(perf, "checkout_flow");
t.start();
// ...
t.stop();
```

Auto-captured:
- **Page load** (LCP-like metric, full-load duration)
- **Network requests** (every fetch/XHR with timing breakdown)

Custom traces for any user-flow you care about. The metrics show up in Firebase Console → Performance.

Cloud Trace integration (2024-2025) means web traces can correlate with backend Cloud Function / Cloud Run traces — useful for "the user's checkout took 3 seconds; where did the time go?"

## Firebase Analytics on web

```ts
import { getAnalytics, logEvent, setUserProperties } from "firebase/analytics";

const analytics = getAnalytics(app);

logEvent(analytics, "purchase", {
  currency: "USD",
  value: 42.99,
  items: [{ item_id: "sku1", item_name: "Pro plan", quantity: 1, price: 42.99 }],
});

setUserProperties(analytics, { subscription_tier: "pro" });
```

### Consent Mode v2

```ts
import { setConsent } from "firebase/analytics";

setConsent({
  ad_storage: "denied",
  ad_user_data: "denied",
  ad_personalization: "denied",
  analytics_storage: "granted",
});
```

Required for EEA traffic. Set consent before logging events. Default to denied; update when user grants.

### PII discipline

Same rules as mobile: no email, phone, full name in user properties or event parameters. Use enums and buckets.

### gtag.js coexistence

If your marketing team has gtag.js / GTM already on the page, the Firebase Analytics SDK can interfere. Pick one Analytics integration per page. Firebase Analytics is itself a GA4 client — using it gives you GA4 without extra script tags.

## Remote Config — client and server

### Client-side

```ts
import { getRemoteConfig, fetchAndActivate, getValue } from "firebase/remote-config";

const rc = getRemoteConfig(app);
rc.settings.minimumFetchIntervalMillis = 3600000;
rc.defaultConfig = { show_new_feature: false };

await fetchAndActivate(rc);
const showNewFeature = getValue(rc, "show_new_feature").asBoolean();
```

Use cases: feature flags, A/B test variant selection, server-driven copy, kill switches.

### Server-side (2024 GA)

Useful in SSR / Cloud Functions for per-request flag evaluation:

```ts
import { getRemoteConfig } from "firebase-admin/remote-config";

const template = await getRemoteConfig().getServerTemplate();
const config = template.evaluate({ /* user signals */ });
const variant = config.getString("paywall_variant");
```

Server-side Remote Config integrates with A/B Testing in console; you can ship variants per cohort with goal-metric tracking via GA4.

## Frontend footguns on Firebase

- **Namespaced v8 imports** — 150kb of Firebase JS for no reason. Migrate.
- **Listeners not detached on unmount** — read costs continue, connection stays open.
- **App Check not initialized before other services** — first calls go unprotected.
- **Debug App Check provider shipping to production** — backdoor.
- **`getDownloadURL()` for sensitive content** — long-lived, hard-to-revoke public URL. Use server-signed URLs.
- **Auth state-dependent UI rendered before initial auth check completes** — flash of wrong content.
- **Firestore queries without `.limit()`** — cost time bomb as the collection grows.
- **`onSnapshot` on a query that fires hundreds of doc updates per second** — cost + render thrash.
- **PII in Analytics user properties** — GA4 rejects, but only after transmission.
- **Hosting CSP headers that allow `unsafe-eval`** for Firebase JS — Firebase doesn't need `unsafe-eval`. Tight CSP.
- **SSR + Firebase Web SDK calling `signIn*` server-side** — those APIs need `window`. Use Admin SDK on server.
- **App Hosting backend in a different region from Firestore** — hidden cross-region latency on every request.
- **`firebase deploy` from a developer laptop to production** — no CI gating. Use CI with WIF.

## Decision frameworks

### Hosting vs App Hosting

| Pick Hosting if | Pick App Hosting if |
|----------------|---------------------|
| Static SPA | Next.js or Angular SSR |
| Marketing site / docs | App needs per-request HTML rendering |
| Mostly static, few APIs (use Functions rewrites) | App needs streaming SSR / WebSockets |
| Free tier matters | App needs the GitHub-native CI flow |

### Firebase Auth UI: pre-built vs custom

| | Pre-built (FirebaseUI / drop-in) | Custom |
|--|----------------------------------|--------|
| **Time to ship** | Hours | Days+ |
| **Brand consistency** | Limited | Full control |
| **MFA UX** | Out of box | You build it |
| **i18n** | Built-in | You build it |
| **Best for** | Internal tools, MVPs | Consumer-facing apps with brand requirements |

Most consumer apps build custom auth UI. Internal admin tools and quick MVPs often use FirebaseUI or similar drop-ins.

### Client-side Firestore vs server-rendered initial state

| | Client-side | Server-rendered |
|--|-------------|------------------|
| **Time to first paint** | After client JS loads + Firestore round trip | Immediate |
| **SEO** | Bad (content arrives after JS) | Good |
| **Reactivity** | Real-time via `onSnapshot` | Static (or re-fetch on action) |
| **Best for** | Live-updating dashboards, chat | Public pages, content-heavy sites |

Hybrid is common: SSR the initial state with Admin SDK on App Hosting; subscribe to updates from the client.

### Firestore vector search vs server-side search (Algolia/Typesense/Meilisearch)

| Use Firestore vector search if | Use dedicated search if |
|--------------------------------|-------------------------|
| Small corpus, semantic similarity primary | Large corpus, keyword + facets + ranking |
| Co-located with app data | Decoupled search infra |
| Embedding cost dominated by infrequent re-indexing | Large query volume, ranking flexibility matters |

## Integration with always-on protocols

### TDD on the frontend with Firebase

1. **Unit tests** for components don't touch Firebase — mock the data layer.
2. **Integration tests** point at the Local Emulator Suite:
   ```ts
   import { connectAuthEmulator } from "firebase/auth";
   import { connectFirestoreEmulator } from "firebase/firestore";
   if (window.location.hostname === "localhost") {
     connectAuthEmulator(auth, "http://localhost:9099");
     connectFirestoreEmulator(db, "localhost", 8080);
   }
   ```
3. **E2E tests** (Playwright / Cypress) run against the emulator suite — no production data risk, no quota burn.

### Verification

- [ ] Bundle size measured; Firebase JS under ~50kb
- [ ] App Check init before any service call
- [ ] Listeners detach on unmount (verified with React DevTools / Vue devtools)
- [ ] Auth state cookies sized + signed correctly for SSR
- [ ] Hosting headers (CSP, Cache-Control, X-Frame-Options) set
- [ ] App Hosting `apphosting.yaml` reviewed for region, secrets, min-instances
- [ ] Analytics events match the GA4 schema, no PII
- [ ] Consent Mode v2 wired for EEA users
- [ ] Performance traces on critical paths

### Debugging

- **Firebase Web SDK debug logging:** `setLogLevel("debug")` from `firebase/app`.
- **Firestore listeners not firing:** check rules first (rules failures are silent on the client; the request just gets `permission-denied`).
- **App Check failures:** browser console shows `appCheck/recaptcha-error` or similar; check that the reCAPTCHA Enterprise key is for the right project and the right domains.
- **Auth redirect loops:** check that `authDomain` in firebaseConfig matches the actual domain serving the app; mismatched authDomain causes infinite redirects.

## Cross-references

- App Check + reCAPTCHA Enterprise + debug provider hygiene: [`security-engineer.md`](security-engineer.md#app-check)
- Server-side rendering with Admin SDK in App Hosting: [`backend-architect.md`](backend-architect.md#firebase-admin-sdk--what-you-actually-do-with-it)
- Calling Genkit flows / AI Logic from the client: [`ai-ml-engineer.md`](ai-ml-engineer.md#firebase-ai-logic--the-client-side-gemini-surface)
- Mobile-side Auth UX parity: [`mobile-architect.md`](mobile-architect.md)

## Delegate skills

If the user environment has the Firebase skill suite, defer to:

- [`firebase:firebase-basics`](#) — CLI setup, project init
- [`firebase:firebase-hosting-basics`](#) — Hosting deep dive
- [`firebase:firebase-app-hosting-basics`](#) — App Hosting for Next.js / Angular
- [`firebase:firebase-auth-basics`](#) — Auth flow UX patterns
- [`firebase:firebase-firestore`](#) — query syntax, indexes
- [`firebase:firebase-ai-logic-basics`](#) — client-side Gemini integration

These delegate skills cover product-specific API depth and platform-specific behavior that this overlay summarizes.
