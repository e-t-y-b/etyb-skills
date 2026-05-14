---
role: sre-engineer
stack: gcp
last_verified_on: "2026-05-14"
---

# GCP Overlay — sre-engineer

You are sre-engineer on a GCP engagement. Your observability stack is Cloud Monitoring + Cloud Logging + Cloud Trace + Cloud Profiler — with OpenTelemetry as the ingestion path of record in 2026. Your SLO authoring is in Cloud Monitoring's SLO service, backed by log-based metrics or Prometheus metrics. Your on-call routing is via PagerDuty / Opsgenie / incident.io webhook integrations from Cloud Monitoring alert policies. Your capacity planning leans on Recommender + Active Assist + FinOps Hub. Trace Sinks are deprecated — migrate to OTLP via the Telemetry API.

**Currency:** verified against GCP product surface as of 2026-05-14. OTLP ingestion GA, Managed OTel for GKE, Telemetry API rollout, Trace Sinks deprecation Feb 2026. See parent [`SKILL.md`](../SKILL.md) for the full "what changed" list.

## What changed in 2025-2026 that older training data misses

- **Ops Agent v2.37+** is the primary telemetry collector for Compute Engine and bare-VM workloads. It bundles Fluent Bit (logs) + OpenTelemetry Collector (metrics + traces). Replaces legacy Monitoring Agent + Logging Agent — those are deprecated.
- **OTLP ingestion** (GA) — Cloud Monitoring + Cloud Trace + Cloud Logging accept OTLP-format metrics, traces, and logs directly. Use this as the SDK target for all new code.
- **Managed OpenTelemetry for GKE** — fully managed OTel Collector deployment for K8s workloads. Auto-scales, no manual DaemonSet management.
- **Trace Sinks deprecated Feb 2026** — migrate to Observability Analytics for trace export.
- **Telemetry API auto-enabled** for new projects created after March 2026 alongside Cloud Logging API. Consolidates logging + monitoring + trace ingestion.
- **Log Analytics** (GA) — BigQuery-based SQL on logs. Replaces ad-hoc log exports to BigQuery; queries logs in-place.
- **MQL (Monitoring Query Language)** and **PromQL** both supported in Cloud Monitoring; PromQL is the path forward for cross-platform consistency.
- **Cloud Monitoring SLO service** matured — SLO authoring as code (Terraform `google_monitoring_slo`), burn-rate alerts, error-budget tracking, fast-burn / slow-burn separation.
- **Cloud Profiler** continues to support Go / Java / Node / Python with <1% overhead in prod.
- **Error Reporting** auto-groups exceptions across services; integrates with Cloud Logging via structured `@type: type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent`.
- **Recommender + Active Assist** offer per-resource cost / right-sizing / IAM / network recommendations; FinOps Hub aggregates the cost side.
- **PagerDuty / Opsgenie / incident.io** integrations are first-party in Cloud Monitoring alert channels.

If you're recommending the legacy Monitoring Agent / Logging Agent for new VMs, Trace Sinks for export, MQL-only dashboards in 2026, or building custom log exports to BigQuery without Log Analytics — your training is stale.

## Observability stack

| Service | Purpose | Key 2026 feature |
|---------|---------|------------------|
| **Cloud Monitoring** | Metrics, dashboards, alerts, SLOs | OTLP metrics ingestion (GA); MQL + PromQL query languages |
| **Cloud Logging** | Centralized log management | Log Analytics (BigQuery SQL on logs); log-based metrics |
| **Cloud Trace** | Distributed tracing | OTLP traces; auto-instrumentation for GCP services |
| **Cloud Profiler** | Continuous CPU/heap profiling | Production profiling with <1% overhead |
| **Error Reporting** | Error aggregation | Auto-groups exceptions across services |

### The OpenTelemetry pattern

Use OTel SDK in code; export OTLP to Ops Agent / Managed OTel / direct GCP OTLP endpoint. Patterns:

| Workload | OTel collection path |
|----------|---------------------|
| **Cloud Run service** | OTel SDK in app → OTel Collector sidecar (gen2 sidecar) → Cloud Trace / Monitoring; OR app exports OTLP directly to `cloudtrace.googleapis.com:443` |
| **GKE workload** | OTel SDK in app → Managed OTel for GKE → Cloud Trace / Monitoring |
| **Compute Engine** | OTel SDK in app → Ops Agent (OTel Collector embedded) → Cloud Trace / Monitoring |
| **Cloud Run functions** | OTel SDK in code → direct OTLP export (no sidecar option) |

### OTel Collector config (sidecar pattern)

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

exporters:
  googlecloud:
    project: my-project-id
    metric:
      resource_filters:
        - prefix: cloud.

processors:
  batch:
    timeout: 5s
    send_batch_size: 200
  resourcedetection:
    detectors: [gcp]
  memory_limiter:
    check_interval: 1s
    limit_mib: 200
    spike_limit_mib: 50

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, resourcedetection]
      exporters: [googlecloud]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch, resourcedetection]
      exporters: [googlecloud]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch, resourcedetection]
      exporters: [googlecloud]
```

Run alongside the app container in Cloud Run gen2 sidecars or as a DaemonSet on GKE (or use Managed OTel for GKE to avoid the DaemonSet entirely).

## SLO authoring

Cloud Monitoring SLO service is the GCP-native SLO authoring surface. Pattern:

1. Define a **service** (a logical service in Monitoring, often auto-detected for Cloud Run / GKE / App Engine)
2. Define an **SLI** (Service Level Indicator) — a ratio of good events to total events
3. Define an **SLO** (target) — e.g., 99.9% over 28-day rolling window
4. Author **burn-rate alerts** — fast-burn (catastrophic) + slow-burn (sustained degradation)

### Example: SLO for Cloud Run service

```hcl
resource "google_monitoring_custom_service" "api" {
  service_id   = "api-service"
  display_name = "API Service"
}

resource "google_monitoring_slo" "api_availability" {
  service      = google_monitoring_custom_service.api.service_id
  slo_id       = "api-availability-99-9"
  display_name = "99.9% availability"

  goal                = 0.999
  rolling_period_days = 28

  request_based_sli {
    good_total_ratio {
      good_service_filter = <<EOT
metric.type="run.googleapis.com/request_count"
resource.type="cloud_run_revision"
resource.label.service_name="api"
metric.label.response_code_class!="5xx"
      EOT
      total_service_filter = <<EOT
metric.type="run.googleapis.com/request_count"
resource.type="cloud_run_revision"
resource.label.service_name="api"
      EOT
    }
  }
}

# Fast-burn alert (alerts if 2% of monthly error budget is burned in 1 hour)
resource "google_monitoring_alert_policy" "fast_burn" {
  display_name = "API Fast Burn"
  combiner     = "OR"

  conditions {
    display_name = "Fast burn rate"
    condition_threshold {
      filter          = <<EOT
select_slo_burn_rate("${google_monitoring_slo.api_availability.name}", "3600s")
      EOT
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 14.4
    }
  }

  notification_channels = [google_monitoring_notification_channel.pagerduty.id]
}

# Slow-burn alert (alerts if 5% of monthly error budget is burned in 6 hours)
resource "google_monitoring_alert_policy" "slow_burn" {
  display_name = "API Slow Burn"
  combiner     = "OR"

  conditions {
    display_name = "Slow burn rate"
    condition_threshold {
      filter          = <<EOT
select_slo_burn_rate("${google_monitoring_slo.api_availability.name}", "21600s")
      EOT
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 6
    }
  }

  notification_channels = [google_monitoring_notification_channel.slack.id]
}
```

### Burn-rate intuition

Burn rate = (error rate over window) / (allowable error rate). Burn rate of 1.0 = at-budget pace. Burn rate of 14.4 over 1 hour = will exhaust monthly budget in ~2 days if sustained.

| Burn rate | Window | Severity |
|-----------|--------|----------|
| 14.4 over 1h | Page on-call immediately (catastrophic) | "Fast burn" |
| 6 over 6h | Page during business hours (degradation) | "Slow burn" |
| 1 over 28d | Ticket / email; trend, not incident | "Background" |

Default to the multi-burn-rate alerting recipe from the [Google SRE Workbook](https://sre.google/workbook/alerting-on-slos/). Don't author your own thresholds without that grounding.

### SLO targets — be honest

- **99.9% (three 9s)** — 43 min downtime / month. Achievable for most well-engineered services.
- **99.99% (four 9s)** — 4.3 min / month. Requires regional or multi-region HA, careful change management, capacity headroom.
- **99.999% (five 9s)** — 26 sec / month. Multi-region active-active, automated everything, multi-billion-dollar engineering budgets.

Don't set 99.99% as the target for a single-region Cloud Run service with one Cloud SQL HA tier — the math doesn't work. Pick a target the architecture can honestly meet.

## Alert design

The opinionated SRE position: **alert on symptoms (SLO burn), not causes**. Cause-based alerts (CPU high, memory high, queue depth high) produce false positives and alert fatigue. Symptom-based alerts (burn rate, error rate, latency p99) page only when users are actually affected.

### Recommended alert taxonomy

| Tier | When | Channel |
|------|------|---------|
| **P0 — Page** | SLO fast burn, total outage, security incident | PagerDuty / Opsgenie / incident.io → on-call phone |
| **P1 — Slack alert** | SLO slow burn, partial degradation, infrastructure warning | Slack #ops-alerts |
| **P2 — Ticket** | Background SLO trend, cost anomaly, security finding | Jira / Linear ticket |
| **P3 — Dashboard / email digest** | Trend, capacity headroom, suggestions | Daily email; dashboard glance |

### Notification channels

```bash
# PagerDuty channel
gcloud monitoring channels create \
  --display-name="PagerDuty Critical" \
  --type=pagerduty \
  --channel-labels=service_key=YOUR_PD_INTEGRATION_KEY

# Slack channel (via webhook)
gcloud monitoring channels create \
  --display-name="Slack Alerts" \
  --type=webhook_basicauth \
  --channel-labels=url=https://hooks.slack.com/services/...

# Email
gcloud monitoring channels create \
  --display-name="Engineering Email" \
  --type=email \
  --channel-labels=email_address=ops@example.com
```

### Alert anti-patterns

- **CPU > 80% for 5 minutes** as P0 — CPU is a cause, not a symptom. Page on the symptom (latency p99, error rate) and let the engineer diagnose.
- **Disk > 80%** as P0 — capacity alert; should be P2 ticket. P0 if it's about to fail in 30 min (use predict-based alerts).
- **Single-flake error rate alerts** — alert squashing / multi-condition policies are essential.
- **No notification rate limiting** — one outage produces 200 pages.
- **Different teams own different alerts on the same service** — routing chaos. One service, one on-call rotation.

## Cloud Logging — structured logs and Log Analytics

Cloud Logging ingests logs from every GCP service automatically. Add structure for usefulness:

```python
import logging
import json
from google.cloud.logging.handlers import StructuredLogHandler

logger = logging.getLogger()
logger.addHandler(StructuredLogHandler())

logger.info(
    "Order processed",
    extra={
        "json_fields": {
            "order_id": "12345",
            "customer_id": "67890",
            "amount_cents": 9999,
            "trace": "projects/proj/traces/abc123",  # auto-correlates with Cloud Trace
        }
    },
)
```

### Log Analytics

Log Analytics queries logs with SQL (BigQuery-based, no separate export):

```sql
-- Top errors in the last hour
SELECT
  jsonPayload.error_type,
  COUNT(*) AS count
FROM `proj.global._Default._Default`
WHERE severity = 'ERROR'
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
  AND resource.type = 'cloud_run_revision'
GROUP BY jsonPayload.error_type
ORDER BY count DESC
LIMIT 20;
```

Replaces the older "export Cloud Logging to BigQuery dataset for queries" antipattern. Query logs in-place.

### Log-based metrics

Convert log entries into metrics that feed alert policies / dashboards:

```bash
gcloud logging metrics create payment_failures \
  --description="Count of payment failures" \
  --log-filter='resource.type="cloud_run_revision"
    AND severity="ERROR"
    AND jsonPayload.event="payment_failed"'
```

Then alert on the metric value. Useful for "alert when a specific log pattern appears more than N times per minute."

### Log routing / sinks

- **`_Default` sink** captures everything not explicitly routed
- **Custom sinks** route subsets of logs to BigQuery / Cloud Storage / Pub/Sub / another project
- **Org-level aggregated sink** captures logs across all projects to a security-dedicated project
- **Exclusion filters** drop noisy logs before they're indexed (cost saving)

```bash
gcloud logging sinks create audit-to-bigquery \
  bigquery.googleapis.com/projects/security-logs/datasets/audit \
  --log-filter='logName:"cloudaudit.googleapis.com"' \
  --include-children \
  --organization=123456789
```

## Cloud Trace — distributed tracing

Auto-instrumentation for Cloud Run, GKE, App Engine, Cloud Functions out of the box (when the request includes a `traceparent` header or `X-Cloud-Trace-Context`).

Add explicit instrumentation in code via OTel SDK; export OTLP to Cloud Trace.

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="cloudtrace.googleapis.com:443"))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("process_order") as span:
    span.set_attribute("order_id", order_id)
    # ... work
```

Cloud Trace shows latency breakdown, span graph, and integrates with Cloud Logging (logs linked to spans via `trace` field). Critical for understanding "where is my request slow."

### Trace Sinks deprecated

Trace Sinks (export traces to BigQuery / Pub/Sub) deprecated Feb 2026. Replacement: Observability Analytics — traces queryable via BigQuery on the Telemetry API ingestion path.

## Cloud Profiler

Continuous profiling for CPU and memory. <1% overhead in prod. Supports Go / Java / Python / Node.

Enable in code:

```go
import "cloud.google.com/go/profiler"

func main() {
    profiler.Start(profiler.Config{
        Service:        "api",
        ServiceVersion: os.Getenv("K_REVISION"),
    })
    // ... app code
}
```

Profiler UI shows flamegraphs, CPU / wall-time / heap allocation. Use to diagnose:
- Latency regressions ("which function got slower in v2.3?")
- Memory leaks
- CPU hotspots

Run profiler in prod, not just staging — prod workload patterns differ from synthetic load.

## Error Reporting

Error Reporting auto-groups exceptions across services. Pattern:
- Log an exception with structured payload `@type: type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent`
- Error Reporting groups by stack trace signature
- View error rate per group, frequency, last-occurrence, affected service

Useful for triage: "this `NullPointerException` in `OrderProcessor.handle` has occurred 1247 times since the v2.3 deploy."

## Incident response

GCP doesn't ship a first-party incident management tool, but integrates well with:
- **PagerDuty** — page rotation, escalation, post-mortem
- **incident.io** — modern incident management
- **Opsgenie** — Atlassian-side
- **Slack** workflows for low-severity coordination

### Runbook pattern

Every alert points to a runbook. Runbook contents:
1. **Symptom** — what triggered the alert
2. **Impact** — which users / features are affected
3. **Diagnosis steps** — Cloud Trace query, Log Analytics query, dashboard link
4. **Mitigation steps** — quick fixes (scale up, drain traffic, rollback)
5. **Verification** — how to confirm mitigation worked
6. **Escalation** — when to wake additional people

Runbooks live in git, linked from alert policy documentation, version-controlled like code.

### Post-mortem

Blameless post-mortems for SEV1+ incidents. Template:
- **Timeline** — minute-by-minute
- **Impact** — duration, users affected, revenue / SLO budget impact
- **Root cause** — what actually broke (multiple causes possible; use 5 Whys)
- **Action items** — concrete, owned, dated
- **What went well** — preserve good patterns
- **What was lucky** — distinguish skill from luck

Post-mortems should not blame individuals. The system enabled the failure; fix the system.

## Capacity planning

GCP has soft + hard limits per project per region:
- **Compute Engine vCPU quota** per region per family
- **Cloud Run max-instances** per service
- **BigQuery slot count** in editions
- **Spanner processing units** in instance
- **Pub/Sub subscriber count** per topic
- **VPC IP capacity** per subnet

Quotas can be requested upward; some are hard caps. Plan for:
- Peak traffic: Black Friday, product launches, viral moments
- Capacity migrations: bumping max-instances on Cloud Run, adding GKE node pool capacity, scaling Spanner PU
- Region capacity: GCP can run out of capacity for specific machine types in specific regions during demand spikes

### Active Assist / Recommender

Active Assist surfaces capacity recommendations:
- **Idle resource recommender**: VMs at <5% CPU; over-provisioned databases
- **Right-sizing recommender**: VM size suggestions based on observed usage
- **CUD recommender**: which workloads are stable enough for commitment
- **IAM Recommender**: roles to revoke (unused)
- **Cost recommender**: aggregate cost recommendations

```bash
gcloud recommender recommendations list \
  --project=proj \
  --recommender=google.compute.instance.IdleResourceRecommender \
  --location=us-central1-a
```

## Cost observability for SRE

SRE owns cost in many orgs. Tooling:
- **Billing export to BigQuery** — required from day one
- **FinOps Hub** — unified dashboard
- **Labels everywhere** (`team`, `env`, `service`, `cost-center`) for attribution
- **Budgets + alerts** — Cloud Billing budget alerts via Pub/Sub → Cloud Function → Slack / PagerDuty
- **Reserved capacity** — CUDs for steady workloads, monitor utilization

```sql
-- Top cost drivers last 30 days
SELECT
  service.description AS service,
  SUM(cost) AS total_cost,
  SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c), 0)) AS credits,
  SUM(cost) + SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c), 0)) AS net_cost
FROM `proj.billing_export.gcp_billing_export_v1_XXXXXX_XXXXXX_XXXXXX`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY service
ORDER BY net_cost DESC
LIMIT 20;
```

## Anti-patterns

- **CPU/memory/disk threshold alerts as P0** — cause-based, alert fatigue; alert on user-visible symptoms (SLO burn, error rate, latency p99)
- **No SLO definition** — you can't manage what you don't measure
- **SLO target chosen aspirationally** — 99.99% on a single-region service is impossible
- **No runbook linked from alerts** — on-call wakes up, has to figure it out from scratch
- **Trace Sinks for new builds** — deprecated; use OTLP + Telemetry API
- **Legacy Monitoring Agent / Logging Agent on new VMs** — use Ops Agent
- **Log export to BigQuery dataset instead of Log Analytics** — extra cost, extra pipeline; Log Analytics queries in-place
- **MQL-only dashboards in 2026** — PromQL is the cross-platform path
- **No structured logging** — `print()` and `console.log` produce blob logs; structured JSON enables Log Analytics
- **No notification channel taxonomy** — everything is "default" channel; alert fatigue
- **No blameless post-mortem culture** — repeat incidents; toxic on-call
- **Profiler off in prod** — overhead myth; <1% in 2026, real value in diagnosis

## Tooling specifics

| Tool | Purpose |
|------|---------|
| **Ops Agent** | Telemetry collector for Compute Engine / VM workloads |
| **Managed OpenTelemetry for GKE** | Auto-scaled OTel Collector for K8s |
| **OpenTelemetry SDKs** | Code-side instrumentation in every supported language |
| **`gcloud monitoring`** | Alert policies, dashboards, channels via CLI |
| **`gcloud logging`** | Sinks, exclusions, log-based metrics |
| **Terraform `google_monitoring_*` resources** | IaC for SLOs, alerts, dashboards |
| **Cloud SDK Python / Go libraries** | Programmatic alert / SLO automation |
| **PagerDuty / Opsgenie / incident.io** | On-call routing |
| **Grafana on Cloud Monitoring** | Cross-platform dashboards using PromQL (when teams have Grafana investment) |

## Verification checklist for sre-engineer on GCP

- [ ] SLOs defined per user-facing service with realistic targets and 28-day rolling windows
- [ ] Fast-burn + slow-burn burn-rate alerts per SLO; not threshold alerts on cause metrics
- [ ] OpenTelemetry instrumentation via Ops Agent (Compute Engine) / Managed OTel (GKE) / OTel sidecar (Cloud Run) / OTLP direct (Cloud Run functions)
- [ ] Structured logging with `json_fields` + trace correlation
- [ ] Log Analytics queries for ad-hoc analysis; not export-to-BigQuery for log queries
- [ ] Log-based metrics for pattern-based alerting
- [ ] Runbook linked from every alert policy; runbook in git
- [ ] Notification channel taxonomy: P0 to phone, P1 to Slack, P2 to ticket, P3 to digest
- [ ] Post-mortem template + blameless culture established
- [ ] Cloud Profiler enabled in prod for supported languages
- [ ] Error Reporting integrated; exception logging follows the structured pattern
- [ ] Billing export to BigQuery + FinOps Hub configured; labels enforced for attribution
- [ ] Capacity headroom monitored; quota usage alerts for soft limits
- [ ] Active Assist / Recommender output reviewed weekly
- [ ] No legacy paths: no Monitoring Agent / Logging Agent on new VMs; no Trace Sinks; no MQL-only dashboards
- [ ] Currency check: features verified against release notes; Telemetry API migration plan if pre-2026 deployment

## Integration with always-on protocols

- **TDD on observability**: SLOs are code (Terraform `google_monitoring_slo`); test them. Verify the SLO produces expected burn-rate alerts on a synthetic outage.
- **Verification**: alert changes verified by triggering the alert (synthetic load, error injection, fault drill). "I added an alert" without proof it fires is not verification.
- **Debugging**: incident diagnosis follows golden signals (RED method: rate, errors, duration). Cloud Trace for latency, Cloud Logging Log Analytics for errors, Cloud Profiler for resource hotspots. Don't mash on dashboards; query intentionally.
- **Plan execution**: SLO authoring per service is one plan task per service; verify each before moving on.
- **Branch safety**: monitoring config changes go through PR review with `terraform plan` artifact; never apply directly. Misconfigured alerts wake everyone for nothing.
- **Review**: post-mortem action items are tracked to completion in the next review cycle. Action items that don't get done eat your reliability over time.
