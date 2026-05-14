# Backend Architecture Patterns — Deep Reference

**Always use `WebSearch` to verify current best practices. Patterns are stable but tooling evolves.**

## Table of Contents
1. [Monolith vs Microservices](#1-monolith-vs-microservices)
2. [API Design Patterns](#2-api-design-patterns)
3. [Integration Patterns](#3-integration-patterns)
4. [High-Throughput Systems](#4-high-throughput-systems)
5. [Lightweight / Serverless Patterns](#5-lightweight--serverless-patterns)
6. [Database Patterns](#6-database-patterns)
7. [Authentication and Authorization](#7-authentication-and-authorization)
8. [CI/CD and Deployment](#8-cicd-and-deployment)

---

## 1. Monolith vs Microservices

### The Spectrum

Not a binary choice. The actual spectrum:

**Single-process monolith → Modular monolith → Service-oriented architecture → Microservices → Serverless functions**

### When Monolith Is Right
- Team <20-30 engineers
- Domain boundaries still being discovered (early-stage product)
- Performance-sensitive (no inter-process communication overhead)
- Can't afford a platform team for distributed systems ops

### When Microservices Are Right
- Large orgs (50+ engineers) needing team autonomy and independent deployment
- Distinct scaling profiles across components
- Polyglot requirements (different languages for different services)
- Fault isolation (crash in one service shouldn't take down everything)

### The Modular Monolith (Recommended Default)
Single deployable unit, internally organized into modules with clear boundaries:
- Modules communicate through well-defined interfaces only
- Each module owns its own tables/schema — no cross-module JOINs
- Can extract to services later along module boundaries
- **Java**: Spring Modulith provides first-class support
- **TypeScript**: NestJS modules with DI scoping
- **Ruby**: Shopify's Packwerk for boundary enforcement

### Real-World Examples

**Chose monolith / returned to monolith:**
- **Shopify**: One of the world's largest Rails monoliths. Handles Black Friday billions.
- **37signals (DHH)**: HEY.com (millions of users) on single Rails monolith
- **Amazon Prime Video** (2023): Moved from microservices/serverless back to monolith, 90% cost reduction
- **Stack Overflow**: Handful of servers with monolithic .NET app

**Chose microservices:**
- **Netflix**: Hundreds of services, hundreds of teams
- **Uber**: Monolith → microservices, then introduced DOMA (domain-oriented microservice architecture) to manage over-splitting

### Signs You Need to Split
1. Deployment conflicts — teams constantly stepping on each other
2. Blast radius too large — one bug takes down everything
3. Scaling mismatch — one component needs 100x the resources
4. Team autonomy blocked — shared release train is bottleneck
5. Technology constraints — part of system genuinely needs different runtime

### Signs You Over-Split
1. Distributed monolith — must deploy services together anyway
2. Single request fans out to 10+ services
3. More time managing infrastructure than building features
4. Sagas and eventual consistency where a simple transaction would work
5. 5 engineers, 20 services

---

## 2. API Design Patterns

### REST Maturity (Richardson Model)
- **Level 2** (proper verbs + resources) is where most production APIs land
- **Level 3** (HATEOAS) has limited adoption — use OpenAPI/Swagger specs instead
- HATEOAS shines for public APIs with diverse clients and workflow-driven APIs

### GraphQL at Scale
**Federation (Apollo Federation v2):**
- Each team owns a "subgraph" for their domain
- Router (Apollo Router, Cosmo Router) composes unified "supergraph"
- Key benefit: team autonomy with independent deployment
- Key challenge: cross-subgraph query planning complexity

**When GraphQL, when NOT:**
- Use: multiple clients with different data needs, complex nested data
- Don't use: simple CRUD (REST is simpler), file uploads, small team where overhead isn't justified

### gRPC
- Protocol Buffers serialization: 5-10x faster than JSON, 3-10x smaller
- Best for: service-to-service, streaming, polyglot environments
- Not for: browser clients directly (need gRPC-Web or Connect proxy)
- **Connect (by Buf)**: Generates idiomatic HTTP APIs from protobuf. Supports gRPC + simpler HTTP/1.1 protocol. Growing rapidly as more ergonomic gRPC.

### API Versioning

| Strategy | When to Use |
|----------|-----------|
| URL path (`/api/v1/users`) | Public APIs, clear major versions |
| Header (`Accept: vnd.api.v2+json`) | Sophisticated consumers |
| Additive-only (no versioning) | Internal APIs, fast-moving teams |
| Date-based (Stripe-style: `2024-01-15`) | Public APIs with aggressive backward compatibility |

### BFF (Backend for Frontend)
- Dedicated backend per client type (web BFF, mobile BFF)
- Owned by the frontend team, not backend team
- Use when: multiple frontends with significantly different data needs
- Alternatives: GraphQL as BFF, tRPC in monorepo

### API Gateway
Core responsibilities: routing, auth, rate limiting, request transformation, SSL termination, logging.

| Tier | Options | Best For |
|------|---------|----------|
| Cloud-native | AWS API Gateway, Google Cloud API Gateway | Serverless, pay-per-request |
| Self-hosted | Kong, Tyk, KrakenD | Complex routing, plugin ecosystems |
| Reverse proxy | Nginx, Envoy, Caddy, Traefik | Routing + TLS without full API management |
| App-level | Spring Cloud Gateway, Express Gateway | Gateway logic coupled to app code |

Anti-pattern: putting business logic in the gateway. Keep it as a thin routing/auth layer.

---

## 3. Integration Patterns

### Frontend-Backend Integration

| Pattern | Best For |
|---------|---------|
| REST + SPA | Clear separation, cacheable, any frontend framework |
| GraphQL gateway | Multiple clients needing different data shapes |
| tRPC in monorepo | Maximum type safety, TypeScript full-stack |
| BFF per client | Different clients with very different needs |
| SSR (Next.js/Nuxt) | SEO-critical, blurs frontend/backend line |
| Edge middleware | Auth checks, redirects, A/B testing before hitting origin |

### Service Mesh (Istio, Linkerd)
- Handles mTLS, retries, circuit breaking, observability via sidecar proxies (Envoy)
- Use when: 50+ services needing consistent security and observability
- Don't use: <10-15 services (handle in application code or shared library)
- Trend: Ambient mesh (Istio) eliminates per-pod sidecar for per-node proxies

### Third-Party API Integration

**Circuit Breaker**: Closed → Open (fail fast) → Half-Open (test recovery). Configure: 50% failure threshold in 10s window.

**Retries**: Exponential backoff + jitter. `delay = min(base * 2^attempt + jitter, max_delay)`. Only retry idempotent operations. Never blindly retry POST.

**Idempotency**: Client sends `Idempotency-Key` header (UUID). Server caches key + result. Duplicate requests return cached result. TTL: 24-48h. (Stripe's pattern.)

**Timeouts**: Always explicit. Connection timeout (1-5s), read timeout (5-30s). Downstream timeout should be shorter than your own service's timeout.

### Event-Driven Integration

| Broker | Best For |
|--------|---------|
| **Kafka** | High-throughput streaming, event sourcing, replay |
| **NATS** | Lightweight messaging, request-reply, IoT |
| **RabbitMQ** | Traditional queuing, complex routing |
| **Redis Streams** | Moderate throughput, already using Redis |
| **SQS/SNS** | Serverless event-driven, AWS-native |
| **Redpanda** | Kafka-compatible, simpler ops (no JVM/ZooKeeper) |

### Saga Pattern (Distributed Transactions)

**Choreography** (event-based): Each service listens for events and publishes its own. Simple but hard to trace full flow. Use for 3-4 step flows.

**Orchestration** (command-based): Central orchestrator directs each service. Easy to understand and debug. Use for 5+ step flows.

### Outbox Pattern (Reliable Event Publishing)
Solves dual-write: how to atomically update DB AND publish an event.
1. Write business data + event to "outbox" table in same transaction
2. Separate process reads outbox and publishes to message broker
3. Mark outbox records as processed

Implementations: Polling publisher (simple, adds latency) or CDC/Debezium (near-real-time via transaction log tailing).

---

## 4. High-Throughput Systems

### Connection Pooling
- DB connections are expensive to create. Always pool.
- **HikariCP** (Java): `connections = (2 * CPU_cores) + spindle_count`. Typically 10-20.
- **node-postgres**: Built-in pool, typically 10-20 per process
- **External poolers**: PgBouncer (Postgres), ProxySQL (MySQL). Essential for serverless.

### Back-Pressure
1. **Bounded queues**: Reject when full, producer handles rejection
2. **Rate limiting**: Token bucket or sliding window
3. **Load shedding**: Reject low-priority requests (503) to protect high-priority
4. **Reactive streams**: Consumer controls rate (pull-based)
5. **Kafka consumer lag**: Scale consumers horizontally

### Request Coalescing (Singleflight)
Multiple concurrent identical requests collapsed into one backend call. Critical for cache stampede prevention.

### Load Balancing Algorithms

| Algorithm | Best For |
|-----------|---------|
| Round-robin | Homogeneous backends, equal request cost |
| Least connections | Varying request durations |
| Consistent hashing | Caching layers, sticky sessions |
| **Power of Two Choices** | Best general-purpose (used by Envoy/Nginx) |

### Scaling
- **Vertical first**: Simpler, no distributed complexity. Has a ceiling.
- **Horizontal when**: Hit vertical limits, need HA, have variable load
- Horizontal requires: stateless services, externalized state, load balancing

---

## 5. Lightweight / Serverless Patterns

### Serverless Options
- **AWS Lambda**: Cold start 100ms-seconds. Max 15 min. SnapStart for Java.
- **CloudFlare Workers**: V8 isolates, sub-ms cold starts, 300+ edge locations. Best for edge APIs.
- **Vercel Functions / Edge Functions**: Lambda + CloudFlare Workers, tightly integrated with Next.js
- **Cloud Run / App Runner**: Serverless containers (no function limitations)

### When Serverless vs Servers

**Serverless when:** Spiky traffic, zero ops overhead, short-lived stateless functions, event-driven workflows, small team.

**Servers when:** Sustained high traffic (reserved instances cheaper), long-running processes, WebSockets, cold start is unacceptable, need fine-grained runtime control.

---

## 6. Database Patterns

### Database per Service vs Shared
- **Per service**: Enforces loose coupling. Challenges: distributed transactions (sagas), cross-service queries (API composition/CQRS).
- **Shared**: Simpler consistency (ACID transactions). Risk: tight coupling, schema changes affect all.
- **Hybrid**: Shared DB with schema-per-service. No cross-schema foreign keys.

### CQRS
Separate read model from write model. Write to normalized relational DB; read from denormalized store (Redis, Elasticsearch). Event/CDC pipeline syncs.

Use when: Read/write patterns differ vastly, need multiple read representations, heavily skewed ratio (90%+ reads).

### Event Sourcing
Store state as immutable event sequence instead of current state. Benefits: audit trail, temporal queries, event replay. Challenges: schema evolution, read performance requires projections, storage growth.

### Multi-Tenancy

| Pattern | Isolation | Cost | Use When |
|---------|-----------|------|----------|
| Row-level (tenant ID column) | Lowest | Cheapest | Many small tenants |
| Schema per tenant | Medium | Medium | Moderate tenant count |
| DB per tenant | Highest | Highest | Enterprise, strict compliance |

PostgreSQL RLS (Row-Level Security) automates row-level filtering. Citus extension for distributed multi-tenancy.

### Connection Pooling
- **PgBouncer**: Transaction mode (most common). Essential for serverless.
- **ProxySQL**: MySQL equivalent. Query routing to read replicas.
- **Neon serverless driver**: WebSocket-based, built-in pooling for edge/serverless.

---

## 7. Authentication and Authorization

### OAuth 2.0 Flows by Client

| Client | Flow |
|--------|------|
| Server-rendered web | Authorization Code |
| SPA | Authorization Code + PKCE |
| Mobile/native | Authorization Code + PKCE |
| Machine-to-machine | Client Credentials |
| Device (TV, CLI) | Device Authorization |

Implicit Flow is **deprecated**. Always use PKCE.

### JWT vs Sessions
- **JWT**: Stateless, horizontally scalable, can't revoke before expiry without blocklist. Best for APIs.
- **Sessions**: Stateful (Redis), easy revocation, smaller cookie. Best for server-rendered web.
- **Hybrid**: Sessions for web apps, JWTs for API access.

### Authorization Models
- **RBAC**: Users → Roles → Permissions. Simple, well-understood. Most applications.
- **ABAC**: Decisions based on attributes (user, resource, context). Fine-grained. Complex systems.
- **ReBAC**: Based on relationships (Google Zanzibar). SpiceDB, Ory Keto, Auth0 FGA. Complex resource hierarchies.

### Service-to-Service Auth
- **mTLS**: Via service mesh (Istio/Linkerd handles cert rotation)
- **Service accounts + JWT**: Each service authenticates to IdP
- **SPIFFE/SPIRE**: Standardized workload identity across platforms

---

## 8. CI/CD and Deployment

### Deployment Strategies

| Strategy | Tradeoff | Use When |
|----------|---------|----------|
| **Rolling** | Both versions serve during deploy | Default K8s. Backward-compatible changes. |
| **Blue-Green** | Double infrastructure, instant rollback | Need instant reliable rollback |
| **Canary** | Gradual traffic shift, real validation | Minimize blast radius |
| **Shadow/Dark** | Compare old vs new with real traffic | Validating major rewrites |

### Feature Flags
- Deploy dormant code, activate independently of deployment
- Gradual rollout, A/B testing, kill switches
- Tools: LaunchDarkly, Unleash (OSS), Flagsmith (OSS), PostHog
- Clean up old flags to avoid flag debt

### Zero-Downtime Database Migrations
"Expand and contract" pattern:
1. Add column as nullable (no downtime)
2. Deploy code writing to both old and new
3. Backfill existing rows
4. Deploy code reading from new column
5. Remove old column code, then drop column

Key principle: every migration must be backward-compatible with currently running code. Deploy code and schema changes independently.

### Branching Strategy

| Strategy | Best For |
|----------|---------|
| **Trunk-based** + feature flags | SaaS, continuous deployment (Google, Meta) |
| **GitHub Flow** | Most web apps (simpler than GitFlow) |
| **GitFlow** | Versioned releases, mobile apps, SDKs |

Trunk-based with feature flags is the dominant approach for modern SaaS.

---

## Decision Framework Summary

| Decision | Default | Switch When |
|----------|---------|-------------|
| Architecture | Modular monolith | Team >30, distinct scaling needs |
| External API | REST (Level 2) | Multiple diverse clients (GraphQL), streaming (gRPC) |
| Internal API | gRPC or Connect | Very simple (REST), same-language full-stack (tRPC) |
| Messaging | Redis Streams / SQS | Need replay (Kafka), complex routing (RabbitMQ) |
| Database | PostgreSQL, shared | Per-service isolation, massive read scale (CQRS) |
| Auth | OAuth 2.0 + PKCE, JWT for APIs | Server-rendered (sessions), complex perms (ReBAC) |
| Deployment | Rolling | Instant rollback (blue-green), risk mitigation (canary) |
| Hosting | Containers (Cloud Run/ECS/K8s) | Spiky traffic (serverless), edge latency (Workers) |
| Scaling | Vertical first | Hit limits, need HA, variable load (horizontal) |

**Overarching principle**: Start simple, add complexity only when you have evidence the simpler approach is insufficient. Premature complexity is the most common and most expensive architectural mistake.
