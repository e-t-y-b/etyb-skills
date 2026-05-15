---
title: Thanos
description: Prometheus long-term storage via object-storage — sidecar + store gateway + querier + compactor. Stable, in maintenance-quality.
product:
  name: Thanos
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer]
  authoritative_url: https://thanos.io/
  notes: "Stable; sidecar + store + querier topology unchanged; smaller migration jump than Mimir."
---

## What it is

Thanos extends Prometheus with object-storage-backed long-term retention. Sidecar reads Prometheus's TSDB blocks, ships to object store; Store Gateway queries historical blocks; Querier federates Sidecar + Store Gateway behind one PromQL endpoint; Compactor downsamples and deduplicates. See [thanos.io](https://thanos.io/).

## When to use

Pick Thanos when:
- You have existing Prometheus and want object-storage-backed retention with minimal change.
- Single-tenant — Thanos doesn't have native multi-tenancy.
- You want a smaller operational footprint than [Mimir](/stacks/observability/grafana-mimir/).

Alternatives: [Mimir](/stacks/observability/grafana-mimir/) (multi-tenant, larger), [VictoriaMetrics](/stacks/observability/victoriametrics/) (simpler, often faster).

## 2025-2026 currency anchors

- **Stable**, in maintenance-quality mode — fewer feature releases than Mimir.
- **Sidecar + Store Gateway + Querier + Compactor** topology unchanged.

## Patterns

- **Sidecar pattern** — drop-in alongside Prometheus.
- **Compactor downsampling** — 5m and 1h downsampled blocks accelerate long-window queries.
- **Receiver mode** as alternative to sidecar — receives `remote_write` instead of reading from disk.

## Anti-patterns

- **Thanos when you need multi-tenant** — use Mimir.
- **Compactor running on the same node as Prometheus** — resource contention.

## Gotchas

- **Object storage egress on long queries** — historicals from S3 cost.
- **Querier deduplication** requires consistent external labels on Prometheus replicas.

## Cross-references

- Prometheus → [prometheus-server](/stacks/observability/prometheus-server/)
- Multi-tenant alternative → [grafana-mimir](/stacks/observability/grafana-mimir/)
- VictoriaMetrics alternative → [victoriametrics](/stacks/observability/victoriametrics/)
- Authoritative: [thanos.io](https://thanos.io/)
