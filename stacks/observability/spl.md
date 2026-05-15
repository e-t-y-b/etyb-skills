---
title: SPL (Splunk Search Processing Language)
description: Splunk's search language — schema-on-read, pipeline syntax. SPL2 forward bet; classic SPL still supported.
product:
  name: SPL
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, sre-engineer]
  authoritative_url: https://docs.splunk.com/Documentation/SplunkCloud/latest/SearchReference/
  notes: "SPL2 rollout ongoing — multi-line, more SQL-like; classic SPL still mainstream."
---

## What it is

SPL is Splunk's search and analysis language — a pipeline syntax with schema-on-read field extraction. Powers searches, alerts, reports, dashboards in [Splunk Cloud](/stacks/observability/splunk-cloud/) and Splunk Enterprise. See [docs.splunk.com/SearchReference](https://docs.splunk.com/Documentation/SplunkCloud/latest/SearchReference/).

```spl
index=app_logs sourcetype=checkout_api status=5*
| stats count by status, host
| eval error_rate = count / total_count
```

## When to use

SPL is required for any Splunk Enterprise / Cloud work — searches, scheduled alerts, dashboards, ITSI service health, ES correlation rules.

## 2025-2026 currency anchors

- **SPL2** — multi-line, more SQL-like, named pipelines. Forward syntax. Coexists with classic SPL.
- **Classic SPL** still supported and mainstream; most existing content is in classic syntax.

## Patterns

- **`tstats`** for fast aggregation on indexed fields — faster than `stats` on schema-on-read.
- **Saved searches as recurring queries**; Reports for scheduled exports; Alerts trigger on search results.
- **CIM-aware field names** for cross-source correlation.

## Anti-patterns

- **Wildcard everything** (`index=* sourcetype=*`) — slow and expensive.
- **`stats` over huge sets** — use `tstats` where indexed fields exist.
- **No time-range constraint** — searches scan to maximum retention.

## Gotchas

- **SPL2 syntax conversion** — most documentation still uses classic; cross-reference carefully.
- **Search head capacity** — heavy searches monopolize search heads; orchestrate via scheduler.

## Cross-references

- Splunk Cloud → [splunk-cloud](/stacks/observability/splunk-cloud/)
- Splunk ITSI → [splunk-itsi](/stacks/observability/splunk-itsi/)
- Authoritative: [docs.splunk.com/SearchReference](https://docs.splunk.com/Documentation/SplunkCloud/latest/SearchReference/)
