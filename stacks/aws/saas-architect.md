---
title: SaaS Architect on AWS
description: Multi-tenant patterns on AWS — silo / pool / bridge tenancy, IAM ABAC + KMS per-tenant for isolation, Cognito app-client-per-tenant for federated SSO, AWS SaaS Factory references, per-tenant cost via CUR 2.0.
role_overlay:
  role: saas-architect
  stack: aws
  last_verified_on: "2026-05-14"
  products_covered: [cognito, aurora, dynamodb, iam, kms, cloudwatch, s3]
---

## Role briefing — saas-architect on AWS

You design the **tenancy model**, the **tenant isolation**, the **per-tenant cost attribution**, the **onboarding/offboarding**, the **billing surface**, and the **multi-tier pricing/entitlement** architecture.

Distinct from the principle-level role: AWS-specific patterns matter. [Aurora DSQL](/stacks/aws/aurora/) changes silo-pool calculus (per-tenant DB now operationally viable). [Verified Permissions](/stacks/aws/security-engineer/) (Cedar) is the AWS-managed authz. AWS Resource Control Policies (RCPs) complement SCPs for multi-tenant data perimeter. Control Tower Account Factory for Terraform (AFT) for programmatic account vending.

## Decision frameworks specific to this role's lens on AWS

### Tenancy model

| Model | Description | Use when |
|---|---|---|
| **Silo (full)** | One AWS account per tenant; or one VPC + isolated stack per tenant | Enterprise customers paying $$$+, strict isolation, BYOK, compliance |
| **Silo (data)** | Shared compute, per-tenant DB (or schema) | Mid-market, data-sensitive workloads, cost-per-tenant reasonable |
| **Pool (full)** | Shared everything; tenant ID is a field, isolation enforced in code | Cost-sensitive, lower-tier customers, freemium |
| **Bridge** | Pool by default, silo by exception (e.g., enterprise tier) | Most B2B SaaS in practice |

**Bridge is the modal 2026 SaaS shape** — pool for small/mid customers, silo for enterprises.

### Multi-tier pricing — architectural implications

| Tier | Tenancy | Compute | Database | Other |
|---|---|---|---|---|
| **Free / Starter** | Pool | Shared Lambda / Fargate | Shared DynamoDB / Aurora pool with RLS | Tight rate limits, no SLO |
| **Pro** | Pool | Shared, dedicated Lambda concurrency reservation | Schema or DB per tenant | SLA 99.5%, rate limits |
| **Business** | Pool with isolation | Reserved capacity | Per-tenant Aurora DSQL or DynamoDB | SLA 99.9%, audit logs, custom domain |
| **Enterprise** | Silo (account or VPC) | Dedicated compute | Dedicated DB, BYOK | SLA 99.95%, dedicated CSM, SSO, DSAR support |

Different tiers map to different deployment shapes. Plan the cross-tier promotion paths early.

## Product references

### Silo by account — AWS Control Tower + AFT

```
[Tenant A AWS Account]   [Tenant B AWS Account]   [Tenant C AWS Account]
        ^                         ^                         ^
        |                         |                         |
        +-----[ Control Plane Account ]------+
                  (provisions + manages)
```

**Pros**: hardest isolation (account is AWS's strongest boundary); BYOK customers hold keys in their account; AWS Marketplace billing handed per-tenant naturally; compliance scope shrinks.

**Cons**: operational overhead per tenant; account vending must be automated (Control Tower Account Factory or AFT); onboarding/offboarding is account-create / account-suspend; AWS account close has a 90-day waiting period.

**Pick silo-by-account when**: ARPU > $50K/year; BYOK or customer-controlled keys; compliance demands account-level isolation; customer extends their own AWS environment.

### Silo by data — Aurora DSQL or DynamoDB per tenant

```
[Shared Application Tier — ECS / EKS / Lambda]
                    |
                    +--> [Tenant A Database]
                    +--> [Tenant B Database]
                    +--> [Tenant C Database]
                    +--> [Shared Cache (with tenant prefix keys)]
```

**[Aurora DSQL](/stacks/aws/aurora/) per tenant** (2026 best fit): serverless, no instance sizing, multi-region available.

**[DynamoDB](/stacks/aws/dynamodb/) per tenant** (alternative): on-demand mode, single-table-per-tenant.

**Schema-per-tenant on shared Aurora Postgres**: tighter integration, easier migrations, but shared resource limits.

**Row-level security (RLS) on shared schema**: cheaper, but isolation depends on every query being correct. Use only with rigorous testing.

### IAM ABAC for pool tenancy

```json
{
  "Effect": "Allow",
  "Action": ["dynamodb:Query", "dynamodb:GetItem", "dynamodb:PutItem"],
  "Resource": "arn:aws:dynamodb:*:*:table/Orders",
  "Condition": {
    "StringEquals": {
      "aws:ResourceTag/Tenant": "${aws:PrincipalTag/Tenant}"
    }
  }
}
```

Principal tagged `Tenant=acme` can only act on resources tagged `Tenant=acme`. Tagging discipline is everything.

### KMS per-tenant keys

For BYOK or tenant-isolated encryption:
- One CMK per tenant.
- Tenant's data encrypted with their key.
- Key policy grants only tenant's principals + application's tenant-scoped role.
- Tenant rotates the key; audits usage via CloudTrail (in their account if silo).

### [Cognito](/stacks/aws/cognito/) for SaaS auth

| Approach | Use when |
|---|---|
| **One pool, tenant as custom attribute** | Pool / bridge tenancy |
| **Pool per tenant** | Silo tenancy; per-tenant branding, policies, federation |
| **App client per tenant in shared pool** | Enterprise SSO — each tenant brings their own IdP |

JWT claims for tenant context — `custom:tenant`. **Never** rely on a request body for tenant ID — derive from authenticated identity, server-side.

### Tenant context propagation

Every request must carry tenant context end-to-end:
- API Gateway extracts `tenantId` from JWT (Cognito-issued).
- API Gateway → Lambda — in event.requestContext or via authorizer.
- Lambda → DB — in query/scan/key.
- Lambda → downstream service — in headers (Service Connect / VPC Lattice).

### Onboarding control plane

```
[Customer signs up via website]
              |
              v
[Marketing → Control Plane API → Lambda]
              |
              v
[Lambda creates tenant]:
  - Cognito user pool / app client
  - DynamoDB tenant record
  - Aurora DSQL DB / DynamoDB table / namespace
  - Per-tenant IAM role (silo) or tenant tag (pool)
  - KMS key (silo) or grant on shared key (pool)
  - Stripe / Billing customer record
              |
              v
[Notification: tenant ready → email customer]
```

Control plane separate from data plane — different stacks, different blast radius.

### Per-tenant cost attribution

| Pattern | How |
|---|---|
| **Tag-based via CUR** | Every resource tagged with `Tenant=<id>`. CUR 2.0 → Athena → cost-per-tenant query. |
| **Account-based** | Silo: one account = one tenant. Account-level billing reports. |
| **Metered usage** | Track API calls, storage, compute time per tenant; apply pricing in billing system. |

**AWS Billing Conductor** for virtual "billing groups" combining tenant accounts with shared services into unified per-tenant view.

### Entitlements

| Tool | Use for |
|---|---|
| **AWS AppConfig** | Managed feature flags + config delivery |
| **LaunchDarkly / Statsig / Unleash** | Feature flag SaaS, deeper experiment + entitlement support |
| **Verified Permissions (Cedar)** | Formal policy decisions: "can Tenant X access Feature Y on Tier Z?" |

For tier-based entitlements, Verified Permissions + Cedar centralizes tier checks — don't scatter `if` statements through the codebase.

### Noisy neighbor management (pool)

- **Per-tenant rate limits** — API Gateway usage plans or in-app limiting via Redis / ElastiCache.
- **Per-tenant quotas** — DynamoDB on-demand limits or per-tenant DSQL DPU limits.
- **Throttling at the edge** — WAF rate-based rules with tenant-aware keys.
- **Compute isolation per tier** — pool premium customers in a separate Lambda alias / ECS service.
- **Hot-tenant detection** — DynamoDB Contributor Insights, custom CloudWatch metrics per tenant.

### Data residency

EU customers → eu-west-1 / eu-central-1; US → us-east-2; APAC → ap-southeast-2 (Sydney) / ap-south-1 (Mumbai).
- Tenant routing at the edge (Route 53 geo routing, CloudFront edge logic, or registry lookup).
- Per-region data plane.
- Cross-region tenant migration procedure.

**AWS European Sovereign Cloud (EUSC)** — GA late 2025/2026 for highest-bar EU.

## 2025-2026 platform-reset items relevant to this role

- **AWS SaaS Factory** (formerly SaaS Boost) — reference architectures, code, templates.
- **Aurora DSQL** changes silo-pool calculus — serverless Postgres with no instance sizing.
- **Verified Permissions** (Cedar) is the AWS-managed authz.
- **AWS Resource Control Policies (RCPs)** for multi-tenant data perimeter.
- **Control Tower Account Factory for Terraform (AFT)** for programmatic account vending.
- **AWS Marketplace SaaS contracts** — in-AWS-billing path for AWS-sourced customers.
- **AWS Billing Conductor** for chargeback/showback grouping.
- **CUR 2.0** — new schema for tenant cost attribution.

If proposing one-account-per-tenant without AFT, per-tenant tables in a shared schema without an isolation story, or "we'll figure out billing later" — your design isn't 2026-ready.

## Patterns the role applies

### TDD on SaaS architecture

- **Tenant isolation tests** — integration test authenticates as Tenant A, asserts queries can't return Tenant B data. Run on every PR.
- **Onboarding/offboarding tests** — simulate new tenant signup; assert all resources created. Simulate offboarding; assert all resources released within SLA.
- **Entitlement tests** — per-tier feature gating.

### Verification on SaaS

Claims must cite:
- "AWS Marketplace SaaS contracts support metered + subscription + per-seat" → Marketplace docs.
- "Aurora DSQL is multi-region active-active" → DSQL service-level statement.
- "Cognito user pool app clients" → Cognito docs.

### Debugging tenant issues

1. Reproduce in tenant-scoped sandbox; never debug in production with admin access.
2. Trace tenant context through the request — CloudWatch Logs with `tenantId`; X-Ray annotations.
3. **Check tenant routing logic first** — wrong tenant = wrong data; debug routing before business logic.
4. **One change at a time** — tenancy bugs often have multi-layer fixes.

### Branch safety on SaaS

- **Tenant isolation tests mandatory on every PR.** No merge without green isolation tests.
- **Onboarding/offboarding changes get two reviewers.** High-blast-radius.
- **Cross-tenant queries flagged in PR review.** Must be explicitly bounded to admin context.

## Cross-references

- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — IAM ABAC, KMS, Verified Permissions
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — per-tenant Aurora DSQL / DynamoDB design
- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — Control Tower + AFT account vending
- [AWS SaaS Factory](https://aws.amazon.com/partners/programs/saas-factory/)
- [`/stacks/aws/`](/stacks/aws/) — Stack index
