---
role: backend-architect
stack: azure
last_verified_on: "2026-05-14"
---

# Azure — backend-architect overlay

You're writing the application code that runs on Azure. .NET / Java / Node.js / Python / Go service that exposes an API, processes messages, integrates with Azure services. This overlay tells you what 2026 Azure expects: which compute model, which SDK, which auth pattern, which messaging idiom, which gotchas will bite you in production.

You're not the architect (system-architect picks topology) or the platform owner (devops-engineer writes Bicep) — you write the service, hook it to Azure services correctly, and survive the platform's quirks.

## What this role does on Azure

- Picks the **runtime** (.NET 8/9/10, Java 17/21, Node 20+, Python 3.11+, Go) and **target SDK** for each Azure service you integrate with.
- Writes the **HTTP / gRPC / event-driven** API surface and wires it to the chosen compute (App Service / Container Apps / Functions / AKS).
- Implements **Managed Identity** authentication for every Azure service call.
- Designs **idempotent message handlers** for Service Bus / Event Grid / Event Hubs.
- Owns the **.NET Aspire** orchestration story (when applicable) — service composition, local dev, OpenTelemetry wiring.
- Implements **Dapr** building blocks when on Container Apps with managed Dapr sidecar.
- Manages the **Cosmos DB / Azure SQL / PostgreSQL SDK usage** — pooling, retry, partition-aware queries.
- Handles **graceful shutdown** + **scale-to-zero** correctness for serverless compute.
- Owns the **in-process → isolated worker migration** for any legacy Azure Functions code.

## Decision frameworks

### .NET / Java / Node / Python — runtime selection on Azure

Azure has no opinion on language, but compute models have edges:

| Runtime | Best fit | Watch out for |
|---------|----------|---------------|
| **.NET 8 / .NET 9 / .NET 10** | Functions (isolated worker), Container Apps, App Service, AKS | .NET 10 Native AOT changes Functions cold-start economics (<50ms startup, 60-80% memory reduction); in-process .NET retired late 2026 |
| **.NET Aspire** | Distributed app composition + local dev + OTel | Aspire deploys to Container Apps by default; Functions-on-Aspire skips event-driven scaling currently |
| **Java 17 / 21** | App Service, Functions, Container Apps, AKS | Spring Boot / Quarkus / Micronaut all supported; Java cold starts on Functions are worst-in-class — prefer Flex Consumption with always-ready |
| **Node 20 / 22** | Functions v4, Container Apps, App Service, Static Web Apps backends | Node Functions cold start is best-in-class; ESM works but check runtime version |
| **Python 3.11 / 3.12** | Functions v4, Container Apps, App Service, AML | Functions Python v2 programming model (decorator-based) is current; v1 is retiring |
| **Go** | Container Apps, AKS, Functions (custom handler) | First-class Go SDKs (Azure SDK for Go); Functions Go is via custom handler — not as polished |
| **Rust** | Container Apps, AKS | No first-party Functions runtime; runs fine in containers |

**.NET Aspire** is the strongest current Microsoft-recommended composition for distributed .NET — F5 debugging with OTel dashboard, declarative service-to-service wiring, default deployment to Container Apps via `azd`. If your team is .NET-heavy, default to Aspire for new microservices.

### Compute selection — the backend perspective

Pick your compute model based on **request shape**, not architecture-doc trendiness:

| Request shape | Pick | Gotcha |
|---------------|------|--------|
| HTTP-triggered, < 10 min, irregular load | **Functions Flex Consumption** | Always-ready instance minimum eliminates cold start; Premium Plan is legacy for new builds |
| Sustained HTTP load, predictable | **Container Apps (Workload Profile)** or **App Service** | App Service has slot deployments + IIS-like dev model; Container Apps is more flexible for containerized apps |
| Long-running, in-memory cache, websocket | **App Service** or **Container Apps Dedicated** | Functions / Flex Consumption is a poor fit for websocket; use SignalR Service for managed websocket |
| Stateless microservice, container-based | **Container Apps** | Dapr-native, traffic splitting native, no K8s ops |
| Multi-team K8s cluster | **AKS** | If your team is one of many, AKS is the right shared platform |
| Cron / scheduled job | **Container Apps Jobs** | Better than Functions Timer trigger for long batch |
| Event-triggered batch | **Container Apps Jobs (event triggers)** | KEDA-driven; scales 0→N on event count |
| Server-Sent Events / streaming | **App Service** or **Container Apps** | Both support streaming responses; Functions has timeout caps |

**Anti-pattern: HTTP API on Functions Consumption (classic)** — cold starts ruin user-facing P99. Move to Flex Consumption or App Service / Container Apps.

**Anti-pattern: Always-on `min replicas = 5` on Container Apps Consumption** — you're paying for warm containers idle. Use Workload Profile (dedicated) for sustained load, Consumption for spiky.

### SDK selection per language

Microsoft maintains the **Azure SDK family** ([github.com/Azure/azure-sdk](https://github.com/Azure/azure-sdk)) with consistent design across languages. Use it unless you have a specific reason not to.

| Service | .NET package | Java package | Node package | Python package |
|---------|--------------|--------------|--------------|----------------|
| Identity | `Azure.Identity` | `com.azure:azure-identity` | `@azure/identity` | `azure-identity` |
| Key Vault Secrets | `Azure.Security.KeyVault.Secrets` | `com.azure:azure-security-keyvault-secrets` | `@azure/keyvault-secrets` | `azure-keyvault-secrets` |
| Service Bus | `Azure.Messaging.ServiceBus` | `com.azure:azure-messaging-servicebus` | `@azure/service-bus` | `azure-servicebus` |
| Event Hubs | `Azure.Messaging.EventHubs` | `com.azure:azure-messaging-eventhubs` | `@azure/event-hubs` | `azure-eventhub` |
| Event Grid | `Azure.Messaging.EventGrid` | `com.azure:azure-messaging-eventgrid` | `@azure/eventgrid` | `azure-eventgrid` |
| Blob Storage | `Azure.Storage.Blobs` | `com.azure:azure-storage-blob` | `@azure/storage-blob` | `azure-storage-blob` |
| Cosmos DB (NoSQL) | `Microsoft.Azure.Cosmos` | `com.azure:azure-cosmos` | `@azure/cosmos` | `azure-cosmos` |
| Azure SQL | `Microsoft.Data.SqlClient` | `mssql-jdbc` | `mssql` | `pyodbc` / `aioodbc` |
| OpenAI / Foundry | `Azure.AI.OpenAI` | `com.azure:azure-ai-openai` | `@azure/openai` | `openai` (with Azure config) |
| AI Search | `Azure.Search.Documents` | `com.azure:azure-search-documents` | `@azure/search-documents` | `azure-search-documents` |

**Anti-pattern: Using `Microsoft.Azure.*` (the old pre-2020 SDK family) for new code.** The current SDKs are `Azure.*` for .NET. The old packages are still on NuGet but in maintenance. Always check the current docs URL for the recommended package.

### Authentication — `DefaultAzureCredential` is the answer

Every Azure SDK call should use `DefaultAzureCredential` (or its language equivalent) — never connection strings or service principal secrets.

```csharp
// .NET — single line, works in dev (Visual Studio / az CLI), staging (Managed Identity),
// prod (Managed Identity), CI (Workload Identity Federation)
var credential = new DefaultAzureCredential();
var secretClient = new SecretClient(new Uri("https://my-kv.vault.azure.net/"), credential);
```

```python
# Python — same idiom
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://my-kv.vault.azure.net/", credential=credential)
```

```typescript
// Node — same idiom
import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";

const credential = new DefaultAzureCredential();
const client = new SecretClient("https://my-kv.vault.azure.net/", credential);
```

`DefaultAzureCredential` tries (in order): Environment vars → Managed Identity → Visual Studio → Azure CLI → Azure PowerShell → Interactive Browser. For local dev, you log in with `az login` and the SDK picks up the credential. For production, the Managed Identity assigned to the resource is used. No code change between environments.

**`ChainedTokenCredential` for explicit ordering**: when you want to fail fast in prod (don't fall back to `az login`):

```csharp
var credential = new ChainedTokenCredential(
    new ManagedIdentityCredential(),
    new AzureCliCredential());
```

**Workload Identity Federation in CI/CD**: GitHub Actions `azure/login@v2` with `client-id` + `tenant-id` + `audience: api://AzureADTokenExchange` + `permissions: id-token: write`. No client secret. See [WIF docs](https://learn.microsoft.com/entra/workload-id/workload-identity-federation).

### Messaging — Service Bus vs Event Grid vs Event Hubs

You've been through this with system-architect, but as the backend implementer:

| | Service Bus | Event Grid | Event Hubs |
|---|-------------|------------|------------|
| Delivery model | Pull (queues + topics) | Push | Pull (partition reader) |
| Ordering guarantee | Yes (sessions) | No | Yes (per partition) |
| Dedup | Yes | No | No (consumer-side) |
| TTL | Yes | 24h max | Yes (retention) |
| Max msg size | 100 MB (Premium) | 1 MB | 1 MB |
| Throughput | 100K msg/s (Premium) | 10M events/s | Millions/sec |
| Code idiom | `ServiceBusProcessor` | Webhook endpoint or pull (Namespaces) | `EventProcessorClient` |

**Pattern: Service Bus topic + subscription per consumer service**. Each downstream service has its own subscription filtered by message properties. Failure handling is per-subscription via dead-letter queue + retry policy.

**Pattern: idempotent message handlers**. Every handler must be idempotent on the message ID — Service Bus + Event Grid guarantee at-least-once delivery. Store processed message IDs (Cosmos / Redis / SQL) with a TTL > max retry window.

```csharp
// Idempotent handler pattern
public async Task ProcessMessage(ProcessMessageEventArgs args)
{
    var msg = args.Message;
    if (await _dedupStore.IsProcessedAsync(msg.MessageId))
    {
        await args.CompleteMessageAsync(msg);
        return; // already processed
    }
    
    try
    {
        await _handler.HandleAsync(msg);
        await _dedupStore.MarkProcessedAsync(msg.MessageId);
        await args.CompleteMessageAsync(msg);
    }
    catch (Exception ex) when (ShouldDeadLetter(ex))
    {
        await args.DeadLetterMessageAsync(msg, "non-retryable", ex.Message);
    }
    // else: don't complete, message will be redelivered after lock expires
}
```

**Pattern: Event Grid as the resource-event bus**. When you need to react to "Blob uploaded", "Resource Group changed", "Custom topic emitted X", Event Grid pushes to your endpoint with retry. Use the System Topic for Azure resource events; custom topics for your domain events.

**Pattern: Event Hubs for high-throughput streaming**. Telemetry, IoT, logs, change-data-capture. EventProcessorClient with Storage-based checkpoint store. Use Kafka surface if your code is Kafka-native.

### Dapr — when and how on Container Apps

Container Apps has **managed Dapr** sidecar (Dapr 1.13.6-msft.6+). Enable per app via `--enable-dapr`. Building blocks you'll use:

| Building block | Use case |
|----------------|----------|
| Service invocation | Service-to-service HTTP calls with mTLS + retry |
| State management | Per-service KV store (Cosmos / Redis / Storage backing) |
| Pub/sub | Service Bus / Event Hubs / Kafka via Dapr component |
| Bindings | Input/output bindings to Azure services |
| Secrets | Pull from Key Vault via Dapr |
| Configuration | App Configuration via Dapr |
| Actors | Stateful "actor" model with single-threaded per-actor execution |

**When to use Dapr**: heterogeneous polyglot microservices benefit (Java service calling .NET service via Dapr service invocation gets mTLS + retry + tracing without per-language plumbing). Single-language teams may find Dapr overhead vs direct SDK use.

**Anti-pattern: Dapr state management on Cosmos when you need transactions across services**. Dapr's state API is single-service-scoped. For cross-service consistency, use the saga pattern with Service Bus + idempotent handlers.

### Functions — in-process .NET → isolated worker

If you're maintaining Functions code targeting .NET 6 / 7 / 8 **in-process**, you have a migration deadline (late 2026). The migration is non-trivial.

**Differences:**

| | In-process | Isolated worker |
|---|------------|-----------------|
| Process model | Shares host process | Separate worker process |
| Startup | Loaded as plugin | Independent .NET host |
| DI | Functions runtime container | Standard .NET host builder |
| Middleware | Limited | Full middleware pipeline |
| Logging | `ILogger` injected | `ILogger<T>` via DI |
| Configuration | `IConfiguration` injected | Standard `IHostBuilder` |
| Triggers | Attributes (different namespace) | Attributes (different namespace) |
| HttpRequest type | `HttpRequest` (ASP.NET Core) | `HttpRequestData` (custom) |
| Cold start | Faster (no separate process) | Slower in classic; .NET 10 Native AOT closes the gap |

**Migration steps:**

1. Update project to use `Microsoft.NET.Sdk.Worker` SDK.
2. Replace `Microsoft.Azure.WebJobs.*` packages with `Microsoft.Azure.Functions.Worker.*`.
3. Move startup logic from `FunctionsStartup` to a `Program.cs` with `HostBuilder`.
4. Update trigger attributes to the new namespaces.
5. Change HTTP function signatures from `HttpRequest` / `HttpRequestData`.
6. Wire OTel via `Microsoft.Azure.Functions.Worker.OpenTelemetry` (Azure Monitor Distro compatible).
7. Test locally with `func start` (Functions Core Tools).
8. Update CI/CD to deploy isolated artifact format.

Cite: [Azure Functions .NET isolated worker migration guide](https://learn.microsoft.com/azure/azure-functions/migrate-dotnet-to-isolated-model).

### Durable Functions v3 — orchestration patterns

When you need orchestrated workflows (saga, fan-out/fan-in, human approval, timer-based polling), Durable Functions v3 + **Durable Task Scheduler** (new managed backend) is the path.

| Pattern | Use case |
|---------|----------|
| Function chaining | Sequential steps with checkpoints |
| Fan-out / fan-in | Parallel work + aggregation |
| Async HTTP API | Long-running request → 202 + status URL |
| Monitor | Recurring poll until external state changes |
| Human interaction | Wait for external event with timeout |

**Durable Task Scheduler** (new in Functions v3) is a managed backend that's lower-latency than the Azure Storage Tables backing of older Durable Functions. Use it for new builds on Flex Consumption (supported storage providers: Azure Storage and Durable Task Scheduler).

Cite: [Durable Functions docs](https://learn.microsoft.com/azure/azure-functions/durable/).

### Cosmos DB SDK patterns

**Partition-aware queries**: every query should specify the partition key (or accept that it's a cross-partition fan-out).

```csharp
// Single-partition query — efficient
var query = new QueryDefinition("SELECT * FROM c WHERE c.userId = @userId")
    .WithParameter("@userId", userId);
var iterator = container.GetItemQueryIterator<MyDoc>(
    query,
    requestOptions: new QueryRequestOptions { PartitionKey = new PartitionKey(userId) });

// Cross-partition — expensive, last resort
var iterator = container.GetItemQueryIterator<MyDoc>(query);  // no PartitionKey
```

**Bulk operations**: Cosmos SDK 3.x has bulk mode. Set `AllowBulkExecution = true` on the client options. Useful for ingest pipelines.

**Change feed processor**: subscribe to Cosmos change feed with `GetChangeFeedProcessorBuilder` — lease-based, multiple workers can share. Replaces homegrown polling.

**Vector search (DiskANN)**: use the new `VectorEmbeddingPolicy` and `IndexingPolicy.VectorIndexes` to declare vector indexes. Query with `VectorDistance(c.embedding, @queryVector)` in SELECT. DiskANN index type for production scale.

Cite: [Cosmos DB .NET SDK v3](https://learn.microsoft.com/azure/cosmos-db/nosql/sdk-dotnet-v3), [Cosmos DB vector search](https://learn.microsoft.com/azure/cosmos-db/nosql/vector-search).

### Azure SQL — connection management

**Use `Microsoft.Data.SqlClient`** (not `System.Data.SqlClient` — that's the .NET Framework version).

**Always pool with retries**:

```csharp
var connectionString = "Server=mysqlserver.database.windows.net;Authentication=Active Directory Default;Database=mydb;";
// Authentication=Active Directory Default → uses Managed Identity in prod

builder.Services.AddDbContext<MyDbContext>(opts =>
    opts.UseSqlServer(connectionString, sqlOpts =>
    {
        sqlOpts.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null);
    }));
```

**Hyperscale serverless does NOT auto-pause** — if the architect promised "auto-pause to zero", confirm tier; it's only General Purpose serverless that auto-pauses.

**Read replica routing**: Hyperscale supports `ApplicationIntent=ReadOnly` connection strings to route to a read replica. Use for read-heavy reporting workloads.

### PostgreSQL Flexible Server — connection management

**Use `Npgsql`** (.NET) or `psycopg3` (Python) or `pg` (Node).

**PgBouncer is built-in** on Flexible Server — set `pooler_mode = transaction` for short-lived connections at high concurrency.

**Citus Elastic Clusters**: when on the Elastic Cluster tier, declare `distribute_table('mytable', 'tenant_id')` for distributed tables. Queries must include the distribution column for single-node execution.

### Azure Managed Redis — patterns

**Use `StackExchange.Redis`** (.NET), `lettuce` (Java), `ioredis` (Node), `redis-py` (Python).

**Always use TLS** in production (`ssl=True`).

**Auth via Entra ID** (not access keys) when supported by the SDK — uses Managed Identity.

**Flash Optimized tier** auto-moves cold data to NVMe. Useful for large caches with hot/cold access pattern.

**Active geo-replication** for cross-region read/write — but understand the consistency model (LWW per key).

### Static Web Apps backend — API conventions

When using Static Web Apps with a managed Functions backend:

- API functions live in `api/` folder.
- Authentication handled by SWA's built-in providers (Entra ID, GitHub, custom OIDC).
- `x-ms-client-principal` header injected by SWA into your function — base64-encoded JSON with `userId`, `userRoles`, `identityProvider`.
- Routing in `staticwebapp.config.json`.

Note: SWA backend investment has slowed; for complex backends, use Container Apps or App Service.

## 2025-2026 platform reset items relevant to backend

- **Azure Functions Flex Consumption** is the new default plan. Premium Plan is legacy for new builds.
- **Functions in-process .NET retirement** through late 2026 — start migration NOW.
- **.NET Aspire** is Microsoft's recommended distributed-app composition story; deploys to Container Apps via `azd`.
- **Container Apps Workload Profiles** broke the Consumption-only ceiling. Use Workload Profile for sustained-load microservices.
- **Container Apps managed Dapr** at 1.13.6-msft.6+. Versions with `-msft` suffix are Azure-specific patches; latest applied automatically.
- **Foundry Agents** managed agent runtime — if you're building agent backends, use Foundry Agents API, not raw OpenAI Assistants on a custom orchestrator.
- **Cosmos DB DiskANN vector index** for native vector store.
- **Cosmos DB for MongoDB vCore (Azure DocumentDB)** — open-source DocumentDB engine, MongoDB-compatible, provisioned compute pricing.
- **Azure Managed Redis** — successor to Azure Cache for Redis classic.
- **Azure Monitor OpenTelemetry Distro** — replace classic Application Insights SDK.
- **AKS Workload Identity** — Pod Identity is retired; only WI is supported.
- **Cosmos DB for PostgreSQL retiring** — migrate to PostgreSQL Flex + Elastic Clusters (Citus).
- **API Management v2 tiers (Standard v2 / Premium v2)** are the new defaults.

## Patterns and anti-patterns

### Pattern: Managed Identity → Azure SDK chain

Every Azure service call goes:

```
App code → Azure SDK → DefaultAzureCredential → Managed Identity → Azure AD token → service call
```

No connection strings with secrets, no env vars with client secrets, no Key Vault round-trip for tokens (the SDK handles it).

### Pattern: Outbox for cross-service consistency

When you're emitting an event after a DB write, you need an outbox to avoid the dual-write problem.

```
1. Begin SQL transaction
2. INSERT into business table
3. INSERT into outbox table (event payload + status='pending')
4. COMMIT
5. Background worker reads outbox → publishes to Service Bus → marks 'sent'
```

This pattern is platform-agnostic, but on Azure: outbox poller as a Container Apps Job with Service Bus output. Or use Cosmos DB Change Feed → Functions → Service Bus.

### Pattern: Circuit breaker on outbound calls to flaky upstream

Use **Polly** (.NET), **resilience4j** (Java), or framework equivalents. Wrap every outbound HTTP call to: (a) external APIs, (b) other internal services. Trip the breaker after N consecutive failures; half-open after cool-down.

### Pattern: Structured logging with `ILogger<T>` + OTel

Don't `Console.WriteLine`. Use `ILogger<T>` (.NET), SLF4J + Logback (Java), `pino` (Node), `structlog` (Python). Configure the Azure Monitor OpenTelemetry Distro and your logs + traces + metrics flow to App Insights / Log Analytics without per-call code.

```csharp
// Program.cs — wire OTel
builder.Services.AddOpenTelemetry()
    .UseAzureMonitor();
```

That single call gives you traces, logs, metrics, exception capture. Distributed tracing across Service Bus + HTTP + Cosmos works out of the box.

### Pattern: Graceful shutdown on scale-down

When Container Apps scales a replica down (or Functions scales an instance down), your service receives SIGTERM with a grace period. In-flight requests must complete; in-flight message processing must commit or release.

```csharp
// .NET — register shutdown handler
builder.Services.AddHostedService<MyBackgroundService>();
// MyBackgroundService implements IHostedService with proper StopAsync handling
```

Container Apps default grace period is 30 seconds (configurable up to 600s via `terminationGracePeriodSeconds`).

### Pattern: Per-tenant connection or schema in multi-tenant SaaS

When the app is multi-tenant (one Cosmos / SQL / Postgres per tenant or partition-per-tenant):

- **Partition-per-tenant on Cosmos** — partition key = `tenantId`.
- **Schema-per-tenant on PostgreSQL** — `SET search_path TO tenant_xyz`; connection pool per schema.
- **Row-level security on Azure SQL** — RLS policy filters by `SESSION_CONTEXT('TenantId')`.
- **Database-per-tenant via Hyperscale Elastic Pool** — when tenants need isolation but share compute.

See saas-architect overlay for the strategic decision.

### Anti-pattern: HTTP calls from a request handler to another internal service synchronously, sequentially

If your handler does `await GetUser() → await GetOrders() → await GetPayments()`, that's three serial network hops. Either parallelize (`Task.WhenAll`), pre-aggregate via a backend-for-frontend, or shift to async messaging if eventual consistency is acceptable.

### Anti-pattern: Storing JWT signing keys in app config / env vars

JWT signing keys go in Key Vault (or Managed HSM for regulated workloads). Apps fetch via Managed Identity. Rotate via Key Vault rotation policy. Never check in, never log.

### Anti-pattern: Long-running HTTP requests on Functions Consumption

Consumption plan has a 10-minute timeout. If your work takes longer, you need: (a) Durable Functions (orchestration), (b) Container Apps Jobs (batch), (c) async pattern (return 202 immediately, process via queue, poll status).

### Anti-pattern: Hot-loop polling Cosmos / Service Bus

Don't `while(true) { await GetMessages() }` with no backoff. Use the SDK's processor/consumer abstractions (`ServiceBusProcessor`, `EventProcessorClient`, `ChangeFeedProcessorBuilder`) — they handle backoff, checkpointing, lease management.

### Anti-pattern: Logging full request bodies to App Insights

App Insights ingestion is metered. Logging full request bodies on every call inflates cost and may capture PII / secrets. Log structured properties (request ID, user ID, route, status, duration) — not the body.

## Tooling specifics

- **Azure Functions Core Tools** (`func`) for local Functions dev: `func start`, `func azure functionapp publish`. Latest version is `func@4`.
- **Azure Storage Explorer** for browsing Blob / Queue / Table / Cosmos.
- **Azurite** for local emulation of Storage (Blob/Queue/Table). Use in dev + CI.
- **Cosmos DB Emulator** for local Cosmos (Linux + macOS supported via container).
- **.NET Aspire dashboard** (local) — `dotnet run` on an Aspire AppHost shows distributed traces, metrics, logs in one place.
- **Service Bus Explorer** (in Azure portal or standalone) for inspecting queues / topics / dead-letter.
- **Application Insights Live Metrics** — real-time low-cardinality view; doesn't hit ingestion budget the way KQL queries do.
- **Azure SDK shared core packages** — `Azure.Core` (.NET), `azure-core` (Python). Provides retry policies, telemetry, pipeline policies.

## Integration with always-on protocols

### TDD on Azure backend

- **Local first**: tests run against Azurite (Storage), Cosmos Emulator, in-memory Postgres / SQL, in-memory Service Bus (test doubles). Don't TDD against live Azure — too slow, too costly, too flaky.
- **Integration tests against deployed dev environment**: `dotnet test --filter Category=Integration` runs after deploy to dev env. Cleans up resources after.
- **Contract tests for cross-service**: Pact or similar — service A's expectations of service B encoded as a contract, enforced in both CI pipelines.
- **Functions local testing**: `func start` runs the runtime locally; tests hit `http://localhost:7071`.

### Verification

- `az deployment what-if` for any IaC change before deploy.
- `dotnet test` (or equivalent) passes before merging to `main`.
- App Insights Live Metrics during deploy validates traffic shifts cleanly.
- Synthetic monitoring (App Insights availability test) confirms post-deploy health.

### Review

- Push back on any service-to-service auth using a client secret. Managed Identity is non-negotiable.
- Push back on any handler without idempotency. Service Bus / Event Grid are at-least-once.
- Push back on missing OTel instrumentation.
- Push back on missing retries / circuit breakers on outbound calls.
- Push back on unbounded queries (no partition key on Cosmos; missing index on SQL).

### Debugging on Azure

- **App Insights Application Map**: visualizes service dependencies. Slow span → click → see the actual query / HTTP call.
- **App Insights Failures blade**: groups exceptions by type, shows correlated traces.
- **Container Apps `az containerapp logs show --follow`**: streams stdout/stderr.
- **AKS `kubectl logs --previous`**: when a pod crashed, see the previous container's logs.
- **Live Metrics**: real-time view of incoming requests, dependencies, exceptions — without paying for KQL queries.
- **Application Insights Profiler**: on-demand CPU profiles in production (.NET, Java).
- **Snapshot Debugger**: snapshot of process state when an exception is thrown (.NET).

When a service is misbehaving:

1. Reproduce in dev environment or with a synthetic test.
2. Look at App Insights End-to-end Transaction Details for the failing trace.
3. Hypothesize one cause; test it (change one thing in dev).
4. Verify with App Insights / logs.
5. After 3 failed hypotheses, escalate (don't shotgun).

## Cross-references to products_covered

| Product | When you use it |
|---------|-----------------|
| `Azure Functions` (Flex Consumption) | Event-driven serverless backend |
| `Azure Container Apps` | Default container-based backend |
| `App Service` | Traditional web app, slot deployments |
| `AKS` | When K8s ecosystem is needed |
| `Azure SQL Database` / `PostgreSQL Flexible Server` | RDBMS backing |
| `Cosmos DB for NoSQL` | Document NoSQL + vector store |
| `Azure Managed Redis` | Cache / session store |
| `Service Bus` | Transactional messaging |
| `Event Grid` | Reactive event-driven |
| `Event Hubs` | High-throughput streaming |
| `Azure Key Vault` | Secrets / certs (RBAC mode) |
| `App Configuration` | Feature flags + dynamic config |
| `Managed Identities` | All service-to-service auth |
| `API Management v2` | API exposure with throttling |

## When to refresh this overlay

- New Functions runtime version (especially .NET 11+ when it ships)
- New Container Apps feature GA (new Workload Profile sizes, new managed components)
- Dapr major version change
- Azure SDK major version bumps (especially Cosmos SDK, Identity)
- Azure Monitor OpenTelemetry Distro major version
- Functions in-process retirement deadline updates
- New idiom for AI integration (Foundry Agents API evolution)

Target refresh cadence: every 6 months; sooner on major language / SDK changes.
