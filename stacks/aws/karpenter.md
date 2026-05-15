---
title: Karpenter
description: Kubernetes node autoscaler optimized for AWS — v1 GA late 2024 with breaking CRD migration. NodePool and EC2NodeClass replace Provisioner and AWSNodeTemplate.
product:
  name: Karpenter
  stack: aws
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect, sre-engineer]
  authoritative_url: https://karpenter.sh/
  notes: "v1 GA late 2024; breaking CRD migration from v1beta1 is a hard step LLMs often miss; new NodePool/NodeClass shape."
---

## What it is

Karpenter is the AWS-native Kubernetes node autoscaler — it observes unschedulable pods, picks instance types that fit (across families, sizes, capacity types), launches EC2 nodes directly (no Auto Scaling Group), and consolidates by terminating underutilized nodes. Built into [EKS Auto Mode](/stacks/aws/eks/).

Canonical surface: [karpenter.sh](https://karpenter.sh/).

## When to use

| Need | Use Karpenter? |
|---|---|
| EKS cluster needing dynamic node provisioning | Yes — default node autoscaler |
| Karpenter-on-non-EKS Kubernetes (kops, etc.) | Yes, but more setup |
| Static node groups that rarely change | No — managed node groups suffice |
| GPU workloads with bursty demand | Yes — Karpenter NodePool for GPU instance types |

## 2025-2026 currency anchors

- **Karpenter v1 GA late 2024** with breaking CRD migration:
  - `Provisioner` → `NodePool`
  - `AWSNodeTemplate` → `EC2NodeClass`
  - API group `karpenter.sh/v1beta1` → `karpenter.sh/v1`
  - Disruption controls first-class (`spec.disruption.consolidationPolicy`, `spec.disruption.expireAfter`).
- **Spot-to-spot consolidation** matured — Karpenter can replace spot nodes with cheaper spot when prices shift.
- **AL2023** is the default `amiFamily` (AL2 EOL mid-2026).
- **Integration with EKS Auto Mode** — Karpenter v1 is what Auto Mode runs under the hood.

If you find configs with `apiVersion: karpenter.sh/v1beta1`, `kind: Provisioner`, or `kind: AWSNodeTemplate` — they're pre-v1. Migrate.

## Patterns

### v1 NodePool + EC2NodeClass

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["arm64"]   # Graviton default
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["m", "c", "r"]
        - key: karpenter.k8s.aws/instance-cpu
          operator: In
          values: ["2", "4", "8", "16"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      taints: []
      expireAfter: 720h  # 30 days
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
  limits:
    cpu: 1000
    memory: 1000Gi
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023   # AL2 EOL — use AL2023
  role: KarpenterNodeRole-${CLUSTER}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${CLUSTER}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${CLUSTER}
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 50Gi
        volumeType: gp3
        encrypted: true
```

### NodePool design patterns

- **Multi-architecture pools**: separate ARM64 and AMD64; pin workloads via node selectors. Most stateless workloads run on ARM64 (Graviton) — 20% cheaper.
- **Spot + On-Demand mixed**: `values: ["spot", "on-demand"]` lets Karpenter pick cheapest. Add `spot-to-spot consolidation` for stable spot pricing.
- **System workloads on On-Demand only**: separate NodePool with `taints` so `kube-system`, addons, monitoring run on stable nodes.
- **GPU pools**: separate NodePool with GPU instance categories (`g5`, `p4`, `p5`, `p6`) and the `nvidia.com/gpu` resource hint.

### Disruption controls

- **`consolidationPolicy: WhenEmptyOrUnderutilized`** — Karpenter consolidates aggressively; pair with PodDisruptionBudgets to protect critical workloads.
- **`consolidateAfter`** — minimum idle time before consolidation triggers; default 0s, 30s reduces churn.
- **`expireAfter`** — periodic node replacement for security/refresh (e.g., 720h = 30 days).
- **`Budget`** — limit how many nodes can be disrupted at once (percent or count).

## Anti-patterns

- **`v1beta1` CRDs** (`Provisioner`, `AWSNodeTemplate`) in 2026. Pre-v1; migrate.
- **One NodePool for everything** — separate by tier (system / general / GPU / spot-only).
- **No PodDisruptionBudgets** on critical workloads. Karpenter will consolidate aggressively without them.
- **AL2 AMI family.** Use AL2023.
- **Cluster Autoscaler + Karpenter together.** Pick one; running both causes thrash.
- **`expireAfter` set to "Never"** — periodic node replacement is part of patching hygiene.

## Gotchas

- **`spec.template.spec.requirements`** is the v1 schema; old `spec.requirements` is wrong.
- **EC2NodeClass `role`** must be the **role name**, not ARN.
- **Karpenter controller IAM permissions** are extensive — use the AWS-provided policy as baseline.
- **Capacity-type spot interruptions** trigger node drain; pod restart on a new node. Stateless workloads only on spot.
- **Pod resource requests must be accurate** — Karpenter sizes nodes from requests. Wrong requests = wrong node sizing.

## Cross-references

- [`/stacks/aws/eks/`](/stacks/aws/eks/) — Karpenter v1 is what Auto Mode runs
- [`/stacks/aws/ec2/`](/stacks/aws/ec2/) — underlying compute, instance family selection
- [`/stacks/aws/devops-engineer/`](/stacks/aws/devops-engineer/) — role view; NodePool design
- [Karpenter migration guide](https://karpenter.sh/v1.0/upgrading/v1-migration/) — canonical v1 migration steps
- [Karpenter docs (v1)](https://karpenter.sh/docs/)
