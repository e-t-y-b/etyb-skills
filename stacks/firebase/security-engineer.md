---
title: security-engineer on Firebase
description: Composed role view — Security Rules, App Check + Replay Protection, Identity Platform MFA/SSO/blocking functions, secrets via Cloud Secret Manager, OWASP mapping.
role_overlay:
  role: security-engineer
  stack: firebase
  last_verified_on: "2026-05-14"
  products_covered: [security-rules, app-check, firebase-auth, identity-platform, cloud-functions-firebase, firebase-storage, cloud-firestore, realtime-database, firebase-data-connect, firebase-ai-logic, fcm]
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## Role briefing

You are security-engineer on a Firebase engagement. Firebase concentrates a lot of attack surface in client-facing SDKs that talk directly to managed backends — Firestore, RTDB, Storage, AI Logic. The security model is **client + [Security Rules](/stacks/firebase/security-rules/) + [App Check](/stacks/firebase/app-check/) + [Identity Platform](/stacks/firebase/identity-platform/)**. Get the rules wrong and a Firestore collection is world-readable. Skip App Check and your project ID is your only secret. Misconfigure custom claims and a user can elevate to admin.

What's distinctive vs. principle-level security-engineer:

- **Security Rules are public.** Anyone with the project ID can fetch them. Treat as enforcement, not secrecy.
- **App Check is non-negotiable in 2026.** Without it, anyone with the project ID can hit your backends as if they were your app.
- **Custom claims are the canonical auth mechanism** for server-set authorization data — 1000-byte cap, refresh-after-update behavior.
- **The Admin SDK has root access.** A leaked service account JSON is total compromise.

## Top-of-mind 2025-2026 changes

| Change | Effective | Implication |
|--------|-----------|-------------|
| **App Check Replay Protection** GA | 2024 | Single-use tokens for callable Functions; `consumeAppCheckToken: true` |
| **Identity Platform / Firebase Auth tier convergence** | 2024-2025 | MFA, SAML, OIDC reachable from same surface; upgrade is a toggle |
| **FCM legacy server APIs deprecated** | 2024 | `fcm.googleapis.com/fcm/send` + Server Key broken or about to be |
| **Apple Privacy Manifests required** for iOS | 2024 | Firebase publishes its own; you incorporate |
| **Consent Mode v2** for Analytics | 2024 | EEA without proper consent flags = compliance impact |
| **Vertex AI in Firebase → Firebase AI Logic rebrand** | 2025 | SDK package renamed; App Check on AI Logic is critical |
| **Functions gen 2 default** | 2024 | `enforceAppCheck` syntax differs from gen 1; secrets via `defineSecret` |
| **Workload Identity Federation matures** | 2024-2025 | Replace long-lived service account JSON in CI |

## Decision frameworks specific to security-engineer on Firebase

### Identity Platform vs WorkOS / Auth0 / Clerk / Stytch

| Pick [Identity Platform](/stacks/firebase/identity-platform/) if | Pick a dedicated identity vendor if |
|--------------------------|--------------------------------------|
| You're already on Firebase | Deep org/team management UI (WorkOS shines) |
| Consumer + B2B SSO in one product | Passwordless flows not yet GA in Identity Platform |
| Want MFA, blocking functions, custom claims in Firebase ecosystem | Admin UI for impersonation / debugging not in Firebase |
| Cost sensitivity | Compliance standardized on another vendor |

### Custom claims vs per-user Firestore doc

| | Custom claims | Firestore doc |
|--|---------------|---------------|
| **Read latency in rules** | Free (already in token) | Adds a `get()` per check |
| **Update latency** | Up to 1 hour (token refresh) | Immediate on doc write |
| **Size** | 1000 bytes total | Unbounded |
| **Server access** | Admin SDK only | Admin SDK or rules-gated client read |
| **Use for** | Role, plan tier, tenant ID, small enums | Permission matrices, feature flags, anything large/fast-changing |

Common pattern: **role/tenant in custom claims; granular permissions in Firestore.**

### App Hosting vs Hosting+Functions, from a security lens

[App Hosting's](/stacks/firebase/firebase-app-hosting/) Cloud Run backend supports IAM-based invocation control, Cloud Armor for WAF/DDoS, and direct integration with Cloud Identity-Aware Proxy. [Hosting](/stacks/firebase/firebase-hosting/) + Functions rewrites give you Firebase App Check on the function but no WAF — for any app with attack-surface-aware threat models, App Hosting + Cloud Armor is the stronger posture.

## Product references

### [Security Rules](/stacks/firebase/security-rules/)

Firestore + RTDB + Storage. **Deny by default.** Check `request.auth` and `request.app != null` on every privileged path. Validate `request.resource.data` on writes — shape, types, max sizes, no surprise fields. Use `get()` and `exists()` sparingly (cap at 10 per rule). **Unit-test every rule** with `@firebase/rules-unit-testing` against the [Local Emulator Suite](/stacks/firebase/emulator-suite/).

### [App Check](/stacks/firebase/app-check/)

Coverage: Firestore, RTDB, Storage, Functions, Data Connect, AI Logic, Auth (anti-abuse), FCM (token registration), Hosting (limited; set up Cloud Armor for full).

**Replay Protection** (`consumeAppCheckToken: true`) on every mutating callable. **Debug providers gated** behind `#if DEBUG` / `BuildConfig.DEBUG`. Staged rollout: install in clients → unenforced monitoring → wait a release cycle → enforce.

### [Firebase Authentication](/stacks/firebase/firebase-auth/) + [Identity Platform](/stacks/firebase/identity-platform/)

Tier convergence (2024-2025). Identity Platform adds MFA (TOTP/SMS), SAML 2.0, OIDC, anonymous account upgrade, advanced security (rate limiting, anomaly detection), multi-tenancy, blocking functions.

**MFA for high-privilege roles** is non-negotiable. Don't gate behind "user opts in." Enforce via blocking function.

**Custom claims:**
- 1000-byte cap on the entire claims object
- Claims update only on token refresh (or `getIdToken(true)`)
- Server-set, server-trusted
- Use for: role, plan, tenant ID

**Blocking functions** (`firebase-functions/v2/identity`):
- `beforeUserCreated` — block disposable emails, country fencing, set initial claims
- `beforeUserSignedIn` — require corporate domain, mint tenant assignment, force MFA enrollment

Keep blocking functions fast — they run synchronously in the auth flow.

### [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — security posture

- **Scope service accounts** — default `<project-id>@appspot.gserviceaccount.com` has Editor role, way more than most functions need. Create a dedicated service account, grant only needed IAM roles, set as the function's runtime service account.
- **`defineSecret`** for runtime secrets — integrates with Cloud Secret Manager.
- **`enforceAppCheck` + `consumeAppCheckToken`** for production callables.
- **Workload Identity Federation** for CI — replace long-lived `firebase login:ci` tokens.

### [Cloud Storage for Firebase](/stacks/firebase/firebase-storage/)

Size-bound uploads in rules. Content-type validate. Server-signed URLs for sensitive downloads, not long-lived `getDownloadURL()`.

### [Cloud Firestore](/stacks/firebase/cloud-firestore/) / [RTDB](/stacks/firebase/realtime-database/) / [Data Connect](/stacks/firebase/firebase-data-connect/)

Rules + App Check + custom claims. Data Connect adds `@auth(level: ...)` directives per operation. RTDB rules cascade open at parents — be wary.

### [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) — security-critical

Without App Check, a leaked client config + a botnet = a five-figure Gemini bill in hours. **Enforce App Check on AI Logic before going to production. Always.**

### [Cloud Messaging (FCM)](/stacks/firebase/fcm/)

HTTP v1 only. APNs auth keys over certificates. Topic subscription gated where it matters — bots subscribe to your topics if the binary leaks.

## Secrets management

### The rules

1. **Never** check `service-account.json`, `firebase login:ci` token, FCM keys, third-party API keys into git.
2. **Never** bake secrets into client bundles.
3. **Use Cloud Secret Manager** for runtime secrets in Cloud Functions: `defineSecret("STRIPE_KEY")`.
4. **Use Workload Identity Federation** for CI/CD — GitHub Actions ↔ Google Cloud short-lived tokens, no JSON.
5. **Rotate `firebase login:ci` tokens** on staff churn.
6. **Scope service accounts** — least privilege.

### Workload Identity Federation for CI

```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/123/.../providers/gh
    service_account: deploy@my-project.iam.gserviceaccount.com
- run: firebase deploy --only functions
```

No `FIREBASE_TOKEN` or service-account JSON in repo secrets.

## Logging and audit

- **Cloud Audit Logs** capture admin activity. Inspect via Cloud Logging; route to a SIEM via log sinks for compliance.
- **Firebase Auth events** — sign-in / sign-up / disable / delete events logged.
- **Cloud Functions logs** structured via `logger`. Log security-relevant events at `info` or `warn`.
- **App Check logs** — token validation outcomes in console + Cloud Logging. Sudden failure spike often = botnet.

### Don't log

- Raw passwords / OTPs / API keys / tokens — even at debug.
- Full PII payloads — log keys and hashes, not records.
- App Check tokens themselves.

## OWASP top-10 for Firebase

| OWASP | Firebase failure mode | Mitigation |
|-------|----------------------|-----------|
| A01 Broken Access Control | Permissive rules; missing custom-claim checks | Deny-by-default rules + custom claims + rules tests in CI |
| A02 Cryptographic Failures | Custom auth path mishandling passwords | Use Firebase Auth, not custom; if custom, Identity Platform import |
| A03 Injection | Dynamic Firestore field paths from user input | Validate / whitelist field names |
| A04 Insecure Design | "Trust client to send the right userId" | Use `request.auth.uid` server-side, never client's claim |
| A05 Security Misconfiguration | App Check off; debug provider shipped; default `appspot` SA | App Check enforced; debug providers gated; scoped SAs |
| A06 Vulnerable Components | Old `firebase-admin` with CVE | Renovate / Dependabot; pin to BoM (mobile) |
| A07 Identification/Auth Failures | No MFA; SMS-only second factor for admins | Identity Platform MFA; phishing-resistant for high-privilege |
| A08 Software/Data Integrity | Firebase CLI deploy from compromised CI; SA JSON leaked | WIF; rotate tokens; least-privilege SAs |
| A09 Logging/Monitoring | No audit log retention; no anomaly alerts | Audit Logs to BigQuery sink; alerts on rule changes, IAM changes, App Check spikes |
| A10 SSRF | Callable function fetching user-provided URL | Whitelist destinations |

## Verification checklist

- [ ] Security Rules: deny-by-default at the bottom of each rules file
- [ ] Security Rules: every collection / path has positive AND negative rules tests in CI
- [ ] App Check: enforced on Firestore, RTDB, Storage, Functions, Data Connect, AI Logic in production
- [ ] App Check: Replay Protection on every mutating callable function
- [ ] App Check: debug provider gated behind `#if DEBUG` / equivalent
- [ ] Identity Platform: MFA enforced on admin/high-privilege roles
- [ ] Identity Platform: blocking functions for sign-up gating
- [ ] Custom claims: scoped, server-set, under 1000 bytes total
- [ ] Service accounts: scoped to needed IAM roles, default `appspot` not used for privileged functions
- [ ] Secrets: in Cloud Secret Manager, never in env or git
- [ ] CI/CD: Workload Identity Federation, not long-lived JSON
- [ ] FCM: HTTP v1 API, OAuth-scoped, no legacy server keys
- [ ] Cloud Audit Logs: routed to a long-retention sink
- [ ] App Check failure rate: monitored with an alert
- [ ] Auth event anomalies: monitored

## Common security footguns on Firebase

- **Permissive rules in dev shipped to prod** — `allow read, write: if request.auth != null` is catastrophic.
- **App Check disabled "until we figure out the rollout"** — plan the rollout.
- **Debug provider not gated** — token forgeable; production accepts them = no App Check.
- **Service account JSON in git history** — even after `git rm`. Rotate immediately if exposed.
- **Trusting `request.resource.data.userId` over `request.auth.uid`** — client lies.
- **Custom claims with personal data** — claims travel in the ID token.
- **Anonymous accounts with no graduation path** — accumulate; attackers create thousands.
- **`createUserWithEmailAndPassword` from client without rate limiting** — abuse. Use App Check + Identity Platform rate limits + blocking functions.
- **Long-lived `getDownloadURL()`** — use signed URLs with short expiry.
- **Hosting headers don't apply to Functions** — set CSP at function response level if needed.
- **Not auditing rules drift** — PR-review rules changes; never direct console edits to "fix prod."
- **Trusting `email_verified` flag for high-privilege ops** — re-verify; don't trust the flag alone.

## Cross-references

- [backend-architect overlay](/stacks/firebase/backend-architect/) — Cloud Functions architecture; service account hygiene
- [frontend-architect overlay](/stacks/firebase/frontend-architect/) — client-side Auth + App Check on web
- [mobile-architect overlay](/stacks/firebase/mobile-architect/) — mobile App Check + FCM auth
- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — AI Logic billing protection
- [Firebase stack index](/stacks/firebase/) — products + role overlay map
