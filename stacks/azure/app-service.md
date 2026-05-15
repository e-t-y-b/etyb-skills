---
title: App Service
description: Azure App Service — managed web apps with slot deployments, traditional IIS/Tomcat model. ASE v3 only; v1/v2 retired Aug 2024.
product:
  name: Azure App Service
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, system-architect]
  authoritative_url: https://learn.microsoft.com/azure/app-service/
  notes: "Mature; ASE v3 only; Linux + Windows plans diverge on features."
---

## What it is

App Service is Azure's managed PaaS for web apps — supports .NET, Java, Node, PHP, Python, Ruby (some on Linux only). Slot deployments, custom domains, managed certs, VNet integration, autoscaling. Canonical reference: [App Service docs](https://learn.microsoft.com/azure/app-service/).

## When to use

Pick App Service when:

- **Traditional web app** — .NET / Java / PHP / Node, request-response, not container-first.
- **Lift-and-shift from IIS / Tomcat** — App Service mirrors enough of the IIS / Tomcat model to migrate without re-architecting.
- **Slot deployments + warm-up** — staging slot → warm up → swap to production with zero downtime.
- **Websockets / SSE** — App Service supports streaming well; Functions doesn't.

Don't pick App Service for:

- **Containerized microservices** — use [Container Apps](/stacks/azure/container-apps/) for the modern equivalent.
- **Event-driven** workloads — use [Functions](/stacks/azure/functions/).
- **K8s ecosystem requirements** — use [AKS](/stacks/azure/aks/).

## 2025-2026 currency anchors

- **App Service Environment v3** is the only current ASE. **v1 and v2 retired August 2024.**
- **Linux + Windows plans diverge** on features — verify your stack matches.
- **Container support** on App Service is fine but doesn't get the Container Apps featureset (managed Dapr, KEDA, traffic splitting per revision).
- **Static Web Apps** is a separate service for SPAs — see [Static Web Apps](/stacks/azure/static-web-apps/).
- **Managed certificates** for custom domains; free auto-renewing SSL.
- **Hybrid Connections** (legacy) for on-prem integration; new builds use VNet integration + Private Link.

## Patterns + anti-patterns

### Pattern: Slot deployments with warm-up

Deploy to a staging slot → run smoke tests → call `applicationInitialization` URLs to warm up → swap slots. Production traffic continues during deploy; cutover is atomic.

### Pattern: VNet integration + Private Endpoint

Production App Service: VNet integration (outbound) + Private Endpoint (inbound). Public endpoint disabled in app settings. App Gateway / Front Door fronts.

### Pattern: Application settings as connection mechanism

App Service settings → injected as environment variables. Combine with Key Vault references (`@Microsoft.KeyVault(SecretUri=...)`) so secrets resolve via Managed Identity at runtime.

### Pattern: Authentication / Authorization (EasyAuth)

App Service has built-in OIDC / Entra ID integration. Configure once; app receives `x-ms-client-principal` headers. Good for quick wins; complex flows should still be handled in app code.

### Anti-pattern: Hardcoded connection strings in app settings

Use Managed Identity to data tier (SQL / Postgres / Cosmos / Service Bus / Storage) wherever supported. App Setting only holds the resource URL.

### Anti-pattern: App Service Plan over-sized for the workload

App Service Plans bill on the VM tier, not usage. Auto-scale rules + the right SKU keep cost honest.

### Anti-pattern: Building new containerized microservices on App Service

Container Apps is the modern equivalent. App Service is for traditional / lift-and-shift web apps.

## Gotchas

- **ASE v3 vs Multi-tenant App Service** — ASE is single-tenant, premium isolation. Most workloads use multi-tenant; ASE is for strict isolation / regulated.
- **Hybrid Connections is legacy** for VNet bridging. New builds: VNet integration + Private Link.
- **Linux vs Windows feature parity is incomplete.** Some specific features (e.g., certain runtime stacks, certain integrations) only on one platform.
- **`always_on = true`** for production — keep the app warm. Default `false` lets the app sleep.

## Cross-references

- [Container Apps](/stacks/azure/container-apps/) — containerized microservice alternative
- [Functions](/stacks/azure/functions/) — event-driven alternative
- [Static Web Apps](/stacks/azure/static-web-apps/) — SPA-focused
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — runtime selection
- [App Service docs](https://learn.microsoft.com/azure/app-service/overview)
