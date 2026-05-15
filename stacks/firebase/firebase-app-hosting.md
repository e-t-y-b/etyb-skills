---
title: Firebase App Hosting
description: SSR-first deployment for Next.js + Angular — Cloud Run + Cloud Build backed, GitHub-integrated, framework-aware. The modern Firebase SSR path.
product:
  name: Firebase App Hosting
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, devops-engineer, backend-architect]
  authoritative_url: https://firebase.google.com/docs/app-hosting
  notes: "GA 2024 for Next.js + Angular SSR (Cloud Run + Cloud Build under the hood); replaces brittle 'Hosting + Cloud Functions rewrites' for SSR."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase App Hosting is the SSR-aware deployment surface for Next.js and Angular. It connects to a GitHub repository, builds your app on Cloud Build, deploys to a Cloud Run service (the "backend"), and fronts it with a Firebase Hosting CDN for static assets. Per-request SSR hits the Cloud Run service; static assets are served from the CDN.

GA'd in 2024 — replaces the brittle "Hosting + Cloud Functions rewrites" pattern that teams built circa 2022 for SSR. App Hosting is purpose-built for the framework.

Canonical reference: [Firebase App Hosting docs](https://firebase.google.com/docs/app-hosting).

## When to use it

**Use App Hosting when:**

- Next.js or Angular with SSR
- Streaming SSR is part of the architecture
- You want GitHub-native CI flow (push to branch → Cloud Build → deploy)
- WebSocket support is needed (Cloud Run feature)
- You're already on Firebase and want a Google-native alternative to Vercel

**Use Vercel / Cloudflare instead when:**

- You need Vercel-specific features (Edge Config, OG image generation, deep Next.js middleware)
- Your stack centers on Cloudflare (Workers, R2, KV)
- Cost model preference

**Use Firebase Hosting (static) when:**

- SPA or pure static site
- No per-request SSR
- You can defer dynamic to client-side data fetching

## 2025-2026 currency anchors

- **GA 2024.** Pre-2024 references to "Web Frameworks on Firebase Hosting" were an experimental precursor — App Hosting is the productized successor.
- **Cloud Build + Cloud Run pipeline** is the deployment model. Build logs in Cloud Build; runtime logs in Cloud Logging.
- **`apphosting.yaml`** is the configuration file — checked into your repo.
- **Secrets via Cloud Secret Manager**, referenced in `apphosting.yaml` with `secret: <name>`.
- **Rollouts versioned per deploy**; traffic can be split or rolled back via the console.

## Patterns

### Setup

```bash
firebase init apphosting
```

Creates `apphosting.yaml` and configures a backend in the Firebase Console connected to a branch. Pushes to the connected branch trigger Cloud Build → deploy.

### `apphosting.yaml`

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

### Region pinning

Pick the same region as your Firestore database. Cross-region latency on every SSR fetch is silent and adds up.

### Custom domains

Managed in App Hosting console; TLS handled.

### Rollouts

Every deploy creates a new revision. Cloud Run supports traffic splitting between revisions — promote/canary via the console.

### SSR + Admin SDK pattern

For server components / route handlers / server actions in Next.js App Router, use the **Firebase Admin SDK** (`firebase-admin/*`) — the Admin SDK runs with the App Hosting backend's runtime service account, which has Editor-level access to the project by default (scope it down to needed roles).

Client components use the Firebase **JS Modular SDK** (`firebase/auth`, `firebase/firestore`, etc.) with App Check and Auth state.

Don't mix them blindly. Server side = Admin SDK; client side = JS SDK.

## Anti-patterns

- **App Hosting backend in a different region from Firestore** — hidden cross-region latency on every request.
- **Stitching App Hosting + parallel Cloud Functions APIs without a clear demarcation** — overlapping concerns. Either App Hosting owns all UI + APIs (typical), or carve out specific webhook receivers / scheduled jobs to Cloud Functions and document the split.
- **Putting secrets in `env` inline** — use Secret Manager (`secret: <name>`).
- **`minInstances: 0` for latency-critical apps** — cold starts hit user-perceived latency.
- **Mismatched `availability: [BUILD, RUNTIME]`** — public `NEXT_PUBLIC_*` envs typically need both; server-only secrets only need `RUNTIME`.

## Gotchas

- **Cloud Run cold starts apply.** Set `minInstances: 1` for latency-critical apps (see [Cloud Functions](/stacks/firebase/cloud-functions-firebase/) for cold-start economics).
- **Build is on Cloud Build**, not your laptop. CI peculiarities (large `node_modules`, native binaries) surface here.
- **Cloud Build quota** can throttle frequent pushes during dev.
- **GitHub repo permissions** — App Hosting needs read access to the repo. Org-level restrictions can block.
- **Build env vs runtime env** — `NEXT_PUBLIC_*` typically needs build-time exposure; server secrets need runtime only. Mismatch causes hard-to-diagnose blank values.

## App Hosting vs Hosting + Function rewrites

| | App Hosting | Hosting + Function rewrites |
|--|-------------|------------------------------|
| **SSR** | First-class | Manual stitching |
| **Streaming SSR (Next.js)** | Supported | Limited |
| **Build process** | Cloud Build, framework-aware | Local build, manual upload |
| **GitHub integration** | Native | Via custom CI |
| **WebSocket support** | Yes (Cloud Run feature) | No (Functions don't do WebSockets) |
| **Cold start affects user-perceived latency** | Yes (mitigate with `minInstances`) | Yes (each function invocation) |
| **Best for** | Next.js, Angular SSR | Static SPA + API |

For new SSR apps: App Hosting. Existing Hosting + Functions apps can stay until App Hosting parity covers their setup.

## Cross-references

- [Firebase Hosting](/stacks/firebase/firebase-hosting/) — static sibling
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — cold-start economics shared with App Hosting (same Cloud Run substrate)
- [App Check](/stacks/firebase/app-check/) — protect App Hosting endpoints + AI Logic calls from the SSR layer
- [frontend-architect overlay](/stacks/firebase/frontend-architect/#firebase-app-hosting--ssr-for-nextjs--angular) — App Hosting setup deep dive
- [security-engineer overlay](/stacks/firebase/security-engineer/#app-hosting-vs-hostingfunctions-from-a-security-lens) — security posture comparison
- Authoritative: [firebase.google.com/docs/app-hosting](https://firebase.google.com/docs/app-hosting)
