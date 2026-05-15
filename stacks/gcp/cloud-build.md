---
title: Cloud Build
description: GCP's managed CI engine — container builds, tests, deploys; private pools for VPC access; binauthz attestor pipelines; mature integration with Artifact Registry + Cloud Deploy.
product:
  name: Cloud Build
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, security-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/build/docs
  notes: "Private pools GA; binauthz attestor integration mature; default public pool for OSS-style builds; pairs with Cloud Deploy."
---

## What it is

Cloud Build is GCP's managed CI engine — runs container builds, tests, and arbitrary build steps in GCP-managed runners. **Private pools** run in your VPC for builds that need private resource access. Integrates natively with [Artifact Registry](/stacks/gcp/artifact-registry/), Binary Authorization, and [Cloud Deploy](/stacks/gcp/cloud-deploy/).

Authoritative reference: [cloud.google.com/build/docs](https://cloud.google.com/build/docs).

## When to use

Pick Cloud Build when:
- Builds need GCP-internal network access (private GitHub Enterprise, private Artifact Registry without public endpoint, private resources during integration tests)
- You want GCP-native CI without managing GitHub Actions / GitLab CI runners
- Tight integration with binauthz attestor pipeline

Don't pick Cloud Build when:
- GitHub Actions / GitLab CI is the org's CI standard — they integrate fine with GCP via [WIF](/stacks/gcp/devops-engineer/)
- Heavy multi-repo orchestration — GitHub Actions workflow ecosystem is broader

Most teams use **GitHub Actions for general CI** and **Cloud Build for builds that specifically need GCP-internal network access**.

## 2025-2026 currency anchors

- **Private pools GA** — Cloud Build runners in your VPC.
- **Binary Authorization integration** mature — sign at build, verify at deploy.
- **Container Analysis** vulnerability scans on Artifact Registry; blocks deploys via binauthz.

## Patterns

### Build + push + deploy

```yaml
# cloudbuild.yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/repo/api:$COMMIT_SHA'
      - '.'

  - name: 'us-central1-docker.pkg.dev/$PROJECT_ID/repo/api:$COMMIT_SHA'
    entrypoint: 'pytest'
    args: ['tests/']

  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/repo/api:$COMMIT_SHA']

  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: 'gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'api'
      - '--image=us-central1-docker.pkg.dev/$PROJECT_ID/repo/api:$COMMIT_SHA'
      - '--region=us-central1'

options:
  pool:
    name: projects/$PROJECT_ID/locations/us-central1/workerPools/private-pool
  logging: CLOUD_LOGGING_ONLY

images:
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/repo/api:$COMMIT_SHA'
```

### Build trigger

```bash
gcloud builds triggers create github \
  --name=main-deploy \
  --repo-name=my-repo \
  --repo-owner=my-org \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

### Private pool

For builds needing VPC access:
```bash
gcloud builds worker-pools create private-pool \
  --region=us-central1 \
  --peered-network=projects/proj/global/networks/prod-vpc \
  --no-public-egress
```

## Anti-patterns

- **`gcr.io/...` in new Dockerfile FROM lines or deploy commands** — deprecated; use Artifact Registry.
- **Public pool for builds touching private resources** — they'll fail; use private pool.
- **No Container Analysis** on production images — vulnerability blind spot.
- **Service account JSON keys in build steps** — runtime Cloud Build SA is preferred.

## Gotchas

- **Cloud Build SA** has broad default permissions; tighten if needed.
- **Build minute pricing**: free tier 120 min/day; private pool is per-machine-hour.
- **Build log retention** — verify against compliance needs; export to BigQuery via log sink if longer retention required.

## Cross-references

- Related: [Artifact Registry](/stacks/gcp/artifact-registry/), [Cloud Deploy](/stacks/gcp/cloud-deploy/), [Cloud Run](/stacks/gcp/cloud-run/), [GKE](/stacks/gcp/gke/) (binauthz)
- Roles: [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [security-engineer on GCP](/stacks/gcp/security-engineer/)
- Authoritative: [cloud.google.com/build/docs](https://cloud.google.com/build/docs)
