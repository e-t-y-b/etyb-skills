---
title: Security Engineer on Azure
description: Entra, External ID, Conditional Access, PIM, WIF, Key Vault, Managed HSM, Defender for Cloud, Sentinel, Purview, Azure Policy, Private Link, Confidential Computing, Entra Agent ID.
role_overlay:
  role: security-engineer
  stack: azure
  last_verified_on: "2026-05-14"
  products_covered:
    - entra-id
    - entra-external-id
    - key-vault
    - defender-for-cloud
    - sentinel
    - microsoft-purview
    - application-gateway
    - front-door
    - storage-account
    - azure-sql
    - postgresql-flexible-server
    - cosmos-db
    - aks
    - container-apps
    - functions
    - api-management
    - foundry-agents
    - azure-openai
---

## Role briefing

You're the security engineer on Azure. Identity, network, key custody, secrets, governance, threat detection, response, compliance, data classification. This view is heavier than most because Azure's security surface — **Entra ID + External ID + Conditional Access + PIM + Defender for Cloud + Sentinel + Purview + Key Vault + Managed HSM + Azure Policy + Confidential Computing** — is where most of the platform's value is delivered and where most things go wrong.

You don't write app code ([backend-architect](/stacks/azure/backend-architect/)) or IaC ([devops-engineer](/stacks/azure/devops-engineer/)) — you set the guardrails, run threat detection, respond to incidents, prove compliance, and push back when the architecture compromises security.

## Decision frameworks specific to this role's lens on Azure

### Identity tenant strategy

| Use case | Pick |
|----------|------|
| Employee SSO / SaaS access | [Entra ID workforce tenant](/stacks/azure/entra-id/) |
| Customer-facing CIAM | [Entra External ID](/stacks/azure/entra-external-id/) — replaces Azure AD B2C |
| Partner / B2B | Entra B2B (workforce tenant + cross-tenant access) |
| AI agent identity | Entra Agent ID (Ignite 2025+) |
| Dev/staging/prod separation | Same tenant + Conditional Access + RBAC; separate tenants only if regulatory requires |

**Anti-pattern: new Azure AD B2C tenant in 2026.**
**Anti-pattern: separate Entra tenants per environment "for isolation".**

### Authentication baseline

**Human identity baseline (workforce tenant)**:

- **Phishing-resistant MFA** (Windows Hello, FIDO2 keys, passkeys, certificate-based). TAP for onboarding only.
- **Conditional Access** requiring compliant device (Intune-managed) or hybrid-joined for sensitive apps.
- **Token protection** (binds tokens to devices) — GA.
- **Continuous Access Evaluation (CAE)** — real-time policy enforcement.
- **Sign-in / user risk policies** via Identity Protection.
- **Authentication strengths** — define acceptable MFA methods per app/policy.

**Privileged human identity (admins)**:

- **No permanent role assignments.** PIM-eligible only, MFA at activation + approval workflow + 4-8h max duration.
- **Quarterly access reviews** for all privileged roles.
- **Separate admin account from regular user account.**
- **Privileged Access Workstation (PAW)** for admin tasks.

**Service identity**:

- **Managed Identity** for Azure service-to-service.
- **Workload Identity Federation (OIDC)** for CI/CD service principals — no client secrets.
- **Dedicated identity per service** (no shared admin SP).

**AI agent identity (2026+)**:

- **Entra Agent ID** — agents authenticate with first-class identities, governed by Conditional Access + PIM + audit like humans.
- Per-agent permissions (least privilege on tools).
- Agent-on-behalf-of-user → explicit consent + OBO token exchange.

### Conditional Access — baseline policies

Every tenant:

1. **Block legacy authentication.**
2. **Require MFA for all users** (except break-glass).
3. **Require compliant device for admin portals.**
4. **Block sign-in from high-risk locations** per business need.
5. **Require phishing-resistant MFA for privileged role activation.**
6. **Block on user risk = High** (Identity Protection).
7. **Require Token Protection for sensitive apps.**

Advanced: authentication contexts (fine-grained gating), session controls, custom controls.

**Always have a break-glass account.** Global Administrator excluded from Conditional Access, FIDO2 key in a safe, sign-in alerting, tested quarterly.

### PIM design

**No permanent role assignments for privileged roles.** Activation:

- MFA at activation (or "phishing-resistant MFA" authentication strength).
- Justification (text + optional ticket reference).
- Approval for high-impact roles (GA, Privileged Role Admin).
- Max 4-8h duration; 24h only for specific scenarios.
- Activation alerts to security team.

**Access reviews** quarterly. **PIM for Azure RBAC** extends to subscription/RG/resource. **PIM for Groups** is cleaner than per-individual.

### Workload Identity Federation

**Every CI/CD pipeline that touches Azure must use WIF.** Pattern in [DevOps Engineer on Azure](/stacks/azure/devops-engineer/). 20 federated credentials per identity is the cap; use multiple UAMIs if needed.

**Anti-pattern: long-lived service principal client secrets.** WIF replaces all of them.

### Key Vault — RBAC mode

See [Key Vault](/stacks/azure/key-vault/). Critical points:

- **Azure RBAC for all new Key Vaults.** Migrate via Azure Policy initiative.
- **Soft-delete + purge protection ALWAYS ENABLED.**
- **Public network access disabled in production** — Private Endpoint.
- **Rotation policy** built-in.

### Managed HSM — when to use

For FIPS 140-2 Level 3 single-tenant HSM key custody:

- PCI-DSS card data encryption keys
- HIPAA / HITRUST highest-sensitivity PHI keys
- FedRAMP High
- CMK with audit-grade attestation

Don't use where standard Key Vault Premium (FIPS 140-2 Level 2, multi-tenant HSM-backed) suffices.

### Defender for Cloud plan selection

See [Defender for Cloud](/stacks/azure/defender-for-cloud/) for scoping strategy.

**Defender plans bill per-resource per-hour.** Scope via Azure Policy on management group / RG, not blanket-on.

### Microsoft Sentinel

See [Sentinel](/stacks/azure/sentinel/). Critical: **cost-tiered ingestion** (Analytics / Basic / Auxiliary / Archive); **alerts → playbooks** auto-respond; **out-of-box rules + custom hunting queries**; **separate workspaces per environment** for retention + RBAC.

### Microsoft Purview

See [Purview](/stacks/azure/microsoft-purview/). Standard implementation:

1. **Classification rules** (built-in + custom) for PII / PCI / PHI / IP.
2. **Sensitivity labels** with visual marking + encryption + DLP policy.
3. **DLP policies** block/warn/audit on labeled data movement.
4. **Lineage tracking**.

**Pattern: classify before encrypting. Pattern: integrate Purview with Defender CSPM Premium Sensitive Data Discovery. Pattern: Purview AI Hub for AI workloads.**

### Azure Policy — governance at scale

Effects: `Audit`, `Deny`, `Modify`, `DeployIfNotExists`, `Append`, `AuditIfNotExists`.

**Initiatives**: Microsoft maintains regulatory compliance initiatives for SOC 2, ISO 27001, NIST SP 800-53, PCI-DSS 4.0, HIPAA HITRUST, FedRAMP Moderate/High, IRS 1075, CIS Azure 2.x, Microsoft Cloud Security Benchmark (MCSB).

**Landing zone guardrails**: baseline initiative at MG-level. Typical assertions: tag requirements; Storage public access disabled; Key Vault RBAC mode + soft-delete + purge protection; TLS 1.2+; HTTPS-only; CMK disk encryption for prod; approved VM SKUs only; diagnostic settings configured; VNet Flow Logs enabled.

**Exemptions** for legitimate exceptions, with justification + expiration + approval.

### Private Link as default posture

**In production scope, every PaaS must use Private Link / Private Endpoints.** No public endpoints on Storage, KV, SQL, Cosmos, App Configuration, Service Bus, Event Grid, Container Registry, APIM Premium, AKS API server.

Enforce via Azure Policy `Deny` effects.

**Private DNS Zones**: wire `privatelink.blob.core.windows.net`, `privatelink.vaultcore.azure.net`, etc., centrally in the connectivity hub.

Exception: external partner APIs and customer-facing endpoints stay public, fronted by APIM / Front Door / App Gateway with WAF.

### Azure Firewall + WAF

**Azure Firewall Premium** — TLS inspection, IDPS, URL filtering, threat intelligence. Integrates with Virtual WAN as Secure Virtual Hub. Hierarchical Firewall Policy (parent at MG-level + child per landing zone).

**WAF**: [Front Door (Premium)](/stacks/azure/front-door/) for global + bot manager; [Application Gateway WAF v2](/stacks/azure/application-gateway/) for regional in-VNet. Detection mode first, then Prevention.

### Network segmentation

- NSGs (stateful packet filter on subnet/NIC).
- ASGs (group VMs for rule targeting).
- Service Endpoints (legacy) — prefer Private Link.
- Service Tags (Microsoft-managed CIDR groups).
- Azure Firewall at hub for north-south.
- WAF for L7.

**VNet Flow Logs** (replaces NSG Flow Logs, mandatory mid-2025 migration) — capture flow telemetry for forensics + Traffic Analytics.

### Confidential Computing — TEE-attested workloads

**DCsv3 / DCsv5 / ECsv5** (Intel SGX), **DCadsv5 / ECadsv5** (AMD SEV-SNP), **Confidential Containers on AKS**, **Azure Attestation**.

Use cases: PHI / financial data in cloud where customer wants attestation; multi-party computation; confidential AI inference.

**Anti-pattern: Confidential Computing where standard encryption + Managed Identity suffice.** TEE has cost + complexity overhead.

### Entra Agent ID — AI agent identity (Ignite 2025+)

First-class Entra identity for AI agents:

- Conditional Access policies apply.
- PIM-eligible for sensitive ops.
- Audit log attributes actions to the agent identity.
- Per-agent permission scoping.

**Pattern**: agent on behalf of user → OBO token flow → both identities logged. Agent as service → agent identity only, tightly scoped.

**Anti-pattern: agent running with developer's user credentials in production.**

### Compliance posture

Azure has eligibility for SOC 1/2/3, ISO 27001/27017/27018/27701, PCI-DSS 4.0, HIPAA HITRUST, FedRAMP Moderate/High, IRS 1075, GDPR, CCPA, NIST SP 800-53/171, CMMC, IRAP, ENS High, C5, MTCS Tier 3, and others.

**Per-service eligibility is published in [Microsoft Trust Center service compliance page](https://learn.microsoft.com/compliance/azure/azure-services). Reference; don't assume.**

Standard workflow:

1. **Scope** services + regions + data.
2. **Map** controls (HIPAA technical safeguards, etc.) via MCSB + regulatory initiatives.
3. **Implement** controls (Defender, Sentinel, Purview classification, audit retention).
4. **Monitor** Azure Policy compliance + Defender Secure Score + Sentinel.
5. **Evidence** — export Activity Log, sign-in log, Defender alerts, Policy compliance to immutable Storage.
6. **Audit** — read-only RBAC + Azure Monitor exports.

**Compliance Manager** (in Purview) — assessment tool with control mapping + evidence collection.

## 2025-2026 platform-reset items relevant to this role

- **Azure AD → Entra ID** rename (July 2023).
- **Azure AD B2C → Entra External ID** (2024).
- **Entra Agent ID** (Ignite 2025).
- **CAE expanding**.
- **Token Protection GA**.
- **Authentication strengths GA**.
- **Workload Identity Federation** replaces SP secrets; AKS Pod Identity retired.
- **Key Vault RBAC mode** recommended.
- **VNet Flow Logs** mandatory migration from NSG Flow Logs.
- **Defender for Cloud unified SecOps portal** with Defender XDR (2024-25).
- **Defender for APIs / Defender for AI Services**.
- **API Security Posture (CSPM Premium)** GA.
- **Sentinel Auxiliary / Basic Logs tiers** GA 2024.
- **Purview consolidation + AI Hub**.
- **Confidential AI on Azure** — Confidential Containers + attestation.
- **AKS Pod Identity retired** — Workload Identity only.

## Patterns the role applies

### Pattern: Zero Trust baseline for every Azure tenant

1. MFA on every user (with break-glass exception).
2. Phishing-resistant MFA for admins.
3. Block legacy auth.
4. Compliant device for admin portals.
5. All privileged roles PIM-eligible.
6. Managed Identity for every service-to-service.
7. WIF for every CI/CD service principal.
8. Private Link for every PaaS in production.
9. Key Vault RBAC + soft-delete + purge protection.
10. Defender for Cloud CSPM Foundational minimum.
11. Sentinel with Entra + Activity Log + Defender XDR connectors.
12. VNet Flow Logs.
13. Azure Policy baseline initiative at MG-level.

### Pattern: Least-privilege RBAC via custom roles + scope

Built-in roles often over-scoped. For sensitive resources, custom role + scoped assignment.

### Pattern: Deny-list first, audit-list never first

Audit-only creates "compliant on paper" environments where non-compliance is invisible until incident. Deny + targeted exemptions is the discipline.

### Pattern: Service identity per workload

One Managed Identity per logical workload. Don't share across "all the things this app touches."

### Pattern: Forensics-grade audit log retention

Activity Log + Entra sign-in/audit + Defender alerts → Diagnostic Settings to Storage with:

- Immutability policy (1-7 years).
- Separate subscription (compromised prod doesn't expose audit log).
- Limited write access (Azure Diagnostic Settings only; no human write).
- Read via PIM-eligible auditor role.

### Pattern: Defender + Sentinel unified workflow

Defender detects → alert flows to Sentinel via connector → correlation with other sources → incident → playbook → response.

### Anti-pattern: "Owner" assignments at subscription scope

Owner includes RBAC. PIM-eligible only, never permanent. Default to Contributor + specific data-plane roles.

### Anti-pattern: SP client secrets

WIF.

### Anti-pattern: Storage with public access

Private Endpoint.

### Anti-pattern: SQL Auth in production

Entra auth.

### Anti-pattern: Key Vault legacy access policies

RBAC.

### Anti-pattern: TLS 1.0 / 1.1 anywhere

1.2+ minimum.

### Anti-pattern: Diagnostic Settings not configured

DeployIfNotExists policy enforces.

### Anti-pattern: Sentinel alerts without playbook

Wire playbooks for alerts that matter.

### Anti-pattern: Compliance-as-snapshot

Continuous compliance via Policy + Defender + Sentinel.

## Integration with always-on protocols

### TDD on security

- **Policy-as-code**: Azure Policy initiatives in Bicep / Terraform; `what-if` validates before apply.
- **Security tests in CI**: tfsec / checkov / PSRule for Azure on every PR.
- **Smoke tests post-deploy**: synthetic auth (signed-in user with various CA scenarios) verifies policies.

### Verification

- Defender for Cloud Secure Score trend.
- Sentinel ingestion health.
- Policy compliance percentage.
- Access review completion rate.
- PIM activation rate (low for break-glass; controlled for admins).
- Key rotation success rate.
- WIF adoption rate (target: 100%).

### Review

Push back on the anti-patterns above.

### Debugging

- **Entra sign-in logs** + **audit logs** + **provisioning logs** via Log Analytics.
- **Defender for Cloud alerts** with investigation graph.
- **Sentinel incident investigation** — entity graph view.
- **Activity Log** for control plane.
- **Resource diagnostic logs** for data plane.

Workflow: signal → entity pivot → timeline → actor/asset/vector → contain → eradicate → recover → post-incident lessons + hardening.

## Cross-references

- [System Architect on Azure](/stacks/azure/system-architect/) — guardrails in landing zone
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — WIF + secret rotation
- [Backend Architect on Azure](/stacks/azure/backend-architect/) — Managed Identity + Key Vault
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/) — observability overlap
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — AI security + Entra Agent ID
- [Healthcare Architect on Azure](/stacks/azure/healthcare-architect/) — HIPAA-eligible inventory
- [Azure Stack index](/stacks/azure/)
- [Microsoft Trust Center](https://www.microsoft.com/trust-center)
- [Conditional Access](https://learn.microsoft.com/entra/identity/conditional-access/overview)
- [PIM](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/)
- [Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/)
- [Sentinel](https://learn.microsoft.com/azure/sentinel/)
- [Purview](https://learn.microsoft.com/purview/)
