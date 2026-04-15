# Microservices Architecture — Deep Reference

**Always use `WebSearch` to verify version numbers and tooling. Distributed systems tooling evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [Service Decomposition](#1-service-decomposition)
2. [Inter-Service Communication](#2-inter-service-communication)
3. [Message Brokers](#3-message-brokers)
4. [Saga Patterns](#4-saga-patterns)
5. [Circuit Breakers and Resilience](#5-circuit-breakers-and-resilience)
6. [Service Mesh](#6-service-mesh)
7. [Service Discovery](#7-service-discovery)
8. [API Gateway](#8-api-gateway)
9. [Event-Driven Architecture](#9-event-driven-architecture)
10. [Data Management](#10-data-management)
11. [Distributed Tracing and Observability](#11-distributed-tracing-and-observability)
12. [Testing Microservices](#12-testing-microservices)
13. [Deployment Patterns](#13-deployment-patterns)
14. [Workflow Orchestration (Temporal)](#14-workflow-orchestration-temporal)
15. [Platform Engineering](#15-platform-engineering)
16. [When NOT to Use Microservices](#16-when-not-to-use-microservices)

---

## 1. Service Decomposition

### How to Decompose

**Domain-Driven Design (DDD) is the foundation:**
1. Identify **bounded contexts** — distinct areas of the business with their own ubiquitous language
2. Map bounded contexts to services — one context, one service (roughly)
3. Define **context maps** — how contexts relate (shared kernel, customer-supplier, anti-corruption layer)

**Decomposition patterns:**
| Pattern | When to Use |
|---------|------------|
| **By business capability** | Clear business functions (orders, payments, inventory) |
| **By subdomain** | DDD-aligned (core, supporting, generic subdomains) |
| **Strangler fig** | Incrementally extracting from a monolith |
| **By team** | Conway's Law — services mirror team structure |

### Right-Sizing Services

**Too big:** Still a monolith with a network boundary. Signs: multiple teams need to coordinate deployments, services own too many database tables, changes cascade across multiple domains.

**Too small (nano-services):** More infrastructure overhead than value. Signs: most requests fan out to 5+ services, you have more services than engineers, simple features require changes to 3+ services.

**Right-sized:** One team owns one service. Service can be rewritten in 2-4 weeks. Service has a clear API contract. Deploys independently without coordinating with other services.

### Strangler Fig Pattern (Monolith → Microservices)

```
1. Identify a bounded context in the monolith
2. Build the new service alongside the monolith
3. Route traffic to the new service (API gateway or proxy)
4. Migrate data (dual-write, then cutover)
5. Remove the old code from the monolith
6. Repeat for the next bounded context
```

**Critical rule:** Never do a big-bang rewrite. Extract one service at a time. Each extraction should deliver value independently.

---

## 2. Inter-Service Communication

### Synchronous vs Asynchronous

| | Synchronous | Asynchronous |
|---|------------|-------------|
| **Protocol** | REST, gRPC, Connect | Message queue, event stream |
| **Coupling** | Temporal (both must be up) | Decoupled (producer/consumer independent) |
| **Latency** | Request-response, immediate | Eventually consistent |
| **Complexity** | Simpler | Harder to debug, eventual consistency |
| **Best for** | Queries, real-time reads | Commands, events, long workflows |

### Choreography vs Orchestration

**Choreography** (event-based):
- Each service listens for events and publishes its own
- No central coordinator — services react to what happened
- Simple for 3-4 step flows
- Hard to trace the full flow, hard to handle failures

**Orchestration** (command-based):
- Central orchestrator directs each service step by step
- Easy to understand, visualize, and debug
- Use for 5+ step flows or complex error handling
- Risk: orchestrator becomes a bottleneck or god service

### Communication Patterns

| Pattern | Use Case |
|---------|----------|
| **Request/Reply** | Synchronous query (gRPC/REST) |
| **Fire-and-Forget** | Async command that doesn't need response |
| **Publish/Subscribe** | Event notification to multiple consumers |
| **Request/Async Reply** | Long-running operations (send request, poll for result) |
| **Event-Carried State Transfer** | Events contain full state change (consumers don't need to call back) |

---

## 3. Message Brokers

### Comparison Matrix

| Broker | Throughput | Ordering | Replay | Best For |
|--------|-----------|----------|--------|----------|
| **Apache Kafka** | Very high (millions/sec) | Per partition | Yes (retention-based) | Event streaming, event sourcing, high-throughput pipelines |
| **NATS** | Very high | Per subject (JetStream) | JetStream only | Lightweight messaging, request-reply, IoT, edge |
| **RabbitMQ** | High | Per queue | Limited | Complex routing, task queues, traditional messaging |
| **Redis Streams** | High | Per stream | Yes | When already using Redis, moderate throughput |
| **Amazon SQS/SNS** | High | FIFO variant only | No (except DLQ) | AWS-native, serverless, zero ops |
| **Redpanda** | Very high | Per partition | Yes | Kafka-compatible, simpler ops (no JVM/ZooKeeper) |
| **Apache Pulsar** | Very high | Per partition | Yes | Multi-tenancy, geo-replication, tiered storage |

### Kafka in 2026

**Kafka 4.0+ (March 2025)** removed ZooKeeper entirely — KRaft-only mode. Latest stable: **4.2.0** (February 2026).

Key patterns:
- **Topic per event type**: `order-created`, `payment-processed`
- **Consumer groups**: Multiple consumers share partition load
- **Compacted topics**: Keep latest value per key (materialized views)
- **Schema Registry**: Enforce schema evolution (Confluent Schema Registry, Apicurio)
- **Kafka Streams / ksqlDB**: Stream processing without separate framework

### NATS with JetStream

NATS JetStream adds persistence, replay, and exactly-once delivery to NATS's lightweight messaging:
- Subjects with wildcards: `orders.>`, `orders.*.created`
- Key-Value store built on JetStream (like Redis for config/state)
- Object store for large payloads
- Best for: microservices that need lightweight messaging without Kafka's operational weight

---

## 4. Saga Patterns

### The Problem

Distributed transactions across services can't use traditional ACID transactions. Sagas provide a mechanism for maintaining data consistency across services without distributed locks.

### Choreography Saga

```
Order Service → publishes "OrderCreated"
Payment Service → listens, processes payment → publishes "PaymentProcessed"
Inventory Service → listens, reserves stock → publishes "StockReserved"
Shipping Service → listens, creates shipment → publishes "ShipmentCreated"

Compensation (on failure):
Shipping Service → publishes "ShipmentCancelled"
Inventory Service → listens, releases stock → publishes "StockReleased"
Payment Service → listens, refunds → publishes "PaymentRefunded"
```

**Pros:** Simple, no central point of failure
**Cons:** Hard to trace, hard to add new steps, compensation logic scattered

### Orchestration Saga

```
Order Orchestrator:
  1. → Payment Service: "Process payment"     ← OK
  2. → Inventory Service: "Reserve stock"      ← OK
  3. → Shipping Service: "Create shipment"     ← FAIL
  Compensate:
  3c. → Inventory Service: "Release stock"
  2c. → Payment Service: "Refund payment"
```

**Pros:** Easy to understand, centralized compensation, easy to add steps
**Cons:** Orchestrator can become a bottleneck, single point of failure

### Saga Implementation Options

| Tool | Language | Pattern |
|------|----------|---------|
| **Temporal** | Any (Go, Java, TypeScript, Python, Rust) | Workflow orchestration with durable execution |
| **Axon Framework** | Java/Kotlin | Event sourcing + saga management |
| **MassTransit** | .NET | State machine sagas |
| **NServiceBus** | .NET | Saga pattern built-in |

**Recommendation:** For new projects, use Temporal — it handles retries, compensation, timeouts, and failure recovery automatically.

### Saga Design Guidelines

- Every step must have a compensating action
- Compensating actions must be idempotent (safe to retry)
- Design for partial failure — any step can fail at any point
- Use idempotency keys to prevent duplicate processing
- Set timeouts on every step — don't wait forever

---

## 5. Circuit Breakers and Resilience

### Circuit Breaker Pattern

```
Closed (normal) → Open (fail fast) → Half-Open (test recovery)

Closed:  Requests pass through. Track failure rate.
         If failure rate > threshold (e.g., 50% in 10s) → Open.

Open:    All requests fail immediately (no downstream call).
         After timeout (e.g., 30s) → Half-Open.

Half-Open: Allow limited test requests.
           If they succeed → Closed.
           If they fail → Open (reset timeout).
```

### Resilience Patterns

| Pattern | Purpose | Implementation |
|---------|---------|---------------|
| **Circuit breaker** | Prevent cascade failures | resilience4j (Java), Polly (.NET), gobreaker (Go) |
| **Retry with backoff** | Handle transient failures | Exponential backoff + jitter: `delay = min(base * 2^attempt + random, max)` |
| **Bulkhead** | Isolate failures | Separate thread pools/connections per dependency |
| **Timeout** | Prevent hanging | Always set explicit timeouts (connection: 1-5s, read: 5-30s) |
| **Fallback** | Graceful degradation | Return cached data, default values, or degraded response |
| **Rate limiter** | Protect downstream | Limit outgoing calls per time window |

### Key Rules

- **Never retry non-idempotent operations** blindly (don't retry POST without idempotency key)
- **Set downstream timeouts shorter than your own service's timeout** (prevent timeout chains)
- **Always add jitter to retries** — synchronized retries create thundering herd
- **Fail fast when circuit is open** — return 503 immediately, don't queue

### Implementation by Language

| Language | Library | Notes |
|----------|---------|-------|
| Java | resilience4j | Circuit breaker, rate limiter, bulkhead, retry, time limiter |
| .NET | Polly | Comprehensive resilience library |
| Go | gobreaker, sony/gobreaker | Simple, effective circuit breakers |
| TypeScript | cockatiel, opossum | Circuit breaker + retry + bulkhead |
| Rust | tower (TimeoutLayer, RateLimitLayer) | Tower middleware provides resilience patterns |

---

## 6. Service Mesh

### What a Service Mesh Does

Handles cross-cutting concerns for service-to-service communication at the infrastructure layer:
- **mTLS** (automatic encryption between services)
- **Traffic management** (retries, timeouts, circuit breaking, canary routing)
- **Observability** (distributed tracing, metrics, access logs — without code changes)
- **Authorization policies** (which service can call which)

### Comparison (2026)

| Mesh | Architecture | Version | Best For |
|------|-------------|---------|----------|
| **Istio** | Sidecar (Envoy) + Ambient mode (sidecarless) | ~1.27 | Full-featured, large deployments, strong community |
| **Linkerd** | Sidecar (Rust-based proxy) | 2.18 | Simplicity, low resource overhead, CNCF graduated |
| **Cilium** | eBPF-based (kernel-level) | CNCF graduated | Performance, observability, combined networking + mesh |

### Istio Ambient Mesh

**Key evolution in 2026:** Ambient mesh (GA since Istio 1.24) eliminates per-pod Envoy sidecars in favor of per-node ztunnel proxies + optional waypoint proxies:
- **ztunnel** (zero-trust tunnel): Per-node, handles mTLS and L4 policies
- **Waypoint proxy**: Optional per-service, handles L7 policies (HTTP routing, auth)
- **90%+ memory reduction** and **50%+ CPU reduction** compared to sidecar mode
- Simpler operations — no sidecar injection, no pod restart for mesh changes
- Istio 1.27: ambient multicluster (beta), Gateway API Inference Extension for AI workloads

### When to Use a Service Mesh

**Use when:**
- 50+ services needing consistent mTLS, observability, and traffic management
- Zero-trust networking is required
- You need traffic splitting for canary deployments at the infrastructure level
- Teams shouldn't have to implement retry/timeout logic in application code

**Don't use when:**
- <10-15 services — handle in application code or shared libraries
- Team lacks Kubernetes expertise
- Simple networking needs that a load balancer handles

---

## 7. Service Discovery

### Mechanisms

| Mechanism | How It Works | Best For |
|-----------|-------------|----------|
| **Kubernetes DNS** | Services resolve via `service-name.namespace.svc.cluster.local` | K8s-native services |
| **Consul** | Service catalog with health checking, KV store, connect mesh | Multi-datacenter, multi-cloud |
| **etcd** | Distributed key-value store (Kubernetes uses it internally) | Custom service registries |
| **Client-side discovery** | Client queries registry, picks instance (Eureka, Consul client) | Fine-grained load balancing control |
| **Server-side discovery** | Load balancer queries registry (AWS ALB, K8s Service) | Simpler client, infrastructure handles routing |

### Recommendation

- **Kubernetes environments:** K8s DNS + Service resources are sufficient for most cases
- **Multi-cloud / hybrid:** Consul for its multi-datacenter capabilities
- **Service mesh:** The mesh handles discovery — you don't need a separate mechanism

---

## 8. API Gateway

### Gateway vs Service Mesh

| Concern | API Gateway | Service Mesh |
|---------|------------|-------------|
| **Scope** | North-south (external → internal) | East-west (internal ↔ internal) |
| **Auth** | Validate external tokens, API keys | mTLS between services |
| **Rate limiting** | External client limits | Internal service limits |
| **Protocol** | HTTP/REST/GraphQL → internal | gRPC/HTTP between services |

Use both: API gateway for external traffic, service mesh for internal traffic.

### Gateway Patterns

| Pattern | Description |
|---------|------------|
| **Routing** | Route requests to correct backend service |
| **Aggregation** | Combine responses from multiple services into one |
| **Protocol translation** | REST → gRPC, GraphQL → REST |
| **Authentication** | Validate tokens before forwarding |
| **Rate limiting** | Protect backends from overload |
| **Request transformation** | Add/remove headers, transform payloads |

### Kubernetes Gateway API (2026 Standard)

The Kubernetes Gateway API is replacing Ingress as the standard for traffic management:
- **GatewayClass**: Defines the controller (Envoy, Istio, Cilium, Kong)
- **Gateway**: Defines listeners (ports, protocols, TLS)
- **HTTPRoute**: Defines routing rules (path matching, header matching, traffic splitting)

Supported by: Envoy Gateway, Istio, Cilium, Kong, Traefik, HAProxy.

---

## 9. Event-Driven Architecture

### Event Types

| Type | Description | Example |
|------|------------|---------|
| **Domain event** | Something that happened in the business | OrderPlaced, PaymentReceived |
| **Integration event** | Cross-service notification | UserCreated (notifies other services) |
| **Command** | Request to do something | ProcessPayment, SendEmail |
| **Change event (CDC)** | Database state change captured | Row insert/update/delete in orders table |

### Event Sourcing

Store state as an immutable sequence of events instead of current state:

```
Event 1: OrderCreated { orderId: "123", items: [...], total: 99.00 }
Event 2: PaymentReceived { orderId: "123", amount: 99.00, method: "card" }
Event 3: ItemShipped { orderId: "123", trackingNumber: "TRACK-456" }
```

**Benefits:** Complete audit trail, temporal queries (state at any point in time), event replay for rebuilding state.

**Challenges:** Schema evolution (how to handle changed event formats), read performance requires projections, storage growth.

**When to use:** Audit-critical domains (finance, healthcare, legal), systems where "why" matters as much as "what", domains that benefit from temporal queries.

### CQRS (Command Query Responsibility Segregation)

Separate the write model (commands) from the read model (queries):

```
Commands → Write Store (normalized, ACID) → CDC/Events → Read Store (denormalized, fast)

Write: PostgreSQL (source of truth, ACID transactions)
Read: Elasticsearch (search), Redis (fast lookups), Materialized views (aggregations)
```

**When to use:** Read/write patterns differ vastly, need multiple read representations, heavily skewed ratio (90%+ reads), need independent scaling of reads and writes.

### Outbox Pattern (Reliable Event Publishing)

Solves the dual-write problem — how to atomically update DB AND publish an event:

```
1. Write business data + event to "outbox" table in same DB transaction
2. Separate process reads outbox and publishes to message broker
3. Mark outbox records as processed
```

**Implementation options:**
- **Polling publisher**: Simple, adds 100-500ms latency
- **CDC (Debezium)**: Near-real-time via transaction log tailing, more complex setup

### Change Data Capture (CDC)

Capture database changes (insert/update/delete) from the transaction log and stream them as events:

- **Debezium**: Most popular CDC tool, supports PostgreSQL, MySQL, MongoDB, SQL Server
- Connects to Kafka, Kinesis, Pub/Sub
- Enables real-time data pipelines, cache invalidation, search index updates

---

## 10. Data Management

### Database per Service (Recommended Default)

Each service owns its database — no shared database access. This enforces loose coupling.

**Challenges and solutions:**

| Challenge | Solution |
|-----------|----------|
| Cross-service queries | API composition (service A calls service B) or CQRS read models |
| Distributed transactions | Saga pattern (not distributed 2PC) |
| Data consistency | Eventual consistency via events |
| Reporting/analytics | Event streaming to data warehouse, CQRS read models |
| Reference data | Shared reference data service, event-carried state transfer |

### Shared Database Anti-Pattern

Multiple services sharing a database creates tight coupling:
- Schema changes affect all services
- One service's query can degrade another's performance
- Can't deploy or scale services independently
- Use only as a temporary step during migration from monolith

### Data Consistency Patterns

| Pattern | Consistency | Performance | Complexity |
|---------|------------|-------------|------------|
| **Saga** | Eventually consistent | Good | High |
| **Event-carried state transfer** | Eventually consistent | Best (no callbacks) | Medium |
| **API composition** | Strong (at query time) | Latency depends on slowest service | Low |
| **CQRS with CDC** | Eventually consistent | Read-optimized | High |

---

## 11. Distributed Tracing and Observability

### Three Pillars

| Pillar | What It Provides | Tools |
|--------|-----------------|-------|
| **Metrics** | Aggregated measurements (latency, error rate, throughput) | Prometheus, Grafana, Datadog |
| **Logs** | Discrete events with structured data | ELK/EFK, Loki, Datadog |
| **Traces** | Request flow across services with timing | Jaeger, Tempo, Zipkin, Datadog |

### OpenTelemetry (2026 Standard)

OpenTelemetry has become the standard for observability instrumentation:

- **Traces**: Stable across all languages
- **Metrics**: Stable
- **Logs**: Stable (bridges exist for all major logging libraries)
- **Profiling**: Alpha (March 2026) — the 4th signal, targeting GA by Q3 2026
- **OTLP** (OpenTelemetry Protocol): Standard wire format for exporting telemetry (v1.10.0)

**Auto-instrumentation:** Libraries for Java, Node.js, Python, Go, .NET, Ruby — instrument HTTP clients, database queries, and gRPC calls without code changes.

### Distributed Tracing Pattern

```
[API Gateway] ──trace-id: abc──→ [User Service] ──trace-id: abc──→ [Database]
                                        │
                                        └──trace-id: abc──→ [Auth Service]
```

- **Trace ID** propagated via headers (`traceparent` / W3C Trace Context)
- Each service creates **spans** (named, timed units of work)
- Spans form a tree showing the request flow and timing across services
- **Baggage**: Key-value pairs propagated with trace context (tenant ID, feature flags)

### SLIs, SLOs, SLAs

| Level | Definition | Example |
|-------|-----------|---------|
| **SLI** (Indicator) | Metric that measures service quality | p99 latency, error rate, availability |
| **SLO** (Objective) | Target for an SLI | p99 latency < 200ms, 99.9% availability |
| **SLA** (Agreement) | Business contract with penalties | 99.95% uptime or credits issued |

**Error budgets:** If SLO is 99.9% (43 minutes/month downtime), the error budget is 0.1%. When budget is exhausted, focus on reliability over features.

---

## 12. Testing Microservices

### Testing Pyramid for Microservices

```
        △ End-to-End (few)
       ╱ ╲   Cross-service integration flows
      ╱───╲ Contract Tests (moderate)
     ╱     ╲  Pact / consumer-driven contracts
    ╱───────╲ Integration Tests (many)
   ╱         ╲  Service + real DB/queue (testcontainers)
  ╱───────────╲ Unit Tests (most)
 ╱             ╲  Business logic, domain models
```

### Contract Testing (Critical for Microservices)

**Consumer-Driven Contracts (Pact):**
1. Consumer writes tests defining expected API interactions
2. Pact generates a contract (JSON)
3. Provider verifies it can fulfill the contract
4. Contracts are versioned and tracked (Pactflow/Pact Broker)

**Why it matters:** Catches breaking changes between services before deployment — without running all services together.

### Chaos Engineering

Test system resilience by injecting failures:

| Tool | What It Does |
|------|-------------|
| **Litmus** (CNCF) | Kubernetes-native chaos engineering |
| **Chaos Mesh** | Comprehensive fault injection for K8s |
| **Gremlin** | SaaS chaos engineering platform |
| **Toxiproxy** | Simulate network conditions (latency, errors) |

**Game days:** Scheduled exercises where teams inject failures and practice incident response.

---

## 13. Deployment Patterns

### Strategies for Microservices

| Strategy | How It Works | Risk | Rollback Speed |
|----------|-------------|------|---------------|
| **Rolling** | Replace instances gradually | Both versions serve during deploy | Slow (redeploy) |
| **Blue-Green** | Two identical environments, switch traffic | Double infrastructure cost | Instant (switch back) |
| **Canary** | Route small % of traffic to new version | Low (only affects canary %) | Fast (route away) |
| **Shadow/Dark** | Mirror traffic to new version (no user impact) | None (shadow doesn't serve users) | N/A |

### GitOps

- Store desired infrastructure state in Git
- Automated reconciliation: Git → Kubernetes (via ArgoCD or Flux)
- Every change is a Git commit — auditable, reversible
- Pull-based: Agent in cluster pulls changes (more secure than push-based)

**ArgoCD:** Most popular GitOps tool for Kubernetes. Watches Git repositories, syncs K8s manifests, provides UI for visualization.

**Flagger:** Progressive delivery operator — automates canary deployments, A/B testing, blue-green deployments with metrics-based promotion.

---

## 14. Workflow Orchestration (Temporal)

### What Temporal Solves

Temporal provides durable execution for complex, long-running workflows ($5B valuation, Series D February 2026):

- **Durable execution**: Workflow state survives process crashes, server restarts, even datacenter failures
- **Automatic retries**: Activity retries with configurable backoff
- **Compensation/cleanup**: Saga pattern built-in
- **Visibility**: Query workflow state, search workflows, view execution history
- **Timer management**: Sleep for days/weeks without holding resources
- **Temporal Nexus** (GA): Connect workflows across isolated namespaces
- **Multi-Region Replication** (GA): 99.99% SLA
- **Worker Versioning** (pre-release): Pin workflows to deployment versions with traffic ramping

### When to Use Temporal

- Multi-step business processes (order fulfillment, loan origination, onboarding)
- Long-running operations (data migrations, batch processing)
- Saga orchestration across microservices
- Scheduled and recurring tasks (cron-like workflows)
- Human-in-the-loop workflows (approvals, reviews)

### Architecture

```
Temporal Server (manages workflow state)
    ↕
Workers (your code, runs activities and workflows)
    ↕
Activities (individual steps: call API, send email, update DB)
```

SDKs: Go, Java, TypeScript, Python, .NET, Rust (community), PHP.

### Temporal vs Message Queues

| Concern | Temporal | Message Queue + Custom Code |
|---------|---------|---------------------------|
| Retry logic | Built-in, configurable | You implement |
| Compensation/rollback | Built-in saga support | You implement |
| Workflow state | Durable, queryable | You manage (DB + queue) |
| Visibility | Full execution history | You build |
| Complexity | Learn Temporal | Build everything yourself |

---

## 15. Platform Engineering

### Internal Developer Platforms (IDPs)

Platform engineering provides golden paths for developers — standardized ways to build, deploy, and operate services.

**Backstage** (Spotify, CNCF):
- Service catalog: Discover services, owners, APIs, documentation
- Software templates: Scaffold new services with best practices built-in
- TechDocs: Documentation-as-code, lives alongside service code
- Plugin ecosystem: CI/CD, monitoring, cloud resources

### Golden Paths

A "golden path" is the recommended, well-supported way to build and deploy a service:
- Scaffolding template with standard project structure
- Pre-configured CI/CD pipeline
- Built-in observability (tracing, metrics, logging)
- Standard auth middleware
- Health check endpoints
- Database migration tooling

**Why:** Reduces cognitive load on developers. They focus on business logic, not infrastructure.

---

## 16. When NOT to Use Microservices

### Choose a Monolith (or Modular Monolith) When

- Team is <20 engineers
- Domain boundaries are unclear (you're still discovering the product)
- You don't have DevOps/platform expertise for distributed systems
- Speed of iteration matters more than independent scaling
- The overhead of inter-service communication isn't justified

**Data point:** A 2026 CNCF survey found that **42% of organizations** that initially adopted microservices have consolidated some services back into larger deployable units, citing debugging complexity, operational overhead, and network latency.

### Signs You're Doing Microservices Wrong

| Symptom | Problem | Fix |
|---------|---------|-----|
| Must deploy services together | Distributed monolith | Merge into one service or fix coupling |
| Single request fans out to 10+ services | Over-decomposed | Merge related services |
| More infra time than feature time | Premature decomposition | Consolidate, invest in platform |
| Sagas everywhere for simple operations | Over-split data | Merge services that share data |
| 5 engineers, 20 services | Too many services | Target 1-2 services per team |

### The Modular Monolith Alternative

Single deployable unit with internal module boundaries:
- Modules communicate through well-defined interfaces (not direct DB access)
- Each module owns its own schema/tables
- Can extract to services later along module boundaries
- **Java**: Spring Modulith provides first-class support
- **TypeScript**: NestJS modules with DI scoping
- **Go**: Internal packages with clear import boundaries

**This is the recommended default for most new projects.** Extract to microservices only when you have evidence that the monolith is the bottleneck.

---

## Decision Framework

| Decision | Default | Switch When |
|----------|---------|-------------|
| Architecture | Modular monolith | Team >30, distinct scaling needs, clear domain boundaries |
| Communication | REST/gRPC (synchronous) | Fire-and-forget (async messaging), streaming (Kafka) |
| Message broker | SQS/Redis Streams | Need replay/streaming (Kafka), complex routing (RabbitMQ), lightweight (NATS) |
| Saga pattern | Temporal orchestration | Simple 3-step flows (choreography) |
| Service mesh | None (application code) | 50+ services, zero-trust requirement |
| Service discovery | K8s DNS | Multi-cloud (Consul) |
| Observability | OpenTelemetry | Already invested in vendor-specific (Datadog, etc.) |
| Deployment | Rolling | Need instant rollback (blue-green), minimize risk (canary) |
| Data pattern | Database per service | Still extracting from monolith (shared DB temporarily) |

**Overarching principle:** Start with a monolith. Extract services when you have evidence — not theory — that the monolith is the bottleneck. Every extraction should deliver measurable value (team autonomy, independent scaling, different technology needs). If you can't articulate the specific benefit, don't extract.
