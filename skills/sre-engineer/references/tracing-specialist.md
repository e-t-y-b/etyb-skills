# Distributed Tracing — Deep Reference

**Always use `WebSearch` to verify version numbers, tool features, and best practices before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Tracing Tool Selection](#1-tracing-tool-selection)
2. [OpenTelemetry](#2-opentelemetry)
3. [OpenTelemetry Collector](#3-opentelemetry-collector)
4. [Span Design & Naming](#4-span-design--naming)
5. [Sampling Strategies](#5-sampling-strategies)
6. [Trace Correlation](#6-trace-correlation)
7. [Performance & Overhead](#7-performance--overhead)
8. [Trace-Based Testing](#8-trace-based-testing)
9. [Storage & Retention](#9-storage--retention)
10. [Service Maps & Visualization](#10-service-maps--visualization)

---

## 1. Tracing Tool Selection

### Comparison Matrix (2025-2026)

| Feature | Jaeger v2 | Grafana Tempo | Zipkin | Datadog APM | AWS X-Ray | Elastic APM | Honeycomb | ServiceNow CO (Lightstep) |
|---|---|---|---|---|---|---|---|---|
| **License** | Apache 2.0 | AGPLv3 | Apache 2.0 | Proprietary | Proprietary | SSPL (Server) / Proprietary (Cloud) | Proprietary | Proprietary (EOL Mar 2026) |
| **Architecture** | OTel Collector-based (v2) | Microservices / monolithic | Single binary | SaaS agent | SaaS SDK/daemon | Elastic Stack | SaaS | SaaS |
| **Storage** | Cassandra, Elasticsearch, ClickHouse (coming), Badger, gRPC remote | Object storage (S3, GCS, Azure Blob) | Cassandra, Elasticsearch, MySQL, in-memory | Proprietary managed | Proprietary managed | Elasticsearch | Proprietary columnar | Proprietary |
| **Query Model** | Full search + trace ID | Trace ID lookup + TraceQL | Full search + trace ID | Full search + analytics | Trace ID + filter groups | Full search via KQL | High-cardinality exploration (BubbleUp) | Correlation + change intelligence |
| **Native OTel** | Yes (OTLP native) | Yes (OTLP native) | Via collector | Via OTel SDK or agent | Via ADOT collector | Via OTel agent | Yes (OTLP native) | Yes (OTLP native, was OTel co-creator) |
| **Sampling** | Head (SDK) + Tail (Collector) | Head (SDK) + Tail (Collector/Alloy) | Head only (SDK) | Intelligent (agent-side) | Reservoir sampling | Head + tail | Dynamic sampling | Head + tail |
| **Pricing** | Free (self-hosted) | Free (self-hosted) / Grafana Cloud traces from $0.50/GB | Free (self-hosted) | $31/host/mo APM + $0.10/M indexed spans | $5/M traces scanned | Free (self-managed) / Elastic Cloud usage-based | $0.007/10K events (Standard) | EOL March 2026 |
| **Operational Burden** | Medium (OTel Collector + storage backend) | Low-Medium (object storage only) | Low (simple, limited features) | None (SaaS) | None (SaaS) | High (Elastic cluster management) | None (SaaS) | N/A (sunsetting) |

### Tool Deep-Dives

#### Jaeger v2

Jaeger v2 (released Nov 2024) is a complete rewrite that embeds the OpenTelemetry Collector at its core. This is the single biggest architectural shift in the tracing ecosystem.

**Key changes from v1:**
- All-in-one binary is now an OTel Collector distribution with Jaeger storage extensions
- Native OTLP ingestion -- no more Thrift/gRPC translation overhead
- Configuration follows OTel Collector YAML format
- Batch-based internal pipeline benefits storage backends like ClickHouse
- Inherits all Collector capabilities: auth, cert reloading, health checks, z-pages

**v1 deprecation timeline:** Last v1 release was December 2025. v1 fully deprecated January 2026. If you are still on v1, migrate now.

**Best for:** Teams that want open-source full-text trace search with a proven UI, already run OTel Collector infrastructure, and need flexible storage backend choices.

**Avoid when:** You need a no-ops SaaS solution or your team lacks capacity to manage storage backends (Cassandra/ES clusters are non-trivial).

#### Grafana Tempo

Tempo is the only major backend that requires no indexing infrastructure. Spans go directly to object storage (S3, GCS, Azure Blob). This makes it dramatically cheaper at scale.

**Architecture:**
- Distributor: receives spans, hashes trace IDs for routing
- Ingester: buffers spans in memory, flushes blocks to object storage
- Compactor: merges small blocks, enforces retention
- Querier: fetches traces by ID or TraceQL from storage

**TraceQL (Tempo's query language):**
```
{ span.http.status_code >= 500 && span.http.method = "POST" && duration > 2s }
```

TraceQL enables structural queries across spans within a trace -- you can filter by span attributes, duration, status, and resource attributes without a full index.

**Best for:** Cost-sensitive environments at scale, Grafana stack users, teams that primarily use trace ID lookup or TraceQL rather than free-text search.

**Avoid when:** You need full ad-hoc search over all span attributes without knowing trace IDs (Tempo is improving here with vParquet4 and TraceQL metrics, but it is not Elasticsearch).

#### Zipkin

Still maintained but has not kept pace with the OTel-native world. In 2026, Zipkin is best viewed as a lightweight or educational tracing backend.

**Best for:** Small teams learning distributed tracing, simple architectures with <10 services, environments where minimal dependencies matter.

**Avoid when:** You need tail sampling, advanced analytics, service-level objectives, or integration into a broader observability stack.

#### Datadog APM

The most comprehensive commercial APM. Unmatched breadth: infrastructure monitoring, APM, logs, RUM, synthetics, security, profiling, and CI visibility in one platform.

**Strengths:**
- Auto-instrumentation agents for 15+ languages with near-zero configuration
- Intelligent tail-based sampling at the agent level (Datadog decides what to keep)
- Watchdog AI: automatic anomaly detection on traces
- Live Process and Live Containers correlation
- Error tracking with automatic issue grouping

**The cost problem:** Datadog pricing scales linearly and surprises teams at scale. APM at $31/host/month (annual) plus $0.10 per million indexed spans plus $1.70 per million ingested spans. A 200-host environment can exceed $100K/year on APM alone before adding other products.

**Best for:** Engineering teams with budget that want a single pane of glass and minimal operational overhead.

**Avoid when:** Cost predictability is critical, you want to avoid vendor lock-in, or you need OpenTelemetry-native workflows (Datadog supports OTel but steers toward its proprietary agent).

#### AWS X-Ray

Native AWS integration is the selling point. X-Ray auto-instruments Lambda, API Gateway, ECS, EKS, and most AWS SDKs.

**Critical 2025-2026 change:** AWS X-Ray SDKs and Daemon enter maintenance mode February 25, 2026. Only security patches after that date; end of support one year later. AWS is migrating X-Ray to use the OpenTelemetry SDK and AWS Distro for OpenTelemetry (ADOT) as the recommended instrumentation path. This is a clear signal that even AWS considers OTel the future.

**Best for:** AWS-heavy shops that want tracing with zero additional infrastructure and are willing to use ADOT as the instrumentation layer.

**Avoid when:** You run multi-cloud or hybrid, need advanced trace analytics, or want to avoid AWS-specific lock-in.

#### Elastic APM

Built on the Elastic Stack (Elasticsearch + Kibana). The key differentiator is search power -- Elasticsearch enables arbitrary queries over any span attribute with sub-second response times.

**Strengths:**
- Unmatched full-text search over trace data
- Correlations feature identifies attributes that correlate with latency/errors
- Service Map auto-generated from trace data
- Anomaly detection via ML on transaction durations
- Logs, metrics, APM, and infrastructure in one Elastic cluster

**Operational reality:** Running Elasticsearch clusters for trace data is non-trivial. Expect 3-5x storage cost compared to object-storage approaches. Hot-warm-cold tiering is essential for cost management.

**Best for:** Teams already running Elastic for logs that want unified observability, environments where full-text trace search is a hard requirement.

**Avoid when:** You do not want to manage Elasticsearch clusters, cost per GB of trace storage matters, or your team is small.

#### Honeycomb

Honeycomb pioneered the "observability" movement. Its core differentiator is high-cardinality data exploration. BubbleUp automatically identifies which attributes are different between slow/fast or error/success request populations.

**Strengths:**
- Unlimited cardinality with no pre-aggregation
- BubbleUp: automatic difference detection between populations
- Query-time aggregation over raw events
- SLO burn rate alerts natively integrated
- First-class OTel support (Honeycomb was co-created by OTel contributors)

**Trade-off:** Honeycomb is primarily a tracing and events platform. For metrics, you will need Prometheus/Grafana/Datadog alongside it. The unified "one tool for everything" pitch does not apply here.

**Best for:** Teams doing serious production debugging in complex distributed systems, organizations that value exploratory investigation over dashboards.

**Avoid when:** You want a single unified observability platform, your team prefers pre-built dashboards over exploratory queries, or budget is extremely tight.

#### ServiceNow Cloud Observability (Lightstep)

**EOL Notice:** ServiceNow announced end-of-life for Cloud Observability. Support ends March 1, 2026, or at contract end. There is no direct replacement or migration path from ServiceNow. If you are on Lightstep/SNCO, migrate now. Because Lightstep was OTel-native, switching to another OTel-compatible backend (Honeycomb, Grafana Cloud, SigNoz) requires zero re-instrumentation -- just change the OTLP endpoint.

### Decision Framework

```
START
  |
  v
Do you have budget for commercial SaaS?
  |-- Yes --> Do you need unified platform (APM + infra + logs + security)?
  |             |-- Yes --> Datadog (best breadth) or Elastic Cloud (best search)
  |             |-- No  --> Honeycomb (best debugging) or Grafana Cloud (best OSS ecosystem)
  |
  |-- No  --> Are you already running the Grafana stack (Prometheus + Loki)?
                |-- Yes --> Grafana Tempo (natural fit, cheapest storage)
                |-- No  --> Do you need full-text search over span attributes?
                              |-- Yes --> Jaeger v2 + Elasticsearch
                              |-- No  --> Jaeger v2 + ClickHouse or Tempo + S3
```

---

## 2. OpenTelemetry

### Architecture Overview

OpenTelemetry (OTel) is the CNCF-graduated standard for telemetry instrumentation. It is vendor-neutral, supported by every major observability vendor, and is the de facto standard for new instrumentation in 2026.

**Three layers:**

```
┌─────────────────────────────────────────────────────┐
│  Application Code                                   │
│  ┌───────────┐   ┌───────────┐   ┌───────────┐    │
│  │  OTel API  │   │  OTel API  │   │  OTel API  │   │
│  │  (Traces)  │   │ (Metrics)  │   │  (Logs)    │   │
│  └─────┬─────┘   └─────┬─────┘   └─────┬─────┘    │
│        │               │               │            │
│  ┌─────┴───────────────┴───────────────┴─────┐     │
│  │              OTel SDK                       │     │
│  │  (Samplers, SpanProcessors, Exporters,     │     │
│  │   Resource, Propagators)                    │     │
│  └─────────────────┬───────────────────────────┘     │
│                    │ OTLP (gRPC/HTTP)                │
└────────────────────┼─────────────────────────────────┘
                     │
                     v
           ┌─────────────────┐
           │  OTel Collector  │
           └─────────────────┘
```

- **API**: Thin, zero-dependency interfaces. Safe to use in libraries. No-op if SDK is not installed.
- **SDK**: Implements the API. Handles sampling, processing, batching, exporting. This is where configuration lives.
- **Collector**: Standalone binary that receives, processes, and exports telemetry. Decouples applications from backends.

### Signal Maturity Status (2026)

| Signal | API Status | SDK Status | Notes |
|--------|-----------|------------|-------|
| **Traces** | Stable | Stable (all major languages) | Production-ready since 2022. Fully mature. |
| **Metrics** | Stable | Stable (all major languages) | Production-ready. Delta and cumulative temporality. |
| **Logs** | Stable | Stable (all major languages) | Bridges existing log frameworks (Log4j, SLF4J, Python logging, slog). |
| **Profiling** | Alpha | Alpha (limited languages) | Entered public alpha March 2026. Do not use for critical production. GA target Q3 2026. |
| **Baggage** | Stable | Stable | Cross-cutting context propagation for key-value pairs. |

### Auto-Instrumentation by Language

| Language | Mechanism | Maturity | Key Libraries Covered |
|----------|-----------|----------|----------------------|
| **Java** | Java agent (`-javaagent`) | Stable, production-proven | Spring Boot, gRPC, JDBC, Hibernate, Kafka, Netty, Servlet, JAX-RS, Lettuce, Jedis |
| **Python** | `opentelemetry-instrument` CLI wrapper | Stable | Flask, Django, FastAPI, requests, urllib3, psycopg2, SQLAlchemy, Celery, aiohttp |
| **Node.js** | `@opentelemetry/auto-instrumentations-node` | Stable | Express, Fastify, Koa, http/https, gRPC, pg, mysql2, Redis, MongoDB, AWS SDK |
| **Go** | eBPF-based auto-instrumentation (beta 2025) | Beta | net/http, gRPC, database/sql, gin, echo. Does not require code changes or binary rebuild. |
| **.NET** | `OpenTelemetry.AutoInstrumentation` | Stable | ASP.NET Core, HttpClient, SqlClient, Entity Framework, gRPC, StackExchange.Redis |
| **Rust** | No auto-instrumentation | Manual only | `tracing-opentelemetry` crate bridges the `tracing` ecosystem to OTel. Manual span creation required. |

### SDK Setup Examples

#### Go

```go
package main

import (
    "context"
    "log"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/propagation"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

func initTracer(ctx context.Context) (func(), error) {
    exporter, err := otlptracegrpc.New(ctx,
        otlptracegrpc.WithEndpoint("otel-collector:4317"),
        otlptracegrpc.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }

    res, err := resource.New(ctx,
        resource.WithAttributes(
            semconv.ServiceName("order-service"),
            semconv.ServiceVersion("1.4.2"),
            semconv.DeploymentEnvironmentName("production"),
        ),
        resource.WithHost(),
        resource.WithProcess(),
    )
    if err != nil {
        return nil, err
    }

    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter,
            sdktrace.WithMaxQueueSize(2048),
            sdktrace.WithMaxExportBatchSize(512),
            sdktrace.WithBatchTimeout(5*time.Second),
        ),
        sdktrace.WithResource(res),
        sdktrace.WithSampler(
            sdktrace.ParentBased(sdktrace.TraceIDRatioBased(0.1)),
        ),
    )

    otel.SetTracerProvider(tp)
    otel.SetTextMapPropagator(
        propagation.NewCompositeTextMapPropagator(
            propagation.TraceContext{},
            propagation.Baggage{},
        ),
    )

    return func() {
        if err := tp.Shutdown(ctx); err != nil {
            log.Printf("Error shutting down tracer provider: %v", err)
        }
    }, nil
}
```

#### Python

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION
from opentelemetry.propagate import set_global_textmap
from opentelemetry.propagators.composite import CompositeHTTPPropagator
from opentelemetry.trace.propagation import TraceContextTextMapPropagator
from opentelemetry.baggage.propagation import W3CBaggagePropagator

def init_tracer():
    resource = Resource.create({
        SERVICE_NAME: "payment-service",
        SERVICE_VERSION: "2.1.0",
        "deployment.environment.name": "production",
    })

    exporter = OTLPSpanExporter(
        endpoint="otel-collector:4317",
        insecure=True,
    )

    provider = TracerProvider(
        resource=resource,
        # ParentBased sampler: respect parent decision, sample 10% of roots
        sampler=trace.sampling.ParentBased(
            root=trace.sampling.TraceIdRatioBased(0.1)
        ),
    )
    provider.add_span_processor(
        BatchSpanProcessor(
            exporter,
            max_queue_size=2048,
            max_export_batch_size=512,
            schedule_delay_millis=5000,
        )
    )

    trace.set_tracer_provider(provider)
    set_global_textmap(CompositeHTTPPropagator([
        TraceContextTextMapPropagator(),
        W3CBaggagePropagator(),
    ]))

    return provider
```

#### Node.js

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
} = require('@opentelemetry/semantic-conventions');
const { ParentBasedSampler, TraceIdRatioBasedSampler } = require('@opentelemetry/sdk-trace-base');
const { W3CTraceContextPropagator } = require('@opentelemetry/core');
const { W3CBaggagePropagator, CompositePropagator } = require('@opentelemetry/core');

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: 'inventory-service',
    [ATTR_SERVICE_VERSION]: '3.0.1',
    'deployment.environment.name': 'production',
  }),
  traceExporter: new OTLPTraceExporter({
    url: 'grpc://otel-collector:4317',
  }),
  sampler: new ParentBasedSampler({
    root: new TraceIdRatioBasedSampler(0.1),
  }),
  textMapPropagator: new CompositePropagator({
    propagators: [
      new W3CTraceContextPropagator(),
      new W3CBaggagePropagator(),
    ],
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      // Disable fs instrumentation -- too noisy in production
      '@opentelemetry/instrumentation-fs': { enabled: false },
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingPaths: ['/healthz', '/readyz', '/metrics'],
      },
    }),
  ],
});

sdk.start();

process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('OTel shutdown error:', err);
      process.exit(1);
    });
});
```

#### Java (Spring Boot)

```java
// build.gradle.kts
dependencies {
    implementation("io.opentelemetry:opentelemetry-api:1.45.0")
    implementation("io.opentelemetry:opentelemetry-sdk:1.45.0")
    implementation("io.opentelemetry:opentelemetry-exporter-otlp:1.45.0")
    implementation("io.opentelemetry:opentelemetry-sdk-extension-autoconfigure:1.45.0")
    implementation("io.opentelemetry.semconv:opentelemetry-semconv:1.29.0-alpha")
}

// For auto-instrumentation, use the Java agent instead of SDK setup:
// java -javaagent:opentelemetry-javaagent.jar \
//   -Dotel.service.name=user-service \
//   -Dotel.exporter.otlp.endpoint=http://otel-collector:4317 \
//   -Dotel.traces.sampler=parentbased_traceidratio \
//   -Dotel.traces.sampler.arg=0.1 \
//   -jar user-service.jar

// Programmatic SDK setup (when agent is not suitable):
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.sdk.trace.samplers.Sampler;
import io.opentelemetry.semconv.ResourceAttributes;

public class TracerConfig {
    public static OpenTelemetry initOpenTelemetry() {
        Resource resource = Resource.getDefault()
            .merge(Resource.create(Attributes.builder()
                .put(ResourceAttributes.SERVICE_NAME, "user-service")
                .put(ResourceAttributes.SERVICE_VERSION, "1.0.0")
                .put(ResourceAttributes.DEPLOYMENT_ENVIRONMENT_NAME, "production")
                .build()));

        OtlpGrpcSpanExporter exporter = OtlpGrpcSpanExporter.builder()
            .setEndpoint("http://otel-collector:4317")
            .build();

        SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
            .setResource(resource)
            .addSpanProcessor(BatchSpanProcessor.builder(exporter)
                .setMaxQueueSize(2048)
                .setMaxExportBatchSize(512)
                .setScheduleDelay(java.time.Duration.ofSeconds(5))
                .build())
            .setSampler(Sampler.parentBased(Sampler.traceIdRatioBased(0.1)))
            .build();

        return OpenTelemetrySdk.builder()
            .setTracerProvider(tracerProvider)
            .setPropagators(io.opentelemetry.context.propagation.ContextPropagators.create(
                io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator.getInstance()))
            .build();
    }
}
```

### Context Propagation

**W3C TraceContext** (the standard -- use this by default):
```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
             ^  ^                                ^                  ^
             |  trace-id (128-bit)               span-id (64-bit)  flags (sampled)
tracestate: congo=t61rcWkgMzE,rojo=00f067aa0ba902b7
```

**B3 Propagation** (legacy Zipkin format, still needed for older services):
```
X-B3-TraceId: 4bf92f3577b34da6a3ce929d0e0e4736
X-B3-SpanId: 00f067aa0ba902b7
X-B3-Sampled: 1
```

**Production tip:** If migrating from Zipkin/B3 to W3C, use composite propagators that read B3 headers but write both W3C + B3 during the transition:

```go
otel.SetTextMapPropagator(
    propagation.NewCompositeTextMapPropagator(
        propagation.TraceContext{},  // W3C (primary)
        b3.New(b3.WithInjectEncoding(b3.B3MultipleHeader)), // B3 compat
    ),
)
```

### Baggage API

Baggage propagates key-value pairs across service boundaries within a trace. Useful for passing tenant IDs, feature flags, or request metadata without modifying service interfaces.

```python
from opentelemetry import baggage, context

# Set baggage in upstream service
ctx = baggage.set_baggage("tenant.id", "acme-corp")
ctx = baggage.set_baggage("feature.flags", "new-checkout=true", context=ctx)

# Read baggage in downstream service (propagated automatically via headers)
tenant = baggage.get_baggage("tenant.id")
```

**Warning:** Baggage is sent as HTTP headers in cleartext. Never put sensitive data (tokens, PII) in baggage. Keep baggage entries small -- they add to every inter-service request.

---

## 3. OpenTelemetry Collector

### Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    OTel Collector                          │
│                                                            │
│  ┌───────────┐   ┌────────────┐   ┌───────────────┐      │
│  │ Receivers  │──>│ Processors │──>│   Exporters    │      │
│  └───────────┘   └────────────┘   └───────────────┘      │
│                                                            │
│  ┌───────────┐                    ┌───────────────┐      │
│  │ Extensions │                    │  Connectors    │      │
│  │ (health,   │                    │  (pipe signal  │      │
│  │  zpages,   │                    │   A to signal  │      │
│  │  pprof)    │                    │   B pipeline)  │      │
│  └───────────┘                    └───────────────┘      │
└──────────────────────────────────────────────────────────┘
```

- **Receivers**: Ingest data. OTLP (gRPC + HTTP), Jaeger, Zipkin, Prometheus, Kafka, filelog, hostmetrics.
- **Processors**: Transform data in-flight. Batch, filter, attributes, tail_sampling, memory_limiter, transform, span, resource.
- **Exporters**: Send data to backends. OTLP, Jaeger, Prometheus, Loki, Kafka, debug, file.
- **Connectors**: Act as both exporter and receiver, bridging two pipelines. The `spanmetrics` connector generates RED metrics from trace data.
- **Extensions**: Auxiliary services. health_check, zpages, pprof, basicauth, bearertokenauth, oauth2clientauth.

### Deployment Patterns

#### Agent (DaemonSet / Sidecar)

```
┌──────────────────────────────────┐
│           Kubernetes Node         │
│  ┌─────────┐  ┌─────────┐       │
│  │  App A   │  │  App B   │       │
│  └────┬─────┘  └────┬─────┘      │
│       │              │            │
│       v              v            │
│  ┌────────────────────────┐      │
│  │   OTel Collector Agent  │      │
│  │   (DaemonSet)           │      │
│  │   - batch               │      │
│  │   - memory_limiter      │      │
│  │   - resourcedetection   │      │
│  └────────────┬────────────┘      │
└───────────────┼───────────────────┘
                │ OTLP
                v
        ┌───────────────┐
        │  Gateway Pool  │
        └───────────────┘
```

**When to use agent pattern:**
- Host-level metadata enrichment (k8s pod/node attributes)
- Reducing per-application configuration
- Low per-node resource overhead (~50-100MB RAM, <0.5 CPU)

#### Gateway

```
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │  Agent 1  │  │  Agent 2  │  │  Agent N  │
        └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
              │              │              │
              v              v              v
        ┌────────────────────────────────────────┐
        │         Load Balancer (L4/L7)          │
        └─────────────────┬──────────────────────┘
                          │
           ┌──────────────┼──────────────┐
           v              v              v
     ┌──────────┐  ┌──────────┐  ┌──────────┐
     │ Gateway 1 │  │ Gateway 2 │  │ Gateway 3 │
     │ - tail    │  │ - tail    │  │ - tail    │
     │   sampling│  │   sampling│  │   sampling│
     │ - transform│  │ - transform│ │ - transform│
     └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
           │              │              │
           v              v              v
     ┌─────────────────────────────────────┐
     │          Backend (Tempo/Jaeger)      │
     └─────────────────────────────────────┘
```

**When to use gateway pattern:**
- Centralized tail-based sampling (all spans for a trace must reach the same gateway)
- Cross-service processing, enrichment, or routing
- Multi-backend fan-out (export to Tempo AND Datadog simultaneously)

#### Two-Tier for Tail Sampling

Tail sampling requires all spans of a trace to arrive at the same Collector instance. Use trace-aware load balancing:

```
Tier 1 (Agents):
  - loadbalancing exporter (routes by trace_id)

Tier 2 (Gateways):
  - tail_sampling processor (makes sampling decisions)
```

### Pipeline Configuration -- Production Example

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
        max_recv_msg_size_mib: 16
      http:
        endpoint: 0.0.0.0:4318

processors:
  # Memory safety -- always first in the chain
  memory_limiter:
    check_interval: 1s
    limit_mib: 1536        # Hard limit
    spike_limit_mib: 512   # Spike buffer

  # Batch for efficiency
  batch:
    send_batch_size: 8192
    send_batch_max_size: 16384
    timeout: 5s

  # Drop health check and readiness probe spans
  filter:
    error_mode: ignore
    traces:
      span:
        - 'attributes["http.route"] == "/healthz"'
        - 'attributes["http.route"] == "/readyz"'
        - 'attributes["http.route"] == "/metrics"'

  # Enrich with k8s metadata
  resourcedetection:
    detectors: [env, system, gcp, aws, azure]
    timeout: 5s
    override: false

  # Add/modify attributes
  attributes:
    actions:
      - key: environment
        value: production
        action: upsert

  # Tail sampling (gateway only)
  tail_sampling:
    decision_wait: 30s
    num_traces: 100000
    expected_new_traces_per_sec: 1000
    policies:
      # Keep all error traces
      - name: errors-policy
        type: status_code
        status_code:
          status_codes: [ERROR]
      # Keep slow traces (>2s)
      - name: latency-policy
        type: latency
        latency:
          threshold_ms: 2000
      # Keep traces with specific attributes
      - name: important-operations
        type: string_attribute
        string_attribute:
          key: operation.critical
          values: [true]
      # Sample remaining traces at 10%
      - name: probabilistic-policy
        type: probabilistic
        probabilistic:
          sampling_percentage: 10
      # Always keep traces that hit specific services
      - name: payment-traces
        type: ottl_condition
        ottl_condition:
          span:
            - 'resource.attributes["service.name"] == "payment-service"'

exporters:
  otlp/tempo:
    endpoint: tempo-distributor:4317
    tls:
      insecure: true
    retry_on_failure:
      enabled: true
      initial_interval: 5s
      max_interval: 30s
      max_elapsed_time: 300s

  otlp/jaeger:
    endpoint: jaeger-collector:4317
    tls:
      insecure: true

  debug:
    verbosity: basic

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  zpages:
    endpoint: 0.0.0.0:55679
  pprof:
    endpoint: 0.0.0.0:1777

connectors:
  # Generate RED metrics from traces
  spanmetrics:
    histogram:
      explicit:
        buckets: [5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s, 10s]
    dimensions:
      - name: http.method
      - name: http.status_code
      - name: http.route
    exemplars:
      enabled: true

service:
  extensions: [health_check, zpages, pprof]

  pipelines:
    traces/ingest:
      receivers: [otlp]
      processors: [memory_limiter, filter, resourcedetection, attributes, tail_sampling, batch]
      exporters: [otlp/tempo, spanmetrics]

    metrics/spanmetrics:
      receivers: [spanmetrics]
      processors: [batch]
      exporters: [otlp/tempo]

  telemetry:
    logs:
      level: info
    metrics:
      address: 0.0.0.0:8888
```

### Key Processors Deep-Dive

| Processor | Purpose | Production Notes |
|---|---|---|
| `memory_limiter` | Prevents OOM. Always first in chain. | Set `limit_mib` to 80% of container memory limit. Set `spike_limit_mib` to 25% of `limit_mib`. |
| `batch` | Reduces export calls. Groups spans into batches. | `send_batch_size: 8192` is a good default. `timeout: 5s` prevents stale data. |
| `tail_sampling` | Makes sampling decisions after trace completion. | `decision_wait` must be longer than your longest trace. `num_traces` is the in-memory buffer -- size it for (traces/sec * decision_wait). |
| `filter` | Drops unwanted spans/metrics/logs. | Use `error_mode: ignore` to prevent pipeline crashes from filter expression errors. |
| `transform` | OTTL-based mutation of any telemetry field. | Replaces `attributes`, `span`, and `resource` processors for complex transformations. |
| `attributes` | Add/update/delete/hash span attributes. | Use for enrichment (add environment), redaction (hash PII), and cleanup. |
| `span` | Rename spans, extract attributes from span name. | Useful for normalizing span names from different instrumentation libraries. |
| `resourcedetection` | Auto-detects cloud/host/k8s metadata. | Set `override: false` to avoid overwriting application-set attributes. |
| `probabilistic_sampler` | Head-based probabilistic sampling. | Use at agent level. For tail-based, use `tail_sampling` at gateway level. |

### Health Monitoring

Monitor the Collector itself via its internal metrics (exposed on port 8888 by default):

```promql
# Spans received vs exported (detect drops)
rate(otelcol_receiver_accepted_spans[5m])
rate(otelcol_exporter_sent_spans[5m])

# Queue utilization (approaching capacity = risk of drops)
otelcol_exporter_queue_size / otelcol_exporter_queue_capacity

# Memory limiter triggers (data being dropped to protect the process)
rate(otelcol_processor_refused_spans[5m])

# Export failures
rate(otelcol_exporter_send_failed_spans[5m])
```

**Alert on:**
- `otelcol_processor_refused_spans > 0` -- memory limiter is actively dropping data
- `otelcol_exporter_queue_size / otelcol_exporter_queue_capacity > 0.8` -- export queue nearing capacity
- `otelcol_exporter_send_failed_spans` sustained increase -- backend is unavailable

---

## 4. Span Design & Naming

### What to Instrument

**Always instrument (service boundaries):**
- Inbound HTTP/gRPC requests (auto-instrumentation handles this)
- Outbound HTTP/gRPC calls to other services
- Database queries (SQL, NoSQL)
- Cache operations (Redis, Memcached)
- Message queue publish/consume (Kafka, RabbitMQ, SQS)
- External API calls (payment gateways, third-party services)

**Instrument selectively (internal operations):**
- CPU-intensive business logic (>10ms)
- File I/O operations
- Complex calculations or transformations
- Retry/circuit breaker operations

**Do not instrument:**
- Trivial getters/setters
- Simple in-memory lookups
- Operations under 1ms (the span overhead exceeds the value)
- Every loop iteration (use span events for batch operations)

### Span Naming Conventions

Follow OTel semantic conventions. The pattern is `{VERB} {OBJECT}` with low cardinality:

```
GOOD (low cardinality):
  HTTP server:    GET /api/users/{userId}
  HTTP client:    GET api.stripe.com
  Database:       SELECT products
  Message queue:  orders.created publish
  gRPC:           grpc.health.v1.Health/Check
  Internal:       ProcessPayment
  Cache:          redis GET

BAD (high cardinality -- will explode your backend):
  GET /api/users/12345          <-- user ID in span name
  SELECT * FROM products WHERE id = 99   <-- query params in span name
  Process order ORD-2026-04-12345        <-- order ID in span name
```

**Rule:** Parameterized values go in span attributes, never in span names. Span names are for grouping; attributes are for filtering.

### Attribute Selection

Follow OTel semantic conventions for common attributes:

```go
// HTTP spans (server)
span.SetAttributes(
    semconv.HTTPRequestMethodKey.String("GET"),
    semconv.HTTPResponseStatusCode(200),
    semconv.HTTPRoute("/api/users/{userId}"),
    semconv.URLPath("/api/users/12345"),
    semconv.URLScheme("https"),
    semconv.ServerAddress("api.example.com"),
    semconv.UserAgentOriginal(r.UserAgent()),
)

// Database spans
span.SetAttributes(
    semconv.DBSystemPostgreSQL,
    semconv.DBNamespace("orders_db"),
    semconv.DBOperationName("SELECT"),
    semconv.DBCollectionName("products"),
    semconv.DBQueryText("SELECT id, name, price FROM products WHERE category = $1"),
    semconv.ServerAddress("db-primary.internal"),
    semconv.ServerPort(5432),
)

// Messaging spans
span.SetAttributes(
    semconv.MessagingSystemKafka,
    semconv.MessagingOperationTypePublish,
    semconv.MessagingDestinationName("orders.created"),
    semconv.MessagingKafkaMessageOffset(12345),
    semconv.MessagingMessageBodySize(1024),
)
```

**Custom attributes -- use domain prefixes:**
```go
span.SetAttributes(
    attribute.String("order.id", "ORD-2026-04-12345"),
    attribute.Float64("order.total", 149.99),
    attribute.String("order.currency", "USD"),
    attribute.String("customer.tier", "premium"),
    attribute.Bool("feature_flag.new_checkout", true),
)
```

### Span Events vs Child Spans

**Use span events** for point-in-time occurrences within a span that do not have duration:
```go
span.AddEvent("cache.miss", trace.WithAttributes(
    attribute.String("cache.key", "user:12345:profile"),
))
span.AddEvent("retry.attempt", trace.WithAttributes(
    attribute.Int("retry.count", 2),
    attribute.String("retry.reason", "timeout"),
))
```

**Use child spans** for operations with meaningful duration that you want to measure independently:
```go
ctx, childSpan := tracer.Start(ctx, "ValidatePaymentDetails",
    trace.WithAttributes(
        attribute.String("payment.method", "credit_card"),
    ),
)
defer childSpan.End()
```

**Guideline:** If the operation takes <1ms or has no independent duration, use an event. If it takes >1ms and you want latency breakdown, use a child span.

### Span Status and Error Recording

```go
import "go.opentelemetry.io/otel/codes"

// Set error status with description
span.SetStatus(codes.Error, "payment gateway timeout")

// Record exception with stack trace (as span event)
span.RecordError(err, trace.WithAttributes(
    attribute.String("exception.type", "PaymentGatewayTimeout"),
    attribute.Bool("error.retryable", true),
))

// IMPORTANT: RecordError does NOT set span status.
// Always call both RecordError AND SetStatus.
span.RecordError(err)
span.SetStatus(codes.Error, err.Error())
```

**Status codes:**
- `Unset` -- default. Backend decides how to interpret.
- `Ok` -- explicitly successful. Only set this when you want to override a child error.
- `Error` -- operation failed.

**Production pattern:** Never set `Ok` status on every span. Only set it when you need to explicitly override an inherited error status. Use `Error` for failures. Leave everything else `Unset`.

### Span Links for Async Operations

Span links connect causally related traces that do not have a parent-child relationship. Common in async systems:

```go
// Consumer creates a new trace but links back to the producer span
producerCtx := // extracted from message headers
producerSpanCtx := trace.SpanContextFromContext(producerCtx)

ctx, consumerSpan := tracer.Start(ctx, "orders.created process",
    trace.WithLinks(trace.Link{
        SpanContext: producerSpanCtx,
        Attributes: []attribute.KeyValue{
            attribute.String("messaging.source", "orders.created"),
        },
    }),
)
```

**Use span links when:**
- Message queue consumer processing a message (link to producer)
- Batch processing: a single span processes multiple requests (link to each request trace)
- Fan-out: one request triggers multiple independent operations
- Scheduled jobs triggered by an original request

---

## 5. Sampling Strategies

### Head-Based Sampling

Decisions made at trace creation time. Low overhead, but cannot consider trace outcome.

**Probability sampler:**
```yaml
# Sample 10% of traces uniformly
sampler: traceidratio
sampler_arg: 0.1
```

**Rate-limiting sampler:**
```yaml
# Maximum 100 traces per second, regardless of traffic volume
sampler: rate_limiting
sampler_arg: 100
```

**Parent-based sampler (recommended default):**
```yaml
# Respect parent's sampling decision. For root spans, sample 10%.
sampler: parentbased_traceidratio
sampler_arg: 0.1
```

Parent-based sampling is critical for trace consistency. Without it, you get orphaned child spans where the parent was sampled out, or missing children where the child was sampled out.

### Tail-Based Sampling

Decisions made after trace completion. Requires buffering all spans until the trace is considered complete.

**Advantages:**
- Keep 100% of error traces
- Keep all high-latency traces
- Keep traces with specific attributes (VIP customers, specific operations)
- Dramatically reduce storage while retaining all "interesting" data

**Disadvantages:**
- Requires stateful Collector (all spans for one trace must reach same instance)
- Memory pressure: buffering traces in-flight
- Added latency before data appears in backend (decision_wait period)
- Complexity of two-tier Collector deployment

### Tail Sampling Processor Configuration

```yaml
processors:
  tail_sampling:
    # How long to wait for a trace to complete before making a decision.
    # Must be longer than your longest expected trace duration.
    decision_wait: 30s

    # Maximum number of traces held in memory.
    # When exceeded, OLDEST traces are force-decided (likely dropped).
    # Size this as: expected_new_traces_per_sec * decision_wait * 1.5
    num_traces: 150000

    # Used for internal memory pre-allocation.
    expected_new_traces_per_sec: 5000

    # Policies are evaluated in order. First match wins for AND logic;
    # use composite policy for OR/AND combinations.
    policies:
      # 1. Keep ALL error traces -- non-negotiable
      - name: keep-errors
        type: status_code
        status_code:
          status_codes: [ERROR]

      # 2. Keep traces slower than p99 threshold
      - name: keep-slow-traces
        type: latency
        latency:
          threshold_ms: 3000
          upper_threshold_ms: 0  # 0 = no upper limit

      # 3. Keep traces from critical services
      - name: keep-payment-traces
        type: string_attribute
        string_attribute:
          key: service.name
          values: [payment-service, fraud-detection]
          enabled_regex_matching: false

      # 4. Keep traces that match custom OTTL conditions
      - name: keep-high-value-orders
        type: ottl_condition
        ottl_condition:
          span:
            - 'attributes["order.total"] != nil and Double(attributes["order.total"]) > 1000.0'

      # 5. Composite policy: AND multiple conditions
      - name: composite-policy
        type: composite
        composite:
          max_total_spans_per_second: 5000
          policy_order: [health-check-drop, error-keep, baseline]
          composite_sub_policy:
            - name: health-check-drop
              type: string_attribute
              string_attribute:
                key: http.route
                values: [/healthz, /readyz]
            - name: error-keep
              type: status_code
              status_code:
                status_codes: [ERROR]
            - name: baseline
              type: probabilistic
              probabilistic:
                sampling_percentage: 5
          rate_allocation:
            - policy: health-check-drop
              percent: 0   # Drop all health checks
            - policy: error-keep
              percent: 50  # Allocate 50% of budget to errors
            - policy: baseline
              percent: 50  # Remaining 50% for probabilistic baseline
```

### Memory Sizing for Tail Sampling

This is where most production deployments fail. The math:

```
Memory required = traces_per_second * decision_wait_seconds * avg_spans_per_trace * avg_span_size_bytes

Example:
  1,000 traces/sec * 30s wait * 5 spans/trace * 2KB/span = 300MB of span data in buffer
  Add 50% overhead for hash maps and metadata = ~450MB

  With num_traces = 30,000 (1000 * 30):
  If a burst pushes to 2,000 traces/sec, you need num_traces = 60,000 or oldest traces get dropped.
```

**Production recommendation:** Set `num_traces` to 2-3x your expected `traces_per_sec * decision_wait_seconds`. Monitor `otelcol_processor_tail_sampling_count_traces_sampled` and the memory usage of the Collector pod.

### Adaptive Sampling

Adjust sampling rates dynamically based on traffic volume. Not built into OTel natively, but achievable through:

1. **Honeycomb Refinery**: Standalone tail-sampling proxy that supports dynamic rate targeting.
2. **Custom controller**: Monitor trace volume, adjust `probabilistic_sampler` rate via Collector config reload.
3. **Grafana Alloy**: Supports tail sampling with automatic scaling across instances using a shared ring.

### The Sampling Decision Flow

```
Request arrives
    │
    v
Is there a parent span context?
    │
    ├── Yes: Parent sampled? ──> Yes: SAMPLE (maintain trace consistency)
    │                        ──> No:  DROP   (maintain trace consistency)
    │
    ├── No (root span): HEAD SAMPLING DECISION
    │       │
    │       v
    │   Apply SDK sampler (probability, rate-limit, custom)
    │       │
    │       v
    │   Sampled? ──> Yes: Create span, propagate sampled flag
    │            ──> No:  Create no-op span, propagate unsampled flag
    │
    v
Spans flow to Collector
    │
    v
TAIL SAMPLING at Gateway (if configured)
    │
    v
Wait for trace completion (decision_wait)
    │
    v
Evaluate policies (error? slow? specific attribute?)
    │
    v
Keep or drop entire trace
```

### Trade-offs: Cost vs Visibility

| Strategy | Typical Reduction | Errors Retained | Latency Outliers | Cost Savings |
|---|---|---|---|---|
| Head 100% | 0% | 100% | 100% | None |
| Head 10% | 90% | ~10% | ~10% | ~90% |
| Tail (errors + slow + 5%) | 85-95% | 100% | 100% | ~85-95% |
| Tail (errors only + 1%) | 95-99% | 100% | Some missed | ~95-99% |
| Adaptive (target rate) | Variable | 100% | Most kept | Variable |

**Production recommendation:** Start with `ParentBased(TraceIDRatio(1.0))` at SDK level (sample everything) and use tail sampling at the Collector gateway to make intelligent keep/drop decisions. This gives you maximum flexibility without re-deploying applications to change sampling rates.

---

## 6. Trace Correlation

### Traces to Metrics (Exemplars)

Exemplars attach trace IDs to metric data points, enabling direct jumps from a metric spike to the offending trace.

**How it works:**
1. OTel SDK records a metric (e.g., HTTP request duration histogram)
2. SDK attaches the current span's trace ID as an exemplar
3. Prometheus scrapes the metric with exemplars
4. Grafana displays exemplar dots on metric graphs
5. Clicking an exemplar dot opens the trace in Tempo

**Prometheus exemplar configuration:**

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

# Enable exemplar storage
storage:
  exemplars:
    max_exemplars: 100000

scrape_configs:
  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8889']

# If using remote_write to Mimir/Thanos/Cortex:
remote_write:
  - url: http://mimir:9009/api/v1/push
    send_exemplars: true  # Critical: must be explicitly enabled
```

**OTel Collector spanmetrics connector (generates metrics with exemplars):**

```yaml
connectors:
  spanmetrics:
    histogram:
      explicit:
        buckets: [5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s, 10s]
    dimensions:
      - name: http.method
      - name: http.status_code
      - name: http.route
    exemplars:
      enabled: true
    namespace: traces.spanmetrics

exporters:
  prometheusremotewrite:
    endpoint: http://mimir:9009/api/v1/push
    send_metadata: true
```

**PromQL with exemplars in Grafana:**
```promql
# View histogram with exemplars overlaid
histogram_quantile(0.99,
  sum(rate(traces_spanmetrics_duration_milliseconds_bucket{service_name="order-service"}[5m])) by (le)
)
```

In Grafana, enable "Exemplars" toggle in the query editor. Configure the Prometheus data source with an "Internal link" pointing to your Tempo data source, mapping `trace_id` to the TraceQL query.

### Traces to Logs

Inject trace context (trace_id, span_id) into every log record so you can jump from a trace span to the exact log lines emitted during that span.

#### Go (slog + OTel)

```go
package logging

import (
    "context"
    "log/slog"

    "go.opentelemetry.io/otel/trace"
)

// TraceHandler wraps an slog.Handler to inject trace context
type TraceHandler struct {
    slog.Handler
}

func (h TraceHandler) Handle(ctx context.Context, r slog.Record) error {
    spanCtx := trace.SpanContextFromContext(ctx)
    if spanCtx.IsValid() {
        r.AddAttrs(
            slog.String("trace_id", spanCtx.TraceID().String()),
            slog.String("span_id", spanCtx.SpanID().String()),
            slog.String("trace_flags", spanCtx.TraceFlags().String()),
        )
    }
    return h.Handler.Handle(ctx, r)
}

// Usage:
// logger := slog.New(TraceHandler{Handler: slog.NewJSONHandler(os.Stdout, nil)})
// logger.InfoContext(ctx, "order processed", "order_id", "ORD-123")
//
// Output:
// {"time":"2026-04-14T10:00:00Z","level":"INFO","msg":"order processed",
//  "order_id":"ORD-123","trace_id":"4bf92f3577b34da6a3ce929d0e0e4736",
//  "span_id":"00f067aa0ba902b7","trace_flags":"01"}
```

#### Python (structlog + OTel)

```python
import structlog
from opentelemetry import trace

def add_trace_context(logger, method_name, event_dict):
    span = trace.get_current_span()
    ctx = span.get_span_context()
    if ctx.is_valid:
        event_dict["trace_id"] = format(ctx.trace_id, '032x')
        event_dict["span_id"] = format(ctx.span_id, '016x')
        event_dict["trace_flags"] = format(ctx.trace_flags, '02x')
    return event_dict

structlog.configure(
    processors=[
        add_trace_context,
        structlog.processors.JSONRenderer(),
    ]
)

logger = structlog.get_logger()
# logger.info("payment processed", order_id="ORD-123", amount=99.99)
```

#### Node.js (pino + OTel)

```javascript
const pino = require('pino');
const { trace, context } = require('@opentelemetry/api');

const logger = pino({
  mixin() {
    const span = trace.getSpan(context.active());
    if (span) {
      const spanContext = span.spanContext();
      return {
        trace_id: spanContext.traceId,
        span_id: spanContext.spanId,
        trace_flags: `0${spanContext.traceFlags.toString(16)}`,
      };
    }
    return {};
  },
});

// logger.info({ orderId: 'ORD-123' }, 'payment processed');
```

#### Java (Logback + OTel Java Agent)

The OTel Java agent automatically injects trace context into MDC. Configure Logback pattern:

```xml
<!-- logback.xml -->
<configuration>
  <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%d{ISO8601} [%thread] %-5level %logger{36} trace_id=%X{trace_id} span_id=%X{span_id} - %msg%n</pattern>
    </encoder>
  </appender>

  <!-- JSON format for production (Loki/Elasticsearch ingest) -->
  <appender name="JSON" class="ch.qos.logback.core.ConsoleAppender">
    <encoder class="net.logstash.logback.encoder.LogstashEncoder">
      <includeMdcKeyName>trace_id</includeMdcKeyName>
      <includeMdcKeyName>span_id</includeMdcKeyName>
      <includeMdcKeyName>trace_flags</includeMdcKeyName>
    </encoder>
  </appender>

  <root level="INFO">
    <appender-ref ref="JSON" />
  </root>
</configuration>
```

### Correlated Views in Grafana

**Loki to Tempo (log to trace):**

Configure Loki data source in Grafana with a derived field:
```
Name:     TraceID
Regex:    "trace_id":"(\w+)"
URL:      ${__value.raw}
Internal link:  Tempo data source
```

**LogQL query to find logs for a trace:**
```logql
{service_name="order-service"} | json | trace_id = "4bf92f3577b34da6a3ce929d0e0e4736"
```

**Tempo to Loki (trace to logs):**
In Grafana Tempo data source settings, configure "Trace to logs" pointing to Loki with `service.name` mapped to `service_name` label.

**The full correlation chain:**
```
Metric (Prometheus/Mimir)  ──exemplar──>  Trace (Tempo)  ──trace_id──>  Logs (Loki)
          ^                                    │
          │                                    │
          └─────── spanmetrics connector ──────┘
```

---

## 7. Performance & Overhead

### Instrumentation Overhead

Tracing is not free. Every span creation involves memory allocation, timestamp capture, attribute storage, and async export. The goal is to keep total overhead under a strict budget.

**Production overhead budgets:**

| Metric | Target | Red Line |
|---|---|---|
| CPU overhead | < 2-3% | > 5% requires investigation |
| Memory overhead | < 30-50MB for SDK + exporter | > 100MB indicates a leak or misconfiguration |
| Latency added per span | < 1 microsecond (creation) | > 10 microseconds per span is a problem |
| Network bandwidth | < 1% of service traffic | Monitor OTLP export bytes |

### Measured Benchmarks (2025-2026)

**Java agent overhead (OTel Java agent):**
- Startup latency: +2-5 seconds (agent attachment and bytecode transformation)
- Steady-state CPU: +1-3% (with default sampling)
- Memory: +30-50MB heap for agent structures
- P99 latency impact: +0.5-2ms per request (varies by instrumentation count)

**Go SDK overhead:**
- CPU: +1-2% at 1000 spans/second with batch exporter
- Memory: +15-25MB for SDK + batch buffer
- A 2025 study showed CPU increases of 18-49% in micro-benchmarks, but real-world services see much lower impact due to application CPU dominating

**Node.js SDK overhead:**
- CPU: +2-5% (higher due to single-threaded nature)
- Memory: +20-40MB
- Event loop lag: +0.1-0.5ms (monitor with `perf_hooks`)

**Python SDK overhead:**
- CPU: +3-8% (Python's GIL makes instrumentation more costly per-span)
- Memory: +20-40MB

### Async Export Patterns

Never export spans synchronously in the request path. Always use batch processing:

```go
// GOOD: Batch span processor (async, batched export)
tp := sdktrace.NewTracerProvider(
    sdktrace.WithBatcher(exporter,
        sdktrace.WithMaxQueueSize(2048),      // Spans buffered before dropping
        sdktrace.WithMaxExportBatchSize(512),  // Spans per export call
        sdktrace.WithBatchTimeout(5*time.Second), // Max wait before flushing
    ),
)

// BAD: Simple span processor (synchronous, blocks on every span end)
// Only use for debugging/development
tp := sdktrace.NewTracerProvider(
    sdktrace.WithSyncer(exporter),
)
```

### Batch Processing Configuration

| Parameter | Description | Recommended | Impact |
|---|---|---|---|
| `max_queue_size` | Buffer capacity before drops | 2048-4096 | Higher = more memory, fewer drops during bursts |
| `max_export_batch_size` | Spans per export RPC | 256-512 | Higher = fewer RPCs, more latency per batch |
| `schedule_delay` (batch_timeout) | Max wait before flushing | 5s | Lower = fresher data, more RPCs |
| `export_timeout` | Max time for export RPC | 30s | Backend dependent. Too low = drops on slow network |

### SDK Resource Limits

Protect against runaway instrumentation:

```go
// Limit span attributes to prevent memory explosion from bad instrumentation
tp := sdktrace.NewTracerProvider(
    sdktrace.WithSpanLimits(sdktrace.SpanLimits{
        AttributeValueLengthLimit:   256,  // Truncate attribute values
        AttributeCountLimit:         128,  // Max attributes per span
        EventCountLimit:             128,  // Max events per span
        LinkCountLimit:              128,  // Max links per span
        AttributePerEventCountLimit: 32,   // Max attributes per event
        AttributePerLinkCountLimit:  32,   // Max attributes per link
    }),
)
```

### Benchmarking Instrumentation Impact

Use a controlled load test to measure before/after impact:

```bash
# 1. Baseline: Run load test WITHOUT OTel instrumentation
k6 run --duration 5m --vus 100 load-test.js > baseline.json

# 2. Instrumented: Run same test WITH OTel enabled
k6 run --duration 5m --vus 100 load-test.js > instrumented.json

# 3. Compare key metrics:
#    - P50/P95/P99 latency
#    - Throughput (requests/sec)
#    - CPU usage (pod metrics)
#    - Memory usage (pod metrics)
#    - Error rate
```

**Monitor in production:**
```promql
# CPU overhead from OTel (compare instrumented vs non-instrumented pods)
rate(container_cpu_usage_seconds_total{container="order-service"}[5m])

# Memory from OTel SDK
process_resident_memory_bytes{service_name="order-service"}

# Export queue health
otelcol_exporter_queue_size{exporter="otlp/tempo"}
```

---

## 8. Trace-Based Testing

### Concept

Traditional integration tests assert on HTTP responses. Trace-based testing asserts on the internal behavior of the entire distributed system by examining the traces produced during a test run.

**What you can validate with traces that you cannot with HTTP assertions:**
- Which downstream services were called (and which were not)
- Database query patterns (N+1 queries visible as repeated DB spans)
- Message queue interactions (publish/consume pairs)
- Retry behavior (visible as repeated spans)
- Latency breakdown across services
- Error propagation paths

### Tracetest

Tracetest is a CNCF project that enables trace-based testing with OpenTelemetry. It triggers a test (HTTP request, gRPC call, Kafka message, etc.), waits for the trace to be collected, then runs assertions against the trace spans.

**Architecture:**
```
┌──────────┐     trigger     ┌──────────────┐
│ Tracetest │────────────────>│  Your System  │
│  Server   │                 │  (instrumented│
└─────┬─────┘                 │   with OTel)  │
      │                       └───────┬───────┘
      │                               │ spans
      │                               v
      │ fetch trace            ┌──────────────┐
      └───────────────────────>│ Trace Backend │
                               │ (Tempo/Jaeger)│
                               └──────────────┘
```

**Test definition file (YAML):**

```yaml
# test-order-creation.yaml
type: Test
spec:
  name: "Order creation flow"
  description: "Validates the full order creation path across services"
  trigger:
    type: http
    httpRequest:
      url: http://api-gateway:8080/api/orders
      method: POST
      headers:
        - key: Content-Type
          value: application/json
      body: |
        {
          "product_id": "PROD-001",
          "quantity": 2,
          "customer_id": "CUST-123"
        }
  specs:
    # Assert on the HTTP response
    - name: "API returns 201"
      selector: span[tracetest.span.type="http" name="POST /api/orders"]
      assertions:
        - attr:http.response.status_code = 201

    # Assert that the order service created a database record
    - name: "Order saved to database"
      selector: span[tracetest.span.type="database" name="INSERT orders"]
      assertions:
        - attr:db.system = "postgresql"
        - attr:db.operation.name = "INSERT"

    # Assert that an event was published to Kafka
    - name: "Order event published"
      selector: span[tracetest.span.type="messaging" name="orders.created publish"]
      assertions:
        - attr:messaging.system = "kafka"
        - attr:messaging.destination.name = "orders.created"

    # Assert that the payment service was called and succeeded
    - name: "Payment processed"
      selector: span[tracetest.span.type="http" name="POST payment-service"]
      assertions:
        - attr:http.response.status_code = 200
        - attr:tracetest.span.duration < 2000  # Under 2 seconds

    # Assert no N+1 queries
    - name: "No N+1 query pattern"
      selector: span[tracetest.span.type="database" name="SELECT products"]
      assertions:
        - attr:tracetest.selected_spans.count <= 2
```

**CI/CD integration:**

```yaml
# .github/workflows/trace-tests.yml
name: Trace-Based Tests
on: [push]

jobs:
  trace-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start services with docker-compose
        run: docker-compose -f docker-compose.test.yml up -d

      - name: Wait for services
        run: |
          sleep 30  # Wait for services + OTel Collector to be ready

      - name: Install Tracetest CLI
        run: curl -L https://raw.githubusercontent.com/kubeshop/tracetest/main/install-cli.sh | bash

      - name: Configure Tracetest
        run: |
          tracetest configure \
            --server-url http://localhost:11633 \
            --output pretty

      - name: Run trace-based tests
        run: |
          tracetest run test \
            --file ./tests/trace-tests/test-order-creation.yaml \
            --required-gates test-specs \
            --output pretty

      - name: Run all trace test suites
        run: |
          tracetest run testsuite \
            --file ./tests/trace-tests/suite-e2e.yaml
```

### Custom Trace Assertions (Without Tracetest)

For teams that want lighter-weight trace assertions without a separate tool:

```python
# Python: Custom trace assertion using OTel SDK InMemorySpanExporter
import unittest
from opentelemetry.sdk.trace.export.in_memory import InMemorySpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor

class TraceAssertionTest(unittest.TestCase):
    def setUp(self):
        self.exporter = InMemorySpanExporter()
        self.provider = TracerProvider()
        self.provider.add_span_processor(SimpleSpanProcessor(self.exporter))
        # Inject provider into your application

    def test_order_creates_db_and_kafka_spans(self):
        # Trigger the operation
        response = create_order({"product_id": "PROD-001", "quantity": 2})

        # Collect exported spans
        spans = self.exporter.get_finished_spans()
        span_names = [s.name for s in spans]

        # Assert expected spans exist
        self.assertIn("INSERT orders", span_names)
        self.assertIn("orders.created publish", span_names)

        # Assert no excessive DB queries (N+1 detection)
        db_spans = [s for s in spans if s.attributes.get("db.system")]
        self.assertLess(len(db_spans), 5, "Possible N+1 query detected")

        # Assert latency
        for span in spans:
            if span.name == "POST payment-service":
                duration_ms = (span.end_time - span.start_time) / 1e6
                self.assertLess(duration_ms, 2000, "Payment service too slow")

    def tearDown(self):
        self.exporter.clear()
```

### Contract Testing with Traces

Use traces to verify service contracts at integration test time:

```yaml
# Verify that service A calls service B with expected attributes
- name: "Inventory check includes product_id"
  selector: span[name="GET inventory-service/api/stock"]
  assertions:
    - attr:http.request.header.x-request-id != ""
    - attr:url.query contains "product_id"
```

This catches breaking changes in inter-service communication that unit tests and API contract tests may miss.

---

## 9. Storage & Retention

### Trace Data Volume Estimation

```
Daily trace volume = requests_per_day * sampling_rate * avg_spans_per_trace * avg_span_size

Example:
  10M requests/day * 0.10 (10% sampling) * 8 spans/trace * 1.5KB/span
  = 10,000,000 * 0.10 * 8 * 1.5KB
  = 12 GB/day raw
  = ~360 GB/month

With compression (typical 3-5x):
  = ~72-120 GB/month stored
```

**Span size breakdown:**
- Minimal span (name, timestamps, trace/span IDs): ~200 bytes
- Typical span (10-15 attributes, 1-2 events): ~1-2KB
- Heavy span (many attributes, long string values, stack traces): ~5-10KB

### Storage Backend Comparison

| Backend | Used By | Cost/TB/month | Query Speed | Operational Complexity | Best For |
|---|---|---|---|---|---|
| **S3/GCS/Azure Blob** | Tempo | ~$23 (S3 Standard) | Slow (trace ID lookup only without index) | Low | High-volume, cost-sensitive |
| **Elasticsearch** | Jaeger, Elastic APM | ~$500-1000 (depends on instance type) | Fast (full-text search) | High (cluster management) | Ad-hoc search over any attribute |
| **Cassandra** | Jaeger (legacy) | ~$300-700 | Medium (trace ID + service/operation lookup) | High (ring management, compaction tuning) | Write-heavy workloads |
| **ClickHouse** | Jaeger v2 (coming), SigNoz, Uptrace | ~$100-300 | Fast (columnar analytics) | Medium | Analytics queries, long retention |
| **Badger** | Jaeger (single-node) | Local disk | Fast | Low (single node, no HA) | Development, small deployments |
| **Managed SaaS** | Datadog, Honeycomb, Grafana Cloud | $500-5000+ | Fast | None | Teams without infra capacity |

### Retention Policies

**Tiered retention strategy:**

```
Hot (0-7 days):    Full-resolution data, fast queries
                   Storage: Elasticsearch hot nodes / Tempo ingester cache

Warm (7-30 days):  Full data, slower queries acceptable
                   Storage: Elasticsearch warm nodes / S3 Standard

Cold (30-90 days): Sampled or aggregated data only
                   Storage: S3 Infrequent Access / GCS Nearline

Archive (90+ days): Error traces and SLO-violating traces only
                    Storage: S3 Glacier / GCS Coldline
```

**Tempo retention configuration:**
```yaml
# tempo.yaml
compactor:
  compaction:
    block_retention: 720h  # 30 days

storage:
  trace:
    backend: s3
    s3:
      bucket: tempo-traces
      endpoint: s3.us-east-1.amazonaws.com
      region: us-east-1
    blocklist_poll: 5m
```

**Jaeger (Elasticsearch) retention:**
```yaml
# Use the es-rollover tool for index lifecycle management
# Create ILM policy:
PUT _ilm/policy/jaeger-traces
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_age": "1d",
            "max_size": "50gb"
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "allocate": {
            "require": { "data": "warm" }
          },
          "forcemerge": { "max_num_segments": 1 }
        }
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### Cost Optimization Strategies

1. **Sampling first, retention second:** Tail sampling reduces volume 85-95% before data hits storage. This is the single highest-impact cost lever.

2. **Attribute pruning:** Drop high-cardinality attributes that are not useful for debugging before export:
   ```yaml
   processors:
     attributes:
       actions:
         - key: http.request.header.cookie
           action: delete
         - key: http.request.header.authorization
           action: delete
         - key: user_agent.original
           action: delete  # Often high-cardinality noise
   ```

3. **Span filtering:** Drop entire spans for health checks, metrics endpoints, and other non-interesting traffic at the Collector level.

4. **Tempo's object-storage advantage:** Storing 1TB in S3 costs ~$23/month. Storing 1TB in Elasticsearch hot nodes costs $500-1000/month. This is a 20-40x cost difference. If you do not need full-text search, Tempo with TraceQL is the most cost-effective approach.

5. **ClickHouse compression:** Columnar storage with codecs like ZSTD achieves 10x compression ratios on trace data. A ClickHouse-backed tracing system (SigNoz, Jaeger v2 with future ClickHouse support) can store 10TB of raw trace data in ~1TB of disk.

---

## 10. Service Maps & Visualization

### Auto-Generated Service Dependency Maps

Most tracing backends generate service maps automatically from trace data by analyzing which services call which other services.

**How service maps are built:**
1. Extract `service.name` from resource attributes of each span
2. Identify client-server span pairs (client span in service A, server span in service B)
3. Build a directed graph: A -> B with edge metadata (request rate, error rate, latency percentiles)

**Tools and their service map capabilities:**

| Tool | Feature | Notes |
|---|---|---|
| **Grafana + Tempo** | Service graph via `tempo-query` or `spanmetrics` connector | Requires `spanmetrics` connector to generate `traces_service_graph_request_total` metric |
| **Jaeger** | Built-in "System Architecture" view | Uses Spark or Flink job for offline graph generation, or monitor tab in v2 |
| **Datadog** | Real-time Service Map | Best-in-class: shows request rates, error rates, latency on edges. Filters by environment, version |
| **Elastic APM** | Service Map in Kibana | Auto-generated, shows dependencies including databases and external services |
| **Honeycomb** | Service Map (beta) | Newer addition, relies on trace link analysis |

### Generating Service Graphs with OTel Collector

Use the `spanmetrics` connector + `servicegraph` connector:

```yaml
connectors:
  servicegraph:
    latency_histogram_buckets: [5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 5s]
    dimensions:
      - http.method
      - http.status_code
    store:
      ttl: 2s
      max_items: 1000

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp/tempo, servicegraph]
    metrics/servicegraph:
      receivers: [servicegraph]
      processors: [batch]
      exporters: [prometheusremotewrite]
```

This generates metrics like:
```promql
# Request rate between services
rate(traces_service_graph_request_total{client="order-service", server="payment-service"}[5m])

# Error rate between services
rate(traces_service_graph_request_failed_total{client="order-service", server="payment-service"}[5m])
/ rate(traces_service_graph_request_total{client="order-service", server="payment-service"}[5m])

# Latency between services
histogram_quantile(0.99,
  rate(traces_service_graph_request_duration_seconds_bucket{client="order-service", server="payment-service"}[5m])
)
```

### Request Flow Visualization

Beyond service maps, trace waterfalls show the exact sequence and timing of operations within a single request.

**Reading a trace waterfall effectively:**

```
order-service: POST /api/orders               |==========================================| 450ms
  order-service: ValidateOrder                 |=====| 25ms
  order-service: SELECT products (PostgreSQL)    |====| 15ms
  inventory-service: GET /api/stock                |=============| 80ms
    inventory-service: SELECT stock (PostgreSQL)      |====| 12ms
    inventory-service: GET redis (cache miss)           |==| 3ms
  payment-service: POST /api/charge                          |================| 200ms
    payment-service: POST api.stripe.com                       |==============| 180ms
  order-service: INSERT orders (PostgreSQL)                                      |====| 18ms
  order-service: orders.created publish (Kafka)                                        |==| 5ms
```

**What to look for:**
1. **Long sequential chains:** Services called one-after-another that could be parallelized
2. **Disproportionate spans:** One span dominating total latency (e.g., the Stripe API call above)
3. **Missing spans:** Gaps in the waterfall indicate uninstrumented services
4. **Excessive child spans:** Possible N+1 queries or chatty service interactions
5. **Error propagation:** Where did the error originate vs where was it reported

### Critical Path Analysis

The critical path is the longest chain of sequential operations that determines total request latency. Optimizing anything not on the critical path does not reduce total latency.

```
Total request: 450ms

Critical path:
  ValidateOrder (25ms) -> inventory-service (80ms) -> payment-service (200ms) -> INSERT orders (18ms) -> Kafka publish (5ms)
  = 328ms on critical path

Non-critical path operations:
  - Some of these operations may overlap or be parallel

Key insight: Optimizing payment-service from 200ms to 100ms would reduce total latency by ~100ms.
             Optimizing the inventory-service cache miss from 3ms to 0ms would save only 3ms.
```

**Grafana Tempo supports critical path highlighting in trace views (2025+),** visually marking spans on the longest dependency chain.

### Latency Breakdown Views

Build latency breakdown dashboards using spanmetrics:

```promql
# P99 latency by service for a specific operation
histogram_quantile(0.99,
  sum(rate(traces_spanmetrics_duration_milliseconds_bucket{
    span_name="POST /api/orders"
  }[5m])) by (le, service_name)
)

# Compare latency across deployments (canary analysis)
histogram_quantile(0.99,
  sum(rate(traces_spanmetrics_duration_milliseconds_bucket{
    service_name="order-service",
    service_version="1.5.0"
  }[5m])) by (le)
)
/
histogram_quantile(0.99,
  sum(rate(traces_spanmetrics_duration_milliseconds_bucket{
    service_name="order-service",
    service_version="1.4.9"
  }[5m])) by (le)
)
```

### Production Dashboard Essentials

Every service should have a tracing dashboard with:

1. **RED metrics from traces** (Rate, Errors, Duration) -- generated by spanmetrics connector
2. **Service map** with real-time error rates on edges
3. **Slowest operations** table (P99 by span name)
4. **Error traces** quick-link panel (pre-filtered for status=ERROR)
5. **Deployment markers** correlated with latency changes
6. **Exemplar-linked** metric panels for drill-down to specific traces

---

## Quick Reference: Production Checklist

```
[ ] OTel SDK initialized with Resource (service.name, service.version, deployment.environment.name)
[ ] ParentBased sampler configured (never use AlwaysOn in production without tail sampling)
[ ] BatchSpanProcessor with tuned queue size and batch size
[ ] Span limits configured (attribute count, value length, event count)
[ ] Health/readiness endpoints excluded from tracing
[ ] Context propagation set (W3C TraceContext + Baggage)
[ ] Trace-log correlation: trace_id/span_id injected into all log records
[ ] OTel Collector deployed with memory_limiter as first processor
[ ] Collector health metrics monitored (refused spans, queue size, export failures)
[ ] Tail sampling configured at gateway tier with error + latency + probabilistic policies
[ ] Retention policy defined and enforced (hot/warm/cold tiers)
[ ] Service map generating from spanmetrics or servicegraph connector
[ ] Exemplars enabled and flowing from metrics to traces in Grafana
[ ] Trace-based tests in CI/CD for critical paths
[ ] Overhead benchmarked: <3% CPU, <50MB memory confirmed under load
[ ] Graceful shutdown calls TracerProvider.Shutdown() to flush buffered spans
```
