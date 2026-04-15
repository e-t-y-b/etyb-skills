# Identity and Access Management — Deep Reference

**Always use `WebSearch` to verify current protocol specs, IdP features, authorization tool versions, and passkey adoption data before giving advice. The identity landscape moves fast — new standards, deprecations, and provider changes happen quarterly.**

## Table of Contents
1. [OAuth 2.1 and OIDC](#1-oauth-21-and-oidc)
2. [Passkeys, WebAuthn, and FIDO2](#2-passkeys-webauthn-and-fido2)
3. [Identity Providers](#3-identity-providers)
4. [Authorization Models (RBAC, ABAC, ReBAC)](#4-authorization-models-rbac-abac-rebac)
5. [Fine-Grained Authorization Engines](#5-fine-grained-authorization-engines)
6. [Session Management](#6-session-management)
7. [MFA and Phishing-Resistant Authentication](#7-mfa-and-phishing-resistant-authentication)
8. [SSO and Federation](#8-sso-and-federation)
9. [Machine-to-Machine Authentication](#9-machine-to-machine-authentication)
10. [Cloud IAM Patterns](#10-cloud-iam-patterns)
11. [Privileged Access Management](#11-privileged-access-management)
12. [IAM Architecture Decision Framework](#12-iam-architecture-decision-framework)

---

## 1. OAuth 2.1 and OIDC

### OAuth 2.1 (draft-ietf-oauth-v2-1-15, March 2026)

OAuth 2.1 is at **draft-15** (March 2026), not yet a published RFC but its principles are widely adopted. It consolidates OAuth 2.0 best practices and obsoletes RFC 6749/6750. **RFC 9700** ("OAuth 2.0 Security Best Current Practice", published January 2025) serves as its theoretical foundation.

**Key changes from OAuth 2.0:**

| Change | OAuth 2.0 | OAuth 2.1 |
|--------|-----------|-----------|
| **PKCE** | Optional (RFC 7636) | **Required** for all authorization code grants |
| **Implicit grant** | Allowed | **Removed** entirely |
| **Resource Owner Password grant** | Allowed | **Removed** entirely |
| **Refresh token rotation** | Optional | **Required** (sender-constrained or rotated) |
| **Bearer tokens in URI** | Allowed | **Removed** (no access tokens in query strings) |
| **Redirect URI matching** | Loose matching OK | **Exact string matching required** |
| **Client authentication** | Various methods | Recommends stronger methods (private_key_jwt, mTLS) |

### Authorization Code Flow with PKCE (The Standard Flow)

```
┌──────────┐     1. Auth Request + code_verifier     ┌──────────┐
│          │ ──────────────────────────────────────→  │          │
│  Client  │     (code_challenge = SHA256(verifier))  │  AuthZ   │
│  (SPA /  │                                          │  Server  │
│  Mobile) │  2. Authorization Code                   │  (IdP)   │
│          │ ←──────────────────────────────────────  │          │
│          │                                          │          │
│          │  3. Token Request + code_verifier         │          │
│          │ ──────────────────────────────────────→  │          │
│          │                                          │          │
│          │  4. Access Token + Refresh Token          │          │
│          │ ←──────────────────────────────────────  │          │
└──────────┘                                          └──────────┘
```

**Why PKCE is required**: Without PKCE, authorization code interception attacks are possible. PKCE ensures only the client that initiated the flow can exchange the code, even for public clients (SPAs, mobile apps) that cannot keep a client secret.

### OpenID Connect Updates

| Feature | Status | Description |
|---------|--------|-------------|
| **OIDC Core 1.0** | Current standard | Authentication layer on OAuth 2.0, ID tokens (JWT) |
| **OIDC Federation 1.0** | Final Spec voting Feb 2026 | Automated trust establishment without pre-registration |
| **OID4VP 1.0** | Final Spec (Jul 2025) | Verifiable Presentations — wallet-based identity |
| **OID4VCI 1.0** | Final Spec (Sep 2025) | Verifiable Credential Issuance — EU Digital Identity Wallet |
| **OpenID AuthZEN 1.0** | Final Spec (Jan 2026) | Standard PDP/PEP communication API for authorization engines |
| **Shared Signals Framework** | RFC 8935 (2025) | Cross-IdP signal sharing (CAEP, RISC events) |

### Token Best Practices (2025-2026)

| Token Type | Lifetime | Storage (SPA) | Storage (Mobile) | Storage (Server) |
|-----------|----------|---------------|-------------------|-----------------|
| **Access Token** | 5-15 minutes | Memory only (never localStorage) | Secure Keychain/Keystore | Server-side session or in-memory |
| **Refresh Token** | 1-24 hours, rotate on use | HttpOnly secure cookie (BFF pattern) | Secure Keychain/Keystore | Server-side, encrypted |
| **ID Token** | 5-15 minutes | Memory only | Secure storage | Server-side session |

**The BFF (Backend-For-Frontend) Pattern** is the recommended approach for SPAs in 2025-2026:

```
Browser ←(session cookie)→ BFF Server ←(OAuth tokens)→ IdP / APIs
                                |
                           Tokens never reach
                           the browser JavaScript
```

The BFF holds tokens server-side, issues a session cookie to the browser, and proxies API calls with the access token. This eliminates token theft via XSS.

---

## 2. Passkeys, WebAuthn, and FIDO2

### Adoption Status (2025-2026)

| Platform | Passkey Support | Syncing | Status |
|----------|----------------|---------|--------|
| **Apple** | iCloud Keychain passkeys | Cross-device via iCloud | GA since iOS 16, macOS Ventura |
| **Google** | Google Password Manager passkeys | Cross-device via Google account | GA since Android 9+, Chrome |
| **Microsoft** | Windows Hello passkeys | Cross-device via Microsoft account | GA since Windows 11 23H2 |
| **1Password** | Third-party passkey storage | Cross-platform (macOS, Windows, iOS, Android, Linux) | GA |
| **Bitwarden** | Third-party passkey storage | Cross-platform | GA |

**Industry adoption milestones (verified 2025-2026):**
- **15 billion** online accounts support passkeys
- **87%** of enterprises surveyed by FIDO Alliance deploying or actively deploying passkeys
- **48%** of top 100 websites offer passkeys (doubled from 2022)
- **93%** authentication success rate (vs 63% for legacy auth)
- **Google**: Full cross-platform passkey sync (Android, iOS, macOS, Windows via Chrome) since Jan 2025
- **Microsoft**: Passkey Profiles and Synced Passkeys GA March 2026; passkeys now default for new accounts
- SMS OTP being eliminated: UAE (Mar 2026), India (Apr 2026), Philippines (Jun 2026) for financial services

### WebAuthn Registration Flow

```
1. User clicks "Register passkey"
2. Server generates challenge (random bytes)
3. Browser calls navigator.credentials.create() with challenge
4. Authenticator creates key pair:
   - Private key stored securely (TPM, Secure Enclave, or synced)
   - Public key + attestation returned to server
5. Server stores public key + credential ID
```

**Registration example (server-side, Node.js with SimpleWebAuthn):**
```typescript
import { generateRegistrationOptions, verifyRegistrationResponse } from '@simplewebauthn/server';

// Step 1: Generate options
const options = await generateRegistrationOptions({
  rpName: 'My App',
  rpID: 'myapp.com',
  userID: user.id,
  userName: user.email,
  authenticatorSelection: {
    residentKey: 'preferred',         // Discoverable credential (passkey)
    userVerification: 'preferred',     // Biometric/PIN
    authenticatorAttachment: 'platform', // Built-in authenticator
  },
  // Exclude existing credentials to prevent re-registration
  excludeCredentials: user.credentials.map(c => ({
    id: c.credentialID,
    type: 'public-key',
  })),
});

// Step 2: Verify response
const verification = await verifyRegistrationResponse({
  response: registrationResponse,
  expectedChallenge: challenge,
  expectedOrigin: 'https://myapp.com',
  expectedRPID: 'myapp.com',
});

if (verification.verified) {
  // Store credential
  await saveCredential(user.id, verification.registrationInfo);
}
```

### Passkey vs Traditional MFA

| Factor | Passkey | TOTP | SMS OTP | Push Notification |
|--------|---------|------|---------|-------------------|
| **Phishing resistant** | Yes (origin-bound) | No | No | Partially (fatigue attacks) |
| **User experience** | Biometric/PIN (fastest) | Code entry (slow) | Code entry (slow) | Tap to approve |
| **Device dependency** | Synced across devices | Per-device (unless cloud TOTP) | Per-phone number | Per-device |
| **Account recovery** | Sync provider + recovery key | Backup codes | SIM swap risk | Backup codes |
| **Enterprise control** | Attestation policies | Easy to mandate | Easy to mandate | Per-provider |
| **Replay protection** | Challenge-response | Time-windowed | Time-windowed | Session-based |

---

## 3. Identity Providers

### IdP Comparison (2025-2026)

| Feature | Auth0 (Okta) | Okta Workforce | Microsoft Entra ID | AWS IAM Identity Center | Keycloak | Clerk | WorkOS |
|---------|-------------|----------------|-------------------|------------------------|----------|-------|--------|
| **Target** | Customer identity (CIAM) | Employee identity | Employee + Customer | AWS SSO | Self-hosted | Developer-first CIAM | Enterprise SSO for SaaS |
| **Passkey support** | Yes | Yes | Yes (Windows Hello) | No (federated) | Plugin | Yes (native) | Yes |
| **SSO protocols** | OIDC, SAML, WS-Fed | OIDC, SAML | OIDC, SAML, WS-Fed | OIDC, SAML | OIDC, SAML | OIDC | OIDC, SAML |
| **MFA** | All methods | All methods | All methods + WHfB | Delegated to IdP | Plugin-based | All methods | Delegated to IdP |
| **User management** | Full (Actions, Hooks) | Full + HR integration | Full + Entra lifecycle | AWS-focused | Full | Full (UI components) | SCIM, directory sync |
| **Social login** | 50+ providers | Limited | Microsoft, Google | No | Plugin-based | All major | Google, Microsoft |
| **Pricing** | Free tier + per-MAU | Per-user/month | Per-user/month (M365) | Free with AWS | Free (OSS) | Free tier + per-MAU | Per-connection |
| **Self-hosted** | No | No | No | No | Yes (primary model) | No | No |
| **Best for** | B2C/B2B apps needing flexibility | Enterprise workforce | Microsoft shops | AWS-only environments | Full control, privacy | Startups, modern UX | B2B SaaS needing enterprise SSO |

### When to Use Each IdP

```
Building a consumer-facing app?
├── Need maximum flexibility + Actions/Hooks → Auth0
├── Want beautiful pre-built UI components → Clerk
├── Need self-hosted / data sovereignty → Keycloak
└── Building for mobile-first → Firebase Auth or Auth0

Building a B2B SaaS product?
├── Customers need SSO → WorkOS (enterprise connections) or Auth0 Organizations
├── Need SCIM provisioning → WorkOS, Auth0, or Okta
└── Need multi-tenant auth → Auth0 Organizations or custom on Keycloak

Securing internal workforce?
├── Microsoft shop → Entra ID
├── Google Workspace → Google Workspace + OIDC
├── AWS-centric → IAM Identity Center
├── Multi-cloud / on-prem → Okta Workforce or Keycloak
└── Small team → Google/Microsoft SSO via any OIDC provider
```

---

## 4. Authorization Models (RBAC, ABAC, ReBAC)

### Model Comparison

| Model | How Permissions Work | Best For | Limitations |
|-------|---------------------|----------|-------------|
| **RBAC** (Role-Based) | User → Role → Permissions | Simple apps, clear role hierarchy | Role explosion in complex domains |
| **ABAC** (Attribute-Based) | Policies evaluate attributes (user, resource, environment) | Context-dependent access, regulatory compliance | Complex to reason about, test, and audit |
| **ReBAC** (Relationship-Based) | Permissions derived from object relationships | Social networks, document sharing, multi-tenant SaaS | Complex to model initially |

### RBAC Example

```
User "alice"
  └── Role: "editor"
        └── Permissions: ["document:read", "document:write", "document:publish"]

User "bob"
  └── Role: "viewer"
        └── Permissions: ["document:read"]
```

**RBAC with hierarchy:**
```
admin → editor → viewer
  |        |        |
  |        |        └── document:read
  |        └── document:write, document:publish
  └── document:delete, user:manage, settings:manage
```

### ABAC Example

```
Policy: "Doctors can access patient records during working hours in their department"

Attributes evaluated:
- Subject: role=doctor, department=cardiology
- Resource: type=patient_record, department=cardiology
- Environment: time=14:30, day=Tuesday
- Action: read

Decision: PERMIT (all conditions met)
```

### ReBAC Example (Google Zanzibar-style)

```
# Relationship tuples (like Google Zanzibar)
document:readme#owner@user:alice
document:readme#viewer@team:engineering#member
team:engineering#member@user:bob
team:engineering#member@user:charlie
folder:docs#viewer@user:alice
document:readme#parent@folder:docs

# Query: Can bob view document:readme?
# Resolution: bob is member of team:engineering,
#             team:engineering#member has viewer on document:readme
# Answer: YES
```

---

## 5. Fine-Grained Authorization Engines

### Engine Comparison (2025-2026)

| Feature | OpenFGA | SpiceDB (Authzed) | Cedar (AWS) | Cerbos | Oso Cloud | Permit.io |
|---------|---------|-------------------|-------------|--------|-----------|-----------|
| **Model** | ReBAC (Zanzibar) | ReBAC (Zanzibar) | ABAC + RBAC + ReBAC | ABAC + RBAC | Polar (declarative) | RBAC + ABAC + ReBAC |
| **Architecture** | Hosted or self-hosted | Hosted (Authzed) or self-hosted | Library (embedded) | Sidecar or library | Hosted cloud | Hosted + local PDP |
| **Language** | DSL (type definitions) | Schema language | Cedar policy language | YAML policies | Polar language | UI + API |
| **Performance** | <10ms P99 | <5ms P99 | <1ms (in-process) | <10ms P99 | <50ms (cloud) | <10ms P99 |
| **Open source** | Yes (CNCF) | Yes (SpiceDB core) | Yes (Cedar language) | Yes | No | Partial (OPA/Cedar-backed) |
| **Version (2026)** | GA | v1.50 (Mar 2026) | v4.9 (Mar 2026) | GA | GA | GA |
| **Maintained by** | Auth0/Okta → CNCF | Authzed | AWS | Cerbos Ltd | Oso | Permit.io |
| **Best for** | Google Drive-style sharing | High-scale ReBAC | AWS-native apps, AI agent authZ (Bedrock AgentCore) | Microservices, API authorization | Startups, rapid iteration | SaaS with UI-driven policies |

**Emerging trend — AI Agent authorization**: Cedar is used for Amazon Bedrock AgentCore Policy (GA Mar 2026). SpiceDB has LangChain integration. Non-human identities now outnumber employees 5:1 in large enterprises. **OpenID AuthZEN 1.0** (Jan 2026) standardizes PDP/PEP communication for cross-engine interoperability.

### OpenFGA Example

```
# Authorization model
model
  schema 1.1

type user

type document
  relations
    define owner: [user]
    define editor: [user, team#member] or owner
    define viewer: [user, team#member] or editor
    define can_delete: owner

type team
  relations
    define member: [user]

type folder
  relations
    define viewer: [user]
    define parent_viewer: viewer from parent
  relations
    define parent: [folder]
```

```typescript
// Check permission
const { allowed } = await fga.check({
  user: 'user:bob',
  relation: 'viewer',
  object: 'document:readme',
});

// Write relationship tuple
await fga.write({
  writes: {
    tuple_keys: [{
      user: 'user:alice',
      relation: 'editor',
      object: 'document:readme',
    }],
  },
});
```

### Cedar Policy Example (AWS)

```
// Allow editors to update documents in their department
permit(
  principal in Role::"editor",
  action in [Action::"UpdateDocument", Action::"ReadDocument"],
  resource in Folder::"engineering"
) when {
  principal.department == resource.department
};

// Deny access outside business hours
forbid(
  principal,
  action,
  resource
) when {
  !(context.time.hour >= 8 && context.time.hour <= 18)
} unless {
  principal in Role::"admin"
};
```

---

## 6. Session Management

### Token Storage Security (2025-2026 Best Practices)

| Storage Location | XSS Risk | CSRF Risk | Use Case |
|-----------------|----------|-----------|----------|
| **HttpOnly Secure Cookie** | Protected (not accessible via JS) | Vulnerable (mitigate with SameSite) | BFF pattern, server-rendered apps |
| **In-memory (JS variable)** | Cleared on page refresh | N/A | SPA access tokens (short-lived) |
| **localStorage** | Vulnerable to XSS | N/A | **Never use for tokens** |
| **sessionStorage** | Vulnerable to XSS | N/A | **Never use for tokens** |
| **Secure Keychain (mobile)** | Protected by OS | N/A | Mobile apps (iOS Keychain, Android Keystore) |
| **Web Worker** | Isolated from main thread | N/A | Advanced SPA pattern (tokens in worker) |

### Refresh Token Rotation

```
1. Client sends refresh_token_1 to get new tokens
2. Server issues new access_token + refresh_token_2
3. Server invalidates refresh_token_1
4. If refresh_token_1 is used again → token reuse detected → revoke ALL tokens for user

This prevents stolen refresh tokens from being used indefinitely.
```

### Session Hardening Checklist

```
Authentication:
  ✓ Regenerate session ID after login (prevent session fixation)
  ✓ Set absolute session timeout (e.g., 24 hours max)
  ✓ Set idle timeout (e.g., 30 minutes without activity)
  ✓ Bind session to user-agent and/or IP range (detect session hijacking)

Cookies:
  ✓ HttpOnly flag (prevent JS access)
  ✓ Secure flag (HTTPS only)
  ✓ SameSite=Lax or Strict (CSRF protection)
  ✓ __Host- prefix (ensures Secure + no Domain + Path=/)
  ✓ Short Max-Age for session cookies

Token management:
  ✓ Short access token lifetime (5-15 minutes)
  ✓ Refresh token rotation (single-use)
  ✓ Token revocation on logout, password change, MFA change
  ✓ Token binding (DPoP for API tokens)
```

---

## 7. MFA and Phishing-Resistant Authentication

### MFA Method Ranking (2025-2026)

| Method | Phishing Resistant | User Experience | Enterprise Readiness | Recommendation |
|--------|-------------------|-----------------|---------------------|----------------|
| **Passkeys (FIDO2)** | Yes | Best (biometric/PIN) | Growing | **Preferred** — deploy for all users |
| **Hardware security keys** | Yes | Good (physical tap) | Mature | **Preferred** for high-security roles |
| **Platform authenticators** | Yes | Good (built-in) | Mature | Good alternative to passkeys |
| **Push notifications** | Partial (fatigue attacks) | Good (tap to approve) | Mature | Acceptable with number matching |
| **TOTP (authenticator apps)** | No | Moderate (code entry) | Mature | Acceptable as fallback |
| **SMS OTP** | No (SIM swap, SS7) | Moderate | Actively deprecated | **Discouraged** — FBI/CISA advised against Dec 2024; NIST SP 800-63B discourages for high-assurance |
| **Email OTP** | No | Poor | Legacy | **Discouraged** — use only as last resort |

### Push Notification Hardening (Against MFA Fatigue)

MFA fatigue attacks (bombing users with push requests until they approve) are countered by:
1. **Number matching**: User must enter a number shown on the login screen
2. **Geographic context**: Show login location, deny if impossible travel
3. **Rate limiting**: Max 3 push requests per 10 minutes
4. **Anomaly detection**: Flag unusual login patterns before sending push

### FIDO2 Attestation for Enterprise

```
Enterprise can require specific authenticators via attestation:

1. Collect AAGUID from authenticator during registration
2. Check AAGUID against allowlist (e.g., only YubiKey 5 series)
3. Verify attestation certificate chain
4. Store attestation metadata for audit

This ensures only company-approved authenticators are registered.
```

---

## 8. SSO and Federation

### SAML vs OIDC for SSO

| Feature | SAML 2.0 | OIDC |
|---------|----------|------|
| **Token format** | XML assertions | JWT (JSON) |
| **Transport** | HTTP POST/Redirect bindings | HTTP + JSON |
| **Token size** | Large (XML + signatures) | Small (compact JWT) |
| **Mobile support** | Poor (XML parsing, browser redirects) | Good (native HTTP) |
| **Modern framework support** | Limited (libraries aging) | Excellent (every language/framework) |
| **Enterprise adoption** | Very high (legacy systems) | Growing rapidly |
| **Use in 2026** | Required for enterprise SSO (many IdPs only support SAML) | Preferred for new implementations |
| **Recommendation** | Support it for enterprise customers | Default choice for new SSO |

### SCIM Provisioning

SCIM (System for Cross-domain Identity Management) automates user lifecycle:

```
IdP (Okta, Entra ID)  ──SCIM 2.0──>  Your SaaS App

Operations:
  POST   /scim/v2/Users          → Create user when hired
  PUT    /scim/v2/Users/{id}     → Update user attributes
  PATCH  /scim/v2/Users/{id}     → Partial update (e.g., deactivate)
  DELETE /scim/v2/Users/{id}     → Deprovision when they leave
  GET    /scim/v2/Users          → List/search users
  POST   /scim/v2/Groups         → Create group
  PATCH  /scim/v2/Groups/{id}    → Add/remove members
```

Implementing SCIM is essential for enterprise B2B SaaS — it's how IT admins automate onboarding/offboarding. WorkOS and Clerk provide SCIM-as-a-service.

---

## 9. Machine-to-Machine Authentication

### Workload Identity (SPIFFE/SPIRE)

**SPIFFE** (Secure Production Identity Framework For Everyone) provides a standard for workload identity:

```
SPIFFE ID format: spiffe://trust-domain/path

Examples:
  spiffe://acme.com/frontend/web-server
  spiffe://acme.com/backend/payment-service
  spiffe://acme.com/database/postgres-primary
```

**SPIRE** implements the SPIFFE spec:
- Issues short-lived X.509 certificates (SVIDs) to workloads
- Automatic rotation (no manual certificate management)
- Works across Kubernetes, VMs, bare metal
- Attestation based on node (AWS instance identity) and workload (K8s service account)

### CI/CD Workload Identity (OIDC Federation)

Eliminate long-lived CI/CD secrets by using OIDC tokens:

```yaml
# GitHub Actions → AWS (no static credentials)
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/github-deploy
      aws-region: us-east-1
      # No access key needed — uses OIDC token

# GitHub Actions → GCP
  - uses: google-github-actions/auth@v2
    with:
      workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github/providers/github
      service_account: deploy@project.iam.gserviceaccount.com

# GitHub Actions → Azure
  - uses: azure/login@v2
    with:
      client-id: ${{ secrets.AZURE_CLIENT_ID }}
      tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      # Uses federated credentials, no client secret
```

### mTLS (Mutual TLS)

```
Standard TLS:        Client verifies server certificate
Mutual TLS (mTLS):   Client AND server verify each other's certificates

Use cases:
  - Service-to-service in microservices (via service mesh)
  - API authentication for high-security integrations
  - Zero-trust network access
  - IoT device authentication

Implementation:
  - Service mesh (Istio, Linkerd): Automatic mTLS between all pods
  - cert-manager + SPIRE: Certificate issuance and rotation
  - Cloud-native: AWS Private CA, Azure Managed HSM, GCP Certificate Authority Service
```

---

## 10. Cloud IAM Patterns

### AWS IAM Best Practices

```json
// Least privilege policy example
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-app-uploads/*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalTag/team": "backend"
        },
        "IpAddress": {
          "aws:SourceIp": "10.0.0.0/8"
        }
      }
    }
  ]
}
```

**AWS IAM evolution (2025-2026):**
- **IAM Access Analyzer**: Validates policies, finds unused access, generates least-privilege policies from CloudTrail logs
- **IAM Roles Anywhere**: Certificate-based auth for on-prem workloads; **FIPS 204 ML-DSA** (post-quantum) support since March 2026
- **IAM Identity Center**: Centralized SSO for all AWS accounts + SAML/OIDC apps
- **Service Control Policies (SCPs)**: Organization-wide guardrails
- **Resource Control Policies (RCPs)**: Resource-based guardrails (2024+)
- **AWS Interconnect (preview Nov 2025)**: Private connections to Google Cloud (first partner), Azure planned

### Cross-Cloud Identity Patterns

| Pattern | Use Case | How It Works |
|---------|----------|-------------|
| **OIDC Federation** | CI/CD across clouds | GitHub OIDC → AWS/GCP/Azure federated credentials |
| **SAML Federation** | Enterprise SSO across clouds | Entra ID → AWS IAM Identity Center + GCP Workspace |
| **SPIFFE/SPIRE** | Workload identity across clouds | Universal workload identity standard |
| **Cloud IAM mapping** | Multi-cloud access | Map cloud roles to centralized IdP groups |

---

## 11. Privileged Access Management

### Just-in-Time (JIT) Access

Zero-standing privileges: nobody has permanent admin access. Access is requested, approved, and time-limited.

```
Developer needs production access:
1. Request access via Slack bot / web portal / CLI
2. Auto-approve if meets policy (on-call + incident active) OR route to approver
3. Grant temporary access (1-4 hours, scoped to specific resources)
4. Automatically revoke when time expires
5. Log everything for audit trail
```

**Tools implementing JIT access:**
- **ConductorOne**: Automated access reviews + JIT access
- **Opal**: JIT access + automated access reviews
- **Indent**: Slack-based access requests + time-limited grants
- **AWS IAM Identity Center**: Temporary elevated access sets
- **Azure PIM (Privileged Identity Management)**: Time-bound role activation

### Break-Glass Procedures

```
Emergency access when normal channels are down:

1. Break-glass account exists (disabled by default)
2. Enable via separate, hardened channel (hardware key + approval)
3. All actions logged with enhanced monitoring
4. Automatic alert to security team
5. Mandatory post-incident review of all break-glass actions
6. Re-disable account immediately after use

Store break-glass credentials in:
  - Physical safe (for last-resort access)
  - Separate Vault instance (not dependent on primary infrastructure)
  - Split knowledge (two-person integrity)
```

---

## 12. IAM Architecture Decision Framework

### Choosing an Auth Architecture

```
What are you building?
│
├── Consumer-facing app (B2C)
│   ├── Need social login + email/password → Auth0, Clerk, Firebase Auth
│   ├── Need passkey-first → Clerk, Auth0 with passkey configuration
│   ├── Privacy/sovereignty concerns → Keycloak (self-hosted)
│   └── Mobile-first → Firebase Auth, Auth0
│
├── B2B SaaS product
│   ├── Enterprise customers need SSO
│   │   ├── Want turnkey SSO connections → WorkOS
│   │   ├── Full CIAM platform → Auth0 Organizations
│   │   └── Self-hosted → Keycloak with org support
│   ├── Need SCIM provisioning → WorkOS, Auth0, Okta
│   └── Multi-tenant authorization → OpenFGA, Cerbos
│
├── Internal workforce
│   ├── Microsoft ecosystem → Entra ID
│   ├── Google Workspace → Google Workspace SSO
│   ├── AWS-centric → IAM Identity Center
│   └── Multi-cloud → Okta Workforce, JumpCloud
│
└── Microservices / API
    ├── Service-to-service auth → mTLS (Istio/Linkerd), SPIFFE/SPIRE
    ├── API consumer auth → OAuth 2.1 Client Credentials + API gateway
    └── Fine-grained AuthZ → Cedar (embedded), OpenFGA, SpiceDB
```

### Authorization Architecture by Complexity

| Complexity | Model | Tool | Example |
|-----------|-------|------|---------|
| **Simple** | RBAC (3-5 roles) | Framework middleware (e.g., CASL, next-auth roles) | Admin, Editor, Viewer |
| **Moderate** | RBAC + resource ownership | Application-level checks + database queries | "Users can edit their own posts" |
| **Complex** | ReBAC | OpenFGA, SpiceDB | Google Drive-style sharing with inheritance |
| **Regulated** | ABAC | Cedar, OPA/Rego | Context-dependent policies (time, location, classification) |
| **Multi-tenant** | ReBAC + RBAC | OpenFGA with per-org type system | SaaS with org-level roles + resource sharing |
