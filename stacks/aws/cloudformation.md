---
title: CloudFormation
description: AWS native infrastructure-as-code — mostly used via CDK or SAM; useful directly for compliance, StackSets, AWS Support hand-offs.
product:
  name: CloudFormation
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect]
  authoritative_url: https://docs.aws.amazon.com/cloudformation/
  notes: "Stable; mostly used via CDK; StackSets + Organizations integration for multi-account; drift detection mature."
---

## What it is

AWS CloudFormation is AWS's native infrastructure-as-code service — YAML / JSON templates describing resources, processed into "stacks." Both [CDK](/stacks/aws/cdk/) and [SAM](/stacks/aws/sam/) compile to CloudFormation. StackSets deploy templates across many accounts/regions.

Canonical surface: [docs.aws.amazon.com/cloudformation](https://docs.aws.amazon.com/cloudformation/).

## When to use

Direct CFN usage in 2026 is mostly:
- **Compliance** requires JSON/YAML templates as source of truth.
- **StackSets / Organizations** integration (CDK can do this, but CFN templates simplify the contract).
- **Hand-off to AWS Support / partners** expecting CFN.
- **Team prefers YAML to TypeScript / Python.**

For everything else, write CDK or SAM.

## 2025-2026 currency anchors

- **StackSets + Organizations integration** mature — deploy to entire OUs with one push.
- **Drift detection** mature — detect resources that have been changed outside CFN.
- **`AWS::*::*` resource type coverage** mostly complete for current services.
- **Custom resources** via Lambda for AWS resources or third-party that CFN doesn't natively cover.

## Patterns

### Template basics

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Orders application stack

Parameters:
  Environment:
    Type: String
    AllowedValues: [dev, staging, prod]

Resources:
  OrdersTable:
    Type: AWS::DynamoDB::Table
    Properties:
      AttributeDefinitions:
        - AttributeName: pk
          AttributeType: S
      KeySchema:
        - AttributeName: pk
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: true
      Tags:
        - Key: Environment
          Value: !Ref Environment

Outputs:
  TableArn:
    Value: !GetAtt OrdersTable.Arn
    Export:
      Name: !Sub '${AWS::StackName}-TableArn'
```

### StackSets

Deploy templates to multiple accounts and regions:

```bash
aws cloudformation create-stack-set \
  --stack-set-name security-baselines \
  --template-body file://baselines.yaml \
  --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false \
  --permission-model SERVICE_MANAGED

aws cloudformation create-stack-instances \
  --stack-set-name security-baselines \
  --deployment-targets OrganizationalUnitIds=ou-xxxx \
  --regions us-east-2 us-west-2
```

Use for org-wide baselines: GuardDuty, CloudTrail, Config, IAM Identity Center permission sets.

### Drift detection

```bash
aws cloudformation detect-stack-drift --stack-name my-stack
aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id ...
aws cloudformation describe-stack-resource-drifts --stack-name my-stack
```

Run drift detection on critical stacks weekly; alert on drift.

### Cross-stack references

```yaml
# Stack A exports
Outputs:
  TableArn:
    Value: !GetAtt OrdersTable.Arn
    Export:
      Name: !Sub '${AWS::StackName}-TableArn'

# Stack B imports
Resources:
  Consumer:
    Type: AWS::Lambda::Function
    Properties:
      Environment:
        Variables:
          TABLE_ARN: !ImportValue stack-a-TableArn
```

Cross-stack imports create dependencies — Stack A can't be updated in a way that removes the export while Stack B imports it.

### Custom resources

For resources CFN doesn't natively cover (third-party SaaS, complex provisioning):

```yaml
CustomThing:
  Type: Custom::MyResource
  Properties:
    ServiceToken: !GetAtt CustomResourceFn.Arn
    SomeProperty: value
```

Custom resource Lambda receives create/update/delete events; responds with success or failure URLs.

## Anti-patterns

- **Writing CFN by hand for serverless workloads.** Use [SAM](/stacks/aws/sam/).
- **Writing CFN by hand for complex multi-stack architectures.** Use [CDK](/stacks/aws/cdk/).
- **Manual console changes** to CFN-managed resources. Causes drift; defeats IaC.
- **No drift detection** on production stacks.
- **One mega-stack** with everything. Split by lifecycle.
- **Wildcard `iam:*` in IAM resources defined in CFN.** Scope policies.
- **Cross-stack imports for everything** — they create deployment dependencies that complicate rollback.

## Gotchas

- **CloudFormation update failures roll back** by default — but the rollback itself can fail, leaving the stack in `UPDATE_ROLLBACK_FAILED`. Have a runbook.
- **Some resources can't be updated in place** — require replace, which means deletion + recreation. Database / EBS resources can lose data; check `UpdateReplacePolicy`.
- **`DeletionPolicy: Retain`** on stateful resources is essential.
- **Cross-account drift detection** requires StackSets and is more involved.
- **Stack quota** — 200 active stacks per region per account by default; quota-bumpable.
- **Template size limits** — 51,200 bytes inline; 460,800 bytes via S3.

## Cross-references

- [`/stacks/aws/cdk/`](/stacks/aws/cdk/) — high-level abstraction; compiles to CFN
- [`/stacks/aws/sam/`](/stacks/aws/sam/) — serverless-focused CFN transform
- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — role view
- [CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html)
