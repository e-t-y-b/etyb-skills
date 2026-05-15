---
title: Compute Engine
description: GCP VMs — the foundational compute layer; C4A/Axion Arm, Spot VMs up to 91% off, CUDs for committed spend, GPU/TPU families.
product:
  name: Compute Engine
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, ai-ml-engineer, sre-engineer]
  authoritative_url: https://cloud.google.com/compute/docs
  notes: "Foundational; mature. Current-gen families C4A (Arm/Axion), N4, C4, E2; Spot up to 91% off, CUDs 1yr 37% / 3yr 57%."
---

## What it is

Compute Engine is GCP's foundational IaaS layer — VMs you provision, size, and manage. The underlying compute substrate for [GKE](/stacks/gcp/gke/), the host for specialized workloads (HPC, ML training, custom OS, SAP, Windows), and the fallback when serverless / managed K8s don't fit.

The 2026 question on Compute Engine isn't "should I use VMs?" — usually you shouldn't if [Cloud Run](/stacks/gcp/cloud-run/) or [GKE Autopilot](/stacks/gcp/gke-autopilot/) covers the workload. It's "what machine type and pricing model?"

Authoritative reference: [cloud.google.com/compute/docs](https://cloud.google.com/compute/docs).

## When to use

Pick Compute Engine when:
- Workload needs raw OS access, custom kernel, specific drivers
- HPC, ML training with custom orchestration (not Vertex AI Pipelines)
- Legacy software requires Windows / specific Linux distros
- SAP, Oracle, or other ISV workloads that target VMs
- GKE Standard node pools are the underlying substrate

Don't use Compute Engine when:
- The workload is a stateless container — [Cloud Run](/stacks/gcp/cloud-run/) is simpler
- The workload is a Kubernetes workload — [GKE Autopilot](/stacks/gcp/gke-autopilot/) or [GKE Standard](/stacks/gcp/gke/) is the right shape

## 2025-2026 currency anchors

- **C4A (Arm/Axion)** — Google's Arm-based VMs are 20-40% cheaper than equivalent x86 for compatible workloads. The default for Arm-compatible code.
- **N4 / C4 / E2** — current-gen x86 families; pick by perf-per-dollar profile of your workload.
- **Spot VMs** up to 91% off on-demand; right for fault-tolerant batch / CI / training where preemption is acceptable. Combine with checkpoint frequency.
- **CUDs (Committed Use Discounts)**: 1-year 37%, 3-year 57%. The standard lever for steady-state cost optimization.
- **GPU families**: NVIDIA A3 (H100), A3 Ultra (H200, 141 GB HBM3e), G2 (L4, 24 GB), L40S — see [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/) for selection.
- **TPU families**: v5e (cost-optimized), v6e (Trillium, training-optimized), v7 (Ironwood, inference-optimized).
- **Confidential VMs** — AMD SEV-SNP and Intel TDX; memory encryption for sensitive workloads.
- **OS Login** is the audited SSH access pattern; org-policy `compute.requireOsLogin` mandatory in regulated orgs.

## Patterns

### Create a VM

```bash
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --machine-type=c4-standard-4 \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --service-account=workload-runtime@proj.iam.gserviceaccount.com \
  --scopes=cloud-platform \
  --network=projects/proj/global/networks/prod-vpc \
  --subnet=projects/proj/regions/us-central1/subnetworks/workloads-subnet \
  --no-address  # internal IP only
```

Key choices:
- **`--service-account`** with least-privilege bindings; not the default Compute Engine SA.
- **`--no-address`** for internal-only; pair with Cloud NAT for outbound.
- **`--scopes=cloud-platform`** is the common-but-loose default; tighten when you can.

### Managed Instance Groups (MIGs)

For fleets of stateless VMs behind a Load Balancer:

```bash
gcloud compute instance-templates create web-template \
  --machine-type=c4-standard-2 \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud

gcloud compute instance-groups managed create web-mig \
  --template=web-template \
  --size=3 \
  --region=us-central1 \
  --health-check=web-health-check
```

### Spot VMs for batch

```bash
gcloud compute instances create batch-worker \
  --provisioning-model=SPOT \
  --instance-termination-action=DELETE \
  --machine-type=n4-standard-8
```

Spot saves 60-91% but you can be preempted with 30s notice. Right for: training (with checkpointing), CI runners, batch ETL, ML inference with retries.

### CUDs and rightsizing

- **Active Assist Recommender** continuously analyzes VM usage; flags over-provisioned VMs and CUD opportunities.
- **CUDs** are flexible (spend-based) or resource-based. Spend-based CUDs auto-apply across machine families and regions — generally lower commit risk.

## Anti-patterns

- **Compute Engine for stateless containers** — [Cloud Run](/stacks/gcp/cloud-run/) is simpler and not deprecated.
- **Default Compute Engine SA** as runtime SA — over-privileged; bind a per-workload SA.
- **`scopes=cloud-platform`** with no IAM tightening — broad scope is a security smell.
- **No CUDs on steady workloads** — leaving 37-57% discount on the table.
- **Public IPs on production VMs** — disable; use Cloud NAT + Cloud Identity-Aware Proxy for admin access.
- **Disabling OS Login** — breaks audit trail on SSH.

## Gotchas

- **Sole-tenant nodes** when you need physical isolation for licensing — uncommon but worth knowing about.
- **Spot preemption** is delivered as ACPI G2 soft-off + 30s grace; instrument graceful shutdown.
- **Persistent Disk types**: pd-ssd, pd-balanced, pd-extreme, Hyperdisk — different perf/cost profiles. Pick deliberately.
- **GPU quota** is per-region per-family and often the bottleneck; request increases in advance for large training runs.

## Cross-references

- Related: [GKE](/stacks/gcp/gke/) (node pool substrate), [Cloud Run](/stacks/gcp/cloud-run/), [VPC](/stacks/gcp/vpc/), [Cloud KMS](/stacks/gcp/cloud-kms/) (CMEK on disks)
- Roles: [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/), [ai-ml-engineer on GCP](/stacks/gcp/ai-ml-engineer/)
- Authoritative: [cloud.google.com/compute/docs](https://cloud.google.com/compute/docs)
