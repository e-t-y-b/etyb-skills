# Integration Architecture — Deep Reference

**Always use `WebSearch` to verify current tool versions, cloud service updates, and pricing before giving advice. Integration tooling evolves rapidly.**

## Table of Contents
1. [Integration Patterns Overview](#1-integration-patterns-overview)
2. [Event-Driven Integration](#2-event-driven-integration)
3. [API Gateways](#3-api-gateways)
4. [Workflow Orchestration](#4-workflow-orchestration)
5. [Third-Party Integration](#5-third-party-integration)
6. [Data Integration and ETL/ELT](#6-data-integration-and-etlelt)
7. [Distributed Transactions](#7-distributed-transactions)
8. [B2B and Legacy Integration](#8-b2b-and-legacy-integration)
9. [Integration Testing and Observability](#9-integration-testing-and-observability)
10. [Anti-Patterns](#10-anti-patterns)

---

## 1. Integration Patterns Overview

### Enterprise Integration Patterns (Modernized)

The classic Hohpe/Woolf patterns remain relevant but are implemented with modern tools:

| Pattern | Classic | Modern Implementation |
|---------|---------|----------------------|
| **Message Channel** | JMS Queue | Kafka topic, NATS subject, SQS queue |
| **Message Router** | ESB routing | API gateway rules, event routing, Kafka Streams |
| **Message Translator** | XSLT transform | Schema registry + serde, middleware transform |
| **Message Filter** | Content-based routing | Kafka consumer filter, SQS message filtering |
| **Publish-Subscribe** | JMS Topics | Kafka, SNS, NATS JetStream, Redis Pub/Sub |
| **Dead Letter Channel** | DLQ in MQ | DLQ in SQS/Kafka, retry topic pattern |
| **Wire Tap** | Message interceptor | Distributed tracing (OpenTelemetry), CDC |
| **Idempotent Receiver** | Dedup in consumer | Idempotency key + dedup store (Redis) |

### Integration Style Decision

| Style | Best For | Latency | Coupling |
|-------|----------|---------|----------|
| **Synchronous API call** | Simple request-response, strong consistency | Low | High |
| **Async messaging (queue)** | Task processing, decoupling, buffering | Medium | Low |
| **Event streaming** | Real-time data flow, event sourcing, replay | Low-Medium | Very Low |
| **File transfer** | Batch data exchange, legacy systems | High | Very Low |
| **Shared database** | Tight integration (anti-pattern in most cases) | Lowest | Highest |

### When to Choose Each

- **Sync API**: When the caller needs an immediate response and the downstream service is reliable
- **Async queue**: When work can be deferred, or you need to buffer against load spikes
- **Event stream**: When multiple consumers need the same data, or you need replay capability
- **File transfer**: When integrating with legacy/batch systems, or data volumes are massive (GBs)

---

## 2. Event-Driven Integration

### Message Broker Comparison

| Broker | Model | Throughput | Durability | Best For |
|--------|-------|-----------|-----------|----------|
| **Apache Kafka** | Log-based streaming | Very high (millions/sec) | Durable (configurable retention) | Event sourcing, streaming, high-throughput |
| **Redpanda** | Kafka-compatible | Very high | Durable | Kafka alternative, simpler ops (no JVM/ZK) |
| **Apache Pulsar** | Log + queue hybrid | Very high | Tiered storage | Multi-tenancy, geo-replication |
| **NATS JetStream** | Lightweight streaming | High | Configurable | Lightweight, edge, IoT, request-reply |
| **RabbitMQ** | Traditional queue | Medium-High | Durable | Complex routing, task queues, RPC |
| **Amazon SQS/SNS** | Managed queue + pub/sub | High | Managed | Serverless, AWS-native, zero ops |
| **Google Pub/Sub** | Managed pub/sub | High | Managed | GCP-native, global ordering |
| **Azure Service Bus** | Managed queue | High | Managed | Azure-native, enterprise features |
| **Redis Streams** | Lightweight streaming | High | With AOF/RDB | Simple streaming, already using Redis |

### Kafka Architecture Essentials

```
Producer → Topic (partitioned) → Consumer Group

Key concepts:
- Topic: Named stream of events
- Partition: Ordered, immutable append-only log
- Consumer Group: Set of consumers that share partitions
- Offset: Consumer's position in a partition
- Retention: How long events are kept (time or size based)
```

**Kafka operational considerations:**
- **Partitioning key**: Choose carefully — determines ordering and parallelism
- **Consumer group rebalancing**: Can cause brief processing pauses
- **Schema evolution**: Use Avro + Schema Registry with compatibility modes
- **Exactly-once semantics**: Kafka Transactions + idempotent producers (since Kafka 0.11)
- **Kafka Connect**: Pre-built connectors for databases, S3, Elasticsearch, etc.

### Redpanda as Kafka Alternative

Redpanda is Kafka-compatible (same protocol, same clients) but:
- No JVM dependency (C++ implementation)
- No ZooKeeper (built-in Raft consensus)
- Simpler operations (single binary)
- Often faster for tail latencies
- Good choice when you want Kafka semantics without Kafka operational complexity

### Event Schema Management

| Tool | Format | Features |
|------|--------|----------|
| **Confluent Schema Registry** | Avro, Protobuf, JSON Schema | Compatibility checking, versioning, Kafka integration |
| **Apicurio Registry** | Avro, Protobuf, JSON Schema, OpenAPI | Open-source, multiple storage backends |
| **Buf Schema Registry (BSR)** | Protobuf | Breaking change detection, code generation, module management |
| **AWS Glue Schema Registry** | Avro, JSON Schema | AWS-native, Kafka/Kinesis integration |

**Schema compatibility modes:**
- **Backward**: New schema can read old data (add optional fields)
- **Forward**: Old schema can read new data (remove optional fields)
- **Full**: Both backward and forward compatible
- **None**: No compatibility checking (not recommended)

### CDC (Change Data Capture)

Capture database changes as events without modifying application code:

- **Debezium**: Open-source CDC from database transaction logs. Supports PostgreSQL, MySQL, MongoDB, SQL Server, Oracle. Emits events to Kafka.
- **AWS DMS**: Managed CDC service for AWS databases
- **Fivetran / Airbyte**: SaaS CDC for data integration

**Debezium architecture:**
```
Database (WAL/binlog) → Debezium Connector → Kafka → Consumers
                                                    ├── Search index (Elasticsearch)
                                                    ├── Cache invalidation (Redis)
                                                    ├── Analytics (data warehouse)
                                                    └── Other services
```

---

## 3. API Gateways

### Gateway Decision Matrix

| Gateway | Type | Best For | Key Features |
|---------|------|----------|-------------|
| **Kong** | Self-hosted (Lua/Nginx) | Large-scale, plugin ecosystem | 100+ plugins, declarative config, K8s Ingress |
| **Envoy** | Proxy/sidecar | Service mesh, high-performance | L7 proxy, gRPC-native, xDS API, Wasm extensions |
| **Traefik** | Reverse proxy | Container-native, auto-discovery | Docker/K8s native, automatic TLS, middleware |
| **AWS API Gateway** | Managed | Serverless/AWS-native | Lambda integration, usage plans, WebSocket |
| **Azure API Management** | Managed | Enterprise Azure | Developer portal, policy engine, monetization |
| **Google Cloud API Gateway** | Managed | GCP-native | OpenAPI-based, Cloud Functions integration |
| **KrakenD** | Self-hosted | API aggregation | Stateless, declarative, response composition |
| **Tyk** | Self-hosted | API management | Analytics, developer portal, GraphQL support |

### Gateway vs Service Mesh

| Concern | API Gateway | Service Mesh (Istio/Linkerd) |
|---------|------------|------------------------------|
| **Position** | Edge (north-south traffic) | Internal (east-west traffic) |
| **Primary job** | External API management | Service-to-service communication |
| **Auth** | API keys, OAuth, JWT validation | mTLS, SPIFFE identity |
| **Rate limiting** | Per-consumer/API key | Per-service/endpoint |
| **When needed** | Any external API | 50+ internal services |

**Don't use both** unless you have genuinely different needs at the edge vs internally. For <20 services, an API gateway + application-level retries/circuit breakers is simpler than a full mesh.

### Gateway Anti-Pattern

**Don't put business logic in the gateway.** The gateway should be a thin layer for:
- Routing
- Authentication/authorization
- Rate limiting
- Request/response transformation (light)
- SSL termination
- Logging/metrics

If you find yourself writing complex orchestration or data transformation in the gateway, extract it into a dedicated service.

---

## 4. Workflow Orchestration

### Durable Execution Engines

Durable execution engines guarantee that workflows complete despite failures, restarts, or infrastructure changes. They're transforming how developers build reliable distributed applications.

| Engine | Language | Key Features | Best For |
|--------|----------|-------------|----------|
| **Temporal** | Go, Java, TypeScript, Python, .NET | Durable execution, versioning, visibility, multi-cluster | Complex business workflows, long-running processes, saga orchestration |
| **Restate** | TypeScript, Java, Kotlin, Go, Python | Durable execution with virtual objects, lightweight | Simpler workflows, event-driven, lower operational overhead |
| **AWS Step Functions** | JSON/YAML (ASL) | Serverless, visual workflow, AWS integration | AWS-native, simple state machines, Lambda orchestration |
| **Inngest** | TypeScript, Python, Go | Event-driven functions, step functions, cron | Serverless workflows, background jobs, scheduled tasks |
| **Trigger.dev** | TypeScript | Background jobs, long-running tasks | TypeScript-first, simple deployment |
| **Apache Airflow** | Python | DAG-based, massive ecosystem | Data pipelines, batch ETL |
| **Dagster** | Python | Asset-based, type-safe, observable | Modern data pipelines, software-defined assets |
| **Prefect** | Python | Pythonic, flexible, observable | ML pipelines, data engineering |

### Temporal Deep Dive

Temporal has emerged as the leading open-source platform for durable execution. In 2026, it's standard for complex business workflows and increasingly for agent orchestration.

**Core concepts:**
- **Workflow**: A function that orchestrates activities, can run for days/months
- **Activity**: A function that performs a single operation (API call, DB write, file processing)
- **Worker**: Process that executes workflows and activities
- **Signal**: External input to a running workflow
- **Query**: Read state of a running workflow without affecting it
- **Timer**: Durable sleep (survives process restarts)

**When Temporal vs Kafka:**
- **Temporal**: Orchestration (coordinate steps in order), long-running processes, human-in-the-loop, complex retry logic
- **Kafka**: Choreography (events trigger independent reactions), high-throughput streaming, event replay, data distribution

They're complementary: Temporal orchestrates; Kafka distributes.

### Orchestration vs Choreography

| Aspect | Orchestration | Choreography |
|--------|--------------|--------------|
| **Control** | Central coordinator directs services | Each service reacts to events independently |
| **Visibility** | Easy to see the full workflow | Hard to trace the full flow |
| **Coupling** | Services coupled to orchestrator | Services coupled to event schema |
| **Debugging** | Easier (single point of truth) | Harder (distributed, emergent behavior) |
| **Best for** | 5+ step workflows, complex logic | Simple event-driven reactions, decoupling |
| **Tools** | Temporal, Step Functions, BPMN engines | Kafka, NATS, event bus |

**Recommendation**: Use orchestration for business processes with defined flows. Use choreography for data distribution and loose coupling. Many systems use both.

---

## 5. Third-Party Integration

### Webhook Design

**Sending webhooks (your system → consumers):**
```json
POST /webhook-endpoint HTTP/1.1
Content-Type: application/json
X-Webhook-Signature: sha256=abc123...
X-Webhook-ID: evt_12345
X-Webhook-Timestamp: 1620000000

{
  "type": "order.completed",
  "data": {
    "order_id": "ord_123",
    "total": 49.99
  }
}
```

**Webhook reliability patterns:**
1. **Signature verification**: HMAC-SHA256 of payload with shared secret
2. **Retry with exponential backoff**: Retry 3-5 times over 24 hours
3. **Idempotency**: Include `X-Webhook-ID` so consumers can deduplicate
4. **Timeout**: 5-30 second timeout per delivery attempt
5. **Dead letter**: After max retries, store failed deliveries for manual retry
6. **Webhook-to-queue bridge**: Convert incoming webhooks to queue messages for reliable processing

### OAuth Token Management

When integrating with third-party APIs that use OAuth:
- **Token storage**: Encrypted at rest, never in logs or error messages
- **Token refresh**: Refresh proactively before expiry (at 80% of TTL)
- **Token caching**: Cache access tokens, share across instances (Redis)
- **Rate limit handling**: Respect `Retry-After` headers, implement backoff
- **Circuit breaker**: Open circuit after N consecutive failures, half-open to test recovery

### Integration Resilience Patterns

| Pattern | What It Does | When to Use |
|---------|-------------|-------------|
| **Circuit Breaker** | Stop calling a failing service, fail fast | Any external dependency |
| **Retry with Backoff** | Retry transient failures with increasing delay | Network errors, 503s, timeouts |
| **Bulkhead** | Isolate resources per dependency | Prevent one slow integration from exhausting all connections |
| **Timeout** | Bound how long you wait for a response | Every external call (always set explicit timeouts) |
| **Fallback** | Serve cached/default data when dependency fails | When partial data is better than no data |
| **Rate Limiter** | Self-throttle to stay within third-party limits | APIs with strict rate limits |

### Circuit Breaker State Machine

```
CLOSED (normal operation)
  │ Failure count exceeds threshold
  ▼
OPEN (fail fast, don't call service)
  │ After timeout period
  ▼
HALF-OPEN (allow one test request)
  │ Success → CLOSED
  │ Failure → OPEN
```

Typical config: Open after 50% failure rate in a 10-second window. Half-open after 30 seconds.

---

## 6. Data Integration and ETL/ELT

### Modern Data Stack

```
Sources → Extract/Load → Transform → Serve
          (Fivetran,      (dbt)       (BI tools,
           Airbyte)                    ML models)
```

| Component | Tools | Purpose |
|-----------|-------|---------|
| **Extract/Load** | Fivetran (SaaS), Airbyte (open-source), Meltano | Pull data from sources into warehouse/lake |
| **Transform** | dbt (SQL transforms), Spark, Flink | Model, clean, aggregate data |
| **Storage** | Snowflake, BigQuery, Databricks, Redshift | Analytical storage |
| **Orchestration** | Dagster, Airflow, Prefect | Schedule and coordinate pipelines |
| **Quality** | Great Expectations, Soda, dbt tests | Validate data quality |
| **Catalog** | DataHub, OpenMetadata, Amundsen | Discover and document data assets |

### Batch vs Streaming

| Aspect | Batch (ETL/ELT) | Streaming |
|--------|-----------------|-----------|
| **Latency** | Minutes to hours | Seconds to milliseconds |
| **Complexity** | Lower | Higher |
| **Cost** | Lower (process in bulk) | Higher (always running) |
| **Use case** | Reporting, analytics, data warehouse | Real-time dashboards, alerts, event processing |
| **Tools** | dbt, Spark (batch), Airflow | Kafka Streams, Flink, Spark Structured Streaming |

### Streaming ETL

Process data in real-time as it flows through:

| Tool | Approach | Best For |
|------|----------|----------|
| **Kafka Streams** | Library (runs in your app) | Simple stream processing, Kafka-native |
| **Apache Flink** | Distributed engine | Complex event processing, exactly-once, large state |
| **Spark Structured Streaming** | Micro-batch | Unified batch + streaming, SQL-friendly |
| **Redpanda Connect (Benthos)** | Declarative pipelines | Simple transforms, routing, protocol translation |

### Reverse ETL

Push data from the warehouse back into operational tools:
- **Hightouch**, **Census**: SaaS reverse ETL
- Use case: Sync customer segments from Snowflake to Salesforce, HubSpot, Braze
- Growing pattern as warehouses become the source of truth for customer data

---

## 7. Distributed Transactions

### Saga Pattern

When a business operation spans multiple services, use the saga pattern instead of distributed transactions:

**Choreography-based saga (event-driven):**
```
OrderService creates order → publishes OrderCreated
PaymentService charges card → publishes PaymentCompleted
InventoryService reserves stock → publishes StockReserved
ShippingService creates shipment → publishes ShipmentCreated

Compensation (if payment fails):
PaymentService publishes PaymentFailed
OrderService cancels order → publishes OrderCancelled
InventoryService releases stock
```

**Orchestration-based saga (coordinator):**
```
Saga Orchestrator:
1. Create Order (OrderService)
2. Charge Payment (PaymentService)
   - If fails: Cancel Order (compensate step 1)
3. Reserve Stock (InventoryService)
   - If fails: Refund Payment, Cancel Order
4. Create Shipment (ShippingService)
   - If fails: Release Stock, Refund Payment, Cancel Order
```

**When to use each:**
- **Choreography**: 2-4 steps, simple flows, loose coupling preferred
- **Orchestration**: 5+ steps, complex compensation logic, need visibility

### Outbox Pattern

Solve the dual-write problem (atomically update DB + publish event):

```
1. BEGIN TRANSACTION
2. Update business table (orders)
3. Insert event into outbox table
4. COMMIT TRANSACTION

-- Separate process (poller or CDC):
5. Read outbox table for unpublished events
6. Publish to message broker
7. Mark events as published
```

**Implementation options:**
- **Polling publisher**: Simple, adds latency (poll interval)
- **CDC (Debezium)**: Near-real-time via transaction log tailing. Recommended for production.
- **Transactional outbox libraries**: Built into some frameworks (Axon, MassTransit)

---

## 8. B2B and Legacy Integration

### Common B2B Protocols

| Protocol | Domain | Modern Alternative |
|----------|--------|-------------------|
| **EDI (X12, EDIFACT)** | Supply chain, logistics | API + webhook, but EDI still dominant in large enterprises |
| **AS2** | Secure B2B file transfer | SFTP + PGP, API-based transfer |
| **SFTP** | File exchange | API-based, but still very common |
| **HL7 v2** | Healthcare messaging | HL7 FHIR (REST-based) |
| **SWIFT / ISO 20022** | Financial messaging | Open Banking APIs, PSD2 |

### Legacy Integration Patterns

| Pattern | Description | When to Use |
|---------|------------|-------------|
| **Strangler Fig** | Gradually replace legacy behind a facade | Incremental migration |
| **Anti-Corruption Layer** | Translation layer between old and new | Protect new system from legacy model |
| **Database View** | Expose legacy data through database views | Read-only integration with legacy DB |
| **Change Data Capture** | Stream changes from legacy DB | When can't modify legacy code |
| **File Drop** | Exchange data via files on shared storage | When legacy only supports batch/file |
| **Screen Scraping** | Automate legacy UI interactions | Last resort when no other interface exists |

---

## 9. Integration Testing and Observability

### Contract Testing

Verify that API consumers and providers agree on the contract:

| Tool | Approach | Best For |
|------|----------|----------|
| **Pact** | Consumer-driven contracts | REST/GraphQL, multi-language, mature ecosystem |
| **Spring Cloud Contract** | Producer-driven | Spring Boot microservices |
| **Schemathesis** | Property-based from OpenAPI spec | Auto-generated edge cases, fuzzing |
| **Specmatic** | Spec-driven (OpenAPI → tests) | Contract-as-spec, zero-code tests |

### Distributed Tracing

Track requests across service boundaries:

- **OpenTelemetry**: Vendor-neutral standard for traces, metrics, and logs. The industry standard.
- **Trace context propagation**: W3C Trace Context (`traceparent` header) across all services
- **Correlation IDs**: Include in all logs, events, and API responses for end-to-end tracing
- **Backends**: Jaeger (open-source), Tempo (Grafana), Honeycomb, Datadog, New Relic

### Integration Observability Checklist

| What to Monitor | Why |
|----------------|-----|
| **Latency per integration** | Detect slow downstream services before they cascade |
| **Error rate per integration** | Circuit breaker trigger, dependency health |
| **Queue depth** | Consumer lag, processing bottleneck |
| **Dead letter queue size** | Failed messages requiring attention |
| **Schema compatibility** | Breaking changes in event schemas |
| **Token expiry** | OAuth tokens about to expire |
| **Rate limit headroom** | How close to hitting third-party limits |

---

## 10. Anti-Patterns

### What to Avoid

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Distributed Monolith** | Services must deploy together, share database, tight coupling | Enforce bounded contexts, database per service, async communication |
| **Chatty Integration** | Too many fine-grained calls between services | Aggregate into bulk operations, use events, BFF pattern |
| **Shared Database** | Two services reading/writing the same tables | Database per service + events for synchronization |
| **ESB as Business Logic** | Complex orchestration logic in middleware | Move logic to services, use lightweight gateways |
| **Point-to-Point Spaghetti** | Every service talks directly to every other | Introduce event bus or API gateway |
| **Synchronous Chain** | A → B → C → D → E (one slow link kills everything) | Break chains with async messaging, timeouts, circuit breakers |
| **Ignoring Idempotency** | Duplicate messages cause duplicate processing | Idempotency keys, deduplication at consumer |
| **No Dead Letter Queue** | Failed messages are silently dropped | Always configure DLQ, alert on DLQ growth |

---

## Decision Framework Summary

| Decision | Default | Switch When |
|----------|---------|-------------|
| **Integration style** | Async messaging (queue/events) | Need immediate response (sync API), legacy (file transfer) |
| **Message broker** | Kafka (event streaming) or SQS (simple queue) | Lightweight/edge (NATS), complex routing (RabbitMQ), Kafka-compatible simpler ops (Redpanda) |
| **API gateway** | Traefik or Kong | AWS-native (API Gateway), high-performance proxy (Envoy), simple (Caddy) |
| **Workflow orchestration** | Temporal (complex) or Inngest (simple) | AWS-native (Step Functions), data pipelines (Dagster/Airflow) |
| **Schema format** | JSON Schema (getting started) | High-throughput (Avro + Schema Registry), type safety (Protobuf + Buf) |
| **CDC** | Debezium | AWS-native (DMS), SaaS (Fivetran/Airbyte) |
| **Saga pattern** | Choreography (simple flows) | Orchestration (5+ steps, complex compensation) |
| **Distributed transactions** | Outbox pattern + CDC | Temporal saga (complex multi-service) |
| **Contract testing** | Pact | OpenAPI-driven (Schemathesis), Spring (Spring Cloud Contract) |
| **Tracing** | OpenTelemetry + Jaeger/Tempo | SaaS (Honeycomb, Datadog) for managed experience |
