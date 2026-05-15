---
title: VictoriaMetrics
description: Drop-in Prometheus replacement with higher throughput per dollar. Single-binary or 3-component cluster. vmagent + vmalert.
product:
  name: VictoriaMetrics
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer]
  authoritative_url: https://docs.victoriametrics.com/
  notes: "Drop-in Prometheus replacement; vmagent + vmalert mature; simplest cluster topology of the alternatives."
---

## What it is

VictoriaMetrics is a Prometheus-compatible TSDB optimized for high throughput and disk efficiency. Single-binary mode for simple setups; 3-component cluster (vmstorage, vminsert, vmselect) for scale. Ecosystem: **vmagent** (lightweight scraper/forwarder), **vmalert** (alert evaluator), **vmgateway**, **vmctl**. See [docs.victoriametrics.com](https://docs.victoriametrics.com/).

## When to use

Pick VictoriaMetrics when:
- You want simpler cluster topology than [Mimir](/stacks/observability/grafana-mimir/) (3 components vs 8+).
- Maximum throughput per dollar — VictoriaMetrics is often the cheapest per-series option.
- You have existing Prometheus and want a drop-in replacement.

## 2025-2026 currency anchors

- **vmagent** mature — replaces Prometheus + remote_write for many use cases (lighter, faster).
- **vmalert** evaluates Prometheus alerting + recording rules against VictoriaMetrics.
- **PromQL + MetricsQL** — MetricsQL is a PromQL superset with helpful additions.

## Patterns

- **Single-binary for <10M active series** — minimal ops.
- **Cluster mode for >10M** — distinct vmstorage, vminsert, vmselect.
- **vmagent at edge** for scrape + remote_write replacement.

## Anti-patterns

- **VictoriaMetrics + Mimir** in the same org — pick one.
- **Single-replica vmstorage** at scale — data loss risk.

## Gotchas

- **MetricsQL extensions** are non-portable — if you might migrate to Prometheus/Mimir later, stick to PromQL syntax.
- **vmselect query timeouts** — tune for long-window dashboards.

## Cross-references

- Prometheus → [prometheus-server](/stacks/observability/prometheus-server/)
- Alternatives → [grafana-mimir](/stacks/observability/grafana-mimir/), [thanos](/stacks/observability/thanos/)
- Authoritative: [docs.victoriametrics.com](https://docs.victoriametrics.com/)
