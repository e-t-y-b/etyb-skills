---
title: CDK
description: AWS Cloud Development Kit — v2 (aws-cdk-lib) is the only supported track. Mixins, ECS deployment strategies, EKS Hybrid Nodes constructs added 2025-2026. v1 fully EOL.
product:
  name: CDK
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect, backend-architect]
  authoritative_url: https://docs.aws.amazon.com/cdk/v2/guide/
  notes: "CDK v1 fully EOL; mixins, ECS deployment strategies, EKS Hybrid Nodes constructs added 2025-2026; cdk --revert-drift single-command drift remediation."
---

## What it is

AWS CDK is the infrastructure-as-code framework that compiles to CloudFormation, with idiomatic libraries in TypeScript, Python, Java, .NET, Go. CDK v2 (`aws-cdk-lib`) is the monolithic library that replaces the per-service packages of v1. The path of least resistance for AWS IaC if your team is AWS-only and prefers code over HCL.

Canonical surface: [docs.aws.amazon.com/cdk](https://docs.aws.amazon.com/cdk/v2/guide/).

## When to use

| Choice | Use when |
|---|---|
| **CDK v2** | AWS-only IaC, team prefers code, AWS-native deployment |
| **Terraform / OpenTofu** | Multi-cloud (AWS + GCP + Azure + Cloudflare + Vercel); deep Terraform muscle memory; Sentinel/OPA policy-as-code |
| **SAM** | Serverless-only projects; `sam local invoke` dev loop |
| **CloudFormation directly** | Compliance demands JSON/YAML source of truth; StackSets/Organizations integration; AWS Support/partner hand-off |

**Anti-pattern:** writing CDK and Terraform in the same project. Pick one for AWS.

## 2025-2026 currency anchors

- **CDK v1 fully EOL.** CDK v2 (`aws-cdk-lib`) is the only supported track.
- **CDK Mixins** — compose reusable infrastructure behaviors via `.with()` on any construct. Replaces aspects + custom L3 patterns for the common case.
- **CDK ECS deployment strategies built-in** — Linear, Canary, AllAtOnce for ECS service rollouts without writing CodeDeploy by hand.
- **CDK `--revert-drift`** — single-command drift remediation.
- **EKS Hybrid Nodes constructs** for on-prem extensions.
- **AWS SAM CLI** supports local dev/test of CDK projects (preview, 2025). One toolchain for serverless + IaC dev loop.
- **cdk-nag** — IaC security scans run in CI.

## Patterns

### Project structure

```
/infra
├── bin/
│   └── app.ts              # CDK app entry
├── lib/
│   ├── stacks/
│   │   ├── network.ts      # VPC, subnets, NAT (or none), endpoints
│   │   ├── data.ts         # Aurora, DynamoDB, ElastiCache
│   │   ├── compute.ts      # ECS / EKS / Lambda
│   │   ├── observability.ts# CloudWatch, dashboards, alarms, X-Ray
│   │   └── shared.ts       # IAM roles, KMS keys, ECR repos
│   ├── constructs/
│   │   ├── lambda-fn.ts    # L3 wrapper
│   │   ├── ecs-service.ts  # L3 wrapper
│   │   └── dynamo-table.ts # L3 wrapper
│   └── mixins/
│       ├── with-pii-encryption.ts
│       └── with-cost-tags.ts
├── test/
│   ├── stacks.snapshot.test.ts
│   └── stacks.assertions.test.ts
└── cdk.json
```

**Stacks split by lifecycle, not by service.** Network rarely changes; data on schema migration; compute on every deploy. Separate stacks = compute deploy doesn't carry network risk.

### App structure

```typescript
import * as cdk from 'aws-cdk-lib';

const app = new cdk.App();
const envs: Record<string, cdk.Environment> = {
  dev:     { account: '111111111111', region: 'us-east-2' },
  staging: { account: '222222222222', region: 'us-east-2' },
  prod:    { account: '333333333333', region: 'us-east-2' },
};

for (const [name, env] of Object.entries(envs)) {
  const network = new NetworkStack(app, `Network-${name}`, { env });
  const data = new DataStack(app, `Data-${name}`, { env, vpc: network.vpc });
  new ComputeStack(app, `Compute-${name}`, { env, vpc: network.vpc, db: data.cluster });
}
```

Environment-per-account is the default modern shape.

### Constructs — L1, L2, L3

- **L1**: CloudFormation resources, 1:1 (`CfnVpc`, `CfnInstance`). Use when L2 doesn't expose what you need.
- **L2**: AWS-curated constructs with opinionated defaults (`Vpc`, `Function`, `Bucket`). Default starting point.
- **L3 / Patterns**: composed constructs (`ApplicationLoadBalancedFargateService`). Quick start; easy to outgrow.

**Don't build L3 wrappers prematurely.** Start with L2 + named parameters. Promote to L3 when the same pattern shows up 3+ times.

### Mixins

```typescript
const fn = new lambda.Function(this, 'Handler', { ... })
  .with(withCostTags({ Application: 'orders', CostCenter: '4500' }))
  .with(withPIIEncryption(piiKey));
```

Mixins replace many one-off Aspect classes and ad-hoc helper functions.

### Testing CDK

```typescript
import { Template, Match } from 'aws-cdk-lib/assertions';

test('Aurora cluster has deletion protection in prod', () => {
  const app = new App();
  const stack = new DataStack(app, 'Test', {
    env: { account: '333333333333', region: 'us-east-2' },
    stage: 'prod',
    vpc: mockVpc(),
  });
  const t = Template.fromStack(stack);

  t.hasResourceProperties('AWS::RDS::DBCluster', {
    DeletionProtection: true,
    DBClusterIdentifier: Match.stringLikeRegexp('^prod-'),
  });
});
```

**Two test layers**: fine-grained assertions for rules that *must* hold (deletion protection on prod, encryption everywhere, tags applied); snapshot tests as a backstop against accidental drift.

### Asset management

- Use a single `cdk synth` per pipeline; cache assets across stacks.
- Set lifecycle policies on the CDK staging buckets — assets older than 30 days get cleaned up.
- For Lambda code, bundle with esbuild (TypeScript) or build via CodeBuild for fast iteration.
- For container images, build once in CI, push to ECR with a content-addressable tag, reference by digest.

### Hot-swap for dev loop

```bash
cdk deploy MyStack --hotswap
```

Updates Lambda code, ECS task definitions, Step Functions definitions without CloudFormation. **Dev only — never prod** (state drift, no rollback).

### cdk-nag in CI

Run `cdk-nag` against synthesized templates to enforce AWS Solutions / HIPAA / NIST best practices. Fail CI on Critical findings.

## Anti-patterns

- **CDK v1 in new code.** Fully EOL; aws-cdk-lib only.
- **`cdk deploy` from a developer laptop into prod.** Always through a pipeline with audit trail.
- **`AdministratorAccess` on the cross-account deploy role.** Always scoped.
- **Hand-rolled multi-AZ Karpenter / EKS without using Auto Mode** when Auto Mode fits.
- **One CDK stack with everything in it.** Split by lifecycle.
- **CDK assets bucket with no lifecycle.** Grows indefinitely.
- **Inline IAM policies instead of managed policies for shared use.**
- **Hard-coded account IDs / region strings in CDK code.** Use context, env vars, or `cdk.json`.

## Gotchas

- **`cdk synth` is expensive on large monorepos** — cache strategically.
- **Cross-stack references via `addDependency`** are explicit; implicit cross-stack via `getAtt` works but is harder to reason about.
- **`Tags.of(stack).add(...)`** applies to all taggable children; useful but watch for unexpected resources getting tagged.
- **`removalPolicy: RETAIN`** on stateful resources is essential — `DESTROY` will delete the DB on `cdk destroy`.
- **CDK + Terraform in the same project** — pick one for AWS resources.

## Cross-references

- [`/stacks/aws/sam/`](/stacks/aws/sam/) — alternative for serverless-only
- [`/stacks/aws/cloudformation/`](/stacks/aws/cloudformation/) — what CDK compiles to
- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — role view; CDK patterns + pipeline integration
- [CDK v2 API Reference](https://docs.aws.amazon.com/cdk/api/v2/)
