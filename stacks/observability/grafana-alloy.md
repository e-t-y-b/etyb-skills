---
title: Grafana Alloy
description: Grafana's OTel-Collector-compatible distribution — replaces Grafana Agent (EOL Nov 2025). River/Alloy config + Prometheus pipelines + clustering.
product:
  name: Grafana Alloy
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer]
  authoritative_url: https://grafana.com/docs/alloy/
  notes: "Replaced Grafana Agent Nov 2025; OpAMP support landing; clustering mode mature."
---

## What it is

Grafana Alloy is the Grafana distribution of the [OTel Collector](/stacks/observability/otel-collector/), with first-class Prometheus pipeline support, **clustering mode** (no external state store), and River/Alloy config syntax. **Replaced Grafana Agent** which went EOL November 2025. See [grafana.com/docs/alloy](https://grafana.com/docs/alloy/).

## When to use

Pick Alloy when:
- You're in the Grafana ecosystem (Mimir / Loki / Tempo / Pyroscope).
- You want Prometheus-native pipelines alongside OTel.
- Fleet config management matters (OpAMP support).

Use upstream OTel Collector if you're vendor-agnostic and don't need Prometheus discovery/relabel rules.

## 2025-2026 currency anchors

- **Replaced Grafana Agent November 2025**. If you see `grafana-agent` in a Helm chart, migrate to Alloy.
- **OpAMP support landing** — fleet config management without Helm/Ansible.
- **Clustering mode** — horizontally scaled scrape work with deterministic hash distribution.

## Patterns

- **Unified pipeline**: discover K8s pods + Prometheus scrape + OTel receive + remote_write to Mimir + OTLP to Tempo, all in one Alloy config.
- **Clustering for horizontal scale** — no "every Alloy scrapes every pod" duplicate work.
- **Use as Agent + Gateway tier** like upstream Collector.

## Anti-patterns

- **`grafana-agent` Helm charts in 2026** — deprecated. Migrate.
- **Alloy alone without clustering at scale** — duplicate scrape work.
- **Mixing Alloy config with raw OTel YAML** in same fleet — pick one.

## Gotchas

- **River/Alloy syntax** differs from upstream OTel YAML — same processors, different declarations.
- **Alloy clustering needs network reachability** between Alloy pods (gossip protocol).
- **Migration from Grafana Agent** requires config rewrite; not a drop-in.

## Cross-references

- Upstream OTel Collector → [otel-collector](/stacks/observability/otel-collector/)
- Grafana ecosystem managed → [grafana-cloud](/stacks/observability/grafana-cloud/)
- Operational deployment → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Authoritative: [grafana.com/docs/alloy](https://grafana.com/docs/alloy/)
