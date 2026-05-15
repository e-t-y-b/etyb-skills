---
title: Backend Architect on AWS
description: Lambda idioms, API Gateway / AppSync / ALB choice, Step Functions JSONata, EventBridge Pipes, DynamoDB SDK patterns, SDK v3 idioms, SigV4. The AWS-specific shape of backend work in 2026.
role_overlay:
  role: backend-architect
  stack: aws
  last_verified_on: "2026-05-14"
  products_covered: [lambda, ecs, fargate, api-gateway, step-functions, eventbridge, sqs, dynamodb, aurora, elasticache, secrets-manager, s3, bedrock, cloudwatch, x-ray]
---

## Role briefing — backend-architect on AWS

You're writing the [Lambda](/stacks/aws/lambda/) handlers, [ECS](/stacks/aws/ecs/) task definitions, [Step Functions](/stacks/aws/step-functions/) state machines, [EventBridge](/stacks/aws/eventbridge/) rules, [DynamoDB](/stacks/aws/dynamodb/) single-table designs, [API Gateway](/stacks/aws/api-gateway/) integrations, and SDK calls — not infra-as-code (that's [devops-engineer](/stacks/aws/devops-engineer/)), not the IAM posture ([security-engineer](/stacks/aws/security-engineer/)).

Distinct from the principle-level role: on AWS, the SDK families, idioms, and primitives that matter in 2026 are different from 2023 muscle memory. SDK v3 modular packages, Powertools, Converse API, Pipes, JSONata + Variables, SnapStart for Python/.NET/Node — your training is stale if you haven't internalized these.

## Decision frameworks specific to this role's lens on AWS

### Compute primitive for backend code

See [`/stacks/aws/system-architect/`](/stacks/aws/system-architect/) for the architectural matrix. As backend-architect, you defer to the architect call, then write handlers idiomatic to the chosen primitive:
- **Lambda** → thin handler + pure business logic, Powertools, SnapStart-aware.
- **ECS / Fargate** → containerized service, ARM64 default, Service Connect for east-west.
- **EKS** → containerized pod, Pod Identity for AWS access.
- **Step Functions** → declarative state machine, JSONata for new state machines, Lambda for tasks.

### HTTP surface

| Surface | Auth | Best for |
|---|---|---|
| **API Gateway HTTP API** | JWT, Cognito, Lambda authorizer, IAM | New REST APIs, cost-sensitive |
| **API Gateway REST API** | All HTTP API + API keys, usage plans | API products with keys, request validation |
| **API Gateway WebSocket** | IAM, Lambda authorizer | Bidirectional real-time |
| **AppSync** | API key, Cognito, IAM, OIDC, Lambda | GraphQL, subscriptions, multi-source |
| **Lambda URLs** | IAM or NONE | Internal endpoints, webhooks |
| **ALB + Lambda target** | OIDC, Cognito | Mixing Lambda + container behind one LB |

Default for new public REST APIs in 2026: **API Gateway HTTP API + Lambda + Cognito or JWT authorizer**. Upgrade to REST API only for usage plans, API keys, or request validation models.

### Queue / topic / stream

| Need | Use | Why |
|---|---|---|
| Decouple producer / consumer, at-least-once | [SQS Standard](/stacks/aws/sqs/) | Simple, scalable, cheap |
| Strict FIFO ordering within partition | SQS FIFO | Up to 3000 msg/sec/group |
| Pub/sub fan-out without ordering | SNS Standard | Fan to 12.5M endpoints |
| Ordered stream with replay | Kinesis Data Streams | Multi-consumer, 7-day default retention |
| Long retention + Kafka semantics | MSK / MSK Serverless | Industry-standard, ecosystem |
| Routing with rules across services/accounts | [EventBridge](/stacks/aws/eventbridge/) | Schema-aware, cross-account, partner events |

## Product references

### [Lambda](/stacks/aws/lambda/)

Thin handler + pure business logic; SDK clients outside the handler; Powertools (Python, TypeScript, Java, .NET) for logger/tracer/metrics/idempotency. **AWS SDK v2 (JS) is EOL** — modular v3 packages only. Cold-start fix order: right-size memory → SnapStart (Python/Java/.NET/Node) → Provisioned Concurrency → smaller deployment package.

### [API Gateway](/stacks/aws/api-gateway/)

HTTP API default for new builds (~3.5x cheaper than REST). JWT authorizer for OIDC IdPs including Cognito. Throttling defaults (10K RPS account-level) need quota increase pre-launch for high-RPS designs.

### [Step Functions](/stacks/aws/step-functions/)

**JSONata + Variables** (re:Invent 2024) replace ResultPath/InputPath/OutputPath/Parameters for new state machines — incrementally adoptable per state. **TestState API GA Mar 2026** for unit tests before deploy. Standard for long-running; Express only when measured >100 starts/sec or unit economics demand it.

### [EventBridge](/stacks/aws/eventbridge/)

**One custom bus per bounded context** for organic isolation. **Pipes** eliminate Lambda-as-glue for `source → filter → enrich → target` — SQS → Step Functions, DynamoDB Streams → EventBridge, Kinesis → Lambda. Schema Registry auto-discovers schemas.

### [DynamoDB](/stacks/aws/dynamodb/)

`DynamoDBDocumentClient` auto-marshals; never write `{ S: 'value' }` shapes. **Optimistic concurrency via `ConditionExpression` + version attribute** — only reliable way to prevent last-writer-wins. **Single-table design**, GSI strategy from access patterns, sparse indexes, hot-partition mitigation via hierarchical timestamps or write sharding. **Zero-ETL to OpenSearch / Redshift** replaces custom replication Lambdas.

### [Aurora DSQL](/stacks/aws/aurora/)

Postgres-compatible, multi-region active-active. Connection pattern is different — **no RDS Proxy in front of DSQL** (multiplexes natively). Tokens are short-lived (15-min default); refresh per connection. **Retry on `serialization_failure`** is mandatory for SERIALIZABLE workloads.

### [ElastiCache (Valkey)](/stacks/aws/elasticache/)

Net-new caches: Valkey (33% cheaper than Redis OSS, wire-compatible). Set `enableOfflineQueue: false` and small `maxRetriesPerRequest` — fail open to the DB when cache is down, don't queue commands forever.

### [Secrets Manager](/stacks/aws/secrets-manager/)

Never plaintext credentials. Powertools `get_secret` caches for 5 min by default. For high-RPS Lambda, the AWS Parameters and Secrets Lambda Extension caches via a local HTTP endpoint.

### [Bedrock](/stacks/aws/bedrock/)

Use **Converse API** (not legacy `invoke_model`) for new code. Cross-region inference profiles (`us.` prefix) reduce throttling. Guardrails on every customer-facing model call.

### [CloudWatch](/stacks/aws/cloudwatch/) + [X-Ray](/stacks/aws/x-ray/)

**EMF for custom metrics** — don't call PutMetricData. Powertools `metrics`. Structured JSON logs with `requestId`, `traceId`, business context (`userId`, `orderId`). Tracer annotations for filterable indexed fields.

## 2025-2026 platform-reset items relevant to this role

- **SnapStart for Python/Node/.NET** (not just Java) — cold starts to ~250ms.
- **Lambda Web Adapter** — run FastAPI/Express/Flask/Spring Boot on Lambda without rewriting handlers.
- **Step Functions JSONata + Variables** + **TestState API**.
- **EventBridge Pipes** for Lambda glue replacement.
- **ECS Express Mode** for "container to HTTPS in one step."
- **HTTP API** as default API Gateway choice.
- **DynamoDB Zero-ETL** to OpenSearch / Redshift.
- **Aurora DSQL** changes connection patterns.
- **Lambda Runtimes (current)**: Python 3.13, Node.js 22, Java 21.
- **AWS SDK v2 (JS) is EOL** — `@aws-sdk/client-*` modular packages.

If you're proposing AWS SDK v2 (JS) imports, ResultPath chains in new Step Functions, Copilot CLI for new services, Lambda glue for SQS→Step Functions, Java-only for SnapStart — your training is stale.

## Patterns the role applies

### TDD on Lambda

```typescript
import { mockClient } from 'aws-sdk-client-mock';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { handler } from './handler';

const s3Mock = mockClient(S3Client);

test('handler returns summary on success', async () => {
  s3Mock.on(GetObjectCommand).resolves({ Body: stream('summary text') });
  const res = await handler({ pathParameters: { id: 'abc' }, requestContext: { requestId: 'req-1' } } as any);
  expect(res).toEqual({ statusCode: 200, body: 'summary text' });
});
```

Red → green → refactor. Use `aws-sdk-client-mock` (Node) or `moto` (Python).

### Idempotency on every external write

```python
@idempotent(persistence_store=persistence, config=IdempotencyConfig(expires_after_seconds=3600))
def handler(event, context):
    process_order(event)
```

Assume retries; design for duplicates. DynamoDB with TTL is the canonical store.

### Retry semantics

SDK v3 (JS), boto3, aws-sdk-go-v2 default to **adaptive retry mode**. For non-AWS APIs: exponential backoff with **mandatory jitter**.

### Connection pooling

| Scenario | Pooling |
|---|---|
| Lambda → RDS / Aurora (non-DSQL) | **RDS Proxy** |
| Lambda → Aurora DSQL | No proxy; DSQL multiplexes natively |
| Lambda → DynamoDB | SDK internal pool |
| Lambda → ElastiCache | Client pool in execution context |
| ECS / EKS → RDS | App-level pool (PgBouncer sidecar) |
| ECS / EKS → DSQL | App-level pool; DSQL handles more connections than RDS |

### Verification on backend AWS

Claims must cite docs. Examples:
- "Lambda max payload is 6 MB sync, 256 KB async" → Lambda Quotas page.
- "API Gateway HTTP API costs $1/M requests" → API Gateway pricing.
- "DynamoDB on-demand has 40K WCU / 40K RCU per-table default" → DynamoDB Service Quotas.

### Debugging on AWS

1. Reproduce locally first — SAM local, LocalStack, mocked SDK.
2. CloudWatch Logs Insights + X-Ray. Filter by `requestId`.
3. One variable at a time.
4. Three-failure escalation — if three hypotheses fail, stop changing code and gather data.

## Cross-references

- [`/stacks/aws/system-architect/`](/stacks/aws/system-architect/) — architectural shape
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — DynamoDB / Aurora design depth
- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — CDK + pipeline integration
- [`/stacks/aws/sre-engineer/`](/stacks/aws/sre-engineer/) — observability strategy
- [`/stacks/aws/`](/stacks/aws/) — Stack index
