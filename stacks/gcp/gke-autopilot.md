---
title: GKE Autopilot
description: Google-managed GKE node mode — per-pod billing, no node management, GPU/TPU support, K8s API surface without node ops.
product:
  name: GKE Autopilot
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect, ai-ml-engineer, sre-engineer]
  authoritative_url: https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview
  notes: "Per-pod billing model + GPU/TPU support evolving; default pod density and quota defaults changed in 2025."
---

## What it is

GKE Autopilot is GKE's managed-node mode. You author K8s manifests, Google handles nodes — provisioning, sizing, upgrading, securing. Pay per pod (CPU + memory + ephemeral storage), not per node.

Same control plane, release channels, Workload Identity, and Binary Authorization integration as [GKE Standard](/stacks/gcp/gke/) — the difference is who owns node operations.

Authoritative reference: [cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview).

## When to use

Pick Autopilot when:
- You want K8s API surface (CRDs, controllers, mesh) without operating nodes
- Workload utilization is moderate (per-pod billing wins below ~60-70% sustained)
- Team prefers `kubectl apply` over `gcloud run deploy` for everything
- You want GPU/TPU access without authoring node pool topology

Escalate to **GKE Standard** when Autopilot blocks something:
- DaemonSets (kube-system DaemonSets are allowed; user DaemonSets restricted)
- Privileged containers
- Custom CNI
- Specific node topology (e.g., bare-metal NVMe, custom OS images)
- Sustained utilization >70% (Standard wins on cost)

Don't pick Autopilot when:
- A [Cloud Run service](/stacks/gcp/cloud-run/) covers the workload — simpler, autoscales to zero
- Your team has no K8s practice and no reason to grow one

## 2025-2026 currency anchors

- **Per-pod billing** is the cost model — pay for CPU + memory + ephemeral storage requests on each running pod.
- **GPU support** (L4, A100, H100, H200) is GA on Autopilot; declarative via node selectors / accelerator manifests.
- **TPU support** (v5e, v6e/Trillium) is GA on Autopilot; same pattern.
- **Default pod density** and quota defaults changed in 2025 — verify against current docs if you're sizing carefully.
- **DaemonSet support** for kube-system extensions is allowed; user DaemonSets remain restricted.
- **Workload Identity is on by default** in Autopilot — no per-pod SA key risk.

## Patterns

### Create cluster

```bash
gcloud container clusters create-auto prod-cluster \
  --region=us-central1 \
  --release-channel=regular \
  --enable-private-nodes \
  --master-ipv4-cidr=172.16.0.0/28
```

### Deploy a service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  selector:
    matchLabels: { app: api }
  template:
    metadata:
      labels: { app: api }
    spec:
      serviceAccountName: api-ksa
      containers:
        - name: api
          image: us-central1-docker.pkg.dev/proj/repo/api:v1.0
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
          ports: [{ containerPort: 8080 }]
```

Autopilot enforces `requests` (you pay for them) and `limits` boundaries. Right-size requests; padded requests cost money.

### GPU pod

```yaml
spec:
  nodeSelector:
    cloud.google.com/gke-accelerator: nvidia-l4
  containers:
    - name: inference
      image: ...
      resources:
        limits:
          nvidia.com/gpu: 1
```

Autopilot provisions a GPU node behind the scenes; you don't author the node pool.

## Anti-patterns

- **Padded resource requests** — Autopilot bills on requests, not actual usage. Right-size or you're overpaying.
- **GKE Autopilot when Cloud Run suffices** — extra complexity, extra cost for stateless HTTP.
- **GKE Standard when Autopilot would do** — you pay for idle nodes you don't need to manage.
- **No HPA** — pods don't scale with load; you've replicated Compute Engine, not K8s.
- **DaemonSet attempts on Autopilot** — they'll be rejected; use a different pattern or fall back to Standard.

## Gotchas

- **Pod density per Autopilot node** is platform-managed and may differ from Standard expectations. If you're sizing per-pod carefully against memory, profile.
- **Image pulls count toward ephemeral storage** in some configurations — large image layers can push pods over the limit.
- **Autopilot doesn't expose node access** — no SSH, no `kubectl debug node`. Diagnosis must use pod-level logs / traces / probes.
- **Binary Authorization** can be enforced via `evaluation_mode: PROJECT_SINGLETON_POLICY_ENFORCE` on the cluster.

## Cross-references

- Related: [GKE](/stacks/gcp/gke/), [Cloud Run](/stacks/gcp/cloud-run/), [Anthos / GKE Enterprise](/stacks/gcp/anthos/), [Artifact Registry](/stacks/gcp/artifact-registry/)
- Roles: [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Authoritative: [cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
