# Go Backend Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Modern Go (1.21+)](#1-modern-go-121)
2. [Framework Decision Matrix](#2-framework-decision-matrix)
3. [Standard Library (net/http)](#3-standard-library-nethttp)
4. [Gin](#4-gin)
5. [Echo](#5-echo)
6. [Fiber](#6-fiber)
7. [Other Frameworks](#7-other-frameworks)
8. [API Patterns](#8-api-patterns)
9. [Database Access](#9-database-access)
10. [Concurrency Patterns](#10-concurrency-patterns)
11. [Dependency Injection](#11-dependency-injection)
12. [Messaging](#12-messaging)
13. [Testing](#13-testing)
14. [Observability](#14-observability)
15. [Deployment](#15-deployment)
16. [Performance](#16-performance)
17. [When Go Shines](#17-when-go-shines)

---

## 1. Modern Go (1.21+)

### Go 1.21 (August 2023)
- **Built-in `min`, `max`, `clear` functions**
- **`log/slog`**: Structured logging in the standard library. Handlers for text and JSON.
- **`maps` and `slices` packages**: Generic utility functions for maps and slices
- **Profile-Guided Optimization (PGO)**: Feed CPU profiles to compiler for 2-7% performance improvement
- **WASI preview support**: WebAssembly System Interface

### Go 1.22 (February 2024)
- **Range over integers**: `for i := range 10 { ... }` — no more `for i := 0; i < 10; i++`
- **Enhanced ServeMux routing**: Method-based routing and path parameters in `net/http`
  ```go
  mux.HandleFunc("GET /users/{id}", getUser)
  mux.HandleFunc("POST /users", createUser)
  ```
- **Loop variable fix**: Each iteration gets its own variable (fixes the classic goroutine-in-loop bug)
- **`math/rand/v2`**: New random number package with better API

### Go 1.23 (August 2024)
- **Range-over-func (iterators)**: Custom iterator functions with `iter.Seq[V]` and `iter.Seq2[K, V]`
  ```go
  func Backward[E any](s []E) iter.Seq2[int, E] {
      return func(yield func(int, E) bool) {
          for i := len(s) - 1; i >= 0; i-- {
              if !yield(i, s[i]) { return }
          }
      }
  }
  for i, v := range Backward(mySlice) { ... }
  ```
- **`unique` package**: Canonical values (interning) for memory-efficient deduplication
- **Timer/Ticker changes**: Unreferenced timers are now garbage collected (prevents leaks)

### Go 1.24 (February 2025)
- **Generic type aliases**: `type Set[T comparable] = map[T]struct{}`
- **`testing/synctest`**: Testing package for concurrent code with virtual time
- **`os.Root`**: Rooted filesystem access for security
- **Swiss table map implementation**: Faster map operations
- **Improved PGO**: Better devirtualization, more inlining
- **`go tool` subcommands**: `go tool trace`, `go tool pprof` improvements
- **FIPS 140-3 compliance** in crypto packages

### Key Go Philosophy for Backend Architects
- **Simplicity over abstraction**: No inheritance, no generics complexity (generics added in 1.18 but used sparingly)
- **Concurrency is a first-class citizen**: Goroutines + channels are the core programming model
- **Explicit error handling**: `if err != nil` pattern — no exceptions, no hidden control flow
- **Fast compilation**: Full rebuild of large projects in seconds
- **Single binary deployment**: No runtime dependencies, no JVM, no interpreter
- **Opinionated formatting**: `gofmt` — one true style, no debates

---

## 2. Framework Decision Matrix

| Framework | Best For | Performance | Philosophy |
|-----------|---------|-------------|-----------|
| **net/http (stdlib)** | Production APIs, max control | Excellent | Go-idiomatic, zero deps |
| **Chi** | stdlib-compatible router | Excellent | Lightweight, composable middleware |
| **Gin** | Rapid development, familiar API | Excellent | Express-like, most popular |
| **Echo** | Feature-rich APIs | Excellent | Clean API, good docs |
| **Fiber** | Maximum throughput | Fastest | Express-like, fasthttp-based |
| **Connect** | gRPC-compatible APIs | Excellent | Protobuf-first, Buf ecosystem |
| **Fuego** | Type-safe, OpenAPI auto-gen | Very good | Modern, code-first |

### Quick Recommendation
- **Production API, Go-idiomatic**: net/http (1.22+) + Chi
- **Team coming from Express/Fastify**: Gin or Fiber
- **gRPC + REST from same proto**: Connect-Go
- **Maximum throughput**: Fiber (fasthttp-based)
- **Auto-generated OpenAPI**: Fuego

### The "Do You Even Need a Framework?" Question
In Go, the standard library `net/http` (especially since 1.22 with method routing and path params) is production-ready for most APIs. The community often recommends starting with stdlib + a lightweight router (Chi) before reaching for a full framework. This is different from Java/TypeScript where frameworks provide essential structure.

---

## 3. Standard Library (net/http)

### Since Go 1.22 — A Real API Framework
```go
mux := http.NewServeMux()
mux.HandleFunc("GET /users/{id}", func(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")
    user := getUser(id)
    json.NewEncoder(w).Encode(user)
})
mux.HandleFunc("POST /users", createUser)
mux.HandleFunc("DELETE /users/{id}", deleteUser)

http.ListenAndServe(":8080", mux)
```

### What stdlib provides
- Method-based routing with path parameters (1.22+)
- Middleware via `http.Handler` wrapping
- TLS support built-in
- HTTP/2 support built-in
- `httptest` package for testing
- `net/http/httputil` for reverse proxies

### What stdlib lacks (add via libraries)
- Request validation (use `go-playground/validator`)
- CORS handling (use `rs/cors`)
- Structured response helpers (write your own or use Chi)
- Rate limiting (use `golang.org/x/time/rate`)
- OpenAPI generation (use `swaggo/swag` or `oapi-codegen`)

---

## 4. Gin

### Overview
Most popular Go web framework. Express-like API.

```go
r := gin.Default() // includes Logger and Recovery middleware
r.GET("/users/:id", func(c *gin.Context) {
    id := c.Param("id")
    c.JSON(200, gin.H{"id": id, "name": "Alice"})
})
r.POST("/users", func(c *gin.Context) {
    var user User
    if err := c.ShouldBindJSON(&user); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    c.JSON(201, user)
})
r.Run(":8080")
```

### Key Features
- Request binding and validation (JSON, XML, form, query params)
- Middleware support (Logger, Recovery, CORS, Auth)
- Route grouping with prefix
- Custom validators via `go-playground/validator`
- HTML template rendering
- Excellent performance (~50K req/s benchmarks)

### When to Use
- Teams coming from Express/Fastify wanting familiar API
- Rapid development with built-in validation and binding
- Projects needing comprehensive middleware ecosystem

---

## 5. Echo

### Overview
High-performance, minimalist framework with clean API.

```go
e := echo.New()
e.GET("/users/:id", getUser)
e.POST("/users", createUser)

func getUser(c echo.Context) error {
    id := c.Param("id")
    return c.JSON(http.StatusOK, map[string]string{"id": id})
}
```

### Key Features
- Built-in middleware (CORS, JWT, Logger, Recover, Rate Limiter, Gzip)
- Data binding for JSON, XML, form, query params
- Auto TLS with Let's Encrypt
- HTTP/2 support
- OpenAPI integration via extensions
- Websocket support

### When to Use
- Feature-rich APIs needing built-in JWT, rate limiting
- Clean API preferred over Gin's context pattern
- Auto-TLS requirement

---

## 6. Fiber

### Overview
Express-inspired, built on **fasthttp** (not net/http). Fastest Go framework.

```go
app := fiber.New()
app.Get("/users/:id", func(c *fiber.Ctx) error {
    return c.JSON(fiber.Map{"id": c.Params("id")})
})
app.Listen(":3000")
```

### Key Features
- Built on fasthttp (2-3x faster than net/http for raw throughput)
- Express-like API (familiar to Node.js developers)
- Built-in rate limiting, CORS, CSRF, compression
- WebSocket support
- Template engines (Pug, Handlebars, Mustache)
- ~100K+ req/s in benchmarks

### Tradeoffs
- **fasthttp is not net/http compatible**: Won't work with net/http middleware or handlers
- Some Go ecosystem libraries assume net/http
- Community smaller than Gin

### When to Use
- Maximum HTTP throughput is the priority
- Team coming from Node.js/Express
- Benchmarks matter (edge proxies, API gateways)

---

## 7. Other Frameworks

### Chi
- **Lightweight router** compatible with net/http
- Composable middleware stack, route grouping, URL parameters
- Mounts standard `http.Handler` — works with all net/http middleware
- **Recommended**: Chi + stdlib is the Go-idiomatic choice for most APIs

### Connect-Go (Buf)
- Generate **gRPC-compatible APIs** from protobuf definitions
- Supports gRPC, gRPC-Web, AND a simpler Connect protocol (curl-friendly, HTTP/1.1 compatible)
- Type-safe, code-generated handlers and clients
- Part of the **Buf ecosystem** (buf build, buf lint, buf breaking)
- **When to use**: Service-to-service communication, need both gRPC and REST from same proto

### Fuego
- **Type-safe** framework with automatic OpenAPI generation from Go types
- Code-first: define handlers with typed request/response, get OpenAPI 3.1 spec
- Validation via struct tags
- **When to use**: When you want OpenAPI auto-generation without manual annotations

### Hertz (CloudWeGo/ByteDance)
- High-performance HTTP framework from ByteDance
- Built on Netpoll (event-driven networking library)
- Code generation from IDL (thrift/protobuf)
- **When to use**: Very high-throughput microservices, ByteDance ecosystem

---

## 8. API Patterns

### REST Best Practices in Go
- Use stdlib `encoding/json` or faster alternatives (`json-iterator/go`, `goccy/go-json`, `bytedance/sonic`)
- Validation: `go-playground/validator` with struct tags
- Error handling: consistent error response struct
- Middleware pattern: `func(next http.Handler) http.Handler`
- Context propagation: pass `context.Context` through the stack

### gRPC
- **grpc-go**: Official gRPC implementation
- Protocol Buffers for schema, code generation via `protoc-gen-go` and `protoc-gen-go-grpc`
- Streaming: unary, server, client, bidirectional
- Interceptors for auth, logging, tracing (equivalent to middleware)
- **Performance**: Go is one of the best gRPC runtimes

### GraphQL
- **gqlgen** (99designs): Code-first, generates resolver interfaces from schema. Type-safe. Most popular.
- Schema-first: write `.graphql` schema, gqlgen generates Go code
- DataLoader support for N+1 prevention
- Subscriptions via WebSocket

### OpenAPI
- **oapi-codegen**: Generate Go server/client from OpenAPI 3.0 spec (contract-first)
- **swaggo/swag**: Generate OpenAPI spec from code annotations (code-first)
- **Fuego**: Auto-generates OpenAPI from typed handlers (no annotations needed)
- **Recommendation**: oapi-codegen for contract-first, Fuego for code-first

---

## 9. Database Access

### database/sql (stdlib)
- Standard interface for SQL databases
- Connection pooling built-in (`SetMaxOpenConns`, `SetMaxIdleConns`, `SetConnMaxLifetime`)
- Drivers: `lib/pq` (Postgres), `go-sql-driver/mysql`, `mattn/go-sqlite3`
- Use `context.Context` variants: `QueryContext`, `ExecContext`

### pgx (PostgreSQL driver)
- **Recommended over lib/pq** for PostgreSQL
- Native PostgreSQL protocol (not database/sql wrapper, though it has a database/sql adapter)
- Connection pooling via `pgxpool`
- COPY protocol support, listen/notify, batch queries
- Better performance and more PostgreSQL-specific features than lib/pq

### sqlx
- Extension of database/sql with named parameters, struct scanning
- `sqlx.Get`, `sqlx.Select` for scanning rows into structs
- Named queries: `db.NamedExec("INSERT INTO users (name) VALUES (:name)", user)`
- No code generation — runtime reflection
- **When to use**: When you want more than raw database/sql but less than an ORM

### sqlc
- **Compile-time SQL**: Write SQL queries, sqlc generates type-safe Go code
- Zero runtime reflection — generated code is plain Go
- Supports PostgreSQL, MySQL, SQLite
- Schema from SQL migrations or `CREATE TABLE` statements
- **Recommended** for teams that prefer writing SQL directly
```sql
-- name: GetUser :one
SELECT * FROM users WHERE id = $1;
```
Generates:
```go
func (q *Queries) GetUser(ctx context.Context, id int64) (User, error)
```

### GORM
- Most popular Go ORM. Active Record pattern.
- Auto-migrations, associations, hooks, transactions, scopes
- Code-first: define Go structs, GORM creates/migrates tables
- **Tradeoffs**: Magic/implicit behavior (un-Go-like), performance overhead for complex queries
- **When to use**: Rapid development, teams from Active Record backgrounds

### Ent (Facebook/Meta)
- **Graph-based ORM** with code generation
- Define schema as Go code → generate type-safe CRUD, traversals, mutations
- Built-in support for edges (relationships), privacy policies, hooks
- GraphQL integration
- **When to use**: Complex data models with many relationships, projects needing graph traversals

### Database Migrations
- **goose**: SQL or Go migration files. Simple, reliable.
- **golang-migrate**: URL-based drivers, SQL migration files. Supports many databases.
- **Atlas**: Declarative schema management (HCL/SQL). Diff desired vs actual state.
- **GORM AutoMigrate**: For GORM projects (not recommended for production — use explicit migrations)

---

## 10. Concurrency Patterns

### Goroutines and Channels — Core Model
```go
// Fan-out: spawn N workers
results := make(chan Result, len(items))
for _, item := range items {
    go func(item Item) {
        results <- process(item)
    }(item)
}

// Collect results
for range items {
    result := <-results
    // handle result
}
```

### errgroup (golang.org/x/sync/errgroup)
- Goroutine group with error propagation and context cancellation
```go
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error { return fetchUser(ctx) })
g.Go(func() error { return fetchOrders(ctx) })
if err := g.Wait(); err != nil {
    // first error cancels context, all goroutines stop
}
```

### Worker Pool Pattern
```go
func workerPool(jobs <-chan Job, results chan<- Result, workers int) {
    var wg sync.WaitGroup
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                results <- process(job)
            }
        }()
    }
    wg.Wait()
    close(results)
}
```

### Context Propagation
- **Always pass `context.Context`** as the first parameter
- Use for: cancellation, timeouts, request-scoped values (trace ID, user ID)
- `context.WithTimeout(ctx, 5*time.Second)` for deadline propagation
- Never store contexts in structs

### Select for Multiplexing
```go
select {
case msg := <-msgCh:
    handle(msg)
case <-ctx.Done():
    return ctx.Err()
case <-time.After(5 * time.Second):
    return errors.New("timeout")
}
```

### sync Primitives
- `sync.Mutex` / `sync.RWMutex`: Traditional locks. RWMutex for read-heavy workloads.
- `sync.Once`: One-time initialization (singletons, config loading)
- `sync.Map`: Concurrent map (use sparingly — regular map + mutex is usually better)
- `sync.Pool`: Object pooling to reduce GC pressure (HTTP request buffers, JSON encoders)
- `sync.WaitGroup`: Wait for goroutine completion
- `atomic` package: Lock-free atomic operations for counters and flags

### Singleflight (golang.org/x/sync/singleflight)
- Deduplicate concurrent identical requests
```go
var g singleflight.Group
result, err, _ := g.Do(cacheKey, func() (interface{}, error) {
    return fetchFromDB(cacheKey) // only one goroutine executes this
})
```
Critical for: cache stampede prevention, deduplicating expensive computations

---

## 11. Dependency Injection

### Go Community Preference: Manual DI
Most Go projects use **manual dependency injection** via constructor functions:
```go
type UserService struct {
    repo UserRepository
    cache Cache
}

func NewUserService(repo UserRepository, cache Cache) *UserService {
    return &UserService{repo: repo, cache: cache}
}
```

This is the Go-idiomatic approach. Advantages: explicit, no magic, easy to understand and test.

### Wire (Google)
- Compile-time DI code generation
- Define "provider" functions, Wire generates the wiring code
- No runtime reflection
- **When to use**: Large projects with many dependencies where manual wiring is tedious

### fx (Uber)
- Runtime DI container based on reflection
- `fx.Provide`, `fx.Invoke`, lifecycle hooks
- **When to use**: Large applications with complex dependency graphs, Uber-style microservices

### Recommendation
Start with manual DI. Move to Wire only when constructor chains become unmanageable (50+ dependencies). Avoid fx unless you specifically need runtime flexibility.

---

## 12. Messaging

### Kafka
- **sarama** (Shopify): Most mature Go Kafka client. Producer, consumer, consumer groups, admin.
- **confluent-kafka-go**: Official Confluent wrapper around librdkafka (C). Highest performance but CGO dependency.
- **franz-go**: Pure Go, modern API. No CGO. Excellent performance. Growing adoption.
- **Recommendation**: franz-go for new projects (pure Go, fast, modern API). sarama for mature ecosystem.

### NATS
- **nats.go**: Official client. Extremely fast pub/sub, request-reply.
- JetStream for persistent messaging, KV store, object store.
- **When to use**: Lightweight service-to-service messaging, real-time systems.

### RabbitMQ
- **amqp091-go**: Standard AMQP client (successor to streadway/amqp)
- Exchanges, queues, bindings, dead letter exchanges

### Watermill
- **Event-driven framework** for Go
- Abstracts message broker (Kafka, NATS, RabbitMQ, Google Pub/Sub, AMQP)
- Middleware pattern for message processing
- Router for message routing
- **When to use**: Event-driven architectures where you want broker abstraction

---

## 13. Testing

### Standard Library (`testing`)
- `go test` built into the toolchain
- **Table-driven tests** (Go idiom):
```go
tests := []struct {
    name    string
    input   int
    want    int
}{
    {"positive", 5, 25},
    {"zero", 0, 0},
    {"negative", -3, 9},
}
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got := Square(tt.input)
        if got != tt.want {
            t.Errorf("Square(%d) = %d, want %d", tt.input, got, tt.want)
        }
    })
}
```

### Built-in Fuzzing (Go 1.18+)
```go
func FuzzParseJSON(f *testing.F) {
    f.Add([]byte(`{"name": "test"}`))
    f.Fuzz(func(t *testing.T, data []byte) {
        var result map[string]any
        json.Unmarshal(data, &result) // find panics/crashes
    })
}
```

### Testing Libraries
- **testify**: Assertions (`assert.Equal`), mocks, suite. Most popular.
- **gomock/mockgen**: Interface-based mock generation (Google). Code-generated mocks.
- **testcontainers-go**: Real Docker containers in tests. PostgreSQL, Redis, Kafka modules.
- **httptest** (stdlib): Test HTTP handlers without starting a server.
- **go-cmp**: Deep equality comparison (Google). Better diff output than reflect.DeepEqual.

### HTTP Handler Testing
```go
func TestGetUser(t *testing.T) {
    req := httptest.NewRequest("GET", "/users/123", nil)
    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)
    assert.Equal(t, 200, w.Code)
}
```

---

## 14. Observability

### Structured Logging: slog (stdlib, Go 1.21+)
```go
logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
logger.Info("user created", "user_id", 123, "email", "alice@test.com")
// {"time":"...","level":"INFO","msg":"user created","user_id":123,"email":"alice@test.com"}
```
- Built into stdlib, no external dependency
- Handlers: TextHandler (human), JSONHandler (machine)
- Groups and attributes for structured context
- Custom handlers for any output format

### Alternatives
- **zerolog**: Zero-allocation JSON logger. Fastest Go logger.
- **zap** (Uber): Structured, leveled logging. High performance. Widely adopted.
- **Recommendation**: slog for new projects (stdlib, good enough). zerolog for maximum performance.

### OpenTelemetry Go
- `go.opentelemetry.io/otel`: SDK for traces, metrics, logs
- Auto-instrumentation for net/http, gRPC, database/sql
- OTLP exporters to Jaeger, Tempo, Prometheus
- Context-based trace propagation

### Prometheus
- `prometheus/client_golang`: Official client
- `promhttp.Handler()` for `/metrics` endpoint
- Counter, Gauge, Histogram, Summary metric types
- Go runtime metrics (goroutines, GC, memory) built-in

### Recommended Stack
- **Logging**: slog (stdlib) → Loki → Grafana
- **Tracing**: OpenTelemetry → Tempo/Jaeger → Grafana
- **Metrics**: Prometheus client → Prometheus → Grafana

---

## 15. Deployment

### Tiny Docker Images
Go's killer feature for deployment: static binary, no runtime needed.

```dockerfile
# Build stage
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /server ./cmd/server

# Production: scratch image (ZERO base OS)
FROM scratch
COPY --from=builder /server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/server"]
```

**Image sizes:**
- `FROM scratch`: ~5-15 MB (just your binary + TLS certs)
- `FROM gcr.io/distroless/static`: ~2 MB base + your binary
- `FROM alpine`: ~5 MB base + your binary
- Compare: Java ~200-500 MB, Node.js ~150-300 MB, Python ~100-200 MB

### Cross-Compilation
```bash
GOOS=linux GOARCH=amd64 go build -o server-linux
GOOS=darwin GOARCH=arm64 go build -o server-mac
GOOS=windows GOARCH=amd64 go build -o server.exe
```
No cross-compiler toolchain needed. Built into `go build`.

### CGO Considerations
- `CGO_ENABLED=0`: Pure Go, static binary, cross-compilation works. **Preferred.**
- `CGO_ENABLED=1`: Needed for some libraries (SQLite via `mattn/go-sqlite3`, confluent-kafka-go). Requires C compiler, complicates Docker builds.
- **Recommendation**: Avoid CGO when possible. Use pure Go alternatives (e.g., `modernc.org/sqlite` instead of `mattn/go-sqlite3`, `franz-go` instead of `confluent-kafka-go`).

### Single Binary Deployment
- No package manager, no runtime, no interpreter
- Copy binary to server, run it. That's deployment.
- Systemd service file or Docker container — both trivial

---

## 16. Performance

### Why Go is Fast
- **Compiled to native code**: No JIT warmup, no interpreter overhead
- **Goroutines**: M:N scheduling, ~2 KB per goroutine (vs ~1 MB per OS thread)
- **Garbage collection**: Sub-millisecond pauses (Go 1.19+ with GOMEMLIMIT)
- **No runtime overhead**: No virtual machine, no reflection at runtime (by convention)
- **Efficient memory layout**: Value types, no boxing, struct embedding

### GC Tuning
- **GOGC** (default 100): Controls GC frequency. `GOGC=50` = more frequent GC, less memory. `GOGC=200` = less frequent, more throughput.
- **GOMEMLIMIT** (Go 1.19+): Soft memory limit. `GOMEMLIMIT=1GiB`. GC adjusts frequency to stay within limit. **Recommended over GOGC tuning** in containers.
- **GODEBUG=gctrace=1**: Print GC statistics

### Profiling (pprof)
```go
import _ "net/http/pprof"
go http.ListenAndServe(":6060", nil)
```
Then: `go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30`

**Profile types:**
- CPU profile: where time is spent
- Heap profile: memory allocations
- Goroutine profile: goroutine stacks (find goroutine leaks)
- Block profile: where goroutines block on synchronization
- Mutex profile: mutex contention

### Benchmarking
```go
func BenchmarkParse(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Parse(testData)
    }
}
```
`go test -bench=. -benchmem` — shows allocations per operation.

### Performance Tips
- Use `sync.Pool` for frequently allocated objects (JSON encoders, buffers)
- Preallocate slices: `make([]T, 0, expectedSize)`
- Avoid unnecessary allocations in hot paths (escape analysis: `go build -gcflags="-m"`)
- Use `strings.Builder` for string concatenation
- Profile before optimizing — `pprof` is your friend

---

## 17. When Go Shines

### High-Concurrency Services
Goroutines make handling 100K+ concurrent connections trivial. No thread pool tuning, no async/await ceremony.

### Infrastructure and DevOps Tooling
Docker, Kubernetes, Terraform, Prometheus, Grafana agents — all written in Go. The ecosystem is Go-native.

### CLI Tools
Single binary distribution, fast startup, cross-compilation. cobra (CLI framework) + viper (config) is the standard stack.

### API Gateways and Proxies
Envoy's control plane, Traefik, Caddy — all Go. High throughput with minimal resource usage.

### Kubernetes Operators
client-go, controller-runtime, kubebuilder — the K8s operator ecosystem is Go-first.

### Microservices
Tiny Docker images (5-15 MB), fast startup (<100ms), low memory usage (~10-30 MB per service). Perfect for containerized microservices.

### Where Go is NOT Best
- **Complex business logic with deep domain models**: Java/C# have better OOP support
- **Rapid prototyping with many integrations**: Python/TypeScript are faster to iterate
- **Frontend-backend shared types**: TypeScript (tRPC) wins
- **ML/AI backends**: Python owns the ML ecosystem
- **Admin panel / CRUD apps**: Django (Python) or Rails (Ruby) are faster to ship

---

## Recommended Stack (2025-2026)

| Layer | Recommended | Alternative |
|-------|------------|-------------|
| Go version | 1.24 (latest) | 1.22+ (minimum for new routing) |
| Router/Framework | net/http + Chi (Go-idiomatic) | Gin (familiar), Fiber (max throughput) |
| gRPC | Connect-Go (Buf) | grpc-go (official) |
| Database driver | pgx (PostgreSQL) | database/sql + driver |
| Query layer | sqlc (compile-time SQL) | sqlx (runtime), GORM (ORM) |
| Migrations | goose or golang-migrate | Atlas (declarative) |
| Logging | slog (stdlib) | zerolog, zap |
| Messaging | franz-go (Kafka), nats.go (NATS) | sarama, Watermill |
| Testing | stdlib + testify + testcontainers | gomock |
| Observability | OpenTelemetry + Prometheus | slog + pprof |
| DI | Manual (constructor injection) | Wire (large projects) |
| Docker | FROM scratch or distroless | Alpine |
