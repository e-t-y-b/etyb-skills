---
title: Azure Managed Redis
description: Successor to Azure Cache for Redis. Redis Ltd. enterprise tech. Flash Optimized tier; active geo-replication; RediSearch / RedisJSON / RedisTimeSeries / RedisBloom built-in.
product:
  name: Azure Managed Redis
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect, devops-engineer]
  authoritative_url: https://learn.microsoft.com/azure/azure-managed-redis/
  notes: "New service in active rollout; Azure Cache for Redis classic in phased migration; Valkey not first-party."
---

## What it is

Azure Managed Redis is the successor to Azure Cache for Redis — Redis Ltd. enterprise technology with tiered SKUs (Compute Optimized, Balanced, Memory Optimized, Flash Optimized), active geo-replication, and Redis modules (RediSearch, RedisJSON, RedisTimeSeries, RedisBloom) built in. Canonical reference: [Azure Managed Redis docs](https://learn.microsoft.com/azure/azure-managed-redis/).

## When to use

Pick Azure Managed Redis when:

- **Cache / session store** for any new build.
- **Need Redis modules** — search, JSON, time-series, bloom filter built-in.
- **Large + cheap** caches — Flash Optimized auto-tiers cold data to NVMe.
- **Cross-region read/write** — active geo-replication (with LWW conflict resolution per key).

Don't pick **Azure Cache for Redis classic** (Basic / Standard / Premium / Enterprise / EnterpriseFlash) for new builds — it's in migration to Managed Redis.

## 2025-2026 currency anchors

- **Tiers**: Compute Optimized, Balanced, Memory Optimized, Flash Optimized.
- **SKU sizes 150 and 250 GA at Ignite 2025.**
- **Reserved Instances**: 35% (1y) / 55% (3y) in 30+ regions.
- **Classic Azure Cache for Redis migration tooling** phased: Basic/Standard/Premium from Nov 2025; Enterprise/EnterpriseFlash from March 2026. Expect brief DNS blip (seconds) during migration.
- **Redis modules built-in**: RediSearch (full-text + vector), RedisJSON, RedisTimeSeries, RedisBloom.
- **Active geo-replication** with LWW conflict resolution per key.
- **No first-party managed Valkey on Azure** — self-host on AKS / VMs if license / strategic concerns require it. AWS has ElastiCache Valkey; Azure does not.

## Patterns + anti-patterns

### Pattern: Entra ID auth (not access keys)

Use `DefaultAzureCredential` from app SDK where supported (`StackExchange.Redis` 2.7+, `lettuce`, `ioredis`, `redis-py`). Eliminates access key rotation.

### Pattern: TLS in production, always

`ssl=True` everywhere. Reject any path that disables TLS for "convenience."

### Pattern: Flash Optimized for large hot/cold caches

When working set is mostly in memory but cold tail is large, Flash Optimized auto-tiers cold data to local NVMe. Same Redis API; cheaper than all-RAM at scale.

### Pattern: Active geo-replication for cross-region read

Read locally, write locally; conflicts resolved LWW per key. **Understand the consistency model** — not strong consistency.

### Pattern: Connection multiplexing in client SDK

`StackExchange.Redis`'s `ConnectionMultiplexer` is thread-safe, designed to be a long-lived singleton. Don't open per-request connections.

### Anti-pattern: Azure Cache for Redis classic for new builds

In migration. Pick Managed Redis.

### Anti-pattern: Storing PII in Redis without TTL or encryption-at-rest considerations

Redis is fast, not secret. PII goes elsewhere or with explicit data-handling controls.

### Anti-pattern: Big-key / hot-key patterns

A single 100 MB key blocks the server during eviction. A single key hammered by 10K req/s saturates one shard. Use partitioning / hashing.

## Gotchas

- **Migration from classic to Managed has a DNS blip** (seconds). Plan a maintenance window even for tooling-driven migration.
- **Module availability per tier** — verify RediSearch / RedisJSON inclusion before committing.
- **Active geo-replication latency** — async; cross-region reads of recent writes may miss.
- **No Valkey on Azure** — if license / governance pushes you off Redis Ltd., AKS self-host is the only Azure option.

## Cross-references

- [Backend Architect on Azure](/stacks/azure/backend-architect/) — SDK patterns
- [Database Architect on Azure](/stacks/azure/database-architect/) — tier selection
- [DevOps Engineer on Azure](/stacks/azure/devops-engineer/) — provisioning + migration
- [Azure Managed Redis docs](https://learn.microsoft.com/azure/azure-managed-redis/)
