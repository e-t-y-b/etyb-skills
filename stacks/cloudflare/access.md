---
title: Access (ZTNA)
description: Cloudflare's identity-aware proxy — gate web apps and SSH/RDP behind SSO + device + posture policies without a VPN.
product:
  name: Access
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, system-architect, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/cloudflare-one/identity/
  notes: "Identity-aware proxy with stable Service Auth + JWT validation patterns. Per-app session length and external evaluation hooks evolve."
---

## What it is

Cloudflare Access is a ZTNA (Zero Trust Network Access) product: it stands in front of a web app (or SSH/RDP/VNC target) and requires the requester to authenticate against your IdP (Okta, Entra ID, Google, GitHub, generic OIDC/SAML). Validated requests carry a JWT (`Cf-Access-Jwt-Assertion`) into your origin or [Worker](/stacks/cloudflare/workers/). Combined with [Cloudflare Tunnel](/stacks/cloudflare/tunnel/), the origin doesn't need a public IP at all.

Authoritative reference: [developers.cloudflare.com/cloudflare-one/identity](https://developers.cloudflare.com/cloudflare-one/identity/).

## When to use

- **Employee-facing surfaces** — internal admin, dashboards, dev/staging environments, Grafana, Argo CD, anything you'd otherwise put behind a corporate VPN.
- **Service-to-service auth between your own systems** — Access Service Auth issues JWTs your services can verify.
- **Partner / vendor portals** — single-app access without provisioning corporate accounts.
- **Replacing VPN ingress** — works hand-in-hand with [Cloudflare Tunnel](/stacks/cloudflare/tunnel/) for origin-without-public-IP architecture.

Don't reach for Access when:

- **Customer-facing auth** — you want branded login (Auth0, Clerk, Cognito, or your own); Access shows Cloudflare's challenge page.
- **Public APIs with API keys** — use [API Shield](/stacks/cloudflare/waf/) + Worker token validation.
- **Pure machine-to-machine** with no human identity — use mTLS.

## 2025-2026 currency anchors

- **Service Auth + JWT validation in a [Worker](/stacks/cloudflare/workers/)** is the canonical pattern for service-to-service over Access; verify the JWT with the team's JWKS endpoint and check `audience` against the per-app AUD tag.
- **External Evaluation** — Access policies can call out to a Worker for custom decision logic (e.g., "user must belong to the tenant this subdomain represents").
- **Device posture integration** with Cloudflare WARP enables policies like "only allow if device has disk encryption + MDM enrolled."

## Patterns

### JWT verification in a Worker

```ts
import { jwtVerify, createRemoteJWKSet } from "jose";

const JWKS = createRemoteJWKSet(new URL(`https://${TEAM_NAME}.cloudflareaccess.com/cdn-cgi/access/certs`));

export default {
  async fetch(req, env) {
    const token = req.headers.get("Cf-Access-Jwt-Assertion");
    if (!token) return new Response("Unauthorized", { status: 401 });
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `https://${TEAM_NAME}.cloudflareaccess.com`,
      audience: env.ACCESS_AUD_TAG
    });
    return handle(req, payload, env);
  }
};
```

Defense in depth: Access already validated identity at the edge, but verifying the JWT in your Worker prevents direct-origin bypass (see [Cloudflare Tunnel](/stacks/cloudflare/tunnel/)) and `Cf-Access-Authenticated-User-Email` header spoofing.

### External Evaluation policy

```
[Access policy]
  Include: external_evaluation -> https://policy-eval.example.com/eval
```

Cloudflare POSTs the request context to your Worker; the Worker returns `{ "allow": true }` or `false`. Use this for per-tenant access decisions (`user.email` matches a tenant's allowed list) without inflating IdP groups.

### Tunnel + Access composition

```
[Internet] -> [Cloudflare zone with Access] -> [Cloudflare Tunnel] -> [Private origin, no public IP]
```

Origin sits in a private subnet. `cloudflared` outbound-connects to Cloudflare. Access enforces identity. The origin firewalls everything except the tunnel.

## Anti-patterns

- **Trusting `Cf-Access-Authenticated-User-Email` without JWT verification.** Headers can be spoofed if the Worker is callable outside the Cloudflare zone. Verify the JWT.
- **Using Access for customer-facing login.** Customers don't want a Cloudflare-branded challenge; build branded auth.
- **Stale Access policies after employees leave.** Wire IdP group → Access policy mapping; don't maintain hand-lists.
- **No `audience` check in the JWT verifier.** Without `audience`, a token issued for one Access app can be replayed against another.

## Gotchas

1. **The JWT's `aud` claim** must match the AUD tag of the Access app — copy it from the Access app configuration into your Worker config.
2. **Session length is per-app, configurable.** Short for high-stakes apps (1h); longer for low-stakes (8-24h).
3. **`cloudflared` for SSH/RDP** uses a different access path than the JWT-in-header pattern — see Cloudflare One docs for the agent-based flow.
4. **Access logs need [Logpush](/stacks/cloudflare/logpush/)** to your SIEM for SOC 2 / compliance audit trails — they're not retained indefinitely in the dashboard.

## Cross-references

- [Cloudflare Tunnel](/stacks/cloudflare/tunnel/) — origin-without-public-IP composition
- [WAF + Managed Rulesets](/stacks/cloudflare/waf/) — different layer, applied at the same zone
- [Workers](/stacks/cloudflare/workers/) — runtime for External Evaluation policies and JWT verification
- [Logpush](/stacks/cloudflare/logpush/) — `access_logins` dataset to SIEM
- Role overlay: [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/cloudflare-one/identity](https://developers.cloudflare.com/cloudflare-one/identity/), [Service Auth](https://developers.cloudflare.com/cloudflare-one/identity/service-tokens/)
