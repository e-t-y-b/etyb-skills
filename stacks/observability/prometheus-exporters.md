---
title: Prometheus Exporters
description: HTTP endpoints that expose metrics in Prometheus text format — node-exporter, blackbox-exporter, postgres-exporter, kube-state-metrics, etc.
product:
  name: Prometheus Exporters
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer]
  authoritative_url: https://prometheus.io/docs/instrumenting/exporters/
  notes: "Mature ecosystem; node-exporter, blackbox-exporter, kube-state-metrics, postgres-exporter, redis-exporter all stable."
---

## What it is

Prometheus exporters are HTTP `/metrics` endpoints that expose system, database, or service-internal state in Prometheus text format. Prometheus scrapes them on schedule. See [prometheus.io/docs/instrumenting/exporters](https://prometheus.io/docs/instrumenting/exporters/).

Common exporters:
- **node-exporter** — host-level metrics (CPU, memory, disk, network).
- **kube-state-metrics (KSM)** — K8s object state (pods, deployments, nodes).
- **blackbox-exporter** — probe HTTP/TCP/ICMP from inside cluster (synthetic-like, internal).
- **postgres-exporter, mysqld-exporter, redis-exporter, mongodb-exporter** — database internals.
- **prometheus-msteams, prometheus-snmp-exporter, jmx-exporter** — long tail.

## When to use

Always — exporters are the path to get infra/DB telemetry into Prometheus. Pair with [Prometheus Server](/stacks/observability/prometheus-server/).

## 2025-2026 currency anchors

- **Stable ecosystem**; rare breaking changes.
- **`kube-state-metrics` label allowlist** is critical — default labels generate custom-metric explosions on managed vendors. Configure `metricLabelsAllowlist`.

## Patterns

- **DaemonSet `node-exporter`** on every K8s node.
- **Deployment `kube-state-metrics`** with tight `metricLabelsAllowlist`.
- **Sidecar database exporters** to avoid DB credential proliferation.
- **Pin exporter version** in Helm values.

## Anti-patterns

- **`kube-state-metrics` with default labels** at scale on Datadog → custom-metric explosion. Always set `metricLabelsAllowlist`.
- **`blackbox-exporter` for external synthetics** — runs inside cluster, misses ISP/CDN/DNS issues. Use external synthetics ([Datadog Synthetics](/stacks/observability/datadog-synthetics/), [Grafana Synthetic](/stacks/observability/grafana-cloud/), Checkly) for external coverage.
- **Many exporters, no `sample_limit`** — one runaway OOMs Prometheus.

## Gotchas

- **Exporter version drift** with target system version — `postgres-exporter` may need updates per Postgres major.
- **Exporter security** — exporters often expose sensitive internals; restrict `/metrics` endpoint by NetworkPolicy.

## Cross-references

- Prometheus → [prometheus-server](/stacks/observability/prometheus-server/)
- ServiceMonitor / PodMonitor CRDs → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Authoritative: [prometheus.io/docs/instrumenting/exporters](https://prometheus.io/docs/instrumenting/exporters/)
