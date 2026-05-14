---
name: stack-observability
description: >
  Observability platform knowledge overlay for the ETYB team. Loads when work
  involves the observability ecosystem — Datadog, New Relic, Grafana stack
  (Mimir/Loki/Tempo/Pyroscope/Faro/Beyla/Alloy), Prometheus, Splunk (Enterprise +
  Observability Cloud), Honeycomb, Sentry, Dynatrace, and the OpenTelemetry
  standard that ties them together. This is NOT a new team member; it is a
  context overlay that teaches each existing ETYB role what it needs to know to
  ship production-grade observability work as of 2026-Q2.
  Triggers: observability, monitoring, alerting, telemetry, instrumentation, metrics, logs, traces, profiling, RUM, real user monitoring, synthetics, APM, application performance monitoring, datadog, dd-agent, datadog agent, dogstatsd, watchdog, bits ai, datadog llm observability, sensitive data scanner, datadog software catalog, datadog asm, cspm, cwpp, new relic, newrelic, nrql, nrdb, new relic ai monitoring, errors inbox, applied intelligence, pixie, nr1, grafana, grafana cloud, grafana enterprise, lgtm, mimir, loki, tempo, pyroscope, faro, beyla, alloy, grafana agent, grafana alerting, grafana oncall, grafana irm, k6, sift, grafana ml, promql, logql, traceql, prometheus, prometheus operator, kube-prometheus-stack, alertmanager, node-exporter, blackbox-exporter, postgres-exporter, redis-exporter, recording rule, alerting rule, federation, remote_write, thanos, victoriametrics, vmagent, amp, gmp, splunk, splunk cloud, splunk enterprise, splunk observability cloud, signalfx, spl, splunk index, itsi, splunk apm, splunk infrastructure monitoring, splunk synthetics, splunk rum, honeycomb, honeycomb beelines, honeycomb refinery, bubbleup, honeycomb triggers, honeycomb boards, honeycomb markers, honeycomb spans, sentry, sentry replay, sentry crons, sentry releases, sentry source maps, sentry issue owners, sentry profiling, sentry performance, dynatrace, oneagent, purepath, smartscape, davis ai, grail, dql, dynatrace synthetic, dynatrace rum, opentelemetry, otel, otlp, otel collector, otel-collector, otel auto-instrumentation, semantic conventions, semconv, w3c trace context, b3 propagation, vector, fluent bit, fluentd, logstash, elastic stack, elasticsearch, kibana, beats, slo, sli, error budget, burn rate, multi-window burn rate, golden signals, red method, use method, sre, runbook, alert fatigue, deduplication, apdex, exemplar, native histogram, exponential histogram, ebpf observability, ebpf tracing, universal service monitoring, sloth, pyrra, nobl9, openslo, llm observability, agent observability, langfuse, langsmith, helicone, llm tracing, gen ai observability, sli sli slo, error budget policy, incident management, pagerduty, opsgenie, statuspage, mean time to detect, mttd, mttr.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - sre-engineer
    - devops-engineer
    - backend-architect
    - security-engineer
authoritative_sources:
  primary:
    - { name: "OpenTelemetry Docs",            url: "https://opentelemetry.io/docs/",                       type: official_docs }
    - { name: "OpenTelemetry GitHub",          url: "https://github.com/open-telemetry",                    type: source }
    - { name: "OTel Semantic Conventions",     url: "https://opentelemetry.io/docs/specs/semconv/",         type: spec }
    - { name: "Datadog Docs",                  url: "https://docs.datadoghq.com/",                          type: official_docs }
    - { name: "Datadog API Reference",         url: "https://docs.datadoghq.com/api/latest/",               type: api_reference }
    - { name: "Datadog Agent GitHub",          url: "https://github.com/DataDog/datadog-agent",             type: source }
    - { name: "New Relic Docs",                url: "https://docs.newrelic.com/",                           type: official_docs }
    - { name: "New Relic NerdGraph",           url: "https://docs.newrelic.com/docs/apis/nerdgraph/",       type: api_reference }
    - { name: "Grafana Docs",                  url: "https://grafana.com/docs/",                            type: official_docs }
    - { name: "Grafana Cloud",                 url: "https://grafana.com/docs/grafana-cloud/",              type: official_docs }
    - { name: "Prometheus Docs",               url: "https://prometheus.io/docs/",                          type: official_docs }
    - { name: "Prometheus Operator",           url: "https://prometheus-operator.dev/",                     type: official_docs }
    - { name: "Splunk Docs",                   url: "https://docs.splunk.com/",                             type: official_docs }
    - { name: "Splunk Observability Cloud",    url: "https://docs.splunk.com/observability/",               type: official_docs }
    - { name: "Honeycomb Docs",                url: "https://docs.honeycomb.io/",                           type: official_docs }
    - { name: "Sentry Docs",                   url: "https://docs.sentry.io/",                              type: official_docs }
    - { name: "Dynatrace Docs",                url: "https://docs.dynatrace.com/",                          type: official_docs }
    - { name: "CNCF Observability TAG",        url: "https://github.com/cncf/tag-observability",            type: community }
    - { name: "Google SRE Books",              url: "https://sre.google/books/",                            type: reference }
delegate_to_skills:
  # No first-party Datadog / New Relic / Splunk / Honeycomb / Sentry / Dynatrace MCP server
  # is GA in a generally available installable form as of last_verified_on. Datadog, New Relic,
  # and Splunk have public MCP servers in active development; revisit when installable surfaces ship.
  []
products_covered:
  - { name: "OpenTelemetry (OTel SDKs + Collector + OTLP)", drift_risk: high,   notes: "Semconv versioning moves every few months; Logs spec stabilized 2024-2025; Profiles spec landing 2025-2026; OTel is the cross-vendor pivot point" }
  - { name: "Datadog APM + Infrastructure + Logs",         drift_risk: high,   notes: "Custom-metric and indexed-log billing model shifts; Watchdog/Bits AI surfaces evolve quarterly; Agent v7 features add monthly" }
  - { name: "Datadog LLM Observability",                    drift_risk: high,   notes: "GA'd 2024-2025; pricing and evaluator surface still iterating; new model providers added each quarter" }
  - { name: "Datadog Software Catalog + ASM + CSPM/CWPP",   drift_risk: high,   notes: "Catalog moved toward Backstage-style IDP convergence in 2025-2026; ASM and CSPM merged surfaces" }
  - { name: "New Relic APM + Logs + NRDB",                  drift_risk: medium, notes: "Consumption pricing stable; Pixie eBPF integration deepening; AI Monitoring (LLM) GA'd 2024" }
  - { name: "Grafana Mimir",                                drift_risk: medium, notes: "Mimir 3.x added Kafka async buffer; multi-tenancy limits surface evolving" }
  - { name: "Grafana Loki",                                 drift_risk: medium, notes: "Loki 3.x TSDB index by default; bloom filters GA; structured metadata replaces label cardinality patterns" }
  - { name: "Grafana Tempo + TraceQL",                      drift_risk: medium, notes: "TraceQL metrics + service-graph processor GA; tail-based sampling moved to Tempo metrics generator" }
  - { name: "Grafana Pyroscope",                            drift_risk: medium, notes: "Continuous profiling went GA; OTel Profiles spec convergence in 2025-2026" }
  - { name: "Grafana Faro (RUM) + Beyla (eBPF)",            drift_risk: high,   notes: "Beyla auto-instrumentation rapidly evolving; Faro GA 2024; both surfaces still landing features" }
  - { name: "Grafana Alloy",                                drift_risk: medium, notes: "Replaced Grafana Agent (EOL Nov 2025); OpAMP support landing; River → Alloy config syntax stable" }
  - { name: "Grafana Alerting + OnCall + IRM",              drift_risk: medium, notes: "OnCall + IRM consolidating; Grafana Alerting matured in 11+; alert rules now multi-datasource" }
  - { name: "Prometheus 3.x server + Alertmanager",         drift_risk: medium, notes: "Prometheus 3.0 brought UTF-8 metric names, native OTLP ingest, native histograms; Remote Write 2.0; default scrape protocol negotiations changed" }
  - { name: "VictoriaMetrics",                              drift_risk: low,    notes: "Drop-in Prometheus replacement, stable architecture; vmagent and vmalert mature" }
  - { name: "Thanos",                                       drift_risk: low,    notes: "Stable, in maintenance-quality mode; sidecar + store + querier topology unchanged" }
  - { name: "Splunk Observability Cloud (ex-SignalFx)",     drift_risk: high,   notes: "Cisco acquisition closed 2024; product roadmap shifts post-acquisition; SignalFx → Splunk Observability rename pre-dated this but lingering docs use old name" }
  - { name: "Splunk Enterprise + Splunk Cloud + SPL",       drift_risk: medium, notes: "SPL2 rollout ongoing; Federated Search for Amazon S3 GA; ITSI evolves slowly" }
  - { name: "Honeycomb (Events + Triggers + BubbleUp)",     drift_risk: medium, notes: "Refinery tail-sampling becoming standard; AI features (Honeycomb AI insights) landed 2025" }
  - { name: "Sentry (Errors + Performance + Replay)",       drift_risk: medium, notes: "Spans v2 + Profiling v2 reshaping pricing 2025-2026; Replay quotas changed; Source Maps Debug IDs mandatory for modern builds" }
  - { name: "Dynatrace (OneAgent + Davis AI + Grail)",      drift_risk: medium, notes: "Grail (data lakehouse) is the strategic backend; DQL replacing legacy USQL; OneAgent K8s deployment improving each quarter" }
  - { name: "Vector / Fluent Bit / Fluentd / Logstash",     drift_risk: low,    notes: "Log routing stable; Vector replacing Fluent Bit in some Datadog Agent paths" }
  - { name: "PagerDuty / Opsgenie integrations",            drift_risk: low,    notes: "Stable v2 Events API on PagerDuty; Opsgenie deprecation roadmap from Atlassian to watch" }
---

# Observability Stack Pack — Team Briefing

You're shipping observability work. This is a **multi-vendor knowledge overlay**, not a single-product stack. The decision space is broader here than for AWS or Salesforce: most engagements pick one or two vendors per signal (metrics / logs / traces / RUM / synthetics / profiling), and the cross-vendor pivot is **OpenTelemetry**. This pack teaches each role enough about each vendor to (a) pick wisely, (b) avoid the bill traps, and (c) write production-grade instrumentation that survives a vendor swap.

**Currency stamp:** verified for 2026-Q2 — OpenTelemetry semconv 1.28+, Prometheus 3.4, Grafana 11.x, Datadog Agent 7.x, New Relic agents 2026.x, Sentry SDKs 8.x, Dynatrace OneAgent 1.300+, Splunk Observability Cloud post-Cisco. If today's date is more than 6 months past `last_verified_on`, the pack is stale — warn the user, check the relevant vendor changelog, and re-verify before recommending pricing, agent flags, or product names.

## What changed in 2025-2026 that older training data misses

An LLM with a 2023-2024 cutoff will get the following wrong. Read the deltas before you recommend anything:

- **OpenTelemetry is the default instrumentation choice.** As of 2025-2026, every major vendor (Datadog, New Relic, Splunk, Honeycomb, Dynatrace, Grafana, Sentry for traces, AWS, GCP, Azure) ingests OTLP first-class. Vendor proprietary SDKs (`dd-trace`, `newrelic`, `signalfx`) still exist and still have parity-plus features in specific languages, but starting greenfield with OTel and shipping to your vendor over OTLP is the right default. Don't recommend a vendor-locked agent unless you can name a feature that the OTel path lacks today (e.g., Datadog Profiling, NR Browser RUM, Dynatrace PurePath end-to-end).
- **Semantic conventions are versioned.** `semconv 1.28` (mid-2024) stabilized HTTP, RPC, messaging, and DB attributes. `1.29-1.32` (2025-2026) added GenAI, Kafka, Kubernetes, and CICD conventions. If your code is on `semconv 1.20`-era attributes (`http.method`, `http.status_code` instead of `http.request.method`, `http.response.status_code`), your dashboards on a new vendor will look broken — names rotated. Pin a semconv version, upgrade in lockstep with collectors, and don't mix attribute schemas across services.
- **OTel Logs spec is GA.** Logs are now a first-class OTel signal, not a "use Fluent Bit instead" gap. OTLP/logs ingestion is supported by every major vendor. Application code can emit logs over OTLP, get them correlated to the active span automatically, and stop maintaining a parallel log pipeline. The OTel Collector's `logs` pipeline is production-ready.
- **OTel Profiles spec landed.** Continuous profiling joined the OTel signal family in 2025; SDKs and ingestion are still rolling out per language (Go and Java first; Node and Python catching up). Pyroscope, Grafana Cloud Profiles, Datadog Profiling, and Splunk APM Profiling are converging on the OTel profile format.
- **eBPF auto-instrumentation is real.** **Grafana Beyla**, **Datadog Universal Service Monitoring (USM)**, **Pixie** (under New Relic), and **Cilium Tetragon** can produce service-level RED metrics + L7 traces without changing application code. Useful for legacy services, third-party binaries, and adoption acceleration. Not a replacement for in-app spans (context propagation, business attributes), but a strong complement.
- **LLM Observability is a first-class product.** Datadog **LLM Observability** (GA 2024), New Relic **AI Monitoring**, Honeycomb's AI insights, Grafana **AI traces** + Tempo, and OSS tools (**Langfuse**, **LangSmith**, **Helicone**) all instrument prompts, completions, tool calls, evaluators, and cost-per-call. The OTel **GenAI semantic conventions** (1.30-1.32) gave us `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, etc. — instrument LLM apps with OTel today, not vendor-proprietary tags.
- **Agent observability is splitting from LLM observability.** AI **agents** (multi-step, tool-using, planner) need traces with **agent spans** (planning, tool selection, reflection) on top of LLM spans. Datadog, Langfuse, and Honeycomb all ship agent-aware views in 2026. The OTel semconv group has a draft agent conventions extension.
- **Datadog Watchdog AI and Bits AI** moved from preview to default surfaces in 2025-2026 — anomaly detection without configured thresholds, automatic correlation between deploys/services/errors, and a natural-language assistant in the UI. **Dynatrace Davis AI** (causal AI, auto-root-cause) is the most mature in this space and remains Dynatrace's central differentiator. **New Relic Applied Intelligence** is the equivalent.
- **Splunk was acquired by Cisco** (March 2024 close). Roadmap convergence with Cisco AppDynamics and Cisco ThousandEyes is in motion. Splunk Observability Cloud (the ex-SignalFx surface) is the strategic forward bet; expect pricing and packaging changes through 2026-2027.
- **Grafana Alloy replaced Grafana Agent** (Grafana Agent EOL November 2025). Alloy is an OTel-Collector-compatible distribution with River/Alloy config syntax and Prometheus pipeline support. If you see `grafana-agent` in a Helm chart, it's deprecated — migrate.
- **Prometheus 3.x** brought native OTLP ingest (`/api/v1/otlp/v1/metrics`), UTF-8 metric names, native (exponential) histograms with order-of-magnitude cardinality reduction on latency metrics, and Remote Write 2.0. Pre-3.0 patterns (dot-to-underscore translation for OTel, classic histograms for latency, RW 1.x) still work but are no longer the recommended path.
- **Honeycomb Refinery** for tail-based sampling became a standard pattern in 2025. With trace volumes growing 5-10x as services adopt OTel, head-based sampling at the SDK throws away the interesting traces (errors, high-latency). Tail-based sampling at a Refinery cluster keeps the interesting ones at 100% and rolls cheap ones to <1%.
- **Sentry Source Maps Debug IDs.** Sentry deprecated the legacy "release name → source maps" association. Debug IDs (embedded in build artifacts and uploaded via `sentry-cli sourcemaps inject`) are the modern path. Old `sentry-cli releases files upload-sourcemaps` patterns produce silently-broken stack traces in 2026 builds.
- **Sentry Spans + Tracing** repricing (mid-2025) — Performance is metered on accepted spans, not transactions. Aggressive `tracesSampleRate` settings can balloon bills. Use **dynamic sampling** (Sentry-controlled) instead of hand-tuned rates.
- **Vector replaced Fluent Bit** in some Datadog Agent deployments as the log router — better backpressure handling, Rust-based, single binary. Fluent Bit is still mainstream for K8s logs in non-Datadog stacks. **Logstash** is legacy; new builds skip it.
- **Splunk SPL2** is the forward syntax for SPL — multi-line, schema-on-read still, more SQL-like in places. SPL classic still works.
- **OpenTelemetry Collector signal independence.** Logs, metrics, traces, and (in 2026) profiles each have separate pipelines in the Collector. Don't share a single batch processor across signals at high volume; tune per-signal exporters; use `connector` components (e.g., `spanmetrics`, `servicegraph`) to derive metrics from traces.

If you're recommending vendor-specific SDKs over OTel for greenfield, classic histograms for latency in a Prometheus 3.x environment, `grafana-agent` instead of Alloy, Sentry source maps via release name, or `dd-trace`-only when the user has multi-vendor requirements — you're using stale knowledge. Read the references below.

## Routing across roles — which overlay loads when

ETYB's router detects observability signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

| Role | Reference | Owns |
|------|-----------|------|
| `sre-engineer` | [`references/sre-engineer.md`](references/sre-engineer.md) | **Vendor selection**, signal architecture, SLO instrumentation across Datadog/NR/Grafana/Splunk/Honeycomb/Dynatrace, alerting strategy at each platform, cardinality cost management, on-call integration. The deepest overlay — this is the SRE's primary surface |
| `devops-engineer` | [`references/devops-engineer.md`](references/devops-engineer.md) | OTel Collector deployment topology, Alloy/Fluent Bit/Vector pipelines, agent rollouts (Datadog Agent, OneAgent, NR Infra, Beelines), K8s Helm patterns, CI Visibility, GitOps for dashboards/alerts |
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | Application-layer instrumentation (OTel SDKs by language, vendor SDKs when needed), structured logging conventions, custom metrics design, RED/USE on application code, span attributes for product analytics, LLM/agent observability patterns |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | Sensitive Data Scanner (DD), Log Pipelines PII scrubbing, audit log retention, Datadog CSPM/CWPP/ASM, SIEM patterns vs APM, Splunk Enterprise Security composition, encryption-in-transit, multi-tenant data isolation |

The four roles above are the primary surfaces. If a `qa-engineer`, `frontend-architect`, `mobile-architect`, or `ai-ml-engineer` engagement hits observability work, they read the SKILL.md (this file) plus the `backend-architect` overlay for instrumentation patterns, plus the relevant base specialist reference. The depth on those roles for observability is intentionally not separated — the SKILL.md briefing + backend-architect overlay covers them.

## Top observability gotchas the team must know

Opinionated, named, with consequences:

1. **Datadog bill surprise: custom metrics and indexed logs.** The default `kube-state-metrics` integration with default tags can put a 500-pod cluster into the multi-thousand-dollar/month custom-metrics overage tier. Indexed log events ($1.70/M as of 2026) compound similarly. **Always set up metric exclusion at install time** (Agent `dogstatsd_metrics_exclude` + per-integration tag whitelists), **route logs through Datadog Log Pipelines with `archives` enabled** so non-investigation logs go to S3 (1/10th the cost), and **review the Usage Attribution dashboard weekly** for the first 90 days of a new install. Custom metrics can hit 52% of total Datadog bill at scale; aggressive cardinality control is non-negotiable.

2. **Prometheus cardinality explosions kill the cluster, not just the bill.** A label with unbounded values (user_id, request_id, full URL with query params) creates millions of time series, fills `prometheus_tsdb_head_series`, and OOMs the Prometheus pod. **Rule:** no label may have more than ~100 unique values in steady state. Use `topk(10, count by (__name__)({__name__=~".+"}))` weekly to find the offenders. Use `metric_relabel_configs` with `labeldrop` to kill bad labels at scrape time. For OTel SDKs, set per-instrument cardinality limits via `View`s.

3. **OTel Collector batch sizing trap.** Default `batch` processor settings (8192 spans / 200ms timeout) work for low volume. At >10K spans/sec, you'll see Collector OOMs, exporter retries, and dropped spans. Increase `send_batch_size` and `send_batch_max_size`, set `timeout: 1s`, deploy the Collector as a **gateway** tier (not just sidecar/agent), and run the Collector with `GOMEMLIMIT` set below the pod's memory limit. Without this, the Collector itself becomes the bottleneck.

4. **`tracesSampleRate: 1.0` on Sentry Performance is an outage waiting.** Sampling 100% of spans at moderate traffic blows through the Sentry quota in hours and produces useless aggregate dashboards (every endpoint at 1.0 makes p99 unrepresentative). Use Sentry **dynamic sampling** (Sentry decides per-environment) and let the platform balance. For Datadog APM, the equivalent trap is `DD_TRACE_SAMPLE_RATE=1.0` at app level; let the Agent's adaptive sampler do the work.

5. **Honeycomb without Refinery at scale = sampling at the SDK.** Random head sampling at 1% throws away 99% of errors and slow requests, defeating the purpose. Either use Refinery for tail-based sampling (deterministic: 100% of errors + p99 latency, ~1% of everything else) or accept full unsampled cost. Don't run 50K events/sec at `SampleRate: 1` against a paid Honeycomb tier without checking the bill.

6. **`up == 0` is the alert that saves you, but don't rely on it alone.** Prometheus's `up` metric tells you when a scrape target is down. But it cannot tell you when **Prometheus itself** is down, or when the **service discovery** is broken. Run a second Prometheus or use Grafana Cloud's `synthetic-monitoring-up` from outside the cluster. Same logic for Datadog — the Agent reports its own health, but a network partition that prevents the Agent from reaching Datadog reports nothing.

7. **Mixing semantic convention versions across services creates broken dashboards.** Service A on `semconv 1.20` reports `http.method=GET`. Service B on `semconv 1.28` reports `http.request.method=GET`. Your "Top endpoints by service" panel splits across two attributes and shows half the data. **Pin a semconv version repo-wide** (declare the version in your shared OTel config), bump in lockstep across services, and migrate older attributes via Collector `transform` processor during transition windows.

8. **Logs without trace correlation are 1/10th as useful.** When a span carries `trace_id` and the log line on the same goroutine/coroutine emits without it, you can't pivot from a slow trace to its logs. **Every structured logger should auto-inject `trace_id` and `span_id` from the active OTel context.** OTel SDKs in Java, Python, Node, Go, .NET, Ruby all provide log appenders/handlers that do this. If you're seeing logs without trace IDs in 2026, the instrumentation is broken — fix it before debugging anything else.

9. **Synthetic monitoring from the same VPC as the app monitors nothing.** Synthetic checks must run from outside your infra (Datadog managed locations, Grafana global probes, Checkly's network, Pingdom). A check that runs inside the same VPC misses DNS failures, CDN issues, ISP routing problems, and TLS cert validation from real client networks. Always deploy at least 3 globally distributed probes for tier-1 endpoints.

10. **Trace sampling decisions cascade.** If service A samples a trace at 10% but service B (a downstream call) samples at 100%, downstream-only spans appear orphaned in your UI. Use **`sampler=parentbased_traceidratio`** on every SDK (the OTel default) so the sampling decision propagates via the W3C tracecontext `traceparent` header. Don't override sampler choice per-service unless you know the propagation contract.

11. **Datadog Software Catalog ≠ Backstage, but pressure is converging them.** Datadog Software Catalog (2024-2025) builds a service inventory from APM/USM data. Backstage builds a service inventory from `catalog-info.yaml`. As of 2026 they don't fully share a schema. Don't tell the team "we have a catalog" if half the teams use Backstage and half use DD — pick one as system-of-record and feed the other.

12. **OpenTelemetry GenAI vs vendor LLM tagging.** Datadog `ml_app`, Langfuse `trace_id`, Sentry AI spans, and OTel `gen_ai.*` all describe similar things slightly differently. For 2026, **emit OTel GenAI semantic conventions in your SDK** (`gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`, `gen_ai.response.finish_reasons`), and let the vendor mapping happen at the Collector. Datadog's LLM Observability ingests OTel GenAI attributes natively as of late 2025.

## Vendor selection — a decision framework

If you're standing up observability today and choosing between platforms, here's the structured way to think:

### Step 1 — What signals do you need, at what scale?

| Signal | Low scale (<1M req/day) | Mid scale (1M-100M req/day) | High scale (100M+ req/day) |
|--------|-------------------------|------------------------------|----------------------------|
| **Metrics** | Prometheus + Grafana Cloud Free, or Datadog free tier | Grafana Cloud Pro, Datadog, New Relic, VictoriaMetrics self-hosted | Mimir/VictoriaMetrics self-hosted, Datadog Enterprise, Dynatrace |
| **Logs** | Cloud-provider logs (CloudWatch, GCP Logging), or Loki Free | Loki, Datadog Logs (with archives), New Relic Logs | Splunk Enterprise/Cloud, Loki at scale + archives, Datadog with aggressive Pipelines |
| **Traces** | OTel + Jaeger or Tempo Free, or Sentry Performance | Tempo, Datadog APM, New Relic, Honeycomb | Honeycomb (with Refinery), Dynatrace, Datadog at scale |
| **RUM** | Sentry Replay (free tier), or skip | Sentry, Datadog RUM, New Relic Browser, Grafana Faro | Datadog RUM Premium, Dynatrace RUM, New Relic |
| **Synthetics** | Grafana Cloud Synthetic free, or skip | Checkly, Grafana Synthetic, Datadog Synthetics | Datadog Synthetics, Dynatrace Synthetic, Catchpoint |
| **Profiling** | Pyroscope OSS | Grafana Cloud Profiles, Datadog Profiling | Datadog Profiling, Dynatrace, Splunk APM Profiling |

### Step 2 — Single-pane-of-glass or best-of-breed?

- **Single-pane-of-glass winners** (one vendor, one bill, unified UI): **Datadog**, **Dynatrace**, **New Relic**. Easiest to onboard, hardest to leave. Bill surprises are the risk.
- **Best-of-breed compositions**: Grafana stack for metrics+logs+traces+profiles, Sentry for errors+RUM, Checkly for synthetics, Honeycomb for high-cardinality traces. More config surface, lower lock-in, often cheaper at scale. The OTel Collector is the seam.

### Step 3 — Org context

| Org shape | Recommended starting point | Why |
|-----------|----------------------------|-----|
| **Pre-revenue startup, 1-10 engineers** | Sentry (errors) + Grafana Cloud Free or Datadog free tier | Free tiers cover MVP, add Sentry early — errors compound silently |
| **Series A-B, 10-50 engineers, K8s** | Grafana Cloud Pro (LGTM) + Sentry, or Datadog Pro | Two unified vendors max; resist five-vendor mosaics until 50+ engineers |
| **Series C+, 50-500 engineers, multi-region** | Datadog or Dynatrace as primary + Honeycomb for high-cardinality services + Sentry for frontend | Single primary covers 80%; specialist tools for the 20% where they pay back |
| **Enterprise, 500+ engineers, compliance-heavy** | Splunk Enterprise + Splunk Observability Cloud OR Dynatrace + Splunk Enterprise for SIEM | SOC, compliance, audit log retention dominate the choice; Datadog and NR also viable at the price tier |
| **K8s-native, SRE-heavy, cost-sensitive** | Self-hosted Grafana stack (Mimir + Loki + Tempo) + Beyla + Sentry | Highest ops cost, lowest per-GB cost; requires real SRE bandwidth |
| **AWS-only, minimal observability team** | CloudWatch + X-Ray + AMP/AMG (managed Prometheus/Grafana) | Native, zero agent setup, AWS-only, integrates with IAM directly |

### Step 4 — The OTel hedge

Whatever platform you pick, **instrument with OpenTelemetry**. The vendor receives OTLP; the cost of switching becomes "change the OTLP endpoint and the exporter config in the Collector," not "rewrite every service's instrumentation." This is the single highest-leverage decision in observability strategy in 2026.

Two cases where vendor-native SDKs still beat OTel today (May 2026):
- **Datadog Profiling**: native `dd-trace-py`/`dd-trace-go`/`dd-trace-java` continuous profilers are still more featureful than the OTel Profiles SDKs (still landing).
- **New Relic Browser RUM**: native NR Browser agent has session replay + heatmaps via NR; OTel Browser instrumentation is metrics+traces-only as of mid-2026.

Otherwise: OTel everywhere.

## Cross-product matrix — what each vendor ships and what to use it for

This is the cross-vendor lookup table — given a signal need, which vendor product covers it. Useful when planning multi-vendor compositions.

| Need | Datadog | New Relic | Grafana | Prometheus | Splunk Obs | Splunk Ent | Honeycomb | Sentry | Dynatrace | OSS |
|------|---------|-----------|---------|------------|------------|-------------|-----------|--------|-----------|-----|
| **Metrics (TSDB)** | Datadog Metrics | NRDB | Mimir | Prometheus | Splunk Obs (MTS) | (limited) | derived from events | (limited) | Grail | VictoriaMetrics, Thanos |
| **Logs** | Datadog Logs | NR Logs | Loki | n/a | Splunk Obs Logs | Splunk Ent | (events) | n/a | Grail | Loki, ELK, OpenSearch |
| **Distributed traces** | Datadog APM | NR Distributed Tracing | Tempo | n/a | Splunk APM | n/a | Honeycomb (events) | Sentry Performance | PurePath | Tempo, Jaeger, Zipkin |
| **Profiling** | DD Continuous Profiling | NR Profiling, Pixie | Pyroscope | n/a | Splunk APM Profiling | n/a | n/a | Sentry Profiling | OneAgent | Pyroscope, Parca |
| **Errors / Exceptions** | DD Error Tracking | NR Errors Inbox | (via Loki) | n/a | Splunk Obs | (via Splunk Ent) | (events) | Sentry | Dynatrace | Sentry self-hosted, GlitchTip |
| **RUM (Browser)** | DD RUM | NR Browser | Faro | n/a | Splunk RUM | n/a | (custom) | Sentry Replay | Dynatrace RUM | Faro, OpenReplay |
| **RUM (Mobile)** | DD Mobile RUM | NR Mobile | Faro (limited) | n/a | Splunk Mobile RUM | n/a | (custom) | Sentry Mobile | Dynatrace Mobile | Embrace (separate vendor) |
| **Synthetics** | DD Synthetics | NR Synthetics | Grafana Synthetic | (via blackbox-exporter) | Splunk Synthetics | n/a | n/a | (limited Crons) | Dynatrace Synthetic | Checkly (SaaS), k6, Locust |
| **Network monitoring** | DD NPM | NR Network | (limited) | (limited) | Splunk ITSI | (via Splunk Ent) | n/a | n/a | Dynatrace NPM | ntopng, Pktvisor |
| **Database monitoring** | DD DBM | NR DB | (via exporters) | postgres-exporter, etc. | Splunk Obs | n/a | (events) | n/a | Dynatrace DB | percona-pmm, pganalyze |
| **CI Visibility** | DD CI Visibility | NR CI | (via OTel exporter) | n/a | n/a | n/a | (events) | (limited) | n/a | OTel CI exporters |
| **Software Catalog / IDP** | DD Software Catalog | NR Service Catalog | (via Backstage integration) | n/a | n/a | n/a | n/a | n/a | n/a | Backstage, Cortex, OpsLevel |
| **LLM Observability** | DD LLM Obs | NR AI Monitoring | (via Tempo + Grafana AI) | n/a | (limited) | n/a | Honeycomb AI insights | Sentry AI Spans | n/a | Langfuse, LangSmith, Helicone |
| **Security: APM AppSec** | DD ASM | (via NR + AppD-converged) | n/a | n/a | n/a | (via Splunk ES) | n/a | n/a | Dynatrace AppSec | OSS WAF (ModSecurity) |
| **Security: CSPM/CWPP** | DD CSPM/CWPP | NR Cloud Security | n/a | n/a | (via Splunk Cloud Security) | (via Splunk ES) | n/a | n/a | (limited) | Wiz, Lacework, Aqua, Sysdig |
| **Security: SIEM** | (limited) | (limited) | n/a | n/a | n/a | Splunk ES | n/a | n/a | n/a | Sentinel, Elastic SIEM, Chronicle |
| **Incident response** | DD Incident Management | NR Incident Intelligence | Grafana OnCall + IRM | (via Alertmanager) | (limited) | (via Splunk SOAR) | (limited triggers) | Sentry Alerts | (limited) | PagerDuty, incident.io, FireHydrant, Rootly |
| **SLO product** | DD SLOs | NR Service Level | Grafana SLO (Sloth integration) | Sloth, Pyrra | Splunk Obs SLO | (limited) | Honeycomb SLOs | n/a | Davis SLO | Sloth, Pyrra, Nobl9 |
| **Audit log of the platform** | DD Audit Trail | NR Audit Logs API | Grafana Audit Log (Enterprise) | n/a | Splunk Obs Audit | `_audit` index | Honeycomb Audit (Enterprise) | Sentry Audit Log | Dynatrace Audit | (per-tool varies) |

Use this to plan compositions. If the user is on Grafana + Sentry + Checkly, you have metrics + logs + traces + profiles + errors + synthetics covered; you're missing RUM (add Faro) and CI Visibility (add OTel-CI exporters). Read across the row to see what each vendor brings.

## Compliance composition — when verticals overlay this stack

When observability work touches a regulated vertical:

| Vertical | What changes | Vertical specialist owns |
|----------|--------------|--------------------------|
| **Healthcare** (HIPAA, HITRUST) | Audit log retention requirements (6 years HIPAA), PHI scrubbing in logs/traces, BAA with each vendor (Datadog, NR, Splunk, Dynatrace all sign BAAs; Grafana Cloud signs; Honeycomb signs at Enterprise; Sentry signs; Loki self-hosted is fine for PHI if encrypted at rest) | `healthcare-architect` |
| **Fintech** (PCI DSS, SOX, FINRA) | PAN never in logs (use Sensitive Data Scanner, Splunk SED), 7-year audit retention (SOX), separation-of-duty in alert routing, transaction-log immutability requirements | `fintech-architect` |
| **SaaS multi-tenant** | Tenant isolation in metrics labels and log filtering (`tenant_id` as cardinality dimension is dangerous), per-tenant SLO reporting, customer-specific status pages | `saas-architect` |
| **E-commerce** | Synthetic checks for checkout flows from major-customer geographies, real-user monitoring on conversion funnels, payment-flow tracing as separate trace pipeline | `e-commerce-architect` |
| **Healthcare/Fintech + EU operations** | Data residency for logs and traces (EU regions only for EU traffic), GDPR right-to-erasure on log lines (Datadog, Splunk, Loki all have erasure APIs; Honeycomb relies on TTL) | both verticals + `security-engineer` |

Don't restate vertical compliance content from this pack — route to the vertical and let them own the legal frame. This pack covers the **observability-platform mechanics** of compliance (which vendor signs which BAA, where the PII scrubbing toggles live, how retention is configured), not the legal interpretation.

## Always-on protocols on observability work

The nine engineering disciplines still apply. Specifically:

- **TDD on instrumentation** — write a test that asserts a span emits the expected attributes (use the OTel `InMemorySpanExporter` / `SpanRecorder` / vendor test SDK), then implement the instrumentation. New custom metrics: write a test that scrapes the `/metrics` endpoint and asserts the metric appears. Without this, instrumentation rots silently.
- **Verification before claims** — "the SLO alert fires correctly" requires evidence: a synthetic burn, the alert firing in Alertmanager/PagerDuty, the runbook URL resolving. Don't accept "I configured the alert" without artifacts.
- **Plan execution** — observability rollouts are multi-step (instrument → collector → backend → dashboards → alerts → runbooks → rollback plan). Don't skip the rollback plan; an over-eager `traces_sample_rate` bump can take down a service via Collector OOM.
- **Brainstorm-first** — vendor selection is the brainstorm step. Don't jump to "install the Datadog Agent" when the user hasn't told you what signals they need at what scale.
- **Branch safety** — alert rules and dashboards in production should land via PR with at least one approval; same for OTel Collector config changes.
- **Subagent coordination** — observability touches SRE + DevOps + Backend + Security. Use the multi-role pattern: one role drives, others review.
- **Debugging** — when an alert doesn't fire, debug root-cause-first: scrape the metric, check the recording rule, check the alert query, check the routing tree. Don't shotgun-fix by dropping thresholds.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| K8s cluster-level observability platform topology | `devops-engineer` (uses this pack + Kubernetes-stack knowledge) |
| Application-level instrumentation library design | `backend-architect` (uses this pack + language-stack knowledge) |
| SLO definition and error-budget policy authoring | `sre-engineer` (uses this pack + product context) |
| SIEM, audit log retention, compliance composition | `security-engineer` + `fintech-architect` / `healthcare-architect` |
| Cost modeling beyond a single vendor's bill | `research-analyst` (cross-platform TCO model) |
| Frontend RUM instrumentation specifics (Sentry Replay, Datadog RUM browser SDK quirks) | `frontend-architect` (uses this pack as overlay) |
| Mobile RUM (Datadog Mobile RUM, Sentry Mobile, NR Mobile, Embrace) | `mobile-architect` (uses this pack as overlay) |
| LLM/agent observability deep design | `ai-ml-engineer` (uses this pack + LLM-eval knowledge) |

## Stack composition

If the user is on observability **plus** another stack (AWS, GCP, Salesforce, Supabase, Cloudflare), both overlays load. The observability pack handles signals + vendors + OTel; the other pack handles native integration with its observability surfaces (CloudWatch, Stackdriver, Salesforce Event Monitoring, Supabase Logs, Cloudflare Logpush). Neither pack should pretend to know the other's depth — the AWS pack tells you `aws_observability_access_manager` exists; this pack tells you how to wire AMP into Grafana.

## The five signals — what each is for, where each lives

Observability is the set of signals that let you ask new questions about your system without redeploying. As of 2026 there are five:

| Signal | What it answers | Cardinality model | Cost driver | Default storage |
|--------|-----------------|-------------------|-------------|-----------------|
| **Metrics** | "How much, how often, how fast?" — aggregate health and SLI computation | Time series (low-medium cardinality) | Series count | Prometheus / Mimir / VictoriaMetrics / vendor TSDB |
| **Logs** | "What exactly happened?" — discrete events with full context | Event count + GB ingest | GB ingested + GB indexed | Loki / Splunk / vendor log store / S3 archive |
| **Traces** | "How did this request flow through the system?" — causal chains across services | Span count (very high cardinality) | Span volume × retention | Tempo / Jaeger / vendor APM |
| **Profiles** | "Where is the CPU/memory going inside this service?" — call-stack samples | Sample volume per service | Sample × symbolization cost | Pyroscope / DD Profiling / vendor profiler |
| **Events/Errors** | "What broke, when, where in code?" — deduplicated exception records | Issue count + occurrence volume | Per-event + replay storage | Sentry / vendor error tracking |

Plus three derived/specialized surfaces:

- **RUM (Real User Monitoring)** — browser/mobile-side performance + UX. Sentry Replay, Datadog RUM, NR Browser, Grafana Faro, Dynatrace RUM, Splunk RUM.
- **Synthetics** — outside-in checks that simulate users. Datadog Synthetics, Grafana Synthetic, Checkly, Pingdom, Catchpoint.
- **LLM Observability** — prompts, completions, evaluators, agent traces. Datadog LLM Obs, NR AI Monitoring, Langfuse, Honeycomb AI insights, Helicone.

**Rule of thumb on signal coverage:** start with metrics + logs + errors (Sentry). Add traces when you have ≥3 services calling each other. Add profiles when you have a CPU/memory bug you can't reason about. Add RUM when frontend latency starts mattering to revenue. Add Synthetics when uptime SLAs go on contracts.

## OpenTelemetry — what to actually know

OTel is the cross-vendor pivot point and the right default for 2026 instrumentation. The seven concepts that matter:

1. **SDK + Resource + Exporter** — every instrumented service has an SDK (per language), declares its identity via `Resource` attributes (`service.name`, `service.version`, `deployment.environment`), and exports telemetry via OTLP (gRPC or HTTP) to a Collector or directly to a vendor.
2. **Collector** — the central processing layer. Receives OTLP (and Prometheus scrape, Fluent Forward, Jaeger, Zipkin, etc.), processes (batch, sampling, attribute editing, PII redaction), and exports to one or many backends. Distributions: upstream OTel Collector, OTel Collector Contrib, Grafana Alloy, Splunk OTel Collector, Datadog OTel Collector. Pick one.
3. **Semantic Conventions (semconv)** — standardized attribute names. Pin a version (`1.28+` for 2026), upgrade in lockstep, don't mix versions across services. Versions ship every quarter; major rotations rare but not zero (`http.method` → `http.request.method` was 1.20 → 1.25 → 1.28 incremental).
4. **W3C Trace Context** — the propagation standard. `traceparent` and `tracestate` HTTP headers. Every OTel SDK propagates them by default. B3 (Zipkin's format) is still supported but deprecated; use W3C tracecontext.
5. **Sampling** — head sampling at SDK, tail sampling at Collector, or vendor-managed (Datadog Agent adaptive, Sentry dynamic). Parent-based sampling propagates the decision via `traceparent`'s sampled flag.
6. **Auto-instrumentation** — language-specific libraries that wrap framework boundaries (HTTP server, DB client, queue client) with spans. Use them; supplement with custom spans for business logic. OTel Java Agent is the gold standard; Python and Node have rich auto-instrumentation packages; Go is mostly manual.
7. **Connectors** (the 2023+ addition) — Collector components that derive one signal from another. `spanmetrics` derives RED metrics from traces. `servicegraph` derives service topology from traces. Reduces redundant instrumentation.

If you remember only one thing: **emit OTel from app code, send OTLP to a Collector, let the Collector route to vendor(s)**. This is the single highest-leverage architecture in observability 2026.

## Cost model — the recurring theme

Every observability vendor's bill scales with one or more of these axes. Knowing the axis is the difference between a $10K/month bill and a $100K/month bill on the same workload.

| Vendor | Primary cost axis | Surprise factor | Hardest to predict |
|--------|-------------------|-----------------|---------------------|
| **Datadog** | Per-host (infra), per-host (APM), per-100-custom-metrics, per-M-indexed-log-events, per-session (RUM), per-check (Synthetics) | **Very high** — multiple multiplicative axes | Custom metrics, indexed log events |
| **New Relic** | Per-GB ingested, per-user (full access), per-CU for ML/AI | Medium | User license + CU at scale |
| **Grafana Cloud** | Per-1K-active-series (metrics), per-GB (logs/traces/profiles) | Low — single-axis predictable | Spike during outages (95th percentile billing helps) |
| **Splunk Cloud** | Per-GB-indexed (Splunk Cloud), per-MTS (Splunk Observability), per-license-tier | Medium | Indexed volume + license tier breaks |
| **Splunk Enterprise** | Per-GB-indexed | Low | Volume planning |
| **Honeycomb** | Per-M-events | Medium | Event count when sampling misconfigured |
| **Sentry** | Per-event (errors), per-span (Performance), per-replay (Replay), per-attachment | Medium-high | Performance spans at 100% sampling |
| **Dynatrace** | DDU (per-GiB-hour), HU (host units), DPS (Davis Problem Severity at scale) | Medium-high | DDU model is unintuitive on small containers |
| **Prometheus self-hosted** | Infra cost (compute + storage) | Low | Mostly storage when you neglect cardinality |
| **Loki self-hosted** | Infra cost (compute + object storage) | Low | Object storage egress when querying historicals |

The hardest-to-debug bill surprises in 2026:
- **Datadog kube-state-metrics with full label set** → custom metrics explosion. Set the integration tag whitelist before install.
- **Sentry Performance at `tracesSampleRate: 1.0`** → span quota burn in days. Use dynamic sampling.
- **Honeycomb without Refinery at >10K events/sec** → event volume × $/M-event = surprise. Deploy Refinery.
- **Datadog logs indexed-everything** → indexed events bill. Use Log Pipelines + Archives.
- **Loki with high-cardinality labels** (you added `request_id` as a label) → stream explosion, query timeouts. Move to structured metadata.
- **NR with per-user licenses on a growing eng team** → $99/user × 200 engineers. Use Core access tiers + dashboard-only roles.

### A cost-model brief for the vendor selection brainstorm

When the user asks "how much will this cost," resist a number-only answer. The structure that actually predicts cost:

1. **Hosts** (or vCPUs) under monitoring × $/host × 730 hours.
2. **Custom metrics** (or active series, depending on vendor) × $/metric × time.
3. **GB ingested per signal type** × $/GB × time.
4. **Sessions / events / spans per second** × tier rate.
5. **Users with full access** × $/user.
6. **Retention multiplier** if you exceed default.
7. **Add-on products** (Profiling, Synthetics, RUM, LLM Obs, CSPM).

Get an order-of-magnitude estimate before committing. Every vendor offers free trials with usage caps; instrument a representative slice for 2 weeks and extrapolate.

## Vendor-vs-OSS — the recurring binary

You'll see this decision repeatedly. Three rules:

1. **Default to vendor SaaS** if SRE headcount is small or growing. Operational cost of self-hosting Mimir/Loki/Tempo at scale is real.
2. **Default to OSS self-hosted** if data residency / compliance forces it, OR if your workload is at the scale where SaaS bills exceed $200K/yr (the rough break-even for a 2-3 SRE-FTE LGTM stack).
3. **Hybrid is fine** — Grafana Cloud for some signals, self-hosted Prometheus for others. The OTel Collector is the seam. Just don't fragment by signal-type-times-environment ("staging in Loki, prod in Datadog, dev in CloudWatch") — that's where dashboards become useless.

## What this pack does NOT cover

Some neighboring topics are out of scope and route elsewhere:

- **Incident response choreography** (incident commander roles, runbook authoring, postmortem facilitation) — that's SRE process, in the base `sre-engineer` reference.
- **Chaos engineering / fault injection** (Litmus, Chaos Mesh, Gremlin) — base `sre-engineer`.
- **Capacity planning and load testing** (k6, JMeter, Locust) — `qa-engineer` for testing, base `sre-engineer` for capacity.
- **DORA metrics and DevEx measurement** — base `sre-engineer` + `project-planner`.
- **APM at the language-runtime level for specific languages** (JVM GC tuning, Go pprof reading, Python async profiling) — base `backend-architect` per-language references.
- **K8s autoscaling driven by metrics** (HPA with custom metrics, KEDA) — base `devops-engineer`.
- **SLO theory and error-budget policy** — base `sre-engineer/references/monitoring-specialist.md`.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- **No coverage of Last9, Better Stack, Highlight.io, OpenObserve, ClickStack, Coralogix, Lightstep, SumoLogic, Logz.io, SolarWinds.** Smaller-share vendors. Add if engagement signal increases.
- **No SaaS-billing-meter perspective** (Cloudability, Vantage, Datadog Cost Recommendations beyond a paragraph). Cost FinOps for observability is a candidate Pro module.
- **No deep dive on Pixie scripts (PxL).** Pixie is referenced as the eBPF surface under New Relic; PxL DSL is out of scope.
- **No coverage of Tableau / PowerBI as observability surfaces.** Some enterprises pipe metrics into business BI; out of scope.
- **No deep dive on ELK (Elasticsearch/Logstash/Kibana) administration.** The pack notes ELK as a log destination but doesn't cover Elasticsearch operations — that's database-architect territory.
- **No deep dive on Mezmo, Cribl Stream, Edge Delta.** These are observability data pipeline / log routing companies. Vector and Fluent Bit cover most of the surface; add Cribl if user signal increases.
- **No coverage of carrier-grade telemetry (gNMI, OpenConfig).** Out of scope for application/infra observability.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation.

## Currency refresh — when this pack goes stale

This pack is stale and must be refreshed when **any** of the following are true:
- `last_verified_on` is more than 6 months in the past
- A vendor releases a major repricing announcement (Datadog has done this twice in 2024-2025; Sentry once in 2025)
- A new OTel semconv major version ships (track `semantic-conventions` releases at https://github.com/open-telemetry/semantic-conventions)
- A vendor is acquired/sunset (Splunk → Cisco was the most recent; if Datadog or Honeycomb were acquired, this pack rewrites)
- Prometheus or Grafana major versions (Prometheus 4.x, Grafana 12.x) ship

Refresh protocol:
1. Re-verify each `products_covered` entry against the vendor's changelog (URLs in `authoritative_sources.primary`).
2. Update `drift_risk` ratings — anything that shipped a major release in the period bumps to `high` for one quarter.
3. Re-check the "What changed in 2025-2026" section. Move stable items to the role overlays; add new currency items.
4. Re-verify the vendor-selection decision framework against current pricing pages.
5. Stamp the new `last_verified_on` date and bump the version in `metadata.version`.

The maintainer skill (`etyb-oss-maintainer`) coordinates this refresh; this pack does not self-modify.
