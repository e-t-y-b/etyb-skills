---
title: Argo Smart Routing
description: Tiered caching plus smart routing across Cloudflare's backbone — measurable latency wins on the long tail of cache-miss traffic.
product:
  name: Argo
  stack: cloudflare
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/argo-smart-routing/
  notes: "Stable feature; cost is a per-zone add-on. Most measurable wins on cache-miss-heavy traffic to a single backend region."
---

## What it is

Argo is two related features:

- **Argo Smart Routing** — Cloudflare routes cache-miss (origin-bound) traffic over its own backbone using real-time congestion data, instead of letting it traverse the public internet end-to-end.
- **Tiered Cache** — multi-tier cache topology that consolidates origin requests through a smaller set of upper-tier PoPs, raising hit ratio.

Authoritative reference: [developers.cloudflare.com/argo-smart-routing](https://developers.cloudflare.com/argo-smart-routing/).

## When to use

- **HTTP zones with substantial origin-bound traffic** that traverses long distances (origin in one region, users worldwide).
- **Cache-miss heavy workloads** where average origin RTT matters — Argo's typical promise is ~30% reduction in end-to-end latency variance.
- **Zones running through Cloudflare's CDN** where every percentage point of hit ratio matters — Tiered Cache stacks neatly.

Don't reach for Argo when:

- Your origin is a [Worker](/stacks/cloudflare/workers/) — there's no origin-bound cache-miss traffic to route smarter.
- Your audience is regional and origin is close — Argo's wins shrink dramatically.
- Cost is the constraint and the latency gain isn't measured — Argo is a per-zone paid add-on.

## 2025-2026 currency anchors

- **[Smart Placement](/stacks/cloudflare/smart-placement/) overlaps for Workers** — Smart Placement runs the Worker near the backend, often capturing similar wins for Worker-fronted apps. Argo is the legacy zone-level mechanism; Smart Placement is the modern Worker-level one.
- **Tiered Cache topology** has matured — Cloudflare manages the upper-tier topology; you opt in via Cache settings.

## Patterns

### Enable Argo + Tiered Cache

Both flip on at the zone level via dashboard or API. Measure before / after with RUM (`Real User Monitoring`) or Workers Logs latency percentiles — Argo's gains are real but variable.

### Argo vs Smart Placement

| Scenario | Use |
|----------|-----|
| Static-asset CDN with origin in us-east-1, users worldwide | **Argo + Tiered Cache** |
| Worker that talks to a single Postgres in us-east-1 | **[Smart Placement](/stacks/cloudflare/smart-placement/)** — Worker runs near the backend |
| Both | Argo for the CDN tier; Smart Placement for the Worker tier |

## Anti-patterns

- **Buying Argo without measuring.** Latency improvements are measurable; if you can't show a delta in your p50 / p95, you're paying for invisible value.
- **Argo as a substitute for caching.** Cache aggressively at the CDN tier first; Argo helps the misses, not the hits.
- **Ignoring Tiered Cache.** Argo Smart Routing is half of the value; Tiered Cache compounds the hit-ratio gain.

## Gotchas

1. **Per-zone pricing.** Argo charges for routed bytes; high-throughput sites should estimate cost before enabling.
2. **Diminishing returns when origin moves closer.** Migrating origin to Cloudflare-adjacent infra (or to a Worker) reduces Argo's value proposition.
3. **Tiered Cache topology is managed by Cloudflare** — you don't pick the upper-tier PoPs.

## Cross-references

- [Smart Placement](/stacks/cloudflare/smart-placement/) — Worker-level analog
- [Workers](/stacks/cloudflare/workers/) — the modern path to "compute near data"
- [DDoS Protection](/stacks/cloudflare/ddos/) — runs in parallel with Argo at every PoP
- Role overlay: [system-architect on Cloudflare](/stacks/cloudflare/system-architect/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/argo-smart-routing](https://developers.cloudflare.com/argo-smart-routing/), [Tiered Cache](https://developers.cloudflare.com/cache/how-to/tiered-cache/)
