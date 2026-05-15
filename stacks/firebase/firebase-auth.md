---
title: Firebase Authentication
description: Firebase's identity product — sign-in methods, ID tokens, custom claims, and the free-tier base of the Authentication ↔ Identity Platform converged surface.
product:
  name: Firebase Authentication
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect, mobile-architect, security-engineer]
  authoritative_url: https://firebase.google.com/docs/auth
  notes: "Identity Platform tier convergence (2024-2025); MFA + SSO + custom claims surfaces evolving; passkeys/WebAuthn on the roadmap."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Authentication is Google's drop-in identity product for web and mobile clients. It manages sign-in via email/password, federated providers (Google, Apple, Microsoft, GitHub, Facebook, Twitter/X), phone (SMS OTP), email-link magic links, anonymous accounts, and custom-token bridging from external auth systems. It issues short-lived ID tokens (1-hour expiry, auto-refreshed by the SDK) that downstream Firebase services and your own backends validate via the Admin SDK.

Since 2024-2025, the free Firebase Authentication tier and the paid **Identity Platform** tier share the same project surface and SDK — see [Identity Platform](/stacks/firebase/identity-platform/) for the paid features (MFA, SAML/OIDC SSO, blocking functions, multi-tenancy, advanced security).

Canonical reference: [Firebase Authentication docs](https://firebase.google.com/docs/auth).

## When to use it

**Use Firebase Authentication when:**

- You're already on Firebase and want consumer auth with minimal lift
- Sign-in methods you need are covered (email/password, Google, Apple, Microsoft, GitHub, phone, anonymous, custom token)
- You don't need MFA, SAML, or OIDC SSO (free tier limit — upgrade to Identity Platform)
- You want ID tokens that Security Rules and the Admin SDK both understand natively

**Use a dedicated identity vendor (WorkOS, Auth0, Clerk, Stytch) when:**

- You need deep org/team management UI (WorkOS shines here for B2B)
- You need passwordless flows that aren't yet GA in Identity Platform
- You need an admin UI for impersonation / debugging that Firebase doesn't ship
- Compliance team has standardized on one of the others

See [security-engineer overlay](/stacks/firebase/security-engineer/) for the full decision matrix.

## 2025-2026 currency anchors

- **Firebase Auth ↔ Identity Platform convergence** (2024-2025) — upgrading is a project-level toggle, not a re-architecture. Same SDK, same APIs, additional features on the paid tier.
- **Passkeys / WebAuthn** are on the roadmap but not yet GA in all SDKs as of 2026 Q2. Check current docs before recommending.
- **Apple sign-in is mandatory** for any iOS app that offers third-party sign-in via the App Store (Apple's policy, not Firebase's).
- **`getAuth().verifyIdToken(token, /* checkRevoked */ true)`** — the `checkRevoked` flag adds a roundtrip to check the user's record for revocation. Use for sensitive operations.

## Sign-in methods — security characteristics

| Method | Security level | Notes |
|--------|----------------|-------|
| Email/password | Medium | Requires email verification flow; password reset attack surface |
| Magic link (email link) | Medium | Email account security = your account security |
| Phone (SMS OTP) | Medium-low | SIM-swap exposure; expensive; carrier abuse |
| Google / Apple / Microsoft / GitHub | High | Federated, MFA inherited from provider |
| Anonymous | Lowest | Useful for "try before sign-up"; graduate via account linking |
| Custom token | Depends | You're responsible for pre-Firebase auth path |
| Passkeys / WebAuthn (roadmap) | High | Phishing-resistant; not yet GA in all SDKs |

Standard combo for consumer web/mobile: **email/password + Google + Apple**. For B2B, upgrade to Identity Platform for SAML/OIDC.

## Patterns

### ID token lifecycle

- Tokens expire after 1 hour
- SDK auto-refreshes via the refresh token while the user has an active session
- Custom claim changes appear in the ID token **only after refresh** — force via `user.getIdToken(true)` after a server-side claim change
- For SSR contexts, the client sets the ID token as a cookie (signed, secure, HttpOnly), server reads and validates with `verifyIdToken`

### Pop-up vs redirect (web)

Detect mobile, use redirect; pop-up on desktop, or just always use redirect for consistency. Pop-ups fail in embedded webviews, iOS PWAs, and are awkward on mobile browsers. See [frontend-architect overlay](/stacks/firebase/frontend-architect/#authentication-ux--what-to-actually-build).

### Auth state observation

```ts
useEffect(() => {
  return onAuthStateChanged(auth, (user) => {
    setUser(user);
    setLoading(false);
  });
}, []);
```

Render auth-dependent UI only after the initial auth state has been determined. Otherwise you get a flash of signed-out UI before the cached session is restored.

### Custom token bridging

For users authenticated by some external system (legacy SSO, custom corporate auth):

1. User authenticates with external system
2. Your backend mints `getAuth().createCustomToken(uid, { ...claims })`
3. Backend returns custom token to client
4. Client calls `signInWithCustomToken(customToken)` — Firebase exchanges for a full session

Custom tokens are **single-use, 5-minute-lifetime** handoff tokens. Don't mint a custom token per request; exchange once, let Firebase manage the session.

## Anti-patterns

- **Trusting `email_verified` flag without re-checking** for sensitive changes. The flag is set after first verification click; for high-privilege operations, re-verify.
- **Server-side `signInWithEmailAndPassword`** — the JS SDK's `signIn*` APIs require `window`. SSR contexts use Admin SDK `verifyIdToken` against a token the client passed.
- **`createUserWithEmailAndPassword` from the client without rate limiting** — sign-up endpoints get abused. Use App Check + Identity Platform sign-up rate limits + blocking functions.
- **Anonymous accounts with no graduation or cleanup path** — they accumulate; attackers create thousands. Schedule a cleanup job for stale anonymous accounts.

## Gotchas

- **Auth ID tokens expire after 1 hour.** Custom claims in the ID token only update after the token refreshes — when you change claims server-side, the client sees the new claim only after `getIdToken(true)` is forced or after the next auto-refresh. Don't gate UI on stale claims.
- **`authDomain` in `firebaseConfig` mismatched with the actual serving domain** causes infinite redirect loops on social sign-in.
- **Preview channels share Auth state with production** (same project), so OAuth redirect URLs work without extra config — but it also means a preview channel can mutate prod auth data. Pair with rule guards.
- **Phone auth quota** — SMS OTP is rate-limited per project per day. Plan for the quota before relying on phone auth as a primary method.

## Cross-references

- [Identity Platform](/stacks/firebase/identity-platform/) — paid tier features (MFA, SAML/OIDC, blocking functions, multi-tenancy)
- [Security Rules](/stacks/firebase/security-rules/) — how `request.auth` and custom claims gate access
- [App Check](/stacks/firebase/app-check/) — protect Auth endpoints from sign-up abuse
- [security-engineer overlay](/stacks/firebase/security-engineer/) — full auth security checklist
- [frontend-architect overlay](/stacks/firebase/frontend-architect/) — web Auth UX
- [mobile-architect overlay](/stacks/firebase/mobile-architect/) — mobile Auth integration
- Authoritative: [firebase.google.com/docs/auth](https://firebase.google.com/docs/auth)
