---
title: Grafana Tempo + TraceQL
description: Object-storage-backed distributed tracing. TraceQL for queries; spanmetrics + servicegraph for derived signals.
product:
  name: Grafana Tempo + TraceQL
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, backend-architect]
  authoritative_url: https://grafana.com/docs/tempo/
  notes: "TraceQL metrics + service-graph processor GA; tail-based sampling moved to Tempo metrics generator."
---

## What it is

Grafana Tempo is object-storage-backed distributed tracing. Stores spans in S3/GCS, queries via **TraceQL**. Generates RED metrics via the `metrics-generator` (`spanmetrics`, `servicegraph` connectors). See [grafana.com/docs/tempo](https://grafana.com/docs/tempo/).

## When to use

Pick Tempo when:
- You're in the Grafana ecosystem.
- Object-storage-backed trace retention at low cost.
- TraceQL syntax fits your query patterns.

Alternatives: Jaeger (older OSS), Zipkin (older OSS), vendor APMs (DD/NR/Honeycomb).

## 2025-2026 currency anchors

- **TraceQL metrics GA** — derive metrics from traces inside Tempo.
- **Service-graph processor GA** — auto-build service topology from traces.
- **Metrics generator** writes RED + service-graph metrics back to Mimir.

## Patterns

- **Tail-based sampling via OTel Collector** upstream — Tempo accepts all spans the collector sends; sampling decisions happen earlier.
- **Use `spanmetrics` connector at the Collector** — avoid double-charging for app-side custom RED metrics.
- **Object storage for long retention** — cheap; query latency higher than ingester-local.

## Anti-patterns

- **Tempo without `tail_sampling` upstream** — full-sample at scale is expensive.
- **Spans + manual RED metrics in app code** — let `spanmetrics` derive.
- **Single replica of distributor / ingester** — span loss.

## Gotchas

- **Object storage egress on query** — historical queries hit S3.
- **TraceQL is younger than PromQL/LogQL** — less community content; refer to the official docs.

## Cross-references

- Tail-based sampling at Collector → [otel-collector](/stacks/observability/otel-collector/)
- Grafana Cloud managed → [grafana-cloud](/stacks/observability/grafana-cloud/)
- Mimir for derived metrics → [grafana-mimir](/stacks/observability/grafana-mimir/)
- Authoritative: [grafana.com/docs/tempo](https://grafana.com/docs/tempo/)
