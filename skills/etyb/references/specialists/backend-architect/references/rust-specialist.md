# Rust Backend Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features before giving advice. This reference provides architectural context; the Rust ecosystem evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [Modern Rust for Backends](#1-modern-rust-for-backends)
2. [Framework Decision Matrix](#2-framework-decision-matrix)
3. [Axum](#3-axum)
4. [Actix Web](#4-actix-web)
5. [Tokio Runtime](#5-tokio-runtime)
6. [Error Handling](#6-error-handling)
7. [Serialization](#7-serialization)
8. [Database Access](#8-database-access)
9. [Authentication](#9-authentication)
10. [gRPC with Tonic](#10-grpc-with-tonic)
11. [Async Patterns](#11-async-patterns)
12. [Testing](#12-testing)
13. [Observability](#13-observability)
14. [Deployment](#14-deployment)
15. [Cargo Workspaces for Microservices](#15-cargo-workspaces-for-microservices)
16. [When Rust Is the Right Choice](#16-when-rust-is-the-right-choice)

---

## 1. Modern Rust for Backends

### Why Rust for Backend Services

Rust brings a unique value proposition to backend development:

- **Memory safety without GC**: No garbage collector pauses — predictable p99 latency
- **Zero-cost abstractions**: High-level patterns compile to efficient machine code
- **Fearless concurrency**: The type system prevents data races at compile time
- **Small binaries**: Deploy from `scratch` Docker images (~5-10MB)
- **Low resource usage**: 2-4x less memory than equivalent Go services, no JVM overhead

### Key Language Features for Backends

- **Enums with data** (algebraic types): Model domain states precisely — `enum OrderStatus { Pending, Paid { tx_id: String }, Shipped { tracking: String } }`
- **Pattern matching**: Exhaustive matching ensures all cases handled
- **Traits**: Define shared behavior (like interfaces, but more powerful with associated types, default implementations)
- **Lifetimes**: Compiler-enforced memory safety without runtime cost
- **`?` operator**: Ergonomic error propagation — `let user = db.get_user(id).await?;`
- **Async/await**: Native async with zero-cost futures (no hidden allocations)

### Rust Edition 2024

The latest edition (Rust 2024) with MSRV ~1.85+ brings:
- Refined `unsafe` ergonomics — `unsafe_op_in_unsafe_fn` lint enabled by default
- Improved lifetime elision rules
- Stabilized `async fn` in traits (critical for middleware and service abstractions)
- `gen` blocks for iterator generators

---

## 2. Framework Decision Matrix

| Factor | Axum | Actix Web | Rocket |
|--------|------|-----------|--------|
| **Latest version** | 0.8.x | 4.12.x | 0.5.x |
| **Paradigm** | Functional, Tower-based | Actor model (optional) | Macro-heavy, opinionated |
| **Performance** | Excellent | Highest raw throughput | Good |
| **Tower compatibility** | Native (built on Tower) | Separate integration | Limited |
| **Learning curve** | Moderate | Moderate-High | Low (most ergonomic) |
| **Community momentum** | Fastest growing | Mature, stable | Smaller, slower releases |
| **Async runtime** | Tokio (required) | Tokio (default), can use others | Tokio |
| **Best for** | New projects, microservices | Max throughput, existing codebases | Prototypes, smaller APIs |

**Default recommendation for 2026**: Axum for new projects — simplest mental model, best Tower ecosystem integration, fastest-growing community. Choose Actix Web when raw throughput is the decisive factor (10-15% edge over Axum in benchmarks). Choose Rocket for rapid prototyping where ergonomics matter more than flexibility.

---

## 3. Axum

### Overview (v0.8.x)

Axum is the HTTP framework from the Tokio team. It doesn't have its own middleware system — it uses Tower services directly, giving you access to the entire Tower ecosystem.

**Key changes in 0.8:**
- Path parameter syntax: `/{param}` and `/{*wildcard}` (changed from `/:param` and `/*wildcard`)
- WebSocket over HTTP/2 support
- `method_not_allowed_fallback` for handling matched paths with wrong HTTP method
- Improved compiler diagnostics for handler trait bound errors
- `ws::Message` uses `Bytes` and `Utf8Bytes` (not `Vec<u8>` and `String`)

### Extractors

Extractors implement `FromRequest` or `FromRequestParts` — type-checked request parsing at compile time:

```rust
async fn create_user(
    State(db): State<DbPool>,           // Application state
    Json(payload): Json<CreateUser>,     // JSON body → struct
) -> Result<Json<User>, AppError> {
    let user = db.insert_user(payload).await?;
    Ok(Json(user))
}

async fn get_user(
    Path(id): Path<Uuid>,               // URL path parameter
    Query(params): Query<Pagination>,   // Query string parameters
) -> Result<Json<User>, AppError> { ... }
```

Built-in extractors: `Json<T>`, `Query<T>`, `Path<T>`, `State<T>`, `Form<T>`, `Multipart`, `Extension<T>`, `HeaderMap`, `ConnectInfo`, `MatchedPath`

Community extractors: `axum-jsonschema` (JSON schema validation), `axum-typed-multipart` (type-safe file uploads), `axum-extra` (cookie jar, typed headers, form with multi-value support)

### State Management

```rust
#[derive(Clone)]
struct AppState {
    db: PgPool,
    redis: RedisPool,
    config: Arc<Config>,
}

// Extract sub-states using FromRef
impl FromRef<AppState> for PgPool {
    fn from_ref(state: &AppState) -> Self { state.db.clone() }
}

let app = Router::new()
    .route("/users", post(create_user))
    .with_state(AppState { db, redis, config });
```

- `State<T>` is the recommended approach (faster, more type-safe than `Extension`)
- Use `FromRef` to extract sub-states from a larger `AppState`
- Shared mutable state: `Arc<RwLock<T>>` or `Arc<Mutex<T>>`

### Middleware (Tower)

Axum uses Tower directly — no bespoke middleware system:

```rust
use tower_http::{trace::TraceLayer, compression::CompressionLayer, cors::CorsLayer};

let app = Router::new()
    .route("/api/users", get(list_users))
    .layer(TraceLayer::new_for_http())       // Logging/tracing
    .layer(CompressionLayer::new())           // Response compression
    .layer(CorsLayer::permissive())           // CORS
    .layer(TimeoutLayer::new(Duration::from_secs(30)));  // Request timeout
```

Custom middleware via `axum::middleware::from_fn`:

```rust
async fn auth_middleware(
    State(state): State<AppState>,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    let token = request.headers().get("Authorization")
        .ok_or(StatusCode::UNAUTHORIZED)?;
    // Validate token...
    Ok(next.run(request).await)
}

app.layer(middleware::from_fn_with_state(state, auth_middleware))
```

Layers wrap bottom-to-top: last `.layer()` call is the outermost middleware.

### Error Handling Pattern

```rust
enum AppError {
    NotFound(String),
    Validation(Vec<String>),
    Unauthorized,
    Internal(anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, body) = match self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, json!({"error": msg})),
            AppError::Validation(errs) => (StatusCode::BAD_REQUEST, json!({"errors": errs})),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, json!({"error": "unauthorized"})),
            AppError::Internal(err) => {
                tracing::error!(?err, "internal error");
                (StatusCode::INTERNAL_SERVER_ERROR, json!({"error": "internal server error"}))
            }
        };
        (status, Json(body)).into_response()
    }
}

// Automatic conversion from anyhow errors
impl From<anyhow::Error> for AppError {
    fn from(err: anyhow::Error) -> Self { AppError::Internal(err) }
}
```

---

## 4. Actix Web

### Overview (v4.12.x)

Actix Web is the highest-throughput Rust web framework, built on the actor model (though actors are optional for typical handler patterns).

**When to choose Actix Web over Axum:**
- Raw throughput is the decisive factor (~10-15% more RPS under heavy load)
- Existing Actix codebase
- Need the actor model for stateful concurrent processing

**When Axum is better:**
- New projects (simpler mental model, standard Rust patterns)
- Tower ecosystem integration
- Growing faster in community adoption and library support
- Easier onboarding for new developers

### Key Patterns

```rust
use actix_web::{web, App, HttpServer, HttpResponse};

async fn get_user(path: web::Path<Uuid>, db: web::Data<PgPool>) -> HttpResponse {
    match db.get_user(path.into_inner()).await {
        Ok(user) => HttpResponse::Ok().json(user),
        Err(_) => HttpResponse::NotFound().finish(),
    }
}

HttpServer::new(move || {
    App::new()
        .app_data(web::Data::new(db_pool.clone()))
        .service(web::resource("/users/{id}").route(web::get().to(get_user)))
})
.bind("0.0.0.0:8080")?
.run()
.await
```

---

## 5. Tokio Runtime

### Current State (v1.51.x LTS)

Tokio is the async runtime for Rust. Two LTS branches:
- **1.47.x** — supported until September 2026
- **1.51.x** — supported until March 2027

### Task Management

**JoinSet** (recommended for dynamic task collections):
```rust
let mut set = JoinSet::new();
for url in urls {
    set.spawn(async move { fetch(url).await });
}
while let Some(result) = set.join_next().await {
    handle(result??);
}
```

**TaskTracker** (for graceful shutdown):
```rust
let tracker = TaskTracker::new();
tracker.spawn(async { long_running_task().await });
// On shutdown:
tracker.close();
tracker.wait().await; // Wait for all tracked tasks
```

**`select!`** (multiplexing futures):
```rust
tokio::select! {
    msg = rx.recv() => handle_message(msg),
    _ = shutdown.recv() => return,
    _ = tokio::time::sleep(timeout) => handle_timeout(),
}
```
Budget-aware as of Tokio 1.44 (cooperatively yields). Compile-time limit: 64 branches. For variable-sized collections, use `JoinSet` or `FuturesUnordered`.

### io_uring Support

Via `tokio-uring` crate (~0.4.x+) — requires Linux kernel 5.10+:
- Truly async filesystem operations (unlike `tokio::fs` which uses thread pool)
- Uses `current_thread` Tokio runtime with io_uring driver
- Best for high-IOPS workloads (databases, file-heavy services)
- Still maturing — use for specific I/O-heavy paths, not as default runtime

---

## 6. Error Handling

### The Standard Stack

| Crate | Use Case | Version |
|-------|----------|---------|
| **thiserror** | Libraries — typed error enums with `#[derive(Error)]` | 2.0.x |
| **anyhow** | Applications — wrap any error with `.context()` | 1.x |
| **color-eyre** | CLI/production — beautiful error reports with backtraces | Latest |

### Production Pattern

```rust
// In your library/domain crate — thiserror for typed errors
#[derive(Debug, thiserror::Error)]
enum DomainError {
    #[error("user {0} not found")]
    UserNotFound(Uuid),
    #[error("invalid email: {0}")]
    InvalidEmail(String),
    #[error("database error")]
    Database(#[from] sqlx::Error),
}

// In your application/handler layer — anyhow for aggregation
async fn handler() -> Result<Json<User>, AppError> {
    let user = find_user(id).await
        .context("failed to find user for profile page")?;
    Ok(Json(user))
}
```

**thiserror 2.0** breaking changes: raw identifiers in format strings no longer accepted. Supports `#[no_std]`.

**miette**: For CLI tools — provides beautiful error diagnostics with source code snippets and help text.

---

## 7. Serialization

### serde (The Foundation)

Serde is the universal serialization framework. `#[derive(Serialize, Deserialize)]` on any struct/enum.

```rust
#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct CreateUser {
    full_name: String,
    email: String,
    #[serde(default)]
    role: UserRole,
    #[serde(skip_serializing_if = "Option::is_none")]
    avatar_url: Option<String>,
}
```

### JSON (`serde_json`)

- `serde_json::Value` for dynamic JSON
- `serde_json::from_str`, `serde_json::to_string` for parsing/emission
- Axum `Json<T>` extractor handles this automatically

### Form Handling (Axum)

- `axum::Form<T>` — `application/x-www-form-urlencoded` (T must be `Deserialize`)
- `axum::extract::Multipart` — `multipart/form-data` (2MB default, configurable via `DefaultBodyLimit`)
- `axum_extra::extract::Form<T>` — multi-value support (checkboxes, multi-select) via `serde_html_form`

### Protocol Buffers

- **prost**: The standard protobuf implementation for Rust (used by Tonic for gRPC)
- **buffa** (by Anthropic): Pure Rust protobuf with binary, JSON, and text encodings, plus optional serde integration

---

## 8. Database Access

### Decision Matrix

| Factor | SQLx | Diesel | SeaORM |
|--------|------|--------|--------|
| **Version** | 0.8.6 | 2.3.6 | 2.0 |
| **Paradigm** | Raw SQL with compile-time checking | Type-safe query builder (ORM) | ActiveRecord pattern (ORM) |
| **Async** | Native | Via `diesel-async` (0.5.x) | Native (built on SQLx) |
| **Query style** | Write SQL, compiler verifies types | Rust DSL, no SQL written | Entity methods + query builder |
| **Compile-time safety** | Checks queries against real DB | Full type-system enforcement | Partial |
| **Learning curve** | Low (know SQL, know SQLx) | Medium-High | Low (familiar to Rails/Django devs) |
| **Best for** | Teams that think in SQL | Maximum compile-time guarantees | Rapid development, familiar patterns |

### SQLx (Recommended Default)

```rust
// Compile-time checked query — connects to dev DB at compile time
let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
    .fetch_one(&pool)
    .await?;

// Offline mode for CI/CD (no DB needed):
// cargo sqlx prepare  → generates .sqlx/ metadata directory
```

- Pure Rust drivers for PostgreSQL, MySQL, SQLite (zero unsafe in Postgres/MySQL drivers)
- Migrations: `sqlx::migrate!()` macro embeds migrations in binary
- Supports PostgreSQL, MySQL/MariaDB, SQLite

### SeaORM 2.0 (January 2026)

Major rewrite with significant improvements:
- New denser Entity Format — less boilerplate
- Entity-first workflow: write entities, generate tables/foreign keys
- Entity Loader solves N+1 problem (batch-loading related entities)
- 20% faster query building
- `raw_sql!` macro with SQL injection protection
- Built-in RBAC via `RestrictedConnection`

### Connection Pooling

| Pool | Version | Notes |
|------|---------|-------|
| **deadpool** | 0.10 / deadpool-postgres 0.12 | Simpler config, file-based configuration |
| **bb8** | 0.8 / bb8-postgres 0.8 | More flexibility for custom connection types |

Both integrate with Tokio and handle thousands of concurrent DB operations.

---

## 9. Authentication

### JWT — `jsonwebtoken` (v10)

```rust
use jsonwebtoken::{encode, decode, Header, Algorithm, Validation, EncodingKey, DecodingKey};

#[derive(Serialize, Deserialize)]
struct Claims {
    sub: String,
    exp: usize,
    role: String,
}

// Encode
let token = encode(
    &Header::new(Algorithm::ES256),
    &claims,
    &EncodingKey::from_ec_pem(private_key)?,
)?;

// Decode
let data = decode::<Claims>(
    &token,
    &DecodingKey::from_ec_pem(public_key)?,
    &Validation::new(Algorithm::ES256),
)?;
```

Supports: HS256/384/512, RS256/384/512, ES256/384, PS256/384/512, EdDSA. Two crypto backends: `aws_lc_rs` and `rust_crypto`.

### Password Hashing

- **argon2** (0.5.x): Pure Rust — Argon2id is the recommended default
- **bcrypt**: Work factor 10+, 72-byte password limit
- Both from the RustCrypto/password-hashes ecosystem

### Session Management

- **tower-sessions**: Sessions as Tower/Axum middleware, key-value interface with native Rust types, manifests as cookies
- **axum-login**: Built on tower-sessions — `AuthSession` extractor, `login_required!` and `permission_required!` macros for route protection

---

## 10. gRPC with Tonic

### Overview (v0.14.x)

Tonic is the native gRPC client/server implementation, built on Tokio, Hyper, and Tower.

```protobuf
// proto/user.proto
service UserService {
    rpc GetUser (GetUserRequest) returns (User);
    rpc ListUsers (ListUsersRequest) returns (stream User);
}
```

```rust
// build.rs
tonic_build::compile_protos("proto/user.proto")?;

// Server implementation
#[tonic::async_trait]
impl UserService for MyUserService {
    async fn get_user(&self, req: Request<GetUserRequest>) -> Result<Response<User>, Status> {
        let user = self.db.find(req.into_inner().id).await
            .map_err(|e| Status::not_found(e.to_string()))?;
        Ok(Response::new(user))
    }
}
```

- Full HTTP/2, unidirectional and bidirectional streaming
- Load balancing, TLS, timeouts, async interceptors (since 0.5.7)
- **prost** generates Rust code from `.proto` files via `tonic-build`

---

## 11. Async Patterns

### Channels (`tokio::sync`)

| Channel | Pattern | Backpressure |
|---------|---------|-------------|
| `mpsc` (bounded) | Multi-producer, single-consumer | Yes — sender awaits when full |
| `mpsc` (unbounded) | Multi-producer, single-consumer | No — can grow without limit |
| `oneshot` | Single value, request/response | N/A |
| `broadcast` | Multi-producer, multi-consumer | Configurable capacity |
| `watch` | Single-producer, latest-value | N/A (readers get latest) |

### Backpressure Pattern

Bounded `mpsc` channels are the primary backpressure mechanism:
```rust
let (tx, mut rx) = mpsc::channel(100); // Buffer of 100

// Producer — blocks when buffer full
tx.send(work_item).await?;

// Consumer — processes at its own pace
while let Some(item) = rx.recv().await {
    process(item).await;
}
```

### Actor-Like Pattern (Without Framework)

```rust
struct DbActor { rx: mpsc::Receiver<DbCommand>, pool: PgPool }

impl DbActor {
    async fn run(mut self) {
        while let Some(cmd) = self.rx.recv().await {
            match cmd {
                DbCommand::GetUser { id, reply } => {
                    let result = self.pool.get_user(id).await;
                    let _ = reply.send(result);
                }
            }
        }
    }
}
```

---

## 12. Testing

### Integration Testing with Testcontainers

```rust
use testcontainers::runners::AsyncRunner;
use testcontainers_modules::postgres::Postgres;

#[tokio::test]
async fn test_user_creation() {
    let container = Postgres::default().start().await.unwrap();
    let pool = PgPool::connect(&container.connection_string()).await.unwrap();
    sqlx::migrate!().run(&pool).await.unwrap();

    let user = create_user(&pool, "test@example.com").await.unwrap();
    assert_eq!(user.email, "test@example.com");
}
```

- Spins up real Docker containers per test (PostgreSQL, Redis, Kafka)
- Parallel test execution is safe — each test gets isolated environment
- Catches real integration issues: SQL syntax, constraints, transactions

### Unit Testing with mockall

```rust
#[automock]
trait UserRepository {
    async fn find_by_id(&self, id: Uuid) -> Result<User>;
}

#[tokio::test]
async fn test_get_user_handler() {
    let mut mock = MockUserRepository::new();
    mock.expect_find_by_id()
        .with(eq(user_id))
        .returning(|_| Ok(test_user()));

    let result = get_user_handler(&mock, user_id).await;
    assert!(result.is_ok());
}
```

### HTTP Integration Testing

```rust
#[tokio::test]
async fn test_api_endpoint() {
    let app = create_app(test_state()).await;
    let response = app
        .oneshot(Request::builder().uri("/api/users").body(Body::empty()).unwrap())
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::OK);
}
```

---

## 13. Observability

### tracing (Core)

The `tracing` crate provides structured, span-based diagnostics:

```rust
#[tracing::instrument(skip(db))]
async fn get_user(db: &PgPool, id: Uuid) -> Result<User> {
    tracing::info!(%id, "fetching user");
    let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
        .fetch_one(db)
        .await?;
    tracing::debug!(email = %user.email, "user found");
    Ok(user)
}
```

- `#[instrument]` auto-creates spans with function arguments
- `tracing-subscriber` with `FmtSubscriber` for console output
- JSON structured logging via JSON layer
- `env_logger`-style filtering: `RUST_LOG=my_app=debug,tower_http=trace`

### OpenTelemetry (v0.30.0)

- Logs and Metrics: **stable**
- Traces: **beta**
- `tracing-opentelemetry` bridge: code uses `tracing`, ops gets OTel-compatible telemetry
- Exporters: OTLP (Jaeger, Tempo, Grafana), Zipkin, Prometheus

### Metrics

- `metrics` crate + `metrics-exporter-prometheus` for Prometheus integration
- `axum-prometheus` for per-route HTTP metrics

---

## 14. Deployment

### Docker Multi-Stage Builds

```dockerfile
# Build stage
FROM rust:1.85 AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

# Runtime — scratch for minimal image (~5-10MB)
FROM scratch
COPY --from=builder /app/target/release/my-service /
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["/my-service"]
```

| Base Image | Size | Debugging | Security |
|------------|------|-----------|----------|
| `scratch` | ~5-10MB | None (no shell) | Highest (minimal attack surface) |
| `distroless/cc` | ~28MB | Minimal | High |
| `alpine` | ~40-60MB | Full shell | Good |

### Binary Size Optimization

In `Cargo.toml`:
```toml
[profile.release]
strip = true          # Strip debug symbols (10-20% reduction)
opt-level = "z"       # Optimize for size (vs "3" for speed)
lto = true            # Link-time optimization
codegen-units = 1     # Better optimization, slower compile
panic = "abort"       # Smaller binary (no unwinding support)
```

### Cross-Compilation

- **cargo-zigbuild**: Uses Zig's bundled C compiler — easy musl cross-compilation, 5-10x faster Docker builds
- **cross** (cross-rs): Docker-based cross-compilation, drop-in Cargo replacement
- Common targets: `x86_64-unknown-linux-musl`, `aarch64-unknown-linux-musl`

---

## 15. Cargo Workspaces for Microservices

```
Cargo.toml                    # [workspace] root
crates/
  common/                     # Shared types, error types, middleware
  proto/                      # Protobuf definitions (generated code)
  user-service/               # Binary crate
  order-service/              # Binary crate
  notification-service/       # Binary crate
```

### Workspace Dependencies (DRY)

```toml
# Root Cargo.toml
[workspace]
members = ["crates/*"]

[workspace.dependencies]
tokio = { version = "1.51", features = ["full"] }
axum = "0.8"
sqlx = { version = "0.8", features = ["postgres", "runtime-tokio"] }
serde = { version = "1", features = ["derive"] }
tracing = "0.1"
```

```toml
# crates/user-service/Cargo.toml
[dependencies]
tokio = { workspace = true }
axum = { workspace = true }
common = { path = "../common" }
```

- All members get exact same dependency versions — prevents conflicts
- Single `target/` directory — shared compilation outputs
- 40-60% build time reduction vs separate repositories
- `cargo-autoinherit` tool auto-migrates existing dependencies to workspace format

---

## 16. When Rust Is the Right Choice

### Choose Rust When

- **Maximum performance with safety**: Finance, blockchain, edge computing, gaming backends
- **Predictable latency**: No GC pauses — real-time systems, game servers, trading platforms
- **Infrastructure software**: Proxies (Cloudflare Pingora), databases, runtimes, search engines
- **Memory-constrained environments**: IoT, embedded, edge devices
- **Long-running services**: Safety and reliability compound over time
- **WebAssembly targets**: Rust has the most mature Wasm toolchain

### Do NOT Choose Rust When

- **Rapid prototyping / MVPs**: The compiler slows early development — use Python/TypeScript/Go
- **CRUD-heavy apps**: No performance constraints? Go/Java/Node are faster to ship
- **Small team without Rust experience**: Steep learning curve, expensive mentoring
- **ML/data science backends**: Python ecosystem is unmatched
- **Fast time-to-market**: Go compiles faster, hires easier, ships sooner

### Real-World Adoption

| Company | Use Case |
|---------|----------|
| **Cloudflare** | Pingora proxy (replaced NGINX), Workers runtime |
| **Discord** | Read States service (rewrote from Go — eliminated GC pauses), scales to 11M+ concurrent users |
| **AWS** | Firecracker VMM (powers Lambda and Fargate) |
| **Figma** | Multiplayer syncing engine (rewrote from TypeScript) |
| **Dropbox** | File metadata indexing, synchronization, live collaboration |
| **1Password** | ~70% of desktop app, Brain engine ported from Go for Wasm |
| **Google** | Android, ChromeOS, Fuchsia components |
| **Linux Kernel** | Rust for Linux — driver development |
| **Vercel** | Turborepo and Turbopack |

### Rust + Go: The Complementary Pattern

Many organizations use both:
- **Rust** for performance-critical services (proxies, data processing, hot paths)
- **Go** for standard-throughput services (CRUD APIs, orchestration, tooling)
- Shared via gRPC or message queues

This avoids forcing Rust's learning curve on every service while using it where it delivers outsized value.
