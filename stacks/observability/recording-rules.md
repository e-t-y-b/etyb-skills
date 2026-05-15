---
title: Recording Rules
description: Pre-computed PromQL expressions stored as new time series — accelerate dashboards, drive SLO computation. TDD via promtool.
product:
  name: Recording Rules
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer]
  authoritative_url: https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/
  notes: "Pattern stable; promtool test rules workflow mature; Sloth / Pyrra generate SLO recording rules."
---

## What it is

Recording rules pre-compute expensive PromQL expressions on a schedule and store the result as new time series. Used to: accelerate dashboards, drive SLO computation, pre-aggregate high-cardinality queries into low-cardinality series. See [prometheus.io/docs/prometheus/latest/configuration/recording_rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/).

```yaml
groups:
  - name: api.rules
    interval: 30s
    rules:
      - record: job:http_requests_total:rate5m
        expr: sum(rate(http_requests_total[5m])) by (job)
      - record: slo:checkout:error_ratio_rate5m
        expr: |
          sum(rate(http_server_request_duration_count{
            service_name="checkout-api", http_response_status_code=~"5.."
          }[5m]))
          /
          sum(rate(http_server_request_duration_count{
            service_name="checkout-api"
          }[5m]))
```

## When to use

- **SLO computation** — burn-rate alerts evaluate recording rules, not raw metrics.
- **Expensive dashboards** — pre-aggregate to keep dashboards fast.
- **Cross-service rollups** — sum across many services into a single team-level series.

## 2025-2026 currency anchors

- **Sloth and Pyrra generate SLO recording rules** declaratively. Use Sloth if you want CLI + K8s operator; Pyrra if you want UI + recording rules + Kubernetes CRDs.
- **`promtool test rules`** for TDD on recording rules — mature workflow.

## Patterns

### TDD recording rules

```yaml
rule_files:
  - "slo-recording-rules.yaml"
tests:
  - interval: 1m
    input_series:
      - series: 'http_server_request_duration_count{service_name="checkout-api",http_response_status_code="200"}'
        values: '100x5'
      - series: 'http_server_request_duration_count{service_name="checkout-api",http_response_status_code="500"}'
        values: '1x5'
    promql_expr_test:
      - expr: slo:checkout:error_ratio_rate5m
        eval_time: 5m
        exp_samples:
          - labels: '{service_name="checkout-api"}'
            value: 0.01
```

### Naming convention

`level:metric:operation` — e.g., `job:http_requests_total:rate5m`. Makes it obvious in PromQL that this is a recorded series.

## Anti-patterns

- **Recording rule for every query** — explodes series count.
- **No TDD via `promtool test rules`** — broken rules ship; SLO alerts fire on bad data.
- **Window mismatch** — recording rule uses `rate(metric[5m])` but alert expects `rate(metric[1h])`.

## Gotchas

- **Rule evaluation lags** — `interval: 30s` means the rule output is up to 30s stale.
- **Backfill is hard** — recording rules don't retroactively compute historicals.

## Cross-references

- PromQL → [promql](/stacks/observability/promql/)
- Prometheus → [prometheus-server](/stacks/observability/prometheus-server/)
- SLO tooling (Sloth, Pyrra, Nobl9) → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [prometheus.io/docs/prometheus/latest/configuration/recording_rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
