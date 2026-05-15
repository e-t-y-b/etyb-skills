---
title: Azure Developer CLI (azd)
description: "End-to-end project lifecycle. `azd up` (provision + deploy). 100+ templates. `azd ai agent` commands (March 2026). GitHub Copilot integration in `azd init`."
product:
  name: Azure Developer CLI (azd)
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect, backend-architect, ai-ml-engineer]
  authoritative_url: https://learn.microsoft.com/azure/developer/azure-developer-cli/
  notes: "1.12+ March 2026: AI agent commands, GitHub Copilot integration in `azd init`, pnpm/yarn detection."
---

## What it is

Azure Developer CLI (`azd`) is the end-to-end project lifecycle tool — `azd init` (scaffold from template), `azd provision` (Bicep / Terraform), `azd deploy` (app), `azd up` (both), `azd pipeline config` (CI/CD with OIDC). Canonical reference: [azd docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/).

## When to use

Pick azd when:

- **New project** — `azd init` from a template gives you working IaC + CI/CD + dev experience.
- **Local-to-prod parity** — `azd up` provisions infra and deploys app from the same definitions.
- **AI agent local dev** — `azd ai agent` commands (March 2026+).

azd is the **architect's recommended starting point for new projects** — it produces a working pairing that you customize from.

## 2025-2026 currency anchors

- **azd 1.12+ (March 2026)**:
  - `azd ai agent show / monitor` — local dev surface for AI agents.
  - **GitHub Copilot integration in `azd init`** (Preview).
  - **Container App Jobs deployment** via `host: containerapp` config.
  - **Package manager detection** (pnpm, yarn for JS/TS).
- **100+ templates** in `azd template list` and [Awesome AZD](https://azure.github.io/awesome-azd/).
- **`azd pipeline config`** auto-configures GitHub Actions with WIF (OIDC).
- **Hooks** — pre/post deploy scripts.

## Patterns + anti-patterns

### Pattern: `azd init` from template

```bash
azd template list                # browse
azd init --template Azure-Samples/azure-search-openai-demo
azd up                           # provision + deploy
```

Working app in minutes; customize from there.

### Pattern: `azd pipeline config` for OIDC CI/CD

```bash
azd pipeline config --provider github
```

Auto-creates UAMI, federated credential, GitHub Actions workflow with `azure/login@v2` (OIDC, no client secret).

### Pattern: `azd env` for environment separation

`azd env new dev` / `azd env new prod` — each environment has its own variables, IaC parameters, deployed resources.

### Pattern: `azd ai agent` for AI agent local dev

`azd ai agent monitor` streams logs / traces from a locally-running agent. Productive for prompt engineering iteration.

### Anti-pattern: Rolling your own scaffolding when a template fits

Microsoft + community maintain 100+ templates. Start from one; modify; commit. Custom-from-scratch is unnecessary work.

### Anti-pattern: Skipping `azd pipeline config` for CI/CD setup

Manually wiring UAMI + federated credential + workflow is error-prone. azd does it correctly.

## Gotchas

- **`azd.yaml`** is the project descriptor; understand it before customizing.
- **`infra/` folder** contains Bicep (or Terraform if you choose) — standard layout.
- **`azd hooks`** run pre/post phases — useful but easy to miss in code review.
- **Template versions** — pin or accept what `azd init` gives you; templates evolve.

## Cross-references

- [Bicep](/stacks/azure/bicep/) — default IaC
- [Terraform AzureRM](/stacks/azure/terraform-azurerm/) — alternative IaC
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — CI/CD with OIDC
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — `azd ai agent` workflows
- [azd docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Awesome AZD](https://azure.github.io/awesome-azd/)
