---
title: Datadog Software Catalog
description: Service inventory built from APM/USM data — RED metrics, SLO status, owners, deployments per service. The IDP convergence surface.
product:
  name: Datadog Software Catalog
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, backend-architect]
  authoritative_url: https://docs.datadoghq.com/service_catalog/
  notes: "2024-26 Backstage-style convergence; schema not finalized vs Backstage catalog-info.yaml; rebranded from Service Catalog 2024."
---

## What it is

Datadog Software Catalog (formerly Service Catalog) auto-builds a service inventory from APM, USM, and infra data. Each service has an overview with RED metrics, SLO status, deployments, owners, scorecards, runbooks, and ownership wiring via Datadog Teams. See [docs.datadoghq.com/service_catalog](https://docs.datadoghq.com/service_catalog/).

Treat it as the **first stop for any service-related question** if you're on Datadog.

## When to use

Pick DD Software Catalog when:
- You're on Datadog APM and want zero-config service inventory.
- Ownership routing matters — wire team-per-service via DD Teams (2024+).

Alternatives in the IDP space:
- **Backstage** — Spotify's OSS IDP. `catalog-info.yaml` per repo. Most popular.
- **Cortex** — commercial Backstage alternative.
- **OpsLevel** — commercial IDP with scorecards.
- **New Relic Service Catalog** — similar in spirit; see [newrelic-apm](/stacks/observability/newrelic-apm/).

## 2025-2026 currency anchors

- **Rebranded** from Service Catalog → Software Catalog (2024).
- **Backstage-style convergence** in 2025-2026 — DD added scorecards, custom metadata, runbooks. Schema not yet finalized vs Backstage's `catalog-info.yaml`.
- **Auto-discovery from APM + USM** — services appear without manual registration.
- **DD Teams** ownership model replaces legacy `dd.team` tag.

## Patterns

- **Pick a system-of-record** — DD Software Catalog OR Backstage, not both. As of 2026, schemas don't fully share; feeding both from the same source-of-truth is the safer multi-platform pattern.
- **Wire scorecards** — production-readiness checklist, on-call coverage, SLO defined.
- **Use as a deploy-history surface** — each service shows recent deploys auto-correlated with regressions.

## Anti-patterns

- **DD Software Catalog + Backstage as parallel sources of truth** — half the teams use one, half the other. Pick one as authoritative.
- **Manually populating Software Catalog when APM auto-discovery covers it** — duplicate work that drifts.
- **No ownership wiring** — every alert routes to "the platform team."

## Gotchas

- **Schema differs from Backstage `catalog-info.yaml`** — full bidirectional sync isn't a solved problem.
- **Auto-discovery depends on APM coverage** — services not on DD APM don't appear unless manually added.
- **Scorecards still iterating** — expect the rule library to evolve through 2026-2027.

## Cross-references

- DD APM (the data source) → [datadog-apm](/stacks/observability/datadog-apm/)
- Ownership-driven alerting → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- IDP composition (Backstage vs Cortex vs OpsLevel) → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Authoritative: [docs.datadoghq.com/service_catalog](https://docs.datadoghq.com/service_catalog/)
