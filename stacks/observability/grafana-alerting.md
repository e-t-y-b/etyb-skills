---
title: Grafana Alerting
description: Grafana's unified alerting — multi-datasource rules, contact points, mute timings. Mature in Grafana 11+.
product:
  name: Grafana Alerting
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer]
  authoritative_url: https://grafana.com/docs/grafana/latest/alerting/
  notes: "Multi-datasource rules; matured in Grafana 11+; replaces legacy dashboard alerting; can forward to Alertmanager."
---

## What it is

Grafana Alerting is the unified alerting subsystem inside Grafana (since 9, mature in 11+). Multi-datasource rules — a single rule can query Prometheus + Loki + CloudWatch in one expression. See [grafana.com/docs/grafana/latest/alerting](https://grafana.com/docs/grafana/latest/alerting/).

## When to use

Pick Grafana Alerting when:
- Alerts span multiple data sources (e.g., metric + log + cloud-provider in one rule).
- You're in the Grafana ecosystem.
- You want unified contact points across multiple Prometheus instances.

Use [Alertmanager](/stacks/observability/alertmanager/) when:
- Prometheus-pure setup with battle-tested routing/grouping/inhibition needs.
- You prefer Alertmanager's mature routing tree.

Hybrid (common): Grafana Alerting forwards everything to Alertmanager for unified routing.

## 2025-2026 currency anchors

- **Grafana 11+ matured** — replaces legacy dashboard alerting for most use cases.
- **Multi-datasource rules** — combine PromQL + LogQL + CloudWatch in one rule.
- **IaC via Grafana Terraform provider** — `grafana_rule_group`, `grafana_contact_point`.

## Patterns

- **Provision via Terraform** — IaC source-of-truth.
- **Use `for: 5m`** on burn-rate alerts to require sustained conditions.
- **Mute timings for maintenance windows** — declarative.
- **Forward to Alertmanager** if you want unified routing across many Grafanas.

## Anti-patterns

- **Editing rules in UI then losing them** — provision in IaC.
- **No `runbook_url` annotation** — first responder Googles for a runbook.
- **Mixing UI-managed + IaC-managed rules** in same folder — drift.

## Gotchas

- **Multi-datasource rules are expensive** — query each source on every evaluation.
- **Contact points have provider-specific quirks** (PagerDuty Events API v2 vs v1, Slack rate limits).
- **`no_data_state` and `exec_err_state`** matter — wrong settings produce silent failures.

## Cross-references

- Alertmanager (Prometheus-native) → [alertmanager](/stacks/observability/alertmanager/)
- Grafana OnCall (paging) → [grafana-oncall](/stacks/observability/grafana-oncall/)
- SLO + burn-rate patterns → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [grafana.com/docs/grafana/latest/alerting](https://grafana.com/docs/grafana/latest/alerting/)
