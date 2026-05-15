---
title: Secret Manager
description: GCP's managed secret store — passwords, API keys, certificates; pair with Parameter Manager for non-secret config; automatic rotation for supported integrations.
product:
  name: Secret Manager
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect, devops-engineer]
  authoritative_url: https://cloud.google.com/secret-manager/docs
  notes: "Stable; Parameter Manager GA companion service for non-secret config; runtime SA = `secretAccessor`."
---

## What it is

Secret Manager is GCP's managed secret store — passwords, API keys, certificates, private keys. Companion service **Parameter Manager** (GA) handles non-secret configuration (feature flags, URLs, tunable knobs) with the same IAM + audit model.

Authoritative reference: [cloud.google.com/secret-manager/docs](https://cloud.google.com/secret-manager/docs).

## When to use

Pick Secret Manager when:
- Passwords, API keys, OAuth client secrets, certificates
- Per-environment secrets (different DB password per env)
- Need versioned secret history for rotation

Pick Parameter Manager when:
- Non-secret runtime config (feature flag, URL, tunable)
- Same audit + IAM model you want for secrets, applied to config

Don't use Secret Manager when:
- The value is non-secret config — use Parameter Manager
- The value is an encryption key — use [Cloud KMS](/stacks/gcp/cloud-kms/)
- The value is a service identity — use IAM service account + WIF, not a stored credential

## 2025-2026 currency anchors

- **Parameter Manager** GA — companion to Secret Manager for non-secret config.
- **Automatic rotation** for supported integrations (Cloud SQL via Secret Manager + Cloud Scheduler trigger to rotation function).
- **Replication policy** per secret (automatic global vs user-managed regional).
- **CSI driver** for Secret Manager → GKE pod mount.
- **`--set-secrets`** flag on `gcloud run deploy` for Cloud Run secret mounting.

## Patterns

### Secret lifecycle

```bash
gcloud secrets create db-password --replication-policy=automatic

echo -n "s3cur3P@ss" | gcloud secrets versions add db-password --data-file=-

# Access in Cloud Run
gcloud run deploy my-service \
  --set-secrets=DB_PASSWORD=db-password:latest

# Access in GKE via CSI driver (Secret Manager CSI driver mounts secrets as files)
```

### IAM on secrets

- **`roles/secretmanager.secretAccessor`** — read secret versions; bind to **runtime SA**
- **`roles/secretmanager.secretVersionManager`** — add/disable/destroy versions; bind to **deploy SA** or rotation function
- **`roles/secretmanager.admin`** — full control; bind **sparingly to humans**, never at project scope

### Rotation

- **Automated** for supported integrations
- **Manual** for everything else — schedule via Cloud Scheduler + Cloud Run function; function generates new credential, writes new Secret Manager version, retires old version
- **Rotation period**: 90 days for sensitive secrets, 365 days for medium-sensitivity. Compliance regimes have specific requirements (e.g., PCI DSS 12.3.10 for keys).

### Audit

Secret access logs go to Cloud Audit Logs (`DATA_READ`). Enable via project-level audit log config; aggregate to BigQuery sink for analysis.

## Anti-patterns

- **`secretmanager.admin` at project scope** — over-broad; grant per-secret.
- **Long-lived secrets with no rotation** — same as long-lived passwords; audit liability.
- **`secretVersionManager` to runtime SA** — runtime should be `secretAccessor` only.
- **Secret stored in env var without Secret Manager** — env vars leak into logs, snapshots, debugger sessions.
- **Same secret across environments** (prod / staging / dev) — defeats rotation isolation.

## Gotchas

- **Replication policy** at creation is irreversible — pick automatic (global) or user-managed (specific regions) deliberately.
- **CMEK on secrets** is supported but adds latency; only when policy mandates.
- **Secret value limits** — max 64 KiB per version; larger payloads (certs with full chain) may need chunking.
- **Cloud Run secret mount** vs **env var** — both work; volume mount is rotated transparently when the secret rotates and the service restarts.

## Cross-references

- Related: [Cloud KMS](/stacks/gcp/cloud-kms/), [Cloud IAM](/stacks/gcp/cloud-iam/), [Cloud Run](/stacks/gcp/cloud-run/), [GKE](/stacks/gcp/gke/)
- Roles: [security-engineer on GCP](/stacks/gcp/security-engineer/), [backend-architect on GCP](/stacks/gcp/backend-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/secret-manager/docs](https://cloud.google.com/secret-manager/docs)
