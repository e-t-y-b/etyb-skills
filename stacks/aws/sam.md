---
title: SAM
description: AWS Serverless Application Model — CloudFormation transform for Lambda + API Gateway + DynamoDB + Step Functions, with sam local invoke for dev loop. CDK integration preview 2025.
product:
  name: SAM
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer]
  authoritative_url: https://docs.aws.amazon.com/serverless-application-model/
  notes: "Mature CloudFormation transform for serverless; CDK integration preview 2025; sam local invoke and start-api for the dev loop."
---

## What it is

AWS SAM is a CloudFormation transform optimized for serverless workloads — shorter syntax for Lambda, API Gateway, DynamoDB, Step Functions, EventBridge. The SAM CLI provides `sam local invoke`, `sam local start-api`, and integration testing without deploying.

Canonical surface: [docs.aws.amazon.com/serverless-application-model](https://docs.aws.amazon.com/serverless-application-model/).

## When to use

| Need | Use SAM? |
|---|---|
| Project is serverless-only ([Lambda](/stacks/aws/lambda/) + [API Gateway](/stacks/aws/api-gateway/) + [DynamoDB](/stacks/aws/dynamodb/) + [Step Functions](/stacks/aws/step-functions/)) | Yes |
| Team wants `sam local invoke` for the dev loop | Yes |
| Hand-off shapes match the SAM template (smaller, easier to read for serverless reviewers) | Yes |
| Infrastructure exceeds serverless scope (VPC, EKS, multi-tier) | No — use [CDK](/stacks/aws/cdk/) or Terraform |
| Multi-cloud | No — Terraform |

## 2025-2026 currency anchors

- **SAM CLI's CDK support** (preview, 2025) bridges SAM and CDK — you can use SAM CLI for the dev loop and CDK for the deploy.
- **AWS Lambda Powertools** integrates with SAM-built Lambdas idiomatically.
- **`sam sync`** for fast dev iteration — code-only sync to deployed stack.

## Patterns

### Basic template

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  OrdersApi:
    Type: AWS::Serverless::Api
    Properties:
      StageName: prod
      Auth:
        DefaultAuthorizer: CognitoAuth
        Authorizers:
          CognitoAuth:
            UserPoolArn: !Ref UserPoolArn

  CreateOrderFn:
    Type: AWS::Serverless::Function
    Properties:
      Runtime: python3.13
      Handler: handler.create_order
      Architectures: [arm64]
      MemorySize: 512
      Timeout: 30
      Environment:
        Variables:
          TABLE_NAME: !Ref OrdersTable
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref OrdersTable
      Events:
        Api:
          Type: Api
          Properties:
            Path: /orders
            Method: POST
            RestApiId: !Ref OrdersApi

  OrdersTable:
    Type: AWS::Serverless::SimpleTable
    Properties:
      PrimaryKey:
        Name: pk
        Type: String
```

### Local dev loop

```bash
sam build
sam local invoke CreateOrderFn -e events/event.json
sam local start-api  # Local API Gateway emulation
sam local start-lambda  # Local Lambda invoke endpoint
```

### Sync for fast deploys

```bash
sam sync --stack-name my-stack --watch
```

Code-only sync without full CloudFormation update. Dev only — not for production deploys.

### Step Functions local emulation

```bash
sam local start-stepfunctions  # Local Step Functions emulation
```

### Layers + dependencies

```yaml
SharedLayer:
  Type: AWS::Serverless::LayerVersion
  Properties:
    ContentUri: layers/shared/
    CompatibleRuntimes:
      - python3.13

CreateOrderFn:
  Type: AWS::Serverless::Function
  Properties:
    Layers:
      - !Ref SharedLayer
    ...
```

## Anti-patterns

- **SAM for non-serverless workloads** (VPC, EKS, EC2). Use CDK or Terraform.
- **Layers for code shared across <5 functions.** Adds cold-start hop; bundle directly.
- **`sam deploy` from a developer laptop to production.** Use a pipeline.
- **No local invoke** — SAM's whole point is the dev loop.

## Gotchas

- **`sam build` requires Docker** for many runtimes — verify your CI has Docker available.
- **Local emulation accuracy varies** — most services work; some (Step Functions, EventBridge) are best-effort.
- **SAM templates are CloudFormation** — drift detection + import + StackSets all work the same.
- **SAM CLI version matters** — newer features require recent CLI; pin in CI.

## Cross-references

- [`/stacks/aws/cdk/`](/stacks/aws/cdk/) — alternative when scope grows beyond serverless
- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — primary SAM workload
- [`/stacks/aws/api-gateway/`](/stacks/aws/api-gateway/) — SAM-native integration
- [`/stacks/aws/cloudformation/`](/stacks/aws/cloudformation/) — what SAM compiles to
- [SAM CLI reference](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli.html)
