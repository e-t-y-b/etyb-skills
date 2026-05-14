---
role: saas-architect
stack: azure
last_verified_on: "2026-05-14"
---

# Azure — saas-architect overlay

You're building a multi-tenant SaaS on Azure. Tenant isolation, scalable provisioning, per-tenant cost attribution, customer-facing identity, billing surfaces. This overlay teaches you what Azure 2026 provides for SaaS patterns and where the platform's defaults serve or fight you.

You don't make end-to-end SaaS strategy decisions (saas-architect specialist) — you implement the Azure-side mechanisms.

## What this role does on Azure

- Picks the **tenant isolation model** (silo / pool / bridge) and maps to Azure resources.
- Designs **per-tenant data partitioning** (Cosmos partition / SQL Hyperscale Elastic Pool / schema-per-tenant on Postgres).
- Designs **customer auth via Entra External ID** (CIAM, formerly B2C).
- Designs **partner / B2B auth via Entra B2B + cross-tenant access settings**.
- Designs **per-tenant cost attribution** (resource tags + Cost Management exports + tenant cost dashboards).
- Designs **noisy-neighbor controls** (quotas, rate limits, isolation tiers).
- Implements **tenant lifecycle** (provisioning, suspension, decommission) via Bicep / Terraform / Azure Resource Manager API.
- Designs **per-tenant routing** (Front Door / APIM tenant routing).
- Implements **billing integration** with Stripe / Azure Marketplace Billing API.
- Designs **white-label / custom domain** capability per tenant.

## Decision frameworks

### Tenancy model — silo vs pool vs bridge

Three canonical patterns:

| Model | Description | Cost | Isolation | Operational complexity |
|-------|-------------|------|-----------|------------------------|
| **Silo** | Resource-per-tenant (separate DB, separate App Service, etc.) | High | Highest | High (N times the stuff) |
| **Pool** | Shared resources, logical separation (one DB, partition key = tenantId) | Low | Lowest (relies on app code for isolation) | Low |
| **Bridge** | Mixed (shared compute, dedicated DB per tenant) | Medium | Medium | Medium |

**On Azure specifically**:

| Pattern | Azure mechanism |
|---------|-----------------|
| Pool (shared Cosmos) | Cosmos NoSQL with partition key = `tenantId` |
| Pool (shared Postgres) | Postgres with `tenant_id` column + RLS policy |
| Pool (shared SQL) | Azure SQL with RLS + `SESSION_CONTEXT` filtering |
| Bridge (DB per tenant on shared compute) | **Azure SQL Hyperscale Elastic Pools** — perfect fit |
| Bridge (schema per tenant) | Postgres `SET search_path TO tenant_xyz` + connection pool per schema |
| Silo (full resource per tenant) | Separate RG / subscription per tenant + per-tenant Bicep template |

**Decision matrix**:

| Customer requirement | Recommended |
|---------------------|-------------|
| < 100 small / medium tenants, basic isolation | **Pool (shared DB with PK = tenantId)** |
| 100-10000 tenants, varying sizes | **Bridge (Hyperscale Elastic Pool with DB per tenant)** |
| Enterprise tenant with regulatory isolation | **Silo (separate subscription)** |
| Per-tenant custom infra (VPC peering, etc.) | **Silo** |

**Hyperscale Elastic Pool** (GA 2025-26) is the sweet spot for B2B SaaS — pool Hyperscale DBs, share compute, per-DB autonomy.

**Anti-pattern: pure silo for high tenant count**. You'll burn out on management overhead. Use bridge.

**Anti-pattern: pure pool for regulated customers**. They'll ask for evidence of isolation; you have none.

Cite: [Multi-tenant SaaS architectural patterns on Azure](https://learn.microsoft.com/azure/architecture/guide/multitenant/overview).

### Customer auth — Entra External ID

**Replaces Azure AD B2C** for new builds (2024 rebrand). B2C is in legacy support.

External ID capabilities:

- Email / password / social (Google, Facebook, Apple)
- SAML / WS-Federation for enterprise customer SSO
- Custom branding (per-tenant white-label sign-in pages)
- MFA + Conditional Access for customer accounts
- Self-service password reset
- Custom user attributes (extension properties)
- Token claims customization (groups, roles, custom claims)

**Multi-tenant customer scenarios on External ID**:

| Scenario | Pattern |
|----------|---------|
| All customers in one External ID tenant | Use custom attribute `tenantId` to track which app tenant they belong to |
| Per-customer External ID tenant (white-label) | Provisioned External ID tenant per customer organization; their users sign in to "their" portal |
| Hybrid: customer's own Entra ID for SSO | Multi-tenant Entra app + accept tokens from customer's tenant; external ID for users without their own IdP |

**Pattern: extension attributes for app tenant routing**. Add `tenantId` extension attribute on user; include in token claims; app routes by claim.

**Anti-pattern: new Azure AD B2C tenant in 2026**. Use External ID.

Cite: [Entra External ID](https://learn.microsoft.com/entra/external-id/customers/overview).

### Partner / B2B — Entra B2B

For customers that have their own Entra ID and want SSO:

- **Multi-tenant Entra app registration** in your home tenant.
- Customer admins consent on behalf of their org.
- Customer's users sign in with their own Entra creds; tokens issued by customer's tenant; your app validates.
- **Cross-tenant access settings** control inbound (you accept) + outbound (you allow your users to access partner).

**Pattern: hybrid External ID + B2B**. Customers without their own IdP → External ID local accounts. Customers with Entra → B2B federation.

### Per-tenant data partitioning

#### Cosmos DB

Partition key = `tenantId`. Every query includes `WHERE c.tenantId = @t`. Each tenant's data in its own logical partition (up to 20 GB).

**Large tenants**: synthetic key `tenantId + bucket` where bucket = `hash(documentId) % N`.

**Tenant lookup**: separate small container with metadata about each tenant (settings, tier, region preference).

#### Azure SQL — Hyperscale Elastic Pool

DB per tenant. Pool shares compute. Per-DB isolation; pool-level capacity.

```bicep
resource pool 'Microsoft.Sql/servers/elasticPools@2023-08-01-preview' = {
  parent: server
  name: 'tenant-pool'
  sku: {
    name: 'HyperscaleElasticPool'
    tier: 'Hyperscale'
    capacity: 8  // vCores
  }
  properties: {
    perDatabaseSettings: { minCapacity: 0.25, maxCapacity: 4 }
    zoneRedundant: true
  }
}

resource tenantDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: server
  name: 'tenant-${tenantId}'
  sku: { name: 'HS_Gen5_2', tier: 'Hyperscale' }
  properties: {
    elasticPoolId: pool.id
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}
```

Per-tenant DB connection: `Server=...;Database=tenant-{tenantId};Authentication=Active Directory Default`.

#### PostgreSQL Flex — schema per tenant

```sql
CREATE SCHEMA tenant_abc;
SET search_path TO tenant_abc, public;
-- Tenant's tables created in tenant_abc schema
```

Connection pool per schema (using `application_name` to identify pool); PgBouncer transaction-mode supports.

#### PostgreSQL Flex — Citus Elastic Cluster

```sql
SELECT create_distributed_table('orders', 'tenant_id');
```

Distributed table sharded by `tenant_id`. Queries include `tenant_id` → single-shard execution. Cross-tenant analytics → multi-shard.

### Per-tenant cost attribution

**Tagging strategy** (every resource):

```hcl
tags = {
  Environment      = "prod"
  Service          = "saas-app"
  TenantId         = var.tenant_id    # if silo / bridge
  TenantTier       = "enterprise"     # standard / premium / enterprise
  CostCenter       = "saas-product"
}
```

**Cost Management**:

- Export daily cost data to Storage (CSV / parquet) with tag columns.
- Power BI / Fabric to aggregate by `TenantId` tag.
- Per-tenant cost dashboard for internal use + (optionally) customer-facing.

**For pool model** (no per-tenant resources), cost attribution requires app-side telemetry:

- Track per-tenant request count + data volume + RU/s consumed.
- Allocate shared resource cost proportionally based on usage.
- Cosmos DB: per-partition-key RU consumption available via diagnostic logs.
- Azure SQL: per-DB metrics; Hyperscale Elastic Pool surfaces per-DB consumption.

### Tenant routing

#### Front Door per-tenant path or host

Single Front Door endpoint with rules:

- Path-based: `app.saas.com/tenants/{tenantId}/*` → origin per tier or shared origin with header
- Host-based: `{tenantId}.app.saas.com` → wildcard cert + dynamic routing
- Custom domain per tenant: `customer.com` mapped via managed certs + DNS verification

```bicep
// Front Door rule: extract tenantId from host header, add to request
resource rule 'Microsoft.Cdn/profiles/ruleSets/rules@2023-05-01' = {
  parent: ruleSet
  name: 'tenant-routing'
  properties: {
    order: 1
    conditions: [
      {
        name: 'HostName'
        parameters: {
          typeName: 'DeliveryRuleHostNameConditionParameters'
          operator: 'Equal'
          matchValues: ['.app.saas.com']
        }
      }
    ]
    actions: [
      {
        name: 'ModifyRequestHeader'
        parameters: {
          typeName: 'DeliveryRuleHeaderActionParameters'
          headerAction: 'Append'
          headerName: 'X-Tenant-ID'
          value: '<extracted from host>'
        }
      }
    ]
  }
}
```

#### APIM per-subscription tenancy

APIM subscriptions = developer/team-level keys, but can model tenants:

- Subscription per tenant
- Products group APIs available to tenant tier
- Policies for per-subscription rate limiting + quota
- Tenant identifier in JWT claim from External ID flow

### Noisy-neighbor controls

| Surface | Mechanism |
|---------|-----------|
| Cosmos DB | Per-partition RU limit (avoid single tenant exceeding ~10K RU/s of shared throughput); split throughput; isolation tier |
| Azure SQL Elastic Pool | `perDatabaseSettings.maxCapacity` caps a tenant's burst |
| App Service | Per-app CPU / memory limits (custom autoscale rules per tenant if needed) |
| APIM | Per-subscription rate limit + quota policies |
| Front Door | Rate-limit rules in WAF |
| Service Bus | Per-tenant queue or session ID partitioning; throttle per-session |

**Pattern: hard cap per tenant**. Even in pool model, app code enforces tenant quota (requests/min, storage GB, AI tokens/day). Exceeded → 429 with `Retry-After`.

### Tenant lifecycle automation

#### Provisioning

```bicep
module tenant 'tenant.bicep' = {
  name: 'tenant-${tenantId}'
  scope: subscription()
  params: {
    tenantId: tenantId
    tier: tier
    region: region
  }
}
```

Triggered by:

- Signup flow → Azure Function → ARM API to deploy template
- Or: signup creates record in tenant registry → background process provisions

**Time-to-provision target**: < 5 minutes for pool; < 30 minutes for bridge; < 2 hours for silo.

#### Suspension

- Revoke tenant's External ID users (block sign-in)
- Disable tenant's API key (APIM subscription state)
- Soft-disable DB (revoke RBAC; keep data for restore window)

#### Decommission

- Hard delete after retention period (GDPR considerations)
- Lifecycle policy on blob containers
- Drop schema / DB / partition

### Billing integration

**Pattern: Azure Marketplace Transact** for enterprise SaaS sold through Azure Marketplace:

- Customer purchases via Azure Marketplace; Azure handles billing.
- Your app receives webhook on subscription state changes.
- Per-seat / per-tier pricing handled by Marketplace.

**Pattern: Stripe for direct billing** (most SaaS):

- Stripe handles cards, subscriptions, dunning.
- App receives webhooks on subscription state.
- Map Stripe customer + subscription to app tenant.

**Pattern: usage-based billing**:

- App tracks usage per tenant (API calls, AI tokens, storage GB, etc.).
- Daily aggregation to Cosmos / SQL.
- Daily export to Stripe Metered Billing or Azure Marketplace Usage API.

**Anti-pattern: billing logic in app code**. Use Stripe / Marketplace; your app reports usage + reads subscription state.

### White-label / custom domain

Per-tenant custom domain:

- DNS verification via TXT record or CNAME.
- Managed cert auto-issued + auto-renewed via Front Door / App Service.
- Tenant config mapped from incoming host header.

**Pattern: certs as Key Vault Certificates**. Front Door reads from Key Vault; auto-renews via Key Vault's cert lifecycle.

## 2025-2026 platform reset items relevant to this role

- **Entra External ID** (rename of Azure AD B2C, 2024) — for CIAM.
- **Azure SQL Hyperscale Elastic Pools GA 2025-26** — purpose-built for multi-tenant SaaS DB-per-tenant.
- **Cosmos DB partition strategies** — DiskANN vector + hierarchical PK (preview / partial GA).
- **APIM v2 tiers (Standard v2 / Premium v2)** — new defaults for API management.
- **Front Door rule engine v2** — more flexible per-tenant routing.
- **Azure Marketplace Transact** — first-party billing for ISVs.
- **Cost Management exports to Fabric** — better tenant cost analytics.

## Patterns and anti-patterns

### Pattern: Hyperscale Elastic Pool for B2B DB-per-tenant

Per-tenant Hyperscale DB; pool shares compute; per-DB autonomy with shared cost. Sweet spot for 100-1000 tenants.

### Pattern: Cosmos partition-per-tenant for B2C / high-tenant-count

Single Cosmos account; partition key = `tenantId`; one container per logical entity (Users / Orders / Products). Every query filters by partition.

### Pattern: Entra External ID for customer auth + B2B for enterprise customers

Hybrid: customers without their own IdP use External ID local accounts; customers with Entra get B2B federation. Same app, multiple auth paths.

### Pattern: Tags + Cost Management for cost attribution

`TenantId` tag on every resource (silo / bridge model). Daily Cost Management export. Power BI / Fabric for per-tenant cost.

### Pattern: APIM subscription per tenant for API tenancy

Tenant gets an APIM subscription key. Per-subscription rate limit + quota. JWT validation policy verifies token from External ID.

### Pattern: Tenant registry as the source of truth

Small Cosmos / SQL DB stores: `tenantId`, `tier`, `region`, `state` (active / suspended / decommissioning), `customDomain`, `provisioningStatus`. Every other surface reads this.

### Pattern: White-label cert via Key Vault + Front Door

Customer brings cert (or auto-issued via DNS verification) → store in Key Vault → Front Door reads → SNI binding per domain.

### Anti-pattern: pure silo for high tenant count

Operational overhead explodes. Use Hyperscale Elastic Pool / Cosmos partition-per-tenant.

### Anti-pattern: pure pool for regulated customers

They'll ask for isolation evidence; you have none. Move enterprise tenants to silo / bridge.

### Anti-pattern: per-customer subscription without automation

Manual customer onboarding doesn't scale. Bicep + automation pipeline triggered by signup.

### Anti-pattern: tenant id in URL path without auth check

`/tenants/123/data` without verifying the JWT's `tenantId` claim matches → cross-tenant data leak. Auth middleware must enforce.

### Anti-pattern: new B2C tenant in 2026

Use Entra External ID.

### Anti-pattern: hard-coded tenant config in app

Tenant config (tier, features, custom domain, etc.) in DB or App Configuration with tenant-keyed entries. App reads at request time.

### Anti-pattern: shared App Configuration namespace for all tenants

Tenant config separation; either separate App Config stores or namespaced keys (`tenants/{tenantId}/feature.x`).

## Tooling specifics

- **Azure Resource Manager API** for tenant provisioning automation.
- **Bicep modules** for per-tenant resource templates.
- **`az sql db copy` / `az sql db replica create`** for tenant DB ops.
- **Front Door rule engine** for tenant routing.
- **APIM `subscription`** for tenant API keys.
- **Cost Management API** + **Fabric / Power BI** for tenant cost dashboards.
- **Entra External ID admin portal** for CIAM management.

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

Push back on:

- Tenant ID in URL without auth-side validation.
- New B2C tenant for net-new build.
- Pure pool for regulated customers.
- Hard-coded tenant config in code.
- No quota / rate limit per tenant.

### Debugging

- Tenant-tagged log queries: `requests | where customDimensions.tenantId == "abc"`.
- Per-tenant App Insights workspaces (or workspace-level + custom dimension filtering).
- Cost Management anomaly detection per-tenant.

## Cross-references to products_covered

| Product | Role usage |
|---------|------------|
| `Entra External ID` | CIAM for customer auth |
| `Microsoft Entra ID` (B2B) | Enterprise customer SSO |
| `Azure SQL Database` (Hyperscale Elastic Pools) | DB-per-tenant in pool |
| `Cosmos DB for NoSQL` | Partition-per-tenant for high count |
| `PostgreSQL Flexible Server` (Citus) | Distributed-by-tenant |
| `Front Door` | Tenant routing + custom domains |
| `API Management` | API tenancy via subscriptions |
| `App Configuration` | Per-tenant feature flags |
| `Cost Management` | Per-tenant attribution |
| `Azure Marketplace` | First-party SaaS billing |

## When to refresh this overlay

- Hyperscale Elastic Pool feature changes
- Entra External ID feature changes
- New per-tenant isolation mechanism in Cosmos / SQL
- APIM tenancy feature changes
- Azure Marketplace pricing model changes

Target refresh cadence: every 6 months.
