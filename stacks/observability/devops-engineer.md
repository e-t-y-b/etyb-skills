---
title: DevOps Engineer on Observability
description: DevOps's lens on the Observability Stack — Collector topology, agent rollout, log routing pipelines, dashboard/alert IaC.
role_overlay:
  role: devops-engineer
  stack: observability
  last_verified_on: "2026-05-14"
  products_covered:
    - opentelemetry
    - otel-collector
    - grafana-alloy
    - datadog-apm
    - datadog-logs
    - newrelic-apm
    - newrelic-pixie
    - splunk-observability-cloud
    - dynatrace-oneagent
    - prometheus-server
    - prometheus-exporters
    - grafana-cloud
    - grafana-mimir
    - grafana-loki
    - grafana-tempo
    - grafana-alerting
    - alertmanager
    - ebpf-instrumentation
    - grafana-beyla
---

## Role briefing

You're the DevOps engineer on an observability engagement. Your work is the **collection layer and the operational substrate** — agents and collectors that gather telemetry, K8s topology that runs them, pipelines that route and transform, IaC that defines dashboards/alerts, CI/CD that ships changes.

**Distinctive vs. the SRE:** the SRE owns *what gets measured and when we page*; you own *how the bytes flow from workload to storage and what we do when they don't*. The SRE designs the SLO; you build the Collector tier that emits the SLI data without dropping spans under load.

## What's distinctive about DevOps on this Stack

- **You own Collector topology** — agent / gateway / backend tiering. The single most important decision in your toolkit.
- **You ship vendor agents** — [Datadog Agent](/stacks/observability/datadog-apm/), [NR Infrastructure agent + Pixie](/stacks/observability/newrelic-pixie/), [OneAgent](/stacks/observability/dynatrace-oneagent/), [Splunk OTel Collector](/stacks/observability/splunk-observability-cloud/) — via Helm, with the correct flags.
- **You own log routing** — [Fluent Bit, Vector, OTel Collector filelog](#log-routers).
- **You own dashboard/alert IaC** — Terraform / grafonnet / `*Monitor` CRDs.
- **You run the CI Visibility pipeline** when applicable.

## 2025-2026 platform-reset items for DevOps

- **[OTel Collector](/stacks/observability/otel-collector/) is the default collection layer.** Vendor agents still have parity-plus features but greenfield K8s leads with OTel Collector or vendor distribution (Splunk OTel Collector, DD OTel Collector).
- **[Grafana Alloy replaced Grafana Agent](/stacks/observability/grafana-alloy/)** — Agent EOL November 2025.
- **[Vector is winning the log router war](#log-routers)** where Fluent Bit backpressure is insufficient. Logstash is legacy.
- **OTel Collector Connectors** (`spanmetrics`, `servicegraph`) derive metrics from traces — reduce redundant in-app instrumentation.
- **[Datadog Agent v7 OTLP receiver](/stacks/observability/datadog-apm/)** — run a single DD Agent that receives OTLP from apps with OTel SDKs.
- **[Prometheus 3.x scrape negotiation](/stacks/observability/prometheus-server/)** — text, OpenMetrics, native histograms.
- **[Pyroscope](/stacks/observability/grafana-pyroscope/) continuous profiling** is a first-class K8s deployment.
- **Helm charts moved toward Operator-driven** for stateful platforms (Mimir, Loki, Tempo Operators).
- **[eBPF auto-instrumentation](/stacks/observability/ebpf-instrumentation/)** ships as DaemonSets needing elevated capabilities; PSS interactions matter.
- **OpAMP** for fleet management of collectors landing in Alloy and OTel Collector.
- **CI Visibility table-stakes** — DD CI Visibility, GitHub Actions OTel exporter, Buildkite OTel.

## OTel Collector deployment topology

The single most important decision. Three placement tiers:

### Tier 1: Agent (DaemonSet or sidecar)

- One Collector per node (DaemonSet) or pod (sidecar).
- Receives local telemetry, minimal processing, forwards to gateway.
- Per-node host metrics (CPU, memory, disk, network) via `hostmetrics` receiver.
- K8s log collection via `filelog` receiver reading `/var/log/pods/`.
- 256-512Mi memory, `GOMEMLIMIT=450MiB`.

### Tier 2: Gateway (Deployment, 3-10 replicas, HPA)

- Heavy processing: [tail-based sampling](/stacks/observability/otel-collector/), attribute transform, PII redaction, multi-backend routing.
- 2-4Gi memory, `GOMEMLIMIT=3GiB`.
- HPA targeting CPU 70%, min 3.

### Tier 3: Backend / Storage

- Vendor SaaS or self-hosted ([Mimir](/stacks/observability/grafana-mimir/), [Loki](/stacks/observability/grafana-loki/), [Tempo](/stacks/observability/grafana-tempo/), [VictoriaMetrics](/stacks/observability/victoriametrics/), Jaeger).

### Required hygiene

- **`GOMEMLIMIT` on every Collector pod** — without it, Go runtime ignores K8s memory limits, random OOMs.
- **`memory_limiter` as first processor** — drops rather than OOMs.
- **`service.telemetry.metrics` enabled** (port 8888) — alert on Collector health.
- **`health_check` + `zpages` extensions** for probes.

See [otel-collector](/stacks/observability/otel-collector/) for pipeline examples (traces with tail-sampling, metrics with prometheusremotewrite, logs with filelog → Loki, connectors).

## Grafana Alloy

[Alloy](/stacks/observability/grafana-alloy/) is the Grafana distribution of the OTel Collector with Prometheus pipeline support and clustering. Use Alloy when in Grafana ecosystem. **Clustering mode** distributes scrape work deterministically — no more "all 10 Alloys scrape every pod."

## Vendor agent deployment

| Vendor | Helm pattern | Notable |
|---|---|---|
| **[Datadog Agent](/stacks/observability/datadog-apm/)** | `datadog/datadog` Helm | APM Library Injection v2 webhook (no SDK in Dockerfile); USM eBPF via `system-probe`; OTLP receiver |
| **[New Relic](/stacks/observability/newrelic-apm/)** | `nri-bundle` Helm | `k8s-agents-operator` for APM auto-instrument; Metadata Injection webhook; [Pixie](/stacks/observability/newrelic-pixie/) sub-chart |
| **[Splunk OTel Collector](/stacks/observability/splunk-observability-cloud/)** | `splunk-otel-collector-chart` | Thin upstream wrapper; agent + gateway in one chart |
| **[Dynatrace](/stacks/observability/dynatrace-oneagent/)** | DynaKube CRD via Dynatrace Operator | `cloudNativeFullStack` mode; ActiveGate for cluster-level |

Operational warning: **eBPF agents (Beyla, Pixie, DD USM, OneAgent) need elevated capabilities** — `CAP_BPF`, `CAP_PERFMON`, sometimes `CAP_SYS_ADMIN`. PSS `restricted` blocks these. See [security-engineer overlay](/stacks/observability/security-engineer/).

## Log routers

### Fluent Bit

Mainstream K8s log router. C-based, low memory (50-100MB), mature K8s filter. Limited backpressure compared to Vector. OTLP support newer (3.x).

### Vector

Rust-based, designed for high throughput with strong backpressure. Datadog acquired Timber.io (Vector's parent) and uses Vector in newer DD Agent paths. VRL (Vector Remap Language) is the best transform DSL in the space. Disk-buffer-backed backpressure. Higher memory (150-300MB).

### Recommendation

- **Fluent Bit** for K8s logs in non-Datadog stacks. Mature, low resource.
- **Vector** for heavy log transformation, strong backpressure, or Datadog ecosystem.
- **Fluentd** — legacy; only keep if Ruby plugins exist.
- **Logstash** — legacy; migrate.

## Prometheus operations

### kube-prometheus-stack

The canonical [Prometheus](/stacks/observability/prometheus-server/)-on-K8s install. Production-grade values:
- `replicas: 2`, `shards: 1` (raise to 4+ for cardinality >5M series).
- `retention: 2d`, `retentionSize: "40GB"` — local short retention.
- `remoteWrite` to long-term storage.
- `enableFeatures: [native-histograms, exemplar-storage, otlp-write-receiver]` for 3.x.
- `alertmanager.replicas: 3` for HA.
- `kubeStateMetrics.metricLabelsAllowlist` — **critical** for cost control on managed vendors.

### ServiceMonitor / PodMonitor / PrometheusRule

CRD-based scrape targets and alerts. **Missing `release` label** = silently no scraping.

### Long-term storage

| Option | Ops shape | When |
|---|---|---|
| **[Thanos](/stacks/observability/thanos/)** | Sidecar + Store + Querier + Compactor | Easiest migration from single Prometheus |
| **[Mimir](/stacks/observability/grafana-mimir/)** | 8-component cluster or monolithic | Multi-tenant, Grafana ecosystem |
| **[VictoriaMetrics](/stacks/observability/victoriametrics/)** | Single-binary or 3-component | Max throughput per dollar; simplest topology |
| **AMP (AWS Managed Prometheus)** | Fully managed | AWS-native, minimal ops |
| **[Grafana Cloud Mimir](/stacks/observability/grafana-cloud/)** | Fully managed | Predictable per-series billing |

## CI Visibility

Pipelines emit OTel spans; vendors ingest; dashboards show pipeline duration, flakiness, failure rate. **Datadog CI Visibility** has the deepest surface (GitHub Actions, GitLab, Buildkite, CircleCI, Jenkins). [Honeycomb CI](/stacks/observability/honeycomb-events/) and Grafana Cloud CI are OTel-native alternatives. Datadog Test Visibility (paired with CI Visibility) auto-detects flaky tests.

## Dashboard and alert IaC

Pick one repo-wide:
- **Grafana** — grafonnet (Jsonnet) for complex reuse; Terraform provider with JSON files for simple. `editable = false` in IaC to prevent UI drift.
- **Datadog** — Terraform `datadog_dashboard_json` + `datadog_monitor`. `datadog-cli` for sync.
- **New Relic** — Terraform `newrelic_one_dashboard`; NerdGraph API for advanced.
- **[Honeycomb](/stacks/observability/honeycomb-events/)** — Terraform `honeycombio_board` + `honeycombio_query`.

For SLO-as-code: use Sloth/Pyrra to generate [Prometheus rules](/stacks/observability/recording-rules/), then Terraform to provision.

## Anti-patterns and gotchas

- **Running OTel Collector without `memory_limiter`** — OOM on spike.
- **No `GOMEMLIMIT`** — random OOMs.
- **Default batch settings at >10K spans/sec** — silent drops.
- **Single replica of stateful observability components** — Prometheus, Alertmanager, Mimir ingester.
- **`grafana-agent` Helm charts in 2026** — deprecated. [Alloy](/stacks/observability/grafana-alloy/).
- **Direct app → vendor OTLP at >5K spans/sec** — no buffer/retry/backpressure. Gateway required.
- **Multiple agents per node** — DD Agent + OTel Collector + Fluent Bit + Prometheus scraping. Consolidate.
- **No alert on Collector/Prometheus/Loki health** — scrape port 8888.
- **`scrape_interval: 1s`** — 60x cost.
- **No `retentionSize` on local Prometheus** — disk fills, OOM on restart.
- **No `sample_limit` on scrapes** — one runaway exporter ingests millions.
- **eBPF without PSS / kernel version check** — DaemonSet fails to schedule.

## Integration with always-on protocols

- **TDD on Collector/agent config** — `otelcol validate`, `promtool check config/rules`, `alloy fmt/validate`, vendor Terraform `plan`.
- **Verification** — after Collector deploy, scrape `localhost:8888/metrics`, assert `otelcol_receiver_accepted_spans > 0`, `otelcol_exporter_send_failed_spans == 0`. After dashboard deploy, render via API, assert non-empty data within 5min. After alert rule, induce synthetic burn, assert PagerDuty event.
- **Plan execution** — Collector rollouts in waves: staging → 5% prod → 25% → 100%.
- **Branch safety** — Collector config PRs with validate CI; Helm value PRs with `helm template` diff; dashboard/alert IaC PRs with vendor preview output.
- **Debugging** — Collector dropping data → check `otelcol_processor_dropped_spans`, `otelcol_exporter_send_failed_spans`, memory_limiter firing. Prometheus missing scrapes → check `up{job=...}`, `prometheus_target_scrapes_exceeded_sample_limit_total`, Operator reconciliation.

## Cross-references

- **SLO design and alerting strategy** → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- **Application-side OTel SDK config** → [backend-architect overlay](/stacks/observability/backend-architect/)
- **PII scrubbing + Collector hardening + audit logs** → [security-engineer overlay](/stacks/observability/security-engineer/)
- **Stack index** (full briefing) → [/stacks/observability/](/stacks/observability/)
