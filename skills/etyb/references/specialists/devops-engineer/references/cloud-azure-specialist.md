# Azure Cloud Engineering — Pointer

As of v4.0.0 (2026-05-14), all Azure-specific guidance — compute (AKS Auto/LTS, Container Apps, Functions Flex), data (Cosmos DB with DiskANN, Azure SQL Hyperscale, PostgreSQL Flexible Server, Azure Managed Redis), Entra ID + External ID (rebranded from Azure AD / B2C in 2023-2024), Defender for Cloud + Sentinel + Purview, Bicep + AVM + Deployment Stacks, AI Foundry (rebranded from Azure AI Studio in 2025) + Azure OpenAI, Microsoft Fabric, and 2025-2026 platform shifts — lives in the **Azure Stack Pack** at [`stacks/azure/SKILL.md`](../../../../../../stacks/azure/SKILL.md).

## Where that content lives now

| Topic | New location |
|-------|--------------|
| Compute selection (VM series, AKS Auto/LTS/Karpenter, Container Apps Workload Profiles, Functions Flex) | `stacks/azure/references/system-architect.md`, `stacks/azure/references/devops-engineer.md` |
| Networking — Front Door, Application Gateway, VWAN, Private Link | `stacks/azure/references/system-architect.md`, `stacks/azure/references/security-engineer.md` |
| Databases — Cosmos DB (NoSQL + Mongo vCore + PostgreSQL retirement), Azure SQL, PostgreSQL Flexible Server, Azure Managed Redis | `stacks/azure/references/database-architect.md` |
| Entra ID / External ID / PIM / Workload Identity Federation, Defender for Cloud, Sentinel, Purview | `stacks/azure/references/security-engineer.md` |
| IaC — Bicep + Azure Verified Modules + Deployment Stacks, Terraform AzureRM v4, azd | `stacks/azure/references/devops-engineer.md` |
| Observability — Azure Monitor + OTel Distro + Managed Prometheus/Grafana | `stacks/azure/references/sre-engineer.md` |
| AI — AI Foundry, Azure OpenAI deployment types, Foundry Agents, Entra Agent ID | `stacks/azure/references/ai-ml-engineer.md` |
| Multi-tenant SaaS on Azure (subscription vending, B2C → External ID migration) | `stacks/azure/references/saas-architect.md` |
| Healthcare APIs (FHIR R4 service, healthcare workload patterns) | `stacks/azure/references/healthcare-architect.md` |
| Hybrid + Azure Arc + Azure Local | `stacks/azure/references/system-architect.md` |

## Why the move

Azure's product naming has shifted heavily in the v3 → v4 window: Azure AD → Entra ID, Azure AD B2C → Entra External ID, Azure AI Studio → AI Foundry, Cognitive Search → AI Search, with Foundry Agents and Entra Agent ID launching in 2025. The v4.0.0 knowledge-currency framework (`skills/etyb/core/knowledge-currency.md`) makes drift visible: every Stack carries `last_verified_on`, authoritative-source URLs, and per-product `drift_risk` ratings. The DevOps Engineer specialist owns *platform-neutral* DevOps patterns; the Azure Stack adds the platform-specific layer when ETYB's router detects Azure signals.
