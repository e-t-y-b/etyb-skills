---
title: CloudWatch
description: Observability on AWS — Application Signals for APM/SLOs, Container Insights with enriched OTel metadata, EMF for cost-efficient custom metrics, native OTLP ingestion preview Apr 2026.
product:
  name: CloudWatch
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer, backend-architect, system-architect]
  authoritative_url: https://docs.aws.amazon.com/cloudwatch/
  notes: "Application Signals matured 2025; native OTLP preview Apr 2026; cross-account observability to 100K accounts; Logs Insights V2."
---

## What it is

Amazon CloudWatch is AWS's observability stack — metrics, logs, alarms, dashboards, Application Signals (APM/SLOs), Container Insights, Synthetics, Internet Monitor, Network Monitor, RUM, Evidently. Tightly integrated with every AWS service.

Canonical surface: [docs.aws.amazon.com/cloudwatch](https://docs.aws.amazon.com/cloudwatch/).

## When to use

Every AWS workload uses CloudWatch in some form. The interesting decisions:
- **EMF vs PutMetricData** for custom metrics — EMF is cost-efficient.
- **Application Signals vs hand-rolled SLOs** — Application Signals is the AWS-native APM.
- **OTel via [ADOT](https://aws-otel.github.io/)** vs CloudWatch-native — OTel for vendor-neutral instrumentation.
- **Log retention strategy** — never "Never Expire."

## 2025-2026 currency anchors

- **CloudWatch Application Signals** (GA 2024, matured 2025) — APM-shaped service overview, SLOs, service maps, derived from OTel. AWS-native APM.
- **Container Insights with enriched OTel metadata** (preview Apr 2026) — 150+ labels per metric, full pod / workload / cluster context.
- **Native OTel metrics in CloudWatch via OTLP** (preview Apr 2026) — no custom conversion logic; combine custom OTel with 70+ AWS-vended metrics; query with PromQL.
- **Cross-account observability** — up to 100K source accounts share metrics/logs/traces with a monitoring account.
- **Logs Insights V2** — improved query performance, materialized queries.
- **Anomaly Detection on metrics** — ML-based bands replace fixed thresholds for many seasonal metrics.
- **Internet Monitor** — end-user experience monitoring from AWS's view of the internet.
- **Network Monitor** — synthetic network monitoring on AWS network paths (latency, packet loss).
- **Application Signals SLOs** for AWS-native APM with rolling 28-day intervals and burn-rate alerts.

## Patterns

### Application Signals SLOs

```typescript
import * as appsignals from 'aws-cdk-lib/aws-applicationsignals';

new appsignals.Slo(this, 'OrderApiAvailability', {
  name: 'OrderApi-Availability-99.9',
  serviceLevelIndicator: {
    sliMetric: {
      keyAttributes: { Type: 'Service', Name: 'OrderApi', Environment: 'prod' },
      operationName: 'POST /orders',
      metricType: appsignals.SliMetricType.AVAILABILITY,
    },
    metricThreshold: 99.9,
    comparisonOperator: 'GreaterThanOrEqualTo',
  },
  goal: {
    interval: { rollingInterval: { duration: Duration.days(28), durationUnit: 'DAY' } },
    attainmentGoal: 99.9,
    warningThreshold: 50,  // burn-rate warning at 50% budget consumed
  },
});
```

Rolling 28-day intervals, burn-rate alerts at 50% / 75% / 100% budget consumption.

### EMF (Embedded Metric Format)

Don't call `PutMetricData` from Lambda — $0.01 per 1,000 metrics + execution time. Use EMF:

```python
from aws_lambda_powertools import Metrics
from aws_lambda_powertools.metrics import MetricUnit

metrics = Metrics(namespace='OrdersApi', service='orders-api')

@metrics.log_metrics
def handler(event, context):
    metrics.add_metric(name='OrdersCreated', unit=MetricUnit.Count, value=1)
    metrics.add_dimension(name='Tier', value=event['tier'])
```

EMF embeds metrics in structured log lines; CloudWatch extracts them. Essentially free per metric.

### Log retention — never "Never Expire"

```typescript
new logs.LogGroup(this, 'AppLogs', {
  logGroupName: '/aws/app/orders',
  retention: logs.RetentionDays.ONE_MONTH,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});
```

| Tier | Retention | Use case |
|---|---|---|
| Hot | 7-14 days | Active debugging |
| Warm | 30-90 days | Recent troubleshooting, audit |
| Cold (archive) | 1-7 years | Compliance, forensics |

For tier-3 retention, route via subscription filter → Kinesis Firehose → S3 (with Glacier transition). 10x cheaper than CloudWatch indefinite retention.

### Structured JSON logs

```json
{
  "timestamp": "2026-05-14T10:23:45.123Z",
  "level": "INFO",
  "service": "orders-api",
  "version": "1.4.2",
  "requestId": "abc-123",
  "traceId": "1-65b3e4f0-abc123",
  "userId": "u-789",
  "orderId": "o-456",
  "message": "order created",
  "durationMs": 234
}
```

`requestId` correlates to API Gateway access log; `traceId` correlates to [X-Ray](/stacks/aws/x-ray/) segment. Business-context fields (`userId`, `orderId`) are what you'll grep at 3am.

### Logs Insights

```
# p95 latency for an endpoint
fields @timestamp, durationMs
| filter service = "orders-api" and event = "request_complete"
| stats percentile(durationMs, 95) as p95 by bin(5m)
```

Save common queries as Logs Insights saved queries per service.

### Burn-rate alerts

| Burn rate | Long window | Short window | Severity |
|---|---|---|---|
| 14.4x | 1 hour | 5 min | P1 — burning monthly budget in an hour |
| 6x | 6 hours | 30 min | P2 |
| 3x | 24 hours | 2 hours | P3 |
| 1x | 72 hours | 6 hours | P4 |

Both windows must be in burn state simultaneously to fire — prevents single-event spikes from paging.

### Composite alarms

```typescript
const compositeAlarm = new cw.CompositeAlarm(this, 'ServiceDegraded', {
  alarmRule: cw.AlarmRule.allOf(
    cw.AlarmRule.fromAlarm(errorRateAlarm, cw.AlarmState.ALARM),
    cw.AlarmRule.fromAlarm(latencyAlarm, cw.AlarmState.ALARM),
  ),
});
```

Page only when multiple symptoms agree — reduces noise.

### OTel + ADOT

```yaml
# ADOT collector — exporters
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

Instrument with OpenTelemetry, ship to ADOT collector, fan out to CloudWatch + your APM vendor of choice. Avoid double-instrumenting.

### CloudWatch Synthetics

Selenium/Puppeteer canaries on a schedule:
- Critical user journeys (login → search → checkout).
- API endpoint health checks with payload validation.
- Multi-step flow validation from multiple regions.

## Anti-patterns

- **"Never Expire" log retention.** Silent budget killer.
- **PutMetricData from every Lambda invocation.** Use EMF.
- **Custom metrics with unbounded dimensions** (userId, requestId). Cardinality explosion.
- **One alarm per metric.** Page fatigue; use composite alarms.
- **No burn-rate alerting on SLOs.** Threshold alerts miss slow burn.
- **DEBUG logging in production.** Ingestion cost compounds.
- **X-Ray sampling at 100% at high RPS.** Use sampling rules.
- **No runbook URL in alarm description.** On-call gets paged with no guidance.
- **No service ownership of alarms.** Alerts without an owner → no one acts.

## Gotchas

- **Custom metric cost** is $0.30/metric/month after free tier. 1000 custom metrics = $300/mo. Bound dimensions.
- **Logs Insights queries** are charged per data scanned — partition by date in S3 if scanning gigabytes regularly.
- **Vended metrics** (Lambda Invocations, API Gateway Count) are free; custom metrics aren't.
- **Cross-region metric streams** require explicit Metric Streams config.
- **CloudWatch Alarms have a default datapoint horizon** — alarms on slow-fill metrics may never fire if not configured for treat-missing-data.
- **Application Signals SLO count** — costs scale per SLO; pick SLOs that matter.

## Cross-references

- [`/stacks/aws/x-ray/`](/stacks/aws/x-ray/) — distributed tracing
- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — EMF metrics, log retention
- [`/stacks/aws/ecs/`](/stacks/aws/ecs/) — Container Insights
- [`/stacks/aws/eks/`](/stacks/aws/eks/) — Container Insights + OTel
- [`/stacks/aws/sre-engineer/`](/stacks/aws/sre-engineer/) — role view; SLO + alert design
- [ADOT (AWS Distro for OpenTelemetry)](https://aws-otel.github.io/)
- [PowerTools for AWS Lambda](https://docs.powertools.aws.dev/)
