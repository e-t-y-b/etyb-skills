# API Development — Deep Reference

**Always use `WebSearch` to verify version numbers, tooling, and best practices. API tooling evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [REST API Design](#1-rest-api-design)
2. [GraphQL Implementation](#2-graphql-implementation)
3. [gRPC and Connect](#3-grpc-and-connect)
4. [Type-Safe APIs (tRPC and Beyond)](#4-type-safe-apis-trpc-and-beyond)
5. [API Versioning](#5-api-versioning)
6. [Error Handling (RFC 9457)](#6-error-handling-rfc-9457)
7. [Middleware Patterns](#7-middleware-patterns)
8. [Rate Limiting](#8-rate-limiting)
9. [Pagination](#9-pagination)
10. [Caching](#10-caching)
11. [Real-Time APIs](#11-real-time-apis)
12. [API Documentation](#12-api-documentation)
13. [API Testing](#13-api-testing)
14. [API Gateway Patterns](#14-api-gateway-patterns)
15. [API-First Development](#15-api-first-development)
16. [API Security](#16-api-security)

---

## 1. REST API Design

### OpenAPI 3.1 / 3.2 (Current Standard)

OpenAPI 3.1 aligns with JSON Schema 2020-12, bringing full JSON Schema compatibility. **OpenAPI 3.2** was released in early 2026 with additional features:

**3.1 improvements over 3.0:**
- Full JSON Schema support (not a subset)
- `$ref` alongside other keywords
- `webhooks` top-level object for event-driven APIs
- `pathItems` for reuse across paths

**3.2 additions (early 2026):**
- Hierarchical tags for better organization
- QUERY HTTP method support via `additionalOperations`
- Streaming support for event-driven APIs
- Enhanced multipart support (multipart/mixed, multipart/related, multipart/byteranges)
- Improved OAuth 2 metadata
- Backward-compatible with 3.1

**Design-first workflow:**
1. Write OpenAPI spec (YAML/JSON)
2. Lint with Spectral or Redocly CLI
3. Generate server stubs and client SDKs
4. Implement handlers against the generated interfaces
5. Validate request/response against spec in tests

### REST Design Principles (2026)

**Resource naming:**
- Nouns, not verbs: `/users`, not `/getUsers`
- Plural for collections: `/users`, `/orders`
- Nested for relationships: `/users/{id}/orders`
- Avoid deep nesting beyond 2 levels — use filtering instead

**HTTP methods:**
| Method | Semantics | Idempotent | Safe |
|--------|-----------|------------|------|
| GET | Read | Yes | Yes |
| POST | Create | No | No |
| PUT | Full replace | Yes | No |
| PATCH | Partial update | No* | No |
| DELETE | Remove | Yes | No |

*PATCH can be idempotent with JSON Merge Patch (RFC 7396).

**Richardson Maturity Model:**
- **Level 2** (proper verbs + resources) is where most production APIs land
- **Level 3** (HATEOAS) has limited adoption — use when clients need to discover available actions dynamically (workflow-driven APIs, public APIs with diverse consumers)
- For most internal APIs, OpenAPI specs serve the discoverability purpose better than HATEOAS

### Response Envelope Pattern

```json
{
  "data": { "id": "123", "name": "Alice" },
  "meta": { "requestId": "req_abc123" }
}
```

For collections:
```json
{
  "data": [{ "id": "1" }, { "id": "2" }],
  "meta": { "total": 42 },
  "pagination": { "cursor": "eyJpZCI6Mn0=", "hasMore": true }
}
```

### Filtering and Sorting

```
GET /users?status=active&role=admin          # Equality filters
GET /users?created_after=2026-01-01          # Range filters
GET /users?sort=-created_at,name             # Sort (- for descending)
GET /users?fields=id,name,email              # Sparse fieldsets
GET /users?search=alice                       # Full-text search
```

---

## 2. GraphQL Implementation

### When to Use GraphQL

**Use GraphQL when:**
- Multiple clients (web, mobile, third-party) need different data shapes from the same API
- Complex, deeply nested data relationships
- Frontend teams want control over data fetching without backend changes
- Reducing over-fetching/under-fetching is critical (mobile bandwidth, latency)

**Don't use GraphQL when:**
- Simple CRUD with few clients (REST is simpler)
- File uploads are a primary use case (GraphQL file uploads are awkward)
- Small team where the operational overhead isn't justified
- Caching requirements are simple and uniform (REST HTTP caching is more mature)

### Federation (Apollo Federation v2)

The standard architecture for large-scale GraphQL:
- Each team owns a **subgraph** for their domain
- **Router** (Apollo Router, Cosmo Router) composes a unified **supergraph**
- Teams deploy subgraphs independently
- Cross-subgraph query planning handled by the router

```graphql
# User subgraph
type User @key(fields: "id") {
  id: ID!
  name: String!
  email: String!
}

# Order subgraph — extends User from user subgraph
type User @key(fields: "id") {
  id: ID!
  orders: [Order!]!
}
```

### GraphQL Security

**Query depth limiting:** Prevent deeply nested queries that cause exponential DB calls:
```
{ user { friends { friends { friends { ... } } } } }
```
Set maximum depth (typically 7-10 levels).

**Persisted queries:** Client sends query hash instead of full query string. Server maps hash to pre-approved query. Prevents arbitrary query injection.

**Cost analysis:** Assign cost to each field/resolver. Reject queries exceeding cost budget. Libraries: `graphql-query-complexity`, `graphql-cost-analysis`.

**Rate limiting:** Per-client rate limiting based on query complexity, not just request count.

### DataLoader Pattern

Solves the N+1 problem in GraphQL resolvers:
```
# Without DataLoader: 1 query for users + N queries for each user's avatar
# With DataLoader: 1 query for users + 1 batched query for all avatars
```

Available in every language: `dataloader` (JS), `DataLoader` (Java), `aiodataloader` (Python).

### Schema-First vs Code-First

| Approach | Tools | Best For |
|----------|-------|----------|
| **Schema-first** | Apollo Server, gqlgen (Go) | Teams wanting single source of truth in `.graphql` files |
| **Code-first** | NestJS GraphQL, Strawberry (Python), async-graphql (Rust) | Teams preferring code colocation, TypeScript/Python |

---

## 3. gRPC and Connect

### gRPC in 2026

**Protobuf Editions:** Protobuf Editions replace `syntax = "proto2"` / `syntax = "proto3"` with `edition = "2024"`. Editions unify proto2 and proto3 semantics with configurable features as options. New editions planned roughly annually.

Protocol Buffers serialization: 5-10x faster than JSON, 3-10x smaller payloads.

**Four communication patterns:**
| Pattern | Use Case |
|---------|----------|
| **Unary** | Traditional request/response (most common) |
| **Server streaming** | Server pushes multiple responses (live data, large results) |
| **Client streaming** | Client sends multiple messages (file upload, batch processing) |
| **Bidirectional streaming** | Both sides stream simultaneously (chat, real-time collaboration) |

**Language implementations:**
| Language | Library | Notes |
|----------|---------|-------|
| Go | `google.golang.org/grpc` | Mature, widely used |
| Java | `io.grpc:grpc-java` | Full-featured, Spring Boot integration |
| Rust | `tonic` | Built on Tokio/Tower, 0.14.x |
| TypeScript | `@grpc/grpc-js` | Pure JS implementation |
| Python | `grpcio` | C-extension based |

### Connect Protocol (by Buf)

Connect is what the gRPC protocol should have been — a simpler, HTTP-first RPC protocol:

- **Three protocols in one**: Connect (HTTP/1.1 + JSON), gRPC, gRPC-Web
- POST-only, works over HTTP/1.1 or HTTP/2
- JSON or protobuf encoding (client chooses)
- No special proxy needed for browsers (unlike gRPC-Web)
- Same `.proto` definitions, same generated code
- `buf.build` for protobuf management (BSR registry, breaking change detection, linting)

**When to use Connect over raw gRPC:**
- Browser clients need to call the API directly
- You want HTTP/1.1 compatibility (easier debugging, wider infrastructure support)
- You want JSON encoding option for debugging/tooling
- Starting a new project with protobuf-first APIs

**Implementations:**
- `connect-go` (Go) — most mature
- `connect-es` (TypeScript/JavaScript) — browser and Node.js
- `connect-kotlin`, `connect-swift` — mobile clients

### buf.build Tooling

- **Buf CLI**: Lint, format, and detect breaking changes in `.proto` files
- **Buf Schema Registry (BSR)**: Hosted registry for protobuf modules (like npm for protos)
- **Generated SDKs**: BSR generates type-safe clients for Go, TypeScript, Java, etc.

---

## 4. Type-Safe APIs (tRPC and Beyond)

### tRPC v11

The standard for end-to-end type-safe APIs in TypeScript monorepos:

```typescript
// Server
const appRouter = router({
  user: router({
    getById: publicProcedure
      .input(z.object({ id: z.string() }))
      .query(async ({ input }) => {
        return db.user.findUnique({ where: { id: input.id } });
      }),
  }),
});

// Client — fully typed, no codegen
const user = await trpc.user.getById.query({ id: "123" });
```

- Deep TanStack Query v5 integration via `useTRPCQuery`
- Works with Next.js, Nuxt, SvelteKit, React Native
- Best for: TypeScript monorepos where frontend and backend share a process

### Alternatives to tRPC

| Framework | Language | Key Differentiator |
|-----------|----------|----------|
| **oRPC** v1.0 (Dec 2025) | TypeScript | **Generates OpenAPI specs** — works with non-TS consumers (Python, Go, Java). Supports Zod, Valibot, ArkType. |
| **ElysiaJS Eden** | TypeScript | Type-safe RPC via Elysia's runtime type system (Bun-optimized, 2.3x faster than Hono on Bun) |
| **Hono RPC** | TypeScript | Lightweight, edge-native — built into Hono framework, no extra dependency |
| **tRPC** v11 | TypeScript | Established leader, largest ecosystem, deepest TanStack Query integration |

**When tRPC isn't the answer:**
- Multiple backend languages → Use OpenAPI or gRPC/Connect (or oRPC which generates OpenAPI)
- Public API consumers → REST with OpenAPI or GraphQL
- Performance-critical internal APIs → gRPC with protobuf

---

## 5. API Versioning

### Strategies Compared

| Strategy | Example | Best For | Tradeoffs |
|----------|---------|----------|-----------|
| **URL path** | `/api/v1/users` | Public APIs, clear major versions | URL pollution, routing complexity |
| **Header** | `Accept: vnd.api.v2+json` | Sophisticated consumers | Harder to test (curl), less visible |
| **Query param** | `/users?version=2` | Quick implementation | Cache key complexity |
| **Date-based** (Stripe-style) | `Stripe-Version: 2026-01-15` | Aggressive backward compatibility | Complex server-side routing |
| **Additive-only** | No versioning | Internal APIs, fast-moving teams | Must never break existing fields |

**Recommendation:**
- **Public APIs**: URL path versioning (`/v1/`) — most widely understood
- **Internal APIs**: Additive-only (never remove/rename fields, only add) — simplest
- **Platform APIs** (Stripe-like): Date-based versioning — maximum backward compatibility

### Breaking vs Non-Breaking Changes

**Non-breaking (safe):** Adding new fields to response, adding new optional query params, adding new endpoints, adding new enum values (if client handles unknown values)

**Breaking (requires new version):** Removing or renaming fields, changing field types, making optional fields required, changing URL structure, changing error response format

---

## 6. Error Handling (RFC 9457)

### Problem Details for HTTP APIs

RFC 9457 defines a standard error response format. Adopted across frameworks in 2026:

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 422,
  "detail": "The email field is not a valid email address",
  "instance": "/users/signup",
  "errors": [
    {
      "field": "email",
      "message": "must be a valid email address",
      "value": "not-an-email"
    }
  ]
}
```

**Required fields:** `type` (URI identifying error type), `title` (human-readable summary), `status` (HTTP status code)

**Optional fields:** `detail` (specific explanation), `instance` (URI of the specific occurrence)

**Extension fields:** Add domain-specific fields like `errors`, `traceId`, `retryAfter`

### Error Response Guidelines

- **4xx errors**: Include enough detail for the client to fix the request
- **5xx errors**: Return generic message to client, log full details server-side
- **Validation errors**: Return all field-level errors at once (don't make the client fix one at a time)
- **Include request/trace IDs**: Every error response should include a correlation ID for debugging

---

## 7. Middleware Patterns

### Request/Response Pipeline

```
Client → [Auth] → [RateLimit] → [Logging] → [Validation] → Handler
                                                                ↓
Client ← [Logging] ← [Compression] ← [CORS] ← ─────── Response
```

### Cross-Cutting Concerns (What Middleware Should Handle)

| Concern | Where | Notes |
|---------|-------|-------|
| **Authentication** | Before handler | Verify tokens, set user context |
| **Authorization** | Before handler | Check permissions for the specific route |
| **Request logging** | Before + after | Log request/response (sanitize sensitive data) |
| **Tracing** | Before + after | Start span, propagate trace context |
| **Rate limiting** | Before handler | Apply per-client or per-endpoint limits |
| **CORS** | Before handler | Set appropriate headers |
| **Compression** | After handler | gzip/brotli/zstd response bodies |
| **Request ID** | Before handler | Generate or extract correlation ID |
| **Timeout** | Wrapping handler | Cancel slow requests |

### Language-Specific Middleware Patterns

**Java (Spring Boot):** `OncePerRequestFilter`, `HandlerInterceptor`, Spring Security filter chain

**TypeScript (NestJS):** Guards → Interceptors → Pipes → Exception Filters (layered architecture)

**TypeScript (Fastify):** Hooks (`onRequest`, `preHandler`, `preSerialization`, `onSend`)

**Go:** `func(next http.Handler) http.Handler` pattern — compose via chaining

**Rust (Axum):** Tower `Layer` + `Service` traits — compose via `.layer()`

**Python (FastAPI):** `@app.middleware("http")` decorator, dependency injection for per-route middleware

---

## 8. Rate Limiting

### Algorithms

| Algorithm | How It Works | Best For |
|-----------|-------------|----------|
| **Token bucket** | Tokens added at fixed rate, consumed per request | Bursty traffic (allow short bursts) |
| **Sliding window** | Count requests in a sliding time window | Even distribution |
| **Fixed window** | Count requests in fixed intervals | Simplest implementation |
| **Leaky bucket** | Requests processed at fixed rate, excess queued/dropped | Smoothing traffic |

### Implementation Patterns

**Per-client:** Rate limit by API key, user ID, or IP address. Use Redis for distributed rate limiting across multiple server instances.

**Per-endpoint:** Different limits for different endpoints (e.g., login: 5/min, search: 100/min, read: 1000/min).

**Response headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1718284800
Retry-After: 30
```

**429 Too Many Requests:** Always return `Retry-After` header with the number of seconds to wait.

---

## 9. Pagination

### Cursor-Based (Recommended Default)

```json
{
  "data": [...],
  "pagination": {
    "cursor": "eyJpZCI6MTAwfQ==",
    "hasMore": true
  }
}
```

Request: `GET /users?cursor=eyJpZCI6MTAwfQ==&limit=20`

**Advantages:** Consistent results with concurrent inserts/deletes, efficient for large datasets (no OFFSET), works with real-time data.

**Implementation:** Encode the last item's sort key(s) as an opaque cursor (base64). Query: `WHERE id > $cursor ORDER BY id LIMIT $limit + 1` (fetch one extra to determine `hasMore`).

### Offset-Based (Simpler, Limited)

```
GET /users?page=3&per_page=20
```

**Advantages:** Simpler mental model, easy "jump to page N"

**Disadvantages:** Inconsistent with concurrent writes (skipped/duplicated items), poor performance on large offsets (`OFFSET 10000` scans 10000 rows)

### Keyset Pagination (Most Efficient)

Like cursor-based but with transparent sort keys instead of opaque cursors:
```
GET /users?after_id=100&limit=20
GET /users?created_before=2026-01-15T10:00:00Z&limit=20
```

### Relay Connection Spec (GraphQL Standard)

```graphql
{
  users(first: 10, after: "cursor123") {
    edges {
      cursor
      node { id, name }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

---

## 10. Caching

### HTTP Caching Headers

```
Cache-Control: public, max-age=3600, stale-while-revalidate=60
ETag: "abc123"
Last-Modified: Mon, 14 Apr 2026 10:00:00 GMT
Vary: Accept-Encoding, Authorization
```

**Cache-Control directives:**
| Directive | Meaning |
|-----------|---------|
| `public` | Any cache can store (CDN, browser) |
| `private` | Only browser cache (user-specific data) |
| `max-age=N` | Fresh for N seconds |
| `s-maxage=N` | CDN/proxy-specific max-age |
| `no-cache` | Must revalidate before using |
| `no-store` | Never cache (sensitive data) |
| `stale-while-revalidate=N` | Serve stale for N seconds while revalidating |
| `immutable` | Content never changes (versioned assets) |

### Caching Tiers

1. **CDN** (Cloudflare, CloudFront): Cache at the edge, closest to users. Best for static/semi-static responses.
2. **Application cache** (Redis/Memcached): Cache computed results, database query results, session data.
3. **Database query cache**: Query result caching (use cautiously — invalidation is hard).
4. **In-process cache**: Language-level LRU cache for hot data. Fastest but per-instance.

### Cache Invalidation Patterns

- **TTL-based**: Set expiration time. Simplest, eventually consistent.
- **Event-driven**: Publish cache invalidation events on data change.
- **Cache-aside**: Application checks cache first, falls back to DB, writes result to cache.
- **Write-through**: Write to cache and DB simultaneously.
- **Write-behind**: Write to cache immediately, async write to DB.

---

## 11. Real-Time APIs

### Technology Comparison

| Technology | Direction | Protocol | Browser Support | Best For |
|------------|-----------|----------|----------------|----------|
| **WebSocket** | Bidirectional | WS/WSS | Universal | Chat, gaming, collaboration |
| **SSE** | Server → Client | HTTP/1.1+ | Universal | Notifications, feeds, streaming |
| **Long polling** | Simulated push | HTTP | Universal | Fallback, simple use cases |
| **WebTransport** | Bidirectional | HTTP/3 | Chrome, Edge | Low-latency, unreliable delivery OK |

### When to Use What

**WebSocket:** Bidirectional real-time communication — chat, multiplayer games, collaborative editing, live trading. Requires connection state management.

**SSE (Server-Sent Events):** Server-to-client push — live notifications, activity feeds, streaming AI responses, real-time dashboards. Simpler than WebSocket, auto-reconnects, works through proxies.

**Long polling:** When WebSocket/SSE infrastructure isn't available. Simple but inefficient at scale.

**WebTransport:** Experimental — for ultra-low-latency scenarios where occasional packet loss is acceptable (gaming, live video). HTTP/3 only.

### SSE Pattern (Recommended for Most Push Use Cases)

```
// Server sends events
event: message
data: {"type": "notification", "text": "New comment"}

event: heartbeat
data: {"timestamp": 1718284800}
```

SSE advantages over WebSocket for many use cases:
- Works over standard HTTP (no special proxy config)
- Auto-reconnects with `Last-Event-ID`
- Simpler server implementation
- Better for streaming responses (AI, logs, live data)

---

## 12. API Documentation

### Tools Comparison (2026)

| Tool | Type | Strengths |
|------|------|-----------|
| **Scalar** | Interactive reference | Beautiful UI, try-it-out, dark mode, modern DX |
| **Redocly** | Reference + portal | Enterprise features, multi-spec, linting, CLI tools |
| **Swagger UI** | Interactive reference | Most well-known, aging UI, still functional |
| **Stoplight Elements** | Embeddable reference | Good for embedding in existing docs |
| **Apidog** | All-in-one platform | API design + testing + mocking + docs |

### Linting

- **Spectral** (Stoplight): Rule-based OpenAPI linter, custom rules, CI integration
- **Redocly CLI**: Lint + bundle + preview, migration path from Spectral
- **Vacuum**: High-performance OpenAPI linter (Go-based, fast on large specs)

### Best Practices

- Write descriptions for every endpoint, parameter, and schema
- Include request/response examples (not just schemas)
- Document error responses with example payloads
- Use `tags` to organize endpoints by domain
- Generate SDKs from the spec (openapi-generator, Kiota, Fern)

---

## 13. API Testing

### Contract Testing with Pact

Consumer-driven contract testing — the consumer defines what it expects, the provider verifies it can deliver:

1. **Consumer** writes tests using Pact mock server
2. Pact generates a **contract** (JSON) describing expected interactions
3. **Provider** replays the contract against its real API
4. If all interactions pass, the contract is verified

**When to use:** Microservices where consumer/provider are developed by different teams. Catches integration issues before deployment.

### API Mocking

| Tool | Environment | Pattern |
|------|-------------|---------|
| **MSW** (Mock Service Worker) | Browser + Node.js | Intercepts at network level, no code changes |
| **WireMock** | JVM / standalone | HTTP-based, record-and-playback, fault injection |
| **Prism** (Stoplight) | Any | Mock server from OpenAPI spec |
| **Hoverfly** | Any | Proxy-based, capture/simulate/mutate |

### Integration Testing Patterns

- **Test against real dependencies** using testcontainers (Docker-based isolated environments)
- **Snapshot testing**: Capture API response snapshots, detect unintended changes
- **Schema validation**: Validate every response against OpenAPI spec in tests
- **Load testing**: k6, Artillery, or Locust for performance validation

---

## 14. API Gateway Patterns

### Responsibilities

Core: routing, authentication, rate limiting, request transformation, SSL termination, logging, health checks.

### Gateway Options (2026)

| Tier | Options | Best For |
|------|---------|----------|
| **Cloud-native** | AWS API Gateway, Google API Gateway | Serverless, pay-per-request |
| **Self-hosted** | Kong, APISIX, Tyk, KrakenD | Complex routing, plugin ecosystems, full control |
| **Envoy-based** | Envoy Gateway, Istio Gateway, Cilium Gateway | K8s-native, service mesh integration |
| **Reverse proxy** | Nginx, Caddy, Traefik | Routing + TLS without full API management |

### Kubernetes Gateway API

The Kubernetes Gateway API is the emerging standard (replacing Ingress), supported by:
- **Envoy Gateway**: Reference implementation
- **Istio**: Full service mesh + gateway
- **Cilium**: eBPF-based, high performance
- **Kong**: Kong Ingress Controller with Gateway API support

### Anti-Patterns

- **Business logic in the gateway**: Keep the gateway as a thin routing/auth layer
- **Gateway as a crutch**: Don't use the gateway to paper over poor API design
- **Single point of failure**: Deploy gateway with HA (multiple replicas, health checks)

---

## 15. API-First Development

### Design-First Workflow

```
1. Define API contract (OpenAPI/protobuf spec)
2. Review and iterate on the spec (before any code)
3. Generate:
   - Server stubs (code implements the spec)
   - Client SDKs (consumers can start immediately)
   - Mock server (frontend can develop in parallel)
4. Implement server against generated interfaces
5. Validate responses against spec in CI
6. Publish SDK and documentation
```

### Benefits

- Frontend and backend develop in parallel (mock server from spec)
- API contract is the single source of truth
- SDK generation eliminates hand-written client code
- Breaking change detection in CI (Buf for protobuf, Spectral for OpenAPI)

### Code Generation Tools

| Tool | Input | Output |
|------|-------|--------|
| **openapi-generator** | OpenAPI 3.x | 50+ language SDKs, server stubs |
| **Kiota** (Microsoft) | OpenAPI 3.x | Type-safe clients for C#, Go, Java, PHP, Python, TypeScript |
| **Fern** | OpenAPI / Fern DSL | SDKs, docs, server stubs |
| **buf generate** | Protobuf | gRPC/Connect clients and servers |
| **orval** | OpenAPI 3.x | TypeScript clients with React Query/SWR integration |

---

## 16. API Security

### Authentication at the API Layer

| Method | Use Case | Notes |
|--------|----------|-------|
| **API Keys** | Server-to-server, simple integrations | Easy to implement, hard to rotate, no user context |
| **OAuth 2.1 + PKCE** | User-facing APIs | Standard for delegated authorization |
| **JWT Bearer** | Stateless API auth | Verify signature + claims, no DB lookup per request |
| **mTLS** | Service-to-service | Certificate-based, handled by service mesh |
| **Signed requests** (AWS SigV4) | High-security APIs | Request signing prevents tampering |

### Input Validation

- Validate all input at the API boundary — never trust client data
- Use schema validation (Zod, Joi, JSON Schema, Pydantic, Bean Validation)
- Validate types, ranges, lengths, formats, and business rules
- Reject unknown fields or sanitize them (defense against mass assignment)

### CORS (Cross-Origin Resource Sharing)

```
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 86400
```

- Never use `Access-Control-Allow-Origin: *` with credentials
- Whitelist specific origins, not wildcard
- Set `Access-Control-Max-Age` to reduce preflight requests

### Common API Vulnerabilities

| Vulnerability | Mitigation |
|--------------|------------|
| **Injection** (SQL, NoSQL, command) | Parameterized queries, input validation |
| **Broken authentication** | Strong token validation, rate limit login |
| **Excessive data exposure** | Return only needed fields, use DTOs |
| **Mass assignment** | Allowlist writable fields, use DTOs |
| **BOLA** (Broken Object-Level Authorization) | Check ownership on every request |
| **Rate limiting bypass** | Multiple rate limit keys (IP + API key + user) |

---

## Decision Framework

| Decision | Default | Switch When |
|----------|---------|-------------|
| API style | REST (OpenAPI 3.1) | Multiple clients (GraphQL), internal high-perf (gRPC/Connect), TS monorepo (tRPC) |
| Serialization | JSON | Performance-critical internal (protobuf), binary data (protobuf) |
| Versioning | Additive-only (internal), URL path (public) | Platform APIs with many consumers (date-based) |
| Pagination | Cursor-based | Simple use cases with small data (offset), GraphQL (Relay connections) |
| Real-time | SSE | Bidirectional needed (WebSocket), ultra-low-latency (WebTransport) |
| Documentation | Scalar or Redocly | Enterprise multi-spec (Redocly), existing Swagger investment (Swagger UI) |
| Testing | Contract testing (Pact) + integration | Simple single-team API (integration only) |
| Error format | RFC 9457 Problem Details | Already using a custom format (migration path) |

**Overarching principle**: Design APIs for your consumers. The best API pattern is the one your consumers can use most effectively — not the one with the most features or the best benchmarks.
