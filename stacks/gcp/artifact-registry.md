---
title: Artifact Registry
description: "GCP's universal package registry — Docker, npm, Maven, Python, Apt, Yum; Container Analysis vulnerability scans, cleanup policies, CMEK. Replaces `gcr.io`."
product:
  name: Artifact Registry
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, security-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/artifact-registry/docs
  notes: "Container Registry (gcr.io) deprecated; ALL new workloads must use Artifact Registry; redirect of legacy hosts in 2025-2026."
---

## What it is

Artifact Registry is GCP's universal package registry — Docker images, npm, Maven, Python, Apt, Yum, generic. Replaces the legacy Container Registry (`gcr.io`).

Authoritative reference: [cloud.google.com/artifact-registry/docs](https://cloud.google.com/artifact-registry/docs).

## When to use

Artifact Registry is mandatory for all new container workloads on GCP. `gcr.io` is deprecated; legacy hostnames redirect but new repos cannot be created there.

Use cases:
- Container images for [Cloud Run](/stacks/gcp/cloud-run/) / [GKE](/stacks/gcp/gke/) / [Cloud Run functions](/stacks/gcp/cloud-functions/)
- Language package repos (npm / Maven / PyPI) for org-internal libraries
- Remote / virtual repositories — proxy public registries for egress control + cache

## 2025-2026 currency anchors

- **Container Registry (`gcr.io`) deprecated**; redirect in 2025-2026 to Artifact Registry hostnames.
- **Container Analysis** scans Artifact Registry images for OS package vulnerabilities; integrates with Binary Authorization.
- **Remote repositories** GA — proxy public registries.
- **Virtual repositories** GA — aggregate multiple upstream repos behind one URL.
- **Cleanup policies** — delete images by tag/age/keep-N.

## Patterns

### Create repo + push image

```bash
gcloud artifacts repositories create my-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Production container images"

gcloud auth configure-docker us-central1-docker.pkg.dev

docker tag my-image:latest us-central1-docker.pkg.dev/proj/my-repo/api:v1.0.0
docker push us-central1-docker.pkg.dev/proj/my-repo/api:v1.0.0
```

### Vulnerability scanning

```bash
gcloud artifacts vulnerabilities list \
  us-central1-docker.pkg.dev/proj/my-repo/api:v1.0.0
```

Findings exposed via Cloud Asset Inventory + Security Command Center. Pair with Binary Authorization to block deploys of vulnerable images.

### Cleanup policy

```bash
gcloud artifacts repositories set-cleanup-policies my-repo \
  --location=us-central1 \
  --policy=cleanup-policy.json
```

Essential for cost control.

### Remote repository (proxy public)

```bash
gcloud artifacts repositories create dockerhub-proxy \
  --repository-format=docker \
  --mode=remote-repository \
  --remote-docker-repo=DOCKER-HUB \
  --location=us-central1
```

Pull through Artifact Registry; egress control + cache.

## Anti-patterns

- **`gcr.io/proj/image:tag`** in new Dockerfile FROM lines or deploy commands.
- **No cleanup policy** — storage cost time bomb.
- **No CMEK on regulated repos** — audit finding.
- **Granting `artifactregistry.admin` at project scope** — over-broad.

## Gotchas

- **Regional repos** — pick the region matching your deploy region for latency.
- **Image immutability**: tag mutability is allowed by default; consider enforcing immutable tags via repo config.
- **`gcloud auth configure-docker`** must be re-run per machine; CI authenticates via WIF + ADC.

## Cross-references

- Related: [Cloud Build](/stacks/gcp/cloud-build/), [Cloud Deploy](/stacks/gcp/cloud-deploy/), [Cloud Run](/stacks/gcp/cloud-run/), [GKE](/stacks/gcp/gke/), [Cloud KMS](/stacks/gcp/cloud-kms/)
- Roles: [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [security-engineer on GCP](/stacks/gcp/security-engineer/)
- Authoritative: [cloud.google.com/artifact-registry/docs](https://cloud.google.com/artifact-registry/docs)
