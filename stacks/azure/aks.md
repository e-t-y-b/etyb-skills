---
title: AKS
description: Azure Kubernetes Service — AKS Automatic, LTS channels, Karpenter / Node Autoprovisioning, Workload Identity. Pick AKS only when the K8s ecosystem is the reason; otherwise prefer Container Apps.
product:
  name: AKS
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, security-engineer, backend-architect, sre-engineer]
  authoritative_url: https://learn.microsoft.com/azure/aks/
  notes: "AKS Automatic, LTS, Karpenter, Workload Identity all evolved 2024-25; Pod Identity retirement is a hard break."
---

## What it is

AKS is Microsoft's managed Kubernetes. The control plane is run by Azure; you own (or share with Microsoft, depending on mode) the worker nodes. As of 2026, AKS has two operating modes: **Automatic** (managed defaults) and **Standard** (you pick the knobs). Canonical reference: [AKS docs](https://learn.microsoft.com/azure/aks/).

## When to use

Pick AKS when one of these is true:

- You need the **K8s ecosystem** — Helm charts, Istio, custom operators, third-party CRDs.
- **Multi-team shared cluster** — namespace-level isolation, RBAC per team.
- **Custom networking** — Cilium policies, service mesh, advanced traffic management.
- **Specialized scheduling** — pod affinity, topology spread, taints/tolerations for hardware.
- **Regulated workloads with long K8s version pinning** — AKS LTS extends 1.27 / 1.30 past community EOL.

Don't default to AKS for "I have a containerized microservice with autoscaling and a Postgres." That's [Container Apps](/stacks/azure/container-apps/) — Dapr-native, KEDA-native, no cluster ops.

## 2025-2026 currency anchors

- **AKS Automatic** (GA 2024) — default for new clusters. Pre-wires HPA, VPA, KEDA, Karpenter, Azure Monitor, Azure Policy, Key Vault CSI driver, Workload Identity.
- **AKS Long-Term Support (LTS) channels** (GA 2025) — extended support for K8s versions beyond the standard community window. Pin 1.27 / 1.30 with LTS.
- **Supported K8s versions (2026-Q2):** 1.30 (community-supported through Q2 2026), 1.31, 1.32, 1.33; LTS covers 1.27 / 1.30.
- **Karpenter / Node Autoprovisioning** (GA 2025) — individual node provisioning beyond Cluster Autoscaler. Default in AKS Automatic.
- **Workload Identity** is the only supported pod-to-Azure auth. **Pod Identity + Pod Identity v2 are retired.** KEDA 2.15+ removed Pod Identity support entirely.
- **App Routing** add-on — managed NGINX ingress controller.
- **Managed Istio service mesh** add-on — alternative to self-managed Istio.
- **Image Cleaner** — auto-removes unused container images from nodes.
- **Cost Analysis** — cluster-level cost view in portal.
- **Artifact Streaming** (Preview) — lazy-load container images for faster cold starts.

## Patterns + anti-patterns

### Pattern: AKS Automatic as the default

Standard mode lets you turn off managed add-ons and rebuild from scratch. Don't, unless you have a stated reason. The managed add-ons are how Microsoft supports the cluster — fight them and you own the operability.

### Pattern: Workload Identity for pod-to-Azure auth

Standard configuration:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    azure.workload.identity/client-id: <UAMI-client-id>
---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: my-app
      containers:
      - name: app
        image: ...
```

The projected SA token is federated to Entra; the app uses `DefaultAzureCredential` and gets a managed identity token without local creds. See [Security Engineer on Azure](/stacks/azure/security-engineer/) for the full pattern.

### Pattern: Container Insights from cluster creation, cost-optimized

Enable Container Insights at cluster creation. Apply the **cost optimization preset** to bound ingestion; exclude system / non-prod namespaces; filter logs at agent level. Without this, Log Analytics ingestion on a large cluster will dominate observability cost.

### Pattern: Karpenter for elastic workloads

Karpenter (Node Autoprovisioning) provisions individual nodes sized to pod requests. Better bin-packing than Cluster Autoscaler; faster scale-up. Default in Automatic; opt-in for Standard: `--node-provisioning-mode Auto`.

### Pattern: GitOps via Flux v2 (managed extension)

Cluster syncs from Git repo. Drift detection + reconciliation. Available as Azure Arc-enabled K8s extension; works for AKS and Arc-attached clusters identically.

### Anti-pattern: AKS Standard by default

You give up Microsoft's pre-wired managed add-ons. Use Standard only when you have a specific reason (specific CNI choice, custom kubelet flags, untrusted add-ons).

### Anti-pattern: Pod Identity (legacy or v2)

Retired. If you upgrade KEDA to 2.15+ without migrating to Workload Identity first, your scalers go offline.

### Anti-pattern: Pinning to LTS when you can keep up

LTS has a cost premium. Use only when you genuinely can't keep up with the community release cadence.

### Anti-pattern: Treating AKS as the default for every containerized workload

If you don't need: third-party operators, Istio, multi-team shared cluster, specialized scheduling — use [Container Apps](/stacks/azure/container-apps/). You'll ship faster, pay less for idle nodes, and skip cluster ops entirely.

## Gotchas

- **Pod Identity → Workload Identity migration** is a hard break. KEDA 2.15+ broke. Plan it before upgrading KEDA.
- **Container Insights cost on a large cluster** can dominate observability spend. Apply cost preset; exclude non-prod namespaces; sample logs.
- **Karpenter respects pod requests strictly.** Misconfigured requests = wasted capacity (over-request) or evictions (under-request).
- **App Routing add-on is NGINX-based.** Migrating from custom NGINX controller works but watch annotation differences.
- **Cluster autoscaler vs Karpenter coexistence** — pick one. They will fight.
- **`kubectl` auth uses `kubelogin`** for Entra; not stock kubectl auth plugin.

## Cross-references

- [Container Apps](/stacks/azure/container-apps/) — the default when AKS isn't justified
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — day-2 operations (LTS, Karpenter, Workload Identity)
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — Workload Identity, network posture
- [SRE Engineer on Azure](/stacks/azure/sre-engineer/) — Container Insights, Managed Prometheus
- [AKS Workload Identity](https://learn.microsoft.com/azure/aks/workload-identity-overview)
- [AKS LTS](https://learn.microsoft.com/azure/aks/long-term-support)
- [AKS Automatic](https://learn.microsoft.com/azure/aks/intro-aks-automatic)
