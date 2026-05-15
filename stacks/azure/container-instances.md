---
title: Container Instances
description: ACI — single-container serverless. Stable but largely displaced by Container Apps for new workloads. Still useful for one-off containers and burst-out from AKS via Virtual Nodes.
product:
  name: Azure Container Instances
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer]
  authoritative_url: https://learn.microsoft.com/azure/container-instances/
  notes: "Mature service; for greenfield container workloads, Container Apps is the recommendation."
---

## What it is

Azure Container Instances (ACI) runs a single container (or a small group) without managing a host or orchestrator. Per-second billing. Canonical reference: [ACI docs](https://learn.microsoft.com/azure/container-instances/).

## When to use

Pick ACI when:

- You have a **one-off container** — short-lived task, CI runner, ad-hoc job — and don't want a Container Apps environment.
- You need **AKS Virtual Nodes** for burst capacity (Virtual Kubelet backed by ACI).
- A **partner/vendor sample** specifies ACI as the deployment target.

For new microservices or event-driven workloads, prefer [Container Apps](/stacks/azure/container-apps/) — same per-second billing, more features (autoscaling, traffic splitting, managed Dapr, KEDA, revisions).

## 2025-2026 currency anchors

- Service is stable. Most new investment is going to [Container Apps](/stacks/azure/container-apps/) and [AKS](/stacks/azure/aks/) Virtual Nodes.
- **Confidential Containers on ACI** — Intel SGX / AMD SEV-SNP attestation for sensitive workloads where you want serverless + TEE without AKS.
- **GPU container groups** available in select regions for short inference jobs.

## Patterns + anti-patterns

### Pattern: AKS Virtual Nodes burst to ACI

When AKS Cluster Autoscaler / Karpenter would take too long to provision a node for a sudden burst, Virtual Nodes schedule pods on ACI instantaneously. Useful for spiky batch.

### Pattern: One-shot task containers

Run a tooling container (e.g., DB migration runner, infra job, periodic report) for the duration of the task and terminate. Cheaper than running a dedicated VM or always-on App Service for an occasional task.

### Anti-pattern: ACI as primary microservice host

Use Container Apps. ACI lacks autoscaling, traffic splitting, ingress controller, managed Dapr.

### Anti-pattern: ACI for long-running stateful workloads

No managed scaling, no graceful shutdown signals consistent with Container Apps. Use AKS or Container Apps.

## Gotchas

- **ACI billing is per-second per-resource (vCPU + memory).** Forgotten ACI groups can quietly burn budget.
- **VNet integration is supported but limited** vs Container Apps environments.
- **No managed certs for custom domains** — bring your own.

## Cross-references

- [Container Apps](/stacks/azure/container-apps/) — the recommended successor for new workloads
- [AKS](/stacks/azure/aks/) — Virtual Nodes burst to ACI
- [ACI overview](https://learn.microsoft.com/azure/container-instances/container-instances-overview)
