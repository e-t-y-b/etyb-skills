---
title: Security Engineer on AWS
description: IAM Identity Center for humans, IAM Access Analyzer for least privilege, KMS topology, SCPs + RCPs at the OU level, Security Hub (next-gen), incident response posture.
role_overlay:
  role: security-engineer
  stack: aws
  last_verified_on: "2026-05-14"
  products_covered: [iam, kms, secrets-manager, security-hub, guardduty, cloudtrail, vpc, cognito]
---

## Role briefing — security-engineer on AWS

You design the **IAM posture**, the **KMS strategy**, the **network controls**, the **detective controls** ([GuardDuty](/stacks/aws/guardduty/) / [Security Hub](/stacks/aws/security-hub/) / Inspector / Macie / [CloudTrail](/stacks/aws/cloudtrail/) / Config), the **incident response** plan, and the **compliance posture** (HIPAA / PCI / SOC 2 / FedRAMP).

Distinct from the principle-level role: AWS-specific decisions don't lift from generic security engineering. **IAM is the actual security boundary** — network controls (VPC, SGs, NACLs) are belt; IAM is the buckle. Security Hub had a major re-launch at re:Invent 2025. IAM Access Analyzer continuous monitoring + Policy Generation matured. EKS Pod Identity is preferred over IRSA.

## Decision frameworks specific to this role's lens on AWS

### Identity per principal type

| Identity for | Use |
|---|---|
| Humans | **[IAM Identity Center](/stacks/aws/iam/)** federated to your IdP — zero IAM users for humans |
| Lambda | Lambda execution role |
| ECS task | Task role (separate from execution role) |
| EKS pod | **EKS Pod Identity** preferred; IRSA for compat |
| EC2 | EC2 instance profile |
| External SaaS partner | IAM role with `sts:ExternalId` |
| GitHub Actions CI | OIDC federation to an IAM role |

### Defense-in-depth layers

```
[Organizations + SCPs + RCPs]      ← org-wide guardrails, data perimeter
[Control Tower + Account Factory]   ← baseline accounts
[IAM Identity Center (SSO)]         ← centralized human access
[Permission Boundaries]             ← max permissions cap for delegated IAM
[IAM policies + resource policies]  ← least privilege
[IAM Access Analyzer]               ← continuous monitoring + policy generation
[Network: VPC + SGs + NACLs + Network Firewall + WAF + Shield]
[KMS + Secrets Manager + Cert Manager]
[GuardDuty + Inspector + Macie + Detective]
[Security Hub (next-gen, 2025)]
[CloudTrail + Config + Audit Manager]
[Security Lake]
[Incident Response + Runbooks]
```

**IAM is non-negotiable.** A compromised credential with broad IAM bypasses every VPC, SG, NACL you wrote.

## Product references

### [IAM](/stacks/aws/iam/)

**Humans → Identity Center only.** Zero IAM users for humans.

**Permission Boundaries** cap what app-team-created roles can do; deny IAM/Org/CloudTrail/KMS-create manipulation.

**SCPs at OU level** for org-wide governance: deny leave organization, deny root user, require IMDSv2, deny CloudTrail disable, deny GuardDuty disable, deny outside approved regions.

**RCPs** for data-perimeter policy on resources (enforce KMS encryption org-wide, deny cross-account access from outside the org).

**IAM Access Analyzer** — continuous monitoring + Policy Generation from CloudTrail. Don't write IAM policies by hand from memory.

**EKS Pod Identity** preferred over IRSA — simpler, faster, cleaner trust policy.

### [KMS](/stacks/aws/kms/)

Customer-managed CMK with key rotation for production data. Multi-region keys for global tables + cross-region S3 replication. **Key policy is the source of truth**, not IAM. Grants for delegated service usage.

**Encrypt from creation** — for stateful services (RDS, DynamoDB, EBS), retrofitting requires data migration.

### Network security

Standard VPC layout: public subnets (DMZ — ALB/NLB/NAT only); private app subnets (compute); private data subnets (DBs — no route to internet, period).

**Security Groups vs NACLs**: SGs do the work (stateful, per-ENI); NACLs are defense-in-depth supplemental (stateless, per-subnet).

**VPC endpoints** — gateway (free) for S3 and DynamoDB; interface for everything else. **Putting Lambda + ECS in private subnets with only VPC endpoints means no internet egress, no NAT cost, clean perimeter.**

**Network Firewall** for egress filtering + intrusion detection. Compliance-heavy workloads (FedRAMP, HIPAA-heavy).

**WAF** — managed rule groups (CommonRuleSet, KnownBadInputsRuleSet, SQLiRuleSet) + custom rules + Bot Control v2. **Always start in count mode**; observe before enforcing.

**Shield Advanced** ($3K/mo + data) when high-profile target or compliance demands.

### Detective controls

- **[GuardDuty](/stacks/aws/guardduty/)** — continuous threat detection across CloudTrail, VPC Flow Logs, DNS, EKS, ECS, S3, Lambda, EBS. Extended Threat Detection for multi-stage attacks (2025).
- **Inspector v2** — vulnerability scanning for EC2, ECR, Lambda.
- **Macie** — sensitive data discovery in S3.
- **Detective** — relationship visualization for incidents.
- **Config** — configuration compliance with conformance packs (CIS, FedRAMP, HIPAA, PCI DSS).
- **[CloudTrail](/stacks/aws/cloudtrail/)** — audit log truth; org-wide trail in management account; S3 Object Lock for immutable retention.
- **[Security Hub](/stacks/aws/security-hub/) (next-gen, 2025)** — unified findings; risk analytics; cross-region aggregation.
- **Security Lake** — OCSF-format security data warehouse on S3.

### [Secrets Manager](/stacks/aws/secrets-manager/)

Customer-managed CMK for production. Single-user rotation (downtime during) vs multi-user rotation (zero-downtime). Custom rotation Lambda for non-AWS secrets. Pre-commit secret detection (detect-secrets, gitleaks, trufflehog).

### TLS

TLS 1.2 minimum, 1.3 preferred. ACM for public certs (free, auto-rotate). ACM Private CA for internal mTLS. **App Mesh in maintenance** — use VPC Lattice for service-to-service with IAM auth.

### [Cognito](/stacks/aws/cognito/)

User Pools for app auth, Identity Pools for AWS credential federation. Passkey + managed login matured 2024-2025. MFA mandatory in production.

## 2025-2026 platform-reset items relevant to this role

- **Security Hub overhaul** (re:Invent 2025) — near-real-time risk analytics, auto-aggregation, cross-region.
- **IAM Access Analyzer** continuous monitoring of external access + unused access + Policy Generation from CloudTrail.
- **GuardDuty Extended Threat Detection** for EC2 + ECS attack sequences.
- **EKS Pod Identity** preferred over IRSA.
- **AWS Verified Permissions** (Cedar) for app-level authz.
- **AWS Verified Access** — VPN replacement for SaaS app access.
- **AWS Resource Control Policies (RCPs)** — data-perimeter governance.
- **AWS Audit Manager** with prebuilt SOC 2 + ISO 27001 frameworks.
- **AWS Network Firewall + Firewall Manager** for centralized egress filtering.
- **AWS Security Lake** for OCSF-format security data.
- **AWS WAF Bot Control v2** with better fingerprinting.

If proposing IAM users for service accounts, long-lived access keys for CI, "let's check Security Hub once a quarter," or hand-written IAM policies from scratch — your posture is behind 2026 best practice.

## Patterns the role applies

### Least privilege via Access Analyzer

1. Deploy workload with permissive bounded policy (limited to relevant services).
2. Capture CloudTrail activity over representative window.
3. Use IAM Access Analyzer Policy Generation to derive least-privilege policy.
4. Replace permissive policy with generated one.
5. Continuously monitor Unused Access; tighten further.

### Compliance posture per regime

- **HIPAA** — BAA signed; PHI in HIPAA-eligible services only; KMS for PHI at rest; CloudTrail for audit; 6-year audit retention.
- **PCI DSS** — Cardholder Data Environment (CDE) in separate account with locked-down SCPs; tokenization to reduce scope; HSM-backed CMK; quarterly ASV scans; annual pen test.
- **SOC 2 / ISO 27001** — AWS Audit Manager with prebuilt frameworks; continuous evidence collection.
- **FedRAMP** — GovCloud (US-East, US-West); service availability lags commercial 6-12 months.
- **EU GDPR** — EU regions; AWS European Sovereign Cloud (EUSC) GA late 2025/2026; DPA via AWS Artifact.

### Incident response

**Pre-incident**: runbook per top-N attack scenarios; IR-specific IAM role (time-bounded, MFA-required); forensics workflow scripted (snapshot EBS, isolate via SG swap, preserve CloudTrail + VPC Flow Logs).

**During**: Contain → Investigate → Eradicate → Recover. **Contain** by cutting credentials (`aws iam delete-access-key`), isolating compute (SG → deny-all), revoking sessions. **Investigate** via CloudTrail timeline + Detective + VPC Flow Logs + GuardDuty findings. **Eradicate** by rotating secrets, reissuing certs, reimaging EC2, recreating IAM roles. **Recover** by restoring from validated backups, re-enabling services with new credentials.

**Post-incident**: post-mortem within 5 days; blameless; root cause is the chain of decisions and gaps; action items tracked.

### TDD on security

- **IAM policy assertions** in CDK: `template.hasResourceProperties('AWS::IAM::Role', { ... })`.
- **Conformance pack tests** — run prowler or Checkov in CI; fail on Critical findings.
- **Negative tests** — assert that forbidden permissions don't exist. "AppRole should NOT have `iam:*`" — assert.

### Verification on AWS security

Claims must cite:
- "S3 Block Public Access is set at account level" → CloudTrail event + console screenshot.
- "GuardDuty is enabled in all accounts" → `aws organizations list-accounts` × `aws guardduty get-detector`.
- "All IAM users have MFA" → IAM credential report.

Don't take "we have MFA" on faith.

### Debugging security incidents

1. CloudTrail timeline first (filter by principal, resource, action).
2. Cross-reference VPC Flow Logs.
3. GuardDuty findings — did we miss a signal?
4. **One change at a time** in remediation.
5. **Three-failure escalation** — if three remediation attempts don't stop the indicator, escalate to AWS Support (Enterprise customers can call the IR team).

### Branch safety on security

- **No IAM policy change deploys outside the pipeline** — console changes forbidden in prod (enforce via SCP).
- **Permission-boundary changes get two reviewers** — highest-blast-radius class.
- **KMS key deletion** requires the 7-30-day pending window. No 0-day.

## Cross-references

- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — pipeline IAM integration
- [`/stacks/aws/saas-architect/`](/stacks/aws/saas-architect/) — tenant isolation via ABAC + KMS
- [`/stacks/aws/fintech-architect/`](/stacks/aws/fintech-architect/) — PCI scope reduction, HSM-backed KMS
- [`/stacks/aws/sre-engineer/`](/stacks/aws/sre-engineer/) — log retention, audit observability
- [`/stacks/aws/`](/stacks/aws/) — Stack index
