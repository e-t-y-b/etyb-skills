---
title: Application Gateway
description: Regional L7 load balancer + WAF v2 SKU. L4 (TCP/TLS) proxy in preview. Pick for in-VNet inspection of regional apps; Front Door for global.
product:
  name: Application Gateway v2
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, security-engineer]
  authoritative_url: https://learn.microsoft.com/azure/application-gateway/
  notes: "Regional L7; WAF v2 SKU stable; Layer 4 (TCP/TLS) proxy in preview."
---

## What it is

Application Gateway v2 is Azure's regional Layer-7 load balancer with TLS termination, URL-based routing, multi-site hosting, autoscaling, and WAF v2 SKU. Canonical reference: [Application Gateway docs](https://learn.microsoft.com/azure/application-gateway/).

## When to use

Pick Application Gateway when:

- **Regional app** — single Azure region; no need for global edge.
- **WAF inside the VNet** — inspection on traffic that hasn't crossed the edge.
- **Path-based routing within a VNet** — multiple backend pools (apps).
- **TCP/TLS proxy** (preview) — Layer 4 needs in addition to L7.

Pick [Front Door](/stacks/azure/front-door/) instead when: global app, want CDN, want Private Link to origins (zero public exposure), want bot manager.

## 2025-2026 currency anchors

- **WAF v2 SKU** with managed CRS rule sets, custom rules, geo-filtering, rate limiting.
- **Layer 4 (TCP/TLS) proxy in preview** — extends App Gateway beyond pure HTTP.
- **Autoscaling** with min/max instance counts.
- **mTLS to backends** supported.
- **Integration with Key Vault** for cert lifecycle.

## Patterns + anti-patterns

### Pattern: App Gateway WAF v2 in front of regional internet-facing app

Public IP → App Gateway (WAF v2) → backend pool (App Service / Container Apps / AKS). WAF in Detection mode first, then Prevention after tuning.

### Pattern: Internal App Gateway for VNet-only apps

Private IP App Gateway → backend in internal subnet. Useful for line-of-business apps with strict no-internet posture.

### Pattern: Key Vault-backed certs

Cert lifecycle in Key Vault; App Gateway reads via Managed Identity. Auto-renews don't require redeploy.

### Anti-pattern: App Gateway for global app

Regional. Use [Front Door](/stacks/azure/front-door/) for global L7.

### Anti-pattern: App Gateway as a generic firewall

It's L7 (with preview L4). For network-level firewall, use Azure Firewall. For inspection of east-west VNet traffic, Azure Firewall + NSGs.

## Gotchas

- **WAF rule tuning** is real work. Default Prevention mode will block legitimate traffic; Detection mode + tuning + then Prevention is the path.
- **Backend health probe** quirks — custom probe with correct path / status / body match is often needed.
- **Two SKUs (v1 vs v2)** — v1 is legacy; use v2.
- **Path-based routing rules** are evaluated in order; first match wins.

## Cross-references

- [Front Door](/stacks/azure/front-door/) — global L7 alternative
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — WAF design
- [System Architect on Azure](/stacks/azure/system-architect/) — load balancer selection
- [Application Gateway overview](https://learn.microsoft.com/azure/application-gateway/overview)
