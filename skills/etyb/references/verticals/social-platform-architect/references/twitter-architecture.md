# X/Twitter Architecture Deep Dive

## Table of Contents
1. [Timeline / Feed Architecture](#1-timeline--feed-architecture)
2. [Data Storage](#2-data-storage)
3. [Real-Time Infrastructure](#3-real-time-infrastructure)
4. [Caching Strategy](#4-caching-strategy)
5. [Search and Indexing](#5-search-and-indexing)
6. [Media Handling](#6-media-handling)
7. [Scale Numbers](#7-scale-numbers)
8. [Post-Acquisition Changes](#8-post-acquisition-changes)
9. [Event Streaming and Messaging](#9-event-streaming-and-messaging)
10. [Multi-Region Deployment](#10-multi-region-deployment)
11. [Key Open-Source Projects](#11-key-open-source-projects)

---

## 1. Timeline / Feed Architecture

### Hybrid Fan-Out Model

Twitter's most important architectural decision is the **hybrid fan-out** approach.

**Fan-out on Write (for regular users, <~3,000 followers):**
- When a user tweets, the tweet ID is written into every follower's home timeline cache (Redis)
- Each user's home timeline is a pre-computed Redis list capped at ~800 entries
- Reads are extremely fast — the timeline is pre-materialized

**Fan-out on Read (for "heavy hitter" accounts):**
- Accounts with very high follower counts are NOT fanned out at write time
- When a follower requests their timeline, tweets from these accounts are queried in real-time and merged
- Solves the "Lady Gaga problem" — fanning out to 80M+ followers on every tweet would be prohibitively expensive

**The Timeline Merge Pipeline:**
- **Timeline Service**: Orchestrates timeline construction, fetches from timeline cache
- **Timeline Mixer**: Merges candidates from multiple sources (home timeline cache, high-follower tweets, ads, recommendations)
- **Timeline Ranker**: ML-based re-ordering of tweets
- **Timeline Scorer**: Scores individual tweets for relevance

### "For You" Recommendation Pipeline (Open-Sourced March 2023)

Processes ~1.5 billion candidate tweets down to ~1,500 shown per session. Three stages:

**Stage 1 — Candidate Sourcing (~50% in-network, ~50% out-of-network):**

*In-Network:*
- **Real Graph**: Predicts engagement probability between two users. ~500 features. Ranks tweets from followed accounts.

*Out-of-Network:*
- **Social Graph Traversal**: "What did people I follow engage with?"
- **SimClusters**: ~145,000 communities discovered via matrix factorization on the follow graph. Users and tweets get community embedding vectors. Recommendations based on community overlap.
- **TwHIN (Twitter Heterogeneous Information Network)**: Knowledge graph embeddings on user-tweet interactions for similarity matching.

**Stage 2 — Heavy Ranker:**
- ~48M parameter neural network (MaskNet-based architecture)
- Predicts multiple engagement types simultaneously: like, retweet, reply, click, profile click, dwell time (>2 min), video watch, negative feedback
- ~10 prediction heads combined with weighted sum
- Features: user features, tweet features, engagement history, social graph signals, real-time engagement
- Trained on TPUs, served by **Navi** (Rust-based ML inference service)

**Stage 3 — Post-Ranking Heuristics:**
- Author diversity: max 2-3 tweets from same author consecutively
- Content balance: mix of tweets, retweets, quote tweets, media tweets
- Feedback dampening: suppress content similar to "Not interested" taps
- Visibility filtering: NSFW, blocked/muted accounts
- Ads injection at specific positions
- Target ~50/50 split between in-network and out-of-network

**Serving Infrastructure:**
- **Home Mixer**: Scala-based orchestrator on the Product Mixer framework
- **CrMixer (Candidate Retrieval Mixer)**: Out-of-network candidate sourcing
- **Navi**: High-performance Rust-based ML inference (TensorFlow Serving alternative)
- Massive feature store for real-time feature hydration

---

## 2. Data Storage

### Manhattan (Primary KV Store)
- In-house distributed key-value store (developed ~2014)
- Multi-tenant, real-time, strongly consistent within a DC, eventually consistent cross-DC
- Storage backends: SSD (RocksDB) and in-memory
- Used for: timelines, tweet metadata, user profiles, social graph, DMs, engagement counters
- Handles **tens of millions of QPS**
- Data model: `(key, column_key) -> value` with TTL support
- Replication: synchronous within DC, async cross-DC (log-based)
- Partitioning: consistent hashing

### MySQL (Gizzard)
- Tweets historically stored in MySQL, sharded via **Gizzard** (Scala sharding middleware)
- Gizzard provided: sharding, replication, job scheduling on top of MySQL
- Much MySQL-backed storage later migrated to Manhattan

### Snowflake ID Generation
- Twitter's globally unique, time-sortable 64-bit ID generator
- Format: timestamp (41 bits) + machine ID (10 bits) + sequence (12 bits)
- Generates ~4,096 IDs per millisecond per machine
- Open-sourced, now an industry standard pattern

### FlockDB (Social Graph)
- Distributed graph database for the social graph (who follows whom)
- Optimized for large adjacency lists and high-rate follow/unfollow
- Backed by MySQL with Gizzard sharding
- Edges stored as `(source_id, graph_type, destination_id)` with state
- Later superseded by Manhattan-backed graph services and **GraphJet** for recommendations

### Redis
- Thousands of Redis instances, tens of TB in memory
- Used for: timeline caching (pre-computed home timeline as Redis lists)
- Managed via **Twemproxy (nutcracker)**: proxy for Redis/Memcached with automatic sharding
- Custom fork work: **Pelikan** (see caching section)

### Memcached
- General-purpose caching: user objects, tweet objects, API responses
- Large fleet, gradually replaced by **Pelikan**

### Blobstore
- Internal blob storage for media (images, videos, profile pictures)
- Distributed, replicated, optimized for large binary objects

### HDFS / Hadoop
- Tens of thousands of nodes for offline analytics and ML training
- **Scalding** (Scala DSL on MapReduce) for batch processing
- Post-acquisition: migration to Google BigQuery for data warehousing

---

## 3. Real-Time Infrastructure

### Tweet Delivery Pipeline
1. Tweet written to tweet store (Manhattan/MySQL)
2. **Fanout Service** pushes tweet ID to followers' timeline caches (Redis)
3. **EventBus** (Kafka-based) publishes tweet event to: search indexing, notifications, analytics, trending topics
4. Push notifications triggered for users with notifications enabled for the author

### Streaming APIs
- Used long-lived HTTP connections (chunked transfer encoding), not WebSockets
- Firehose: full stream of all public tweets (sold to data partners)
- Filter Stream: real-time filtered stream matching keywords/users
- Internal pub/sub built on Kafka

### Push Notifications
- Routed through Apple APNs and Google FCM
- Notification relevance scoring: ML model predicts whether a notification is worth sending
- Rate-limited and batched to avoid notification fatigue

### Live Updates
- Web client historically used long polling and periodic refresh
- Live engagement count updates use SSE and polling hybrid

---

## 4. Caching Strategy

### Multi-Layer Architecture
Read-to-write ratio: ~100:1 to 1,000:1 for popular tweets.

**Layer 1 — CDN Edge:** Static assets, media, profile images (historically Akamai, post-acquisition Cloudflare/Fastly)
**Layer 2 — Application Cache (Memcached/Pelikan):** Tweet objects, user objects, auth tokens. >99% hit rate for popular content. Cache-aside pattern.
**Layer 3 — Timeline Cache (Redis):** Pre-computed home timelines as sorted sets/lists of tweet IDs (~800 per user). On request: fetch IDs from Redis, hydrate with full tweet objects from Layer 2.
**Layer 4 — Row Cache (Manhattan internal):** RocksDB block cache, OS page cache.

### Cache Invalidation
- **Write-through** for timeline cache (fanout writes to Redis at tweet time)
- **TTL-based expiry** for tweet/user object caches
- **Event-driven invalidation**: Tweet deletion/user suspension → Kafka event → consumers invalidate cache
- **Lease-based invalidation** to prevent thundering herd

### Pelikan (Custom Cache Engine)
- Written in C, designed to replace both Memcached and Redis
- Deterministic memory allocation (no fragmentation), predictable sub-ms latency
- Supports Memcached ASCII and Redis RESP protocols
- Open-sourced

### Twemproxy (Nutcracker)
- Lightweight proxy for Memcached/Redis
- Automatic sharding, connection pooling, request pipelining
- Open-sourced, widely adopted

---

## 5. Search and Indexing

### Earlybird (Real-Time Search Engine)
- Built on heavily modified Apache Lucene
- Tweets searchable within **seconds** of posting (typically <10s)

**Three-tier architecture:**
- **Earlybird Realtime**: Last ~7 days, in-memory index (RAM-based postings lists)
- **Earlybird Protected**: Protected/private tweets in separate cluster for access control
- **Earlybird Archive (Full Archive)**: Entire tweet history (~500B+ tweets), SSD-based index

Sharded by tweet ID ranges (Snowflake's time-sortable property enables efficient range sharding).

**Blender**: Search aggregation service that fans out queries to Earlybird shards, merges results, applies ranking.

### Search Ranking
- Text match (BM25-like)
- Engagement signals (likes, retweets, replies)
- Author reputation (follower quality, not just count)
- Recency (strong decay function)
- Social signals (tweets from followed/interacted accounts ranked higher)
- Embedding-based semantic search (dense retrieval models added later)

### Ingestion Pipeline
Tweets → Kafka → **Earlybird Ingester** (tokenization, language detection, entity extraction, feature computation) → Earlybird index

---

## 6. Media Handling

### Images
- Upload → Media Upload Service → **Blobstore**
- Resized into multiple variants (thumbnail, small, medium, large, original)
- Formats: JPEG, PNG, GIF, WebP
- Max size: 5MB photos, 15MB GIFs

### Video
- Chunked upload for large files
- **Transcoding pipeline**: Multiple resolutions/bitrates (240p through 1080p+)
- Codec: H.264 (historically), H.265/HEVC and VP9 for newer content
- Delivery: HLS (HTTP Live Streaming) with adaptive bitrate
- Max length: historically 2:20, extended to 4+ hours for premium users

### CDN Delivery
- **pbs.twimg.com** (images), **video.twimg.com** (video)
- Providers: historically Akamai, plus Fastly and Cloudflare
- Aggressive edge caching with long TTLs for media

---

## 7. Scale Numbers

### Traffic
- **~500 million tweets/day** (~6,000 TPS average, peaks 12,000-15,000+ TPS)
- Historical peak: ~143,000 TPS (Japan, August 2013)
- **~200 billion tweet views per day**
- **~400,000+ Redis writes/second** for home timeline fanout
- **~12 million RPS** to backend (aggregated across all services)

### Users
- ~450 million MAU (pre-acquisition estimate)
- ~240 million DAU
- Average user follows ~400 accounts
- Power-law follower distribution

### Infrastructure (Pre-Acquisition)
- ~300,000+ servers across multiple data centers
- ~800+ microservices
- Data centers: Sacramento, Portland, Atlanta (US)
- 10TB+ data in Redis (timeline cache alone)
- Hundreds of petabytes in HDFS

---

## 8. Post-Acquisition Changes (Late 2022-2024)

### Infrastructure Reductions
- Engineering headcount: ~7,500 → ~1,500 (~80% reduction)
- Entire SRE, infrastructure, data engineering teams significantly reduced
- Loss of institutional knowledge about custom systems (Manhattan, Pelikan, Earlybird)

### Cloud Migration
- Historically ran almost entirely on **bare-metal in owned data centers**
- Migrated to **Google Cloud Platform (GCP)**
- Sacramento data center decommissioned (Dec 2022)
- Estimated GCP spend: $100M+ annually
- Some workloads on **Oracle Cloud**

### Cost-Cutting
- Microservice consolidation (800+ reduced significantly)
- CDN renegotiation, reduced media quality
- Reduced redundancy (fewer replicas)
- API monetization: Free access eliminated → Basic ($100/mo), Pro ($5,000/mo), Enterprise ($42,000+/mo)

---

## 9. Event Streaming and Messaging

### Apache Kafka (EventBus)
- One of the largest Kafka deployments globally
- **Hundreds of billions of events per day**
- Use cases: tweet publish events, user actions, ad events, ML feature logging, log aggregation
- Custom client libraries and management tools

### Messaging Patterns
- **Event sourcing**: Core tweet/action events as immutable events
- **CQRS**: Write path publishes events; read path constructs materialized views (timeline cache = materialized view)
- **Pub/sub**: Multiple independent consumers per topic (search, analytics, fanout)

### Heron (Stream Processing)
- Replaced Apache Storm at Twitter
- Better resource isolation, back-pressure handling
- Used for: trending topics, real-time engagement aggregation, spam detection
- Open-sourced

### Finagle (RPC Framework)
- Scala/JVM-based RPC framework for all inter-service communication
- Provides: service discovery, load balancing, circuit breaking, retries, timeouts
- Integrated with ZooKeeper for service registration
- Protocols: Thrift (primary), HTTP, gRPC
- Companion: **Finatra** (HTTP framework), **Scrooge** (Thrift codegen)

---

## 10. Multi-Region Deployment

### Pre-Cloud Topology
- Primary DCs: Sacramento (CA), Portland (OR), Atlanta (GA)
- Active-active for read traffic; writes typically routed to primary then replicated
- User routing via anycast DNS and global load balancer

### Data Replication
- **Manhattan**: Async cross-DC replication with last-writer-wins conflict resolution
- **MySQL/Gizzard**: Async replication across DCs
- **Redis/Cache**: NOT replicated across DCs — each DC maintains its own timeline cache, populated independently by local fanout service
- **Kafka**: Cross-DC replication via MirrorMaker

### Edge Architecture
- **Twitter Front End (TFE)**: Edge proxy handling TLS, auth, rate limiting, routing to backend
- PoPs globally for TLS termination
- DDoS protection at edge layer

### Post-Cloud
- GCP multi-region with US, Europe, Asia-Pacific regions
- GKE, BigQuery, Cloud Storage, Pub/Sub

---

## 11. Key Open-Source Projects from Twitter

| Project | Purpose |
|---------|---------|
| **Snowflake** | Distributed unique ID generation |
| **Finagle** | RPC framework |
| **Finatra** | HTTP/Thrift server framework |
| **Scrooge** | Thrift code generator |
| **Twemproxy** | Redis/Memcached proxy |
| **Pelikan** | Unified cache engine |
| **Heron** | Stream processing |
| **Scalding** | Scala MapReduce DSL |
| **FlockDB** | Graph database |
| **SimClusters** | Community detection for recommendations |
| **the-algorithm** | Full recommendation pipeline |

## Key Architectural Principles

1. **Optimize for reads** — 100:1+ read-to-write ratio drives every decision
2. **Pre-compute feeds** — Materialize timelines at write time, not read time
3. **Hybrid fan-out** — Push for normal users, pull for celebrities
4. **Cache everything** — Multiple layers, >99% hit rate target
5. **Event-driven backbone** — Kafka enables loose coupling
6. **Custom infrastructure at scale** — Manhattan, Earlybird, Pelikan built because off-the-shelf didn't meet requirements
7. **JVM-heavy stack** — Scala/Java with Finagle as universal RPC
