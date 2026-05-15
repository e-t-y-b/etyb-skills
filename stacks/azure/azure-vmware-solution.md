---
title: Azure VMware Solution
description: AVS — first-party VMware Cloud Foundation on Azure. Stretched Clusters in select regions. VCF 9 path under evaluation.
product:
  name: Azure VMware Solution (AVS)
  stack: azure
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer]
  authoritative_url: https://learn.microsoft.com/azure/azure-vmware/
  notes: "Stable; VCF 9 path under evaluation; Stretched Clusters in select regions."
---

## What it is

Azure VMware Solution is a first-party Microsoft service hosting VMware Cloud Foundation on Azure — vSphere, vSAN, NSX, HCX. Customers lift-and-shift VMware workloads to Azure without re-platforming. Canonical reference: [AVS docs](https://learn.microsoft.com/azure/azure-vmware/).

## When to use

Pick AVS when:

- **Existing VMware estate** — large vSphere workload that can't be re-platformed in available time.
- **Specialized VMware features** — NSX-T, HCX live migration, VMware-licensed third-party.
- **Compliance / governance** that mandates VMware compatibility.

For new builds, Azure-native ([VMs](/stacks/azure/virtual-machines/), [AKS](/stacks/azure/aks/), [Container Apps](/stacks/azure/container-apps/)) is usually the right path.

## 2025-2026 currency anchors

- **Stable** service.
- **VCF (VMware Cloud Foundation) 9 path under evaluation** at Microsoft.
- **Stretched Clusters** in select regions — cross-AZ within a region for HA.
- **HCX** for live migration from on-prem VMware to AVS.
- **Express Route + AVS** for hybrid network integration.

## Patterns + anti-patterns

### Pattern: Lift-and-shift with HCX

Use HCX to live-migrate VMs from on-prem vSphere to AVS without VM IP changes. Cutover with minimal downtime.

### Pattern: AVS as the hybrid landing pad, then re-platform over time

Land in AVS to exit the data center. Re-platform individual workloads to Azure-native over time as application changes allow.

### Anti-pattern: AVS for new builds

Use Azure-native compute. AVS is a transition path, not a destination.

## Gotchas

- **Cost** — AVS is expensive vs Azure-native; sized per minimum host count.
- **VMware license cost** is separate from Azure infrastructure cost.
- **VCF version path** — keep informed; major version transitions are real projects.

## Cross-references

- [Virtual Machines](/stacks/azure/virtual-machines/) — Azure-native alternative
- [Azure Arc](/stacks/azure/azure-arc/) — alternative hybrid path
- [System Architect on Azure](/stacks/azure/system-architect/) — migration planning
- [AVS docs](https://learn.microsoft.com/azure/azure-vmware/)
