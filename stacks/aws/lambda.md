---
title: Lambda
description: Event-driven compute primitive for short stateless work — handler idioms, SnapStart for cold-start kills, Lambda Web Adapter for FastAPI/Express/Spring Boot, idempotency, and VPC connectivity in 2026.
product:
  name: Lambda
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, devops-engineer, security-engineer, sre-engineer]
  authoritative_url: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
  notes: "SnapStart for Python/.NET/Node added 2024-2025; runtime EOL list shifts quarterly; AWS SDK v2 (JS) is EOL — modular v3 packages only."
---

## What it is

AWS Lambda is the event-driven function runtime — the canonical "scale to zero, scale to thousands instantly" compute primitive on AWS. You write a handler, attach it to an event source (API Gateway, EventBridge, S3, SQS, Kinesis, Step Functions, etc.), and Lambda manages capacity, scaling, runtime, and OS. Pricing is per ms × MB-second.

Canonical surface: [docs.aws.amazon.com/lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html).

## When to use

| Scenario | Use Lambda? |
|---|---|
| Stateless HTTP API, p99 latency tolerates ~250ms-1s cold starts | Yes — Lambda + [API Gateway HTTP API](/stacks/aws/api-gateway/) |
| Event-driven glue (SQS, S3 events, EventBridge, DynamoDB Streams) | Yes — Lambda is the default |
| Workload exceeds 15-minute execution | No — use [ECS](/stacks/aws/ecs/) / [Fargate](/stacks/aws/fargate/) |
| Sustained >100 RPS with idle gaps <5min | Maybe — math it against Fargate; cross-over varies |
| Sustained >1,000 RPS p99-bound | Probably not — request concurrency quota increase first, but evaluate ECS |
| Workload needs full OS/kernel control | No — use [EC2](/stacks/aws/ec2/) |

The most common mistake: **defaulting to Lambda for everything.** Cold starts compound, the 1,000 default concurrency becomes real, and $0-and-pennies pricing breaks down at high RPS. The reverse mistake: defaulting to containers for a 10-RPS spiky webhook receiver that should have stayed on Lambda.

## 2025-2026 currency anchors

- **SnapStart now covers Python 3.12+, Node.js 22+, .NET 8 AOT** — not just Java. Cold starts drop from seconds to ~250ms. Constraints: incompatible with Provisioned Concurrency, EFS, ephemeral storage >512 MB, container images.
- **Lambda Web Adapter** is the canonical way to run FastAPI / Express / Flask / Spring Boot on Lambda without rewriting handlers. Supports response streaming via `AWS_LWA_INVOKE_MODE=response_stream` for TTFB improvements.
- **Lambda+VPC cold-start penalty was retired** (Hyperplane ENI sharing). VPC attach is now ~10ms incremental.
- **AWS SDK v2 (JavaScript) is EOL.** All new Node/TypeScript code uses `@aws-sdk/client-*` modular packages.
- **Lambda runtimes (current):** Python 3.13, Node.js 22, Java 21. **Deprecated:** Python 3.8/3.9, Node.js 16/18, Java 8.
- **Powertools for AWS Lambda** (Python, TypeScript, Java, .NET) is the idiomatic helper library — structured logging, X-Ray tracing, EMF metrics, idempotency, batch utilities, parameters.
- **Cross-region Bedrock inference profiles** are the cleanest way for Lambda to reach Bedrock at scale — see [`/stacks/aws/bedrock/`](/stacks/aws/bedrock/).

## Patterns

### Thin handler + pure business logic

Initialize SDK clients **outside** the handler (reused on warm containers). Keep business logic in pure functions that can be unit-tested without Lambda runtime:

```typescript
// handler.ts — Node 22, SDK v3
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import type { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';

const s3 = new S3Client({});

async function getReportSummary(bucket: string, key: string): Promise<string> {
  const res = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
  return await res.Body!.transformToString();
}

export const handler = async (
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyResultV2> => {
  try {
    const summary = await getReportSummary(process.env.REPORTS_BUCKET!, event.pathParameters!.id!);
    return { statusCode: 200, body: summary };
  } catch (err) {
    console.error('handler failure', { error: err, requestId: event.requestContext.requestId });
    return { statusCode: 500, body: 'Internal error' };
  }
};
```

### Powertools (Python)

```python
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.metrics import MetricUnit

logger = Logger()
tracer = Tracer()
metrics = Metrics(namespace='OrdersApi', service='orders-api')

@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event, context):
    metrics.add_metric(name='OrdersCreated', unit=MetricUnit.Count, value=1)
    ...
```

EMF (Embedded Metric Format) via Powertools is essentially free; never call `PutMetricData` from a hot Lambda path — it costs $0.01/1,000 metrics + execution time. See [CloudWatch](/stacks/aws/cloudwatch/).

### Cold-start fix order

1. **Right-size memory first.** Lambda CPU scales linearly with memory; 1,769 MB = 1 full vCPU. Use [Lambda Power Tuning](https://github.com/alexcasalboni/aws-lambda-power-tuning) to find the cost/latency sweet spot.
2. **SnapStart** for Java 11+, Python 3.12+, .NET 8 AOT, Node.js 22. Sub-second cold starts. Not compatible with Provisioned Concurrency, EFS, ephemeral storage >512 MB, or container images.
3. **Provisioned Concurrency** when SnapStart isn't an option. ~$0.0000041667/provisioned-GB-second on top of invocation cost.
4. **Smaller deployment package** — esbuild for TypeScript, optimal whl for Python. Lambda Layers add a network hop on cold start; measure before assuming they help.

### Idempotency on Lambda

```python
from aws_lambda_powertools.utilities.idempotency import (
    IdempotencyConfig, idempotent, DynamoDBPersistenceLayer,
)

persistence = DynamoDBPersistenceLayer(table_name='IdempotencyStore')
config = IdempotencyConfig(expires_after_seconds=3600)

@idempotent(persistence_store=persistence, config=config)
def handler(event, context):
    process_order(event)
    return {'status': 'processed'}
```

DynamoDB with TTL on the idempotency table; let TTL clean up keys older than your retry window + safety margin. See [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) for the TTL pattern.

### Lambda destinations (preferred over DLQs)

For async invocations, on-success / on-failure destinations (SQS, SNS, EventBridge, another Lambda) are cleaner than DLQs and carry first-class metadata. DLQs still work; Destinations are the new shape.

### Lambda Web Adapter

Run FastAPI / Express / Flask / Spring Boot on Lambda without rewriting handlers:

```dockerfile
FROM public.ecr.aws/docker/library/python:3.13-slim
COPY --from=public.ecr.aws/awsguru/aws-lambda-web-adapter:0.8.4 /lambda-adapter /opt/extensions/
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
ENV PORT=8080
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
```

Use when you have a web framework codebase you don't want to rewrite or when you want response streaming for TTFB.

## Anti-patterns

- **AWS SDK v2 (JS) imports** (`require('aws-sdk')`). SDK v2 is EOL. Use modular v3 packages (`@aws-sdk/client-*`).
- **Synchronous calls in a Lambda handler for things that don't need to be sync.** Push to SQS, return 202.
- **VPC-attached Lambda with NAT for outbound to AWS APIs.** Use VPC endpoints (interface for most services, gateway for S3 and DynamoDB). See [`/stacks/aws/vpc/`](/stacks/aws/vpc/).
- **DLQ-less async work.** Failures silently disappear; always set a destination or DLQ.
- **Layers for everything.** Layers add cold-start time. Bundle directly unless a layer is shared across >5 functions.
- **Hard-coded ARNs / region strings.** Inject via env vars; CDK / SAM does this for you.
- **Hand-rolled SigV4.** Use `@aws-sdk/signature-v4` or the boto3 signer.
- **Catch-all `try / except` that swallows errors.** Log + rethrow.
- **One Lambda doing the work of three.** Single-responsibility: orchestration in [Step Functions](/stacks/aws/step-functions/), work in Lambda.

## Gotchas

- **Lambda payload limits cliff** — 6 MB sync invocation, 256 KB async (SQS, EventBridge). Hitting either silently fails or truncates. Default pattern: drop the payload to [S3](/stacks/aws/s3/), pass a reference.
- **Default account concurrency is 1,000.** Quota-bumpable but ships as a default that surprises teams under load. Request the increase **before** launch.
- **Visibility timeout must exceed Lambda max execution** when consuming from SQS, or the message becomes visible again mid-processing.
- **Lambda + RDS connection exhaustion** — without [RDS Proxy](/stacks/aws/rds/), thousands of Lambda containers will exhaust the DB's connection pool. Aurora DSQL does *not* need RDS Proxy — it multiplexes natively.
- **Cross-AZ data transfer ($0.01/GB each way)** compounds when Lambdas in AZ-a chat with RDS in AZ-b. Pin Lambda subnets to the same AZs as the workload it serves.
- **`re:Invent announcement ≠ GA.`** Check the AWS What's New page for the exact GA date and regional rollout before betting an architecture on a re:Invent name.

## Cross-references

- [`/stacks/aws/api-gateway/`](/stacks/aws/api-gateway/) — the HTTP front door for Lambda
- [`/stacks/aws/step-functions/`](/stacks/aws/step-functions/) — orchestrate Lambda invocations as workflows
- [`/stacks/aws/eventbridge/`](/stacks/aws/eventbridge/) — event-driven Lambda triggers and Pipes
- [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) — idempotency store, single-table design
- [`/stacks/aws/vpc/`](/stacks/aws/vpc/) — VPC endpoints + NAT considerations for Lambda
- [`/stacks/aws/cloudwatch/`](/stacks/aws/cloudwatch/) — EMF metrics, log retention, alarms
- [`/stacks/aws/x-ray/`](/stacks/aws/x-ray/) — tracing Lambda calls
- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — role view; handler patterns + retry shape
- [Lambda Quotas](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html) — canonical limits page
