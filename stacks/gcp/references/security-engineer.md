---
role: security-engineer
stack: gcp
last_verified_on: "2026-05-14"
---

# GCP Overlay — security-engineer

You are security-engineer on a GCP engagement. Your IAM model is hierarchical (org → folder → project → resource) with allow + deny policies and IAM Conditions. Your data exfiltration boundary is VPC Service Controls. Your edge security is Cloud Armor. Your secrets path is Secret Manager + Cloud KMS / EKM with CMEK on everything regulated. Your non-human auth is Workload Identity Federation — service account JSON keys are an audit liability in 2026.

**Currency:** verified against GCP product surface as of 2026-05-14. JA4 fingerprinting + hierarchical Cloud Armor policies, WIF SAML/X.509 GA, Trace Sinks deprecated, Telemetry API rollout. See parent [`SKILL.md`](../SKILL.md) for the full "what changed" list.

## What changed in 2025-2026 that older training data misses

- **Workload Identity Federation** is the mandatory pattern for non-GCP workloads. Service account JSON keys are audit red flags. WIF supports OIDC, SAML 2.0 (GA), and X.509 certificate federation (GA).
- **Cloud Armor JA4 fingerprinting** (GA) — TLS client identification beyond JA3; rate-limit / block by JA4. JA4 rate-limit key is GA.
- **Cloud Armor hierarchical security policies** (GA) — org/folder/project policy inheritance. Lets central security team enforce baseline rules across all projects.
- **Cloud Armor body inspection** raised to 8 KB–64 KB for all preconfigured WAF rules.
- **Cloud Armor ModSecurity CRS 3.3** preconfigured WAF rule set GA.
- **VPC Service Controls** supports identity groups + third-party identities in ingress/egress rules (Preview); pair with Private Service Connect for defense-in-depth.
- **Security Command Center Enterprise** is the maturing platform — Findings + Security Posture + Toxic Combinations (chain of misconfigurations + vulnerabilities that produce an exploitable path).
- **Chronicle SIEM** is the GCP-native SIEM; integrated with SCC for advanced threat hunting.
- **BeyondCorp Enterprise** matured into a zero-trust access platform — context-aware access, device posture, replaces VPN-based perimeter for many use cases.
- **Confidential Computing** (Confidential VMs, Confidential GKE Nodes, Confidential Space) — memory encryption with TDX / SEV-SNP. Strong default for regulated workloads + cross-tenant scenarios.
- **Assured Workloads** packages: HIPAA, FedRAMP High, IL4/IL5, CJIS, ITAR, EU Sovereign — compliance scaffolding (BAA, residency, personnel access boundary, FIPS 140-2 encryption) configured automatically when you create an Assured Workloads folder.
- **Parameter Manager** (GA) — companion to Secret Manager for non-secret configuration with audit + IAM control.
- **Secret Manager replication policies** + automatic rotation for supported integrations (DB credentials).
- **Container Analysis** vulnerability scans on Artifact Registry; integrates with Binary Authorization for deploy-time enforcement.
- **Trace Sinks deprecated Feb 2026** — migrate to Observability Analytics. New projects post-March 2026 auto-enable the Telemetry API.

If you're recommending downloading service account JSON keys, "we'll just put it in a Secret Manager and forget about rotation," default VPC for prod, or Cloud Armor with only rate-limiting on a public service — your training is stale.

## IAM hierarchy and the project blast radius

GCP IAM is hierarchical:
- **Organization** (your domain / company) — root of trust
- **Folders** (optional, nested up to 10 levels) — group projects, attach policies + budgets
- **Projects** — the resource container and primary IAM blast radius
- **Resources** — individual buckets, instances, services

IAM bindings at a higher level inherit downward. A grant of `roles/editor` at the org level gives editor on every project under the org. A grant of `roles/storage.objectViewer` at the project gives viewer on every bucket in the project.

**The most common IAM mistake**: granting `roles/editor` or `roles/viewer` at project scope to a human or service account when a more specific predefined role or resource-scoped binding would suffice. Editor is essentially admin minus a few governance operations — leaking it is catastrophic.

### Allow vs deny policies

- **Allow policies** grant permissions; the default GCP model
- **Deny policies** (newer; GA) explicitly forbid actions regardless of allows; useful for "no one, not even owners, can delete this bucket"

Use deny policies for **break-glass guardrails**: production data buckets, KMS keys for prod, billing accounts. The deny applies even to identities with org-admin allow grants.

### IAM Conditions

Conditions add ABAC dimensions to IAM:
- Time-bound access (`request.time < timestamp('2026-06-01T00:00:00Z')`)
- Resource tags (`resource.matchTag('123/env', 'prod')`)
- IP source range (`request.host == 'specific-host'`)

Use for just-in-time elevation (24-hour admin grant), break-glass workflows, and tag-based RBAC.

```bash
gcloud projects add-iam-policy-binding proj \
  --member="user:incident-responder@example.com" \
  --role=roles/cloudsql.admin \
  --condition="expression=request.time < timestamp('2026-05-15T00:00:00Z'),title=incident_2026_05_14"
```

### Custom roles — when

Custom roles when:
- Predefined role set is too coarse (e.g., need read-only on a subset of Compute Engine)
- You're building an automation that needs an absolute minimum permission set
- Compliance requires explicit permission inventory

Custom roles cost overhead — maintain them, update for new permissions. Default to predefined roles; promote to custom only when necessary.

### Service accounts

Service accounts are non-human identities. Patterns:
- **Runtime SA** per workload: each Cloud Run service / GKE workload / Cloud Function gets its own SA bound to least-privilege roles
- **Deploy SA** per CI pipeline: separate from runtime, used only for `gcloud deploy` / `terraform apply` / `kubectl apply`
- **No shared SAs**: the per-workload-per-stage SA is the unit of IAM granularity

Avoid:
- Using `default` Compute Engine SA — it has broad permissions
- Granting human-user permissions on a service account that doesn't need them
- Embedding SA JSON keys in code (use WIF or runtime SA)

### Policy Intelligence

Policy Intelligence (a.k.a. Recommender) analyzes IAM usage and produces:
- **Unused role recommendations** — flag roles no one has exercised in 90 days
- **Excess permission recommendations** — suggest narrower roles
- **Policy Insights** — what would happen if you granted X to Y

Use in CI to keep IAM lean over time. The "everyone is `roles/editor` because it just works" antipattern dies when recommender runs as part of weekly housekeeping.

## Workload Identity Federation — the 2026 baseline

WIF eliminates downloaded service account keys. The auth flow:
1. External workload has its own identity (GitHub OIDC, AWS IAM role, on-prem SAML, X.509 cert)
2. GCP workload identity pool + provider validates the external identity
3. External workload exchanges its native token for a short-lived GCP federated token
4. Federated token assumes a GCP service account via `roles/iam.workloadIdentityUser`

Patterns by external system:

| External | Federation type |
|----------|----------------|
| GitHub Actions | OIDC |
| GitLab CI | OIDC |
| CircleCI | OIDC |
| AWS workload | AWS IAM (sigv4) |
| Azure workload | Azure AD OIDC |
| On-prem with SAML IdP | SAML 2.0 (GA) |
| On-prem with mTLS / certs | X.509 (GA) |
| Kubernetes outside GCP | OIDC |

See [`devops-engineer.md`](devops-engineer.md#workload-identity-federation--the-2026-baseline) for the GitHub Actions worked example.

**Security review item:** any audit or pentest in 2026 should grep the env / secrets store / code for `"type": "service_account"` JSON keys. Each match is a finding.

## VPC Service Controls — data exfiltration boundary

VPC Service Controls (VPC-SC) creates an **identity-aware perimeter** around GCP API surfaces. Inside the perimeter, services can talk to each other freely. Outside the perimeter, ingress / egress is gated by explicit rules.

Use VPC-SC when:
- Sensitive data exfiltration is a real threat (regulated workloads, IP-sensitive)
- You want to enforce "no Cloud Storage data can leave this perimeter regardless of IAM"
- You need to protect against insider exfiltration via legitimate IAM grants

Limits:
- Some services aren't VPC-SC-protectable (verify per [VPC-SC supported services](https://cloud.google.com/vpc-service-controls/docs/supported-products))
- Configuration is operational overhead — every new service or cross-perimeter dependency requires explicit ingress/egress rules

```bash
gcloud access-context-manager perimeters create prod-perimeter \
  --title="Production Perimeter" \
  --resources="projects/123456789,projects/987654321" \
  --restricted-services="bigquery.googleapis.com,storage.googleapis.com,pubsub.googleapis.com" \
  --policy=POLICY_ID
```

### Ingress / egress policies

- **Ingress rules**: allow specific identities or services from outside the perimeter to call services inside
- **Egress rules**: allow services inside to call specific external destinations

The 2025 update: ingress / egress rules support **identity groups and third-party identities** (Preview) — useful for granting external partner access without inviting them into your GCP org.

### Dry-run perimeter

Always dry-run a perimeter for at least a week before enforcement. Dry-run mode logs violations without blocking — gives you the failure inventory before flipping enforcement.

## Private Service Connect — private API surface

Private Service Connect (PSC) exposes GCP managed services on private IPs in your VPC. Pattern:
- Cloud SQL / AlloyDB / Spanner / Pub/Sub / BigQuery accessed via PSC endpoints
- Endpoints live in your VPC subnet; traffic never touches the public internet
- Pairs with VPC-SC for defense-in-depth

Use PSC over the older Private Google Access for new builds — PSC is more granular, supports cross-project, and is the path forward.

```bash
# Create PSC endpoint for Cloud SQL
gcloud compute forwarding-rules create cloudsql-psc \
  --region=us-central1 \
  --network=prod-vpc \
  --subnet=psc-subnet \
  --target-service-attachment=...
```

**The 2025 additions**:
- **IPv6-only NAT subnets** GA — publish services over IPv6
- **Propagated connections** GA — service accessible in one VPC spoke automatically available to all spokes via Network Connectivity Center hub
- **Service connectivity automation with IPv6** GA

## Cloud Armor — edge security

Cloud Armor is Google's WAF + DDoS layer in front of Global External Application Load Balancers (and now Regional internal ALBs, GA). Features (2026):

| Feature | Status |
|---------|--------|
| Preconfigured WAF rules (OWASP Top 10 via ModSecurity CRS 3.3) | GA |
| Body inspection up to 64 KB | GA |
| Rate limiting per IP / cookie / header / JA4 | GA |
| JA4 / JA3 TLS fingerprinting | GA |
| Hierarchical security policies (org/folder/project) | GA |
| Organization-scoped address groups | GA |
| Adaptive Protection (ML-based DDoS) | GA |
| Bot Management (reCAPTCHA Enterprise integration) | GA |
| Regional internal ALB support | GA |

### Policy structure

A Cloud Armor policy is a list of rules evaluated in order by priority:

```bash
# Block known bad IPs (priority 1000)
gcloud compute security-policies rules create 1000 \
  --security-policy=api-protection \
  --src-ip-ranges=192.0.2.0/24 \
  --action=deny-403

# OWASP CRS SQLi (priority 1100)
gcloud compute security-policies rules create 1100 \
  --security-policy=api-protection \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable')" \
  --action=deny-403

# OWASP CRS XSS (priority 1110)
gcloud compute security-policies rules create 1110 \
  --security-policy=api-protection \
  --expression="evaluatePreconfiguredExpr('xss-v33-stable')" \
  --action=deny-403

# Rate limit unauthenticated traffic (priority 2000)
gcloud compute security-policies rules create 2000 \
  --security-policy=api-protection \
  --expression="true" \
  --action=throttle \
  --rate-limit-threshold-count=100 \
  --rate-limit-threshold-interval-sec=60 \
  --conform-action=allow \
  --exceed-action=deny-429 \
  --enforce-on-key=IP

# JA4 rate limit for sus client (priority 2100)
gcloud compute security-policies rules create 2100 \
  --security-policy=api-protection \
  --expression="request.ja4 == 't13d1715h2_5b57614c22b0_3d5424432f57'" \
  --action=throttle \
  --rate-limit-threshold-count=10 \
  --rate-limit-threshold-interval-sec=60 \
  --enforce-on-key=JA4
```

### Hierarchical policies

Apply security policies at org / folder level to enforce baseline rules across all projects:

```bash
gcloud compute security-policies create --global-organization-policy \
  baseline-org-policy \
  --type=CLOUD_ARMOR_INTERNAL_SERVICE \
  --organization=123456789
```

Project-level policies layer additional rules. This is the 2026 pattern for "central security team enforces baselines, app teams customize per service."

### Adaptive Protection

ML-based DDoS detection. Enable per policy; produces signed signatures suggesting rules to add during attack. Don't auto-apply suggested rules without review — false positives can lock out legitimate users.

## Secret Manager + Parameter Manager

| Service | What |
|---------|------|
| **Secret Manager** | Passwords, API keys, certificates, private keys |
| **Parameter Manager** (GA) | Non-secret configuration (feature flags, URLs, tunable knobs) with same IAM + audit model |

### Secret lifecycle

```bash
# Create with automatic global replication
gcloud secrets create db-password --replication-policy=automatic

# Add a version
echo -n "s3cur3P@ss" | gcloud secrets versions add db-password --data-file=-

# Access in Cloud Run
gcloud run deploy my-service \
  --set-secrets=DB_PASSWORD=db-password:latest

# Access in GKE via CSI driver
# (pod gets secret mounted as file via Secret Manager CSI driver)
```

### Rotation

- **Automated rotation** for supported integrations (Cloud SQL via Secret Manager + Cloud Scheduler trigger to rotation function)
- **Manual rotation** for everything else — schedule via Cloud Scheduler + Cloud Run function; the function generates new credential, writes to Secret Manager, retires old version
- **Rotation period**: 90 days for sensitive secrets, 365 days for medium-sensitivity, longer for low-sensitivity. Compliance regimes have specific requirements (e.g., PCI DSS 12.3.10 for keys).

### IAM on secrets

- **`roles/secretmanager.secretAccessor`** — read secret versions; bind to runtime SA
- **`roles/secretmanager.secretVersionManager`** — add/disable/destroy versions; bind to deploy SA or rotation function
- **`roles/secretmanager.admin`** — full control; bind sparingly to humans

**Never** grant `secretmanager.admin` at project scope unless absolutely necessary. Grant at secret scope.

### Audit

Secret access logs go to Cloud Audit Logs (`DATA_READ`). Enable via project-level audit log config; aggregate to BigQuery sink for analysis.

## Cloud KMS and EKM

Cloud KMS manages encryption keys; CMEK (customer-managed encryption keys) is the regulated-workload default.

| Service tier | When |
|--------------|------|
| **Software** (default) | Standard CMEK; keys managed in Google's hardware boundary |
| **HSM** | FIPS 140-2 Level 3 validated hardware; required for some compliance regimes (PCI, HIPAA-strict) |
| **EKM (External Key Manager)** | Keys held by external HSM provider (Thales, Equinix, Fortanix, virtu); GCP gets short-lived key access; required when sovereign control mandates non-Google possession |

### Key pattern

- **Key rings** are regional; create one ring per environment per region
- **Keys** within a ring; one key per use case (encrypting Cloud Storage X, encrypting Cloud SQL Y)
- **Automatic rotation**: 90-day default for software, manual for HSM/EKM
- **Versioning**: old key versions kept for decryption of old ciphertext; rotate, don't rebuild

```bash
gcloud kms keyrings create prod-keyring --location=us-central1

gcloud kms keys create app-data-key \
  --keyring=prod-keyring \
  --location=us-central1 \
  --purpose=encryption \
  --rotation-period=90d \
  --next-rotation-time=2026-08-01T00:00:00Z
```

### CMEK enforcement

Org policy `constraints/gcp.restrictNonCmekServices` enforces CMEK on supported services org-wide. Combine with `constraints/gcp.restrictCmekCryptoKeyProjects` to scope which projects' keys can be used.

## BeyondCorp Enterprise — zero-trust access

BeyondCorp replaces VPN-based perimeter security with context-aware access. Per-request decisions based on:
- User identity (Google Identity / external IdP)
- Device posture (managed device, endpoint security state)
- Location
- Time
- Risk signals

Pair with **Identity-Aware Proxy (IAP)** to gate internal apps:

```bash
# Enable IAP on a Cloud Run service
gcloud run services update my-internal-tool \
  --no-allow-unauthenticated \
  --ingress=internal-and-cloud-load-balancing

# Set up IAP on the GLB backend service
gcloud iap web add-iam-policy-binding \
  --service=my-internal-tool \
  --member=user:alice@example.com \
  --role=roles/iap.httpsResourceAccessor
```

**The 2026 default**: internal tools (admin consoles, BI dashboards, internal APIs) sit behind IAP with BeyondCorp policies. VPN is reserved for legacy / non-HTTP protocols.

## Security Command Center (SCC)

SCC is GCP's centralized vulnerability + threat management. Tiers:

| Tier | What |
|------|------|
| **Standard** | Free; basic findings (Security Health Analytics misconfigurations) |
| **Premium** | Subscription; Event Threat Detection, Web Security Scanner, Container Threat Detection, Virtual Machine Threat Detection |
| **Enterprise** | Premium + Chronicle SIEM integration, Toxic Combinations, posture management, multi-cloud (AWS findings) |

### Key built-in detectors

- **Security Health Analytics** — misconfiguration scanner (open buckets, public IPs, weak firewall rules, etc.)
- **Web Security Scanner** — vulnerability scan of App Engine / Compute Engine HTTP endpoints
- **Event Threat Detection** — detects threats from Cloud Audit Logs (data exfiltration, IAM anomalies, etc.)
- **Container Threat Detection** — runtime container threat detection on GKE
- **VM Threat Detection** — runtime threat detection on Compute Engine
- **Toxic Combinations** (Enterprise) — chains of vulnerabilities + misconfigurations that produce exploitable paths

### Findings workflow

- Findings appear in SCC console + as Pub/Sub events (route to Jira / PagerDuty / Slack)
- Mute / triage / close with notes
- Compliance dashboards (CIS Benchmarks, NIST 800-53, PCI DSS, ISO 27001)

Integrate SCC findings into Sec-Ops workflow from day one. SCC without a triage process is just an alarm that gets ignored.

## Chronicle SIEM

Chronicle is the GCP-native SIEM. Ingests logs from anywhere (GCP audit logs, AWS CloudTrail, M365, Okta, on-prem appliances) and provides:
- Year-long retention at petabyte scale
- YARA-L detection rules
- Threat intelligence integration (Mandiant)
- Pre-built parsers for 500+ log sources

Use when:
- You need SIEM with multi-cloud / hybrid scope
- Existing SIEM (Splunk, Sentinel) cost is prohibitive at scale
- You want managed detection + response with Mandiant playbooks

Skip when:
- Existing SIEM investment is justified
- Compliance regime requires specific SIEM vendor

## Assured Workloads

Assured Workloads packages enforce compliance scaffolding when you create a regulated folder:

| Package | Controls |
|---------|----------|
| **HIPAA** | BAA-eligible services only, US data residency, FIPS 140-2 encryption, personnel access boundary |
| **FedRAMP Moderate / High** | US-based personnel, restricted services, audit logging requirements |
| **IL4 / IL5** | DoD compliance |
| **CJIS** | Criminal Justice Information Services |
| **ITAR** | Export-controlled technical data |
| **EU Sovereign** | EU residency + non-EU personnel access boundary |
| **CMMC** | DoD supply chain |

Create an Assured Workloads folder for regulated projects; the platform enforces the package's controls. Don't try to assemble compliance posture project-by-project — Assured Workloads is the scaffolding.

## Confidential Computing

Confidential Computing encrypts data in use (memory). GCP offerings:

| Product | Substrate |
|---------|-----------|
| **Confidential VMs** | AMD SEV-SNP, Intel TDX |
| **Confidential GKE Nodes** | Same substrates, GKE-native |
| **Confidential Space** | Trusted execution for multi-party workflows (e.g., joint ML training without exposing inputs) |

Use for:
- Workloads handling extremely sensitive data (financial, health, PII)
- Multi-party computation where parties don't trust each other
- Cross-tenant analytics where customer data isolation must be enforceable beyond IAM

Cost overhead is modest (~10-20% in some workloads); enable as a default for regulated.

## Audit logging

Cloud Audit Logs categories:

| Log type | Default | What |
|----------|---------|------|
| **Admin Activity** | Always on, free | IAM changes, resource create/delete, config changes |
| **System Event** | Always on, free | GCP-initiated events (e.g., auto-scaling) |
| **Data Access** | Off by default (except BigQuery); not free | Read/write operations on data |
| **Policy Denied** | Always on | IAM denials |

### The "Data Access" decision

Data Access logs are off by default because they're expensive at scale. For regulated workloads, **must enable** on:
- Cloud Storage (object access)
- BigQuery (already on by default for queries)
- Cloud SQL / AlloyDB / Spanner (data reads + writes)
- Secret Manager (already covered)
- Cloud KMS (key use)

```hcl
resource "google_project_iam_audit_config" "audit" {
  project = var.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
```

### Aggregated sinks

Org-level aggregated sink → BigQuery dataset in a security-dedicated project. **Do not store audit logs in the same project as the workloads being audited** — tampering risk.

```bash
gcloud logging sinks create org-audit-sink \
  bigquery.googleapis.com/projects/security-logs/datasets/audit_logs \
  --organization=123456789 \
  --include-children \
  --log-filter='logName:"cloudaudit.googleapis.com"'
```

## Network security

- **Disable default VPC creation** at org policy level: `constraints/compute.skipDefaultNetworkCreation`
- **Explicit VPC** per environment with deliberate subnet + firewall design
- **Firewall hierarchy**: org-level firewall policies > network-level firewall policies > VPC firewall rules
- **Cloud NAT** for egress IP control; static external IPs for partner allowlisting
- **Cloud IDS** (Intrusion Detection System) for in-VPC traffic inspection; mirror traffic for analysis

### Org policies for security

Mandatory list for any prod org:

```
constraints/compute.skipDefaultNetworkCreation = enforced
constraints/compute.requireOsLogin = enforced
constraints/compute.disableSerialPortAccess = enforced
constraints/iam.disableServiceAccountKeyCreation = enforced
constraints/storage.uniformBucketLevelAccess = enforced
constraints/gcp.restrictNonCmekServices = enforced (with allowed services list)
constraints/iam.allowedPolicyMemberDomains = enforced (allowlist your domain only)
constraints/sql.restrictPublicIp = enforced
constraints/compute.restrictVpcPeering = enforced (with allowed list)
```

The `iam.disableServiceAccountKeyCreation` constraint is the single most effective control to prevent key proliferation. Combined with WIF, the org has no path to create downloadable keys.

## Anti-patterns

- **Granting `roles/owner` or `roles/editor` to humans at project scope** — over-broad; use predefined roles
- **Service account JSON keys in env vars / repo** — WIF for external workloads
- **Default VPC in prod** — disable at org policy
- **No org-level audit log sink** — when you need them, they're gone
- **Storing audit logs in the project being audited** — tampering risk
- **Cloud Armor with only rate-limiting** — needs OWASP CRS + JA4 + adaptive
- **No VPC-SC perimeter for sensitive data** — exfiltration risk
- **No CMEK on regulated services** — audit finding
- **Long-lived secrets in Secret Manager with no rotation** — same as long-lived passwords
- **No Binary Authorization on prod GKE / Cloud Run** for regulated workloads — untrusted image risk
- **Granting `secretmanager.admin` at project scope** — over-broad; grant per-secret
- **Disabling auto-upgrade on GKE** — patches don't apply, CVEs accumulate
- **Allowing `secretmanager.versionManager` to runtime SA** — runtime should be `secretAccessor` only

## Verification checklist for security-engineer on GCP

- [ ] Org policy baseline applied: no default network, no SA key creation, uniform bucket-level access, CMEK enforcement, allowed-domain restriction, no Cloud SQL public IP, OS Login required
- [ ] IAM model: predefined roles default, custom roles only where justified, no Editor/Viewer at project scope for humans
- [ ] WIF configured for all non-GCP-workload authentication; no service account JSON keys
- [ ] Per-workload runtime SAs with least-privilege bindings; no shared SAs
- [ ] VPC-SC perimeter design for projects with sensitive data; dry-run before enforce
- [ ] PSC endpoints for Cloud SQL / AlloyDB / Spanner / BigQuery / Pub/Sub
- [ ] Cloud Armor policies in front of every public-facing GLB; ModSecurity CRS 3.3 + rate limiting + JA4 baseline; hierarchical baseline at org level
- [ ] Cloud KMS with CMEK on regulated services; EKM evaluated if external HSM mandate
- [ ] Secret Manager: secrets created with replication policy, rotation scheduled, runtime SA = `secretAccessor`
- [ ] Audit logging: Data Access logs enabled for sensitive services, org-level aggregated sink to dedicated security project
- [ ] Security Command Center: at least Premium tier enabled, findings routed to PagerDuty/Jira/Slack
- [ ] Binary Authorization enforced on regulated GKE/Cloud Run with attestor pipeline
- [ ] BeyondCorp Enterprise + IAP for internal-facing tools; VPN reserved for legacy
- [ ] Assured Workloads folder for regulated projects (HIPAA, FedRAMP, EU sovereign, etc.)
- [ ] Confidential Computing evaluated for cross-tenant or extreme-PII workloads
- [ ] Chronicle SIEM or external SIEM integration plan
- [ ] No legacy paths: no service account keys, no default network, no public-IP databases for new builds
- [ ] Currency check: every recommended control verified against release notes / security bulletins

## Integration with always-on protocols

- **TDD**: security controls are code; test them. `gcloud kms keys verify`, `gcloud iam policy analyze` for IAM, `gcloud access-context-manager perimeters dry-run` for VPC-SC. Pen-test the perimeter before declaring it complete.
- **Verification**: every security change produces evidence — policy diff, audit log entry, SCC posture-score delta. "I enabled CMEK" without proof is not done.
- **Debugging**: security failures hide in Cloud Audit Logs (`POLICY_DENIED`), VPC Flow Logs, SCC findings, Cloud Armor logs. First stop: Cloud Audit Logs filtered by `protoPayload.authorizationInfo.granted="false"`.
- **Plan execution**: security changes are reversible (mostly); but VPC-SC enforcement and org-policy changes can lock out admins. Dry-run + sequenced rollout with break-glass identity preserved.
- **Review**: every IAM change reviewed by a second pair of eyes; no self-approval on prod IAM. Policy Intelligence runs weekly to flag drift toward over-permission.
