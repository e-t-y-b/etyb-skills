---
title: Splunk Observability Cloud
description: Splunk's APM + Infrastructure + Logs + RUM + Synthetics platform (ex-SignalFx). SignalFlow query language. Post-Cisco.
product:
  name: Splunk Observability Cloud
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer, backend-architect]
  authoritative_url: https://docs.splunk.com/observability/
  notes: "Cisco acquisition March 2024; roadmap shifts through 2026-27; ex-SignalFx surface; SignalFlow for SLI."
---

## What it is

Splunk Observability Cloud is the APM, Infrastructure, Logs, RUM, Synthetics platform (originally SignalFx, rebranded post-Splunk acquisition, now post-Cisco acquisition). **SignalFlow** is its streaming query language for detectors. See [docs.splunk.com/observability](https://docs.splunk.com/observability/).

```python
# SignalFlow detector for burn rate
A = data('checkout.errors.rate', rollup='rate').publish(label='errors')
B = data('checkout.requests.rate', rollup='rate').publish(label='requests')
error_ratio_1h = (A.mean(over='1h') / B.mean(over='1h')).publish('error_ratio_1h')
detect((error_ratio_1h > 0.0144), mode='paired', auto_resolve_after='10m').publish('BURN')
```

## When to use

Pick Splunk Observability Cloud when:
- You're a Splunk shop and want APM/metrics adjacent to Splunk Enterprise.
- High-frequency infra alerting matters — SignalFlow detector evaluation is faster than Datadog/NR.
- MTS-at-scale — billions of metric time series.

Don't pick if:
- You want broader observability community resources — DD/NR/Grafana have more.
- You don't already have Splunk relationship — DD/NR/Grafana are likely better starting points.

## 2025-2026 currency anchors

- **Cisco acquisition closed March 2024** — roadmap shifts pre and post-acquisition; expect packaging changes through 2026-2027.
- **SignalFx → Splunk Observability rename** completed pre-Cisco (legacy docs still reference SignalFx).
- **Splunk OTel Collector** — Splunk's distribution of the upstream OTel Collector.

## Patterns

- **Splunk OTel Collector as agent tier** — ships OTel + Splunk-specific receivers.
- **SignalFlow detectors** for alerting — faster than DD/NR monitor evaluation.
- **MTS-aware metricsets** — tag whitelist per integration.

## Anti-patterns

- **SignalFlow without learning the streaming model** — different mental model from PromQL/NRQL.
- **Splunk Observability + Splunk Enterprise as one product** — they're distinct surfaces with different licensing.

## Gotchas

- **SignalFlow learning curve** — Python-like but streaming-first.
- **Lingering "SignalFx" references** in older docs — current name is Splunk Observability Cloud.
- **Cisco roadmap convergence** with AppDynamics, ThousandEyes — expect product changes.

## Cross-references

- [Splunk Cloud](/stacks/observability/splunk-cloud/) (the SIEM platform)
- [SPL](/stacks/observability/spl/) (separate from SignalFlow)
- SRE vendor selection → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.splunk.com/observability](https://docs.splunk.com/observability/)
