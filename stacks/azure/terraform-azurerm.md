---
title: Terraform AzureRM
description: Terraform AzureRM provider v4 current. Provider-defined functions; resource_provider_registrations flag. Multi-cloud IaC alternative to Bicep.
product:
  name: Terraform AzureRM provider
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect]
  authoritative_url: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
  notes: "v4 current; provider-defined functions; granular provider registration; lag vs Bicep on newest Azure features."
---

## What it is

The HashiCorp Terraform AzureRM provider — Azure resource Terraform support. Use it for multi-cloud (AWS + Azure + GCP in one workflow) or when your team has existing Terraform skills + Terraform Cloud / Enterprise investment. Canonical reference: [AzureRM provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).

## When to use

Pick Terraform AzureRM when:

- **Multi-cloud** — single workflow across providers.
- **Existing Terraform skills + workflows.**
- **Pre-existing modules** in your org.
- **Terraform Cloud / Enterprise** for state + RBAC + drift detection.

Pick [Bicep](/stacks/azure/bicep/) for Azure-only — Bicep gets new Azure features first.

## 2025-2026 currency anchors

- **v4 current** — released 2024; significant breaking changes from v3 (resource property renames, validation tightening).
- **Provider-defined functions** — e.g., `provider::azurerm::normalise_resource_id`.
- **`resource_provider_registrations`** flag — subset registration (replaces `skip_provider_registration`).
- **`resource_providers_to_register`** for explicit list.
- **Lag** — AzureRM provider lags Bicep by days/weeks on new Azure features.
- **Terraform AVM modules** (`Azure/avm-res-*`) — Microsoft-supported supply chain on Terraform side.

## Patterns + anti-patterns

### Pattern: Provider configuration with granular registration

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "core"
  resource_providers_to_register  = ["Microsoft.App", "Microsoft.OperationalInsights"]
}
```

### Pattern: Remote state in Terraform Cloud / Enterprise

State files contain provisioned secrets and resource references. Local state is unsafe in production (no concurrency, no RBAC). Remote state in Terraform Cloud / Enterprise / Atlantis / Spacelift / env0.

### Pattern: AVM modules over hand-rolled

```hcl
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"
  # ...
}
```

Microsoft-maintained, AVM-standard. Same supply chain story as Bicep.

### Pattern: `plan` on every PR

CI runs `terraform plan -out=tfplan`; posts plan to PR. Verification before apply.

### Anti-pattern: Local terraform.tfstate in production

Secrets at rest on laptop. Race conditions across team. Remote state, always.

### Anti-pattern: Workload Identity Federation via client secret in CI

Use `azure/login@v2` OIDC token + Terraform provider OIDC support (`use_oidc = true`). No client secret.

### Anti-pattern: Pinning to `latest` provider version

Pin to a minor version range (`~> 4.5`). Breaking changes between minor versions in v3→v4 happened; will happen again.

## Gotchas

- **v3 → v4 breaking changes** — verify with `terraform plan` before bulk-upgrading providers.
- **Provider lag** vs Bicep — if you need a newly GA'd Azure feature, Bicep may have it first.
- **`features {}` block** — required; quirks per resource type.
- **`azurerm_resource_group` `prevent_deletion_if_contains_resources`** — defaults vary; verify.

## Cross-references

- [Bicep](/stacks/azure/bicep/) — Azure-native alternative
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — IaC strategy
- [Terraform AzureRM provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
