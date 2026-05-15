---
title: Prometheus Server
description: The reference open-source metrics server. 3.x added OTLP ingest, UTF-8 names, native histograms, Remote Write 2.0.
product:
  name: Prometheus Server
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, backend-architect]
  authoritative_url: https://prometheus.io/docs/
  notes: "Prometheus 3.4 as of 2026; 3.x brought OTLP ingest, UTF-8 metric names, native histograms, Remote Write 2.0."
---

## What it is

Prometheus is the open-source metrics database — pull-based scraping (or push via Pushgateway), label-based TSDB, [PromQL](/stacks/observability/promql/) query language. The reference implementation that the entire CNCF metrics ecosystem builds on. See [prometheus.io/docs](https://prometheus.io/docs/).

## When to use

Pick Prometheus when:
- K8s-native — Prometheus + Prometheus Operator are the canonical pattern.
- OSS metrics stack (with [Thanos](/stacks/observability/thanos/), [Mimir](/stacks/observability/grafana-mimir/), or [VictoriaMetrics](/stacks/observability/victoriametrics/) for long-term).
- Cost-sensitive with real SRE bandwidth.

## 2025-2026 currency anchors

- **Prometheus 3.0** brought **native OTLP ingest** (`/api/v1/otlp/v1/metrics`), **UTF-8 metric names** (so `http.server.request.duration` works without dot-to-underscore translation), **native (exponential) histograms** with order-of-magnitude cardinality reduction on latency metrics, **Remote Write 2.0**.
- **3.4** as of 2026-Q2.
- **Scrape protocol negotiation** — Prometheus negotiates with exporters (text, OpenMetrics, native histograms).

## Patterns

- **`kube-prometheus-stack` Helm chart** — canonical K8s install.
- **2-replica Prometheus** + `kubeStateMetrics` + `node-exporter` + `blackbox-exporter`.
- **Short local retention (2-7 days)** + `remote_write` to long-term storage (Mimir / Thanos / VictoriaMetrics).
- **Native histograms for latency** — order-of-magnitude cardinality reduction vs classic histograms.
- **`metric_relabel_configs` at scrape time** to drop bad labels before TSDB.
- **`sample_limit` per scrape** to kill runaway exporters.

## Anti-patterns

- **Single Prometheus replica** in production.
- **No retention bounds** — disk fills, OOM on restart.
- **High-cardinality labels** (user_id, request_id) — millions of series, OOM.
- **Classic histograms in 3.x environments** — use native histograms.
- **`scrape_interval: 1s`** — 60x cost; 15s default is right.
- **No `sample_limit`** — one bad exporter ingests millions of series.

## Gotchas

- **Cardinality kills the cluster, not just the bill.** No label may have >100 unique values in steady state.
- **`up == 0`** tells you when a scrape target is down — but **not** when Prometheus itself is down. Run a second Prometheus or external synthetic.
- **Native histograms require Prometheus 3.0+ + recent client SDKs.** Pin both.

## Cross-references

- [Alertmanager](/stacks/observability/alertmanager/), [PromQL](/stacks/observability/promql/), [Recording Rules](/stacks/observability/recording-rules/), [Exporters](/stacks/observability/prometheus-exporters/)
- Long-term storage: [Thanos](/stacks/observability/thanos/), [Mimir](/stacks/observability/grafana-mimir/), [VictoriaMetrics](/stacks/observability/victoriametrics/)
- Cardinality detective work → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [prometheus.io/docs](https://prometheus.io/docs/), [Prometheus Operator](https://prometheus-operator.dev/)
