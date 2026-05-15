---
name: stack-azure
description: >
  Microsoft Azure platform knowledge overlay for the ETYB team. Loads when work involves the Azure ecosystem — Entra ID, AKS, Container Apps, Azure Functions, App Service, Logic Apps, Service Bus, Event Grid, Event Hubs, Cosmos DB, Azure SQL, PostgreSQL Flexible Server, Azure Managed Redis, Application Gateway, Front Door, API Management, Key Vault, Managed HSM, Defender for Cloud, Sentinel, Purview, Azure Policy, Azure Monitor, Log Analytics, Application Insights, Azure OpenAI Service, AI Foundry, Azure AI Search, Azure ML, Copilot Studio, Microsoft Fabric, Synapse, Data Factory, Databricks on Azure, Bicep, Terraform AzureRM, Azure CLI, azd, Azure Arc, Azure VMware Solution. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Azure work as of 2026-Q2.
  Triggers: azure, microsoft azure, az cli, azure cli, azure portal, azure resource manager, arm, bicep, .bicep, .bicepparam, azure verified modules, avm, terraform azurerm, azurerm, pulumi azure native, azd, azure developer cli, entra, entra id, azure ad, entra external id, azure ad b2c, b2c, conditional access, pim, privileged identity management, workload identity federation, wif, managed identity, system-assigned identity, user-assigned identity, azure rbac, key vault, managed hsm, defender for cloud, defender for servers, defender for containers, defender for storage, defender for databases, defender for app service, microsoft sentinel, sentinel, microsoft purview, azure policy, azure blueprints, deployment stacks, landing zone, alz, platform landing zone, azure vm, virtual machine, vmss, scale set, cobalt 100, dpsv6, dplsv6, epsv6, dv6, ev6, ncads h100, nd h200, ncv6, aks, azure kubernetes service, aks automatic, aks lts, aks long-term support, karpenter, node autoprovisioning, keda, dapr, container apps, aca, container apps jobs, workload profiles, container instances, aci, azure functions, flex consumption, durable functions, durable task scheduler, app service, app service environment, ase v3, static web apps, logic apps, service bus, event grid, event hubs, cosmos db, cosmos nosql, cosmos mongo, cosmos mongo vcore, cosmos cassandra, cosmos gremlin, cosmos table, diskann, azure sql database, sql hyperscale, sql managed instance, sql mi, postgresql flexible server, postgresql flex, citus, elastic clusters, azure cache for redis, azure managed redis, valkey, application gateway, front door, afd, azure cdn, traffic manager, load balancer, virtual wan, vwan, expressroute, private link, private endpoint, nsg, vnet flow logs, azure firewall, api management, apim, app configuration, blob storage, azure files, azure netapp files, data lake gen2, premium ssd v2, ultra disk, immutable storage, azure openai, azure openai service, gpt-4o, gpt-5, ai foundry, microsoft foundry, azure ai studio, foundry agents, azure ai search, azure cognitive search, azure ml, azure machine learning, copilot studio, semantic kernel, autogen, microsoft fabric, onelake, synapse, azure data factory, adf, azure databricks, hdinsight, azure monitor, log analytics, application insights, app insights, kql, azure managed prometheus, azure managed grafana, opentelemetry, otel, devops pipelines, azure devops, ado, github actions on azure, azure/login, azure arc, azure local, azure stack hci, azure vmware solution, avs, fhir, azure health data services, dicom, hipaa, azure spot, azure reservations, azure savings plans, azure hybrid benefit, ahb.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
  last_verified_on: "2026-05-14"
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
  primary:
    - { name: "Azure Documentation",              url: "https://learn.microsoft.com/azure/",                                       type: official_docs }
    - { name: "Azure CLI Reference",              url: "https://learn.microsoft.com/cli/azure/",                                   type: cli_reference }
    - { name: "Azure REST API Reference",         url: "https://learn.microsoft.com/rest/api/azure/",                              type: api_reference }
    - { name: "Azure Updates (changelog)",        url: "https://azure.microsoft.com/updates/",                                     type: changelog }
    - { name: "Azure Architecture Center",        url: "https://learn.microsoft.com/azure/architecture/",                          type: official_docs }
    - { name: "Microsoft Security Update Guide",  url: "https://msrc.microsoft.com/update-guide",                                  type: security_advisories }
    - { name: "Azure GitHub Organization",        url: "https://github.com/Azure",                                                 type: source_repos }
    - { name: "Microsoft Entra ID Docs",          url: "https://learn.microsoft.com/entra/identity/",                              type: official_docs }
    - { name: "Bicep Documentation",              url: "https://learn.microsoft.com/azure/azure-resource-manager/bicep/",          type: official_docs }
    - { name: "Azure Well-Architected Framework", url: "https://learn.microsoft.com/azure/well-architected/",                      type: official_docs }
delegate_to_skills:
  # No first-party Azure-hosted MCP server is generally available as of last_verified_on.
  # The Azure MCP Server project (github.com/Azure/azure-mcp) is in active development but not
  # GA-distributed to typical user environments. Revisit when Microsoft ships a first-party MCP
  # surface to Azure Portal / VS Code / azd defaults.
  []
products_covered:
  # === Compute ===
  - { name: "Azure Virtual Machines",       drift_risk: medium, notes: "Cobalt 100 Arm GA 2024-25; Dv6/Ev6 Emerald Rapids GA 2025; NCv6 Blackwell preview Nov 2025; series naming churns yearly" }
  - { name: "AKS",                          drift_risk: high,   notes: "AKS Automatic GA 2024; Long-Term Support (LTS) channels 2025; Karpenter / Node Autoprovisioning GA 2025; Workload Identity replaces Pod Identity (retired)" }
  - { name: "Azure Container Apps",         drift_risk: high,   notes: "Workload Profiles GA 2024; dedicated compute pools; Jobs GA; Dapr 1.13+ managed; Functions-on-ACA via Aspire" }
  - { name: "Azure Container Instances",    drift_risk: low,    notes: "Stable; mostly displaced by Container Apps for new workloads" }
  - { name: "Azure Functions",              drift_risk: high,   notes: "Flex Consumption GA 2024; in-process .NET model retired late 2026 — must migrate to isolated worker; Durable Functions v3 + Durable Task Scheduler" }
  - { name: "Azure App Service",            drift_risk: medium, notes: "App Service Environment v3 is current; v2 retired; Linux + Windows plans diverge on features" }
  - { name: "Azure Static Web Apps",        drift_risk: medium, notes: "Slowing investment as of 2025; evaluate Vercel/Cloudflare for cutting-edge frontend; still fine for Azure-integrated SPAs" }
  - { name: "App Service Environment v3",   drift_risk: low,    notes: "Stable; v1/v2 retired Aug 2024" }

  # === Integration & Messaging ===
  - { name: "Azure Logic Apps",             drift_risk: low,    notes: "Standard tier preferred over Consumption for new builds (VNet, stateful, local dev)" }
  - { name: "Azure Service Bus",            drift_risk: low,    notes: "Premium tier feature set stable; geo-DR matured" }
  - { name: "Azure Event Grid",             drift_risk: medium, notes: "MQTT broker GA + Namespaces (pull delivery) reshape patterns; CloudEvents 1.0 native" }
  - { name: "Azure Event Hubs",             drift_risk: low,    notes: "Kafka surface stable; Premium tier capacity model unchanged" }
  - { name: "API Management",               drift_risk: medium, notes: "Standard v2 + Premium v2 tiers GA 2024-25; legacy Premium tier still supported but new builds should pick v2" }
  - { name: "Azure App Configuration",      drift_risk: low,    notes: "Feature flags + dynamic config; Microsoft.FeatureManagement libraries stable" }

  # === Storage ===
  - { name: "Storage Accounts",             drift_risk: low,    notes: "ZRS/GZRS replication stable; v1 retired" }
  - { name: "Blob Storage",                 drift_risk: low,    notes: "Cold tier GA; immutability + versioning stable" }
  - { name: "Azure Files",                  drift_risk: low,    notes: "Premium SSD v2 backing; NFS 4.1 + SMB stable" }
  - { name: "Queue / Table Storage",        drift_risk: low,    notes: "Stable but losing mindshare to Service Bus / Cosmos DB for new builds" }
  - { name: "Azure NetApp Files",           drift_risk: low,    notes: "Large volumes 7.2 PiB; cool access; SAP HANA / Oracle / high-perf NAS workloads" }
  - { name: "Azure Data Lake Storage Gen2", drift_risk: low,    notes: "HNS must be enabled at create; foundation for Fabric/Synapse/Databricks" }

  # === Databases ===
  - { name: "Azure SQL Database",           drift_risk: medium, notes: "Hyperscale + Hyperscale Elastic Pools GA; Hyperscale serverless does NOT auto-pause" }
  - { name: "Azure SQL Managed Instance",   drift_risk: medium, notes: "SQL Server 2025 update policy GA March 2026; vector data type; Managed Instance Link for hybrid HA/DR" }
  - { name: "Cosmos DB for NoSQL",          drift_risk: high,   notes: "DiskANN vector search GA 2024-25; multi-region writes; partition strategy still critical" }
  - { name: "Cosmos DB for MongoDB (RU)",   drift_risk: low,    notes: "Original Cosmos Mongo API; recommend vCore for new builds" }
  - { name: "Cosmos DB for MongoDB vCore",  drift_risk: high,   notes: "Now built on open-source DocumentDB engine; sometimes called Azure DocumentDB; provisioned compute model" }
  - { name: "Cosmos DB for Cassandra",      drift_risk: low,    notes: "Stable" }
  - { name: "Cosmos DB for Gremlin",        drift_risk: low,    notes: "Stable" }
  - { name: "Cosmos DB for PostgreSQL",     drift_risk: high,   notes: "RETIRING — migrate workloads to Azure DB for PostgreSQL Flexible Server with Elastic Clusters (Citus). Flag immediately." }
  - { name: "PostgreSQL Flexible Server",   drift_risk: high,   notes: "Single Server retired March 2025; Elastic Clusters (Citus) GA; pgvector native; primary managed Postgres" }
  - { name: "Azure Managed Redis",          drift_risk: high,   notes: "Successor to Azure Cache for Redis; Flash Optimized tier; migration tooling phased Nov 2025 → Mar 2026" }
  - { name: "Azure Cache for Redis",        drift_risk: high,   notes: "Classic tiers (Basic/Standard/Premium/Enterprise) in retirement; migrate to Azure Managed Redis" }

  # === Networking & Edge ===
  - { name: "Azure Front Door",             drift_risk: medium, notes: "Premium SKU + Private Link origins; subsumes retired Azure CDN from Microsoft (classic)" }
  - { name: "Application Gateway v2",       drift_risk: low,    notes: "Regional L7; Layer 4 (TCP/TLS) proxy in preview; WAF v2 SKU" }
  - { name: "Azure Load Balancer (Standard)", drift_risk: low,  notes: "L4; Gateway LB for NVA chaining; cross-region LB available" }
  - { name: "Virtual WAN",                  drift_risk: low,    notes: "Hub-spoke as managed service; Route Server scales to 500 VNet connections" }
  - { name: "Private Link / Private Endpoints", drift_risk: low, notes: "Default posture for production PaaS; cross-tenant supported" }
  - { name: "Azure Firewall",               drift_risk: low,    notes: "Premium SKU TLS inspection + IDPS; integrates with Virtual WAN secure hubs" }
  - { name: "ExpressRoute",                 drift_risk: low,    notes: "400 Gbps Direct ports announced 2026 for AI workloads; FastPath + IPsec stable" }
  - { name: "VNet Flow Logs",               drift_risk: medium, notes: "NSG Flow Logs RETIRING — migrate to VNet Flow Logs by mid-2025 (already past for net-new)" }

  # === Identity & Security ===
  - { name: "Microsoft Entra ID",           drift_risk: high,   notes: "Renamed from Azure AD July 2023; Entra Agent ID for AI workloads (Ignite 2025); CAE expanding" }
  - { name: "Entra External ID",            drift_risk: high,   notes: "Replaces Azure AD B2C (rebranded 2024); B2C in legacy support — new builds use External ID" }
  - { name: "Conditional Access",           drift_risk: medium, notes: "Token protection GA; authentication strengths; CAE on critical events" }
  - { name: "Privileged Identity Management", drift_risk: low,  notes: "JIT for Entra + Azure RBAC; approval workflows + access reviews" }
  - { name: "Workload Identity Federation", drift_risk: low,    notes: "Replaces SP client secrets for CI/CD; 20 federated credentials per identity" }
  - { name: "Managed Identities",           drift_risk: low,    notes: "System-assigned + user-assigned; standard for service-to-service auth" }
  - { name: "Azure Key Vault",              drift_risk: low,    notes: "Azure RBAC is the recommended access model; legacy access policies have known gaps" }
  - { name: "Azure Managed HSM",            drift_risk: low,    notes: "FIPS 140-2 Level 3; single-tenant; required for regulated key custody" }
  - { name: "Defender for Cloud",           drift_risk: high,   notes: "CSPM + CWPP plans evolve quarterly; API Security Posture GA; AI security posture extended to GCP Vertex" }
  - { name: "Microsoft Sentinel",           drift_risk: medium, notes: "Unified SecOps portal merges Sentinel + Defender XDR (2024-25); SOAR + UEBA stable" }
  - { name: "Microsoft Purview",            drift_risk: high,   notes: "Unified data governance + DLP + insider risk; Purview catalog replaces older Azure Purview branding" }
  - { name: "Azure Policy",                 drift_risk: low,    notes: "Effects + initiatives stable; regulatory compliance initiatives kept current" }

  # === Observability ===
  - { name: "Azure Monitor",                drift_risk: low,    notes: "Unified platform; Metrics + Logs + App Insights + Alerts" }
  - { name: "Log Analytics",                drift_risk: low,    notes: "KQL-based; basic logs + auxiliary logs tiers GA 2024 for cost control" }
  - { name: "Application Insights",         drift_risk: medium, notes: "Classic SDK in maintenance mode — migrate to Azure Monitor OpenTelemetry Distro" }
  - { name: "Azure Managed Prometheus",     drift_risk: low,    notes: "PromQL; Azure Monitor Workspace as storage; AKS native integration" }
  - { name: "Azure Managed Grafana",        drift_risk: low,    notes: "Essential + Standard tiers; Azure Monitor + Prometheus data sources pre-configured" }

  # === AI / ML ===
  - { name: "Azure OpenAI Service",         drift_risk: high,   notes: "Folded into AI Foundry experience; PTU + Standard + Batch deployment types; quotas region-gated" }
  - { name: "AI Foundry (Azure AI Studio)", drift_risk: high,   notes: "Renamed from Azure AI Studio 2024-25; Foundry Agents GA 2025; 1900+ model catalog (OpenAI + Anthropic + Mistral + Llama + Phi)" }
  - { name: "Azure AI Search",              drift_risk: medium, notes: "Renamed from Azure Cognitive Search 2023; vector + hybrid search; semantic ranker; integrated vectorization GA" }
  - { name: "Azure Machine Learning",       drift_risk: medium, notes: "Managed online endpoints + MLflow native; prompt flow available here AND in Foundry" }
  - { name: "Copilot Studio",               drift_risk: high,   notes: "Renamed from Power Virtual Agents 2024; low-code agent builder; multi-agent orchestration GA 2025" }
  - { name: "Semantic Kernel",              drift_risk: medium, notes: "Open-source orchestration SDK; .NET + Python + Java; positioned alongside AutoGen for multi-agent" }
  - { name: "Azure Health Data Services",   drift_risk: medium, notes: "FHIR R4 service + DICOM + MedTech connector; replaces older Azure API for FHIR (retired)" }

  # === Data Platform ===
  - { name: "Microsoft Fabric",             drift_risk: high,   notes: "GA 2024; OneLake unified data lake; subsumes Power BI Premium + parts of Synapse/Data Factory for new builds" }
  - { name: "Synapse Analytics",            drift_risk: medium, notes: "Stagnant — new analytics work shifting to Fabric; dedicated SQL pools still supported" }
  - { name: "Azure Data Factory",           drift_risk: medium, notes: "Still primary orchestrator outside Fabric; Fabric Data Factory experience converging" }
  - { name: "Azure Databricks",             drift_risk: medium, notes: "First-party Microsoft offering; Unity Catalog standard; Lakehouse Federation expanding" }

  # === DevOps ===
  - { name: "Azure DevOps (Pipelines/Boards/Repos/Artifacts)", drift_risk: medium, notes: "Stagnant investment; new builds prefer GitHub Actions; Pipelines still supported but treat as maintenance" }
  - { name: "GitHub Actions on Azure",      drift_risk: low,    notes: "azure/login@v2 with OIDC (WIF) is the new default; recommended for greenfield" }
  - { name: "Azure Bicep",                  drift_risk: low,    notes: "DSL over ARM; Deployment Stacks GA; .bicepparam files; Azure Verified Modules (AVM) ecosystem mature" }
  - { name: "Azure Verified Modules (AVM)", drift_risk: medium, notes: "Platform Landing Zone module GA Jan 2026; replaces classic ALZ-Bicep (archived Feb 2027)" }
  - { name: "Terraform AzureRM provider",   drift_risk: low,    notes: "v4 current; provider-defined functions; resource_provider_registrations flag" }
  - { name: "Azure CLI (az)",               drift_risk: low,    notes: "Primary admin CLI; az login --service-principal --federated-token for WIF" }
  - { name: "Azure Developer CLI (azd)",    drift_risk: medium, notes: "azd ai agent commands (March 2026); GitHub Copilot integration in azd init; pnpm/yarn detection" }
  - { name: "Deployment Stacks",            drift_risk: low,    notes: "Native Azure lifecycle management; tracks resources + auto-cleans; works with Bicep + ARM" }

  # === Hybrid & Migration ===
  - { name: "Azure Arc",                    drift_risk: medium, notes: "Servers + K8s + Data Services + SQL Server; indirect mode for Arc Data Services retired Sep 2025" }
  - { name: "Azure Local (Azure Stack HCI)", drift_risk: high,  notes: "Renamed from Azure Stack HCI; 23H2 EOS April 2026; migrate to 24H2" }
  - { name: "Azure VMware Solution (AVS)",  drift_risk: low,    notes: "Stable; VCF 9 path under evaluation; Stretched Clusters in select regions" }
  - { name: "Azure Resource Mover",         drift_risk: low,    notes: "Cross-region resource moves; supports VMs, NICs, NSGs, SQL, AKS" }

  # === Cost ===
  - { name: "Azure Reservations",           drift_risk: low,    notes: "Up to 72%/80% 1y/3y discount; pro-rated cancellation up to $50K lifetime" }
  - { name: "Azure Savings Plans (Compute)", drift_risk: low,   notes: "Up to 65% discount; hourly spend commit; family/region flexible" }
  - { name: "Azure Spot VMs",               drift_risk: low,    notes: "Up to 90% discount; 30s eviction notice; batch/HPC/CI workloads only" }
  - { name: "Azure Hybrid Benefit",         drift_risk: low,    notes: "Windows Server + SQL Server SA conversion; Linux RHEL/SUSE also eligible" }
---

# Azure Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Azure knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/azure/index.md`](index.md)
- **Per-product pages:** `stacks/azure/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/azure/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/azure/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Azure AD is now Microsoft Entra ID** (renamed July 2023). The tenant, the SDKs, the portal blade — all "Entra". Saying "Azure AD" in 2026 reads as out-of-date; the brand and docs are Entra.
- **Azure AD B2C is now Entra External ID** (renamed 2024). New builds use External ID; B2C tenants exist but are in legacy support — do not propose a new B2C tenant in 2026.
- **Azure AI Studio is now Microsoft Foundry / Azure AI Foundry** (2024-25). Same product, expanded scope (Foundry Agents, model catalog, evaluation). Use "Foundry" or "AI Foundry" in current voice.
- **Azure Cognitive Search is now Azure AI Search** (renamed 2023). Same service.
- **Azure Stack HCI is now Azure Local** (renamed 2024-25). New docs use "Azure Local".
- **Azure Functions in-process .NET model is phasing out** through late 2026 — migrate to the isolated worker model. New Functions projects should never use in-process.
- **Cosmos DB for PostgreSQL is retiring.** Replacement: **Azure Database for PostgreSQL Flexible Server with Elastic Clusters (Citus extension)**. Flag immediately if anyone proposes Cosmos for PostgreSQL on a new build.
- **Azure Database for PostgreSQL Single Server retired March 2025.** Only **Flexible Server** is current.
- **Azure Cache for Redis classic tiers** (Basic/Standard/Premium/Enterprise/EnterpriseFlash) are being migrated to **Azure Managed Redis**. Migration tooling phased: Basic/Standard/Premium from Nov 2025; Enterprise/EnterpriseFlash from March 2026. New builds choose Azure Managed Redis.
- **NSG Flow Logs are retired** (mandatory migration by mid-2025) — use **VNet Flow Logs**.
- **AKS Pod Identity and Pod Identity v2 retired** — only **Workload Identity** (OIDC-federated) is supported. KEDA 2.15+ removed Pod Identity support entirely.
- **AKS Long-Term Support (LTS) channels** (GA 2025) — extended support for Kubernetes versions beyond the standard community window. Use for regulated workloads that can't keep up with the K8s release cadence.
- **Azure Functions Flex Consumption** (GA 2024) — pay-per-execution with always-ready instances + VNet integration + zone redundancy. The new default for production serverless.
- **Entra Agent ID** (Ignite 2025) — first-class Entra identity for AI agents. Conditional Access, PIM, audit logging applied to agent identities the same way as humans.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on an Azure engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Honor Zero Trust by default.** Managed Identity for every service-to-service auth, Private Link for every PaaS endpoint that supports it, Key Vault (RBAC mode) for every secret, Conditional Access on every human identity, Workload Identity Federation for every CI/CD service principal.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Azure | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Azure alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
