---
title: ECS
description: Container orchestration on AWS — Fargate as the modern default, ECS Express Mode (Nov 2025) for "container to HTTPS in one step", Service Connect for east-west traffic, Graviton for cost.
product:
  name: ECS
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, system-architect, sre-engineer]
  authoritative_url: https://docs.aws.amazon.com/ecs/
  notes: "ECS Express Mode (Nov 2025) replaces Copilot CLI (EOL June 2026); App Runner in maintenance. Service Connect mature; Graviton/ARM64 default."
---

## What it is

Amazon ECS is AWS's native container orchestrator. Task definitions describe containers; Services maintain a desired count of tasks; tasks run on Fargate (serverless) or EC2 (self-managed) launch types. Tightly integrated with ALB/NLB, IAM, CloudWatch, and VPC.

Canonical surface: [docs.aws.amazon.com/ecs](https://docs.aws.amazon.com/ecs/).

## When to use

| Need | Use ECS? |
|---|---|
| "Ship a container to HTTPS in one step" | Yes — [ECS Express Mode](#ecs-express-mode-nov-2025) |
| Microservices on containers, team doesn't need Kubernetes ecosystem | Yes — ECS + Fargate; cheaper operationally than EKS |
| K8s-ecosystem workloads (Helm, Argo, Istio, GPU operators) | No — use [EKS](/stacks/aws/eks/) |
| Event-driven, short-lived work | Lambda first — but ECS for stateful or long-running async work |
| Workloads needing kernel/OS access | No — use [EC2](/stacks/aws/ec2/) |

The shape teams flip-flop on most: Lambda → ECS (when cold-start hits) → EKS (when ecosystem need emerges). Make the call up front based on workload, not team identity. See [the system-architect overlay](/stacks/aws/system-architect/) for the full compute-primitive matrix.

## 2025-2026 currency anchors

- **ECS Express Mode** (Nov 2025) replaces Copilot CLI (EOL **June 2026**) and App Runner (maintenance mode) for "ship a container to HTTPS in one step."
- **AWS Copilot CLI** is EOL **June 2026** — flag immediately if proposed for new pipelines.
- **AWS App Runner** is in **maintenance mode** — no new feature investment. Migrate net-new to ECS Express Mode.
- **ARM64 (Graviton) is the default `cpuArchitecture`** — 20% cheaper Fargate.
- **CDK now ships built-in Linear/Canary ECS deployment strategies** via `aws-cdk-lib`; no need to wire CodeDeploy app + deployment groups by hand.
- **ECS Service Connect** matured into the default east-west service-to-service traffic shape (CloudMap-based DNS + observability without sidecars).
- **VPC Lattice** added L7 cross-VPC / cross-account integration with IAM auth — see [`/stacks/aws/vpc/`](/stacks/aws/vpc/).

## Patterns

### ECS Express Mode (Nov 2025)

One command to deploy: Fargate service, ALB with TLS (ACM), autoscaling, CloudWatch dashboards + alarms, VPC networking with sane defaults.

```bash
aws ecs create-service \
  --cluster default \
  --service-name my-api \
  --launch-type FARGATE \
  --express-mode-config enabled=true \
  --task-definition my-api:1
```

No additional charge beyond Fargate + ALB. Available in all ECS+Fargate regions.

### CDK for ECS (full control)

```typescript
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecs_patterns from 'aws-cdk-lib/aws-ecs-patterns';

const service = new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'Api', {
  cluster,
  taskImageOptions: {
    image: ecs.ContainerImage.fromEcrRepository(repo, 'latest'),
    containerPort: 8080,
    environment: { NODE_ENV: 'production' },
    secrets: { DB_PASSWORD: ecs.Secret.fromSecretsManager(dbSecret, 'password') },
  },
  desiredCount: 2,
  runtimePlatform: {
    cpuArchitecture: ecs.CpuArchitecture.ARM64,  // Graviton
    operatingSystemFamily: ecs.OperatingSystemFamily.LINUX,
  },
  circuitBreaker: { enable: true, rollback: true },  // Auto-rollback on failed deploy
  healthCheckGracePeriod: Duration.seconds(60),
});

service.service.autoScaleTaskCount({ minCapacity: 2, maxCapacity: 20 })
  .scaleOnCpuUtilization('CpuScaling', { targetUtilizationPercent: 70 });
```

Key wins: ARM64, circuit breaker + rollback, asymmetric scaling cooldowns, health check tuned for Fargate cold-start.

### Task definition essentials

- **`runtimePlatform: ARM64`** — Graviton, 20% cheaper.
- **`awslogs` non-blocking mode** — application doesn't block on CloudWatch Logs ingestion under load.
- **Separate execution role and task role** — execution role pulls images + ships logs; task role is what the app code uses (least privilege).
- **Secrets via [Secrets Manager](/stacks/aws/secrets-manager/)** — no plaintext DB passwords in task definitions.
- **Health check with start period** — gives the app time to boot before failing health.

### Service Connect vs ALB target group

| Pattern | Use when |
|---|---|
| **ALB → Service** | Public-facing HTTP/HTTPS, WebSocket, multiple paths to multiple services |
| **NLB → Service** | TCP/UDP traffic, ultra-high throughput, static IP requirements |
| **Service Connect** | East-west service-to-service traffic with DNS + observability (CloudMap-based) |
| **VPC Lattice** | Cross-VPC / cross-account service-to-service with IAM auth and L7 policies |

Typical 2026 microservice topology: CloudFront → ALB → ECS Service for north-south; Service Connect for same-VPC east-west; VPC Lattice for cross-VPC.

### Deployment strategies

```typescript
service.deploymentController = {
  type: ecs.DeploymentControllerType.CODE_DEPLOY,
};

new codedeploy.EcsDeploymentGroup(this, 'Deploy', {
  service: service.service,
  blueGreenDeploymentConfig: {
    blueTargetGroup: service.targetGroup,
    greenTargetGroup: greenTg,
    listener: service.listener,
  },
  deploymentConfig: codedeploy.EcsDeploymentConfig.CANARY_10PERCENT_5MINUTES,
  autoRollback: { failedDeployment: true, deploymentInAlarm: true },
  alarms: [errorRateAlarm, latencyAlarm],
});
```

**Set alarms before configuring deployment groups.** CodeDeploy uses CloudWatch alarms to decide rollback; without alarms, only infra failure triggers rollback.

### Auto-scaling

Target tracking with CPU 70% primary + ALBRequestCountPerTarget secondary. **Asymmetric cooldowns** — scale-out fast (1min), scale-in slow (5min). Aggressive scale-in causes thrashing.

## Anti-patterns

- **Copilot CLI for new pipelines.** EOL June 2026.
- **App Runner for new services.** Maintenance mode; use ECS Express Mode.
- **Bridge-mode networking on Fargate.** Always `awsvpc` mode.
- **Shared execution + task role.** Separate them; task role gets app permissions, execution role only pulls images and ships logs.
- **Plaintext secrets in task definitions.** Always Secrets Manager / Parameter Store.
- **Health check that fires before app is ready.** Configure `startPeriod`.
- **Mutable image tags (`:latest`).** Use immutable tags via [ECR lifecycle policy](#cross-references).
- **No circuit breaker on deployments.** Auto-rollback is a single flag.

## Gotchas

- **Fargate Spot task interruption** — SIGTERM arrives 2 minutes before. Stateless workloads only.
- **Service Connect requires Cloud Map namespace** — set up at cluster level once.
- **awslogs blocking mode** drops application throughput under log pressure. Use `mode=non-blocking` with a bounded buffer.
- **Tasks per service quota** is 5,000 by default — request increase before launch if you'll exceed.
- **Cross-AZ data transfer ($0.01/GB each way)** compounds if Service Connect routes traffic across AZs.

## Cross-references

- [`/stacks/aws/fargate/`](/stacks/aws/fargate/) — the serverless launch type
- [`/stacks/aws/eks/`](/stacks/aws/eks/) — alternative for K8s-ecosystem workloads
- [`/stacks/aws/vpc/`](/stacks/aws/vpc/) — networking, VPC Lattice, Service Connect
- [`/stacks/aws/cdk/`](/stacks/aws/cdk/) — CDK constructs for ECS
- [`/stacks/aws/cloudwatch/`](/stacks/aws/cloudwatch/) — Container Insights, dashboards
- [`/stacks/aws/iam/`](/stacks/aws/iam/) — task role, execution role
- [`/stacks/aws/backend-architect/`](/stacks/aws/backend-architect/) — role view; task definition idioms
- [ECR lifecycle policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html)
