---
title: API Management
description: APIM Standard v2 / Premium v2 GA 2024-25. New builds pick v2; legacy Premium still supported. Throttling, transformation, dev portal, OAuth 2.0, mTLS to backends.
product:
  name: API Management
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, devops-engineer, security-engineer, saas-architect]
  authoritative_url: https://learn.microsoft.com/azure/api-management/
  notes: "Standard v2 + Premium v2 SKUs GA 2024-25 are the new defaults; legacy Premium still supported but new builds pick v2."
---

## What it is

Azure API Management (APIM) is the API gateway — throttling, request/response transformation, IP allow-lists, OAuth 2.0 validation, developer portal, mTLS to backends. **Standard v2** and **Premium v2** SKUs (GA 2024-25) are the new defaults. Canonical reference: [APIM docs](https://learn.microsoft.com/azure/api-management/).

## When to use

Pick APIM when:

- **Internet-exposed API** — APIM as the egress edge, not direct exposure of Functions / App Service / Container Apps.
- **Multiple internal teams / external partners** — Products / Subscriptions / Developer Portal organize access.
- **Per-subscription rate limits + quotas** — SaaS tenancy mapped to APIM subscriptions.
- **Request/response transformation** — version-skew between consumer and provider.
- **Hybrid (on-prem + Azure)** — self-hosted gateway extends APIM into customer infra.

## 2025-2026 currency anchors

- **Standard v2** and **Premium v2** SKUs GA 2024-25 — **new builds pick v2.**
- **Premium v2** supports VNet integration without the "STv2 quirks" of legacy Premium.
- **Legacy Premium tier** still supported; existing deployments don't need rushed migration but new builds shouldn't choose it.
- **Workspaces** for multi-team API governance.
- **OpenAPI / GraphQL / gRPC** support.
- **Microsoft Graph PowerShell SDK** + REST API for automation.

## Patterns + anti-patterns

### Pattern: APIM as the egress edge

Internet → APIM → backend pool (Functions / App Service / Container Apps / AKS). APIM handles throttling, IP allow-lists, OAuth validation, mTLS to backends. Backends have no public endpoint.

### Pattern: Per-subscription rate limit + quota

```xml
<rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription.Id)" />
<quota-by-key calls="10000" bandwidth="1024" renewal-period="86400" counter-key="@(context.Subscription.Id)" />
```

Tenant gets an APIM subscription key; per-subscription policies enforce limits.

### Pattern: OAuth 2.0 token validation

```xml
<validate-jwt header-name="Authorization" failed-validation-httpcode="401">
  <openid-config url="https://login.microsoftonline.com/.../v2.0/.well-known/openid-configuration" />
  <required-claims>
    <claim name="aud"><value>api://my-api</value></claim>
  </required-claims>
</validate-jwt>
```

Validates Entra-issued tokens; rejects invalid; passes through valid.

### Pattern: Developer Portal as the contract surface

Internal + partner developers explore APIs, get subscription keys, run test calls. Self-service onboarding.

### Anti-pattern: New API exposed without APIM

Direct public exposure of Functions / Container Apps loses central throttling, transformation, OAuth validation, observability.

### Anti-pattern: Legacy Premium SKU for new builds

Standard v2 / Premium v2 are the new defaults.

### Anti-pattern: Hand-rolled JWT validation in every API

APIM's policy does this once at the edge. Duplicate in app code only as defense-in-depth (and don't trust APIM bypass).

## Gotchas

- **Cold start on Consumption tier** — fine for dev; production usually wants Standard v2 / Premium v2.
- **Premium v2 VNet integration** behaves differently from legacy Premium — re-test if migrating.
- **Policy expressions are C#** — read the docs; debugging is in-portal.
- **Caching policies** can mask backend issues; use carefully.
- **Subscription keys vs OAuth** — both supported; OAuth is the modern default.

## Cross-references

- [Backend Architect on Azure](/stacks/azure/backend-architect/) — API exposure
- [SaaS Architect on Azure](/stacks/azure/saas-architect/) — per-tenant subscriptions
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — JWT validation at the edge
- [System Architect on Azure](/stacks/azure/system-architect/) — gateway placement
- [API Management v2 tiers](https://learn.microsoft.com/azure/api-management/v2-service-tiers-overview)
