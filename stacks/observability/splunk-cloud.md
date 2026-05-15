---
title: Splunk Cloud
description: Managed Splunk Enterprise — schema-on-read indexing, SPL queries, hot/warm/cold tiering, Federated Search to S3.
product:
  name: Splunk Cloud
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer, sre-engineer]
  authoritative_url: https://docs.splunk.com/Documentation/SplunkCloud
  notes: "SPL2 rollout + Federated Search to S3 GA; license-tier breakpoints unchanged; Cisco acquisition March 2024."
---

## What it is

Splunk Cloud is the managed Splunk Enterprise platform — log indexing at scale, SPL ([Splunk Search Processing Language](/stacks/observability/spl/)) queries, schema-on-read, hot/warm/cold/frozen storage tiering. The canonical SIEM substrate. See [docs.splunk.com](https://docs.splunk.com/Documentation/SplunkCloud).

## When to use

Pick Splunk Cloud when:
- SIEM, audit retention, compliance dominate your requirements.
- Enterprise SOC workflow — Splunk ES on top.
- Multi-year retention required (PCI 1yr+, SOX 7yr).

Don't pick if:
- You need APM-grade metrics + traces — that's [Splunk Observability Cloud](/stacks/observability/splunk-observability-cloud/) (separate product line).
- Per-GB pricing breaks your model at scale.

## 2025-2026 currency anchors

- **Cisco acquisition closed March 2024** — roadmap convergence with Cisco SecureX through 2026-2027.
- **SPL2** is the forward syntax — multi-line, more SQL-like.
- **Federated Search to S3 GA (2024)** — query cold logs in S3 without re-ingesting.
- **HEC (HTTP Event Collector)** as the modern push-ingestion path.

## Patterns

- **Indexes + Sourcetypes** — segment data by retention and access policy.
- **Tier hot → warm → cold → frozen** for cost — frozen is S3 + Federated Search.
- **Use HEC for app log ingest**, Forwarders for system logs, Cribl Stream as the front door for routing.
- **Apply CIM (Common Information Model)** so correlation rules work across sources.

## Anti-patterns

- **Splunk as APM** — wrong product. Use [Splunk Observability Cloud](/stacks/observability/splunk-observability-cloud/).
- **No license capacity planning** — Splunk Cloud breaks at GB-per-day thresholds.
- **Heavy searches** monopolizing search heads — schema-on-read on large sets is expensive.

## Gotchas

- **License model is volume-based** — over-ingest pauses indexing. Capacity-plan.
- **Federated Search latency** — querying S3 is slower than indexed search.
- **SPL2 vs classic SPL** — both supported, SPL2 is forward bet.

## Cross-references

- [Splunk Observability Cloud](/stacks/observability/splunk-observability-cloud/) (the APM/metrics surface)
- [SPL](/stacks/observability/spl/) query language
- [Splunk ITSI](/stacks/observability/splunk-itsi/) service health
- SIEM vs APM composition → [security-engineer overlay](/stacks/observability/security-engineer/)
- Authoritative: [docs.splunk.com](https://docs.splunk.com/)
