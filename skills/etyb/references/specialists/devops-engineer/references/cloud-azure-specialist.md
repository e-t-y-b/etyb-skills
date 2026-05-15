# Azure Cloud Engineering — Pointer

As of v4.0.0 (2026-05-14), all Azure-specific guidance — compute (AKS Auto/LTS, Container Apps, Functions Flex), data (Cosmos DB with DiskANN, Azure SQL Hyperscale, PostgreSQL Flexible Server, Azure Managed Redis), Entra ID + External ID (rebranded from Azure AD / B2C in 2023-2024), Defender for Cloud + Sentinel + Purview, Bicep + AVM + Deployment Stacks, AI Foundry (rebranded from Azure AI Studio in 2025) + Azure OpenAI, Microsoft Fabric, and 2025-2026 platform shifts — lives across two layers: the slim local detection pointer at [`stacks/azure/SKILL.md`](../../../../../../stacks/azure/SKILL.md) and the canonical per-product + per-role pages at **<https://docs.etyb.ai/stacks/azure/>**, fetched at runtime per `skills/etyb/core/knowledge-currency.md`.

## Where that content lives now

| Topic | Canonical location on docs.etyb.ai |
|-------|------------------------------------|
| Compute selection (VM series, AKS Auto/LTS/Karpenter, Container Apps Workload Profiles, Functions Flex) | <https://docs.etyb.ai/stacks/azure/system-architect/>, <https://docs.etyb.ai/stacks/azure/devops-engineer/> |
| Networking — Front Door, Application Gateway, VWAN, Private Link | <https://docs.etyb.ai/stacks/azure/system-architect/>, <https://docs.etyb.ai/stacks/azure/security-engineer/> |
| Databases — Cosmos DB (NoSQL + Mongo vCore + PostgreSQL retirement), Azure SQL, PostgreSQL Flexible Server, Azure Managed Redis | <https://docs.etyb.ai/stacks/azure/database-architect/> |
| Entra ID / External ID / PIM / Workload Identity Federation, Defender for Cloud, Sentinel, Purview | <https://docs.etyb.ai/stacks/azure/security-engineer/> |
| IaC — Bicep + Azure Verified Modules + Deployment Stacks, Terraform AzureRM v4, azd | <https://docs.etyb.ai/stacks/azure/devops-engineer/> |
| Observability — Azure Monitor + OTel Distro + Managed Prometheus/Grafana | <https://docs.etyb.ai/stacks/azure/sre-engineer/> |
| AI — AI Foundry, Azure OpenAI deployment types, Foundry Agents, Entra Agent ID | <https://docs.etyb.ai/stacks/azure/ai-ml-engineer/> |
| Multi-tenant SaaS on Azure (subscription vending, B2C → External ID migration) | <https://docs.etyb.ai/stacks/azure/saas-architect/> |
| Healthcare APIs (FHIR R4 service, healthcare workload patterns) | <https://docs.etyb.ai/stacks/azure/healthcare-architect/> |
| Hybrid + Azure Arc + Azure Local | <https://docs.etyb.ai/stacks/azure/system-architect/> |

## Why the move

Azure's product naming has shifted heavily in the v3 → v4 window: Azure AD → Entra ID, Azure AD B2C → Entra External ID, Azure AI Studio → AI Foundry, Cognitive Search → AI Search, with Foundry Agents and Entra Agent ID launching in 2025. The v4.0.0 knowledge-currency framework (`skills/etyb/core/knowledge-currency.md`) makes drift visible: every Stack carries `last_verified_on`, authoritative-source URLs, and per-product `drift_risk` ratings. The DevOps Engineer specialist owns *platform-neutral* DevOps patterns; the Azure Stack adds the platform-specific layer when ETYB's router detects Azure signals.
