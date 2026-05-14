---
role: backend-architect
stack: aws
last_verified_on: "2026-05-14"
---

# AWS Overlay — backend-architect

You are backend-architect on an AWS engagement. You're writing the Lambda handlers, ECS task definitions, Step Functions state machines, EventBridge rules, DynamoDB single-table designs, API Gateway integrations, and SDK calls — not infra-as-code (that's devops-engineer), not the IAM posture (security-engineer). This overlay covers the AWS-specific idioms you must get right in 2026.

**Currency:** AWS as of **2026-Q2**. The SDK v3 (JS), boto3, aws-sdk-go-v2, aws-sdk-rust are the supported SDK families; SDK v2 (JS) is EOL.

## What changed in 2025-2026 that older training data misses

- **Lambda SnapStart for Python (3.12+), Node.js (22+), .NET 8 AOT** — not just Java. Cold starts drop from seconds to ~250ms. Constraints: incompatible with Provisioned Concurrency, EFS, ephemeral storage >512 MB, container images.
- **Lambda Web Adapter** is the canonical way to run FastAPI / Express / Flask / Spring Boot on Lambda without rewriting handlers. Supports response streaming for TTFB improvements.
- **Step Functions JSONata + Variables** (re:Invent 2024) replace ResultPath/InputPath/OutputPath/Parameters. Incrementally adoptable per state. **TestState API GA Mar 2026** — unit-test individual states before deploying state machines.
- **EventBridge Pipes** eliminates Lambda glue for "source → filter → enrich → target" patterns. SQS→Step Functions, DynamoDB Streams→EventBridge, Kinesis→Lambda with enrichment.
- **ECS Express Mode** (Nov 2025) — image to HTTPS in seconds. Auto-provisions Fargate service, ALB with TLS, autoscaling, monitoring. Replaces Copilot CLI (EOL June 2026).
- **API Gateway HTTP API** is the default for new HTTP APIs in 2026; REST API only when you need usage plans, request validation models, or full API key management. HTTP API ≈ 3.5x cheaper at the same RPS.
- **DynamoDB zero-ETL to OpenSearch / Redshift** (2024-2025) eliminates the custom replication Lambda for search/analytics over DynamoDB data.
- **Aurora DSQL** (GA May 2025) — Postgres-compatible, serverless, multi-region active-active. The connection model is fundamentally different (no `MAX_CONNECTIONS` — connection pooling at the SQL layer, not the proxy layer).
- **Lambda Runtimes**: Python 3.13, Node.js 22, Java 21 are the modern supported runtimes. Python 3.8/3.9, Node.js 16/18, Java 8 are deprecated.
- **AWS SDK v2 (JavaScript) is EOL.** All new Node/TypeScript code uses **`@aws-sdk/client-*`** modular packages.

If you're proposing AWS SDK v2 (JS) imports, ResultPath chains in new Step Functions, Copilot CLI for new services, AWS Lambda glue for SQS→Step Functions, Java-only for SnapStart — your training is stale.

## Lambda idioms — the patterns that actually scale

### Handler structure (Node.js, TypeScript)

```typescript
// handler.ts — modern Lambda handler shape (Node 22, SDK v3)
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import type { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';

// Initialize SDK clients OUTSIDE the handler (reused across invocations on warm containers).
const s3 = new S3Client({});

// Pure business logic — testable without Lambda runtime.
async function getReportSummary(bucket: string, key: string): Promise<string> {
  const cmd = new GetObjectCommand({ Bucket: bucket, Key: key });
  const res = await s3.send(cmd);
  return await res.Body!.transformToString();
}

export const handler = async (
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyResultV2> => {
  try {
    const summary = await getReportSummary(
      process.env.REPORTS_BUCKET!,
      event.pathParameters!.id!,
    );
    return { statusCode: 200, body: summary };
  } catch (err) {
    console.error('handler failure', { error: err, requestId: event.requestContext.requestId });
    return { statusCode: 500, body: 'Internal error' };
  }
};
```

Three things this gets right:

1. **SDK client outside handler** — reused on warm invocations, avoids re-construction cost.
2. **Pure business logic separated from handler** — `getReportSummary` is unit-testable without Lambda runtime mocking.
3. **Errors logged with `requestId`** — correlate logs to X-Ray traces and API Gateway access logs.

### Handler structure (Python)

```python
# handler.py — Python 3.13, Powertools for AWS Lambda
import os
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.utilities.typing import LambdaContext
import boto3

logger = Logger()
tracer = Tracer()
metrics = Metrics()

# Module-level — reused across invocations
s3 = boto3.client('s3')

@tracer.capture_method
def get_report_summary(bucket: str, key: str) -> str:
    res = s3.get_object(Bucket=bucket, Key=key)
    return res['Body'].read().decode('utf-8')

@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: dict, context: LambdaContext) -> dict:
    try:
        summary = get_report_summary(
            os.environ['REPORTS_BUCKET'],
            event['pathParameters']['id'],
        )
        metrics.add_metric(name='ReportFetched', unit='Count', value=1)
        return {'statusCode': 200, 'body': summary}
    except Exception:
        logger.exception('handler failure')
        return {'statusCode': 500, 'body': 'Internal error'}
```

**AWS Lambda Powertools** (Python, TypeScript, Java, .NET) is the idiomatic helper library — structured logging, X-Ray tracing, embedded metrics format (EMF) for CloudWatch metrics without extra API calls. Use it; don't roll your own.

### Cold starts: when to care, how to fix

**Care about cold starts when:**
- User-facing synchronous request path with p99 latency SLO.
- Spiky traffic with idle gaps (Lambda containers expire after ~5-15 min of idle).

**Don't care:**
- Async (SQS, EventBridge, S3 events) — extra 500ms is invisible.
- Batch (Kinesis, DynamoDB Streams) — first invocation in batch warms; rest are warm.

**Fix order (cheapest first):**
1. **Right-size memory.** Lambda CPU scales linearly with memory. 1769 MB = 1 full vCPU. Most cold start fixes are memory bumps. Use [Lambda Power Tuning](https://github.com/alexcasalboni/aws-lambda-power-tuning) to find the cost/latency sweet spot.
2. **SnapStart** for Java 11+/Java 17/Java 21, Python 3.12+, .NET 8 AOT, Node.js 22. Sub-second cold starts. **Not compatible** with Provisioned Concurrency, EFS, ephemeral storage >512 MB, container images. Test priming strategies (Invoke Priming for critical endpoints; Class Priming for class loading without business-logic execution).
3. **Provisioned Concurrency** when SnapStart isn't an option and predictable warm capacity is needed. Costs ~$0.0000041667 per provisioned GB-second, on top of invocation cost. Use auto-scaling Provisioned Concurrency with Application Auto Scaling.
4. **Smaller deployment package.** Tree-shake. Bundle dependencies (esbuild for TS, optimal whl for Python). Lambda Layers help on shared deps but add a network hop on cold start — measure before assuming they help.
5. **Lambda SnapStart + connection priming** — pre-establish DB connections, prefetch config, prewarm HTTP clients during snapshot creation. Persists into restored snapshots.

### Lambda + VPC: the cold-start penalty is *gone*, but data transfer still matters

Lambda+VPC cold-start penalty was retired (Hyperplane ENI sharing). VPC attach is now ~10ms incremental. **But:**
- Lambda in a VPC + outbound internet = NAT Gateway = $0.045/hr + $0.045/GB processed. For Lambda-only architectures, **use VPC endpoints** (interface for most services, gateway for S3 and DynamoDB) instead of NAT.
- Cross-AZ data transfer ($0.01/GB each way) compounds when Lambdas in AZ-a chat with RDS in AZ-b. Pin Lambda subnets to the same AZs as the workload it serves.

### Lambda Web Adapter — running Express/FastAPI/Flask/Spring Boot on Lambda

```dockerfile
# Lambda Web Adapter with FastAPI + uvicorn
FROM public.ecr.aws/docker/library/python:3.13-slim
COPY --from=public.ecr.aws/awsguru/aws-lambda-web-adapter:0.8.4 /lambda-adapter /opt/extensions/
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
ENV PORT=8080
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
```

Use when:
- Existing web framework code you don't want to rewrite as raw Lambda handlers.
- Response streaming for TTFB (set `AWS_LWA_INVOKE_MODE=response_stream`).
- Lift-and-shift to Lambda for cost or scaling reasons.

Don't use when:
- The traffic profile genuinely fits raw Lambda handlers (Web Adapter adds a small overhead).
- You need execution >15 min (use Fargate).

### Lambda destinations + DLQ

For async invocations (SQS, EventBridge, S3 events, etc.):
- **On Success / On Failure destinations**: SQS, SNS, EventBridge, or another Lambda. Cleaner than DLQs; first-class metadata.
- **DLQ (SQS or SNS)**: legacy pattern, still works, but Destinations is preferred for new code.
- **Max retries**: 2 by default for async; configurable. Use idempotency tokens — Lambda may invoke duplicates.

### Idempotency on Lambda

```python
# AWS Lambda Powertools idempotency
from aws_lambda_powertools.utilities.idempotency import (
    IdempotencyConfig, idempotent, DynamoDBPersistenceLayer,
)

persistence = DynamoDBPersistenceLayer(table_name='IdempotencyStore')
config = IdempotencyConfig(expires_after_seconds=3600)

@idempotent(persistence_store=persistence, config=config)
def handler(event, context):
    # Lambda may invoke duplicates on retry — this decorator dedupes by event hash
    process_order(event)
    return {'status': 'processed'}
```

DynamoDB with TTL on the idempotency table; let TTL clean up keys older than your retry window + safety margin.

## ECS / Fargate idioms

### Task definition essentials

```json
{
  "family": "api-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "runtimePlatform": {
    "cpuArchitecture": "ARM64",
    "operatingSystemFamily": "LINUX"
  },
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789012:role/api-service-task",
  "containerDefinitions": [{
    "name": "app",
    "image": "123456789012.dkr.ecr.us-east-2.amazonaws.com/api-service:abc123",
    "essential": true,
    "portMappings": [{"containerPort": 8080, "protocol": "tcp"}],
    "environment": [
      {"name": "NODE_ENV", "value": "production"}
    ],
    "secrets": [
      {"name": "DB_PASSWORD", "valueFrom": "arn:aws:secretsmanager:us-east-2:123456789012:secret:rds/api/password"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/aws/ecs/api-service",
        "awslogs-region": "us-east-2",
        "awslogs-stream-prefix": "app",
        "mode": "non-blocking",
        "max-buffer-size": "25m"
      }
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 30
    }
  }]
}
```

Things this gets right:
- **`runtimePlatform: ARM64`** — Graviton, 20% cheaper Fargate.
- **`awslogs` non-blocking mode** — application doesn't block on CloudWatch Logs ingestion under load.
- **Separate execution role and task role** — execution role pulls images and ships logs; task role is what the app code uses (least privilege).
- **Secrets via Secrets Manager** — no plaintext DB passwords in task definitions.
- **Health check with start period** — gives the app time to boot before health-checking.

### Service Connect vs ALB target group

| Pattern | Use when |
|---------|----------|
| **ALB → Service** | Public-facing HTTP/HTTPS, WebSocket, multiple paths to multiple services |
| **NLB → Service** | TCP/UDP traffic, ultra-high throughput, static IP requirements |
| **Service Connect** | East-west service-to-service traffic with DNS + observability (CloudMap-based) |
| **VPC Lattice** | Cross-VPC / cross-account service-to-service with IAM auth and L7 policies |

For a typical microservice topology in 2026:
- North-south (public traffic in): CloudFront → ALB → ECS Service.
- East-west (service-to-service): Service Connect for same-VPC; VPC Lattice for cross-VPC or cross-account.

### Auto-scaling on ECS

Application Auto Scaling with target tracking. Default to **CPU utilization 70%** as primary scaling metric; add **ALBRequestCountPerTarget** as secondary for predictive scale-out before CPU peaks.

```typescript
// CDK
const scalable = service.autoScaleTaskCount({ minCapacity: 2, maxCapacity: 20 });
scalable.scaleOnCpuUtilization('CpuScaling', {
  targetUtilizationPercent: 70,
  scaleInCooldown: Duration.minutes(5),
  scaleOutCooldown: Duration.minutes(1),
});
scalable.scaleOnRequestCount('RpsScaling', {
  requestsPerTarget: 1000,
  targetGroup: service.targetGroup,
});
```

**Asymmetric cooldowns**: scale-out fast (1min), scale-in slow (5min). Aggressive scale-in causes thrashing under burst loads.

## API Gateway vs Lambda URLs vs AppSync vs ALB

| Surface | Auth | Throttling | Caching | WAF | Best for |
|---------|------|------------|---------|-----|----------|
| **API Gateway HTTP API** | JWT, Cognito, Lambda authorizer, IAM | Per-stage | Via CloudFront | Yes (via CloudFront) | New REST APIs, cost-sensitive |
| **API Gateway REST API** | All HTTP API + API keys, usage plans | Built-in | Built-in | Native | API products with keys, request validation, full mgmt |
| **API Gateway WebSocket API** | IAM, Lambda authorizer | Per-stage | N/A | Yes (via CloudFront) | Real-time bidirectional |
| **Lambda URLs** | IAM or NONE | Lambda concurrency only | None | None | Internal endpoints, webhooks |
| **AppSync** | API key, Cognito, IAM, OIDC, Lambda authorizer | Per-resolver | Built-in (server + client cache) | Yes | GraphQL, subscriptions, multi-source |
| **ALB + Lambda target** | OIDC, Cognito | None | None | Yes | Mixing Lambda + container behind one LB |

**Default for new public REST APIs in 2026:** API Gateway HTTP API + Lambda + Cognito user pool authorizer. Drop to Lambda URLs for internal-only webhooks; promote to REST API only when you need usage plans, API keys, or request validation models.

### API Gateway throttling — defaults and what to do

| Type | Default |
|------|---------|
| Account-level throttle (default) | 10,000 RPS per region |
| Burst | 5,000 |
| Per-API throttle | Match account by default; configure per stage |
| Per-method throttle (REST API) | Configurable per resource |

Request a Service Quotas increase **before launch** if your design exceeds 10K RPS sustained; the increase isn't instant.

## AppSync GraphQL — when GraphQL wins

AppSync is worth it when:
- Multiple frontends (web, iOS, Android, partner) need different shapes from the same backend.
- The frontend benefits from a single round trip to fetch a join (vs N REST calls).
- Real-time subscriptions are a first-class need (chat, dashboards, collaborative editing).
- Multiple data sources (DynamoDB + Lambda + RDS + HTTP endpoints) — AppSync resolvers wire each field to its source.

Avoid AppSync when:
- The API surface is small and stable (the schema-first overhead doesn't pay back).
- The team doesn't have GraphQL experience and the operational complexity isn't justified.

### Resolver patterns

- **VTL → JavaScript resolvers**: AppSync resolvers were originally VTL (Velocity); JavaScript resolvers are now the preferred runtime. Migrate.
- **Pipeline resolvers** for multi-step logic (auth check → fetch → transform) — keep each function single-purpose.
- **Direct DynamoDB resolvers** for high-RPS lookups — no Lambda in the path = no cold start, no concurrency cap.
- **Lambda resolvers** for anything that needs business logic.

## Step Functions — the modern shape

### JSONata over ResultPath/InputPath chains

```json
// Old shape (avoid for new state machines)
{
  "Type": "Task",
  "Resource": "arn:aws:states:::lambda:invoke",
  "Parameters": {
    "FunctionName": "FetchUser",
    "Payload.$": "$.userId"
  },
  "ResultPath": "$.user",
  "OutputPath": "$",
  "Next": "NextStep"
}

// New shape — JSONata
{
  "Type": "Task",
  "Resource": "arn:aws:states:::lambda:invoke",
  "Arguments": "{% { 'FunctionName': 'FetchUser', 'Payload': $userId } %}",
  "Assign": {
    "user": "{% $states.result.Payload %}"
  },
  "Next": "NextStep"
}
```

JSONata + Variables (re:Invent 2024) are incrementally adoptable per state. Variables hold values across states without threading them through every state's input/output. Far cleaner than the old ResultPath/InputPath/OutputPath/Parameters dance.

### Standard vs Express workflows

| | Standard | Express |
|--|----------|---------|
| **Max duration** | 1 year | 5 minutes |
| **Throughput** | 2,000 starts/sec | 100,000 starts/sec |
| **Pricing** | Per state transition (~$0.025/1K) | Per request + duration (~$1/M + duration cost) |
| **History** | Full execution history (3 months) | CloudWatch Logs only |
| **Best for** | Long-running workflows, human-in-the-loop | High-throughput, short workflows |

Default for typical workflows: **Standard**. Promote to Express only when you've measured >100 starts/sec sustained or your unit economics demand it.

### TestState API (GA Mar 2026)

Test individual states in isolation or complete workflows before deploying:

```bash
aws stepfunctions test-state \
  --definition file://state-definition.json \
  --role-arn arn:aws:iam::123456789012:role/MyStateMachineRole \
  --input '{"userId": "user-123"}'
```

Use in CI before deploying state machine changes. Catches input-shape errors that previously required full deploys.

### Wait-for-callback pattern (human-in-the-loop)

```json
{
  "Type": "Task",
  "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
  "Parameters": {
    "FunctionName": "RequestApproval",
    "Payload": {
      "approvalRequest.$": "$",
      "taskToken.$": "$$.Task.Token"
    }
  },
  "Next": "ProcessApproval",
  "TimeoutSeconds": 86400
}
```

Lambda gets the task token, sends a notification (email/Slack with a link), and SendTaskSuccess/SendTaskFailure is called from the approval handler. Step Functions waits up to TimeoutSeconds; the approval handler is whatever surface fits (API Gateway endpoint, Slack interactive message, etc.).

## EventBridge — event-driven architecture

### Default vs custom event bus

| Bus | Use for |
|-----|---------|
| **Default bus** | AWS service events (S3 events, EC2 state changes, etc.) |
| **Custom bus** | Application events with custom event schema |
| **Partner event bus** | Third-party SaaS event integration (Stripe, Shopify, Auth0, etc.) |

Default to **one custom bus per bounded context** (microservice, team, domain). Bus-per-microservice creates organic blast-radius isolation.

### EventBridge Pipes — eliminate Lambda glue

Pipes connect source → optional filter → optional enrichment → target, without Lambda in the middle:

```typescript
// CDK
import * as pipes from 'aws-cdk-lib/aws-pipes-alpha';

new pipes.Pipe(this, 'OrdersToWorkflow', {
  source: new pipes.SqsSource(ordersQueue),
  filter: new pipes.Filter([
    pipes.FilterPattern.fromObject({
      'body.orderType': ['premium']
    })
  ]),
  enrichment: new pipes.LambdaEnrichment(enrichFn),
  target: new pipes.SfnStateMachine(workflow, {
    invocationType: pipes.StateMachineInvocationType.FIRE_AND_FORGET,
  }),
});
```

Pipes can replace these Lambda-glue patterns:
- SQS → Step Functions (no Lambda needed)
- DynamoDB Streams → EventBridge (no Lambda needed)
- Kinesis → Lambda with prior filtering/enrichment (Lambda still in path, but less glue)
- MQ → Lambda
- Kafka → Lambda

### Schema Registry

EventBridge Schema Registry auto-discovers schemas from events flowing through buses. Use it to:
- Generate code bindings (TypeScript, Java, Python) for event publishers/consumers.
- Catch breaking schema changes via the Discoverer.

Treat event schemas like API contracts — version explicitly, evolve additively, never break consumers without a major version bump.

## SQS / SNS / Kinesis / MSK — when each

| Need | Use | Why |
|------|-----|-----|
| Decouple producer from consumer, at-least-once delivery | **SQS Standard** | Simple, scalable, cheap |
| Strict FIFO ordering within partition | **SQS FIFO** | Up to 3000 msg/sec per group with high throughput mode |
| Pub/sub fan-out without ordering | **SNS Standard** | Fan to 12.5M endpoints |
| Pub/sub fan-out with ordering | **SNS FIFO** | Order preserved per group |
| Ordered stream with replay | **Kinesis Data Streams** | Multiple consumers, 7-day default retention |
| Long retention + Kafka semantics | **MSK** (Kafka) or **MSK Serverless** | Industry-standard, ecosystem, multi-cloud portability |
| Routing with rules across services/accounts | **EventBridge** | Schema-aware, cross-account, partner events |

**SQS gotchas:**
- Visibility timeout must exceed Lambda max execution (or message becomes visible again mid-processing).
- Long polling (`ReceiveMessageWaitTimeSeconds=20`) reduces empty receives — set it on every queue.
- Lambda + SQS scaling has a partial batch failure pattern (`ReportBatchItemFailures`) — use it.

**Kinesis gotchas:**
- Shard model is per-shard 1 MB/sec write, 2 MB/sec read. On-demand mode (recommended for unpredictable load) auto-scales but costs more.
- Enhanced fan-out: 2 MB/sec per consumer (not shared). Use for multi-consumer reads.
- Lambda + Kinesis: tumbling windows, parallelization factor, batch window — tune for throughput vs latency.

**MSK gotchas:**
- MSK Serverless is the right starting point for most workloads — no broker sizing.
- MSK provisioned for tight cost control at predictable scale.
- IAM auth via SASL/IAM is the modern auth path (vs mTLS or SCRAM).

## SigV4 signing — when you write it by hand

Most SDK calls handle SigV4 automatically. You write it by hand when:
- Calling AWS APIs from a non-SDK environment (browser, embedded device, custom HTTP client).
- Pre-signed URLs for S3 / DynamoDB / etc.
- IAM-authenticated calls to API Gateway / AppSync from a client.

**Don't roll your own SigV4.** Use:
- `@aws-sdk/signature-v4` (JS)
- `aws-requests-auth` (Python)
- `aws-sigv4` Go module
- `aws-sigv4` Rust crate

Or rely on the SDK's signer if the call is to an AWS service.

## DynamoDB from the backend perspective

(Database modeling lives in [`database-architect.md`](database-architect.md). Here is what the backend code does once the table exists.)

### SDK usage — the patterns that matter

```typescript
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, QueryCommand, BatchWriteCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const doc = DynamoDBDocumentClient.from(client, {
  marshallOptions: { removeUndefinedValues: true, convertClassInstanceToMap: true },
});

// Get item — pk + sk
const result = await doc.send(new GetCommand({
  TableName: 'Orders',
  Key: { pk: 'ORDER#abc', sk: 'ORDER#abc' },
}));

// Query — pk + sk pattern
const items = await doc.send(new QueryCommand({
  TableName: 'Orders',
  KeyConditionExpression: 'pk = :pk AND begins_with(sk, :prefix)',
  ExpressionAttributeValues: { ':pk': 'CUSTOMER#123', ':prefix': 'ORDER#' },
  Limit: 50,
}));

// Batch write — 25 items max per call, paginate above that
await doc.send(new BatchWriteCommand({
  RequestItems: { Orders: items.map(i => ({ PutRequest: { Item: i } })) },
}));
```

**`DynamoDBDocumentClient`** auto-marshals JS objects to DynamoDB attribute-value format. Always use it; never write `{ S: 'value' }` shapes by hand.

### Conditional writes — the only reliable concurrency control

```typescript
import { ConditionalCheckFailedException } from '@aws-sdk/client-dynamodb';

try {
  await doc.send(new UpdateCommand({
    TableName: 'Orders',
    Key: { pk: 'ORDER#abc', sk: 'ORDER#abc' },
    UpdateExpression: 'SET #status = :new, version = :v_new',
    ConditionExpression: 'version = :v_old',
    ExpressionAttributeNames: { '#status': 'status' },
    ExpressionAttributeValues: {
      ':new': 'CONFIRMED',
      ':v_old': 3,
      ':v_new': 4,
    },
  }));
} catch (err) {
  if (err instanceof ConditionalCheckFailedException) {
    // Optimistic concurrency conflict — retry or surface to caller
    throw new ConflictError('Order was modified by another writer');
  }
  throw err;
}
```

Version attribute + ConditionExpression is the canonical optimistic concurrency pattern on DynamoDB. Without it, last-writer-wins eats data.

### Transactions

`TransactWriteItems` — up to 100 items, ACID across items in one or more tables in the same region. 2x the cost of regular writes. Use for:
- Multi-item write that must succeed or fail together (e.g., debit one account, credit another).
- Idempotency tokens (provide `ClientRequestToken` to dedupe retries).

Don't use for performance-critical hot paths where eventual consistency would suffice.

## Aurora DSQL from the backend perspective

(Database design in [`database-architect.md`](database-architect.md).)

DSQL is Postgres-compatible at the wire protocol level. Existing `pg` / `psycopg` / `pgx` drivers work. **Key differences from RDS Postgres:**
- **No connection limit** in the traditional sense; DSQL multiplexes connections at the protocol layer. Don't put RDS Proxy in front of it.
- **No background workers / cron extensions** — DSQL is serverless; use EventBridge Scheduler for periodic work.
- **No long-lived transactions** — DSQL targets short OLTP transactions (typical web request shape). Don't try to run hour-long ETL inside a DSQL transaction.
- **No PL/pgSQL stored procedures** (as of GA; check current state). Move logic into the application layer.
- **IAM auth** is the default — connection string includes a short-lived token derived from your IAM principal.

```python
# Connecting to DSQL with IAM auth (Python)
import boto3
import psycopg

client = boto3.client('dsql', region_name='us-east-2')
token = client.generate_db_connect_admin_auth_token(
    Hostname='abc123.dsql.us-east-2.on.aws',
    Region='us-east-2',
)

conn = psycopg.connect(
    host='abc123.dsql.us-east-2.on.aws',
    dbname='postgres',
    user='admin',
    password=token,
    sslmode='verify-full',
)
```

Tokens are short-lived (15 min default). Refresh on connection establishment, not per query.

## ElastiCache (Valkey) from the backend perspective

Connection patterns:
- **Cluster mode disabled**: single primary + read replicas. Drivers connect to the primary endpoint for writes, reader endpoint for reads. Simpler; use for cache-sized workloads.
- **Cluster mode enabled**: sharded across nodes. Drivers must be cluster-aware (`redis-cluster` for Node, `redis-py-cluster` for Python). Use for >100GB caches or >100K RPS.

```typescript
import Redis from 'ioredis';

const redis = new Redis({
  host: process.env.CACHE_ENDPOINT!,
  port: 6379,
  tls: {}, // ElastiCache encryption-in-transit
  password: process.env.CACHE_AUTH_TOKEN!, // Or use IAM auth
  enableOfflineQueue: false, // Fail fast when cache is down
  maxRetriesPerRequest: 1,
  connectTimeout: 1000,
});
```

**Always** set `enableOfflineQueue: false` and a small `maxRetriesPerRequest` — when the cache is down, you want the application to fail-open to the database, not queue commands forever.

**Valkey vs Redis**: Valkey 7.2 on ElastiCache is 33% cheaper than Redis OSS engine on the same instance class. Net-new caches: Valkey. Wire-compatible; existing Redis client libraries work unchanged.

## Secrets Manager + Parameter Store

| Storage | Use for | Cost |
|---------|---------|------|
| **Secrets Manager** | Rotated secrets (DB passwords, API keys), automatic rotation hooks | $0.40/secret/month + API calls |
| **SSM Parameter Store (Standard)** | Configuration (non-secret), free tier | Free up to 10K params |
| **SSM Parameter Store (Advanced)** | Larger params (up to 8 KB), policies | $0.05/param/month |

**Anti-pattern: secrets in environment variables in source.** Read at runtime from Secrets Manager, cached with TTL.

```python
from aws_lambda_powertools.utilities.parameters import get_secret

# Cached for 5 minutes by default
db_creds = get_secret('rds/api/credentials', transform='json', max_age=300)
```

For Lambda with high RPS, the AWS Lambda Extension for Parameters and Secrets (`AWS-Parameters-and-Secrets-Lambda-Extension`) caches via a local HTTP endpoint — avoids per-invocation API calls.

## Error handling, retries, idempotency

### Retry semantics in the AWS SDK

SDK v3 (JS), boto3, aws-sdk-go-v2 all default to **adaptive retry mode**: exponential backoff + token-bucket rate-limiter. For most Lambda code, the defaults are fine.

Adjust when:
- Throughput-critical: lower `maxAttempts` to fail fast (e.g., `2` for cache-style calls).
- Idempotent batch work: higher `maxAttempts` (e.g., `5`) with longer base delay.

```typescript
const s3 = new S3Client({
  maxAttempts: 3,
  retryMode: 'adaptive',
});
```

### Application-level retries with exponential backoff

For non-AWS API calls or HTTP webhooks:

```typescript
import { setTimeout } from 'node:timers/promises';

async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  { maxAttempts = 5, baseDelayMs = 100, maxDelayMs = 30_000 } = {},
): Promise<T> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxAttempts) throw err;
      if (!isRetryable(err)) throw err;
      const delay = Math.min(baseDelayMs * 2 ** (attempt - 1), maxDelayMs);
      const jitter = Math.random() * delay * 0.5;
      await setTimeout(delay + jitter);
    }
  }
  throw new Error('unreachable');
}
```

**Jitter is mandatory** at scale. Without it, retry storms synchronize across thundering hordes of failing clients.

### Dead-letter queues + replay

Every async invocation should have a DLQ or Destination on failure. Without it, failed messages disappear silently. Standard pattern:

```
[Producer] → [SQS] → [Lambda consumer]
                      ↓ failure (after retries)
                     [SQS DLQ] → [Lambda DLQ inspector / Step Functions replay]
```

DLQ Lambda can republish to the main queue after fix, or write to S3 for human inspection. **Always alarm on DLQ depth > 0** in CloudWatch.

## Observability — what the backend ships

(Deep dive in [`sre-engineer.md`](sre-engineer.md).)

The backend's responsibility:
1. **Structured logs** — JSON output with `requestId`, `traceId`, business context (`userId`, `orderId`). Use Powertools.
2. **X-Ray traces** — `@tracer.capture_method`, `@tracer.capture_lambda_handler`. Trace external calls (HTTP, DB, SDK) with subsegments.
3. **Custom metrics** — Use EMF (Embedded Metric Format) via Powertools `metrics`, not the CloudWatch `PutMetric` API directly. EMF is essentially free; PutMetric isn't.
4. **OpenTelemetry compatibility** — ADOT (AWS Distro for OpenTelemetry) auto-instruments most languages. If the rest of your platform speaks OTel, ship OTLP from Lambda to ADOT collector → CloudWatch + X-Ray.

## Idempotency tokens, retries, and exactly-once-effect

AWS gives you at-least-once almost everywhere. Exactly-once-effect is your code's job.

- **Lambda async invocations**: retry-on-failure means duplicate executions. Idempotency by event hash + DynamoDB persistence layer (Powertools `@idempotent`).
- **SQS**: at-least-once. Use `MessageDeduplicationId` (FIFO) or application-level dedup table.
- **EventBridge**: at-least-once. Same as SQS.
- **API Gateway → Lambda**: client retries with same `Idempotency-Key` header; Lambda checks DDB before processing.
- **Step Functions**: at-least-once on async tasks; use idempotency in the called Lambdas.

**Test for it.** Inject duplicate events deliberately; if they double-charge or double-send, you don't have idempotency.

## Connection pooling: Lambda vs containers

| Scenario | Pooling |
|----------|---------|
| Lambda → RDS / Aurora (non-DSQL) | **RDS Proxy** in front — Lambda makes a single connection to the proxy, proxy maintains the pool. Without proxy, you'll exhaust DB connections at scale. |
| Lambda → Aurora DSQL | No proxy needed; DSQL multiplexes connections natively. |
| Lambda → DynamoDB | Connection pool is internal to SDK; no extra component. |
| Lambda → ElastiCache | Client maintains pool inside the Lambda execution context; reused across warm invocations. |
| ECS / EKS → RDS | App-level pool (PgBouncer sidecar or in-process driver pool). 10-20 connections per pod typical. |
| ECS / EKS → DSQL | App-level pool — but DSQL handles many more connections than RDS, so size accordingly. |

**RDS Proxy gotcha:** "session pinning" can kill efficiency. Avoid SET, prepared statements with names, temp tables — they pin connections. Use parameter binding, not prepared statements.

## Patterns and anti-patterns

### Patterns

- **Lambda thin handlers + pure business logic** — testable, swappable runtime.
- **EventBridge custom bus per bounded context** — organic isolation.
- **Pipes for Lambda glue replacement** — every "Lambda that does nothing but forward" is a code smell.
- **Step Functions for orchestration, Lambda for tasks** — orchestrate in declarative state machines, do work in Lambda.
- **Optimistic concurrency via DynamoDB ConditionExpression + version attribute** — only reliable way to prevent last-writer-wins.
- **Idempotency tokens on every external write** — assume retries, design for duplicates.
- **HTTP API + Cognito for new public APIs**, REST API only when needed.
- **Lambda Web Adapter for "I have a FastAPI/Express app, put it on Lambda"** — vs rewriting as raw handlers.
- **ARM64 (Graviton) for everything that runs Linux** — Lambda, Fargate, EC2. 20% cheaper, drop-in for most code.
- **Use Powertools (Python/TS/Java/.NET)** — don't roll your own logger/tracer/metrics.

### Anti-patterns

- **AWS SDK v2 (JS) imports in new code** (`require('aws-sdk')`). SDK v2 is EOL. Use modular v3 packages (`@aws-sdk/client-*`).
- **Synchronous calls in a Lambda handler for things that don't need to be sync.** Push to SQS, return 202. Save user-facing latency.
- **Long polling without `WaitTimeSeconds`** — empty receives at full rate burn money and quota.
- **DLQ-less async work.** Failures silently disappear.
- **Catch-all `try / except` that swallows errors.** Log + rethrow or alert. Silent failures are the worst kind.
- **One Lambda doing the work of three.** Single-responsibility: orchestration in Step Functions, transformation in one Lambda, persistence in another.
- **Hard-coded ARNs / region strings.** Inject via environment variables (CDK / SAM does this for you).
- **Hand-rolled SigV4.** Use the SDK signer.
- **Lambda layers for everything.** Layers add cold-start time and operational complexity. Bundle directly unless layer is shared across >5 functions.
- **VPC-attached Lambda with NAT for outbound to AWS APIs.** Use VPC endpoints.
- **DynamoDB scans on hot tables.** Scans are full-table reads, $$ at scale. Design GSIs.

## Tooling specifics

- **AWS SAM CLI** — local Lambda invoke, local API Gateway emulation, local Step Functions emulation. SAM templates ARE CloudFormation, so they integrate cleanly with deployed AWS. Use for the iteration loop on serverless apps.
- **AWS CDK v2** — when the infrastructure is more than a single Lambda + table. Mixins (`.with()`) for reusable behaviors. See [`devops-engineer.md`](devops-engineer.md) for CDK patterns.
- **AWS Powertools** — Python, TypeScript, Java, .NET. Logger, Tracer, Metrics, Parameters, Idempotency, Batch utilities. First-party AWS, well-maintained.
- **LocalStack** — local AWS emulation. Useful for offline iteration; accuracy varies by service (S3, DynamoDB, SNS, SQS, Lambda are strong; SageMaker, AppSync less so).
- **`aws-sdk-client-mock`** (Node), **`moto`** (Python) — for unit tests. Mock SDK calls without LocalStack.
- **Amazon Q Developer** (formerly CodeWhisperer) — IDE extension for IDE-assisted code authoring. Not an MCP / installable agent skill as of this currency; works inside VS Code, IntelliJ, Cursor, Eclipse.
- **CloudFront Functions vs Lambda@Edge**: for header manipulation, URL rewrites, simple A/B logic, CloudFront Functions (JS, sub-1ms, 2 MB). For auth, origin selection, full Node/Python runtime, Lambda@Edge (5-30s, 128MB-3GB).

## Cross-references — products this overlay touches

From `products_covered` in the parent `SKILL.md`:

- Bedrock + AgentCore — see [`ai-ml-engineer.md`](ai-ml-engineer.md) for agent design; backend writes the Bedrock invocation glue.
- Lambda SnapStart — covered here.
- VPC Lattice — service mesh / east-west; covered here at the integration layer.
- Step Functions JSONata — covered here.
- DynamoDB — modeling in `database-architect.md`; SDK usage here.
- Aurora DSQL — schema in `database-architect.md`; connection pattern here.
- API Gateway / AppSync / ALB / Lambda URLs — covered here.

## Integration with always-on protocols

### TDD on Lambda

```typescript
// handler.test.ts — unit test with aws-sdk-client-mock
import { mockClient } from 'aws-sdk-client-mock';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { handler } from './handler';
import { Readable } from 'node:stream';
import { sdkStreamMixin } from '@smithy/util-stream';

const s3Mock = mockClient(S3Client);

beforeEach(() => s3Mock.reset());

test('handler returns summary on success', async () => {
  const body = sdkStreamMixin(Readable.from('summary text'));
  s3Mock.on(GetObjectCommand).resolves({ Body: body as any });

  const res = await handler({
    pathParameters: { id: 'abc' },
    requestContext: { requestId: 'req-1' },
  } as any);

  expect(res).toEqual({ statusCode: 200, body: 'summary text' });
});

test('handler returns 500 on S3 failure', async () => {
  s3Mock.on(GetObjectCommand).rejects(new Error('boom'));
  const res = await handler({
    pathParameters: { id: 'abc' },
    requestContext: { requestId: 'req-1' },
  } as any);
  expect(res).toEqual({ statusCode: 500, body: 'Internal error' });
});
```

Red: write the test for the success path before the handler. Green: minimal handler that makes the test pass. Refactor: extract `getReportSummary`, add error path test. Same loop on every change.

### Verification on AWS

Claims must cite docs. Examples:

- "Lambda max payload is 6 MB sync, 256 KB async" — cite `https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html`.
- "API Gateway HTTP API costs $1/M requests" — cite the API Gateway pricing page.
- "DynamoDB on-demand has 40K WCU / 40K RCU per-table default quota" — cite `https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ServiceQuotas.html`.

If you can't find the doc, the claim is suspect.

### Debugging on AWS

1. **Reproduce locally first** when possible. SAM local invoke, LocalStack, mocked SDK.
2. **Capture from production via CloudWatch Logs Insights** + X-Ray. Query Logs Insights with the `requestId` from the failing trace. Cross-reference X-Ray for the call graph.
3. **One variable at a time.** If you change the Lambda memory, the timeout, the runtime, and the IAM policy at once, you don't know what fixed the bug.
4. **Three-failure escalation** — if three hypotheses fail to land, stop changing code and gather data instead. Often it's a quota you didn't know about, a NAT outage, or an API change you missed in What's New.
