---
title: VPC
description: GCP networking — VPC, Shared VPC, VPC Service Controls perimeters, Private Service Connect, Cloud NAT. Default VPC is an antipattern in prod.
product:
  name: VPC
  stack: gcp
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, security-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/vpc/docs
  notes: "Foundational. Shared VPC for centralized network admin; VPC-SC for data exfiltration boundary; PSC for private managed-service access."
---

## What it is

VPC is GCP's networking primitive — your private network of subnets, firewall rules, routes, and gateways. Key adjacent concepts:

- **Shared VPC** — central host project owns the VPC; service projects attach for compute, while networking lives centrally
- **VPC Service Controls (VPC-SC)** — identity-aware data exfiltration perimeter around GCP API surfaces
- **Private Service Connect (PSC)** — private endpoints for managed services (Cloud SQL, AlloyDB, Spanner, BigQuery, Pub/Sub) in your VPC
- **Cloud NAT** — egress IP control without public IPs on VMs

Authoritative reference: [cloud.google.com/vpc/docs](https://cloud.google.com/vpc/docs).

## When to use

VPC is universal. The decisions:

- **Default VPC** vs **explicit VPC** — always explicit in prod. Default VPC is an antipattern; disable at org policy.
- **Shared VPC** vs **standalone VPC per project** — Shared VPC is the default for enterprise landing zones.
- **PSC** vs **Private Google Access** — PSC for new builds; PGA is the legacy path.
- **VPC-SC** when data exfiltration is in the threat model — pair with PSC for defense-in-depth.

## 2025-2026 currency anchors

- **VPC Service Controls** supports identity groups + third-party identities in ingress/egress rules (Preview).
- **Private Service Connect** — IPv6 NAT + propagated connections GA in 2025; replacement path for legacy Private Google Access patterns.
- **Network Connectivity Center** hub-and-spoke for multi-region / hybrid topologies (replaces VPC peering hub-and-spoke).
- **Default network creation** — disable at org policy: `constraints/compute.skipDefaultNetworkCreation`.

## Patterns

### Production VPC (explicit, no default)

```bash
gcloud compute networks create prod-vpc \
  --subnet-mode=custom

gcloud compute networks subnets create prod-us-central \
  --network=prod-vpc \
  --region=us-central1 \
  --range=10.10.0.0/16 \
  --enable-private-ip-google-access \
  --enable-flow-logs
```

### Shared VPC

```bash
# Host project
gcloud compute shared-vpc enable host-project

# Attach service project
gcloud compute shared-vpc associated-projects add service-project \
  --host-project=host-project
```

Service teams create resources in their service project; networking lives in host project. Default for enterprise landing zones.

### Private Service Connect for Cloud SQL

```bash
gcloud compute forwarding-rules create cloudsql-psc \
  --region=us-central1 \
  --network=prod-vpc \
  --subnet=psc-subnet \
  --target-service-attachment=...
```

PSC endpoint is a private IP in your VPC; traffic to Cloud SQL never touches the public internet.

### VPC Service Controls perimeter

```bash
gcloud access-context-manager perimeters create prod-perimeter \
  --title="Production Perimeter" \
  --resources="projects/123456789,projects/987654321" \
  --restricted-services="bigquery.googleapis.com,storage.googleapis.com,pubsub.googleapis.com" \
  --policy=POLICY_ID
```

**Always dry-run** a perimeter for at least a week before enforcement. Dry-run logs violations without blocking.

### Firewall hierarchy

- **Org-level firewall policies** (highest precedence) — enforce baselines
- **Network-level firewall policies** — VPC-wide rules
- **VPC firewall rules** — per-VPC fine-grained

Org-level policies are how a central security team enforces "no SSH from 0.0.0.0/0 anywhere in the org."

## Anti-patterns

- **Default VPC in prod** — disable at org policy level.
- **Public IPs on production VMs** — use Cloud NAT for egress; Identity-Aware Proxy for admin ingress.
- **No VPC Flow Logs** — incident investigation is blind without them.
- **VPC-SC perimeter enforced without dry-run** — admins get locked out.
- **Private Google Access** for new builds — use PSC instead.
- **No firewall hierarchy** — every project rolls its own firewall; baseline drift.

## Gotchas

- **VPC-SC supported services** is a defined list — verify per [VPC-SC supported products](https://cloud.google.com/vpc-service-controls/docs/supported-products).
- **PSC `/26` minimum subnet** per service attachment — plan IP space.
- **Cloud NAT** allocates ports per VM — high outbound concurrency can exhaust port pool; tune accordingly.
- **VPC peering** is non-transitive; for hub-and-spoke use Network Connectivity Center.

## Cross-references

- Related: [Cloud Armor](/stacks/gcp/cloud-armor/), [Cloud CDN](/stacks/gcp/cloud-cdn/), [Cloud Run](/stacks/gcp/cloud-run/) (Direct VPC egress), [Cloud SQL](/stacks/gcp/cloud-sql/) / [AlloyDB](/stacks/gcp/alloydb/) / [Spanner](/stacks/gcp/spanner/) (PSC)
- Roles: [security-engineer on GCP](/stacks/gcp/security-engineer/), [system-architect on GCP](/stacks/gcp/system-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/vpc/docs](https://cloud.google.com/vpc/docs)
