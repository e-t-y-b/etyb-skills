# Chat Systems Architecture — Deep Reference

**Always use `WebSearch` to verify chat platform features, pricing, SDK versions, and protocol specifications before giving advice. The chat infrastructure space evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [Chat Architecture Fundamentals](#1-chat-architecture-fundamentals)
2. [Chat-as-a-Service Platforms](#2-chat-as-a-service-platforms)
3. [Chat Protocols](#3-chat-protocols)
4. [Message Storage Architecture](#4-message-storage-architecture)
5. [Message Delivery and Ordering](#5-message-delivery-and-ordering)
6. [Fan-Out Strategies](#6-fan-out-strategies)
7. [Chat Features Implementation](#7-chat-features-implementation)
8. [Presence and Typing Indicators](#8-presence-and-typing-indicators)
9. [Chat Search](#9-chat-search)
10. [Content Moderation](#10-content-moderation)
11. [End-to-End Encryption](#11-end-to-end-encryption)
12. [Push Notifications](#12-push-notifications)
13. [Scaling Chat Systems](#13-scaling-chat-systems)

---

## 1. Chat Architecture Fundamentals

### Core Components

Every chat system has these components, regardless of scale:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Connection  │────▶│   Message    │────▶│   Message    │
│  Layer       │     │   Router     │     │   Store      │
│ (WebSocket)  │     │              │     │ (persistent) │
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │
                     ┌──────▼───────┐     ┌──────────────┐
                     │  Fan-Out     │     │   Push       │
                     │  Service     │     │   Notification│
                     │              │────▶│   Service    │
                     │  (online +   │     │              │
                     │   offline)   │     │  (APNs/FCM)  │
                     └──────────────┘     └──────────────┘
```

### Message Flow

```
1. Sender types message
2. Client sends via WebSocket: {channel: "ch-123", text: "Hello", client_id: "msg-uuid"}
3. Server receives → validates (auth, rate limit, permissions)
4. Server assigns server-side message ID + timestamp (canonical ordering)
5. Server persists to message store
6. Server fan-out:
   a. Online members: deliver via WebSocket (immediate)
   b. Offline members: queue push notification
   c. Unread counters: increment for all members except sender
7. Server sends ACK to sender: {client_id: "msg-uuid", server_id: "m-456", ts: 1713100800}
8. Sender updates local message with server ID + timestamp (optimistic → confirmed)
```

### Channel Types

| Type | Members | Use Case | Examples |
|------|---------|----------|---------|
| DM (1:1) | 2 | Private conversations | iMessage, WhatsApp DM |
| Group DM | 3-10 | Small group conversations | WhatsApp group, iMessage group |
| Channel (public) | 10-100K+ | Topic-based, discoverable | Slack channel, Discord channel |
| Channel (private) | 10-1K | Invite-only | Slack private channel |
| Thread | Any (scoped to parent) | Contextual discussions | Slack thread, Discord thread |
| Broadcast | 1→many | Announcements | Telegram channel, WhatsApp broadcast |

### Build vs Buy Decision

**Build custom when:**
- Chat is a core product feature (you ARE building a chat app)
- Unique requirements no platform supports (custom encryption, compliance, UX)
- Scale economics: >1M MAU where per-MAU pricing exceeds infrastructure cost
- Team has real-time engineering experience

**Buy (Chat-as-a-Service) when:**
- Chat is a secondary feature (adding chat to an existing product)
- Speed to market matters more than customization
- Team lacks WebSocket/real-time experience
- <500K MAU where engineering cost exceeds platform cost

---

## 2. Chat-as-a-Service Platforms

### Stream (GetStream.io)

- **Model**: Chat API + SDK — add chat to any app
- **Features**: Channels, threads, reactions, file attachments, read receipts, typing indicators, moderation (AI + manual), offline support, push notifications, user presence, message search
- **SDKs**: React, React Native, Flutter, Swift, Kotlin, Angular, Vue
- **UI components**: Pre-built UI kits for React, React Native, Flutter, Swift, Kotlin — customizable
- **Scale**: Handles billions of messages, used by major apps
- **Differentiator**: Most comprehensive SDK/UI kit ecosystem, best developer experience, AI moderation
- **Pricing**: Per-MAU + per-message pricing, free tier (100 MAU)
- **Best for**: Apps that need polished chat with minimal engineering effort

### Sendbird

- **Model**: Chat and calls API + SDK
- **Features**: Group channels, DMs, moderation, file sharing, push, typing indicators, read receipts, message search, chat AI (GPT integration), voice/video calling
- **SDKs**: JavaScript, React, React Native, Flutter, Swift, Kotlin, .NET
- **Differentiator**: Voice/video calling built-in alongside chat, strong enterprise presence
- **Pricing**: Per-MAU pricing, free tier (100 MAU)
- **Best for**: Apps needing both chat AND voice/video calls from one vendor

### CometChat

- **Model**: Chat SDK with pre-built UI and widget options
- **Features**: Text, voice, video messaging, groups, file sharing, reactions, threads, moderation, push
- **SDKs**: React, React Native, Flutter, Swift, Kotlin, Angular, Vue
- **Differentiator**: Embeddable chat widget (add to any website), extensions marketplace
- **Pricing**: Per-MAU pricing
- **Best for**: Adding chat to websites, marketplaces, and existing apps quickly

### TalkJS

- **Model**: Chat widget/SDK focused on marketplace and commerce use cases
- **Features**: Pre-built chat UI (inbox, chat popup), email fallback, moderation, custom data
- **Differentiator**: Designed specifically for marketplaces (buyer↔seller chat), includes email notifications when offline
- **Pricing**: Per-MAU pricing
- **Best for**: Marketplace/commerce chat (Airbnb-like, eBay-like), support chat

### Amity

- **Model**: Social features SDK — chat, social feed, video streaming
- **Features**: Chat (group, live, community), social feed, live streaming, moderation
- **Differentiator**: Social features beyond just chat — if you need chat + social feed + live
- **Best for**: Social apps, community platforms, apps that need multiple social features

### Platform Selection Matrix

| Factor | Stream | Sendbird | CometChat | TalkJS | Amity |
|--------|--------|----------|-----------|--------|-------|
| Best UI kit | Excellent | Good | Good (widget) | Pre-built widget | Good |
| Voice/video | No | Yes | Yes | No | Yes (streaming) |
| AI moderation | Yes | Yes | Basic | Basic | Yes |
| Offline support | Yes | Yes | Yes | Limited | Yes |
| Search | Yes | Yes | Basic | Basic | Basic |
| E2EE | Custom | Yes | No | No | No |
| Marketplace focus | No | No | No | Yes | No |
| Free tier | 100 MAU | 100 MAU | Varies | 500 conversations | Varies |
| Best for | Full-featured chat | Chat + calls | Widget/embed | Marketplace | Social platform |

---

## 3. Chat Protocols

### Custom WebSocket Protocol (Most Common)

Most modern chat applications use a custom protocol over WebSocket:

**Advantages:**
- Complete control over message format, features, and behavior
- Optimized for your specific use case
- No protocol overhead or unused features
- Can use binary serialization (Protobuf, MessagePack)

**Typical message format:**
```json
// Client → Server
{"op": "send_message", "d": {"channel_id": "ch-123", "content": "Hello!", "nonce": "uuid-abc"}}
{"op": "typing_start", "d": {"channel_id": "ch-123"}}
{"op": "mark_read", "d": {"channel_id": "ch-123", "message_id": "m-456"}}

// Server → Client
{"op": "message_create", "d": {"id": "m-456", "channel_id": "ch-123", "content": "Hello!", "author": {...}, "ts": 1713100800}}
{"op": "typing_start", "d": {"channel_id": "ch-123", "user": {...}}}
{"op": "presence_update", "d": {"user_id": "u-789", "status": "online"}}
```

### Matrix Protocol

- **Open standard**: Federated, decentralized chat protocol
- **Homeservers**: Each organization runs a Matrix homeserver; they federate (like email servers)
- **Implementations**: Synapse (Python, reference server), Dendrite (Go, next-gen), Conduit (Rust)
- **Clients**: Element (web, desktop, mobile), many third-party clients
- **Features**: E2EE (Megolm/Olm, based on Signal Protocol), rooms, threads, VoIP, bridges to other services
- **Bridges**: Connect Matrix to Slack, Discord, Telegram, IRC, XMPP, SMS, WhatsApp
- **Best for**: Organizations wanting self-hosted, federated chat with E2EE; replacing Slack with self-hosted alternative
- **Limitation**: Federation adds complexity and latency, Synapse can be resource-heavy

### XMPP (Extensible Messaging and Presence Protocol)

- **Standard**: IETF standard (RFCs 6120-6122), XML-based
- **History**: WhatsApp originally used XMPP, ejabberd and Prosody are popular servers
- **Features**: Extensible via XEPs (XMPP Extension Protocols), presence, multi-user chat, file transfer
- **Status (2026)**: Still used in enterprise/gaming (ejabberd), but largely superseded by custom WebSocket protocols for consumer chat
- **Best for**: Legacy integration, when XMPP compliance is required

### MQTT (Message Queuing Telemetry Transport)

- **Model**: Lightweight pub/sub, designed for IoT and constrained devices
- **Relevance to chat**: Facebook Messenger originally used MQTT for mobile push efficiency
- **Advantages**: Very low overhead (2-byte header minimum), great for mobile (battery-efficient), QoS levels
- **Best for**: Chat on constrained devices (IoT), mobile-first chat where battery efficiency matters

---

## 4. Message Storage Architecture

### Storage Requirements

Chat messages have specific storage characteristics:
- **Write-heavy**: Messages are written constantly, reads are bursty (loading history)
- **Append-only**: Messages are rarely updated (edit) or deleted
- **Time-ordered**: Most reads are "most recent messages" (reverse chronological)
- **Per-channel partitioning**: Messages naturally partition by channel/conversation

### Database Selection

**Cassandra / ScyllaDB**
- Best for: High-throughput, write-heavy chat workloads at scale
- Partition key: `channel_id`, Clustering key: `message_id` (time-sorted)
- Reads: Efficient range query for "last N messages in channel"
- Scale: Handles billions of messages, linear horizontal scaling
- Used by: Discord (Cassandra → ScyllaDB migration), Apple Messages, Netflix
- ScyllaDB: C++ rewrite of Cassandra — same API, 5-10x better performance per node

**Schema example (Cassandra/ScyllaDB):**
```sql
CREATE TABLE messages (
    channel_id    bigint,
    bucket        int,           -- time bucket (monthly/weekly) to limit partition size
    message_id    timeuuid,      -- time-ordered UUID
    author_id     bigint,
    content       text,
    attachments   list<frozen<attachment>>,
    edited_at     timestamp,
    deleted       boolean,
    PRIMARY KEY ((channel_id, bucket), message_id)
) WITH CLUSTERING ORDER BY (message_id DESC);
```

**DynamoDB**
- Best for: Serverless chat, AWS-native, when you want zero operational overhead
- Partition key: `channel_id`, Sort key: `message_id`
- Scale: Unlimited (provisioned or on-demand capacity)
- Limitation: 400KB item limit, expensive at scale compared to self-managed Cassandra
- Used by: Many AWS-native applications

**PostgreSQL**
- Best for: Small-medium chat (<10M messages), when you want SQL + familiar tooling
- Works fine for: Internal tools, small SaaS chat features, early-stage products
- Limitation: Single-node write throughput caps at ~10-50K writes/second; sharding is complex
- Optimization: Partition by channel_id, index on (channel_id, created_at DESC), BRIN index for time-range queries
- Used by: Many small-medium applications, Slack (early days)

**PostgreSQL schema:**
```sql
CREATE TABLE messages (
    id            bigint GENERATED ALWAYS AS IDENTITY,
    channel_id    bigint NOT NULL,
    author_id     bigint NOT NULL,
    content       text,
    attachments   jsonb,
    created_at    timestamptz NOT NULL DEFAULT now(),
    edited_at     timestamptz,
    deleted_at    timestamptz,
    CONSTRAINT pk_messages PRIMARY KEY (id)
) PARTITION BY HASH (channel_id);

-- Partition into 16 partitions
CREATE TABLE messages_p0 PARTITION OF messages FOR VALUES WITH (MODULUS 16, REMAINDER 0);
-- ... messages_p1 through messages_p15

CREATE INDEX idx_messages_channel_time ON messages (channel_id, created_at DESC);
```

### Message ID Generation

Message IDs must be:
- **Unique**: No collisions
- **Time-ordered**: Sortable by creation time (for efficient range queries)
- **Generated quickly**: No coordination bottleneck

**Snowflake IDs (Discord, Twitter approach):**
```
| 41 bits: timestamp (ms since epoch) | 10 bits: worker ID | 12 bits: sequence |
```
- 64-bit integer, time-sortable, ~4096 IDs per millisecond per worker
- No coordination needed (each worker has unique ID)
- Used by: Discord, Twitter (original Snowflake), Instagram

**UUIDv7 (IETF standard, 2024+):**
- 128-bit UUID with time-ordered prefix
- Standardized, sortable, globally unique without coordination
- Growing adoption as the modern default for time-ordered IDs

**ULID:**
- 128-bit, lexicographically sortable, timestamp-prefixed
- Similar to UUIDv7 but predates the standard

---

## 5. Message Delivery and Ordering

### Delivery Guarantees

**At-most-once**: Message delivered 0 or 1 times. Simplest — fire and forget over WebSocket. Acceptable for typing indicators, presence updates.

**At-least-once**: Message delivered 1 or more times. Client retries on failure, server deduplicates. Required for chat messages.

**Exactly-once (effectively)**: At-least-once delivery + idempotent processing. Client sends with idempotency key (`nonce`), server deduplicates by nonce.

### Message Ordering

**Total ordering (global):**
- All clients see messages in the exact same order
- Requires a single serialization point (bottleneck)
- Used by: Slack (per-channel total order via database sequence)

**Causal ordering:**
- If message B references message A (reply, reaction), B appears after A
- Messages without causal relationship can appear in different orders for different clients
- More scalable than total ordering
- Used by: Most distributed chat systems

**Implementation: Lamport timestamps or vector clocks**
```
Message A: {sender: "alice", lamport: 5, content: "Hello"}
Message B: {sender: "bob", lamport: 6, content: "Hi!", reply_to: "A"}  // Bob saw A before sending B
```

**Per-channel ordering (practical default):**
- Total order within a channel (server assigns monotonic ID per channel)
- No ordering guarantee across channels (unnecessary and expensive)
- Used by: Discord, Slack, most chat systems

### Delivery Receipts and Read Receipts

**Delivery receipt**: "Message arrived at recipient's device"
```
Sender → Server → Recipient → Server: {type: "delivered", msg_id: "m-456"} → Sender
```

**Read receipt**: "Recipient viewed the message"
```
Recipient opens chat → Client sends: {type: "read", channel_id: "ch-123", last_read: "m-456"}
Server broadcasts: {type: "read_state", channel_id: "ch-123", user: "bob", last_read: "m-456"}
```

**Optimization**: Don't send individual read receipts per message — batch as "read up to message X." One event per channel per user, not per message.

### Handling Offline → Online Transition

When a client comes online after being offline:

1. Client sends last known state: `{last_sync: "m-400", channels: ["ch-1", "ch-2", ...]}`
2. Server computes delta: All messages after m-400 for client's channels
3. Server sends delta (or full channel state if delta is too large)
4. Client merges with local cache

**Optimization for long offline periods:**
- If >1000 missed messages in a channel: Send only the last 50 + "N messages above"
- Lazy load: Full history loaded on scroll-up, not on reconnect

---

## 6. Fan-Out Strategies

### Fan-Out on Write (Push Model)

When a message is sent, immediately deliver to all members' inboxes/feeds:

```
Alice sends "Hello" to #general (1000 members)
  → Write message to messages table
  → For each of 1000 members:
     → If online: push via WebSocket
     → Write to user's inbox/timeline table
     → Increment unread counter
```

**Pros**: Reading is fast (inbox is pre-computed), real-time delivery is straightforward
**Cons**: Write amplification (1 message → 1000 writes), expensive for large channels
**Best for**: DMs, small groups, channels with <1000 members

### Fan-Out on Read (Pull Model)

When a user opens a channel, aggregate messages at read time:

```
Bob opens #general
  → Query messages table: SELECT * FROM messages WHERE channel_id = 'general' ORDER BY id DESC LIMIT 50
  → Server computes unread count from last_read bookmark
```

**Pros**: No write amplification, efficient for large channels
**Cons**: Reading is more expensive (aggregation at query time), harder to compute unread counts efficiently
**Best for**: Large channels (1000+ members), broadcast channels

### Hybrid (WhatsApp/Slack Approach)

- **DMs and small groups (<100 members)**: Fan-out on write (fast delivery, pre-computed inbox)
- **Large channels (100+ members)**: Fan-out on read (avoid write amplification)
- **Online users in any channel**: Always push via WebSocket (real-time regardless of fan-out model)
- **Unread counters**: Maintained separately per user per channel (increment on write, reset on read)

### Discord's Approach

Discord combines multiple strategies:
- Messages stored once per channel (Cassandra, partitioned by channel_id)
- Online members get real-time WebSocket push
- Offline members get push notifications (if enabled)
- No traditional fan-out — messages live in the channel, not copied to user inboxes
- Unread state: Last-read message ID per user per channel (lightweight)
- History: Loaded on demand when user opens channel (fan-out on read)

---

## 7. Chat Features Implementation

### Threads

**Data model:**
```
messages table:
  id, channel_id, content, author_id, thread_id (null for top-level), created_at

threads table:
  id, channel_id, parent_message_id, reply_count, last_reply_at, last_reply_author
```

- Thread is a virtual sub-channel anchored to a parent message
- Thread messages have `thread_id` pointing to the parent message
- Thread metadata (reply count, last reply) denormalized for display
- Loading a thread: `SELECT * FROM messages WHERE thread_id = ? ORDER BY created_at`

### Reactions

**Data model:**
```
reactions table:
  message_id, emoji, user_id, created_at
  PRIMARY KEY (message_id, emoji, user_id)

-- Denormalized on message for display:
message.reactions = [{"emoji": "👍", "count": 3, "users": ["alice", "bob", "charlie"]}]
```

- Individual reactions stored for "who reacted" queries
- Aggregate counts denormalized on the message (avoid COUNT query on every render)
- Real-time: Broadcast reaction event to channel members, clients update local state

### Mentions

```
message.content = "Hey <@user:alice>, check <#channel:general>"
message.mentions = ["alice"]
message.channel_mentions = ["general"]
```

- Parse mentions during send (client or server-side)
- Store mentioned user IDs for notification routing
- Render: Client replaces `<@user:alice>` with clickable user name
- Notification: Mentioned users get push notification even if channel is muted

### Rich Media (Files, Images, Voice Messages)

**Upload flow:**
```
1. Client uploads file to blob storage (S3/R2) → gets URL
2. Client sends message with attachment reference:
   {content: "Check this out", attachments: [{type: "image", url: "...", width: 800, height: 600}]}
3. Server validates attachment metadata, stores message
4. Recipients render attachment inline
```

- Separate upload from message send (upload can be slow, message send should be fast)
- Generate thumbnails/previews server-side for images/videos
- Voice messages: Upload audio file, display waveform + duration in UI

### Message Editing and Deletion

**Edit:**
```
Client: {op: "edit_message", d: {message_id: "m-456", content: "Updated text"}}
Server: Store edit, update message, broadcast:
  {op: "message_update", d: {id: "m-456", content: "Updated text", edited_at: 1713100900}}
```

- Store edit history (optional — Slack shows "(edited)", Discord allows viewing edit history)
- Edit window: Many platforms allow editing only within a time window (15 min, 1 hour)

**Deletion:**
```
Client: {op: "delete_message", d: {message_id: "m-456"}}
Server: Soft-delete (set deleted_at), broadcast:
  {op: "message_delete", d: {id: "m-456", channel_id: "ch-123"}}
```

- Soft delete: Mark as deleted, don't remove from database (for compliance, audit)
- Client: Replace message content with "This message was deleted"
- Hard delete: Actually remove data — required for GDPR "right to erasure" in some cases

---

## 8. Presence and Typing Indicators

### Presence System Architecture

**Simple (Redis-based):**
```
User comes online:
  SET user:presence:alice "online" EX 60    # Expires in 60 seconds
  SADD channel:ch-123:online "alice"        # Track per-channel online users

Heartbeat (every 30s):
  SET user:presence:alice "online" EX 60    # Refresh TTL

User goes offline (connection closed or TTL expires):
  DEL user:presence:alice
  SREM channel:ch-123:online "alice"
```

**Broadcast strategy:**
- Don't broadcast every presence change to everyone (expensive at scale)
- Channel-scoped: Only broadcast to members of shared channels
- Batched: Aggregate presence changes over 5-second windows, broadcast summary
- Lazy: Client requests presence for visible users, not all contacts

### Typing Indicators

**Protocol:**
```
User starts typing:
  Client → Server: {op: "typing_start", d: {channel_id: "ch-123"}}
  
Server → Other channel members: {op: "typing_start", d: {channel_id: "ch-123", user: {id: "alice", name: "Alice"}}}

Auto-expire: After 8-10 seconds of no typing events, clear indicator
```

**Optimizations:**
- Throttle typing events: Send at most once per 3-5 seconds (not on every keystroke)
- Client-side timeout: Clear "typing" indicator after 10 seconds of no updates
- Don't persist: Typing is ephemeral — never stored in database
- Large channels: Only show typing to a subset (e.g., users who have the channel open)

### Presence at Scale (Discord-Style)

Discord handles presence for millions:
- Presence updates flow through a dedicated presence service
- Per-guild (server) presence — not global
- Lazy guilds: For guilds with >75K members, presence is lazy-loaded (only tracked for online members you can see)
- Incremental presence: On connect, send presence for visible members; update on changes

---

## 9. Chat Search

### Full-Text Search Options

**Elasticsearch / OpenSearch**
- Most popular for chat search — inverted index, full-text analysis
- Features: Fuzzy matching, highlighting, phrase search, filters (channel, author, date range)
- Architecture: Index messages asynchronously (write to search index after persisting message)
- Scale: Handles billions of documents, clustered
- Limitation: Operational complexity (cluster management, sharding, reindexing)

**Typesense**
- Developer-friendly search — simpler than Elasticsearch
- Features: Typo tolerance, faceting, filtering, relevance tuning
- Best for: Small-medium chat search, when ES is overkill

**Meilisearch**
- Similar to Typesense — instant search, typo-tolerant
- Rust-based, very fast for small-medium datasets
- Best for: Client-facing search UI with instant results

### Indexing Strategy

```
Message created → Write to message store → Publish event → Search indexer → Write to search index
                                                              │
                                                        Index fields:
                                                        - content (full-text analyzed)
                                                        - channel_id (filter)
                                                        - author_id (filter)
                                                        - created_at (range filter)
                                                        - attachments.name (full-text)
                                                        - mentions (filter)
```

**What to index:**
- Message content (full-text, analyzed — stemming, tokenization)
- Channel ID, author ID (for filtering)
- Timestamp (for date range queries)
- File/attachment names
- Mentions (for "messages mentioning me")

**What NOT to index:**
- Reactions, read receipts, delivery status (query from primary store)
- Deleted messages (remove from index on delete)
- Typing indicators, presence (ephemeral)

---

## 10. Content Moderation

### Moderation Architecture

```
Message sent → Pre-check (rate limit, spam) → Persist → Async moderation → Action
                       │                                      │
                 Block if spam                          ┌─────┼─────┐
                 detected pre-send                     ▼     ▼     ▼
                                                    Auto   Queue  Notify
                                                    remove for    user
                                                           human
                                                           review
```

### Moderation Strategies

**Rule-based (fast, deterministic):**
- Banned word lists (profanity, slurs, custom)
- Regex patterns (phone numbers, emails, URLs)
- Rate limiting (max messages per second, duplicate detection)
- Limitation: Easy to circumvent (l33tspeak, zero-width characters, homoglyphs)

**AI/ML-based (contextual, catches more):**
- Content classification: Toxic, hate speech, harassment, NSFW, spam
- Services: Perspective API (Google), OpenAI Moderation, Hive, custom models
- Latency: 50-200ms per message — can be async (post to store, check in background, remove if flagged)
- Accuracy: Better than rules for nuanced content, but false positives exist

**Human moderation (highest accuracy):**
- Moderator queue for flagged content
- User reporting ("report this message")
- Moderator tools: Delete, mute user, ban user, warn user
- Required for: Edge cases, appeals, context-dependent decisions

### Implementation Pattern

```
function moderateMessage(message) {
    // Layer 1: Fast rules (synchronous, <1ms)
    if (containsBannedWord(message.content)) return BLOCK;
    if (isRateLimited(message.author)) return RATE_LIMITED;
    if (isDuplicate(message)) return BLOCK;
    
    // Layer 2: AI moderation (async, <200ms)
    enqueueForAIModeration(message);  // Check in background
    
    // Layer 3: User reports (human-triggered)
    // Handled via report button → moderator queue
    
    return ALLOW;  // Optimistic — allow message, remove later if AI flags it
}
```

---

## 11. End-to-End Encryption

### Signal Protocol

The gold standard for chat E2EE, used by Signal, WhatsApp, Facebook Messenger (optional):

**Key concepts:**
- **Double Ratchet Algorithm**: Each message uses a unique encryption key, derived from a chain of ratchets
- **Forward secrecy**: Compromising today's key doesn't decrypt past messages
- **Post-compromise security**: After a compromise, security is restored after a few messages (ratchet advances)
- **X3DH (Extended Triple Diffie-Hellman)**: Key agreement protocol for establishing shared secrets between two parties

**How it works (simplified):**
1. Each user generates identity key pair + signed prekey + one-time prekeys
2. Public keys uploaded to server (key bundle)
3. To start a conversation: Fetch recipient's key bundle, run X3DH to establish shared secret
4. Each message encrypted with unique key from Double Ratchet
5. Server cannot read messages — only relays encrypted blobs

### MLS (Messaging Layer Security)

- **IETF standard (RFC 9420, published July 2023)** for group E2EE — designed to scale to large groups (up to 50,000 members)
- Signal Protocol is designed for 1:1 (group chat is N × 1:1 sessions, O(N) encryption per message)
- MLS uses a tree-based key structure (ratchet tree) — O(log N) operations for group changes
- **2025 milestone**: GSMA Universal Profile 3.0 adopted MLS for RCS E2EE. Apple announced MLS-based RCS E2EE support. First large-scale interoperable E2EE between different messaging providers.
- Adoption: Google Messages (RCS), Apple Messages (RCS), Wire, Cisco Webex, Matrix (exploring)
- Best for: Large encrypted groups (100+ members), multi-device users, cross-provider interoperability

### Post-Quantum Cryptography (Emerging)

- Apple adopted "PQ3" protocol for iMessage (2024) — post-quantum key establishment using ML-KEM (CRYSTALS-Kyber)
- Signal added PQXDH (post-quantum X3DH) in 2023
- Preparing for "harvest now, decrypt later" quantum computing threats
- Not yet required for most chat systems, but watch for adoption in regulated industries

### Architecture with E2EE

```
Sender → Encrypt (client-side) → Encrypted blob → Server (cannot decrypt) → Relay → Decrypt (recipient)
```

**Server limitations with E2EE:**
- No server-side search (content is encrypted)
- No server-side moderation (can't read messages)
- No server-side link previews, notifications with content
- Push notifications: Generic ("New message from Alice") not content-specific

**Workarounds:**
- Client-side search: Build search index locally on each device
- Abuse reporting: User explicitly reports (decrypts and submits to server)
- Key backup: Encrypted key backup for device migration (user's password encrypts the backup)

---

## 12. Push Notifications

### Push Architecture

```
Message for offline user → Push service → Platform gateway → User's device
                              │
                        ┌─────┼─────┐
                        ▼     ▼     ▼
                      APNs   FCM   Web Push
                      (iOS)  (Android)  (Browser)
```

### Apple Push Notification Service (APNs)

- Required for iOS push notifications
- Connection: HTTP/2 to Apple's servers with JWT or certificate auth
- Payload: Max 4KB JSON
- Features: Rich notifications (images, actions), notification groups, priority levels
- Background updates: Silent push to wake app for data sync

### Firebase Cloud Messaging (FCM)

- Google's push service — works on Android, iOS, and web
- Connection: HTTP v1 API (recommended) or legacy HTTP/XMPP
- Payload: Max 4KB
- Features: Topics (pub/sub), conditional targeting, analytics
- Best for: Android (mandatory), cross-platform when you want one API

### Notification Batching and Quiet Hours

**Batching:**
- Don't send a push for every message in a burst — batch into "5 new messages from Alice"
- Wait 5-10 seconds after first undelivered message before pushing
- If user comes online during wait period, cancel the push

**Quiet hours:**
- User-configurable: "Don't notify between 10 PM and 8 AM"
- Server-side enforcement: Queue notifications, deliver at quiet hour end
- Or: Reduce to summary ("You have 15 unread messages") at quiet hour end

**Channel-level muting:**
- Users mute specific channels: No push notifications, but unread badge still updates
- @mention override: Push even in muted channels if user is mentioned
- Keywords: Push if message contains user-defined keywords

---

## 13. Scaling Chat Systems

### Connection Sharding

At millions of connections, shard across gateway servers:

```
User A (hash → Gateway 1) ←WS→ Gateway 1 ←→ Redis/NATS ←→ Gateway 2 ←WS→ User B
```

- Consistent hashing or round-robin assignment
- Each gateway handles 50K-200K connections
- Cross-gateway message routing via pub/sub (Redis, NATS)

### Message Throughput

**Bottlenecks and solutions:**

| Bottleneck | Solution |
|------------|----------|
| Write throughput | Partition by channel_id (Cassandra, DynamoDB, sharded PostgreSQL) |
| Fan-out for large channels | Fan-out on read for 1000+ member channels |
| Cross-server message routing | Partitioned pub/sub (NATS with subjects, Kafka with partitions) |
| Unread counter updates | Batch counter updates, eventual consistency |
| Push notification volume | Batch pushes, deduplicate, rate limit |
| Search indexing | Async indexing pipeline (Kafka → search indexer → Elasticsearch) |

### Discord's Scale (Reference Architecture)

Discord handles 19M+ concurrent users and billions of messages:

- **Connection gateway**: Custom Elixir gateway fleet (BEAM VM — millions of lightweight processes)
- **Message storage**: Cassandra → ScyllaDB migration (better performance per node)
- **Message routing**: Custom pub/sub service
- **Presence**: Dedicated presence service with lazy guilds
- **Search**: Elasticsearch cluster
- **Voice**: Custom media servers (originally WebRTC SFU, now enhanced)

### Slack's Scale (Reference Architecture)

- **Backend**: PHP (legacy) + Java + Go services
- **Connection**: WebSocket gateway (Flannel — custom Go service)
- **Message storage**: MySQL (sharded by workspace) + Vitess
- **Message routing**: Custom job queue + Kafka
- **Search**: Elasticsearch (per-workspace sharding)
- **Real-time**: Flannel gateway + Redis for pub/sub

### WhatsApp's Scale (Reference Architecture)

- **Backend**: Erlang/BEAM VM — handles massive concurrency natively
- **Protocol**: Custom binary protocol over TCP (originally XMPP-derived)
- **Message storage**: Mnesia (Erlang distributed DB) + custom storage
- **Scale**: 2B+ users, ~100B messages/day
- **Key design**: Minimal server-side storage (messages deleted after delivery), E2EE
- **Infrastructure**: Remarkably small team and server fleet relative to user count (BEAM efficiency)
