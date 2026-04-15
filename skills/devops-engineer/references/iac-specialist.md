# Infrastructure as Code — Deep Reference

**Always use `WebSearch` to verify version numbers, CLI flags, and feature availability before giving advice. This reference provides architectural context; the IaC ecosystem evolves rapidly.**

## Table of Contents
1. [Terraform (1.10 / 1.11 / 1.15)](#1-terraform-110--111--115)
2. [OpenTofu (1.8 / 1.9 / 1.10 / 1.11)](#2-opentofu-18--19--110--111)
3. [Pulumi](#3-pulumi)
4. [AWS CDK v2](#4-aws-cdk-v2)
5. [CloudFormation](#5-cloudformation)
6. [Bicep](#6-bicep)
7. [State Management](#7-state-management)
8. [Module Design Patterns](#8-module-design-patterns)
9. [Testing IaC](#9-testing-iac)
10. [Drift Detection and Remediation](#10-drift-detection-and-remediation)
11. [GitOps for Infrastructure](#11-gitops-for-infrastructure)
12. [Platform Engineering and IaC](#12-platform-engineering-and-iac)
13. [IaC Tool Selection Framework](#13-iac-tool-selection-framework)

---

## 1. Terraform (1.10 / 1.11 / 1.15)

### Version Timeline

| Version | Release | Key Feature |
|---------|---------|-------------|
| **1.5** | Jun 2023 | `import` and `check` blocks, `moved` block cross-module |
| **1.6** | Oct 2023 | Native `terraform test` framework |
| **1.7** | Jan 2024 | `removed` block, config-driven `import` for_each |
| **1.8** | Apr 2024 | Provider-defined functions |
| **1.9** | Sep 2024 | Enhanced variable validation |
| **1.10** | Dec 2024 | Ephemeral values (variables, outputs, resources) |
| **1.11** | Mar 2025 | Write-only arguments, test `state_key` |
| **1.15** | 2026 (beta) | Variables/locals in module `source`/`version` |

### Import, Check, and Moved Blocks

```hcl
# import block (1.5+) — declarative, version-controlled import
import {
  to = aws_s3_bucket.legacy
  id = "my-legacy-bucket-prod"
}

# for_each import (1.7+) — bulk import
import {
  for_each = var.existing_security_groups
  to       = aws_security_group.imported[each.key]
  id       = each.value
}

# check block — post-deploy assertions (warnings, not errors)
check "api_health" {
  data "http" "api" { url = "https://${aws_lb.main.dns_name}/healthz" }
  assert {
    condition     = data.http.api.status_code == 200
    error_message = "API health check failed."
  }
}

# moved block — refactor without destroy/recreate
moved {
  from = aws_instance.web
  to   = module.networking.aws_instance.application
}
```

Auto-generate resource blocks: `terraform plan -generate-config-out=generated.tf`

### Variable Validation, Ephemeral Values, and Stacks

```hcl
variable "cidr_block" {
  type = string
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}

# Ephemeral values (1.10+) — never persisted in state or plan
ephemeral "aws_secretsmanager_secret_version" "db_pass" {
  secret_id = aws_secretsmanager_secret.db.id
}

# Write-only argument (1.11+) — provider accepts but never reads back
resource "aws_db_instance" "main" {
  password_wo         = ephemeral.aws_secretsmanager_secret_version.db_pass.secret_string
  password_wo_version = 1
}
```

**Terraform Stacks (GA)**: Manage multiple components (VPC, database, app cluster) as a single deployment unit. All stacks commands now in main CLI (`terraform stacks`).

### HCP Terraform (Cloud) Pricing

| Tier | Price | Concurrent Runs | Key Features |
|------|-------|-----------------|--------------|
| **Free** | $0 | 1 | 500 managed resources, remote state, VCS |
| **Essentials** | ~$0.10/resource/mo | 3 | Teams, SSO, run tasks |
| **Standard** | ~$0.47/resource/mo | 5 | Sentinel/OPA, audit logging, drift detection |
| **Premium** | ~$0.99/resource/mo | 10 | Self-hosted agents, custom concurrency |
| **Enterprise** | Custom | Custom | Air-gapped, full data sovereignty |

Free Legacy tier end-of-life: March 31, 2026 (auto-transition to new Free tier).

---

## 2. OpenTofu (1.8 / 1.9 / 1.10 / 1.11)

### Divergence from Terraform

OpenTofu (MPL-2.0 licensed) has introduced features Terraform lacks:

| Feature | OpenTofu | Terraform |
|---------|----------|-----------|
| **State encryption** | Native since 1.7 (AES-GCM, AWS KMS, GCP KMS, OpenBao) | Not available |
| **Client-side plan encryption** | Yes (same key providers as state) | Not available |
| **Early variable/locals evaluation** | 1.8+ (vars in `terraform {}` block, module sources) | 1.15 beta (partial) |
| **Provider `for_each`** | 1.9+ (dynamic multi-region providers) | Not available |
| **`-exclude` flag** | 1.9+ | Not available |
| **Native test framework** | 1.10+ | 1.6+ |
| **Ephemeral resources** | 1.11+ | 1.10+ |
| **License** | MPL-2.0 (open source) | BSL 1.1 (source-available) |

### State Encryption

```hcl
terraform {
  encryption {
    key_provider "aws_kms" "main" {
      kms_key_id = "arn:aws:kms:us-east-1:123456789:key/my-key-id"
      region     = "us-east-1"
    }
    method "aes_gcm" "default" { keys = key_provider.aws_kms.main }
    state { method = method.aes_gcm.default }
    plan  { method = method.aes_gcm.default }
  }
}
```

Key providers: `pbkdf2`, `aws_kms`, `gcp_kms`, `openbao` (beta).

### Early Variable Evaluation (1.8+) and Provider Iteration (1.9+)

```hcl
# Variables in terraform block and module source — OpenTofu only
terraform {
  backend "s3" { bucket = "tfstate-${var.environment}" }
}
module "vpc" {
  source = "git::https://github.com/org/modules.git//vpc?ref=${var.module_version}"
}

# Provider for_each (1.9+) — dynamic multi-region
provider "aws" {
  for_each = toset(["us-east-1", "eu-west-1", "ap-southeast-1"])
  alias    = each.value
  region   = each.value
}
```

---

## 3. Pulumi

### Language Support

| Language | Maturity | Policy (CrossGuard) |
|----------|----------|-------------------|
| **TypeScript/JavaScript** | GA | Yes |
| **Python** | GA | Yes |
| **Go** | GA | No |
| **C# (.NET)** | GA | No |
| **Java** | GA | No |
| **YAML** | GA | No |
| **OPA (Rego)** | GA | Yes (policies only) |

### Pulumi ESC (Environments, Secrets, Configuration)

Centralized secrets and config management. Aggregates secrets from Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager into composable *environments*. Immutable revision history with side-by-side diff.

### Pulumi Deployments (GA)

Managed infrastructure execution with Review Stacks, GitHub Enterprise support, and multiple deployment triggers. Eliminates self-hosted CI runners for infrastructure.

### Pulumi CrossGuard Policy

```typescript
new policy.PolicyPack("compliance", {
  policies: [{
    name: "s3-no-public-read",
    enforcementLevel: "mandatory",
    validateResource: policy.validateResourceOfType(
      aws.s3.Bucket, (bucket, args, reportViolation) => {
        if (bucket.acl === "public-read")
          reportViolation("S3 bucket must not be publicly readable.");
      }),
  }],
});
```

CrossGuard policies can be written in TypeScript, Python, or OPA/Rego. Java and YAML are supported for infrastructure code, but not for policy authoring.

### Pulumi Automation API

```typescript
import { LocalWorkspace } from "@pulumi/pulumi/automation";
const stack = await LocalWorkspace.createOrSelectStack({
  stackName: "dev", projectName: "infra",
  program: async () => {
    const bucket = new aws.s3.Bucket("data", { tags: { Environment: "dev" } });
    return { bucketName: bucket.id };
  },
});
const result = await stack.up({ onOutput: console.log });
```

Embed Pulumi operations inside application code for self-service infrastructure provisioning.

**Pulumi Neo**: Purpose-built AI agent for platform engineering. **MCP Server**: Connects AI assistants directly to Pulumi CLI and registry.

---

## 4. AWS CDK v2

### Construct Levels

| Level | Description | Example |
|-------|-------------|---------|
| **L1** | Direct CloudFormation mapping (`Cfn*` prefix) | `CfnBucket` |
| **L2** | Opinionated defaults, helper methods | `Bucket` (sensible encryption defaults) |
| **L3** | Patterns composing multiple resources | `ApplicationLoadBalancedFargateService` |

### CDK Example with L2 Constructs

```typescript
const bucket = new s3.Bucket(this, "DataBucket", {
  encryption: s3.BucketEncryption.S3_MANAGED,
  versioned: true,
  lifecycleRules: [{ expiration: cdk.Duration.days(90) }],
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});
const processor = new lambda.Function(this, "Processor", {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: "index.handler",
  code: lambda.Code.fromAsset("lambda/"),
  environment: { BUCKET_NAME: bucket.bucketName },
});
bucket.grantReadWrite(processor);  // L2 convenience — generates IAM policy
```

### CDK Testing (Fine-Grained Assertions)

```typescript
import { Template, Match } from "aws-cdk-lib/assertions";
const template = Template.fromStack(new DataPipelineStack(app, "Test"));
template.hasResourceProperties("AWS::S3::Bucket", {
  BucketEncryption: { ServerSideEncryptionConfiguration: Match.arrayWith([
    Match.objectLike({ ServerSideEncryptionByDefault: { SSEAlgorithm: "AES256" } }),
  ])},
});
template.resourceCountIs("AWS::Lambda::Function", 1);
```

**CDK Pipelines**: Self-mutating CI/CD — pipeline updates itself when CDK code changes. Add stages with `pipeline.addStage()` and manual approval gates.

### 2026 Updates

- **Mixins**: Compose reusable infrastructure patterns as a core language construct
- **Bedrock support**: First-class CDK constructs for AI model provisioning
- **GitOps**: Integration with ArgoCD and Flux
- **CDKTF deprecated**: Archived Dec 10, 2025 — migrate to HCL or AWS CDK

---

## 5. CloudFormation

### Current State (2025-2026)

CloudFormation remains the foundational AWS IaC service. Key 2025 enhancements:
- **Early validation**: Catches template errors before deployment
- **IaC Generator**: Scan existing AWS resources and generate templates (3 scans/day, 30-day validity), with targeted resource type scanning (2025)
- **Deployment safety**: Improved drift detection and configuration management
- **IaC MCP Server**: Nine specialized AI tools for documentation search and guidance

### StackSets

Deploy stacks across accounts and regions with dependency ordering:
- Up to 10 dependencies per stack instance via `DependsOn` parameter
- Built-in cycle detection for dependency resolution
- Drift detection across multi-account StackSet instances

### Key Tools

| Tool | Purpose |
|------|---------|
| **cfn-lint** | Local syntax and best-practice validation |
| **rain** | CLI for rapid CloudFormation development (deploy, logs, diff) |
| **CloudFormation Guard** | Policy-as-code for template validation |
| **IaC Generator** | Reverse-engineer templates from existing resources |

### CloudFormation vs CDK Decision

Use **CloudFormation** directly when: team prefers declarative YAML/JSON, existing template library, simpler stacks, or non-developer operators manage infrastructure.

Use **CDK** when: team knows TypeScript/Python, need abstractions over boilerplate, complex conditional logic, want programmatic testing, or building shared construct libraries.

---

## 6. Bicep

### Latest Version: 0.42.1 (April 2026)

Bicep is Azure's recommended IaC language, transpiling to ARM templates. Approximately half the line count of equivalent ARM JSON.

### Key Features (2025-2026)

| Feature | Version | Status |
|---------|---------|--------|
| **Deployment Stacks** | 0.36+ | GA — lifecycle management, auto-cleanup with `ActionOnUnmanage: DeleteAll` |
| **Azure Verified Modules (AVM)** | -- | GA — standardized modules for Landing Zones |
| **Microsoft Graph extension** | 0.38+ | Experimental — manage Entra ID resources in Bicep |
| **Kubernetes extension** | 0.38+ | Experimental — deploy K8s manifests via Bicep |
| **Snapshot command** | 0.41.2 | GA — normalized resource snapshots |
| **Multi-line interpolated strings** | 0.41.2 | GA |
| **Local Deploy** | 0.42+ | Experimental — run Bicep extensions locally without Azure |
| **CIDR functions** | 0.36+ | GA — `parseCidr()`, `cidrSubnet()` |
| **.bicepparam files** | 0.36+ | GA — IntelliSense-enabled parameter files |
| **Managed identity on modules** | 0.36.1+ | GA |

### Bicep Example

```bicep
@description('The environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

param tags object = {
  Environment: environment
  ManagedBy: 'Bicep'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${environment}${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: { name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
  }
}

output storageAccountId string = storageAccount.id
output keyVaultUri string = keyVault.properties.vaultUri
```

### Deployment Stacks

Deployment Stacks track which resources should exist and automatically clean up orphaned resources. This eliminates manual cleanup scripts when policies or resources are removed from templates.

### Extensibility Terminology

Microsoft is deprecating the term *provider* in Bicep, replacing it with *extension* for clarity (since *provider* conflicts with Azure Resource Providers). Phase 1 covers built-in first-party extensions; Phase 2 will enable third-party extensions.

---

## 7. State Management

### Remote Backend Comparison

| Backend | Locking | Encryption | Best For |
|---------|---------|-----------|----------|
| **S3 + DynamoDB** | DynamoDB table | SSE-KMS (AES-256) | AWS-native teams |
| **GCS** | Native | CMEK / default | GCP-native teams |
| **Azure Blob** | Native blob lease | SSE + CMEK | Azure-native teams |
| **HCP Terraform** | Built-in | Managed | Teams using Terraform Cloud |
| **pg (PostgreSQL)** | Advisory locks | TLS in transit | Self-hosted, multi-tool |
| **Consul** | Session-based | ACLs + TLS | HashiCorp ecosystem |
| **OpenTofu encrypted** | Backend-dependent | Client-side AES-GCM | Security-critical workloads |

### S3 Backend Configuration (Production)

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state-prod"
    key            = "services/api/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:123456789:alias/terraform-state"
    dynamodb_table = "terraform-locks"
  }
}
```

### State Migration

```bash
# Step 1: Update backend configuration in .tf files
# Step 2: Run init with migration flag
terraform init -migrate-state

# Pre-migration checklist:
# - Backup current state: terraform state pull > backup.tfstate
# - Coordinate with team (no concurrent applies)
# - Test in non-production first
# - Validate after migration: terraform plan (should show no changes)
```

### Import Workflows

| Method | Terraform Version | Use Case |
|--------|------------------|----------|
| `terraform import` CLI | All | One-off imports, scripted bulk |
| `import {}` block | 1.5+ | Version-controlled, reviewable |
| `import { for_each }` | 1.7+ | Bulk declarative import |
| CloudFormation IaC Generator | N/A | AWS resource scan + template gen |
| `cdk migrate` | CDK v2 | Convert CFN templates to CDK |
| `az deployment stack` | Bicep | Azure existing resource adoption |

---

## 8. Module Design Patterns

### Versioning Strategy

Use semantic versioning with version constraints:

```hcl
module "vpc" {
  source  = "app.terraform.io/company/vpc/aws"
  version = "~> 3.0"   # Accepts 3.x.x, not 4.0.0
}

module "rds" {
  source  = "app.terraform.io/company/rds/aws"
  version = ">= 2.1.0, < 3.0.0"
}
```

### Monorepo vs Polyrepo

| Factor | Monorepo | Polyrepo |
|--------|----------|----------|
| **Versioning** | Path-based refs or custom registry | Git tags per repo |
| **CI/CD** | Matrix builds, selective testing | Independent pipelines |
| **Discoverability** | Single search surface | Scattered, needs catalog |
| **Coupling** | Higher — cross-module changes easy | Lower — explicit boundaries |
| **Best for** | Small-medium teams, tightly coupled modules | Large orgs, multiple platform teams |

### Composition Pattern

Prefer thin root modules that compose child modules:

```hcl
# root module composes domain modules
module "networking" {
  source      = "./modules/networking"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "database" {
  source            = "./modules/database"
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.networking.db_security_group_id
  environment       = var.environment
}

module "application" {
  source            = "./modules/application"
  subnet_ids        = module.networking.public_subnet_ids
  db_endpoint       = module.database.endpoint
  environment       = var.environment
}
```

### Terragrunt 1.0

Terragrunt v1.0 (GA, 2025) adds **Stacks** for reusable unit combinations, declared via `terragrunt.stack.hcl` files. Other improvements: recursive stack generation, dynamic values via `terragrunt.values.hcl`, overhauled CLI (no more `terragrunt-` prefix flags), and the `run` command replacing `run-all`.

---

## 9. Testing IaC

### Testing Pyramid for IaC

| Layer | Tool | Speed | Cost | Catches |
|-------|------|-------|------|---------|
| **Static analysis** | Checkov, Trivy, KICS | Seconds | Free | Misconfigs, policy violations |
| **Unit tests** | `terraform test`, CDK assertions | Seconds | Free | Logic errors, expected outputs |
| **Plan-based tests** | OPA/Rego on `terraform show -json` | Seconds | Free | Resource drift, policy violations |
| **Integration tests** | Terratest (Go) | Minutes | Real infra cost | End-to-end, actual cloud behavior |

### Native Terraform Test Framework (1.6+)

```hcl
# tests/vpc.tftest.hcl
run "vpc_creates_correct_subnets" {
  command = plan

  variables {
    vpc_cidr    = "10.0.0.0/16"
    environment = "test"
    az_count    = 2
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Expected 2 private subnets, got ${length(aws_subnet.private)}"
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR does not match input."
  }
}

run "tags_are_applied" {
  command = plan

  assert {
    condition     = aws_vpc.main.tags["Environment"] == "test"
    error_message = "Environment tag missing or incorrect."
  }
}
```

### Security Scanners

| Tool | Policies | IaC Support | Status |
|------|----------|-------------|--------|
| **Checkov** | 1,000+ built-in | TF, CFN, K8s, ARM, Helm, Dockerfile | Active, 80M+ downloads |
| **Trivy** | tfsec rules absorbed | TF, CFN, K8s, Helm, Docker, ARM, Ansible | Active (tfsec deprecated 2023) |
| **KICS** | 2,400+ Rego queries | TF, CFN, K8s, Ansible, Pulumi, Helm, Docker | Active |
| **Terrascan** | -- | -- | **Archived Nov 2025** — migrate away |

### Sentinel vs OPA

| Aspect | Sentinel | OPA (Rego) |
|--------|----------|-----------|
| **Scope** | HashiCorp products only | Any JSON — K8s, Terraform, APIs, CI |
| **Enforcement** | Advisory, soft-mandatory, hard-mandatory | Deny/allow/warn |
| **Data input** | Native `tfplan/v2` imports | `terraform show -json` output |
| **Runs** | Inside TFC/TFE | Anywhere (pre-commit, CI, admission) |
| **License** | Proprietary (TFC/TFE required) | Open source (Apache 2.0) |
| **Best for** | All-in on Terraform Cloud/Enterprise | Multi-tool, multi-cloud environments |

HCP Terraform supports both Sentinel and OPA side by side in the same workspace.

---

## 10. Drift Detection and Remediation

### Detection Strategies

| Strategy | Tool | Frequency |
|----------|------|-----------|
| **Scheduled plan** | `terraform plan` in CI (cron) | Hourly/daily |
| **Platform drift scan** | Spacelift, env0, Terraform Cloud | Continuous |
| **AWS Config rules** | `cloudformation-stack-drift-detection-check` | Real-time |
| **Pulumi refresh** | `pulumi refresh --diff` | On-demand/CI |
| **CloudFormation** | Drift detection API on stacks and StackSets | On-demand |

### Remediation Best Practices

1. **Auto-PR on drift**: Scheduled `terraform plan` detects drift, CI opens a PR with the diff against the IaC repo
2. **Triage by severity**: Link drift events to compliance frameworks (SOX, GDPR, HIPAA) to prioritize remediation
3. **Never auto-apply**: Drift remediation should be reviewed — auto-apply can revert intentional emergency changes
4. **Root cause tagging**: Tag each drift event (manual console change, missing IaC coverage, provider bug)
5. **Reconciliation loop**: Import unmanaged resources into IaC rather than destroying them

### Continuous Compliance Architecture

```
Scheduled trigger (cron/webhook)
  -> terraform plan -detailed-exitcode
  -> Exit code 2 = drift detected
  -> Generate diff report
  -> Open PR / Slack alert / PagerDuty
  -> Human review + approve
  -> terraform apply
  -> Audit log updated
```

---

## 11. GitOps for Infrastructure

### Platform Comparison

| Platform | Open Source | IaC Support | Key Differentiator |
|----------|-----------|-------------|-------------------|
| **Atlantis** | Yes (self-hosted) | Terraform, OpenTofu | PR-based plan/apply, lowest cost |
| **Spacelift** | No (SaaS) | TF, OpenTofu, Pulumi, CFN, Ansible, K8s | Multi-IaC, built-in drift detection |
| **env0** | No (SaaS) | TF, OpenTofu, Pulumi, CFN, Ansible, Helm | FinOps focus, cost estimation |
| **Scalr** | No (SaaS) | TF, OpenTofu | OPA built-in, hierarchical config |
| **HCP Terraform** | No (SaaS) | Terraform only | Deepest TF integration, Stacks, Sentinel |
| **Crossplane** | Yes (CNCF Graduated) | K8s-native CRDs | Kubernetes reconciliation loop |

### Atlantis

Self-hosted, listens for PR comments (`atlantis plan`, `atlantis apply`). Free, widely adopted, but requires operational overhead for scaling, security hardening, and secret management.

### Crossplane v2 (2025-2026)

Crossplane v2 (GA Aug 2025) makes composite resources (XRs) namespaced by default. CNCF Graduated project.

- **Composition Functions**: Request OpenAPI schemas for any cluster resource kind
- **Providers**: AWS, Azure, GCP, Alibaba, DigitalOcean, Helm, ArgoCD, GitHub
- **Key value**: Kubernetes reconciliation loop for infrastructure — continuous drift correction built in

---

## 12. Platform Engineering and IaC

### Adoption (2026)

Gartner reports 80% of software engineering orgs now have dedicated platform teams (up from 55% in 2025). IDPs and self-service infrastructure reduce cognitive load by 40-50%.

### Golden Paths

Pre-approved, opinionated IaC blueprints that make the secure, compliant choice the easiest path:

```
Developer Portal (Backstage / Port)
  -> Select "New Microservice" template
  -> Fill: name, team, environment
  -> Scaffolder creates:
     - Git repo with app skeleton
     - Terraform module (VPC, ECS, RDS)
     - CI/CD pipeline (GitHub Actions)
     - Monitoring (Datadog dashboards)
     - Backstage catalog entry
  -> PR auto-created, reviewed, merged
  -> Infrastructure deployed via Spacelift/Atlantis
```

### Backstage + IaC Integration

Backstage scaffolder templates invoke Terraform modules or Pulumi programs to provision infrastructure alongside application code. TMNA uses 40+ approved templates through Backstage's self-service catalog.

### Architecture Layers

| Layer | Purpose | Tools |
|-------|---------|-------|
| **Developer Portal** | Self-service catalog, templates | Backstage, Port, Cortex |
| **IaC Engine** | Resource provisioning | Terraform, Pulumi, Crossplane |
| **Policy Engine** | Guardrails, compliance | OPA, Sentinel, Checkov |
| **GitOps** | Deployment orchestration | Atlantis, Spacelift, ArgoCD |
| **Observability** | Drift, cost, health | Datadog, Firefly, Spacelift |

---

## 13. IaC Tool Selection Framework

### Decision Matrix

| Factor | Terraform | OpenTofu | Pulumi | CDK | CloudFormation | Bicep |
|--------|-----------|----------|--------|-----|----------------|-------|
| **Cloud** | Multi-cloud | Multi-cloud | Multi-cloud | AWS only | AWS only | Azure only |
| **Language** | HCL | HCL | TS/Py/Go/C#/Java | TS/Py/Go/C#/Java | YAML/JSON | Bicep DSL |
| **License** | BSL 1.1 | MPL-2.0 | Apache 2.0 | Apache 2.0 | Proprietary | MIT |
| **State** | Remote file | Remote file (encrypted) | Managed service or self-hosted | CloudFormation | CloudFormation | ARM/Azure |
| **Learning curve** | Medium (HCL) | Medium (HCL) | Low (if you know the language) | Medium | Low (YAML) | Low |
| **Ecosystem** | Largest provider registry | Growing, Terraform-compatible | Strong, growing | AWS-only constructs | AWS-only resources | Azure-only |
| **Testing** | Built-in + Terratest | Built-in | Standard test frameworks | CDK assertions | cfn-lint, Guard | Bicep linter |
| **Drift detection** | Plan-based | Plan-based | Refresh-based | Stack drift | Stack drift | Deployment Stacks |
| **GitOps tools** | Atlantis, Spacelift, env0, Scalr, TFC | Same as Terraform | Pulumi Deployments | CDK Pipelines | StackSets | Azure DevOps / bicep-deploy |
| **Best for** | Multi-cloud, large ecosystem | Open-source preference, state encryption | Dev teams, programming-first | AWS-heavy, TypeScript shops | Simple AWS, low-code teams | Azure-only shops |

### Decision Flowchart

```
Start
  |
  +-- Azure only? -> Bicep (default) or Terraform (multi-cloud future)
  |
  +-- AWS only?
  |     +-- Team knows TypeScript/Python? -> CDK
  |     +-- Prefer declarative YAML? -> CloudFormation
  |     +-- Multi-cloud possible later? -> Terraform / OpenTofu
  |
  +-- Multi-cloud?
  |     +-- Programming-first team? -> Pulumi
  |     +-- Ops-first team? -> Terraform or OpenTofu
  |     +-- Open source required? -> OpenTofu
  |     +-- State encryption required? -> OpenTofu
  |
  +-- K8s-native control plane? -> Crossplane
```

### Migration Paths

| From | To | Strategy |
|------|-----|----------|
| CloudFormation -> CDK | Use `cdk migrate` to import existing CFN templates |
| Terraform -> OpenTofu | Drop-in replacement — `tofu init` on existing HCL |
| CDKTF -> HCL | Manual conversion (CDKTF archived Dec 2025) |
| ARM -> Bicep | `az bicep decompile` for automatic conversion |
| Console-managed -> IaC | CloudFormation IaC Generator or `terraform import` blocks |
