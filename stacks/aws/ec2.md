---
title: EC2
description: Foundational virtual-machine compute on AWS — Graviton4 default, gp3 + io2 Block Express for storage, Spot for batch, Reserved Instances and Savings Plans for committed baseline.
product:
  name: EC2
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, sre-engineer]
  authoritative_url: https://docs.aws.amazon.com/ec2/
  notes: "Foundational surface stable; Graviton4 the default; Graviton5 (M9g) preview Dec 2025; Amazon Linux 2 EOL mid-2026."
---

## What it is

Amazon EC2 is the foundational virtual machine compute primitive — full OS access, broad instance family selection, integrated with Auto Scaling Groups, Spot, Reserved Instances, and the Savings Plans economics. Reach for EC2 when no managed AWS primitive fits the workload shape (databases AWS doesn't manage for you, message brokers, single-tenant services, full kernel control, custom AMIs).

Canonical surface: [docs.aws.amazon.com/ec2](https://docs.aws.amazon.com/ec2/).

## When to use

| Need | Use EC2? |
|---|---|
| Stateless HTTP API | No — use [Lambda](/stacks/aws/lambda/) or [ECS](/stacks/aws/ecs/)/[Fargate](/stacks/aws/fargate/) |
| Databases AWS doesn't manage for you (custom Postgres extensions, Cassandra, Elasticsearch self-managed) | Yes — EC2 with [io2 Block Express](#ebs-storage) |
| Message brokers (self-managed RabbitMQ, Kafka without MSK) | Yes — but evaluate [MSK Serverless](/stacks/aws/opensearch/) and [Amazon MQ](/stacks/aws/sqs/) first |
| Batch / ML training, fault-tolerant compute | Yes — Spot via ASG with mixed-instance policies, or [AWS Batch](#anti-patterns) |
| Long-running stateful workloads needing reserved pricing | Yes — Reserved Instances + Savings Plans |
| Anything Kubernetes-native | Use [EKS](/stacks/aws/eks/) with [Karpenter](/stacks/aws/karpenter/) instead of bare EC2 ASGs |

## 2025-2026 currency anchors

- **Graviton4 is the default.** ARM-first is the AWS posture across most managed services and EC2 itself. x86 is the exception you justify, not the default. **Graviton5 (M9g)** preview Dec 2025; volume in 2026.
- **gp3 EBS** is the default volume type — 80,000 max IOPS, 2 GiB/s throughput, 64 TiB max capacity. 20% cheaper than gp2 and 4x max IOPS.
- **io2 Block Express** for tier-1 OLTP and latency-critical workloads — 256,000 max IOPS, 4 GiB/s throughput, 99.999% durability. SRD protocol underneath.
- **NVMe-only Nitro instances** are now assumed; instance-store storage is local NVMe SSD across most families.
- **Amazon Linux 2 (AL2) end-of-life cadence:** standard support ended June 2025, maintenance support ends June 2026. **AL2023 is the default base AMI.** ParallelCluster 3.15 is the last release supporting AL2.
- **IMDSv2 mandatory** for new instances via SCP — IMDSv1 is a credential-leak vector.

## Patterns

### Instance family pick

| Family | Best for |
|---|---|
| **M-family (m7g, m8g)** | General-purpose; default starting point |
| **C-family (c7g, c8g)** | Compute-intensive; CPU-bound services, batch |
| **R-family (r7g, r8g)** | Memory-intensive; in-memory caches, large datasets |
| **X-family (x2iezn)** | Memory-monster; up to 24 TB RAM for SAP HANA and large in-memory DBs |
| **G/P-family (g5, p5, p6)** | GPU inference + training; Blackwell on p6 |
| **Trn/Inf-family** | Trainium2/3 for training, Inferentia2 for cost-optimized inference. See [SageMaker](/stacks/aws/sagemaker/). |
| **I/D-family** | Storage-optimized (local NVMe) |
| **T-family** | Burstable; dev/staging where steady-state is low |

### EBS storage

| Type | Max IOPS | Max Throughput | Max Size | Use case |
|---|---|---|---|---|
| **gp3** | 80,000 | 2 GiB/s | 64 TiB | Default for everything |
| **io2 Block Express** | 256,000 | 4 GiB/s | 64 TiB | Tier-1 OLTP, latency-critical |
| **st1** | 500 | 500 MiB/s | 16 TiB | Sequential (logs, data lakes) |
| **sc1** | 250 | 250 MiB/s | 16 TiB | Cold, infrequent |

gp3 is the default; io2 BX is the upgrade for I/O-bound tier-1 OLTP databases. Account-level EBS encryption-by-default should be on — every new volume KMS-encrypted.

### Mixed-instance ASGs for Spot

```yaml
# Mixed-instance policy with 3+ families, capacity-optimized allocation
MixedInstancesPolicy:
  InstancesDistribution:
    OnDemandPercentageAboveBaseCapacity: 25
    SpotAllocationStrategy: capacity-optimized
  LaunchTemplate:
    Overrides:
      - InstanceType: m7g.large
      - InstanceType: m8g.large
      - InstanceType: c7g.large
      - InstanceType: r7g.large
```

Spot interruption is real (2-minute warning). On EC2 + ASG, mixed-instance policies with 3+ families and capacity-optimized allocation. **Stateful workloads — never Spot.**

### Right-sizing

[AWS Compute Optimizer](https://aws.amazon.com/compute-optimizer/) ML recommendations applied monthly; over a year, typically 15-30% cost savings.

### Patching + access

- **SSM Patch Manager** with maintenance windows per environment.
- **SSM Session Manager** for shell access — no SSH ports open, fully CloudTrail-audited.
- **No SSH ports inbound** on prod fleets — period.

## Anti-patterns

- **AL2 base AMIs for new builds.** Use AL2023 — AL2 maintenance support ends June 2026.
- **x86 by default.** Migrate to Graviton; 20-40% savings, mostly drop-in for Linux.
- **gp2 volumes for new builds.** Always gp3.
- **Spot for stateful single-instance services.** Interruption = data loss.
- **No instance profile (no IAM role) on EC2.** Use IAM roles + STS, never long-lived access keys.
- **SSH bastion hosts.** Use Session Manager.
- **One AZ for production.** Distribute across 3 AZs.
- **No EBS snapshots scheduled.** Use [AWS Backup](#cross-references) with tag-based selection.

## Gotchas

- **Cross-AZ data transfer** ($0.01/GB each way) compounds when chatty workloads span AZs. Keep tightly-coupled services in the same AZ.
- **NVMe instance store is ephemeral** — terminating the instance wipes local NVMe. Never use for persistent state.
- **EC2 default soft quotas** are per-family per-region; check Service Quotas console before assuming you can launch 1,000 m8g instances.
- **`re:Invent` instance families ≠ available everywhere.** New families (e.g., p6, m9g) take months to roll out across regions; verify against the [instance type availability matrix](https://aws.amazon.com/ec2/instance-types/).

## Cross-references

- [`/stacks/aws/vpc/`](/stacks/aws/vpc/) — networking, security groups, NAT
- [`/stacks/aws/karpenter/`](/stacks/aws/karpenter/) — for EKS workloads, Karpenter manages EC2 nodes
- [`/stacks/aws/eks/`](/stacks/aws/eks/) — Kubernetes on EC2
- [`/stacks/aws/ecs/`](/stacks/aws/ecs/) — containers on EC2 (or Fargate)
- [`/stacks/aws/iam/`](/stacks/aws/iam/) — EC2 instance profiles
- [AWS Compute Optimizer](https://aws.amazon.com/compute-optimizer/) — right-sizing recommendations
- [AWS Backup](https://docs.aws.amazon.com/aws-backup/) — backup orchestration for EBS + EC2
