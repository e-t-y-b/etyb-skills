---
title: Cloud Storage
description: GCP object storage — single-region / dual-region / multi-region buckets, storage classes (Standard / Nearline / Coldline / Archive), Autoclass, lifecycle policies.
product:
  name: Cloud Storage
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, backend-architect, database-architect, security-engineer]
  authoritative_url: https://cloud.google.com/storage/docs
  notes: "Foundational; mature. Autoclass auto-transitions storage classes; multi-region buckets have RTO of zero by design."
---

## What it is

Cloud Storage is GCP's object store — durable, globally-accessible, strongly consistent. Foundation for everything from static asset hosting to data lakes, ML training data, and backups.

Buckets can be:
- **Single-region** — lowest cost, region-bound
- **Dual-region** — two specific regions; transparent replication
- **Multi-region** — broad geographic coverage; highest cost, lowest latency from disparate clients

Storage classes:
- **Standard** — hot data, frequent access
- **Nearline** — accessed monthly, lower at-rest cost
- **Coldline** — accessed quarterly
- **Archive** — accessed yearly; lowest at-rest cost, highest retrieval cost

Authoritative reference: [cloud.google.com/storage/docs](https://cloud.google.com/storage/docs).

## When to use

Cloud Storage is the default for:
- Static assets, media, large file uploads
- Backups, ML training data, BigQuery external tables ([BigLake](/stacks/gcp/biglake/))
- Pub/Sub long-archive ([Cloud Storage subscription](/stacks/gcp/pub-sub/))
- App Engine static handlers' replacement when migrating to Cloud Run

When you need:
- **Transactional access patterns** → not Cloud Storage; use a database
- **POSIX file semantics** → Filestore (managed NFS), not Cloud Storage
- **Block storage** → Persistent Disk on Compute Engine

## 2025-2026 currency anchors

- **Autoclass** auto-transitions objects between storage classes based on access patterns — useful when access pattern is unknown or variable. **Explicit lifecycle policies are cheaper than Autoclass for predictable patterns.**
- **Uniform bucket-level access** is the recommended default — disables legacy ACLs in favor of IAM. Enforce via org policy `constraints/storage.uniformBucketLevelAccess`.
- **Soft delete** retention is configurable per bucket; protects against accidental delete.
- **Object versioning** + lifecycle to keep N versions / delete after M days is the standard pattern for tamper resistance.

## Patterns

### Production bucket with lifecycle + versioning + CMEK

```bash
gcloud storage buckets create gs://my-bucket \
  --location=us-central1 \
  --uniform-bucket-level-access \
  --default-encryption-key=projects/proj/locations/us-central1/keyRings/prod/cryptoKeys/storage \
  --versioning
```

Lifecycle:
```json
{
  "lifecycle": {
    "rule": [
      {"action": {"type": "Delete"}, "condition": {"age": 365, "isLive": false}},
      {"action": {"type": "SetStorageClass", "storageClass": "NEARLINE"}, "condition": {"age": 30}},
      {"action": {"type": "SetStorageClass", "storageClass": "COLDLINE"}, "condition": {"age": 90}}
    ]
  }
}
```

### Public asset bucket behind Cloud CDN

```bash
gcloud storage buckets create gs://public-assets --location=us-central1
gcloud storage buckets add-iam-policy-binding gs://public-assets \
  --member=allUsers --role=roles/storage.objectViewer
```

Pair with [Cloud CDN](/stacks/gcp/cloud-cdn/) backed by a GLB pointing at the bucket as a backend bucket.

### Signed URLs for time-limited access

```python
from google.cloud import storage
from datetime import timedelta

client = storage.Client()
bucket = client.bucket("private-uploads")
blob = bucket.blob("user-uploads/abc.jpg")

url = blob.generate_signed_url(
    version="v4",
    expiration=timedelta(minutes=15),
    method="PUT",
)
# Return url to client for direct upload
```

## Anti-patterns

- **Public buckets without intent** — `allUsers` IAM binding is a common data leak. Default uniform bucket-level access + audit IAM bindings.
- **Legacy ACLs** instead of IAM — use uniform bucket-level access.
- **No lifecycle policy** on long-lived buckets — storage costs grow indefinitely.
- **Autoclass on predictable workloads** — explicit lifecycle is cheaper.
- **No CMEK on regulated buckets** — encryption-at-rest with default keys is OK for most data; CMEK required for regulated.
- **Single-region bucket for global asset serving** — pair with [Cloud CDN](/stacks/gcp/cloud-cdn/) or use multi-region bucket.

## Gotchas

- **Egress cost** is real — interzone, interregion, and internet egress charge by GB. Place compute and bucket in the same region; use Cloud CDN for repeated content.
- **Object versioning + lifecycle** is the standard pattern for retain-N-versions; raw versioning without lifecycle accumulates forever.
- **Strong consistency** for object create / update / delete; no eventual consistency window for new builds.
- **`gsutil` is deprecated**; `gcloud storage` is the current CLI.

## Cross-references

- Related: [Cloud CDN](/stacks/gcp/cloud-cdn/), [BigLake](/stacks/gcp/biglake/) (external tables), [Pub/Sub](/stacks/gcp/pub-sub/) (Cloud Storage subscription), [Cloud KMS](/stacks/gcp/cloud-kms/) (CMEK)
- Roles: [system-architect on GCP](/stacks/gcp/system-architect/), [security-engineer on GCP](/stacks/gcp/security-engineer/), [database-architect on GCP](/stacks/gcp/database-architect/)
- Authoritative: [cloud.google.com/storage/docs](https://cloud.google.com/storage/docs)
