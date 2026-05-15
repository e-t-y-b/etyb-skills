---
title: New Relic APM
description: New Relic's APM + Infrastructure surface — consumption pricing per GB, Applied Intelligence AIOps, Service Maps, Workloads.
product:
  name: New Relic APM
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer, devops-engineer]
  authoritative_url: https://docs.newrelic.com/docs/apm/
  notes: "Consumption pricing stable; auto-instrumentation operator 2024+; per-user license is the surprise factor at scale."
---

## What it is

New Relic APM ingests traces and metrics from NR agents (Java, .NET, Python, Node, Ruby, Go) or via OTLP. Renders services, transactions, errors, Service Maps, and Workloads (grouped entity views). See [docs.newrelic.com/docs/apm](https://docs.newrelic.com/docs/apm/).

Pricing axis: **per-GB ingested** (predictable) + **per-user** licenses (Full Platform vs Core) — the surprise factor at scale.

## When to use

Pick NR APM when:
- You want per-GB pricing predictability over Datadog's multi-axis.
- NRQL (more SQL-like than DD's query language) suits the team.
- [Pixie eBPF](/stacks/observability/newrelic-pixie/) auto-instrumentation for K8s appeals.
- You want Errors Inbox triage — see [newrelic-errors-inbox](/stacks/observability/newrelic-errors-inbox/).

Don't pick if:
- Per-user pricing breaks your engineer growth model — at 200 engineers × $99/user, NR is expensive.
- You need DD-level correlation surface (DD has slightly deeper trace↔log↔RUM links).

## 2025-2026 currency anchors

- **NR agents 2026.x** as of 2026-Q2.
- **`k8s-agents-operator`** (2024+) provides APM Auto-Instrumentation similar in spirit to [Datadog Library Injection](/stacks/observability/datadog-apm/).
- **Metadata Injection webhook** auto-adds `NEW_RELIC_APP_NAME`, `NEW_RELIC_LICENSE_KEY` env vars to pods.
- **Pixie eBPF** integration deepening — auto-instrument HTTP/MySQL/Redis/Postgres/gRPC/DNS.
- **Applied Intelligence** AIOps — baseline-relative alerts, correlation, decision logic.
- **Infinite Tracing** (paid add-on) — tail-based sampling decided at NR's side.

## Patterns

- **OTel + NR via OTLP** — emit OTel, send OTLP to NR. Preserves portability. Native NR agents still beat OTel for: NR Browser RUM, Pixie eBPF, full APM Auto-Instrumentation.
- **Workloads** group entities into a logical service view — wire to teams.
- **Service Maps** auto-build from APM trace data; review topology before instrumenting.
- **Materialized Views (NRDB feature)** for repeated heavy queries — saves Compute Units.

## Anti-patterns

- **Per-user pricing surprise** — audit who needs Full Platform vs Core/Basic access. Many users only need dashboards.
- **Long-window dashboards (90d, 1y) running 24/7** — Compute Units burn.
- **NR Infrastructure agent + Pixie + NR OTel in same service** — three collection surfaces; pick one.
- **`FACET` on high-cardinality fields** in NRQL — Compute Units burn fast.

## Gotchas

- **Compute Units (CU)** model on ML/AI features is hard to predict at scale.
- **Per-data-type retention varies** (8-395 days default depending on type).
- **EU and US regions are separate signups** — multi-region deployments need two accounts or careful single-account routing.

## Cross-references

- NRQL + NRDB → [newrelic-nrql-nrdb](/stacks/observability/newrelic-nrql-nrdb/)
- AI Monitoring (LLM) → [newrelic-ai-monitoring](/stacks/observability/newrelic-ai-monitoring/)
- Pixie eBPF → [newrelic-pixie](/stacks/observability/newrelic-pixie/)
- Errors Inbox → [newrelic-errors-inbox](/stacks/observability/newrelic-errors-inbox/)
- Authoritative: [docs.newrelic.com/docs/apm](https://docs.newrelic.com/docs/apm/), [NerdGraph](https://docs.newrelic.com/docs/apis/nerdgraph/)
