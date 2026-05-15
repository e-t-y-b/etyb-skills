---
title: Container Apps
description: Azure Container Apps — Workload Profiles, managed Dapr, Jobs, KEDA scaling. The default container compute on Azure when AKS is overkill.
product:
  name: Azure Container Apps
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, system-architect]
  authoritative_url: https://learn.microsoft.com/azure/container-apps/
  notes: "Workload Profiles GA 2024 closed the Consumption-only ceiling; managed Dapr + KEDA on Azure-managed patches."
---

## What it is

Container Apps is Azure's serverless container platform — you ship an image, Azure runs it with autoscaling, traffic splitting, managed Dapr, KEDA-based event scaling, and per-app or environment-level networking. No Kubernetes ops. Canonical reference: [Container Apps docs](https://learn.microsoft.com/azure/container-apps/).

## When to use

Pick Container Apps when:

- You have a **containerized microservice** that scales horizontally and you don't need K8s ecosystem features.
- You want **Dapr** (service invocation, state, pub/sub) without running it yourself.
- You want **KEDA-based event scaling** off Service Bus / Event Hubs / Cosmos Change Feed.
- You want **scale-to-zero** with low cold-start cost.
- You want **traffic splitting / canary** built in.
- You have **batch / scheduled jobs** that Functions can't handle (Container Apps Jobs).

Pick [AKS](/stacks/azure/aks/) instead when you need: third-party operators, Istio, multi-team shared cluster, specialized scheduling. Pick [Functions](/stacks/azure/functions/) for purely event-driven sub-10-minute workloads.

## 2025-2026 currency anchors

- **Workload Profiles** (GA 2024) — mix Consumption (scale-to-zero) and Dedicated D-series CPU-optimized / E-series memory-optimized profiles in one environment. Eliminates the old "Consumption-only ceiling."
- **Container Apps Jobs** (GA) — cron + event-triggered + manual-triggered batch jobs. Better than Functions Timer trigger for long batch.
- **Managed Dapr** at version 1.13.6-msft.6+ — `-msft` suffix denotes Azure-specific patches; latest applied automatically.
- **Managed certificates** for custom domains — auto-renewing, Let's Encrypt-backed.
- **Multiple revisions + weighted traffic** — canary deploys without external tooling.
- **VNet integration** — internal-only or external; subnets configured at environment level.
- **GPU profiles** rolling out — check current SKU availability before architecting GPU inference.

## Patterns + anti-patterns

### Pattern: Workload Profiles for mixed workloads

```bicep
resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: envName
  properties: {
    workloadProfiles: [
      { name: 'Consumption', workloadProfileType: 'Consumption' }
      { name: 'D4', workloadProfileType: 'D4', minimumCount: 1, maximumCount: 5 }
    ]
    vnetConfiguration: { infrastructureSubnetId: subnetId, internal: true }
  }
}
```

Workers that idle most of the day → Consumption. Web tier with sustained load → D4. Same environment, same Dapr, same observability.

### Pattern: KEDA-driven worker on Service Bus queue

Worker app uses Consumption profile + KEDA scaler on Service Bus queue length. Idle = 0 replicas, cost 0. Burst = scale 0→N replicas on event count.

### Pattern: Revision traffic splitting for canary

```bicep
configuration: {
  activeRevisionsMode: 'Multiple'
  ingress: {
    traffic: [
      { revisionName: 'app--blue',  weight: 90 }
      { revisionName: 'app--green', weight: 10 }
    ]
  }
}
```

10% canary → observe metrics → shift gradually.

### Pattern: Managed Dapr for polyglot microservices

Java service calling .NET service via Dapr service invocation gets mTLS + retry + tracing without per-language plumbing. Configure components (state store, pub/sub, secrets) once per environment.

### Anti-pattern: Always-on `min replicas = 5` on Consumption

You're paying for 5 warm containers idle. Use a Workload Profile (Dedicated D-series) for sustained load; Consumption for spiky bursts.

### Anti-pattern: Dapr state for cross-service consistency

Dapr's state API is single-service-scoped. For cross-service consistency, use the saga pattern with Service Bus + idempotent handlers. See [Backend Architect on Azure](/stacks/azure/backend-architect/).

### Anti-pattern: Container Apps for K8s-ecosystem requirements

If the team is shipping Helm charts and CRDs, you'll outgrow Container Apps. Use [AKS](/stacks/azure/aks/).

### Anti-pattern: Dapr enabled but no components configured

Sidecar runs, does nothing useful. Configure state store / pub/sub / secrets components in Bicep or YAML.

## Gotchas

- **Graceful shutdown grace period** — default 30 seconds (configurable up to 600s via `terminationGracePeriodSeconds`). In-flight requests must complete; in-flight message processing must commit or release.
- **VNet integration is environment-level**, not per-app. Pick the right subnet sizing upfront.
- **Cold start on Consumption** — < 1s typical, but ESM-heavy Node / large .NET / JVM startup is slower. Use Dedicated profile if cold start violates SLO.
- **Managed Dapr version is Azure-controlled.** You can't pin to upstream Dapr release; Microsoft applies `-msft` patches.

## Cross-references

- [Backend Architect on Azure](/stacks/azure/backend-architect/) — runtime selection, Dapr building blocks
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — environment design, Workload Profile sizing
- [Functions](/stacks/azure/functions/) — event-driven short-lived alternative
- [AKS](/stacks/azure/aks/) — when you need the K8s ecosystem
- [Container Apps overview](https://learn.microsoft.com/azure/container-apps/overview)
- [Dapr in Container Apps](https://learn.microsoft.com/azure/container-apps/dapr-overview)
