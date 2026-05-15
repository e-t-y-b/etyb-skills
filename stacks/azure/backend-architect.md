---
title: Backend Architect on Azure
description: Application code that runs on Azure — runtime selection, Azure SDK chain, Managed Identity, idempotent messaging, in-process → isolated worker migration, .NET Aspire, Dapr.
role_overlay:
  role: backend-architect
  stack: azure
  last_verified_on: "2026-05-14"
  products_covered:
    - functions
    - container-apps
    - app-service
    - aks
    - azure-sql
    - postgresql-flexible-server
    - cosmos-db
    - azure-managed-redis
    - service-bus
    - event-grid
    - event-hubs
    - key-vault
    - api-management
    - entra-id
    - azure-openai
    - foundry-agents
    - ai-search
    - application-insights
---

## Role briefing

You're writing the application code that runs on Azure. .NET / Java / Node.js / Python / Go service exposing an API, processing messages, integrating with Azure services. This view tells you what Azure 2026 expects — which compute model, which SDK, which auth pattern, which messaging idiom, which gotchas will bite you in production.

You're not the architect ([system-architect](/stacks/azure/system-architect/) picks topology) or the platform owner ([devops-engineer](/stacks/azure/devops-engineer/) writes Bicep) — you write the service, hook it to Azure services correctly, and survive the platform's quirks.

## Decision frameworks specific to this role's lens on Azure

### Runtime selection — language × compute model

Azure has no opinion on language; compute models have edges:

| Runtime | Best fit | Watch out for |
|---------|----------|---------------|
| .NET 8 / 9 / 10 | [Functions (isolated)](/stacks/azure/functions/), [Container Apps](/stacks/azure/container-apps/), [App Service](/stacks/azure/app-service/), [AKS](/stacks/azure/aks/) | .NET 10 Native AOT changes Functions cold-start; in-process .NET retired late 2026 |
| .NET Aspire | Distributed app composition + local dev + OTel | Aspire deploys to Container Apps by default; Functions-on-Aspire skips event-driven scaling currently |
| Java 17 / 21 | App Service, Functions, Container Apps, AKS | Spring Boot / Quarkus / Micronaut all supported; Java Functions cold starts worst-in-class — prefer Flex Consumption with always-ready |
| Node 20 / 22 | Functions v4, Container Apps, App Service, [Static Web Apps](/stacks/azure/static-web-apps/) backends | Best-in-class cold starts; ESM works; verify runtime version |
| Python 3.11 / 3.12 | Functions v4, Container Apps, App Service | Python v2 programming model (decorator-based) current; v1 retiring |
| Go | Container Apps, AKS, Functions custom handler | First-class Azure SDK for Go; Functions Go is via custom handler — not as polished |
| Rust | Container Apps, AKS | No first-party Functions runtime |

**.NET Aspire** is Microsoft's recommended distributed-app composition story — F5 debugging with OTel dashboard, declarative service-to-service wiring, default deployment to Container Apps via `azd`. If your team is .NET-heavy, default to Aspire for new microservices.

### Compute selection — backend perspective

Pick based on **request shape**:

| Request shape | Pick | Gotcha |
|---------------|------|--------|
| HTTP, < 10 min, irregular load | [Functions Flex Consumption](/stacks/azure/functions/) | Always-ready min eliminates cold start |
| Sustained HTTP load, predictable | [Container Apps Workload Profile](/stacks/azure/container-apps/) or [App Service](/stacks/azure/app-service/) | App Service has slot deploys + IIS-like model; Container Apps more flexible for containerized |
| Long-running, websocket | App Service or Container Apps Dedicated | Functions / Flex is a poor fit for websocket; use SignalR Service for managed websocket |
| Stateless microservice, container-based | [Container Apps](/stacks/azure/container-apps/) | Dapr-native, traffic splitting native |
| Multi-team K8s cluster | [AKS](/stacks/azure/aks/) | When your team is one of many |
| Cron / scheduled | Container Apps Jobs | Better than Functions Timer for long batch |
| Event-triggered batch | Container Apps Jobs (KEDA-driven) | Scales 0→N on event count |
| SSE / streaming | App Service or Container Apps | Both support streaming; Functions has timeout caps |

### Authentication — `DefaultAzureCredential` is the answer

Every Azure SDK call should use `DefaultAzureCredential` (or language equivalent) — never connection strings or service principal secrets.

```csharp
var credential = new DefaultAzureCredential();
var secretClient = new SecretClient(new Uri("https://my-kv.vault.azure.net/"), credential);
```

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://my-kv.vault.azure.net/", credential=credential)
```

```typescript
import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";

const credential = new DefaultAzureCredential();
const client = new SecretClient("https://my-kv.vault.azure.net/", credential);
```

`DefaultAzureCredential` tries: Env vars → Managed Identity → Visual Studio → Azure CLI → PowerShell → Interactive Browser. Local dev: `az login`. Production: Managed Identity assigned to the resource. No code change between environments.

Use `ChainedTokenCredential` to fail fast in prod (don't fall back to `az login`):

```csharp
var credential = new ChainedTokenCredential(
    new ManagedIdentityCredential(),
    new AzureCliCredential());
```

### Messaging — which Azure messaging primitive

Reference [Service Bus](/stacks/azure/service-bus/) vs [Event Grid](/stacks/azure/event-grid/) vs [Event Hubs](/stacks/azure/event-hubs/) for full comparison.

**Idempotent message handlers** are non-negotiable — all three are at-least-once.

```csharp
public async Task ProcessMessage(ProcessMessageEventArgs args)
{
    var msg = args.Message;
    if (await _dedupStore.IsProcessedAsync(msg.MessageId)) {
        await args.CompleteMessageAsync(msg);
        return;
    }
    try {
        await _handler.HandleAsync(msg);
        await _dedupStore.MarkProcessedAsync(msg.MessageId);
        await args.CompleteMessageAsync(msg);
    } catch (Exception ex) when (ShouldDeadLetter(ex)) {
        await args.DeadLetterMessageAsync(msg, "non-retryable", ex.Message);
    }
}
```

### Functions — in-process .NET → isolated worker

If you're maintaining Functions code targeting .NET 6 / 7 / 8 **in-process**, you have a migration deadline (late 2026). The migration is non-trivial:

| | In-process | Isolated worker |
|---|------------|-----------------|
| Process model | Shares host process | Separate worker process |
| DI | Functions runtime container | Standard .NET host builder |
| Middleware | Limited | Full middleware pipeline |
| HttpRequest type | `HttpRequest` (ASP.NET Core) | `HttpRequestData` (custom) |
| Cold start | Faster | .NET 10 Native AOT closes the gap |

Steps:

1. Update project to `Microsoft.NET.Sdk.Worker` SDK.
2. Replace `Microsoft.Azure.WebJobs.*` with `Microsoft.Azure.Functions.Worker.*`.
3. Move startup from `FunctionsStartup` to `Program.cs` with `HostBuilder`.
4. Update trigger attribute namespaces.
5. Change HTTP signatures to `HttpRequestData`.
6. Wire OTel via `Microsoft.Azure.Functions.Worker.OpenTelemetry`.

### Dapr on Container Apps — when and how

[Container Apps](/stacks/azure/container-apps/) has **managed Dapr** sidecar (1.13.6-msft.6+). Building blocks:

| Building block | Use |
|----------------|-----|
| Service invocation | Service-to-service HTTP with mTLS + retry |
| State management | Per-service KV store (Cosmos / Redis / Storage) |
| Pub/sub | Service Bus / Event Hubs / Kafka via Dapr component |
| Bindings | Input/output to Azure services |
| Secrets | Pull from Key Vault via Dapr |
| Actors | Stateful single-threaded per-actor execution |

**When to use Dapr**: heterogeneous polyglot microservices benefit (Java service calling .NET service gets mTLS + retry + tracing without per-language plumbing). Single-language teams may find direct SDK use simpler.

**Anti-pattern**: Dapr state management on Cosmos when you need cross-service transactions — Dapr state API is single-service-scoped. Use saga pattern with Service Bus + idempotent handlers.

### Data tier SDK patterns

For [Cosmos DB](/stacks/azure/cosmos-db/) partition-aware queries, bulk mode, Change Feed, DiskANN vector indexing — see the product page.

For [Azure SQL](/stacks/azure/azure-sql/) — use `Microsoft.Data.SqlClient` (not `System.Data.SqlClient`), Entra auth (`Authentication=Active Directory Default`), EF Core retry-on-failure.

For [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/) — `Npgsql` / `psycopg3` / `pg`; built-in PgBouncer transaction mode; Citus distribution column in WHERE for single-shard.

For [Azure Managed Redis](/stacks/azure/azure-managed-redis/) — `StackExchange.Redis` / `lettuce` / `ioredis` / `redis-py`; TLS always; Entra auth where supported.

## 2025-2026 platform-reset items relevant to backend

- **Functions Flex Consumption** is the new default — Premium Plan is legacy for new builds.
- **In-process .NET retirement** through late 2026 — start migration NOW.
- **.NET Aspire** is the distributed-app composition story.
- **Container Apps Workload Profiles** broke the Consumption-only ceiling.
- **Managed Dapr** at 1.13.6-msft.6+ — Azure-specific patches auto-applied.
- **[Foundry Agents](/stacks/azure/foundry-agents/)** — use the managed runtime instead of raw OpenAI Assistants on custom orchestrator.
- **[Cosmos DB DiskANN](/stacks/azure/cosmos-db/)** vector index.
- **MongoDB vCore = Azure DocumentDB** rebrand.
- **[Azure Managed Redis](/stacks/azure/azure-managed-redis/)** successor.
- **Azure Monitor OpenTelemetry Distro** replaces classic [App Insights](/stacks/azure/application-insights/) SDK.
- **AKS Workload Identity** only; Pod Identity retired.
- **API Management v2** SKUs new defaults.

## Patterns the role applies

### Pattern: Managed Identity → Azure SDK chain

```
App code → Azure SDK → DefaultAzureCredential → Managed Identity → Entra token → service call
```

No connection strings with secrets. No env vars with client secrets. No Key Vault round-trip for tokens (the SDK handles it).

### Pattern: Outbox for cross-service consistency

```
1. Begin SQL transaction
2. INSERT into business table
3. INSERT into outbox table (event payload + status='pending')
4. COMMIT
5. Background worker reads outbox → publishes to Service Bus → marks 'sent'
```

Or use [Cosmos DB Change Feed](/stacks/azure/cosmos-db/) → Functions → Service Bus.

### Pattern: Circuit breaker on outbound

Polly (.NET), resilience4j (Java), framework equivalents. Wrap every outbound HTTP call. Trip after N consecutive failures; half-open after cool-down.

### Pattern: Structured logging + OTel

```csharp
builder.Services.AddOpenTelemetry().UseAzureMonitor();
```

One line. Traces + logs + metrics + exception capture flow to App Insights / Log Analytics. Distributed tracing across Service Bus + HTTP + Cosmos works out of the box.

### Pattern: Graceful shutdown on scale-down

Container Apps SIGTERM with 30s grace period (configurable up to 600s). In-flight requests complete; in-flight message processing commits or releases.

### Pattern: Per-tenant connection or schema in multi-tenant SaaS

See [SaaS Architect on Azure](/stacks/azure/saas-architect/) for the strategic decision.

### Anti-pattern: Long-running HTTP on Functions Consumption

10-minute timeout. Use Durable Functions, Container Apps Jobs, or async pattern (202 + poll status).

### Anti-pattern: Hot-loop polling

Use SDK processor abstractions (`ServiceBusProcessor`, `EventProcessorClient`, `ChangeFeedProcessorBuilder`).

### Anti-pattern: Logging full request bodies to App Insights

Ingestion is metered + PII risk. Log structured properties (request ID, user ID, route, status, duration) — not body.

## Integration with always-on protocols

### TDD on Azure backend

- **Local first**: tests against Azurite (Storage), Cosmos Emulator, in-memory Postgres / SQL, in-memory Service Bus test doubles. Don't TDD against live Azure.
- **Integration tests against deployed dev**: `dotnet test --filter Category=Integration` runs after deploy to dev env; cleans up.
- **Contract tests**: Pact or similar — service A's expectations of service B encoded as contract; enforced in both pipelines.
- **Functions local**: `func start` runs runtime locally; tests hit `http://localhost:7071`.

### Verification

- `az deployment what-if` for any IaC change before deploy.
- `dotnet test` passes before merging.
- App Insights Live Metrics during deploy validates traffic shifts cleanly.
- Synthetic monitoring confirms post-deploy health.

### Review

Push back on:

- Service-to-service auth using a client secret. Managed Identity is non-negotiable.
- Handler without idempotency. Service Bus / Event Grid are at-least-once.
- Missing OTel instrumentation.
- Missing retries / circuit breakers on outbound calls.
- Unbounded queries (no partition key on Cosmos; missing index on SQL).

### Debugging on Azure

- **App Insights Application Map**: visualizes service dependencies → click slow span → see actual query / HTTP call.
- **App Insights Failures**: groups exceptions by type, correlated traces.
- **Container Apps `az containerapp logs show --follow`**: streams stdout/stderr.
- **AKS `kubectl logs --previous`**: previous container's logs after crash.
- **Live Metrics**: real-time view without paying KQL.
- **Profiler** + **Snapshot Debugger** (.NET / Java).

## Cross-references

- [System Architect on Azure](/stacks/azure/system-architect/) — the architectural decisions you implement
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — the platform that runs your code
- [Database Architect on Azure](/stacks/azure/database-architect/) — data tier collaboration
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — Managed Identity + Key Vault
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/) — observability + SLOs
- [Azure Stack index](/stacks/azure/)
- [Azure SDK family](https://github.com/Azure/azure-sdk)
- [Functions .NET isolated worker migration](https://learn.microsoft.com/azure/azure-functions/migrate-dotnet-to-isolated-model)
