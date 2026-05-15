---
title: Datadog APM
description: Datadog's distributed tracing + service observability — Agent v7, OTLP receiver, Library Injection v2, Watchdog correlation.
product:
  name: Datadog APM
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, sre-engineer]
  authoritative_url: https://docs.datadoghq.com/tracing/
  notes: "Agent 7.55+ OTLP-direct receiver + Library Injection v2 evolving quarterly; pricing model adds axes; USM eBPF deepening."
---

## What it is

Datadog APM is the distributed-tracing product inside the Datadog platform. It ingests traces from `dd-trace-*` SDKs or via OTLP at the Agent, correlates with metrics, logs, RUM, infrastructure, and the Software Catalog. See [docs.datadoghq.com/tracing](https://docs.datadoghq.com/tracing/).

Pricing axis: per-host (typically $31/host/mo) on top of infra. APM Profiling is a separate add-on. Custom metrics inside instrumented services count against your custom-metrics quota.

## When to use

**Pick Datadog APM when you want single-pane-of-glass** and you're willing to actively manage costs. It's the most common 2024-2026 choice for Series B-C SaaS shops. Strengths:
- Deepest correlation across signals (trace ↔ log ↔ metric ↔ RUM ↔ deploy event).
- Watchdog AI automatic anomaly detection on every metric.
- APM Library Injection v2 (no SDK in Dockerfile).
- Universal Service Monitoring (USM) — eBPF auto-instrumentation for legacy.

Don't pick Datadog APM when:
- Cost predictability is critical (multi-axis billing is the biggest surprise risk in observability).
- You're at >$200K/yr observability spend with a real SRE team — self-hosted [Mimir](/stacks/observability/grafana-mimir/) + [Tempo](/stacks/observability/grafana-tempo/) becomes competitive.
- You need sub-minute alert latency (DD monitor evaluation is 60-120s min).

## 2025-2026 currency anchors

- **Agent v7.55+** as of 2026-Q2. **OTLP receiver in the Agent** (since 7.40, refined 2024) accepts OTLP from app SDKs — use this instead of running a parallel OTel Collector for Datadog-only stacks.
- **APM Library Injection v2** (2024+) auto-injects `dd-trace-*` into pods via a Mutating Admission Webhook. No tracer in the app Dockerfile. Opt-in via namespace/pod labels.
- **Universal Service Monitoring (USM)** — eBPF-based RED metrics + service map without code changes. Powered by system-probe DaemonSet (`CAP_SYS_ADMIN`). See [eBPF instrumentation](/stacks/observability/ebpf-instrumentation/).
- **Watchdog AI** moved from preview to default surface (2025-2026) — anomaly detection on every metric; route Watchdog signals to a low-priority channel, not paging.
- **Bits AI** natural-language assistant — "Why did checkout error rate spike?" returns a correlation analysis. Useful for triage, not paging (2026).
- **Time-slice SLOs** (mature 2025) — best for ratio-based SLIs; combine with monitor-based SLOs for the legacy / pager-driven paths.
- **Workflow Automation** (formerly Workflows) — visual workflow builder for alert → page → Slack → Jira → status page. Treat as code via `datadog_workflow_automation` Terraform resource.

## Patterns

### OTel + DD Agent OTLP receiver

The recommended 2026 path. Apps emit OTel; DD Agent receives OTLP:

```yaml
# Helm values
datadog:
  apm:
    portEnabled: true
  otlp:
    receiver:
      protocols:
        grpc: { enabled: true, endpoint: 0.0.0.0:4317 }
        http: { enabled: true, endpoint: 0.0.0.0:4318 }
```

Now your services use OTel SDKs (`OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317`) and you keep the option to swap vendors. See [OpenTelemetry](/stacks/observability/opentelemetry/) and [backend-architect overlay](/stacks/observability/backend-architect/).

### Library Injection v2 for `dd-trace`

If you need DD Profiling or DD ASM (not in OTel today), use Library Injection rather than baking SDK into Docker:

```yaml
datadog:
  apm:
    instrumentation:
      enabled: true
      libVersions:
        java:  "1.40"
        python: "2.8"
        nodejs: "5.16"
```

Opt-in via namespace label or pod annotation. Avoid mutating-everything.

### Adaptive sampling at the Agent

Don't set `DD_TRACE_SAMPLE_RATE=1.0` at app level. Let the Agent's adaptive sampler retain 100% of errors + p95 outliers + 1-10% baseline. Trace sampling is the most common bill-balloon mistake.

### SLOs

Time-slice SLO for ratio SLIs (Datadog computes the SLI ratio per minute, aggregates over 30d/7d). Monitor-based SLO when you want one monitor driving both paging and SLO. Multiple-SLOs product when a product surface needs availability + latency + freshness combined.

```hcl
resource "datadog_monitor" "slo_burn_rate_critical" {
  name  = "[CRITICAL] Checkout SLO burn rate 14.4x"
  type  = "slo alert"
  query = "burn_rate(\"slo_id\").over(\"1h\").long_window(\"1h\").short_window(\"5m\") > 14.4"
  tags  = ["team:platform", "severity:critical"]
}
```

## Anti-patterns

- **`DD_TRACE_SAMPLE_RATE=1.0`** — bill balloon + Agent OOM. Let adaptive sampler work.
- **Enabling every Datadog Agent integration** — each brings 50-500 metrics. Audit; disable unused in `datadog.yaml`.
- **Running OTel Collector parallel to DD Agent for the same data** — pick one. Agent has the OTLP receiver.
- **No Usage Attribution dashboard pinned for SRE team** — custom-metrics surprise within 90 days, guaranteed.
- **`ddtrace` SDK in Dockerfile when Library Injection works** — manual maintenance, version drift, breaking deploys.
- **15-day default log retention without Archives** — compliance gaps.

## Gotchas

- **Monitor evaluation delay** is 60-120s minimum. Not the right primary for sub-minute paging (HFT, real-time bidding).
- **`default_zero()` matters** in monitor queries — without it, gaps in data make monitors stuck in `No Data`.
- **`@team` mention** uses Datadog Teams (2024+); older `@pagerduty-integration` syntax still works but doesn't auto-include team context.
- **`kube-state-metrics` integration with default tags** = custom-metric explosion. Always set tag whitelist before install. See [sre-engineer overlay](/stacks/observability/sre-engineer/) cardinality section.
- **APM Profiling priced per host** on top of base APM. Useful for CPU-bound services; skip for I/O-bound.

## Cross-references

- Datadog log surface → [datadog-logs](/stacks/observability/datadog-logs/)
- DD RUM → [datadog-rum](/stacks/observability/datadog-rum/)
- DD LLM Observability → [datadog-llm-observability](/stacks/observability/datadog-llm-observability/)
- Watchdog + Bits AI → [watchdog-ai](/stacks/observability/watchdog-ai/)
- Sensitive Data Scanner (PII scrubbing) → [datadog-sds](/stacks/observability/datadog-sds/)
- SLO + alerting patterns → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Agent deployment (Helm, Library Injection) → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Authoritative: [docs.datadoghq.com/tracing](https://docs.datadoghq.com/tracing/), [DD Agent GitHub](https://github.com/DataDog/datadog-agent)
