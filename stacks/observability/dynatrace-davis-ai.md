---
title: Dynatrace Davis AI
description: Causal AI for auto-root-cause — Dynatrace's signature feature. Most mature AIOps in the observability space.
product:
  name: Dynatrace Davis AI
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer]
  authoritative_url: https://docs.dynatrace.com/docs/observe/davis-ai
  notes: "Causal AI most mature in space; Site Reliability Guardian workflow evolving; adaptive baselines per service."
---

## What it is

Davis AI is Dynatrace's causal AI engine — computes adaptive baselines per service, detects anomalies, **automatically identifies the root cause** by reasoning over Smartscape (Dynatrace's topology graph). The signature differentiator vs Datadog Watchdog and New Relic Applied Intelligence — Davis is **most mature** in the space. See [docs.dynatrace.com/docs/observe/davis-ai](https://docs.dynatrace.com/docs/observe/davis-ai).

## When to use

Pick Davis AI when:
- Triage time matters more than dashboards.
- Small SRE team — Davis does the correlation work.
- You want explicit causal root-cause, not just anomaly detection.

Datadog Watchdog + Bits AI ([watchdog-ai](/stacks/observability/watchdog-ai/)) and New Relic Applied Intelligence are competing surfaces; Davis remains the most mature on causal RCA.

## 2025-2026 currency anchors

- **Most mature causal AI** in observability space.
- **Site Reliability Guardian (2024+)** — workflow that gates deploys on SLO health, runs auto-rollback on burn-rate breach.

## Patterns

- **Davis adaptive baselines** replace most static-threshold alerts.
- **Site Reliability Guardian** as the deploy gate.
- **Davis problem notifications** flow to PagerDuty/Slack via Workflows.

## Anti-patterns

- **Manual static-threshold alerts** when Davis adaptive works — alert fatigue.
- **Davis on infra signals only** — extend to APM and RUM for full causal graph.

## Gotchas

- **Davis needs ~2 weeks of baseline** for reliable signals on new services.
- **High-seasonality workloads** generate false positives until Davis learns.

## Cross-references

- [Dynatrace OneAgent](/stacks/observability/dynatrace-oneagent/)
- [Dynatrace Grail + DQL](/stacks/observability/dynatrace-grail-dql/)
- Equivalents → [watchdog-ai](/stacks/observability/watchdog-ai/) (Datadog), [newrelic-apm](/stacks/observability/newrelic-apm/) (NR)
- Authoritative: [docs.dynatrace.com/docs/observe/davis-ai](https://docs.dynatrace.com/docs/observe/davis-ai)
