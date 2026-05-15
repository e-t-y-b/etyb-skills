# Reddit Architecture Deep Dive

## Table of Contents
1. [Architecture Evolution](#1-architecture-evolution)
2. [Data Storage](#2-data-storage)
3. [Caching](#3-caching)
4. [Ranking Algorithms](#4-ranking-algorithms)
5. [Real-Time Features](#5-real-time-features)
6. [Infrastructure](#6-infrastructure)
7. [Scale Numbers](#7-scale-numbers)
8. [Media Handling](#8-media-handling)
9. [Search](#9-search)
10. [Anti-Spam and Moderation](#10-anti-spam-and-moderation)
11. [GraphQL Adoption](#11-graphql-adoption)

---

## 1. Architecture Evolution

### Original Stack (2005-2008)
- Originally written in Common Lisp, rewritten in Python within months
- Python monolith using **Pylons** web framework (later Pyramid) with **Mako** templates
- Open-source codebase (`reddit/reddit` on GitHub, archived 2017) — single large Python app called **r2**

### Decomposition (~2016-2022)
- Extracted services in Go, Python, and Node.js
- Internal platform framework: **Baseplate** — Python/Thrift-based with standardized observability, context propagation, service discovery
- New services predominantly in **Go** for performance-critical paths (listings/feed, media processing) and **Python** with Baseplate for others
- **Node.js** for SSR of new React-based frontend (2018 redesign)
- **Thrift** for inter-service RPC (Apache Thrift)
- **Envoy** proxy for service mesh / load balancing
- The monolith (r2) continued running for old.reddit.com well into 2023+

### Frontend Evolution
- **old.reddit.com**: Server-rendered Mako templates from Python monolith
- **new.reddit.com** (2018): React frontend with Node.js SSR, consuming GraphQL API
- **"Shreddit"** (2023-2024): Web-components-based rewrite using **Lit** (Google), replacing React SSR for better performance
- Native mobile: iOS (Swift), Android (Kotlin)

---

## 2. Data Storage

### PostgreSQL (Primary)
- Primary relational database since early days
- **"Thing/Data" model** — quasi-schemaless approach on top of Postgres:
  - `thing` table: metadata (thing_id, ups, downs, type_id, created_utc, deleted, spam)
  - `thing_data` table: key-value attribute pairs (title, body, url, author, etc.)
  - Each entity type (link, comment, account, subreddit, message) has its own pair of tables
- Writes sharded across multiple PostgreSQL masters by thing type and ID ranges
- Advantage: schema evolution without migrations (new fields = new keys)
- Disadvantage: no relational integrity, no efficient SQL on attributes, heavy cache dependence

### Cassandra
- Adopted for **listings** (sorted sets of thing IDs):
  - "Hot posts in r/programming"
  - "New comments on post X"
  - Previously in Postgres, moved for better write throughput and horizontal scaling
- Also used for **vote storage**: `(user_id, thing_id) -> (direction, timestamp)`
  - Tens of millions of votes per day — one of the most write-heavy workloads

### Vote System Internals
When a vote is cast:
1. Write to Cassandra
2. Update score on the thing in Postgres
3. Invalidate relevant caches
4. Enqueue job to update affected listings/rankings

Votes are idempotent — re-voting updates existing record. Unvoting deletes and adjusts score.

### Comment Trees
- Comments stored as individual "things" in Postgres with `parent_id` references forming a tree
- **CommentForest** service manages tree construction, sorting (best/top/new/controversial/old/Q&A), and pagination
- "More comments" objects represent unexpanded subtrees when tree exceeds display limits (typically 200 top-level with depth limits)
- Comment tree structure materialized as sorted flat list with depth indicators for efficient retrieval

### Other Data Stores
- **Amazon S3**: Media blob storage (images, videos, thumbnails)
- **Amazon DynamoDB**: Some newer services
- **ZooKeeper**: Distributed coordination (pre-Kubernetes era)

---

## 3. Caching

### Memcached
- One of the largest Memcached deployments — hundreds of instances
- **Thing cache**: Serialized Thing objects keyed by thing_id. Nearly every page render hits this
- **Rendered page/fragment caching**: HTML fragments (comment trees, listing pages)
- **Permacache**: Special Memcached pool for "never-evict" data — essentially a fast KV store in front of Postgres for very hot data, with extremely large memory allocations

### Redis
- Real-time features: live comment updates, notifications, chat
- Rate limiting: per-user/IP request counts with TTL-based keys
- Queues and pub/sub
- **Amazon ElastiCache** for managed Redis

### Cache Patterns
- **Write-through caching**: On writes, update both database and cache
- **Dogpile locking** (via pylibmc): On cache expiry, one process regenerates while others serve stale value — prevents stampede
- **Precomputed listings**: Hot/rising/top listings for popular subreddits computed by background workers and cached, not on-demand
- Targeted cache invalidation on state changes (gilding, mod actions)

---

## 4. Ranking Algorithms

### Hot Ranking (Posts)

Reddit's hot ranking formula (from open-source code):

```
hot(ups, downs, date):
    s = score = ups - downs
    order = log10(max(abs(s), 1))
    sign = 1 if s > 0, -1 if s < 0, 0 if s == 0
    seconds = epoch_seconds(date) - 1134028003
    return round(sign * order + seconds / 45000, 7)
```

Key insight: **Time dominates**. A post needs ~10x the votes to overcome a 12.5-hour age difference. The epoch constant `1134028003` is December 8, 2005.

### Best Ranking (Comments)

Wilson score confidence interval (lower bound):

```
confidence(ups, downs):
    n = ups + downs
    if n == 0: return 0
    z = 1.96  # 95% confidence
    p = ups / n
    left = p + z*z/(2*n)
    right = z * sqrt(p*(1-p)/n + z*z/(4*n*n))
    under = 1 + z*z/n
    return (left - right) / under
```

Accounts for small sample sizes — a comment with 1 up / 0 down does NOT outrank 100 up / 10 down.

### Other Rankings
- **Top**: Simple `score = ups - downs`, sorted descending, filterable by time window
- **Controversial**: Emphasizes items with many total votes but near-even split
- **Rising**: Based on recent velocity of upvotes relative to age
- **New**: Pure reverse chronological

### Subreddit Feed Generation
- Listings (hot, new, rising, top, controversial) are **precomputed** by background workers
- Front page (logged-in): merges listings from subscribed subreddits using **weighted sampling** to ensure diversity
- r/all and r/popular: additional filtering (NSFW removal, subreddit opt-outs)

---

## 5. Real-Time Features

### WebSockets
- Live comments: pub/sub model. New comment → publish to channel identified by post ID → subscribers receive update
- **Reddit Chat** (launched ~2018): separate WebSocket-based service for real-time messaging

### Notifications
- Push: Firebase Cloud Messaging (Android) + Apple Push Notification Service (iOS)
- In-app: polling + WebSocket hybrid
- Notification service aggregates events (replies, mentions, upvote milestones, mod actions)

### r/place
- Massive real-time coordination event (2017, 2022, 2023)
- 2022 r/place: WebSockets pushing pixel updates to millions of concurrent viewers
- Backend: Go services + Redis (canvas state) + Kafka (event streaming) + custom tile-based rendering

---

## 6. Infrastructure

### AWS
- Migrated from self-hosted data centers to **AWS** starting ~2009, fully on AWS by ~2015
- Key services: EC2, S3, CloudFront, ElastiCache (Redis/Memcached), RDS (managed Postgres), SQS, SNS, Route 53

### Kubernetes Migration
- Began ~2017-2019, shared extensively at KubeCon and r/RedditEng
- K8s on EC2 (EKS and self-managed clusters)
- Docker containerization, CI/CD pipelines, service discovery
- Most services on Kubernetes by 2021-2022
- Internal tooling: **Snooboard** (deployment management), **Drone** (CI, later migrated)

### CDN and Media
- **Fastly**: Primary CDN for cached page content and static assets
- **Amazon CloudFront**: Media delivery (i.redd.it images, v.redd.it videos)
- **Imgix**: Image resizing/optimization at one point

### Load Balancing and Observability
- **HAProxy** historically → migrated to **AWS ALB/NLB** + **Envoy** for service-to-service
- Metrics: Graphite + StatsD → migrated to **Prometheus + Grafana**
- Error tracking: **Sentry**
- Distributed tracing: **Zipkin/Jaeger** (integrated with Baseplate)
- Alerting: **PagerDuty**

---

## 7. Scale Numbers

From various Reddit engineering talks and the 2024 IPO S-1 filing:

- **DAU**: ~70-80M (2023), growing to ~100M+ by late 2024
- **MAU**: ~1.7 billion monthly unique visitors; ~430M logged-in MAU
- **Requests/second**: Peak hundreds of thousands to the application layer (~100K-400K req/s at API layer)
- **Posts/day**: Hundreds of thousands
- **Comments/day**: Millions (~2-3M historically, higher now)
- **Votes/day**: Tens of millions
- **Page views**: Billions per month
- **Active subreddits**: ~100,000+ (millions total created)
- **Memcached**: Tens of terabytes across hundreds of instances
- **Media**: i.redd.it serves billions of image requests per day
- **Cumulative content**: 16+ billion posts and comments (S-1 filing)
- **2023 Revenue**: $804 million

---

## 8. Media Handling

### Image Hosting (i.redd.it)
- Launched 2016, replaced dependence on Imgur
- Upload → S3 → processing (resize, thumbnail) → CloudFront CDN
- Multiple thumbnail sizes generated at upload time (default, mobile, retina)

### Video Hosting (v.redd.it)
- Launched 2017
- **FFmpeg**-based transcoding pipeline for multiple resolutions/bitrates
- **HLS** adaptive bitrate streaming + DASH support
- Async processing: upload triggers transcoding job, post updated on completion

### Media Pipeline
1. Upload → ingest service (validate file type/size)
2. Store original in S3
3. Message to queue (SQS or Kafka) triggers processing
4. Workers transcode video / resize images
5. Processed assets → S3 with predictable key patterns
6. CDN URLs associated with post

### Reddit Galleries (~2020)
- Multiple images per post
- Each image processed independently, stored as separate S3 objects linked via metadata

---

## 9. Search

### Historical Issues
- Reddit's search was notoriously poor for years
- Tried: Solr (original), CloudSearch (Amazon, ~2014), Elasticsearch

### Current Approach (~2022+)
- Significant investment in search improvement
- Modern search infrastructure (likely Elasticsearch-based)
- Typeahead/autocomplete for subreddit and user search
- Search within communities feature
- Index covers: posts, comments, communities, users
- Google partnership (2024): Google indexing Reddit content more prominently

### Search Architecture
- Indexing pipeline consumes events from post/comment creation
- Documents enriched with community metadata, author data, engagement signals
- Ranking: recency + relevance (TF-IDF/BM25) + community size + engagement metrics

---

## 10. Anti-Spam and Moderation

### AutoModerator
- Originally a third-party bot (by user Deimorz), later integrated as first-party
- YAML-based rule definitions per subreddit
- Matches on: title, body, URL domain, account age, karma, flair, regex patterns
- Actions: remove, approve, report, flair, comment, send modmail

### Spam Filtering
- ML-based spam classifiers at submission time
- Features: account age, karma, posting frequency, URL reputation, text similarity to known spam
- Domain blocklists for known spam sources
- Rate limiting: per-user and per-IP (stricter for new/low-karma accounts)

### Trust & Safety Systems
- Ban evasion detection (ML-based alt account identification)
- Vote manipulation detection (coordinated voting rings)
- Content policy violation detection (harassment, hate speech, doxxing)
- **Crowd Control**: Automatically collapse comments from non-members or negative-karma users
- Reporting → mod queue per subreddit, threshold-based auto-removal

### Rate Limits
- API: 60 requests/minute (OAuth), 100 for moderators
- Posting: new accounts wait ~10 min between posts (reduces with positive karma)
- Login throttling, CAPTCHA for suspicious activity

---

## 11. GraphQL Adoption

### Migration from REST
- Traditional REST API: `api/v1/` endpoints
- GraphQL adoption starting ~2018-2019 with new Reddit redesign
- GraphQL gateway serves new web frontend and mobile apps

### Architecture
- **GraphQL gateway** between clients and backend microservices
- Handles: query parsing, validation, authorization, fan-out to downstream services (Thrift/gRPC)
- **Federated schema**: each team owns their portion of the schema
- **DataLoader pattern** to avoid N+1 problems
- **Query batching** for efficiency

### Benefits
- Reduced over-fetching (mobile clients fetch exactly what they need)
- Single request for complex views (post + comments + author + community + votes in one query)
- Strong typing and schema-as-documentation
- Easier evolution (deprecate fields without breaking clients)

### Technology
- Gateway likely in Go or Node.js
- Code generation from GraphQL schema for typed clients
- Old REST API continues for third-party apps and old.reddit.com

---

## Additional Technical Details

### Message Queuing
- **RabbitMQ** historically for job queues
- Migration to **Apache Kafka** for high-throughput event streaming
- **Amazon SQS** for some async jobs

### Analytics Pipeline
- Kafka → S3 data lake → Spark/Presto/Trino
- Schema-validated event pipeline
- Looker + internal dashboards

### Feature Flags / Experimentation
- Internal A/B testing platform
- Percentage-based rollouts, user-segment targeting, kill switches
- Critical during new Reddit rollout and shreddit migration

### Authentication
- OAuth 2.0 for API access
- Session-based for web
- JWT tokens internally between services for identity propagation
