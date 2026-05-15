---
title: Anthos / GKE Enterprise
description: Multi-cluster fleet management — GKE on AWS/Azure, Distributed Cloud (bare-metal, edge), Config Sync, Policy Controller, Cloud Service Mesh.
product:
  name: GKE Enterprise
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, saas-architect, security-engineer]
  authoritative_url: https://cloud.google.com/anthos/docs
  notes: "Rebranded from Anthos to GKE Enterprise; architecture stable. Fleet management + Config Sync + Policy Controller mature."
---

## What it is

GKE Enterprise (formerly Anthos) is GCP's multi-cluster, multi-cloud, hybrid Kubernetes management plane. It treats a fleet of clusters — across GCP, AWS, Azure, on-prem hardware, edge locations — as a single unit for policy, configuration, observability, and service mesh.

Core capabilities:
- **GKE on AWS / GKE on Azure** — GKE-equivalent K8s on competitor clouds, fleet-managed
- **Google Distributed Cloud (Connected / Air-Gapped)** — formerly Anthos bare-metal; GKE on customer hardware
- **Distributed Cloud Edge** — Google-managed hardware at customer edge locations
- **Config Sync** — GitOps for fleet-wide deployment + config
- **Policy Controller** — OPA Gatekeeper for fleet-wide K8s policy
- **Cloud Service Mesh** — managed Istio for fleet-wide service mesh

Authoritative reference: [cloud.google.com/anthos/docs](https://cloud.google.com/anthos/docs).

## When to use

Pick GKE Enterprise when:
- You operate K8s across multiple clouds and want unified management
- Sovereign / regulated workloads require on-prem or air-gapped K8s
- BYOC (bring-your-own-cluster) SaaS — customer hosts your software in their infra
- Significant ACV justifies the operational complexity

Don't pick GKE Enterprise when:
- Single-cluster, single-cloud deployment — plain [GKE Autopilot](/stacks/gcp/gke-autopilot/) is sufficient
- Tenant count is high and BYOC operational overhead breaks unit economics
- Team has no K8s investment — adding K8s + fleet management is overhead

## 2025-2026 currency anchors

- **Rebranded from Anthos to GKE Enterprise**; architecture stable. Older docs may still say "Anthos."
- **Distributed Cloud (Air-Gapped)** for sovereign / classified workloads — fully air-gapped GKE.
- **Distributed Cloud Edge** for telco / edge-location workloads.
- **Config Sync** is the GitOps engine; pairs with [Config Connector](/stacks/gcp/devops-engineer/) for declaring GCP resources as K8s CRDs.
- **Cloud Service Mesh** is the managed-Istio offering; service mesh across the fleet.

## Patterns

### Register a non-GCP cluster to a fleet

```bash
gcloud container fleet memberships register external-cluster \
  --gke-uri=... \
  --location=us-central1 \
  --enable-workload-identity
```

Once registered, the cluster gets fleet-level features: Config Sync, Policy Controller, mesh enrollment, observability rollup.

### GitOps with Config Sync

```yaml
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  enableMultiRepo: true
  git:
    syncRepo: https://github.com/my-org/k8s-config
    syncBranch: main
    secretType: ssh
```

Every cluster in the fleet pulls config from the repo; drift is corrected automatically.

### Policy Controller (OPA Gatekeeper)

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-team-label
spec:
  match:
    kinds: [{ apiGroups: [""], kinds: ["Namespace"] }]
  parameters:
    labels: ["team"]
```

Enforced across every cluster in the fleet via Config Sync.

## Anti-patterns

- **GKE Enterprise for a single cluster** — fleet management overhead without fleet benefits.
- **BYOC offered without operational discipline** — supporting customer-run clusters is its own job; underestimating it ruins margins. See [saas-architect on GCP](/stacks/gcp/saas-architect/).
- **No Policy Controller on regulated workloads** — fleet-wide guardrails are the value prop; skipping them defeats the point.
- **Config Sync without a tested rollback path** — bad config propagates everywhere fast.

## Gotchas

- **Pricing**: GKE Enterprise has a per-vCPU fleet license fee. Verify the cost math against the alternative of operating separate clusters with separate tooling.
- **Service mesh adoption** requires careful sidecar injection rollout — start with a small namespace and grow.
- **Config Sync conflicts** with `kubectl apply` to managed resources — pick one source of truth per resource.
- **Multi-cloud egress costs** add up; Network Connectivity Center hub-and-spoke can reduce inter-region traffic.

## Cross-references

- Related: [GKE](/stacks/gcp/gke/), [GKE Autopilot](/stacks/gcp/gke-autopilot/), [VPC](/stacks/gcp/vpc/), [Cloud Build](/stacks/gcp/cloud-build/) (binauthz integration)
- Roles: [system-architect on GCP](/stacks/gcp/system-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [saas-architect on GCP](/stacks/gcp/saas-architect/)
- Authoritative: [cloud.google.com/anthos/docs](https://cloud.google.com/anthos/docs)
