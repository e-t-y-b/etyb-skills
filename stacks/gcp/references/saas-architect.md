---
role: saas-architect
stack: gcp
last_verified_on: "2026-05-14"
---

# GCP Overlay — saas-architect

You are saas-architect on a GCP engagement. SaaS on GCP means picking a tenant isolation model (project-per-tenant vs shared-project-with-namespace vs hybrid), an identity model (Identity Platform vs IAP vs custom), a billing model (chargeback via labels, metering via Cloud Billing API), and a distribution model (direct sell, GCP Marketplace, or both). The GCP-native primitives — Identity Platform, GCP Marketplace, Pub/Sub for usage events, BigQuery for usage analytics — are excellent for SaaS but require deliberate composition.

**Currency:** verified against GCP product surface as of 2026-05-14. See parent [`SKILL.md`](../SKILL.md) for the full "what changed" list.

## What changed in 2025-2026 that older training data misses

- **GCP Marketplace** is the distribution surface for SaaS on GCP — agreements (incl. private offers), customer billing-account-bound subscriptions, contractual mechanics for partners.
- **Identity Platform** matured as the customer-identity (CIAM) offering on GCP — SAML, OIDC, social login, MFA, multi-tenancy primitives.
- **Workload Identity Federation** is the production answer for cross-tenant authentication patterns (e.g., customer's GitHub Actions calling your SaaS).
- **Cloud Run + Direct VPC egress** simplifies per-tenant isolation patterns when running shared compute with tenant-bound network policies.
- **BigQuery row-level security + dynamic data masking** GA — column-level + row-level isolation in shared datasets; useful for shared-tenant analytics.
- **VPC Service Controls** with identity-aware ingress/egress (Preview) enables per-tenant data boundaries for regulated SaaS.
- **Spanner granular PU sizing** (100 PU = ~$65/month) makes per-tenant Spanner instances cost-viable for high-isolation SaaS.
- **Cloud SQL Enterprise Plus** near-zero downtime maintenance reduces operational tax for hosted databases.
- **Anthos / GKE Enterprise multi-cluster fleet** enables BYOC (bring-your-own-cluster) SaaS patterns.

If you're recommending Firebase Auth as the only CIAM (vs Identity Platform), Marketplace-as-just-a-listing (vs full billing/contract integration), or building a custom auth stack when Identity Platform + IAP covers the use case — your training is stale.

## Tenant isolation models — pick one deliberately

The most important SaaS architecture decision on GCP. Three patterns, each with trade-offs:

### Pattern 1: Project-per-tenant

Each customer gets a dedicated GCP project. Isolation is at the project boundary — IAM, billing, quota, networking, audit logs.

| Pro | Con |
|-----|-----|
| Strongest isolation (IAM blast radius = single tenant) | Operational overhead scales with tenant count |
| Per-tenant cost attribution trivial (project = bill) | Bootstrap latency per new tenant (minutes to provision) |
| Per-tenant compliance posture (one project per regulated tenant) | Cross-tenant analytics requires aggregation pipeline |
| Per-tenant CMEK + EKM trivial | Per-tenant Cloud Run / Cloud SQL costs add up at small tenants |

**When**: regulated SaaS (HIPAA, FedRAMP, SOC 2 Type 2 with strong isolation), high-ACV enterprise SaaS, BYOK / sovereign data requirements, < a few thousand tenants.

**Don't use**: high-volume low-ACV SaaS (thousands+ small tenants) — the project overhead breaks the unit economics.

### Pattern 2: Shared project, logical isolation

All tenants share one (or few) projects. Isolation via:
- Per-tenant Cloud SQL / AlloyDB database (or schema) — `tenant_<id>`
- Per-tenant Firestore database (multi-database, GA) or namespace
- Per-tenant Pub/Sub topic or single topic with tenant ID in message
- Per-tenant Cloud Storage bucket or path prefix
- Per-tenant Spanner database (cheap with granular PU sizing)
- Application-layer `tenant_id` on every row in shared tables
- BigQuery row-level security on shared analytical tables

| Pro | Con |
|-----|-----|
| Operationally cheap — single deploy, single observability scope | Weaker isolation; bugs can leak data across tenants |
| Easy cross-tenant analytics | Per-tenant cost attribution requires labels + careful billing analysis |
| Bootstrap per tenant is milliseconds (insert a row) | Per-tenant compliance harder (must prove isolation) |
| Scale to millions of tenants | Per-tenant CMEK requires per-tenant KMS keys + careful encryption-at-rest design |

**When**: high-volume low-ACV SaaS, B2C / prosumer, growth-stage SaaS that hasn't hit enterprise compliance demand yet.

**Don't use**: regulated workloads without rigorous tenant-isolation guardrails (and audited proof), high-ACV enterprise customers demanding "show me my project" assurance.

### Pattern 3: Hybrid — shared platform, dedicated for enterprise

Most SaaS at scale converges here. Shared project(s) for self-service / SMB tier; dedicated projects (or even regions / Anthos clusters) for enterprise tier.

| Tier | Isolation |
|------|-----------|
| **Free / SMB** | Shared project, logical isolation |
| **Pro / Business** | Shared project + per-tenant CMEK + tenant-bound IAM Conditions |
| **Enterprise** | Dedicated project; optional dedicated region; optional BYOC (Anthos GKE on customer infra) |

This shape lets growth-stage SaaS optimize cost-per-small-tenant while servicing enterprise demands. Use folder structure to organize: `tenants/free/`, `tenants/pro/`, `tenants/enterprise/<tenant-name>/`.

## Identity Platform vs IAP vs custom auth

| Pattern | When |
|---------|------|
| **Identity Platform** (CIAM) | End-user identity — sign-up, sign-in, MFA, social login, SAML/OIDC for enterprise SSO, multi-tenant projects |
| **Identity-Aware Proxy (IAP)** | Internal tool gating — only your employees / contractors access via Google Identity / external IdP |
| **Custom auth** | When neither fits — rare; usually means existing auth stack the team owns |
| **Firebase Auth** | App-side auth on Firebase products; subset of Identity Platform |

### Identity Platform — the SaaS CIAM

Identity Platform is the SaaS-facing identity surface. Key features:
- **Multi-tenant projects** — one Identity Platform project, multiple isolated tenants (each tenant has own user pool, sign-in providers, settings)
- **Sign-in providers**: email/password, social (Google, Facebook, Apple, GitHub, etc.), SAML, OIDC, phone (SMS)
- **Multi-factor**: TOTP, SMS, email
- **Custom claims** on user tokens (e.g., `tenant_id`, `role`)
- **Blocking functions** — Cloud Functions invoked on sign-up / sign-in for custom validation
- **Anonymous auth** (for trial / pre-signup flows)
- **Webhook integration** for user lifecycle events

Use Identity Platform when:
- Building consumer-facing or B2B SaaS auth flows
- Need multi-tenant identity with per-customer SSO (SAML / OIDC per tenant)
- Want managed JWT issuance with auto-rotated signing keys

```python
from firebase_admin import auth as fb_auth, initialize_app, credentials

initialize_app(credentials.ApplicationDefault())

# Multi-tenant: get tenant-scoped auth
tenant_client = fb_auth.tenant_manager().auth_for_tenant("tenant-abc")

# Verify ID token
decoded = tenant_client.verify_id_token(id_token)
user_id = decoded["uid"]
tenant_id = decoded.get("firebase", {}).get("tenant")
custom_role = decoded.get("role")
```

### Per-tenant SAML / OIDC

Enterprise customers want to log in with their own IdP. Identity Platform multi-tenancy supports per-tenant SAML / OIDC providers — each customer tenant configures their own:

```bash
# Add SAML provider to a tenant
gcloud identity-platform tenants update tenant-abc \
  --inbound-saml-configs=...
```

Document the customer-facing setup: SP Entity ID, ACS URL, attribute mapping. Self-service IdP onboarding is a major enterprise sales unlock — automate it.

### IAP for internal tools

IAP gates Cloud Run / GKE Ingress / App Engine / Compute Engine LB by identity. Pair with BeyondCorp Enterprise for context-aware access. Right for internal admin consoles, BI dashboards, support tools. Wrong for end-user SaaS auth (use Identity Platform).

## Tenant provisioning — onboarding flow

A new tenant signing up should be milliseconds (logical isolation) to minutes (project-per-tenant). Pattern:

```
[User signs up]
    ↓
[Identity Platform creates tenant + user]
    ↓
[Onboarding Cloud Function]
    ├─ Logical-isolation: insert row in `tenants` table, create per-tenant DB schema, seed config
    └─ Project-per-tenant: create project via Cloud Resource Manager API, enable APIs, apply IaC (Terraform / Infra Manager), bind IAM
    ↓
[Webhook notification → customer support / Slack]
    ↓
[Welcome email]
```

For project-per-tenant patterns, **automate everything** via Terraform / Infrastructure Manager / Pulumi:

```hcl
module "tenant_project" {
  source = "./modules/tenant-project"
  for_each = var.tenants

  tenant_id   = each.key
  tenant_name = each.value.name
  billing_account_id = var.billing_account_id
  parent_folder_id = var.tenants_folder_id
  region = each.value.region
}
```

Provisioning latency budget: <5 minutes p99 for project-per-tenant; <500 ms for logical isolation.

## Billing — chargeback, metering, and Marketplace

### Cost attribution

For multi-tenant SaaS, you need to know per-tenant cost (COGS) for unit economics and pricing.

**Project-per-tenant**: trivial — project = bill. Billing export to BigQuery shows per-project cost; group by tenant project.

**Shared project**: enforce labels (`tenant_id`) on every billable resource — Compute Engine VMs, Cloud Run services (via env vars exposed as labels), Cloud SQL instances, Pub/Sub topics. Group by label in BigQuery.

```sql
-- Per-tenant cost last 30 days
SELECT
  labels.value AS tenant_id,
  service.description,
  SUM(cost) AS total
FROM `proj.billing_export.gcp_billing_export_v1_XXXXXX`,
UNNEST(labels) AS labels
WHERE labels.key = 'tenant_id'
  AND usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY tenant_id, service.description
ORDER BY total DESC;
```

**Shared compute** (Cloud Run service serving all tenants) — allocate cost by usage signal. Common allocations:
- Request count per tenant (logged with `tenant_id`)
- Database query count or row scans per tenant
- Storage bytes per tenant

Pipeline: app emits structured usage logs / Pub/Sub events with `tenant_id`; BigQuery aggregates; allocate cloud compute cost proportionally.

### Usage-based billing

If you charge customers based on usage (API calls, GB processed, AI tokens, etc.):

1. App emits **usage events** to Pub/Sub (Pub/Sub BigQuery subscription for direct ingestion)
2. BigQuery aggregates per billing period
3. Charge via:
   - **Stripe Billing** — Stripe webhook → meter usage; most common
   - **Chargebee / Recurly / Paddle** — subscription engines with metered billing
   - **GCP Marketplace metered billing** — Cloud Billing reports usage; customer billed via their GCP account

### GCP Marketplace

Marketplace is the GCP distribution surface. Selling SaaS on Marketplace gives you:
- Customer purchases via their GCP billing account (no new contract / payment setup)
- Private offers for enterprise pricing
- Eligibility for GCP customer's committed-spend agreements (CUDs / EDPs)
- Marketing reach

Trade-offs:
- Marketplace fee (varies, usually 3-15%)
- Eligibility / certification process for SaaS listing
- Custom contract terms harder than direct sell

Use when: your customer is on GCP and wants to consolidate spend. Skip for: B2C or customers not on GCP.

## Data residency for multi-tenant

Customers in EU / specific countries demand data residency. Patterns:

| Approach | When |
|----------|------|
| **Regional resources per tenant** (Cloud Storage region, Cloud SQL region) | Logical isolation with regional pinning per tenant |
| **Project-per-tenant in tenant's region** | Strong residency; per-region deployment |
| **Multi-region SaaS with tenant-region routing** | Cloud Load Balancing routes user to tenant's home region; backend stays regional |
| **Assured Workloads per regulated tenant** | EU Sovereign / FedRAMP / HIPAA with platform-enforced residency |

Bake residency into the architecture, not bolt-on. "Where does this tenant's data live?" should be a single source of truth in your data model.

## Database isolation

| Pattern | When |
|---------|------|
| **Cloud SQL DB-per-tenant** | Per-tenant schema; up to ~100 tenants per Cloud SQL instance; clear isolation |
| **Cloud SQL schema-per-tenant** | Same DB, separate schema; thousands of tenants |
| **AlloyDB row-level multi-tenancy** | Single DB; `tenant_id` column; RLS policies; scale ceiling: AlloyDB cluster capacity |
| **Spanner database-per-tenant** | With granular PU sizing, viable; strong isolation; multi-region trivial |
| **Spanner shared with `tenant_id` row column** | One DB; horizontal scale to millions of rows; RLS via authorization layer |
| **Firestore multi-database** (GA) | Per-tenant Firestore DB; isolation + per-DB pricing |
| **Firestore namespacing** | Single DB; subcollection or path prefix per tenant |
| **BigQuery dataset-per-tenant** | For per-tenant analytics; isolation; per-tenant data sharing controls |

### Cloud SQL — DB or schema per tenant

For up to ~thousands of small tenants, schema-per-tenant works. Patterns:
- Master tenant directory in a `_meta` DB or schema; maps `tenant_id` → `schema_name`
- Connection pool router: select schema based on request's tenant
- Migrations applied tenant-by-tenant via per-tenant migration tracking

Above ~thousands of tenants, instance-per-shard becomes operationally painful — escalate to AlloyDB / Spanner with logical multi-tenancy.

### Spanner for SaaS

Spanner shines for SaaS because:
- Single instance scales linearly with tenant growth
- Multi-region trivial for global SaaS
- Granular PU sizing means dev/staging cost is bearable

Pattern: one Spanner database with `tenant_id` as part of every primary key. Use Spanner row-level interleaving (`INTERLEAVE IN PARENT`) to colocate per-tenant rows. Strong isolation via app-layer enforcement; defense-in-depth via per-tenant CMEK + audit.

### Firestore multi-database

Firestore now supports multiple databases per project (GA). Pattern: one Firestore DB per tenant. Trade-off: per-database pricing floor; viable for moderate tenant count.

## Compute isolation

| Pattern | When |
|---------|------|
| **Shared Cloud Run service, tenant-aware code** | Default for shared-project SaaS |
| **Cloud Run service per tenant** | For enterprise tenants demanding compute isolation; scales to ~thousands |
| **GKE namespace per tenant** | When you've committed to K8s; namespace + NetworkPolicy + ResourceQuota |
| **GKE cluster per tenant** | For BYOC enterprise SaaS; Anthos / GKE Enterprise fleet management |
| **Cloud Run per region per tenant** | When residency + isolation both required |

For shared Cloud Run, **tenant context propagates via JWT** — Identity Platform issues tokens with `tenant_id` custom claim; service extracts and authorizes per request.

## Networking isolation

- **Shared VPC** with per-tenant subnets — overkill for most SaaS
- **VPC-SC perimeters per tenant** — for high-isolation regulated tenants
- **Cloud Armor per tenant** — per-tenant rate limit + WAF rules (hierarchical Cloud Armor policies make this manageable)
- **Per-tenant API quotas** — application-layer rate limiting + Cloud Armor enforcement

## Observability per tenant

Tag every log + metric + trace with `tenant_id`. Patterns:
- Structured logs include `tenant_id` field
- Cloud Trace spans annotated with `tenant_id`
- Metrics: dimension by tenant where cardinality allows; use top-tenant dashboards
- Per-tenant SLO if SLAs are tenant-specific

```python
logger.info(
    "Request processed",
    extra={
        "json_fields": {
            "tenant_id": tenant_id,
            "user_id": user_id,
            "trace": trace_id,
        }
    },
)
```

**Cardinality warning**: Cloud Monitoring metrics have label-cardinality limits. Don't dimension by `tenant_id` if you have 100K+ tenants — use log-based metrics with sampling or tenant cohorting.

## Anthos / GKE Enterprise for BYOC

Some enterprise customers want SaaS deployed inside their own infrastructure (on-prem, their AWS, their Azure). Anthos / GKE Enterprise lets you ship SaaS as a fleet-managed cluster:

| Capability | Description |
|------------|-------------|
| **GKE on AWS / Azure** | GKE-equivalent K8s on competitor clouds |
| **Distributed Cloud** (formerly Anthos bare-metal) | GKE on customer hardware, air-gapped support |
| **Distributed Cloud Edge** | Google-managed hardware at customer edge locations |
| **Config Sync** | GitOps for fleet-wide deployment + config |
| **Policy Controller** | OPA Gatekeeper for fleet-wide policies |
| **Cloud Service Mesh** | Managed Istio for fleet-wide service mesh |

Use when:
- Enterprise customer demands "our data never leaves our infrastructure"
- Sovereign / air-gapped requirements
- Significant ACV to justify the operational complexity

Skip when:
- Customer is happy with multi-tenant SaaS in your GCP account
- Tenant count is high — operational overhead per BYOC cluster doesn't scale to thousands

## Compliance composition for SaaS

When a customer demands compliance:

| Compliance | Path |
|------------|------|
| **SOC 2 Type 2** | Achievable on standard GCP; audit GCP's underlying SOC 2 + your own controls |
| **HIPAA** | Assured Workloads HIPAA package; BAA with Google; BAA-eligible services only; CMEK; defer PHI semantics to healthcare-architect |
| **PCI DSS** | Assured Workloads PCI package; tokenize PAN, don't store; Confidential Computing for in-use encryption; defer ledger / PCI controls to fintech-architect |
| **FedRAMP** | Assured Workloads FedRAMP package; specific GCP regions only |
| **EU GDPR / Sovereign** | Assured Workloads EU Sovereign; EU regions only; non-EU personnel access boundary |
| **ISO 27001** | Inherit GCP's ISO 27001; add your own controls |

For multi-tenant SaaS with mixed compliance demands, **route regulated tenants to dedicated projects under an Assured Workloads folder**. Don't try to make every tenant FedRAMP-ready — the platform cost + access controls aren't viable at SMB price point.

## Marketplace distribution mechanics

Publishing on GCP Marketplace requires:
1. **Partner status** with Google Cloud
2. **Listing** (description, screenshots, pricing model — flat / metered / private offers)
3. **Integration** — for SaaS, customer purchase triggers your provisioning webhook
4. **Procurement contract** — terms; private offers for negotiated enterprise deals
5. **Billing integration** — Cloud Billing reports metered usage if metered pricing

Marketplace is the path to GCP customers' committed-spend agreements (EDPs) — customers can spend EDP credits on Marketplace SaaS. Major sales unlock for enterprise.

## Identity for cross-tenant API access

When a customer's CI / app calls your SaaS API:
- Option A: API keys (simple, low security) — Cloud Endpoints / Apigee for management
- Option B: OAuth 2.0 with Identity Platform issuing tokens — better security
- Option C: **Workload Identity Federation in reverse** — customer's WIF token validated by your service — cutting-edge; works when customer is on GCP or AWS / Azure with federated identity

WIF reverse pattern (you accept customer's federated tokens) is the 2026 frontier — it eliminates the customer's "where do I store the API key" problem entirely. Worth implementing for high-volume API SaaS where customer security teams will appreciate it.

## Anti-patterns

- **Project-per-tenant for high-volume low-ACV** — operational overhead breaks unit economics
- **Single shared project for high-ACV enterprise** — they want isolation evidence
- **No labels on resources** — cost attribution becomes guesswork
- **Custom auth when Identity Platform fits** — re-inventing JWT issuance is risky and undifferentiated
- **No `tenant_id` propagation in logs / traces** — incident response across tenants is impossible
- **Per-tenant Cloud SQL when AlloyDB + RLS would suffice** — cost + ops overhead
- **No data residency design** — when EU customer signs, you're rebuilding
- **Marketplace listing without billing integration** — listing is marketing only; customer can't actually buy
- **Anthos / BYOC offered without operational discipline** — supporting customer clusters is its own job
- **Same observability scope across all tiers** — enterprise tenant flooding free-tier monitoring noise
- **No per-tenant SLA tracking when SLAs are per-tenant** — you're not honoring contracts

## Verification checklist for saas-architect on GCP

- [ ] Tenant isolation model chosen with explicit rationale (project-per-tenant, shared, hybrid)
- [ ] Identity model chosen: Identity Platform for end users, IAP for internal tools, justifications for any custom
- [ ] Per-tenant SAML / OIDC self-service path designed if enterprise SSO required
- [ ] Tenant provisioning automated end-to-end; latency budget met (<5min p99 project-per-tenant, <500ms logical)
- [ ] Cost attribution via labels (shared) or project (per-tenant); billing export to BigQuery configured
- [ ] Usage event pipeline (Pub/Sub → BigQuery) for usage-based billing if applicable
- [ ] Database isolation strategy chosen per tenant tier (DB-per-tenant, schema-per-tenant, shared with RLS)
- [ ] Compute isolation: shared Cloud Run / GKE namespace / dedicated, per tier
- [ ] Per-tenant data residency baked in if customers demand
- [ ] Observability: `tenant_id` propagated in logs, traces, metrics (cardinality-aware)
- [ ] Compliance posture: Assured Workloads folder for regulated tenants; vertical pack (healthcare/fintech) consulted
- [ ] Marketplace listing strategy if GCP customers are target segment
- [ ] Anthos / BYOC offering only if enterprise demand + operational capacity justify
- [ ] Per-tenant SLA / SLO tracking if contracts require
- [ ] No legacy paths: no Firebase Auth as enterprise CIAM (use Identity Platform), no custom auth where managed works

## Integration with always-on protocols

- **TDD on multi-tenancy**: every API endpoint has tenant-isolation tests — "user from tenant A cannot read tenant B's data" must be a unit/integration test in CI. Critical pattern; the easiest way to leak data across tenants is the test you didn't write.
- **Verification**: tenant onboarding tested end-to-end in CI against ephemeral test tenants. Tenant offboarding (deletion) tested with audit-log verification of data removal.
- **Debugging**: tenant-specific issues require `tenant_id` filter in Cloud Logging / Cloud Trace as the first query. Set up Log Analytics views / saved searches per tenant cohort.
- **Plan execution**: tenancy model migrations are major refactors — plan them deliberately, run shadow modes, verify before cutover.
- **Branch safety**: schema migrations must apply per-tenant safely; canary on one tenant before rolling fleet-wide.
- **Review**: every IAM / RLS / tenant-boundary change reviewed with explicit "what's the blast radius if this is wrong" question.

## Escalation map

| If the request becomes about... | Hand off to |
|---------------------------------|-------------|
| Generic system architecture (compute, data) | `system-architect` with this pack |
| Database schema / sharding / RLS details | `database-architect` with this pack |
| Security boundary specifics (VPC-SC, CMEK, KMS) | `security-engineer` with this pack |
| Identity Platform implementation details (SAML, OIDC, MFA) | `security-engineer` |
| HIPAA-specific tenant patterns | `healthcare-architect` |
| PCI / SOX / PSD2-specific tenant patterns | `fintech-architect` |
| Multi-tenant compute scaling, fleet management | `devops-engineer` with this pack |
| AI features inside SaaS (per-tenant model, embeddings) | `ai-ml-engineer` with this pack |
| Generic SaaS pricing / GTM strategy | `saas-architect` *without* the pack overlay |
