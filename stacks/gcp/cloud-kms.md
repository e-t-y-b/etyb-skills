---
title: Cloud KMS
description: GCP's managed key management — software / HSM / External Key Manager (EKM); CMEK on supported services; automatic rotation.
product:
  name: Cloud KMS
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, system-architect, database-architect]
  authoritative_url: https://cloud.google.com/kms/docs
  notes: "Stable. CMEK + EKM patterns mature; default for regulated workloads; key rings are regional."
---

## What it is

Cloud KMS is GCP's managed key management. Three service tiers:

- **Software** (default) — keys managed in Google's hardware boundary
- **HSM** — FIPS 140-2 Level 3 validated hardware; required for some compliance regimes (PCI strict, HIPAA strict)
- **EKM (External Key Manager)** — keys held by external HSM provider (Thales, Equinix, Fortanix, Virtru); GCP gets short-lived key access; required when sovereign control mandates non-Google possession

Customer-managed encryption keys (**CMEK**) are the regulated-workload default — pair Cloud KMS keys with Cloud Storage, Cloud SQL, BigQuery, Pub/Sub, and most other GCP services.

Authoritative reference: [cloud.google.com/kms/docs](https://cloud.google.com/kms/docs).

## When to use

Pick Cloud KMS when:
- Regulated workloads (HIPAA, PCI, FedRAMP, SOC 2) — CMEK on supported services
- Sovereign / export-controlled workloads — EKM with external HSM
- Application-layer encryption (encrypt fields before storing)
- Signing operations (asymmetric keys, MAC keys)

Don't pick Cloud KMS when:
- Default Google-managed encryption is sufficient for the data class — most non-regulated apps
- The need is a secret (password, API key) — use [Secret Manager](/stacks/gcp/secret-manager/)

## 2025-2026 currency anchors

- **CMEK** on supported services is mature; the standard for regulated workloads.
- **EKM** providers expanded; check the supported list for your HSM vendor.
- **Automatic rotation** for software-protected symmetric keys; manual for HSM/EKM.
- **Org policy `constraints/gcp.restrictNonCmekServices`** enforces CMEK org-wide on supported services.

## Patterns

### Key ring + key + rotation

```bash
gcloud kms keyrings create prod-keyring --location=us-central1

gcloud kms keys create app-data-key \
  --keyring=prod-keyring \
  --location=us-central1 \
  --purpose=encryption \
  --rotation-period=90d \
  --next-rotation-time=2026-08-01T00:00:00Z
```

- **Key rings are regional** — create per environment per region
- **Keys** within a ring — one per use case (encrypting Cloud Storage X, encrypting Cloud SQL Y)
- **Versioning** — old key versions kept for decryption of old ciphertext; rotate, don't rebuild

### CMEK on Cloud Storage

```bash
gcloud storage buckets create gs://my-bucket \
  --location=us-central1 \
  --default-encryption-key=projects/proj/locations/us-central1/keyRings/prod-keyring/cryptoKeys/storage
```

### CMEK enforcement at org policy level

```
constraints/gcp.restrictNonCmekServices = enforced (with allowed services list)
constraints/gcp.restrictCmekCryptoKeyProjects = enforced (scope which projects' keys can be used)
```

Forces CMEK across the org for supported services.

## Anti-patterns

- **No CMEK on regulated services** — audit finding.
- **Same key for multiple unrelated workloads** — blast radius issue on key compromise.
- **No rotation policy** — long-lived keys are an audit smell.
- **Granting `cloudkms.cryptoKeyEncrypterDecrypter` at project scope** — over-broad; grant per-key.

## Gotchas

- **Key ring deletion** is not allowed — you can disable / schedule destruction of versions, but not the key ring.
- **Cross-region key usage**: KMS keys are regional; align with the resource's region or use a multi-region key.
- **EKM latency** adds per-operation cost; verify against your throughput needs.
- **Backup and DR for keys**: HSM/EKM keys may not survive ungraceful provider transitions — plan key migration ahead of vendor change.

## Cross-references

- Related: [Cloud Storage](/stacks/gcp/cloud-storage/), [Cloud SQL](/stacks/gcp/cloud-sql/), [Secret Manager](/stacks/gcp/secret-manager/), [BigQuery](/stacks/gcp/bigquery/)
- Roles: [security-engineer on GCP](/stacks/gcp/security-engineer/), [database-architect on GCP](/stacks/gcp/database-architect/)
- Authoritative: [cloud.google.com/kms/docs](https://cloud.google.com/kms/docs)
