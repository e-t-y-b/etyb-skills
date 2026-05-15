---
title: CloudTrail
description: AWS audit log — org-wide trail in management account, S3 + Object Lock for immutable retention, CloudTrail Lake for SQL queries over events, integration with IAM Access Analyzer for least-privilege policy generation.
product:
  name: CloudTrail
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, system-architect, devops-engineer, fintech-architect]
  authoritative_url: https://docs.aws.amazon.com/cloudtrail/
  notes: "Mature audit trail surface; CloudTrail Lake SQL queries; data events expensive at scale (per-object API call cost)."
---

## What it is

AWS CloudTrail is the audit log for AWS API calls — every control-plane operation (and optionally data-plane operations via "data events") is captured. It's the audit-log truth for the AWS environment.

Canonical surface: [docs.aws.amazon.com/cloudtrail](https://docs.aws.amazon.com/cloudtrail/).

## When to use

CloudTrail is mandatory in every production AWS account. Decisions:
- **Org-wide trail** in management account (default for multi-account orgs).
- **Data events** — selectively enable; expensive at scale.
- **CloudTrail Lake** — SQL queries vs Athena on the S3 trail.
- **S3 Object Lock** on the destination — immutable retention for compliance.

## 2025-2026 currency anchors

- **CloudTrail Lake** — SQL queries over trail data, no separate Athena setup.
- **Org-wide trail** in management account, configured for all regions, all accounts.
- **Log file integrity validation** enabled (detects tampering).
- **S3 destination in Log Archive account**; S3 Object Lock for immutable retention.
- **CloudWatch Logs subscription** for real-time alerting on suspicious events.
- **IAM Access Analyzer Policy Generation** consumes CloudTrail to derive least-privilege policies — see [`/stacks/aws/iam/`](/stacks/aws/iam/).

## Patterns

### Standard configuration

```typescript
import * as cloudtrail from 'aws-cdk-lib/aws-cloudtrail';

new cloudtrail.Trail(this, 'OrgTrail', {
  isMultiRegionTrail: true,
  isOrganizationTrail: true,
  includeGlobalServiceEvents: true,
  enableFileValidation: true,
  bucket: logArchiveBucket,  // In Log Archive account
  cloudWatchLogGroup: logGroup,  // For real-time alerting
  cloudWatchLogsRetention: logs.RetentionDays.ONE_MONTH,
});
```

What this gets right:
- Multi-region + organization-wide capture.
- Log file integrity validation (tamper detection).
- Centralized in a separate Log Archive account.
- CloudWatch Logs subscription for real-time alerting.

### Account topology — Log Archive account

The Log Archive account is **write-only from the rest of the org** — production accounts ship logs but cannot read or modify the archive. SCPs enforce.

### S3 Object Lock for immutable retention

```json
{
  "ObjectLockEnabled": "Enabled",
  "Rule": {
    "DefaultRetention": {
      "Mode": "COMPLIANCE",
      "Days": 2555
    }
  }
}
```

COMPLIANCE mode: no one (including root) can delete during retention. Use for SOX, financial audit, HIPAA 6-year retention.

### CloudTrail Lake

```sql
SELECT eventTime, userIdentity.arn, eventName, requestParameters
FROM <event-data-store-id>
WHERE eventTime > '2026-05-01'
  AND eventName = 'AssumeRole'
  AND userIdentity.type = 'AssumedRole'
ORDER BY eventTime DESC
LIMIT 100
```

Native SQL queries over trail data. Use over Athena-on-trail-S3 when you query CloudTrail frequently.

### Data events vs management events

| Event class | What | Cost |
|---|---|---|
| **Management events** | Control-plane (create, modify, delete) | First copy free; second copy paid |
| **Data events** | Data-plane operations (S3 GetObject, Lambda Invoke, DynamoDB Query) | Per-event cost; expensive at scale |

Default: management events on; data events selectively enabled for high-sensitivity resources.

### Real-time alerting

CloudWatch Logs subscription → metric filter → alarm. Common targets:
- **Root user activity** — should never happen; alarm immediately.
- **IAM policy changes outside the pipeline.**
- **CloudTrail Stop/Delete attempts** (also blocked by SCP).
- **KMS key deletion scheduling.**

## Anti-patterns

- **CloudTrail off** in any account. SCP at OU level should make this impossible.
- **No log file integrity validation.** Tampering goes undetected.
- **Trail destination in the workload account.** Centralize in Log Archive.
- **No Object Lock on long-retention buckets.** Logs can be deleted.
- **Data events on every S3 bucket.** Expensive; selectively enable.
- **No real-time alerting on critical events.** Logs only-archived means the alarm doesn't fire.

## Gotchas

- **CloudTrail event delivery latency** is typically 5-15 minutes — not real-time.
- **Data events** can dominate trail cost at scale. Selectively enable for sensitive buckets / functions.
- **CloudTrail Lake billing** is per ingested event + storage; can be substantial for high-volume accounts.
- **Cross-account access to trail S3 bucket** requires bucket policy + KMS key policy alignment.
- **CloudTrail captures `eventTime` in UTC** — verify timezone in queries.

## Cross-references

- [`/stacks/aws/iam/`](/stacks/aws/iam/) — Access Analyzer policy generation consumes CloudTrail
- [`/stacks/aws/s3/`](/stacks/aws/s3/) — trail destination, Object Lock
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — role view; full audit posture
- [`/stacks/aws/fintech-architect/`](/stacks/aws/fintech-architect/) — audit trail compliance for financial workloads
- [CloudTrail Lake](https://docs.aws.amazon.com/cloudtrail/latest/userguide/cloudtrail-lake.html)
