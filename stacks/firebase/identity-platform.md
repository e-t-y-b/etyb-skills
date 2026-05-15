---
title: Identity Platform
description: The paid tier of Firebase Authentication — MFA, SAML/OIDC SSO, blocking functions, multi-tenancy, advanced security. Same SDK, same project, toggle to enable.
product:
  name: Identity Platform
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect, saas-architect]
  authoritative_url: https://cloud.google.com/identity-platform/docs
  notes: "Auth tier convergence 2024-2025; passkeys/WebAuthn on roadmap; SAML/OIDC SSO + blocking functions GA."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Identity Platform is the paid tier of [Firebase Authentication](/stacks/firebase/firebase-auth/). Since 2024-2025, the free Auth tier and the paid Identity Platform tier share the same project surface, SDKs, and billing model — "upgrading to Identity Platform" is a project-level toggle, not a re-platform or library swap. Identity Platform adds:

- **Multi-factor authentication** (TOTP, SMS, with phishing-resistant factors on the roadmap)
- **SAML 2.0** and **OIDC** SSO for enterprise sign-in
- **Anonymous account upgrade** with data preservation
- **Advanced security** features — rate limiting per IP / per account, anomaly detection
- **Multi-tenancy** — multiple isolated tenants in one project
- **Blocking functions** — Cloud Functions invoked synchronously in the sign-up/sign-in flow to enforce custom checks
- Support and SLAs (free tier has none)

Canonical reference: [Identity Platform docs](https://cloud.google.com/identity-platform/docs).

## When to use it

**Upgrade to Identity Platform when:**

- Real users in production are at stake — MFA is non-negotiable for any compliance posture
- You need SAML 2.0 or OIDC SSO for B2B customers' enterprise IdPs
- You need blocking functions to enforce sign-up gating (disposable email blocking, corporate domain requirements, country fencing)
- You need multi-tenancy for a B2B SaaS where customer organizations are isolated
- You need the advanced security signals — anomaly detection, per-IP rate limiting

The free Firebase Auth tier is fine for prototypes, side projects, and consumer apps where you can defer compliance work. **Anything handling real users in production should be on Identity Platform.**

## 2025-2026 currency anchors

- **Tier convergence** (2024-2025) — Auth and Identity Platform are now one product surface with a tier toggle. Old docs that describe Identity Platform as "a separate product you migrate to" are out of date.
- **Blocking functions in `firebase-functions/v2/identity`** — `beforeUserCreated` and `beforeUserSignedIn` are the gen 2 shape. Older `firebase-functions` v1 identity imports are legacy.
- **Passkeys / WebAuthn** on the roadmap; check current docs for GA status.
- **MFA enrollment** — server-side enrollment via Admin SDK now supported alongside client-driven enrollment.

## Patterns

### MFA enforcement

```ts
// Server (Admin SDK) — enroll a phone factor
import { getAuth } from "firebase-admin/auth";
await getAuth().updateUser(uid, {
  multiFactor: {
    enrolledFactors: [{ phoneNumber: "+15551234567", displayName: "My phone", factorId: "phone" }]
  }
});
```

Don't gate MFA behind "user opts in if they want." For high-privilege roles (admins, finance), enforce MFA via a blocking function — if the user lacks an MFA factor, deny access to privileged paths or force enrollment during sign-in.

### Blocking functions

```ts
import { beforeUserCreated, beforeUserSignedIn } from "firebase-functions/v2/identity";

export const blockDisposableEmail = beforeUserCreated((event) => {
  const email = event.data.email ?? "";
  if (isDisposable(email)) {
    throw new HttpsError("invalid-argument", "Disposable email domains not allowed.");
  }
  return {};
});

export const requireCorporateDomain = beforeUserSignedIn((event) => {
  const email = event.data.email ?? "";
  if (!email.endsWith("@acme.com")) {
    throw new HttpsError("permission-denied", "Corporate email required.");
  }
  return {};
});
```

Blocking functions run **synchronously inside the auth flow** — they add latency, so keep them fast. Common uses:

- Block sign-up from suspicious origins or countries you don't operate in
- Require email domain
- Set initial custom claims based on email domain
- Mint a tenant assignment on first sign-in
- Force MFA enrollment for high-privilege roles before the session activates

### Multi-tenancy

Identity Platform tenants are isolated user pools within one project. Each tenant has its own users, sign-in methods, and configurations. Pair with:

- **Per-tenant Custom Claims** (`tenantId` on every user)
- **Tenant-scoped Security Rules** (`request.auth.token.tenantId == resource.data.tenantId`)
- **Remote Config segmentation** per tenant
- **Per-tenant Firestore subcollections or named multi-databases**

See the [saas-architect role on Firebase](/stacks/firebase/security-engineer/#identity-platform) for the broader pattern.

### SAML / OIDC SSO for B2B

For B2B customers, configure SAML 2.0 or OIDC providers per tenant. The customer's IT admin owns user lifecycle in their IdP; Firebase Auth federates. Don't try to maintain a local mirror — federate.

## Anti-patterns

- **Optional MFA for privileged roles** — if your admin can disable their MFA, an attacker who phishes them once can disable it too. Enforce.
- **Trusting custom claims as the only signal** for tenant isolation — pair with Security Rules that check `request.auth.token.tenantId` matches `resource.data.tenantId`.
- **Custom claims with PII** — claims travel in the ID token; treat them as observable. Use opaque IDs and look up details server-side.

## Gotchas

- **Claims update only on token refresh** — same gotcha as base Auth. When you set a tenant assignment in a blocking function, the client sees it after the next refresh or `getIdToken(true)`.
- **Blocking function timeouts** — your function runs inside the auth flow. A slow blocking function = slow sign-in. Cap at low single-digit seconds.
- **1000-byte cap on the entire custom claims object** — put references (`tenantId`), not full objects. Look up details server-side.
- **MFA enrollment requires recent sign-in** — the client must re-authenticate before enrolling factors. Plan the UX.

## Cross-references

- [Firebase Authentication](/stacks/firebase/firebase-auth/) — the base tier
- [Security Rules](/stacks/firebase/security-rules/) — `request.auth.token.<claim>` is set by Identity Platform claims
- [App Check](/stacks/firebase/app-check/) — pair with Identity Platform for sign-up abuse defense
- [security-engineer overlay](/stacks/firebase/security-engineer/) — Identity Platform setup checklist
- Authoritative: [cloud.google.com/identity-platform/docs](https://cloud.google.com/identity-platform/docs)
