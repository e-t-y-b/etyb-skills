---
title: Grafana Loki
description: Horizontally scalable log aggregation — TSDB index, bloom filters, structured metadata. GB-ingested billing, not stream count.
product:
  name: Grafana Loki
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer]
  authoritative_url: https://grafana.com/docs/loki/
  notes: "Loki 3.x TSDB index by default; bloom filters GA; structured metadata replaces high-cardinality label patterns."
---

## What it is

Grafana Loki is horizontally scalable log aggregation, designed Prometheus-style. Stores logs as compressed streams keyed by labels; queries via **LogQL**. Object-storage-backed. See [grafana.com/docs/loki](https://grafana.com/docs/loki/).

Cost model: **GB ingested + GB stored**, NOT stream count or label cardinality (in 3.x with structured metadata).

## When to use

Pick Loki when:
- You're K8s-native and want Prometheus-style log management.
- Cost predictability per GB matters.
- You're in the Grafana ecosystem (LGTM-stack).

Don't pick if:
- You need rich full-text search like Splunk — Loki is grep-style.
- Compliance demands 1+ year hot-queryable retention without object-storage warmup latency.

## 2025-2026 currency anchors

- **Loki 3.x** TSDB index by default (replaces old chunk index).
- **Bloom filters GA** — accelerated label-value queries.
- **Structured metadata** — key-value pairs on log lines that don't drive label-based queries. **Critical**: use structured metadata instead of labels for high-cardinality fields (`request_id`, `trace_id`, `user_id`). Labels create streams; structured metadata doesn't bloat stream count.
- **OTLP logs ingest** — accept logs over OTLP.

## Patterns

- **Labels low-cardinality** — `cluster`, `namespace`, `app`, `pod`. NOT `request_id`, `user_id`, `trace_id`.
- **Structured metadata for high-cardinality fields** — `trace_id`, `span_id`, `request_id`, `customer_id` go here.
- **Helm chart `grafana/loki-distributed`** for production.
- **TSDB index since 3.x** — auto-enabled in new installs; migrate older.

## Anti-patterns

- **Labels as fields** — `request_id` as label → millions of streams, query timeouts.
- **Single-replica ingester** — data loss on restart.
- **No retention bound** — disk fills; configure `compactor.retention_period`.
- **Loki without bloom filters at high label cardinality** — query times degrade.

## Gotchas

- **Migration from label to structured metadata** is non-trivial for existing dashboards — plan a cutover window.
- **Object storage egress on query** — historicals from S3 cost.
- **LogQL is grep-style** — sophisticated search patterns require regex; not Splunk-grade.

## Cross-references

- Grafana Cloud managed → [grafana-cloud](/stacks/observability/grafana-cloud/)
- Alternative: Splunk Cloud → [splunk-cloud](/stacks/observability/splunk-cloud/) for SIEM-grade
- Operational patterns → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Authoritative: [grafana.com/docs/loki](https://grafana.com/docs/loki/)
