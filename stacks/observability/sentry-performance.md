---
title: Sentry Performance
description: Span-based tracing inside Sentry — OTel SpanProcessor integration. Mid-2025 repricing on accepted spans; use dynamic sampling.
product:
  name: Sentry Performance
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer]
  authoritative_url: https://docs.sentry.io/product/performance/
  notes: "Spans v2 + Performance repricing mid-2025 (per accepted span); dynamic sampling default; tracesSampleRate 1.0 = outage risk."
---

## What it is

Sentry Performance is the tracing surface inside Sentry — captures spans alongside errors for performance + error correlation. Integrates with OTel via Sentry SpanProcessor (OTel spans flow into Sentry). See [docs.sentry.io/product/performance](https://docs.sentry.io/product/performance/).

## When to use

Pick Sentry Performance when:
- You're already on [Sentry Errors](/stacks/observability/sentry-errors/) and want minimal performance lens.
- Frontend + backend in one platform with replay correlation.

For production-grade performance dashboards, pair with a dedicated trace backend ([Datadog APM](/stacks/observability/datadog-apm/), [Honeycomb](/stacks/observability/honeycomb-events/), [Tempo](/stacks/observability/grafana-tempo/)). They complement; don't compete.

## 2025-2026 currency anchors

- **Spans v2 + Performance repricing (mid-2025)** — Performance is metered on **accepted spans**, not transactions. Pricing changed.
- **Dynamic sampling default** — Sentry decides per-environment, balances quota.
- **`tracesSampleRate: 1.0` is an outage waiting** — span quota burn in days at moderate volume.

## Patterns

- **Use dynamic sampling**, not hand-tuned `tracesSampleRate`.
- **OTel + Sentry integration** via SpanProcessor — one span set, sent to both.
- **Pair with replay** for error-driven RUM context.

## Anti-patterns

- **`tracesSampleRate: 1.0` in production** — bill balloon.
- **Hand-tuned per-service `tracesSampleRate`** — defeats dynamic sampling.
- **Sentry as primary APM** — for production dashboards, use a dedicated trace backend.

## Gotchas

- **Spans v2 model** — count is per accepted span, not per transaction. Aggressive sampling = bill surprise.
- **Profile integration** with [Sentry Profiling](/stacks/observability/sentry-profiling/) — profiles attached to spans; check sampling consistency.

## Cross-references

- [Sentry Errors](/stacks/observability/sentry-errors/)
- [Sentry Profiling](/stacks/observability/sentry-profiling/)
- [Sentry Replay](/stacks/observability/sentry-replay/)
- Sampling strategy → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.sentry.io/product/performance](https://docs.sentry.io/product/performance/)
