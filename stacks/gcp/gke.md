---
title: GKE
description: Google Kubernetes Engine — managed K8s with regional clusters, release channels, Workload Identity, Binary Authorization, GPU/TPU node pools.
product:
  name: GKE
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, security-engineer, sre-engineer, ai-ml-engineer]
  authoritative_url: https://cloud.google.com/kubernetes-engine/docs
  notes: "Release channels (RAPID/REGULAR/STABLE) mature; auto-upgrade discipline mandatory; Workload Identity is default."
---

## What it is

GKE is Google's managed Kubernetes Engine — two operating modes:

- **GKE Standard** — you manage node pools, scale them, taint them. Full K8s control.
- **GKE Autopilot** — Google manages nodes; you only manage pods. Per-pod billing.

Both modes share the same control plane, release channels, Workload Identity model, and integration with [Artifact Registry](/stacks/gcp/artifact-registry/), [Cloud Build](/stacks/gcp/cloud-build/), and [Cloud Deploy](/stacks/gcp/cloud-deploy/). This page covers Standard mode and shared GKE concepts; see [GKE Autopilot](/stacks/gcp/gke-autopilot/) for the managed-node mode specifics.

Authoritative reference: [cloud.google.com/kubernetes-engine/docs](https://cloud.google.com/kubernetes-engine/docs).

## When to use

Pick GKE Standard when:
- You need full K8s control: DaemonSets, privileged pods, custom CNI, eBPF tooling, specific node topology, GPU/TPU node pools you size yourself
- Sustained utilization is high and you want node-pool cost predictability
- You have a mature K8s practice and prefer it over Cloud Run's serverless model

Pick GKE Autopilot (see [GKE Autopilot](/stacks/gcp/gke-autopilot/)) when:
- You want K8s API surface without operating nodes
- Per-pod billing is acceptable

Don't pick GKE when:
- A [Cloud Run service](/stacks/gcp/cloud-run/) covers the workload — Cloud Run gen2 closed most of the gaps that pushed teams to K8s
- You don't have K8s fluency on the team — operational tax is real

## 2025-2026 currency anchors

- **Release channels matured**: RAPID (latest features, test envs), REGULAR (prod default), STABLE (risk-averse).
- **Auto-upgrade is on by default in Autopilot**; in Standard, configure maintenance windows + exclusions. **Never disable auto-upgrade in prod** — you'll fall behind and face leapfrog risk.
- **Workload Identity** (GKE-side) maps Kubernetes service accounts to GCP service accounts. Same security posture as Cloud Run runtime SA.
- **Binary Authorization** integration mature; sign at build, verify at deploy.
- **`gke-gcloud-auth-plugin`** is the kubectl auth path (replaces in-tree auth removed in K8s 1.26+).
- **C4A (Arm/Axion) node pools** — 20-40% cheaper than x86 for compatible workloads.
- **Managed OpenTelemetry for GKE** auto-scales the OTel Collector; no DaemonSet management.

## Patterns

### Regional private cluster with Workload Identity + Binary Authorization

```bash
gcloud container clusters create prod-cluster \
  --region=us-central1 \
  --release-channel=regular \
  --enable-private-nodes \
  --enable-private-endpoint=false \
  --master-ipv4-cidr=172.16.0.0/28 \
  --workload-pool=proj.svc.id.goog \
  --enable-shielded-nodes \
  --enable-binauthz
```

**Always pick regional** for prod (control plane + nodes across 3 zones), not zonal.

### Node pool patterns (Standard only)

- **Separate node pools** for system workloads (kube-system) and application workloads
- **Spot node pool** for batch / fault-tolerant workloads — taint + pod toleration
- **GPU node pool** with taints; app pods tolerate the taint
- **C4A (Arm) node pool** for Arm-compatible workloads — 20-40% cost savings

### Workload Identity binding

```bash
gcloud iam service-accounts add-iam-policy-binding gsa@proj.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="serviceAccount:proj.svc.id.goog[my-namespace/my-ksa]"

kubectl annotate serviceaccount my-ksa \
  --namespace=my-namespace \
  iam.gke.io/gcp-service-account=gsa@proj.iam.gserviceaccount.com
```

Pod uses KSA → KSA is bound to GSA → pod gets GSA's IAM permissions transparently. **No service account keys mounted into pods.**

### Inference serving (KServe + vLLM)

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: llama-3-70b
spec:
  predictor:
    minReplicas: 1
    maxReplicas: 5
    nodeSelector:
      cloud.google.com/gke-accelerator: nvidia-h100-80gb
    containers:
      - name: kserve-container
        image: vllm/vllm-openai:latest
        args:
          - "--model=/mnt/models"
          - "--tensor-parallel-size=8"
        resources:
          limits:
            nvidia.com/gpu: 8
```

For multi-GPU model parallelism and custom serving stacks, GKE beats [Cloud Run](/stacks/gcp/cloud-run/) GPU on cost/perf. See [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/) for accelerator selection guidance.

## Anti-patterns

- **GKE Standard for every workload** — you'll spend more time on node-pool upgrades and capacity planning than on the application. Default to Cloud Run; promote to GKE Autopilot when you need K8s API; GKE Standard only when Autopilot blocks something specific.
- **Auto-upgrade disabled in prod** — patches don't apply, CVEs accumulate, version eventually deprecates.
- **Zonal cluster in prod** — control plane down on zonal outage; always regional.
- **No taints on spot node pool** — workloads schedule on spot, get preempted, you wonder why.
- **No Workload Identity** — pods use SA JSON keys; audit red flag.
- **No Binary Authorization on regulated workloads** — untrusted image risk.
- **Default VPC** — disable at org policy level; design VPCs deliberately.

## Gotchas

- **Maintenance windows + exclusions** are how you keep auto-upgrade tame in Standard. Don't disable upgrade; constrain when.
- **`gke-gcloud-auth-plugin`** must be installed locally for `kubectl` against GKE 1.26+ (in-tree auth removed). Install via `gcloud components install`.
- **Node pool upgrades cascade** if you have lots of pools — stagger them across maintenance windows.
- **Service Mesh**: Anthos Service Mesh is the managed Istio path; for simple cases, consider whether you need a mesh at all (Cloud Run + GLB covers a lot).
- **Cluster Autoscaler** scales node pools; **Horizontal Pod Autoscaler** scales pods within nodes. Both must be configured for elastic workloads.

## Cross-references

- Related: [GKE Autopilot](/stacks/gcp/gke-autopilot/), [Cloud Run](/stacks/gcp/cloud-run/), [Anthos / GKE Enterprise](/stacks/gcp/anthos/), [Artifact Registry](/stacks/gcp/artifact-registry/), [Cloud Deploy](/stacks/gcp/cloud-deploy/), [Binary Authorization via Cloud Build](/stacks/gcp/cloud-build/)
- Roles: [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/), [security-engineer on GCP](/stacks/gcp/security-engineer/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Authoritative: [cloud.google.com/kubernetes-engine/docs](https://cloud.google.com/kubernetes-engine/docs)
