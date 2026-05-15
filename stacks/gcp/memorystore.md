---
title: Memorystore
description: Managed in-memory data store on GCP — defaults to Valkey 9.0 in 2026, fully compatible with existing Redis clients, 99.99% SLA.
product:
  name: Memorystore for Valkey
  stack: gcp
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, system-architect]
  authoritative_url: https://cloud.google.com/memorystore/docs
  notes: "Default engine shifted from Redis to Valkey 9.0; existing Redis instances OK but new builds should default to Valkey."
---

## What it is

Memorystore is GCP's managed in-memory data store. **The default engine is now Valkey 9.0**, the Linux Foundation BSD-licensed open-source fork of Redis. Existing Memorystore for Redis tiers are still supported; new builds should default to Valkey for licensing + perf.

Authoritative reference: [cloud.google.com/memorystore/docs](https://cloud.google.com/memorystore/docs).

## When to use

Pick Memorystore for Valkey when:
- In-memory cache for read-heavy workloads (session store, computed results, hot data)
- Pub/Sub-style messaging at low latency where Pub/Sub's semantics don't fit
- Rate limiting / counter store with atomic operations
- Existing Redis client code — Valkey is fully compatible; no driver swap needed

Don't pick Memorystore when:
- Persistent durable storage is the requirement — use [Cloud SQL](/stacks/gcp/cloud-sql/) / [AlloyDB](/stacks/gcp/alloydb/) / [Firestore](/stacks/gcp/firestore/) etc.
- Memory cache is small and can live in-process — Memorystore has per-node minimums

## 2025-2026 currency anchors

- **Valkey 9.0 is the default engine** (2026). Old "Memorystore for Redis" is still available but new builds default to Valkey.
- **Valkey 9.0 perf gains**: +40% throughput from pipeline memory prefetching, +200% on BITCOUNT/HyperLogLog from SIMD, TLS by default.
- **Up to 5 replica nodes per primary**.
- **99.99% SLA**, **Private Service Connect** for private connectivity, persistence, cross-region replication.
- **Fully compatible with existing Redis clients** — driver swap is unnecessary.

## Patterns

### Create a multi-shard Valkey instance

```bash
gcloud memorystore instances create my-cache \
  --location=us-central1 \
  --node-type=highmem-medium \
  --shard-count=3 \
  --replica-count=1 \
  --engine-version=valkey-9.0
```

Multi-shard for horizontal scale + replicas for HA.

### Connectivity from Cloud Run

Use Private Service Connect endpoint; clients connect via redis-protocol on the PSC IP.

```bash
gcloud run deploy api \
  --image=... \
  --vpc-egress=private-ranges-only \
  --network=projects/proj/global/networks/prod-vpc \
  --subnet=projects/proj/regions/us-central1/subnetworks/run-subnet \
  --set-env-vars=REDIS_HOST=10.50.0.10,REDIS_PORT=6379
```

## Anti-patterns

- **Memorystore for Redis as default for new builds** — Valkey is the path forward and Google has aligned with the Linux Foundation fork.
- **Memorystore as durable storage** — it's a cache. Persistence is best-effort recovery, not source-of-truth.
- **No TLS** — Valkey 9.0 has TLS by default; don't disable for "simplicity."
- **Single-zone Memorystore for prod** — use Standard tier (HA) with cross-zone failover.

## Gotchas

- **Cross-region replication** doubles cost — only when DR justifies.
- **Persistence to Cloud Storage** as the backup path; recovery is best-effort, not bit-perfect.
- **Standard tier (HA)** doubles cost vs Basic tier; pick deliberately.
- **Auth** is via AUTH password or IAM (newer paths). PSC + private VPC is the network-level control.

## Cross-references

- Related: [VPC](/stacks/gcp/vpc/) (Private Service Connect), [Cloud Run](/stacks/gcp/cloud-run/) (typical consumer)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [backend-architect on GCP](/stacks/gcp/backend-architect/)
- Authoritative: [cloud.google.com/memorystore/docs](https://cloud.google.com/memorystore/docs)
