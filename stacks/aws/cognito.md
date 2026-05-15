---
title: Cognito
description: AWS managed user authentication — User Pools for auth, Identity Pools for AWS credential federation, managed login + passkey support 2024-2025, app-client-per-tenant pattern for SaaS.
product:
  name: Cognito
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect, saas-architect, fintech-architect]
  authoritative_url: https://docs.aws.amazon.com/cognito/
  notes: "User Pools + Identity Pools stable; managed login + passkey support 2024-2025; advanced security pricing changed."
---

## What it is

Amazon Cognito is the managed user auth + federation service — **User Pools** for authentication (signup, signin, MFA, federation to OIDC/SAML IdPs), **Identity Pools** for federated AWS credentials (let an authenticated user get temp AWS credentials to call S3 / DynamoDB directly).

Canonical surface: [docs.aws.amazon.com/cognito](https://docs.aws.amazon.com/cognito/).

## When to use

| Need | Use Cognito? |
|---|---|
| B2C user auth (signup, signin, social) | Yes |
| B2B SaaS with enterprise SSO | Yes — app-client-per-tenant federation |
| Mobile/web client → AWS resources directly | Yes — Identity Pools |
| Internal AWS access (humans) | No — use [IAM Identity Center](/stacks/aws/iam/) |
| Auth0 / Clerk / WorkOS for advanced features | Consider alternatives; Cognito has gaps for some flows |

## 2025-2026 currency anchors

- **Managed login + passkey (WebAuthn / FIDO2) support** matured 2024-2025.
- **Advanced security pricing changed** — verify current tier costs.
- **JWT authorizers** integrate natively with [API Gateway HTTP API](/stacks/aws/api-gateway/).
- **SAML 2.0 + OIDC federation** mature for enterprise IdPs (Okta, Entra ID, Auth0, OneLogin).

## Patterns

### Basic user pool

```typescript
const userPool = new cognito.UserPool(this, 'TenantUsers', {
  signInAliases: { email: true },
  mfa: cognito.Mfa.REQUIRED,
  mfaSecondFactor: { sms: false, otp: true },
  passwordPolicy: {
    minLength: 12,
    requireDigits: true,
    requireLowercase: true,
    requireUppercase: true,
    requireSymbols: true,
  },
  accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
  customAttributes: {
    tenant: new cognito.StringAttribute({ mutable: false }),
    role: new cognito.StringAttribute({ mutable: true }),
  },
});
```

### One pool vs many for SaaS

| Approach | Use when |
|---|---|
| **One pool, tenant as custom attribute** | Pool / bridge tenancy; tenant routing happens in the app via the `tenant` claim |
| **Pool per tenant** | Silo tenancy; tenant-specific branding, password policies, federation configs |
| **Pool per federation source** | Enterprise SSO — each tenant brings their own IdP (Okta / Entra / etc.); federate to a per-tenant pool or app client in a shared pool |

For B2B SaaS supporting enterprise SSO, **app client per tenant** in a shared pool is a common pattern: same user pool, per-tenant identity provider config.

### JWT claims for tenant context

```javascript
// Cognito JWT
{
  "sub": "user-uuid",
  "email": "user@acme.com",
  "custom:tenant": "acme",
  "custom:role": "admin",
  "exp": ...,
  ...
}
```

[API Gateway JWT authorizer](/stacks/aws/api-gateway/) validates the token; the `custom:tenant` claim is passed to Lambda. **Never** rely on a request body field for tenant ID — derive from the authenticated identity, server-side.

### Federation — enterprise SSO

- **SAML 2.0** for enterprise IdPs (Okta, Entra ID, OneLogin, ADFS).
- **OIDC** for modern IdPs.
- **Social** (Google / Facebook / Apple) — typically B2C.

Customer-facing config: customer provides metadata URL or XML; you wire it into their app client. **Tenant-scoped** via app client per tenant.

### Passkeys (WebAuthn / FIDO2)

Managed login UI supports passkeys 2024-2025. Configure in user pool advanced security settings. Pair with risk-based auth for PSD2 SCA / WebAuthn-based MFA.

### Identity Pools — when

Cognito Identity Pools are for **AWS resource access** — let an authenticated user get temporary AWS credentials.

Use when:
- Mobile/web client must talk directly to AWS (e.g., S3 upload with tenant-scoped IAM).
- You want to avoid an API tier for some operations.

**Don't use for** primary auth — User Pools are auth, Identity Pools are AWS credential federation.

## Anti-patterns

- **No MFA in production user pools.** MFA mandatory.
- **Weak password policy.** Minimum 12 chars + complexity.
- **One pool for all tenants without app client isolation.** Tenant federation is per-app-client.
- **Storing app-side user records that duplicate Cognito state.** Source of truth in Cognito; cache identifying claims in app side if needed.
- **Identity Pools as primary auth.** Use User Pools for auth, Identity Pools only for AWS credential federation.
- **Long JWT TTLs.** 1-hour default is reasonable; longer requires careful risk analysis.
- **Custom signup flow that bypasses Cognito triggers.** Use pre-signup / post-confirmation Lambda triggers.

## Gotchas

- **Cognito custom attributes are immutable after creation** unless `mutable: true` set.
- **JWT validation requires the JWKS endpoint** — clients should cache the JWKS but refresh on key rotation.
- **Advanced security features (compromised credentials, adaptive auth)** are paid tier.
- **MFA enforcement modes** — OPTIONAL vs ON; ON forces all users.
- **App client secret** vs no-secret — public clients (mobile/SPA) don't have secrets; backend clients do.
- **Pre-token-generation Lambda trigger** can mutate claims — useful for adding tenant scoping at JWT issuance time.

## Cross-references

- [`/stacks/aws/api-gateway/`](/stacks/aws/api-gateway/) — JWT authorizer integration
- [`/stacks/aws/iam/`](/stacks/aws/iam/) — Identity Center for humans; Cognito for app users
- [`/stacks/aws/saas-architect/`](/stacks/aws/saas-architect/) — role view; multi-tenant patterns
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — role view; user-pool config
- [Cognito User Pool docs](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)
