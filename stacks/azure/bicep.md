---
title: Bicep
description: DSL over ARM. Deployment Stacks GA — Azure-native lifecycle management. .bicepparam files for typed parameters. Azure Verified Modules (AVM) ecosystem mature.
product:
  name: Azure Bicep
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect, security-engineer]
  authoritative_url: https://learn.microsoft.com/azure/azure-resource-manager/bicep/
  notes: "DSL over ARM; Deployment Stacks GA; AVM ecosystem mature; Platform Landing Zone AVM GA Jan 2026."
---

## What it is

Bicep is Microsoft's domain-specific language for Azure infrastructure-as-code — a clean DSL that compiles to ARM JSON. First-class with Azure features (Microsoft ships Bicep support concurrent with new resource provider features). Canonical reference: [Bicep docs](https://learn.microsoft.com/azure/azure-resource-manager/bicep/).

## When to use

Pick Bicep when:

- **Azure-only** infrastructure.
- **Newest Azure features** — Bicep gets them first; Terraform AzureRM lags by weeks.
- **No state file management** — Deployment Stacks handle it.
- **AVM ecosystem** — Microsoft-maintained modules.

Pick [Terraform AzureRM](/stacks/azure/terraform-azurerm/) for multi-cloud (AWS + Azure + GCP).

## 2025-2026 currency anchors

- **Bicep CLI 0.30+** current.
- **Deployment Stacks** (GA) — Azure-native lifecycle management; tracks deployed resources and auto-cleans removed ones (Terraform-state-like semantics without Terraform).
- **`.bicepparam` files** — typed parameter files.
- **Azure Verified Modules (AVM)** ecosystem mature — `br:mcr.microsoft.com/bicep/avm/...` registry.
- **AVM Platform Landing Zone module GA Jan 2026** — replaces classic ALZ-Bicep (archived Feb 2027).
- **`az deployment what-if`** — preview changes before deploy. Always run before prod.

## Patterns + anti-patterns

### Pattern: AVM module composition for landing zones

```bicep
module storage 'br:mcr.microsoft.com/bicep/avm/res/storage/storage-account:0.15.0' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      { service: 'blob', subnetResourceId: privateLinkSubnetId }
    ]
  }
}
```

### Pattern: Deployment Stacks for lifecycle

```bash
az stack sub create \
  --name my-stack \
  --location eastus2 \
  --template-file main.bicep \
  --action-on-unmanage deleteAll \
  --deny-settings-mode denyDelete
```

`action-on-unmanage`: `deleteAll` (Terraform-like), `deleteResources` (delete resource keep RG), `detachAll` (orphan).
`deny-settings-mode`: `denyDelete`, `denyWriteAndDelete`, `none`.

### Pattern: `.bicepparam` for typed parameter files

```bicep
// main.bicepparam
using './main.bicep'

param location = 'eastus2'
param envName = 'prod'
param skuName = readEnvironmentVariable('SKU_NAME', 'Standard_D4_v5')
```

Deploy: `az deployment sub create --location eastus2 --template-file main.bicep --parameters main.bicepparam`.

### Pattern: `what-if` on every PR

CI runs `az deployment sub what-if` and posts to PR. Verification before deploy.

### Anti-pattern: Hand-rolled Bicep where an AVM module exists

You're maintaining what Microsoft maintains, badly.

### Anti-pattern: AVM module pinned at `latest`

Pin specific versions. AVM follows SemVer; breaking changes happen.

### Anti-pattern: `resource existing` as ordering

`existing` does NOT create deployment dependencies. If the resource isn't deployed when the template runs, you get a runtime 404, not a compile error. Add explicit `dependsOn` or pass parameters through modules.

## Gotchas

- **`existing` references** are runtime-resolved; null if missing — handle in IaC review.
- **Deployment Stacks `deny-settings-mode`** prevents direct portal edits to managed resources. Good for compliance; surprises users.
- **Bicep linter** + **PSRule for Azure** are valuable in CI.
- **`azd` + Bicep** is the recommended starting point — see [Azure Developer CLI (azd)](/stacks/azure/azd/).

## Cross-references

- [Terraform AzureRM](/stacks/azure/terraform-azurerm/) — multi-cloud alternative
- [Azure Developer CLI (azd)](/stacks/azure/azd/) — wraps Bicep + deploy
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — IaC strategy + Deployment Stacks
- [System Architect on Azure](/stacks/azure/system-architect/) — Landing Zone via AVM
- [Bicep docs](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Deployment Stacks](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
