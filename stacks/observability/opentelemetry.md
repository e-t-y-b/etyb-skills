---
title: OpenTelemetry
description: Vendor-neutral instrumentation standard — SDKs, OTLP protocol, Resource model. The cross-vendor pivot for 2026 observability.
product:
  name: OpenTelemetry
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, sre-engineer, security-engineer]
  authoritative_url: https://opentelemetry.io/docs/
  notes: "Semconv versioning rotates every few months; Logs spec GA 2024-25; Profiles landing 2025-26. OTel is the cross-vendor pivot."
---

## What it is

OpenTelemetry (OTel) is the CNCF observability standard: per-language SDKs that produce traces, metrics, logs, and (newly) profiles, plus the **OTLP** wire protocol (gRPC or HTTP/protobuf) that ships them to any compliant backend. Every major observability vendor — Datadog, New Relic, Splunk, Honeycomb, Dynatrace, Grafana, Sentry for traces, AWS, GCP, Azure — accepts OTLP first-class as of 2025-2026. See [opentelemetry.io/docs](https://opentelemetry.io/docs/).

The seven concepts that matter:
1. **SDK + Resource + Exporter** — every instrumented service has a per-language SDK, declares identity via `Resource` attributes (`service.name`, `service.version`, `deployment.environment`), exports via OTLP.
2. **Collector** — central processing layer (see [OTel Collector](/stacks/observability/otel-collector/)).
3. **Semantic Conventions** — versioned attribute names (see [OTel Semantic Conventions](/stacks/observability/otel-semantic-conventions/)).
4. **W3C Trace Context** — `traceparent` + `tracestate` HTTP headers for propagation. Replaces B3.
5. **Sampling** — head at SDK, tail at Collector, or vendor-managed.
6. **Auto-instrumentation** — per-language libraries wrap framework boundaries (HTTP server, DB, queue) with spans, no code changes.
7. **Connectors** (2023+) — Collector components that derive one signal from another (`spanmetrics`, `servicegraph`).

## When to use

**For 2026 greenfield: always.** OTel-first instrumentation, OTLP to a Collector, vendor as the consumer. The cost of switching vendors becomes "change the OTLP endpoint," not "rewrite every service's instrumentation." This is the single highest-leverage architectural decision in modern observability.

Two cases where vendor-native SDKs still beat OTel (May 2026):
- **[Datadog Profiling](/stacks/observability/datadog-apm/)** — `dd-trace-*` continuous profilers more featureful than OTel Profiles SDKs (still landing per language).
- **[New Relic Browser RUM](/stacks/observability/newrelic-apm/)** — native Browser agent has session replay + heatmaps. OTel Browser is metrics+traces-only as of mid-2026.

Otherwise: OTel everywhere. Don't ship `dd-trace` first and "migrate to OTel later" — the migration is 10x harder than starting OTel.

## 2025-2026 currency anchors

- **OTel Logs spec is GA.** Logs are a first-class OTel signal (not "use Fluent Bit instead"). Application code emits over OTLP, auto-correlated to active span via `trace_id`/`span_id` injection.
- **OTel Profiles spec landed (2025).** Go and Java SDKs first; Node and Python catching up through 2026. Converging with Pyroscope and DD Profiling formats.
- **Semantic Conventions 1.28+ rotated key HTTP attributes** — `http.method` → `http.request.method`, `http.status_code` → `http.response.status_code`, `http.url` → `url.full`. Pin a version repo-wide.
- **GenAI semantic conventions (1.30-1.32)** added `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, etc. Instrument LLM apps with OTel, not vendor-proprietary tags. See [OTel GenAI](/stacks/observability/otel-genai/).
- **SDK versions current as of 2026-Q2**: Java 1.42, Python 1.30, Node 1.27, Go 1.30, .NET 1.10, Rust 0.27.
- **Connectors matured.** `spanmetrics` and `servicegraph` connectors at the Collector reduce the need for redundant in-app RED metrics.

## Patterns

- **Pre-load tracing init** — Node `--require ./tracing.js`, Python `opentelemetry-instrument`, Java `-javaagent:opentelemetry-javaagent.jar`. Init **before** any app imports.
- **Parent-based sampling at the SDK** — `sampler=parentbased_traceidratio` propagates the trace-level sampling decision via W3C tracecontext. Don't override sampler choice per-service unless you know the propagation contract.
- **Auto-instrument first, custom spans second** — OTel Java Agent and Python/Node auto-instrumentation packs cover framework boundaries. Add custom spans for business logic (`checkout.process`, `inventory.reserve`).
- **Set `service.name` + `service.version` + `deployment.environment`** on every service. Resource attributes drive dashboard filtering and deploy-regression analysis.
- **Use OTel `LoggingHandler` / `OpenTelemetryAppender` / equivalent** so log records carry `trace_id` + `span_id` from the active span context. Logs without trace IDs in 2026 = broken instrumentation.

## Anti-patterns

- **Mixed semconv versions** across services — Service A on `http.method`, Service B on `http.request.method` → dashboards split across two attributes.
- **Vendor SDK first, OTel later** — the migration is brutal. Always OTel-first.
- **Manual `start_span` without `with` / context propagation** — span never closes, never exports.
- **`tracesSampleRate` at 100% on edge services without tail-sampling downstream** — Collector OOM, exporter retries, dropped spans.
- **No graceful shutdown call to `tp.shutdown()`** — last 1-5 seconds of traces lost on SIGTERM.

## Gotchas

- **Auto-instrumentation order matters.** Init OTel before importing the framework. Node `--require` before `node ./server.js`; Python `opentelemetry-instrument` wraps the entrypoint.
- **Cardinality enforcement is per-SDK** — set `View`s to drop high-cardinality attributes at the SDK before they reach the exporter.
- **Browser instrumentation is metrics+traces only** as of 2026-Q2. RUM-style features (session replay, heatmaps) require [Sentry](/stacks/observability/sentry-replay/), [Datadog RUM](/stacks/observability/datadog-rum/), or [Grafana Faro](/stacks/observability/grafana-faro/).
- **GenAI semconv is still moving.** Pin 1.32 for stability; expect agent conventions to land 2026-2027.

## Cross-references

- Application-side OTel SDK config per language → [backend-architect overlay](/stacks/observability/backend-architect/)
- Collector deployment topology → [otel-collector](/stacks/observability/otel-collector/) and [devops-engineer overlay](/stacks/observability/devops-engineer/)
- Attribute discipline + semconv migration → [otel-semantic-conventions](/stacks/observability/otel-semantic-conventions/)
- LLM observability → [otel-genai](/stacks/observability/otel-genai/)
- Authoritative: [opentelemetry.io/docs](https://opentelemetry.io/docs/), [GitHub open-telemetry](https://github.com/open-telemetry)
