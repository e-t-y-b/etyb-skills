---
title: ElastiCache
description: AWS managed in-memory cache — Valkey 7.2 is 33% cheaper than Redis OSS, MemoryDB for durable in-memory with multi-region, Cluster Mode for >100GB caches.
product:
  name: ElastiCache
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, backend-architect, system-architect]
  authoritative_url: https://docs.aws.amazon.com/elasticache/
  notes: "Valkey 7.2 is 33% cheaper than Redis OSS engine on the same instance class. Net-new caches: Valkey. Wire-compatible; existing Redis clients work unchanged."
---

## What it is

Amazon ElastiCache is the managed in-memory cache — **Valkey** (Redis fork, the new default), **Redis OSS** (legacy engine), and **Memcached**. ElastiCache **Serverless** auto-scales capacity. **MemoryDB** is the durable in-memory sibling with multi-AZ transaction log and multi-region active-active.

Canonical surface: [docs.aws.amazon.com/elasticache](https://docs.aws.amazon.com/elasticache/).

## When to use

| Need | Use ElastiCache? |
|---|---|
| Cache (recoverable from a source of truth) | Yes — ElastiCache (Valkey) |
| Durable in-memory primary store | No — use MemoryDB |
| Multi-region in-memory | MemoryDB Multi-Region |
| Variable cache load | ElastiCache Serverless |
| Predictable large cache | Node-based with reserved capacity |

## 2025-2026 currency anchors

- **Valkey 7.2 on ElastiCache** is **33% cheaper** than Redis OSS engine on the same instance class. Wire-compatible; existing Redis client libraries work unchanged. **Net-new caches: Valkey.**
- **ElastiCache Serverless** matured — auto-scales capacity.
- **MemoryDB** mature — durable in-memory with multi-AZ transaction log.
- **MemoryDB Multi-Region** — active-active replication, microsecond reads, single-digit ms writes, 99.999% availability.

## Patterns

### ElastiCache vs MemoryDB

| | ElastiCache | MemoryDB |
|---|---|---|
| **Durability** | Lossy (in-memory only; replicas + snapshots help) | Durable (multi-AZ transaction log) |
| **Latency** | Sub-ms reads | Microsecond reads, single-digit ms writes |
| **Use case** | Cache, session store, leaderboard, rate limiter | Primary KV store with Redis API |
| **Multi-region** | Global Datastore (active-passive) | Multi-Region (active-active) |
| **Cost** | Lower | Higher (durability premium) |

**Pick ElastiCache** when data is recoverable from a source of truth (typically RDS / DynamoDB / Aurora).

**Pick MemoryDB** when data must not be lost across node failures, and you want Redis API.

### Connection patterns

```typescript
import Redis from 'ioredis';

const redis = new Redis({
  host: process.env.CACHE_ENDPOINT!,
  port: 6379,
  tls: {}, // ElastiCache encryption-in-transit
  password: process.env.CACHE_AUTH_TOKEN!, // Or use IAM auth
  enableOfflineQueue: false, // Fail fast when cache is down
  maxRetriesPerRequest: 1,
  connectTimeout: 1000,
});
```

**Always** set `enableOfflineQueue: false` and a small `maxRetriesPerRequest` — when the cache is down, fail open to the database, don't queue commands forever.

### Cluster mode

- **Cluster mode disabled**: single primary + read replicas. Drivers connect to primary for writes, reader endpoint for reads. Simpler; cache-sized workloads.
- **Cluster mode enabled**: sharded across nodes. Drivers must be cluster-aware (`redis-cluster` for Node, `redis-py-cluster` for Python). Use for >100GB caches or >100K RPS.

### Cache patterns

- **Cache-aside (lazy loading)**: app reads from cache; on miss, reads from source, populates cache. Simple, but stampedes possible.
- **Write-through**: app writes to cache and source synchronously. Stronger consistency, higher write latency.
- **Write-behind**: app writes to cache, async to source. Eventual consistency.
- **Read-through**: cache itself fetches on miss (less common; usually in client lib).

### TTL discipline

Every cache entry must have a TTL unless you have a story for invalidation. Default: 5-15 minutes for most data. Sub-second for high-mutation. Long TTL + manual invalidation only if you control all write paths.

### Valkey migration

ElastiCache Blue/Green in-place upgrade migrates from Redis OSS to Valkey without re-provisioning. Existing client libraries unchanged.

## Anti-patterns

- **Redis OSS engine on new ElastiCache.** Use Valkey.
- **No TTL on cache entries** — cache forever, invalidate manually — only viable if you control all write paths perfectly.
- **`enableOfflineQueue: true`** — when cache is down, queue commands fills memory and stalls the app.
- **Cluster mode disabled for >100GB cache.** Use cluster mode enabled.
- **AUTH token in source code.** Use Secrets Manager.
- **Cache in public subnet.** Always private subnet + VPC endpoint.

## Gotchas

- **Cluster mode requires cluster-aware client.** Standard Redis client won't work for cluster mode enabled.
- **TLS in transit** requires `tls: {}` in client config — easy to miss; cache reads fail silently otherwise.
- **AUTH token** vs IAM auth (newer) — IAM is preferred for new deployments.
- **Replication lag** to read replicas can cause stale reads.
- **Failover preserves connections via DNS** but in-flight commands may fail; application must retry.

## Cross-references

- [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) — alternative for sub-ms KV with durability
- [`/stacks/aws/aurora/`](/stacks/aws/aurora/) — typical cache source-of-truth
- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — Lambda + ElastiCache connection pooling
- [`/stacks/aws/database-architect/`](/stacks/aws/database-architect/) — role view; caching tier
- [Valkey + ElastiCache migration](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/valkey-migration.html)
