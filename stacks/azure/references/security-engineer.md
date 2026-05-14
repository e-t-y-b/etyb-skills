---
role: security-engineer
stack: azure
last_verified_on: "2026-05-14"
---

# Azure — security-engineer overlay

You're the security engineer on Azure. Identity, network, key custody, secrets, governance, threat detection, response, compliance, data classification. This overlay is heavier than most because Azure's security surface — **Entra ID + External ID + Conditional Access + PIM + Defender for Cloud + Sentinel + Purview + Key Vault + Managed HSM + Azure Policy + Confidential Computing** — is the surface where most of the platform's value is delivered, and where most things go wrong.

You don't write the application code (backend-architect) or the IaC (devops-engineer) — you set the guardrails, run the threat detection, respond to incidents, prove compliance, and push back when the architecture compromises security.

## What this role does on Azure

- Designs and operates **Microsoft Entra ID** tenants (workforce + External ID + B2B + Agent ID).
- Designs **Conditional Access** policies, **MFA enforcement**, **PIM** workflows.
- Implements **Workload Identity Federation** to eliminate service principal client secrets in CI/CD.
- Designs **Managed Identity** posture across the platform (no plaintext credentials).
- Operates **Azure Key Vault** + **Managed HSM** with RBAC + soft-delete + purge protection + rotation policies.
- Selects and scopes **Microsoft Defender for Cloud** plans (Servers, Containers, Storage, Databases, App Service, Key Vault, AI, APIs).
- Operates **Microsoft Sentinel** SIEM/SOAR — data connectors, analytic rules, KQL hunting queries, automation playbooks.
- Operates **Microsoft Purview** — data classification, DLP, insider risk, AI hub.
- Authors **Azure Policy** initiatives + **Landing Zone guardrails**.
- Designs **Private Link as default posture** + network segmentation + WAF + Azure Firewall.
- Owns **secret rotation**, **certificate lifecycle**, **PKI** strategy.
- Designs **Entra Agent ID** governance for AI agents (Ignite 2025+).
- Designs **Confidential Computing** posture for regulated workloads.
- Drives **compliance evidence collection** (SOC 2 / ISO 27001 / HIPAA / PCI / FedRAMP / IRS 1075 / GDPR).
- Runs **threat models** + **pen test prep** + **incident response** drills.

## Decision frameworks

### Identity — tenant strategy

| Use case | Pick |
|----------|------|
| Employee SSO / SaaS access | **Entra ID workforce tenant** (one per company) |
| Customer-facing app (CIAM) | **Entra External ID** — replaces Azure AD B2C for new builds |
| Partner / B2B collaboration | **Entra B2B** (workforce tenant + cross-tenant access settings) |
| AI agent identity | **Entra Agent ID** (Ignite 2025+) — first-class identity for agents |
| Dev/staging/prod separation | Same tenant + Conditional Access scoped to apps + RBAC; separate tenants only if regulatory requires |

**Anti-pattern: new Azure AD B2C tenant in 2026.** B2C is in legacy support. New customer-facing apps go on Entra External ID. Existing B2C tenants continue to work but new builds shouldn't choose B2C.

**Anti-pattern: separate Entra tenants per environment "for isolation".** Cross-tenant operations add friction (cross-tenant access settings, guest invites, separate Conditional Access). Use one workforce tenant with app-scoped RBAC unless regulatory requires separation.

Cite: [Entra External ID](https://learn.microsoft.com/entra/external-id/), [Entra Agent ID](https://learn.microsoft.com/entra/identity/agent-id/).

### Authentication — what every human and service gets

**Human identity baseline (workforce tenant)**:

- Phishing-resistant MFA (Windows Hello, FIDO2 keys, passkeys, certificate-based) — TAP (Temporary Access Pass) for onboarding only.
- Conditional Access requiring compliant device (Intune-managed) or hybrid-joined for sensitive apps.
- Token protection (binds tokens to specific devices) — GA.
- Continuous Access Evaluation (CAE) — real-time policy enforcement (revoke session immediately on risk signal).
- Sign-in risk + user risk policies via Identity Protection.
- Authentication strengths — define which MFA methods are acceptable per app/policy.

**Privileged human identity (admins)**:

- **No permanent role assignments**. PIM-eligible only, with MFA at activation + approval workflow + max 4-8 hour activation duration.
- Access reviews quarterly for all privileged roles.
- Separate admin account from regular user account (don't elevate your daily-driver account).
- Privileged Access Workstation (PAW) — dedicated hardened device for admin tasks.

**Service identity (workload)**:

- **Managed Identity** for service-to-service auth on Azure resources.
- **Workload Identity Federation (OIDC)** for CI/CD service principals — no client secrets.
- **Federated identity** for cross-tenant / external workloads.
- Each service has a dedicated identity (no "shared admin SP" for everything).

**AI agent identity** (2026+):

- **Entra Agent ID** — agents authenticate with first-class identities, governed by Conditional Access + PIM + audit log just like humans.
- Per-agent permissions (least privilege on the tools the agent can call).
- Agent-on-behalf-of-user flows require explicit user consent + OBO token exchange.

### Conditional Access — policy design

Baseline policies (every tenant):

1. **Block legacy authentication** — POP, IMAP, SMTP basic auth, MAPI/EWS, etc. Legacy protocols bypass MFA.
2. **Require MFA for all users** — except break-glass accounts (excluded, with monitoring on their sign-in).
3. **Require compliant device for admin portals** — Azure portal, Entra admin center, M365 admin center.
4. **Block sign-in from high-risk locations** — defined per business need.
5. **Require phishing-resistant MFA for privileged role activation** — admin roles use FIDO2 / passkey / cert-based.
6. **Block on user risk = High** (Identity Protection) — require password reset.
7. **Require Token Protection for sensitive apps** — binds token to device, prevents token replay.

Advanced:

- **Authentication contexts** — fine-grained gating (e.g., require step-up MFA before accessing a specific SharePoint site).
- **Session controls** — force sign-in frequency, persistent browser session control, app-enforced restrictions.
- **Custom controls** — integrate third-party MFA / verification providers.

**Always have a break-glass account.** A Global Administrator account excluded from Conditional Access, with strong passphrase + FIDO2 key in a safe + sign-in monitoring on activation. Tested quarterly. **You will lock yourself out otherwise.**

Cite: [Conditional Access overview](https://learn.microsoft.com/entra/identity/conditional-access/overview), [Token Protection](https://learn.microsoft.com/entra/identity/conditional-access/concept-token-protection).

### PIM (Privileged Identity Management) — design

**No permanent role assignments for privileged roles.** Every Global Admin, Application Administrator, Conditional Access Administrator, Privileged Role Administrator, Security Administrator — PIM-eligible.

PIM activation requirements:

- **MFA at activation** (or stronger — authentication strength = "phishing-resistant MFA").
- **Justification** (text reason, optionally with ticket reference).
- **Approval** for high-impact roles (Global Admin, Privileged Role Admin).
- **Max duration**: 4-8 hours typical; 24h only for specific scenarios.
- **Activation alerts** — notification to security team on any high-tier activation.

**Access reviews**: quarterly recertification of all role assignments. Reviewers attest "yes still needed" or remove. PIM automates the workflow.

**PIM for Azure RBAC**: same model extends to subscription/resource-group/resource RBAC. "Just-in-time owner on production subscription" with approval.

**PIM for Groups**: assign roles via groups; PIM the group membership. Cleaner than assigning roles to individuals.

Cite: [PIM overview](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/).

### Workload Identity Federation — eliminating CI/CD secrets

**Every CI/CD pipeline that touches Azure must use WIF.** No `client_secret` in workflow files, no SP credentials in GitHub Secrets / Azure DevOps variables.

Pattern (GitHub Actions):

1. Create a User-Assigned Managed Identity (UAMI) in Azure.
2. Add a federated identity credential to the UAMI, trusting GitHub's OIDC issuer for a specific `repo:org/repo:environment:prod` subject.
3. Grant RBAC on target resources to the UAMI.
4. Workflow uses `azure/login@v2` with `client-id`, `tenant-id`, `subscription-id` (not secrets).

```yaml
permissions:
  id-token: write   # required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

WIF works for: GitHub Actions, Azure DevOps service connections, AKS pods (Workload Identity), AWS EKS, GKE, on-prem Kubernetes, any OIDC provider.

**Cap: 20 federated identity credentials per app/managed identity.** Use multiple UAMIs if needed.

**Anti-pattern: long-lived service principal client secrets.** Replace all of them with WIF. There is no scenario where a 90-day client secret rotation policy is better than secretless federation.

Cite: [Workload Identity Federation docs](https://learn.microsoft.com/entra/workload-id/workload-identity-federation).

### Key Vault — RBAC mode, not access policies

**Use Azure RBAC for all new Key Vaults.** Migrate existing vaults via the Azure Policy initiative "Key vaults should use RBAC permission model".

Legacy access policies have known gaps:

- No scoped permissions (anyone with "List secrets" can list every secret).
- Awkward audit trail.
- Doesn't integrate with PIM cleanly.
- Can't apply ABAC conditions.

RBAC built-in roles:

| Role | Use |
|------|-----|
| Key Vault Administrator | Full control (rare; PIM-eligible only) |
| Key Vault Secrets Officer | Manage secret CRUD |
| Key Vault Secrets User | Read secret values |
| Key Vault Reader | Metadata read only |
| Key Vault Certificates Officer | Manage cert CRUD |
| Key Vault Crypto Officer | Manage keys |
| Key Vault Crypto User | Use keys for crypto ops |
| Key Vault Crypto Service Encryption User | Service encryption use case |

**Soft-delete + purge protection: ALWAYS ENABLED.** Without them, a malicious or accidental delete is unrecoverable. Soft-delete = retention (7-90 days). Purge protection = no permanent delete even with privileged access during retention period.

```bicep
properties: {
  enableRbacAuthorization: true
  enableSoftDelete: true
  softDeleteRetentionInDays: 90
  enablePurgeProtection: true
  publicNetworkAccess: 'Disabled'   // require Private Link in production
}
```

**Rotation policy** (built-in):

```bicep
resource keyRotationPolicy 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: kv
  name: 'my-encryption-key'
  properties: {
    rotationPolicy: {
      lifetimeActions: [
        {
          trigger: { timeAfterCreate: 'P90D' }
          action: { type: 'Rotate' }
        }
      ]
    }
  }
}
```

**Anti-pattern: storing secrets in Key Vault but not enabling soft-delete/purge protection.** It's the default in new vaults via Azure Policy if you apply the right initiative; verify.

**Anti-pattern: Key Vault with public network access enabled in production.** Private Endpoint, period.

Cite: [Key Vault RBAC](https://learn.microsoft.com/azure/key-vault/general/rbac-guide), [Key rotation](https://learn.microsoft.com/azure/key-vault/keys/how-to-configure-key-rotation).

### Managed HSM — when to use

For regulated workloads requiring **FIPS 140-2 Level 3** single-tenant HSM key custody:

- PCI-DSS card data encryption keys
- HIPAA / HITRUST PHI encryption keys
- FedRAMP High keys
- Customer-Managed Keys (CMK) for storage / SQL / Cosmos with audit-grade attestation

Managed HSM costs more than standard Key Vault. Don't use it where standard Key Vault Premium (FIPS 140-2 Level 2, multi-tenant HSM-backed keys) suffices.

Cite: [Managed HSM overview](https://learn.microsoft.com/azure/key-vault/managed-hsm/overview).

### Defender for Cloud — plan selection

**Defender plans bill per-resource per-hour.** Blanket-on across a large subscription is a budget event. Scope carefully.

Plans (as of 2026-Q2):

| Plan | Coverage |
|------|----------|
| **Defender CSPM (Foundational)** | Free; secure score, basic recommendations |
| **Defender CSPM (Premium)** | $$$ per workload; attack path analysis, regulatory compliance, sensitive data discovery |
| **Defender for Servers Plan 1** | VM-level threat detection, MDE integration (per server-hour) |
| **Defender for Servers Plan 2** | Plan 1 + vulnerability assessment + adaptive app controls + file integrity monitoring |
| **Defender for Containers** | AKS runtime + image scanning + admission control |
| **Defender for Storage** | Malware scan on upload + sensitive data discovery + threat alerts |
| **Defender for Databases (SQL)** | Vulnerability assessment + threat detection |
| **Defender for Open-Source Relational Databases** | PostgreSQL, MySQL threat detection |
| **Defender for Cosmos DB** | Threat detection on Cosmos DB |
| **Defender for App Service** | Web app threat detection |
| **Defender for Key Vault** | Anomalous access detection |
| **Defender for Resource Manager** | Control plane threat detection |
| **Defender for DNS** | DNS-based threat detection |
| **Defender for APIs** | API Security Posture (CSPM-Premium); runtime API protection (separate plan) |
| **Defender for AI Services** | Azure OpenAI / Foundry threat detection (prompt injection, abuse) |
| **Defender for DevOps** | GitHub / Azure DevOps repo scanning |

**Scoping strategy**:

- **CSPM Foundational on the whole tenant** — free, baseline.
- **CSPM Premium on production scope only** — management group / RG-level enable.
- **Defender for Servers Plan 2 on production VMs** — Azure Policy scopes to RGs with `environment=prod`.
- **Defender for Containers on AKS production clusters** — same scoping.
- **Defender for Storage on storage accounts with customer data** — not on every storage account.
- **Defender for Databases on databases with PII / regulated data**.
- **Defender for Key Vault on every Key Vault** — cost is low, value is high.
- **Defender for Resource Manager on every subscription** — control-plane attacks affect everything.
- **Defender for AI Services on Azure OpenAI / Foundry endpoints**.

**Anti-pattern: blanket-on every plan**. Use Azure Policy to assign plans by management group / RG scope.

**Anti-pattern: ignoring Defender recommendations**. The Secure Score is your KPI. Track it.

**Sensitive data scanning** (CSPM Premium): now covers Azure file shares (GA), blob containers, databases — discovers PII without sampling.

**Attack path analysis**: visualizes chains of vulnerabilities → likely attacker path. Now includes compromised Entra OAuth apps.

**AI security posture** (CSPM Premium): now extends to GCP Vertex AI workloads — multicloud AI discovery + attack path analysis.

Cite: [Defender for Cloud overview](https://learn.microsoft.com/azure/defender-for-cloud/), [Defender for Cloud plans](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction).

### Microsoft Sentinel — SIEM/SOAR

Sentinel is Microsoft's cloud-native SIEM. As of 2024-25, the **Unified SecOps portal** merges Sentinel + Defender XDR experience.

**Architecture**:

```
Data sources → Data Connectors → Log Analytics Workspace (Sentinel-enabled)
                                              ↓
                                  Analytics Rules (KQL)
                                              ↓
                                  Incidents (correlated alerts)
                                              ↓
                                  SOAR Playbooks (Logic Apps)
```

**Data connectors** (typical):

- Azure Activity Log
- Entra ID sign-in / audit logs
- Defender XDR alerts
- Azure resource diagnostic settings
- Office 365 / SharePoint / Exchange
- Cloud App Security
- Third-party: Palo Alto, Cisco, Okta, AWS CloudTrail, GCP, Salesforce, etc.

**Analytic rule types**:

- **Microsoft security rules** — Microsoft-authored, alert-based
- **Fusion rules** — ML-based correlation across sources
- **ML behavioral analytics** — UEBA-style anomaly detection
- **Scheduled queries** — your custom KQL on a schedule
- **NRT (near real-time)** — KQL evaluated every 1 min
- **Anomaly rules** — built-in anomaly detection on specific data types

**Hunting queries**: pre-built KQL queries for threat hunting. Run on-demand.

**Workbooks**: dashboards built on KQL queries — pre-built for common scenarios.

**Playbooks (SOAR)**: Logic Apps triggered by incidents. Auto-respond (isolate VM, disable user, post to Teams).

**Data retention strategy**:

- Hot data in Sentinel-enabled workspace (last 30-90 days).
- **Auxiliary Logs** (2024 GA) — cheaper ingestion tier for low-query logs (NetFlow, firewall, proxy logs).
- **Basic Logs** — even cheaper, limited KQL.
- Archive to Storage for long-term retention (compliance) via Data Export rules.

**Anti-pattern: ingesting every log into Sentinel hot tier**. Cost explodes. Use Basic/Auxiliary Logs for high-volume low-query logs; archive to Storage for compliance.

**Anti-pattern: relying only on out-of-box rules**. Tune to your environment. Build org-specific hunting queries based on your threat model.

Cite: [Sentinel docs](https://learn.microsoft.com/azure/sentinel/), [Auxiliary Logs](https://learn.microsoft.com/azure/azure-monitor/logs/auxiliary-logs).

### Microsoft Purview — data governance + DLP

Purview unified suite (2024+ consolidation):

- **Data Map** — automated discovery + classification across Azure + AWS + on-prem + SaaS
- **Data Catalog** — searchable inventory with business glossary + lineage
- **Information Protection** — sensitivity labels (Public / Internal / Confidential / Highly Confidential)
- **Data Loss Prevention (DLP)** — policy enforcement on labeled data movement
- **Insider Risk Management** — user behavior analytics for data exfiltration
- **Communication Compliance** — policy enforcement on email/Teams
- **eDiscovery** — legal hold + search across M365 + Azure data
- **AI Hub** (2025+) — visibility into AI prompts, risky AI usage, sensitive data flowing to AI

Standard implementation:

1. **Classification rules** — built-in + custom (regex / dictionary / ML model). Classify PII / PCI / PHI / IP.
2. **Sensitivity labels** — visual marking + encryption + DLP policy attachment.
3. **DLP policies** — block / warn / audit on movement of labeled data.
4. **Lineage tracking** — see where sensitive data originated + flowed.

**Pattern: classify before encrypting.** Encrypting unclassified data is fine, but you can't enforce DLP without classification.

**Pattern: integrate Purview with Defender for Cloud Sensitive Data Discovery.** Both surfaces show classified data findings.

**Pattern: Purview AI Hub for AI workloads.** Monitor prompts to Azure OpenAI / Foundry / Copilot for sensitive data leakage.

Cite: [Microsoft Purview docs](https://learn.microsoft.com/purview/), [Purview AI Hub](https://learn.microsoft.com/purview/ai-microsoft-purview).

### Azure Policy — governance at scale

Policy effects:

| Effect | Use |
|--------|-----|
| **Audit** | Report compliance; don't block |
| **Deny** | Block non-compliant resource creation |
| **Modify** | Auto-modify resource on create (e.g., add tag) |
| **DeployIfNotExists** | Auto-deploy missing config (e.g., enable diagnostic settings on new resources) |
| **Append** | Append a property on create |
| **AuditIfNotExists** | Audit if a related resource doesn't exist (e.g., NSG on VNet) |

**Initiatives**: groups of policies. Microsoft maintains regulatory compliance initiatives for SOC 2, ISO 27001, NIST SP 800-53, PCI-DSS 4.0, HIPAA HITRUST, FedRAMP Moderate / High, IRS 1075, CIS Azure 2.x, Microsoft Cloud Security Benchmark (MCSB).

**Landing zone guardrails**: a baseline initiative applied at the management-group level — typical assertions:

- All resources require `environment`, `costCenter`, `dataClassification` tags
- Storage accounts must disable public network access
- Key Vaults must use RBAC mode + soft-delete + purge protection
- Public IPs must have Basic SKU disabled
- Network security groups must have flow logs enabled (VNet Flow Logs)
- Diagnostic settings must be configured for security-relevant resources
- TLS 1.2+ required across services
- HTTPS-only required for App Service / Functions / Storage
- Disk encryption with CMK for production VMs
- Approved VM SKUs only

**Exemptions** for legitimate exceptions, with justification + expiration + approval. Track via Policy compliance dashboard.

Cite: [Azure Policy docs](https://learn.microsoft.com/azure/governance/policy/), [Regulatory compliance initiatives](https://learn.microsoft.com/azure/governance/policy/samples/).

### Private Link as default posture

**In production scope, every PaaS service must use Private Link / Private Endpoints.** No public endpoints on storage, KV, SQL, Cosmos, App Configuration, Service Bus, Event Grid, Container Registry, APIM Premium, AKS API server.

Enforce via Azure Policy:

- "Storage accounts should disable public network access" (Deny)
- "Azure Key Vault should disable public network access" (Deny)
- "Azure SQL servers should have public network access disabled" (Deny)
- ...

**Private DNS Zones**: auto-resolution for private endpoints. Wire `privatelink.blob.core.windows.net`, `privatelink.vaultcore.azure.net`, etc., centrally in the connectivity hub.

**Cost**: Private Endpoints have per-endpoint hourly + data transfer cost. Negligible vs the security value.

**Exception**: external partner APIs, customer-facing endpoints — these stay public, fronted by APIM / Front Door / App Gateway with WAF.

### Azure Firewall — when and how

Premium SKU adds:

- TLS inspection (decrypt + inspect + re-encrypt SSL traffic; requires intermediate CA cert in customer Key Vault)
- IDPS (Intrusion Detection and Prevention) — signature-based + heuristic
- URL filtering + web categories
- Threat intelligence feed (Microsoft + custom)

**Integrates with Virtual WAN** as Secure Virtual Hub.

**Firewall Policy** (hierarchical): parent policy at MG-level + child policies per landing zone — rule inheritance + override.

**Anti-pattern: third-party NVA when Azure Firewall fits.** Azure Firewall is fully managed, scales automatically, integrates with Sentinel. Third-party NVAs are appropriate for orgs with existing investment / specific feature need; not as default.

### WAF — Front Door vs Application Gateway

| | Front Door (Premium) WAF | App Gateway WAF v2 |
|---|--------------------------|---------------------|
| Scope | Global edge | Regional |
| Rule set | Default Rule Set 2.x + Bot Manager | CRS 3.2 + custom |
| Bot manager | Yes (Premium-only) | No |
| Threat intelligence | Microsoft TI rules | Manual rules |
| Best when | Global app, want bot protection, want CDN | Regional app, in-VNet inspection |

**Always use WAF for internet-facing apps.** Detection mode first (audit), then Prevention mode after tuning.

**Custom rules**: geo-filtering, rate limiting, IP allow/deny, request size limits.

### Network segmentation

- **NSGs (Network Security Groups)** — stateful packet filter on subnet / NIC; default rules + custom.
- **Application Security Groups (ASGs)** — group VMs / apps for rule targeting (vs IP addresses).
- **Service Endpoints** (legacy) — service-level access from subnet; **prefer Private Link** for new builds.
- **Service Tags** — Microsoft-managed CIDR groups (Storage, AzureCloud, Internet, etc.).
- **Azure Firewall** at hub for north-south.
- **Azure Web Application Firewall** for L7 inspection.

**VNet Flow Logs** (replaces NSG Flow Logs, mandatory migration by mid-2025) — capture flow telemetry for forensics + Traffic Analytics. Configure at VNet level, not per-NSG.

Cite: [VNet Flow Logs](https://learn.microsoft.com/azure/network-watcher/vnet-flow-logs-overview).

### Confidential Computing — TEE-attested workloads

For workloads where the operator (Microsoft) should not have access to data in use:

- **DCsv3 / DCsv5 / ECsv5 VMs** — Intel SGX TEE
- **DCadsv5 / ECadsv5** — AMD SEV-SNP
- **Confidential Containers on AKS** — encrypted containers with attestation
- **Azure Attestation service** — verify TEE state remotely

Use cases:

- PHI / financial data processed in cloud where customer wants attestation that even Microsoft can't see it
- Multi-party computation (joint analytics across parties without sharing raw data)
- Confidential AI inference (model + data isolated from host OS)

**Anti-pattern: Confidential Computing where standard managed disks + encryption-at-rest + Managed Identity suffice.** TEE has cost + complexity overhead. Use only when the threat model demands it.

Cite: [Azure Confidential Computing](https://learn.microsoft.com/azure/confidential-computing/).

### Entra Agent ID — AI agent identity

Ignite 2025 announcement, evolving through 2026. First-class Entra identity for AI agents:

- Agents get unique IDs in the tenant directory.
- Conditional Access policies apply: "this agent can only operate from these tools, during these hours, against these resources."
- PIM-eligible "agent role activation" for sensitive operations.
- Audit log entries attribute actions to the agent identity (not the human who invoked it, unless OBO).
- Access reviews recertify agent permissions.

**Pattern**: agent acts on behalf of user → OBO token flow → agent identity + user identity both logged.

**Pattern**: agent acts as service → agent identity only → must be scoped tightly.

**Anti-pattern: agent running with the developer's user credentials**. Audit log attributes the agent's actions to the developer's identity, which is wrong. Use Entra Agent ID.

Cite: [Entra Agent ID](https://learn.microsoft.com/entra/identity/agent-id/).

### Compliance posture

Azure has eligibility for: SOC 1 / 2 / 3, ISO 27001 / 27017 / 27018 / 27701, PCI-DSS 4.0, HIPAA HITRUST, FedRAMP Moderate / High, IRS 1075, GDPR, CCPA, NIST SP 800-53 / 171, CMMC, IRAP, ENS High (Spain), C5 (Germany), MTCS Tier 3 (Singapore), and many more.

**Per-service eligibility is published in the [Microsoft Trust Center service compliance page](https://learn.microsoft.com/compliance/azure/azure-services).** Reference this — don't assume.

Standard compliance workflow:

1. **Scope** — which services + regions + data are in scope?
2. **Map** — which controls apply (e.g., HIPAA technical safeguards)? Use Microsoft Cloud Security Benchmark + regulatory compliance initiative in Azure Policy.
3. **Implement** — enable controls (Defender, Sentinel, Purview classification, audit log retention, etc.).
4. **Monitor** — Azure Policy compliance + Defender Secure Score + Sentinel.
5. **Evidence** — export Activity Log, sign-in log, Defender alerts, Policy compliance to long-term storage with immutability (compliance lock).
6. **Audit** — auditor accesses evidence via dedicated read-only RBAC + Azure Monitor exports.

**Compliance Manager** (in Microsoft Purview) — assessment tool with control mapping + evidence collection workflow.

Cite: [Microsoft Trust Center](https://www.microsoft.com/trust-center), [Compliance Manager](https://learn.microsoft.com/purview/compliance-manager).

## 2025-2026 platform reset items relevant to this role

- **Azure AD → Entra ID rename** (July 2023). All docs, portals, SDK branding "Entra".
- **Azure AD B2C → Entra External ID** (2024). B2C in legacy support; new builds = External ID.
- **Entra Agent ID** (Ignite 2025) — first-class identity for AI agents.
- **Continuous Access Evaluation (CAE)** expanding — real-time policy enforcement.
- **Token Protection GA** — bind tokens to devices.
- **Authentication strengths GA** — phishing-resistant MFA enforcement at policy level.
- **Workload Identity Federation** — replaces SP secrets; AKS Pod Identity retired.
- **Key Vault RBAC mode** is the recommended; Azure Policy enforces.
- **VNet Flow Logs** mandatory migration from NSG Flow Logs (mid-2025).
- **Defender for Cloud unified SecOps portal** with Defender XDR (2024-25).
- **Defender for APIs / Defender for AI Services** plan additions.
- **API Security Posture (Defender CSPM Premium)** GA.
- **Microsoft Sentinel auxiliary logs / basic logs tiers** GA 2024 — cost-tiered ingestion.
- **Microsoft Purview consolidation** + **AI Hub** for AI-aware DLP.
- **Confidential AI on Azure** — confidential containers + attestation for regulated AI inference.
- **AKS Pod Identity retirement** — Workload Identity only.

## Patterns and anti-patterns

### Pattern: Zero Trust baseline for every Azure tenant

1. **MFA on every user** (with break-glass exception).
2. **Phishing-resistant MFA for admins** (FIDO2 / passkey / cert-based).
3. **Block legacy authentication**.
4. **Compliant device for admin portals**.
5. **All privileged roles PIM-eligible** (no permanent).
6. **Managed Identity for every service-to-service auth**.
7. **WIF for every CI/CD service principal**.
8. **Private Link for every PaaS in production**.
9. **Key Vault RBAC + soft-delete + purge protection**.
10. **Defender for Cloud CSPM Foundational** at minimum.
11. **Sentinel** with Entra + Activity Log + Defender XDR connectors.
12. **VNet Flow Logs** for all VNets.
13. **Azure Policy** baseline initiative applied at MG-level.

This is the "good Zero Trust starting posture." Anything below is incident waiting to happen.

### Pattern: Least-privilege RBAC via custom roles + scope

Built-in roles are convenient but often over-scoped. For sensitive resources, custom role + scoped assignment:

```json
{
  "roleName": "App Deploy Operator",
  "description": "Deploy to specific app",
  "actions": [
    "Microsoft.Web/sites/slots/write",
    "Microsoft.Web/sites/slots/swap/action",
    "Microsoft.Web/sites/read"
  ],
  "notActions": [],
  "dataActions": [],
  "notDataActions": [],
  "assignableScopes": ["/subscriptions/.../resourceGroups/rg-app/providers/Microsoft.Web/sites/my-app"]
}
```

### Pattern: Deny-list (then allow-list) before audit-list

Azure Policy effects work best when you Deny first, then add Audit for transitional cases. Audit-only policies create "compliant on paper" environments where non-compliance is invisible until incident.

### Pattern: Service identity per workload

One Managed Identity per logical workload (or smaller). Don't share an identity across "all the things this app touches" — when scope creeps, the blast radius grows.

### Pattern: Forensics-grade audit log retention

Activity Log + Entra sign-in/audit logs + Defender alerts → exported via Diagnostic Settings to Storage Account with:

- Immutability policy (time-based lock, 1-7 years per regulatory requirement)
- Storage account in separate subscription (so a compromised production sub doesn't expose audit log)
- Limited write access (only Azure Diagnostic Settings; no human RBAC for write)
- Read access via PIM-eligible auditor role

### Pattern: Defender for Cloud + Sentinel as a unified workflow

Defender for Cloud detects → alerts flow to Sentinel via the connector → Sentinel correlates with other sources → incident → playbook → response.

### Anti-pattern: "Owner" assignments at subscription scope

Owner = everything including RBAC. Should be PIM-eligible only, never permanent. Default to Contributor + specific data-plane roles.

### Anti-pattern: Service Principal client secrets

WIF replaces these. If you see a `client_secret` in production, that's a finding.

### Anti-pattern: Storage account with public network access

Private Endpoint, period. Public network access for production storage is a finding.

### Anti-pattern: SQL Auth in production

Use Entra authentication for Azure SQL / PostgreSQL / Cosmos / Managed Redis. Eliminates the password rotation problem and centralizes audit.

### Anti-pattern: Key Vault legacy access policies

Migrate to RBAC. Policy initiative "Key vaults should use RBAC permission model" enforces.

### Anti-pattern: TLS 1.0 / 1.1 on any service

TLS 1.2+ minimum. TLS 1.3 where supported. Azure Policy enforces.

### Anti-pattern: Diagnostic Settings not configured

Without diagnostic settings, you have no audit trail for the resource. Apply DeployIfNotExists policy to enforce.

### Anti-pattern: Sentinel alerts without playbook

If an alert fires and no one is paged or auto-response fires, it's not an alert — it's a log. Wire playbooks for the alerts you care about.

### Anti-pattern: Compliance-as-snapshot

Compliance isn't a one-time audit. Continuous compliance via Azure Policy compliance dashboard + Defender Secure Score + Sentinel ingestion of governance signals. Drift detection is the discipline.

## Tooling specifics

- **Entra admin center** (admin.entra.microsoft.com) — modern UI for Entra ID, External ID, PIM, Identity Protection.
- **Azure portal Security** — Defender for Cloud, Sentinel, Policy, RBAC.
- **Microsoft Purview portal** (purview.microsoft.com) — classification, DLP, eDiscovery.
- **Defender XDR portal** (security.microsoft.com) — unified SecOps with Sentinel.
- **`az ad`** — Entra CLI (limited surface; `Microsoft Graph PowerShell SDK` for richer ops).
- **`Microsoft Graph PowerShell SDK`** — modern Entra automation (replaces deprecated AzureAD module).
- **`az policy`** — policy assignment + exemption management.
- **`az security`** — Defender for Cloud CLI.
- **Microsoft Sentinel API** + **Logic Apps** for SOAR.
- **Microsoft Cloud Security Benchmark** (MCSB) — baseline benchmark for Azure security posture.
- **Azure Security Benchmark v3** — built-in Azure Policy initiative.
- **Compliance Manager** (Microsoft Purview) — assessment + evidence workflow.

## Integration with always-on protocols

### TDD on security

- **Policy-as-code**: Azure Policy initiatives in Bicep / Terraform; pre-deploy `what-if` validates assignments before apply.
- **Security tests in CI**: tfsec / checkov / Bicep `PSRule for Azure` on every PR.
- **Smoke tests post-deploy**: synthetic auth (signed-in user with various Conditional Access scenarios) verifies policies work end-to-end.

### Verification

- Defender for Cloud Secure Score trend (improving over time).
- Sentinel ingestion health checks (data connectors all up; expected log volumes).
- Policy compliance percentage (and root cause for non-compliance).
- Access review completion rate.
- PIM activation rate (low for break-glass; controlled for admin roles).
- Key rotation success rate.
- WIF adoption rate (target: 100% of CI/CD service principals).

### Review

Push back on:

- Client secrets in any production identity (use WIF / MI).
- Permanent Global Admin / Owner.
- Public network access on production PaaS.
- Key Vault legacy access policies.
- Disabled soft-delete / purge protection.
- TLS 1.0/1.1 anywhere.
- Diagnostic Settings not configured.
- NSG Flow Logs (retired).
- Defender plans blanket-on without scoping (or all-off in production).
- New B2C tenant (use External ID).
- AKS Pod Identity (retired).
- Sentinel rules without playbooks.

### Debugging

- **Entra sign-in logs**: every authentication event, filterable by user / app / location / result. KQL queries via Log Analytics.
- **Audit logs**: every Entra admin action.
- **Provisioning logs**: SCIM provisioning events.
- **Defender for Cloud alerts**: alert details + investigation graph.
- **Sentinel incident investigation**: graph view of related entities + signals.
- **Activity Log**: control plane operations.
- **Resource diagnostic logs**: data plane operations per resource.

Workflow:

1. What signal triggered investigation?
2. Pivot via the entity (user / IP / device / resource).
3. Build a timeline.
4. Identify the actor / asset / vector.
5. Contain (disable user, isolate VM, revoke token via CAE).
6. Eradicate (remove backdoor, rotate keys, patch vulnerability).
7. Recover.
8. Post-incident: lessons learned + control hardening.

## Cross-references to products_covered

| Product | Role usage |
|---------|------------|
| `Microsoft Entra ID` | Workforce identity |
| `Entra External ID` | Customer (CIAM) identity |
| `Conditional Access` | Risk-based access control |
| `Privileged Identity Management` | JIT for admin roles |
| `Workload Identity Federation` | Secretless CI/CD + cross-tenant |
| `Managed Identities` | Service-to-service auth |
| `Azure Key Vault` | Secrets + certs (RBAC mode) |
| `Azure Managed HSM` | FIPS 140-2 L3 key custody |
| `Defender for Cloud` | CSPM + CWPP |
| `Microsoft Sentinel` | SIEM + SOAR |
| `Microsoft Purview` | Data governance + DLP |
| `Azure Policy` | Governance + guardrails |
| `Azure Firewall` | Network firewall |
| `Front Door` / `Application Gateway` (WAF) | L7 inspection |
| `Private Link / Private Endpoints` | Zero-trust network |
| `VNet Flow Logs` | Network forensics |
| `Azure Confidential Computing` | TEE-attested workloads |

## When to refresh this overlay

- Entra feature GA (Agent ID evolution, External ID evolution, CAE expansion)
- New Defender for Cloud plan or pricing change
- New Sentinel feature (auxiliary logs evolution, ML rules)
- Purview AI Hub evolution
- New Conditional Access feature
- Regulatory compliance initiative changes (PCI-DSS v5, etc.)
- New retirement / migration (e.g., the next NSG-Flow-Logs-like change)

Target refresh cadence: every 3-6 months given the velocity of identity / security feature shipping at Microsoft.
