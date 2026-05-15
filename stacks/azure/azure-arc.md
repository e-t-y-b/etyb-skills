---
title: Azure Arc
description: Project on-prem / multi-cloud resources into Azure. Servers + Kubernetes + Data Services + SQL Server. Indirect mode for Arc Data Services retired September 2025.
product:
  name: Azure Arc
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, security-engineer]
  authoritative_url: https://learn.microsoft.com/azure/azure-arc/
  notes: "Direct connected mode only for Arc Data Services as of Sep 2025; Arc Kubernetes + Servers mature."
---

## What it is

Azure Arc extends Azure management — RBAC, Policy, Monitor, Defender, Update Management — to resources outside Azure (on-prem, other clouds, edge). Arc-enabled Servers, Kubernetes, Data Services, SQL Server. Canonical reference: [Azure Arc docs](https://learn.microsoft.com/azure/azure-arc/).

## When to use

Pick Azure Arc when:

- **On-prem / multi-cloud resources** need unified Azure management.
- **GitOps via Flux v2** on non-AKS clusters (Arc-enabled Kubernetes).
- **SQL Server on-prem** with cloud-side observability + license benefits.
- **Hybrid landing zone** — Azure Local (Azure Stack HCI) + Arc.

## 2025-2026 currency anchors

- **Indirect connected mode for Arc Data Services retired September 2025** — direct connected only.
- **Arc-enabled Servers** — on-prem / other-cloud Linux + Windows machines into Azure inventory.
- **Arc-enabled Kubernetes** — non-AKS K8s clusters with Azure Policy + Defender + Flux v2 GitOps extension.
- **Arc-enabled SQL Server** — license benefits + Azure-side observability + Defender for SQL on Servers.
- **Arc-enabled Data Services** (PostgreSQL Hyperscale, SQL Managed Instance) for cloud-managed DB on customer infra.

## Patterns + anti-patterns

### Pattern: Arc-enabled Servers for unified inventory

On-prem + AWS EC2 + GCP Compute Engine all visible in Azure Resource Graph; one Defender for Servers plan covers all.

### Pattern: Arc-enabled Kubernetes for GitOps

Non-AKS cluster (EKS, on-prem K8s) + Flux v2 extension + Azure Policy for K8s = unified policy + GitOps experience.

### Pattern: Azure Local (Azure Stack HCI) + Arc for edge

Microsoft's hyperconverged infrastructure (renamed from Azure Stack HCI to Azure Local in 2024-25); Arc projects the resources into Azure.

### Anti-pattern: Arc Data Services indirect mode

Retired Sep 2025. Direct connected only.

### Anti-pattern: Arc as the primary management surface for cloud-native

Use Azure-native resources where possible. Arc is for when "we can't move it to Azure native."

## Gotchas

- **Arc agent installation** is the friction point — automate via configuration management.
- **Pricing** varies per Arc-enabled resource type; verify before scaling.
- **Direct mode for Arc Data Services** requires outbound connectivity from on-prem to Azure control plane.

## Cross-references

- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — GitOps via Flux v2
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — Defender for Servers on Arc
- [Azure VMware Solution](/stacks/azure/azure-vmware-solution/) — alternative hybrid path
- [Azure Arc docs](https://learn.microsoft.com/azure/azure-arc/)
