# System Design Patterns for Social Platforms

## Table of Contents
1. [Feed Generation Patterns](#1-feed-generation-patterns)
2. [Low-Latency Serving](#2-low-latency-serving)
3. [Real-Time Infrastructure](#3-real-time-infrastructure)
4. [Data Consistency Patterns](#4-data-consistency-patterns)
5. [API Design](#5-api-design)
6. [Observability and Reliability](#6-observability-and-reliability)
7. [Content Moderation at Scale](#7-content-moderation-at-scale)
8. [Database Sharding Strategies](#8-database-sharding-strategies)

---

## 1. Feed Generation Patterns

### Fan-Out on Write (Push)

**How it works:**
1. User creates a post
2. System looks up all followers (from social graph store)
3. For each follower, insert the post ID into their pre-computed feed (Redis sorted set/list)
4. When a follower opens their feed, read directly from Redis — no computation needed

**When to use:**
- Most users have moderate follower counts (<10K)
- Low read latency is critical (sub-10ms feed loads)
- Write latency is tolerable (async fanout via queue)
- You can afford the storage (N followers × post ID per post)

**Implementation:**
```
# Write path (async, via Kafka/queue)
on_post_created(post):
    followers = get_followers(post.author_id)
    for follower_id in followers:
        redis.zadd(f"feed:{follower_id}", post.timestamp, post.id)
        redis.zremrangebyrank(f"feed:{follower_id}", 0, -MAX_FEED_SIZE)

# Read path (fast)
get_feed(user_id, offset, limit):
    post_ids = redis.zrevrange(f"feed:{user_id}", offset, offset+limit)
    return hydrate_posts(post_ids)
```

**Tradeoffs:**
- Write amplification: 1 post → N writes (N = follower count)
- Storage: N × 8 bytes per post (just storing IDs). 1M users × 800 posts = ~6 GB
- Fan-out delay: With Kafka, a post reaches all followers within seconds
- Celebrity problem: A post by someone with 10M followers = 10M Redis writes

### Fan-Out on Read (Pull)

**How it works:**
1. User creates a post — stored once in the post store
2. When a reader opens their feed, query all accounts they follow, fetch recent posts, merge, rank, return

**When to use:**
- Users follow many accounts with very uneven posting rates
- Write speed is critical (post must be stored instantly)
- You can tolerate higher read latency (50-200ms)
- Storage is expensive (can't afford pre-computed feeds for all users)

**Implementation:**
```
get_feed(user_id, offset, limit):
    followed_ids = get_following(user_id)
    # Parallel fetch recent posts from each followed account
    candidate_posts = parallel_fetch(
        [get_recent_posts(uid, limit=20) for uid in followed_ids]
    )
    ranked = rank(candidate_posts)
    return ranked[offset:offset+limit]
```

**Tradeoffs:**
- Read latency: Must query many sources and merge. With 400 followees, that's 400 queries (batch/parallel)
- No write amplification
- Always fresh — no stale cache issues
- Harder to rank — need all candidates before ranking

### Hybrid Fan-Out (Twitter's Approach — Recommended at Scale)

**How it works:**
1. Regular users (<threshold followers): fan-out on write
2. "Celebrity" accounts (>threshold): NOT fanned out
3. At read time: merge pre-computed feed (from Redis) with real-time query of celebrity posts

**Implementation:**
```
CELEBRITY_THRESHOLD = 5000  # Tune based on your platform

on_post_created(post):
    if get_follower_count(post.author_id) < CELEBRITY_THRESHOLD:
        # Fan-out on write
        enqueue_fanout(post)
    else:
        # Just store the post, don't fan out
        store_post(post)

get_feed(user_id):
    # Get pre-computed feed
    precomputed = redis.zrevrange(f"feed:{user_id}", 0, MAX_FEED)

    # Get celebrity posts (fan-out on read)
    celebrity_followees = get_celebrity_followees(user_id)
    celebrity_posts = parallel_fetch(
        [get_recent_posts(uid) for uid in celebrity_followees]
    )

    # Merge and rank
    all_candidates = precomputed + celebrity_posts
    return rank(all_candidates)
```

### Activity Streams Pattern

For platforms with diverse activity types (posts, comments, likes, shares, follows):

**Event Model:**
```json
{
    "actor": "user:123",
    "verb": "post",
    "object": "post:456",
    "target": "community:789",
    "timestamp": "2025-01-15T10:30:00Z",
    "metadata": {"has_media": true, "content_type": "image"}
}
```

Store activities in an append-only log (Kafka). Materialize different views (feeds, notifications, analytics) from the same event stream.

---

## 2. Low-Latency Serving

### Edge Computing

**Cloudflare Workers:**
- Run JavaScript/Wasm at 300+ edge locations
- Sub-ms cold starts
- Good for: API response caching, request routing, A/B testing, auth token validation
- Pricing: $0.50/M requests + $12.50/M ms CPU time
- Use with KV (key-value store at edge) or R2 (object storage)

**AWS Lambda@Edge / CloudFront Functions:**
- Lambda@Edge: Run at CloudFront regional edge (13 locations). Up to 30s execution, 50MB package.
- CloudFront Functions: Run at all 400+ edge locations. Sub-ms, 10KB package, 2ms max.
- Good for: header manipulation, URL rewrites, auth, simple caching logic

**Fastly Compute:**
- Wasm-based edge compute
- Sub-ms cold starts, 50ms p99 overhead
- Good for: custom CDN logic, personalized caching

**When to use edge compute for social platforms:**
- Auth token validation (avoid round-trip to origin)
- Serve cached public content (trending posts, public profiles)
- Rate limiting at the edge (before hitting origin)
- Geographic routing decisions
- NOT for: anything requiring database access or complex state

### Multi-Region Database Strategies

**CockroachDB:**
- Distributed SQL, PostgreSQL-compatible
- Automatic sharding and replication
- Geo-partitioning: pin data to specific regions (e.g., EU user data stays in EU)
- Latency: cross-region writes add ~100-200ms (consensus round-trip)
- Cost: Serverless from $0.50/M RU. Dedicated from ~$700/mo

**YugabyteDB:**
- Distributed SQL, PostgreSQL-compatible
- Multi-region with configurable consistency (sync vs async replication)
- xCluster for async replication between regions (lower latency, eventual consistency)
- Cost: Managed from ~$600/mo

**Vitess (MySQL Sharding):**
- MySQL-compatible sharding middleware (used by YouTube, Slack, GitHub)
- Horizontal scaling without changing application code
- Good if you're already on MySQL and need to scale
- Open source, free

**TiDB:**
- MySQL-compatible, distributed HTAP database
- Strong consistency via Raft protocol
- Good for mixed workloads (OLTP + OLAP)

**Recommendation for social platforms:**
- Start with single-region PostgreSQL + read replicas
- If you need multi-region writes: CockroachDB or YugabyteDB
- If you're on MySQL and need sharding: Vitess
- For eventually-consistent data (feeds, counters): use Cassandra/ScyllaDB replicated across regions

### Global Load Balancing

**Anycast DNS:**
- Same IP advertised from multiple locations
- BGP routing directs users to nearest instance
- Used by: Cloudflare, all major CDNs
- Good for: CDN traffic, stateless API requests

**GeoDNS:**
- DNS returns different IPs based on client location
- Services: AWS Route 53 geolocation routing, Cloudflare load balancer
- Good for: routing to region-specific API clusters

**Global Server Load Balancing (GSLB):**
- Health-aware routing across regions
- Failover when a region goes down
- AWS: Route 53 health checks + failover routing
- GCP: Cloud Load Balancing (Anycast by default, cross-region)

### Connection Optimization

- **Connection pooling**: PgBouncer for PostgreSQL (transaction mode), ProxySQL for MySQL
- **HTTP/2 multiplexing**: Single connection, multiple concurrent requests
- **Keep-alive**: Reuse TCP connections (avoid 3-way handshake per request)
- **gRPC**: HTTP/2-based, binary protocol, ~10x faster than REST/JSON for internal services
- **DNS prefetching + TCP preconnect**: Hint browsers to connect early

---

## 3. Real-Time Infrastructure

### WebSocket at Scale

**The challenge:** Millions of concurrent WebSocket connections, each maintaining state.

**Architecture pattern:**
```
Clients → Load Balancer (L4/TCP) → WebSocket Servers → Pub/Sub Backbone → Backend Services
```

**Pub/Sub backbone options:**

| Technology | Connections/Server | Latency | Best For |
|-----------|-------------------|---------|----------|
| Redis Pub/Sub | ~100K | <1ms | Simple, moderate scale |
| NATS | ~1M | <1ms | High throughput, simple pub/sub |
| Kafka | N/A (not real-time pub/sub) | 10-100ms | Event streaming, replay |
| Centrifugo | ~1M | <5ms | Turnkey WebSocket server |

**Scaling WebSocket servers:**
- Each server holds ~50K-100K connections (depends on message rate)
- Use consistent hashing to route users to servers (sticky sessions)
- When a user's followed account posts, publish to the channel; all servers subscribed to that channel push to their connected users
- Heartbeat mechanism to detect dead connections (ping/pong every 30s)

**Centrifugo** — recommended turnkey solution:
- Open-source real-time messaging server
- Handles millions of connections
- Built-in: pub/sub channels, presence, history, connection authentication
- Integrates with Redis, KeyDB, NATS, or Tarantool as broker
- Supports WebSocket, SSE, HTTP streaming, GRPC

### Server-Sent Events vs WebSocket vs Long Polling

| Feature | SSE | WebSocket | Long Polling |
|---------|-----|-----------|-------------|
| Direction | Server → Client | Bidirectional | Server → Client |
| Protocol | HTTP | WS (TCP) | HTTP |
| Reconnection | Automatic | Manual | Manual |
| Binary data | No | Yes | No |
| Proxy-friendly | Yes | Sometimes issues | Yes |
| Scaling complexity | Low | High | Low |
| Best for | Feed updates, notifications | Chat, live collaboration | Simple notifications, MVP |

**Recommendation:**
- Feed updates / notifications: **SSE** (simpler, HTTP-compatible, auto-reconnect)
- Chat / live comments: **WebSocket** (bidirectional needed)
- MVP: **Long polling** (simplest, works everywhere)

---

## 4. Data Consistency Patterns

### CQRS (Command Query Responsibility Segregation)

Essential pattern for social platforms. Separate the write model from the read model.

**Write side:**
- Receives commands (create post, vote, follow)
- Validates and persists to primary database
- Publishes events to Kafka

**Read side:**
- Consumes events from Kafka
- Builds materialized views optimized for queries (feeds, comment trees, user profiles)
- Stores in read-optimized stores (Redis, Elasticsearch, DynamoDB)

**Why it matters for social platforms:**
- Writes and reads have fundamentally different patterns (100:1 ratio)
- Read models can be denormalized, cached, and replicated aggressively
- Write model stays normalized and consistent
- Each read model can be rebuilt from the event log if needed

### Event Sourcing

Store all changes as an immutable sequence of events rather than overwriting state.

**Events for a social platform:**
```
PostCreated { author_id, content, timestamp }
PostLiked { user_id, post_id, timestamp }
PostUnliked { user_id, post_id, timestamp }
CommentAdded { user_id, post_id, content, parent_id, timestamp }
UserFollowed { follower_id, followee_id, timestamp }
```

**Benefits:**
- Complete audit trail
- Can rebuild any materialized view by replaying events
- Enables time-travel debugging
- Natural fit with Kafka (append-only log)

**When NOT to use:**
- When event volume is extreme and you don't need replay (just use CQRS without full event sourcing)
- When GDPR/data deletion requirements make immutable logs complicated

### Eventual Consistency Patterns

Social platforms can tolerate eventual consistency for most data:

| Data | Consistency Requirement | Acceptable Delay |
|------|------------------------|------------------|
| Post content | Strong (author sees their post immediately) | 0 |
| Feed delivery | Eventual | 1-30 seconds |
| Like/vote counts | Eventual | 5-60 seconds |
| Follower counts | Eventual | Minutes |
| Search index | Eventual | 10-60 seconds |
| Notifications | Eventual | 1-10 seconds |

**Read-your-own-writes pattern:** After a user creates a post, ensure THEY see it immediately (read from primary DB or cache-aside), even if other users see it with a delay.

### Conflict Resolution in Multi-Region

- **Last-writer-wins (LWW)**: Simplest. Use timestamps. Works for most social data (posts, profiles).
- **CRDTs (Conflict-free Replicated Data Types)**: For counters (likes, views), sets (followers). Automatically merge without conflicts.
  - G-Counter: grow-only counter (each region maintains its own count, sum for total)
  - PN-Counter: positive-negative counter (for votes)
  - OR-Set: observed-remove set (for follower lists)
- **Application-level merge**: For complex data, define merge rules per entity type.

---

## 5. API Design

### GraphQL vs REST vs gRPC

| Factor | REST | GraphQL | gRPC |
|--------|------|---------|------|
| Client flexibility | Low (fixed endpoints) | High (query exactly what you need) | Low (defined in .proto) |
| Over-fetching | Common | Eliminated | N/A (binary) |
| Caching | Easy (HTTP caching) | Complex (POST requests) | Application-level |
| Real-time | Polling/SSE | Subscriptions | Streaming |
| Mobile efficiency | Moderate | High (minimal data transfer) | Highest (binary, compressed) |
| Learning curve | Low | Medium | Medium-High |
| Best for | Public APIs, simple CRUD | Mobile/web frontends | Internal services |

**Recommendation for social platforms:**
- **Public API**: REST (simplest for third parties, cacheable)
- **Mobile/Web frontend**: GraphQL (reduces over-fetching, single request for complex views)
- **Internal service-to-service**: gRPC (fastest, strongly typed, streaming support)

### Rate Limiting

**Token Bucket** (recommended):
- Each user gets a bucket with N tokens, refills at R tokens/second
- Each request consumes 1 token
- When bucket is empty, requests are rejected (429)
- Simple to implement in Redis: `MULTI / DECR / EXPIRE / EXEC`

**Sliding Window:**
- Track request counts in fixed windows (e.g., 1-minute)
- Smoother than fixed window, prevents burst at window boundary
- Implementation: Redis sorted set with timestamp scores

**Recommended limits for social platforms:**
| Action | Rate Limit |
|--------|-----------|
| Read API (authenticated) | 300/min |
| Read API (unauthenticated) | 60/min |
| Create post | 10/hour |
| Comments | 30/hour |
| Votes | 100/min |
| Follow/unfollow | 30/hour |
| Search | 30/min |
| Media upload | 20/hour |

### API Gateway Patterns

**Kong** (open source, Lua/Nginx):
- Plugin-based: auth, rate limiting, logging, transformations
- Good ecosystem, widely adopted
- Self-hosted or managed (Konnect)

**Envoy** (open source, C++):
- High-performance L4/L7 proxy
- gRPC-native, excellent observability
- Commonly used as sidecar in service mesh (Istio)

**AWS API Gateway:**
- Managed, serverless
- WebSocket support, request validation
- Expensive at scale ($3.50/M requests)

**Recommendation:** Start with Kong or API Gateway for MVP. Migrate to Envoy at scale for better performance and service mesh integration.

---

## 6. Observability and Reliability

### Circuit Breakers

When a downstream service is failing, stop sending requests (avoid cascade failures).

**States:** Closed (normal) → Open (failing, reject immediately) → Half-Open (test with one request)

**Libraries:**
- Go: `sony/gobreaker`, `afex/hystrix-go`
- Java/Scala: Resilience4j, Hystrix (deprecated but widely used)
- Node.js: `opossum`

**Recommended settings for social platforms:**
- Failure threshold: 50% of requests in 10-second window
- Open duration: 30 seconds
- Half-open: allow 3 test requests

### Distributed Tracing

**OpenTelemetry** (industry standard):
- Traces request across all services
- Backends: Jaeger, Zipkin, Tempo (Grafana), AWS X-Ray
- Correlate: trace ID propagated in headers across all services

**What to trace in social platforms:**
- Full feed request path: API → Feed Service → Cache → DB → Ranking → Response
- Post creation: API → Validation → Storage → Kafka → Fanout → Cache
- Search: API → Query Parser → Search Index → Ranking → Response

### Feature Flags

Essential for safe rollouts:
- **LaunchDarkly** (managed, $10/mo+)
- **Unleash** (open source, self-hosted)
- **Flagsmith** (open source, managed option)

**Patterns:**
- Percentage rollout: 1% → 5% → 25% → 50% → 100%
- User segment targeting: internal → beta users → new users → all
- Kill switch: instant disable if metrics degrade

---

## 7. Content Moderation at Scale

### ML-Based Classification Pipeline

```
User Submission → Pre-filter (regex, blocklists) → ML Classifier → Queue → Human Review (if uncertain)
```

**Pre-filter (fast, cheap):**
- Regex patterns for known bad content
- Domain/URL blocklists
- Account age/karma thresholds
- Rate limiting

**ML Classification:**
- Text classification: fine-tuned transformer model for toxicity, spam, hate speech
- Image classification: NSFW detection (e.g., OpenAI moderation API, Google Cloud Vision SafeSearch)
- Combined signals: text + image + metadata features

**Queue-Based Review:**
- High-confidence spam → auto-remove
- High-confidence safe → auto-approve
- Uncertain (0.3-0.7 confidence) → human review queue
- Priority: reported content > automated flags > routine

### Trust and Safety Scoring

Assign a trust score to each account:
- Starts at baseline (e.g., 50)
- Increases with: age, positive engagement, verified email/phone, community participation
- Decreases with: spam reports, content removals, rate limit violations, ban evasion signals
- Low trust = stricter rate limits, more content moderation, limited features

### Progressive Enforcement by Risk Score

```
Score 0.0-0.3: Auto-approve, full distribution
Score 0.3-0.5: Approve but reduce algorithmic amplification
Score 0.5-0.7: Queue for human review, limit distribution
Score 0.7-0.9: Auto-remove, notify user, allow appeal
Score 0.9-1.0: Auto-remove, no notification, flag for legal review
```

### Moderation Queue Prioritization

- **P0**: CSAM, imminent violence (immediate removal, law enforcement notification)
- **P1**: Hate speech, harassment, self-harm (review within hours)
- **P2**: Spam, misinformation (review within 24h)
- **P3**: Copyright claims (review within days)

### Behavioral Signals for Abuse Detection

- Posting velocity analysis (spam detection)
- Network analysis (coordinated inauthentic behavior: clusters of new accounts amplifying same content)
- Device fingerprinting (same device creating multiple accounts)
- IP reputation scoring

---

## 8. Database Sharding Strategies

### Sharding by User ID (Most Common for Social Platforms)

- All data for a user on the same shard
- Enables efficient queries for "my posts", "my feed", "my settings"
- Hot-spot risk: celebrity users overload their shard

**Implementation:**
```
shard_id = hash(user_id) % num_shards
# or for consistent hashing:
shard_id = consistent_hash(user_id, shard_ring)
```

### Sharding by Post ID

- Distributes write load evenly (every post equally likely on any shard)
- "Get all posts by user X" requires scatter-gather across all shards
- Better for post-centric queries (single post view, comments on a post)

### Sharding by Time Range

- Recent data on fast storage, old data on cheaper storage
- Natural for social platforms (most reads are recent content)
- Used by Twitter's Earlybird (sharded by tweet ID, which encodes timestamp via Snowflake)

### Consistent Hashing

Preferred over simple modulo for sharding:
- Adding/removing shards only remaps ~1/N of keys (vs all keys with modulo)
- Virtual nodes for better distribution
- Libraries: `hashring` (Go), `ketama` pattern

### Sharding Anti-Patterns to Avoid

- **Cross-shard joins**: Design your data model to avoid them. Denormalize instead.
- **Sequential IDs as shard key**: All new data goes to one shard. Use random or time-based distributed IDs.
- **Too few shards**: Hard to split later. Start with more shards than you think you need (64-256), mapped to fewer physical nodes.
- **Shard key that changes**: User's country, status, etc. Use immutable keys (user_id, post_id).
