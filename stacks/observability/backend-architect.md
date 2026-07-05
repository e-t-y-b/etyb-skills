---
title: Backend Architect on Observability
description: Backend architect's lens — OTel SDK per language, structured logging with trace correlation, custom metrics, LLM/agent observability.
role_overlay:
  role: backend-architect
  stack: observability
  last_verified_on: "2026-05-14"
  products_covered:
    - opentelemetry
    - otel-semantic-conventions
    - otel-genai
    - datadog-apm
    - datadog-llm-observability
    - newrelic-apm
    - newrelic-ai-monitoring
    - sentry-errors
    - sentry-performance
    - sentry-profiling
    - sentry-debug-ids
    - honeycomb-events
    - honeycomb-beelines
    - grafana-pyroscope
---

## Role briefing

You're the backend architect on an observability engagement. Your work is the **instrumentation layer in application code** — [OTel SDK setup](/stacks/observability/opentelemetry/) per language, span attributes that survive a vendor swap, structured log conventions, custom metric design, error reporting, LLM/agent observability, the API contracts that let your service be observable without becoming the cost center.

**Distinctive vs. the DevOps engineer:** the DevOps engineer owns *how the bytes flow from your service to the storage*; you own *what bytes leave your service in the first place*. You ship the SDK init, the resource attributes, the custom spans for business operations, the metric definitions that respect cardinality budgets.

## What's distinctive about backend on this Stack

- **You write the instrumentation that the SRE will define SLOs against.** Get the attributes wrong, the SLO breaks.
- **You own the semconv version pinning** across your services.
- **You own the structured logger configuration** — trace correlation, JSON output, level discipline.
- **You design custom metrics with cardinality in mind** — what's a label vs. an attribute on a span.

## 2025-2026 platform-reset items for backend

- **[OpenTelemetry](/stacks/observability/opentelemetry/) is the default SDK**, period. Vendor SDKs still have parity-plus in specific lanes ([DD Profiling](/stacks/observability/datadog-apm/), [NR Browser RUM](/stacks/observability/newrelic-apm/), SDK-native auto-instrumentation packs) but greenfield 2026 leads with OTel.
- **[Semantic conventions](/stacks/observability/otel-semantic-conventions/) are versioned.** Pin 1.28+; `http.method` → `http.request.method`, `http.status_code` → `http.response.status_code`, `http.url` → `url.full`. Pre-1.28 names = broken dashboards on a new vendor.
- **OTel Logs SDK is stable** — app code emits over OTLP with auto-correlation to active span.
- **OTel Profiles SDK landing** — Go and Java working; Node, Python catching up.
- **[GenAI semantic conventions](/stacks/observability/otel-genai/)** — `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`. Instrument LLM apps with OTel semconv.
- **Auto-instrumentation libraries matured** — `opentelemetry-instrumentation-*` (Python), OTel Java Agent, `@opentelemetry/auto-instrumentations-node` cover framework boundaries.
- **[Sentry Source Maps Debug IDs](/stacks/observability/sentry-debug-ids/)** mandatory for modern builds.
- **[Sentry Spans v2 + Tracing repricing](/stacks/observability/sentry-performance/)** — don't ship `tracesSampleRate: 1.0`; use dynamic sampling.
- **[Datadog APM Library Injection v2](/stacks/observability/datadog-apm/)** — inject `dd-trace-*` via Mutating Webhook. No SDK in Dockerfile.
- **Structured logging with trace correlation is table stakes.**

If you're shipping `dd-trace-py` first and "OTel later", `http.method` attributes on a semconv-1.28 SDK, Sentry releases without Debug IDs, or 100% trace sampling without checking SDK effective rate — your training is stale.

## OTel SDK setup by language

Same conceptual setup across languages: `TracerProvider` + `MeterProvider` + `LoggerProvider` with a `Resource` (service identity) and OTLP exporter to local Collector.

### Python

```python
resource = Resource.create({
    ResourceAttributes.SERVICE_NAME: "checkout-api",
    ResourceAttributes.SERVICE_VERSION: os.getenv("SERVICE_VERSION"),
    ResourceAttributes.DEPLOYMENT_ENVIRONMENT: os.getenv("DEPLOYMENT_ENVIRONMENT"),
    "team": "platform",
})
trace_provider = TracerProvider(resource=resource)
trace_provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="http://localhost:4317")))
trace.set_tracer_provider(trace_provider)
# Logs via LoggingHandler — auto trace correlation
```

Auto-instrument: `opentelemetry-instrument --service_name checkout-api python app.py` or via `opentelemetry-instrumentation-{flask,fastapi,django,requests,sqlalchemy,redis,kafka-python,celery,boto3}` packages.

### Node.js

Pre-load via `node --require ./tracing.js`:

```typescript
const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: 'checkout-api',
    [ATTR_SERVICE_VERSION]: process.env.SERVICE_VERSION,
    [ATTR_DEPLOYMENT_ENVIRONMENT]: process.env.DEPLOYMENT_ENVIRONMENT,
  }),
  traceExporter: new OTLPTraceExporter({ url: 'http://localhost:4317' }),
  instrumentations: [getNodeAutoInstrumentations({
    '@opentelemetry/instrumentation-fs': { enabled: false },
  })],
});
sdk.start();
process.on('SIGTERM', () => sdk.shutdown().finally(() => process.exit(0)));
```

### Java

```bash
java -javaagent:opentelemetry-javaagent.jar \
     -Dotel.service.name=checkout-api \
     -Dotel.exporter.otlp.endpoint=http://localhost:4317 \
     -jar app.jar
```

OTel Java Agent is the gold standard — auto-instruments JDBC, JMS, HTTP servers/clients, Kafka with no code.

### Go

Less auto-instrumentation; wrap framework boundaries with `otelhttp`, `otelgrpc`, `otelmux`, `otelchi`, `otelpgx`. Manual span creation more common.

### .NET

`AddOpenTelemetry()` with `WithTracing()` + `WithMetrics()` + `AddOtlpExporter()`. ASP.NET Core integration is native.

See [opentelemetry](/stacks/observability/opentelemetry/) for the seven concepts and patterns.

## Custom spans — business logic

Auto-instrumentation gives framework spans (HTTP request, DB query, queue publish). You add **business spans**:

```python
with tracer.start_as_current_span("checkout.process") as span:
    span.set_attribute("checkout.cart_id", cart_id)
    span.set_attribute("user.id", user_id)
    try:
        # ...
        span.set_status(trace.Status(trace.StatusCode.OK))
    except PaymentError as e:
        span.set_attribute("error.type", "payment")
        span.set_attribute("payment.failure_reason", e.code)
        span.record_exception(e)
        span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
        raise
```

Conventions:
- **Span name = operation**, low-cardinality. Don't include IDs in the name.
- **Attributes = high-cardinality context**.
- **`record_exception(e)` + `set_status(ERROR)`** for errors.
- **OTel semconv names** for known concepts (`http.*`, `db.*`), custom namespace for app-specific.

## Attribute discipline — semconv 1.28+

See [otel-semantic-conventions](/stacks/observability/otel-semantic-conventions/). Pin version repo-wide; migrate via Collector `transform` during transition.

## Structured logging with trace correlation

Every log line within an active span carries `trace_id` + `span_id`:

- **Python**: `structlog` + custom processor or OTel `LoggingHandler`.
- **Node**: `pino` with `mixin()` reading active span.
- **Java**: Logback + `OpenTelemetryAppender` or Logstash encoder with MDC.
- **Go**: custom `slog.Handler` reading context.

Conventions:
- **JSON output to stdout/stderr**.
- **One log line per event** (no multi-line tracebacks).
- **Top-level fields**: `timestamp`, `level`, `message`, `service.name`, `trace_id`, `span_id`.
- **No PII in messages** — see [security-engineer overlay](/stacks/observability/security-engineer/).
- **Avoid logging in tight loops** — sample or emit metric.

## Custom metrics — design discipline

### Naming

OTel semconv match where possible. Custom: `<domain>.<entity>.<operation>` (`checkout.cart.abandoned`). Counters end in present-tense verbs (`cart.abandoned`); don't end in `_total` in OTel (Prometheus exporter adds it).

### Cardinality budget

- **Low (<100 series)**: service-level RED.
- **Medium (<10K series)**: per-endpoint RED. Add `http.route`. Don't add `http.target` (full URL).
- **High (>10K series)**: probably should be traces. Reconsider.

Set cardinality limits via OTel `View`s — drop attributes before exporter.

### Histograms

Native histograms (Prometheus 3.x + OTel 1.27+): no manual bucket choice. Classic histograms: pick buckets matching SLI thresholds.

### Counter vs gauge

- **Counter**: only increases. `rate(counter[5m])`.
- **Gauge**: up or down. Query directly.
- **Histogram**: distribution. `histogram_quantile()`.

## LLM observability — [OTel GenAI](/stacks/observability/otel-genai/) semconv

```python
with tracer.start_as_current_span("gen_ai.chat") as span:
    span.set_attribute("gen_ai.system", "anthropic")
    span.set_attribute("gen_ai.request.model", "claude-sonnet-5")
    # ... TTFT capture, response handling
    span.set_attribute("gen_ai.usage.input_tokens", response.usage.input_tokens)
    span.set_attribute("gen_ai.usage.output_tokens", response.usage.output_tokens)
    span.set_attribute("gen_ai.cost.usd", compute_cost(model, response.usage))
```

For agent traces: nested `agent.execute` → `agent.step` → `agent.plan` / `agent.tool_call` spans. See [otel-genai](/stacks/observability/otel-genai/) for the agent pattern.

Vendor surfaces: [Datadog LLM Observability](/stacks/observability/datadog-llm-observability/), [New Relic AI Monitoring](/stacks/observability/newrelic-ai-monitoring/), [Honeycomb AI insights](/stacks/observability/honeycomb-events/), Langfuse (OSS).

## Error tracking with Sentry

Sentry sits alongside OTel for richer error capture — see [sentry-errors](/stacks/observability/sentry-errors/), [sentry-performance](/stacks/observability/sentry-performance/), [sentry-profiling](/stacks/observability/sentry-profiling/), [sentry-replay](/stacks/observability/sentry-replay/).

Key configurations:
- **`instrumenter: "otel"`** — Sentry uses OTel SDK context.
- **`SentrySpanProcessor`** on OTel TracerProvider — spans flow to both.
- **`tracesSampleRate: undefined`** for dynamic sampling.
- **`beforeSend` hook** to redact PII.

**Source maps via Debug IDs** — see [sentry-debug-ids](/stacks/observability/sentry-debug-ids/). Old `sentry-cli releases files upload-sourcemaps` produces broken stack traces in 2026. Migrate.

## Datadog SDK — when you need it beyond OTel

[Cases where DD-native beats OTel today](/stacks/observability/datadog-apm/):
- **Datadog Continuous Profiling** — `dd-trace-*` profilers still more featureful.
- **Datadog RUM Browser** — replay + heatmaps unique.
- **Datadog ASM** — needs `dd-trace` integration; no OTel equivalent.

Run `dd-trace` alongside OTel; correlate by `service.name` + `service.version` + `deployment.environment`.

## RED, USE, application-layer SLI

You emit:
- **RED**: `http.server.request.count` (rate), `http.server.request.duration` (histogram), `http.server.request.count{status_code=~"5.."}` (errors).
- **USE**: `process.cpu.time`, `process.memory.usage`, runtime metrics auto-instrumented (`opentelemetry-instrumentation-system-metrics`, OTel Java Agent's `runtime-telemetry`, `@opentelemetry/host-metrics`).

For business SLIs (cart-abandonment rate, checkout success rate): emit a counter per outcome; SRE computes ratio in metrics layer.

## Common mistakes

- **Multiple SDK versions in one repo** — mixed semconv → broken dashboards.
- **Manual `start_span` without `with` / context propagation** — span never closes.
- **Logging full LLM prompt** — PII, payload size, cost.
- **`tracesSampleRate: 1.0`** on Sentry in production.
- **No `service.version` resource attribute** — can't filter by deploy.
- **Span name with high-cardinality** (`GET /users/12345`) — every name unique.
- **`db.statement` with raw PII** — use parameterized values or `?` placeholders.
- **No graceful shutdown call to `tp.shutdown()`** — last 1-5s of traces lost.

## Integration with always-on protocols

- **TDD on instrumentation** — `InMemorySpanExporter` to assert spans have expected attributes; `InMemoryMetricReader` to assert metric increments.
- **Verification** — after instrumentation lands, verify trace appears in vendor within 60s; verify expected attributes + status; verify logs carry `trace_id`; verify metric appears with expected cardinality.
- **Plan execution** — instrumentation rollouts service-by-service: SDK init → resource attrs → auto-instrumentation → stage verify → custom spans → custom metrics → error reporting → logs correlation → prod deploy with revert plan.
- **Brainstorm-first** — for LLM/agent observability, brainstorm SLIs before adding spans.
- **Branch safety** — every instrumentation change is a PR with TDD assertions; SDK upgrades land in low-traffic services first.
- **Debugging** — trace missing? SDK init order, OTLP exporter URL, Collector receiver, sampling decision. Log without `trace_id`? Logger handler not wired to OTel context. Metric value wrong? Distinguish counter rate from raw value.

## Cross-references

- **Vendor selection and SLO design** → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- **Collector / Agent deployment topology** → [devops-engineer overlay](/stacks/observability/devops-engineer/)
- **PII scrubbing (SDS, Log Pipelines)** → [security-engineer overlay](/stacks/observability/security-engineer/)
- **OTel semconv reference** → [otel-semantic-conventions](/stacks/observability/otel-semantic-conventions/)
- **LLM observability evaluators + SLOs** → [sre-engineer overlay LLM section](/stacks/observability/sre-engineer/)
- **Stack index** → [/stacks/observability/](/stacks/observability/)
