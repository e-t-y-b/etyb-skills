---
title: Key Vault
description: Secrets / keys / certificates with Azure RBAC. Legacy access policies have gaps — use RBAC mode. Soft-delete + purge protection ALWAYS enabled. Private Link in production.
product:
  name: Azure Key Vault
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer, backend-architect]
  authoritative_url: https://learn.microsoft.com/azure/key-vault/
  notes: "Azure RBAC is the recommended access model; legacy access policies have known gaps."
---

## What it is

Azure Key Vault stores secrets, encryption keys, and TLS certificates. Backed by FIPS 140-2 Level 2 HSMs (Standard SKU) or Level 3 HSMs ([Managed HSM](/stacks/azure/key-vault/#when-to-use-managed-hsm) — separate service). Canonical reference: [Key Vault docs](https://learn.microsoft.com/azure/key-vault/).

## When to use

Always — every Azure project needs Key Vault. Choices are:

- **Standard vs Premium SKU** — Premium adds HSM-backed keys.
- **RBAC mode vs legacy access policies** — **always RBAC for new vaults.**
- **Standalone Key Vault vs Managed HSM** — Managed HSM (FIPS 140-2 L3, single-tenant) for regulated key custody.

## 2025-2026 currency anchors

- **Azure RBAC is the recommended access model.** Legacy access policies have known gaps (no scoped ABAC, awkward audit, no PIM integration, no ABAC conditions).
- **Migrate existing vaults** via Azure Policy initiative "Key vaults should use RBAC permission model".
- **Soft-delete + purge protection** should be enabled at create — without them, a malicious or accidental delete is unrecoverable.
- **Public network access** should be disabled in production; Private Endpoint instead.
- **Rotation policy** built-in for keys.
- **Managed HSM** for FIPS 140-2 Level 3 single-tenant — required for PCI card data keys, HIPAA highest-sensitivity PHI keys, FedRAMP High, CMK with audit-grade attestation.

## Patterns + anti-patterns

### Pattern: RBAC + soft-delete + purge protection at create

```bicep
properties: {
  enableRbacAuthorization: true
  enableSoftDelete: true
  softDeleteRetentionInDays: 90
  enablePurgeProtection: true
  publicNetworkAccess: 'Disabled'   // Private Endpoint in production
}
```

Once `enablePurgeProtection: true` is set, it cannot be disabled. Soft-deleted secrets/keys recover within retention period.

### Pattern: Key rotation policy

```bicep
resource keyRotation 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: kv
  name: 'my-encryption-key'
  properties: {
    rotationPolicy: {
      lifetimeActions: [
        { trigger: { timeAfterCreate: 'P90D' }, action: { type: 'Rotate' } }
      ]
    }
  }
}
```

Combine with Event Grid `Microsoft.KeyVault.SecretNearExpiry` / `SecretNewVersionCreated` → Function updates downstream consumers.

### Pattern: Managed Identity access from app code

App uses `DefaultAzureCredential` → Managed Identity → Entra token with `Key Vault Secrets User` RBAC role → reads secret. No connection string with embedded key.

### Pattern: Passwordless DB auth eliminates rotation

For Azure SQL / PostgreSQL / Cosmos / Managed Redis, use Entra auth + Managed Identity. No DB password in Key Vault, no rotation chore.

### Pattern: Built-in RBAC roles per access scope

| Role | Use |
|------|-----|
| Key Vault Administrator | Full control (rare; PIM-eligible only) |
| Key Vault Secrets Officer | Manage secret CRUD |
| Key Vault Secrets User | Read secret values |
| Key Vault Crypto Officer | Manage keys |
| Key Vault Crypto User | Use keys for crypto ops |

### Anti-pattern: Legacy access policies on new vaults

No scoping (anyone with "List secrets" lists every secret), awkward audit, no PIM. Use RBAC.

### Anti-pattern: Public network access on production Key Vault

Private Endpoint. Period. Enforce via Azure Policy.

### Anti-pattern: Soft-delete or purge protection disabled

Accidental or malicious delete is unrecoverable. Defaults: enabled.

### Anti-pattern: Storing JWT signing keys / cert PFXs / API tokens in app config

Key Vault (or Managed HSM for regulated). Apps fetch via Managed Identity.

## When to use Managed HSM

For regulated workloads requiring **FIPS 140-2 Level 3 single-tenant** HSM key custody:

- PCI-DSS card data encryption keys
- HIPAA / HITRUST highest-sensitivity PHI keys
- FedRAMP High
- Customer-Managed Keys (CMK) for storage / SQL / Cosmos where customer needs audit-grade attestation

Don't use Managed HSM where standard Key Vault Premium suffices — cost is materially higher.

## Gotchas

- **Soft-delete retention 7-90 days** — pick the right value at create.
- **Purge protection is one-way** — once enabled, cannot disable.
- **Cross-region replication** is via geo-redundant backups; not strong consistency.
- **`Microsoft.KeyVault` RP must be registered** in subscription before deploying.
- **App Service / Functions Key Vault references** use Managed Identity automatically — `@Microsoft.KeyVault(SecretUri=...)` in App Settings.

## Cross-references

- [Security Engineer on Azure](/stacks/azure/security-engineer/) — full key custody design
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — secret rotation patterns
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — SDK + Managed Identity
- [Event Grid](/stacks/azure/event-grid/) — Key Vault events for rotation flows
- [Key Vault RBAC guide](https://learn.microsoft.com/azure/key-vault/general/rbac-guide)
- [Key rotation](https://learn.microsoft.com/azure/key-vault/keys/how-to-configure-key-rotation)
- [Managed HSM overview](https://learn.microsoft.com/azure/key-vault/managed-hsm/overview)
