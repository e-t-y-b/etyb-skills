---
title: SRE Engineer on Observability
description: SRE's lens on the Observability Stack — vendor selection, SLO instrumentation across vendors, alerting topology, cardinality cost management.
role_overlay:
  role: sre-engineer
  stack: observability
  last_verified_on: "2026-05-14"
  products_covered:
    - opentelemetry
    - otel-collector
    - otel-semantic-conventions
    - prometheus-server
    - alertmanager
    - promql
    - recording-rules
    - grafana-mimir
    - grafana-loki
    - grafana-tempo
    - grafana-pyroscope
    - grafana-alerting
    - grafana-oncall
    - datadog-apm
    - datadog-logs
    - datadog-rum
    - datadog-synthetics
    - datadog-llm-observability
    - watchdog-ai
    - newrelic-apm
    - newrelic-nrql-nrdb
    - newrelic-ai-monitoring
    - newrelic-errors-inbox
    - splunk-observability-cloud
    - honeycomb-events
    - honeycomb-refinery
    - sentry-errors
    - sentry-performance
    - dynatrace-davis-ai
    - dynatrace-grail-dql
    - k6
    - otel-genai
---

## Role briefing

You're the SRE on an observability engagement. This is your **deepest surface** in the Stack — vendor selection, SLO instrumentation, alerting topology, cardinality cost management, on-call integration. You bring **platform-neutral SRE principles** (RED, USE, error-budget math, multi-window burn rates, golden signals, incident response) from the base `sre-engineer` skill; this overlay teaches you what each vendor expects in 2026 and how to apply the principles on each platform without making the canonical mistakes.

**Distinctive vs. principle-level SRE:** here you make the *vendor selection* decision, not just the SLO design. The Stack index has the cross-cutting framework; this overlay layers on the SRE-specific lens of **operational ownership** — is this platform self-hosted (you operate the storage) or managed (someone else operates it)? That ownership question dominates Day-2 cost and reliability of the observability stack itself.

## What's distinctive about SRE on this Stack

- **Vendor selection is your call.** Not the backend architect's, not the security engineer's. You weigh signal scale × ownership appetite × bill predictability × cardinality shape × compliance posture.
- **SLO instrumentation differs per vendor.** Same principle, four different implementations across [Prometheus](/stacks/observability/prometheus-server/), [Datadog APM](/stacks/observability/datadog-apm/), [New Relic](/stacks/observability/newrelic-apm/), [Honeycomb](/stacks/observability/honeycomb-events/).
- **Cardinality cost management is 80% of your day-to-day work** at scale. Each vendor has a different lever; you need to know all of them.
- **You own the alerting topology** — multi-window burn rates, routing tree, on-call schedules, runbook authoring.

## 2025-2026 platform-reset items for SRE

- **OTel-first SLO instrumentation.** SLI emission via [OTel](/stacks/observability/opentelemetry/) metrics + traces; vendor receives OTLP. Don't recommend hand-coded `dogstatsd` or `newrelic.recordCustomEvent` for new SLOs.
- **Prometheus 3.x patterns** changed — native histograms over classic, OTLP-direct ingest, UTF-8 names. See [prometheus-server](/stacks/observability/prometheus-server/).
- **Multi-window burn-rate alerts** are the standard, not a fancy option. Sloth, Pyrra, Nobl9 generate them.
- **AIOps is default** — [Datadog Watchdog + Bits AI](/stacks/observability/watchdog-ai/), [Dynatrace Davis AI](/stacks/observability/dynatrace-davis-ai/), New Relic Applied Intelligence. Cut alert volume 60-80% on infra signals.
- **[Honeycomb Refinery](/stacks/observability/honeycomb-refinery/) tail-based sampling** is mainstream above 10K events/sec.
- **[Sentry dynamic sampling](/stacks/observability/sentry-performance/)** replaces hand-tuned `tracesSampleRate`.
- **[Grafana Alloy](/stacks/observability/grafana-alloy/)** replaced Grafana Agent — migrate.
- **[Splunk Observability Cloud](/stacks/observability/splunk-observability-cloud/)** is the strategic Splunk forward bet post-Cisco. Splunk Enterprise remains the SIEM surface.
- **LLM Observability is a distinct surface** with its own SLOs — token-spend SLO, TTFT/TTC SLOs, hallucination-rate SLO with evaluators. See [otel-genai](/stacks/observability/otel-genai/) and [sre-engineer LLM patterns](#sre-on-llm-specifics).

If you're proposing static-threshold infra alerts as the primary strategy, hand-rolled classic histograms on Prometheus 3.x, `grafana-agent` instead of Alloy, or 100% trace sampling without Refinery — your training is stale.

## Vendor decision framework — the SRE lens

The Stack index gives a generalized framework. Your additional dimension: **operational ownership**.

| Concern | Self-hosted ([Prometheus](/stacks/observability/prometheus-server/) + [Grafana](/stacks/observability/grafana-cloud/) + [Loki](/stacks/observability/grafana-loki/) + [Tempo](/stacks/observability/grafana-tempo/)) | [Grafana Cloud](/stacks/observability/grafana-cloud/) | [Datadog](/stacks/observability/datadog-apm/) | [New Relic](/stacks/observability/newrelic-apm/) | [Dynatrace](/stacks/observability/dynatrace-oneagent/) | [Splunk Obs](/stacks/observability/splunk-observability-cloud/) |
|---|---|---|---|---|---|---|
| **Who runs storage?** | You | Grafana | DD | NR | DT | Splunk |
| **Day-2 ops effort** | High | Low | Very low | Very low | Very low | Medium |
| **Bill predictability** | High | High | **Low — biggest surprise risk** | Medium | Medium | Medium |
| **K8s-native depth** | Excellent | Excellent | Good | Good | Good | Good |
| **OTel first-class?** | Yes (3.x OTLP) | Yes (Alloy) | Yes (Agent v7 OTLP) | Yes | Yes | Yes |
| **Long-term storage** | Object storage via [Mimir](/stacks/observability/grafana-mimir/)/[Thanos](/stacks/observability/thanos/) | 13mo default Pro | 15d / 15mo max | 13mo | 35d / 10yr | Configurable |
| **AIOps maturity** | Grafana ML/Sift (less) | Sift + ML | [Watchdog + Bits](/stacks/observability/watchdog-ai/) | Applied Intelligence | **[Davis AI most mature](/stacks/observability/dynatrace-davis-ai/)** | ITSI Predictive |

### How to actually pick

1. **SRE team headcount.** Below 3 dedicated SREs, **don't self-host Mimir/Loki/Tempo**. Ops burden exceeds budget savings.
2. **Language ecosystem.** Java/.NET/Python — any vendor. Erlang/OCaml/Crystal/Zig — pick OTel-first vendor (Grafana, Honeycomb, Datadog).
3. **SIEM vs APM.** Different stacks. [Splunk ES](/stacks/observability/splunk-cloud/) for SIEM; DD/NR/Dynatrace/Grafana for APM.
4. **Regulatory profile.** HIPAA → BAA-signing vendors. PCI → [SDS](/stacks/observability/datadog-sds/) toggle required. FedRAMP → DD Gov, Splunk Gov, AWS-native.
5. **Cardinality shape.** High-cardinality (per-customer attribution, ad-tech) → [Honeycomb](/stacks/observability/honeycomb-events/) or trace-first.
6. **Causal AI value.** Small team + triage matters → [Dynatrace Davis AI](/stacks/observability/dynatrace-davis-ai/).

### Anti-patterns in vendor selection

- **"Datadog for everything"** at <10 engineers without Usage Attribution monitoring on Day 1 — bill surprise in 90 days.
- **"Self-host LGTM to save money"** at <3 dedicated SREs — SRE-hours cost > SaaS bill.
- **"Grafana for dashboards + Datadog for alerts"** — splits source of truth.
- **"`dd-trace` first, OTel later"** — migration is 10x harder.
- **"Skip RUM, server-side is enough"** at consumer-facing — miss third-party JS failures, CDN, mobile-network slow.
- **"Splunk is for security only"** — historical; [Splunk Observability Cloud](/stacks/observability/splunk-observability-cloud/) is a real APM platform.

## SLO instrumentation across vendors

The SLO theory (SLI vs SLO vs SLA, error-budget math, multi-window multi-burn-rate) stays in the base `sre-engineer` skill. This section is **how to implement on each vendor in 2026**.

### Pattern: SLI from OTel metrics, computed at the vendor

Greenfield 2026 pattern. Application emits OTel metrics (`http.server.request.duration` histogram, `http.server.request.count` counter, both with `http.response.status_code` attribute) using semconv 1.28+. [OTel Collector](/stacks/observability/otel-collector/) forwards OTLP. SLI computation in vendor query language.

**Per-vendor implementations:**

| Vendor | Tooling | Notes |
|---|---|---|
| **[Prometheus / Mimir](/stacks/observability/prometheus-server/)** | [Sloth or Pyrra](/stacks/observability/recording-rules/) generate PrometheusRule manifests | Best DX for declarative SLOs |
| **[Datadog](/stacks/observability/datadog-apm/)** | Native SLO product, time-slice (ratio) or monitor-based | Burn-rate monitors per SLO |
| **[New Relic](/stacks/observability/newrelic-apm/)** | Events-based SLO via NerdGraph + `newrelic_service_level` Terraform | Rolling and calendar windows |
| **[Honeycomb](/stacks/observability/honeycomb-events/)** | Derived columns as SLI, native SLO product | Most flexible model; trace-based SLIs |
| **[Splunk Obs Cloud](/stacks/observability/splunk-observability-cloud/)** | SignalFlow detectors | Faster eval than DD/NR |
| **[Dynatrace](/stacks/observability/dynatrace-davis-ai/)** | DQL via Site Reliability Guardian | Davis auto-computes burn-rate |
| **[Grafana Alerting](/stacks/observability/grafana-alerting/)** | Multi-datasource rules; Sloth-generated PromQL | Forward to Alertmanager or native |

### Pattern: SLI with high-cardinality dimensions

Per-customer SLOs blow metrics-based cardinality. Three patterns:
1. **Trace-based SLOs on [Honeycomb](/stacks/observability/honeycomb-events/)** — derived columns per event; per-customer rollups are free.
2. **Datadog Trace Metrics or NR Trace-based SLIs** — generate metrics from traces with limited cardinality.
3. **Customer-segmented dashboards (not SLOs)** — accept that SLO is service-level.

Recommended: **trace-based SLOs for per-customer commitments**, metrics-based SLOs for service-level.

## Alerting topology by vendor

- **[Prometheus + Alertmanager](/stacks/observability/alertmanager/)** — 3-replica HA, gossip clustering, routing tree, inhibition. The reference impl.
- **[Datadog Monitors + Workflows](/stacks/observability/datadog-apm/)** — monitor-centric; Workflow Automation for alert response.
- **[New Relic Alert Conditions + Applied Intelligence](/stacks/observability/newrelic-apm/)** — NRQL or APM-condition based; AI correlation + anomaly.
- **[Splunk Observability Detectors](/stacks/observability/splunk-observability-cloud/)** — SignalFlow; sub-minute eval.
- **[Honeycomb Triggers](/stacks/observability/honeycomb-events/)** — query-based; native SLO product preferred.
- **[Grafana Alerting (unified)](/stacks/observability/grafana-alerting/)** — multi-datasource; forward to Alertmanager for hybrid.
- **[Dynatrace Davis](/stacks/observability/dynatrace-davis-ai/)** — adaptive baselines + Site Reliability Guardian.

Pattern-wise: **multi-window burn-rate alerts are the 2026 standard**. Static-threshold for tier-1 SLOs is an anti-pattern.

## Cardinality and cost management — vendor by vendor

This is where 80% of your day-to-day work lives.

| Vendor | Top surprise axis | Lever |
|---|---|---|
| **Datadog** | Custom metrics + indexed logs | Tag exclusion, Log Pipelines + Archives, [SDS](/stacks/observability/datadog-sds/), Trace adaptive sampler |
| **New Relic** | GB ingested + per-user license | Drop filters, sampling, NRDB Drop Rules, retention policies |
| **Grafana Cloud** | Active series + GB | [Adaptive Metrics](/stacks/observability/grafana-cloud/), [Loki structured metadata](/stacks/observability/grafana-loki/), Tempo metrics generator, 95th-pctl billing |
| **Prometheus self-hosted** | Storage + memory | `metric_relabel_configs`, `sample_limit`, [recording rules](/stacks/observability/recording-rules/), federation, remote_write |
| **Honeycomb** | Events per month | [Refinery](/stacks/observability/honeycomb-refinery/) tail sampling, sampling rules, markers |
| **Splunk Obs Cloud** | MTS + GB | Tag whitelist, Resource-Aware Sampling, Federated S3 |
| **Sentry** | Events/spans/replays | [Dynamic sampling](/stacks/observability/sentry-performance/), Inbound Filters, Rate Limits, Issue Owners |

### Cardinality detective work (Prometheus)

```promql
# Find offending metrics
topk(20, count by (__name__)({__name__=~".+"}))
# Find offending labels
topk(10, count by (job, instance, namespace, ...)({__name__="THE_NAME"}))
# Drop bad label at scrape time
metric_relabel_configs:
  - regex: 'bad_label'
    action: labeldrop
```

## Trace sampling strategy 2026

The default for most services:
1. **OTel SDK**: `parentbased_traceidratio` with ratio 1.0 at edge services.
2. **[OTel Collector at Gateway tier](/stacks/observability/otel-collector/)**: **tail-sampling processor**:
   - 100% of error traces.
   - 100% of high-latency traces (>p99).
   - 1-10% baseline.
   - Per-service rate limits.

For [Honeycomb](/stacks/observability/honeycomb-events/): use [Refinery](/stacks/observability/honeycomb-refinery/) (more memory-efficient).
For [Datadog APM](/stacks/observability/datadog-apm/): rely on Agent's adaptive sampler.
For **LLM/agent traces**: keep 100%. Low volume, high value.

## Incident response integration

- **PagerDuty Events API v2** is the integration target. `dedup_key` controls collapsing.
- **Opsgenie** deprecation announced 2024 — migrate within 2 years.
- **incident.io / FireHydrant / Rootly** sit above PagerDuty for IR orchestration.
- **[Grafana OnCall + IRM](/stacks/observability/grafana-oncall/)** is the PagerDuty alternative; still maturing.

## RUM and Profiling

- **[Datadog RUM](/stacks/observability/datadog-rum/)** — deepest APM correlation.
- **[Sentry Replay](/stacks/observability/sentry-replay/)** — replay video unique.
- **NR Browser, [Grafana Faro](/stacks/observability/grafana-faro/), Dynatrace RUM, Splunk RUM** — competitive.

For profiling: **continuous profiling went mainstream** 2024-2025. [Datadog Profiling](/stacks/observability/datadog-apm/), [Grafana Pyroscope](/stacks/observability/grafana-pyroscope/), [Sentry Profiling](/stacks/observability/sentry-profiling/), Dynatrace, Splunk APM Profiling. Use for CPU-bound regressions; skip I/O-bound.

## LLM observability — the new surface

LLM endpoints have different SLI shapes — see [otel-genai](/stacks/observability/otel-genai/) and [datadog-llm-observability](/stacks/observability/datadog-llm-observability/).

Recommended LLM SLOs:
- **Availability**: 5xx / 4xx-other / 429 / total. 429s are NOT 5xx (separate quota signal).
- **TTFT p99 < 500ms** (or vendor baseline).
- **TTC p99 < N seconds** (depends on max_tokens).
- **Cost SLO**: 99% of requests cost <$X.
- **Quality SLO** (evaluator-driven; async, not real-time pagers).
- **Tool-call success rate** (for agents).

Vendor surfaces: [Datadog LLM Obs](/stacks/observability/datadog-llm-observability/), [New Relic AI Monitoring](/stacks/observability/newrelic-ai-monitoring/), [Honeycomb AI insights](/stacks/observability/honeycomb-events/), Langfuse (OSS), LangSmith, Helicone.

## SLO-as-code tooling

| Tool | Type | Best for |
|---|---|---|
| **Sloth** | CLI + K8s operator (OSS) | Prometheus/Mimir; SLO-as-code without UI |
| **Pyrra** | CLI + K8s operator + Web UI (OSS) | Visual SLO dashboard |
| **Nobl9** | SaaS | Cross-platform SLOs (DD, NR, Grafana, Splunk, Dynatrace, CloudWatch) |
| **OpenSLO** | YAML spec | Vendor-neutral SLO definition |
| **Keptn Lifecycle Toolkit** | K8s controller | SLO-driven deploy gates |

Use **Nobl9** when you have 3+ observability backends and need unified SLOs. Otherwise vendor-native SLO product.

## Runbook and postmortem discipline

Every alert needs a runbook with: meaning, user impact, first-60s response, top common causes with verification + mitigation, escalation contact, history link, postmortem hook. Store in Git + wiki, link from alert annotations.

Postmortem within 5 business days. Summary, timeline, root cause (debugging-protocol root-cause-first), contributing factors, what-went-well, what-went-poorly, action items, lessons learned. Tools: incident.io / FireHydrant / Rootly auto-generate templates from incident timelines.

## Alert audit cadence

Quarterly review every paging alert. Targets:
- % requiring action: >80%
- % actionable within 15min: >90%
- MTTA: <5min
- False positive rate: <20%

Below thresholds — retune, delete, or split.

## Integration with always-on protocols

- **TDD on instrumentation** — assert spans emit expected attributes (OTel `InMemorySpanExporter`); `promtool test rules` for recording rules / alert rules.
- **Verification before claims** — "SLO alert fires" requires synthetic burn evidence + PagerDuty incident artifact + runbook URL resolving.
- **Plan execution** — observability rollouts have 10 steps. Don't skip step 10 (rollback plan).
- **Brainstorm-first** — vendor selection IS the brainstorm step. Don't pre-decide.
- **Branch safety** — alert rules and dashboards via PR with one SRE approval; Collector config changes with staging rollout.
- **Subagent coordination** — observability touches SRE + DevOps + Backend + Security. One drives, others review.
- **Debugging** — when an alert doesn't fire, debug root-cause-first: rule expression, recording rule output, routing tree, PagerDuty integration key, mute timings.

## Cross-references

- **Collector deployment + agent rollout** → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- **Application instrumentation per language** → [backend-architect overlay](/stacks/observability/backend-architect/)
- **PII scrubbing + audit logs + SIEM composition** → [security-engineer overlay](/stacks/observability/security-engineer/)
- **Stack index** (full briefing, vendor selection summary) → [/stacks/observability/](/stacks/observability/)
