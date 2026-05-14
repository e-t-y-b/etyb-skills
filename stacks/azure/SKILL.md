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

# Azure Stack Pack — Team Briefing

You're working on Microsoft Azure. This is a **knowledge overlay**, not a new specialist. The existing ETYB team is doing the work — backend-architect writes the .NET/Java/Node service running on Container Apps, devops-engineer writes the Bicep and the GitHub Actions workflow, security-engineer wires up Entra + Key Vault + Defender, ai-ml-engineer designs the Foundry agent with Azure OpenAI. This pack teaches each role what the Azure platform expects in 2026.

**Currency stamp:** verified against Azure as of **2026-Q2** — Ignite 2025 announcements, TDX-equivalent Azure Updates through April 2026, MS Build 2025, Microsoft Foundry Agents GA, AKS LTS channels, Azure Managed Redis tier rollout, Entra Agent ID, Cosmos DB DiskANN vector search GA, Cosmos DB for PostgreSQL retirement guidance. If today's date is more than 6 months past `last_verified_on` above, the pack is stale — warn the user and consult Azure Updates before recommending API-shape, SKU, or pricing details.

## What changed in 2024-2026 that older training data misses

An LLM with a 2023 or early-2024 cutoff will be wrong on these. Treat the list as a checklist before recommending anything Azure:

### Renames you cannot guess

- **Azure AD is now Microsoft Entra ID** (renamed July 2023). The tenant, the SDKs, the portal blade — all "Entra". Saying "Azure AD" in 2026 reads as out-of-date; the product name in code (`Microsoft.Identity.Client`, `@azure/identity`) is unchanged but the brand and docs are Entra.
- **Azure AD B2C is now Entra External ID** (renamed 2024). New builds use External ID; B2C tenants exist but are in legacy support — do not propose a new B2C tenant in 2026.
- **Azure AI Studio is now Microsoft Foundry / Azure AI Foundry** (2024-25). Same product, expanded scope (Foundry Agents, model catalog, evaluation). Use "Foundry" or "AI Foundry" in current voice.
- **Azure Cognitive Search is now Azure AI Search** (renamed 2023). Same service.
- **Power Virtual Agents is now Copilot Studio** (renamed 2024). Low-code agent builder, now multi-agent-capable.
- **Azure Stack HCI is now Azure Local** (renamed 2024-25). New docs use "Azure Local".
- **Cosmos DB for MongoDB vCore** is sometimes called **Azure DocumentDB** in recent surfaces — same product, new branding for the open-source DocumentDB engine underneath.

### Retirements and forced migrations

- **Azure Functions in-process .NET model is phasing out** through late 2026 — migrate to the isolated worker model. New Functions projects should never use in-process.
- **Cosmos DB for PostgreSQL is retiring.** Replacement: **Azure Database for PostgreSQL Flexible Server with Elastic Clusters (Citus extension)**. Flag immediately if anyone proposes Cosmos for PostgreSQL on a new build.
- **Azure Database for PostgreSQL Single Server retired March 2025.** Only **Flexible Server** is current.
- **Azure Cache for Redis classic tiers** (Basic/Standard/Premium/Enterprise/EnterpriseFlash) are being migrated to **Azure Managed Redis**. Migration tooling phased: Basic/Standard/Premium from Nov 2025; Enterprise/EnterpriseFlash from March 2026. New builds choose Azure Managed Redis.
- **NSG Flow Logs are retired** (mandatory migration by mid-2025) — use **VNet Flow Logs**.
- **Azure CDN from Microsoft (classic) retired** — migrate to **Azure Front Door Standard/Premium**.
- **App Service Environment v1/v2 retired August 2024.** Only **ASE v3** is current.
- **Azure Arc Data Services indirect connected mode retired September 2025** — direct connected mode only.
- **Connected Apps for Entra** continue, but **Workload Identity Federation (WIF)** replaces service principal client secrets for CI/CD. If you propose `client_secret` in a GitHub Actions workflow, you're using stale knowledge.
- **AKS Pod Identity and Pod Identity v2 retired** — only **Workload Identity** (OIDC-federated) is supported. KEDA 2.15+ removed Pod Identity support entirely.
- **Azure Stack HCI 23H2 reaches EOS April 2026** — migrate to **24H2 (Azure Local)**.
- **Salesforce Functions** got mentioned by name in another pack — Azure has its own retirements; the equivalent on Azure is **Functions in-process .NET** sunset.

### New surfaces you might not know exist

- **AKS Long-Term Support (LTS) channels** (GA 2025) — extended support for Kubernetes versions beyond the standard community window. Use for regulated workloads that can't keep up with the K8s release cadence.
- **AKS Karpenter / Node Autoprovisioning** (GA 2025) — node provisioning beyond Cluster Autoscaler; better bin-packing, faster scale-up. Default for new AKS Automatic clusters.
- **Container Apps Workload Profiles** (GA 2024) — dedicated compute pools inside a Container Apps environment (Consumption + Dedicated D-series/E-series). Eliminates the old "Consumption-only vs full AKS" gap.
- **Azure Functions Flex Consumption** (GA 2024) — pay-per-execution with always-ready instances + VNet integration + zone redundancy. The new default for production serverless. Old "Consumption" plan still exists but Flex is what to recommend.
- **Cosmos DB DiskANN vector search** (GA 2024-25) — Microsoft Research's billion-scale vector index, native to Cosmos NoSQL. Predictable latency at millions of QPS. The default vector store inside Cosmos.
- **Foundry Agents** (GA 2025) — first-class agent runtime in AI Foundry; declarative tools, threads, structured outputs, evaluation hooks. Different surface from raw Azure OpenAI Assistants API.
- **Entra Agent ID** (Ignite 2025) — first-class Entra identity for AI agents. Conditional Access, PIM, audit logging applied to agent identities the same way as humans. Zero Trust extended to autonomous workloads.
- **Microsoft Fabric + OneLake** (GA 2024) — unified analytics platform; new analytics work shifts here over time. Synapse Analytics is in maintenance.
- **Microsoft Foundry model catalog** with **both Anthropic Claude and OpenAI** frontier models — Azure is the only hyperscaler with both in one managed catalog as of 2026.
- **Cosmos DB for MongoDB vCore "Azure DocumentDB"** rebrand — open-source DocumentDB engine underneath, MongoDB-compatible wire protocol, provisioned compute pricing model.
- **Hyperscale Elastic Pools** (GA) — pool Hyperscale databases for SaaS multi-tenant workloads. Combines auto-scaling storage with elastic compute sharing.
- **SQL Server 2025 update policy on Managed Instance** (GA March 2026) — choose between rolling latest-engine features or fixed SQL Server 2022/2025 feature set per instance.
- **Bicep Deployment Stacks** (GA) — Azure-native lifecycle management; tracks deployed resources and auto-cleans removed ones (Terraform-state-like semantics without Terraform).
- **Azure Verified Modules (AVM)** — Microsoft-maintained Bicep + Terraform module ecosystem with standard naming, testing, and versioning. **Platform Landing Zone AVM module GA Jan 2026** replaces classic ALZ-Bicep (archived Feb 2027).

### Currency anchors for code-level claims

When a role overlay says "as of 2026-Q2..." — that's anchored to:

- Azure CLI `az` 2.65+ (mid-2025+)
- Bicep CLI 0.30+
- azd 1.12+ with `azd ai agent` command surface (March 2026)
- AKS supported Kubernetes versions: 1.30 (community-supported through Q2 2026), 1.31, 1.32, 1.33; LTS extends 1.27 / 1.30
- Terraform AzureRM provider v4.x
- KEDA 2.16 on K8s ≥ 1.32; KEDA 2.14 on K8s 1.30/1.31
- Dapr 1.13.6-msft.6+ in Container Apps managed sidecar
- Azure Functions runtime v4 (in-process .NET in sunset)
- Azure Monitor OpenTelemetry Distro stable for .NET 8/9, Java 17/21, Node 18/20, Python 3.10+

If you find yourself recommending Azure AD, Cognitive Search, Power Virtual Agents, Cosmos DB for PostgreSQL, Functions in-process .NET, Azure CDN from Microsoft, Azure AD B2C for a new build, classic Azure Cache for Redis, NSG Flow Logs, Pod Identity, or ASE v2 — stop and read the relevant role overlay. You're pattern-matching on stale knowledge.

## How this pack plugs in

ETYB's router detects Azure signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` for that role if one exists. The role overlay is the deep work; this file is the cross-cutting context.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement, debugging. The Azure overlay does not relax engineering discipline; it shapes how the discipline is applied on this platform (TDD on Azure Functions = local Functions runtime + xUnit/pytest, not `az functionapp` round-trips; verification on Bicep = `az deployment what-if` before deploy, not "looks right"; debugging on AKS = `kubectl describe` + `kubectl logs --previous` + Container Insights, not vibes).

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `system-architect` | [`references/system-architect.md`](references/system-architect.md) | **The architectural decision** — Landing Zone topology, Hub-Spoke vs Virtual WAN, multi-region patterns, compute selection (Functions vs Container Apps vs AKS vs App Service vs VMs), event mesh design (Service Bus vs Event Grid vs Event Hubs), Foundry agent vs orchestrated compute, Azure-only vs multi-cloud composition |
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | API surfaces on App Service / Container Apps / Functions / APIM; .NET Aspire patterns; Dapr building blocks; idempotent message handlers on Service Bus; Cosmos DB SDK patterns; Managed Identity for service-to-service; in-process → isolated worker migration |
| `database-architect` | [`references/database-architect.md`](references/database-architect.md) | Cosmos DB partitioning + RU sizing + DiskANN vector indexing; Azure SQL Hyperscale + Hyperscale Elastic Pools; PostgreSQL Flexible Server + Citus Elastic Clusters; Azure Managed Redis tier selection; Fabric + OneLake landing patterns; CDC + Debezium-on-Azure |
| `devops-engineer` | [`references/devops-engineer.md`](references/devops-engineer.md) | Bicep + AVM + Deployment Stacks; Terraform AzureRM v4; GitHub Actions with WIF (OIDC) as default; azd for end-to-end; AKS day-2 (LTS channels, Karpenter, Workload Identity); Container Apps Workload Profiles; pipeline-grade testing patterns |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | **The heaviest overlay.** Entra ID + External ID; Conditional Access design; PIM + access reviews; Workload Identity Federation; Key Vault + Managed HSM; Defender for Cloud plan selection (Servers/Containers/Storage/Databases/App Service/AI); Sentinel pipelines + KQL hunting; Purview DLP + data classification; Azure Policy + initiatives + landing-zone guardrails; Private Link as default posture; Entra Agent ID |
| `sre-engineer` | [`references/sre-engineer.md`](references/sre-engineer.md) | Azure Monitor data model; OpenTelemetry Distro migration off classic App Insights SDK; KQL for SLOs; Managed Prometheus + Managed Grafana stack; Container Insights for AKS; Alert routing via Action Groups; chaos engineering with Azure Chaos Studio; cost-aware observability (basic/auxiliary log tiers) |
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | **Agent design on Azure** — Foundry Agents + AutoGen + Semantic Kernel; Azure OpenAI deployment selection (PTU vs Standard vs Batch); Azure AI Search hybrid retrieval + integrated vectorization; Cosmos DiskANN as vector store; content safety; evaluation framework; BYO model via Foundry; AML for training |
| `saas-architect` | [`references/saas-architect.md`](references/saas-architect.md) | Multi-tenant on Azure — Hyperscale Elastic Pools, Cosmos DB partition-per-tenant, AKS per-tenant namespaces vs shared cluster, Front Door multi-tenant routing, Entra External ID for customer auth, B2B for partner auth, per-tenant cost attribution via tags + Cost Management |
| `healthcare-architect` | [`references/healthcare-architect.md`](references/healthcare-architect.md) | **Thin overlay.** Azure Health Data Services (FHIR R4 + DICOM + MedTech) + HIPAA-eligible service inventory + Azure Confidential Computing for PHI processing + Purview classification for PHI. Defers to healthcare-architect (specialist) for HIPAA/HITRUST/FHIR semantics/audit discipline |

## Top 10 platform gotchas the team must know

These are the things that will bite you in production if a role overlay glosses over them. Named, with consequences.

### 1. Default access policies on Key Vault are a footgun

Legacy access policies are still selectable in the portal, but they have well-known gaps (no scoped ABAC, awkward audit). **Use Azure RBAC for all new Key Vaults**, and migrate existing vaults via the Azure Policy initiative "Key vaults should use RBAC permission model". Consequence of getting this wrong: anyone with "List secrets" on the vault has list-on-every-secret, no scoping. (security-engineer overlay covers this.)

### 2. Cosmos DB partition key is permanent

Once you create a container, you cannot change the partition key. Renaming requires a data migration. Pick the partition key from the read pattern, not the write pattern, and verify with realistic data volume. Consequence: you'll be writing a Data Factory pipeline to re-shard at 3 AM. (database-architect overlay covers this.)

### 3. Cosmos DB serverless and provisioned are not interchangeable

You pick serverless or provisioned at container creation. Switching requires creating a new account and migrating data. Serverless caps at 1 TB and 5K RU/s burst. Plan for provisioned (autoscale) when you don't know the load yet. (database-architect overlay covers this.)

### 4. AKS Workload Identity, not Pod Identity

Pod Identity and Pod Identity v2 are retired. Only Workload Identity (OIDC federation via projected service account tokens) is supported. KEDA 2.15+ removed Pod Identity entirely — if you upgrade KEDA without migrating to Workload Identity first, your scalers go offline. (devops-engineer + security-engineer overlays cover this.)

### 5. Azure Functions in-process .NET is dead

In-process .NET runtime is in retirement through late 2026. New Functions projects MUST use the isolated worker model. Migration is non-trivial (different host config, different middleware model, different DI). Do it before the deadline, not after. (backend-architect overlay covers this.)

### 6. NSG Flow Logs → VNet Flow Logs migration is past due

NSG Flow Logs retired mid-2025. If you still have them enabled, they're silently broken on the latest agents. Migrate to VNet Flow Logs. Consequence: your security team thinks they have flow visibility, they don't. (security-engineer overlay covers this.)

### 7. Cosmos DB for PostgreSQL is retiring — don't pick it

If anyone (user, vendor sample, blog post, older training data) proposes Cosmos DB for PostgreSQL for a new build, push back immediately. The replacement is **Azure Database for PostgreSQL Flexible Server with Elastic Clusters (Citus extension)**. Same Citus extension, supported lifecycle. (database-architect overlay covers this.)

### 8. PTU quotas are region-bound and contended

Azure OpenAI Provisioned Throughput Units (PTUs) are reserved capacity per region per deployment type. If you build an app assuming "we'll just provision more PTUs when we grow", you'll hit a regional cap that takes weeks to negotiate. Plan PTU allocation with the AI team's growth model, and have a Standard-tier fallback for burst. (ai-ml-engineer overlay covers this.)

### 9. Bicep `existing` references aren't enforced as ordering

`resource existing` in Bicep does not create a dependency. If the resource isn't actually deployed when your template runs, you get a runtime 404, not a compile error. Add explicit `dependsOn` or pass parameters through modules. (devops-engineer overlay covers this.)

### 10. Defender for Cloud plans price per-resource, not per-subscription

Enabling Defender for Servers Plan 2 across a subscription bills every VM, every Arc-enabled server, every container host. Run `az security pricing list` before flipping a plan on a multi-thousand-resource subscription. Use Azure Policy to scope plans by resource group / management group. (security-engineer overlay covers this.)

## Compliance composition — when verticals get involved

Azure is HIPAA/HITRUST/SOC 2/PCI/FedRAMP/IRS 1075/GDPR-eligible across the vast majority of services, but **service eligibility is per-service, per-region, and changes**. The pack lists current eligibility at last_verified_on; for an authoritative answer, point at the Microsoft Trust Center service-by-service compliance dashboard.

Splits to enforce:

- **Healthcare engagements (HIPAA / PHI / FHIR semantics):** Azure Health Data Services data model + HIPAA-eligible service selection is in this pack's scope (see `references/healthcare-architect.md`). HIPAA controls, BAA workflow, FHIR R4 semantics, audit discipline are in the **healthcare-architect specialist's** scope. Don't restate compliance content from this pack — route to the specialist.
- **Fintech engagements (PCI-DSS / PSD2 / ledger / AML):** Azure Confidential Ledger + Azure Payment HSM + PCI-eligible service selection is platform-level here. PCI-DSS, PSD2 strong customer authentication, ledger correctness, sanctions screening are **fintech-architect** territory. Note: this pack does NOT list fintech-architect in `applies_to_roles` because Azure's fintech footprint is well-served by general-purpose role overlays + the specialist; if that changes, add the overlay.
- **SaaS engagements:** Multi-tenant Azure patterns are in `references/saas-architect.md`. Billing-engine, entitlement-model, tenant lifecycle policy are the **saas-architect specialist's** territory.
- **AI safety / responsible AI / model governance:** Azure-side controls (Content Safety, Foundry evaluation, Entra Agent ID, Purview AI hub) are in `references/ai-ml-engineer.md`. Cross-cutting AI safety strategy is **ai-ml-engineer's** scope without the overlay.

## Currency — when this pack is stale

This pack is verified against Azure as of **2026-05-14**. Azure ships features weekly via Azure Updates and major surfaces shift at Build (May), Inspire (July), and Ignite (November). Treat the pack as **freshness ≤ 6 months** — past that, you must validate before recommending:

- SKU names and series (VM Cobalt/Dv6/Ev6/NC; AKS node SKUs; Cosmos throughput tiers)
- Service tier branding (Azure Cache for Redis migration progress; Azure Managed Redis tier rollout)
- AI Foundry model catalog (frontier models shift quarterly)
- Azure Functions runtime / Dapr / KEDA versions
- Defender for Cloud plan inventory and pricing
- Bicep + AVM module versions
- Azure Updates retirements (always check before recommending a "currently GA" feature)

Refresh protocol when stale:

1. Pull the latest [Azure Updates](https://azure.microsoft.com/updates/) for retired / changed services in your work area.
2. Validate any SKU / quota / pricing claim against [Microsoft Learn](https://learn.microsoft.com/azure/) (search the service page; the docs reflect current state faster than the pack).
3. For security-sensitive claims, check [Microsoft Security Update Guide](https://msrc.microsoft.com/update-guide) for relevant CVEs.
4. Bump `last_verified_on` and commit the refresh PR.

## Standing instructions for every role on an Azure engagement

1. **Anchor to currency.** Before recommending API shapes, SKUs, or product names, check whether the overlay references your role. If the overlay covers your area, follow it; do not pattern-match from older general-purpose knowledge. If the overlay does not cover your area, say so explicitly and consult Azure Updates + the relevant docs page before asserting specifics.

2. **Defer to specialists on domain.** Azure Health Data Services hosts FHIR R4 — that's a platform fact, in this pack. HIPAA compliance, BAA scoping, PHI semantics — that's healthcare-architect's territory. Same split for fintech (Confidential Ledger is platform; PCI-DSS is fintech) and SaaS (Hyperscale Elastic Pools is platform; entitlement engine is saas-architect).

3. **Honor Zero Trust by default.** Production Azure means: Managed Identity for every service-to-service auth, Private Link for every PaaS endpoint that supports it, Key Vault (RBAC mode) for every secret, Conditional Access on every human identity, MFA enforced (phishing-resistant for admins), Workload Identity Federation for every CI/CD service principal. Don't propose architectures that assume "we'll add security later" — Azure makes the default easy enough that there's no excuse.

4. **Use AVM (Azure Verified Modules) for landing zones.** New subscriptions / projects start with the AVM Platform Landing Zone module, not hand-rolled Bicep, not classic ALZ-Bicep (archived). The AVM ecosystem is the Microsoft-supported supply chain for Bicep + Terraform.

5. **Pick the right compute tier — don't default-to-AKS.** Azure has a real compute ladder: Functions Flex Consumption (event-driven), Container Apps (containerized microservices without K8s ops), AKS (when you need the K8s ecosystem), App Service (traditional web apps), VMs (lift-and-shift or specialized hardware). Don't reach for AKS because "Kubernetes is best practice" — Container Apps has Dapr, KEDA, Workload Profiles, and zero cluster ops. Use AKS when you need it, not when you don't.

6. **Stay specific within Azure.** "Azure" is not one thing. Government cloud (Azure Government), China (21Vianet), sovereign clouds (Azure Local, Arc), commercial — these differ materially. Workload Identity feature parity, service availability, and pricing all vary. Ask if it's unclear.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics for Health Data Services / PHI workflows | `healthcare-architect` (specialist, without Azure overlay) |
| PCI-DSS / PSD2 / AML / ledger semantics on Azure-hosted fintech | `fintech-architect` (specialist) |
| Multi-tenant SaaS billing engine, entitlement model, tenant lifecycle | `saas-architect` (the overlay handles Azure-side patterns; specialist handles strategy) |
| AI safety + responsible AI strategy beyond Azure-side controls | `ai-ml-engineer` (without overlay) |
| External system architecture not running on Azure | `system-architect` (without overlay) |
| Generic web frontend not deployed to Azure | `frontend-architect` (no Azure overlay shipped — yet) |

## Stack composition with other packs

If the user is using Azure **plus** another stack (Snowflake, Databricks-on-AWS, Stripe, Salesforce), and that other stack has a registered pack in `STACKS.md`, both overlays load. The Azure pack handles Azure-side patterns (Private Link → Snowflake, Azure Functions calling Stripe, Entra ID federation with Salesforce-as-IdP); the other pack handles its side. Neither pack should pretend to know the other's depth.

Common compositions to expect:

- **Azure + Salesforce** — Entra ID as IdP for Salesforce SSO; Salesforce External Client Apps calling Azure APIM; Data 360 Zero Copy to Synapse / Fabric.
- **Azure + Snowflake** — Snowflake on Azure marketplace; Private Link from Azure Functions / Container Apps to Snowflake; Purview classification reaching into Snowflake via OCI connector.
- **Azure + Databricks (Azure-native)** — Azure Databricks workspace is a first-party Microsoft offering; Unity Catalog + ABFS to ADLS Gen2; pass-through auth via Entra.
- **Azure + Stripe / external payments** — APIM as the egress edge; Key Vault for webhook signing keys; Service Bus for event ingest; Confidential Ledger for tamper-evident audit log.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- No `frontend-architect` overlay. Azure-hosted frontends (Static Web Apps, App Service, Azure Front Door + Blob) are addressable from the general-purpose frontend-architect specialist; deep coverage deferred until demand justifies.
- No `mobile-architect` overlay. Azure Notification Hubs + Azure Mobile Apps (deprecated) + App Center (retired) leave a thin Azure-mobile surface; mobile-architect specialist covers what's needed.
- No `qa-engineer` overlay. Azure DevOps test plans + Application Insights availability tests + Playwright-on-Azure are covered well by the general-purpose qa-engineer specialist; deep coverage deferred.
- No `technical-writer` overlay. Microsoft Learn authoring contracts are well-documented externally.
- No `project-planner` overlay. Azure DevOps Boards + Microsoft Planner + Loop are covered by the general-purpose project-planner.
- No `fintech-architect` overlay. Azure has Confidential Ledger, Payment HSM, and PCI-eligibility, but the fintech specialist + general overlays cover most engagements. Add an overlay if a major fintech-on-Azure engagement justifies it.
- No `real-time-architect` overlay. Azure SignalR Service + Web PubSub + Event Hubs cover the surface; real-time-architect specialist handles the patterns.
- No `e-commerce-architect` overlay. Azure has no first-party commerce platform (commerce typically runs on Sitecore-on-Azure, Commerce-on-Containers, BigCommerce-on-Azure); e-commerce-architect handles strategy.
- No `social-platform-architect` overlay. Social workloads run on the same compute/event mesh covered elsewhere in this pack.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation.

## Final word

Azure rewards teams that **lean into managed services and Microsoft-supported supply chains** (Bicep + AVM, Managed Identity, Container Apps + Workload Profiles, Foundry Agents) and punishes teams that **fight the platform with from-scratch K8s, hand-rolled secrets, classic SKUs the rest of Microsoft has moved off**. The overlays below tell each role how to lean in.
