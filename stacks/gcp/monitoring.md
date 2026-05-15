---
title: Cloud Monitoring
description: GCP metrics, dashboards, alerts, SLOs — OTLP ingestion GA, PromQL + MQL, SLO service for burn-rate alerting. Pairs with Ops Agent / Managed OTel.
product:
  name: Cloud Monitoring
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/monitoring/docs
  notes: "OTLP ingestion GA; MQL + PromQL both supported; SLO service mature; alert channels integrate PagerDuty / Opsgenie / incident.io natively."
---

## What it is

Cloud Monitoring is GCP's metrics + dashboards + alerts + SLOs surface. Ingests metrics from every GCP service automatically; accepts custom metrics via OTLP, the Monitoring API, and the legacy custom-metrics path. Pair with [Cloud Logging](/stacks/gcp/logging/) for log-based metrics and [Cloud Trace](/stacks/gcp/monitoring/) for trace-based latency analysis.

Authoritative reference: [cloud.google.com/monitoring/docs](https://cloud.google.com/monitoring/docs).

## When to use

Cloud Monitoring is universal — every GCP service writes metrics here. The decisions:

- **OTLP ingestion** vs Monitoring API — OTLP for any new code; cross-platform consistency
- **PromQL** vs **MQL** — PromQL is the path forward for cross-platform consistency; MQL exists for back-compat
- **SLO service** vs **threshold alerts** — SLO burn-rate alerts page on user-visible symptoms; threshold alerts cause-based alert fatigue
- **Notification channels**: PagerDuty / Opsgenie / incident.io for P0; Slack for P1; email for P2

## 2025-2026 currency anchors

- **OTLP ingestion GA** — Cloud Monitoring accepts OTLP metrics directly; SDK target for new code.
- **PromQL** supported alongside MQL; PromQL is the cross-platform path forward.
- **SLO service** matured — `google_monitoring_slo` Terraform resource, burn-rate alerts, error-budget tracking, fast-burn / slow-burn separation.
- **PagerDuty / Opsgenie / incident.io** are first-party alert channels.

## Patterns

### SLO with burn-rate alerts (Terraform)

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
```

Pair with **fast-burn** (14.4 over 1h) and **slow-burn** (6 over 6h) alert policies. See [sre-engineer on GCP](/stacks/gcp/sre-engineer/) for the full burn-rate intuition + recipe.

### Alert design — symptoms, not causes

| Tier | When | Channel |
|------|------|---------|
| **P0 — Page** | SLO fast burn, total outage, security incident | PagerDuty / Opsgenie / incident.io |
| **P1 — Slack alert** | SLO slow burn, partial degradation | Slack |
| **P2 — Ticket** | Background SLO trend, cost anomaly | Jira / Linear |
| **P3 — Dashboard / digest** | Trend, capacity, suggestions | Daily email |

### Notification channels

```bash
gcloud monitoring channels create \
  --display-name="PagerDuty Critical" \
  --type=pagerduty \
  --channel-labels=service_key=YOUR_PD_INTEGRATION_KEY
```

## Anti-patterns

- **CPU/memory/disk threshold alerts as P0** — cause-based; alert fatigue. Alert on user-visible symptoms (SLO burn, error rate, latency p99).
- **No SLO definition** — you can't manage what you don't measure.
- **SLO target chosen aspirationally** — 99.99% on a single-region service is impossible.
- **No runbook linked from alerts** — on-call wakes up, has to figure it out from scratch.
- **MQL-only dashboards in 2026** — PromQL is the cross-platform path.

## Gotchas

- **Cardinality limits** on labels — high-cardinality labels (per-user, per-tenant) blow up metric storage.
- **Alert latency** is a function of evaluation window; configure carefully.
- **Notification deduplication** can be subtle; verify alert policies don't generate duplicate pages.

## Cross-references

- Related: [Cloud Logging](/stacks/gcp/logging/), [Cloud Run](/stacks/gcp/cloud-run/), [GKE](/stacks/gcp/gke/)
- Roles: [sre-engineer on GCP](/stacks/gcp/sre-engineer/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/monitoring/docs](https://cloud.google.com/monitoring/docs)
