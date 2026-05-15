---
title: System Architect on Azure
description: Landing Zone topology, compute / data tier selection, integration backbone, network posture, identity strategy, regional plan. The architectural decisions, justified against the Well-Architected Framework.
role_overlay:
  role: system-architect
  stack: azure
  last_verified_on: "2026-05-14"
  products_covered:
    - virtual-machines
    - aks
    - container-apps
    - functions
    - app-service
    - static-web-apps
    - cosmos-db
    - azure-sql
    - postgresql-flexible-server
    - microsoft-fabric
    - azure-openai
    - ai-foundry
    - foundry-agents
    - sentinel
    - defender-for-cloud
    - microsoft-purview
    - front-door
    - application-gateway
    - api-management
    - service-bus
    - event-grid
    - event-hubs
    - bicep
    - terraform-azurerm
    - azd
    - azure-arc
    - azure-vmware-solution
---

## Role briefing

You're the architectural decision-maker on Azure. Your job is to pick the topology, compute tier, data tier, integration backbone, security boundary, deployment unit — and to **justify each pick against the [Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)** before any specialist starts writing code or Bicep.

You don't write the application code ([backend-architect](/stacks/azure/backend-architect/)), the IaC ([devops-engineer](/stacks/azure/devops-engineer/)), or the agent prompts ([ai-ml-engineer](/stacks/azure/ai-ml-engineer/)). You decide what gets built, where, and how the parts talk.

## Decision frameworks specific to this role's lens on Azure

### Compute selection — the ladder, don't default to AKS

| Workload shape | Pick | Why |
|----------------|------|-----|
| HTTP, < 10 min, event-driven | [Functions Flex Consumption](/stacks/azure/functions/) | Always-ready eliminates cold start; no cluster ops |
| Long-running container microservice, scale-to-zero OK | [Container Apps Consumption](/stacks/azure/container-apps/) | Dapr-native, KEDA-native, traffic splitting built in |
| Sustained microservice + dedicated CPU/RAM | [Container Apps Workload Profile](/stacks/azure/container-apps/) | Same API, dedicated compute pool |
| Need K8s ecosystem (Helm, Istio, CRDs) | [AKS Automatic](/stacks/azure/aks/) | Pre-wired Karpenter, KEDA, Workload Identity, Container Insights |
| Regulated, long-lived K8s version pinning | [AKS LTS](/stacks/azure/aks/) | Extended support beyond community window |
| Traditional .NET / Java / PHP web app | [App Service](/stacks/azure/app-service/) | Slot deployments, IIS-like, lift-and-shift |
| Static SPA + tiny backend | [Static Web Apps](/stacks/azure/static-web-apps/) | Tight Azure integration; evaluate Vercel/Cloudflare first |
| Specialized hardware, lift-and-shift | [Virtual Machines](/stacks/azure/virtual-machines/) | Cobalt 100 Arm; Dv6/Ev6 Intel; NCads H100 / ND H200 for AI |

**Anti-pattern: AKS by default.** Don't pick AKS unless you need: third-party operators, custom networking, multi-team shared cluster, specialized scheduling. Container Apps with Workload Profiles is faster to operate, cheaper, and won't blow the budget on idle node pools.

**Anti-pattern: Functions for everything.** Functions Consumption (classic) cold starts ruin user-facing SLOs. Flex Consumption mitigates, but if you need >5 always-ready instances the math often favors Container Apps or App Service.

**Anti-pattern: VMs as the default.** Right for: SQL Server on Always On AG, SAP HANA, third-party appliance images, GPU not yet in Container Apps. Wrong for new microservices, new web apps, new APIs.

### Data tier selection

| Data shape | Pick |
|------------|------|
| OLTP relational, single-region | [Azure SQL Database (Hyperscale)](/stacks/azure/azure-sql/) |
| Multi-tenant SaaS, many small tenant DBs | [Azure SQL Hyperscale Elastic Pools](/stacks/azure/azure-sql/) |
| OLTP, Postgres preferred | [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/) |
| Horizontally scalable Postgres | [PostgreSQL Flex + Elastic Clusters (Citus)](/stacks/azure/postgresql-flexible-server/) — replaces retiring Cosmos for PG |
| Document NoSQL, global writes, vectors | [Cosmos DB for NoSQL with DiskANN](/stacks/azure/cosmos-db/) |
| MongoDB-compatible | [Cosmos DB for MongoDB vCore (Azure DocumentDB)](/stacks/azure/cosmos-db/) |
| Cache / session | [Azure Managed Redis](/stacks/azure/azure-managed-redis/) |
| Big data lake | ADLS Gen2 (HNS on [Storage Account](/stacks/azure/storage-account/)) |
| Unified analytics | [Microsoft Fabric + OneLake](/stacks/azure/microsoft-fabric/) |
| Streaming analytics | [Event Hubs](/stacks/azure/event-hubs/) → Fabric Real-Time Intelligence |
| FHIR R4 health records | Azure Health Data Services (see [healthcare-architect on Azure](/stacks/azure/healthcare-architect/)) |

**Anti-pattern: Cosmos DB for PostgreSQL on a new build.** It's retiring. Migrate to Postgres Flex + Elastic Clusters.

**Anti-pattern: Cosmos serverless for unknown-load production.** Caps at 1 TB and 5K RU/s burst. Start provisioned + autoscale.

**Anti-pattern: Hyperscale serverless assuming auto-pause.** Only General Purpose serverless auto-pauses. Hyperscale doesn't.

### Integration backbone selection

| Pattern | Pick |
|---------|------|
| Transactional message broker, queues, ordered topics, sessions | [Service Bus (Premium)](/stacks/azure/service-bus/) |
| Reactive event broker, resource events, custom events, partner events | [Event Grid](/stacks/azure/event-grid/) |
| High-throughput streaming, Kafka surface, replay | [Event Hubs](/stacks/azure/event-hubs/) |
| Workflow orchestration with 400+ SaaS connectors | [Logic Apps Standard](/stacks/azure/logic-apps/) |
| API exposure with throttling, transformation, dev portal | [API Management v2](/stacks/azure/api-management/) |
| In-process orchestration with state | Durable Functions v3 + Durable Task Scheduler (see [Functions](/stacks/azure/functions/)) |
| AI agent runtime with tools + threads | [Foundry Agents](/stacks/azure/foundry-agents/) |

Many systems use Service Bus + Event Grid + Event Hubs. That's normal.

### Network topology selection

| Pattern | When |
|---------|------|
| Hub-spoke with one hub VNet | Single team, single subscription |
| Virtual WAN + Secure Virtual Hubs | Multi-region, multi-spoke; managed hub-spoke |
| Application Gateway v2 (WAF v2) | Internet-facing regional app |
| Front Door Premium | Internet-facing global app; want Private Link origins (zero public exposure) |
| Traffic Manager | Non-HTTP global routing |

See [Application Gateway](/stacks/azure/application-gateway/) and [Front Door](/stacks/azure/front-door/) for the regional-vs-global decision.

### Identity tenant strategy

| Use case | Pick |
|----------|------|
| Employee SSO + SaaS access | [Entra ID workforce tenant](/stacks/azure/entra-id/) |
| Customer-facing app (B2C) | [Entra External ID](/stacks/azure/entra-external-id/) — replaces Azure AD B2C |
| Partner / B2B collaboration | Entra B2B (workforce tenant + cross-tenant access) |
| AI agent identity | Entra Agent ID (see [Entra ID](/stacks/azure/entra-id/)) |

**Anti-pattern: new Azure AD B2C tenant in 2026.** B2C is legacy support. Use External ID.

**Anti-pattern: separate Entra tenants per environment "for isolation".** Cross-tenant operations add friction. One workforce tenant + app-scoped RBAC unless regulatory requires.

### Multi-region strategy

Default single region (paired region as DR target). Move to active-active only when SLO + cost analysis demands it. [Cosmos DB](/stacks/azure/cosmos-db/) multi-region writes for stateless web tier behind [Front Door](/stacks/azure/front-door/).

### Landing Zone selection

Use the **Azure Verified Modules (AVM) Platform Landing Zone module** for any new subscription / project / tenant. **GA Jan 2026.** Replaces classic ALZ-Bicep (archived Feb 2027). Configurable via `platform-landing-zone.yaml`. Deploy via [Bicep](/stacks/azure/bicep/) Deployment Stacks for lifecycle tracking.

## 2025-2026 platform-reset items relevant to this role

If your last serious Azure engagement predates 2024, these architectural facts have moved:

- **AKS Automatic** is the default — you stop having opinions about kubelet flags, CNI, kube-proxy.
- **Container Apps Workload Profiles** broke the Consumption-only ceiling — mix scale-to-zero + dedicated in one environment.
- **Cosmos DB DiskANN** changed vector store calculus — don't stand up Pinecone if Cosmos fits.
- **Foundry Agents** moved managed agent runtime into the platform — don't roll your own.
- **Entra Agent ID** moved AI agent identity into Zero Trust — designs that have agents acting on behalf of users now have first-class identity.
- **Microsoft Fabric + OneLake** changed analytics platform choice — new BI / DE / DS work on Fabric, not Synapse.
- **Bicep Deployment Stacks** changed IaC lifecycle — no external state file needed for Azure-only.
- **Azure Verified Modules (AVM)** changed the supply chain — hand-rolled Bicep is no longer the architect's responsibility.
- **GitHub Actions on Azure** is the recommended CI/CD for greenfield — Azure DevOps still works but isn't where Microsoft invests.

## Patterns the role applies

### Pattern: Hub-Spoke with Private Link as default posture

Every PaaS service in production has no public endpoint. Storage, KV, SQL, Cosmos, App Configuration, Service Bus, Event Grid, APIM (Premium), Functions (Premium / Flex), Container Registry — Private Endpoints. Enforce via Azure Policy.

### Pattern: Managed Identity everywhere

Every service-to-service auth uses Managed Identity. No connection strings with embedded secrets. No service principal client secrets in env vars.

### Pattern: APIM as the egress edge for partner / internet exposure

Internet-exposed APIs go through [API Management](/stacks/azure/api-management/), not directly to Functions / App Service / Container Apps.

### Pattern: Foundry Agents for managed agent state

When the design says "agent with tools, threaded conversation state, evaluation" — use [Foundry Agents](/stacks/azure/foundry-agents/), not custom orchestration.

### Anti-pattern: "We'll add Private Link later"

Bake Private Link into the Landing Zone via Azure Policy. Later is too late.

### Anti-pattern: AKS without a managed addon plan

AKS Automatic gives you pre-wired add-ons. Fight them and you own the operability.

### Anti-pattern: Choosing services from older docs

Azure CDN from Microsoft (classic) → [Front Door](/stacks/azure/front-door/). Azure API for FHIR → Health Data Services. NSG Flow Logs → VNet Flow Logs. Azure Cache for Redis classic → [Azure Managed Redis](/stacks/azure/azure-managed-redis/). Cosmos for PostgreSQL → [PostgreSQL Flex + Citus](/stacks/azure/postgresql-flexible-server/). Pod Identity → Workload Identity. In-process .NET Functions → isolated worker.

## Integration with always-on protocols

### TDD on architecture

You don't write tests. You write **executable validation gates** in the ADR:

- "We claim [Cosmos DB](/stacks/azure/cosmos-db/) with X partition key and Y RU/s handles 5K writes/sec" → [database-architect](/stacks/azure/database-architect/) + [backend-architect](/stacks/azure/backend-architect/) demonstrate with a k6 / JMeter test in pre-prod before commit.
- "We claim Front Door Premium gives us P99 < 200ms globally" → [sre-engineer](/stacks/azure/sre-engineer/) runs global synthetic monitoring.
- "We claim Foundry Agent achieves Z% accuracy" → [ai-ml-engineer](/stacks/azure/ai-ml-engineer/) demonstrates with Foundry evaluation framework.

### Verification

For every architectural claim that maps to an Azure feature, cite the docs page URL inline in the ADR. The Stack helps with the right URL; the ADR is your record.

### Review

Use the WAF pillars as the review checklist. Push back on:

- "Multi-region from day 1" when SLO doesn't demand it.
- "Public IP on Storage / KV / SQL" when Private Link is available.
- "AKS for everything" when Container Apps fits.
- "Standard tier of every Defender plan" without scoping (see [Defender for Cloud](/stacks/azure/defender-for-cloud/)).
- "No managed identity" when source service supports it.

### Debugging

When an architectural decision turns out wrong (Functions Consumption + unacceptable P99 due to cold starts), debugging discipline says: reproduce → hypothesize → test one variable. Don't shotgun "let's also move the DB and add a CDN."

## Architectural review checklist

Before signing off on an Azure architecture:

- [ ] **Landing Zone**: AVM Platform Landing Zone is the deployment unit?
- [ ] **Identity**: Entra workforce tenant + (External ID for customer auth if applicable)? Conditional Access? PIM for admin? Managed Identity for service-to-service?
- [ ] **Network**: Hub-spoke or Virtual WAN? Private Link for all PaaS in production? VNet Flow Logs (not legacy NSG Flow Logs)?
- [ ] **Compute**: Right-sized to workload shape? Workload Profiles used where AKS isn't justified?
- [ ] **Data**: Right tier for access pattern? Cosmos partition key validated? Hyperscale serverless used only when auto-pause isn't needed?
- [ ] **Secrets**: [Key Vault](/stacks/azure/key-vault/) in RBAC mode? Managed Identity, not connection strings?
- [ ] **CI/CD**: GitHub Actions (or Azure DevOps if mandated) using WIF (OIDC), not client secrets?
- [ ] **Observability**: [Azure Monitor](/stacks/azure/azure-monitor/) + OpenTelemetry Distro (not classic SDK)? Action Groups + alert routing wired?
- [ ] **Security**: [Defender for Cloud](/stacks/azure/defender-for-cloud/) plans scoped? [Sentinel](/stacks/azure/sentinel/) ingestion configured? [Purview](/stacks/azure/microsoft-purview/) classification on data tier?
- [ ] **Cost**: Reservations / Savings Plans for steady-state? Spot for batch? Auto-shutdown for dev?
- [ ] **Compliance**: Service eligibility verified against Trust Center? Data residency mapped?
- [ ] **DR / BCP**: Paired region designated? RPO / RTO defined? Restore drill scheduled?
- [ ] **WAF Review**: Scored against all 5 WAF pillars? Well-Architected Review tool run?

## Cross-references

- [Backend Architect on Azure](/stacks/azure/backend-architect/) — the implementer
- [Database Architect on Azure](/stacks/azure/database-architect/) — the data design
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — the platform
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — the guardrails
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/) — the observability + SLOs
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — AI architecture
- [SaaS Architect on Azure](/stacks/azure/saas-architect/) — multi-tenant patterns
- [Healthcare Architect on Azure](/stacks/azure/healthcare-architect/) — healthcare overlay
- [Azure Stack index](/stacks/azure/)
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
