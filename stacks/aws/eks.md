---
title: EKS
description: "Managed Kubernetes on AWS — EKS Auto Mode (re:Invent 2024) is the default for new clusters; Karpenter v1 for node management; EKS Pod Identity over IRSA; Hybrid Nodes for on-prem extensions."
product:
  name: EKS
  stack: aws
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect, security-engineer, sre-engineer]
  authoritative_url: https://docs.aws.amazon.com/eks/
  notes: "Auto Mode + Karpenter v1 + Pod Identity + Hybrid Nodes are 2024-2026 additions; older guides build everything by hand."
---

## What it is

Amazon EKS is AWS's managed Kubernetes service. The control plane is fully managed; you bring (or let Auto Mode bring) the data plane via managed node groups, self-managed nodes, Fargate profiles, or Auto Mode + Karpenter.

Canonical surface: [docs.aws.amazon.com/eks](https://docs.aws.amazon.com/eks/).

## When to use

| Need | Use EKS? |
|---|---|
| K8s ecosystem (Helm, Argo, Istio, GPU operators) is required | Yes |
| Multi-cloud portability stance | Yes — Kubernetes API is the lingua franca |
| ML / GPU workloads with Kubernetes scheduling | Yes — `g5`/`p5`/`p6` nodes via Karpenter |
| "Ship a container to HTTPS in one step" | No — use [ECS Express Mode](/stacks/aws/ecs/) |
| Microservices on containers without K8s ecosystem need | No — [ECS + Fargate](/stacks/aws/ecs/) is simpler |
| Hybrid (on-prem + cloud) container orchestration | Yes — EKS Hybrid Nodes |

EKS adds an operational tax. If the team isn't already running K8s elsewhere and the workload doesn't need K8s-ecosystem tooling, pick ECS Express Mode and save 3-6 months of platform plumbing.

## 2025-2026 currency anchors

- **EKS Auto Mode** (re:Invent 2024) — managed compute, networking, storage with a single config flag. KMS encryption + capacity reservations + vended logs added through 2025-2026. New clusters in 2026 default to Auto Mode + Karpenter v1.
- **Karpenter v1** GA late 2024 — breaking CRD migration from `v1beta1` to `v1`. `NodePool` replaces `Provisioner`; `EC2NodeClass` replaces `AWSNodeTemplate`. See [`/stacks/aws/karpenter/`](/stacks/aws/karpenter/).
- **EKS Pod Identity** (re:Invent 2023, matured 2024-2025) is preferred over IRSA for new pod-to-AWS auth — simpler, faster credentials, cleaner trust policy.
- **EKS Hybrid Nodes** (re:Invent 2024) — on-prem nodes joining EKS clusters via dedicated networking.
- **Kubernetes versions** — supported versions roll forward quarterly; deprecated versions force upgrade.
- **AL2023 is the default node AMI** family — AL2 EOL mid-2026.
- **VPC CNI Network Policy** support GA — no Calico/Cilium required for basic NetworkPolicy enforcement.

## Patterns

### EKS Auto Mode

```typescript
import * as eks from 'aws-cdk-lib/aws-eks';

const cluster = new eks.Cluster(this, 'Cluster', {
  version: eks.KubernetesVersion.V1_31,
  vpc,
  defaultCapacity: 0,  // Auto Mode handles capacity
  authenticationMode: eks.AuthenticationMode.API_AND_CONFIG_MAP,
  endpointAccess: eks.EndpointAccess.PRIVATE,
  computeConfig: {
    enabled: true,
    nodePools: ['system', 'general-purpose'],
  },
  kubernetesNetworkConfig: {
    elasticLoadBalancing: { enabled: true },
  },
  storageConfig: {
    blockStorage: { enabled: true },
  },
  ipFamily: eks.IpFamily.IP_V4,
});
```

Auto Mode gives you Karpenter-managed compute (no node group sizing), default gp3 StorageClass, default ALB IngressClass, pod identity associations — all out of the box.

### Self-managed EKS (when Auto Mode doesn't fit)

Use self-managed when:
- Specialized node groups (GPUs with custom AMIs, hybrid nodes, bare metal).
- CNI other than VPC CNI (e.g., Cilium with eBPF).
- Custom Kubernetes versions or lifecycle conflicts with AWS-prescribed.

### Pod Identity > IRSA

```yaml
# EKS Pod Identity — simpler, no OIDC issuer to manage
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: orders
```

Association created via EKS API:
```bash
aws eks create-pod-identity-association \
  --cluster-name my-cluster \
  --namespace orders \
  --service-account app-sa \
  --role-arn arn:aws:iam::123456789012:role/AppRole
```

Pod Identity advantages over IRSA:
- No OIDC provider setup.
- Faster credential delivery (no token-exchange round trip).
- Cleaner trust policy (no `sub` claim wildcarding).
- Cluster-scoped, not per-role-trust.

Use IRSA only for cross-cluster workloads or when migration isn't justified. See [`/stacks/aws/iam/`](/stacks/aws/iam/) for IAM identity patterns.

### Pod security

- **Pod Security Standards (Restricted)** — disallow privileged, root, hostPath, hostNetwork, hostPID, hostIPC. Enforce via Kyverno or OPA Gatekeeper.
- **Network policies** — default deny; explicit allowlist. Calico, Cilium, or AWS-native (VPC CNI Network Policy).
- **GuardDuty Runtime Monitoring** — agentless or with the GuardDuty Agent for deeper visibility. See [`/stacks/aws/guardduty/`](/stacks/aws/guardduty/).
- **Signed images** — cosign + KMS-backed key; admission controller enforces signed-image-only.

### Karpenter v1 NodePool design

See [`/stacks/aws/karpenter/`](/stacks/aws/karpenter/) for the full v1 CRD shape. Quick reference:
- **Multi-architecture pools**: separate ARM64 (Graviton) and AMD64; let workload selectors pin.
- **Spot + On-Demand**: `values: ["spot", "on-demand"]` lets Karpenter pick cheapest.
- **System pool** on On-Demand only: separate NodePool with taints so kube-system/addons run on stable nodes.
- **GPU pool**: separate NodePool with GPU instance categories and `nvidia.com/gpu` resource hint.

## Anti-patterns

- **Karpenter `v1beta1` CRDs in new code.** `Provisioner` and `AWSNodeTemplate` are pre-v1. Migrate to `NodePool` and `EC2NodeClass`.
- **EKS with manually-sized node groups** when Auto Mode fits. Auto Mode + Karpenter v1 is the 2026 default.
- **IRSA for new clusters.** Use Pod Identity unless cross-cluster.
- **AL2 base AMIs.** Use AL2023.
- **EKS in a single AZ.** Always 3 AZs for the control plane and worker nodes.
- **Long-lived service account tokens** (Kubernetes pre-1.21 default). Modern bound-service-account-tokens are the default; verify.
- **Privileged containers without justification.** Pod Security Standards Restricted enforced.
- **No PodDisruptionBudgets** on production deployments. Karpenter respects PDBs during consolidation.

## Gotchas

- **EKS control plane cost** is $0.10/hr per cluster (~$73/mo) regardless of node count. Many small clusters cost more than one large cluster.
- **VPC CNI IP exhaustion** — each pod gets an ENI IP; large clusters need careful subnet sizing. Custom networking with prefix delegation extends capacity.
- **Karpenter consolidation can be aggressive** — set `consolidateAfter` carefully and use PDBs to protect critical workloads.
- **Pod Identity is cluster-scoped** — for cross-cluster pod-to-AWS auth, you still need IRSA or per-cluster associations.
- **Kubernetes version EOL** — AWS provides extended support for EOL versions at additional cost; plan upgrades quarterly.
- **Service Account token mount** — modern projected tokens are short-lived (1hr default). Workloads that cache the token need refresh logic.

## Cross-references

- [`/stacks/aws/karpenter/`](/stacks/aws/karpenter/) — node management for EKS
- [`/stacks/aws/iam/`](/stacks/aws/iam/) — Pod Identity vs IRSA
- [`/stacks/aws/ec2/`](/stacks/aws/ec2/) — underlying compute
- [`/stacks/aws/vpc/`](/stacks/aws/vpc/) — VPC CNI, private clusters, endpoints
- [`/stacks/aws/cloudwatch/`](/stacks/aws/cloudwatch/) — Container Insights + OTel
- [`/stacks/aws/guardduty/`](/stacks/aws/guardduty/) — Runtime Monitoring
- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — role view; cluster IaC patterns
- [Karpenter migration guide](https://karpenter.sh/v1.0/upgrading/v1-migration/)
- [EKS Pod Identity docs](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
