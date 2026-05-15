---
title: Front Door
description: Global L7 + WAF + CDN. Premium SKU adds Private Link origins (zero public exposure) and bot manager. Subsumes retired Azure CDN from Microsoft (classic).
product:
  name: Azure Front Door
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, security-engineer, saas-architect]
  authoritative_url: https://learn.microsoft.com/azure/frontdoor/
  notes: "Premium SKU + Private Link origins; subsumes retired classic Azure CDN; rule engine v2 for routing."
---

## What it is

Azure Front Door is Microsoft's global edge — Layer-7 load balancing, WAF, CDN, TLS termination, custom domains, anycast IP, Microsoft global backbone. Premium SKU adds Private Link to origins (zero public exposure) and bot manager. Canonical reference: [Front Door docs](https://learn.microsoft.com/azure/frontdoor/).

## When to use

Pick Front Door when:

- **Global app** — users worldwide; edge presence reduces latency.
- **CDN need** — cache static assets globally.
- **Private Link to origins** (Premium) — zero public exposure of backend.
- **WAF + bot manager** — Premium bot manager isn't available on App Gateway.
- **Multi-region active-active** — Front Door routes per health / latency / weight.

Pick [Application Gateway](/stacks/azure/application-gateway/) instead when: regional only, want WAF inside a VNet, want TCP/TLS L4 proxy.

## 2025-2026 currency anchors

- **Premium SKU** — Private Link origins, bot manager, advanced WAF rules, Microsoft Threat Intelligence-backed rules.
- **Rule engine v2** — more flexible per-tenant routing (path rewrites, header manipulation, host conditionals).
- **Subsumes retired Azure CDN from Microsoft (classic)** — migrate classic CDN to Front Door Standard/Premium.
- **Standard SKU** — entry tier, no Private Link origins or bot manager.
- **Managed certificates** with DNS verification.
- **Custom domain per tenant** workflow (DNS TXT/CNAME verification + auto-cert) — common SaaS pattern.

## Patterns + anti-patterns

### Pattern: Front Door Premium + Private Link to origins

Origins (Container Apps / App Service / AKS ingress) have no public endpoint. Front Door reaches them via Private Link. Zero internet exposure on the data plane.

### Pattern: Multi-region active-active routing

Two origins in different regions; Front Door routes per latency + health. Failover is automatic on origin health failure.

### Pattern: SaaS per-tenant custom domain

DNS verification (TXT or CNAME) → Front Door auto-issues managed cert → SNI binding per domain. Tenant's custom hostname terminates at Front Door; routed to shared origin with `X-Tenant-ID` header.

### Pattern: WAF + bot manager in Detection then Prevention

Premium bot manager filters bad bots (scrapers, credential stuffers). Start Detection; tune; flip to Prevention.

### Anti-pattern: Front Door for regional internal app

Front Door is global edge. For regional or internal apps, use [Application Gateway](/stacks/azure/application-gateway/).

### Anti-pattern: Origins on public endpoints despite Front Door

If you have Front Door but origins are still public, attackers bypass Front Door. Premium + Private Link closes this gap.

### Anti-pattern: Classic Azure CDN from Microsoft for new builds

Retired. Use Front Door.

## Gotchas

- **Cost model** — per GB egress + per request. For high-traffic CDN scenarios, validate budget against Cloudflare / Vercel alternatives.
- **Rule engine v2** vs v1 — pick v2; new features land there.
- **Backend health probe path** — must return 200 consistently; misconfiguration cycles origins.
- **Bot manager false positives** — tune carefully; some legitimate user agents look bot-like.

## Cross-references

- [Application Gateway](/stacks/azure/application-gateway/) — regional alternative
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — WAF design + bot manager
- [SaaS Architect on Azure](/stacks/azure/saas-architect/) — per-tenant custom domain
- [System Architect on Azure](/stacks/azure/system-architect/) — load balancer selection
- [Front Door overview](https://learn.microsoft.com/azure/frontdoor/front-door-overview)
