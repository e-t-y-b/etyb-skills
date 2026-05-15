---
title: Cloud Deploy
description: GCP's CD service for Cloud Run / GKE / Anthos — delivery pipelines with approval gates, automated rollback, canary via Service Mesh integration.
product:
  name: Cloud Deploy
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, system-architect]
  authoritative_url: https://cloud.google.com/deploy/docs
  notes: "Cloud Run + GKE + Anthos targets; canary deployments via Service Mesh integration; Skaffold for rendering."
---

## What it is

Cloud Deploy is GCP's managed continuous-delivery service. Targets: [Cloud Run](/stacks/gcp/cloud-run/), [GKE](/stacks/gcp/gke/), [Anthos / GKE Enterprise](/stacks/gcp/anthos/). Features:

- Delivery pipelines with target promotion (dev → staging → prod)
- Approval gates between stages
- Automated rollback on failure
- Canary deployments via Service Mesh integration
- Render verifications using Skaffold

Authoritative reference: [cloud.google.com/deploy/docs](https://cloud.google.com/deploy/docs).

## When to use

Pick Cloud Deploy when:
- Multi-environment promotion with approval gates
- Canary shape is more than `gcloud run deploy --no-traffic` + manual splitting
- Team wants GCP-native CD; doesn't want to maintain Argo CD / Flux

Skip Cloud Deploy when:
- Single-environment direct deploys (deploy on green main)
- Existing Argo CD / Flux investment
- Workflow is simple enough for [Cloud Build](/stacks/gcp/cloud-build/) or GitHub Actions to handle end-to-end

## 2025-2026 currency anchors

- **Cloud Run + GKE + Anthos targets** GA.
- **Canary via Service Mesh** (Cloud Service Mesh / Istio) integration for GKE.
- **Skaffold-based rendering** for K8s manifests.
- **Approval gates** with IAM-controlled access.

## Patterns

### Delivery pipeline (clouddeploy.yaml)

```yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
  name: api-pipeline
description: API service delivery pipeline
serialPipeline:
  stages:
    - targetId: dev
      profiles: [dev]
    - targetId: staging
      profiles: [staging]
      strategy:
        canary:
          runtimeConfig:
            cloudRun:
              automaticTrafficControl: true
          canaryDeployment:
            percentages: [25, 50]
            verify: true
    - targetId: prod
      profiles: [prod]
      strategy:
        canary:
          runtimeConfig:
            cloudRun:
              automaticTrafficControl: true
          canaryDeployment:
            percentages: [10, 50]
            verify: true
```

## Anti-patterns

- **No verify step** between canary phases — promoting blindly.
- **No rollback on failure** — defeats the canary value prop.
- **Approval gates without IAM** — anyone can approve.

## Gotchas

- **Skaffold version** matters for manifest rendering; pin.
- **Canary percentages** apply only when supported by the runtime; Cloud Run native, GKE via mesh.
- **Audit trail**: every promotion + approval is logged in Cloud Audit Logs.

## Cross-references

- Related: [Cloud Build](/stacks/gcp/cloud-build/), [Cloud Run](/stacks/gcp/cloud-run/), [GKE](/stacks/gcp/gke/), [Artifact Registry](/stacks/gcp/artifact-registry/)
- Roles: [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/deploy/docs](https://cloud.google.com/deploy/docs)
