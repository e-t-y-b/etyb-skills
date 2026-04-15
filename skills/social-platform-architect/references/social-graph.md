# Social Graph Architecture

The social graph is the foundational data structure of any social platform — it defines how users relate to each other and drives feed generation, recommendations, privacy controls, and content delivery. Getting the graph architecture right is critical because it underpins nearly every other system in the platform.

## Table of Contents

1. [Social Graph Data Models](#1-social-graph-data-models)
2. [Follow and Friend System Design](#2-follow-and-friend-system-design)
3. [Graph Storage Strategies by Scale](#3-graph-storage-strategies-by-scale)
4. [Social Graph Queries](#4-social-graph-queries)
5. [Friend and Follow Recommendations](#5-friend-and-follow-recommendations)
6. [Blocking, Muting, and Privacy Controls](#6-blocking-muting-and-privacy-controls)
7. [Group and Community Membership](#7-group-and-community-membership)
8. [Graph Partitioning and Sharding](#8-graph-partitioning-and-sharding)
9. [Real-World Graph Systems](#9-real-world-graph-systems)

---

## 1. Social Graph Data Models

### Adjacency List Model (Relational)

The simplest and most common approach — store edges in a relational table.

```sql
-- Unidirectional follow graph (Twitter model)
CREATE TABLE follows (
    follower_id  BIGINT NOT NULL,
    following_id BIGINT NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

-- Indexes for both directions of traversal
CREATE INDEX idx_follows_following ON follows (following_id, follower_id);

-- Denormalized counters (avoid COUNT(*) at scale)
ALTER TABLE users ADD COLUMN follower_count  INT DEFAULT 0;
ALTER TABLE users ADD COLUMN following_count INT DEFAULT 0;
```

**Pros**: Simple, well-understood, ACID transactions, easy to query with SQL.
**Cons**: Graph traversal (friends-of-friends, shortest path) requires multiple JOINs — becomes expensive at scale.
**Best for**: Startup and growth stage (<5M users).

### Edge Table with Metadata

For richer relationship types (friendship status, interaction weight, relationship category):

```sql
CREATE TABLE relationships (
    id            BIGINT PRIMARY KEY,
    source_id     BIGINT NOT NULL,
    target_id     BIGINT NOT NULL,
    rel_type      VARCHAR(20) NOT NULL,  -- 'follow', 'friend', 'block', 'mute'
    status        VARCHAR(20) DEFAULT 'active',  -- 'active', 'pending', 'rejected'
    weight        FLOAT DEFAULT 1.0,     -- interaction strength for ranking
    metadata      JSONB,                 -- flexible attributes
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (source_id, target_id, rel_type)
);

CREATE INDEX idx_rel_source ON relationships (source_id, rel_type, status);
CREATE INDEX idx_rel_target ON relationships (target_id, rel_type, status);
```

**Pros**: Flexible, supports multiple relationship types in one table, metadata for ranking.
**Cons**: Larger table, more complex queries.
**Best for**: Platforms with multiple relationship types (follow + friend + block + mute).

### Graph Database Model (Neo4j)

For platforms where graph traversal is a core feature (recommendations, community detection):

```cypher
// Create a follow relationship
CREATE (alice:User {id: 1, username: 'alice'})
       -[:FOLLOWS {since: datetime(), weight: 0.85}]->
       (bob:User {id: 2, username: 'bob'})

// Find mutual followers (2-hop traversal)
MATCH (a:User {id: 1})-[:FOLLOWS]->(mutual)<-[:FOLLOWS]-(b:User {id: 2})
RETURN mutual

// People you may know (friends of friends, not already following)
MATCH (me:User {id: 1})-[:FOLLOWS]->(friend)-[:FOLLOWS]->(suggestion)
WHERE NOT (me)-[:FOLLOWS]->(suggestion)
  AND suggestion <> me
RETURN suggestion, COUNT(friend) AS mutual_count
ORDER BY mutual_count DESC
LIMIT 20
```

**Pros**: Excellent for multi-hop traversals, recommendations, community detection. Native graph operations.
**Cons**: Less mature ecosystem, operational complexity, not great for non-graph queries, expensive at hyper-scale.
**Best for**: Platforms where graph features are the primary differentiator (professional networks, dating apps).

### Key-Value / Wide-Column Model (Cassandra/ScyllaDB)

For hyper-scale with simple graph access patterns:

```
// Partition key: user_id, Clustering key: followed_user_id
// Table: user_follows (who does this user follow?)
Row key: user:123:follows
  -> column: user:456, value: {created_at: ..., metadata: ...}
  -> column: user:789, value: {created_at: ..., metadata: ...}

// Reverse index: user_followers (who follows this user?)
Row key: user:456:followers
  -> column: user:123, value: {created_at: ...}
```

**Pros**: Horizontally scalable, fast key lookups, handles massive fan-out.
**Cons**: No complex graph traversals, eventual consistency, limited query flexibility.
**Best for**: Hyper-scale platforms with simple graph access patterns (follow/follower lookups).

---

## 2. Follow and Friend System Design

### Unidirectional Follow (Twitter/Instagram Model)

Users follow other users without reciprocation. This is the simplest model.

```
Alice follows Bob  (Alice sees Bob's posts, Bob doesn't see Alice's unless he follows back)
```

**Implementation:**

```python
async def follow_user(follower_id: int, target_id: int):
    # 1. Validate (can't follow self, can't follow if blocked, rate limit)
    if follower_id == target_id:
        raise ValueError("Cannot follow yourself")
    if await is_blocked(target_id, follower_id):
        raise ForbiddenError("Cannot follow this user")

    # 2. Create the edge (idempotent — use UPSERT)
    await db.execute("""
        INSERT INTO follows (follower_id, following_id, created_at)
        VALUES ($1, $2, NOW())
        ON CONFLICT (follower_id, following_id) DO NOTHING
    """, follower_id, target_id)

    # 3. Update counters atomically
    await db.execute("UPDATE users SET following_count = following_count + 1 WHERE id = $1", follower_id)
    await db.execute("UPDATE users SET follower_count = follower_count + 1 WHERE id = $1", target_id)

    # 4. Emit event for downstream systems (feed, notifications, recommendations)
    await event_bus.publish("user.followed", {
        "follower_id": follower_id,
        "following_id": target_id,
        "timestamp": now()
    })
```

**Key design decisions:**
- **Idempotent follows**: Use UPSERT — following someone twice should not create duplicate edges or increment counters twice.
- **Counter denormalization**: Store follower_count/following_count on the user record. Do NOT compute from COUNT(*) at scale — it's O(n) per query.
- **Counter drift**: Counters can drift from reality over time (race conditions, failed events). Run periodic reconciliation jobs to recount and correct.

### Bidirectional Friendship (Facebook Model)

Both parties must agree to the relationship. Adds complexity for the request/accept flow.

```
Alice sends friend request → Bob accepts → Both see each other's posts
```

**Implementation:**

```sql
CREATE TABLE friendships (
    user_id_1    BIGINT NOT NULL,  -- always the smaller ID (canonical ordering)
    user_id_2    BIGINT NOT NULL,  -- always the larger ID
    status       VARCHAR(20) NOT NULL DEFAULT 'pending',  -- 'pending', 'accepted', 'rejected'
    requester_id BIGINT NOT NULL,   -- who sent the request
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    accepted_at  TIMESTAMP,
    PRIMARY KEY (user_id_1, user_id_2),
    CHECK (user_id_1 < user_id_2)   -- enforce canonical ordering
);
```

**Canonical ordering trick**: Always store the smaller user ID first. This prevents duplicate edges (Alice-Bob and Bob-Alice both map to the same row) and simplifies lookups.

**Request flow:**
1. Alice sends request → INSERT with status='pending', requester_id=Alice
2. Bob accepts → UPDATE status='accepted', accepted_at=NOW()
3. Bob rejects → UPDATE status='rejected' (or DELETE, depending on product requirements)

**Key considerations:**
- **Privacy by default**: Pending requests should not grant any access to the requester.
- **Request limits**: Rate-limit friend requests to prevent spam/harassment (e.g., max 50 pending requests).
- **Notification**: Emit events on request, accept, reject for notification service.

### Hybrid: Follow + Communities (Reddit Model)

Users join communities (subreddits) rather than following individuals. The "social graph" is user→community, not user→user.

```sql
CREATE TABLE community_members (
    community_id  BIGINT NOT NULL,
    user_id       BIGINT NOT NULL,
    role          VARCHAR(20) NOT NULL DEFAULT 'member',  -- 'member', 'moderator', 'admin'
    joined_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (community_id, user_id)
);

CREATE INDEX idx_user_communities ON community_members (user_id, community_id);
```

This model is simpler for feed generation — a user's feed is the union of posts from all communities they've joined, rather than from all users they follow. The fan-out problem is different: instead of fan-out per follower, it's fan-out per community member, but communities are shared so caching is more effective.

---

## 3. Graph Storage Strategies by Scale

### Startup (<100K users): PostgreSQL Adjacency Lists

```sql
-- Simple follows table with indexes on both columns
-- This handles millions of edges easily on a single PostgreSQL instance
CREATE TABLE follows (
    follower_id  BIGINT NOT NULL,
    following_id BIGINT NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);
CREATE INDEX idx_follows_reverse ON follows (following_id, follower_id);
```

At this scale, a single PostgreSQL instance handles all graph queries. Use connection pooling (PgBouncer) and read replicas for analytics queries that scan the graph.

**Query patterns that work fine at this scale:**
- Get following list: `SELECT following_id FROM follows WHERE follower_id = $1 ORDER BY created_at DESC`
- Get follower list: `SELECT follower_id FROM follows WHERE following_id = $1 ORDER BY created_at DESC`
- Check if following: `SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2`
- Mutual follows: `SELECT f1.following_id FROM follows f1 JOIN follows f2 ON f1.following_id = f2.follower_id WHERE f1.follower_id = $1 AND f2.following_id = $1`

### Growth (100K-1M users): PostgreSQL + Redis Cache

The graph is still in PostgreSQL, but hot data is cached in Redis for fast lookups.

```python
# Cache the following list in Redis for quick feed generation
async def get_following_ids(user_id: int) -> list[int]:
    cache_key = f"following:{user_id}"

    # Try cache first
    cached = await redis.smembers(cache_key)
    if cached:
        return [int(id) for id in cached]

    # Cache miss — query DB and populate cache
    rows = await db.fetch("SELECT following_id FROM follows WHERE follower_id = $1", user_id)
    ids = [row['following_id'] for row in rows]

    if ids:
        await redis.sadd(cache_key, *ids)
        await redis.expire(cache_key, 3600)  # 1 hour TTL

    return ids
```

**Cache invalidation pattern:**
- On follow: `SADD following:{follower_id} {target_id}`
- On unfollow: `SREM following:{follower_id} {target_id}`
- Use Redis Sets for O(1) membership checks (`SISMEMBER following:123 456` → "does user 123 follow user 456?")

**When to use Redis Sorted Sets instead of Sets:**
- When you need ordered results (most recent follows first): `ZADD following:{user_id} {timestamp} {target_id}`
- When you need to paginate the list: `ZREVRANGE following:{user_id} 0 19` (first 20)

### Scale (1M-10M users): Dedicated Graph Service

At this scale, the graph logic is complex enough to warrant its own service:

```
┌───────────┐     ┌──────────────────┐     ┌────────────┐
│  API      │────▶│  Graph Service   │────▶│ PostgreSQL │
│  Gateway  │     │                  │     │ (sharded)  │
└───────────┘     │  - Follow/unfollow│     └────────────┘
                  │  - Check follow   │            │
                  │  - Get followers  │     ┌──────▼─────┐
                  │  - Recommendations│     │   Redis    │
                  │  - Mutual friends │     │   Cache    │
                  └──────────────────┘     └────────────┘
```

The graph service:
- Owns the follow/friend data model and all mutations
- Maintains the Redis cache layer
- Provides APIs for other services (feed service queries "get following list for user X")
- Handles privacy checks (is user X blocked by user Y?)
- Computes recommendations (people you may know)

**Sharding strategy**: Shard the follows table by `follower_id`. This ensures all of a user's following list is on the same shard (fast reads for feed generation). The reverse lookup (who follows user X) requires a scatter-gather across shards — cache heavily to avoid this.

### Hyper-scale (10M+ users): Custom Graph Store

At Twitter/Facebook scale, general-purpose databases can't handle the graph workload efficiently. Custom solutions emerge:

- **Twitter's FlockDB**: Purpose-built for high-volume adjacency list storage. Optimized for `add`, `remove`, `list`, and `count` operations on large sets. Backed by MySQL with heavy caching.
- **Facebook's TAO**: Distributed graph store with automatic caching. Objects (nodes) and Associations (edges) with a two-level cache (L1 per-server, L2 per-region).
- **LinkedIn's graph service**: Custom in-memory graph for real-time social graph queries.

Key characteristics of custom graph stores at hyper-scale:
- **In-memory for hot data**: The working set of graph data fits in memory across the cluster
- **Asynchronous replication**: Writes are eventually consistent across regions
- **Specialized APIs**: Not SQL — purpose-built operations like "add edge", "get adjacency list", "intersect two adjacency lists"
- **Tiered storage**: Hot data in memory/SSD, warm data on disk, cold data in archival storage

---

## 4. Social Graph Queries

### Common Query Patterns

| Query | Use Case | Complexity |
|-------|----------|------------|
| Does A follow B? | Privacy checks, UI state | O(1) with cache/index |
| Who does A follow? | Feed generation | O(k) where k = following count |
| Who follows A? | Follower list, notifications | O(k) where k = follower count |
| Mutual follows of A and B | Profile display, trust signals | O(min(k_A, k_B)) with set intersection |
| Friends of friends of A | Recommendations | O(k * avg_k) — expensive |
| Shortest path A → B | Social distance features | O(V + E) — BFS, very expensive on large graphs |

### Mutual Connections

Finding users that both A and B follow (or who follow both A and B):

```sql
-- PostgreSQL: Mutual following (users that both A and B follow)
SELECT f1.following_id
FROM follows f1
JOIN follows f2 ON f1.following_id = f2.following_id
WHERE f1.follower_id = :user_a
  AND f2.follower_id = :user_b;
```

```python
# Redis: Set intersection for mutual follows (much faster)
mutual = await redis.sinter(f"following:{user_a}", f"following:{user_b}")
```

At scale, Redis set intersection (`SINTER`) is the go-to approach — it's O(N*M) where N and M are the set sizes, but it's in-memory and very fast for typical social graph sizes.

### Fan-out Queries for Feed Generation

The most critical graph query — determining whose posts to include in a user's feed:

```python
async def get_feed_sources(user_id: int) -> list[int]:
    """Get the list of user IDs whose posts should appear in this user's feed."""
    # Get all users this person follows
    following_ids = await graph_service.get_following(user_id)

    # For community-based platforms, also get community posts
    community_ids = await graph_service.get_communities(user_id)

    return {
        "following": following_ids,
        "communities": community_ids,
        # Optionally: recommended/suggested content sources
        "recommended": await recommendation_service.get_suggested_sources(user_id)
    }
```

### Follower Count at Scale

Never compute follower counts with `COUNT(*)` at scale. Use denormalized counters:

```python
# Counter update on follow (in a transaction or via event)
async def update_follow_counts(follower_id: int, following_id: int, delta: int):
    """delta = +1 for follow, -1 for unfollow"""
    await db.execute(
        "UPDATE users SET following_count = following_count + $1 WHERE id = $2",
        delta, follower_id
    )
    await db.execute(
        "UPDATE users SET follower_count = follower_count + $1 WHERE id = $2",
        delta, following_id
    )

# Periodic reconciliation job (run daily/weekly)
async def reconcile_follower_counts():
    """Fix counter drift from failed events, race conditions, etc."""
    await db.execute("""
        UPDATE users u SET follower_count = (
            SELECT COUNT(*) FROM follows f WHERE f.following_id = u.id
        )
        WHERE u.id IN (
            SELECT id FROM users
            WHERE follower_count != (SELECT COUNT(*) FROM follows WHERE following_id = users.id)
            LIMIT 1000  -- batch to avoid long transactions
        )
    """)
```

---

## 5. Friend and Follow Recommendations

### Simple: Mutual Connection Count

The baseline recommendation algorithm — suggest users who share the most mutual connections with the target user:

```sql
-- "People you may know" based on mutual follows
SELECT f2.following_id AS suggested_user,
       COUNT(*) AS mutual_count
FROM follows f1
JOIN follows f2 ON f1.following_id = f2.follower_id
WHERE f1.follower_id = :user_id
  AND f2.following_id != :user_id
  AND NOT EXISTS (
      SELECT 1 FROM follows WHERE follower_id = :user_id AND following_id = f2.following_id
  )
GROUP BY f2.following_id
ORDER BY mutual_count DESC
LIMIT 20;
```

**Pros**: Simple, explainable ("12 mutual friends"), works surprisingly well.
**Cons**: Expensive query at scale (requires graph traversal), cold-start problem for new users.

### Intermediate: Multi-Signal Scoring

Combine multiple signals for better recommendations:

```python
def score_recommendation(user: User, candidate: User) -> float:
    score = 0.0

    # Signal 1: Mutual connections (strongest signal)
    mutual_count = get_mutual_count(user.id, candidate.id)
    score += mutual_count * 10.0

    # Signal 2: Shared communities/interests
    shared_communities = get_shared_communities(user.id, candidate.id)
    score += len(shared_communities) * 5.0

    # Signal 3: Geographic proximity
    if user.country == candidate.country:
        score += 3.0
    if user.city == candidate.city:
        score += 5.0

    # Signal 4: Activity level (prefer active users)
    if candidate.last_active_within_days(7):
        score += 2.0

    # Signal 5: Profile completeness
    if candidate.has_profile_photo and candidate.has_bio:
        score += 1.0

    # Signal 6: Interaction history (if they've interacted before)
    interaction_count = get_interaction_count(user.id, candidate.id)
    score += interaction_count * 3.0

    return score
```

### Advanced: Graph-Based Recommendations

For scale-stage platforms, use graph algorithms:

**Personalized PageRank (PPR):**
- Run PageRank from the target user's perspective
- Nodes with high PPR scores are "close" to the user in the graph
- Twitter uses a variant of this in their recommendation pipeline

**Node2Vec / Graph Embeddings:**
- Learn low-dimensional embeddings for each user based on graph structure
- Similar users (close in embedding space) are good recommendations
- Can be combined with content features (what they post about)

**Graph Neural Networks (GNN):**
- Most sophisticated approach — learn from both graph structure and node features
- Used by major platforms for recommendation ranking
- Requires significant ML infrastructure

### Cold-Start Strategies

New users have no graph connections. Use fallback signals:

1. **Onboarding flow**: Ask users to follow topics/interests during signup → recommend popular users in those topics
2. **Contact import**: Import phone contacts or email contacts → match against existing users
3. **Demographic matching**: Recommend users with similar profile attributes (location, language, interests)
4. **Popular/trending**: Show globally popular accounts as a starting point
5. **Content-based**: After a user engages with a few posts, recommend authors of similar content

---

## 6. Blocking, Muting, and Privacy Controls

### Implementation Patterns

```sql
CREATE TABLE blocks (
    blocker_id   BIGINT NOT NULL,
    blocked_id   BIGINT NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id)
);

CREATE TABLE mutes (
    muter_id     BIGINT NOT NULL,
    muted_id     BIGINT NOT NULL,
    mute_type    VARCHAR(20) DEFAULT 'all',  -- 'all', 'posts', 'notifications'
    expires_at   TIMESTAMP,  -- NULL = permanent
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (muter_id, muted_id)
);
```

### Block Behavior (Critical to Get Right)

When user A blocks user B:
1. **Remove existing follow**: If B follows A, auto-unfollow
2. **Prevent new follows**: B cannot follow A (and vice versa)
3. **Hide from search**: B should not appear in A's search results (and vice versa)
4. **Exclude from feeds**: B's content never appears in A's feed, A's content never appears in B's feed
5. **Block interactions**: B cannot like, comment on, or repost A's content
6. **Bidirectional invisibility**: Neither party can see the other's profile (or show "user not found")
7. **DM blocking**: B cannot send DMs to A

```python
# Block check must be called before every interaction
async def is_blocked(user_id: int, target_id: int) -> bool:
    """Check if either user has blocked the other."""
    cache_key = f"block:{min(user_id, target_id)}:{max(user_id, target_id)}"

    cached = await redis.get(cache_key)
    if cached is not None:
        return cached == "1"

    blocked = await db.fetchval("""
        SELECT 1 FROM blocks
        WHERE (blocker_id = $1 AND blocked_id = $2)
           OR (blocker_id = $2 AND blocked_id = $1)
    """, user_id, target_id)

    await redis.setex(cache_key, 3600, "1" if blocked else "0")
    return bool(blocked)
```

### Fan-out Implications of Blocks

Blocks affect feed generation:
- If using fan-out on write: when user A blocks user B, you must remove B's posts from A's feed cache AND remove A's posts from B's feed cache
- This is a relatively rare operation, so it's acceptable to do synchronously or via a background job

### Mute vs Block Semantics

| Feature | Mute | Block |
|---------|------|-------|
| Their posts in your feed | Hidden | Hidden |
| They can see your posts | Yes | No |
| They can follow you | Yes | No (auto-unfollow) |
| They can DM you | Yes | No |
| They know about it | No (stealth) | Usually discoverable |
| Your posts in their feed | Yes | Hidden |

Mutes are invisible to the muted user — this is important for avoiding social conflict. Blocks are typically visible (the blocked user sees "you can't view this profile").

---

## 7. Group and Community Membership

### Membership Models

```sql
CREATE TABLE communities (
    id           BIGINT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    slug         VARCHAR(100) UNIQUE NOT NULL,
    type         VARCHAR(20) DEFAULT 'public',  -- 'public', 'private', 'restricted'
    member_count INT DEFAULT 0,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by   BIGINT NOT NULL REFERENCES users(id)
);

CREATE TABLE community_members (
    community_id BIGINT NOT NULL REFERENCES communities(id),
    user_id      BIGINT NOT NULL REFERENCES users(id),
    role         VARCHAR(20) NOT NULL DEFAULT 'member',
    status       VARCHAR(20) NOT NULL DEFAULT 'active',  -- 'active', 'pending', 'banned'
    joined_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (community_id, user_id)
);

CREATE INDEX idx_user_communities ON community_members (user_id, role, status);
```

### Role-Based Permissions

```python
COMMUNITY_PERMISSIONS = {
    'member': {
        'can_view': True,
        'can_post': True,
        'can_comment': True,
        'can_vote': True,
        'can_report': True,
    },
    'moderator': {
        'can_view': True,
        'can_post': True,
        'can_comment': True,
        'can_vote': True,
        'can_report': True,
        'can_remove_posts': True,
        'can_ban_members': True,
        'can_pin_posts': True,
        'can_edit_rules': True,
    },
    'admin': {
        # All moderator permissions plus:
        'can_add_moderators': True,
        'can_edit_community': True,
        'can_delete_community': True,
        'can_transfer_ownership': True,
    },
}
```

### Community Types and Access Control

| Community Type | Who Can See | Who Can Join | Who Can Post |
|---------------|------------|-------------|-------------|
| Public | Everyone | Anyone | Members |
| Restricted | Everyone | Approved by mods | Approved members |
| Private | Members only | Invited only | Members |

### Community Feed Generation

Community-based feeds differ from follow-based feeds:

```python
async def get_community_feed(community_id: int, user_id: int, cursor: str = None):
    # 1. Check membership
    if not await is_community_member(community_id, user_id):
        community = await get_community(community_id)
        if community.type != 'public':
            raise ForbiddenError("Not a member of this community")

    # 2. Get posts from this community, ranked
    posts = await get_community_posts(
        community_id=community_id,
        sort='hot',  # or 'new', 'top', 'controversial'
        cursor=cursor,
        limit=25
    )

    # 3. Filter out posts from blocked/muted users
    posts = await filter_blocked_content(posts, user_id)

    return posts
```

---

## 8. Graph Partitioning and Sharding

### Sharding Strategies

**By follower_id (most common):**
- All of user A's following data is on the same shard
- Fast reads for "who does A follow?" (single shard query)
- Slow reads for "who follows A?" (scatter-gather across all shards)
- Best for: feed generation (which needs the following list)

**By min(user_id_1, user_id_2) (for bidirectional friendships):**
- Canonically ordered pairs ensure each friendship is on one shard
- Both directions can be looked up from the same shard
- Best for: friendship-based platforms (Facebook model)

**Dual storage (both directions):**
- Store edges in both directions on different shard keys
- `following:{user_id}` sharded by user_id → fast "who do I follow?"
- `followers:{user_id}` sharded by user_id → fast "who follows me?"
- Doubles storage but eliminates scatter-gather for both directions
- Best for: platforms that need fast access in both directions at scale

### Handling Hot Spots

Celebrity accounts create hot spots — users with millions of followers:

```python
# Anti-hot-spot strategies:
# 1. Shard the follower list itself for very large accounts
async def get_followers_paged(user_id: int, page: int, page_size: int = 1000):
    shard = get_follower_shard(user_id, page)
    return await shard.get_followers(user_id, offset=page * page_size, limit=page_size)

# 2. Cache follower counts separately (don't scan the list)
async def get_follower_count(user_id: int) -> int:
    cached = await redis.get(f"follower_count:{user_id}")
    if cached:
        return int(cached)
    count = await db.fetchval("SELECT follower_count FROM users WHERE id = $1", user_id)
    await redis.setex(f"follower_count:{user_id}", 300, str(count))
    return count

# 3. Use probabilistic data structures for "does A follow B?" on celebrity accounts
# Bloom filters give O(1) membership tests with small false positive rate
```

### Rebalancing and Migration

As the graph grows, shards become unbalanced. Strategies:

1. **Consistent hashing**: Use a hash ring so adding/removing shards only moves a fraction of the data
2. **Virtual shards**: Map logical shards to physical shards. When rebalancing, move virtual shards between physical nodes
3. **Online migration**: Use dual-write patterns during migration — write to both old and new shard, read from new, backfill in background

---

## 9. Real-World Graph Systems

### Twitter's FlockDB

- **Purpose**: High-volume adjacency list storage for the social graph
- **Design**: Simple graph database optimized for `add`, `remove`, `list`, and `count` operations
- **Storage**: Backed by MySQL with aggressive caching
- **Operations**: Supports set operations (intersection, union, difference) on adjacency lists
- **Scale**: Handled Twitter's entire follow graph (billions of edges)
- **Key insight**: Simple operations at extreme scale — no complex graph traversals, just fast adjacency list management

### Facebook's TAO

- **Purpose**: Distributed graph store for social objects and associations
- **Design**: Objects (nodes) and Associations (directed edges) with a two-level cache
  - L1 cache: per-web-server, small, very fast
  - L2 cache: per-region, larger, shared across web servers
- **Storage**: MySQL for persistence, memcached for caching
- **Operations**: `assoc_get`, `assoc_count`, `assoc_range`, `obj_get`
- **Key insight**: Read-optimized with strong cache consistency. Writes go to the leader region and replicate asynchronously.

### LinkedIn's Graph Service

- **Purpose**: Real-time graph queries for professional network features
- **Design**: In-memory graph partitioned across a cluster
- **Operations**: Multi-hop traversals for "2nd degree connections", "people who viewed your profile", "shared connections"
- **Key insight**: The professional network graph is small enough to fit in memory (~1B members, ~10B edges) when using compact adjacency list representation

### Bluesky's AT Protocol

- **Purpose**: Decentralized social graph where users own their data
- **Design**: Each user has a Personal Data Server (PDS) that stores their social graph
- **Federation**: Graph data is federated — follows are stored as records in the user's repository
- **Key insight**: Different architectural constraints when users can move their data between providers. The social graph is not centralized — it's distributed across PDSs.

### Key Takeaways from Real-World Systems

| System | Graph Size | Storage | Traversal Depth | Key Optimization |
|--------|-----------|---------|-----------------|-----------------|
| Twitter FlockDB | Billions of edges | MySQL + cache | 1 hop (adjacency only) | Set operations on adjacency lists |
| Facebook TAO | Trillions of edges | MySQL + memcached | 1-2 hops | Two-level caching, read-path optimization |
| LinkedIn | ~10B edges | In-memory | 2-3 hops | Compact in-memory graph representation |
| Bluesky AT | Distributed | Per-user PDS | 1 hop (federated) | User-owned, portable data |

---

## Design Checklist

When designing a social graph system, verify:

- [ ] **Idempotent operations**: Follow/unfollow/block are idempotent (no duplicates on retry)
- [ ] **Both directions indexed**: Can efficiently query both "who do I follow?" and "who follows me?"
- [ ] **Counter denormalization**: Follower/following counts stored on user record, not computed
- [ ] **Counter reconciliation**: Periodic job to fix counter drift
- [ ] **Block checks on every interaction**: Block status checked before follow, view, like, comment, DM
- [ ] **Cache layer for hot data**: Following lists, block lists, and membership cached in Redis
- [ ] **Pagination**: All list endpoints use cursor-based pagination (not offset)
- [ ] **Privacy controls**: Private accounts, block/mute, community access controls implemented
- [ ] **Rate limiting**: Follow/unfollow rate-limited to prevent spam follows
- [ ] **Event emission**: All graph mutations emit events for downstream systems (feed, notifications, analytics)

Always verify current best practices with `WebSearch` before making final technology recommendations — the graph database landscape evolves rapidly.
