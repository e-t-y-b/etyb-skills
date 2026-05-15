# Java Backend Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Modern Java (21+)](#1-modern-java-21)
2. [Framework Decision Matrix](#2-framework-decision-matrix)
3. [Spring Boot](#3-spring-boot)
4. [Quarkus](#4-quarkus)
5. [Micronaut](#5-micronaut)
6. [Reactive vs Virtual Threads](#6-reactive-vs-virtual-threads)
7. [Data Access](#7-data-access)
8. [API Frameworks](#8-api-frameworks)
9. [Messaging](#9-messaging)
10. [Testing](#10-testing)
11. [Performance and JVM Tuning](#11-performance-and-jvm-tuning)
12. [Deployment](#12-deployment)
13. [Observability](#13-observability)

---

## 1. Modern Java (21+)

### Virtual Threads (Project Loom) — Game Changer

Virtual threads (finalized in Java 21) fundamentally change Java backend architecture:

- **Lightweight threads managed by the JVM**, not the OS. One JVM can run millions.
- Created via `Thread.ofVirtual().start(runnable)` or `Executors.newVirtualThreadPerTaskExecutor()`
- When a virtual thread blocks (I/O, sleep, lock), it unmounts from its carrier thread, freeing it for other work
- **Architecture impact**: Thread-per-request model returns. No need for reactive programming just for scalability.
- **Performance**: ~5-10x improvement in concurrent request handling for I/O-bound workloads vs platform threads
- Memory: ~1 KB per virtual thread (vs ~1 MB stack for platform threads)
- Create/destroy: nanoseconds (vs microseconds for platform threads)

**What virtual threads DON'T change:**
- Connection pooling still matters (database connections are finite resources)
- CPU-bound work doesn't benefit (still limited by core count)
- Backpressure and streaming still need reactive patterns

**Java 24 fix (JEP 491)**: `synchronized` no longer pins virtual threads. This was the biggest practical limitation — now resolved.

**Framework support:**
- Spring Boot 3.2+: `spring.threads.virtual.enabled=true`
- Quarkus: `@RunOnVirtualThread` annotation
- Micronaut: Full virtual thread support

### Other Key Java 21+ Features

- **Structured Concurrency** (preview through Java 24): Treats concurrent tasks as a unit — if one fails, siblings are cancelled
- **Scoped Values** (preview): Replacement for ThreadLocal optimized for virtual threads
- **Records**: Immutable data carriers, perfect for DTOs
- **Sealed Classes**: Restrict which classes can extend/implement
- **Pattern Matching**: `switch` on types, deconstruction patterns
- **Sequenced Collections**: `getFirst()`, `getLast()`, `reversed()` on ordered collections
- **Foreign Function & Memory API** (finalized Java 22): Replaces JNI for native code calls

**Java 25** is the next LTS release (September 2025).

---

## 2. Framework Decision Matrix

| Factor | Spring Boot | Quarkus | Micronaut |
|--------|------------|---------|-----------|
| **Ecosystem size** | Largest | Growing fast | Moderate |
| **JVM startup** | 1.5-4s | 0.5-2s | 0.3-0.5s |
| **Native startup** | 50-200ms | 10-50ms | 10-30ms |
| **Native memory** | 50-100MB | 10-50MB | 20-40MB |
| **JVM memory** | 200-500MB | 100-200MB | 50-80MB |
| **Learning resources** | Most extensive | Growing | Fewer |
| **Enterprise adoption** | Highest | Growing (Red Hat backed) | Niche |
| **DI approach** | Runtime reflection | Build-time (ArC/CDI) | Build-time (APT) |
| **Dev experience** | Good (DevTools) | Excellent (Dev Mode) | Good |
| **Virtual threads** | Full support | Full support | Full support |

**Default recommendation for 2025**: Spring Boot 3.4+ with virtual threads. Choose Quarkus for Kubernetes-native/serverless with aggressive startup/memory needs. Choose Micronaut for minimal startup on JVM without native compilation.

---

## 3. Spring Boot

### Spring Boot 3.x Key Versions
- **3.0** (Nov 2022): Jakarta EE 9 baseline, GraalVM native support via Spring AOT
- **3.1** (May 2023): Docker Compose support, Testcontainers integration
- **3.2** (Nov 2023): Virtual threads, JdbcClient, RestClient
- **3.3** (May 2024): CDS improvements, structured logging, SBOMs
- **3.4** (Nov 2024): Enhanced structured logging, MockMvcTester

**Performance characteristics:**
- JVM startup: 1.5-4s typical
- GraalVM native: 50-200ms startup, 60-80% less memory
- With CDS (Class Data Sharing): ~30-50% startup reduction
- With virtual threads: throughput matches reactive for I/O workloads

### Spring Ecosystem Components

**Spring Cloud** (for microservices):
- Gateway (reactive + MVC variant)
- Config (centralized configuration)
- Circuit Breaker (Resilience4j — Hystrix deprecated)
- Stream (event-driven with Kafka/RabbitMQ binders)
- Kubernetes (native service discovery + config)
- Function (serverless abstractions)
- Netflix OSS (Eureka, Ribbon, Zuul) largely deprecated → use Kubernetes-native

**Spring Data**: Auto-repositories from interfaces. JPA, R2DBC, MongoDB, Redis, Elasticsearch, Neo4j.

**Spring Security 6.x**: Lambda DSL, OAuth2 Resource Server/Client/Auth Server, Passkey/WebAuthn support, method security.

**Spring Modulith**: Modular monolith framework. Enforces module boundaries at test time. Event-based inter-module communication. Module-level tracing. Step toward microservices without the operational overhead.

### GraalVM Native with Spring
- Spring AOT generates optimized code at build time
- Native Maven profile: `mvn -Pnative package`
- Startup: 50-200ms | Memory: 50-100MB
- Tradeoffs: longer builds (2-10 min), no runtime reflection, limited dynamic class loading
- Peak throughput 10-30% lower than JIT-optimized JVM (improving with PGO)
- Best for: serverless, CLIs, auto-scaling microservices

---

## 4. Quarkus

### Philosophy: Container-First, Kubernetes-Native
- Build-time optimization: CDI resolution, config parsing, annotation processing done at build time
- Dev Mode (`quarkus:dev`): Live reload in ~1 second, continuous testing, Dev UI dashboard
- 600+ extensions ecosystem

### Performance
- JVM startup: 0.5-2s
- Native startup: 10-50ms
- Native memory: 10-50MB for a REST API
- GraalVM native support more mature than Spring's

### Key Architecture
- **ArC**: Build-time CDI implementation (covers 90%+ of CDI spec)
- **RESTEasy Reactive**: JAX-RS with both blocking and reactive support
- **Hibernate with Panache**: Active Record or Repository pattern
- **Vert.x**: Underlying reactive engine
- Virtual threads via `@RunOnVirtualThread`

### When to Choose Quarkus
- Kubernetes-native deployments where startup/memory matter
- Serverless/FaaS (AWS Lambda, Azure Functions) — native starts in <50ms
- GraalVM native is a primary requirement
- Teams comfortable with Jakarta EE / MicroProfile
- Exceptional developer experience (Dev Mode)

---

## 5. Micronaut

### Core Differentiator: Compile-Time DI
- All DI, AOP, and bean configuration resolved at compile time via annotation processors
- No runtime reflection, no classpath scanning
- Near-instant startup (~300-500ms JVM), constant memory overhead

### Performance
- JVM startup: 300-500ms
- Native startup: 10-30ms
- JVM memory: 50-80MB for REST API

### Key Features
- **Micronaut Data**: Compile-time query generation
- **Micronaut Serialization**: Compile-time JSON (replaces Jackson reflection)
- **Micronaut Security**: OAuth2, JWT, session-based

### When to Choose Micronaut
- Maximum JVM startup performance without native compilation
- IoT or embedded systems with constrained resources
- Serverless where cold start is critical
- Compile-time safety for DI and data access
- Smaller ecosystem — fewer third-party integrations than Spring

---

## 6. Reactive vs Virtual Threads

### 2025 Decision Guide

| Scenario | Recommendation |
|----------|---------------|
| Standard REST APIs | Virtual threads (Spring MVC) |
| Server-Sent Events / Streaming | Reactive (WebFlux / Mutiny) |
| Backpressure required | Reactive |
| Simple fan-out concurrency | Virtual threads + Structured Concurrency |
| High-connection WebSockets | Either (reactive slightly edges) |
| Team expertise: imperative style | Virtual threads |
| Existing reactive codebase | Continue with reactive |

### Reactive Frameworks
- **Project Reactor** (Spring WebFlux): `Mono<T>` and `Flux<T>`, 200+ operators, backpressure via Reactive Streams
- **Mutiny** (Quarkus): `Uni<T>` and `Multi<T>`, event-driven API, more intuitive than Reactor
- **Vert.x**: Event-loop architecture (like Node.js but multi-reactor), handles 100K+ concurrent connections

**Bottom line**: Virtual threads make reactive optional for most use cases. Reactive remains essential for streaming, backpressure, and complex async pipelines.

---

## 7. Data Access

### Hibernate 6.x
- JPA 3.1 (Jakarta Persistence) implementation
- New SQM query parser, improved type system
- Built-in `@SoftDelete`, `StatelessSession` for batches
- Hibernate Reactive (Vert.x SQL drivers) for non-blocking DB access
- Second-level caching (Caffeine, Redis), batch fetching

### jOOQ
- Typesafe SQL DSL, generates Java code from database schema
- Not an ORM — no entity state management. Records are plain data.
- Excellent for complex queries, reporting, analytics
- Commercial license for Oracle/SQL Server/DB2, open source for PostgreSQL/MySQL

### JdbcClient (Spring 6.1+)
- Fluent API replacing JdbcTemplate. Simpler, more readable.

### R2DBC (Reactive DB)
- Non-blocking database drivers. Spring Data R2DBC support.
- With virtual threads, less compelling for new projects. Standard JDBC on virtual threads provides similar throughput with simpler code.

### Database Migrations
- **Flyway**: SQL-based, versioned migrations. Simpler. Recommended for most projects.
- **Liquibase**: XML/YAML/JSON changelogs, rollback support, diff capabilities. For complex enterprise needs.
- Both auto-configure with Spring Boot and Quarkus.

---

## 8. API Frameworks

### REST
- **Spring MVC**: `@RestController`, `@GetMapping`, etc. Most common.
- **RESTEasy Reactive** (Quarkus): JAX-RS with blocking and reactive support.
- **Jersey**: Jakarta REST reference implementation.

### gRPC
- Protocol Buffers serialization. 2-10x faster than REST/JSON for serialization-heavy workloads.
- Spring integration: `grpc-spring-boot-starter` (official from Boot 3.4+)
- Quarkus: built-in gRPC extension
- Best for: service-to-service communication, streaming, polyglot environments

### GraphQL
- **Spring for GraphQL**: Schema-first, `@QueryMapping`/`@MutationMapping`, DataLoader for N+1 prevention
- **Netflix DGS**: Production-proven, code-first or schema-first, Apollo Federation support
- Both build on `graphql-java`

### OpenAPI / Swagger
- **springdoc-openapi** (2.x): Auto-generates OpenAPI 3.0/3.1 specs with Swagger UI
- **OpenAPI Generator**: Generate server stubs and client SDKs from specs
- Contract-first (write spec, generate code) recommended for API-first design

---

## 9. Messaging

### Apache Kafka
- **Spring Kafka**: `@KafkaListener`, `KafkaTemplate`, transactions, exactly-once, DLT handling
- **Quarkus Kafka** (SmallRye Reactive Messaging): `@Incoming`/`@Outgoing`, embedded Redpanda in dev mode
- **Kafka Streams**: KStream/KTable for real-time stream processing

### RabbitMQ
- Spring AMQP: `@RabbitListener`, `RabbitTemplate`
- Best for: traditional message queuing, complex routing, pub/sub with exchanges

### Apache Pulsar
- Spring for Apache Pulsar (Boot 3.2+): `@PulsarListener`, `PulsarTemplate`
- Multi-tenancy, geo-replication built-in. Growing but smaller community than Kafka.

---

## 10. Testing

### Core Stack
- **JUnit 5**: `@ParameterizedTest`, `@Nested`, dynamic tests, parallel execution
- **Mockito 5.x**: Inline mock maker (final classes), strict stubbing, BDD-style
- **Testcontainers**: Real Docker containers in tests. Spring Boot `@ServiceConnection` (3.1+). Quarkus Dev Services auto-provisions containers.
- **WireMock 3.x**: HTTP mock server, request matching, record/playback
- **ArchUnit**: Architecture rules as code. Enforce package dependencies, layer architecture.

### Spring Boot Test Slices
- `@SpringBootTest`: Full context
- `@WebMvcTest`: Controllers only
- `@DataJpaTest`: Repositories only
- `@WebFluxTest`: Reactive controllers
- `MockMvcTester` (3.4+): Fluent MVC test assertions
- **Contract testing**: Spring Cloud Contract or Pact for consumer-driven contracts

---

## 11. Performance and JVM Tuning

### Garbage Collectors
| GC | Pause Time | Throughput | Best For |
|----|-----------|------------|----------|
| **G1GC** (default) | <10ms achievable | Highest | General workloads, 4-64 GB heaps |
| **ZGC** (Generational) | <1ms regardless of heap | Within 5-10% of G1 | Latency-sensitive (trading, real-time APIs) |
| **Shenandoah** | <1ms | Similar to ZGC | Low-latency (OpenJDK only, not Oracle JDK) |

### Benchmarking and Profiling
- **JMH**: Standard JVM microbenchmarking. Handles warmup, JIT, dead code elimination.
- **Java Flight Recorder (JFR)**: Built-in, <2% overhead, production-safe. Records GC, threads, I/O, allocations.
- **async-profiler**: CPU/allocation/wall-clock profiling. Flame graphs. ~1% overhead.

### JVM in Containers
- Honors container memory since Java 10+: `-XX:MaxRAMPercentage=75`
- CPU detection: `-XX:ActiveProcessorCount`
- Recommended flags: `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75`

---

## 12. Deployment

### Container Images
- **Base images**: Eclipse Temurin (recommended), Amazon Corretto, Azul Zulu
- **Jib** (Google): No Docker daemon needed, optimized layered images, reproducible builds
- **jlink**: Custom JRE with only needed modules. Image size: 50-100 MB.
- Multi-stage builds: Build in JDK image, run in JRE image (150-300 MB)

### GraalVM Native Images
- Startup: 10-100ms | Memory: 30-100MB
- Build: 2-10 min, needs 8-16 GB RAM
- Limitations: No runtime reflection, no runtime bytecode generation
- Best for: serverless, CLIs, auto-scaling microservices

### CRaC (Coordinated Restore at Checkpoint)
- Instant startup by checkpointing a running JVM and restoring
- ~50-100ms startup WITH full JIT-compiled code (best of both worlds)
- Spring Framework 6.1+ supports CRaC lifecycle
- Requires Linux, CRIU. Alternative to GraalVM native without sacrificing throughput.

### JVM Variants
- **HotSpot** (default): Best peak throughput after JIT warmup. Largest ecosystem.
- **OpenJ9** (Eclipse/IBM): 30-50% lower memory. Faster startup via shared classes cache. For memory-constrained containers.

---

## 13. Observability

### Metrics: Micrometer
- Metrics facade (like SLF4J for metrics). Supports Prometheus, Datadog, New Relic, CloudWatch.
- **Micrometer Observation API**: Unified metrics + tracing from one instrumentation point.
- **Micrometer Tracing**: Distributed tracing bridge (replaces Spring Cloud Sleuth). OpenTelemetry and Brave backends.

### Tracing: OpenTelemetry
- **Java Agent**: Zero-code instrumentation. Auto-instruments Spring, JDBC, Kafka, gRPC, HTTP clients, 100+ libraries.
- Exporters: OTLP (to Jaeger, Tempo), Zipkin, Prometheus

### Spring Boot Actuator
- `/actuator/health`, `/actuator/metrics`, `/actuator/prometheus`, `/actuator/threaddump`, `/actuator/heapdump`
- Health groups for Kubernetes probes
- Structured JSON logging (3.3+)
- SBOM endpoint (`/actuator/sbom`)

### Recommended Stack (2025)
- **Metrics**: Micrometer → Prometheus → Grafana
- **Tracing**: OpenTelemetry Agent → Tempo/Jaeger → Grafana
- **Logging**: Structured JSON → Loki / Elasticsearch → Grafana / Kibana
- **All-in-one**: Grafana LGTM stack (Loki, Grafana, Tempo, Mimir)
