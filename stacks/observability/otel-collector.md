---
title: OpenTelemetry Collector
description: The central telemetry processing layer — receives OTLP, processes (batch, sample, redact), exports to one or many backends.
product:
  name: OpenTelemetry Collector
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, sre-engineer, security-engineer]
  authoritative_url: https://opentelemetry.io/docs/collector/
  notes: "Connector model matured 2023-25; tail_sampling, transform, redaction processors evolved quarterly through 2026."
---

## What it is

The OpenTelemetry Collector is the vendor-neutral telemetry processing layer between your apps and your observability backends. It receives telemetry (OTLP, Prometheus scrape, Fluent Forward, Jaeger, Zipkin), runs it through **processors** (batch, sampling, attribute editing, PII redaction), and exports to one or many backends. See [opentelemetry.io/docs/collector](https://opentelemetry.io/docs/collector/).

Distributions: upstream **OTel Collector** + **OTel Collector Contrib** (with the long tail of receivers/processors/exporters), plus vendor wrappers — [Grafana Alloy](/stacks/observability/grafana-alloy/), Splunk OTel Collector, Datadog OTel Collector. Pick one distribution per Stack.

## When to use

**Always run a Collector in production.** Sending OTLP directly from app SDKs to vendor is fine for low-volume dev/staging, but at >5K spans/sec you need a Collector for backpressure, retries, batching, sampling, and egress consolidation.

**Three-tier topology** (the production default):
1. **Agent (DaemonSet)** — one Collector per node. Receives from local workloads (low latency), collects host metrics, reads `/var/log/pods/`. Apps send to `localhost:4317`.
2. **Gateway (Deployment, 3-10 replicas)** — heavy lifting (tail-based sampling, transforms, multi-backend routing). Apps and agents fan in here.
3. **Backend** — where data lands.

Skipping the gateway tier and sending direct from apps to vendor is the most common operational mistake — works fine at small scale, kills you at >5K spans/sec when retries pile up.

## 2025-2026 currency anchors

- **OTel Collector 0.110+** as of 2026-Q2.
- **Connectors** (introduced 2023, mature 2025) derive one signal from another inside the Collector — `spanmetrics` produces RED metrics from traces, `servicegraph` produces topology. Reduces redundant in-app instrumentation.
- **Logs signal pipeline** matured — `filelog` receiver + container parser handles K8s log collection without needing Fluent Bit alongside.
- **Profiles pipeline landing** — Collector profile-signal support per OTel Profiles spec (2025+).
- **OpAMP (Open Agent Management Protocol)** landing in upstream Collector and [Alloy](/stacks/observability/grafana-alloy/) — fleet config management without Helm/Ansible rollouts.
- **CIS Benchmarks for OTel Collector** landed late 2025 — production hardening checklist.

## Patterns

### Three-tier deployment

- Agent DaemonSet: 256Mi-512Mi memory, `GOMEMLIMIT=450MiB`, runs `memory_limiter` + `k8sattributes` + minimal processing, forwards to gateway.
- Gateway Deployment: 2-4Gi memory, `GOMEMLIMIT=3GiB`, runs heavy processors (`tail_sampling`, `transform`, `redaction`), exports to backend(s).
- HPA on Gateway with CPU target 70%, min 3 replicas.

### Required hygiene

- **`memory_limiter` as the first processor in every pipeline.** Forces drops rather than OOM.
- **`GOMEMLIMIT` env var set to ~90% of memory limit.** Without it, the Go runtime ignores K8s memory limits and OOMs at random.
- **`service.telemetry.metrics` enabled** on port 8888 so the Collector exposes its own internal Prometheus metrics. Alert on `otelcol_exporter_send_failed_spans > 0`.
- **`health_check` + `zpages` extensions** for liveness/readiness.

### Tail-based sampling

The 2026 default — sample at the gateway tier, not the SDK:

```yaml
processors:
  tail_sampling:
    decision_wait: 10s
    num_traces: 100000
    expected_new_traces_per_sec: 10000
    policies:
      - { name: errors, type: status_code, status_code: { status_codes: [ERROR] } }
      - { name: slow, type: latency, latency: { threshold_ms: 1000 } }
      - { name: rate-limit, type: rate_limiting, rate_limiting: { spans_per_second: 100 } }
      - { name: baseline, type: probabilistic, probabilistic: { sampling_percentage: 5 } }
```

100% of errors + 100% of slow traces + ~5% baseline = the right shape for most workloads. For Honeycomb specifically, use [Refinery](/stacks/observability/honeycomb-refinery/) (purpose-built, more memory-efficient at high volume). For Datadog, let the [DD Agent's adaptive sampler](/stacks/observability/datadog-apm/) do this.

### Connectors

`spanmetrics` derives RED metrics from traces — skip redundant app-side custom metrics:

```yaml
connectors:
  spanmetrics:
    histogram: { explicit: { buckets: [2ms, 10ms, 100ms, 500ms, 1s, 5s, 10s] } }
    dimensions:
      - { name: service.name, default: unknown }
      - { name: http.request.method }
      - { name: http.response.status_code }
service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlp/honeycomb, spanmetrics]
    metrics:
      receivers: [spanmetrics]
      exporters: [prometheusremotewrite]
```

## Anti-patterns

- **Sending OTLP from app SDK direct to vendor at >5K spans/sec** — no buffer, no retry, no backpressure. Gateway required.
- **Running Collector without `memory_limiter`** — OOMs on traffic spike. Always first processor.
- **Running Collector without `GOMEMLIMIT`** — Go runtime ignores K8s memory limit, random OOMs.
- **Default `batch` settings (8192/200ms) at high volume** — drops spans silently. Increase `send_batch_size`, `send_batch_max_size`, set `timeout: 1s`.
- **Multiple agents per node** ([DD Agent](/stacks/observability/datadog-apm/) + OTel Collector + Fluent Bit + Prometheus scraping) — consolidate; one of these owns each signal.
- **No alert on Collector health** — your observability stack itself needs observability. Scrape port 8888.
- **Sharing one batch processor across signals at high volume** — tune per-signal pipelines.

## Gotchas

- **`tail_sampling` requires all spans of a trace to land in the same Collector replica.** Use a load balancer with sticky routing by `trace_id` (the `loadbalancing` exporter in front of the gateway tier).
- **`k8sattributes` processor needs a ServiceAccount with `pods`/`nodes`/`namespaces` read access.** Don't run as cluster-admin.
- **Pod Security Standards `restricted` profile** is compatible with the Collector if you set `runAsNonRoot`, `readOnlyRootFilesystem`, drop capabilities. See [security-engineer overlay](/stacks/observability/security-engineer/) for the hardened PodSpec.
- **`filelog` receiver reads `/var/log/pods/`** — needs hostPath volume mount; verify PSS allows it.

## Cross-references

- Three-tier topology + Helm patterns → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Hardening + NetworkPolicy + secret management → [security-engineer overlay](/stacks/observability/security-engineer/)
- Sampling strategy decisions → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Grafana distribution → [Alloy](/stacks/observability/grafana-alloy/)
- Authoritative: [opentelemetry.io/docs/collector](https://opentelemetry.io/docs/collector/), [GitHub opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib)
