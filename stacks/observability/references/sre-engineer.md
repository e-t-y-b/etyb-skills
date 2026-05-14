---
role: sre-engineer
stack: observability
last_verified_on: "2026-05-14"
---

# Observability Overlay — sre-engineer

You are sre-engineer on an observability engagement. This is your deepest surface in the stack pack — vendor selection, SLO instrumentation, alerting topology, and the cross-vendor cost/cardinality discipline live here. You bring the **platform-neutral SRE principles** (RED method, USE method, error-budget math, multi-window burn rates, golden signals, incident response choreography) from the base `sre-engineer` reference; this overlay teaches you **what each vendor expects in 2026** and how to apply the principles on each platform without making the canonical mistakes.

**Currency:** verified for 2026-Q2 across OTel semconv 1.28+, Prometheus 3.4, Grafana 11.x, Datadog Agent 7.x, NR agents 2026.x, Splunk Observability Cloud post-Cisco, Honeycomb Refinery 2.x, Sentry SDKs 8.x, Dynatrace OneAgent 1.300+. If recommending a feature, agent flag, or pricing tier shipped in 2025-2026, name the version or release window.

## What changed in 2025-2026 that older training data misses

The big platform resets (full briefing in the SKILL.md). Critical-for-SRE deltas:

- **OTel-first SLO instrumentation.** SLI emission via OTel metrics + traces, vendor receives OTLP. Don't recommend hand-coded `dogstatsd` or `newrelic.recordCustomEvent` for new SLOs unless there's a parity reason.
- **Prometheus 3.x changes the patterns you teach.** Native histograms over classic histograms for latency SLOs. OTLP-direct ingest, no exporter sidecar. UTF-8 names so `http.server.request.duration` works without translation. Recording-rule patterns from 2023 still work but waste cardinality.
- **Multi-window burn-rate alerts are the standard, not a fancy option.** Static-threshold alerts on error rate are an anti-pattern in 2026 for tier-1 services. Sloth (CLI), Pyrra (CLI + UI), and Nobl9 (SaaS, multi-backend) generate them. Hand-rolled is fine if you understand the math.
- **Datadog Watchdog AI, NR Applied Intelligence, Dynatrace Davis AI** are not optional add-ons — they're the default. Disable manual threshold alerts where AIOps anomaly detection is producing equivalent precision; you'll cut alert volume 60-80% on infrastructure signals.
- **Honeycomb Refinery for tail-based sampling** is mainstream for trace volumes above 10K events/sec. Random head sampling is wasteful.
- **Sentry dynamic sampling** for performance traces. Hand-tuned `tracesSampleRate` per service is an anti-pattern.
- **Grafana Alloy replaces Grafana Agent** (Agent EOL Nov 2025). Migrate.
- **Splunk Observability Cloud is the strategic Splunk forward bet** post-Cisco acquisition (March 2024). Splunk Enterprise remains the SIEM/security-analytics surface, not the SRE telemetry stack.
- **LLM Observability is a distinct surface** with its own SLOs (token-spend SLO, completion-latency SLO, hallucination-rate SLO with evaluators). Don't treat LLM endpoints as a regular HTTP service — the SLI shape differs.

If you're proposing static-threshold infra alerts as the primary alerting strategy, hand-rolled classic histograms on a Prometheus 3.x cluster, `grafana-agent` instead of Alloy, or 100% trace sampling without Refinery — your training is stale.

## Vendor decision framework — the SRE-specific lens

The SKILL.md gives a generalized framework. As an SRE, you have an additional dimension: **operational ownership**. Is this platform self-hosted (you operate the storage, the queriers, the alertmanager) or managed (someone else operates them)? That ownership question dominates Day-2 cost and reliability of the observability stack itself.

| Concern | Self-hosted (Prometheus + Grafana + Loki + Tempo) | Grafana Cloud | Datadog | New Relic | Dynatrace | Splunk Observability |
|---------|---------------------------------------------------|---------------|---------|-----------|-----------|----------------------|
| **Who runs the storage?** | You | Grafana | Datadog | New Relic | Dynatrace | Splunk |
| **Who manages cardinality limits?** | You (TSDB head_series, label_limit) | Grafana (per-tier active series quota) | Datadog (custom metrics quota + per-metric tags exclude) | New Relic (per-GB ingest) | Dynatrace (per-host DDU + cardinality keys) | Splunk (per-MTS + index volume) |
| **Day-2 ops effort** | High (alerts, on-call for the observability stack itself) | Low (Grafana on-call for storage) | Very low | Very low | Very low | Medium (still some self-hosted Splunk Enterprise common) |
| **Bill predictability** | High (infra cost only) | High (per-active-series) | **Low — biggest surprise risk in observability** | Medium (per-GB, but per-user licenses surprise at scale) | Medium (GiB-hour DDU model is complex) | Medium (per-MTS plus index volume) |
| **K8s-native depth** | Excellent (Prometheus Operator + ServiceMonitor) | Excellent (inherits ecosystem) | Good (Agent v7 K8s integration) | Good (NR K8s + Pixie) | Good (OneAgent K8s operator) | Good (OpenTelemetry-first since SignalFx era) |
| **OTel first-class?** | Yes (Prometheus 3.x native OTLP) | Yes (Alloy + Mimir/Loki/Tempo OTLP) | Yes (Agent v7 OTLP receiver) | Yes (native OTLP) | Yes (native OTLP) | Yes (SignalFx Smart Agent → OTel transition complete) |
| **Long-term storage** | Object storage (S3/GCS) via Mimir/Thanos | 13-month default Pro | 15-day default, 15-month max | 13-month default | 35-day default, 10-year max | Configurable; Federated S3 Search GA |
| **AIOps / anomaly detection** | Grafana ML, Sift (less mature) | Sift + Grafana ML | Watchdog AI + Bits AI | Applied Intelligence | **Davis AI (most mature)** | ITSI Predictive Analytics |
| **Best-fit org** | K8s-native, SRE-rich, cost-sensitive | K8s-native, want managed | Want unified single pane, can manage cost | Want per-GB pricing predictability | Want causal AI root-cause | Compliance/audit-heavy, security blend |

### How to actually pick

1. **What's the SRE team headcount?** Below 3 dedicated SREs, **don't self-host Mimir/Loki/Tempo**. The operational burden of a 3-replica Prometheus + Mimir cluster + Loki cluster + Tempo cluster + Alertmanager cluster + Grafana cluster exceeds the budget savings unless you have specific cost or compliance reasons.
2. **What's the existing language ecosystem?** Java + .NET + Python — every vendor handles. Erlang/Elixir, OCaml, Crystal, Zig — OTel SDKs are your best/only option; pick a vendor with strong OTLP ingest (Grafana, Honeycomb, Datadog).
3. **Are you instrumenting for security/audit (SIEM) or for performance (APM)?** Different stacks. Splunk Enterprise + Splunk ES for SIEM; Datadog/NR/Dynatrace/Grafana for APM. Don't try to make Datadog the SIEM (it can, but the licensing model doesn't reward it).
4. **What's the regulatory profile?** HIPAA → BAA-signing vendors only. PCI → no card PAN in logs/traces (Sensitive Data Scanner toggle required). FedRAMP → Datadog Gov, Splunk Gov, AWS-native (CloudWatch + AMP). Dynatrace, New Relic FedRAMP Moderate via SaaS US. Grafana Cloud has FedRAMP Moderate.
5. **What's the cardinality shape?** High-cardinality services (e-commerce checkout funnels, B2B SaaS with per-customer attribution, ad-tech) push hard against metrics-based platforms. Use **Honeycomb** or trace-first observability (Grafana Tempo with TraceQL metrics) for these. Datadog and NR will work but charge for it.
6. **How important is causal AI root-cause?** If the team is small and triage matters more than dashboards, **Dynatrace Davis AI** is the most mature; Datadog Bits AI is catching up; New Relic AI is solid; Grafana Sift is functional. OSS has nothing equivalent.

### Anti-patterns in vendor selection

- **"We'll use Datadog for everything"** at <10 engineers without setting up Usage Attribution monitoring on Day 1 — bill surprise within 90 days, guaranteed.
- **"We'll self-host the LGTM stack to save money"** at <3 dedicated SREs — the SRE-hours cost exceeds the SaaS bill.
- **"We'll use Grafana for dashboards and Datadog for alerts"** — splits the source of truth, halves the value of either.
- **"We'll instrument with `dd-trace` first, migrate to OTel later"** — the migration is 10x harder than starting OTel. Always OTel-first.
- **"We'll skip RUM, server-side is enough"** at a consumer-facing product — you'll miss third-party-JS failures, CDN outages, mobile-network slow rendering. Add at least Sentry Replay or Datadog RUM lite tier.
- **"Splunk is for security only"** — historically true, but Splunk Observability Cloud (ex-SignalFx) is a real APM/metrics/logs platform; don't dismiss it on legacy reputation.

## SLO instrumentation across vendors

The SLO theory (SLI vs SLO vs SLA, error-budget math, multi-window multi-burn-rate alerting) stays in the base `sre-engineer/references/monitoring-specialist.md`. This section is **how to implement SLOs on each vendor in 2026**.

### Pattern: SLI from OTel metrics, computed at the vendor

Greenfield 2026 pattern. Application emits OTel metrics (`http.server.request.duration` histogram, `http.server.request.count` counter, both with `http.response.status_code` attribute). Collector forwards over OTLP to vendor. SLI computation lives in the vendor's query language.

```yaml
# OTel SDK config — Node.js example
# meter created with the OTel SDK; semconv 1.28+ attribute names
const httpServerDuration = meter.createHistogram('http.server.request.duration', {
  description: 'Duration of HTTP server requests',
  unit: 's',
  advice: {
    explicitBucketBoundaries: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  },
});

// On each request:
httpServerDuration.record(durationSeconds, {
  'http.request.method': req.method,
  'http.response.status_code': res.statusCode,
  'http.route': req.route?.path || 'unknown',
  'service.name': process.env.OTEL_SERVICE_NAME,
});
```

Now the same instrumentation produces SLIs in each vendor:

#### Prometheus / Grafana Mimir

```promql
# Availability SLI (success ratio) over 5m
sum(rate(http_server_request_duration_count{
  http_response_status_code!~"5..",
  service_name="checkout-api"
}[5m]))
/
sum(rate(http_server_request_duration_count{
  service_name="checkout-api"
}[5m]))

# Latency SLI (p99 < 300ms) over 5m using native histogram
histogram_quantile(0.99,
  sum(rate(http_server_request_duration[5m])) by (le)
) < 0.3
```

#### Datadog

```
# Availability SLI — Datadog metric query
default_zero(
  sum:trace.http.server.request_count{service:checkout-api,!http_response_status_code:5*}.as_rate()
)
/
default_zero(
  sum:trace.http.server.request_count{service:checkout-api}.as_rate()
)

# Wrap as a Datadog SLO (monitor-based)
service-level-objective:
  name: "Checkout API Availability — 99.9%"
  type: monitor
  monitor_ids: [12345]   # availability monitor
  thresholds:
    - timeframe: 30d
      target: 99.9
      warning: 99.95
```

The Datadog **Service-Level Objectives** product takes monitor IDs or metric queries directly. Use the **time-slice SLO** type for ratio-based SLIs (introduced 2023, mature 2025). Use the **monitor-based SLO** for legacy or where you want a single monitor to drive paging *and* SLO. Use **multiple SLOs** product (2025) when one product surface needs availability + latency + freshness combined.

#### New Relic

```sql
-- Availability SLI in NRQL
SELECT
  filter(count(*), WHERE numeric(http.response.status_code) < 500) / count(*) AS availability
FROM Span
WHERE service.name = 'checkout-api'
SINCE 5 minutes ago

-- Wrap as a New Relic SLO (via NerdGraph)
mutation {
  serviceLevelCreate(
    entityGuid: "GUID",
    indicator: {
      name: "checkout-availability",
      events: {
        validEvents: { from: "Span", where: "service.name = 'checkout-api'" },
        goodEvents: { from: "Span", where: "service.name = 'checkout-api' AND numeric(http.response.status_code) < 500" }
      },
      objectives: [{ target: 99.9, timeWindow: { rolling: { count: 30, unit: DAY } } }]
    }
  )
}
```

New Relic SLOs use the events-based model (good events / valid events). The NerdGraph API is the source of truth — use Terraform `newrelic_service_level` provider for IaC. NR's **Errors Inbox** correlates SLO-burning errors to deploys; chain SLO breach alerts into the Errors Inbox triage workflow.

#### Honeycomb

```
# Honeycomb SLI definition — defined per service in the UI or via Terraform
sli:
  name: "checkout-api-availability"
  alias: "checkout_availability"
  description: "Successful checkout requests"
  query:
    # SLI is a derived column returning boolean (or null to exclude)
    expression: |
      IF(EQUALS($service.name, "checkout-api"),
        IF(LT($http.response.status_code, 500), TRUE, FALSE),
        NULL
      )

slo:
  name: "Checkout Availability"
  sli: "checkout_availability"
  target_per_million: 999000   # 99.9%
  time_period_days: 30
```

Honeycomb's SLO product uses **derived columns** for SLI logic (events return TRUE for "good", FALSE for "bad", NULL to be excluded from the SLO). This is the most flexible model — any condition expressible in the Honeycomb derived-column language becomes an SLI. Use Honeycomb Terraform provider (`honeycombio/honeycombio`) for IaC. Burn-rate alerts come built-in.

#### Splunk Observability Cloud

```
# SignalFlow query for availability SLI (Splunk Observability uses SignalFlow)
A = data('http.server.request.count', filter=filter('sf_service', 'checkout-api') and filter('http.response.status_code', '5*'), rollup='rate').sum().publish()
B = data('http.server.request.count', filter=filter('sf_service', 'checkout-api'), rollup='rate').sum().publish()
availability = (B - A) / B
availability.publish('availability')
```

Splunk Observability Cloud (the ex-SignalFx surface) uses SignalFlow for SLI computation. The SLO product wraps SignalFlow into a recurring evaluation with burn-rate detectors. Splunk APM also has a separate **Service Level Tracking** view that auto-suggests SLOs from APM data — useful for first-pass; refine with custom SLIs.

#### Dynatrace

```
# Dynatrace SLO via DQL (Davis SLO product)
fetch spans
| filter dt.entity.service == "SERVICE-ABC123"
| filter k8s.cluster.name == "prod-us-east"
| summarize {
    total_requests = count(),
    failed_requests = countIf(toLong(http.response.status_code) >= 500)
  }, by: { bin(timestamp, 1m) }
| fieldsAdd availability = (total_requests - failed_requests) / total_requests
```

Dynatrace's SLO surface uses DQL (the Grail-era query language). Davis AI auto-computes burn-rate and root-cause for SLO breaches — this is Dynatrace's signature feature. Use the **Site Reliability Guardian** workflow to gate deploys on SLO health.

### Multi-window multi-burn-rate alerts — vendor-specific patterns

The principle (multi-window, multi-burn-rate, 14.4x/6x/3x/1x) is platform-neutral. Implementation differs:

| Vendor | Tooling | Notes |
|--------|---------|-------|
| **Prometheus / Mimir** | Sloth or Pyrra (generates PrometheusRule manifests) | Best DX for declarative SLOs; deploy as Kubernetes CRDs |
| **Datadog** | Native SLO product with burn-rate **monitor alerts** | UI-driven; supports time-slice SLOs (best for ratio SLIs) since 2023; configure 4 burn rates per SLO |
| **New Relic** | Native SLO product with burn-rate **conditions** | Supports rolling and calendar windows; alert conditions per burn rate via Terraform `newrelic_service_level` + `newrelic_nrql_alert_condition` |
| **Honeycomb** | Native SLO product with burn-rate alerts (default 4 levels) | Burn-rate triggers built into SLO definition; auto-configured at SLO creation |
| **Splunk Obs Cloud** | SignalFlow-based detectors per burn rate | More config required; use Terraform `splunkobservability_detector` |
| **Dynatrace** | Davis SLO with auto-burn-rate alerts via DQL | Less manual config; Davis chooses windows and rates based on SLO target |
| **Grafana Alerting** | Multi-datasource rules with PromQL/LogQL/CloudWatch queries | Use Sloth to generate, then provision into Grafana Alerting via Grafana Terraform provider |

### Pattern: SLI with high-cardinality dimensions

If your SLI is **per-customer** (e.g., "customer X's availability over their requests this month"), metrics-based SLOs blow cardinality. Two patterns:

1. **Trace-based SLOs on Honeycomb** — derived columns evaluated per event; per-customer rollups are free; aggregate over events not time series.
2. **Datadog Trace Metrics or NR Trace-based SLIs** — generate metrics from traces with limited cardinality, evaluate SLIs in the metrics layer.
3. **Customer-segmented dashboards, not SLOs** — accept that the SLO is at the service level, and customer-segmented views are dashboards for support, not paging signals.

Recommended: **trace-based SLOs for per-customer SaaS commitments**, metrics-based SLOs for service-level SLOs. Mixing — and pre-aggregating per-customer in metrics — is where bill surprises live.

## Alerting topology by vendor

### Prometheus + Alertmanager

Battle-tested, OSS, the reference implementation. Three-replica Alertmanager cluster with gossip-based deduplication, routing tree driven by labels, inhibition + grouping + silencing built-in. Use it when you control the Prometheus stack.

```yaml
# alertmanager.yml — production-grade routing
global:
  resolve_timeout: 5m

inhibit_rules:
  # Critical inhibits warning for the same alertname + service
  - source_matchers: ['severity = critical']
    target_matchers: ['severity = warning']
    equal: ['alertname', 'namespace', 'service']
  # Maintenance-window silence (set via API during deploys)

route:
  receiver: 'default-slack'
  group_by: ['alertname', 'cluster', 'namespace', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - receiver: 'pagerduty-platform'
      matchers: ['severity = critical', 'team = platform']
      group_wait: 10s
      repeat_interval: 1h
    - receiver: 'pagerduty-application'
      matchers: ['severity = critical', 'team = application']
      group_wait: 10s
      repeat_interval: 1h
    - receiver: 'slack-warnings'
      matchers: ['severity = warning']
      group_wait: 2m
      repeat_interval: 12h
    - receiver: 'email-sre'
      matchers: ['severity = info']
      group_wait: 5m
      repeat_interval: 24h

receivers:
  - name: 'pagerduty-platform'
    pagerduty_configs:
      - routing_key: '${PD_PLATFORM_KEY}'
        severity: '{{ if eq .CommonLabels.severity "critical" }}critical{{ else }}warning{{ end }}'
        details:
          runbook_url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
          dashboard_url: '{{ (index .Alerts 0).Annotations.dashboard_url }}'
        send_resolved: true
```

**Anti-patterns:**
- Single Alertmanager replica (no HA). Three replicas with `--cluster.peer` gossip is the production default.
- Missing inhibit rules — every critical alert produces five duplicate warnings, alert fatigue erupts.
- No `runbook_url` annotation — first-responder Googling for a runbook is wasted MTTR.
- Routing only by severity, not by team — every page wakes up the wrong on-call.

### Datadog Monitors + Workflows

Datadog's alerting is monitor-centric. A **monitor** evaluates a query, has thresholds, and routes notifications via `@team-name` or `@pagerduty-service` mentions in the message body.

```python
# Datadog monitor via Terraform — multi-window burn rate page
resource "datadog_monitor" "slo_burn_rate_critical" {
  name    = "[CRITICAL] Checkout SLO burn rate 14.4x"
  type    = "slo alert"
  message = <<EOF
SLO burn rate critical: 14.4x over 1h, confirmed over 5m.
@pagerduty-platform @slack-sre-alerts
Runbook: https://runbooks.example.com/slo/checkout-availability-critical
Dashboard: https://app.datadoghq.com/dashboard/abc-123
EOF
  query = "burn_rate(\"slo_id\").over(\"1h\").long_window(\"1h\").short_window(\"5m\") > 14.4"
  tags  = ["team:platform", "severity:critical", "service:checkout"]
}
```

Use Datadog **Workflows** (formerly Workflow Automation) to wire alert response: on `slo_burn_rate_critical` fire, auto-create a Jira incident, page on-call, post a Slack runbook link. Workflows are visual + JSON exportable; treat them as code via the Datadog Terraform provider (`datadog_workflow_automation`).

**Datadog-specific gotchas:**
- Monitor evaluation delay is 60-120s minimum. Don't expect <10s alert latency. For sub-minute alerting (e.g., HFT), Datadog isn't the right primary.
- The `default_zero()` and `default(metric, value)` wrappers matter — if your metric has no data points for a period, the query result is `N/A`, not zero. Untreated, the monitor stays in `No Data` state and won't fire.
- `@team` mention notifications use the Datadog teams feature (2024+). The pre-teams `@slack-channel` and `@pagerduty-integration` still work but don't auto-include team context in notifications.
- Datadog Incident Management (the product) ingests fired monitors and lets you run a structured incident response. Pair with Slack + Statuspage for the full IR lifecycle. Don't pay for Datadog Incident Management if you already have PagerDuty Incident Response or incident.io — feature overlap is high.

### New Relic Alert Conditions + Applied Intelligence

NR uses **alert conditions** (NRQL or APM-condition based) grouped into **policies** routed via **destinations** (PagerDuty, Slack, webhook, ServiceNow, Jira).

```terraform
resource "newrelic_alert_policy" "checkout" {
  name = "Checkout API — SRE"
  incident_preference = "PER_CONDITION_AND_TARGET"  # one incident per condition × target
}

resource "newrelic_nrql_alert_condition" "checkout_5xx_burn" {
  policy_id = newrelic_alert_policy.checkout.id
  name      = "Checkout 5xx burn rate critical"
  type      = "static"
  nrql {
    query = <<EOQ
SELECT
  filter(count(*), WHERE numeric(http.response.status_code) >= 500) / count(*) AS errorRatio
FROM Span
WHERE service.name = 'checkout-api'
EOQ
  }
  critical {
    operator              = "above"
    threshold             = 0.0144   # 14.4 × 0.001 (0.1% SLO budget)
    threshold_duration    = 60
    threshold_occurrences = "all"
  }
}

resource "newrelic_workflow" "checkout" {
  name = "Checkout SRE workflow"
  workflow_enabled = true
  destination_configuration {
    channel_id = newrelic_notification_channel.pagerduty.id
  }
  issues_filter {
    name = "Checkout SLO"
    type = "FILTER"
    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.checkout.id]
    }
  }
  enrichments { ... }   # add custom enrichment queries
}
```

**Applied Intelligence** (NR's AIOps) does:
- **Anomaly detection** (baseline-relative alerts; complement static-threshold for capacity signals).
- **Correlation** — groups related issues into a single incident.
- **Decision logic** — rules-based incident enrichment.

Enable Applied Intelligence on infrastructure conditions first; it cuts noise dramatically. Don't enable AI-correlation on SLO conditions — you want each burn-rate breach as its own incident, not grouped with adjacent noise.

### Splunk Observability Cloud Detectors

```python
# SignalFlow detector — multi-window burn rate
A = data('checkout.errors.rate', rollup='rate').publish(label='errors')
B = data('checkout.requests.rate', rollup='rate').publish(label='requests')
error_ratio_1h = (A.mean(over='1h') / B.mean(over='1h')).publish('error_ratio_1h')
error_ratio_5m = (A.mean(over='5m') / B.mean(over='5m')).publish('error_ratio_5m')

# Critical detector when both windows breach 14.4x burn rate
detect((error_ratio_1h > 0.0144) and (error_ratio_5m > 0.0144), mode='paired',
       auto_resolve_after='10m').publish('BURN_RATE_CRITICAL')
```

Detectors route to **integrations** (PagerDuty, Opsgenie, Slack, ServiceNow). Splunk Observability's strength is **MTS (metric time series) at scale** — billions of MTS, fast queries via the streaming SignalFlow engine. Detector evaluation is much faster than Datadog or NR (sub-minute reliable). Use for high-frequency infra alerting where DD/NR are too slow.

### Honeycomb Triggers

```yaml
# Honeycomb Trigger via Terraform — burn rate detection on SLI
resource "honeycombio_trigger" "checkout_burn_rate" {
  dataset    = "checkout-api"
  name       = "Checkout SLO burn rate 14.4x"
  description = "Pages when 14.4x burn over both 1h and 5m windows"
  query_id   = honeycombio_query.checkout_error_ratio.id
  frequency  = 60  # seconds
  alert_type = "on_change"
  threshold {
    op    = ">="
    value = 0.0144
  }
  recipient {
    type   = "pagerduty"
    target = "platform-on-call"
  }
}
```

Honeycomb triggers are simpler than Datadog/NR — they evaluate a stored query and fire on threshold. For burn-rate, build two triggers (one per window) and combine via PagerDuty event rules, OR use Honeycomb's native SLO surface which generates burn-rate alerts automatically. The native SLO product is the recommended path.

### Grafana Alerting (unified)

```yaml
# Grafana Alerting rule via Grafana Terraform provider
resource "grafana_rule_group" "checkout_slo" {
  name             = "checkout-slo"
  folder_uid       = grafana_folder.sre.uid
  interval_seconds = 60
  rule {
    name = "Checkout burn rate critical 14.4x"
    for  = "2m"
    annotations = {
      summary     = "Checkout API SLO burn rate critical"
      description = "Burn rate is {{ $value }} over 1h, confirmed over 5m"
      runbook_url = "https://runbooks.example.com/slo/checkout-availability-critical"
    }
    labels = {
      severity = "critical"
      team     = "platform"
      slo      = "checkout-availability"
    }
    data {
      ref_id = "A"
      relative_time_range { from = 3600 }   # 1h
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "slo:checkout:error_ratio_rate1h > (14.4 * 0.001)"
      })
    }
    data {
      ref_id = "B"
      relative_time_range { from = 300 }    # 5m
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "slo:checkout:error_ratio_rate5m > (14.4 * 0.001)"
      })
    }
    data {
      ref_id = "C"
      datasource_uid = "-100"   # __expr__
      model = jsonencode({
        type = "math"
        expression = "$A > 0 && $B > 0"
      })
    }
    condition = "C"
    no_data_state  = "OK"
    exec_err_state = "Alerting"
    notification_settings {
      contact_point = "pagerduty-platform"
      mute_timings  = ["maintenance-window"]
    }
  }
}
```

Grafana Alerting (unified, since Grafana 9, mature in 11+) replaces dashboard alerting and Alertmanager-driven flows for most use cases. **When to use Grafana Alerting vs Alertmanager:**
- Use Grafana Alerting when alerts span multiple data sources (Prometheus + Loki + CloudWatch in one rule).
- Use Alertmanager for Prometheus-pure setups where battle-tested routing/grouping/inhibition matters more than UI.
- Grafana Alerting can also use Alertmanager as the receiver (forward all Grafana alerts to AM for unified routing) — common hybrid.

### Dynatrace Davis SLO + Anomaly Detection

Dynatrace alerting is **Davis-AI-driven by default**. You don't define static thresholds; Davis computes adaptive baselines per service and alerts on deviations. Manual problem detection rules supplement, but are minority traffic.

```
# Dynatrace problem notification via Workflow (DQL-driven)
fetch dt.davis.events
| filter event.type == "ERROR"
| filter dt.entity.service.tags == "team:platform"
| fields event.id, event.title, dt.davis.problem.id
```

For SLOs, use the **Site Reliability Guardian** (Dynatrace 2024+) — a workflow that gates deployments on SLO health and runs auto-rollback on burn-rate breach. This is the most opinionated end-to-end SLO+deploy flow in the vendor space.

## Cardinality and cost management — vendor by vendor

This is where 80% of SRE-driven observability work lives. Each vendor has a different cost model and a different cardinality lever.

### Datadog

The cost drivers, ranked by surprise potential:
1. **Custom metrics** ($5/100 metrics over the included quota; quotas vary by Pro/Enterprise tier and include 100-200 metrics per host). A single misconfigured `kube-state-metrics` enable can add 25K+ custom metrics.
2. **Indexed log events** ($1.70/M; ingested logs are cheap, *indexing* is what costs).
3. **APM hosts** ($31/host/mo on top of infra; APM Profiling is a separate add-on).
4. **Custom metrics from APM** (DogStatsD metrics inside instrumented services count as custom metrics).
5. **CI Visibility** (per pipeline-minute).
6. **Synthetics** (per check; browser >> API).
7. **RUM** (per session).
8. **LLM Observability** (per LLM call).

Controls:
- **Tag exclusion at integration level:** Each Datadog integration (e.g., `kubernetes_state.dd-agent`) lets you specify which tags to keep. Set this *before* the integration runs in production. Example: keep `cluster`, `namespace`, `deployment`; exclude `pod_id` (unbounded).
- **`dogstatsd_metrics_exclude`:** Agent config to drop metrics matching patterns before they reach Datadog.
- **Log Pipelines + Archives:** Route logs through Datadog Log Pipelines, drop non-investigation logs (audit logs, debug logs) to S3/GCS archives via the **Archive Forwarding** feature. Re-hydrate when needed. Saves 80-90% on indexed log cost.
- **Trace Sampling at the Agent:** The Agent's adaptive sampler retains 100% of error traces + p95 latency outliers + 1-10% baseline. Don't override at SDK with high `sample_rate` values.
- **Sensitive Data Scanner (SDS)** dual-use: PII scrubbing + reducing log indexability.
- **Usage Attribution dashboard:** Built-in. Pin it to every SRE team's home dashboard. Weekly review.

### New Relic

Cost driver: **GB ingested per month**. Predictable per-GB pricing makes NR less surprising than Datadog *until* per-user licenses + Compute Units (CU, for ML/AI features) kick in at scale.

Controls:
- **Drop filters at the Pipeline:** NR pipeline rules (similar to Datadog Log Pipelines) drop matching logs/events before storage.
- **Sampling at agent:** APM agents support adaptive sampling; configurable cap on transactions/min.
- **Custom event retention policies:** Per-event-type retention to keep your most expensive event types short-lived.
- **NRDB query optimization:** Aggregate queries cost CU; use **dashboards backed by NRQL Drop Rules** to prevent expensive queries from running 24/7.

### Grafana Cloud

Cost driver: **active series for metrics, GB for logs/traces/profiles**. Per-series pricing is the most predictable in the industry.

Controls:
- **Adaptive Metrics (2024+):** Grafana Cloud feature that auto-detects unused series and offers to drop them. Saves 30-60% on series count in mature installs.
- **Loki structured metadata:** Use structured metadata (key-value pairs on log lines) instead of labels for fields that don't need to drive label-based queries. Drops cardinality dramatically — labels create streams; structured metadata doesn't.
- **Tempo metrics generator:** Generates RED metrics from traces — reduces the need for redundant application-side metrics.
- **95th-percentile billing:** Top 5% of usage time is excluded; spikes don't bill.

### Prometheus self-hosted

Cost driver: **storage, memory, query time**. No license cost.

Controls:
- **`metric_relabel_configs`** at scrape time — drop metrics and labels before they hit the TSDB.
- **`sample_limit` per scrape target** — kill runaway exporters before they OOM Prometheus.
- **Recording rules** — pre-aggregate high-cardinality queries into low-cardinality series for dashboards.
- **Federation hierarchy** — local Prometheus aggregates and exposes; global Prometheus federates only aggregates.
- **Remote write to long-term storage** — keep local retention small (2-7 days), push to Mimir/Thanos/VictoriaMetrics for long-term.
- **Mimir's per-tenant limits** — `max_global_series_per_tenant`, `max_label_value_length`, `max_series_per_query`.

### Honeycomb

Cost driver: **events per month**. Events are richer than metrics, so $/event > $/metric, but the cardinality model is event-based (no time series, no label limits) so high-cardinality is cheap.

Controls:
- **Refinery (tail-based sampling):** Drop low-value traces (200s, fast, no errors) at high rates; keep all errors and slow traces.
- **Sampling rules:** Define per-service per-error-class sampling rates.
- **Markers:** Annotate events with deploy markers; lets you filter by deploy without adding cardinality to events.

Honeycomb's cost model rewards correct sampling more than other vendors. Get Refinery right and Honeycomb's per-engineer cost drops sharply.

### Splunk Observability Cloud

Cost driver: **metric time series (MTS) for metrics, GB for logs**.

Controls:
- **MTS-aware metricsets:** Tag whitelist per integration.
- **Resource-Aware Sampling** for APM traces — automatic, no-config.
- **Federated Search to S3:** Keep cold logs in S3, query without ingesting into Splunk Cloud.

### Sentry

Cost driver: **events for errors, spans for performance, replays for RUM, attachments**.

Controls:
- **Dynamic Sampling:** Sentry decides per-environment, balances quota.
- **Inbound Filters:** Drop noise events (uncaught browser exceptions from extensions, etc.) before quota.
- **Rate Limits:** Per-project per-DSN rate limits.
- **Issue Owners:** Routes notifications without bloating the issue list with unowned issues.

## Trace sampling strategy in 2026

Sampling is where SRE intuition pays back hardest. The wrong sampling rate burns money or hides bugs.

### Head sampling vs tail sampling vs probabilistic vs deterministic

| Type | Where | Cost | What it keeps |
|------|-------|------|---------------|
| **Head (SDK)** | App SDK at trace start | Lowest CPU | Random subset, decided before knowing trace outcome |
| **Tail (Collector / Refinery)** | After trace completes | Higher CPU (Collector must hold trace) | Deterministic on attributes (e.g., 100% of errors) |
| **Probabilistic** | SDK or Collector | Uniform | Random N% |
| **Parent-based** | SDK | Lowest CPU | Honors parent's decision via traceparent header |
| **Dynamic (vendor)** | Vendor backend | Highest CPU (vendor-side) | Vendor-chosen, balances quota |

### Recommended 2026 default

For most services:
1. **OTel SDK:** `parentbased_traceidratio` with ratio 1.0 at edge services, propagate downstream.
2. **OTel Collector at the Gateway tier:** **Tail-sampling processor** with policies:
   - Keep 100% of traces with errors (`status.code = ERROR`).
   - Keep 100% of traces with high latency (`duration > p99 threshold`).
   - Keep 1-10% of everything else (probabilistic).
   - Apply per-service rate limits to prevent any single service from dominating the sample.

```yaml
# OTel Collector tail-sampling processor
processors:
  tail_sampling:
    decision_wait: 10s
    num_traces: 100000
    expected_new_traces_per_sec: 1000
    policies:
      - name: keep-errors
        type: status_code
        status_code: { status_codes: [ERROR] }
      - name: keep-slow
        type: latency
        latency: { threshold_ms: 1000 }
      - name: rate-limit
        type: rate_limiting
        rate_limiting: { spans_per_second: 100 }
      - name: baseline
        type: probabilistic
        probabilistic: { sampling_percentage: 5 }
```

For Honeycomb specifically, run **Refinery** instead of the OTel tail-sampling processor — Refinery is purpose-built for Honeycomb's event model and uses memory more efficiently for high-volume tail sampling.

For Datadog, **rely on the Agent's adaptive sampler** unless you have a specific reason to override. The Agent samples at the span level and is the recommended path.

For LLM/agent traces: **keep 100%**. LLM traces are low-volume and high-value; sampling defeats the purpose.

## Incident response integration

Page → ack → mitigate → resolve → postmortem. The observability platform's job is to drive the first two stages.

### PagerDuty Events API v2 — the integration target

Every observability platform sends events to PagerDuty via the Events API v2. The payload should include:

```json
{
  "routing_key": "abc-123-pd-key",
  "event_action": "trigger",
  "dedup_key": "checkout-api:slo-burn-rate-critical",
  "payload": {
    "summary": "Checkout API SLO burn rate critical (14.4x)",
    "source": "datadog",
    "severity": "critical",
    "custom_details": {
      "runbook_url": "https://runbooks.example.com/slo/checkout-availability-critical",
      "dashboard_url": "https://app.datadoghq.com/dashboard/abc-123",
      "monitor_id": "12345",
      "slo_id": "slo-checkout-availability",
      "current_burn_rate": 14.4,
      "error_budget_remaining": "5%"
    }
  }
}
```

`dedup_key` is the most important field — it controls whether multiple alerts collapse into one incident or proliferate as separate. Use a deterministic dedup_key per (service × alert-class).

### Opsgenie — increasingly being deprecated

Atlassian announced Opsgenie deprecation in 2024 with a 5-year sunset (mid-2029). New 2026 installs: prefer PagerDuty, incident.io, FireHydrant, or Rootly. Migrate existing Opsgenie to one of those within the next 2 years.

### incident.io / FireHydrant / Rootly — the modern incident-response layer

These platforms sit *above* PagerDuty (PagerDuty for page-out, these for incident orchestration). They:
- Auto-create a Slack channel and incident document.
- Run a structured response (incident commander, scribe, comms lead).
- Auto-update statuspage.
- Generate postmortem templates.

Connect via PagerDuty webhook or directly to the observability platform (Datadog, NR, Grafana Cloud all have native integrations).

### Datadog Incident Management

Optional product (separate billing). Provides incident timeline, action items, postmortem templates inside Datadog. Good if you're already in Datadog and don't want a separate IR tool. Skip if you have incident.io / FireHydrant — overlap is high.

## Status pages

Statuspage.io (Atlassian), Better Stack Status Pages, Instatus, Cachet (OSS). Drive from your monitoring:
- Auto-update components based on SLO burn-rate alert state (e.g., `availability < 99.5%` = "degraded").
- Manual override for planned maintenance.
- Customer-subscribe to component updates via email/SMS/RSS.

Pattern: **the SLO is the source of truth, the status page reflects it**. Don't update status page manually during incidents; wire it to the SLO state. Manual updates only for planned maintenance windows.

## Dashboard discipline

Dashboard principles are platform-neutral (see base `monitoring-specialist.md`). Vendor-specific dashboard gotchas:

### Grafana
- Dashboard-as-code via **grafonnet** (Jsonnet) or Grafana Terraform provider. Pick one repo-wide.
- Use **library panels** for reused components (SLO summary, recent deploys).
- Set `editable = false` in IaC-managed dashboards to prevent UI drift.
- Use **scenes** (Grafana 11+, replaces dashboards-as-code legacy patterns) for new dashboards — better data-flow primitives.

### Datadog
- Dashboard-as-code via Datadog Terraform provider (`datadog_dashboard_json`) or `datadog-cli` (`datadog dashboards import-from-json`).
- Use **template variables** for service/env/tier (every dashboard should be parameterized).
- **Widget chaining via context links** lets you click from a panel into the related dashboard/log/trace view with context preserved.
- Datadog **Service Catalog** auto-generates a service overview dashboard from APM data — start with that, customize.

### New Relic
- Dashboard-as-code via Terraform `newrelic_one_dashboard` or via the **NerdGraph** API.
- NRQL `FACET` clause is the equivalent of `BY` in PromQL — be aware that FACET on high-cardinality fields hits compute units.

### Honeycomb
- Boards-as-code via Terraform `honeycombio_board`.
- Honeycomb Boards are different from Grafana dashboards — they're **collections of saved queries**, not pre-laid-out panels. Treat them as query bookmarks.

### Splunk
- Dashboard Studio (the modern Splunk dashboard engine) uses JSON-based dashboard definitions.
- ITSI provides higher-level service health views.

## Synthetic monitoring

The platform choice (Datadog Synthetics, Grafana Cloud Synthetic, Checkly, Pingdom, AWS CloudWatch Synthetics) matters less than the **discipline**:
1. **Run from outside your VPC** — caught DNS, CDN, ISP, TLS issues.
2. **At least 3 geographic locations** for tier-1 endpoints.
3. **Multi-step user journeys**, not just `GET /health`. Test login → search → checkout.
4. **Alert on degradation, not just failure** — checks slower than baseline by 2-3x are worth a ticket.
5. **Integrate with deploys** — a synthetic regression should block the deploy or auto-rollback.

```typescript
// Checkly TypeScript browser check
import { test, expect } from '@playwright/test';

test('checkout flow completes successfully', async ({ page }) => {
  await page.goto('https://shop.example.com');
  await page.click('[data-testid="product-card"]');
  await page.click('[data-testid="add-to-cart"]');
  await page.click('[data-testid="checkout-button"]');
  await page.fill('[data-testid="email"]', 'monitor@example.com');
  await page.click('[data-testid="continue"]');
  // ... full checkout flow
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible({ timeout: 30000 });
});
```

Checkly's strength: **monitoring as code** via TypeScript + Playwright + Terraform. Grafana Synthetic's strength: **k6 scripts** + global probe network. Datadog Synthetics' strength: deep integration with the rest of Datadog (one-click correlation from synthetic failure to APM trace to error).

## RUM (Real User Monitoring)

| Vendor | RUM SDK | Strength | Trade-off |
|--------|---------|----------|-----------|
| **Datadog RUM** | Browser + Mobile (iOS, Android, React Native, Flutter) | Deepest integration with APM (one-click RUM → trace) | Per-session pricing; expensive at consumer scale |
| **New Relic Browser** | Browser SDK | Reliable, mature, NRQL-queryable | Mobile is a separate product |
| **Sentry Replay** | Browser session replay + error correlation | Replay video is unique — see exactly what the user saw | Mobile replay is newer |
| **Grafana Faro** | Web SDK | OSS + OTel-compatible | Newer; less mature than DD/NR |
| **Dynatrace RUM** | Browser + Mobile | Davis AI for RUM root-cause | Tied to Dynatrace ecosystem |
| **Splunk RUM** | Browser + Mobile | Deep correlation with Splunk APM | Smaller market share, smaller community |

Pattern: **RUM is the user-side SLI**. Server-side latency p99 of 300ms can correspond to user-side LCP of 4s due to network, CDN, JS bundle size, or render blocking. Pair server-side and RUM SLOs.

## Profiling

Continuous profiling went mainstream in 2024-2025. The signal is per-second CPU samples and memory allocations, aggregated.

| Vendor | Profiling product | Format | Strength |
|--------|-------------------|--------|----------|
| **Datadog Continuous Profiling** | dd-trace SDK integration | Datadog format | Best in-app integration; correlates profile to trace span |
| **Grafana Pyroscope** | OSS + Grafana Cloud Profiles | Pyroscope native or OTel Profile | OSS, multi-format ingest |
| **New Relic Profiling** | NR agent integration or Pixie | NR format | Pixie's eBPF profiling is unique — no SDK changes needed |
| **Splunk APM Profiling** | Splunk APM SDK | Splunk APM native | Tied to APM trace context |
| **Dynatrace** | OneAgent | Dynatrace native | Causal AI on profiles |
| **OTel Profiles** | OTel SDKs (Go, Java first) | OTel pprof-based format | Cross-vendor portable; landing 2025-2026 |

Use profiling when: CPU-bound regression, memory-leak hunting, GC tuning, hot-loop identification. Not useful for I/O-bound services — use APM tracing for those.

## LLM Observability — the new surface

LLM endpoints are observability-different. The SLI shape:

- **Availability** (model endpoint up): 5xx / total. Same as HTTP.
- **Latency** (time to first token, time to completion): different than HTTP because **streaming responses** are common. Two SLIs: TTFT and TTC.
- **Token spend SLO**: tokens/request and $/request as observable metrics. Cost is the first-class SLI.
- **Quality SLO**: evaluator-driven. % of responses passing a hallucination check, a tool-call success check, a moderation check. Async; not real-time pagers.
- **Tool-call success rate** (for agents): % of tool invocations that returned the expected structure.

OTel GenAI semantic conventions (semconv 1.30-1.32):
- `gen_ai.system` — e.g., `openai`, `anthropic`, `bedrock`.
- `gen_ai.request.model` — e.g., `claude-3-5-sonnet`.
- `gen_ai.request.temperature`, `gen_ai.request.top_p`, etc.
- `gen_ai.response.id`, `gen_ai.response.finish_reasons`.
- `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`.

Vendor surfaces:
- **Datadog LLM Observability** (GA 2024) — ingests OTel GenAI natively; provides evaluators, prompt inspection, cost analytics.
- **New Relic AI Monitoring** — similar surface; native + OTel.
- **Honeycomb AI insights** — uses Honeycomb's event model for LLM spans.
- **Langfuse** (OSS) — purpose-built LLM tracing; OTel-compatible.
- **LangSmith** — LangChain's tracing layer; OTel-compatible.
- **Helicone** (OSS) — proxy-based instrumentation, simple.
- **Sentry AI Spans** — basic LLM call instrumentation as Performance spans.

For 2026 greenfield, **instrument with OTel GenAI**, send to **Langfuse** (if dev-team-led) or **Datadog LLM Observability** (if SRE-led). Don't ship to multiple at once.

## eBPF auto-instrumentation

Beyla (Grafana), Pixie (New Relic), Datadog USM (Universal Service Monitoring), Cilium Tetragon — all use eBPF to instrument network and syscall events without changing app code.

When eBPF auto-instrumentation pays back:
- Legacy services you can't easily redeploy.
- Third-party binaries (databases, proxies, caches).
- Adoption acceleration — get RED metrics from 100 services in a day, then add OTel SDKs over weeks.

When it doesn't:
- Business attributes — eBPF sees HTTP method/path/status, not your `customer_id` or `cart_total`. Add OTel for product analytics.
- Internal logic — eBPF can't see "the retry logic kicked in"; that's an in-process span.

Pair eBPF for infra/legacy + OTel SDK for new services. Don't pick one and skip the other.

## Tooling specifics — SLO-as-code

| Tool | Type | What it generates | Best for |
|------|------|-------------------|----------|
| **Sloth** | CLI + K8s operator (OSS) | PrometheusRule (recording + alerting) | Prometheus/Mimir; SLO-as-code without UI |
| **Pyrra** | CLI + K8s operator + Web UI (OSS) | Recording rules + UI | Visual SLO dashboard without Grafana |
| **Nobl9** | SaaS | Cross-platform SLOs (DD, NR, Grafana, Splunk, Dynatrace, CloudWatch as backends) | Enterprise with multiple observability backends |
| **OpenSLO** | YAML spec | Vendor-neutral SLO definition consumed by Sloth/others | Standardize across teams/tools |
| **Google SLO Generator** | CLI (OSS) | SLI computation + export | GCP-centric environments |
| **Keptn Lifecycle Toolkit** | K8s controller | SLO-driven deploy gates | K8s deploy automation |

**Sloth SLO example:**

```yaml
# sloth-slo.yaml — checkout availability
version: "prometheus/v1"
service: "checkout-api"
labels:
  owner: "platform-team"
  tier: "tier-1"
slos:
  - name: "requests-availability"
    objective: 99.9
    description: "99.9% of checkout API requests should succeed"
    sli:
      events:
        error_query: |
          sum(rate(http_server_request_duration_count{
            service_name="checkout-api",
            http_response_status_code=~"5.."
          }[{{.window}}]))
        total_query: |
          sum(rate(http_server_request_duration_count{
            service_name="checkout-api"
          }[{{.window}}]))
    alerting:
      name: CheckoutAPIAvailability
      labels:
        team: platform
      annotations:
        runbook_url: "https://runbooks.example.com/checkout-availability"
      page_alert:
        labels: { severity: critical }
      ticket_alert:
        labels: { severity: warning }
```

`sloth generate -i sloth-slo.yaml -o slo-rules.yaml` produces the full multi-window burn-rate PrometheusRule.

## Vendor-specific deep dives

### Datadog — the SRE playbook

Datadog is the most common single-pane-of-glass choice in 2024-2026. As SRE, your day-to-day surfaces:

- **Service Catalog (now Software Catalog)** — auto-built from APM data. Each service has a generated overview with RED metrics, SLO status, deployments, owners. Treat it as the **first stop for any service-related question**. Wire `team` ownership via Datadog Teams (since 2024) or the `dd.team` tag (legacy).
- **Watchdog AI** — automatic anomaly detection on every metric Datadog sees. Surfaces "Service X latency increased 3.2x in last 15m, correlated with deploy Y." Don't disable; tune alert routing so Watchdog signals go to a low-priority channel, not paging.
- **Bits AI** — natural-language assistant. "Why did checkout error rate spike?" returns a correlation analysis. As of 2026, useful for triage, not paging.
- **Workflow Automation (formerly Workflows)** — visual workflow builder. Wire alert → page → Slack post → Jira ticket → status-page update. Treat workflows as code via Terraform; review like alerts.
- **Incident Management** — separate product; the IR layer above monitors. If you have incident.io / FireHydrant / Rootly already, skip Datadog IM. If not, it's reasonable.
- **Synthetic Tests** — managed locations, API + browser. Browser tests are expensive ($12/1K vs $5/1K for API); use API tests for endpoint health, browser tests for tier-1 user journeys.
- **CI Visibility + Test Visibility** — pipeline observability + flaky-test detection. Pricing per pipeline-minute. Worth it for teams with >50 CI runs/day on critical pipelines.
- **LLM Observability** — separate product, OTel GenAI semconv-compatible. Don't roll your own LLM tracing pipeline if Datadog is your platform; this surface is fully featured.
- **APM Profiling** — continuous profiling. Pricing per host on top of APM. Useful for CPU-bound services; skip for I/O-bound.

Pitfalls specific to Datadog:
- **Don't enable every Agent integration**. Each integration brings 50-500 metrics. Audit what you actually use; disable the rest in `datadog.yaml`.
- **Treat `@team` mention vs `@pagerduty-integration` vs `@slack-channel`** as distinct routing surfaces. Migration to teams-based routing is incomplete in many installs.
- **The 15-day default log retention is short for compliance.** Bump to 30/60/90 days indexed or use Log Archives. SOC 2 doesn't strictly require beyond 30 days but customer commitments often do.
- **Datadog Notebooks** are an underused investigation surface — interactive runbook material with embedded queries. Use them for postmortem timelines.

### New Relic — the SRE playbook

NR's strengths and quirks:

- **NRQL is closer to SQL** than other vendor query languages. Power users productive faster; downside is performance — high-cardinality `FACET` clauses hit CU budgets fast.
- **Workloads** — group entities into a logical surface (a service = APM + Infrastructure + Logs + Browser + Synthetics + Mobile). Wire workloads to teams.
- **Service Maps** — auto-built from APM trace data. Excellent for understanding topology before instrumenting.
- **Errors Inbox** — surfaces errors across services, dedupes, assigns. Chain SLO burn-rate alerts → Errors Inbox to triage what's actually breaking.
- **Distributed Tracing** — strong; tail-based sampling via the NR Infinite Tracing feature (paid add-on, decides at NR's side).
- **Pixie eBPF** — auto-instrument K8s services without code changes. Newer / less mature than Datadog USM but improving. Useful for legacy services.
- **NR Code-Level Performance** — IDE plugin that surfaces per-line latency in your editor. Niche but powerful for individual contributors.
- **AI Monitoring** — LLM observability, OTel GenAI compatible. Compare to Datadog LLM Obs for feature parity at your use case.

Pitfalls:
- **Per-user pricing surprise** — Full Platform users vs Core users. Audit who needs full access vs dashboard-only.
- **NRDB query CU consumption** — long-window dashboards (90d, 1y) running 24/7 hit CU budgets. Use Materialized Views (NRDB feature) for repeated heavy queries.
- **NR Infrastructure agent vs Pixie vs NR OTel** — three collection surfaces. Pick one per service; don't double-instrument.

### Grafana stack — the SRE playbook

The LGTM stack: Loki + Grafana + Tempo + Mimir + Alloy. Add Pyroscope for profiles, Faro for RUM, Beyla for eBPF, k6 for load testing, Grafana OnCall + IRM for incident management.

Day-2 ops realities:
- **Mimir at scale**: 8+ microservices to operate. Helm chart `grafana/mimir-distributed`. Per-tenant limits matter — set `max_global_series_per_tenant`, `max_series_per_query` to prevent noisy tenants from breaking the cluster.
- **Loki at scale**: TSDB index since Loki 3.x; bloom filters for accelerated label queries; structured metadata replaces high-cardinality label patterns. Don't put `request_id`, `trace_id`, or `user_id` as labels — use structured metadata. Loki's cost model is **GB ingested**, not stream count; structured metadata doesn't bloat cost.
- **Tempo at scale**: object-storage-backed traces; TraceQL for queries; metrics-generator + service-graph processor for derived signals. Use the spanmetrics connector at the Collector level to avoid double-charging for app-side custom metrics.
- **Alloy at scale**: clustering mode distributes scrape work across replicas; OpAMP support for fleet config management.
- **Grafana Alerting (unified)**: multi-datasource rules, contact points, mute timings. Use this OR Alertmanager depending on whether you need cross-datasource alerts.
- **Grafana OnCall + IRM**: PagerDuty alternative. OnCall is the schedule + escalation surface; IRM is the structured incident response. As of 2026, still maturing vs PagerDuty + incident.io.

Pitfalls:
- **Mimir without per-tenant limits** → one tenant's cardinality explosion knocks out the cluster.
- **Loki labels as fields** → stream count grows linearly with cardinality, query time degrades.
- **Tempo without `tail_sampling` upstream** → full sample at scale is expensive; OTel Collector handles this.
- **Grafana datasource permissions misconfigured** → engineers can query the production DB datasource without intending to. Use Grafana Enterprise/Cloud datasource permissions.

### Honeycomb — the SRE playbook

Honeycomb's event-based model is the most different from the rest:
- **Events**, not metrics. Each event carries arbitrary attributes (high cardinality is FREE).
- **Derived columns** for SLI computation per-event.
- **BubbleUp** — given a slow trace, find what attributes correlate with slowness. The killer feature.
- **Triggers** — alerts on stored queries.
- **Boards** — collections of saved queries (not laid-out dashboards).
- **Markers** — annotate events with deploy or incident markers.
- **Refinery** — tail-based sampling for the SDK → Honeycomb path.

Pitfalls:
- **Don't bring metrics-vendor mental models** to Honeycomb. Don't pre-aggregate into "metrics"; let Honeycomb roll up at query time across events.
- **Refinery memory** — Refinery holds traces in memory while waiting for the tail decision. Default `MaxMemoryPercentage: 75` works for moderate scale; tune for very high volume.
- **60-day max retention** is a compliance gap — see security-engineer overlay.

### Sentry — the SRE playbook

Sentry's niche is **errors + RUM (Replay)**. Treat it as complementary to your APM/metrics platform, not as a replacement.

- **Errors** — dedupe by stack trace fingerprint. Issue Owners route to teams.
- **Performance** — Span-based tracing; integrates with OTel via the Sentry-OTel SpanProcessor.
- **Profiling** — sampling profiler running alongside the SDK.
- **Replay** — session replay (browser DOM mutations recorded). The unique UX-investigation surface.
- **Crons** — heartbeat monitoring for scheduled jobs. Lightweight alternative to Healthchecks.io.
- **Releases** — tag every error/event with the release tag; surface regressions per release.
- **Source Maps** — Debug ID-based since 2024; mandatory for modern builds.

Pitfalls:
- **`tracesSampleRate: 1.0`** — already covered. Use dynamic sampling.
- **Replay sampling** — `replaysSessionSampleRate: 1.0` blows quota; use `replaysOnErrorSampleRate: 1.0` + `replaysSessionSampleRate: 0.1`.
- **Issue ownership not configured** → Sentry becomes an unowned issue dumpster.

### Dynatrace — the SRE playbook

Dynatrace's value props are unique:
- **OneAgent** — single binary that auto-instruments everything on the node. No SDK setup in app code.
- **Davis AI** — causal AI that auto-detects problems, correlates root cause, and explains. Most mature in the space.
- **Grail** — data lakehouse architecture; DQL queries; long-term retention.
- **Smartscape** — topology graph (services, processes, hosts, applications).
- **PurePath** — end-to-end transaction tracing (Dynatrace's name for distributed traces).
- **Site Reliability Guardian** — workflow that gates deploys on SLO health.

Pitfalls:
- **OneAgent is invasive** — auto-instruments via library injection. Compliance reviews require explicit approval in regulated industries.
- **DDU billing model is unintuitive** — GiB-hour with 4 GiB floor per host means a 512 MB container costs the same as a 4 GiB host.
- **DQL learning curve** — different from PromQL, NRQL, SPL. Investment to teach the team.

### Splunk — the SRE playbook

Two surfaces:
1. **Splunk Enterprise + Splunk Cloud** — SPL-based, schema-on-read, used for SIEM + IT operations + custom data.
2. **Splunk Observability Cloud (ex-SignalFx)** — APM + Infrastructure + Logs + RUM + Synthetics, more like Datadog. SignalFlow query language.

Splunk Enterprise as SRE substrate:
- **Indexes + Sourcetypes** — data segmentation. Set retention per index. Tier into hot/warm/cold/frozen for cost.
- **SPL2** is the forward syntax (more SQL-like multi-line); classic SPL still supported.
- **Saved Searches** as recurring queries; **Reports** for scheduled exports; **Alerts** trigger on search results.
- **ITSI** — IT Service Intelligence; service health scoring + episode review. Heavy product; only adopt if you want to commit to its model.

Pitfalls:
- **Splunk Cloud license breaks** at GB-per-day thresholds. Capacity-plan ingest.
- **Heavy searches** can monopolize search heads; use search-time field extraction sparingly on large data sets.
- **Federated Search to S3** (GA 2024) — keep cold logs in S3, query without re-ingest.

## Runbook authoring discipline

Every alert needs a runbook. A good runbook for a pager:

1. **What does this alert mean?** Plain English. "Checkout API error rate exceeds 5% over 5m" — say what user impact this maps to.
2. **What is the user impact?** "Checkout attempts may be failing." Explicit scope.
3. **First response (60 seconds):** Three dashboards to open, three commands to run. Pre-link them.
4. **Common root causes** (top 3-5), each with verification steps and mitigation:
   - Recent deploy regression → check deploy markers, consider rollback.
   - Upstream dependency failure → check dependency RED dashboards.
   - Resource saturation → check container CPU/memory dashboards.
   - Database slow query → check DB monitoring.
   - Config change → check audit logs.
5. **Escalation:** Who to contact at +30 min if unresolved.
6. **History:** Link to previous incidents triggered by this alert (incident.io / FireHydrant track this automatically).
7. **Postmortem template hook:** Link to where to start the postmortem if this turns into an incident.

Anti-patterns in runbooks:
- "Investigate further" → useless, don't write it.
- "Contact Bob" → Bob changes teams. Use roles, not names.
- Static screenshots → go stale fast. Link to live dashboards.
- No "what is normal" baseline → first responder doesn't know if 5% is normal high or anomaly.

Store runbooks in a wiki + Git-tracked Markdown (Confluence + GitHub Pages combo, or runbook.io, or Backstage TechDocs). Link from alert annotations.

## Postmortem patterns

After every paging incident, run a postmortem within 5 business days. Format that works:

1. **Summary** — 3 sentences. What broke, who was impacted, how long.
2. **Timeline** — minute-by-minute. Use the observability platform to pull alert/trace/log timestamps.
3. **Root cause** — the actual mechanism, traced via debugging-protocol root-cause-first method. Don't stop at "the database was slow"; ask why.
4. **Contributing factors** — secondary causes.
5. **What went well** — explicit acknowledgments.
6. **What went poorly** — actionable, not blame-y.
7. **Action items** — each with owner + due date + tracking ticket.
8. **Lessons learned** — generalizable to the org.

Tools that help:
- **incident.io / FireHydrant / Rootly** — auto-generate postmortem templates from incident timelines.
- **Datadog Notebooks** — interactive postmortem doc with embedded queries.
- **Grafana Annotations** — mark the incident on dashboards retroactively.

## SLO communication patterns

SLO health is a board-level metric in mature orgs. Communicate it well:

- **Per-service SLO dashboard** — burn rate over multiple windows, error budget remaining %, recent alerts.
- **Per-team SLO digest** — weekly email or Slack post showing each team's SLO health.
- **Quarterly SLO review** — re-baseline. If a service is consistently at 99.99% but SLO is 99.9%, you have headroom — invest the error budget. If a service is consistently breaching 99.9%, either invest in reliability or renegotiate the SLO (with stakeholders).
- **Error budget policy** — written agreement about what happens when budget is exhausted. Examples: freeze feature deploys until budget recovers, mandate reliability sprint, escalate to engineering leadership.

## Alert audit cadence

Quarterly review of every paging alert:
1. **Fired how many times?** Pull from PagerDuty analytics or vendor monitor history.
2. **% requiring action** — target >80%. Below = noise, retune or delete.
3. **% actionable within 15 min** — target >90%. Below = the alert is too vague or fires too late.
4. **Mean time to acknowledge** — target <5 min. Higher = alert routing problem or on-call burnout.
5. **False positive rate** — target <20%. Higher = threshold too tight or query buggy.

Outputs of the audit:
- Delete alerts with low actionability.
- Increase `for:` durations to require sustained conditions.
- Adjust thresholds where pages exceed the SLO budget burn rate.
- Add inhibition rules for cascading alerts.

## Cross-vendor SLO with Nobl9

If you have observability across multiple vendors (Datadog APM + Prometheus metrics + CloudWatch + Splunk logs), and you want one SLO platform across all of them, **Nobl9** is the canonical surface. SaaS, accepts SLI data from 20+ sources, computes SLO + error budget + burn rate in one place, exports back as Slack notifications / PagerDuty pages / dashboards.

```yaml
# Nobl9 SLO definition (YAML)
apiVersion: n9/v1alpha
kind: SLO
metadata:
  name: checkout-availability
  project: platform
spec:
  service: checkout-api
  indicator:
    metricSource: { kind: Agent, name: prometheus-prod }
    rawMetric:
      query: |
        sum(rate(http_server_request_duration_count{
          service_name="checkout-api"
        }[1m]))
  objectives:
    - displayName: 99.9% availability
      target: 0.999
      timeSliceTarget: 0.999
      countMetrics:
        incremental: true
        good:
          metricSource: { kind: Agent, name: prometheus-prod }
          rawMetric:
            query: |
              sum(rate(http_server_request_duration_count{
                service_name="checkout-api",
                http_response_status_code!~"5.."
              }[1m]))
        total:
          metricSource: { kind: Agent, name: prometheus-prod }
          rawMetric:
            query: |
              sum(rate(http_server_request_duration_count{
                service_name="checkout-api"
              }[1m]))
  timeWindows:
    - count: 30
      isRolling: true
      unit: Day
  alertPolicies: [fast-burn, slow-burn]
```

Worth the cost when:
- You have 3+ observability backends.
- Multi-team org with each team on a different vendor.
- Customer-facing SLO commitments need a unified source of truth.

Skip when:
- Single-vendor shop — use the vendor's native SLO product.

## SRE-on-LLM specifics

LLM endpoints need different SLOs. The Anti-patterns:
- **Treating LLM endpoint like HTTP endpoint** — `p99 latency < 1s` for a 4096-token completion is impossible. Latency SLI is **TTFT** (Time-To-First-Token) and **TTC** (Time-To-Completion), separately.
- **Sampling LLM traces** — keep 100%. Volume is low (LLM calls are expensive in dollars, so they're rate-limited by cost); value is high (debugging hallucinations, tool-call failures).
- **No cost SLO** — for an LLM-heavy product, $/request is the first-class SLI. Set a SLO: "99% of requests cost <$0.10."

Recommended LLM SLOs:
- **Availability**: 5xx / 4xx-other / 429 (rate limit) / total. 429s are NOT 5xx — they're a separate quota signal.
- **TTFT p99 < 500ms** (or vendor-published baseline).
- **TTC p99 < N seconds** (where N depends on max_tokens).
- **Cost SLO**: 99% of requests cost <$X.
- **Quality SLO** (evaluator-driven): % of responses passing a hallucination check / tool-call structure check / moderation check. Async; not real-time pagers. Weekly review.
- **Tool-call success rate** (for agents): % of tool invocations returning expected structure.

## Cardinality detective work

When you see "Prometheus is OOM-ing" or "Mimir bill spiked," follow this:

1. **Identify the offending metrics:**
   ```promql
   topk(20, count by (__name__)({__name__=~".+"}))
   ```
2. **Identify the offending labels:**
   ```promql
   topk(10, count by (job, instance, namespace, ...)({__name__="THE_NAME"}))
   ```
3. **Find unbounded-cardinality labels:**
   ```promql
   count(count by (LABEL_NAME)(SOME_METRIC))
   ```
   If this returns 100K+, that label is the problem.
4. **Drop the bad label at scrape time:**
   ```yaml
   metric_relabel_configs:
     - regex: 'bad_label'
       action: labeldrop
   ```
5. **Or drop the metric entirely** if it's unfixable.
6. **Adjust SDK Views** to permanently prevent re-creation.

## Integration with always-on protocols

### TDD on observability work

The discipline applies. Write the test that asserts the SLO alert fires (or doesn't) **before** writing the alert. Patterns:

- **Recording rule TDD:** Use `promtool test rules` against a fixture of `series` data. Assert the recording rule produces the expected output at the expected time.
- **Alerting rule TDD:** Same `promtool test rules` framework — define `alert_rule_test` cases with `eval_time`, expected alerts (or none).
- **Dashboard TDD:** Lighter — render the dashboard against a test data source, assert specific panel queries produce non-empty results.

```yaml
# promtool test rule example — checkout SLO recording rule
rule_files:
  - "slo-recording-rules.yaml"
tests:
  - interval: 1m
    input_series:
      - series: 'http_server_request_duration_count{service_name="checkout-api",http_response_status_code="200"}'
        values: '100x5'
      - series: 'http_server_request_duration_count{service_name="checkout-api",http_response_status_code="500"}'
        values: '1x5'
    promql_expr_test:
      - expr: slo:checkout:error_ratio_rate5m
        eval_time: 5m
        exp_samples:
          - labels: '{service_name="checkout-api"}'
            value: 0.01    # 1% error rate
    alert_rule_test:
      - eval_time: 5m
        alertname: SLOAvailabilityBurnRateCritical
        exp_alerts: []     # 1% > 0.001*14.4 = 0.0144? No, 0.01 < 0.0144 — should not fire
```

### Verification before claims

"The SLO is configured" requires:
- The recording rule appearing in the Prometheus rules endpoint.
- The alerting rule firing during a synthetic burn test.
- The PagerDuty incident actually being created.
- The runbook URL resolving to a live page.

Don't accept "I deployed the alert" — demand artifacts.

### Plan execution

Observability rollouts are multi-step. Common plan shape:

1. Vendor selection brief (pricing model, signals, ownership) → approved.
2. OTel SDK rollout per language → tests pass.
3. Collector topology design (agent / gateway / contrib processors) → reviewed.
4. Backend tenancy and retention → configured.
5. SLO definitions + recording rules → tested with `promtool` or equivalent.
6. Alert routing → fired in staging with synthetic burns.
7. Dashboard provisioning → IaC merged.
8. Runbook authoring → linked from alert annotations.
9. On-call handoff training → completed.
10. Rollback plan documented.

Don't skip step 10. The most common observability failure mode is the Collector itself becoming the bottleneck after a rollout — rollback path matters.

### Brainstorm-first

Vendor selection is the brainstorm step. Don't pre-decide; lay out the options against the org context and budget.

### Branch safety

- Alert rules and dashboards land via PR with at least one SRE approval.
- OTel Collector config changes land via PR with a staging-rollout step (Collector OOMs are easy to miss in lint).
- Recording rules merge with `promtool test rules` passing in CI.

### Debugging

Root-cause-first on observability bugs. The common failure modes:
- Alert doesn't fire → check the rule expression in a Prometheus/vendor expression UI; check the recording rule output; check the routing tree; check the PagerDuty integration key; check the notification policy mute timings.
- Trace is missing → check the SDK is initialized; check the propagation headers (W3C tracecontext); check the Collector receiver is reachable; check the Collector's batch/queue is not OOM'd; check the exporter retry count.
- Metric is missing → check the scrape config; check `up == 1`; check label drops; check the time range.

Don't shotgun-fix. One variable at a time. Check `up == 1` before claiming the service is broken.

## Cross-references

- **OTel Collector deployment patterns** → see `devops-engineer.md` (Agent/Gateway tiering, K8s deployment).
- **Application instrumentation** → see `backend-architect.md` (OTel SDK config per language, custom metric design).
- **Sensitive Data Scanner + audit log retention + SIEM integration** → see `security-engineer.md`.
- **LLM observability evaluator design** → SKILL.md "What changed in 2025-2026" + `backend-architect.md` LLM section.
- **Healthcare/Fintech compliance composition** → SKILL.md compliance composition + the vertical specialist.
