# TypeScript Backend Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Runtimes](#1-runtimes)
2. [Framework Decision Matrix](#2-framework-decision-matrix)
3. [NestJS](#3-nestjs)
4. [Fastify](#4-fastify)
5. [Hono](#5-hono)
6. [Other Frameworks](#6-other-frameworks)
7. [API Patterns](#7-api-patterns)
8. [ORMs and Database Access](#8-orms-and-database-access)
9. [Validation and Schemas](#9-validation-and-schemas)
10. [Authentication](#10-authentication)
11. [Messaging and Queues](#11-messaging-and-queues)
12. [Testing](#12-testing)
13. [Monorepo Tools](#13-monorepo-tools)
14. [Deployment](#14-deployment)
15. [Performance](#15-performance)
16. [Observability](#16-observability)

---

## 1. Runtimes

### Node.js (20 LTS, 22+)

The established runtime. Key modern features:
- **Built-in test runner** (`node --test`): No external test framework needed for simple cases
- **Built-in fetch API**: Global `fetch()` (no node-fetch needed)
- **Permissions model** (`--experimental-permission`): Restrict file/network/child_process access
- **Single executable apps**: Bundle Node.js + your app into one binary
- **ESM as default**: Full ES modules support, `type: "module"` in package.json
- **Watch mode** (`node --watch`): Built-in file watching for dev
- **Performance**: V8 engine, well-optimized for I/O-bound work

### Bun

Fast JavaScript/TypeScript runtime and toolkit:
- **Performance**: 2-4x faster than Node.js for many benchmarks (startup, HTTP serving, file I/O)
- **Built-in**: Bundler, test runner, package manager (`bun install` — faster than npm/pnpm)
- **Native TypeScript**: Runs `.ts` files directly without compilation
- **Node.js compatibility**: Supports most `node:*` APIs and npm packages
- **SQLite built-in**: `bun:sqlite` for embedded database
- **Hot module reload**: `bun --hot` for development

**When to choose Bun:**
- Maximum performance matters (HTTP throughput, startup time)
- All-in-one tooling (no separate bundler/test runner/package manager)
- Greenfield project where Node.js compatibility edge cases won't bite
- Using ElysiaJS or other Bun-native frameworks

**When to stick with Node.js:**
- Production stability is paramount (Node.js has a much longer production track record)
- Need full npm ecosystem compatibility (some native addons don't work with Bun)
- Team is familiar with Node.js tooling
- Running in environments that don't support Bun

### Deno 2.x

Secure JavaScript/TypeScript runtime:
- **npm compatibility** (Deno 2.0+): Full `npm:` specifier support, runs most npm packages
- **Built-in TypeScript**: No compilation step
- **Security by default**: Explicit permissions for file/network/env access
- **Standard library**: High-quality, audited `@std/*` modules
- **Deno Deploy**: Serverless edge platform (globally distributed)
- **Deno KV**: Built-in key-value store (local SQLite, cloud-replicated on Deno Deploy)

**When to choose Deno:**
- Security-conscious environments (explicit permissions model)
- Edge deployment (Deno Deploy)
- Projects that benefit from built-in KV store
- Teams wanting web-standard APIs (fetch, Web Streams, Web Crypto)

---

## 2. Framework Decision Matrix

| Framework | Best For | Performance | DX | Ecosystem |
|-----------|---------|-------------|-----|-----------|
| **NestJS** | Enterprise apps, large teams | Good | Excellent (DI, modules) | Large |
| **Fastify** | Performance-critical APIs | Excellent | Good (plugins) | Large |
| **Hono** | Edge/multi-runtime, lightweight | Excellent | Good | Growing |
| **Express** | Legacy, simple APIs | Adequate | Simple | Largest |
| **ElysiaJS** | Bun-native, type-safe | Fastest | Excellent | Small |
| **tRPC** | Full-stack TS monorepo | N/A (layer) | Exceptional | Medium |
| **AdonisJS** | Full-stack, opinionated | Good | Excellent | Small |

### Quick Recommendation
- **Enterprise / large team**: NestJS
- **Performance-critical API**: Fastify
- **Edge / multi-runtime**: Hono
- **Full-stack TypeScript monorepo**: tRPC + any framework
- **Rapid prototyping**: Express or AdonisJS
- **Bun-native**: ElysiaJS

---

## 3. NestJS

### Overview
Full-featured, opinionated framework inspired by Angular. Best for large-scale applications.

**Core concepts:**
- **Modules**: Organizational units. Each feature is a module with controllers, providers, and imports.
- **Dependency Injection**: First-class DI container. Constructor injection, custom providers, scoped providers.
- **Decorators**: `@Controller()`, `@Get()`, `@Injectable()`, `@Module()` — clean, declarative API.
- **Middleware, Guards, Interceptors, Pipes, Filters**: Layered request pipeline for cross-cutting concerns.

**Key capabilities:**
- **Microservices**: Built-in transport layers (TCP, Redis, NATS, Kafka, gRPC, RabbitMQ, MQTT)
- **GraphQL**: Code-first and schema-first approaches with `@nestjs/graphql` (Apollo or Mercurius)
- **WebSockets**: `@WebSocketGateway()` with Socket.io or ws
- **OpenAPI**: `@nestjs/swagger` for auto-generated Swagger docs from decorators
- **CQRS**: `@nestjs/cqrs` module for command/query separation
- **Task scheduling**: `@nestjs/schedule` for cron jobs
- **Health checks**: `@nestjs/terminus` for Kubernetes probes

**When to choose NestJS:**
- Large teams needing consistent architecture patterns
- Enterprise applications with complex domain logic
- Microservices architecture (built-in support for multiple transport layers)
- Teams coming from Angular or Spring Boot (familiar patterns)

**When NOT to choose NestJS:**
- Simple APIs (too much ceremony)
- Edge/serverless deployment (too heavy for cold starts)
- Maximum performance (Fastify without NestJS overhead is faster)

---

## 4. Fastify

### Overview
High-performance web framework focused on speed and low overhead.

**Performance:**
- 2-3x faster than Express in benchmarks
- JSON schema-based serialization (faster than `JSON.stringify`)
- Low overhead plugin system

**Key features:**
- **Schema validation**: JSON Schema for request/response validation (also drives serialization optimization)
- **Plugin system**: Encapsulated plugins with proper registration order and decoration
- **TypeScript-first**: Strong TypeScript support with type providers (`@fastify/type-provider-typebox`, `@fastify/type-provider-zod`)
- **Logging**: Built-in Pino integration (structured JSON logging, extremely fast)
- **Hooks**: `onRequest`, `preHandler`, `onSend`, `onResponse` lifecycle hooks

**Ecosystem plugins:**
- `@fastify/cors`, `@fastify/helmet`, `@fastify/rate-limit`
- `@fastify/jwt`, `@fastify/oauth2`, `@fastify/session`
- `@fastify/swagger` for OpenAPI generation
- `@fastify/websocket` for WebSocket support
- `@fastify/multipart` for file uploads

**When to choose Fastify:**
- Performance is a key requirement
- You want schema-driven validation and serialization
- Building REST APIs with structured logging needs
- NestJS can use Fastify as its HTTP adapter (best of both worlds)

---

## 5. Hono

### Overview
Ultra-lightweight framework built for multi-runtime support and edge computing.

**Runs everywhere:**
- Cloudflare Workers, Deno, Bun, Node.js, AWS Lambda, Vercel, Fastly Compute
- Same code, multiple deployment targets

**Key features:**
- **Tiny**: ~14KB (no dependencies)
- **Fast**: Optimized RegExp router, zero-cost middleware
- **Type-safe**: Full TypeScript with type-inferred routes
- **Middleware**: Built-in CORS, ETag, logger, bearer auth, JWT, basic auth, compress
- **RPC mode**: Type-safe client like tRPC (`hc<AppType>()`)
- **Validator middleware**: Zod, Valibot, TypeBox integration
- **JSX/TSX**: Built-in JSX support for server-rendered HTML

**When to choose Hono:**
- Edge-first deployment (Cloudflare Workers, Deno Deploy)
- Need multi-runtime portability
- Lightweight API where Express/Fastify overhead is too much
- Building edge middleware or API proxies

---

## 6. Other Frameworks

### ElysiaJS
- **Bun-native**: Built specifically for Bun runtime
- **End-to-end type safety**: Types flow from route definition to client
- **Performance**: Fastest TypeScript framework on Bun benchmarks
- **Plugin system**: Type-safe plugins, lifecycle hooks
- **Eden**: Type-safe client (like tRPC but for Elysia)

### tRPC
- **Not a framework** — a layer that provides end-to-end type safety
- Backend defines procedures (queries, mutations, subscriptions)
- Frontend gets fully typed client automatically — no code generation
- **Best with**: Next.js, NestJS, Fastify, or any TypeScript backend
- **Limitation**: TypeScript-only (not for public APIs consumed by non-TS clients)
- **v11**: Simplified API, better performance, React Server Components support

### AdonisJS
- Full-stack, opinionated framework (like Laravel for Node)
- Built-in: ORM (Lucid), auth, mailer, validation, testing
- Server-rendered with Edge templating engine, or API-only mode
- Best for: developers wanting batteries-included, coming from Laravel/Rails

### Express
- Still the most widely used Node.js framework
- Middleware-based, unopinionated
- **When to use**: Legacy projects, simple APIs, when you need maximum ecosystem compatibility
- **When to avoid**: New projects where performance matters (Fastify is faster) or you need structure (NestJS)

---

## 7. API Patterns

### REST with TypeScript
- Use Zod or TypeBox for request/response validation
- OpenAPI generation from schemas (fastify-swagger, tsoa, swagger-jsdoc)
- Response DTOs: define shape explicitly, don't leak internal models

### GraphQL
- **Apollo Server**: Most popular, federation support, caching, persisted queries
- **Yoga (The Guild)**: Lightweight, plugin-based, Envelop ecosystem
- **Pothos**: Code-first schema builder with excellent TypeScript inference
- **Nexus**: Code-first schema builder (less active development)
- **DGS on Node**: Netflix DGS concepts ported, less common in Node

### gRPC
- **nice-grpc**: Modern gRPC for Node.js with async iterators and TypeScript
- **@grpc/grpc-js**: Official gRPC library (lower-level)
- **Buf/Connect**: Generate idiomatic TypeScript clients and servers from protobuf

### tRPC (End-to-End Type Safety)
```typescript
// Server
const appRouter = router({
  user: router({
    get: publicProcedure.input(z.string()).query(({ input }) => getUser(input)),
    create: publicProcedure.input(createUserSchema).mutation(({ input }) => createUser(input)),
  }),
});

// Client (types flow automatically)
const user = await trpc.user.get.query("user-123");
```

No code generation, no OpenAPI spec — types flow directly from server to client via TypeScript inference.

---

## 8. ORMs and Database Access

### Prisma
- **Schema-first**: Define models in `schema.prisma`, generate typed client
- **Migrations**: `prisma migrate dev` for development, `prisma migrate deploy` for production
- **Type safety**: Generated client provides full type safety for queries
- **Prisma Studio**: GUI for browsing/editing data
- **Prisma Accelerate**: Edge-compatible connection pooling and caching
- **Prisma Pulse**: Real-time database change events

**Tradeoffs:**
- Generated client can be large (bundle size concern for serverless)
- Complex raw SQL requires `$queryRaw` (less ergonomic)
- Schema changes require regeneration

### Drizzle ORM
- **SQL-like**: Syntax mirrors SQL, minimal abstraction
- **Lightweight**: No code generation needed, small bundle
- **Type-safe**: Full TypeScript inference from schema definition
- **Serverless-friendly**: Small bundle size, fast cold starts
- **Relational queries**: Drizzle-kit for migrations

```typescript
const users = await db.select().from(usersTable).where(eq(usersTable.id, 1));
```

**When Drizzle over Prisma:**
- Need smaller bundle size (serverless/edge)
- Prefer SQL-like syntax over Prisma's query API
- Want more control over queries
- Don't need Prisma's studio/ecosystem tools

### Kysely
- **Type-safe SQL query builder** (not an ORM)
- Zero overhead at runtime — just builds SQL strings
- Works with any database driver
- Best for: teams that want SQL control with TypeScript type safety

### TypeORM
- Older, decorator-based ORM (inspired by Hibernate)
- Active Record and Data Mapper patterns
- **Status**: Still maintained but less community momentum than Prisma/Drizzle
- Use for: existing projects, teams familiar with TypeORM patterns

### Knex
- SQL query builder (not type-safe by default)
- Migrations, seeding, connection pooling
- Foundation for Objection.js (ORM layer on top of Knex)
- Use for: raw SQL control when type safety isn't critical

---

## 9. Validation and Schemas

### Zod
- **Most popular** runtime validation library
- Infers TypeScript types from schemas: `z.infer<typeof schema>`
- Composable: `.extend()`, `.merge()`, `.pick()`, `.omit()`
- Framework integrations: tRPC, Fastify, Hono, React Hook Form
- Performance: adequate for most use cases (~10K validations/sec)

### Valibot
- **Modular**: Tree-shakeable (much smaller bundle than Zod)
- API similar to Zod but functional composition style
- Best for: bundle-size-sensitive deployments (serverless, edge)

### TypeBox
- JSON Schema compatible — validates AND generates JSON Schema
- Fastify's native type provider
- Static type inference like Zod
- Best for: Fastify projects, OpenAPI integration

### ArkType
- Syntax mirrors TypeScript itself: `type({ name: "string", age: "number > 0" })`
- Fastest validation library in benchmarks
- Newer, smaller ecosystem

**Recommendation**: Zod as default. TypeBox for Fastify. Valibot for edge/serverless. ArkType if benchmark performance matters.

---

## 10. Authentication

### Patterns
- **Lucia**: Lightweight auth library. Session-based, database-agnostic. No magic — you understand every line.
- **Auth.js (NextAuth)**: For Next.js/SvelteKit/etc. OAuth providers, JWT/session, database adapters.
- **Passport.js**: Strategy-based auth middleware (200+ strategies). Still widely used but showing age.
- **Oslo**: Cryptographic utilities for auth (by Lucia's author). Password hashing, TOTP, CSRF tokens.
- **Custom JWT**: `jose` library for JWT creation/verification. Full control.

### Best Practices
- Short-lived access tokens (5-15 min) + refresh tokens (days/weeks)
- Store refresh tokens in HTTP-only, secure, SameSite cookies
- Rotate refresh tokens on use (token rotation)
- Use `argon2` or `bcrypt` for password hashing (never SHA/MD5)
- CSRF protection for cookie-based auth

---

## 11. Messaging and Queues

### BullMQ (Redis-based)
- The standard for Node.js job queues
- Features: delayed jobs, repeat/cron, priorities, rate limiting, concurrency control
- Dashboard: Bull Board or Arena for monitoring
- Best for: background jobs, email sending, media processing

### KafkaJS
- Apache Kafka client for Node.js
- Consumer groups, transactions, compression
- Performance: handles thousands of messages/sec per consumer

### NATS Client
- `nats` npm package for NATS/JetStream
- Request-reply, pub/sub, key-value store, object store
- Best for: lightweight real-time messaging

### amqplib (RabbitMQ)
- Low-level AMQP client
- Use with `amqp-connection-manager` for connection resilience

---

## 12. Testing

### Vitest
- **Recommended default**: Fast, ESM-native, Vite-powered
- Jest-compatible API (easy migration)
- Built-in TypeScript support
- Watch mode, coverage, snapshot testing
- Workspace support for monorepos

### Jest
- Still widely used, large ecosystem
- Slower than Vitest for TypeScript (requires transform)
- Better for: existing projects, comprehensive plugin ecosystem

### Testing Libraries
- **Supertest**: HTTP assertion library for API testing
- **MSW (Mock Service Worker)**: Mock HTTP/GraphQL at the network level (no server changes)
- **Testcontainers**: Real Docker containers in tests (PostgreSQL, Redis, Kafka)
- **Faker.js**: Generate realistic test data
- **Playwright**: E2E testing (if testing API + frontend together)

### Patterns
- **Integration tests > unit tests** for APIs. Test the HTTP interface, not internal functions.
- Use Testcontainers for real database tests. Avoid mocking the database.
- MSW for external API mocking (third-party services, payment providers).

---

## 13. Monorepo Tools

### Turborepo
- **By Vercel**: Fast, convention-over-configuration
- Remote caching (Vercel or self-hosted)
- Task pipeline definition in `turbo.json`
- Best for: Vercel/Next.js ecosystems, simple monorepo needs

### Nx
- **Full-featured**: Task orchestration, affected detection, code generators
- Plugin system (React, Next.js, Node, Nest, etc.)
- Nx Cloud for distributed caching and task execution
- Best for: large monorepos, enterprise teams, polyglot (JS + Go + Python)

### pnpm Workspaces
- **Lightweight**: Just package management, no build orchestration
- Efficient disk usage (content-addressable store)
- Use with Turborepo or Nx for task orchestration
- Best for: when you just need shared packages, not a full monorepo framework

### Shared Packages Pattern
```
packages/
  shared-types/     # TypeScript types shared between frontend and backend
  shared-utils/     # Common utilities
  db/               # Prisma/Drizzle schema + client (shared)
  api-client/       # Generated or tRPC client
apps/
  api/              # Backend (NestJS, Fastify, etc.)
  web/              # Frontend (Next.js, etc.)
  mobile/           # Mobile app
```

---

## 14. Deployment

### Docker Best Practices for Node
```dockerfile
# Multi-stage build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:22-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
CMD ["node", "dist/main.js"]
```

- Use `node:*-alpine` for smaller images (~180MB vs ~1GB)
- Multi-stage builds: build in full image, run in slim image
- `npm ci` (not `npm install`) for reproducible builds
- Run as non-root user (`USER node`)
- `.dockerignore`: exclude `node_modules`, `.git`, tests

### Serverless
- **AWS Lambda**: Use `@aws-sdk/client-*` (v3, tree-shakeable). Bundle with esbuild for smallest package.
- **Cloudflare Workers**: Hono or itty-router. Use Wrangler CLI. KV/D1/R2 for storage.
- **Vercel Functions**: Next.js API routes or standalone functions. Edge Functions for low latency.

### Process Management
- **Docker/K8s**: Preferred for production. Built-in restart, scaling, health checks.
- **PM2**: Process manager for non-containerized Node.js. Clustering, log management, monitoring.
- **Cluster mode**: Node.js `cluster` module or PM2 cluster — spawn one process per CPU core.

---

## 15. Performance

### Event Loop Optimization
- Never block the event loop (no synchronous I/O, no heavy computation on main thread)
- Use **Worker Threads** for CPU-intensive tasks (image processing, crypto, parsing)
- `setImmediate()` to yield to the event loop in long-running operations
- Monitor event loop lag with `monitorEventLoopDelay()`

### Node.js vs Bun Benchmarks (Typical)
| Metric | Node.js 22 | Bun |
|--------|-----------|-----|
| HTTP req/sec (hello world) | ~50K | ~100-150K |
| Startup time | ~30ms | ~5-10ms |
| `npm install` equivalent | 5-15s | 1-5s |
| File I/O | Baseline | 2-3x faster |
| SQLite queries | N/A (external) | Built-in, very fast |

### Connection Pooling
- `pg` (node-postgres): Built-in pool. Default 10 connections. Set `max` based on load.
- Use **PgBouncer** externally for serverless (Lambda creates many short connections).
- `generic-pool` for custom resource pooling.

### Memory Management
- Default V8 heap: ~1.5GB (increase with `--max-old-space-size=4096`)
- Monitor with `process.memoryUsage()` and heap snapshots
- Watch for memory leaks: event listeners not removed, closures holding references, growing Maps/Sets

---

## 16. Observability

### Logging: Pino
- **Fastest** Node.js logger (10x faster than Winston)
- Structured JSON output by default
- Log levels, child loggers, redaction of sensitive fields
- `pino-pretty` for human-readable dev output
- Fastify uses Pino by default

### Metrics & Tracing: OpenTelemetry
- **`@opentelemetry/sdk-node`**: Auto-instrumentation for HTTP, database, framework calls
- **`@opentelemetry/auto-instrumentations-node`**: One package to instrument everything
- Exporters: OTLP (to Jaeger, Tempo), Prometheus, Datadog
- Manual instrumentation: `tracer.startSpan()` for custom spans

### Prometheus Client
- `prom-client`: Official Prometheus client for Node.js
- Default metrics (event loop lag, heap usage, GC stats)
- Custom counters, gauges, histograms
- `/metrics` endpoint for Prometheus scraping

### Recommended Stack
- **Logging**: Pino → Loki / Elasticsearch → Grafana / Kibana
- **Tracing**: OpenTelemetry → Tempo / Jaeger → Grafana
- **Metrics**: prom-client → Prometheus → Grafana
- **Error tracking**: Sentry (captures errors + performance)
