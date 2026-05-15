---
title: Dynatrace Grail + DQL
description: Grail — data lakehouse backend for all Dynatrace signals. DQL — the unified query language replacing legacy USQL.
product:
  name: Dynatrace Grail + DQL
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, security-engineer, backend-architect]
  authoritative_url: https://docs.dynatrace.com/docs/discover-dynatrace/platform/grail
  notes: "DQL replacing legacy USQL; Grail strategic backend; 10-year retention possible; learning curve from PromQL/NRQL/SPL."
---

## What it is

**Grail** is Dynatrace's strategic data lakehouse — unified storage for all signal types (metrics, logs, traces, events) with up to 10-year retention.
**DQL (Dynatrace Query Language)** is the unified query language across Grail; replacing legacy USQL. See [docs.dynatrace.com/docs/discover-dynatrace/platform/grail](https://docs.dynatrace.com/docs/discover-dynatrace/platform/grail) and [docs.dynatrace.com/docs/discover-dynatrace/platform/grail/dynatrace-query-language](https://docs.dynatrace.com/docs/discover-dynatrace/platform/grail/dynatrace-query-language).

```dql
fetch spans
| filter dt.entity.service == "SERVICE-ABC123"
| filter k8s.cluster.name == "prod-us-east"
| summarize {
    total = count(),
    failed = countIf(toLong(http.response.status_code) >= 500)
  }, by: { bin(timestamp, 1m) }
| fieldsAdd availability = (total - failed) / total
```

## When to use

DQL is the lingua franca for Dynatrace work — dashboards, alerts, SLO definitions in 2026.

## 2025-2026 currency anchors

- **DQL replacing legacy USQL** — migration ongoing.
- **Grail 10-year retention** available — useful for compliance.
- **SLO product uses DQL** for SLI definitions.

## Patterns

- **`fetch <signal>`** as the source, then `filter`, `summarize`, `fieldsAdd`.
- **Pipeline syntax** familiar from SPL/Kusto.
- **DQL drives Site Reliability Guardian** — see [dynatrace-davis-ai](/stacks/observability/dynatrace-davis-ai/).

## Anti-patterns

- **Continuing to use USQL for new work** — DQL is the forward bet.
- **Unbounded `fetch`** without time filter — expensive.

## Gotchas

- **DQL learning curve** — different from PromQL, NRQL, SPL, SignalFlow.
- **DDU billing on Grail queries** — long-window queries hit DDU budget.

## Cross-references

- [Dynatrace OneAgent](/stacks/observability/dynatrace-oneagent/)
- [Dynatrace Davis AI](/stacks/observability/dynatrace-davis-ai/)
- Authoritative: [docs.dynatrace.com/docs/discover-dynatrace/platform/grail](https://docs.dynatrace.com/docs/discover-dynatrace/platform/grail)
