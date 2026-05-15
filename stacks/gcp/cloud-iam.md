---
title: Cloud IAM
description: GCP's identity and access management — hierarchical (org → folder → project → resource), allow + deny policies, IAM Conditions, custom roles.
product:
  name: Cloud IAM
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, system-architect, devops-engineer, saas-architect]
  authoritative_url: https://cloud.google.com/iam/docs
  notes: "Hierarchical model stable; deny policies GA; IAM Conditions mature; Policy Intelligence / Recommender for IAM hygiene."
---

## What it is

Cloud IAM is GCP's identity + access management. The model is hierarchical:

- **Organization** (your domain / company) — root of trust
- **Folders** (optional, nested up to 10 levels) — group projects, attach policies + budgets
- **Projects** — resource container, primary IAM blast radius
- **Resources** — individual buckets, instances, services

IAM bindings at a higher level inherit downward. A grant of `roles/editor` at the org level gives editor on every project under the org.

Authoritative reference: [cloud.google.com/iam/docs](https://cloud.google.com/iam/docs).

## When to use

IAM is universal on GCP — you can't not use it. The decisions:

- **Predefined roles** vs **custom roles** — default predefined; create custom only when predefined is too coarse
- **Allow policies** vs **deny policies** — allows are the model; deny policies are break-glass guardrails
- **Static IAM** vs **IAM Conditions** — Conditions add ABAC (time-bound, tag-based, resource-attribute-based)
- **Service accounts** — runtime SA per workload, deploy SA per pipeline; never shared SAs

## 2025-2026 currency anchors

- **Deny policies** GA — explicitly forbid actions regardless of allows. Useful for "no one, not even owners, can delete this bucket."
- **IAM Conditions** mature — time-bound access, resource tags, IP source range constraints.
- **Workload Identity Federation** (see [security-engineer on GCP](/stacks/gcp/security-engineer/)) is the production answer for non-GCP workloads. Service account JSON keys are an audit red flag in 2026.
- **Policy Intelligence / Recommender** flags unused roles, excess permissions.
- **`iam.disableServiceAccountKeyCreation`** org constraint blocks key creation org-wide — the most effective single control.

## Patterns

### The project is the blast radius

The most common IAM mistake: granting `roles/editor` or `roles/viewer` at project scope to a human or service account when a more specific predefined role or resource-scoped binding would suffice. **Editor is essentially admin minus a few governance operations** — leaking it is catastrophic.

Default:
- No `roles/owner`, `roles/editor`, `roles/viewer` at project scope for human users
- Predefined roles bound to specific resources where possible
- Custom roles when predefined is too coarse

### IAM Conditions

```bash
gcloud projects add-iam-policy-binding proj \
  --member="user:incident-responder@example.com" \
  --role=roles/cloudsql.admin \
  --condition="expression=request.time < timestamp('2026-05-15T00:00:00Z'),title=incident_2026_05_14"
```

Time-bound JIT elevation; resource tags; IP source ranges. Use for break-glass workflows.

### Service accounts — least privilege

- **Per-workload runtime SA**: each Cloud Run service / GKE workload / Cloud Function gets its own SA with least-privilege roles
- **Per-pipeline deploy SA**: separate from runtime; used for `gcloud deploy` / `terraform apply` / `kubectl apply`
- **No shared SAs**: per-workload-per-stage is the unit of IAM granularity
- **No default Compute Engine SA**: has broad permissions; replace with explicit SAs

## Anti-patterns

- **`roles/owner` / `roles/editor` / `roles/viewer` at project scope** for humans — over-broad; use predefined or custom roles
- **Default Compute Engine SA** as runtime SA — over-privileged
- **Shared SAs** across workloads — blast radius issue
- **Service account JSON keys** — use Workload Identity Federation for external workloads
- **No `iam.disableServiceAccountKeyCreation`** at org level — leaves the key-leakage door open
- **`secretmanager.admin` at project scope** — grant per-secret, not broadly

## Gotchas

- **Policy size limits** apply per resource; very wide policies eventually hit them.
- **Eventual consistency** for IAM changes (~minutes) — don't tightly couple deploy steps to brand-new bindings.
- **Aggregated audit logs** for IAM changes go to Cloud Audit Logs `Admin Activity` (always on, free).
- **Recommender** runs continuously; "Excess Permission Recommendations" + "Unused Role Recommendations" are the IAM hygiene levers.

## Cross-references

- Related: [Secret Manager](/stacks/gcp/secret-manager/), [Cloud KMS](/stacks/gcp/cloud-kms/), [VPC](/stacks/gcp/vpc/), [Cloud Armor](/stacks/gcp/cloud-armor/)
- Roles: [security-engineer on GCP](/stacks/gcp/security-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/iam/docs](https://cloud.google.com/iam/docs)
