---
title: Virtual Machines
description: Azure VMs — Cobalt 100 Arm, Dv6/Ev6 Emerald Rapids, NCads H100 / ND H200 / NCv6 Blackwell. Use for specialized hardware, lift-and-shift, or AI training; not as the default for new microservices.
product:
  name: Azure Virtual Machines
  stack: azure
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, ai-ml-engineer]
  authoritative_url: https://learn.microsoft.com/azure/virtual-machines/
  notes: "VM series naming churns yearly; AI GPU SKUs evolve quarterly."
---

## What it is

Azure Virtual Machines are IaaS compute — you pick a SKU, OS image, networking, disks, and run anything that runs on a server. Despite the modern compute ladder (Functions / Container Apps / AKS / App Service), VMs remain the right answer for specialized hardware, custom kernels, third-party appliances, and lift-and-shift workloads. Canonical reference: [Azure VM docs](https://learn.microsoft.com/azure/virtual-machines/).

## When to use

Pick VMs when one of these is true:

- **Specialized hardware** — GPU training (ND H100 v4, ND H200 v5), HPC fabric (InfiniBand HBv4), confidential compute (DCsv5 / DCadsv5).
- **Lift-and-shift** — existing on-prem servers / VMware workloads where re-architecting is out of scope.
- **Third-party appliances** — vendor-supplied images (firewalls, identity stores, ERPs) that aren't containerized.
- **SQL Server with Always On Availability Groups** — when Managed Instance doesn't fit.
- **SAP HANA** — purpose-built memory-optimized SKUs.

Don't use VMs for new microservices, new web apps, or new APIs — that's [Container Apps](/stacks/azure/container-apps/), [AKS](/stacks/azure/aks/), [Functions](/stacks/azure/functions/), or [App Service](/stacks/azure/app-service/) territory.

## 2025-2026 currency anchors

- **Cobalt 100 (Arm)** — GA 2024-25. Microsoft-designed Arm cores; good for Linux web/API workloads at lower price/perf.
- **Dv6 / Ev6 (Emerald Rapids)** — GA 2025. Intel general-purpose / memory-optimized.
- **NCads H100 v5** — H100 NVL 94 GB; current default for inference + small-to-medium training.
- **ND H200 v5** — H200 141 GB HBM3e; current frontier for large-scale distributed training.
- **NCv6 (RTX PRO 6000 Blackwell)** — preview Nov 2025; cost-effective LLM inference, visual computing.
- **GB200 Grace Blackwell** — cluster-class frontier; reserved access.
- **Maia 100** — Microsoft's custom AI accelerator; currently internal-only. Maia 200 (Braga) delayed to 2026.
- **Premium SSD v2** — direct conversion from Standard/Premium SSD GA; instant access snapshots; tunable IOPS + throughput independent.
- **Spot eviction notice** — 30 seconds. Suitable for batch/HPC/CI; not for user-facing services.

## Patterns + anti-patterns

### Pattern: Cobalt 100 for stateless Linux web / API tiers

When the workload is "Linux container or Node/Python/Go process," Cobalt 100 generally beats Intel/AMD on price-perf. Validate with your benchmark; default to it on greenfield.

### Pattern: Premium SSD v2 for tier-1 production disks

Independent IOPS + throughput tuning, dynamic resize, instant access snapshots. Cost-efficient vs Ultra Disk for most workloads. Premium SSD v1 is in maintenance.

### Pattern: Spot for batch / CI / HPC

Up to 90% discount. 30-second eviction notice. Pair with a queue (Service Bus / Storage Queue) so work checkpoints naturally.

### Anti-pattern: VMs as the default for new microservices

Use Container Apps or AKS. VMs cost more (you manage OS patching, scaling, networking) and ship slower.

### Anti-pattern: standalone GPU VM for inference when Container Apps GPU SKUs fit

Container Apps now offers GPU profiles; AKS GPU node pools are managed. Bare-metal VMs only when you need direct hardware access (custom kernel, specialized drivers).

### Anti-pattern: ignoring VM series rename cadence

The Dv5 / Ev5 you remember may have a newer Dv6 / Ev6 successor with better price-perf. Check Azure Updates before sizing new fleets.

## Gotchas

- **Spot eviction is sudden.** 30-second notice. Plan checkpointing.
- **Cobalt 100 is Arm — your binaries must target Arm.** Most distros and managed runtimes (Node, Python, .NET 8+, Java 17+) work, but verify your image and dependencies.
- **Series naming churns yearly.** Don't hard-code SKU strings in templates that live for years; parameterize.
- **Reserved Instances vs Savings Plans** — RIs lock SKU + region; Savings Plans are family-flexible. For steady-state stable SKUs, RIs save more; for fluid workloads, Savings Plans are flexible.

## Cross-references

- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — cost guardrails (Reservations / Savings Plans / Spot)
- [System Architect on Azure](/stacks/azure/system-architect/) — compute ladder + when to pick VMs
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — GPU VM selection for training / inference
- [GPU VM sizes](https://learn.microsoft.com/azure/virtual-machines/sizes-gpu)
- [Azure Spot Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/spot-vms)
