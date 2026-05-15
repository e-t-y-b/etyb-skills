---
title: Grafana Cloud
description: Managed Grafana + LGTM (Loki, Grafana, Tempo, Mimir) + Pyroscope + Faro + Beyla + k6 + OnCall + IRM. Per-active-series billing.
product:
  name: Grafana Cloud
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer]
  authoritative_url: https://grafana.com/docs/grafana-cloud/
  notes: "Adaptive Metrics + 95th-pctl billing 2024-26; tier breakpoints predictable; FedRAMP Moderate."
---

## What it is

Grafana Cloud is the managed SaaS bundling [Mimir](/stacks/observability/grafana-mimir/), [Loki](/stacks/observability/grafana-loki/), [Tempo](/stacks/observability/grafana-tempo/), [Pyroscope](/stacks/observability/grafana-pyroscope/), [Faro](/stacks/observability/grafana-faro/), [Beyla](/stacks/observability/grafana-beyla/), [k6](/stacks/observability/k6/), [Grafana Alerting](/stacks/observability/grafana-alerting/), and [Grafana OnCall + IRM](/stacks/observability/grafana-oncall/) into one platform. See [grafana.com/docs/grafana-cloud](https://grafana.com/docs/grafana-cloud/).

Billing: **per-1K-active-series (metrics) + per-GB (logs/traces/profiles)** — the most predictable in the industry. 95th-percentile billing excludes top-5% usage spikes.

## When to use

Pick Grafana Cloud when:
- You want managed LGTM without operating Mimir/Loki/Tempo yourself.
- Per-series predictability matters.
- Multi-region (US, EU, AU regions available).
- FedRAMP Moderate compliance is required.

Don't pick if:
- You want one single vendor for absolutely everything (Datadog's surface is broader).
- Datadog or NR's correlation depth is critical (Grafana Cloud is best-of-breed composition, not single-pane).

## 2025-2026 currency anchors

- **Adaptive Metrics (2024+)** — auto-detects unused series and offers to drop. Saves 30-60% on series count in mature installs.
- **95th-percentile billing** — spikes during outages don't bill.
- **k6 Cloud** (2024) — managed load testing.
- **Grafana Cloud Frontend Observability** (Faro-managed) — managed RUM.
- **Grafana 11.x** UI matured; Scenes (replacing legacy dashboards-as-code patterns).

## Patterns

- **Self-hosted Prometheus + Grafana Cloud remote_write** — hybrid pattern. Local Prometheus for short-retention + Cloud for long-term.
- **Use Adaptive Metrics to right-size** — review monthly.
- **Bring [Alloy](/stacks/observability/grafana-alloy/) as the collector**.

## Anti-patterns

- **Self-hosted LGTM with <3 SREs** — operational burden exceeds Cloud cost.
- **Grafana Cloud + Datadog in parallel** — duplicated cost.
- **Ignoring Adaptive Metrics** — leaves 30-60% savings on the table.

## Gotchas

- **Cardinality limits per tier** — Free / Pro / Advanced have hard active-series caps; check before scale-up.
- **Object storage egress** for Loki/Tempo querying historicals — can exceed compute cost on long queries.
- **Region locked at signup** — pick US / EU / AU at the start.

## Cross-references

- Self-hosted alternative → [Mimir](/stacks/observability/grafana-mimir/) + [Loki](/stacks/observability/grafana-loki/) + [Tempo](/stacks/observability/grafana-tempo/) overview
- Operational patterns → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Authoritative: [grafana.com/docs/grafana-cloud](https://grafana.com/docs/grafana-cloud/)
