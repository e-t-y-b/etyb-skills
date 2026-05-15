---
title: Fargate
description: Serverless container compute substrate for ECS and EKS — Graviton (ARM64) default, Fargate Spot for fault-tolerant workloads, no instance sizing.
product:
  name: Fargate
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, system-architect]
  authoritative_url: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html
  notes: "Mature serverless container substrate; Graviton is default; Fargate Spot SIGTERM 2-minute warning semantics stable."
---

## What it is

AWS Fargate is the serverless compute engine for containers — you specify CPU/memory at the task level (ECS) or pod level (EKS), and Fargate provisions and manages the underlying infrastructure. No EC2 instances to size or patch.

Canonical surface: [docs.aws.amazon.com/fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html).

## When to use

| Need | Use Fargate? |
|---|---|
| ECS / EKS workloads without managing nodes | Yes — Fargate is the default launch type |
| Spiky / unpredictable container workloads | Yes — no idle instance cost |
| Need custom AMIs, kernel modules, or GPU types | No — use [EC2](/stacks/aws/ec2/) launch type or self-managed nodes |
| Cost-optimized batch with interruption tolerance | Yes — Fargate Spot (up to 70% savings) |
| Long-running stateful workloads | Possible but EC2 + Reserved Instances often cheaper |

## 2025-2026 currency anchors

- **ARM64 (Graviton) is the default `cpuArchitecture`** — 20% cheaper than x86 at the same CPU/memory.
- **Fargate Spot for ECS** mature; for EKS, GA via managed Fargate profiles.
- **Compute Savings Plans cover Fargate** — 66% off at 1yr, 72% at 3yr.
- **Ephemeral storage** default is 20 GiB; expandable to 200 GiB per task.

## Patterns

### Task / pod sizing

| CPU | Memory range |
|---|---|
| 0.25 vCPU | 0.5, 1, 2 GB |
| 0.5 vCPU | 1, 2, 3, 4 GB |
| 1 vCPU | 2-8 GB |
| 2 vCPU | 4-16 GB |
| 4 vCPU | 8-30 GB |
| 8 vCPU | 16-60 GB |
| 16 vCPU | 32-120 GB |

Memory increments are 1 GB up to 8 vCPU; 4 GB increments above. Pick the smallest tier that meets requirements; Compute Optimizer recommendations after baseline.

### Fargate Spot

For ECS/EKS fault-tolerant workloads:
- 70%+ discount vs on-demand.
- SIGTERM arrives 2 minutes before reclaim.
- Application must handle graceful shutdown — drain connections, checkpoint state, exit.
- Mixed capacity providers: `FARGATE` and `FARGATE_SPOT` with weights for hybrid.

```typescript
const cluster = new ecs.Cluster(this, 'Cluster', {
  vpc,
  capacityProviders: ['FARGATE', 'FARGATE_SPOT'],
});

new ecs.FargateService(this, 'Service', {
  cluster,
  taskDefinition,
  capacityProviderStrategies: [
    { capacityProvider: 'FARGATE_SPOT', weight: 4 },
    { capacityProvider: 'FARGATE', weight: 1 },  // baseline on-demand
  ],
});
```

### Ephemeral storage

Default 20 GiB; expand up to 200 GiB via `ephemeralStorage` in task definition. For shared state across tasks, mount EFS instead.

### Networking — `awsvpc` mode only

Fargate always uses `awsvpc` networking — each task gets its own ENI with an IP in your subnet. Plan subnet capacity accordingly. See [VPC](/stacks/aws/vpc/) for CIDR planning.

### Graviton

```typescript
runtimePlatform: {
  cpuArchitecture: ecs.CpuArchitecture.ARM64,
  operatingSystemFamily: ecs.OperatingSystemFamily.LINUX,
},
```

20% cheaper Fargate; most Linux containers run unchanged on ARM64. Multi-arch Docker builds via `docker buildx`.

## Anti-patterns

- **x86 by default.** Use ARM64 unless an image / dep doesn't compile.
- **Fargate Spot for stateful or single-instance services.** Interruption = data loss / outage.
- **Oversized tasks "for safety".** Compute Optimizer + monitoring tells you actual usage.
- **Mounting EFS for cold storage.** Use S3 + signed URLs.
- **Tiny tasks with chatty cross-AZ traffic.** Pin to fewer AZs or collapse to one larger task.

## Gotchas

- **Cold task start time** is ~30-60s depending on image size and pull cache. For latency-sensitive workloads, keep a minimum task count > 0 or use [Lambda](/stacks/aws/lambda/) with SnapStart.
- **No instance store** — Fargate tasks only have ephemeral storage attached to the task lifecycle.
- **Image size matters** for cold start — multi-stage Docker builds, distroless base images.
- **Per-AZ ENI quotas** — running thousands of tasks consumes ENIs; check VPC quotas before launch.

## Cross-references

- [`/stacks/aws/ecs/`](/stacks/aws/ecs/) — orchestration layer
- [`/stacks/aws/eks/`](/stacks/aws/eks/) — Fargate profiles for K8s
- [`/stacks/aws/ec2/`](/stacks/aws/ec2/) — alternative launch type when you need OS control
- [`/stacks/aws/vpc/`](/stacks/aws/vpc/) — networking, subnet sizing
- [AWS Fargate pricing](https://aws.amazon.com/fargate/pricing/)
