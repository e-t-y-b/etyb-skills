---
title: Alertmanager
description: Prometheus's alert routing engine — gossip-clustered, routing tree, inhibition, grouping, silencing. Battle-tested.
product:
  name: Alertmanager
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer]
  authoritative_url: https://prometheus.io/docs/alerting/latest/alertmanager/
  notes: "Stable; routing + grouping + inhibition + silencing model unchanged for years."
---

## What it is

Alertmanager receives alerts from Prometheus (and other clients), runs them through a routing tree, applies inhibition rules, groups, silences, and dispatches to receivers (PagerDuty, Slack, email, webhook). Gossip-clustered for HA. See [prometheus.io/docs/alerting](https://prometheus.io/docs/alerting/latest/alertmanager/).

## When to use

Pick Alertmanager when:
- Prometheus-pure setup.
- Battle-tested routing/grouping/inhibition matters.
- Multi-team routing tree with severity escalation.

Use [Grafana Alerting](/stacks/observability/grafana-alerting/) when you need multi-datasource rules.

Hybrid: Grafana Alerting forwards to Alertmanager for unified routing.

## 2025-2026 currency anchors

- **Stable** — routing model unchanged.
- **HA mode** via gossip protocol (use `--cluster.peer` to peer 3 replicas).

## Patterns

- **3-replica HA cluster** via gossip — `--cluster.peer=am0:9094 --cluster.peer=am1:9094 --cluster.peer=am2:9094`.
- **Inhibit rules**: critical inhibits warning for same alertname + service.
- **Routing by team + severity** — `severity=critical, team=platform` → `pagerduty-platform`.
- **`runbook_url` annotation** on every paging alert.
- **`group_wait: 30s, group_interval: 5m, repeat_interval: 4h`** as starting defaults.

## Anti-patterns

- **Single-replica Alertmanager** — no HA.
- **Missing inhibit rules** — every critical produces five warnings.
- **No `runbook_url`** — MTTR penalty.
- **Routing only by severity** — every page wakes the wrong on-call.

## Gotchas

- **Time-window mute syntax** — use `mute_time_intervals` (modern) not `time_intervals` (deprecated).
- **Webhook signature verification** — PagerDuty Events API v2 supports it; enable.
- **`amtool`** for testing configs locally.

## Cross-references

- Prometheus → [prometheus-server](/stacks/observability/prometheus-server/)
- Grafana Alerting alternative → [grafana-alerting](/stacks/observability/grafana-alerting/)
- Routing patterns → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [prometheus.io/docs/alerting/latest/alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
