---
title: Firebase Hosting
description: Static + edge hosting with custom domains, free TLS, preview channels, and rewrites. The right call for SPAs and static sites; SSR moved to App Hosting.
product:
  name: Firebase Hosting
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, devops-engineer]
  authoritative_url: https://firebase.google.com/docs/hosting
  notes: "Static-first; preview channels stable; SSR via App Hosting now preferred for new SSR apps."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Hosting serves static files (HTML/JS/CSS/images) from a global CDN, with custom domain support, free TLS, and rewrites that can proxy to Cloud Functions. Edge points-of-presence worldwide. Free tier covers most small apps.

For SSR apps (Next.js, Angular), use [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/) — purpose-built and worth migrating to for new builds.

Canonical reference: [Firebase Hosting docs](https://firebase.google.com/docs/hosting).

## When to use it

**Use Firebase Hosting when:**

- Static site (marketing, blog, docs)
- Single-page app with a separate API (Cloud Functions, Cloud Run, or any backend)
- PWA shell + Firestore-driven content (no SSR needed)
- You want preview channels with per-PR URLs

**Use Firebase App Hosting when:**

- Next.js or Angular with SSR
- You need streaming SSR
- You need WebSocket support
- You need Cloud Build-driven GitHub-integrated deploys

## 2025-2026 currency anchors

- **Preview channels** stable and well-integrated with the Firebase GitHub Action.
- **SSR via Hosting + Cloud Functions rewrites** still works but App Hosting is the modern path for new apps.
- **Web Frameworks integration** (auto-detects Next.js/Angular/Nuxt/etc.) is now superseded by App Hosting for SSR — Hosting handles purely static output.

## Patterns

### `firebase.json` for a static SPA

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

Auto-generated URL like `https://my-project--preview-pr-42-abc123.web.app`. Use the [Firebase Hosting GitHub Action](https://github.com/marketplace/actions/deploy-to-firebase-hosting) to automate per-PR previews. Channels expire automatically (7-day default); cleanup is handled.

Preview channels share Firebase Auth state with production (same project), so social sign-in works on previews without OAuth redirect URL juggling. Channels share data too — pair with rule guards if previews can mutate prod-shaped data.

### Custom domains

Adding a custom domain in the Firebase Console provisions a free managed TLS cert (Let's Encrypt). Set DNS to point to the provided A/AAAA records. Propagation takes hours; the cert issues automatically once DNS resolves.

## Anti-patterns

- **Hosting + Functions rewrites for a new Next.js SSR app** — use App Hosting instead. Hosting + Functions stitching for SSR is the 2022 pattern.
- **Permissive CSP headers** — `unsafe-eval` for Firebase JS isn't needed. Tight CSP.
- **`firebase deploy` from a developer laptop to production** — no CI gating. Use CI with Workload Identity Federation.
- **No Cache-Control on hashed assets** — you're paying for the CDN bandwidth on every page load. Hashed JS/CSS should be `max-age=31536000, immutable`.
- **`Cache-Control: no-cache` on HTML without a hash-based asset strategy** — every page load fetches assets fresh. Hashed bundles fix this.

## Gotchas

- **Rewrites that point at a Cloud Function in a non-matching region** — silent 404 or cross-region latency. Pin region in the rewrite block.
- **Preview channel URL contains the channel name** — short channel names = shorter URLs. Long auto-generated names from CI may exceed share-friendly lengths.
- **DNS propagation for custom domains** can take 24+ hours before the cert is issued. Plan launch timing.
- **`firebase.json` headers are case-sensitive** in `source` glob patterns on some platforms.
- **Hosting + Functions invocations** are billed as Function invocations — `/api/**` rewrites that match a static asset accidentally will burn function quota.

## Cross-references

- [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/) — SSR successor
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — backing API for rewrites
- [Firebase CLI](/stacks/firebase/firebase-cli/) — deploy commands
- [frontend-architect overlay](/stacks/firebase/frontend-architect/#firebase-hosting--static--edge) — Hosting + preview workflow
- Authoritative: [firebase.google.com/docs/hosting](https://firebase.google.com/docs/hosting)
