---
title: API Gateway
description: HTTP, REST, and WebSocket front door on AWS — HTTP API the default for new builds, REST API for full feature set, ~3.5x cost difference. Cognito or JWT authorizers, WAF integration via CloudFront.
product:
  name: API Gateway
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, security-engineer]
  authoritative_url: https://docs.aws.amazon.com/apigateway/
  notes: "HTTP API the default for new builds; REST API for full feature set; surface stable. ~3.5x cost difference at same RPS."
---

## What it is

Amazon API Gateway is the managed HTTP / REST / WebSocket front door — request routing, authorization (JWT, Cognito, Lambda authorizer, IAM, mTLS), throttling, transformation, integration with Lambda, ECS/EKS via VPC Link, and any HTTP backend.

Canonical surface: [docs.aws.amazon.com/apigateway](https://docs.aws.amazon.com/apigateway/).

## When to use

| Choice | Use when | Avoid when |
|---|---|---|
| **HTTP API** | Simple REST/HTTP, JWT auth, cost-sensitive | You need WAF integration with native fit, API keys, usage plans, request validation models |
| **REST API** | Full API management — keys, usage plans, request/response transformation, WAF, models, SDKs | Cost matters at scale (REST is ~3.5x cost of HTTP API) |
| **WebSocket API** | Bidirectional real-time | HTTP-only workloads |
| **[Lambda URLs](/stacks/aws/lambda/)** | Internal endpoints, webhooks, no API mgmt features needed | Anything external-facing that needs throttling, API keys, WAF |
| **ALB + Lambda target** | Existing ALB, want one LB for containers + Lambda | New build with no existing ALB |
| **[AppSync](#cross-references)** | GraphQL | REST-only workloads |

Default for new public REST APIs in 2026: **API Gateway HTTP API + Lambda + Cognito or JWT authorizer**. Drop to Lambda URLs for internal-only webhooks; promote to REST API only for usage plans, API keys, or request validation models.

## 2025-2026 currency anchors

- **HTTP API is the default** for new builds. ~3.5x cheaper than REST API at the same RPS.
- **JWT authorizers** integrate with any OIDC provider including [Cognito](/stacks/aws/cognito/).
- **mTLS via ACM Private CA** mature.
- **Per-stage throttling** standard; per-method requires REST API.

## Patterns

### Authorizer choice

| Authorizer | Pattern |
|---|---|
| **JWT** | Modern OIDC providers — Cognito, Auth0, Okta |
| **Cognito User Pool** | Native Cognito integration |
| **Lambda authorizer** | Custom logic — token introspection, complex claim transformation |
| **IAM** | Service-to-service with SigV4 |
| **mTLS** | Strict B2B integrations, regulated industries |

### Throttling defaults

| Type | Default |
|---|---|
| Account-level throttle (default) | 10,000 RPS per region |
| Burst | 5,000 |
| Per-API throttle | Match account by default; configure per stage |
| Per-method throttle (REST API) | Configurable per resource |

Request a Service Quotas increase **before launch** if your design exceeds 10K RPS sustained; the increase isn't instant.

### Caching

- **REST API**: built-in cache (0.5-237 GB tiers). Use for hot read paths.
- **HTTP API**: no built-in cache — front with [CloudFront](/stacks/aws/cloudfront/) for caching.

### WAF integration

- **REST API**: native WAF web ACL attach.
- **HTTP API**: WAF via CloudFront in front.

See [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) for WAF configuration.

### CDK example

```typescript
import * as apigw from 'aws-cdk-lib/aws-apigatewayv2';
import * as integrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as authorizers from 'aws-cdk-lib/aws-apigatewayv2-authorizers';

const httpApi = new apigw.HttpApi(this, 'OrdersApi', {
  apiName: 'orders',
  corsPreflight: {
    allowOrigins: ['https://app.example.com'],
    allowMethods: [apigw.CorsHttpMethod.GET, apigw.CorsHttpMethod.POST],
    allowHeaders: ['Authorization', 'Content-Type'],
  },
});

const authorizer = new authorizers.HttpJwtAuthorizer(
  'CognitoAuth',
  'https://cognito-idp.us-east-2.amazonaws.com/us-east-2_xxxxx',
  { jwtAudience: ['client-id'] }
);

httpApi.addRoutes({
  path: '/orders',
  methods: [apigw.HttpMethod.POST],
  integration: new integrations.HttpLambdaIntegration('CreateOrder', createOrderFn),
  authorizer,
});
```

### Stages

- **`$default` stage** for HTTP API — simplest.
- **Named stages** (`dev`, `staging`, `prod`) when you need per-stage throttling or variables.
- **Custom domain + base path mapping** for production endpoints.

### Logging + observability

- **Access logs** to CloudWatch Logs or Kinesis Firehose → S3.
- **Execution logs** for Lambda integrations.
- **X-Ray tracing** via `tracingEnabled: true`.

## Anti-patterns

- **REST API when HTTP API fits.** 3.5x cost difference adds up.
- **API Gateway in front of an ALB in front of ECS** when only one is needed.
- **No throttling configured** — single bad client can DoS the account.
- **JWT authorizer without `audience` validation** — anyone with a token from the IdP can hit your API.
- **Lambda authorizer that doesn't cache.** Caching by token saves significant cost.
- **Mixing usage plans + JWT auth** unnecessarily — pick one auth model.
- **Custom domain without CloudFront** when global low latency matters.

## Gotchas

- **HTTP API 29-second integration timeout** — same as Lambda's max sync response time.
- **HTTP API doesn't support all features of REST API** — verify (mTLS, request validation, API keys, usage plans, request/response models, SDK generation).
- **WAF on HTTP API requires CloudFront** in front.
- **Stage variables** are REST-API-only; HTTP API uses environment in route mapping.
- **API key + usage plan** is REST-API-only.
- **WebSocket API connection storage** — connection IDs must be persisted by the application (typically in [DynamoDB](/stacks/aws/dynamodb/)).

## Cross-references

- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — backend integration
- [`/stacks/aws/cognito/`](/stacks/aws/cognito/) — user pool authorizer
- [`/stacks/aws/cloudfront/`](/stacks/aws/cloudfront/) — caching + WAF for HTTP API
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — WAF configuration
- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — role view; surface choice + idioms
- [AppSync](https://docs.aws.amazon.com/appsync/) — GraphQL alternative
- [API Gateway pricing](https://aws.amazon.com/api-gateway/pricing/)
