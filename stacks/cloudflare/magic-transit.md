---
title: Magic Transit
description: L3 DDoS protection and SD-WAN replacement for enterprise networks — anycast IP ingress over GRE/IPsec, with optional Magic WAN and Spectrum for non-HTTP services.
product:
  name: Magic Transit
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, system-architect, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/magic-transit/
  notes: "Enterprise-tier networking; BYOIP, GRE/IPsec, anycast advertisements — paired closely with the Cloudflare account team."
---

## What it is

Magic Transit applies Cloudflare's edge network — DDoS, anycast routing, rule engine — to **L3** (IP-level) traffic for an entire on-prem or VPC network. You advertise your IP space to Cloudflare via BGP (BYOIP) or terminate over GRE / IPsec tunnels. Cloudflare scrubs and forwards. Magic WAN adds SD-WAN connectivity between sites; Spectrum handles individual non-HTTP services.

Authoritative reference: [developers.cloudflare.com/magic-transit](https://developers.cloudflare.com/magic-transit/).

## When to use

- **Enterprise networks subject to high-volume L3/L4 DDoS** — gaming infra, financial trading systems, government, large e-commerce backbones.
- **Replacing legacy DDoS scrubbing providers** (Akamai Prolexic, AWS Shield Advanced + Network Firewall, etc.) with Cloudflare as the carrier.
- **SD-WAN replacement** for branch-to-datacenter connectivity through Cloudflare's backbone.
- **Compliance-bound networks** where every packet to the protected estate must traverse a controlled edge.

Don't reach for Magic Transit when:

- You only need to protect HTTP zones — [WAF](/stacks/cloudflare/waf/) + [DDoS Protection](/stacks/cloudflare/ddos/) at the zone level is sufficient and far simpler.
- The workload is fronted by a [Worker](/stacks/cloudflare/workers/) — L7 protection is already built in.
- Your team isn't ready to operate BGP / GRE / IPsec — Magic Transit is an enterprise-networking product, not a self-serve SKU.

## 2025-2026 currency anchors

- **Magic WAN** matured as an SD-WAN replacement product through 2024-2025; it composes with Magic Transit but is a distinct offering for site-to-site.
- **Spectrum** is the SaaS-product flavor for single non-HTTP services (TCP/UDP); Magic Transit is the whole-network flavor.
- **Enterprise-only.** Pricing, scope, and contract terms are negotiated with the Cloudflare account team.

## Patterns

### BGP / BYOIP ingress

Customer advertises owned IP space to Cloudflare. Cloudflare anycasts the prefixes from every PoP. Inbound traffic lands on Cloudflare's edge; scrubbed traffic forwards to the origin via GRE tunnel.

### GRE / IPsec for non-BYOIP

For customers who don't bring their own IPs (or for additional capacity), GRE or IPsec tunnels between the origin's network edge and Cloudflare.

### Magic WAN site-to-site

Branch routers connect to Cloudflare via Magic WAN connector or hardware appliance; site-to-site traffic flows through Cloudflare's backbone instead of MPLS or VPN.

### Spectrum for one TCP/UDP service

If only one service (a single SSH bastion, a single game server) needs L3/L4 protection, Spectrum is the lighter path — no BGP, no GRE/IPsec, configured per-service in the dashboard.

## Anti-patterns

- **Confusing Magic Transit with [Cloudflare Tunnel](/stacks/cloudflare/tunnel/).** Tunnel is outbound-initiated, app-level, for any plan. Magic Transit is BGP-/IPsec-/GRE-based, network-level, enterprise-only. Different products, different problems.
- **Trying to self-serve Magic Transit.** The product requires Cloudflare network engineering involvement; expect weeks of onboarding for a real deployment.
- **Skipping the simpler products.** If [WAF](/stacks/cloudflare/waf/) + [DDoS Protection](/stacks/cloudflare/ddos/) at the HTTP zone level fits your threat model, Magic Transit is overkill.

## Gotchas

1. **BGP coordination** with your upstream ISPs / IXs is operationally non-trivial — RIR records, ROA, route filters, etc. Plan for weeks, not days.
2. **MTU surprises** with GRE/IPsec — fragment-handling and MSS clamping at the tunnel boundary trip up app teams.
3. **No first-party [Workers](/stacks/cloudflare/workers/) integration.** Magic Transit protects the IP space; if you want to insert Worker logic, you still need the HTTP-zone path on top.
4. **Pricing is bespoke** — committed-throughput-based, negotiated.

## Cross-references

- [DDoS Protection](/stacks/cloudflare/ddos/) — the always-on HTTP-zone equivalent
- [Cloudflare Tunnel](/stacks/cloudflare/tunnel/) — outbound, app-level, simpler scope
- [WAF + Managed Rulesets](/stacks/cloudflare/waf/) — L7, runs after Magic Transit scrubs L3/L4
- Role overlay: [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/magic-transit](https://developers.cloudflare.com/magic-transit/), [Magic WAN](https://developers.cloudflare.com/magic-wan/), [Spectrum](https://developers.cloudflare.com/spectrum/)
