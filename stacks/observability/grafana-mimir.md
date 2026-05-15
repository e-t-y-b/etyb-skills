---
title: Grafana Mimir
description: Horizontally scalable, multi-tenant Prometheus-compatible long-term storage. Object-storage-backed; 8+ microservice topology.
product:
  name: Grafana Mimir
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer]
  authoritative_url: https://grafana.com/docs/mimir/
  notes: "3.x added Kafka async buffer; multi-tenancy limits surface evolving; per-tenant limits prevent noisy-neighbor."
---

## What it is

Grafana Mimir is the horizontally scalable, multi-tenant, long-term storage for Prometheus metrics. Accepts Prometheus `remote_write` (and OTLP), stores in object storage (S3/GCS), queries via PromQL. See [grafana.com/docs/mimir](https://grafana.com/docs/mimir/).

Topology: 8+ microservices (distributor, ingester, querier, query-frontend, compactor, store-gateway, ruler, alertmanager) — or monolithic mode for small installs.

## When to use

Pick Mimir when:
- You're K8s-native with 3+ dedicated SREs.
- Multi-tenancy is real (per-team / per-customer / per-env).
- Cost at scale matters and you can run object-storage-backed infra.

Alternatives: [VictoriaMetrics](/stacks/observability/victoriametrics/) (simpler, often cheaper), [Thanos](/stacks/observability/thanos/) (smaller jump from single Prometheus), [Grafana Cloud Mimir](/stacks/observability/grafana-cloud/) (managed).

## 2025-2026 currency anchors

- **Mimir 3.x** added Kafka async buffer ingester path — handles ingest spikes without OOM.
- **Per-tenant limits surface evolving** — `max_global_series_per_tenant`, `max_series_per_query`, `max_label_value_length`.
- **OTLP ingest support** — receives OTel metrics directly via `/otlp/v1/metrics` endpoint.

## Patterns

- **Helm chart `grafana/mimir-distributed`** for production K8s deployments.
- **Per-tenant limits mandatory** — one tenant's cardinality explosion otherwise knocks out the cluster.
- **Object storage retention tiering** — keep ~24h in ingester local, push to S3 for long-term.

## Anti-patterns

- **Mimir without per-tenant limits** — one tenant breaks the cluster.
- **Self-hosting Mimir with <3 SREs** — operational burden exceeds Grafana Cloud cost.
- **Single replica of ingester** — data loss on pod restart.

## Gotchas

- **Compactor is critical** — without it, block count grows linearly; queries slow. Monitor.
- **Object storage egress** when querying historicals — can dominate cost on long-window dashboards.
- **Memory sizing for ingester** — proportional to active series; OOMs are common when cardinality grows.

## Cross-references

- Prometheus server → [prometheus-server](/stacks/observability/prometheus-server/)
- Alternative: VictoriaMetrics → [victoriametrics](/stacks/observability/victoriametrics/), Thanos → [thanos](/stacks/observability/thanos/)
- Managed → [Grafana Cloud](/stacks/observability/grafana-cloud/)
- Operational patterns → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Authoritative: [grafana.com/docs/mimir](https://grafana.com/docs/mimir/)
