---
title: gcloud CLI
description: GCP's authoritative command-line interface — multi-configuration support, WIF authentication, component-based plugin architecture. Pin version in CI.
product:
  name: gcloud CLI
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, backend-architect, system-architect, security-engineer]
  authoritative_url: https://cloud.google.com/sdk/gcloud/reference
  notes: "Stable but constant additions; alpha/beta surfaces large; release-track flags matter for IaC."
---

## What it is

`gcloud` is GCP's authoritative CLI. Plugin-based via "components"; supports multi-environment configurations; integrates with Workload Identity Federation for keyless CI auth.

Authoritative reference: [cloud.google.com/sdk/gcloud/reference](https://cloud.google.com/sdk/gcloud/reference).

## When to use

`gcloud` is universal on GCP. The decisions:

- **Interactive** vs **CI** — interactive uses `gcloud auth login`; CI uses WIF, not service account keys
- **`gcloud`** vs **`gcloud alpha` / `gcloud beta`** — alpha/beta produce state Terraform may not understand
- **Single config** vs **multiple configurations** — `gcloud config configurations` for multi-env
- **`gcloud`** vs **Terraform** — gcloud for interactive ops; Terraform for IaC; never both for the same resource

## 2025-2026 currency anchors

- **WIF authentication** is the 2026 baseline for CI — `gcloud auth login` is interactive only.
- **`gcloud storage`** replaces `gsutil`.
- **`gke-gcloud-auth-plugin`** is required for `kubectl` against GKE 1.26+.
- **Component pinning** in CI is essential — `gcloud components update` in CI is non-determinism.

## Patterns

### Multi-configuration setup

```bash
gcloud config configurations create prod
gcloud config set project my-prod-project
gcloud config set compute/region us-central1

gcloud config configurations create dev
gcloud config set project my-dev-project

gcloud config configurations activate prod
```

### CI authentication (WIF)

```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github-pool/providers/github-provider
    service_account: deploy@proj.iam.gserviceaccount.com
- uses: google-github-actions/setup-gcloud@v2
- run: gcloud run deploy api --image=...
```

No key file; short-lived federated token.

### Useful command groups

`gcloud auth`, `gcloud config`, `gcloud projects`, `gcloud iam`, `gcloud run`, `gcloud container`, `gcloud artifacts`, `gcloud builds`, `gcloud deploy`, `gcloud secrets`, `gcloud kms`, `gcloud sql` / `gcloud alloydb` / `gcloud spanner`, `gcloud pubsub` / `gcloud eventarc`, `gcloud ai`, `gcloud beta` / `gcloud alpha`.

## Anti-patterns

- **`gcloud auth activate-service-account --key-file`** in 2026 CI — replace with WIF.
- **`gcloud beta` / `gcloud alpha`** for production-managed state without explicit acceptance.
- **`gcloud components update`** in CI — non-deterministic.
- **Mixing default config with explicit `--project` flags** — confusion.

## Gotchas

- **Default regions vary** by command group; always set explicitly in CI scripts.
- **`CLOUDSDK_*` env vars** override flags; produces hard-to-debug behavior.
- **`gcloud beta` / `gcloud alpha`** commands produce state Terraform may not understand without `google-beta` provider.

## Cross-references

- Related: every other GCP product
- Roles: [devops-engineer on GCP](/stacks/gcp/devops-engineer/), [security-engineer on GCP](/stacks/gcp/security-engineer/)
- Authoritative: [cloud.google.com/sdk/gcloud/reference](https://cloud.google.com/sdk/gcloud/reference)
