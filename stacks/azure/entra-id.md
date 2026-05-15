---
title: Microsoft Entra ID
description: Renamed from Azure AD (July 2023). Entra Agent ID for AI workloads (Ignite 2025). CAE expanding. Token protection GA. Phishing-resistant MFA for admins.
product:
  name: Microsoft Entra ID
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, system-architect, saas-architect, healthcare-architect]
  authoritative_url: https://learn.microsoft.com/entra/identity/
  notes: "Renamed from Azure AD July 2023; Entra Agent ID GA at Ignite 2025; CAE + Token Protection expanding."
---

## What it is

Microsoft Entra ID is the workforce identity platform — directory, authentication, authorization, MFA, Conditional Access, PIM. Renamed from Azure Active Directory in July 2023. SDK package names (`Microsoft.Identity.Client`, `@azure/identity`) didn't change; brand and docs are now "Entra." Canonical reference: [Entra ID docs](https://learn.microsoft.com/entra/identity/).

## When to use

Always — every Azure subscription is anchored to an Entra tenant. Specific surfaces:

- **Workforce SSO** — employees access SaaS apps + Azure resources.
- **B2B collaboration** — invite partner users via cross-tenant access settings.
- **AI agent identity** — Entra Agent ID (Ignite 2025+).

For customer-facing CIAM, use [Entra External ID](/stacks/azure/entra-external-id/), not Entra ID.

## 2025-2026 currency anchors

- **Renamed from Azure AD** (July 2023). Use "Entra ID" in current voice.
- **Entra Agent ID** (Ignite 2025) — first-class identity for AI agents. Conditional Access, PIM, audit log apply to agent identities the same way as humans.
- **Continuous Access Evaluation (CAE)** — real-time policy enforcement (session revocation on risk).
- **Token Protection GA** — binds tokens to specific devices, prevents token replay.
- **Authentication strengths GA** — define which MFA methods are acceptable per app/policy (phishing-resistant for admins).
- **Identity Protection** — sign-in risk + user risk signals.
- **Multi-tenant Entra app registrations** for B2B SaaS.
- **AzureAD PowerShell module deprecated** — use Microsoft Graph PowerShell SDK.

## Patterns + anti-patterns

### Pattern: Zero Trust baseline

1. **MFA on every user** (with break-glass exception).
2. **Phishing-resistant MFA for admins** (FIDO2 / passkey / cert-based).
3. **Block legacy authentication** (POP, IMAP, SMTP basic, MAPI/EWS).
4. **Compliant device required for admin portals** (Intune-managed or hybrid-joined).
5. **All privileged roles PIM-eligible** (no permanent).
6. **Token Protection on sensitive apps.**
7. **CAE enabled.**

### Pattern: Break-glass account, always

One or two Global Administrator accounts excluded from Conditional Access, with strong passphrase + FIDO2 key in a safe + sign-in alerting on activation. Tested quarterly. **You will lock yourself out otherwise.**

### Pattern: Workload Identity Federation for CI/CD

Replace service principal client secrets with OIDC federation. See [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) for the GitHub Actions pattern.

### Pattern: Managed Identity for service-to-service

System-assigned or user-assigned Managed Identity → RBAC on target resource. No connection strings with secrets.

### Pattern: Entra Agent ID for AI agents

Production agent gets a first-class Entra identity. Conditional Access scopes when/where it operates; PIM gates sensitive ops; audit log attributes actions to the agent (not the human who invoked it, unless OBO). See [Security Engineer on Azure](/stacks/azure/security-engineer/).

### Anti-pattern: Saying "Azure AD" in 2026

Renamed July 2023. Reads as out-of-date.

### Anti-pattern: Permanent Global Admin assignments

PIM-eligible only. MFA at activation + max 4-8h duration + approval for high-impact roles.

### Anti-pattern: Service Principal client secrets in CI/CD

Workload Identity Federation eliminates these.

### Anti-pattern: Agent running with developer's user credentials

Audit log attributes the agent's actions to the developer. Use Entra Agent ID.

## Gotchas

- **Conditional Access "exclude break-glass account"** — must be tested. Account locked + Conditional Access blocking = you're stuck.
- **CAE works only on services that support it** — Exchange Online, SharePoint, Graph; expanding.
- **20 federated identity credentials per app / managed identity cap** — plan multiple UAMIs if you exceed.
- **Authentication strength** is a Conditional Access concept; not the same as MFA enforcement.
- **PIM activation requires MFA satisfied at activation** — the user must MFA at activation time, not just earlier in session.

## Cross-references

- [Entra External ID](/stacks/azure/entra-external-id/) — customer (CIAM) auth
- [Key Vault](/stacks/azure/key-vault/) — secrets / certs
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — full identity design
- [Foundry Agents](/stacks/azure/foundry-agents/) — agents that consume Entra Agent ID
- [SaaS Architect on Azure](/stacks/azure/saas-architect/) — multi-tenant app registrations + B2B
- [Conditional Access overview](https://learn.microsoft.com/entra/identity/conditional-access/overview)
- [PIM overview](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/)
- [Token Protection](https://learn.microsoft.com/entra/identity/conditional-access/concept-token-protection)
- [Workload Identity Federation](https://learn.microsoft.com/entra/workload-id/workload-identity-federation)
