---
role: security-engineer
stack: cloudflare
last_verified_on: "2026-05-14"
---

# Cloudflare overlay for `security-engineer`

You own the edge-security posture for Cloudflare-fronted workloads:

- **WAF** + managed rulesets (Cloudflare-managed, OWASP-managed, custom).
- **Rate limiting** — both rules-engine (zone-level) and Workers Rate Limiting binding (in-Worker).
- **Turnstile** — CAPTCHA alternative for forms, signups, comments.
- **Cloudflare Access** — identity-aware proxy (ZTNA) for internal/admin surfaces.
- **Cloudflare Tunnel** — outbound-initiated connections from your origin; no public IP needed.
- **mTLS** — mutual TLS at the zone, and a Workers binding for outbound mTLS to private services.
- **API Shield** — schema validation, sequence detection, JWT validation at the edge.
- **Bot Management** — bot scoring; Super Bot Fight Mode for non-enterprise plans.
- **DDoS protection** — always-on L3-L7 + advanced rules.
- **Gateway** — DNS + HTTP filtering for users / devices (DLP, threat intelligence).
- **CASB** — Cloud SaaS discovery + risk scoring.
- **Browser Isolation** — render risky URLs in a Cloudflare-hosted browser.
- **Workers-side concerns** — secret handling, prompt-injection defenses, RPC binding scopes.

The original `security-engineer` reference covers AppSec, IAM, threat modeling, compliance as principles. This overlay is the Cloudflare-specific playbook for 2026.

## Role briefing — security on Cloudflare

Cloudflare's security surface is broad and increasingly the canonical place to terminate the bulk of edge-layer concerns:

- TLS / mTLS terminate at Cloudflare. Origin can speak plain HTTP to the Worker (or Tunnel) and let Cloudflare handle TLS.
- WAF, rate limiting, Bot Management run before your Worker sees the request. Free traffic-shedding.
- Access / Tunnel replace VPN for internal services. Identity-aware proxy, no client install required.
- AI Gateway guardrails sit between Worker → LLM. Prompt-injection defenses ride here.
- Secrets are encrypted at rest by Cloudflare and only visible to the Worker at runtime.

Limits to remember:
- WAF managed rulesets need to be reviewed for false positives on launch.
- Rate limiting on Workers vs zone-level have different semantics; pick deliberately.
- Cloudflare Access SLA depends on plan; for SOC2-bound critical access paths, confirm.
- mTLS binding has a per-Worker certificate limit; check current docs.

## Decision frameworks

### WAF managed rulesets — which to enable

| Ruleset | When to enable | Notes |
|---------|----------------|-------|
| **Cloudflare Managed Ruleset** | Always | Cloudflare's curated rules; high signal |
| **Cloudflare OWASP Core Ruleset** | Always for HTTP APIs | Generic OWASP; tune sensitivity (paranoia level) |
| **Cloudflare Exposed Credentials Check** | Always for login flows | Catches creds known to be breached |
| **Cloudflare Sensitive Data Detection** | If you handle PII or have compliance requirements | Detects PII/PCI in responses |
| **Cloudflare Anomaly Detection** | API-heavy workloads | Detects unusual API patterns |

Start with all of the above in **log mode**. Watch for a week. Move to **block mode** for the ones with zero false positives. Tune the OWASP ruleset paranoia level downward if FP rate is high.

### Rate limiting: rules engine vs Workers binding

| Need | Use |
|------|-----|
| Block at edge before reaching Worker (DDoS-ish patterns, abuse, brute force) | **Rate Limiting Rules** (zone-level) |
| Per-user, per-tenant business logic limits | **Workers Rate Limiting binding** |
| Sliding window, weighted, complex algorithms | **Workers Rate Limiting binding** with custom keys |
| Free traffic shedding before billing kicks in | **Rate Limiting Rules** |

Both can coexist. Zone-level catches the trivial-abuse traffic; Worker-level enforces business limits.

### Turnstile vs CAPTCHA vs nothing

| Surface | Recommend |
|---------|-----------|
| User signup, password reset, contact forms | **Turnstile** |
| Anonymous comments / public review forms | **Turnstile** |
| High-stakes flows (large purchases, account changes) | **Turnstile + Bot Management score check** |
| Admin / internal flows behind SSO | None (Access handles it) |
| API endpoints (machine-to-machine) | Not Turnstile — use mTLS or API tokens |

Turnstile is invisible to legitimate users in 90%+ of cases (no puzzle), unlike reCAPTCHA which puts users through challenges more often.

### Access vs custom JWT vs OAuth in Worker

| Scenario | Recommend |
|----------|-----------|
| Internal tools / admin / dashboard for employees | **Cloudflare Access** with SSO (Okta, Entra, Google) |
| Customer-facing app with own auth | **OAuth/OIDC handled in Worker** (Auth0, Clerk, Cognito, or roll-your-own) |
| Service-to-service (your services calling yours) | **Cloudflare Access Service Auth** (JWT) or mTLS |
| Webhook ingress from known partners | **mTLS or signed-request validation in Worker** |
| Public API with API keys | **API Shield** + Worker token validation |

Cloudflare Access is the right answer for **employee-facing** workloads. It's the wrong answer for customer-facing auth where you need branded login.

### Tunnel: when private origins need it

Use Cloudflare Tunnel when:
- Your origin is on a private network (corp DC, VPC private subnets).
- You want zero public IPs / inbound firewall holes.
- You're moving off a traditional VPN to ZTNA.
- You're connecting Hyperdrive to a private Postgres.

Don't bother with Tunnel for:
- Public Workers (no need; they're already public-edge).
- Origin that's already public on a cloud LB (Tunnel adds a hop).

### mTLS — when and where

| Scenario | mTLS use |
|----------|----------|
| Customer-facing (B2C) | Rarely; use OAuth/passkeys |
| B2B / partner integrations | mTLS at the zone; partners present certs |
| Worker → private origin (your stuff) | Workers mTLS binding |
| Worker → vendor API requiring mTLS (PSPs, banks, healthcare) | Workers mTLS binding |
| Service-to-service in your own infra | mTLS or Access Service Auth |

Cloudflare mTLS at the zone validates the client cert; configurable per route. mTLS binding in a Worker stores a cert that the Worker uses for outbound `fetch`es to mTLS-protected APIs.

## Critical 2025-2026 platform reset for security-engineers

### Workers Rate Limiting binding

```toml
[[unsafe.bindings]]
name = "RATE_LIMITER"
type = "ratelimit"
namespace_id = "100"
simple = { limit = 100, period = 60 }   # 100 req per 60s per key
```

```ts
const { success } = await env.RATE_LIMITER.limit({ key: `user:${userId}` });
if (!success) return new Response("Too Many Requests", { status: 429 });
```

This is **separate** from zone-level Rate Limiting Rules. Both can coexist. Workers binding has per-Worker scope and is the cleanest path for per-user / per-tenant limits. Note: the `unsafe.bindings` block name is the current Wrangler syntax for the rate-limit binding as of 2026-Q2; verify against current docs as the binding type's stable form may have shifted.

### Cloudflare Access — Service Auth + JWT validation in Worker

```ts
// Worker behind Access
import { jwtVerify, createRemoteJWKSet } from "jose";

const JWKS = createRemoteJWKSet(new URL("https://<your-team>.cloudflareaccess.com/cdn-cgi/access/certs"));

export default {
  async fetch(req, env) {
    const token = req.headers.get("Cf-Access-Jwt-Assertion");
    if (!token) return new Response("Unauthorized", { status: 401 });

    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `https://<your-team>.cloudflareaccess.com`,
      audience: env.AUD_TAG  // from Access app config
    });

    // payload.email, payload.identity_nonce, etc.
    return handle(req, payload, env);
  }
}
```

The pattern: Access validates user identity and SSO; the Worker re-verifies the JWT (defense in depth) and applies business authz on the validated identity. **Don't trust the headers without verifying the JWT** — `Cf-Access-Authenticated-User-Email` looks tempting but should be backed up by JWT signature verification.

### API Shield + JWT validation at the edge

API Shield (paid SKU) does schema validation + JWT validation at Cloudflare's edge, before your Worker sees the request:

- Upload OpenAPI spec; non-conforming requests rejected at edge.
- Configure JWT validation per endpoint; expired/invalid tokens rejected at edge.
- Sequence detection: unusual API-call sequences scored as anomalous.

When this is worth it: high-volume APIs where you'd otherwise spend Worker CPU on validation, or APIs with strong abuse signals.

### Cloudflare Tunnel for private Hyperdrive

```bash
cloudflared tunnel create my-pg-tunnel
cloudflared tunnel route ip add 10.0.1.0/24 my-pg-tunnel
cloudflared tunnel run my-pg-tunnel
```

```bash
# Now create Hyperdrive pointing at the tunnel-routed DB
wrangler hyperdrive create my-hyperdrive --connection-string="postgres://user:pass@10.0.1.42:5432/db"
```

DB never has a public IP; Tunnel handles connectivity. Combine with origin firewall rules to deny everything except Cloudflare IPs.

### Bot Management + Turnstile composition

```ts
// In Worker
const bot = req.cf?.botManagement;   // populated by Bot Management
if (bot?.score < 30) {
  // Suspect bot; require Turnstile token
  const tsToken = req.headers.get("cf-turnstile-token");
  const ok = await verifyTurnstile(tsToken, env.TURNSTILE_SECRET);
  if (!ok) return new Response("Forbidden", { status: 403 });
}
```

Bot Management gives a score (1=bot, 99=human). For low scores: challenge. For high scores: let through. **Don't hard-block by score alone** — false positives on real users cost more than the abuse.

### Prompt-injection defenses (AI Workers)

For Workers that pass user input to LLMs:

1. **AI Gateway guardrails** — built-in prompt-injection classifier; enable on the gateway.
2. **Separation of trust** — system instructions, user input, retrieved content clearly separated in the prompt. Retrieved content explicitly marked as untrusted.
3. **Output validation** — when the LLM emits tool calls, validate args before executing (sanitize URLs, restrict file paths, etc.).
4. **Rate limiting** — abuse via LLM is cheap if uncapped; rate-limit per user/IP.

### Secrets handling

```bash
wrangler secret put OPENAI_API_KEY
wrangler secret bulk .secrets.json --env=production
```

Rules:
- Anything that grants capability is a Wrangler secret, **not** a `[vars]` entry.
- `[vars]` is visible in dashboard and logs; secrets are encrypted at rest and only visible to the Worker at runtime.
- Rotate secrets on a schedule (90 days for prod). Document the rotation procedure in the runbook.
- Use **separate** secrets per environment. Don't share prod and staging keys.
- For high-stakes secrets (payment processor keys, encryption keys), consider a secrets-manager pattern: store in Vault/AWS Secrets Manager/1Password, pull at deploy time, push via `wrangler secret bulk`, never persist in CI.

### Cloudflare's compliance posture

- **SOC 2 Type 2** — Cloudflare maintains SOC 2; relevant for customer trust paperwork.
- **PCI-DSS** — Workers and many products eligible on appropriate plans; payment-card workloads need a careful scope review.
- **HIPAA / BAA** — Cloudflare offers BAA on Enterprise plans for in-scope products. Confirm the specific in-scope products at contract time; the list expands over time but it's not "everything."
- **ISO 27001** — Cloudflare certified.
- **GDPR / data localization** — Region: Earth restrictions on Enterprise constrain processing to specific regions; Customer Metadata Boundary, Customer EU Cloud, etc.
- **FedRAMP** — Cloudflare has FedRAMP Moderate authorization for certain products.

For any compliance-bound engagement, the security-engineer should pair with the relevant vertical (healthcare-architect for HIPAA, fintech-architect for PCI/PSD2) and consult Cloudflare's compliance docs for current scope.

## Patterns and anti-patterns

### Pattern: defense-in-depth at the edge

```
[Internet]
   ↓
[Cloudflare zone]
   ├── DDoS (always-on)
   ├── WAF (managed + OWASP + custom)
   ├── Rate Limiting Rules (zone-level, abuse-shaped)
   ├── Bot Management (score → action)
   ├── Turnstile (for forms / abusable endpoints)
   ├── Access (for protected routes)
   └── API Shield (schema + JWT validation)
   ↓
[Worker]
   ├── Worker Rate Limiting (per-user business limits)
   ├── JWT re-verification (defense in depth)
   ├── Authorization (business-level)
   └── Input validation (zod / typebox)
   ↓
[Backend / DB / AI]
```

Don't collapse layers. Each gives independent value; running all of them is the design.

### Pattern: WAF custom rule with explicit logging

```
# Custom WAF rule (in dashboard or via API)
(http.request.uri.path contains "/admin/") and (ip.geoip.country ne "US") then BLOCK
```

Always pair custom rules with a logging plan: which dataset, what fields, alarmed when. Custom rules that no one looks at are noise.

### Pattern: Tunnel-only origin

```
[Internet]
   ↓
[Cloudflare]
   ↓ (Tunnel — outbound connection from origin)
[Origin in private subnet, no public IP]
```

Firewall the origin: deny all inbound. The only path in is via Tunnel. Combined with Access for human users, this is the modern ZTNA architecture.

### Pattern: per-tenant scoped Access policy

```
[Access policy: customer-portal]
  Include: external_evaluation -> calls a Worker that returns true if user.tenant matches subdomain
```

Access policies can call out to an "external evaluation" Worker for custom logic. Use this for "the user must belong to the tenant this subdomain represents."

### Pattern: signed webhooks for incoming integrations

```ts
async function verifyStripeWebhook(req: Request, secret: string): Promise<boolean> {
  const sig = req.headers.get("stripe-signature");
  const body = await req.text();
  // ... HMAC verification
}

async fetch(req, env) {
  if (!await verifyStripeWebhook(req, env.STRIPE_WEBHOOK_SECRET)) {
    return new Response("Unauthorized", { status: 401 });
  }
  // process
}
```

Every webhook source (Stripe, GitHub, Slack, Linear, etc.) has a signing scheme. Verify before processing; don't trust the URL.

### Pattern: mTLS for outbound to a vendor

```toml
[[mtls_certificates]]
binding = "BANK_CERT"
certificate_id = "..."   # uploaded via wrangler mtls-certificate upload
```

```ts
const r = await fetch("https://api.bank.example.com/payment", {
  method: "POST",
  body: ...,
  // The mTLS binding provides the client certificate
  cf: { mtls: env.BANK_CERT }
});
```

Bank/payment APIs requiring client certs work with this binding. Don't manage certs in code.

### Pattern: log-everything-security to a secure sink

```bash
wrangler logpush create --dataset=firewall_events --destination="..."
wrangler logpush create --dataset=access_logins --destination="..."
wrangler logpush create --dataset=workers_trace_events --destination="..."
wrangler logpush create --dataset=audit_logs --destination="..."
```

These four streams cover: WAF / rate limit / Bot / custom rule hits, Access auth events, Worker invocations, account-level admin actions. Push to a SIEM with retention matching your compliance scope.

### Anti-pattern: trusting `Cf-Connecting-IP` blindly

```ts
const ip = req.headers.get("Cf-Connecting-IP");
if (ip === "1.2.3.4") { /* admin path */ }   // BAD
```

`Cf-Connecting-IP` is set by Cloudflare and is reliable when the request comes through Cloudflare. But if your Worker is callable from arbitrary HTTP (not through your zone), this header can be spoofed. Always check `req.cf` is present (it's only populated when Cloudflare proxies the request).

Better: do IP-based decisions via WAF rules (which run at the edge, before the Worker) rather than in the Worker.

### Anti-pattern: secrets in `[vars]`

```toml
[vars]
STRIPE_SECRET_KEY = "sk_live_..."   # WRONG
```

Vars are visible. Use `wrangler secret put STRIPE_SECRET_KEY` and reference as `env.STRIPE_SECRET_KEY`.

### Anti-pattern: skipping Turnstile on assumed-low-volume endpoints

"This signup endpoint only gets 10 signups a day, no need for Turnstile." Until an abuser finds it. Turnstile is invisible to legitimate users; the cost is near-zero. Add it.

### Anti-pattern: relying on origin-only firewalls

Origin firewall says "only Cloudflare IPs allowed." Attacker resolves your origin IP via misconfiguration (DNS history, leaked email headers, exposed dev environment). Attacker hits your origin directly, bypasses Cloudflare. Defense:

- **Authenticated Origin Pulls** — Cloudflare presents a client cert to origin; origin requires it.
- **Cloudflare Tunnel** — origin has no public IP at all.
- **Argo / Cloudflare Spectrum** — origin behind Cloudflare-only access.

### Anti-pattern: shared Cloudflare API tokens across CI jobs

One token, `Account: All`, in 30 GitHub Actions workflows. When (not if) the token leaks, attacker has full Cloudflare-estate access. Scope:
- Per-purpose tokens (deploy, dns, cache, etc.).
- Per-env tokens.
- Per-team tokens for multi-team monorepos.
- 90-day rotation minimum for prod.

### Anti-pattern: forgetting to check `req.cf` in Workers

`req.cf` is the Cloudflare-injected request metadata (bot score, country, ASN, TLS version, mTLS status, etc.). If your Worker is somehow callable directly (not through a Cloudflare zone), `req.cf` is `undefined`. Code that assumes it's always present will crash; code that uses it for security decisions can be bypassed.

```ts
if (!req.cf) return new Response("Direct origin access not allowed", { status: 403 });
```

### Anti-pattern: not reviewing WAF blocks

WAF blocks legitimate traffic occasionally. False positives need a triage process: which rule, what request, what user. Surface block events into your SIEM and review weekly. Without this loop, FPs accumulate and eventually a real user is blocked from doing something important.

## Tooling specifics

### Cloudflare API tokens

Create at: My Profile → API Tokens. Templates available (Edit Cloudflare Workers, Edit Zone, etc.). Custom token:
- Permissions: `Account.Workers Scripts: Edit`, `Account.Workers KV Storage: Edit`, etc.
- Resources: limit to specific account, specific zone.
- IP restrictions: lock to CI runner IPs if static.
- TTL: 1 year max; rotate at 90 days minimum for prod.

### `wrangler secret`

```bash
wrangler secret put NAME [--env=production]
wrangler secret list [--env=production]
wrangler secret delete NAME [--env=production]
wrangler secret bulk file.json [--env=production]
```

### WAF via API / Terraform

```hcl
resource "cloudflare_ruleset" "owasp" {
  account_id  = var.account_id
  name        = "OWASP managed ruleset"
  description = "OWASP CRS"
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  rules {
    action      = "execute"
    description = "OWASP managed ruleset"
    expression  = "true"
    action_parameters {
      id = "4814384a9e5d4991b9815dcfc25d2f1f"   # ID of Cloudflare OWASP ruleset; check current
    }
  }
}
```

Custom rules:
```hcl
resource "cloudflare_ruleset" "custom" {
  account_id = var.account_id
  name       = "Custom rules"
  kind       = "zone"
  phase      = "http_request_firewall_custom"

  rules {
    action      = "block"
    description = "Block admin paths from outside US"
    expression  = "(http.request.uri.path contains \"/admin/\") and (ip.geoip.country ne \"US\")"
  }
}
```

### Access policies via Terraform

```hcl
resource "cloudflare_access_application" "admin" {
  account_id       = var.account_id
  name             = "Admin Portal"
  domain           = "admin.example.com"
  type             = "self_hosted"
  session_duration = "8h"
}

resource "cloudflare_access_policy" "admin_employees" {
  application_id = cloudflare_access_application.admin.id
  account_id     = var.account_id
  name           = "Allow employees"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["example.com"]
  }

  require {
    mfa = true
  }
}
```

### Tunnel via cloudflared + Terraform

```hcl
resource "cloudflare_tunnel" "private_origin" {
  account_id = var.account_id
  name       = "private-origin"
  secret     = random_password.tunnel_secret.result
}

resource "cloudflare_tunnel_config" "private_origin" {
  account_id = var.account_id
  tunnel_id  = cloudflare_tunnel.private_origin.id

  config {
    ingress_rule {
      hostname = "internal.example.com"
      service  = "http://internal:8080"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}
```

Run `cloudflared tunnel run --token <token>` on the origin host (or in a sidecar container).

## Cross-references to products_covered

- **WAF + Rate Limiting + Bot Management + Turnstile** → "WAF managed rulesets" + "Bot Management + Turnstile composition".
- **Access (ZTNA)** → "Cloudflare Access — Service Auth + JWT validation in Worker"; [Access docs](https://developers.cloudflare.com/cloudflare-one/identity/).
- **Tunnel** → "Cloudflare Tunnel for private Hyperdrive" + "Tunnel-only origin"; [Tunnel docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/).
- **mTLS** → "mTLS for outbound to a vendor"; [mTLS docs](https://developers.cloudflare.com/ssl/client-certificates/).
- **API Shield** → "API Shield + JWT validation at the edge"; [API Shield docs](https://developers.cloudflare.com/api-shield/).
- **Workers Rate Limiting binding** → "Workers Rate Limiting binding"; [Rate Limiting docs](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/).
- **Magic Transit / Magic WAN / Spectrum** — enterprise-network L3 protection; deep coverage is out of scope for this overlay. When a customer mentions BYOIP, GRE/IPsec routes, anycast advertisements, or non-HTTP DDoS, route to Cloudflare account team + the [Magic Transit docs](https://developers.cloudflare.com/magic-transit/).
- **CASB / Browser Isolation / Gateway DNS/HTTP** — Cloudflare One / Zero Trust products; useful when scope expands from "protect this app" to "protect employee endpoint traffic." [Cloudflare One docs](https://developers.cloudflare.com/cloudflare-one/).

## Integration with always-on protocols

### Threat modeling on Cloudflare-fronted apps

Before shipping, walk through:
- **Trust boundaries.** Cloudflare edge ↔ origin. Worker ↔ binding. Worker ↔ external API. Each boundary is an authentication/authorization decision.
- **Failure modes.** What if Access misconfigured (user gets in without MFA)? What if WAF lets a request through? What if a secret leaks? What if rate-limit binding fails? Document the secondary defense.
- **Data flow.** Where does PII enter, where does it live, where does it leave? Cloudflare data localization scoped correctly?
- **Authn vs authz.** Access does identity. Worker does authorization. Don't conflate.
- **Audit trail.** Every privileged action logged. Logpush to SIEM.

### Verification for security-engineer on Cloudflare

Before declaring security posture acceptable:

- [ ] WAF managed rulesets enabled and tuned (no avoidable FPs).
- [ ] Rate limiting in place at edge (zone) and in Worker (business limits).
- [ ] Turnstile on user-input endpoints (signup, forms, comments).
- [ ] Access enabled for internal/admin surfaces with MFA required.
- [ ] Service Auth (JWT) used for service-to-service over Access.
- [ ] Tunnel used for private-origin access; no public IPs needed.
- [ ] mTLS for B2B partner ingress and vendor egress where applicable.
- [ ] Secrets via `wrangler secret`; rotation cadence documented.
- [ ] API tokens scoped per-purpose, per-env, rotated 90 days.
- [ ] All `Cf-Connecting-IP` / `req.cf` usage is validated against direct-origin bypass.
- [ ] Webhooks verify signatures.
- [ ] AI Gateway guardrails enabled for any user-input → LLM path.
- [ ] Bot Management score is consulted on abuse-prone endpoints.
- [ ] Logpush sends `firewall_events`, `access_logins`, `workers_trace_events`, `audit_logs` to SIEM with retention matching compliance.
- [ ] WAF block events are reviewed weekly (FP triage).
- [ ] Origin firewall denies non-Cloudflare traffic (or Tunnel is in use).
- [ ] Authenticated Origin Pulls (mTLS Cloudflare → origin) enabled for direct-IP origins.

### Debugging security incidents on Cloudflare

When something hits the security stack:

1. **WAF blocks → review Logpush `firewall_events`.** Which rule? Which request? Is it a real attacker or a misconfigured customer?
2. **Access denials → `access_logins` dataset.** Identity, policy, time, device posture.
3. **Bot Management false positive → `workers_trace_events`** for the bot score; tune custom rules.
4. **Rate-limit complaints → check both zone and Worker bindings.** Either could be the source.
5. **Secret leak → rotate immediately, audit `audit_logs` for anything that used the secret, identify deploy that contained it.**
6. **AI prompt-injection report → AI Gateway logs for the prompts; tighten guardrails; rate-limit harder.**
7. **Suspected origin bypass → check origin logs for non-Cloudflare IPs; enable Authenticated Origin Pulls / move to Tunnel.**

### Escalation paths

- **Architecture-level security tradeoffs** → `system-architect` overlay (Cloudflare).
- **Worker code that needs to enforce authz** → `backend-architect` overlay.
- **Compliance specifics (HIPAA, PCI, GDPR scope)** → relevant vertical.
- **Secret management process / CI hardening** → `devops-engineer` overlay.
- **AI prompt-injection / RAG security** → `ai-ml-engineer` overlay.

## Threat models for common Cloudflare-shaped systems

### Threat model: public API behind WAF + Workers

| Threat | Defense |
|--------|---------|
| Volumetric DDoS | Cloudflare's always-on DDoS (free) |
| L7 abuse (scrapers, abuse) | Bot Management + Rate Limiting Rules |
| SQL injection / XSS in payloads | OWASP managed ruleset + zod validation in Worker |
| Credential stuffing on login | Exposed Credentials Check + Turnstile + Worker-level lockout |
| API key leak | Short-lived tokens, rotation, anomaly detection in Workers Logs |
| Schema-drift abuse | API Shield with OpenAPI spec |
| Origin bypass | No public origin IP (Tunnel) or Authenticated Origin Pulls |

### Threat model: internal admin behind Access

| Threat | Defense |
|--------|---------|
| Stolen credentials | MFA required in Access policy |
| Phishing-redirected SSO | Phishing-resistant MFA (FIDO2/passkeys) |
| Lateral movement post-auth | Per-action authorization in Worker; least-privilege role |
| Session hijacking | Short session duration in Access app; rotation |
| Insider abuse | Comprehensive audit log; review cadence |

### Threat model: AI-backed chat for customers

| Threat | Defense |
|--------|---------|
| Prompt injection via user input | AI Gateway guardrails + system/user separation in prompt |
| RAG-poisoning via user-uploaded docs | Source attribution; sanity-check retrieved snippets; tenant isolation |
| Cost-burning attacks | Per-user token quota; rate-limit |
| Cross-tenant data leakage in retrieval | Mandatory tenant_id filter on every Vectorize query |
| Tool-call abuse (agent executing harmful tools) | Tool argument validation; tool allow-list; human-in-loop for high-risk tools |
| Sensitive data in prompts | Pre-prompt PII redaction; Workers AI classifier |

### Threat model: webhook ingestion (Stripe, GitHub, Linear)

| Threat | Defense |
|--------|---------|
| Forged webhook | Signature verification (HMAC) in Worker |
| Replay | Idempotency key + dedup store (KV or D1) |
| Body tampering | Sign body, verify byte-exact |
| DoS via webhook flood | Queue ingest; 200 immediately; consume async |
| Webhook source compromise | Source-IP allowlist (where source publishes IPs); mTLS where supported |

### Threat model: SaaS with custom hostnames

| Threat | Defense |
|--------|---------|
| TLS misissuance | Cloudflare-managed certs; CAA records |
| Customer's domain hijacked → impersonation | Domain control validation on CNAME; per-hostname revocation pipeline |
| Tenant-A reaching tenant-B's data | Hostname → tenant_id mapping is authoritative; never trust query/header |
| Cert revocation lag | Automated detection via Cloudflare API; emergency revocation runbook |

## Cloudflare-specific incident response

Standard IR playbook items for Cloudflare-fronted apps:

1. **Suspected breach** — rotate all secrets (`wrangler secret bulk` with new values); rotate API tokens; review `audit_logs` for the last 30 days.
2. **DDoS in progress** — verify Cloudflare WAF/DDoS managed rules engaged; tune custom rules if needed; consider Under Attack Mode for non-API zones.
3. **WAF blocking real users** — identify the rule via `firewall_events`; demote rule to log mode while investigating; add exception or tune sensitivity.
4. **Origin IP leaked** — change origin IP, enable Authenticated Origin Pulls, or migrate to Tunnel; audit traffic for direct-origin requests.
5. **Cloudflare account compromise** — change all admin passwords; rotate all tokens; review `audit_logs` for unauthorized resource changes; escalate to Cloudflare support.
6. **AI prompt-injection in the wild** — strengthen Gateway guardrails; lower rate limits; consider blocking the attacker's IP/account via WAF.
7. **mTLS client cert leaked** — revoke at Cloudflare (mTLS cert binding deletion); reissue; notify partner.

Document the response procedure in a runbook; rehearse on a quarter cadence.

## Standing rules for security-engineer on a Cloudflare engagement

1. **Defense in depth.** Edge layers (WAF, rate limit, Bot, Turnstile) + Access + Worker (rate-limit binding, JWT verify, authz, input validation). Don't collapse layers.
2. **WAF in log mode → tuned → block mode.** Don't ship with untuned WAF or you'll page on real users.
3. **Access for employee surfaces; OAuth in Worker for customer surfaces.** Different problems.
4. **Tunnel beats VPN.** Modern ZTNA story.
5. **Secrets via Wrangler secret, never `vars`.** Rotated. Scoped.
6. **API tokens narrow.** Per-purpose, per-env, 90-day rotation.
7. **Verify `req.cf` exists before trusting Cloudflare-injected headers.** Direct-origin requests don't have it.
8. **Webhooks verify signatures.** Always.
9. **AI Gateway guardrails on prompt paths.** Plus output validation and rate limits.
10. **Logpush four datasets minimum.** `firewall_events`, `access_logins`, `workers_trace_events`, `audit_logs`. Reviewed.
