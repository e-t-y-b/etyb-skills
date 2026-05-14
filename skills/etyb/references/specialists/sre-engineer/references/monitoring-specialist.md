# Monitoring & Alerting — Deep Reference

**Always use `WebSearch` to verify version numbers, tool features, and best practices before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Monitoring Tool Selection](#1-monitoring-tool-selection)
2. [Prometheus Architecture](#2-prometheus-architecture)
3. [Grafana Ecosystem](#3-grafana-ecosystem)
4. [SLO/SLI/SLA Framework](#4-sloslisla-framework)
5. [Alert Design & Tuning](#5-alert-design--tuning)
6. [Metrics Pipeline Architecture](#6-metrics-pipeline-architecture)
7. [Synthetic Monitoring](#7-synthetic-monitoring)
8. [Dashboard Design Best Practices](#8-dashboard-design-best-practices)

---

## 1. Monitoring Tool Selection

### Decision Framework

Before comparing tools, answer these questions:

1. **Budget model** -- CapEx (self-hosted OSS) vs OpEx (SaaS per-host/per-GB)?
2. **Team size and ops maturity** -- do you have engineers to run Prometheus+Thanos, or do you need a managed platform?
3. **Scale** -- how many active time series, hosts, containers, and custom metrics?
4. **Multi-cloud / hybrid** -- do you need a single pane across AWS, GCP, Azure, and on-prem?
5. **Compliance** -- data residency, SOC 2, HIPAA, FedRAMP requirements?
6. **Existing ecosystem** -- what are you already running? Migration cost matters.

### Comparison Matrix

| Dimension | Prometheus + Grafana | Datadog | New Relic | Dynatrace | CloudWatch | Grafana Cloud | VictoriaMetrics |
|-----------|---------------------|---------|-----------|-----------|------------|---------------|-----------------|
| **Type** | OSS self-hosted | SaaS | SaaS | SaaS | Cloud-native (AWS) | Managed OSS | OSS self-hosted |
| **Pricing Model** | Free (infra cost only) | Per-host + per-metric + per-GB | Consumption (per-GB ingest + per-user) | Consumption (per-GiB-hour + per-session) | Per-metric + per-GB + per-dashboard | Per-active-series + per-GB | Free (infra cost only) |
| **Infra Monitoring Cost** | $0 (self-hosted) | $15-27/host/mo | $0.30/GB ingest (100 GB free) | $29/host/mo (infra-only) | $0.30/metric/mo (first 10K) | ~$8/1K active series/mo | $0 (self-hosted) |
| **APM Cost** | N/A (use Tempo/Jaeger) | $31/host/mo (requires infra license) | Included in GB pricing | $0.01/GiB-hour (4 GiB min) | X-Ray: $5/1M traces | ~$0.50/GB traces | N/A |
| **Custom Metrics** | Unlimited (storage cost) | 100-200/host included; $5/100 overage | Included in GB pricing | Included in DDU consumption | $0.30/metric/mo | Included in active series | Unlimited (storage cost) |
| **Log Management** | Loki (self-hosted) | $0.10/GB ingest + $1.70/M events indexed | Included in GB pricing | $0.20/GiB ingest | $0.50/GB ingest | ~$0.50/GB ingest | Separate (use Loki/ELK) |
| **Retention** | Configurable (local or object storage) | 15 days default (15 mo max) | 8-395 days by data type | 35 days default (10 yr max) | 15 months metrics, 30 days logs | 13 months metrics (Pro) | Configurable |
| **Scale Ceiling** | ~10M series/instance (federation for more) | Effectively unlimited | Effectively unlimited | Effectively unlimited | Regional limits apply | Billions of series (Mimir) | Billions of series |
| **K8s Native** | Excellent (Prometheus Operator, ServiceMonitor CRDs) | Good (DaemonSet agent, Helm chart) | Good (K8s integration) | Good (OneAgent, K8s operator) | Limited (Container Insights add-on) | Excellent (inherits Prometheus ecosystem) | Excellent (drop-in Prometheus replacement) |
| **AI/ML Features** | Basic (Grafana ML plugin) | Watchdog anomaly detection | Applied Intelligence (AIOps) | Davis AI (causal AI, auto-root-cause) | Anomaly detection alarms | Grafana ML, Sift | None built-in |
| **Multi-Cloud** | Yes (runs anywhere) | Yes (600+ integrations) | Yes | Yes | AWS-only (native) | Yes | Yes (runs anywhere) |
| **OTel Support** | Native OTLP ingest (Prometheus 3.x) | OTLP ingest supported | OTLP ingest supported | OTLP ingest supported | OTLP via ADOT collector | Native OTLP (Alloy, Mimir, Loki, Tempo) | OTLP ingest supported |
| **Bill Surprise Risk** | Low (infra cost only) | HIGH (custom metrics, indexed logs, APM hosts compound) | Medium (per-user licenses are expensive at scale) | Medium (GiB-hour model is complex) | Medium (high-cardinality custom metrics multiply) | Low-Medium (predictable per-series) | Low (infra cost only) |

### Best-For Recommendations

| Scenario | Recommended Tool | Why |
|----------|-----------------|-----|
| **K8s-native, budget-conscious, strong SRE team** | Prometheus + Grafana (self-hosted) or VictoriaMetrics | Zero license cost, full control, best K8s integration |
| **K8s-native, want managed, budget-conscious** | Grafana Cloud | Managed Mimir/Loki/Tempo, generous free tier, no vendor lock-in on instrumentation |
| **Enterprise, need single pane + security + APM** | Datadog | Broadest integration ecosystem (1000+), unified platform, strong security monitoring |
| **Enterprise, need AI-driven root cause analysis** | Dynatrace | Davis AI is best-in-class for automated root cause detection across full stack |
| **AWS-only shop, minimal ops overhead** | CloudWatch + X-Ray | Zero setup, native integration, no additional agents needed |
| **High-scale metrics (billions of series), self-hosted** | VictoriaMetrics | 10x compression vs Prometheus, 5x less memory than Mimir, simpler architecture |
| **Full-stack observability, consumption pricing** | New Relic | Predictable per-GB pricing, 100 GB/mo free, no per-host surprise bills |
| **Startup / small team, need everything** | Grafana Cloud Free or New Relic Free Tier | Both offer meaningful free tiers to get started without commitment |

### Cost Trap Warnings

**Datadog** -- The biggest cost driver is custom metrics and indexed log events. A common pattern: team enables Kubernetes state metrics, each pod generates ~50 custom metrics with labels, 500 pods = 25,000 custom metrics. At $5/100 overage, that is $1,250/month just for kube-state-metrics. Custom metrics can constitute up to 52% of total Datadog billing at scale.

**CloudWatch** -- Dimensions are multiplicative. Adding one high-cardinality tag (e.g., `request_id`) to a custom metric can turn 1 metric into 100,000 metrics at $0.30/each = $30,000/month.

**Dynatrace** -- The GiB-hour model has a 4 GiB minimum floor per host. A 512 MB container still costs the same as a 4 GiB host: 4 x 730 hours x $0.01 = $29.20/month.

---

## 2. Prometheus Architecture

### Core Architecture (Prometheus 3.x)

Prometheus 3.0 (released late 2024, with 3.4.x current as of mid-2025) introduced major changes:

- **Native OTLP ingestion** -- stable `/api/v1/otlp/v1/metrics` endpoint; no sidecar or exporter needed for OTel-instrumented services
- **UTF-8 metric and label names** -- dots, slashes, and other characters now valid by default; OTel metrics no longer need dot-to-underscore translation
- **Remote Write 2.0** -- native support for metadata, exemplars, created timestamps, and native histograms in the wire protocol
- **New UI** -- built on Mantine, cleaner and more extensible
- **Native histograms GA-track** -- exponential bucketing with automatic resolution, dramatically reducing cardinality for latency metrics

### Scraping Model

```
                    ┌──────────────┐
                    │  Prometheus  │
                    │    Server    │
                    └──────┬───────┘
                           │ HTTP GET /metrics (pull)
              ┌────────────┼────────────────┐
              │            │                │
        ┌─────▼─────┐ ┌───▼─────┐  ┌──────▼──────┐
        │ Target A  │ │ Target B│  │  Target C   │
        │ :8080     │ │ :9090   │  │  :3000      │
        │ /metrics  │ │ /metrics│  │  /metrics   │
        └───────────┘ └─────────┘  └─────────────┘
```

**Pull vs Push** -- Prometheus pulls metrics from targets. This means:
- Prometheus controls scrape interval (not the application)
- Failed scrapes are detectable (`up == 0`)
- No backpressure on applications from metric collection
- Service discovery drives target lifecycle

**Scrape interval** -- 15s is the default and the right starting point. Do NOT go below 10s unless you have a specific need (it increases storage and query cost). For batch jobs, use the Pushgateway (push model for short-lived processes).

### Service Discovery

Prometheus discovers targets dynamically. Key mechanisms for Kubernetes:

```yaml
# prometheus.yml -- Kubernetes service discovery
scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      # Only scrape pods with annotation prometheus.io/scrape=true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      # Use annotation for metrics path (default /metrics)
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      # Use annotation for port
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      # Map pod labels to metric labels
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
```

### High Availability Setup

Run **two identical Prometheus replicas** scraping the same targets. They will have slightly different data (different scrape timestamps), but queries via Thanos/Mimir deduplicate transparently.

```
        ┌────────────────┐     ┌────────────────┐
        │ Prometheus-0   │     │ Prometheus-1   │
        │ (replica A)    │     │ (replica B)    │
        └───────┬────────┘     └───────┬────────┘
                │ remote_write          │ remote_write
                └──────────┬───────────┘
                           ▼
                ┌──────────────────┐
                │  Thanos / Mimir  │
                │  (deduplication) │
                └──────────────────┘
```

### Long-Term Storage: Thanos vs Mimir vs VictoriaMetrics

Cortex is in maintenance mode and not recommended for new deployments. The Cortex maintainers themselves migrated to Mimir.

| Dimension | Thanos | Grafana Mimir | VictoriaMetrics |
|-----------|--------|---------------|-----------------|
| **Architecture** | Sidecar + Store Gateway + Querier + Compactor (modular) | Microservices (ingester, distributor, querier, compactor, store-gateway) | Monolithic or cluster (vmselect, vminsert, vmstorage) |
| **Storage Backend** | Object storage (S3, GCS, Azure Blob) | Object storage (S3, GCS, Azure Blob) | Block storage (local disk, EBS, persistent volumes) |
| **Migration Path** | Easiest -- sidecar attaches to existing Prometheus, no data migration | Requires remote_write from Prometheus (new pipeline) | Accepts remote_write (drop-in receiver) |
| **Compression** | 2-4x vs raw Prometheus | Similar to Thanos | Up to 10x vs raw Prometheus |
| **Memory Usage** | Moderate | Higher (microservices overhead) | 5x less than Mimir for same workload |
| **Multi-Tenancy** | Basic (external label based) | Advanced (built-in tenant isolation, per-tenant limits) | Supported (account-based) |
| **Downsampling** | Built-in (5m, 1h automatic) | No automatic downsampling | Built-in (configurable) |
| **Mimir 3.0 Feature** | N/A | Kafka-based async buffer between ingest and query paths | N/A |
| **Best For** | First step from single Prometheus; teams wanting object storage with minimal migration | Enterprise multi-tenant, Grafana Cloud users, need strict tenant isolation | Maximum performance and compression; teams wanting simplicity |
| **Operational Complexity** | Medium (5-7 components to operate) | High (8+ microservices, or use monolithic mode) | Low (single binary or 3-component cluster) |

**Decision shortcut:**
- Already have Prometheus and want the easiest path to long-term storage? **Thanos sidecar**.
- Need multi-tenancy, already in Grafana ecosystem? **Mimir**.
- Need maximum performance per dollar, willing to use block storage? **VictoriaMetrics**.

### Native Histograms

Native histograms (exponential histograms) replace the classic histogram pattern of fixed buckets. Instead of pre-defining `le` buckets (which either waste cardinality on unused ranges or miss resolution where you need it), native histograms use exponential bucketing with automatic resolution.

**Before (classic histogram)** -- a single latency histogram with 10 `le` buckets = 13 time series (10 buckets + `_sum` + `_count` + `_created`). With 100 endpoints x 5 status codes = 6,500 series for one metric.

**After (native histogram)** -- a single time series per label combination, with bucket boundaries encoded in the sample itself. Same 100 endpoints x 5 status codes = 500 series. **13x reduction in cardinality.**

Enable native histograms in scrape config:

```yaml
scrape_configs:
  - job_name: 'my-service'
    scrape_classic_histograms: false  # default in Prometheus 3.x
    metric_relabel_configs: []
```

### Recording Rules

Recording rules precompute frequently needed or expensive PromQL expressions and save the result as a new time series. Use them to:

1. **Speed up dashboards** -- precompute aggregations that dashboards query repeatedly
2. **Reduce query load** -- avoid expensive `rate()` over high-cardinality series at query time
3. **Feed SLO burn-rate alerts** -- the multi-window burn-rate pattern depends on recording rules

```yaml
# recording-rules.yaml -- Golden Signals recording rules
groups:
  - name: golden_signals
    interval: 30s
    rules:
      # --- REQUEST RATE (Traffic) ---
      - record: job:http_requests_total:rate5m
        expr: sum(rate(http_requests_total[5m])) by (job)

      - record: job_status:http_requests_total:rate5m
        expr: sum(rate(http_requests_total[5m])) by (job, status_code)

      # --- ERROR RATE (Errors) ---
      - record: job:http_requests_errors:rate5m
        expr: sum(rate(http_requests_total{status_code=~"5.."}[5m])) by (job)

      - record: job:http_request_error_ratio:rate5m
        expr: |
          job:http_requests_errors:rate5m
          /
          job:http_requests_total:rate5m

      # --- LATENCY (Duration) ---
      - record: job:http_request_duration_seconds:p50
        expr: histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (job, le))

      - record: job:http_request_duration_seconds:p95
        expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (job, le))

      - record: job:http_request_duration_seconds:p99
        expr: histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (job, le))

      # --- SATURATION ---
      - record: instance:node_cpu_utilisation:ratio
        expr: 1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance)

      - record: instance:node_memory_utilisation:ratio
        expr: |
          1 - (
            node_memory_MemAvailable_bytes
            /
            node_memory_MemTotal_bytes
          )
```

### PromQL Patterns for Common Queries

```promql
# Request rate per second (the "R" in RED)
sum(rate(http_requests_total[5m])) by (service)

# Error ratio (the "E" in RED) -- percentage of 5xx responses
sum(rate(http_requests_total{status_code=~"5.."}[5m])) by (service)
/
sum(rate(http_requests_total[5m])) by (service)

# Latency p99 (the "D" in RED)
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (service, le)
)

# CPU saturation (the "S" in USE) -- cores requested vs available
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)
/
sum(kube_pod_container_resource_limits{resource="cpu"}) by (pod)

# Apdex score (alternative to percentile for user-facing latency)
(
  sum(rate(http_request_duration_seconds_bucket{le="0.3"}[5m])) by (service)
  +
  sum(rate(http_request_duration_seconds_bucket{le="1.2"}[5m])) by (service)
)
/ 2
/
sum(rate(http_request_duration_seconds_count[5m])) by (service)

# Detecting missing scrape targets
up == 0

# Container restarts in last hour (CrashLoopBackOff detection)
increase(kube_pod_container_status_restarts_total[1h]) > 3

# Top 10 highest cardinality metrics
topk(10, count by (__name__)({__name__=~".+"}))

# Rate of increase of disk usage (predict full in N hours)
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[6h], 24*3600) < 0
```

### Prometheus Operator and kube-prometheus-stack

The `kube-prometheus-stack` Helm chart deploys a production-ready monitoring stack: Prometheus Operator, Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics, and default dashboards/alerts.

**ServiceMonitor example** -- tells Prometheus Operator to scrape your service:

```yaml
# service-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-api-service
  namespace: my-app
  labels:
    release: kube-prometheus-stack  # must match Prometheus serviceMonitorSelector
spec:
  selector:
    matchLabels:
      app: my-api   # matches the Service's labels
  namespaceSelector:
    matchNames:
      - my-app
  endpoints:
    - port: http-metrics   # must match the Service port name
      path: /metrics
      interval: 15s
      scrapeTimeout: 10s
      honorLabels: true
      metricRelabelings:
        # Drop high-cardinality debug metrics in production
        - sourceLabels: [__name__]
          regex: 'go_gc_.*|promhttp_metric_handler_.*'
          action: drop
```

**PodMonitor** -- for pods that do not have a Service (e.g., CronJobs):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: batch-jobs
  namespace: batch
spec:
  selector:
    matchLabels:
      app: batch-processor
  podMetricsEndpoints:
    - port: metrics
      interval: 30s
```

**PrometheusRule** -- deploy alerting/recording rules as Kubernetes resources:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: my-api-alerts
  namespace: my-app
  labels:
    release: kube-prometheus-stack
spec:
  groups:
    - name: my-api.rules
      rules:
        - alert: HighErrorRate
          expr: job:http_request_error_ratio:rate5m{job="my-api"} > 0.05
          for: 5m
          labels:
            severity: critical
            team: platform
          annotations:
            summary: "High error rate on {{ $labels.job }}"
            description: "Error rate is {{ $value | humanizePercentage }} (threshold: 5%)"
            runbook_url: "https://runbooks.example.com/my-api/high-error-rate"
            dashboard_url: "https://grafana.example.com/d/my-api-overview"
```

**Critical Helm values for production:**

```yaml
# values.yaml for kube-prometheus-stack
prometheus:
  prometheusSpec:
    replicas: 2                          # HA pair
    retention: 2d                        # short local retention
    retentionSize: "40GB"
    resources:
      requests:
        cpu: "2"
        memory: "8Gi"
      limits:
        memory: "12Gi"
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          resources:
            requests:
              storage: 100Gi
    remoteWrite:                         # send to long-term storage
      - url: "http://mimir-distributor:8080/api/v1/push"
        queueConfig:
          maxSamplesPerSend: 5000
          capacity: 10000
          maxShards: 30
    serviceMonitorSelectorNilUsesHelmValues: false  # pick up ALL ServiceMonitors
    podMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false
    enableFeatures:
      - native-histograms
      - exemplar-storage

alertmanager:
  alertmanagerSpec:
    replicas: 3                          # HA cluster
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          resources:
            requests:
              storage: 10Gi

grafana:
  replicas: 2
  persistence:
    enabled: true
    size: 10Gi
  sidecar:
    dashboards:
      enabled: true
      searchNamespace: ALL               # find dashboards in any namespace
    datasources:
      enabled: true
```

---

## 3. Grafana Ecosystem

### LGTM Stack Overview

Grafana Labs' open-source observability stack (the "LGTM" stack):

| Component | Signal | Role | Query Language |
|-----------|--------|------|----------------|
| **Loki** | Logs | Log aggregation (label-indexed, not full-text indexed) | LogQL |
| **Grafana** | Visualization | Dashboarding, alerting, exploration | N/A (consumes all) |
| **Tempo** | Traces | Distributed trace storage (object-storage-backed) | TraceQL |
| **Mimir** | Metrics | Long-term metrics storage (Prometheus-compatible) | PromQL |
| **Alloy** | Collection | Telemetry collector (replaces Grafana Agent, EOL Nov 2025) | Alloy config (River-based) |
| **Pyroscope** | Profiles | Continuous profiling | N/A |

### Grafana Alloy (Collector)

Alloy is Grafana's distribution of the OpenTelemetry Collector with added Prometheus pipeline support, clustering, and Vault integration. It replaces Grafana Agent (EOL November 2025).

**Key features:**
- 120+ components for collecting metrics, logs, traces, and profiles
- Native OTLP and Prometheus scraping in the same pipeline
- Built-in clustering for horizontal scaling without external coordination
- HashiCorp Vault integration for secrets management
- Expression-based configuration syntax (River/Alloy config language)
- Early support for Open Agent Management Protocol (OpAMP) for fleet management

**When to use Alloy vs vanilla OTel Collector:**
- Use Alloy if you are in the Grafana ecosystem (Mimir, Loki, Tempo) and want Prometheus-native pipelines alongside OTel
- Use vanilla OTel Collector if you need maximum vendor neutrality or target non-Grafana backends

### Grafana Cloud Pricing Summary

| Tier | Base Cost | Metrics | Logs | Traces | Profiles |
|------|-----------|---------|------|--------|----------|
| **Free** | $0 | 10K active series | 50 GB/mo | 50 GB/mo | 50 GB/mo |
| **Pro** | $19/mo + usage | ~$8/1K active series | ~$0.50/GB | ~$0.50/GB | ~$0.30/GB |
| **Enterprise** | $25K/yr minimum | Custom | Custom | Custom | Custom |

Billing uses the **95th percentile model** -- the top 5% of usage time during the month is excluded, providing cost stability against temporary spikes.

### Dashboard-as-Code

**Grafonnet (Jsonnet library):**

```jsonnet
// dashboard.jsonnet -- RED method dashboard using grafonnet
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = grafana.dashboard;
local panel = grafana.panel;
local prometheus = grafana.query.prometheus;
local variable = grafana.dashboard.variable;

dashboard.new('Service Overview - RED Method')
+ dashboard.withDescription('Request rate, Error rate, and Duration for $service')
+ dashboard.withUid('red-method-overview')
+ dashboard.withRefresh('30s')
+ dashboard.withVariables([
    variable.query.new('service')
    + variable.query.withDatasourceRef('prometheus')
    + variable.query.queryTypes.withLabelValues('job', 'http_requests_total'),
  ])
+ dashboard.withPanels(
  grafana.util.grid.makeGrid([
    // Row 1: Request Rate
    panel.timeSeries.new('Request Rate')
    + panel.timeSeries.queryOptions.withTargets([
        prometheus.new('$datasource',
          'sum(rate(http_requests_total{job="$service"}[5m]))')
        + prometheus.withLegendFormat('{{job}}'),
      ])
    + panel.timeSeries.standardOptions.withUnit('reqps')
    + { gridPos: { w: 8, h: 8 } },

    // Row 1: Error Rate
    panel.timeSeries.new('Error Rate')
    + panel.timeSeries.queryOptions.withTargets([
        prometheus.new('$datasource',
          'sum(rate(http_requests_total{job="$service",status_code=~"5.."}[5m]))'
          + ' / sum(rate(http_requests_total{job="$service"}[5m]))')
        + prometheus.withLegendFormat('{{job}}'),
      ])
    + panel.timeSeries.standardOptions.withUnit('percentunit')
    + panel.timeSeries.fieldConfig.defaults.thresholds.withSteps([
        { value: 0, color: 'green' },
        { value: 0.01, color: 'yellow' },
        { value: 0.05, color: 'red' },
      ])
    + { gridPos: { w: 8, h: 8 } },

    // Row 1: Latency p50/p95/p99
    panel.timeSeries.new('Latency')
    + panel.timeSeries.queryOptions.withTargets([
        prometheus.new('$datasource',
          'histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket{job="$service"}[5m])) by (le))')
        + prometheus.withLegendFormat('p50'),
        prometheus.new('$datasource',
          'histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="$service"}[5m])) by (le))')
        + prometheus.withLegendFormat('p95'),
        prometheus.new('$datasource',
          'histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job="$service"}[5m])) by (le))')
        + prometheus.withLegendFormat('p99'),
      ])
    + panel.timeSeries.standardOptions.withUnit('s')
    + { gridPos: { w: 8, h: 8 } },
  ], panelWidth=8)
)
```

**Terraform provider:**

```hcl
resource "grafana_dashboard" "service_overview" {
  config_json = file("dashboards/service-overview.json")
  folder      = grafana_folder.sre.id
  overwrite   = true
}

resource "grafana_folder" "sre" {
  title = "SRE Dashboards"
}

resource "grafana_data_source" "mimir" {
  type = "prometheus"
  name = "Mimir"
  url  = "http://mimir-query-frontend:8080/prometheus"

  json_data_encoded = jsonencode({
    httpMethod    = "POST"
    exemplarTraceIdDestinations = [{
      name             = "traceID"
      datasourceUid    = grafana_data_source.tempo.uid
    }]
  })
}
```

### Grafana Alerting

Grafana unified alerting (introduced in Grafana 9, mature in 11+) replaces the legacy dashboard alerting and runs alongside or instead of Alertmanager:

- **Multi-datasource alerts** -- alert on Prometheus, Loki, Elasticsearch, CloudWatch, etc. from a single rule
- **Alert rules as code** -- use Terraform `grafana_rule_group` or the Grafana provisioning API
- **Contact points** -- Slack, PagerDuty, Opsgenie, email, webhooks, Microsoft Teams
- **Notification policies** -- routing tree similar to Alertmanager but managed via Grafana UI or provisioning
- **Mute timings** -- time-based silencing (e.g., suppress non-critical alerts during maintenance windows)

**When to use Grafana Alerting vs Alertmanager:**
- Use Grafana Alerting when you need to alert on non-Prometheus data sources (Loki, Elasticsearch) or want a single UI for all alert management
- Use Alertmanager when you are Prometheus-native and need battle-tested routing, inhibition, and grouping at scale

---

## 4. SLO/SLI/SLA Framework

### Definitions (Get These Right)

| Term | Definition | Owner | Example |
|------|-----------|-------|---------|
| **SLI** (Service Level Indicator) | A quantitative measurement of one aspect of service quality | Engineering | 99.2% of requests completed in <300ms |
| **SLO** (Service Level Objective) | A target value or range for an SLI, measured over a time window | Engineering + Product | 99.9% of requests succeed over 30 days |
| **SLA** (Service Level Agreement) | A contractual commitment with consequences for violation | Business/Legal | 99.95% availability per month; credits issued if breached |
| **Error Budget** | The allowed amount of unreliability = 1 - SLO | Engineering | 0.1% = 43.2 minutes/month of downtime budget |

**Key principle:** SLOs must be stricter than SLAs. If your SLA is 99.95%, your SLO should be 99.99% so you have a buffer before contractual penalties.

### Choosing SLIs

The right SLIs depend on the type of service. Do not measure everything; measure what users care about.

| Service Type | Primary SLIs | How to Measure |
|-------------|-------------|----------------|
| **Request-driven (API, web)** | Availability (success ratio), Latency (p50, p95, p99), Correctness | `http_requests_total` by status, `http_request_duration_seconds` |
| **Pipeline/batch** | Freshness (time since last successful run), Correctness (output validation), Throughput | Custom metrics: `last_successful_run_timestamp`, `records_processed_total` |
| **Storage** | Durability, Availability, Latency | Provider metrics + synthetic probes |
| **Streaming** | Throughput, Latency (end-to-end), Freshness (consumer lag) | `kafka_consumer_group_lag`, custom latency metrics |

**Availability SLI formula:**

```
availability = successful_requests / total_requests
```

What counts as "successful"? Define this precisely:
- HTTP 2xx and 3xx = success
- HTTP 4xx = success (client error, not your fault) -- **controversial; some teams exclude 429s**
- HTTP 5xx = failure
- Timeouts = failure
- Connection refused = failure

**Latency SLI formula:**

```
latency_sli = requests_below_threshold / total_requests
```

Example: "99% of requests complete in under 300ms" means `latency_sli = count(duration < 300ms) / count(all) >= 0.99`.

### Setting SLOs: Data-Driven Approach

1. **Measure current performance** -- look at 30 days of data. What is your actual availability? Actual p99 latency?
2. **Set SLO slightly below current performance** -- if you are currently at 99.97% availability, set SLO at 99.95%. This gives you realistic error budget without requiring heroic effort.
3. **Negotiate with stakeholders** -- product/business may want higher targets. Show them the cost: going from 99.9% to 99.99% is a 10x reduction in allowed downtime (43 min/mo to 4.3 min/mo) and typically requires 3-10x more engineering investment in redundancy.
4. **Start with fewer, not more** -- 2-3 SLOs per service is ideal. More than 5 creates confusion about what matters.

### Error Budget Math

| SLO | Error Budget (30 days) | Error Budget (per day) |
|-----|----------------------|----------------------|
| 99% | 7 hours 12 min | 14 min 24 sec |
| 99.5% | 3 hours 36 min | 7 min 12 sec |
| 99.9% | 43 min 12 sec | 1 min 26 sec |
| 99.95% | 21 min 36 sec | 43 sec |
| 99.99% | 4 min 19 sec | 4.3 sec |
| 99.999% | 26 sec | 0.43 sec |

### Multi-Window Multi-Burn-Rate Alerting

This is the Google SRE book pattern. The idea: alert when you are burning through your error budget faster than expected, with different urgency levels for different burn rates.

**Burn rate** = how fast you are consuming error budget relative to the SLO window.

- Burn rate 1.0 = consuming budget exactly at pace (will exhaust at end of window)
- Burn rate 14.4 = consuming budget 14.4x faster than sustainable (will exhaust in ~2 days of a 30-day window)
- Burn rate 6.0 = will exhaust in ~5 days
- Burn rate 1.0 = on track to just barely exhaust at window end

**Multi-window** means you check both a long window (to confirm the trend) and a short window (to confirm it is happening now, not just a historical blip).

| Severity | Burn Rate | Long Window | Short Window | Budget Consumed Before Alert | Action |
|----------|-----------|-------------|--------------|------------------------------|--------|
| Page (wake up) | 14.4x | 1h | 5m | 2% | Immediate response |
| Page (urgent) | 6.0x | 6h | 30m | 5% | Respond within 30 min |
| Ticket (next business day) | 3.0x | 1d | 2h | 10% | Investigate next business day |
| Ticket (low priority) | 1.0x | 3d | 6h | 10% | Investigate this week |

**Prometheus recording rules and alerts for multi-window burn-rate SLO:**

```yaml
# slo-recording-rules.yaml
groups:
  - name: slo:api_availability
    rules:
      # --- SLI: ratio of successful requests ---
      - record: slo:api_availability:error_ratio_rate5m
        expr: |
          sum(rate(http_requests_total{job="api-server", status_code=~"5.."}[5m]))
          /
          sum(rate(http_requests_total{job="api-server"}[5m]))

      - record: slo:api_availability:error_ratio_rate30m
        expr: |
          sum(rate(http_requests_total{job="api-server", status_code=~"5.."}[30m]))
          /
          sum(rate(http_requests_total{job="api-server"}[30m]))

      - record: slo:api_availability:error_ratio_rate1h
        expr: |
          sum(rate(http_requests_total{job="api-server", status_code=~"5.."}[1h]))
          /
          sum(rate(http_requests_total{job="api-server"}[1h]))

      - record: slo:api_availability:error_ratio_rate2h
        expr: |
          sum(rate(http_requests_total{job="api-server", status_code=~"5.."}[2h]))
          /
          sum(rate(http_requests_total{job="api-server"}[2h]))

      - record: slo:api_availability:error_ratio_rate6h
        expr: |
          sum(rate(http_requests_total{job="api-server", status_code=~"5.."}[6h]))
          /
          sum(rate(http_requests_total{job="api-server"}[6h]))

      - record: slo:api_availability:error_ratio_rate1d
        expr: |
          sum(rate(http_requests_total{job="api-server", status_code=~"5.."}[1d]))
          /
          sum(rate(http_requests_total{job="api-server"}[1d]))

      - record: slo:api_availability:error_ratio_rate3d
        expr: |
          sum(rate(http_requests_total{job="api-server", status_code=~"5.."}[3d]))
          /
          sum(rate(http_requests_total{job="api-server"}[3d]))

  - name: slo:api_availability:alerts
    rules:
      # SLO: 99.9% availability over 30 days
      # Error budget: 0.1% = 0.001

      # --- PAGE: 14.4x burn rate (1h long / 5m short) ---
      # Fires when 2% of monthly error budget consumed in 1 hour
      - alert: SLOAvailabilityBurnRateCritical
        expr: |
          slo:api_availability:error_ratio_rate1h > (14.4 * 0.001)
          and
          slo:api_availability:error_ratio_rate5m > (14.4 * 0.001)
        for: 2m
        labels:
          severity: critical
          slo: api-availability
          team: platform
        annotations:
          summary: "API availability SLO burn rate critical (14.4x)"
          description: |
            API error ratio is {{ $value | humanizePercentage }} over 1h.
            At this burn rate, the 30-day error budget will be exhausted in ~2 days.
          runbook_url: "https://runbooks.example.com/slo/api-availability-critical"

      # --- PAGE: 6x burn rate (6h long / 30m short) ---
      # Fires when 5% of monthly error budget consumed in 6 hours
      - alert: SLOAvailabilityBurnRateHigh
        expr: |
          slo:api_availability:error_ratio_rate6h > (6.0 * 0.001)
          and
          slo:api_availability:error_ratio_rate30m > (6.0 * 0.001)
        for: 5m
        labels:
          severity: critical
          slo: api-availability
          team: platform
        annotations:
          summary: "API availability SLO burn rate high (6x)"
          description: |
            API error ratio is {{ $value | humanizePercentage }} over 6h.
            At this burn rate, the 30-day error budget will be exhausted in ~5 days.
          runbook_url: "https://runbooks.example.com/slo/api-availability-high"

      # --- TICKET: 3x burn rate (1d long / 2h short) ---
      - alert: SLOAvailabilityBurnRateMedium
        expr: |
          slo:api_availability:error_ratio_rate1d > (3.0 * 0.001)
          and
          slo:api_availability:error_ratio_rate2h > (3.0 * 0.001)
        for: 15m
        labels:
          severity: warning
          slo: api-availability
          team: platform
        annotations:
          summary: "API availability SLO burn rate elevated (3x)"
          description: |
            API error ratio is {{ $value | humanizePercentage }} over 1d.
            At this burn rate, the 30-day error budget will be exhausted in ~10 days.
          runbook_url: "https://runbooks.example.com/slo/api-availability-medium"

      # --- TICKET: 1x burn rate (3d long / 6h short) ---
      - alert: SLOAvailabilityBurnRateLow
        expr: |
          slo:api_availability:error_ratio_rate3d > (1.0 * 0.001)
          and
          slo:api_availability:error_ratio_rate6h > (1.0 * 0.001)
        for: 30m
        labels:
          severity: info
          slo: api-availability
          team: platform
        annotations:
          summary: "API availability SLO burn rate sustained (1x)"
          description: |
            API error ratio is {{ $value | humanizePercentage }} over 3d.
            Error budget is being consumed at a rate that will exhaust it by end of window.
          runbook_url: "https://runbooks.example.com/slo/api-availability-low"
```

### SLO Tooling

| Tool | Type | What It Does | Best For |
|------|------|-------------|----------|
| **Sloth** | CLI + K8s operator (OSS) | Generates Prometheus recording rules + multi-window burn-rate alerts from a simple SLO spec (YAML or OpenSLO) | Teams that want SLO-as-code without a UI; lightweight, just generates PrometheusRules |
| **Pyrra** | CLI + K8s operator + Web UI (OSS) | Similar to Sloth but includes a built-in web UI showing error budget status, SLI trends, and multi-burn-rate alert status | Teams that want a visual SLO dashboard without Grafana; includes API for integration |
| **Nobl9** | SaaS platform | Enterprise SLO management with multiple data source integrations (Datadog, Prometheus, CloudWatch, New Relic, Dynatrace), composite SLOs, and burn-rate alert presets | Enterprise teams using multiple observability backends; need cross-platform SLO tracking |
| **OpenSLO** | Specification (YAML) | Vendor-neutral YAML specification for defining SLOs; consumed by tools like Sloth | Standardizing SLO definitions across teams/tools |
| **Google SLO Generator** | CLI (OSS) | Computes SLI values from various backends and exports to various destinations | GCP-centric environments |

**Sloth SLO definition example:**

```yaml
# sloth-slo.yaml
version: "prometheus/v1"
service: "api-server"
labels:
  owner: "platform-team"
  tier: "tier-1"
slos:
  - name: "requests-availability"
    objective: 99.9
    description: "99.9% of API requests should succeed"
    sli:
      events:
        error_query: sum(rate(http_requests_total{job="api-server",status_code=~"5.."}[{{.window}}]))
        total_query: sum(rate(http_requests_total{job="api-server"}[{{.window}}]))
    alerting:
      name: APIHighErrorRate
      labels:
        team: platform
      annotations:
        runbook_url: "https://runbooks.example.com/api-server/availability"
      page_alert:
        labels:
          severity: critical
      ticket_alert:
        labels:
          severity: warning
```

Running `sloth generate -i sloth-slo.yaml` produces all the recording rules and multi-window burn-rate alerts automatically.

---

## 5. Alert Design & Tuning

### Symptom-Based vs Cause-Based Alerting

| Approach | Example | Pros | Cons |
|----------|---------|------|------|
| **Symptom-based** | "Error rate > 5%" or "SLO burn rate critical" | Catches all failure modes (even ones you did not predict); directly tied to user impact | Requires investigation to find root cause |
| **Cause-based** | "Disk > 90%" or "Pod CrashLoopBackOff" | Specific, actionable, easy to write runbooks for | You must enumerate every failure mode; misses unknown-unknowns |

**Best practice:** Lead with symptom-based alerts for paging. Use cause-based alerts for dashboards and tickets (non-paging). SLO burn-rate alerts are the best form of symptom-based alerting.

**Alert hierarchy:**
1. **Page (wake someone up):** SLO burn-rate critical or high. Something is broken NOW and affecting users.
2. **Ticket (next business day):** SLO burn-rate medium/low, or cause-based alerts like disk filling, certificate expiring.
3. **Dashboard only (no notification):** Informational signals -- queue depth increasing, cache hit ratio dropping, GC pause times rising.

### Alert Fatigue Reduction

Alert fatigue is the #1 SRE operational problem. Signs: pages get acknowledged but not investigated, on-call ignores warnings, responders develop "alert blindness."

**Reduction strategies:**

1. **Delete alerts that never led to action** -- review every alert that fired in the last 90 days. If no one investigated or took action, delete it.
2. **Merge duplicates** -- if three alerts fire for the same incident, consolidate into one symptom-based alert.
3. **Increase thresholds and durations** -- an alert that fires for 30 seconds of elevated latency is noise. Use `for: 5m` or `for: 15m` to require sustained conditions.
4. **Use multi-window burn-rate** -- replaces dozens of threshold-based alerts with 4 well-calibrated burn-rate alerts per SLO.
5. **Route by severity** -- critical = page, warning = Slack, info = dashboard. Never page on a warning.
6. **Regular alert review** -- monthly review of all pages. Calculate: what percentage of pages resulted in human action? Target > 80%.

**Alert quality metrics to track:**
- Pages per on-call shift (target: < 5 per 12h shift)
- % of pages requiring human action (target: > 80%)
- % of pages that were actionable within 15 minutes (target: > 90%)
- Mean time to acknowledge (target: < 5 min)
- False positive rate (target: < 20%)

### Alertmanager Architecture

Alertmanager handles deduplication, grouping, silencing, inhibition, and routing of alerts from Prometheus.

```
Prometheus ──alert──▶ Alertmanager cluster (3 replicas, gossip protocol)
                           │
                     ┌─────┴──────┐
                     │  Routing   │
                     │   Tree     │
                     └─────┬──────┘
               ┌───────────┼───────────────┐
               │           │               │
          ┌────▼───┐  ┌────▼───┐   ┌───────▼──────┐
          │PagerDuty│  │ Slack  │   │   Email      │
          │(critical)│  │(warning)│  │  (info)      │
          └────────┘  └────────┘   └──────────────┘
```

**Alertmanager routing configuration:**

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'
  slack_api_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'

# Inhibition rules: suppress lower-severity alerts when higher-severity fires
inhibit_rules:
  # If a critical alert fires for a service, suppress warnings for same service
  - source_matchers:
      - severity = critical
    target_matchers:
      - severity = warning
    equal: ['alertname', 'namespace', 'service']

  # If a cluster-level alert fires, suppress namespace-level alerts
  - source_matchers:
      - scope = cluster
    target_matchers:
      - scope = namespace
    equal: ['cluster']

# Routing tree
route:
  receiver: 'default-slack'
  group_by: ['alertname', 'cluster', 'namespace', 'service']
  group_wait: 30s          # wait before sending first notification for group
  group_interval: 5m       # wait before sending updates for existing group
  repeat_interval: 4h      # resend if alert still firing after this long
  routes:
    # Critical SLO alerts -> PagerDuty (page immediately)
    - receiver: 'pagerduty-platform'
      matchers:
        - severity = critical
        - team = platform
      group_wait: 10s                    # faster for critical
      repeat_interval: 1h
      continue: false

    # Critical SLO alerts for other teams
    - receiver: 'pagerduty-application'
      matchers:
        - severity = critical
        - team = application
      group_wait: 10s
      repeat_interval: 1h
      continue: false

    # Warning alerts -> Slack channel
    - receiver: 'slack-warnings'
      matchers:
        - severity = warning
      group_wait: 2m                     # batch warnings together
      repeat_interval: 12h
      continue: false

    # Info / low-priority -> email digest
    - receiver: 'email-sre'
      matchers:
        - severity = info
      group_wait: 5m
      repeat_interval: 24h

receivers:
  - name: 'default-slack'
    slack_configs:
      - channel: '#alerts-default'
        title: '{{ .GroupLabels.alertname }} [{{ .Status | toUpper }}]'
        text: >-
          {{ range .Alerts }}
          *{{ .Annotations.summary }}*
          {{ .Annotations.description }}
          {{ if .Annotations.runbook_url }}Runbook: {{ .Annotations.runbook_url }}{{ end }}
          {{ end }}
        send_resolved: true

  - name: 'pagerduty-platform'
    pagerduty_configs:
      - routing_key: '<PAGERDUTY_INTEGRATION_KEY_PLATFORM>'
        severity: '{{ if eq .CommonLabels.severity "critical" }}critical{{ else }}warning{{ end }}'
        description: '{{ .CommonAnnotations.summary }}'
        details:
          firing: '{{ .Alerts.Firing | len }}'
          resolved: '{{ .Alerts.Resolved | len }}'
          runbook_url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
          dashboard_url: '{{ (index .Alerts 0).Annotations.dashboard_url }}'
        send_resolved: true

  - name: 'pagerduty-application'
    pagerduty_configs:
      - routing_key: '<PAGERDUTY_INTEGRATION_KEY_APP>'
        severity: '{{ if eq .CommonLabels.severity "critical" }}critical{{ else }}warning{{ end }}'
        send_resolved: true

  - name: 'slack-warnings'
    slack_configs:
      - channel: '#alerts-warnings'
        title: ':warning: {{ .GroupLabels.alertname }}'
        text: >-
          {{ range .Alerts }}
          {{ .Annotations.summary }}
          {{ .Annotations.description }}
          {{ end }}
        send_resolved: true

  - name: 'email-sre'
    email_configs:
      - to: 'sre-team@example.com'
        send_resolved: true
```

### Runbook Links

Every alert annotation should include a `runbook_url`. A good runbook for an alert includes:

1. **What does this alert mean?** -- plain English explanation
2. **What is the user impact?** -- who is affected and how
3. **First response steps** -- check these dashboards, run these commands
4. **Common root causes** -- the top 3-5 reasons this fires, with resolution steps for each
5. **Escalation** -- who to contact if you cannot resolve within 30 minutes
6. **History** -- links to past incidents triggered by this alert

### PagerDuty / Opsgenie Integration Best Practices

- **Use Events API v2** for Alertmanager integration (richer payloads, custom fields)
- **Set dedup keys** based on alertname + service + namespace -- prevents duplicate incidents for the same root cause
- **Enable auto-resolve** (`send_resolved: true`) so incidents close automatically when the alert clears
- **Map severity labels** to PagerDuty severity: critical/high -> PagerDuty `critical`, warning -> PagerDuty `warning`
- **Attach runbook URLs** and dashboard URLs as custom details in the PagerDuty payload
- **Set escalation policies** in PagerDuty: if not acknowledged in 5 min, escalate to secondary; if not acknowledged in 15 min, escalate to engineering manager
- **Quarterly alert audit:** Review the PagerDuty analytics dashboard. Any alert type that fires > 10 times/month without leading to action should be deleted or downgraded.

---

## 6. Metrics Pipeline Architecture

### Collection Models: Pull vs Push

| Model | Tool Example | How It Works | Pros | Cons |
|-------|-------------|-------------|------|------|
| **Pull (scrape)** | Prometheus, VictoriaMetrics | Monitoring system fetches `/metrics` on a schedule | Monitoring controls pace; failed scrape = detection; no app-side buffer | Requires service discovery; does not work for short-lived processes; firewalls can block |
| **Push** | StatsD, Graphite, OTel OTLP | Application sends metrics to a collector/gateway | Works for batch jobs, serverless, and ephemeral workloads; no port exposure needed | Requires backpressure handling; harder to detect "missing" sources; can overwhelm receivers |
| **Hybrid** | Grafana Alloy, OTel Collector | Collector scrapes Prometheus endpoints AND accepts OTLP push | Best of both worlds; single collector for all signal types | More complex collector configuration |

**Recommendation:** Use pull (Prometheus scrape) for long-running services in Kubernetes. Use push (OTLP or Pushgateway) for serverless, batch jobs, and short-lived processes. Deploy Grafana Alloy or OTel Collector as the unified pipeline.

### OpenTelemetry Metrics vs Prometheus Metrics

| Dimension | Prometheus Metrics | OpenTelemetry Metrics |
|-----------|-------------------|----------------------|
| **Data model** | Flat metric name + labels + value | Hierarchical (resource -> scope -> metric -> data points) |
| **Temporality** | Cumulative (counters always increase) | Cumulative or Delta (configurable per exporter) |
| **Histogram** | Classic (fixed `le` buckets) or Native (exponential) | Exponential histogram (similar to Prometheus native) |
| **Naming** | `http_requests_total` (underscores, `_total` suffix) | `http.server.request.count` (dots, no suffix convention) |
| **UTF-8** | Supported in Prometheus 3.x | Native |
| **Exemplars** | Supported (link metrics to traces) | Supported natively |
| **Collection** | Scrape via `/metrics` endpoint | Push via OTLP/gRPC or OTLP/HTTP |
| **SDK maturity** | Client libraries per language | Unified SDK across all languages |

**Practical guidance:** If you are already in the Prometheus ecosystem, continue using Prometheus client libraries for instrumentation. Add OTel for tracing. For new projects, OTel SDKs are a reasonable choice for metrics too -- Prometheus 3.x natively ingests OTLP, so there is no lock-in.

### Cardinality Management

Cardinality = the total number of unique time series. It is the single biggest factor in metrics storage cost and query performance.

**Formula:** `cardinality = metric_count x product(unique_values_per_label)`

**Example of explosion:** A metric with labels `{method, endpoint, status_code, customer_id, instance}` where method has 5 values, endpoint has 200, status_code has 10, customer_id has 50,000, and instance has 20 = 5 x 200 x 10 x 50,000 x 20 = **10 billion series**. That is not viable.

**Rules of thumb:**
1. **Never use unbounded values as labels** -- user IDs, request IDs, email addresses, IP addresses, session IDs, trace IDs. Use these in logs/traces, not metrics.
2. **Limit labels to values with < 100 unique values each** -- method, status_code, region, service_name, deployment_version are fine.
3. **Use recording rules to pre-aggregate** -- aggregate away high-cardinality labels before storage.
4. **Set sample limits per scrape target:**

```yaml
scrape_configs:
  - job_name: 'my-service'
    sample_limit: 10000          # reject scrape if > 10K series
    label_limit: 30              # max labels per series
    label_name_length_limit: 200
    label_value_length_limit: 200
```

5. **Use metric_relabel_configs to drop expensive metrics:**

```yaml
metric_relabel_configs:
  # Drop all Go runtime GC detail metrics (high cardinality, rarely useful)
  - source_labels: [__name__]
    regex: 'go_gc_duration_seconds_.*'
    action: drop
  # Drop debug-level histograms in production
  - source_labels: [__name__]
    regex: '.*_debug_.*'
    action: drop
  # Remove a specific high-cardinality label
  - regex: 'customer_id'
    action: labeldrop
```

6. **OpenTelemetry SDK cardinality limits** -- the OTel SDK has a default limit of 2,000 unique attribute combinations per metric. Configure per-metric:

```go
// Go example: set cardinality limit via View
view := metric.NewView(
    metric.Instrument{Name: "http.server.request.duration"},
    metric.Stream{
        AttributeFilter: attribute.NewAllowKeysFilter(
            "http.request.method",
            "http.response.status_code",
            "url.scheme",
        ),
    },
)
```

7. **Monitor cardinality proactively:**

```promql
# Total active series count (global)
prometheus_tsdb_head_series

# Series created per second (growth rate)
rate(prometheus_tsdb_head_series_created_total[5m])

# Top 10 metrics by cardinality
topk(10, count by (__name__)({__name__=~".+"}))

# Series per job (find the offender)
count by (job)({__name__=~".+"})
```

### Remote Write Pipeline Architecture

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Prometheus-0 │    │ Prometheus-1 │    │ Prometheus-2 │
│  (zone-a)    │    │  (zone-b)    │    │  (zone-c)    │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │ remote_write       │ remote_write       │ remote_write
       └───────────────┬───┘───────────────────┘
                       ▼
            ┌─────────────────────┐
            │  Grafana Alloy /    │   (optional: aggregation,
            │  OTel Collector     │    relabeling, downsampling)
            │  (write pipeline)   │
            └──────────┬──────────┘
                       ▼
            ┌─────────────────────┐
            │  Mimir / Thanos /   │
            │  VictoriaMetrics    │
            │  (long-term store)  │
            └─────────────────────┘
```

**Remote write tuning for high throughput:**

```yaml
remote_write:
  - url: "http://mimir-distributor:8080/api/v1/push"
    queue_config:
      capacity: 10000               # buffer size (samples)
      max_shards: 50                # parallel senders
      min_shards: 1
      max_samples_per_send: 5000    # batch size
      batch_send_deadline: 5s       # flush even if batch not full
      min_backoff: 30ms
      max_backoff: 5s
    write_relabel_configs:
      # Drop metrics you do not need in long-term storage
      - source_labels: [__name__]
        regex: 'promhttp_metric_handler_.*'
        action: drop
```

### Grafana Alloy Configuration for Metrics Pipeline

```alloy
// alloy.config -- unified metrics collection pipeline

// Prometheus scrape for Kubernetes pods
prometheus.scrape "kubernetes_pods" {
  targets    = discovery.kubernetes.pods.targets
  forward_to = [prometheus.relabel.filter.receiver]
}

// Service discovery
discovery.kubernetes "pods" {
  role = "pod"
}

// Relabel and filter
prometheus.relabel "filter" {
  forward_to = [prometheus.remote_write.mimir.receiver]

  rule {
    source_labels = ["__name__"]
    regex         = "go_gc_.*"
    action        = "drop"
  }
}

// OTLP receiver (for push-based OTel instrumented services)
otelcol.receiver.otlp "default" {
  grpc {
    endpoint = "0.0.0.0:4317"
  }
  http {
    endpoint = "0.0.0.0:4318"
  }
  output {
    metrics = [otelcol.processor.batch.default.input]
  }
}

// Batch processor
otelcol.processor.batch "default" {
  output {
    metrics = [otelcol.exporter.prometheus.mimir.input]
  }
}

// Export OTel metrics as Prometheus remote write
otelcol.exporter.prometheus "mimir" {
  forward_to = [prometheus.remote_write.mimir.receiver]
}

// Remote write to Mimir
prometheus.remote_write "mimir" {
  endpoint {
    url = "http://mimir-distributor:8080/api/v1/push"

    queue_config {
      capacity          = 10000
      max_shards        = 30
      max_samples_per_send = 5000
    }
  }
}
```

---

## 7. Synthetic Monitoring

### Why Synthetic Monitoring

Real User Monitoring (RUM) shows what is happening to actual users. Synthetic monitoring tells you what WOULD happen -- it detects outages even when no users are present (3 AM, off-peak, newly launched endpoints). It is essential for:

- **Uptime verification** from multiple geographic locations
- **Baseline performance measurement** with consistent test conditions
- **API contract validation** before users hit a broken endpoint
- **SSL certificate and DNS monitoring**
- **Multi-step transaction verification** (login, checkout, search)

### Tool Comparison

| Dimension | Grafana Synthetic Monitoring | Checkly | Datadog Synthetics | AWS CloudWatch Synthetics |
|-----------|----------------------------|---------|-------------------|--------------------------|
| **Type** | Grafana Cloud feature | SaaS (standalone) | Datadog feature | AWS-native |
| **Check Types** | HTTP, multi-step, DNS, TCP, traceroute, scripted browser (k6) | API checks, browser checks (Playwright), multi-step | API, browser (Chrome), multi-step, gRPC | Node.js canaries (Puppeteer), visual monitoring |
| **Scripting** | k6 (JavaScript) | Playwright (JavaScript/TypeScript) | Managed browser, API tests | Node.js + Puppeteer |
| **Locations** | Global probe network (30+ locations) | 20+ global locations | 130+ managed locations | All AWS regions |
| **Integration** | Native Grafana dashboards, Prometheus/Mimir metrics, Loki logs | Prometheus exporter, Grafana dashboard, OTel, CI/CD (GitHub Actions, Vercel) | Native Datadog dashboards, APM correlation | CloudWatch metrics and dashboards |
| **Monitoring as Code** | Terraform provider, Kubernetes CRDs | CLI + Terraform + GitHub Actions (first-class MaC) | Terraform provider, API | CloudFormation, CDK |
| **AI Features** | None currently | Rocky AI agent (2026) -- auto-triages failures, analyzes packet captures | AIOps anomaly detection on synthetic results | Basic anomaly detection |
| **Pricing** | Included in Grafana Cloud (check-based usage) | From $30/mo (Hobby) to custom Enterprise | $5/1K API tests, $12/1K browser tests | $0.0012/canary run |
| **Best For** | Teams already on Grafana Cloud | Developer-first teams wanting MaC and Playwright | Teams already on Datadog | AWS-only infrastructure |

### Implementation Pattern: Checkly as Code

```typescript
// checkly.config.ts -- Monitoring as Code with Checkly
import { defineConfig } from 'checkly';

export default defineConfig({
  projectName: 'Production API Monitoring',
  logicalId: 'prod-api-monitoring',
  repoUrl: 'https://github.com/myorg/api-service',
  checks: {
    frequency: Frequency.EVERY_1M,       // check every minute
    locations: ['us-east-1', 'eu-west-1', 'ap-southeast-1'],
    runtimeId: '2024.02',
    tags: ['production', 'api'],
    alertChannels: [/* PagerDuty, Slack */],
  },
});

// __checks__/api-health.check.ts
import { ApiCheck, AssertionBuilder } from 'checkly/constructs';

new ApiCheck('api-health-check', {
  name: 'API Health Check',
  request: {
    method: 'GET',
    url: 'https://api.example.com/health',
    assertions: [
      AssertionBuilder.statusCode().equals(200),
      AssertionBuilder.responseTime().lessThan(500),
      AssertionBuilder.jsonBody('$.status').equals('healthy'),
    ],
  },
  degradedResponseTime: 300,
  maxResponseTime: 1000,
});

// __checks__/checkout-flow.spec.ts -- Playwright browser check
import { test, expect } from '@playwright/test';

test('checkout flow completes successfully', async ({ page }) => {
  await page.goto('https://shop.example.com');
  await page.click('[data-testid="product-card"]');
  await page.click('[data-testid="add-to-cart"]');
  await page.click('[data-testid="checkout-button"]');
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible();
});
```

### Grafana Synthetic Monitoring Setup

Grafana Cloud Synthetic Monitoring deploys lightweight probes globally. Configuration via Terraform:

```hcl
resource "grafana_synthetic_monitoring_check" "api_health" {
  job     = "api-health"
  target  = "https://api.example.com/health"
  enabled = true

  probes = [
    data.grafana_synthetic_monitoring_probes.main.probes.Atlanta,
    data.grafana_synthetic_monitoring_probes.main.probes.London,
    data.grafana_synthetic_monitoring_probes.main.probes.Tokyo,
  ]

  settings {
    http {
      method           = "GET"
      valid_status_codes = [200]
      fail_if_body_matches_regexp = ["error", "unhealthy"]
      tls_config {
        insecure_skip_verify = false
      }
    }
  }

  labels = {
    environment = "production"
    team        = "platform"
  }
}
```

---

## 8. Dashboard Design Best Practices

### The Three Frameworks

#### Google's Four Golden Signals

Defined in the Google SRE Book. Best for **request-driven services** (APIs, web servers).

| Signal | What It Measures | Prometheus Metric Example |
|--------|-----------------|--------------------------|
| **Latency** | Time to serve a request (distinguish success vs error latency) | `http_request_duration_seconds` |
| **Traffic** | Demand on the system (requests per second) | `http_requests_total` |
| **Errors** | Rate of failed requests (explicit 5xx AND implicit timeouts) | `http_requests_total{status_code=~"5.."}` |
| **Saturation** | How "full" the service is (CPU, memory, queue depth, connections) | `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes` |

#### RED Method (Request-driven)

Coined by Tom Wilkie at Grafana Labs. A simplified subset of the golden signals focused on microservices.

| Signal | Description | Dashboard Panel Type |
|--------|------------|---------------------|
| **Rate** | Requests per second | Time series (line chart) |
| **Errors** | Errors per second or error ratio | Time series + stat panel for current ratio |
| **Duration** | Latency distribution (p50, p95, p99) | Time series with multiple quantile lines + heatmap |

#### USE Method (Resource-oriented)

Coined by Brendan Gregg. Best for **infrastructure components** (CPU, memory, disk, network, queues).

| Signal | Description | Example |
|--------|------------|---------|
| **Utilization** | Percentage of resource capacity being used | CPU: 72%, Memory: 85%, Disk: 60% |
| **Saturation** | Degree of queued or deferred work | CPU run queue length, disk I/O wait, TCP connection backlog |
| **Errors** | Count of error events | ECC memory errors, NIC packet errors, disk I/O errors |

### Dashboard Layout Principles

**Rule 1: Top-to-bottom, broad-to-specific.**
- Row 1: Service overview (SLO status, request rate, error rate, latency) -- the RED/Golden Signals summary
- Row 2: Breakdown by endpoint, method, or status code
- Row 3: Infrastructure (CPU, memory, disk, network)
- Row 4: Dependencies (database latency, cache hit ratio, external API latency)
- Row 5: Deployment markers, version annotations

**Rule 2: Time range consistency.**
- All panels use the same time range (Grafana's global time picker)
- Use relative ranges (`Last 6 hours`) for operational dashboards
- Use absolute ranges for incident investigation

**Rule 3: Variable templates for drill-down.**
- `$cluster` -> `$namespace` -> `$service` -> `$pod` hierarchy
- Use dependent variables (selecting a namespace filters pods)
- Pre-set commonly used combinations as dashboard links

**Rule 4: Color means something.**
- Green = healthy / within SLO
- Yellow/Amber = degraded / approaching SLO boundary
- Red = SLO breached / error
- Never use red for informational data

**Rule 5: Every chart answers a specific question.**
- Bad: "CPU metrics" (what is this telling me?)
- Good: "Is this service CPU-saturated?" (clear question, clear threshold)

### Dashboard Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Wall of graphs** | 50 panels, no narrative, impossible to scan | Use drill-down hierarchy; top-level dashboard has 6-12 panels max |
| **No thresholds** | Lines go up and down but you cannot tell if it is good or bad | Add threshold lines at SLO boundaries, color zones |
| **Average-only latency** | Averages hide tail latency problems (99th percentile matters) | Always show p50, p95, p99 together; use heatmaps for distribution |
| **Stale dashboards** | Dashboard created 2 years ago for a service that has been redesigned | Quarterly dashboard review; tie dashboard updates to service changes |
| **No variables** | Hardcoded cluster/namespace/service names | Parameterize everything; dashboards should work across environments |
| **Missing units** | Y-axis says "42" but is that bytes, milliseconds, or requests? | Always set units: `reqps`, `s`, `bytes`, `percentunit` |
| **Sum without rate** | Using `sum(http_requests_total)` which is a monotonically increasing counter | Use `sum(rate(http_requests_total[5m]))` to get per-second rate |
| **Too many legends** | 200 series in one panel, legend is unreadable | Aggregate, use `topk()`, or use heatmap. Consider separate panels for separate dimensions |

### Grafana Dashboard JSON Snippet -- SLO Overview Panel

```json
{
  "panels": [
    {
      "type": "stat",
      "title": "API Availability (30d SLO: 99.9%)",
      "gridPos": { "h": 4, "w": 6, "x": 0, "y": 0 },
      "targets": [
        {
          "expr": "1 - (sum(increase(http_requests_total{job=\"api-server\", status_code=~\"5..\"}[30d])) / sum(increase(http_requests_total{job=\"api-server\"}[30d])))",
          "legendFormat": "Availability"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percentunit",
          "decimals": 3,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "value": null, "color": "red" },
              { "value": 0.999, "color": "yellow" },
              { "value": 0.9995, "color": "green" }
            ]
          },
          "mappings": []
        }
      },
      "options": {
        "reduceOptions": {
          "calcs": ["lastNotNull"]
        },
        "colorMode": "background",
        "textMode": "auto"
      }
    },
    {
      "type": "gauge",
      "title": "Error Budget Remaining (30d)",
      "gridPos": { "h": 4, "w": 6, "x": 6, "y": 0 },
      "targets": [
        {
          "expr": "1 - (sum(increase(http_requests_total{job=\"api-server\", status_code=~\"5..\"}[30d])) / sum(increase(http_requests_total{job=\"api-server\"}[30d])) / 0.001)",
          "legendFormat": "Budget Remaining"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percentunit",
          "min": 0,
          "max": 1,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "value": null, "color": "red" },
              { "value": 0.25, "color": "orange" },
              { "value": 0.5, "color": "yellow" },
              { "value": 0.75, "color": "green" }
            ]
          }
        }
      },
      "options": {
        "reduceOptions": {
          "calcs": ["lastNotNull"]
        },
        "showThresholdLabels": true
      }
    },
    {
      "type": "timeseries",
      "title": "Request Rate (req/s)",
      "gridPos": { "h": 8, "w": 8, "x": 0, "y": 4 },
      "targets": [
        {
          "expr": "sum(rate(http_requests_total{job=\"api-server\"}[5m])) by (status_code)",
          "legendFormat": "{{status_code}}"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "reqps",
          "custom": {
            "drawStyle": "line",
            "fillOpacity": 10,
            "stacking": { "mode": "normal" }
          }
        },
        "overrides": [
          {
            "matcher": { "id": "byRegexp", "options": "5.." },
            "properties": [
              { "id": "color", "value": { "mode": "fixed", "fixedColor": "red" } }
            ]
          }
        ]
      }
    },
    {
      "type": "timeseries",
      "title": "Latency (p50 / p95 / p99)",
      "gridPos": { "h": 8, "w": 8, "x": 8, "y": 4 },
      "targets": [
        {
          "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket{job=\"api-server\"}[5m])) by (le))",
          "legendFormat": "p50"
        },
        {
          "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job=\"api-server\"}[5m])) by (le))",
          "legendFormat": "p95"
        },
        {
          "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job=\"api-server\"}[5m])) by (le))",
          "legendFormat": "p99"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "s",
          "custom": {
            "drawStyle": "line",
            "fillOpacity": 0
          }
        }
      }
    },
    {
      "type": "heatmap",
      "title": "Latency Distribution",
      "gridPos": { "h": 8, "w": 8, "x": 16, "y": 4 },
      "targets": [
        {
          "expr": "sum(increase(http_request_duration_seconds_bucket{job=\"api-server\"}[5m])) by (le)",
          "legendFormat": "{{le}}",
          "format": "heatmap"
        }
      ],
      "options": {
        "calculate": false,
        "color": {
          "scheme": "Oranges"
        },
        "yAxis": {
          "unit": "s"
        }
      }
    }
  ]
}
```

### Drill-Down Pattern

Design dashboards as a hierarchy, not a monolith:

```
Level 0: Platform Overview
  ├── SLO status for all tier-1 services (stat panels, red/yellow/green)
  ├── Total request rate across platform
  └── Links to Level 1 dashboards

Level 1: Service Overview (per service)
  ├── RED metrics (rate, errors, duration)
  ├── SLO burn-rate status
  ├── Recent deployments (annotation markers)
  └── Links to Level 2 dashboards

Level 2: Service Deep Dive
  ├── Per-endpoint breakdown
  ├── Per-pod resource usage (CPU, memory)
  ├── Dependency health (DB latency, cache hits, external API)
  └── Links to Level 3 dashboards

Level 3: Infrastructure / Debug
  ├── Container-level metrics
  ├── Node-level metrics (USE method)
  ├── Network metrics
  └── Log panel (Loki integration)
```

Use Grafana's **data links** feature to make these drill-downs clickable: a time series panel in Level 1 can link to the Level 2 dashboard with the same time range and service variable pre-populated.

### Dashboard Review Checklist

Before deploying a dashboard to production, verify:

- [ ] Every panel has a descriptive title that frames a question
- [ ] Y-axis units are set (`reqps`, `s`, `bytes`, `percentunit`)
- [ ] Color thresholds correspond to SLO boundaries
- [ ] Variables are used for cluster, namespace, service (no hardcoded values)
- [ ] Time range is appropriate (operational: last 6h, capacity: last 7d)
- [ ] Latency panels show percentiles, not averages
- [ ] Counter metrics use `rate()` or `increase()`, never raw values
- [ ] High-cardinality labels are aggregated (no 200-series panels)
- [ ] Dashboard has a description explaining its purpose and audience
- [ ] Dashboard is version-controlled (dashboard-as-code or provisioning)
- [ ] Dashboard links provide drill-down to related dashboards
- [ ] Annotations show deployment events
