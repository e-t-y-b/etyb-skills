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
  version: "5.0.0-dev"
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

# Observability (multi-vendor) Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Observability (multi-vendor) knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/observability/index.md`](index.md)
- **Per-product pages:** `stacks/observability/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/observability/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/observability/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **OpenTelemetry is the default instrumentation choice.** As of 2025-2026, every major vendor (Datadog, New Relic, Splunk, Honeycomb, Dynatrace, Grafana, Sentry for traces, AWS, GCP, Azure) ingests OTLP first-class. Vendor proprietary SDKs (`dd-trace`, `newrelic`, `signalfx`) still exist but starting greenfield with OTel and shipping to your vendor over OTLP is the right default.
- **Semantic conventions are versioned.** `semconv 1.28` (mid-2024) stabilized HTTP, RPC, messaging, and DB attributes. `1.29-1.32` (2025-2026) added GenAI, Kafka, Kubernetes, and CICD conventions. If your code is on `semconv 1.20`-era attributes (`http.method`, `http.status_code` instead of `http.request.method`, `http.response.status_code`), your dashboards on a new vendor will look broken.
- **OTel Logs spec is GA.** Logs are now a first-class OTel signal, not a "use Fluent Bit instead" gap. OTLP/logs ingestion is supported by every major vendor.
- **OTel Profiles spec landed.** Continuous profiling joined the OTel signal family in 2025; SDKs and ingestion are still rolling out per language.
- **eBPF auto-instrumentation is real.** **Grafana Beyla**, **Datadog Universal Service Monitoring (USM)**, **Pixie** (under New Relic), and **Cilium Tetragon** can produce service-level RED metrics + L7 traces without changing application code.
- **LLM Observability is a first-class product.** Datadog **LLM Observability** (GA 2024), New Relic **AI Monitoring**, Honeycomb's AI insights, Grafana **AI traces** + Tempo, and OSS tools (**Langfuse**, **LangSmith**, **Helicone**) all instrument prompts, completions, tool calls, evaluators, and cost-per-call. The OTel **GenAI semantic conventions** (1.30-1.32) gave us `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, etc.
- **Splunk was acquired by Cisco** (March 2024 close). Roadmap convergence with Cisco AppDynamics and Cisco ThousandEyes is in motion. Splunk Observability Cloud (the ex-SignalFx surface) is the strategic forward bet; expect pricing and packaging changes through 2026-2027.
- **Grafana Alloy replaced Grafana Agent** (Grafana Agent EOL November 2025). Alloy is an OTel-Collector-compatible distribution with River/Alloy config syntax and Prometheus pipeline support.
- **Prometheus 3.x** brought native OTLP ingest (`/api/v1/otlp/v1/metrics`), UTF-8 metric names, native (exponential) histograms with order-of-magnitude cardinality reduction on latency metrics, and Remote Write 2.0.
- **Honeycomb Refinery** for tail-based sampling became a standard pattern in 2025. With trace volumes growing 5-10x as services adopt OTel, head-based sampling at the SDK throws away the interesting traces (errors, high-latency).
- **Sentry Source Maps Debug IDs.** Sentry deprecated the legacy "release name → source maps" association. Debug IDs (embedded in build artifacts and uploaded via `sentry-cli sourcemaps inject`) are the modern path.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on an Observability (multi-vendor) engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Emit OTel from app code, send OTLP to a Collector, let the Collector route to vendor(s).** This is the single highest-leverage architecture in observability 2026. The cost of switching vendors becomes "change the OTLP endpoint and the exporter config in the Collector," not "rewrite every service's instrumentation."

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Observability (multi-vendor) | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Observability (multi-vendor) alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
