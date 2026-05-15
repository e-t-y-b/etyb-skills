---
title: Splunk ITSI
description: IT Service Intelligence — service health scoring, episode review, predictive analytics on top of Splunk Enterprise.
product:
  name: Splunk ITSI
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, security-engineer]
  authoritative_url: https://docs.splunk.com/Documentation/ITSI
  notes: "Evolves slowly; service health scoring + episode review surface stable; commits to its own data model."
---

## What it is

Splunk ITSI (IT Service Intelligence) is a higher-level surface on top of Splunk Enterprise / Cloud — service health scoring (KPIs roll up into a Service Health Score), Episode Review (related alerts grouped into episodes), Predictive Analytics. See [docs.splunk.com/ITSI](https://docs.splunk.com/Documentation/ITSI).

## When to use

Pick ITSI when:
- You're committed to Splunk and want service-level health views.
- You're at enterprise scale with structured service catalog needs.

ITSI is a heavy product — only adopt if you'll commit to its data model. Smaller orgs are better served by [Datadog Service Catalog](/stacks/observability/datadog-software-catalog/), Backstage, or Grafana service-graphs.

## 2025-2026 currency anchors

- **Evolves slowly** — stable surface.
- **Predictive Analytics** for KPI forecasting and anomaly.

## Patterns

- **KPI definitions** drive Service Health Score.
- **Glass Tables** for service status dashboards.
- **Episode Review** groups noisy alerts into investigation units.

## Anti-patterns

- **ITSI without commitment to its KPI model** — half-configured ITSI provides no value.
- **ITSI for APM** — wrong product; use [Splunk Observability Cloud](/stacks/observability/splunk-observability-cloud/).

## Gotchas

- **License is separate** from Splunk Enterprise/Cloud.
- **Learning curve** for KPI + Glass Tables configuration.

## Cross-references

- Splunk Cloud → [splunk-cloud](/stacks/observability/splunk-cloud/)
- Alternative service catalogs → [datadog-software-catalog](/stacks/observability/datadog-software-catalog/)
- Authoritative: [docs.splunk.com/ITSI](https://docs.splunk.com/Documentation/ITSI)
