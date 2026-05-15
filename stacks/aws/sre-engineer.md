---
title: SRE Engineer on AWS
description: CloudWatch Application Signals for SLOs, EMF for cost-efficient metrics, OTel via ADOT, FIS chaos engineering, burn-rate alerts, log retention discipline.
role_overlay:
  role: sre-engineer
  stack: aws
  last_verified_on: "2026-05-14"
  products_covered: [cloudwatch, x-ray, cloudtrail, sqs]
---

## Role briefing — sre-engineer on AWS

You own the **SLOs**, the **observability stack** ([CloudWatch](/stacks/aws/cloudwatch/) + Application Signals + [X-Ray](/stacks/aws/x-ray/) + OTel), the **alerting**, the **on-call runbooks**, the **chaos engineering** posture (FIS), the **capacity planning**, and the **incident response** rhythm.

Distinct from the principle-level role: AWS-specific observability matters. CloudWatch Application Signals (GA 2024, matured 2025) is the AWS-native APM. Native OTLP ingestion (preview Apr 2026) eliminates conversion logic. Cross-account observability scales to 100K accounts. The cost discipline is non-trivial — observability is one of the top-3 spend categories on mature AWS workloads.

## Decision frameworks specific to this role's lens on AWS

### Observability stack layers

```
Application tier:     Application Signals (APM, SLOs, service maps, RED)
Container tier:       Container Insights + OTel (150+ enriched labels)
Infrastructure:       CloudWatch Metrics + Alarms + Dashboards
Network:              VPC Flow Logs + Internet Monitor + Network Monitor
Tracing:              X-Ray (cross-account) + ADOT (OpenTelemetry)
Logs:                 CloudWatch Logs (with retention!) + Logs Insights + Security Lake
Cross-account:        CloudWatch Observability Access Manager (up to 100K)
Synthetics:           CloudWatch Synthetics canaries + Network Monitor
Health:               AWS Health Dashboard + Personal Health Events via EventBridge
```

**Default approach**: OpenTelemetry as the instrumentation layer, ADOT as the collector, CloudWatch as storage + visualization (with PromQL via OTel metrics ingestion preview). Hybrid teams ship to both AWS and Grafana / Datadog / New Relic via OTel.

### Custom metrics — EMF vs PutMetricData

| Approach | When |
|---|---|
| **EMF** (Embedded Metric Format) | Default. Essentially free. Embed in log lines via Powertools `metrics`. |
| **PutMetricData** | Only when you can't use EMF (rare). Cost: $0.01 per 1,000 metrics + Lambda execution time. |

### Alarm severity

| Severity | Action |
|---|---|
| **P1** | Page on-call, customer impact ongoing |
| **P2** | Page during business hours, customer impact possible |
| **P3** | Ticket created, no page |
| **P4** | Log + dashboard only |

## Product references

### [CloudWatch](/stacks/aws/cloudwatch/) Application Signals

```typescript
new appsignals.Slo(this, 'OrderApiAvailability', {
  name: 'OrderApi-Availability-99.9',
  serviceLevelIndicator: {
    sliMetric: {
      keyAttributes: { Type: 'Service', Name: 'OrderApi', Environment: 'prod' },
      operationName: 'POST /orders',
      metricType: appsignals.SliMetricType.AVAILABILITY,
    },
    metricThreshold: 99.9,
  },
  goal: {
    interval: { rollingInterval: { duration: Duration.days(28), durationUnit: 'DAY' } },
    attainmentGoal: 99.9,
    warningThreshold: 50,
  },
});
```

Rolling 28-day intervals. Burn-rate alerts at 50% / 75% / 100% budget consumption.

### Burn-rate alerts (multi-window multi-burn-rate)

| Burn rate | Long window | Short window | Severity |
|---|---|---|---|
| 14.4x | 1 hour | 5 min | P1 — burning monthly budget in an hour |
| 6x | 6 hours | 30 min | P2 |
| 3x | 24 hours | 2 hours | P3 |
| 1x | 72 hours | 6 hours | P4 |

Both windows must be in burn state simultaneously — prevents single-event spikes from paging.

### [X-Ray](/stacks/aws/x-ray/) cross-account tracing

Up to 100K source accounts share traces with a monitoring account. First trace copy free; additional copies at standard pricing. Sharing via CloudWatch Observability Access Manager.

Sampling rules:
- Errors + critical paths: 100%.
- Default endpoints: 1-5%.
- Background / cron: 1%.

### Log retention

```typescript
new logs.LogGroup(this, 'AppLogs', {
  logGroupName: '/aws/app/orders',
  retention: logs.RetentionDays.ONE_MONTH,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});
```

**Default retention is "Never Expire" — the silent budget killer.** Set explicitly:
- Hot (7-14 days): active debugging.
- Warm (30-90 days): recent troubleshooting, audit.
- Cold (1-7 years): compliance, forensics — route via subscription filter → Kinesis Firehose → S3 (with Glacier lifecycle), 10x cheaper than CloudWatch indefinite retention.

### OTel via ADOT

```yaml
exporters:
  awsxray:
  awsemf:
    namespace: ContainerInsights
    log_group_name: /aws/containerinsights/{ClusterName}/performance
  otlphttp/cloudwatch:
    endpoint: https://otlp.cloudwatch.us-east-2.amazonaws.com/v1/metrics
    auth:
      authenticator: sigv4auth
```

Native OTLP in CloudWatch (preview Apr 2026) — no custom conversion, combine custom OTel with 70+ AWS-vended metrics, query with PromQL.

### Chaos engineering — AWS FIS

Pre-built scenarios:
- EC2: terminate, reboot, network interruption, CPU/memory stress.
- ECS: stop tasks, throttle CPU.
- EKS: pod failures, node failures, network policies.
- RDS: failover, reboot.
- Network: packet loss, latency injection.
- IAM: revoke permissions (test least-privilege).
- Region: simulated regional impairment (re:Invent 2024).

Game-day discipline:
1. Schedule chaos experiments monthly minimum.
2. Run in staging first; production only after staging passes 3+ times.
3. **Always have a stop condition** (alarm) — auto-halt if customer impact triggers.

## 2025-2026 platform-reset items relevant to this role

- **CloudWatch Application Signals** matured 2025 — APM-shape SLOs, service maps, derived from OTel.
- **Native OTLP in CloudWatch** (preview Apr 2026).
- **Container Insights with enriched OTel metadata** (preview Apr 2026) — 150+ labels per metric.
- **X-Ray cross-account Trace Map** to 100K source accounts.
- **Internet Monitor + Network Monitor** for external/internal network experience.
- **AWS FIS** matured — managed chaos.
- **Resilience Hub** for continuous resilience assessment.
- **Anomaly Detection** on metrics — ML-based bands replace fixed thresholds.

If proposing per-Lambda-function dashboards built by hand, threshold-only alerting with no anomaly detection, X-Ray without cross-account integration, or "let's just use CloudWatch Logs" without considering ingestion cost — your knowledge is behind 2026 best practice.

## Patterns the role applies

### Standard mitigations runbook

- **Lambda hot**: increase reserved concurrency; request quota increase; scale upstream pacer.
- **API Gateway 5xx**: check upstream Lambda errors, downstream DB / cache health.
- **ECS service degraded**: task launch failures, ALB target health, scaling events.
- **EKS pod crashloop**: `kubectl describe pod`, `kubectl logs --previous`, resource limits + image pull.
- **Aurora high CPU**: Performance Insights for top queries; consider read replica routing.
- **DynamoDB throttled**: Contributor Insights for hot key; on-demand or split partition key.
- **ElastiCache evictions**: memory pressure, TTL hygiene, larger node.
- **NAT Gateway saturated**: connection counts; add NAT or move to VPC endpoints.

### Capacity planning — quotas before launch

Common quotas to check:
- Lambda: account concurrency (default 1,000).
- API Gateway: account RPS (default 10K).
- DynamoDB: 40K WCU/RCU per table, 80K per account.
- EBS: volume count + storage per region.
- ECS: tasks per service (default 5000).
- ALB: rules per listener (default 100).
- RDS: instances per region (default 40).
- Bedrock: model TPS (varies, low — 10 TPS for some Claude models per region).

State the quota, the request rate the design implies, and whether a Service Quota increase is needed pre-launch. "We'll request more if we hit limits" is an outage waiting to happen.

### Post-incident discipline

- **Post-mortem in 5 days, no exceptions.**
- **Blameless** — process + system failures, not individuals.
- **Root cause is the chain of decisions and gaps**, not "the deploy."
- **Action items in a tracker** with owners and dates; followed up.
- **Public-facing summary** within 24h if customers impacted.

### Cost-aware observability

- Log group retention explicit.
- Subscription filters route heavy logs to S3, not CloudWatch.
- Custom metric dimensions bounded — keep cardinality low.
- X-Ray sampling rules — don't trace 100% at high RPS.
- Application Signals SLO count — costs scale per SLO.
- Synthetic canary frequency — 5-15 minutes sufficient for most; 1-minute is overkill.

Monthly review: top 10 log groups by ingest, top 10 services by metric cost, X-Ray sample rate per service.

### TDD on observability

- **Alarms as code** — CDK assertions ensure every critical service has alarms.
- **Dashboard parity** — every service deployment includes the standard dashboard.
- **Runbook URL in every alarm definition** — test that it's set.

### Verification on AWS observability

Claims must cite:
- "Application Signals supports availability + latency SLOs" → docs.
- "X-Ray cross-account up to 100K source accounts" → docs.
- "OTLP ingestion preview availability" → preview announcement.

### Debugging incidents

1. **Reproduce the alarm in staging** before changing prod.
2. **One variable at a time.** If you scale the Lambda, restart the cache, and update the IAM role, you don't know what fixed it.
3. **Three-failure escalation** — if three mitigation attempts don't restore service, escalate to senior on-call / engineering manager.
4. **Document the diagnostic in real-time** in the incident channel — the transcript becomes the post-mortem timeline.

### Branch safety on observability

- **No alarms removed without two reviewers.** Disabling an alarm = ignoring a customer issue.
- **Runbook + alarm in same PR.** A new service ships with both, or neither.
- **Dashboard updates merged separately from code changes** — smaller blast radius.

## Cross-references

- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — what the backend emits
- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — pipeline-driven alarms + dashboards
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — audit observability + CloudTrail
- [ADOT (AWS Distro for OpenTelemetry)](https://aws-otel.github.io/)
- [`/stacks/aws/`](/stacks/aws/) — Stack index
