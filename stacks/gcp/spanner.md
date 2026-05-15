---
title: Cloud Spanner
description: Globally-distributed, strongly-consistent relational database with horizontal scale, granular PU sizing from $65/month, Spanner Graph, GraphQL endpoint.
product:
  name: Cloud Spanner
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, system-architect, backend-architect, saas-architect]
  authoritative_url: https://cloud.google.com/spanner/docs
  notes: "GraphQL endpoint (2024), Spanner Graph, granular PU sizing, managed autoscaler, PG dialect — feature surface widened materially."
---

## What it is

Spanner is GCP's globally-distributed relational database — strong consistency, horizontal scale, five-9s SLA on multi-region configs, ACID transactions across regions. It's the database equivalent of "buy" vs "build" for globally-distributed strong consistency.

In 2026, Spanner is **no longer the FAANG-only option**. Granular PU sizing starts at 100 PU (~$65/month); 1000 PU = 1 node. 3-year CUDs are 40% off. Dev/staging cost is now bearable.

Authoritative reference: [cloud.google.com/spanner/docs](https://cloud.google.com/spanner/docs).

## When to use

Pick Spanner when:
- **Global ACID** — multi-region writes with strong consistency
- **Horizontal scale beyond a single Postgres instance** — scales linearly to petabytes
- **Five-9s availability SLA** required
- Multi-tenant SaaS where per-tenant Spanner DBs (with granular PU) are operationally simpler than per-tenant Cloud SQL instances

Don't pick Spanner when:
- Single-region is fine and Cloud SQL / AlloyDB sized for the workload — Spanner is more expensive at small scale
- The team has heavy PostgreSQL-isms (specific extensions, JSONB tricks, custom operators) — Spanner's PG dialect is good but not Postgres
- Budget can't absorb Spanner pricing — though with granular PU sizing this is less of a wall than pre-2024

## 2025-2026 currency anchors

- **Granular PU sizing** — starts at 100 PU (~$65/month). 1000 PU = 1 node. Old "Spanner minimum $750/month" advice is wrong.
- **3-year CUDs**: 40% off. 100 PU on 3-year CUD is under $40/mo.
- **Managed autoscaler** (GA) — scales read-only replicas independently from read-write.
- **PostgreSQL dialect** — closer to standard Postgres syntax; easier port path.
- **Spanner Graph** (2024) + **`GRAPH_TABLE(...)`** SQL syntax for Cypher-like queries. Property graphs in Spanner.
- **GraphQL endpoint** (2024) — native GraphQL on top of Spanner schema.

## Patterns

### Create a dev instance with granular PU

```bash
gcloud spanner instances create my-instance \
  --config=regional-us-central1 \
  --processing-units=100 \
  --description="Dev instance" \
  --autoscaling-config=min-processing-units=100,max-processing-units=1000,high-priority-cpu-target=65,storage-target=75
```

### Schema design — primary keys

- **Interleave child tables** with parents — `INTERLEAVE IN PARENT users` colocates child rows for the same user
- **Avoid monotonic primary keys** (timestamps, sequential IDs) — they hotspot the leading split
- **Use UUID v4 or bit-reversed sequences** for primary keys to distribute load
- **Index for read patterns, not write patterns** — secondary indexes have write amplification

### Spanner Graph

```sql
-- Create a property graph over relational tables
CREATE PROPERTY GRAPH SocialGraph
  NODE TABLES (Users, Posts)
  EDGE TABLES (
    Friendships SOURCE KEY (user_id) REFERENCES Users
                DESTINATION KEY (friend_id) REFERENCES Users,
    Authored SOURCE KEY (user_id) REFERENCES Users
             DESTINATION KEY (post_id) REFERENCES Posts
  );

-- Friend-of-friend query
SELECT u2.username AS friend_of_friend
FROM GRAPH_TABLE (SocialGraph
  MATCH (u1:Users WHERE u1.id = @user_id)
       -[:Friendships]->(u2:Users)
       -[:Friendships]->(u3:Users)
  COLUMNS (u3.id, u3.username)
) AS u3;
```

Use cases: social graphs (friends-of-friends), fraud detection (transaction traversal), knowledge graphs. Don't reach for Neo4j on GCP if you can stay in Spanner.

### Sizing

| Workload | Approx PU |
|----------|-----------|
| Dev / staging / small prod | 100 PU (~$65/mo) |
| Small prod transactional | 200-500 PU |
| Mid-size prod (1K-10K QPS) | 1000-5000 PU |
| Large prod | 10000+ PU |

## Anti-patterns

- **Spanner for a single-region OLTP workload that Cloud SQL would handle** — overkill, expensive.
- **Monotonic primary keys** — guaranteed hotspot.
- **No backup strategy because "Spanner is highly available"** — high availability is not DR; ransomware doesn't care. Spanner backups + restore are first-class.
- **Reflexive secondary indexes** — every index has write amplification; index for query patterns, not "just in case."
- **Treating PG dialect as full Postgres** — it's close, not identical.

## Gotchas

- **Multi-region configs** (`nam-eur-asia1`, `nam3`, etc.) have write latency from speed-of-light constraints. Trade-off: strong consistency globally vs higher write latency.
- **Stale reads** are an explicit feature — `MAX_STALENESS` lets you bypass leader for reads when consistency window is acceptable.
- **Transaction limits**: 80,000 mutations per transaction; size accordingly for batch.
- **Spanner emulator** for local development; differs from prod on some edge cases (e.g., autoscaler, multi-region).
- **Cost intuition** has shifted — recheck Spanner pricing for new estimates; old "Spanner is too expensive" advice is often wrong now.

## Cross-references

- Related: [Cloud SQL](/stacks/gcp/cloud-sql/), [AlloyDB](/stacks/gcp/alloydb/), [Firestore](/stacks/gcp/firestore/), [Bigtable](/stacks/gcp/bigtable/), [BigQuery](/stacks/gcp/bigquery/)
- Roles: [database-architect on GCP](/stacks/gcp/database-architect/), [system-architect on GCP](/stacks/gcp/system-architect/), [saas-architect on GCP](/stacks/gcp/saas-architect/)
- Authoritative: [cloud.google.com/spanner/docs](https://cloud.google.com/spanner/docs)
