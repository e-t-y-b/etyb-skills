---
title: IAM
description: AWS Identity and Access Management — Identity Center for humans, IAM roles + Access Analyzer for services, permission boundaries for delegation, SCPs/RCPs at OU level for org-wide guardrails.
product:
  name: IAM
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer, system-architect, saas-architect]
  authoritative_url: https://docs.aws.amazon.com/iam/
  notes: "IAM Identity Center the only path for human access; Access Analyzer continuous + policy generation; EKS Pod Identity preferred over IRSA."
---

## What it is

AWS IAM is the identity and access control plane — IAM users (deprecated for humans), IAM roles (the canonical service identity), IAM Identity Center (formerly SSO, the only modern path for human access), and the policy layer: identity-based policies, resource-based policies, permission boundaries, SCPs, RCPs, IAM Access Analyzer.

Canonical surface: [docs.aws.amazon.com/iam](https://docs.aws.amazon.com/iam/).

## When to use

Everything on AWS uses IAM. Decisions:

| Identity for | Use |
|---|---|
| Humans | **IAM Identity Center** federated to your IdP — zero IAM users |
| Lambda | Lambda execution role |
| ECS task | ECS task role (separate from task execution role) |
| EKS pod | **EKS Pod Identity** preferred; IRSA for compat |
| EC2 | EC2 instance profile |
| Step Functions | State machine role |
| CodeBuild / CodePipeline | Service-specific role |
| External SaaS partner | IAM role with `sts:ExternalId` |
| GitHub Actions CI | OIDC federation to an IAM role |

## 2025-2026 currency anchors

- **IAM Identity Center (formerly SSO)** is the only modern path for human access. Zero IAM users for humans. Period.
- **IAM Access Analyzer** — continuous monitoring of external access (S3, KMS, SQS, Lambda, IAM, etc.), **unused access** detection (find IAM roles/policies with unexercised permissions), **policy generation** from CloudTrail (least-privilege as derived artifact, not handwritten).
- **EKS Pod Identity** (re:Invent 2023, matured 2024-2025) preferred over IRSA for new pod-to-AWS auth.
- **AWS Resource Control Policies (RCPs)** — Organizations-level data-perimeter policies (2024). Complement SCPs.
- **AWS Verified Permissions** (Cedar) — managed policy decision engine for app-level authz.
- **IAM Roles Anywhere** — IAM credentials for workloads outside AWS via X.509 certs.

## Patterns

### Humans → IAM Identity Center

Federated to your IdP (Okta, Entra ID, Auth0, Google Workspace, JumpCloud) via SAML or SCIM. Permission sets define what each user can do per account. Session 1-8h. MFA mandatory.

```bash
aws configure sso
aws sso login --profile dev
aws sts get-caller-identity --profile dev
```

### Services → IAM roles with STS

Never long-lived access keys for services. Every workload gets a role with the smallest permissions needed.

### EKS Pod Identity > IRSA

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: orders
```

```bash
aws eks create-pod-identity-association \
  --cluster-name my-cluster --namespace orders \
  --service-account app-sa \
  --role-arn arn:aws:iam::123456789012:role/AppRole
```

Pod Identity advantages over IRSA: no OIDC issuer setup, faster credential delivery, cleaner trust policy, cluster-scoped. Use IRSA only for cross-cluster workloads.

### GitHub Actions → OIDC

```typescript
const githubOidc = new iam.OpenIdConnectProvider(this, 'GitHubOidc', {
  url: 'https://token.actions.githubusercontent.com',
  clientIds: ['sts.amazonaws.com'],
});

new iam.Role(this, 'GitHubActionsRole', {
  assumedBy: new iam.WebIdentityPrincipal(githubOidc.openIdConnectProviderArn, {
    StringEquals: { 'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com' },
    StringLike: { 'token.actions.githubusercontent.com:sub': 'repo:my-org/my-repo:ref:refs/heads/main' },
  }),
});
```

Scope `sub` claim to the exact `org/repo:ref` you trust. **Don't** wildcard `repo:my-org/*`.

### Least privilege via Access Analyzer

```bash
aws accessanalyzer start-policy-generation \
  --policy-generation-details principalArn=arn:aws:iam::123456789012:role/AppRole \
  --cloud-trail-details "trails=[{cloudTrailArn=arn:aws:cloudtrail:us-east-2:123456789012:trail/org-trail,regions=[us-east-2],accessRole=arn:aws:iam::123456789012:role/PolicyGenRole}],startTime=2026-04-01T00:00:00Z,endTime=2026-05-01T00:00:00Z"
```

Flow:
1. Deploy workload with permissive bounded policy.
2. Capture CloudTrail over a representative window.
3. Access Analyzer Policy Generation derives least-privilege policy.
4. Replace permissive policy with the generated one.
5. Continuously monitor Unused Access; tighten further.

Don't write IAM policies from memory.

### Permission boundaries

Cap what an IAM principal can do, even if a more permissive policy is attached. Platform team delegates IAM creation to app teams, bounded by the boundary.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAppServices",
      "Effect": "Allow",
      "Action": ["s3:*", "dynamodb:*", "lambda:*", "logs:*", "sqs:*", "sns:*", "events:*", "states:*", "execute-api:*", "secretsmanager:GetSecretValue"],
      "Resource": "*"
    },
    {
      "Sid": "DenyIamAndOrgManipulation",
      "Effect": "Deny",
      "Action": ["iam:*", "organizations:*", "account:*", "kms:CreateKey", "kms:ScheduleKeyDeletion", "cloudtrail:Stop*", "cloudtrail:Delete*"],
      "Resource": "*"
    }
  ]
}
```

### SCPs at OU level

Service Control Policies apply org-wide governance. Apply at OU level, not individual account:

```json
{
  "Sid": "DenyLeaveOrganization",
  "Effect": "Deny",
  "Action": "organizations:LeaveOrganization",
  "Resource": "*"
}
```

Common SCP statements: deny CloudTrail disable, deny root user, require IMDSv2, deny GuardDuty disable, deny outside approved regions.

### IAM ABAC for multi-tenant

Tag principal + resource with `Tenant=<id>`; scope by `${aws:PrincipalTag/Tenant}` = `${aws:ResourceTag/Tenant}`.

```json
{
  "Effect": "Allow",
  "Action": ["dynamodb:Query", "dynamodb:GetItem", "dynamodb:PutItem"],
  "Resource": "arn:aws:dynamodb:*:*:table/Orders",
  "Condition": {
    "StringEquals": {
      "aws:ResourceTag/Tenant": "${aws:PrincipalTag/Tenant}"
    }
  }
}
```

See [`/stacks/aws/saas-architect/`](/stacks/aws/saas-architect/) for the full ABAC SaaS pattern.

## Anti-patterns

- **IAM users for humans.** Identity Center only.
- **IAM users for service accounts.** Use roles + STS.
- **Long-lived access keys in CI.** OIDC federation.
- **Wildcard permissions (`Action: "*"`)** in production policies. Scope by service prefix at minimum.
- **No permission boundaries on app-team-created roles.** Privilege escalation waiting.
- **No SCPs at OU level.** Org-wide guardrails are foundational.
- **MFA only on root user.** Every Identity Center user needs MFA.
- **Hand-written IAM policies from memory.** Use Access Analyzer generation.
- **Console-edited IAM in production.** Pipeline-driven only.
- **GitHub Actions wildcard `sub` claim.** Pin to `repo:org/repo:ref:refs/heads/main`.

## Gotchas

- **IAM is eventually consistent globally.** Role/policy creation can take seconds-to-minutes to propagate.
- **STS regional vs global endpoint** — for VPC-attached workloads, use regional STS endpoints to avoid leaving the VPC.
- **Trust policy must match exactly.** Capitalization, conditions, principal — one character off and AssumeRole fails.
- **External ID prevents confused deputy** — but only if you set it. Don't skip for cross-account vendor access.
- **Policy size limits** — managed policy 6,144 chars; inline policy varies by entity (2,048-10,240).
- **IAM Access Analyzer cost** — per-region, per-active-analyzer; budget accordingly.

## Cross-references

- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — role view; full IAM posture, SCPs, RCPs, KMS integration
- [`/stacks/aws/saas-architect/`](/stacks/aws/saas-architect/) — ABAC for multi-tenant
- [`/stacks/aws/eks/`](/stacks/aws/eks/) — Pod Identity
- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — execution role
- [`/stacks/aws/ecs/`](/stacks/aws/ecs/) — task role, execution role
- [`/stacks/aws/cloudtrail/`](/stacks/aws/cloudtrail/) — audit trail for Access Analyzer policy generation
- [IAM Identity Center docs](https://docs.aws.amazon.com/singlesignon/)
