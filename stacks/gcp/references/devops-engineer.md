---
role: devops-engineer
stack: gcp
last_verified_on: "2026-05-14"
---

# GCP Overlay — devops-engineer

You are devops-engineer on a GCP engagement. Your CI builds container images in Cloud Build (or GitHub Actions / GitLab CI authenticated via Workload Identity Federation) and pushes them to Artifact Registry. Your CD targets Cloud Run / GKE / Cloud Functions via Cloud Deploy or Terraform-driven gcloud. Your IaC is Terraform (`google` + `google-beta` providers) or Infrastructure Manager (managed Terraform). Your auth pattern for everything external to GCP is Workload Identity Federation — service account keys are an audit liability in 2026.

**Currency:** verified against GCP product surface as of 2026-05-14. See parent [`SKILL.md`](../SKILL.md) for the full "what changed" list.

## What changed in 2025-2026 that older training data misses

- **Container Registry (`gcr.io`) is deprecated.** All new images must go to **Artifact Registry** (`<region>-docker.pkg.dev/...`). The `gcr.io` hostnames still redirect but new repos cannot be created there. CI pipelines still pushing to `gcr.io` will break silently when the redirect retires.
- **Deployment Manager end-of-support: December 31, 2025.** Migrate to **Infrastructure Manager** (Google-managed Terraform) or self-managed Terraform now. If a customer is still using DM, the migration is overdue.
- **Cloud Functions gen1 is deprecated.** New deploys go to Cloud Run functions (gen2). Pipelines hardcoded to gen1 syntax produce deprecated artifacts.
- **Workload Identity Federation (WIF)** is the production answer for non-GCP CI runners (GitHub Actions, GitLab CI, CircleCI, Jenkins on-prem, AWS-based runners). Service account JSON keys are now an audit red flag.
- **Cloud Build private pools** are GA and the right answer for builds that need VPC access (private GitHub Enterprise, private Artifact Registry, on-prem source mirrors).
- **Cloud Deploy** supports Cloud Run, GKE, Anthos targets — promotion pipelines with approvals, automated rollback, canary deployment via Service Mesh integration.
- **Binary Authorization** for GKE and Cloud Run — sign images at build, verify at deploy. Mandatory for regulated workloads.
- **Container Analysis** scans Artifact Registry images for vulnerabilities; integrates with Binary Authorization to block deploys of vulnerable images.
- **Terraform `google` provider 6.x is current** (verify exact minor when authoring); breaking changes telegraphed in CHANGELOG, beta resources live in the `google-beta` provider. Pin providers in `versions.tf`.
- **Config Connector** (K8s CRDs for GCP resources) is mature and pairs with Config Sync for GitOps-driven GCP infrastructure.
- **GKE release channels** matured: RAPID, REGULAR, STABLE — RAPID for testing new features, REGULAR for prod default, STABLE for risk-averse environments.
- **GKE Autopilot for greenfield K8s**, GKE Standard only when Autopilot blocks something specific.
- **gcloud `--release-track` flag** matters for IaC — alpha/beta features need explicit opt-in and may produce non-portable state.

If you're recommending `gcr.io` image paths, Deployment Manager templates, Cloud Functions gen1 deploys, service account JSON keys for CI, or self-managed Cloud Build with public-pool defaults for sensitive workloads — your training is stale.

## gcloud CLI fundamentals

The `gcloud` CLI is plugin-based via "components." Authenticate, set project, set region as configurations:

```bash
# Authenticate (interactive)
gcloud auth login

# Application Default Credentials for libraries
gcloud auth application-default login

# Multi-environment configurations
gcloud config configurations create prod
gcloud config set project my-prod-project
gcloud config set compute/region us-central1
gcloud config set run/region us-central1

gcloud config configurations create dev
gcloud config set project my-dev-project
# ...

gcloud config configurations activate prod
gcloud config configurations list
```

CI uses WIF, not interactive login. Never use `gcloud auth activate-service-account --key-file` in 2026 unless bootstrapping a non-WIF-capable system.

### Useful component groups

| Command group | What it does |
|---------------|--------------|
| `gcloud auth` | Authentication, including WIF |
| `gcloud config` | CLI configurations |
| `gcloud projects` | Project lifecycle |
| `gcloud iam` | IAM bindings, service accounts, WIF |
| `gcloud compute` | Compute Engine, VPC, firewall, GLB |
| `gcloud run` | Cloud Run services, jobs, functions |
| `gcloud container` | GKE clusters, fleet, multi-cloud |
| `gcloud artifacts` | Artifact Registry |
| `gcloud builds` | Cloud Build |
| `gcloud deploy` | Cloud Deploy delivery pipelines |
| `gcloud secrets` | Secret Manager |
| `gcloud kms` | Cloud KMS |
| `gcloud monitoring` | Monitoring, alert policies |
| `gcloud logging` | Logging, sinks, log-based metrics |
| `gcloud sql` | Cloud SQL |
| `gcloud alloydb` | AlloyDB |
| `gcloud spanner` | Cloud Spanner |
| `gcloud pubsub` | Pub/Sub topics, subscriptions |
| `gcloud eventarc` | Eventarc triggers, buses, pipelines |
| `gcloud ai` | Vertex AI (models, endpoints, custom jobs, pipelines) |
| `gcloud beta` / `gcloud alpha` | Pre-GA surfaces; use with caution |

### Common gotchas

- **`gcloud beta` and `gcloud alpha` commands produce state Terraform may not understand.** If you create something via `gcloud beta`, plan to manage it via `google-beta` Terraform provider or accept it lives outside IaC.
- **Default regions vary**: `gcloud compute` default region differs from `gcloud run` default region differs from `gcloud container` default region. Always set explicitly in CI scripts.
- **`gcloud` honors `CLOUDSDK_CORE_PROJECT` and similar env vars** — useful in CI but produces hard-to-debug behavior when set inadvertently.
- **Component updates**: `gcloud components update` is interactive; in CI, install a pinned version of the SDK and don't update.

## Workload Identity Federation — the 2026 baseline

WIF is non-negotiable for CI/CD in 2026. The pattern:

1. Create a **workload identity pool** in GCP (one per external identity domain — GitHub, AWS, on-prem).
2. Create a **provider** under the pool (OIDC issuer for GitHub Actions, AWS IAM for AWS, etc.).
3. Bind a GCP service account to the federated principal via `roles/iam.workloadIdentityUser`.
4. External CI uses its native OIDC token (GitHub `id-token`, AWS `sts:AssumeRoleWithWebIdentity`) to mint a short-lived GCP federated token.

### GitHub Actions example

```bash
# Set up pool + provider once
gcloud iam workload-identity-pools create github-pool \
  --location=global \
  --display-name="GitHub Actions Pool"

gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location=global \
  --workload-identity-pool=github-pool \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository_owner == 'my-org'"

# Bind a service account to the federated principals
gcloud iam service-accounts add-iam-policy-binding deploy@proj.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/123/locations/global/workloadIdentityPools/github-pool/attribute.repository/my-org/my-repo"
```

GitHub Actions workflow:
```yaml
name: deploy
on: push
permissions:
  id-token: write       # required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github-pool/providers/github-provider
          service_account: deploy@proj.iam.gserviceaccount.com
      - uses: google-github-actions/setup-gcloud@v2
      - run: gcloud builds submit --tag us-central1-docker.pkg.dev/proj/repo/api:$GITHUB_SHA
```

**Never** store the service account JSON key in GitHub Secrets. WIF eliminates the need. Same pattern for GitLab CI (uses OIDC), CircleCI (OIDC), and Jenkins (OIDC plugin).

### Bootstrap exception

The only legit use of a service account JSON key in 2026 is bootstrapping a CI that doesn't yet support OIDC (rare). Rotate aggressively and migrate to WIF as soon as the CI supports it.

## Terraform on GCP

Terraform is the dominant IaC for GCP in 2026. Pattern:

```hcl
# versions.tf
terraform {
  required_version = ">= 1.10"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }
  backend "gcs" {
    bucket = "my-tfstate-bucket"
    prefix = "env/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
```

### State backend — always GCS

- **Always remote** state in GCS bucket with versioning + encryption (CMEK)
- **Per-environment prefix**: `env/prod`, `env/staging`, `env/dev`
- **Bucket in a dedicated `terraform-state` project**, IAM-controlled
- **Object versioning + retention policy** to prevent accidental state loss
- **Lock via GCS object lifecycle** is built-in; no DynamoDB equivalent needed

### Module structure

```
terraform/
├── modules/
│   ├── cloud-run-service/
│   ├── gke-autopilot-cluster/
│   ├── vpc-network/
│   ├── cloud-sql-postgres/
│   ├── alloydb-cluster/
│   ├── pubsub-topic-with-dlq/
│   └── ...
├── envs/
│   ├── prod/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── dev/
└── shared/
    └── org-policies/
```

### `google` vs `google-beta` provider

| Provider | When |
|----------|------|
| `google` | GA resources; default for production |
| `google-beta` | Beta resources and beta-only fields on GA resources; use only for genuinely needed beta features |

Don't mix carelessly — a resource managed by `google-beta` will show drift if read by `google`. Annotate explicitly:

```hcl
resource "google_cloud_run_v2_service" "api" {
  provider = google
  # ...
}

resource "google_some_beta_resource" "thing" {
  provider = google-beta
  # ...
}
```

### Common patterns

**Cloud Run service with VPC connector** (Terraform):

```hcl
resource "google_cloud_run_v2_service" "api" {
  name     = "api-service"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.api_runtime.email
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo}/api:${var.image_tag}"
      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi"
        }
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
    }
    scaling {
      min_instance_count = 1
      max_instance_count = 50
    }
    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = google_compute_network.prod_vpc.id
        subnetwork = google_compute_subnetwork.run_subnet.id
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_service_account" "api_runtime" {
  account_id   = "api-runtime"
  display_name = "API runtime SA"
}

resource "google_secret_manager_secret_iam_member" "api_secret_access" {
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.api_runtime.email}"
}
```

**GKE Autopilot cluster**:

```hcl
resource "google_container_cluster" "autopilot" {
  name     = "prod-autopilot"
  location = var.region

  enable_autopilot = true

  release_channel {
    channel = "REGULAR"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal"
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  network    = google_compute_network.prod_vpc.id
  subnetwork = google_compute_subnetwork.gke_subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
}
```

### `for_each` vs `count` — prefer `for_each`

`for_each` on maps gives stable resource addresses on insert/delete. `count` reshuffles when an item in the middle is removed. Use `for_each` for any collection that might change.

### Plan and apply discipline

- **Always `terraform plan` before `apply`**. CI generates the plan, attaches to the PR, human reviews, then apply.
- **Use `-target` sparingly** — it bypasses dependency graph; reserve for breaking circular dependencies during refactoring.
- **`terraform import` for existing resources** before introducing them to state — gcloud-created infrastructure must be imported, not duplicated.
- **State drift**: nightly `terraform plan` in CI; alert on non-empty diff. Drift in prod is a process failure.

## Infrastructure Manager — managed Terraform

Infrastructure Manager is Google's hosted Terraform execution. It replaces Deployment Manager (end-of-support Dec 31, 2025). Use when:
- You want Google-managed Terraform execution without managing your own runner
- You need integration with Cloud Build / Cloud Deploy for IaC pipelines
- You want IAM-controlled deployments without sharing the state bucket broadly

```bash
gcloud infra-manager deployments apply prod-deployment \
  --location=us-central1 \
  --service-account=infra-manager@proj.iam.gserviceaccount.com \
  --git-source-repo=https://github.com/my-org/infra \
  --git-source-directory=envs/prod \
  --git-source-ref=main \
  --tf-version-constraint="~> 1.10"
```

For most established Terraform teams, self-managed Terraform on GitHub Actions + WIF remains the lower-overhead path. Infrastructure Manager wins for orgs that want IaC operations within GCP without GitHub/GitLab dependency.

## Config Connector — K8s-native IaC

Config Connector exposes GCP resources as Kubernetes CRDs. Combine with Config Sync (GitOps) for fully declarative GCP infrastructure managed by K8s manifests.

```yaml
apiVersion: sql.cnrm.cloud.google.com/v1beta1
kind: SQLInstance
metadata:
  name: prod-postgres
spec:
  databaseVersion: POSTGRES_16
  region: us-central1
  settings:
    tier: db-custom-4-16384
    availabilityType: REGIONAL
    backupConfiguration:
      enabled: true
      pointInTimeRecoveryEnabled: true
    ipConfiguration:
      privateNetworkRef:
        name: prod-vpc
      ipv4Enabled: false
```

Use when:
- Your team is K8s-native and prefers `kubectl apply` for everything
- You want GitOps with Config Sync for both K8s workloads + GCP infra
- You already have an Anthos / GKE Enterprise estate

Don't use when:
- Your team has no K8s investment — adding K8s just to manage GCP infra is overhead

## Cloud Build — CI engine

Cloud Build runs container builds, tests, and arbitrary build steps in GCP-managed runners. Patterns:

```yaml
# cloudbuild.yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/repo/api:$COMMIT_SHA'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/repo/api:latest'
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

### Private pools

Cloud Build private pools run in your VPC; required for builds that need:
- Private GitHub Enterprise / GitLab access
- Private Artifact Registry (without public endpoint)
- Access to private resources during integration tests

Default public pool is fine for OSS-style builds with no private dependencies.

### Build triggers

Triggers tie source repos (GitHub, GitLab, Bitbucket, Cloud Source Repositories) to build configs. Filter by branch, tag, file path:

```bash
gcloud builds triggers create github \
  --name=main-deploy \
  --repo-name=my-repo \
  --repo-owner=my-org \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

GitHub Actions vs Cloud Build is largely team preference in 2026:
- **Cloud Build wins** for: GCP-tight integration, private pool VPC access, Cloud Logging native, no external CI dependency
- **GitHub Actions wins** for: workflow ecosystem (actions marketplace), unified PR experience with GitHub, easier multi-repo orchestration, WIF + setup-gcloud is mature

Most teams use GitHub Actions for general CI and Cloud Build for builds that specifically need GCP-internal network access.

## Cloud Deploy — CD pipelines

Cloud Deploy is GCP's CD service for Cloud Run / GKE / Anthos. Provides:
- Delivery pipelines with target promotion (dev → staging → prod)
- Approval gates between stages
- Automated rollback on failure
- Canary deployments via Service Mesh integration
- Render verifications using Skaffold

```yaml
# clouddeploy.yaml
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

Use Cloud Deploy when:
- Multi-environment promotion with approval gates is needed
- Canary deployment shape is more than `gcloud run deploy --no-traffic` + manual splitting
- Team wants GCP-native CD; doesn't want to maintain Argo CD / Flux

Skip Cloud Deploy when:
- Single-environment direct deploys (deploy on green main)
- Existing Argo CD / Flux investment

## Artifact Registry — the container registry

`gcr.io` and Container Registry are deprecated. All new image pushes go to Artifact Registry.

```bash
# Create regional repo
gcloud artifacts repositories create my-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Production container images"

# Configure Docker to authenticate
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tag and push
docker tag my-image:latest us-central1-docker.pkg.dev/proj/my-repo/api:v1.0.0
docker push us-central1-docker.pkg.dev/proj/my-repo/api:v1.0.0
```

### Vulnerability scanning

Artifact Registry integrates with **Container Analysis**:
- Auto-scans new images for OS package vulnerabilities
- CVE feed from multiple sources
- Findings exposed via Cloud Asset Inventory + Security Command Center
- Pair with Binary Authorization to block deploys of vulnerable images

```bash
gcloud artifacts vulnerabilities list \
  us-central1-docker.pkg.dev/proj/my-repo/api:v1.0.0
```

### Repository policies

- **Remote repositories** proxy public registries (Docker Hub, npm) — control egress + cache
- **Virtual repositories** aggregate multiple upstream repos behind one URL
- **Cleanup policies**: delete images by tag/age/keep-N — essential for cost control
- **CMEK** — encrypt repo contents with customer-managed keys

## Binary Authorization

Sign images at build, verify at deploy. Pattern:

1. **Attestor** = the signing identity (e.g., "build-attestor")
2. **Attestation** = a signed statement that image X passed policy Y at time T
3. **Policy** = "deploys to project P, cluster C require attestation by attestor A"
4. **Binauthz enforcement** = GKE/Cloud Run admission rejects unauthorized images

```bash
# Create policy
gcloud container binauthz policy import policy.yaml
```

```yaml
defaultAdmissionRule:
  evaluationMode: REQUIRE_ATTESTATION
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  requireAttestationsBy:
    - projects/proj/attestors/build-attestor

clusterAdmissionRules:
  us-central1.prod-cluster:
    evaluationMode: REQUIRE_ATTESTATION
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    requireAttestationsBy:
      - projects/proj/attestors/build-attestor
      - projects/proj/attestors/security-attestor
```

Mandatory for regulated workloads. Strongly recommended for everything else — it's the cheapest path to "no untrusted images in prod."

## GKE — release channels and upgrade discipline

| Channel | Cadence | Use |
|---------|---------|-----|
| **RAPID** | Latest releases, most features | Test environments, feature validation |
| **REGULAR** | Stable + features | Production default |
| **STABLE** | Conservative, slowest | Risk-averse production |

**Auto-upgrade is on by default in Autopilot.** In Standard, configure maintenance windows + exclusions; never disable auto-upgrade in prod (you'll fall behind, then need to leapfrog versions).

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

### Node pool patterns (Standard only)

- **Separate node pools** for system workloads (kube-system) and application workloads
- **Spot node pool** for batch / fault-tolerant workloads
- **GPU node pool** with taints, app pods tolerate the taint
- **C4A (Arm) node pool** for Arm-compatible workloads — 20-40% cheaper

### Workload Identity (GKE-side)

Maps Kubernetes service accounts to GCP service accounts. Pod uses KSA → KSA is bound to GSA via `roles/iam.workloadIdentityUser` → pod gets GSA's IAM permissions transparently.

```bash
gcloud iam service-accounts add-iam-policy-binding gsa@proj.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="serviceAccount:proj.svc.id.goog[my-namespace/my-ksa]"

kubectl annotate serviceaccount my-ksa \
  --namespace=my-namespace \
  iam.gke.io/gcp-service-account=gsa@proj.iam.gserviceaccount.com
```

No service account keys mounted into pods. Same security posture as Cloud Run runtime SA.

## Deployment strategies

| Strategy | When | How (Cloud Run) | How (GKE) |
|----------|------|-----------------|-----------|
| **Direct (push to prod)** | Internal tools, low-risk | `gcloud run deploy ... --no-traffic=false` | `kubectl apply` (rolling) |
| **Blue/green** | Stateless services with clean cutover | Two services + GLB switching | Two Deployments + Service selector switch |
| **Canary** | Risk-aware production | Cloud Run traffic splitting (`--no-traffic` then `gcloud run services update-traffic`) | Argo Rollouts / Flagger / Service Mesh |
| **Rolling** | Default for K8s; gradual replacement | N/A | `kubectl rollout` |
| **Shadow / mirror** | Validate new version without serving | Custom routing via GLB + traffic mirroring | Service Mesh traffic mirroring |

**Cloud Run canary** is built in and the cheapest production canary path:

```bash
# Deploy new revision but route 0% traffic to it
gcloud run deploy api \
  --image=... \
  --tag=canary \
  --no-traffic

# Route 10% to canary
gcloud run services update-traffic api \
  --to-tags=canary=10

# Promote if metrics look good
gcloud run services update-traffic api \
  --to-tags=canary=100
```

## Cost optimization in CI/CD

- **Cloud Build minute pricing**: free tier 120 min/day; private pool is per-machine-hour
- **Artifact Registry storage**: cleanup policies are essential — `keep-recent-N` + `delete-old-untagged`
- **GKE Autopilot**: pay per pod; right-size requests
- **Cloud Run min-instances**: cost per warm instance; only raise above 0 when latency demands
- **Compute Engine CUDs**: 1yr 37%, 3yr 57%; FinOps Hub shows recommendations
- **Spot VMs**: up to 91% off; right for fault-tolerant CI runners, batch jobs

## Tooling specifics

| Tool | Purpose |
|------|---------|
| **gcloud CLI** | Authoritative; pin version in CI |
| **Terraform `google` + `google-beta`** | IaC; pin minor version |
| **`terraform-google-modules`** | Maintained module library; use over custom modules for foundation, networking, IAM |
| **Cloud Code (VS Code/IntelliJ)** | Local Cloud Run + GKE dev loop; Gemini Code Assist integration |
| **`cloud-sql-auth-proxy`** | Local Cloud SQL connectivity |
| **`berglas`** / **`google-secret-manager` SDK** | Secret access in code |
| **`gke-gcloud-auth-plugin`** | kubectl auth for GKE clusters (replaces in-tree auth removed in K8s 1.26+) |
| **`skaffold`** | Local Cloud Run/GKE dev loop, manifest rendering, used by Cloud Deploy |
| **`kpt`** | K8s config management; alternative to Helm for some use cases |
| **`config-sync`** | GitOps for GKE + Anthos |
| **`policy-controller`** | OPA Gatekeeper for GKE policy enforcement |

## Anti-patterns

- **`gcr.io/proj/image:tag` in new code** — deprecated; use Artifact Registry hostnames
- **Service account JSON key in CI secret** — use WIF
- **Deployment Manager templates** for new infra — migrate to Infrastructure Manager or Terraform now
- **`gcloud functions deploy --runtime=nodejs14`** without `--gen2` — gen1 is deprecated
- **No `terraform plan` review in PR** — drift and surprise risk
- **Mixing `google` and `google-beta` providers without annotation** — drift confusion
- **Single Terraform state file for everything** — blast radius issues; split per env at minimum
- **Cloud Build public pool for builds that touch private resources** — they'll fail; use private pool
- **No image cleanup policy in Artifact Registry** — storage cost time bomb
- **GKE Standard without taints for spot pools** — workloads schedule on spot, get preempted, you wonder why
- **Auto-upgrade disabled in GKE prod** — you fall behind, then leapfrog risk
- **No Binary Authorization on regulated workloads** — audit finding waiting to happen
- **`gcloud auth activate-service-account --key-file`** in 2026 CI scripts — replace with WIF

## Verification checklist for devops-engineer on GCP

- [ ] Image registry: Artifact Registry only; no `gcr.io` references in Dockerfiles or deploy scripts
- [ ] CI auth: WIF for all external CI (GitHub Actions, GitLab); no service account keys in secrets
- [ ] IaC: Terraform with remote GCS backend, versioning + encryption (CMEK); per-env state prefixes
- [ ] Provider versions pinned in `versions.tf`; explicit `google` vs `google-beta` annotations
- [ ] Plan review in PR: `terraform plan` artifact attached, human review required
- [ ] Cloud Build pool selection: private pool for builds needing VPC access
- [ ] Deployment strategy: canary or rolling for prod, never direct push without traffic guard
- [ ] Binary Authorization enabled for prod GKE + Cloud Run if regulated
- [ ] Artifact Registry cleanup policy configured per repo
- [ ] GKE: regional cluster, release channel set, private nodes, Workload Identity, auto-upgrade enabled
- [ ] Cloud Run min-instances set per latency profile; max-instances cap protects downstreams
- [ ] No legacy paths: no Deployment Manager, no `gcr.io`, no Cloud Functions gen1, no service account keys for net-new
- [ ] Currency check: feature/syntax recommended is GA or explicitly accepted as Preview

## Integration with always-on protocols

- **TDD on infra**: every Terraform module ships with a `tests/` directory containing `terratest` Go tests or `terraform test` HCL tests. Validate the module produces expected resources in a sandbox project before promoting.
- **Verification**: every CI pipeline run produces deploy evidence — `gcloud run services describe`, GKE pod status, observed health probe, smoke-test result. "It deployed" is not verification.
- **Debugging**: failed deploys → Cloud Build logs first, Cloud Run revisions list second, Cloud Audit Logs third (for IAM/permission errors).
- **Plan execution**: pipeline stages map to plan tasks; each stage has its own verification gate (build, test, deploy-staging, smoke-test-staging, deploy-prod, smoke-test-prod).
- **Branch safety**: `terraform plan` must show empty diff on main before merging. Pre-merge hook + nightly drift check + auto-alert on non-empty diff.
- **Review**: every IaC PR includes the plan output, every CI pipeline change includes the rendered config change, every deploy strategy change requires explicit reviewer approval.
