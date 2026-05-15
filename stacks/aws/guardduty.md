---
title: GuardDuty
description: AWS continuous threat detection — Extended Threat Detection (2025) for multi-stage attacks across EC2 + ECS + identity, EKS Runtime Monitoring, EBS Malware Protection.
product:
  name: GuardDuty
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, sre-engineer]
  authoritative_url: https://docs.aws.amazon.com/guardduty/
  notes: "Extended Threat Detection for EC2 + ECS (2025); EKS + Lambda + S3 coverage mature; EBS Malware Protection."
---

## What it is

Amazon GuardDuty is AWS's continuous threat detection — analyzes [CloudTrail](/stacks/aws/cloudtrail/), VPC Flow Logs, DNS logs, EKS audit logs, Lambda invocations, S3 access logs, and EBS volumes for indicators of compromise.

Canonical surface: [docs.aws.amazon.com/guardduty](https://docs.aws.amazon.com/guardduty/).

## When to use

Enable in every AWS account. Delegate admin to the Security Tooling account.

## 2025-2026 currency anchors

- **GuardDuty Extended Threat Detection** — attack-sequence findings for EC2 + ECS tasks (2025). Multistage attack visibility across VMs, containers, identity.
- **GuardDuty Runtime Monitoring** for EKS / ECS — agentless or with the GuardDuty Agent for deeper visibility.
- **EBS Malware Protection** scans EBS volumes for malware.
- **Lambda Protection** — Lambda invocation anomalies.
- **S3 Protection** — S3 unusual activity.

## Patterns

### Coverage layers

GuardDuty detects:
- Suspicious API calls (CloudTrail).
- Compromised IAM credentials (anomalous usage).
- Cryptocurrency mining.
- DNS exfiltration.
- EC2 / Kubernetes / ECS task anomalies.
- S3 unusual activity.
- Lambda anomalies.
- EBS Malware Protection (scan EBS volumes for malware).
- **Extended Threat Detection** (2025) — multi-stage attack sequences.

### Delegation

```bash
aws organizations register-delegated-administrator \
  --account-id 999999999999 \
  --service-principal guardduty.amazonaws.com

aws guardduty enable-organization-admin-account \
  --admin-account-id 999999999999
```

All accounts auto-enroll; centralized finding aggregation.

### Auto-remediation

EventBridge → Lambda for auto-containment on specific findings:

```yaml
EventPattern:
  source:
    - aws.guardduty
  detail-type:
    - "GuardDuty Finding"
  detail:
    severity:
      - { "numeric": [">=", 7.0] }
    type:
      - "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.*"
```

Lambda response: revoke session, isolate instance via SG swap, page on-call.

### Finding triage

Each finding needs an owner, SLA, triage outcome. Routes via [Security Hub](/stacks/aws/security-hub/).

## Anti-patterns

- **GuardDuty disabled.** SCP should make this impossible.
- **Findings ignored.** Each needs an owner.
- **No auto-remediation for high-severity findings.** EventBridge → Lambda for known patterns.
- **Single-account GuardDuty.** Use organization-wide delegated admin.

## Gotchas

- **GuardDuty pricing** is per-account, per-data-source — usage-based.
- **Runtime Monitoring agent** adds overhead; agentless is the default for most.
- **EBS Malware Protection** is opt-in; not default.
- **False positives** happen — tune via suppression rules thoughtfully.
- **Cross-region finding aggregation** requires Security Hub.

## Cross-references

- [`/stacks/aws/security-hub/`](/stacks/aws/security-hub/) — finding aggregation
- [`/stacks/aws/cloudtrail/`](/stacks/aws/cloudtrail/) — primary data source
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — role view; detective controls posture
- [GuardDuty User Guide](https://docs.aws.amazon.com/guardduty/latest/ug/)
