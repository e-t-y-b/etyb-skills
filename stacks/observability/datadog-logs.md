---
title: Datadog Logs
description: Datadog log ingestion, indexing, and archives — Log Pipelines for routing/scrubbing, Archives to S3, indexed events as the cost driver.
product:
  name: Datadog Logs
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, security-engineer]
  authoritative_url: https://docs.datadoghq.com/logs/
  notes: "Indexed-event pricing ($1.70/M as of 2026) is the surprise factor; Log Pipelines + Archives must be configured before scale."
---

## What it is

Datadog Logs is the log management product — ingest from app stdout / Fluent Bit / Vector / Agent / OTLP, route through **Log Pipelines** for parsing and tagging, optionally **index** for fast query, **archive** to S3/GCS/Azure Blob for cheap long-term retention. See [docs.datadoghq.com/logs](https://docs.datadoghq.com/logs/).

Two cost axes: **ingestion** (cheap; per-GB) and **indexed events** (expensive; per-million). Most installs ingest 100% and index 5-30% with the rest going to Archives.

## When to use

Pair with [Datadog APM](/stacks/observability/datadog-apm/) when you want one vendor for traces + logs + metrics. Strong correlation: click from a slow trace's span to its logs with `trace_id` filter pre-applied.

Don't pick if:
- Compliance demands 1+ year hot-queryable logs (Splunk Cloud / Splunk Enterprise better; see [splunk-cloud](/stacks/observability/splunk-cloud/)).
- You need SIEM (Datadog Logs is not Splunk ES).
- Cost predictability is critical and you have variable log volume.

## 2025-2026 currency anchors

- **Indexed event pricing** $1.70/M as of 2026 — ingested logs are cheap; **indexing** is what costs.
- **Log Archives** to S3/GCS/Azure Blob — re-hydrate on demand. Saves 80-90% on indexed log cost.
- **Datadog Log Pipelines** ingest → parse → enrich → optionally drop/archive — the central control plane for log cost.
- **Sensitive Data Scanner v2** (2024) extended from logs to APM, RUM, DBM. See [datadog-sds](/stacks/observability/datadog-sds/).
- **OTLP logs ingestion via DD Agent** — works alongside `dd-trace` for unified pipeline.
- **15-day default retention** indexed; bump to 30/60/90 for compliance; or use Archives.

## Patterns

### Log Pipelines + Archives = mandatory at scale

The single most cost-effective pattern. Route logs through Datadog Log Pipelines, drop non-investigation logs to Archives (S3/GCS) at 1/10th the cost; re-hydrate when needed.

```
Application → DD Agent → Log Pipelines
                          ├── parse + enrich → index (5-30% of volume)
                          └── archive → S3 (70-95% of volume)
```

Set this up on Day 1. Bills double in 90 days otherwise.

### Trace correlation

Every log line emitted within an OTel/dd-trace active span should carry `trace_id` and `span_id`. Pivot from a slow trace to its logs is the highest-value log workflow.

### Log indexes and retention rules

Create separate Datadog Log Indexes for: prod APM logs (15-30 day indexed), audit logs (90+ day indexed), debug logs (1 day indexed), security logs (extended retention). Per-index retention + filter rules.

### Sensitive Data Scanner

PII scrubbing at ingest. See [datadog-sds](/stacks/observability/datadog-sds/). For PCI/HIPAA, **layer with app-side redaction** — SDS is the backstop, not the primary control.

## Anti-patterns

- **Index everything** — bill ballooned. Use Pipelines + Archives + indexed sample.
- **No Log Archives configured at scale** — paying indexed rate for ROI-zero noise (audit logs that never get queried).
- **Stuffing high-cardinality fields as Facets** — Facets are expensive; use sparingly.
- **Mixing prod + staging + dev logs in one index** — query noise, compliance contamination, cost obfuscation.
- **Logs without trace correlation** — 10x less useful. Wire OTel/dd-trace handler into the logger.

## Gotchas

- **Indexed events charge applies even after retention** — the indexed event is counted at index time, not at query time.
- **Re-hydrating from Archives takes time** — minutes to hours for the volume to become queryable. Plan investigations accordingly.
- **PII in messages persists during the SDS scan window** — for hard PCI compliance, app-layer redaction is the only safe path.
- **Log Pipelines run in Datadog's edge** — sub-second processing, but the unscrubbed data is in Datadog briefly.

## Cross-references

- DD APM trace correlation → [datadog-apm](/stacks/observability/datadog-apm/)
- SDS PII scrubbing → [datadog-sds](/stacks/observability/datadog-sds/)
- Log pipelines / Vector / Fluent Bit operational shape → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Audit log retention for compliance → [security-engineer overlay](/stacks/observability/security-engineer/)
- Authoritative: [docs.datadoghq.com/logs](https://docs.datadoghq.com/logs/)
