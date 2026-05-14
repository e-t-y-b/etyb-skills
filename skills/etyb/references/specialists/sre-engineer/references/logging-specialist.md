# Logging & Analysis — Deep Reference

**Always use `WebSearch` to verify version numbers, tool features, and best practices before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Log Aggregation Tool Selection](#1-log-aggregation-tool-selection)
2. [Structured Logging](#2-structured-logging)
3. [Log Pipeline Architecture](#3-log-pipeline-architecture)
4. [Grafana Loki Deep Dive](#4-grafana-loki-deep-dive)
5. [ELK/EFK Stack](#5-elkefk-stack)
6. [Correlation IDs & Request Tracing](#6-correlation-ids--request-tracing)
7. [Cost Optimization](#7-cost-optimization)
8. [Security & Compliance Logging](#8-security--compliance-logging)
9. [Kubernetes Logging Patterns](#9-kubernetes-logging-patterns)

---

## 1. Log Aggregation Tool Selection

### Comparison Matrix

| Criteria | Grafana Loki | ELK/EFK (Elastic) | Datadog Logs | CloudWatch Logs | Splunk | Axiom |
|---|---|---|---|---|---|---|
| **Pricing model** | OSS free; Grafana Cloud usage-based | OSS free; Elastic Cloud from $95/mo | $0.10/GB ingest + $1.70/M indexed events | $0.50/GB first 10TB (tiered) | $150-225/GB/day annual | Free 500GB/mo; Pro from $25/mo |
| **Scale ceiling** | Multi-TB/day (microservices mode) | Multi-PB (hot-warm-cold-frozen) | Effectively unlimited (SaaS) | Effectively unlimited (AWS-native) | Multi-PB | PB-scale (serverless query) |
| **Query language** | LogQL (PromQL-inspired) | KQL / Lucene / ES|QL | Proprietary search syntax | CloudWatch Logs Insights | SPL (Search Processing Language) | APL (Axiom Processing Language) |
| **Full-text search** | Limited (label + filter based) | Excellent (inverted index) | Good | Basic pattern matching | Excellent | Good |
| **Indexing strategy** | Labels only; chunk-based grep | Full inverted index per field | Proprietary indexing | Proprietary | Proprietary inverted index | Columnar, no pre-aggregation |
| **Storage cost** | Very low (object storage, no index) | Medium-high (index + data) | High (SaaS markup) | Low-medium (S3-backed) | High | Low (95%+ compression) |
| **Operational burden** | Low-medium | High (cluster management) | None (SaaS) | None (AWS-managed) | Medium-high | None (SaaS) |
| **Best for** | K8s-native, Grafana shops, cost-sensitive | Full-text search, complex analytics | All-in-one observability | AWS-native workloads | Enterprise SIEM, compliance | Startups, serverless, Vercel/edge |

### Decision Framework

**Choose Grafana Loki when:**
- You already use Grafana for metrics/dashboards
- Cost is a primary concern and you can tolerate label-based querying
- Your team is comfortable with PromQL-style syntax
- Log volume exceeds 500GB/day and budget is constrained
- You need tight correlation between metrics (Prometheus/Mimir) and logs

**Choose ELK/Elasticsearch when:**
- Full-text search across log bodies is a hard requirement
- You need complex aggregations and analytics on log data
- Your team has Elasticsearch operational expertise
- You run on-premise or need complete data sovereignty
- Log-based dashboards with drill-down are core workflow

**Choose Datadog Logs when:**
- You want a single vendor for metrics, traces, logs, and APM
- Operational simplicity outweighs cost concerns
- You need out-of-the-box integrations with 750+ technologies
- Team is small and cannot dedicate engineers to log infrastructure
- Warning: costs escalate rapidly above 100GB/day ingestion

**Choose CloudWatch Logs when:**
- Your infrastructure is predominantly AWS
- Lambda, ECS, EKS logs need zero-config collection
- You want native integration with AWS services (SNS, Step Functions)
- Log Insights queries are sufficient for your analysis needs
- Tiered pricing (introduced May 2025) makes high-volume Lambda logging cost-effective

**Choose Splunk when:**
- Security/SIEM is the primary use case
- Compliance requirements mandate specific audit capabilities (SOX, HIPAA, PCI-DSS)
- You need SPL's powerful analytics for security investigations
- Enterprise support contracts are required
- Budget allows $150-400/GB/day pricing

**Choose Axiom when:**
- You want SaaS simplicity with dramatically lower cost than Datadog
- Serverless and edge workloads (Vercel, Cloudflare, Netlify native)
- You do not need traditional APM or infrastructure monitoring
- The generous free tier (500GB/mo) covers your needs
- You value zero-sampling, zero-aggregation philosophy

### Cost Comparison at Scale (Estimates for 1TB/day)

| Platform | Monthly estimate (1TB/day) | Notes |
|---|---|---|
| **Loki (self-hosted)** | $800-2,000 | Object storage + compute; depends on cloud provider |
| **Loki (Grafana Cloud)** | $3,000-6,000 | Usage-based; depends on query volume |
| **Elasticsearch (self-hosted)** | $3,000-8,000 | Hot-warm-cold cluster; heavy on compute/storage |
| **Elastic Cloud** | $8,000-15,000 | Managed; enterprise features included |
| **Datadog** | $12,000-18,000 | Ingest ($3K) + indexing (15-day retention ~$15K) |
| **CloudWatch** | $6,000-10,000 | Tiered pricing reduces at scale; query costs add up |
| **Splunk Cloud** | $15,000-30,000+ | Negotiable with annual commits |
| **Axiom** | $2,000-4,000 | Usage-based; compression reduces effective cost |

---

## 2. Structured Logging

### Why Structured Logging Matters

Unstructured logs (`printf`-style strings) force downstream systems to parse with fragile regex. Structured logs (key-value pairs, typically JSON) enable:

- **Machine-parseable ingestion** -- no regex required at the collector or aggregator
- **Selective field indexing** -- index only what you query on, reducing storage cost
- **Consistent filtering** -- filter by `level=error AND service=payment` instead of grepping
- **PII redaction** -- target specific fields (`user.email`) rather than scanning full messages
- **Correlation** -- `trace_id` and `span_id` fields link logs to distributed traces automatically
- **Cost control** -- drop or sample fields at the pipeline level before storage

### Standard Field Schema

Every log record should include these fields (enforce via shared libraries or middleware):

| Field | Example | Required |
|---|---|---|
| `timestamp` | `2025-11-14T08:23:45.123456Z` (ISO 8601, UTC) | Yes |
| `level` | `error` (lowercase: debug/info/warn/error/fatal) | Yes |
| `message` | `payment processing failed` | Yes |
| `service` | `payment-api` | Yes |
| `version` | `v2.14.3` | Yes |
| `environment` | `production` | Yes |
| `trace_id` | `4bf92f3577b34da6a3ce929d0e0e4736` (W3C) | When tracing |
| `span_id` | `00f067aa0ba902b7` | When tracing |
| `request_id` | `req_abc123def456` | Yes |
| `error.type` | `PaymentGatewayTimeout` | On errors |
| `http.method` | `POST` | On HTTP requests |
| `http.status_code` | `504` | On HTTP requests |
| `duration_ms` | `30042` | On timed operations |

**Field naming conventions:** Use `snake_case` consistently. Namespace with dots (`http.method`, `error.type`, `db.statement`). Follow OpenTelemetry semantic conventions where applicable.

### Log Level Strategy

| Level | When to use | Production | Examples |
|---|---|---|---|
| `debug` | Internal state for development | OFF | Variable values, cache hit/miss, SQL queries |
| `info` | Normal operations worth recording | ON | Request handled, job completed, config loaded |
| `warn` | Degraded but functional | ON | Retry succeeded, deprecated API called |
| `error` | Operation failed; needs investigation | ON | Unhandled exception, external service failure |
| `fatal` | Process cannot continue | ON | Port in use, missing critical config, OOM |

**Dynamic log levels** -- Change at runtime without redeployment via: env variable + `SIGUSR1` handler, Kubernetes ConfigMap reload, admin endpoint (`POST /admin/log-level`), or feature flag (LaunchDarkly/Unleash).

### Structured Logging by Language

#### Go (log/slog) -- Standard Library

```go
func setupLogger() *slog.Logger {
    handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
        Level: slog.LevelInfo, AddSource: true,
        ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
            if a.Key == slog.TimeKey { a.Key = "timestamp" }
            if a.Key == slog.MessageKey { a.Key = "message" }
            return a
        },
    })
    logger := slog.New(handler)
    slog.SetDefault(logger)
    return logger
}

// Create child logger with request-scoped fields
func requestLogger(ctx context.Context, requestID, traceID string) *slog.Logger {
    return slog.Default().With(
        slog.String("request_id", requestID), slog.String("trace_id", traceID),
        slog.String("service", "payment-api"), slog.String("environment", os.Getenv("ENV")),
    )
}

func handlePayment(ctx context.Context) {
    log := requestLogger(ctx, "req_123", "trace_abc")
    log.InfoContext(ctx, "processing payment", slog.String("user_id", "usr_789"), slog.Float64("amount", 49.99))
}
```

**Key patterns:** Use `slog.With()` for child loggers with request-scoped fields. Use `InfoContext`/`ErrorContext` to pass `context.Context` for OTel trace extraction. Implement `slog.LogValuer` for custom types to redact sensitive data. Always `slog.NewJSONHandler` in production. Use `otelslog` bridge for automatic trace_id/span_id injection.

#### Python (structlog)

```python
import structlog, logging, sys, os

def setup_logging():
    shared_processors = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
    ]
    renderer = structlog.processors.JSONRenderer() if os.getenv("ENV") == "production" else structlog.dev.ConsoleRenderer()

    structlog.configure(
        processors=[*shared_processors, structlog.stdlib.ProcessorFormatter.wrap_for_formatter],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    formatter = structlog.stdlib.ProcessorFormatter(
        processors=[structlog.stdlib.ProcessorFormatter.remove_processors_meta, renderer],
    )
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(formatter)
    root = logging.getLogger()
    root.handlers, root.level = [handler], logging.INFO

# FastAPI middleware -- bind request context
class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(
            request_id=request.headers.get("X-Request-ID", str(uuid4())),
            trace_id=extract_trace_id(request.headers.get("traceparent", "")),
            http_method=request.method, http_path=request.url.path, service="payment-api",
        )
        log = structlog.get_logger()
        log.info("request_started")
        response = await call_next(request)
        log.info("request_completed", http_status_code=response.status_code)
        return response
```

**Key patterns:** Use `structlog.contextvars` for request-scoped context (thread-safe, async-safe). Call `clear_contextvars()` at request start to prevent leaking. Use `orjson` as JSON serializer for 2-3x faster encoding. Wrap stdlib logging so third-party libraries emit structured JSON too.

#### Node.js (pino)

```javascript
const pino = require('pino');
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: { level: (label) => ({ level: label }) },
  base: { service: process.env.SERVICE_NAME, environment: process.env.NODE_ENV },
  timestamp: pino.stdTimeFunctions.isoTime,
  redact: { paths: ['req.headers.authorization', 'req.headers.cookie', 'body.password'], censor: '[REDACTED]' },
});

// Express middleware -- child logger per request
function requestLogger(req, res, next) {
  const requestId = req.headers['x-request-id'] || randomUUID();
  req.log = logger.child({
    request_id: requestId,
    trace_id: extractTraceId(req.headers['traceparent']),
    http: { method: req.method, path: req.path },
  });
  const start = process.hrtime.bigint();
  res.on('finish', () => {
    req.log.info({ message: 'request_completed', http: { status_code: res.statusCode },
      duration_ms: Number(process.hrtime.bigint() - start) / 1e6 });
  });
  req.log.info({ message: 'request_started' });
  next();
}
```

**Key patterns:** Use `pino.child()` for request-scoped loggers; never mutate root logger. Use `redact` for PII. Never use `pino-pretty` in production (10x slower). Pino writes NDJSON to stdout. Use `AsyncLocalStorage` for async context propagation.

#### Java (Logback + Logstash Encoder)

```xml
<!-- logback-spring.xml -->
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <fieldNames><timestamp>timestamp</timestamp><message>message</message><levelValue>[ignore]</levelValue></fieldNames>
            <includeMdcKeyName>trace_id</includeMdcKeyName>
            <includeMdcKeyName>span_id</includeMdcKeyName>
            <includeMdcKeyName>request_id</includeMdcKeyName>
            <customFields>{"service":"payment-api","environment":"${ENV:-development}"}</customFields>
            <throwableConverter class="net.logstash.logback.stacktrace.ShortenedThrowableConverter">
                <maxDepthPerThrowable>30</maxDepthPerThrowable>
                <rootCauseFirst>true</rootCauseFirst>
            </throwableConverter>
        </encoder>
    </appender>
    <appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
        <queueSize>8192</queueSize>
        <discardingThreshold>0</discardingThreshold>
        <neverBlock>true</neverBlock>
        <appender-ref ref="STDOUT" />
    </appender>
    <root level="INFO"><appender-ref ref="ASYNC" /></root>
</configuration>
```

```java
// Servlet filter -- populate MDC with correlation IDs
public class RequestContextFilter implements Filter {
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException, ServletException {
        try {
            HttpServletRequest httpReq = (HttpServletRequest) req;
            MDC.put("request_id", Optional.ofNullable(httpReq.getHeader("X-Request-ID")).orElse(UUID.randomUUID().toString()));
            MDC.put("trace_id", extractTraceId(httpReq.getHeader("traceparent")));
            MDC.put("http.method", httpReq.getMethod());
            MDC.put("http.path", httpReq.getRequestURI());
            chain.doFilter(req, res);
        } finally { MDC.clear(); }
    }
}
```

**Key patterns:** `AsyncAppender` with `neverBlock=true` decouples logging from request threads. `discardingThreshold=0` prevents dropping WARN/ERROR under load. `ShortenedThrowableConverter` with `rootCauseFirst=true` puts useful info first. Always `MDC.clear()` in `finally`. Use `logback-spring.xml` (not `logback.xml`) for Spring profile support.

### Context Propagation Across Async Boundaries

Context (trace_id, request_id) is often lost when work crosses async boundaries (goroutines, thread pools, message queues):

| Language | Mechanism | Notes |
|---|---|---|
| Go | `context.Context` parameter | Pass context explicitly; never store in globals |
| Python | `contextvars` (structlog) | Automatic for `asyncio`; manual for thread pools via `copy_context()` |
| Node.js | `AsyncLocalStorage` | Propagates across `await`, timers, event emitters |
| Java | `MDC` + `TaskDecorator` | Wrap thread pool executors to copy MDC to child threads |

For message queues (Kafka, SQS, NATS), propagate `trace_id` and `request_id` as message headers/attributes. The consumer extracts and binds them to its logging context.

---

## 3. Log Pipeline Architecture

### Collection Agent Comparison

| Feature | Fluent Bit | Fluentd | Vector | Logstash | Grafana Alloy |
|---|---|---|---|---|---|
| **Language** | C | C + Ruby | Rust | JRuby | Go |
| **Memory footprint** | ~5-15 MB | ~40-100 MB | ~20-50 MB | 500MB-2GB | ~30-80 MB |
| **Throughput** | High | Medium | Very high (2x Fluent Bit in benchmarks) | Medium | Medium-high |
| **Plugin ecosystem** | ~100 plugins | 1000+ plugins | ~120 built-in components | 200+ plugins | 120+ components |
| **Configuration** | INI-like / YAML | Ruby-like DSL | TOML / YAML | Ruby-like DSL | HCL (River) |
| **Best for** | K8s DaemonSet, edge | Complex routing, aggregation tier | High-perf collection, VRL transforms | Elastic ecosystem | Grafana stack (LGTM) |
| **Hot reload** | Yes (SIGHUP) | Yes (graceful restart) | Yes (SIGHUP) | Yes (automatic) | Yes (--config.file.watch) |
| **Backpressure** | Memory/file buffer | Memory/file buffer | Disk buffer, adaptive concurrency | Persistent queue | WAL-based |
| **OTLP native** | Yes (v3.0+) | Via plugin | Yes (built-in) | Via plugin | Yes (native) |

### Architecture Patterns

**Pattern 1: DaemonSet Collector (Recommended Default)** -- One collector per node reads all container logs from `/var/log/containers/*.log`, enriches with K8s metadata, buffers to disk, forwards to Loki/ES. Use for 90% of Kubernetes deployments.

**Pattern 2: Sidecar Collector** -- Fluent Bit runs as a sidecar in each pod. Use when applications write to files (not stdout), multi-tenant clusters need isolated log processing, or per-app parsing is required.

**Pattern 3: Two-Tier (Edge + Aggregator)** -- Lightweight Fluent Bit on nodes forwards to a central Fluentd/Vector aggregator tier that handles complex routing, enrichment, and multi-destination fan-out (Loki + ES + S3). Use for large-scale deployments (>500 nodes).

### Fluent Bit DaemonSet Configuration for Kubernetes

```yaml
# fluent-bit-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: logging
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         5
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf
        HTTP_Server   On
        HTTP_Listen   0.0.0.0
        HTTP_Port     2020
        storage.path  /var/fluent-bit/state
        storage.sync  normal
        storage.checksum  off
        storage.backlog.mem_limit  5M

    [INPUT]
        Name              tail
        Tag               kube.*
        Path              /var/log/containers/*.log
        Parser            cri
        DB                /var/fluent-bit/state/flb_kube.db
        DB.locking        true
        Mem_Buf_Limit     50MB
        Skip_Long_Lines   On
        Refresh_Interval  10
        Read_from_Head    false
        storage.type      filesystem

    [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Merge_Log           On
        Merge_Log_Key       log_parsed
        K8S-Logging.Parser  On
        K8S-Logging.Exclude On
        Labels              On
        Annotations         Off
        Buffer_Size         32k

    # Drop logs from noisy namespaces
    [FILTER]
        Name    grep
        Match   kube.*
        Exclude $kubernetes['namespace_name'] ^(kube-system|monitoring)$

    # Add cluster metadata
    [FILTER]
        Name    modify
        Match   kube.*
        Add     cluster production-us-east-1
        Add     region us-east-1

    # Route by namespace
    [FILTER]
        Name          rewrite_tag
        Match         kube.*
        Rule          $kubernetes['namespace_name'] ^(payment|order|inventory)$ critical.$TAG false
        Emitter_Name  re_emitted

    # Critical logs to Loki with higher priority
    [OUTPUT]
        Name                   loki
        Match                  critical.*
        Host                   loki-gateway.logging.svc.cluster.local
        Port                   80
        Labels                 job=fluent-bit, cluster=production
        Label_Keys             $kubernetes['namespace_name'],$kubernetes['pod_name'],$kubernetes['container_name']
        Remove_Keys            logtag,kubernetes
        Auto_Kubernetes_Labels On
        Line_Format            json
        Workers                4
        storage.total_limit_size  500M
        Retry_Limit            5

    # All other logs to Loki (standard)
    [OUTPUT]
        Name                   loki
        Match                  kube.*
        Host                   loki-gateway.logging.svc.cluster.local
        Port                   80
        Labels                 job=fluent-bit, cluster=production
        Label_Keys             $kubernetes['namespace_name'],$kubernetes['container_name']
        Remove_Keys            logtag
        Auto_Kubernetes_Labels Off
        Line_Format            json
        Workers                2

  parsers.conf: |
    [PARSER]
        Name        cri
        Format      regex
        Regex       ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z

    [PARSER]
        Name        json
        Format      json
        Time_Key    timestamp
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z

```

**DaemonSet spec essentials:** Mount `/var/log` and `/var/lib/docker/containers` as read-only hostPath volumes. Use `tolerations: [{operator: Exists}]` to run on all nodes. Set resources to 100m/128Mi request, 500m/256Mi limit. Add liveness/readiness probes on port 2020 (`/api/v1/health`). Use a dedicated ServiceAccount with RBAC for K8s API access. Expose Prometheus metrics via annotations on port 2020.

### Vector Pipeline Configuration

```toml
# vector.toml -- Production Kubernetes deployment
[api]
enabled = true
address = "0.0.0.0:8686"

[sources.kubernetes_logs]
type = "kubernetes_logs"
auto_partial_merge = true
self_node_name = "${VECTOR_SELF_NODE_NAME}"
exclude_paths_glob_patterns = ["*_kube-system_*", "*_monitoring_*"]

[transforms.parse_json]
type = "remap"
inputs = ["kubernetes_logs"]
source = '''
  parsed, err = parse_json(.message)
  if err == null { . = merge(., parsed); del(.message) }
  .level = downcase(string!(.level || .severity || "info"))
  .service = .kubernetes.pod_labels."app.kubernetes.io/name" ?? .kubernetes.container_name
  .namespace = .kubernetes.pod_namespace
  .cluster = get_env_var("CLUSTER_NAME") ?? "unknown"
'''

[transforms.filter_noise]
type = "filter"
inputs = ["parse_json"]
condition = '.level != "debug" || .namespace == "staging"'

[transforms.route_by_criticality]
type = "route"
inputs = ["filter_noise"]
[transforms.route_by_criticality.route]
critical = '.namespace == "payment" || .namespace == "order" || .level == "error"'
standard = '.namespace != "payment" && .namespace != "order"'

[transforms.redact_pii]
type = "remap"
inputs = ["route_by_criticality.critical", "route_by_criticality.standard"]
source = '''
  if exists(.email) { .email = "REDACTED" }
  .message = replace(string!(.message), r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', "[CC_REDACTED]") ?? .message
  .message = replace(string!(.message), r'\b\d{3}-\d{2}-\d{4}\b', "[SSN_REDACTED]") ?? .message
'''

[sinks.loki_critical]
type = "loki"
inputs = ["route_by_criticality.critical"]
endpoint = "http://loki-gateway.logging.svc.cluster.local:80"
encoding.codec = "json"
labels = { job = "vector", cluster = "{{ cluster }}", namespace = "{{ namespace }}", service = "{{ service }}", level = "{{ level }}" }
buffer = { type = "disk", max_size = 1_073_741_824, when_full = "block" }

[sinks.loki_standard]
type = "loki"
inputs = ["route_by_criticality.standard"]
endpoint = "http://loki-gateway.logging.svc.cluster.local:80"
encoding.codec = "json"
labels = { job = "vector", cluster = "{{ cluster }}", namespace = "{{ namespace }}" }
buffer = { type = "disk", max_size = 536_870_912, when_full = "drop_newest" }

[sinks.dead_letter_queue]
type = "aws_s3"
inputs = ["loki_critical.dropped", "loki_standard.dropped"]
bucket = "logs-dead-letter"
key_prefix = "failed/%Y/%m/%d/"
encoding.codec = "ndjson"
compression = "gzip"
```

### Buffering and Backpressure

| Strategy | When to use | Trade-off |
|---|---|---|
| **Memory buffer** | Low-volume, latency-sensitive | Data loss on crash |
| **File/disk buffer** | Production default for reliability | Slightly higher latency; disk I/O |
| **Block on full** | Critical logs that must not be dropped | Application backpressure; can cause cascading failures |
| **Drop newest on full** | High-volume standard logs | Acceptable data loss for non-critical logs |

**Dead letter queue (DLQ) pattern:** When a sink fails (Loki down, Elasticsearch cluster red), failed batches are routed to durable storage (S3, local disk) for later replay. Both Vector and Fluentd support this natively. This prevents data loss during outages without blocking the pipeline.

---

## 4. Grafana Loki Deep Dive

### Architecture Overview

Loki (v3.x) is a horizontally-scalable, multi-tenant log aggregation system inspired by Prometheus. Unlike Elasticsearch, Loki indexes only labels (metadata), not the full log content -- storing compressed log chunks in object storage (S3, GCS, Azure Blob).

**Write path:** Clients (Fluent Bit/Vector/Alloy) -> Distributor (hash ring) -> Ingester (WAL) -> Compressed chunks -> Object Storage (S3/GCS).

**Read path:** Grafana -> Query Frontend (split/cache) -> Querier (parallel scan) -> Object Storage + Ingesters (recent data).

**Background services:** Compactor (merge chunks), Bloom Planner/Builder (bloom filters for query acceleration), Index Gateway (cached index access), Ruler (alerting rules).

### Deployment Modes

| Mode | Scale | When to use |
|---|---|---|
| **Monolithic** | < 20 GB/day | Dev, testing, small teams. Single binary, single process. |
| **Simple Scalable (SSD)** | 20 GB - 1 TB/day | Default Helm chart deployment. Separate read/write/backend targets. Being deprecated before Loki 4.0. |
| **Microservices** | > 1 TB/day | Large-scale production. Each component scaled independently. Full operational control. |

**Migration path:** Start monolithic, move to SSD when you outgrow it, then microservices when you need per-component scaling. The Loki Helm chart supports all three modes via `deploymentMode` value.

### Label Design (Critical for Performance)

Labels are the primary index in Loki. Bad label design is the #1 cause of Loki performance problems.

**Rules:**
1. **Static labels only** -- labels should be bounded and known at deploy time
2. **Low cardinality** -- aim for < 100,000 unique label combinations across your cluster
3. **No high-cardinality values** -- NEVER use user_id, request_id, IP address, or trace_id as labels
4. **Use structured metadata** for high-cardinality data (Loki 3.0+): `trace_id`, `request_id` go into structured metadata, not labels

**Good labels:**

```
{cluster="prod-us-east", namespace="payment", service="payment-api", level="error"}
{cluster="prod-us-east", namespace="order", service="order-worker", level="info"}
```

**Bad labels (will destroy performance):**

```
{user_id="usr_123456"}        # Millions of unique values
{request_id="req_abc123"}     # Unique per request
{ip="10.0.45.123"}            # Thousands of unique values
{pod="payment-api-7b8f9c-xk2nz"}  # Changes on every restart
```

**Structured metadata (Loki 3.0+):** High-cardinality fields like `trace_id` and `request_id` are stored alongside log lines but not indexed as labels. You can still filter on them using LogQL:

```logql
{service="payment-api"} | trace_id = "4bf92f3577b34da6a3ce929d0e0e4736"
```

### LogQL Query Patterns

#### Basic stream selection and filtering

```logql
# All error logs from payment service
{namespace="payment", level="error"}

# Filter by content (fast -- applied after label selection)
{service="payment-api"} |= "timeout"

# Negative filter (exclude healthchecks)
{service="payment-api"} != "/healthz"

# Regex filter
{service="payment-api"} |~ "status=(5[0-9]{2})"

# Case-insensitive match
{namespace="payment"} |~ "(?i)exception"
```

#### Parsing and field extraction

```logql
# Parse JSON logs and filter on extracted fields
{service="payment-api"} | json | http_status_code >= 500

# logfmt parsing
{service="gateway"} | logfmt | duration > 5s

# Pattern parser (faster than regex for known formats)
{service="nginx"} | pattern `<ip> - - [<_>] "<method> <path> <_>" <status> <bytes>`
  | status >= 500

# Regex parser for custom formats
{service="legacy-app"} | regexp `(?P<timestamp>\S+)\s+(?P<level>\S+)\s+(?P<msg>.*)`
  | level = "ERROR"

# Unwrap numeric fields for aggregation
{service="payment-api"} | json | unwrap duration_ms | avg_over_time([5m]) > 1000
```

#### Metric queries (aggregations)

```logql
# Error rate per service (last 5 minutes)
sum by (service) (rate({level="error"}[5m]))

# 99th percentile response time from logs
quantile_over_time(0.99,
  {service="payment-api"} | json | unwrap duration_ms [5m]
) by (http_method)

# Top 10 error messages
topk(10,
  sum by (error_type) (count_over_time(
    {service="payment-api", level="error"} | json [1h]
  ))
)

# Ratio of errors to total requests
sum(rate({service="payment-api", level="error"}[5m]))
/
sum(rate({service="payment-api"}[5m]))

# Bytes throughput per namespace
sum by (namespace) (bytes_over_time({cluster="production"}[1h]))
```

#### Log-based alerting examples

```yaml
# loki-ruler-config.yaml
groups:
  - name: logging-alerts
    interval: 1m
    rules:
      # Alert on high error rate
      - alert: HighErrorRate
        expr: |
          sum by (service) (rate({level="error"}[5m])) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate for {{ $labels.service }}"
          description: "{{ $labels.service }} has {{ $value | printf \"%.1f\" }} errors/sec"

      # Alert on specific error patterns
      - alert: PaymentGatewayFailure
        expr: |
          count_over_time(
            {service="payment-api"} |= "PaymentGatewayTimeout" [5m]
          ) > 5
        for: 2m
        labels:
          severity: critical

      # Recording rule: pre-compute error rates
      - record: service:log_errors:rate5m
        expr: |
          sum by (service, namespace) (rate({level="error"}[5m]))
```

### Loki vs Elasticsearch Comparison

| Aspect | Loki | Elasticsearch |
|---|---|---|
| **Index strategy** | Labels only (low cost) | Full inverted index (high cost) |
| **Storage** | Object storage (S3/GCS) | Local SSD/HDD (hot-warm-cold) |
| **Query speed (known labels)** | Fast | Fast |
| **Query speed (full-text)** | Slow (grep over chunks) | Very fast (inverted index) |
| **Storage cost at 1TB/day** | ~$800/mo (S3) | ~$3,000-8,000/mo (EBS/SSD) |
| **Operational complexity** | Low-medium | High |
| **Multi-tenancy** | Native (header-based) | Index-per-tenant or RBAC |
| **Grafana integration** | Native | Plugin (good but not native) |
| **APM correlation** | Native (Tempo) | Native (Elastic APM) |

---

## 5. ELK/EFK Stack

### Elasticsearch Cluster Design

#### Hot-Warm-Cold-Frozen Architecture

| Tier | Storage | Retention | Replicas | Characteristics |
|---|---|---|---|---|
| **Hot** | NVMe SSD | 0-3 days | 1 | Active writes; 3+ nodes; dedicated masters recommended |
| **Warm** | SSD / fast HDD | 3-30 days | 1 | Read-only, force-merged, shrink shards |
| **Cold** | HDD / searchable snapshots | 30-90 days | 0 | Rarely queried, minimal compute |
| **Frozen** | S3/GCS snapshots | 90-365+ days | 0 | Zero local storage, searchable snapshots |
| **Delete** | -- | After retention | -- | ILM automatic deletion |

Data flows: Ingest -> Hot -> (ILM rollover at 50GB or 1 day) -> Warm -> Cold -> Frozen -> Delete.

#### Index Lifecycle Management (ILM) Policy

```json
{
  "policy": {
    "phases": {
      "hot":    { "min_age": "0ms",   "actions": { "rollover": { "max_primary_shard_size": "50gb", "max_age": "1d" }, "set_priority": { "priority": 100 } } },
      "warm":   { "min_age": "3d",    "actions": { "shrink": { "number_of_shards": 1 }, "forcemerge": { "max_num_segments": 1 }, "allocate": { "require": { "data": "warm" } }, "set_priority": { "priority": 50 } } },
      "cold":   { "min_age": "30d",   "actions": { "allocate": { "require": { "data": "cold" }, "number_of_replicas": 0 }, "set_priority": { "priority": 0 } } },
      "frozen": { "min_age": "90d",   "actions": { "searchable_snapshot": { "snapshot_repository": "logs-archive" } } },
      "delete": { "min_age": "365d",  "actions": { "delete": {} } }
    }
  }
}
```

#### Sharding Strategy

| Shard size guideline | Recommendation |
|---|---|
| Target shard size | 10-50 GB (ideal: ~30 GB) |
| Shards per node | < 600 (across all indices) |
| Maximum shard size | Never exceed 50 GB |
| Primary shards for hot index | Match number of hot data nodes |
| Replicas for hot | 1 (balance between durability and resource use) |

**Formula for primary shard count:**
```
primary_shards = ceil(expected_daily_volume_gb / 30)
```

For 100 GB/day of logs:
- Primary shards = ceil(100 / 30) = 4
- With 1 replica = 8 total shards
- Rollover at 50 GB or 1 day

#### Index Template

```json
{
  "index_patterns": ["logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 4, "number_of_replicas": 1,
      "index.lifecycle.name": "logs-lifecycle-policy",
      "index.lifecycle.rollover_alias": "logs-write",
      "index.codec": "best_compression",
      "index.mapping.total_fields.limit": 2000,
      "index.refresh_interval": "30s",
      "index.translog.durability": "async",
      "index.translog.sync_interval": "30s"
    },
    "mappings": {
      "dynamic_templates": [
        { "strings_as_keywords": { "match_mapping_type": "string", "mapping": { "type": "keyword", "ignore_above": 1024 } } }
      ],
      "properties": {
        "timestamp": { "type": "date" }, "message": { "type": "text" },
        "level": { "type": "keyword" }, "service": { "type": "keyword" },
        "namespace": { "type": "keyword" }, "trace_id": { "type": "keyword" },
        "span_id": { "type": "keyword" }, "request_id": { "type": "keyword" },
        "http.method": { "type": "keyword" }, "http.path": { "type": "keyword" },
        "http.status_code": { "type": "short" }, "duration_ms": { "type": "float" },
        "error.type": { "type": "keyword" }, "error.message": { "type": "text" },
        "error.stack_trace": { "type": "text", "index": false }
      }
    }
  }
}
```

### Performance Tuning Checklist

1. **Set `refresh_interval` to 30s** (default is 1s) -- reduces indexing overhead for logs
2. **Use `best_compression` codec** -- DEFLATE saves 15-25% storage over LZ4
3. **Async translog** -- `index.translog.durability: async` reduces I/O by batching
4. **Map strings as `keyword`** -- most log fields are for filtering, not full-text search; only `message` and `error.stack_trace` should be `text`
5. **Disable indexing for stack traces** -- `"index": false` on `error.stack_trace` saves significant index space
6. **Use `_source` filtering** -- exclude large fields from `_source` that you do not need to retrieve
7. **Force-merge warm indices** -- single-segment indices are faster to search
8. **Set `max_primary_shard_size` for rollover** -- size-based rollover produces more uniform shards than time-based

### Filebeat vs Fluentd as Shippers

| Aspect | Filebeat | Fluentd/Fluent Bit |
|---|---|---|
| **Native to** | Elastic ecosystem | CNCF ecosystem |
| **Config language** | YAML | Ruby DSL / INI |
| **Elasticsearch output** | Optimized (native) | Plugin-based |
| **Kubernetes metadata** | Autodiscover | kubernetes filter |
| **Memory** | 30-80 MB | Fluent Bit: 5-15 MB |
| **Best for** | Elastic-only destinations | Multi-destination routing |

---

## 6. Correlation IDs & Request Tracing

### Implementation Pattern

Every request gets a unique correlation ID propagated through all downstream services (API Gateway generates, all services propagate).

**ID hierarchy:** `trace_id` (32-hex W3C, spans entire distributed trace), `span_id` (16-hex, one unit of work within a trace), `request_id` (business-level, may be user-facing in error pages, format: `req_` + UUID).

### Middleware Injection Pattern

```go
func CorrelationMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        requestID := r.Header.Get("X-Request-ID")
        if requestID == "" { requestID = "req_" + uuid.New().String() }
        traceID := extractTraceID(r.Header.Get("traceparent")) // parse W3C traceparent
        w.Header().Set("X-Request-ID", requestID)
        ctx := context.WithValue(r.Context(), requestIDKey, requestID)
        ctx = context.WithValue(ctx, traceIDKey, traceID)
        logger := slog.Default().With(slog.String("request_id", requestID), slog.String("trace_id", traceID))
        ctx = context.WithValue(ctx, loggerKey, logger)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

### Propagation Across Async Boundaries

#### Message Queues (Kafka Example)

```go
// Producer: inject correlation IDs as Kafka message headers
msg.Headers = []kafka.Header{
    {Key: "request_id", Value: []byte(ctx.Value(requestIDKey).(string))},
    {Key: "traceparent", Value: []byte(buildTraceparent(ctx.Value(traceIDKey).(string)))},
}
// Consumer: extract from headers, bind to logger
logger := slog.Default().With(
    slog.String("request_id", extractHeader(msg.Headers, "request_id")),
    slog.String("trace_id", extractTraceID(extractHeader(msg.Headers, "traceparent"))),
    slog.String("kafka.topic", *msg.TopicPartition.Topic),
)
```

#### Background Jobs / Workers

For Celery (Python): Override `apply_async` in a custom `Task` base class to inject `request_id`/`trace_id` from `structlog.contextvars` into task headers. In the worker, use `@signals.task_prerun.connect` to call `clear_contextvars()` then `bind_contextvars()` with the values from `task.request` headers. Same pattern applies to Sidekiq (Ruby), Bull (Node.js), and any async job framework.

### OpenTelemetry Log Bridge

The OTel log bridge connects your existing logging library to the OpenTelemetry pipeline, automatically attaching `trace_id` and `span_id` to every log record emitted within an active span.

**Key principle:** Do NOT replace your logging library with OTel APIs. Instead, use the bridge:

| Language | Bridge | Logging Library |
|---|---|---|
| Go | `otelslog` | `log/slog` |
| Python | `opentelemetry-instrumentation-logging` | `logging` / `structlog` |
| Java | `opentelemetry-logback-appender-1.0` | Logback |
| Node.js | `@opentelemetry/instrumentation-pino` | pino |

The bridge ensures that when you call `logger.info("payment processed")` inside a traced function, the resulting log record automatically includes the current `trace_id` and `span_id` -- enabling bidirectional navigation between logs and traces in Grafana, Jaeger, or any OTel-compatible backend.

---

## 7. Cost Optimization

### Log Volume Management Hierarchy

Apply these strategies in order, from highest to lowest impact:

#### 1. Eliminate at Source (Highest Impact)

```yaml
# Vector transform -- drop known-noisy logs before they leave the node
[transforms.drop_noise]
type = "filter"
inputs = ["kubernetes_logs"]
condition = '''
  !starts_with(string!(.message), "GET /healthz") &&
  !starts_with(string!(.message), "GET /readyz") &&
  .kubernetes.container_name != "istio-proxy" &&
  .level != "debug"
'''
```

Common noise to eliminate:
- Health check logs (often 30-60% of total volume)
- Istio/Envoy access logs (use metrics instead)
- Debug logs in production
- Kubernetes event spam from kube-system

#### 2. Sample at Source (Medium Impact)

```yaml
# Fluent Bit -- sample 1 in 10 for verbose services
[FILTER]
    Name          throttle
    Match         kube.verbose-service.*
    Rate          10
    Window        30
    Interval      30s
    Print_Status  true
```

**Smart sampling rules:**
- Keep 100% of `error` and `fatal` logs -- never sample these
- Keep 100% of logs with `trace_id` matching sampled traces
- Sample `info` logs at 10-50% for high-volume services (>10K logs/min)
- Sample `debug` logs at 1-5% if they must be enabled

#### 3. Reduce Log Size (Medium Impact)

- Drop unnecessary fields before shipping (`kubernetes.labels`, `kubernetes.annotations`, raw `log` when `message` exists)
- Truncate oversized messages (stack traces > 4KB, SQL queries > 1KB)
- Use shorter field names if volume justifies it (controversial; reduces readability)
- Compress at the transport layer (gzip/snappy between collector and backend)

#### 4. Tiered Retention (Lower Impact, Ongoing Savings)

| Data classification | Hot retention | Warm retention | Cold/archive | Total |
|---|---|---|---|---|
| Critical services (payment, auth) | 7 days | 30 days | 365 days | 365 days |
| Standard services | 3 days | 14 days | 90 days | 90 days |
| Infrastructure logs | 1 day | 7 days | 30 days | 30 days |
| Debug / verbose | 1 day | None | None | 1 day |

### Cost Reduction Strategies for High-Volume Environments (>1TB/day)

| Strategy | Expected savings | Effort | Risk |
|---|---|---|---|
| Drop healthcheck logs | 20-40% volume reduction | Low | None |
| Drop Envoy/Istio access logs | 10-30% volume reduction | Low | Lose HTTP-level log visibility (use metrics) |
| Sample info-level logs | 30-50% on sampled services | Medium | May miss intermittent issues |
| Shorter retention on non-critical | 20-40% storage savings | Low | Reduced lookback window |
| Switch from ELK to Loki | 60-80% cost reduction | High | Query capability changes |
| Move to Axiom from Datadog | 70-90% cost reduction | Medium | Fewer features |
| Implement log levels properly | 20-50% volume reduction | Medium | Requires code changes |

### Cost Monitoring

Track these metrics to prevent cost surprises:

```promql
# Bytes ingested per service per day (Loki)
sum by (service) (bytes_over_time({cluster="production"}[24h]))

# Log lines per second by namespace
sum by (namespace) (rate({cluster="production"}[5m]))

# Identify top talkers
topk(10, sum by (service) (rate({cluster="production"}[1h])))
```

Set alerts when a single service exceeds its expected log volume budget:

```yaml
- alert: LogVolumeAnomaly
  expr: |
    sum by (service) (bytes_over_time({cluster="production"}[1h]))
    > 2 * avg_over_time(
      sum by (service) (bytes_over_time({cluster="production"}[1h]))[7d:1h]
    )
  for: 30m
  labels:
    severity: warning
  annotations:
    summary: "{{ $labels.service }} log volume is 2x above 7-day average"
```

---

## 8. Security & Compliance Logging

### Audit Trail Requirements

Audit logs must answer: **Who** did **what** to **which resource**, **when**, from **where**, and **why** (if applicable).

```json
{
  "timestamp": "2025-11-14T08:23:45.123Z",
  "event_type": "audit",
  "action": "user.permission.grant",
  "actor": { "id": "usr_admin_456", "type": "user", "ip": "10.0.23.45" },
  "target": { "id": "usr_789", "type": "user", "attribute": "role", "old_value": "viewer", "new_value": "editor" },
  "resource": { "type": "organization", "id": "org_123" },
  "result": "success",
  "request_id": "req_abc123",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "metadata": { "justification": "Approved in ticket JIRA-4567" }
}
```

**Audit log pipeline rules:** Separate stream from application logs. Immutable storage (S3 Object Lock). Retention: 1yr (SOX), 6yr (HIPAA), 7yr (financial services). Tamper detection via hash chains or WORM. Separate RBAC for audit log access.

### PII Redaction Patterns

#### At the Application Level (Preferred)

```go
// Go -- Implement slog.LogValuer to redact sensitive types
type Email string

func (e Email) LogValue() slog.Value {
    if len(e) == 0 {
        return slog.StringValue("")
    }
    parts := strings.Split(string(e), "@")
    if len(parts) != 2 {
        return slog.StringValue("[INVALID_EMAIL]")
    }
    return slog.StringValue(parts[0][:1] + "***@" + parts[1])
}

type CreditCard string

func (cc CreditCard) LogValue() slog.Value {
    if len(cc) < 4 {
        return slog.StringValue("[INVALID_CC]")
    }
    return slog.StringValue("****" + string(cc[len(cc)-4:]))
}

// Usage: redaction happens automatically when logging
slog.Info("payment processed",
    slog.Any("email", Email("john.doe@example.com")),      // "j***@example.com"
    slog.Any("card", CreditCard("4111111111111234")),       // "****1234"
)
```

#### At the Pipeline Level (Defense in Depth)

Use Vector VRL `replace()` with regex patterns in a `remap` transform to catch PII that escaped application-level redaction:

| PII type | Regex pattern | Replacement |
|---|---|---|
| Email | `\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z\|a-z]{2,}\b` | `[EMAIL_REDACTED]` |
| SSN (US) | `\b\d{3}-\d{2}-\d{4}\b` | `[SSN_REDACTED]` |
| Credit card | `\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b` | `[CC_REDACTED]` |
| Phone (US) | `\b(\+1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b` | `[PHONE_REDACTED]` |

Also redact named fields: `if exists(.user_email) { .user_email = "[REDACTED]" }`. See the Vector pipeline example in section 3 for a full working config.

**GDPR checklist:** Identify all PII fields logged. Redact at source + pipeline (defense in depth). Right-to-erasure compliance (or never store PII). Retention aligned with data minimization. Document legal basis for any intentional PII logging. Encrypt in transit (TLS) and at rest (KMS).

**HIPAA additions:** All 18 PHI identifiers redacted. BAA required with log vendor. Log access audited. Encryption at rest mandatory.

### Log Integrity and Tamper Detection

For compliance-critical logs, ensure immutability:

1. **S3 Object Lock (Compliance Mode):** Prevents deletion or overwrite for the retention period; not even the root account can bypass it
2. **Hash chain:** Each log batch includes a hash of the previous batch; tampering breaks the chain
3. **Separate write-only accounts:** The service writing audit logs has no read/delete permissions; the investigation team has read-only

### Centralized Security Logging for SIEM

Route security-relevant logs to your SIEM (Splunk, Elastic Security, Sentinel) using a dedicated pipeline:

```toml
# Vector -- route security events to SIEM
[transforms.security_router]
type = "route"
inputs = ["all_logs"]
[transforms.security_router.route]
security = '''
  .event_type == "audit" ||
  .level == "error" && (.service == "auth-api" || .service == "iam-service") ||
  contains(string!(.message), "unauthorized") ||
  contains(string!(.message), "forbidden") ||
  .http_status_code == 401 || .http_status_code == 403
'''

[sinks.siem_splunk]
type = "splunk_hec"
inputs = ["security_router.security"]
endpoint = "https://splunk-hec.internal:8088"
token = "${SPLUNK_HEC_TOKEN}"
encoding.codec = "json"
index = "security_events"
sourcetype = "app:security"
```

### Log Access Controls

| Role | Permissions | Use case |
|---|---|---|
| Developer | Read own service logs (namespace-scoped) | Debugging during development |
| On-call engineer | Read all application logs | Incident response |
| Security team | Read security/audit logs | Investigation, compliance |
| Audit team | Read audit logs only | Compliance verification |
| Platform team | Admin on log infrastructure | Pipeline management |

Implement via: Loki multi-tenancy with tenant ID per team + Grafana RBAC, Elasticsearch index-level security with Kibana Spaces, or Datadog role-based access with log query restrictions.

---

## 9. Kubernetes Logging Patterns

### Log Sources in Kubernetes

| Source | Location | Collector approach |
|---|---|---|
| **Container stdout/stderr** | `/var/log/containers/*.log` | DaemonSet tail |
| **Container runtime logs** | `/var/log/pods/` | DaemonSet tail |
| **Kubelet logs** | systemd journal | journald input |
| **API server audit logs** | `/var/log/kubernetes/audit.log` | DaemonSet tail or sidecar |
| **etcd logs** | systemd journal | journald input |
| **Node-level system logs** | `/var/log/syslog`, `/var/log/messages` | DaemonSet tail |
| **Application file logs** | Custom paths in containers | Sidecar or shared volume |

### Container Runtime Log Format

Modern Kubernetes (containerd/CRI-O) uses CRI format: `<timestamp> <stream> <tag> <log>` (e.g., `2025-11-14T08:23:45Z stdout F {"level":"info",...}`). Stream is `stdout`/`stderr`, tag is `F` (full) or `P` (partial for multiline). Fluent Bit's `cri` parser and Vector's `kubernetes_logs` source handle this automatically.

### DaemonSet Resource Recommendations

| Cluster size | CPU request | CPU limit | Memory request | Memory limit |
|---|---|---|---|---|
| Small (<50 pods/node) | 50m | 200m | 64Mi | 128Mi |
| Medium (50-200 pods/node) | 100m | 500m | 128Mi | 256Mi |
| Large (>200 pods/node) | 200m | 1000m | 256Mi | 512Mi |

### Sidecar Pattern (When DaemonSet Is Not Enough)

Use sidecars when:
- Application writes logs to files, not stdout
- Per-application parsing/routing is needed
- Multi-tenant clusters where namespaces need isolated log pipelines
- Application emits multiline logs that require app-specific parsing

**Sidecar deployment pattern:** Add a Fluent Bit container (20m CPU, 32Mi memory) alongside the app. Share log files via an `emptyDir` volume (`/var/log/app`). App writes logs to the shared volume; sidecar tails and forwards. Mount sidecar config via ConfigMap.

### Multi-Tenant Log Isolation

For clusters shared across teams/tenants, isolate logs by namespace:

#### Approach 1: Label-Based Routing (Loki)

```yaml
# Fluent Bit output -- route by namespace to different Loki tenants
[OUTPUT]
    Name          loki
    Match         kube.team-a.*
    Host          loki-gateway
    Port          80
    Tenant_ID     team-a
    Labels        job=fluent-bit
    Label_Keys    $kubernetes['namespace_name'],$kubernetes['container_name']

[OUTPUT]
    Name          loki
    Match         kube.team-b.*
    Host          loki-gateway
    Port          80
    Tenant_ID     team-b
    Labels        job=fluent-bit
    Label_Keys    $kubernetes['namespace_name'],$kubernetes['container_name']
```

#### Approach 2: Index-Per-Tenant (Elasticsearch)

Use Vector's `route` transform to match `kubernetes.pod_namespace` per tenant, then send each route to a separate Elasticsearch index (`logs-team-a-%Y.%m.%d`, `logs-team-b-%Y.%m.%d`).

### Namespace-Based Log Routing with Annotations

Use pod annotations to control log behavior without changing collector config. Fluent Bit natively supports `fluentbit.io/parser` and `fluentbit.io/exclude` annotations. Add custom annotations (e.g., `logging.company.com/tier: "critical"`) and read them in the Kubernetes filter for routing decisions.

### Multiline Log Handling

Stack traces split across CRI log lines. Handle at the collector with multiline parsers:

```ini
[MULTILINE_PARSER]
    Name          java_stacktrace
    Type          regex
    Flush_timeout 2000
    Rule          "start_state"  "/^\d{4}-\d{2}-\d{2}/"  "cont"
    Rule          "cont"         "/^\s+(at|Caused by|\.\.\.)\s/"  "cont"

[INPUT]
    Name              tail
    Tag               kube.*
    Path              /var/log/containers/*java-app*.log
    Multiline.parser  cri, java_stacktrace
```

### Application vs Cluster Logs

| Category | Examples | Collection | Retention |
|---|---|---|---|
| **Application logs** | Business logic, request handling, errors | DaemonSet (stdout) | 7-90 days |
| **Platform logs** | Ingress controller, service mesh, cert-manager | DaemonSet (stdout) | 3-30 days |
| **Cluster logs** | API server, scheduler, controller-manager, etcd | DaemonSet (journal + files) | 30-90 days |
| **Audit logs** | API server audit, RBAC decisions | Dedicated pipeline | 365+ days |
| **Node logs** | Kubelet, container runtime, kernel | DaemonSet (journal) | 7-30 days |

**Best practice:** Route cluster and audit logs to a separate backend (or at minimum separate indices/tenants) from application logs. Cluster logs are for platform teams; application logs are for developers. Different retention, different access controls, different alert rules.

---

*This reference provides architectural context and production-proven patterns. Always verify specific version numbers, pricing, and feature availability with `WebSearch` before making implementation decisions -- the observability ecosystem evolves rapidly.*
