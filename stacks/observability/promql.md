---
title: PromQL
description: Prometheus's query language — range vectors, instant vectors, histogram_quantile, rate, irate, increase, label matchers.
product:
  name: PromQL
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer, backend-architect]
  authoritative_url: https://prometheus.io/docs/prometheus/latest/querying/basics/
  notes: "Stable; histogram_quantile + rate patterns matured; UTF-8 metric names allowed in 3.x."
---

## What it is

PromQL is the query language for Prometheus and [Mimir](/stacks/observability/grafana-mimir/), [Thanos](/stacks/observability/thanos/), [VictoriaMetrics](/stacks/observability/victoriametrics/). See [prometheus.io/docs/prometheus/latest/querying/basics](https://prometheus.io/docs/prometheus/latest/querying/basics/).

```promql
# Availability SLI
sum(rate(http_server_request_duration_count{
  http_response_status_code!~"5.."
}[5m]))
/
sum(rate(http_server_request_duration_count[5m]))

# Latency p99 from native histogram
histogram_quantile(0.99, sum(rate(http_server_request_duration[5m])) by (le))
```

## When to use

PromQL is the lingua franca for all Prometheus-compatible TSDBs. Every dashboard, alert, recording rule on these systems is PromQL.

## 2025-2026 currency anchors

- **UTF-8 metric names allowed in 3.x** — query OTel-native names (`http.server.request.duration`) without translation.
- **Native histogram support** — `histogram_quantile()` works on exponential native histograms.

## Patterns

- **`rate()` for counters**, not raw value — counters reset.
- **`histogram_quantile()` for latency**, not avg/median — distributions matter.
- **`sum without(instance)`** to aggregate across pod replicas.
- **`topk(N, ...)`** to find offenders.
- **Recording rules to pre-aggregate** expensive queries — see [Recording Rules](/stacks/observability/recording-rules/).

## Anti-patterns

- **`avg(rate(latency_seconds[5m]))`** — averages of percentiles are nonsense.
- **`rate()` on gauges** — gauges don't increase monotonically; use `delta()` or raw value.
- **Window mismatch in burn-rate math** — `rate(metric[1h])` vs `rate(metric[5m])`. Use both for multi-window.
- **Unbounded label matchers** — `{__name__=~".+"}` queries everything, hits Mimir limits.

## Gotchas

- **`rate()` requires at least 2 samples** in the window — short windows on low-frequency counters return empty.
- **Resolution and step in dashboards** — PromQL evaluates at the dashboard step interval; mismatch causes gaps.
- **Cross-metric joins** require matching labels — many queries silently return empty due to label mismatch.

## Cross-references

- Prometheus → [prometheus-server](/stacks/observability/prometheus-server/)
- Recording rules → [recording-rules](/stacks/observability/recording-rules/)
- SLO + burn-rate patterns → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [prometheus.io/docs/prometheus/latest/querying/basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
