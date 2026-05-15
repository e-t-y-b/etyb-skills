---
title: X-Ray
description: Distributed tracing on AWS — Trace Map across accounts (up to 100K source accounts per monitoring account), sampling rules, integration with ADOT (OpenTelemetry).
product:
  name: X-Ray
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, backend-architect, system-architect]
  authoritative_url: https://docs.aws.amazon.com/xray/
  notes: "Cross-account Trace Map mature; sampling rules well-understood; ADOT (OpenTelemetry) is the modern instrumentation."
---

## What it is

AWS X-Ray is the distributed tracing service — segments + subsegments capture the call graph across Lambda, ECS, EKS, API Gateway, AppSync, Step Functions, and any service instrumented with the X-Ray SDK or [ADOT (OpenTelemetry)](https://aws-otel.github.io/).

Canonical surface: [docs.aws.amazon.com/xray](https://docs.aws.amazon.com/xray/).

## When to use

| Need | Use X-Ray? |
|---|---|
| Trace requests across Lambda + API Gateway + DynamoDB | Yes |
| Identify the slow service in a chain | Yes — Service Map |
| Find the error source (root of error propagation) | Yes — annotations + traces |
| Cross-account architecture tracing | Yes — Trace Map across accounts |
| Local-only debugging | Use SAM local + structured logs |

## 2025-2026 currency anchors

- **Cross-account Trace Map** — up to 100K source accounts share traces with a monitoring account.
- **OpenTelemetry via ADOT** is the canonical instrumentation layer in 2026 — vendor-neutral, future-proof.
- **First trace copy free**; additional copies at standard pricing.
- Sharing via **CloudWatch Observability Access Manager**.

## Patterns

### Instrumentation (Powertools)

```python
from aws_lambda_powertools import Tracer

tracer = Tracer()

@tracer.capture_method
def get_user(user_id: str):
    return db.query(user_id)

@tracer.capture_lambda_handler
def handler(event, context):
    user = get_user(event['userId'])
    return {'statusCode': 200, 'body': json.dumps(user)}
```

Annotations (indexed, filterable in console) and metadata (not indexed, useful for context):

```python
tracer.put_annotation(key='order_tier', value='premium')
tracer.put_metadata(key='order_details', value={'id': order_id, 'total': order_total})
```

### Service Map + Trace Map

- **Service Map**: graph of services + edges, latency + error rate per edge.
- **Trace Map** (newer, cross-account): same view across accounts within a region.

Use the maps to identify the slow service in a chain, the error source (root of error propagation), and unexpected dependencies (calls you didn't know about).

### Sampling rules

X-Ray default: 1 request/second + 5% of additional requests. Fine for low-throughput; under-samples at high RPS.

For high-RPS:
- **Errors + critical paths**: 100%.
- **Default endpoints**: 1-5%.
- **Background / cron**: 1%.

Sampling rules deployed via CDK or console.

### Cross-account tracing

For multi-account architectures with calls crossing accounts, configure cross-account tracing at the platform level — developers don't need to think about it. Set up via CloudWatch Observability Access Manager.

### OpenTelemetry via ADOT

```yaml
# ADOT collector — X-Ray exporter
exporters:
  awsxray:
    region: us-east-2
```

Instrument with OTel, ship to ADOT collector, fan out to X-Ray + your APM vendor. Strategy: avoid double-instrumenting.

## Anti-patterns

- **100% sampling at high RPS.** Use sampling rules.
- **No annotations on traces.** Without indexed fields, you can't filter the trace UI.
- **Custom subsegments for every line of code.** Trace at the integration boundaries (DB calls, HTTP calls, SDK calls), not every function.
- **X-Ray without cross-account integration** in multi-account architectures.
- **Different trace IDs for the same logical request.** Propagate `X-Amzn-Trace-Id` end-to-end.

## Gotchas

- **Sampling is per-segment** — sub-segments inherit. Annotations only persist if the parent segment is sampled.
- **Trace retention is 30 days** by default; can't extend per-trace.
- **Lambda X-Ray cost** — sampled segments are charged; high-volume Lambdas need sampling tuning.
- **Service Map node limit** — large architectures may exceed visualization limits; filter by service tag.
- **OpenTelemetry → X-Ray converter** in ADOT — propagation header `X-Amzn-Trace-Id` is the bridge.

## Cross-references

- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — Powertools tracer
- [`/stacks/aws/cloudwatch/`](/stacks/aws/cloudwatch/) — companion metrics + logs
- [`/stacks/aws/sre-engineer/`](/stacks/aws/sre-engineer/) — role view; tracing strategy
- [ADOT (AWS Distro for OpenTelemetry)](https://aws-otel.github.io/)
