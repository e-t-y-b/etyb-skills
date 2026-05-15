---
title: DDoS Protection
description: Always-on L3-L7 DDoS protection — managed rulesets, Spectrum for non-HTTP, Under Attack Mode for incident response.
product:
  name: DDoS Protection
  stack: cloudflare
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, system-architect]
  authoritative_url: https://developers.cloudflare.com/ddos-protection/
  notes: "L3-L7 protection always-on, free at every plan tier; managed ruleset tuning + Under Attack Mode are the user-facing controls."
---

## What it is

Cloudflare's DDoS Protection is **always-on, on every plan**, including Free. It runs at every PoP, inspecting traffic and shedding volumetric / protocol / application-layer attacks before they hit your origin or [Worker](/stacks/cloudflare/workers/). For non-HTTP (TCP/UDP) workloads, Cloudflare Spectrum and [Magic Transit](/stacks/cloudflare/magic-transit/) extend L3/L4 protection to arbitrary services.

Authoritative reference: [developers.cloudflare.com/ddos-protection](https://developers.cloudflare.com/ddos-protection/).

## When to use

This is rarely a decision — DDoS protection is on for every Cloudflare-proxied zone. What you do choose:

- **Tune managed DDoS rulesets** for sensitivity (default-on; raise sensitivity for noisy customer signal).
- **Under Attack Mode** when an active attack is hitting an HTTP zone.
- **Spectrum / Magic Transit** for non-HTTP services that need DDoS protection.
- **L7 anti-DDoS custom rules** for specific abuse patterns (high request rate from one ASN, etc.).

## 2025-2026 currency anchors

- **DDoS managed rulesets** are configurable per zone; sensitivity levels and per-attack-vector override knobs are mature.
- **Adaptive DDoS Protection** (Enterprise) uses traffic fingerprints to detect anomalous patterns specific to your zone — worth enabling on high-stakes zones.
- **HTTP/3 + QUIC** are now first-class — protection covers them by default.

## Patterns

### Under Attack Mode

For an in-progress L7 attack on an HTTP zone, toggle **Under Attack Mode** (Security → Settings). Every visitor gets a JS challenge for ~5 seconds before reaching your origin. UX cost is real; reserve for active incidents.

Programmatically: zone-level setting via Cloudflare API; can be flipped from a runbook.

### Custom L7 anti-DDoS rule

```
when (cf.threat_score > 50) and (http.request.uri.path eq "/api/expensive-endpoint")
action: managed_challenge
```

For endpoints where the per-request cost is high (LLM inference, DB-heavy queries), tighten the threat-score threshold.

### Spectrum for TCP/UDP services

For non-HTTP services (game servers, SSH bastions, custom protocols) configure Spectrum to front-end the service. Cloudflare absorbs L3/L4 attacks; the origin sees only legitimate connections.

## Anti-patterns

- **Believing "Cloudflare DDoS = invincibility."** L7 attacks specifically crafted for your app's slow endpoints can leak through; complement with [Rate Limiting](/stacks/cloudflare/rate-limiting/) and good app design (no unbounded queries, no easily-amplified endpoints).
- **Leaving Under Attack Mode on indefinitely.** It hurts UX and SEO. Use it during incidents; turn off after.
- **Origin reachable on its real IP.** A determined attacker who finds your origin IP via DNS history bypasses Cloudflare entirely. Use [Cloudflare Tunnel](/stacks/cloudflare/tunnel/) or [Authenticated Origin Pulls](/stacks/cloudflare/waf/).
- **No incident runbook.** When the attack hits, on-call shouldn't be googling how to enable Under Attack Mode.

## Gotchas

1. **DDoS metrics live in the Cloudflare dashboard** + `firewall_events` Logpush dataset. Wire to your SIEM if you care about retention.
2. **Sensitivity tuning has tradeoffs.** Too sensitive → false positives on legit traffic spikes (Hacker News hug-of-death). Too loose → real attacks leak through.
3. **Magic Transit** for L3 protection of non-HTTP infra requires Enterprise + BYOIP setup — not a same-day flip.
4. **Cost protection for Workers** (i.e., the bill cap during an attack) is on Workers Paid plans; without it, an L7 attack on a Worker-backed endpoint can drive Workers AI / D1 / Vectorize charges.

## Cross-references

- [WAF + Managed Rulesets](/stacks/cloudflare/waf/) — L7 attack signatures
- [Rate Limiting](/stacks/cloudflare/rate-limiting/) — complements DDoS for L7 abuse
- [Magic Transit](/stacks/cloudflare/magic-transit/) — L3 protection at the network level
- [Argo](/stacks/cloudflare/argo/) — smart routing during attacks
- [Logpush](/stacks/cloudflare/logpush/) — `firewall_events` includes DDoS mitigation events
- Role overlay: [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/), [system-architect on Cloudflare](/stacks/cloudflare/system-architect/)
- Authoritative: [developers.cloudflare.com/ddos-protection](https://developers.cloudflare.com/ddos-protection/), [Spectrum](https://developers.cloudflare.com/spectrum/)
