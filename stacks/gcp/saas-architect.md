---
title: saas-architect on GCP
description: SaaS architecture on GCP — tenant isolation models (project-per-tenant vs shared), Identity Platform, Marketplace, cost attribution, Anthos BYOC, compliance composition.
role_overlay:
  role: saas-architect
  stack: gcp
  last_verified_on: "2026-05-14"
  products_covered:
    - cloud-run
    - gke
    - gke-autopilot
    - anthos
    - cloud-sql
    - alloydb
    - spanner
    - firestore
    - bigquery
    - pub-sub
    - cloud-iam
    - cloud-kms
    - vpc
    - cloud-armor
    - logging
    - monitoring
    - vertex-ai
---

## Role briefing

You are saas-architect on a GCP engagement. SaaS on GCP means picking a **tenant isolation model** (project-per-tenant vs shared-project-with-namespace vs hybrid), an **identity model** (Identity Platform vs IAP vs custom), a **billing model** (chargeback via labels, metering via Cloud Billing API), and a **distribution model** (direct sell, GCP Marketplace, or both).

The GCP-native primitives — Identity Platform, GCP Marketplace, Pub/Sub for usage events, BigQuery for usage analytics — are excellent for SaaS but require deliberate composition.

## What changed in 2025-2026 that older training data misses

- **GCP Marketplace** is the distribution surface for SaaS on GCP — agreements (incl. private offers), customer billing-account-bound subscriptions.
- **Identity Platform** matured as CIAM — SAML, OIDC, social, MFA, multi-tenancy primitives.
- **Workload Identity Federation** is the production answer for cross-tenant authentication (customer's GitHub Actions calling your SaaS).
- **Cloud Run + Direct VPC egress** simplifies per-tenant isolation when running shared compute with tenant-bound network policies.
- **BigQuery row-level security + dynamic data masking** GA — shared-tenant analytics with isolation.
- **VPC Service Controls** with identity-aware ingress/egress (Preview) — per-tenant data boundaries for regulated SaaS.
- **[Spanner](/stacks/gcp/spanner/) granular PU sizing** (100 PU = ~$65/month) makes per-tenant Spanner instances cost-viable.
- **Cloud SQL Enterprise Plus** near-zero downtime maintenance.
- **Anthos / GKE Enterprise multi-cluster fleet** enables BYOC SaaS patterns.

If you're recommending Firebase Auth as the only CIAM (vs Identity Platform), Marketplace-as-just-a-listing (vs full billing/contract integration), or building custom auth when Identity Platform + IAP covers — your training is stale.

## Tenant isolation models — pick one deliberately

### Pattern 1: Project-per-tenant

Each customer gets a dedicated GCP project. Isolation at project boundary — IAM, billing, quota, networking, audit logs.

| Pro | Con |
|-----|-----|
| Strongest isolation | Operational overhead scales with tenant count |
| Per-tenant cost attribution trivial (project = bill) | Bootstrap latency (minutes per new tenant) |
| Per-tenant compliance posture | Cross-tenant analytics requires aggregation pipeline |
| Per-tenant CMEK + EKM trivial | Per-tenant Cloud Run / Cloud SQL costs add up at small tenants |

**When**: regulated SaaS (HIPAA, FedRAMP, SOC 2 Type 2 with strong isolation), high-ACV enterprise, BYOK / sovereign data requirements, < a few thousand tenants.

**Don't use**: high-volume low-ACV (thousands+ small tenants) — project overhead breaks unit economics.

### Pattern 2: Shared project, logical isolation

All tenants share one (or few) projects. Isolation via:
- Per-tenant [Cloud SQL](/stacks/gcp/cloud-sql/) / [AlloyDB](/stacks/gcp/alloydb/) database (or schema) — `tenant_<id>`
- Per-tenant [Firestore](/stacks/gcp/firestore/) database (multi-database, GA) or namespace
- Per-tenant [Pub/Sub](/stacks/gcp/pub-sub/) topic or single topic with tenant ID in message
- Per-tenant [Cloud Storage](/stacks/gcp/cloud-storage/) bucket or path prefix
- Per-tenant [Spanner](/stacks/gcp/spanner/) database (cheap with granular PU)
- Application-layer `tenant_id` on every row in shared tables
- [BigQuery](/stacks/gcp/bigquery/) row-level security on shared analytical tables

| Pro | Con |
|-----|-----|
| Operationally cheap | Weaker isolation; bugs can leak data |
| Easy cross-tenant analytics | Per-tenant cost attribution requires labels |
| Bootstrap per tenant in milliseconds | Per-tenant compliance harder (must prove isolation) |
| Scale to millions of tenants | Per-tenant CMEK requires per-tenant KMS keys |

**When**: high-volume low-ACV, B2C / prosumer, growth-stage without enterprise compliance demand.

**Don't use**: regulated without rigorous tenant-isolation guardrails (and audited proof), high-ACV enterprise demanding "show me my project."

### Pattern 3: Hybrid

Most SaaS at scale converges here. Shared project(s) for self-service / SMB; dedicated for enterprise tier.

| Tier | Isolation |
|------|-----------|
| **Free / SMB** | Shared project, logical isolation |
| **Pro / Business** | Shared project + per-tenant CMEK + tenant-bound IAM Conditions |
| **Enterprise** | Dedicated project; optional dedicated region; optional BYOC ([Anthos](/stacks/gcp/anthos/) GKE on customer infra) |

Use folder structure: `tenants/free/`, `tenants/pro/`, `tenants/enterprise/<tenant-name>/`.

## Identity Platform vs IAP vs custom auth

| Pattern | When |
|---------|------|
| **Identity Platform** (CIAM) | End-user identity — sign-up, sign-in, MFA, social, SAML/OIDC for enterprise SSO, multi-tenant projects |
| **Identity-Aware Proxy (IAP)** | Internal tool gating — employees / contractors only |
| **Custom auth** | Rare; usually existing auth stack |
| **Firebase Auth** | Subset of Identity Platform; app-side auth on Firebase products |

### Identity Platform — the SaaS CIAM

Key features:
- **Multi-tenant projects** — one Identity Platform project, multiple isolated tenants
- **Sign-in providers**: email/password, social, SAML, OIDC, phone
- **MFA**: TOTP, SMS, email
- **Custom claims** on user tokens
- **Blocking functions** for custom validation
- **Anonymous auth**
- **Webhook integration** for user lifecycle events

```python
from firebase_admin import auth as fb_auth, initialize_app, credentials

initialize_app(credentials.ApplicationDefault())

tenant_client = fb_auth.tenant_manager().auth_for_tenant("tenant-abc")
decoded = tenant_client.verify_id_token(id_token)
user_id = decoded["uid"]
tenant_id = decoded.get("firebase", {}).get("tenant")
```

### Per-tenant SAML / OIDC

Enterprise customers want their own IdP. Identity Platform multi-tenancy supports per-tenant SAML / OIDC providers. **Self-service IdP onboarding is a major enterprise sales unlock — automate it.**

### IAP for internal tools

IAP gates Cloud Run / GKE Ingress / App Engine / Compute Engine LB by identity. Pair with BeyondCorp Enterprise. Right for internal admin consoles, BI dashboards, support tools. Wrong for end-user SaaS auth.

## Tenant provisioning — onboarding flow

```
[User signs up]
    ↓
[Identity Platform creates tenant + user]
    ↓
[Onboarding Cloud Function]
    ├─ Logical-isolation: insert row, create per-tenant DB schema, seed config
    └─ Project-per-tenant: create project via Cloud Resource Manager API, enable APIs, apply IaC, bind IAM
    ↓
[Webhook notification → customer support / Slack]
    ↓
[Welcome email]
```

For project-per-tenant, **automate everything** via Terraform / Infrastructure Manager / Pulumi. Provisioning latency budget: <5 min p99 project-per-tenant; <500 ms logical isolation.

## Billing — chargeback, metering, Marketplace

### Cost attribution

**Project-per-tenant**: trivial — project = bill.

**Shared project**: enforce labels (`tenant_id`) on every billable resource. Group by label in BigQuery:

```sql
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

**Shared compute** (Cloud Run service serving all tenants) — allocate cost by usage signal (request count, query count, storage bytes per tenant). App emits structured usage logs / Pub/Sub events with `tenant_id`; BigQuery aggregates; allocate compute cost proportionally.

### Usage-based billing

If you charge by usage:
1. App emits **usage events** to [Pub/Sub](/stacks/gcp/pub-sub/) (BigQuery subscription for direct ingestion)
2. BigQuery aggregates per billing period
3. Charge via:
   - **Stripe Billing** — webhook → meter usage; most common
   - **Chargebee / Recurly / Paddle**
   - **GCP Marketplace metered billing** — customer billed via their GCP account

### GCP Marketplace

Selling SaaS on Marketplace:
- Customer purchases via their GCP billing account
- Private offers for enterprise pricing
- Eligibility for GCP customer's committed-spend agreements (CUDs / EDPs) — major sales unlock
- Marketing reach
- Marketplace fee (3-15%, varies)

Use when: customer is on GCP and wants to consolidate spend. Skip for: B2C or customers not on GCP.

## Data residency for multi-tenant

| Approach | When |
|----------|------|
| **Regional resources per tenant** | Logical isolation with regional pinning per tenant |
| **Project-per-tenant in tenant's region** | Strong residency; per-region deployment |
| **Multi-region SaaS with tenant-region routing** | Cloud Load Balancing routes to tenant's home region |
| **Assured Workloads per regulated tenant** | EU Sovereign / FedRAMP / HIPAA with platform-enforced residency |

**Bake residency into the architecture, not bolt-on.** "Where does this tenant's data live?" should be a single source of truth in your data model.

## Database isolation

| Pattern | When |
|---------|------|
| **Cloud SQL DB-per-tenant** | Per-tenant schema; up to ~100 tenants per instance |
| **Cloud SQL schema-per-tenant** | Same DB, separate schema; thousands of tenants |
| **AlloyDB row-level multi-tenancy** | Single DB; `tenant_id` column; RLS policies |
| **Spanner database-per-tenant** | Granular PU makes it viable; multi-region trivial |
| **Spanner shared with `tenant_id`** | One DB; horizontal scale to millions of rows |
| **Firestore multi-database** (GA) | Per-tenant Firestore DB |
| **Firestore namespacing** | Single DB; subcollection per tenant |
| **BigQuery dataset-per-tenant** | Per-tenant analytics |

### Spanner for SaaS

Single instance scales linearly with tenant growth; multi-region trivial for global SaaS; granular PU sizing means dev/staging cost is bearable. Pattern: one [Spanner](/stacks/gcp/spanner/) database with `tenant_id` as part of every primary key; interleave per-tenant rows.

## Compute isolation

| Pattern | When |
|---------|------|
| **Shared Cloud Run service, tenant-aware code** | Default for shared-project SaaS |
| **[Cloud Run](/stacks/gcp/cloud-run/) service per tenant** | Enterprise tenants demanding compute isolation |
| **GKE namespace per tenant** | Committed to K8s; namespace + NetworkPolicy + ResourceQuota |
| **GKE cluster per tenant** | BYOC enterprise SaaS; [Anthos](/stacks/gcp/anthos/) fleet |
| **Cloud Run per region per tenant** | Residency + isolation both required |

For shared Cloud Run, **tenant context propagates via JWT** — Identity Platform issues tokens with `tenant_id` custom claim; service extracts and authorizes per request.

## Observability per tenant

Tag every log + metric + trace with `tenant_id`:
- Structured logs include `tenant_id` field
- Cloud Trace spans annotated with `tenant_id`
- Metrics: dimension by tenant where cardinality allows; top-tenant dashboards
- Per-tenant SLO if SLAs are tenant-specific

**Cardinality warning**: [Cloud Monitoring](/stacks/gcp/monitoring/) has label-cardinality limits. Don't dimension by `tenant_id` if you have 100K+ tenants — use log-based metrics with sampling or tenant cohorting.

## Anthos / GKE Enterprise for BYOC

See [Anthos / GKE Enterprise](/stacks/gcp/anthos/). Use when:
- Enterprise demands "our data never leaves our infrastructure"
- Sovereign / air-gapped requirements
- Significant ACV to justify operational complexity

Skip when:
- Customer happy with multi-tenant SaaS in your GCP account
- High tenant count — operational overhead per BYOC cluster doesn't scale

## Compliance composition for SaaS

| Compliance | Path |
|------------|------|
| **SOC 2 Type 2** | Achievable on standard GCP |
| **HIPAA** | Assured Workloads HIPAA; BAA-eligible services; CMEK; defer PHI semantics to healthcare-architect |
| **PCI DSS** | Assured Workloads PCI; tokenize PAN; Confidential Computing; defer to fintech-architect |
| **FedRAMP** | Assured Workloads FedRAMP; specific regions |
| **EU GDPR / Sovereign** | Assured Workloads EU Sovereign; EU regions; non-EU personnel boundary |
| **ISO 27001** | Inherit GCP's ISO 27001 + your own controls |

For multi-tenant with mixed compliance, **route regulated tenants to dedicated projects under an Assured Workloads folder**. Don't try to make every tenant FedRAMP-ready.

## Identity for cross-tenant API access

When a customer's CI / app calls your SaaS API:
- **API keys** (simple, low security) — Cloud Endpoints / Apigee for management
- **OAuth 2.0 with Identity Platform** — better security
- **WIF in reverse** — accept customer's federated tokens; cutting-edge 2026 pattern; eliminates "where do I store the API key"

WIF reverse is worth implementing for high-volume API SaaS where customer security teams will appreciate it.

## Anti-patterns

- **Project-per-tenant for high-volume low-ACV** — operational overhead
- **Single shared project for high-ACV enterprise** — they want isolation evidence
- **No labels on resources** — cost attribution becomes guesswork
- **Custom auth when Identity Platform fits** — re-inventing JWT issuance is risky
- **No `tenant_id` propagation in logs / traces** — incident response across tenants impossible
- **Per-tenant Cloud SQL when AlloyDB + RLS would suffice**
- **No data residency design** — when EU customer signs, you're rebuilding
- **Marketplace listing without billing integration** — marketing only; customer can't actually buy
- **Anthos / BYOC offered without operational discipline** — supporting customer clusters is its own job
- **Same observability scope across all tiers** — enterprise tenants flooding free-tier noise
- **No per-tenant SLA tracking when SLAs are per-tenant**

## Verification checklist for saas-architect on GCP

- [ ] Tenant isolation model chosen with explicit rationale
- [ ] Identity model chosen: Identity Platform for end users, IAP for internal tools
- [ ] Per-tenant SAML / OIDC self-service path designed if enterprise SSO required
- [ ] Tenant provisioning automated end-to-end; latency budget met
- [ ] Cost attribution via labels (shared) or project (per-tenant); billing export to BigQuery configured
- [ ] Usage event pipeline (Pub/Sub → BigQuery) for usage-based billing if applicable
- [ ] Database isolation strategy chosen per tenant tier
- [ ] Compute isolation: shared Cloud Run / GKE namespace / dedicated, per tier
- [ ] Per-tenant data residency baked in if customers demand
- [ ] Observability: `tenant_id` propagated in logs, traces, metrics (cardinality-aware)
- [ ] Compliance posture: Assured Workloads folder for regulated tenants
- [ ] Marketplace listing strategy if GCP customers are target segment
- [ ] Anthos / BYOC offering only if enterprise demand + operational capacity justify
- [ ] Per-tenant SLA / SLO tracking if contracts require
- [ ] No legacy paths: no Firebase Auth as enterprise CIAM, no custom auth where managed works

## Patterns I apply

- **TDD on multi-tenancy**: every API endpoint has tenant-isolation tests — "user from tenant A cannot read tenant B's data" must be a CI test. **The easiest way to leak data across tenants is the test you didn't write.**
- **Verification**: tenant onboarding tested end-to-end in CI against ephemeral test tenants. Tenant offboarding (deletion) tested with audit-log verification of data removal.
- **Debugging**: tenant-specific issues require `tenant_id` filter in Cloud Logging / Cloud Trace as the first query.
- **Plan execution**: tenancy model migrations are major refactors — plan deliberately, shadow modes, verify before cutover.
- **Branch safety**: schema migrations must apply per-tenant safely; canary on one tenant before rolling fleet-wide.
- **Review**: every IAM / RLS / tenant-boundary change reviewed with explicit "what's the blast radius if this is wrong" question.

## Cross-references

- Other roles: [system-architect on GCP](/stacks/gcp/system-architect/), [database-architect on GCP](/stacks/gcp/database-architect/), [security-engineer on GCP](/stacks/gcp/security-engineer/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Stack index: [GCP](/stacks/gcp/)
