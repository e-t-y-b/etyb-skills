---
title: Grafana Faro
description: OSS + Grafana Cloud RUM — web SDK, OTel-compatible. Mobile (limited), Frontend Observability managed surface.
product:
  name: Grafana Faro
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer]
  authoritative_url: https://grafana.com/docs/grafana-cloud/monitor-applications/frontend-observability/
  notes: "Faro GA 2024; still landing features; web-first with limited mobile; OTel-compatible output."
---

## What it is

Grafana Faro is the OSS + Grafana Cloud RUM (Real User Monitoring) — a web SDK that captures page load metrics, route changes, errors, user interactions, and ships as OTel-compatible telemetry. See [grafana.com/docs/grafana-cloud/monitor-applications/frontend-observability](https://grafana.com/docs/grafana-cloud/monitor-applications/frontend-observability/).

## When to use

Pick Faro when:
- You're in the Grafana ecosystem.
- You want OSS + OTel-compatible RUM.
- Web RUM is the primary concern (mobile is limited).

Alternatives: [Datadog RUM](/stacks/observability/datadog-rum/), [Sentry Replay](/stacks/observability/sentry-replay/) (for replay-focused), New Relic Browser, Dynatrace RUM.

## 2025-2026 currency anchors

- **GA 2024**; still landing features through 2026.
- **OTel-compatible** — ships as OTel traces and metrics.
- **Frontend Observability** is the managed (Grafana Cloud) surface.

## Patterns

- **Sample sessions** to control cost.
- **Correlate to backend traces** via `traceparent` header (CORS required).
- **Pair with [Sentry Replay](/stacks/observability/sentry-replay/)** if you need session replay video — Faro doesn't include replay.

## Anti-patterns

- **Faro alone for replay-heavy workflows** — Faro lacks DOM replay.
- **No CORS for `traceparent`** — breaks RUM↔backend trace pivot.

## Gotchas

- **Mobile coverage limited** — Faro is primarily web. For mobile RUM, prefer DD Mobile RUM, NR Mobile, or Sentry Mobile.
- **Newer than DD/NR RUM** — fewer community resources.

## Cross-references

- Alternatives: [Datadog RUM](/stacks/observability/datadog-rum/), [Sentry Replay](/stacks/observability/sentry-replay/)
- RUM strategy → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [grafana.com/docs/grafana-cloud/monitor-applications/frontend-observability](https://grafana.com/docs/grafana-cloud/monitor-applications/frontend-observability/)
