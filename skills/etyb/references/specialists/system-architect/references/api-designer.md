# API Design — Deep Reference

**Always use `WebSearch` to verify current spec versions, tool updates, and framework features before giving advice. API standards and tooling evolve rapidly.**

## Table of Contents
1. [API Style Selection](#1-api-style-selection)
2. [REST API Design](#2-rest-api-design)
3. [GraphQL Design](#3-graphql-design)
4. [gRPC and Connect](#4-grpc-and-connect)
5. [OpenAPI and AsyncAPI](#5-openapi-and-asyncapi)
6. [API Versioning](#6-api-versioning)
7. [API Security](#7-api-security)
8. [API Governance and DX](#8-api-governance-and-dx)
9. [Emerging Patterns](#9-emerging-patterns)

---

## 1. API Style Selection

### Decision Matrix

| Factor | REST | GraphQL | gRPC | tRPC |
|--------|------|---------|------|------|
| **Best for** | Public APIs, CRUD, caching | Multi-client, complex graphs | Internal services, streaming | Monorepo TypeScript full-stack |
| **Performance** | Good | Good (watch N+1) | Excellent (5-10x faster) | Good |
| **Caching** | Excellent (HTTP caching) | Complex (no native HTTP cache) | Manual | N/A |
| **Browser support** | Native | Native | Needs proxy (gRPC-Web/Connect) | Native (TypeScript) |
| **Learning curve** | Low | Medium | Medium-High | Low (TypeScript devs) |
| **Type safety** | Via OpenAPI codegen | Built-in (schema) | Built-in (Protobuf) | Built-in (TypeScript) |
| **Streaming** | SSE, WebSocket (separate) | Subscriptions (@defer/@stream) | Native (all 4 patterns) | Limited |
| **Ecosystem size** | Largest | Large | Growing | Small (TypeScript only) |
| **Latency** | ~15ms median | ~20ms median | ~4ms median | ~12ms median |
| **Payload size** | ~1.2KB (JSON) | Variable | ~312B (Protobuf) | ~800B |

### Quick Recommendation

- **Public API (external consumers)**: REST with OpenAPI
- **Multi-client app (web + mobile + third-party)**: GraphQL
- **Internal microservice-to-microservice**: gRPC or Connect
- **Full-stack TypeScript monorepo**: tRPC
- **Real-time bidirectional**: gRPC streaming or WebSocket
- **Mixed**: REST for public + gRPC for internal is the most common production pattern

Teams report 28% faster feature delivery after adopting a dual REST+GraphQL pattern for public endpoints, and hybrid stacks reduce MTTR by up to 35% when aligned with contracts and tracing.

---

## 2. REST API Design

### Resource Modeling

```
# Resources are nouns, not verbs
GET    /users              # List users
POST   /users              # Create user
GET    /users/{id}         # Get user
PUT    /users/{id}         # Replace user
PATCH  /users/{id}         # Partial update
DELETE /users/{id}         # Delete user

# Sub-resources for clear relationships
GET    /users/{id}/orders          # User's orders
POST   /users/{id}/orders          # Create order for user
GET    /users/{id}/orders/{orderId} # Specific order

# Actions (when CRUD doesn't fit) — use verbs sparingly
POST   /orders/{id}/cancel         # Cancel an order
POST   /orders/{id}/refund         # Refund an order
```

### HTTP Methods and Status Codes

| Method | Idempotent | Safe | Typical Response |
|--------|-----------|------|-----------------|
| GET | Yes | Yes | 200 OK |
| POST | No | No | 201 Created (with Location header) |
| PUT | Yes | No | 200 OK or 204 No Content |
| PATCH | No* | No | 200 OK |
| DELETE | Yes | No | 204 No Content |

*PATCH can be made idempotent with JSON Merge Patch (RFC 7396).

**Error responses** — use a consistent structure:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": [
      { "field": "email", "message": "Must be a valid email address" },
      { "field": "age", "message": "Must be a positive integer" }
    ],
    "request_id": "req_abc123"
  }
}
```

### Pagination Patterns

| Pattern | Pros | Cons | Best For |
|---------|------|------|----------|
| **Cursor-based** | Stable with inserts/deletes, performant | Can't jump to page N | Infinite scroll, real-time feeds |
| **Offset-based** | Simple, jump to any page | Skips/duplicates with concurrent writes | Admin UIs, small datasets |
| **Keyset** | Performant, stable | Requires sortable column, can't jump | Large sorted datasets |

**Cursor-based (recommended for most APIs):**
```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTAwfQ==",
    "has_more": true
  }
}
```

### Filtering, Sorting, and Field Selection

```
# Filtering
GET /products?category=electronics&price_min=100&price_max=500&in_stock=true

# Sorting
GET /products?sort=-created_at,price    # Descending created_at, ascending price

# Sparse fieldsets (reduce payload)
GET /products?fields=id,name,price,thumbnail_url

# Search
GET /products?q=wireless+headphones
```

### Rate Limiting Headers

```
X-RateLimit-Limit: 1000          # Requests allowed per window
X-RateLimit-Remaining: 742       # Requests remaining
X-RateLimit-Reset: 1620000000    # Unix timestamp when window resets
Retry-After: 30                  # Seconds to wait (on 429)
```

---

## 3. GraphQL Design

### Schema Design Best Practices

```graphql
# Use connections for paginated lists (Relay spec)
type Query {
  products(
    first: Int
    after: String
    filter: ProductFilter
  ): ProductConnection!
}

type ProductConnection {
  edges: [ProductEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type ProductEdge {
  node: Product!
  cursor: String!
}

# Use input types for mutations
input CreateProductInput {
  name: String!
  price: MoneyInput!
  categoryId: ID!
}

# Return the affected object in mutation responses
type CreateProductPayload {
  product: Product
  userErrors: [UserError!]!
}

type UserError {
  field: [String!]
  message: String!
  code: ErrorCode!
}
```

### Federation v2 (Apollo)

Federation allows multiple teams to contribute to a single unified GraphQL API:

```graphql
# Team A: Product subgraph
type Product @key(fields: "id") {
  id: ID!
  name: String!
  price: Money!
}

# Team B: Review subgraph (extends Product)
extend type Product @key(fields: "id") {
  id: ID! @external
  reviews: [Review!]!
  averageRating: Float
}
```

**Federation components:**
- **Subgraphs**: Individual GraphQL services owned by different teams
- **Router** (Apollo Router / Cosmo Router): Composes subgraphs into a unified supergraph, handles query planning
- **Schema Registry**: Validates composition, checks for breaking changes

**When Federation, when not:**
- Use: Large organizations (5+ teams), need team autonomy with unified API
- Don't use: Small team, single service, simple schema

### GraphQL Security

| Threat | Mitigation |
|--------|-----------|
| **Query depth attack** | Max depth limit (typically 10-15) |
| **Query complexity attack** | Complexity scoring per field, reject above threshold |
| **Batch attack** | Limit number of operations per request |
| **Introspection leak** | Disable introspection in production |
| **N+1 queries** | DataLoader pattern (batch + cache per request) |

### @defer and @stream (Incremental Delivery)

```graphql
query ProductPage($id: ID!) {
  product(id: $id) {
    name
    price
    # Reviews load after initial response
    ...ReviewSection @defer
  }
}

fragment ReviewSection on Product {
  reviews(first: 10) {
    edges { node { rating text author { name } } }
  }
}
```

Supported in Apollo Client, Relay, and urql. Allows progressive rendering of slow-resolving fields.

---

## 4. gRPC and Connect

### Protocol Buffers Best Practices

```protobuf
syntax = "proto3";
package acme.order.v1;

// Use package versioning for breaking changes
service OrderService {
  rpc CreateOrder(CreateOrderRequest) returns (CreateOrderResponse);
  rpc GetOrder(GetOrderRequest) returns (Order);
  rpc ListOrders(ListOrdersRequest) returns (ListOrdersResponse);
  rpc WatchOrders(WatchOrdersRequest) returns (stream OrderEvent);
}

message CreateOrderRequest {
  repeated OrderItem items = 1;
  string customer_id = 2;
  Address shipping_address = 3;
}

message ListOrdersRequest {
  int32 page_size = 1;
  string page_token = 2;  // Cursor-based pagination
  string filter = 3;       // AIP-160 filtering
}

message ListOrdersResponse {
  repeated Order orders = 1;
  string next_page_token = 2;
}
```

### gRPC Streaming Patterns

| Pattern | Use Case | Example |
|---------|----------|---------|
| **Unary** | Simple request-response | Get user by ID |
| **Server streaming** | Server pushes updates | Watch order status changes |
| **Client streaming** | Client sends batch | Upload file chunks, bulk import |
| **Bidirectional streaming** | Real-time, full-duplex | Chat, collaborative editing |

### Connect Protocol (by Buf)

Connect generates idiomatic HTTP APIs from Protobuf definitions, supporting both gRPC and a simpler HTTP/1.1 protocol. This means you can call your APIs from a browser without gRPC-Web.

**Advantages over gRPC-Web:**
- No proxy needed (direct HTTP/1.1 support)
- Works with standard HTTP tools (curl, Postman)
- Same .proto files, same type safety
- Growing rapidly as more ergonomic gRPC

**Buf CLI** for Protobuf management:
- `buf lint`: Enforce style rules on .proto files
- `buf breaking`: Detect breaking changes between versions
- `buf generate`: Code generation for multiple languages
- **Buf Schema Registry (BSR)**: Remote registry for Protobuf modules

---

## 5. OpenAPI and AsyncAPI

### OpenAPI 3.1

OpenAPI 3.1 aligns with JSON Schema (draft 2020-12), meaning you can reuse JSON Schema definitions directly. This is the current standard for REST API definitions.

**Spec-first vs Code-first:**

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **Spec-first** | Design before implementation, contract-driven | Spec can drift from code | Public APIs, multi-team |
| **Code-first** | Always matches implementation, less duplication | API design is an afterthought | Internal APIs, rapid iteration |

**Code generation tools:**
- **openapi-generator**: Multi-language server/client generation (70+ languages)
- **Orval**: TypeScript client generation (React Query, SWR, Angular)
- **Kiota** (Microsoft): Multi-language client generation
- **Speakeasy**: High-quality SDK generation for multiple languages
- **Fern**: API development platform with SDK generation

### AsyncAPI

Specification for event-driven APIs — the OpenAPI equivalent for async messaging:

```yaml
asyncapi: 3.0.0
info:
  title: Order Events
  version: 1.0.0
channels:
  orderPlaced:
    address: orders.placed
    messages:
      OrderPlacedMessage:
        payload:
          type: object
          properties:
            orderId:
              type: string
            customerId:
              type: string
            totalAmount:
              type: number
```

Use AsyncAPI to document: Kafka topics, RabbitMQ exchanges, WebSocket messages, NATS subjects, SNS/SQS queues.

---

## 6. API Versioning

### Strategies Compared

| Strategy | Example | Pros | Cons | Used By |
|----------|---------|------|------|---------|
| **URL path** | `/api/v1/users` | Simple, explicit | URL pollution, hard to sunset | Twitter, GitHub |
| **Header** | `Accept: application/vnd.api.v2+json` | Clean URLs | Hidden, harder to discover | GitHub (also supports) |
| **Query param** | `/users?version=2` | Easy to test | Easy to forget | Google (some APIs) |
| **Date-based** | `Stripe-Version: 2024-10-01` | Granular, backward-compatible | Complex implementation | Stripe, Twilio |
| **Additive-only** | No versioning | Simplest | Can't make breaking changes | Internal APIs |

### Stripe's Date-Based Versioning (Gold Standard)

Stripe's approach is the most sophisticated public API versioning strategy:

1. **API versions are dates** (e.g., `2024-10-01`). Your account is pinned to a version.
2. **Breaking changes bundled** into new dated versions with detailed migration guides
3. **Non-breaking changes** (additive fields, new endpoints) ship continuously
4. **Stripe-Version header** overrides your account's default version for a single request
5. **Version gates**: Internal mechanism that maps version → behavior flags
6. **Monthly releases** with no breaking changes; twice-yearly releases with breaking changes

**Implementation pattern:**
```python
# Internal gate system (simplified)
def allows_amount(api_version):
    return api_version < "2024-09-30"

# In endpoint handler
if version_gate.allows_amount(request.api_version):
    return legacy_response(data)
else:
    return new_response(data)
```

**When to use date-based**: Public APIs with long-lived consumers, where backward compatibility is critical and you want fine-grained control over breaking changes.

### API Deprecation

1. **Announce**: Add `Deprecation` and `Sunset` headers to deprecated endpoints
2. **Document**: Publish migration guide with code examples
3. **Monitor**: Track usage of deprecated endpoints
4. **Grace period**: Minimum 6 months for public APIs (12 months preferred)
5. **Remove**: Return 410 Gone after sunset date

---

## 7. API Security

### OAuth 2.1

OAuth 2.1 consolidates best practices from OAuth 2.0 and its extensions:
- **PKCE required** for all flows (not just public clients)
- **Implicit flow removed** (use Authorization Code + PKCE instead)
- **Refresh token rotation**: New refresh token on each use
- **Exact redirect URI matching**: No wildcards

### API Security Checklist

| Category | Check |
|----------|-------|
| **Authentication** | OAuth 2.1 or API keys (signed, not plain). Never pass credentials in URLs. |
| **Authorization** | Check permissions on every request. Don't rely on obscurity of IDs. |
| **Input validation** | Validate all input (type, length, format). Reject unknown fields. |
| **Rate limiting** | Per-user and per-IP limits. Token bucket or sliding window algorithm. |
| **CORS** | Explicit allowlists, not `Access-Control-Allow-Origin: *` for authenticated APIs |
| **TLS** | HTTPS everywhere. HSTS header. TLS 1.2+ minimum. |
| **Payload limits** | Max request body size. Max array/object depth. |
| **Logging** | Log auth failures, rate limit hits. Never log credentials, tokens, or PII. |
| **Error messages** | Don't leak internal details (stack traces, SQL errors, file paths). |

### OWASP API Security Top 10 (2023)

| # | Risk | Mitigation |
|---|------|-----------|
| API1 | Broken Object Level Authorization | Check ownership on every object access |
| API2 | Broken Authentication | Strong auth, rate limit login, multi-factor |
| API3 | Broken Object Property Level Authorization | Filter response fields based on permissions |
| API4 | Unrestricted Resource Consumption | Rate limiting, pagination limits, payload size limits |
| API5 | Broken Function Level Authorization | Check roles for every action, not just data access |
| API6 | Unrestricted Access to Sensitive Business Flows | Bot detection, CAPTCHA, business logic rate limits |
| API7 | Server Side Request Forgery | Validate/allowlist URLs, block internal network access |
| API8 | Security Misconfiguration | Disable debug, secure defaults, review headers |
| API9 | Improper Inventory Management | API catalog, deprecation tracking, shadow API detection |
| API10 | Unsafe Consumption of APIs | Validate third-party API responses, timeout, circuit breaker |

### Rate Limiting Algorithms

| Algorithm | How It Works | Best For |
|-----------|-------------|----------|
| **Token Bucket** | Tokens added at fixed rate, consumed per request. Allows bursts. | Most APIs (default choice) |
| **Sliding Window** | Count requests in rolling time window | Strict, even rate enforcement |
| **Leaky Bucket** | Requests queued, processed at constant rate | Smoothing traffic, protecting downstream |
| **Fixed Window** | Count requests per time window (e.g., per minute) | Simple, but allows burst at window boundary |

---

## 8. API Governance and DX

### API Design Guidelines

Leading companies publish their API design guidelines:
- **Google API Design Guide**: Resource-oriented, standard methods, AIP (API Improvement Proposals)
- **Microsoft REST API Guidelines**: JSON conventions, versioning, long-running operations
- **Zalando RESTful API Guidelines**: Comprehensive, opinionated, widely adopted in Europe
- **Stripe API Reference**: Gold standard for DX — consistent, well-documented, great error messages
- **Heroku Platform API Guidelines**: Simple, pragmatic, JSON Schema-based

### API Linting

Automated enforcement of design rules:

| Tool | What It Does | Best For |
|------|-------------|----------|
| **Spectral** (Stoplight) | JSON/YAML linter with custom rules, OpenAPI + AsyncAPI support | Flexible rule enforcement, CI integration |
| **Redocly CLI** | Linting + bundling + preview + breaking change detection | Full API lifecycle management |
| **Vacuum** | High-performance OpenAPI linter, Spectral-compatible rules | Large specs, fast CI checks |
| **Buf** | Protobuf linting, breaking change detection, schema registry | gRPC/Connect APIs |

**Recommendation**: Use Spectral for OpenAPI linting in CI. Add Redocly for documentation preview and breaking change detection. Use Buf for Protobuf APIs.

### API Documentation

| Tool | Type | Best For |
|------|------|----------|
| **Redoc** | Static docs from OpenAPI | Beautiful single-page reference docs |
| **Swagger UI** | Interactive docs from OpenAPI | Try-it-out playground |
| **Stoplight** | API design platform | Full lifecycle: design, docs, mock, test |
| **ReadMe** | Developer portal | Interactive docs with user context |
| **Mintlify** | Documentation platform | Modern, beautiful developer docs |

### Developer Experience (DX) Principles

1. **Consistency**: Same patterns everywhere — error format, pagination, naming
2. **Discoverability**: API explorer, interactive docs, code examples in multiple languages
3. **Predictability**: No surprises — if GET /users returns an array, GET /products should too
4. **Error clarity**: Error messages should tell the developer exactly what went wrong and how to fix it
5. **SDKs**: Generate client libraries in popular languages (TypeScript, Python, Go, Java)
6. **Sandboxes**: Test environment with realistic data that doesn't affect production

---

## 9. Emerging Patterns

### API Mesh

A federated approach where multiple APIs (REST, GraphQL, gRPC) are composed into a unified gateway:
- **GraphQL Mesh**: Wraps any API (REST, gRPC, SOAP) as a GraphQL source
- **API gateway composition**: Kong, Tyk, or cloud API gateways aggregating multiple backends

### Event-Driven APIs

Beyond request-response:
- **Webhooks**: Server pushes events to client's URL. Needs: delivery guarantees, retry logic, signature verification
- **Server-Sent Events (SSE)**: One-way server push over HTTP. Simpler than WebSockets for feeds/notifications
- **WebSockets**: Full-duplex. Use for chat, real-time collaboration, gaming
- **Async Request-Reply**: POST returns 202 Accepted + polling URL or webhook callback

### Contract Testing

Verify API compatibility between consumers and providers:
- **Pact**: Consumer-driven contract testing. Consumer defines expected interactions, provider verifies.
- **Schemathesis**: Property-based testing from OpenAPI specs. Auto-generates edge cases.
- **Dredd**: Validates API implementation against OpenAPI spec

### API-First Development

Design the API contract before writing implementation:
1. Write the OpenAPI/Protobuf spec
2. Review with consumers (frontend teams, partners)
3. Generate server stubs and client SDKs
4. Implement the server logic
5. Validate implementation against the spec in CI

---

## Decision Framework Summary

| Decision | Default | Switch When |
|----------|---------|-------------|
| **API style** | REST (public) + gRPC (internal) | Multi-client complex graphs (GraphQL), TypeScript monorepo (tRPC) |
| **Spec format** | OpenAPI 3.1 | Event-driven (AsyncAPI), gRPC (Protobuf) |
| **Spec approach** | Code-first | Public APIs with external consumers (spec-first) |
| **Pagination** | Cursor-based | Simple admin UI (offset), large sorted data (keyset) |
| **Versioning** | URL path (`/v1/`) | Long-lived public API (date-based), internal (additive-only) |
| **Auth** | OAuth 2.1 + PKCE | Machine-to-machine (API keys), internal (mTLS) |
| **Rate limiting** | Token bucket | Strict enforcement (sliding window) |
| **Linting** | Spectral in CI | Full lifecycle (Redocly), Protobuf (Buf) |
| **Documentation** | Redoc (reference) + Swagger UI (playground) | Developer portal (ReadMe, Mintlify) |
| **Contract testing** | None (start simple) | Multiple consumers (Pact), auto-testing (Schemathesis) |
