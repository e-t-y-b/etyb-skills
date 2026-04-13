# Cache Specialist — Deep Reference

**Always use `WebSearch` to verify current versions, licensing changes, and managed service features before giving advice. The caching landscape has undergone significant changes (Redis licensing, Valkey fork) in 2024-2025.**

## Table of Contents
1. [Caching Fundamentals](#1-caching-fundamentals)
2. [Redis Deep Dive](#2-redis-deep-dive)
3. [Valkey — The Redis Fork](#3-valkey--the-redis-fork)
4. [Memcached](#4-memcached)
5. [DragonflyDB](#5-dragonflydb)
6. [Caching Patterns](#6-caching-patterns)
7. [Cache Invalidation Strategies](#7-cache-invalidation-strategies)
8. [CDN Caching](#8-cdn-caching)
9. [Multi-Layer Caching](#9-multi-layer-caching)
10. [Session Management](#10-session-management)
11. [Cache Reliability Patterns](#11-cache-reliability-patterns)
12. [Monitoring and Observability](#12-monitoring-and-observability)

---

## 1. Caching Fundamentals

### When to Cache

Cache when:
- **Read-heavy workloads**: Read:write ratio > 10:1
- **Expensive computations**: Complex SQL queries, aggregations, ML inference results
- **Repeated identical requests**: Product pages, user profiles, configuration
- **Latency-sensitive paths**: API responses, session lookups, feature flags

Don't cache when:
- Data changes frequently and staleness is unacceptable (financial balances)
- Each request is unique (personalized content with no overlap)
- The source is already fast enough (simple primary key lookups on a well-indexed table)
- The cache would be larger than the source data

### Cache Hit Rate — The Only Metric That Matters

```
Hit Rate = Cache Hits / (Cache Hits + Cache Misses)

Target hit rates:
  > 95%  — Excellent (most caches should aim here)
  85-95% — Good (optimize eviction, TTL, and key design)
  < 85%  — Investigate (wrong data cached, TTL too short, cache too small)
```

A cache with a 50% hit rate doubles your infrastructure cost (you pay for both cache AND database) with minimal latency improvement. Either fix the hit rate or remove the cache.

---

## 2. Redis Deep Dive

### Redis Licensing History

Understanding the licensing situation is important for technology decisions:

- **Pre-2024**: Redis was BSD-licensed (fully open-source)
- **March 2024**: Redis Ltd. changed to dual SSPL/RSALv2 license (not OSI-approved open-source)
- **Response**: Linux Foundation forked Redis as **Valkey** (BSD-licensed)
- **AWS, Google Cloud, Oracle**: Adopted Valkey for their managed services
- **Redis Ltd.**: Continues commercial Redis with Redis Stack modules

### Redis 7.x Features

- **Redis Functions**: Server-side scripting replacing Lua scripts (more portable, library-based)
- **ACL v2**: Fine-grained access control (command-level, key-pattern, pub/sub channels)
- **Sharded Pub/Sub**: Pub/Sub messages routed to the shard that owns the channel (scales horizontally)
- **Multi-part AOF**: Append-only file split into base + incremental files (faster restarts)
- **Client-side caching**: Server tracks which keys clients have cached, sends invalidation messages

### Redis Data Structures

| Structure | Use Case | Example |
|-----------|----------|---------|
| **String** | Simple cache, counters, flags | Session data, rate limiting counter, feature flags |
| **Hash** | Object storage (fields) | User profile (`HSET user:123 name "Alice" email "a@b.com"`) |
| **List** | Queues, recent items | Activity feed (LPUSH + LTRIM), task queue |
| **Set** | Unique collections, tagging | Online users, unique visitors, tags |
| **Sorted Set** | Ranked data, leaderboards | Leaderboard, priority queue, time-based feeds |
| **Stream** | Event log, message queue | Event sourcing, lightweight Kafka alternative |
| **HyperLogLog** | Approximate cardinality | Unique visitor count (12KB for billions of items) |
| **Bloom Filter** | Probabilistic membership | "Has this user seen this ad?" (Redis Stack) |
| **JSON** | JSON document storage | Full JSON with JSONPath queries (Redis Stack) |
| **Search** | Full-text + vector search | Product search, semantic search (Redis Stack) |

### Redis Architecture Patterns

**Standalone** (simplest):
```
App → Redis (single instance)
Use when: Dev/staging, non-critical cache, <16GB data
Risk: Single point of failure
```

**Sentinel** (HA without sharding):
```
App → Sentinel (monitors) → Redis Primary
                          → Redis Replica 1
                          → Redis Replica 2
Use when: HA needed, data fits on one node
Provides: Automatic failover, read replicas
```

**Cluster** (HA + horizontal scaling):
```
App → Redis Cluster
  Shard 0: Primary + Replica (slots 0-5460)
  Shard 1: Primary + Replica (slots 5461-10922)
  Shard 2: Primary + Replica (slots 10923-16383)
Use when: Data exceeds single node, need write scaling
Provides: Auto-sharding (16384 hash slots), automatic failover
Limitation: Multi-key operations must be on same shard (use hash tags {})
```

### Redis Performance Tuning

```conf
# Memory
maxmemory 8gb
maxmemory-policy allkeys-lfu    # Recommended for caches (evict least frequently used)

# Persistence (for cache, disable or use lightweight config)
save ""                          # Disable RDB snapshots (pure cache)
appendonly no                    # Disable AOF (pure cache)

# Networking
tcp-keepalive 300
timeout 0

# Threading (Redis 6+)
io-threads 4                    # I/O threads for network (not command execution)
io-threads-do-reads yes
```

**Eviction policies:**

| Policy | Description | Best For |
|--------|-------------|----------|
| **allkeys-lfu** | Evict least frequently used across all keys | General cache (recommended default) |
| **allkeys-lru** | Evict least recently used across all keys | When access recency matters more than frequency |
| **volatile-lfu** | Evict LFU among keys with TTL set | Cache + persistent data in same instance |
| **volatile-ttl** | Evict keys with shortest TTL first | When TTL represents priority |
| **noeviction** | Return error when memory full | Data stores (not caches) |

---

## 3. Valkey — The Redis Fork

### What Is Valkey?

Valkey is a Linux Foundation project — a community fork of Redis 7.2.4 (the last BSD-licensed version). Backed by AWS, Google Cloud, Oracle, Ericsson, and Snap.

**Key facts:**
- **Wire-compatible**: Drop-in replacement for Redis (same protocol, same commands)
- **License**: BSD 3-Clause (truly open-source)
- **Managed services**: Amazon ElastiCache (Valkey), Google Cloud Memorystore (Valkey), Azure Cache switching to Valkey
- **Valkey 8.x**: Added features beyond Redis 7.2 — multi-threaded I/O improvements, RDMA support, performance enhancements

### Redis vs Valkey Decision

| Factor | Redis | Valkey |
|--------|-------|--------|
| **License** | SSPL/RSALv2 (not OSI open-source) | BSD 3-Clause (open-source) |
| **Commercial support** | Redis Ltd. | AWS, Google Cloud, Oracle, community |
| **Redis Stack modules** | Yes (RediSearch, RedisJSON, etc.) | Not yet (community building alternatives) |
| **Managed services** | Redis Cloud | ElastiCache, Memorystore, most cloud providers |
| **Recommendation** | If you need Redis Stack modules | Default choice for new projects |

**Migration path**: Since Valkey is wire-compatible, migration is typically:
1. Deploy Valkey alongside Redis
2. Switch application connection string
3. Verify functionality
4. Decommission Redis

---

## 4. Memcached

### When Memcached Still Makes Sense

Memcached is simpler than Redis — which is sometimes exactly what you need:

| Factor | Memcached | Redis/Valkey |
|--------|-----------|-------------|
| **Data structures** | Key-value only (strings) | Rich (lists, sets, hashes, streams, etc.) |
| **Threading** | Multi-threaded (better multi-core utilization) | Single-threaded command execution (I/O threads in v6+) |
| **Memory efficiency** | Slab allocator (predictable, no fragmentation) | jemalloc (can fragment over time) |
| **Persistence** | None | Optional (RDB, AOF) |
| **Replication** | None built-in | Built-in (Sentinel, Cluster) |
| **Best for** | Simple, high-throughput string caching | Complex data, persistence, pub/sub, Lua scripting |

**Choose Memcached when:**
- You only need simple key-value caching (no data structures)
- Multi-threaded performance matters (very high connection count)
- Memory predictability is critical
- You don't need persistence, replication, or Pub/Sub

**In practice**: Redis/Valkey has effectively won. Most teams use Redis even for simple caching because the operational tooling and ecosystem are richer. Memcached remains in legacy deployments and specific high-throughput scenarios.

---

## 5. DragonflyDB

### DragonflyDB Overview

DragonflyDB is a modern, multi-threaded, Redis-compatible in-memory data store written in C++:

- **Multi-threaded architecture**: Uses all CPU cores (unlike Redis's single-threaded model)
- **Redis + Memcached protocol compatible**: Drop-in replacement
- **Memory efficiency**: Claims 25% less memory than Redis through novel memory management
- **Performance**: Claims up to 25x throughput vs Redis on multi-core machines

**When to consider:**
- Very high throughput requirements on a single node
- Want to avoid Redis Cluster complexity
- Comfortable with a younger project (smaller community than Redis/Valkey)

**Caution**: DragonflyDB is impressive but has a smaller community and ecosystem. Valkey (backed by Linux Foundation + major cloud providers) is the safer choice for most production workloads.

---

## 6. Caching Patterns

### Pattern Comparison

| Pattern | Data Flow | Consistency | Complexity | Best For |
|---------|-----------|-------------|-----------|----------|
| **Cache-Aside** | App manages cache + DB | Eventual | Low | General purpose (recommended default) |
| **Read-Through** | Cache loads from DB on miss | Eventual | Medium | ORM-integrated caching |
| **Write-Through** | Write to cache, cache writes to DB | Strong | Medium | When reads dominate, can't tolerate stale |
| **Write-Behind** | Write to cache, async batch to DB | Eventual | High | Write-heavy with batch optimizations |
| **Refresh-Ahead** | Pre-refresh expiring keys | Strong (proactive) | High | Predictable access patterns, no cache misses tolerable |

### Cache-Aside (Recommended Default)

```python
def get_user(user_id):
    # 1. Check cache
    cached = redis.get(f"user:{user_id}")
    if cached:
        return json.loads(cached)

    # 2. Cache miss — read from database
    user = db.query("SELECT * FROM users WHERE id = %s", user_id)

    # 3. Populate cache with TTL
    redis.setex(f"user:{user_id}", 3600, json.dumps(user))

    return user

def update_user(user_id, data):
    # 1. Update database (source of truth)
    db.execute("UPDATE users SET ... WHERE id = %s", user_id)

    # 2. Invalidate cache (don't update — avoids race conditions)
    redis.delete(f"user:{user_id}")
```

**Why invalidate, not update?** If two concurrent writes update the cache, the cache may end up with stale data from the slower write. Deleting the cache key forces a re-read from the database on next access.

### Write-Through

```python
def update_user(user_id, data):
    # 1. Update database
    db.execute("UPDATE users SET ... WHERE id = %s", user_id)

    # 2. Update cache (synchronously, within same transaction boundary)
    user = db.query("SELECT * FROM users WHERE id = %s", user_id)
    redis.setex(f"user:{user_id}", 3600, json.dumps(user))

    return user
```

Use when: Read-after-write consistency is critical and you can tolerate slightly higher write latency.

### Write-Behind (Write-Back)

```python
def update_user(user_id, data):
    # 1. Write only to cache (fast)
    redis.hset(f"user:{user_id}", mapping=data)
    redis.sadd("dirty_users", user_id)

# Background worker (periodically)
def flush_dirty_users():
    dirty = redis.smembers("dirty_users")
    for user_id in dirty:
        data = redis.hgetall(f"user:{user_id}")
        db.execute("UPDATE users SET ... WHERE id = %s", user_id)
        redis.srem("dirty_users", user_id)
```

Use when: Write throughput is critical and eventual persistence is acceptable (gaming leaderboards, analytics counters). **Risk**: Data loss if cache crashes before flush.

---

## 7. Cache Invalidation Strategies

### "There are only two hard things in computer science..."

| Strategy | Mechanism | Freshness | Complexity | Best For |
|----------|-----------|-----------|-----------|----------|
| **TTL-based** | Key expires after N seconds | Bounded staleness | Low | General purpose, simple |
| **Event-driven** | App publishes invalidation events | Near-real-time | Medium | Microservices, distributed |
| **CDC-based** | Database change capture triggers invalidation | Near-real-time | High | Database-driven applications |
| **Tag-based** | Group related keys, invalidate by tag | Exact | Medium | Complex entity relationships |
| **Version-based** | Include version in cache key | Exact | Low | Immutable data with versions |

### TTL Strategy

```python
# Short TTL: Fresh data, lower hit rate (good for rapidly changing data)
redis.setex("stock_price:AAPL", 10, price)  # 10 seconds

# Medium TTL: Balance of freshness and performance (most common)
redis.setex("user:123:profile", 3600, profile)  # 1 hour

# Long TTL: High hit rate, stale-tolerant data
redis.setex("country_list", 86400, countries)  # 24 hours

# Jittered TTL: Prevent thundering herd on mass expiration
import random
base_ttl = 3600
jitter = random.randint(-300, 300)  # ±5 minutes
redis.setex(f"product:{id}", base_ttl + jitter, data)
```

### Event-Driven Invalidation

```python
# On user update, publish invalidation event
def update_user(user_id, data):
    db.execute("UPDATE users SET ... WHERE id = %s", user_id)
    redis.publish("cache:invalidate", json.dumps({
        "entity": "user", "id": user_id, "action": "update"
    }))

# Cache invalidation subscriber
def cache_invalidator():
    pubsub = redis.pubsub()
    pubsub.subscribe("cache:invalidate")
    for message in pubsub.listen():
        event = json.loads(message['data'])
        if event['entity'] == 'user':
            redis.delete(f"user:{event['id']}:profile")
            redis.delete(f"user:{event['id']}:orders")
            redis.delete(f"user:{event['id']}:permissions")
```

### CDC-Based Invalidation

```
PostgreSQL WAL → Debezium → Kafka → Cache Invalidation Consumer → Redis.DELETE

Advantages:
- No application code changes needed
- Catches ALL changes (including direct SQL, batch jobs, migrations)
- Decoupled from application logic

Disadvantages:
- Infrastructure complexity (Kafka, Debezium)
- Slight delay (seconds)
- Overkill for simple applications
```

---

## 8. CDN Caching

### CDN Provider Comparison

| Provider | Edge PoPs | Best For | Key Feature |
|----------|-----------|----------|-------------|
| **CloudFront** | 600+ | AWS-native applications | Lambda@Edge, Origin Shield |
| **Cloudflare** | 330+ | Universal, developer-friendly | Workers (edge compute), R2 (storage) |
| **Fastly** | 90+ | Performance-critical, VCL customization | Instant Purge (<150ms global), VCL |
| **Vercel Edge** | 100+ | Next.js/frontend | Incremental Static Regeneration |
| **Akamai** | 4000+ | Enterprise, highest capacity | Largest network |

### Cache-Control Headers

```
# Immutable assets (fingerprinted filenames: app.a1b2c3.js)
Cache-Control: public, max-age=31536000, immutable

# API responses (cache 60s, revalidate)
Cache-Control: public, max-age=60, stale-while-revalidate=30

# Private user data (browser cache only, not CDN)
Cache-Control: private, max-age=300

# No caching (authentication endpoints, user-specific data)
Cache-Control: no-store

# Stale-while-revalidate (serve stale while refreshing in background)
Cache-Control: public, max-age=60, stale-while-revalidate=600
# Serves cached response for up to 660s, refreshes in background after 60s
```

### Cache Key Design

```
Default cache key: Method + Host + Path + Query String

Problems:
  /api/products?sort=price&page=1  ≠  /api/products?page=1&sort=price
  (different query parameter order = cache miss)

Solutions:
  1. Sort query parameters at the application level
  2. Configure CDN to normalize query parameter order
  3. Use Vary header for user-specific content: Vary: Accept-Language, Accept-Encoding
  4. Use surrogate keys (Fastly) for fine-grained invalidation
```

---

## 9. Multi-Layer Caching

### L1 + L2 + L3 Architecture

```
Request → L1 (In-Process)  → L2 (Distributed)  → L3 (CDN)  → Origin
          ~0.1ms              ~1-5ms               ~10-50ms     ~50-500ms
          Caffeine/lru-cache  Redis/Valkey          CloudFront   Database
          Per-instance         Shared               Global edge  Source of truth
          1-10K items          10K-10M items         Static/semi  All data
```

### L1: In-Process Cache

| Language | Library | Algorithm | Best For |
|----------|---------|-----------|----------|
| **Java** | Caffeine | W-TinyLFU | JVM applications (Spring Boot, etc.) |
| **Node.js** | lru-cache | LRU | Express/Fastify applications |
| **Python** | cachetools | LRU/LFU/TTL | Django/FastAPI applications |
| **Go** | ristretto | TinyLFU | Go services |

```java
// Java: Caffeine (near-optimal hit rate with W-TinyLFU)
Cache<String, User> cache = Caffeine.newBuilder()
    .maximumSize(10_000)
    .expireAfterWrite(Duration.ofMinutes(5))
    .recordStats()  // Enable monitoring
    .build();
```

### L1 + L2 Consistency Challenge

When using L1 (in-process) + L2 (Redis), L1 caches on different application instances can go stale:

```
Solutions:
1. Short L1 TTL (30-60s): Accept brief staleness, simple
2. Redis Pub/Sub: Publish invalidation to all instances
3. Redis client-side caching: Server-assisted tracking (Redis 6+)
4. Eventually consistent: L1 serves stale, L2 is source of cache truth
```

---

## 10. Session Management

### Session Storage Options

| Option | Latency | Scalability | Persistence | Complexity |
|--------|---------|-------------|-------------|-----------|
| **Redis/Valkey** | Sub-ms | Horizontal (Cluster) | Optional | Low |
| **Database** | ~ms | Vertical + replicas | Yes | Low |
| **JWT (stateless)** | None (no lookup) | Infinite (no server state) | N/A | Medium (rotation, revocation) |
| **Cookie (encrypted)** | None (no lookup) | Infinite | N/A | Low (size limited) |

### Redis Session Pattern

```python
# Store session in Redis Hash
def create_session(user_id, metadata):
    session_id = secrets.token_urlsafe(32)
    redis.hset(f"session:{session_id}", mapping={
        "user_id": user_id,
        "created_at": datetime.now().isoformat(),
        "ip": metadata["ip"],
        "user_agent": metadata["user_agent"]
    })
    redis.expire(f"session:{session_id}", 86400)  # 24 hours
    return session_id

# Slide expiration on activity
def touch_session(session_id):
    redis.expire(f"session:{session_id}", 86400)  # Reset TTL

# Invalidate on logout
def destroy_session(session_id):
    redis.delete(f"session:{session_id}")

# Invalidate ALL sessions for a user (e.g., password change)
# Requires a secondary index: user:<user_id>:sessions → Set of session_ids
```

### JWT vs Server-Side Sessions

| Factor | JWT | Server-Side (Redis) |
|--------|-----|---------------------|
| **Stateless** | Yes (no DB lookup) | No (requires Redis lookup) |
| **Revocation** | Hard (need blocklist) | Easy (delete from Redis) |
| **Size** | Can grow large (payload) | Minimal (just session ID in cookie) |
| **Token theft** | Can't be invalidated until expiry | Can be immediately revoked |
| **Scaling** | No shared state needed | Need shared Redis |
| **Recommendation** | API-to-API auth, short-lived tokens | User-facing web sessions |

---

## 11. Cache Reliability Patterns

### Cache Stampede Prevention

**Problem**: Cache key expires → hundreds of concurrent requests hit the database simultaneously.

**Solution 1: Locking (mutex)**
```python
def get_with_lock(key):
    value = redis.get(key)
    if value:
        return value

    lock_key = f"lock:{key}"
    if redis.set(lock_key, "1", nx=True, ex=10):  # Acquire lock
        try:
            value = db.query(...)  # Fetch from DB
            redis.setex(key, 3600, value)
            return value
        finally:
            redis.delete(lock_key)
    else:
        time.sleep(0.1)  # Wait and retry
        return get_with_lock(key)
```

**Solution 2: Probabilistic Early Expiration (XFetch)**
```python
# Refresh cache before it actually expires
# Each reader has a small probability of refreshing based on remaining TTL
import random, math

def xfetch(key, ttl=3600, beta=1.0):
    value, expiry = redis.get_with_ttl(key)
    remaining_ttl = expiry - time.time()

    # Probabilistic early refresh: higher probability as TTL approaches 0
    if remaining_ttl < 0 or remaining_ttl < beta * math.log(random.random()) * -1:
        value = db.query(...)
        redis.setex(key, ttl, value)

    return value
```

**Solution 3: Stale-While-Revalidate**
```python
# Serve stale data while refreshing in background
def get_with_stale(key):
    value = redis.get(key)
    ttl = redis.ttl(key)

    if ttl < 60:  # Within "stale window"
        # Trigger async refresh
        background_refresh.delay(key)

    return value  # Return potentially stale data
```

### Thundering Herd on Cold Start

When cache is empty (deploy, cache flush, new instance):

```
Solutions:
1. Cache warming: Pre-populate cache before routing traffic
2. Gradual ramp-up: Route increasing percentage of traffic
3. Request coalescing: Single-flight pattern (one fetch per key, share result)
4. Circuit breaker: If DB is overloaded, serve degraded response
```

---

## 12. Monitoring and Observability

### Key Metrics

| Metric | Target | Alert When |
|--------|--------|------------|
| **Hit rate** | > 95% | < 85% sustained |
| **Latency (p99)** | < 2ms | > 10ms |
| **Memory usage** | < 80% maxmemory | > 90% |
| **Eviction rate** | Low | Sustained high evictions |
| **Connected clients** | Stable | Spike (connection leak) |
| **Keys expiring** | Steady | Sudden drop (TTL misconfiguration) |

### Redis Monitoring Commands

```bash
# Real-time stats
redis-cli INFO stats
redis-cli INFO memory
redis-cli INFO clients

# Slow query log
redis-cli SLOWLOG GET 10

# Memory analysis
redis-cli MEMORY DOCTOR
redis-cli MEMORY USAGE key_name

# Big key detection (careful — can be slow on large DBs)
redis-cli --bigkeys

# Monitor commands in real-time (dev only — impacts performance)
redis-cli MONITOR
```

---

## Decision Framework Summary

| Decision | Default | Switch When |
|----------|---------|-------------|
| **Cache engine** | Valkey (new projects) | Redis (need Stack modules), DragonflyDB (extreme throughput) |
| **Caching pattern** | Cache-aside | Write-through (read-after-write), Write-behind (write-heavy) |
| **Invalidation** | TTL with jitter | Event-driven (microservices), CDC (database-driven) |
| **Eviction policy** | allkeys-lfu | allkeys-lru (recency matters), volatile-ttl (mixed cache+data) |
| **Architecture** | Standalone (dev) → Sentinel (HA) → Cluster (scale) | Based on data size and availability needs |
| **CDN** | Cloudflare (general) | CloudFront (AWS), Fastly (instant purge), Vercel (Next.js) |
| **Sessions** | Redis + server-side sessions | JWT (API auth, stateless microservices) |
| **L1 cache** | Caffeine (Java), lru-cache (Node.js) | When Redis latency (~1ms) isn't fast enough |
| **Stampede prevention** | TTL jitter + locking | XFetch (probabilistic), stale-while-revalidate (availability > freshness) |
