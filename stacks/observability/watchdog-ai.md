---
title: Datadog Watchdog AI + Bits AI
description: Datadog's AIOps surface — automatic anomaly detection on every metric (Watchdog), NL assistant for triage (Bits AI).
product:
  name: Watchdog AI + Bits AI
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer]
  authoritative_url: https://docs.datadoghq.com/watchdog/
  notes: "Moved preview → default 2025-26; NL assistant features evolving; route Watchdog to low-priority channel, not paging."
---

## What it is

**Watchdog AI** — automatic anomaly detection running across every metric Datadog ingests. Surfaces "Service X latency increased 3.2x in last 15m, correlated with deploy Y" without configured thresholds. See [docs.datadoghq.com/watchdog](https://docs.datadoghq.com/watchdog/).

**Bits AI** — natural-language assistant. "Why did checkout error rate spike?" returns correlation analysis with linked traces, logs, deploy events.

Datadog's equivalents to [Dynatrace Davis AI](/stacks/observability/dynatrace-davis-ai/) and [New Relic Applied Intelligence](/stacks/observability/newrelic-apm/).

## When to use

Pick Watchdog + Bits when:
- You're on Datadog and want AIOps without separate config.
- Triage time matters more than dashboards.
- You have infrastructure signals (host CPU, memory, container restarts) where static thresholds produce noise.

Don't rely on it for:
- Tier-1 paging — Watchdog signals should go to a low-priority channel, not PagerDuty.
- SLO burn-rate alerts — those should be explicit burn-rate monitors, not AI-correlated.

## 2025-2026 currency anchors

- **Default surface** as of 2025-26 — used to be preview, now always-on.
- **Bits AI** matured for triage (2026); not yet reliable for paging decisions.
- **Correlation across deploy events, error rate, latency** — auto-finds the deploy that caused the regression.

## Patterns

- **Route Watchdog signals to a Slack channel**, not PagerDuty.
- **Use Watchdog as the first triage signal**, then drill into specific dashboards.
- **Disable static-threshold alerts where Watchdog provides equivalent precision** — cut alert volume 60-80% on infra signals.

## Anti-patterns

- **Watchdog signals to PagerDuty** — high false-positive rate at scale; alert fatigue.
- **Disabling SLO burn-rate alerts in favor of Watchdog** — burn rates have specific math; Watchdog is anomaly detection, not error-budget math.
- **Treating Bits AI answers as authoritative** — it's a triage helper, not a debugger.

## Gotchas

- **Watchdog needs ~2 weeks of baseline** to produce reliable signals on a new service.
- **Heavy seasonality services** (cron jobs, batch pipelines) generate false positives until Watchdog learns the pattern.
- **Bits AI uses your DD data** — review data-residency implications for regulated workloads.

## Cross-references

- DD APM correlation → [datadog-apm](/stacks/observability/datadog-apm/)
- SLO-driven alerting (don't replace with AIOps) → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Equivalents in other vendors → [dynatrace-davis-ai](/stacks/observability/dynatrace-davis-ai/), [newrelic-apm](/stacks/observability/newrelic-apm/)
- Authoritative: [docs.datadoghq.com/watchdog](https://docs.datadoghq.com/watchdog/)
