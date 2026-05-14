# Monitoring & Alerting — Platform-Neutral Principles + Stack Pointer

This file used to be a 1635-line single-specialist reference — the largest in the repo. As of v4.0.0 (2026-05-14), **vendor-specific monitoring content has migrated to the multi-vendor Observability Stack**; this file retains the platform-neutral SRE principles that apply regardless of which monitoring tools you use.

## Vendor-specific guidance lives in the Observability Stack

[`stacks/observability/SKILL.md`](../../../../../../stacks/observability/SKILL.md) covers:

- **Datadog** — APM, Infrastructure, Logs (incl. Pipelines + Sensitive Data Scanner), RUM, Synthetics, Network Monitoring, Database Monitoring, CI Visibility, CSPM, CWPP, ASM, Watchdog AI, Bits AI, LLM Observability, Software Catalog
- **New Relic** — APM, Browser, Mobile, Synthetics, Infrastructure, Logs, NRQL/NRDB, AI Monitoring, Pixie, Errors Inbox
- **Grafana stack** — Grafana + Mimir + Loki + Tempo + Pyroscope + Faro + Beyla + k6 + Grafana Alerting + Grafana OnCall + IRM. Alloy as the OTel-Collector-based agent (replacing the deprecated Grafana Agent)
- **Prometheus** — Prometheus 3.x, Alertmanager, exporters, PromQL, recording rules, federation, remote_write to Mimir/Thanos/VictoriaMetrics/AMP/GMP
- **Splunk** — Enterprise, Cloud, Splunk Observability Cloud (formerly SignalFx), APM, Infrastructure, Logs, SPL, ITSI
- **Honeycomb** — events-based observability, Triggers, BubbleUp, Markers, Refinery + tail-based sampling
- **Sentry** — Errors, Performance, Profiling, Replay, Crons, Debug-ID source maps
- **Dynatrace** — OneAgent, PurePath, Smartscape, Davis AI, Grail, DQL
- **OpenTelemetry** — the vendor-neutral instrumentation standard, OTel Collector tiered topologies (agent + gateway), OTLP, semantic conventions 1.28+, OTel Auto-Instrumentation, OTel GenAI conventions for LLM/agent observability
- **eBPF auto-instrumentation** — Beyla, Pixie, Datadog Universal Service Monitoring

Each is covered in `stacks/observability/references/<role>.md` with vendor-pick decision frameworks, instrumentation patterns, alerting topologies, cost models, and 2025-2026 currency anchors (Grafana Agent EOL, Sentry Debug-ID source maps mandatory, OTel semconv migration, Splunk-Cisco acquisition implications, etc.).

## What stays in the platform-neutral surface (this file)

The SRE Engineer specialist still owns these principles, regardless of which monitoring vendor you're on:

- **The Four Golden Signals** — latency, traffic, errors, saturation. From Google's SRE Book; vendor-neutral
- **RED method** (request-oriented services) — Rate, Errors, Duration. When to use this lens
- **USE method** (resource-oriented systems) — Utilization, Saturation, Errors. When to use this lens instead
- **SLO/SLI/SLA framework** — service-level objectives, indicators, agreements; how to define a good SLI, what makes a useful SLO target, how to compute error budgets, the math behind multi-window burn-rate alerting (slow + fast burn alerts together)
- **Error-budget policy** — how to use the budget, freeze/unfreeze deploys, balance feature velocity vs reliability, tier alerts by remaining budget
- **Symptom-based vs cause-based alerting** — alert on what users feel (symptoms), not on internal anomalies (causes). Cause-based alerts as a debug aid only
- **Alert-fatigue reduction discipline** — alert taxonomy, deduplication, grouping, ownership, runbook-or-delete rule, periodic alert audits, "if it can't be acted on, it's not an alert"
- **Runbook structure** — symptom, hypothesis, diagnostic queries, remediation steps, escalation path, post-incident actions. Vendor-neutral template
- **Incident response choreography** — IC role, scribe role, communications role, page → triage → mitigate → resolve → postmortem flow
- **Postmortem discipline** — blameless analysis, contributing factors vs root cause, action items with owners and dates, weekly review cycle
- **Trace sampling strategies** — head-based, tail-based, adaptive. When each fits. Sampling math (when 0.1% loses you 10x more signal than you think)
- **Cardinality management** — the universal observability cost trap. Metrics cardinality, log volume, trace span volume; per-vendor pricing exposure; cardinality-detective playbooks
- **Distributed-tracing principles** — span structure, context propagation, parent/child relationships, error vs warning vs info events, semantic conventions over freeform attributes
- **PromQL pattern library** — counter rate, gauge derivative, histogram quantile, aggregation across labels. PromQL is the open-standard query DSL most vendors honor (Mimir, Thanos, VictoriaMetrics, AMP, GMP, Datadog, New Relic)
- **Synthetic-monitoring philosophy** — golden-path checks vs feature-coverage checks vs canary scripts. Frequency, geographic distribution, alerting threshold tradeoffs
- **Service-catalog hygiene** — every service owns its alerts, runbooks, SLOs, dashboard; on-call rotation; deprecation lifecycle

## How ETYB uses both layers

The SRE specialist answers the *what* and *why* questions (golden signals, SLO math, alert philosophy). The Observability Stack answers the *how* on a specific vendor stack (where to set the SLO in Datadog vs Grafana vs Honeycomb; how Prometheus 3.x handles native histograms; how to migrate from Grafana Agent to Alloy). When a vendor is named or implied in the request, ETYB's router loads the Observability Stack alongside this specialist. When the question is principle-level, this specialist alone suffices.
