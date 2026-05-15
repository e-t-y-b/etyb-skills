---
title: SaaS Architect on Azure
description: Multi-tenant patterns — Hyperscale Elastic Pools, Cosmos partition-per-tenant, Entra External ID, Front Door per-tenant routing, APIM tenant subscriptions, cost attribution.
role_overlay:
  role: saas-architect
  stack: azure
  last_verified_on: "2026-05-14"
  products_covered:
    - azure-sql
    - cosmos-db
    - postgresql-flexible-server
    - entra-external-id
    - entra-id
    - front-door
    - api-management
    - key-vault
    - container-apps
    - aks
---

## Role briefing

You're building a multi-tenant SaaS on Azure. Tenant isolation, scalable provisioning, per-tenant cost attribution, customer-facing identity, billing surfaces.

You don't make end-to-end SaaS strategy decisions (saas-architect specialist) — you implement the Azure-side mechanisms.

## Decision frameworks specific to this role's lens on Azure

### Tenancy model — silo / pool / bridge

| Model | Description | Cost | Isolation | Ops complexity |
|-------|-------------|------|-----------|----------------|
| **Silo** | Resource-per-tenant | High | Highest | High (N times the stuff) |
| **Pool** | Shared resources, logical separation | Low | Lowest (relies on app code) | Low |
| **Bridge** | Mixed (shared compute, dedicated DB per tenant) | Medium | Medium | Medium |

On Azure specifically:

| Pattern | Azure mechanism |
|---------|-----------------|
| Pool (shared Cosmos) | [Cosmos DB NoSQL](/stacks/azure/cosmos-db/) with partition key = `tenantId` |
| Pool (shared Postgres) | [PostgreSQL Flex](/stacks/azure/postgresql-flexible-server/) with `tenant_id` column + RLS |
| Pool (shared SQL) | [Azure SQL](/stacks/azure/azure-sql/) with RLS + `SESSION_CONTEXT` |
| Bridge (DB per tenant on shared compute) | **Azure SQL Hyperscale Elastic Pools** — perfect fit |
| Bridge (schema per tenant) | Postgres `SET search_path` + connection pool per schema |
| Silo (full resource per tenant) | Separate RG / subscription per tenant + per-tenant Bicep |

Decision matrix:

| Customer requirement | Recommended |
|---------------------|-------------|
| < 100 small/medium tenants, basic isolation | Pool (shared DB with PK = tenantId) |
| 100-10000 tenants, varying sizes | Bridge (Hyperscale Elastic Pool with DB per tenant) |
| Enterprise tenant with regulatory isolation | Silo (separate subscription) |
| Per-tenant custom infra | Silo |

**Hyperscale Elastic Pool** (GA 2025-26) is the sweet spot for B2B SaaS — pool Hyperscale DBs, share compute, per-DB autonomy.

**Anti-pattern: pure silo for high tenant count** — operational overhead explodes.

**Anti-pattern: pure pool for regulated customers** — they'll ask for isolation evidence; you have none.

### Customer auth — Entra External ID

See [Entra External ID](/stacks/azure/entra-external-id/). Replaces Azure AD B2C for new builds. B2C is in legacy support.

Multi-tenant customer scenarios:

| Scenario | Pattern |
|----------|---------|
| All customers in one External ID tenant | Custom attribute `tenantId` tracks which app tenant they belong to |
| Per-customer External ID tenant (white-label) | Provisioned External ID tenant per customer org |
| Hybrid: customer's own Entra ID for SSO | Multi-tenant Entra app + accept tokens from customer's tenant; External ID for users without their own IdP |

**Anti-pattern: new Azure AD B2C tenant in 2026.**

### Partner / B2B — Entra B2B

For customers with their own Entra ID: multi-tenant Entra app registration in your home tenant; customer admins consent; users sign in with their creds; cross-tenant access settings control inbound/outbound.

**Pattern: hybrid External ID + B2B.** Customers without their own IdP → External ID. Customers with Entra → B2B federation. Same app.

### Per-tenant data partitioning

**Cosmos DB**: partition key = `tenantId`. Every query `WHERE c.tenantId = @t`. 20 GB per logical partition limit. Large tenants → synthetic key `tenantId + bucket`. Tenant lookup container with metadata. See [Cosmos DB](/stacks/azure/cosmos-db/).

**Azure SQL Hyperscale Elastic Pool**:

```bicep
resource pool 'Microsoft.Sql/servers/elasticPools@2023-08-01-preview' = {
  parent: server
  name: 'tenant-pool'
  sku: { name: 'HyperscaleElasticPool', tier: 'Hyperscale', capacity: 8 }
  properties: {
    perDatabaseSettings: { minCapacity: 0.25, maxCapacity: 4 }
    zoneRedundant: true
  }
}

resource tenantDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: server
  name: 'tenant-${tenantId}'
  sku: { name: 'HS_Gen5_2', tier: 'Hyperscale' }
  properties: { elasticPoolId: pool.id }
}
```

**PostgreSQL Flex schema-per-tenant**:

```sql
CREATE SCHEMA tenant_abc;
SET search_path TO tenant_abc, public;
```

Connection pool per schema; PgBouncer transaction mode.

**PostgreSQL Flex Citus Elastic Cluster**:

```sql
SELECT create_distributed_table('orders', 'tenant_id');
```

Distributed by `tenant_id` → single-shard execution when included in WHERE.

### Per-tenant cost attribution

**Tagging strategy**:

```hcl
tags = {
  Environment = "prod"
  Service     = "saas-app"
  TenantId    = var.tenant_id     # silo / bridge
  TenantTier  = "enterprise"
  CostCenter  = "saas-product"
}
```

**Cost Management**: daily export to Storage (CSV / parquet) with tag columns; Power BI / [Fabric](/stacks/azure/microsoft-fabric/) aggregates by `TenantId`.

For pool model: app-side telemetry tracks per-tenant request count + data volume + RU consumed; allocate shared cost proportionally. Cosmos per-partition RU consumption is available via diagnostic logs. Hyperscale Elastic Pool surfaces per-DB consumption.

### Tenant routing

**Front Door per-tenant path or host**:

- Path: `app.saas.com/tenants/{tenantId}/*` → origin per tier or shared with header
- Host: `{tenantId}.app.saas.com` → wildcard cert + dynamic routing
- Custom domain per tenant: `customer.com` mapped via managed certs + DNS verification

See [Front Door](/stacks/azure/front-door/).

**APIM per-subscription tenancy**:

- Subscription per tenant
- Products group APIs available to tenant tier
- Policies for per-subscription rate limit + quota
- Tenant identifier in JWT claim from External ID flow

See [API Management](/stacks/azure/api-management/).

### Noisy-neighbor controls

| Surface | Mechanism |
|---------|-----------|
| Cosmos DB | Per-partition RU limit; split throughput; isolation tier |
| Azure SQL Elastic Pool | `perDatabaseSettings.maxCapacity` caps a tenant's burst |
| App Service / Container Apps | Per-app CPU/memory limits; custom autoscale per tenant if needed |
| APIM | Per-subscription rate limit + quota |
| Front Door | Rate-limit rules in WAF |
| Service Bus | Per-tenant queue or session ID partitioning |

**Pattern: hard cap per tenant.** Even in pool, app enforces tenant quota (req/min, storage GB, AI tokens/day). Exceeded → 429 with `Retry-After`.

### Tenant lifecycle automation

**Provisioning**: signup flow → Function → ARM API to deploy Bicep template. Or signup creates record in tenant registry → background process provisions.

Time-to-provision target: < 5 min pool; < 30 min bridge; < 2h silo.

**Suspension**: revoke External ID users; disable APIM subscription; soft-disable DB (revoke RBAC; keep data for restore window).

**Decommission**: hard delete after retention (GDPR); lifecycle policy on Blob; drop schema / DB / partition.

### Billing integration

**Pattern: Azure Marketplace Transact** for enterprise SaaS sold through Azure Marketplace — Azure handles billing, your app receives webhooks on subscription state, per-seat / per-tier pricing handled by Marketplace.

**Pattern: Stripe** for direct billing — Stripe handles cards, subscriptions, dunning; app maps Stripe customer + subscription to app tenant.

**Pattern: usage-based billing** — app tracks per-tenant usage; daily aggregation; daily export to Stripe Metered Billing or Marketplace Usage API.

**Anti-pattern: billing logic in app code.** Use Stripe / Marketplace.

### White-label / custom domain

Per-tenant custom domain: DNS verification (TXT or CNAME) → managed cert auto-issued + auto-renewed via Front Door / App Service → tenant config mapped from incoming host header.

**Pattern: certs as Key Vault Certificates.** Front Door reads from Key Vault; auto-renews via Key Vault's cert lifecycle.

## 2025-2026 platform-reset items relevant to this role

- **Entra External ID** (rename of B2C, 2024).
- **Azure SQL Hyperscale Elastic Pools GA 2025-26** — purpose-built for SaaS DB-per-tenant.
- **Cosmos DB partition strategies** — DiskANN + hierarchical PK (partial GA).
- **APIM v2 tiers** — new defaults.
- **Front Door rule engine v2** — flexible per-tenant routing.
- **Azure Marketplace Transact** — first-party billing for ISVs.
- **Cost Management exports to Fabric** — better tenant cost analytics.

## Patterns the role applies

### Pattern: Hyperscale Elastic Pool for B2B DB-per-tenant

Per-tenant Hyperscale DB; pool shares compute; per-DB autonomy with shared cost. Sweet spot for 100-1000 tenants.

### Pattern: Cosmos partition-per-tenant for B2C / high-tenant-count

Single Cosmos account; partition key = `tenantId`; container per logical entity.

### Pattern: Entra External ID for customer auth + B2B for enterprise customers

Hybrid: customers without own IdP → External ID. Customers with Entra → B2B federation. Same app.

### Pattern: Tags + Cost Management for cost attribution

`TenantId` tag on every resource (silo / bridge). Daily export. Power BI / Fabric for per-tenant cost.

### Pattern: APIM subscription per tenant for API tenancy

Per-subscription rate + quota policies. JWT validation verifies External ID token.

### Pattern: Tenant registry as the source of truth

Small Cosmos / SQL DB: `tenantId`, `tier`, `region`, `state`, `customDomain`, `provisioningStatus`. Every surface reads this.

### Pattern: White-label cert via Key Vault + Front Door

Customer brings cert (or auto-issued via DNS verification) → Key Vault → Front Door reads → SNI per domain.

### Anti-pattern: pure silo for high tenant count

### Anti-pattern: pure pool for regulated customers

### Anti-pattern: per-customer subscription without automation

Bicep + automation pipeline triggered by signup.

### Anti-pattern: tenant ID in URL path without auth check

`/tenants/123/data` without verifying JWT `tenantId` claim matches → cross-tenant leak. Auth middleware enforces.

### Anti-pattern: new B2C tenant in 2026

### Anti-pattern: hard-coded tenant config in app

Tenant config in DB or App Configuration with tenant-keyed entries.

### Anti-pattern: shared App Configuration namespace for all tenants

Separate stores or namespaced keys (`tenants/{tenantId}/feature.x`).

## Integration with always-on protocols

### TDD

- Tenant lifecycle tests (provision → use → suspend → decommission).
- Cross-tenant isolation tests (tenant A's API key cannot access tenant B's data).
- Quota enforcement tests (tenant exceeds quota → 429).

### Verification

- Per-tenant cost attribution accuracy ≥ 95%.
- Tenant provisioning time within SLO.
- Cross-tenant isolation audited via security testing.

### Review

Push back on the anti-patterns above.

### Debugging

- Tenant-tagged log queries: `requests | where customDimensions.tenantId == "abc"`.
- Per-tenant App Insights workspaces (or workspace-level + custom dimension filtering).
- Cost Management anomaly detection per-tenant.

## Cross-references

- [System Architect on Azure](/stacks/azure/system-architect/) — overall topology
- [Database Architect on Azure](/stacks/azure/database-architect/) — partition-per-tenant, Hyperscale Elastic Pool
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — Entra External ID + B2B
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — multi-tenant SDK patterns
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — automation, AVM modules
- [Azure Stack index](/stacks/azure/)
- [Multi-tenant SaaS architectural patterns on Azure](https://learn.microsoft.com/azure/architecture/guide/multitenant/overview)
