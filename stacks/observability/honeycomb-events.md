---
title: Honeycomb Events + Triggers + BubbleUp
description: Event-based observability — high-cardinality is FREE. Derived columns for SLI, BubbleUp for root cause, Triggers for alerts.
product:
  name: Honeycomb (Events + Triggers + BubbleUp)
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, backend-architect, devops-engineer]
  authoritative_url: https://docs.honeycomb.io/
  notes: "Event model stable; BubbleUp + Triggers + Boards stable; AI insights landed 2025."
---

## What it is

Honeycomb is event-based observability — each event carries arbitrary high-cardinality attributes (no time-series, no label limits, no stream count). The model is the most different from the rest of the observability space. See [docs.honeycomb.io](https://docs.honeycomb.io/).

Surfaces:
- **Events** — high-cardinality attributes attached to spans/events.
- **Derived columns** — expressions evaluated per event (booleans for SLI, computed fields).
- **BubbleUp** — given a slow trace, finds attributes that correlate with slowness. The killer feature.
- **Triggers** — alerts on stored queries.
- **Boards** — collections of saved queries (not laid-out dashboards).
- **Markers** — annotate events with deploy or incident markers.

## When to use

Pick Honeycomb when:
- High-cardinality services (per-customer attribution, e-commerce checkout funnels) push hard against metrics-based platforms.
- Trace-first observability with rich attribute querying matters.
- You want SLOs per-customer without metric cardinality explosion.

Don't pick if:
- You need an APM-style overview dashboard out of the box (Honeycomb expects you to think query-first).
- 60-day max retention is a compliance gap (see audit-log section in [security-engineer overlay](/stacks/observability/security-engineer/)).

## 2025-2026 currency anchors

- **Refinery tail-sampling** standard for >10K events/sec. See [honeycomb-refinery](/stacks/observability/honeycomb-refinery/).
- **AI insights (Honeycomb AI)** landed 2025.
- **Trace-based SLOs** via derived columns — per-customer SLOs are cheap here.

## Patterns

- **Derived columns for SLI** — boolean expressions per event; events return TRUE for "good", FALSE for "bad", NULL to exclude.
- **BubbleUp first** when investigating slow traces — what attribute is overrepresented?
- **Markers for deploys + incidents** — annotate without adding cardinality.
- **Trace-based SLOs** for per-customer SaaS commitments.

## Anti-patterns

- **Pre-aggregating into metrics** — defeats the event model. Let Honeycomb roll up at query time.
- **Random head sampling at 1%** without Refinery — throws away errors and slow requests.
- **Boards as Grafana-style dashboards** — they're query bookmarks, not laid-out panels.

## Gotchas

- **60-day max retention** — compliance gap for HIPAA/SOX. Stream to S3 via export feature if needed.
- **Refinery memory** at very high volume — see [honeycomb-refinery](/stacks/observability/honeycomb-refinery/) gotchas.
- **Pricing per event** — sampling discipline pays back here more than at metrics-based vendors.

## Cross-references

- [Refinery](/stacks/observability/honeycomb-refinery/) tail-sampling
- [Beelines](/stacks/observability/honeycomb-beelines/) (legacy SDK)
- Trace-based SLO pattern → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.honeycomb.io](https://docs.honeycomb.io/)
