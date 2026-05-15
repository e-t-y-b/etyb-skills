---
title: security-engineer on GCP
description: Security on GCP — hierarchical IAM, Workload Identity Federation (mandatory), VPC-SC, Cloud Armor, Secret Manager + Cloud KMS, BeyondCorp, Security Command Center, Assured Workloads.
role_overlay:
  role: security-engineer
  stack: gcp
  last_verified_on: "2026-05-14"
  products_covered:
    - cloud-iam
    - cloud-kms
    - secret-manager
    - cloud-armor
    - vpc
    - cloud-storage
    - cloud-sql
    - alloydb
    - spanner
    - bigquery
    - logging
    - monitoring
    - artifact-registry
    - cloud-build
    - gke
    - cloud-run
---

## Role briefing

You are security-engineer on a GCP engagement. Your IAM model is hierarchical ([Cloud IAM](/stacks/gcp/cloud-iam/)) with allow + deny policies and IAM Conditions. Your data exfiltration boundary is **VPC Service Controls**. Your edge security is **[Cloud Armor](/stacks/gcp/cloud-armor/)**. Your secrets path is **[Secret Manager](/stacks/gcp/secret-manager/) + [Cloud KMS](/stacks/gcp/cloud-kms/)** with CMEK on everything regulated. Your non-human auth is **Workload Identity Federation** — service account JSON keys are an audit liability in 2026.

## What changed in 2025-2026 that older training data misses

- **Workload Identity Federation** is the mandatory pattern for non-GCP workloads. SAML 2.0 (GA) and X.509 (GA) federation now supported alongside OIDC.
- **[Cloud Armor](/stacks/gcp/cloud-armor/) JA4 fingerprinting** GA — TLS client ID beyond JA3.
- **Cloud Armor hierarchical policies** GA — org/folder/project policy inheritance.
- **Cloud Armor body inspection** raised to 8 KB–64 KB; **ModSecurity CRS 3.3** preconfigured WAF rule set GA.
- **VPC Service Controls** supports identity groups + third-party identities in ingress/egress rules (Preview).
- **Security Command Center Enterprise** maturing — Findings + Security Posture + Toxic Combinations.
- **Chronicle SIEM** is the GCP-native SIEM; integrated with SCC.
- **BeyondCorp Enterprise** matured into a zero-trust access platform.
- **Confidential Computing** (Confidential VMs, GKE Nodes, Confidential Space) — TDX / SEV-SNP memory encryption.
- **Assured Workloads** packages: HIPAA, FedRAMP High, IL4/IL5, CJIS, ITAR, EU Sovereign, CMMC.
- **Parameter Manager** GA — companion to Secret Manager for non-secret config.
- **Container Analysis** scans Artifact Registry; integrates with Binary Authorization.
- **Trace Sinks deprecated Feb 2026** — migrate to Observability Analytics.

If you're recommending downloading service account JSON keys, "we'll put it in Secret Manager and forget about rotation," default VPC for prod, or Cloud Armor with only rate-limiting on a public service — your training is stale.

## IAM hierarchy and the project blast radius

See [Cloud IAM](/stacks/gcp/cloud-iam/) for canonical coverage. Key disciplines:

- **The project is the blast radius.** Default: deny `roles/owner`/`roles/editor`/`roles/viewer` at project scope for humans
- **Allow vs deny policies.** Use deny policies for break-glass guardrails (prod data buckets, prod KMS keys, billing accounts)
- **IAM Conditions** for JIT elevation, break-glass, tag-based RBAC
- **Custom roles** only when predefined too coarse
- **Service accounts**: per-workload runtime SA + per-pipeline deploy SA; never shared SAs; no default Compute Engine SA
- **Policy Intelligence (Recommender)** — flag unused roles, excess permissions; run weekly

## Workload Identity Federation — the 2026 baseline

WIF eliminates downloaded service account keys. Flow:
1. External workload has its own identity (GitHub OIDC, AWS IAM, on-prem SAML, X.509)
2. GCP workload identity pool + provider validates external identity
3. External workload exchanges native token for short-lived GCP federated token
4. Federated token assumes GCP service account via `roles/iam.workloadIdentityUser`

Patterns by external system:

| External | Federation type |
|----------|----------------|
| GitHub Actions / GitLab CI / CircleCI | OIDC |
| AWS workload | AWS IAM (sigv4) |
| Azure workload | Azure AD OIDC |
| On-prem with SAML IdP | SAML 2.0 (GA) |
| On-prem with mTLS / certs | X.509 (GA) |
| K8s outside GCP | OIDC |

See [devops-engineer on GCP](/stacks/gcp/devops-engineer/) for GitHub Actions worked example.

**Security review item**: any audit or pentest in 2026 should grep env / secrets store / code for `"type": "service_account"` JSON keys. Each match is a finding.

## VPC Service Controls — data exfiltration boundary

VPC-SC creates an **identity-aware perimeter** around GCP API surfaces. Inside the perimeter, services talk freely. Outside, ingress/egress is gated by explicit rules.

Use when:
- Sensitive data exfiltration is a real threat (regulated, IP-sensitive)
- Enforce "no Cloud Storage data leaves this perimeter regardless of IAM"
- Protect against insider exfiltration via legitimate IAM grants

```bash
gcloud access-context-manager perimeters create prod-perimeter \
  --title="Production Perimeter" \
  --resources="projects/123456789,projects/987654321" \
  --restricted-services="bigquery.googleapis.com,storage.googleapis.com,pubsub.googleapis.com" \
  --policy=POLICY_ID
```

**Always dry-run** for at least a week before enforcement. Dry-run logs violations without blocking.

### Ingress / egress

- **Ingress rules**: specific identities/services from outside calling services inside
- **Egress rules**: services inside calling specific external destinations
- **Identity groups + third-party identities** (Preview) — useful for partner access

## Private Service Connect

Private API surface for managed services ([Cloud SQL](/stacks/gcp/cloud-sql/) / [AlloyDB](/stacks/gcp/alloydb/) / [Spanner](/stacks/gcp/spanner/) / [BigQuery](/stacks/gcp/bigquery/) / [Pub/Sub](/stacks/gcp/pub-sub/)). Endpoints live in your VPC subnet; traffic never touches public internet. Pair with VPC-SC for defense-in-depth.

See [VPC](/stacks/gcp/vpc/) for setup details. **Use PSC over Private Google Access for new builds.**

## Cloud Armor — edge security

See [Cloud Armor](/stacks/gcp/cloud-armor/) for canonical coverage. Discipline:

- ModSecurity CRS 3.3 + rate limiting + JA4 baseline on every public-facing GLB
- Hierarchical baseline at org level; project-level layers on top
- Adaptive Protection enabled, but don't auto-apply suggested rules without review
- Bot Management via reCAPTCHA Enterprise integration

## Secret Manager + Parameter Manager

See [Secret Manager](/stacks/gcp/secret-manager/). Discipline:

- **Per-secret IAM** — never `secretmanager.admin` at project scope
- **Runtime SA = `secretAccessor`** only
- **Deploy SA / rotation function = `secretVersionManager`**
- **Rotation**: 90 days sensitive, 365 days medium, longer low. PCI DSS 12.3.10 for keys.
- **Audit**: enable Data Access logs on Secret Manager; aggregate to BigQuery sink

## Cloud KMS and EKM

See [Cloud KMS](/stacks/gcp/cloud-kms/). Tiers:
- **Software** — standard CMEK
- **HSM** — FIPS 140-2 Level 3; required for PCI strict / HIPAA strict
- **EKM** — external HSM (Thales, Equinix, Fortanix, Virtru); required for sovereign control

Enforce CMEK via org policy:
```
constraints/gcp.restrictNonCmekServices = enforced
```

## BeyondCorp Enterprise — zero-trust access

BeyondCorp replaces VPN-based perimeter security with context-aware access:
- User identity (Google Identity / external IdP)
- Device posture
- Location
- Time
- Risk signals

Pair with **Identity-Aware Proxy (IAP)** to gate internal apps:

```bash
gcloud run services update my-internal-tool \
  --no-allow-unauthenticated \
  --ingress=internal-and-cloud-load-balancing

gcloud iap web add-iam-policy-binding \
  --service=my-internal-tool \
  --member=user:alice@example.com \
  --role=roles/iap.httpsResourceAccessor
```

**The 2026 default**: internal tools sit behind IAP with BeyondCorp policies. VPN reserved for legacy / non-HTTP.

## Security Command Center (SCC)

| Tier | What |
|------|------|
| **Standard** | Free; Security Health Analytics misconfigurations |
| **Premium** | Subscription; Event Threat Detection, Web Security Scanner, Container Threat Detection, VM Threat Detection |
| **Enterprise** | Premium + Chronicle SIEM, Toxic Combinations, posture management, multi-cloud (AWS) |

Findings appear in SCC console + as Pub/Sub events (route to Jira / PagerDuty / Slack). **SCC without a triage process is just an alarm that gets ignored.**

## Chronicle SIEM

GCP-native SIEM with multi-cloud / hybrid scope, year-long retention at petabyte scale, YARA-L detection rules, Mandiant threat intelligence integration.

Use when:
- Multi-cloud / hybrid SIEM scope
- Existing SIEM cost prohibitive at scale
- Want managed detection + response with Mandiant

## Assured Workloads

Packages enforce compliance scaffolding when you create a regulated folder:

| Package | Controls |
|---------|----------|
| **HIPAA** | BAA-eligible services, US data residency, FIPS 140-2, personnel access boundary |
| **FedRAMP Moderate / High** | US-based personnel, restricted services, audit logging |
| **IL4 / IL5** | DoD compliance |
| **CJIS** | Criminal Justice Information Services |
| **ITAR** | Export-controlled technical data |
| **EU Sovereign** | EU residency + non-EU personnel access boundary |
| **CMMC** | DoD supply chain |

**Don't try to assemble compliance posture project-by-project** — Assured Workloads is the scaffolding.

## Confidential Computing

| Product | Substrate |
|---------|-----------|
| **Confidential VMs** | AMD SEV-SNP, Intel TDX |
| **Confidential GKE Nodes** | Same substrates, GKE-native |
| **Confidential Space** | Trusted execution for multi-party workflows |

Use for extremely sensitive data, multi-party computation, cross-tenant analytics where data isolation must be enforceable beyond IAM. Cost overhead modest (~10-20%).

## Audit logging

| Type | Default | What |
|------|---------|------|
| Admin Activity | Always on, free | IAM changes, resource lifecycle |
| System Event | Always on, free | GCP-initiated events |
| Data Access | Off by default (except BigQuery); not free | Read/write on data |
| Policy Denied | Always on | IAM denials |

For regulated workloads, **enable Data Access** on Cloud Storage, BigQuery (already on for queries), Cloud SQL/AlloyDB/Spanner, Secret Manager, Cloud KMS.

**Org-level aggregated sink → BigQuery dataset in a security-dedicated project.** Do not store audit logs in projects being audited — tampering risk.

## Network security

- **Disable default VPC creation**: `constraints/compute.skipDefaultNetworkCreation`
- **Firewall hierarchy**: org-level policies > network-level policies > VPC firewall rules
- **Cloud NAT** for egress IP control
- **Cloud IDS** for in-VPC traffic inspection

### Org policies for security — mandatory list

```
constraints/compute.skipDefaultNetworkCreation = enforced
constraints/compute.requireOsLogin = enforced
constraints/compute.disableSerialPortAccess = enforced
constraints/iam.disableServiceAccountKeyCreation = enforced
constraints/storage.uniformBucketLevelAccess = enforced
constraints/gcp.restrictNonCmekServices = enforced
constraints/iam.allowedPolicyMemberDomains = enforced
constraints/sql.restrictPublicIp = enforced
constraints/compute.restrictVpcPeering = enforced
```

`iam.disableServiceAccountKeyCreation` is the single most effective control to prevent key proliferation.

## Anti-patterns

- **`roles/owner` or `roles/editor` to humans at project scope**
- **Service account JSON keys in env vars / repo**
- **Default VPC in prod**
- **No org-level audit log sink**
- **Storing audit logs in the project being audited**
- **Cloud Armor with only rate-limiting**
- **No VPC-SC perimeter for sensitive data**
- **No CMEK on regulated services**
- **Long-lived secrets with no rotation**
- **No Binary Authorization on prod GKE / Cloud Run** for regulated
- **`secretmanager.admin` at project scope**
- **Disabling auto-upgrade on GKE**
- **`secretmanager.versionManager` to runtime SA**

## Verification checklist for security-engineer on GCP

- [ ] Org policy baseline applied (see mandatory list above)
- [ ] IAM model: predefined roles default, custom roles only when justified, no Editor/Viewer at project scope for humans
- [ ] WIF configured for all non-GCP-workload auth; no service account JSON keys
- [ ] Per-workload runtime SAs with least-privilege bindings
- [ ] VPC-SC perimeter design for sensitive projects; dry-run before enforce
- [ ] PSC endpoints for Cloud SQL / AlloyDB / Spanner / BigQuery / Pub/Sub
- [ ] Cloud Armor policies in front of every public-facing GLB; CRS 3.3 + rate limiting + JA4 baseline; hierarchical baseline at org level
- [ ] Cloud KMS with CMEK on regulated services; EKM if external HSM mandate
- [ ] Secret Manager: replication policy, rotation scheduled, runtime SA = `secretAccessor`
- [ ] Audit logging: Data Access logs on sensitive services, org-level aggregated sink to dedicated security project
- [ ] Security Command Center: at least Premium tier; findings routed
- [ ] Binary Authorization enforced on regulated GKE/Cloud Run with attestor pipeline
- [ ] BeyondCorp Enterprise + IAP for internal-facing tools
- [ ] Assured Workloads folder for regulated projects
- [ ] Confidential Computing evaluated for cross-tenant / extreme-PII
- [ ] Chronicle SIEM or external SIEM integration plan
- [ ] No legacy paths: no SA keys, no default network, no public-IP databases for new builds
- [ ] Currency check: every recommended control verified against release notes / security bulletins

## Patterns I apply

- **TDD**: security controls are code; test them. `gcloud kms keys verify`, `gcloud iam policy analyze`, `gcloud access-context-manager perimeters dry-run`. Pen-test the perimeter before declaring complete.
- **Verification**: every security change produces evidence — policy diff, audit log entry, SCC posture-score delta.
- **Debugging**: security failures hide in Cloud Audit Logs (`POLICY_DENIED`), VPC Flow Logs, SCC findings, Cloud Armor logs. First stop: Cloud Audit Logs filtered by `protoPayload.authorizationInfo.granted="false"`.
- **Plan execution**: security changes are mostly reversible; VPC-SC enforcement + org-policy changes can lock out admins — dry-run + sequenced rollout with break-glass identity preserved.
- **Review**: every IAM change reviewed by a second pair of eyes; no self-approval on prod IAM. Policy Intelligence weekly to flag drift.

## Cross-references

- Other roles: [system-architect on GCP](/stacks/gcp/system-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [database-architect on GCP](/stacks/gcp/database-architect/), [sre-engineer on GCP](/stacks/gcp/sre-engineer/), [saas-architect on GCP](/stacks/gcp/saas-architect/)
- Stack index: [GCP](/stacks/gcp/)
