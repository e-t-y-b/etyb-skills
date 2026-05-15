---
title: KMS
description: AWS Key Management Service — customer-managed CMKs for compliance, multi-region keys for global tables, key policies are the source of truth (not IAM), grants for delegated service usage.
product:
  name: KMS
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer, backend-architect, fintech-architect]
  authoritative_url: https://docs.aws.amazon.com/kms/
  notes: "Mature; multi-Region keys + XKS evolving for sovereign use cases; key policies remain the source of truth, not IAM."
---

## What it is

AWS KMS is the managed key management service — encrypt and decrypt data (envelope encryption with data keys), manage key rotation, audit usage via CloudTrail. Integrates with every AWS storage / data service.

Canonical surface: [docs.aws.amazon.com/kms](https://docs.aws.amazon.com/kms/).

## When to use

| Need | Use KMS? |
|---|---|
| Encrypt data at rest in AWS storage (S3, DynamoDB, RDS, EBS, EFS, etc.) | Yes — SSE-KMS |
| Encrypt sensitive payloads in transit between services | Yes — envelope encryption with data keys |
| Compliance requirement for customer-managed keys | Yes — CMK with rotation enabled |
| BYOK (Bring Your Own Key) | Yes — CMK with imported key material |
| HSM-grade isolation | Yes — KMS with CloudHSM-backed keys, or AWS Payment Cryptography for payment crypto |
| Sovereign / external HSM | Yes — External Key Store (XKS) |

## 2025-2026 currency anchors

- **Multi-region keys** — same key ID across regions, useful for DynamoDB Global Tables, cross-region S3 replication, multi-region DR.
- **AWS Payment Cryptography** — managed HSM-backed crypto operations for payment processing (DUKPT, PIN block translation, EMV).
- **XKS (External Key Store)** — keep key material in HSM outside AWS; AWS calls out to use it. Niche; FedRAMP / sovereign compliance.
- **Key rotation** — automatic yearly default + manual rotation for rapid rotation events.
- **Account-level S3 default encryption** uses SSE-S3 unless overridden; default to SSE-KMS for production.

## Patterns

### Key topology

| Key type | Use for |
|---|---|
| **AWS-owned keys** | Default for many services; AWS rotates, no visibility. Use when no compliance need. |
| **AWS-managed keys** (`aws/*` aliases) | Per-service managed keys; visible in your account, AWS rotates. |
| **Customer-managed keys (CMK)** | Full control: key policy, rotation, cross-account, grants. **Required for HIPAA/PCI/most compliance.** |
| **CMK with imported key material** | BYOK for regulatory requirements. |
| **External keys (XKS)** | Key material in HSM outside AWS; FedRAMP / sovereign / specific regulatory regimes. |

**Default for production data**: customer-managed CMK with key rotation enabled.

### Key policies vs IAM policies

KMS has both. **The key policy is the source of truth** for who can use a key. IAM policies grant additional permissions only if the key policy delegates to IAM (the typical `"Principal": {"AWS": "arn:aws:iam::ACCOUNT:root"}` does this).

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnableIAMPermissions",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::123456789012:root" },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowAppRole",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::123456789012:role/AppRole" },
      "Action": ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"],
      "Resource": "*"
    },
    {
      "Sid": "AllowAppRoleGrants",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::123456789012:role/AppRole" },
      "Action": "kms:CreateGrant",
      "Resource": "*",
      "Condition": { "Bool": { "kms:GrantIsForAWSResource": "true" } }
    }
  ]
}
```

### Multi-region keys

```typescript
const primaryKey = new kms.Key(this, 'AppKey', {
  alias: 'alias/app/data',
  description: 'Data encryption for app',
  enableKeyRotation: true,
  multiRegion: true,
  pendingWindow: Duration.days(7),  // KMS minimum
});
```

Useful for global DynamoDB tables, cross-region S3 replication, multi-region disaster recovery — same key ID across regions.

### Grants

Scoped, temporary, revokable permissions. AWS services (EBS, S3, Lambda, etc.) request grants when they need to use your key. Grants are how cross-service key usage works without bloating the key policy.

### Encryption at rest defaults

| Service | Encryption |
|---|---|
| [S3](/stacks/aws/s3/) | Bucket policy: `aws:kms` for sensitive data; SSE-S3 the platform default |
| [EBS](/stacks/aws/ec2/) | Account-level default-encryption on; every new volume KMS-encrypted |
| [RDS / Aurora](/stacks/aws/rds/) | KMS at create time; can't add later (must do snapshot + restore) |
| [DynamoDB](/stacks/aws/dynamodb/) | KMS at table create |
| Lambda env vars | KMS automatic; CMK for secrets |
| [Secrets Manager](/stacks/aws/secrets-manager/) | Always KMS-encrypted |
| CloudWatch Logs | KMS optional; required for compliance |

For stateful services, **encrypt from creation** — retrofitting requires data migration.

### Pending deletion window

KMS minimum pending window is 7 days; default 30. Set deliberately:
- Production keys: 30 days (recovery window if deletion was a mistake).
- Test / dev: 7 days OK.

Schedule deletion, don't immediate. If you need immediate, data on that key is unrecoverable — verify nothing depends on it.

## Anti-patterns

- **AWS-owned keys for compliance data.** Always CMK with rotation.
- **`AdministratorAccess` on KMS** — wildcard `kms:*` on the key policy is over-permissive.
- **Hand-rolled encryption in application code** when KMS+envelope-encryption fits.
- **Single-region keys for multi-region workloads** — use multi-region keys.
- **No CloudTrail audit** of KMS usage. KMS is a critical security primitive; audit it.
- **KMS key deletion without the pending window.** No 0-day deletion.
- **Cross-account access via key policy without scoping.** Always condition on `aws:PrincipalArn` or `aws:SourceAccount`.
- **Forgetting key rotation.** Enable automatic yearly rotation by default.

## Gotchas

- **Key policies are mandatory** — KMS requires a key policy; can't be empty.
- **`kms:Decrypt` is the bypass action** — if granted, holder can decrypt anything that key encrypted. Audit carefully.
- **KMS API call cost** — $0.03 per 10K calls. High-RPS workloads accumulating decrypts can spend $$$; consider data-key caching with rotation.
- **Cross-region key access doesn't exist for single-region keys.** Replicas of multi-region keys are needed.
- **KMS quotas per region** — request rate caps; check Service Quotas.
- **HSM-backed key cost** is higher (~$1/key/mo) but required for some compliance regimes.

## Cross-references

- [`/stacks/aws/s3/`](/stacks/aws/s3/) — SSE-KMS encryption
- [`/stacks/aws/rds/`](/stacks/aws/rds/) — RDS / Aurora encryption at rest
- [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) — DDB encryption at rest
- [`/stacks/aws/secrets-manager/`](/stacks/aws/secrets-manager/) — secrets are always KMS-encrypted
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — role view; key policy + RCP integration
- [`/stacks/aws/fintech-architect/`](/stacks/aws/fintech-architect/) — HSM-backed keys for PCI
- [AWS Payment Cryptography](https://docs.aws.amazon.com/payment-cryptography/)
