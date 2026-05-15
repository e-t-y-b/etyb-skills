---
title: Observability
description: Multi-vendor observability knowledge overlay — OpenTelemetry, Datadog, New Relic, Grafana, Prometheus, Splunk, Honeycomb, Sentry, Dynatrace. Current to 2026-Q2.
stack:
  vendor: observability
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - sre-engineer
    - devops-engineer
    - backend-architect
    - security-engineer
  authoritative_sources:
    - { name: "OpenTelemetry Docs",            url: "https://opentelemetry.io/docs/",                   type: official_docs }
    - { name: "OTel Semantic Conventions",     url: "https://opentelemetry.io/docs/specs/semconv/",     type: api_reference }
    - { name: "Datadog Docs",                  url: "https://docs.datadoghq.com/",                      type: official_docs }
    - { name: "Datadog API Reference",         url: "https://docs.datadoghq.com/api/latest/",           type: api_reference }
    - { name: "New Relic Docs",                url: "https://docs.newrelic.com/",                       type: official_docs }
    - { name: "New Relic NerdGraph",           url: "https://docs.newrelic.com/docs/apis/nerdgraph/",   type: api_reference }
    - { name: "Grafana Docs",                  url: "https://grafana.com/docs/",                        type: official_docs }
    - { name: "Grafana Cloud Docs",            url: "https://grafana.com/docs/grafana-cloud/",          type: official_docs }
    - { name: "Prometheus Docs",               url: "https://prometheus.io/docs/",                      type: official_docs }
    - { name: "Prometheus Operator Docs",      url: "https://prometheus-operator.dev/",                 type: official_docs }
    - { name: "Splunk Docs",                   url: "https://docs.splunk.com/",                         type: official_docs }
    - { name: "Splunk Observability Cloud",    url: "https://docs.splunk.com/observability/",           type: official_docs }
    - { name: "Honeycomb Docs",                url: "https://docs.honeycomb.io/",                       type: official_docs }
    - { name: "Sentry Docs",                   url: "https://docs.sentry.io/",                          type: official_docs }
    - { name: "Dynatrace Docs",                url: "https://docs.dynatrace.com/",                      type: official_docs }
    - { name: "CNCF Observability TAG",        url: "https://github.com/cncf/tag-observability",        type: community }
    - { name: "Google SRE Books",              url: "https://sre.google/books/",                        type: community }
  delegate_to_skills: []
---

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against OTel semconv 1.28+, Prometheus 3.4, Grafana 11.x, Datadog Agent 7.55+, New Relic agents 2026.x, Sentry SDKs 8.x, Dynatrace OneAgent 1.300+, Splunk Observability Cloud (post-Cisco).</div>

If today's date is more than 6 months past the last_verified_on above, treat platform specifics — pricing tiers, agent flags, semconv versions, product names — with extra care. The [drift-check protocol](/conventions/knowledge-currency/) governs how agents handle staleness. **Observability is a high-drift area; vendor SDKs and pricing models move quarterly.**

## This is a multi-vendor Stack

Unlike single-vendor Stacks (Salesforce, AWS, Cloudflare), Observability is **structurally multi-vendor**. Most production engagements pick one or two vendors per signal (metrics / logs / traces / RUM / synthetics / profiling), composed via **OpenTelemetry** as the cross-vendor pivot. This index briefs the vendor-selection decision; the per-product pages document each surface in depth.

The decision framework — when to pick which — lives in this index. Don't expect a single "best vendor"; expect a structured choice driven by signal scale, org size, regulatory profile, and operational ownership appetite.

## What changed in 2025-2026 that older training data misses

- **OpenTelemetry is the default greenfield SDK.** Every major vendor (Datadog, New Relic, Splunk, Honeycomb, Dynatrace, Grafana, Sentry) ingests OTLP first-class as of 2025-2026. Vendor proprietary SDKs (`dd-trace`, `newrelic`) still exist with parity-plus features in specific lanes (DD Profiling, NR Browser RUM, Dynatrace PurePath), but starting greenfield with OTel + OTLP is the right default.
- **Semantic conventions rotated key attribute names.** `http.method` → `http.request.method`, `http.status_code` → `http.response.status_code`, `http.url` → `url.full`. Code on pre-1.28 attributes shows broken dashboards on a fresh vendor. Pin semconv 1.28+ repo-wide.
- **OTel Logs spec is GA.** Logs are now a first-class OTel signal alongside traces and metrics. Application code emits over OTLP with auto-correlation to active span. The "Fluent Bit only" log path is no longer the default.
- **OTel Profiles spec landed (2025).** Continuous profiling joins the OTel signal family; Go and Java SDKs first, Node/Python catching up through 2026.
- **eBPF auto-instrumentation is mainstream.** Beyla (Grafana), Pixie (New Relic), Datadog Universal Service Monitoring (USM), Cilium Tetragon produce service-level RED metrics + L7 traces without app code changes.
- **LLM Observability is a first-class product surface.** Datadog LLM Observability (GA 2024), New Relic AI Monitoring, Honeycomb AI insights, Langfuse, LangSmith, Helicone. OTel **GenAI semantic conventions** (semconv 1.30-1.32) — `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens` — are the cross-vendor schema.
- **Datadog Watchdog AI / Bits AI** moved from preview to default surface (2025-2026). **Dynatrace Davis AI** remains the most mature causal-AI root-cause engine. **New Relic Applied Intelligence** is the NR equivalent.
- **Splunk was acquired by Cisco** (closed March 2024). Splunk Observability Cloud (ex-SignalFx) is the strategic forward bet; expect packaging changes through 2026-2027.
- **Grafana Alloy replaced Grafana Agent** — Grafana Agent EOL November 2025. Alloy is OTel-Collector-compatible with River/Alloy config syntax.
- **Prometheus 3.x** brought native OTLP ingest, UTF-8 metric names, native (exponential) histograms, Remote Write 2.0. Pre-3.0 patterns still work but no longer recommended.
- **Honeycomb Refinery tail-based sampling** became standard practice for trace volumes >10K events/sec. Random head sampling at the SDK is wasteful at scale.
- **Sentry Source Maps Debug IDs** are mandatory for modern builds. Legacy `sentry-cli releases files upload-sourcemaps` produces silently broken stack traces.
- **Sentry Spans v2 + Performance repricing (mid-2025)** — Performance is metered on accepted spans, not transactions. `tracesSampleRate: 1.0` is an outage waiting; use dynamic sampling.
- **Vector replaced Fluent Bit** in some Datadog Agent paths. **Logstash is legacy** — new builds skip it.

If you're recommending vendor-locked SDKs for greenfield, classic histograms for latency on Prometheus 3.x, `grafana-agent` instead of Alloy, Sentry source maps via release name, or `dd-trace` only when the user has multi-vendor requirements — your training is stale.

## Vendor selection — decision framework

### Step 1 — Signals and scale

| Signal | Low (<1M req/day) | Mid (1M-100M) | High (100M+) |
|--------|-------------------|---------------|---------------|
| **Metrics** | Prometheus + Grafana Free, DD free | Grafana Pro, DD, NR, VictoriaMetrics | Mimir/VictoriaMetrics, DD Enterprise, Dynatrace |
| **Logs** | CloudWatch/GCP Logging, Loki Free | Loki, DD Logs (+archives), NR Logs | Splunk Enterprise/Cloud, Loki at scale, DD with aggressive Pipelines |
| **Traces** | OTel + Jaeger/Tempo Free, Sentry Perf | Tempo, DD APM, NR, Honeycomb | Honeycomb + Refinery, Dynatrace, DD |
| **RUM** | Sentry Replay, skip | Sentry, DD RUM, NR Browser, Faro | DD RUM Premium, Dynatrace RUM, NR |
| **Synthetics** | Grafana Synthetic, skip | Checkly, Grafana Synthetic, DD | DD Synthetics, Dynatrace, Catchpoint |
| **Profiling** | Pyroscope OSS | Grafana Cloud Profiles, DD Profiling | DD Profiling, Dynatrace, Splunk APM |

### Step 2 — Single-pane or best-of-breed?

- **Single-pane winners**: **Datadog**, **Dynatrace**, **New Relic**. One vendor, one bill, unified UI. Easiest onboard; hardest to leave; bill surprises are the risk.
- **Best-of-breed**: Grafana stack for metrics+logs+traces+profiles, Sentry for errors+RUM, Checkly for synthetics, Honeycomb for high-cardinality traces. More config surface, lower lock-in, cheaper at scale.

The **OTel Collector is the seam** between best-of-breed components.

### Step 3 — Org context

| Org shape | Starting point | Why |
|-----------|----------------|-----|
| **Pre-revenue, 1-10 eng** | Sentry + Grafana Cloud Free or DD free | Errors compound silently; add Sentry early |
| **Series A-B, 10-50, K8s** | Grafana Cloud Pro (LGTM) + Sentry, or DD Pro | Two unified vendors max |
| **Series C+, 50-500, multi-region** | DD or Dynatrace + Honeycomb + Sentry | Single primary covers 80%; specialist tools for the 20% |
| **Enterprise, 500+, compliance-heavy** | Splunk Ent + Splunk Obs Cloud, OR Dynatrace + Splunk Ent for SIEM | SOC, compliance, audit retention dominate |
| **K8s-native, SRE-heavy, cost-sensitive** | Self-hosted LGTM + Beyla + Sentry | Highest ops cost, lowest per-GB cost; needs real SRE bandwidth |
| **AWS-only, minimal obs team** | CloudWatch + X-Ray + AMP/AMG | Native, zero agent setup, IAM-integrated |

### Step 4 — The OTel hedge

Whatever platform you pick, **instrument with OpenTelemetry**. The cost of switching becomes "change the OTLP endpoint in the Collector," not "rewrite every service's instrumentation." Single highest-leverage decision in 2026 observability strategy. See [OpenTelemetry](/stacks/observability/opentelemetry/).

Two cases where vendor-native SDKs still beat OTel (May 2026):
- **Datadog Profiling** — `dd-trace-*` profilers more featureful than OTel Profiles SDKs.
- **New Relic Browser RUM** — native NR Browser has session replay + heatmaps; OTel Browser is metrics+traces-only.

## Products covered

Per-product canonical pages — drift-risk badges reflect rate of change in the underlying vendor surface.

### Cross-cutting (OpenTelemetry + standards)

| Product | Drift risk | Why |
|---|---|---|
| [OpenTelemetry](/stacks/observability/opentelemetry/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Semconv versioning rotates every few months; Logs GA 2024-25; Profiles landing 2025-26 |
| [OTel Collector](/stacks/observability/otel-collector/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Connector model matured 2023-25; tail_sampling and transform processors evolved quarterly |
| [OTel Semantic Conventions](/stacks/observability/otel-semantic-conventions/) | <span class="etyb-drift-badge" data-risk="high">high</span> | 1.28 → 1.32 reshaped HTTP/RPC/GenAI attributes; pin a version |
| [OTel GenAI](/stacks/observability/otel-genai/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Conventions landed 1.30-1.32 (2025-26); agent conventions still drafting |
| [eBPF auto-instrumentation](/stacks/observability/ebpf-instrumentation/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Beyla/Pixie/USM/Tetragon evolving; capabilities + PSS interactions stable |

### Datadog

| Product | Drift risk | Why |
|---|---|---|
| [Datadog APM](/stacks/observability/datadog-apm/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Agent v7 + OTLP receiver + Library Injection v2 evolving; pricing model multi-axis |
| [Datadog Logs](/stacks/observability/datadog-logs/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Indexed-event pricing surprise; Log Pipelines + Archives feature surface evolving |
| [Datadog RUM](/stacks/observability/datadog-rum/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Per-session pricing; Browser + Mobile SDKs at parity 2025-26 |
| [Datadog Synthetics](/stacks/observability/datadog-synthetics/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | API + browser tests; managed locations stable |
| [Datadog Database Monitoring (DBM)](/stacks/observability/datadog-database-monitoring/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Postgres/MySQL/Mongo/SQL Server coverage expanding |
| [Datadog LLM Observability](/stacks/observability/datadog-llm-observability/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2024; evaluator surface + provider list iterating quarterly |
| [Datadog Sensitive Data Scanner](/stacks/observability/datadog-sds/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | SDS v2 (2024) extended to APM/RUM; 70+ standard patterns |
| [Watchdog + Bits AI](/stacks/observability/watchdog-ai/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Moved preview → default 2025-26; NL assistant features evolving |
| [Datadog CSPM/CWPP](/stacks/observability/datadog-cspm/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Cloud Security surface unified; competes with Wiz/Lacework |
| [Datadog ASM](/stacks/observability/datadog-asm/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Agent-side WAF + IAST; tied to dd-trace SDK |
| [Datadog Software Catalog](/stacks/observability/datadog-software-catalog/) | <span class="etyb-drift-badge" data-risk="high">high</span> | 2024-26 Backstage-style convergence; schema not finalized |

### New Relic

| Product | Drift risk | Why |
|---|---|---|
| [New Relic APM](/stacks/observability/newrelic-apm/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Consumption pricing stable; auto-instrumentation operator 2024+ |
| [NRQL + NRDB](/stacks/observability/newrelic-nrql-nrdb/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | NRQL stable; CU billing model unchanged; Materialized Views 2024+ |
| [New Relic AI Monitoring](/stacks/observability/newrelic-ai-monitoring/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2024; OTel GenAI ingestion expanding |
| [Pixie (eBPF)](/stacks/observability/newrelic-pixie/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Under New Relic since acquisition; auto-instrument expanding |
| [Errors Inbox](/stacks/observability/newrelic-errors-inbox/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature; deploy-correlation surface stable |

### Grafana stack

| Product | Drift risk | Why |
|---|---|---|
| [Grafana Cloud](/stacks/observability/grafana-cloud/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Adaptive Metrics + 95th-pctl billing 2024-26 |
| [Mimir](/stacks/observability/grafana-mimir/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | 3.x async buffer + per-tenant limits evolving |
| [Loki](/stacks/observability/grafana-loki/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | 3.x TSDB index + bloom filters + structured metadata reshaped patterns |
| [Tempo + TraceQL](/stacks/observability/grafana-tempo/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | TraceQL metrics + service-graph processor GA |
| [Pyroscope](/stacks/observability/grafana-pyroscope/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Continuous profiling GA; OTel Profiles convergence |
| [Faro (RUM)](/stacks/observability/grafana-faro/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2024; still landing features |
| [Beyla (eBPF)](/stacks/observability/grafana-beyla/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Auto-instrumentation evolving rapidly |
| [Alloy](/stacks/observability/grafana-alloy/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Replaced Grafana Agent Nov 2025; OpAMP landing |
| [Grafana Alerting](/stacks/observability/grafana-alerting/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Multi-datasource rules mature in 11+ |
| [Grafana OnCall + IRM](/stacks/observability/grafana-oncall/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Consolidating; PagerDuty alternative still maturing |
| [k6](/stacks/observability/k6/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable load-testing tool; Grafana Cloud k6 SaaS available |

### Prometheus ecosystem

| Product | Drift risk | Why |
|---|---|---|
| [Prometheus Server](/stacks/observability/prometheus-server/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | 3.x OTLP ingest, UTF-8, native histograms, Remote Write 2.0 |
| [Alertmanager](/stacks/observability/alertmanager/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; routing + grouping + inhibition unchanged |
| [Prometheus Exporters](/stacks/observability/prometheus-exporters/) | <span class="etyb-drift-badge" data-risk="low">low</span> | node-exporter, blackbox-exporter, postgres-exporter et al. stable |
| [PromQL](/stacks/observability/promql/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Query language stable; histogram_quantile patterns matured |
| [Recording Rules](/stacks/observability/recording-rules/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Pattern stable; promtool test rules workflow mature |
| [Thanos](/stacks/observability/thanos/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; sidecar+store+querier topology unchanged |
| [VictoriaMetrics](/stacks/observability/victoriametrics/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Drop-in Prometheus replacement; vmagent + vmalert mature |

### Splunk

| Product | Drift risk | Why |
|---|---|---|
| [Splunk Cloud](/stacks/observability/splunk-cloud/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | SPL2 rollout + Federated Search to S3 GA |
| [Splunk Observability Cloud](/stacks/observability/splunk-observability-cloud/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Cisco acquisition March 2024; roadmap shifts through 2026-27 |
| [SPL](/stacks/observability/spl/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | SPL2 forward syntax landing; classic SPL stable |
| [Splunk ITSI](/stacks/observability/splunk-itsi/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Evolves slowly; service health scoring + episode review |

### Honeycomb

| Product | Drift risk | Why |
|---|---|---|
| [Honeycomb Events](/stacks/observability/honeycomb-events/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Event model stable; BubbleUp + Triggers + Boards stable |
| [Refinery](/stacks/observability/honeycomb-refinery/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Refinery 2.x; tail-sampling memory + rules evolving |
| [Beelines](/stacks/observability/honeycomb-beelines/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Legacy SDK; OTel-based instrumentation preferred for 2026 |

### Sentry

| Product | Drift risk | Why |
|---|---|---|
| [Sentry Errors](/stacks/observability/sentry-errors/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Dedup + Issue Owners stable; SDK 8.x ergonomics changed |
| [Sentry Performance](/stacks/observability/sentry-performance/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Mid-2025 repricing on accepted spans; dynamic sampling default |
| [Sentry Profiling](/stacks/observability/sentry-profiling/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Profiling v2 reshape; languages added quarterly |
| [Sentry Replay](/stacks/observability/sentry-replay/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Quotas changed 2025; mobile replay landing |
| [Sentry Crons](/stacks/observability/sentry-crons/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Heartbeat monitoring stable; alternative to Healthchecks.io |
| [Sentry Debug IDs](/stacks/observability/sentry-debug-ids/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Debug IDs mandatory for modern builds; legacy release-name path deprecated |

### Dynatrace

| Product | Drift risk | Why |
|---|---|---|
| [OneAgent](/stacks/observability/dynatrace-oneagent/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | 1.300+ K8s deployment improving; library injection model stable |
| [Davis AI](/stacks/observability/dynatrace-davis-ai/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Causal AI most mature in space; SRG workflow evolving |
| [Grail + DQL](/stacks/observability/dynatrace-grail-dql/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | DQL replacing legacy USQL; Grail strategic backend |

## Role overlays

Composed views — each role's lens onto this Stack's products.

- [/stacks/observability/sre-engineer/](/stacks/observability/sre-engineer/) — **the deepest overlay**. Vendor selection, SLO instrumentation across vendors, alerting topology, cardinality cost management
- [/stacks/observability/devops-engineer/](/stacks/observability/devops-engineer/) — Collector topology, Alloy/Fluent Bit/Vector pipelines, agent rollouts, dashboard/alert IaC
- [/stacks/observability/backend-architect/](/stacks/observability/backend-architect/) — OTel SDK per language, structured logging, custom metrics, LLM/agent observability
- [/stacks/observability/security-engineer/](/stacks/observability/security-engineer/) — SDS / PII scrubbing, audit-log retention, BAA per vendor, SIEM vs APM composition, Collector hardening

## Authoritative sources

For verified-current behavior:

- **[OpenTelemetry Docs](https://opentelemetry.io/docs/)** — canonical OTel reference
- **[OTel Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)** — the schema your attributes must conform to
- **[Datadog Docs](https://docs.datadoghq.com/)** + **[API Reference](https://docs.datadoghq.com/api/latest/)**
- **[New Relic Docs](https://docs.newrelic.com/)** + **[NerdGraph](https://docs.newrelic.com/docs/apis/nerdgraph/)**
- **[Grafana Docs](https://grafana.com/docs/)** + **[Grafana Cloud](https://grafana.com/docs/grafana-cloud/)**
- **[Prometheus Docs](https://prometheus.io/docs/)** + **[Prometheus Operator](https://prometheus-operator.dev/)**
- **[Splunk Docs](https://docs.splunk.com/)** + **[Splunk Observability Cloud](https://docs.splunk.com/observability/)**
- **[Honeycomb Docs](https://docs.honeycomb.io/)**
- **[Sentry Docs](https://docs.sentry.io/)**
- **[Dynatrace Docs](https://docs.dynatrace.com/)**
- **[CNCF Observability TAG](https://github.com/cncf/tag-observability)** — vendor-neutral community
- **[Google SRE Books](https://sre.google/books/)** — SRE theory baseline

## Delegate skills

No first-party Datadog / New Relic / Splunk / Honeycomb / Sentry / Dynatrace MCP server is generally available in an installable form as of `last_verified_on`. Datadog, New Relic, and Splunk have public MCP servers in active development; this section will be populated once installable surfaces ship. When that happens, ETYB will defer strict-path queries on the relevant products to those skills.

## Compliance composition

When observability work touches a regulated vertical:

| Vertical | What changes | Vertical specialist |
|----------|--------------|---------------------|
| **Healthcare (HIPAA, HITRUST)** | 6yr audit retention, PHI scrubbing in logs/traces, BAA-signed vendors only | `healthcare-architect` |
| **Fintech (PCI DSS, SOX)** | PAN never in logs, 7yr audit retention (SOX), separation-of-duty in alert routing | `fintech-architect` |
| **SaaS multi-tenant** | tenant-id label cardinality discipline, per-tenant SLOs | `saas-architect` |
| **EU operations** | Data residency (EU-only telemetry), GDPR right-to-erasure on log lines | both verticals + `security-engineer` |

This Stack covers the **observability-platform mechanics** of compliance (which vendor signs which BAA, where the PII scrubbing toggles live, how retention is configured). The legal frame stays with the vertical specialist.
