# Authentication & Authorization — Deep Reference

**Always use `WebSearch` to verify version numbers, security advisories, and best practices. Auth standards and libraries evolve rapidly, and outdated advice can create security vulnerabilities. Last verified: April 2026.**

## Table of Contents
1. [OAuth 2.1](#1-oauth-21)
2. [OpenID Connect (OIDC)](#2-openid-connect-oidc)
3. [Passkeys and WebAuthn](#3-passkeys-and-webauthn)
4. [JWT Best Practices](#4-jwt-best-practices)
5. [Session Management](#5-session-management)
6. [RBAC Implementation](#6-rbac-implementation)
7. [ABAC Implementation](#7-abac-implementation)
8. [ReBAC (Relationship-Based)](#8-rebac-relationship-based)
9. [SSO (Single Sign-On)](#9-sso-single-sign-on)
10. [MFA Implementation](#10-mfa-implementation)
11. [Auth Providers](#11-auth-providers)
12. [API Authentication](#12-api-authentication)
13. [Token Security](#13-token-security)
14. [Implementation by Language](#14-implementation-by-language)
15. [Zero Trust Architecture](#15-zero-trust-architecture)
16. [Decision Framework](#16-decision-framework)

---

## 1. OAuth 2.1

### What Changed from OAuth 2.0

OAuth 2.1 (draft-ietf-oauth-v2-1-15, late-stage IETF draft) consolidates OAuth 2.0 best practices. The companion RFC 9700 ("Best Current Practice for OAuth 2.0 Security") is finalized and forms its normative foundation:

| Change | Why |
|--------|-----|
| **PKCE required** for all clients (not just public) | Prevents authorization code interception |
| **Implicit flow removed** | Tokens in URL fragments are insecure |
| **Resource Owner Password Credentials removed** | Sends credentials to the client — defeats delegation purpose |
| **Refresh token rotation required** | Leaked refresh tokens are detected and revoked |
| **Exact redirect URI matching** | Prevents open redirect attacks |
| **Bearer token in request body deprecated** | Use Authorization header |

### OAuth 2.1 Flows by Client Type

| Client Type | Flow | Notes |
|-------------|------|-------|
| Server-rendered web app | Authorization Code + PKCE | Server stores tokens securely |
| SPA (Single Page App) | Authorization Code + PKCE | Tokens in memory, BFF pattern preferred |
| Mobile / native app | Authorization Code + PKCE | System browser, deep link redirect |
| Machine-to-machine | Client Credentials | Service accounts, no user involved |
| Device (TV, CLI, IoT) | Device Authorization | User authenticates on separate device |

### The BFF Pattern for SPAs

Instead of handling tokens in the browser (localStorage/memory), use a Backend-for-Frontend:

```
Browser ──(session cookie)──→ BFF ──(access token)──→ API
```

- BFF stores tokens server-side (secure, httpOnly cookies for session)
- Browser never sees access/refresh tokens
- BFF handles token refresh transparently
- Eliminates XSS-based token theft

---

## 2. OpenID Connect (OIDC)

### OIDC on Top of OAuth 2.1

OIDC adds identity (who is the user?) on top of OAuth's authorization (what can they access?):

- **ID Token**: JWT containing user identity claims (sub, name, email, etc.)
- **UserInfo endpoint**: Additional user claims beyond the ID token
- **Discovery**: `/.well-known/openid-configuration` — auto-discover endpoints, keys, supported features
- **JWKS**: `/.well-known/jwks.json` — public keys for verifying ID token signatures

### Standard Claims

| Claim | Description |
|-------|------------|
| `sub` | Subject — unique user identifier (never changes) |
| `name` | Full name |
| `email` | Email address |
| `email_verified` | Boolean — email verified by provider? |
| `picture` | Profile picture URL |
| `iss` | Issuer — who issued the token |
| `aud` | Audience — who the token is for |
| `exp` | Expiration time |
| `iat` | Issued at time |
| `nonce` | Replay protection (must match request) |

### Logout Flows

| Flow | Description |
|------|------------|
| **RP-Initiated Logout** | App redirects to IdP's logout endpoint |
| **Front-Channel Logout** | IdP sends logout to all apps via iframes |
| **Back-Channel Logout** | IdP sends logout tokens to app endpoints (more reliable) |

---

## 3. Passkeys and WebAuthn

### Adoption Status (2026)

Passkeys have crossed the tipping point from experimental to mainstream:
- **Google**: 800+ million accounts using passkeys
- **Microsoft**: Made passkeys the default for new accounts (May 2025), saw 120% increase in authentication
- **Apple**: Full support across iOS 16+/macOS Ventura+, iCloud Keychain sync
- **Amazon**: 175 million users created passkeys within the first year
- **1Password, Dashlane, Bitwarden**: Third-party passkey management
- **Success rate**: 93% authentication success rate, completing in under 9 seconds

### How Passkeys Work

```
Registration:
1. Server sends challenge + user info
2. Device creates public/private key pair
3. Private key stored on device (never leaves)
4. Public key sent to server

Authentication:
1. Server sends challenge
2. Device signs challenge with private key (biometric/PIN to unlock)
3. Server verifies signature with stored public key
```

### Implementation

**Server-side libraries:**
| Language | Library |
|----------|---------|
| Java | `webauthn4j`, `java-webauthn-server` (Yubico) |
| TypeScript | `@simplewebauthn/server`, `@passwordless-id/webauthn` |
| Go | `go-webauthn/webauthn` |
| Python | `py_webauthn` |
| Rust | `webauthn-rs` |

### Conditional UI (Autofill)

```javascript
// Check if conditional mediation is available
if (window.PublicKeyCredential?.isConditionalMediationAvailable?.()) {
    // Passkey appears in autofill dropdown (no modal)
    navigator.credentials.get({
        publicKey: { challenge, rpId },
        mediation: "conditional"
    });
}
```

### When to Implement Passkeys

- **Primary auth**: Consumer apps where UX matters (replace passwords entirely)
- **MFA replacement**: Passkeys are inherently multi-factor (possession + biometric)
- **Phishing prevention**: Passkeys are bound to the origin — can't be phished
- **Not yet for**: Environments where all users don't have compatible devices, B2B with legacy SSO requirements

---

## 4. JWT Best Practices

### Signing Algorithms

| Algorithm | Type | Key Size | Recommendation |
|-----------|------|----------|---------------|
| **EdDSA** (Ed25519) | EdDSA | 256-bit | Recommended for new systems — fastest sign+verify, side-channel resistant. AWS KMS support added Nov 2025. |
| **ES256** | ECDSA | P-256 | Current industry standard — excellent HSM support across all major providers |
| **RS256** | RSA | 2048+ | Legacy — widely supported, larger tokens and slower than EC |
| HS256 | HMAC | 256-bit | Symmetric — only for self-issued tokens (both parties share secret) |

**Never use:** `alg: none` (explicitly reject in verification), HS256 for multi-party scenarios.

### Token Size Optimization

- Keep claims minimal — only what's needed for authorization
- Use short claim names (standard short names: `sub`, `iss`, `aud`, `exp`)
- Don't put entire user profiles in JWTs
- Typical production JWT: 300-500 bytes (not kilobytes)

### Token Storage

| Location | Security | Use Case |
|----------|----------|----------|
| **httpOnly, Secure, SameSite cookie** | Best | Server-rendered apps, BFF pattern |
| **Memory (JavaScript variable)** | Good | SPAs (lost on refresh — use refresh token to restore) |
| **localStorage** | Poor (XSS risk) | Avoid — any XSS can steal tokens |
| **sessionStorage** | Poor (XSS risk) | Marginally better than localStorage (per-tab) |

**Recommendation:** httpOnly cookies via BFF pattern for SPAs. Direct memory storage only when BFF is infeasible.

### Refresh Token Patterns

```
1. Access token: Short-lived (5-15 minutes)
2. Refresh token: Longer-lived (7-30 days), httpOnly cookie
3. On access token expiry: Use refresh token to get new pair
4. Refresh token rotation: Each use issues a new refresh token
5. Stolen token detection: If old refresh token is used, revoke all tokens for that user
```

### JWE (Encrypted JWTs)

When token claims contain sensitive data that should not be readable by intermediaries:
- Encrypt the entire JWT payload
- Use when tokens pass through untrusted parties
- Adds ~50% to token size
- Most applications don't need JWE — use opaque tokens or keep claims non-sensitive

---

## 5. Session Management

### Server-Side Sessions vs JWTs

| Concern | Server Sessions | JWTs |
|---------|----------------|------|
| **State** | Stateful (Redis/DB) | Stateless (self-contained) |
| **Revocation** | Immediate (delete from store) | Requires blocklist or short expiry |
| **Horizontal scaling** | Need shared session store | No shared state needed |
| **Size** | Small cookie (session ID only) | Larger cookie/header (claims in token) |
| **Best for** | Server-rendered web apps | APIs, microservices |

### Redis Session Store Pattern

```
Session ID (cookie) → Redis key → { userId, roles, preferences, expiresAt }

- TTL: Sliding expiration (extend on each request)
- Max sessions: Limit concurrent sessions per user
- Invalidation: Delete key to logout instantly
```

### Session Security

- **Session ID**: Cryptographically random, 128+ bits
- **Cookie flags**: `httpOnly`, `Secure`, `SameSite=Lax` (or `Strict`)
- **Session fixation**: Regenerate session ID after login
- **Concurrent session limits**: Allow 1-5 concurrent sessions, revoke oldest
- **Idle timeout**: 15-30 minutes for sensitive apps, hours for low-risk
- **Absolute timeout**: Force re-authentication after 8-24 hours regardless of activity

---

## 6. RBAC Implementation

### Core Concepts

```
Users → Roles → Permissions

User "Alice"  → Role "editor"  → Permissions: [create_post, edit_post, delete_own_post]
User "Bob"    → Role "admin"   → Permissions: [*, manage_users, manage_roles]
User "Charlie"→ Role "viewer"  → Permissions: [read_post]
```

### Database Schema Pattern

```sql
-- Users
CREATE TABLE users (id UUID PRIMARY KEY, email TEXT UNIQUE, ...);

-- Roles
CREATE TABLE roles (id UUID PRIMARY KEY, name TEXT UNIQUE, description TEXT);

-- Permissions
CREATE TABLE permissions (id UUID PRIMARY KEY, name TEXT UNIQUE, description TEXT);

-- Role → Permission mapping
CREATE TABLE role_permissions (
    role_id UUID REFERENCES roles(id),
    permission_id UUID REFERENCES permissions(id),
    PRIMARY KEY (role_id, permission_id)
);

-- User → Role mapping
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id),
    role_id UUID REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);
```

### Role Hierarchies

```
super_admin → admin → editor → viewer

Admin inherits all viewer + editor permissions.
Super_admin inherits all admin permissions.
```

Implementation: Store hierarchy in DB, resolve permissions by walking up the chain. Cache the resolved permission set per user.

### Enforcement Points

- **API middleware**: Check permissions before handler executes
- **Database queries**: Filter results by user's accessible resources
- **UI**: Hide/disable elements user can't access (defense in depth — never trust UI-only checks)

### When RBAC Is Enough

RBAC works well for most applications where:
- Access is determined by job function (roles map to job titles)
- Permission model is relatively static
- No need for resource-level or context-dependent access decisions
- <50 distinct permissions

---

## 7. ABAC Implementation

### Core Concepts

Access decisions based on **attributes** of the user, resource, action, and context:

```
Can user Alice (department=engineering, clearance=secret)
   read document X (classification=secret, department=engineering)
   at time 10:30am on a weekday?

Policy: ALLOW if user.clearance >= resource.classification
        AND user.department == resource.department
        AND context.time is within business_hours
```

### Policy Engines

| Engine | Language | Notes |
|--------|---------|-------|
| **OPA (Open Policy Agent)** v1.12 | Rego | CNCF graduated, de facto standard for cloud-native policy |
| **Cedar** v4.5 (AWS) | Cedar | 42-60x faster than OPA/Rego, formally verified, used in AWS Verified Permissions |
| **Casbin** | Multiple (Go, Java, JS, Python, Rust) | Flexible model — supports RBAC, ABAC, ReBAC in one engine |

### OPA/Rego Pattern

```rego
package authz

default allow = false

allow {
    input.user.role == "admin"
}

allow {
    input.action == "read"
    input.resource.owner == input.user.id
}

allow {
    input.action == "read"
    input.resource.visibility == "public"
}
```

**Deployment:** OPA as a sidecar (local evaluation, microsecond latency) or as a central service.

### When to Use ABAC

- Fine-grained access control that RBAC can't express
- Context-dependent decisions (time, location, device, risk score)
- Dynamic policies that change frequently
- Regulatory requirements (HIPAA, GDPR data access rules)
- >50 permissions or complex resource hierarchies

---

## 8. ReBAC (Relationship-Based)

### The Zanzibar Model (Google)

Access is determined by **relationships** between users and resources:

```
document:readme#viewer@user:alice      — Alice can view readme
document:readme#editor@group:eng#member — Engineering group members can edit readme
folder:docs#viewer@user:bob            — Bob can view docs folder
document:readme#parent@folder:docs     — readme is in docs folder → Bob inherits viewer
```

### Implementations

| System | Model | Notes |
|--------|-------|-------|
| **SpiceDB** (AuthZed) | Zanzibar-inspired | v1.50+, most faithful to Zanzibar, <10ms p95, LangChain integration for AI/RAG auth |
| **OpenFGA** (Auth0/Okta) | Zanzibar-inspired | CNCF Incubating (Oct 2025), combined ReBAC+ABAC DSL, ListObjects/ListUsers |
| **Permify** | Zanzibar-inspired | Acquired by FusionAuth (Nov 2025), integrated into their product |
| **Ory Keto** | Zanzibar-inspired | v0.14, Go-native, gRPC+REST, <10ms p95 |
| **AWS Verified Permissions** | Cedar-based | Managed service, Cedar 4.5, integrates with Cognito |

### When to Use ReBAC

- Document/file sharing (Google Docs-like permissions)
- Organizational hierarchies with inherited access
- Social features (friends, followers, group membership)
- Multi-tenant applications with complex sharing models
- Any domain where "X has relationship R to Y" is the natural access model

### SpiceDB Schema Example

```
definition user {}

definition organization {
    relation admin: user
    relation member: user

    permission manage = admin
    permission view = admin + member
}

definition document {
    relation owner: user
    relation org: organization
    relation viewer: user | organization#member

    permission edit = owner + org->admin
    permission view = viewer + edit
}
```

---

## 9. SSO (Single Sign-On)

### SAML 2.0

Still widely used in enterprise SSO:

```
SP-Initiated Flow:
1. User visits app (SP)
2. SP redirects to IdP with SAML AuthnRequest
3. User authenticates at IdP
4. IdP sends SAML Response (signed XML assertion) to SP's ACS URL
5. SP validates assertion, creates session
```

**When SAML:** Enterprise customers require it (many IdPs only support SAML), legacy integrations, when your customers use Active Directory/Okta/OneLogin with SAML.

### OIDC as SSO

OIDC has largely replaced SAML for new SSO implementations:
- Simpler than SAML (JSON vs XML)
- Better mobile support
- Standard token format (JWT vs XML assertions)
- Most modern IdPs support both

**When OIDC for SSO:** New implementations, mobile apps, modern IdPs, when you need both auth and user info.

### SCIM (System for Cross-domain Identity Management)

Automates user provisioning/deprovisioning across systems:
```
IdP creates user → SCIM push to your app → User provisioned
IdP disables user → SCIM push → User deactivated in your app
```

Important for enterprise SSO — user lifecycle management without manual admin work.

---

## 10. MFA Implementation

### Factor Types

| Factor | Type | Security | UX |
|--------|------|----------|-----|
| **Passkeys/WebAuthn** | Something you have + are | Highest (phishing-resistant) | Best |
| **TOTP** (RFC 6238) | Something you have | High | Good (app-based, offline) |
| **Push notification** | Something you have | High | Great (one-tap approval) |
| **SMS OTP** | Something you have | Low (SIM swap, SS7 attacks) | Okay |
| **Email OTP** | Something you have | Low-Medium | Okay |
| **Hardware key** (YubiKey) | Something you have | Highest | Moderate (physical device) |

### TOTP Implementation (RFC 6238)

```
1. Server generates secret (base32 encoded)
2. Share secret via QR code (otpauth:// URI)
3. User scans with authenticator app (Google Authenticator, Authy, 1Password)
4. App generates 6-digit codes every 30 seconds
5. Server verifies: HMAC-SHA1(secret, floor(time / 30))
6. Allow ±1 time step window (clock skew tolerance)
```

### Recovery Codes

- Generate 8-12 single-use recovery codes at MFA setup
- Hash and store them (like passwords)
- Display once, tell user to save securely
- Each code can only be used once
- Allow regeneration (invalidates old codes)

### Step-Up Authentication

For sensitive operations, require additional authentication even if user is logged in:
```
Normal session → View dashboard (no extra auth)
Sensitive operation → "Enter your password" or "Approve on your device"
    → Change email, delete account, transfer funds, view PII
```

---

## 11. Auth Providers

### Comparison (2026)

| Provider | Type | Best For | Pricing Model |
|----------|------|----------|--------------|
| **Auth0** (Okta) | SaaS | Enterprise, complex requirements, SAML/OIDC | Per MAU, enterprise tiers |
| **Clerk** | SaaS | Developer experience, React/Next.js, fast integration | Per MAU, generous free tier |
| **WorkOS** | SaaS | B2B SaaS (enterprise SSO, SCIM, directory sync) | Per connection |
| **Supabase Auth** | Open-source SaaS | Supabase ecosystem, PostgreSQL-based auth | Per MAU (free tier) |
| **Firebase Auth** | SaaS | Google ecosystem, mobile apps | Per verification |
| **Keycloak** v26.6 | Self-hosted (OSS) | Full control, on-premises, FAPI 2.0, DPoP, passkeys, experimental MCP server | Free (infra cost) |
| **Better Auth** v1.0 | Library (OSS) | TypeScript-native, plugin architecture, ~100K weekly npm downloads, now maintains Auth.js | Free |
| **AWS Cognito** | SaaS | AWS ecosystem, serverless, passwordless sign-in | Per MAU |

### Build vs Buy Decision

**Buy (managed provider) when:**
- Time-to-market matters (weeks, not months)
- Small team without security expertise
- Standard auth flows (social login, email/password, MFA)
- Compliance requirements (SOC2, HIPAA — providers handle this)

**Build (self-hosted) when:**
- Custom auth flows that providers don't support
- Data sovereignty requirements (can't send auth data to third party)
- Cost optimization at scale (>100K MAU, managed providers get expensive)
- Need full control over user data and auth behavior

### Better Auth (Notable OSS Option)

TypeScript-native auth library that has become the recommended starting point for new TS projects:
- **Now maintains Auth.js** (formerly NextAuth) — the teams merged
- Supports email/password, social login, magic links, passkeys, OAuth
- Plugin system for 2FA, organization management, API keys, magic links
- Auto-generated database schemas with full TypeScript type inference
- Self-hosted — runs alongside your application
- ~100K weekly npm downloads
- **Note:** Lucia was deprecated March 2025 — Better Auth is the recommended replacement

---

## 12. API Authentication

### Methods Compared

| Method | Stateful | User Context | Best For |
|--------|----------|-------------|----------|
| **API Keys** | No | No (identifies app, not user) | Server-to-server, simple integrations |
| **OAuth 2.1 Bearer Token** | No | Yes | User-facing APIs |
| **Client Credentials** | No | No | Machine-to-machine |
| **mTLS** | No | Certificate identity | Service-to-service (service mesh) |
| **Signed Requests** (SigV4) | No | Yes | High-security APIs (prevents tampering) |
| **Session Cookie** | Yes | Yes | Server-rendered web apps |

### API Key Best Practices

- Prefix with environment identifier: `sk_live_`, `sk_test_`
- Hash stored keys (SHA-256) — never store plaintext
- Support key rotation (generate new, grace period, revoke old)
- Scope keys to specific permissions/resources
- Rate limit per key
- Log key usage for audit

### Service-to-Service Authentication

In a microservices environment:

| Pattern | How | When |
|---------|-----|------|
| **mTLS via service mesh** | Istio/Linkerd handles cert rotation automatically | Standard in service mesh environments |
| **Service JWT** | Each service authenticates to IdP, gets JWT | No service mesh, need user context propagation |
| **SPIFFE/SPIRE** | Standardized workload identity | Multi-platform, cross-cloud identity |

---

## 13. Token Security

### DPoP (Demonstration of Proof-of-Possession)

DPoP binds tokens to a specific client, preventing token theft:

```
1. Client generates ephemeral key pair
2. Client sends public key with authorization request
3. Server binds access token to that public key
4. On each API request, client includes DPoP proof (signed with private key)
5. Server verifies DPoP proof matches bound key
```

**Why:** Stolen access tokens are useless without the corresponding private key.

### Token Revocation

| Strategy | Latency | Complexity |
|----------|---------|------------|
| **Short-lived tokens** (5-15 min) | Up to TTL delay | Lowest |
| **Token blocklist** (Redis) | Near-instant | Medium (check blocklist on each request) |
| **Token introspection** (RFC 7662) | Real-time | Higher (call to auth server per request) |
| **Refresh token revocation** | Next refresh attempt | Low (revoke refresh, access expires naturally) |

### Token Best Practices Summary

1. Use short-lived access tokens (5-15 minutes)
2. Use refresh token rotation (detect stolen tokens)
3. Store tokens in httpOnly cookies (server-rendered) or memory (SPA)
4. Never store tokens in localStorage
5. Include only necessary claims in JWTs
6. Validate `iss`, `aud`, `exp` on every request
7. Use asymmetric signing (ES256/RS256) for tokens verified by multiple services

---

## 14. Implementation by Language

### Java (Spring Security 6+)

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll()
            );
        return http.build();
    }
}
```

- Spring Security 6+ with OAuth2 Resource Server
- `@PreAuthorize("hasAuthority('SCOPE_read')")` for method-level security
- Spring Authorization Server for building your own OAuth2 server

### TypeScript/Node

**Auth.js v5 (formerly NextAuth):**
```typescript
export const { auth, signIn, signOut } = NextAuth({
    providers: [GitHub, Google, Credentials],
    callbacks: {
        authorized: ({ auth, request }) => !!auth?.user,
    },
});
```

**Better Auth:**
```typescript
const auth = betterAuth({
    database: new DrizzleAdapter(db),
    emailAndPassword: { enabled: true },
    socialProviders: { github: { clientId, clientSecret } },
    plugins: [twoFactor(), organization()],
});
```

- Passport.js: Mature, strategy-based auth middleware
- Auth.js v5: Next.js/SvelteKit/Nuxt integration
- Better Auth: Framework-agnostic, plugin-based

### Go

```go
func authMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        token := r.Header.Get("Authorization")
        claims, err := validateJWT(strings.TrimPrefix(token, "Bearer "))
        if err != nil {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }
        ctx := context.WithValue(r.Context(), userKey, claims)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

- `casbin`: Flexible authorization (RBAC, ABAC, ReBAC)
- `ory/fosite`: OAuth2/OIDC server implementation
- Middleware pattern is standard — no heavy frameworks

### Python (FastAPI)

```python
from fastapi import Depends, HTTPException, Security
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    payload = jwt.decode(token, SECRET_KEY, algorithms=["ES256"])
    user = await get_user(payload["sub"])
    if not user:
        raise HTTPException(status_code=401)
    return user

@app.get("/users/me")
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user
```

- FastAPI Security: Dependency injection-based auth
- Django auth: Built-in user model, permissions, groups
- `python-jose`: JWT handling

### Rust (Axum)

```rust
async fn auth_middleware(
    State(state): State<AppState>,
    mut request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    let token = request.headers().get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let claims = decode::<Claims>(token, &state.decoding_key, &Validation::new(Algorithm::ES256))
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    request.extensions_mut().insert(claims.claims);
    Ok(next.run(request).await)
}
```

- `jsonwebtoken` v10: JWT encoding/decoding
- `argon2`: Password hashing
- `axum-login` + `tower-sessions`: Session-based auth

---

## 15. Zero Trust Architecture

### Principles

1. **Never trust, always verify**: Every request is authenticated and authorized, regardless of network location
2. **Least privilege**: Grant minimum necessary access, for minimum necessary time
3. **Assume breach**: Design as if the network is already compromised

### Implementation Layers

| Layer | How |
|-------|-----|
| **Identity verification** | Strong authentication (MFA, passkeys) on every request |
| **Device trust** | Verify device health, compliance, managed status |
| **Network segmentation** | Micro-segmentation, no flat network trust |
| **Service-to-service** | mTLS between all services (service mesh) |
| **Data access** | Encrypt data at rest and in transit, fine-grained access control |
| **Continuous evaluation** | Re-evaluate access based on changing context (CAEP) |

### CAEP (Continuous Access Evaluation Protocol)

Shared Signals Framework + CAEP enables real-time access revocation:
```
User's device becomes non-compliant → Signal sent to all relying parties → Sessions terminated
User changes role → Signal sent → Permissions updated across all services
```

---

## 16. Decision Framework

| Decision | Default | Switch When |
|----------|---------|-------------|
| Auth protocol | OAuth 2.1 + PKCE | Already have SAML infrastructure (add SAML support) |
| Token format | JWT (ES256 signed) | Need instant revocation (opaque + introspection) |
| Token storage | httpOnly cookie (BFF pattern) | No backend for frontend (memory in SPA) |
| Authorization model | RBAC | Fine-grained/contextual (ABAC), relationship-based sharing (ReBAC) |
| MFA | TOTP as default, passkeys encouraged | Enterprise requiring hardware keys, consumer apps (push notifications) |
| Provider | Managed (Clerk/Auth0) for speed | Self-hosted (Keycloak) for full control, cost at scale |
| Session vs JWT | Sessions for web apps, JWTs for APIs | Microservices needing stateless auth (JWT), need instant revocation (sessions) |
| SSO protocol | OIDC | Enterprise customers require SAML |
| Password hashing | Argon2id | Legacy systems already using bcrypt (bcrypt is still fine) |
| API auth | OAuth 2.1 Bearer | Simple integrations (API keys), service-to-service (mTLS) |

**Overarching principle:** Authentication and authorization are not features to rush — they're the foundation of your application's security posture. Use managed providers when you can, implement carefully when you must, and always verify your implementation with security review. A small auth bug can compromise every user.
