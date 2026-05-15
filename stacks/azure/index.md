---
title: Azure
description: Microsoft Azure platform knowledge overlay — Entra, AKS, Container Apps, Functions, Cosmos, Azure SQL, Postgres Flex, Foundry, Sentinel, Defender, Purview, Bicep + AVM. Current to 2026-Q2.
stack:
  vendor: azure
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - system-architect
    - backend-architect
    - database-architect
    - devops-engineer
    - security-engineer
    - sre-engineer
    - ai-ml-engineer
    - saas-architect
    - healthcare-architect
  authoritative_sources:
    - { name: "Azure Documentation",              url: "https://learn.microsoft.com/azure/",                              type: official_docs }
    - { name: "Azure CLI Reference",              url: "https://learn.microsoft.com/cli/azure/",                          type: cli_reference }
    - { name: "Azure REST API Reference",         url: "https://learn.microsoft.com/rest/api/azure/",                     type: api_reference }
    - { name: "Azure Updates (changelog)",        url: "https://azure.microsoft.com/updates/",                            type: changelog }
    - { name: "Azure Architecture Center",        url: "https://learn.microsoft.com/azure/architecture/",                 type: official_docs }
    - { name: "Microsoft Security Update Guide",  url: "https://msrc.microsoft.com/update-guide",                         type: security_advisories }
    - { name: "Microsoft Entra ID Docs",          url: "https://learn.microsoft.com/entra/identity/",                     type: official_docs }
    - { name: "Bicep Documentation",              url: "https://learn.microsoft.com/azure/azure-resource-manager/bicep/", type: official_docs }
    - { name: "Azure Well-Architected Framework", url: "https://learn.microsoft.com/azure/well-architected/",             type: official_docs }
  delegate_to_skills: []
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="note" title="No first-party MCP yet">
No first-party Azure-hosted MCP server is generally available in user environments as of last verified date. The [Azure MCP Server project](https://github.com/Azure/azure-mcp) is in active development but not GA-distributed. Once a default MCP surface ships in Azure Portal / VS Code / azd, it will be added to `delegate_to_skills` and ETYB will defer to it for matching products.
</Aside>

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Azure 2026-Q2 — Ignite 2025, MS Build 2025, Azure Updates through April 2026.</div>

If today's date is more than 6 months past the `last_verified_on` above, treat platform specifics with extra care — bias toward the [authoritative sources](#authoritative-sources) for time-sensitive claims. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness.

## What changed in 2024-2026 that older training data misses

A 2023 or early-2024 cutoff misses most of these. Use this list as a checklist before recommending anything on Azure:

### Renames you cannot guess

- **Azure AD → Microsoft Entra ID** (renamed July 2023). The tenant, SDKs, portal blade — all "Entra". `Microsoft.Identity.Client` / `@azure/identity` package names are unchanged, but docs and branding are Entra.
- **Azure AD B2C → Entra External ID** (renamed 2024). New customer-facing apps go on External ID. B2C is in legacy support — do not propose new B2C tenants.
- **Azure AI Studio → Microsoft Foundry / Azure AI Foundry** (2024-25). Same product, expanded scope (Foundry Agents, evaluation, 1,900+ model catalog).
- **Azure Cognitive Search → Azure AI Search** (renamed 2023). Same service.
- **Power Virtual Agents → Copilot Studio** (renamed 2024). Now multi-agent-capable.
- **Azure Stack HCI → Azure Local** (renamed 2024-25).
- **Cosmos DB for MongoDB vCore** is sometimes branded **Azure DocumentDB** in current surfaces — open-source DocumentDB engine underneath.

### Retirements and forced migrations

- **Azure Functions in-process .NET model phasing out** through late 2026 — new projects MUST use isolated worker.
- **Cosmos DB for PostgreSQL is retiring.** Replacement: **PostgreSQL Flexible Server with Elastic Clusters (Citus)**. Flag immediately if anyone proposes Cosmos for PostgreSQL on a new build.
- **PostgreSQL Single Server retired March 2025.** Only Flexible Server is current.
- **Azure Cache for Redis classic tiers** in migration to **Azure Managed Redis** — tooling phased Nov 2025 (Basic/Standard/Premium) → March 2026 (Enterprise/EnterpriseFlash).
- **NSG Flow Logs retired** (mandatory migration by mid-2025) — use **VNet Flow Logs**.
- **Azure CDN from Microsoft (classic) retired** — migrate to **Front Door Standard/Premium**.
- **App Service Environment v1/v2 retired August 2024.** Only ASE v3 is current.
- **AKS Pod Identity + Pod Identity v2 retired** — only **Workload Identity** (OIDC-federated). KEDA 2.15+ removed Pod Identity entirely.
- **Azure Arc Data Services indirect connected mode retired September 2025** — direct connected only.
- **Azure Stack HCI 23H2 reaches EOS April 2026** — migrate to 24H2 (Azure Local).
- **Azure API for FHIR retired** — migrate to Health Data Services FHIR service.
- **Service Principal client secrets in CI/CD** — replace with **Workload Identity Federation (OIDC)**. If you see `client_secret` in a GitHub Actions workflow, that's stale.

### New surfaces you might not know exist

- **AKS Long-Term Support (LTS) channels** (GA 2025) — extended K8s version support past community window.
- **AKS Karpenter / Node Autoprovisioning** (GA 2025) — default in AKS Automatic.
- **Container Apps Workload Profiles** (GA 2024) — mix Consumption + Dedicated (D/E-series) in one environment.
- **Azure Functions Flex Consumption** (GA 2024) — new default for production serverless.
- **Cosmos DB DiskANN vector search** (GA 2024-25) — Microsoft Research's billion-scale vector index, native to Cosmos NoSQL.
- **Foundry Agents** (GA 2025) — first-class managed agent runtime in AI Foundry.
- **Entra Agent ID** (Ignite 2025) — first-class Entra identity for AI agents.
- **Microsoft Fabric + OneLake** (GA 2024) — unified analytics; Synapse is in maintenance.
- **Microsoft Foundry model catalog** with both Anthropic Claude and OpenAI frontier — Azure is the only hyperscaler with both managed.
- **Hyperscale Elastic Pools** (GA) — pool Hyperscale databases for multi-tenant SaaS.
- **SQL Server 2025 update policy on Managed Instance** (GA March 2026) — vector data type, optimized locking, Change Event Streaming.
- **Bicep Deployment Stacks** (GA) — Azure-native lifecycle management.
- **Azure Verified Modules (AVM)** — Microsoft-maintained Bicep + Terraform module ecosystem. **AVM Platform Landing Zone module GA Jan 2026** replaces classic ALZ-Bicep (archived Feb 2027).

## Products covered

| Product | Drift risk | Why |
|---|---|---|
| [Virtual Machines](/stacks/azure/virtual-machines/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Cobalt 100 Arm GA, Dv6/Ev6 Emerald Rapids GA, NCv6 Blackwell preview Nov 2025; series names churn yearly |
| [AKS](/stacks/azure/aks/) | <span class="etyb-drift-badge" data-risk="high">high</span> | AKS Automatic, LTS channels, Karpenter / Node Autoprovisioning GA 2025; Pod Identity retired |
| [Container Apps](/stacks/azure/container-apps/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Workload Profiles GA 2024; managed Dapr; Jobs GA |
| [Container Instances](/stacks/azure/container-instances/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; displaced by Container Apps for new builds |
| [Azure Functions](/stacks/azure/functions/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Flex Consumption GA 2024; in-process .NET retired late 2026; Durable v3 + Durable Task Scheduler |
| [App Service](/stacks/azure/app-service/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | ASE v3 current; v1/v2 retired Aug 2024 |
| [Static Web Apps](/stacks/azure/static-web-apps/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Slowing investment in 2025; evaluate Vercel/Cloudflare for cutting-edge frontend |
| [Logic Apps](/stacks/azure/logic-apps/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Standard tier preferred over Consumption for new builds |
| [Service Bus](/stacks/azure/service-bus/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Premium feature set stable; geo-DR matured |
| [Event Grid](/stacks/azure/event-grid/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | MQTT broker GA + Namespaces (pull delivery); CloudEvents 1.0 native |
| [Event Hubs](/stacks/azure/event-hubs/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Kafka surface stable |
| [Storage Account](/stacks/azure/storage-account/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Foundation for Blob / Queue / Table / Files / ADLS Gen2 |
| [Cosmos DB](/stacks/azure/cosmos-db/) | <span class="etyb-drift-badge" data-risk="high">high</span> | DiskANN vector search GA; multi-region writes; Cosmos for PG retiring |
| [Azure SQL](/stacks/azure/azure-sql/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Hyperscale + Hyperscale Elastic Pools GA; SQL Server 2025 on MI March 2026 |
| [PostgreSQL Flexible Server](/stacks/azure/postgresql-flexible-server/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Single Server retired March 2025; Elastic Clusters (Citus) GA; pgvector native |
| [Azure Managed Redis](/stacks/azure/azure-managed-redis/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Successor service; Azure Cache for Redis classic in migration |
| [Application Gateway](/stacks/azure/application-gateway/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Regional L7; WAF v2; L4 proxy in preview |
| [Front Door](/stacks/azure/front-door/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Premium SKU + Private Link origins; subsumes retired classic CDN |
| [API Management](/stacks/azure/api-management/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Standard v2 + Premium v2 GA 2024-25; new builds pick v2 |
| [Key Vault](/stacks/azure/key-vault/) | <span class="etyb-drift-badge" data-risk="low">low</span> | RBAC mode is the recommended access model; legacy access policies have gaps |
| [Entra ID](/stacks/azure/entra-id/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Renamed from Azure AD; Entra Agent ID for AI workloads (Ignite 2025) |
| [Entra External ID](/stacks/azure/entra-external-id/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Replaces Azure AD B2C; B2C in legacy support |
| [Defender for Cloud](/stacks/azure/defender-for-cloud/) | <span class="etyb-drift-badge" data-risk="high">high</span> | CSPM + CWPP plans evolve quarterly; AI Security Posture expanded |
| [Microsoft Sentinel](/stacks/azure/sentinel/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Unified SecOps portal merges Sentinel + Defender XDR (2024-25) |
| [Microsoft Purview](/stacks/azure/microsoft-purview/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Unified data governance + DLP + insider risk + AI Hub |
| [Azure Monitor](/stacks/azure/azure-monitor/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Metrics + Logs + App Insights + Alerts unified |
| [Log Analytics](/stacks/azure/log-analytics/) | <span class="etyb-drift-badge" data-risk="low">low</span> | KQL; Basic + Auxiliary Logs tiers GA 2024 for cost control |
| [Application Insights](/stacks/azure/application-insights/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Classic SDK in maintenance — migrate to Azure Monitor OpenTelemetry Distro |
| [Azure OpenAI](/stacks/azure/azure-openai/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Folded into AI Foundry; PTU + Standard + Batch + Global + Data Zone |
| [AI Foundry](/stacks/azure/ai-foundry/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Renamed from Azure AI Studio; 1,900+ model catalog with OpenAI + Anthropic |
| [Foundry Agents](/stacks/azure/foundry-agents/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Managed agent runtime GA 2025; declarative tools + threads + evaluation |
| [Azure AI Search](/stacks/azure/ai-search/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Renamed from Cognitive Search; integrated vectorization GA |
| [Microsoft Fabric](/stacks/azure/microsoft-fabric/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2024; OneLake; subsumes Synapse + Power BI Premium for new builds |
| [Synapse Analytics](/stacks/azure/synapse-analytics/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Stagnant — new analytics work shifts to Fabric |
| [Data Factory](/stacks/azure/data-factory/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Still primary orchestrator outside Fabric |
| [Bicep](/stacks/azure/bicep/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Deployment Stacks GA; .bicepparam files; AVM ecosystem mature |
| [Terraform AzureRM](/stacks/azure/terraform-azurerm/) | <span class="etyb-drift-badge" data-risk="low">low</span> | v4 current; provider-defined functions |
| [Azure Developer CLI (azd)](/stacks/azure/azd/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | `azd ai agent` (March 2026); GitHub Copilot integration |
| [Azure Arc](/stacks/azure/azure-arc/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Servers + K8s + Data; indirect mode for Arc Data retired Sep 2025 |
| [Azure VMware Solution](/stacks/azure/azure-vmware-solution/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; VCF 9 path under evaluation |

## Role overlays

Each role view stitches together the products that role's work touches. Use these as the routing surface when ETYB is dispatching by discipline:

- [System Architect on Azure](/stacks/azure/system-architect/)
- [Backend Architect on Azure](/stacks/azure/backend-architect/)
- [Database Architect on Azure](/stacks/azure/database-architect/)
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/)
- [Security Engineer on Azure](/stacks/azure/security-engineer/)
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/)
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/)
- [SaaS Architect on Azure](/stacks/azure/saas-architect/)
- [Healthcare Architect on Azure](/stacks/azure/healthcare-architect/)

## Authoritative sources

For verified-current behavior, see the official Microsoft surfaces:

- **[Azure Documentation](https://learn.microsoft.com/azure/)** — canonical reference
- **[Azure Updates](https://azure.microsoft.com/updates/)** — changelog; check before recommending currently-GA features
- **[Azure CLI Reference](https://learn.microsoft.com/cli/azure/)**
- **[Azure REST API Reference](https://learn.microsoft.com/rest/api/azure/)**
- **[Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)** — canonical reference architectures
- **[Microsoft Entra ID Docs](https://learn.microsoft.com/entra/identity/)**
- **[Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)**
- **[Microsoft Security Update Guide](https://msrc.microsoft.com/update-guide)** — CVEs
- **[Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)** — design doctrine
- **[Microsoft Trust Center](https://www.microsoft.com/trust-center)** — per-service compliance eligibility

## Delegate skills

`delegate_to_skills` is empty. The [Azure MCP Server](https://github.com/Azure/azure-mcp) project is in active development but no first-party Azure-hosted MCP server is GA-distributed to typical user environments as of last verification. When Microsoft ships a default MCP surface into Azure Portal / VS Code / azd, it will be added here and ETYB will defer to it for matching products.
