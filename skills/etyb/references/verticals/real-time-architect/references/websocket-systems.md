# WebSocket Systems — Deep Reference

**Always use `WebSearch` to verify framework versions, managed service pricing, and browser support before giving advice. The real-time infrastructure space evolves rapidly with new entrants and protocol updates. Last verified: April 2026.**

## Table of Contents
1. [WebSocket Protocol Fundamentals](#1-websocket-protocol-fundamentals)
2. [Server Framework Selection](#2-server-framework-selection)
3. [Managed WebSocket Services](#3-managed-websocket-services)
4. [SSE vs WebSocket vs WebTransport](#4-sse-vs-websocket-vs-webtransport)
5. [WebTransport and HTTP/3](#5-webtransport-and-http3)
6. [Connection Lifecycle Management](#6-connection-lifecycle-management)
7. [Scaling WebSocket Connections](#7-scaling-websocket-connections)
8. [Pub/Sub Backends for Cross-Server Routing](#8-pubsub-backends-for-cross-server-routing)
9. [Edge Computing for Real-Time](#9-edge-computing-for-real-time)
10. [Self-Hosted Real-Time Servers](#10-self-hosted-real-time-servers)
11. [Binary Protocols and Serialization](#11-binary-protocols-and-serialization)
12. [WebSocket Security](#12-websocket-security)
13. [Monitoring and Observability](#13-monitoring-and-observability)

---

## 1. WebSocket Protocol Fundamentals

### The WebSocket Handshake

WebSocket starts as an HTTP/1.1 Upgrade request. The client sends:
```
GET /ws HTTP/1.1
Host: example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Sec-WebSocket-Protocol: chat, superchat
```

Server responds with 101 Switching Protocols, and the connection is upgraded to a persistent, full-duplex TCP connection. After the handshake, both sides can send frames independently.

### Frame Types

| Opcode | Type | Use |
|--------|------|-----|
| 0x0 | Continuation | Multi-frame messages |
| 0x1 | Text | UTF-8 text data |
| 0x2 | Binary | Binary data |
| 0x8 | Close | Connection close |
| 0x9 | Ping | Keepalive from either side |
| 0xA | Pong | Response to ping |

### WebSocket over HTTP/2 (RFC 8441)

RFC 8441 enables WebSocket connections over HTTP/2, allowing multiplexing WebSocket connections alongside regular HTTP requests on a single TCP connection. Benefits:
- Single TCP connection for both HTTP and WebSocket traffic
- Reduced connection overhead for multiple WebSocket streams
- Better utilization of existing HTTP/2 infrastructure
- Support in modern browsers and servers (nginx 1.25+, Envoy, Caddy)

### WebSocket over HTTP/3 (QUIC)

WebSocket-over-HTTP/3 extends the concept to QUIC, eliminating TCP head-of-line blocking. Browser support is still emerging — for HTTP/3 real-time, WebTransport is the preferred path.

### Key Protocol Characteristics

- **No built-in multiplexing**: One WebSocket connection = one TCP stream. Multiple logical channels must be multiplexed at the application layer (or use HTTP/2 WebSocket).
- **No built-in authentication**: Auth must happen during the HTTP handshake (cookies, tokens in query string) or as the first message after connection.
- **No built-in reconnection**: Must be implemented by the client.
- **No built-in message ordering guarantee across servers**: TCP guarantees order within one connection, but messages routed via pub/sub between servers may arrive out of order.
- **Client-to-server frames are masked**: XOR mask to prevent cache poisoning attacks through intermediaries.

---

## 2. Server Framework Selection

### Node.js

**ws (v8+)**
- The de facto Node.js WebSocket library — minimal, fast, spec-compliant
- Handles ~50K concurrent connections per process (depends on message rate)
- No opinions on protocol, rooms, or broadcasting — you build those yourself
- Best for: Custom protocols, maximum control, when you want the thinnest abstraction
- Limitations: No built-in rooms, broadcasting, or reconnection logic

**uWebSockets.js**
- C++ core (uWebSockets) with Node.js bindings — 5-10x faster than ws
- Handles ~100K-300K concurrent connections per process
- Built-in pub/sub, HTTP server, SSL termination
- Best for: High-performance applications, when throughput matters
- Limitations: Different API from standard Node.js patterns, smaller community, author opinionated about issues

**Socket.IO (v4+)**
- Full-featured real-time framework with rooms, namespaces, acknowledgments, fallback transports
- Built-in reconnection, binary support, multiplexing via namespaces
- Redis adapter for horizontal scaling (socket.io-adapter-redis)
- Best for: Rapid prototyping, teams new to WebSocket, when you want batteries included
- Limitations: Proprietary protocol on top of WebSocket (not plain WebSocket), slightly higher overhead, ~30K connections per process
- Note: Socket.IO is NOT just WebSocket — it has its own handshake, packet format, and engine.io transport layer. A plain WebSocket client cannot connect to a Socket.IO server and vice versa.

**Bun Native WebSocket**
- Bun's built-in WebSocket server — fastest JS runtime for WebSocket
- Handles 500K+ concurrent connections (Bun benchmarks)
- Built-in pub/sub with topics, per-message compression
- Best for: New projects willing to adopt Bun, performance-critical applications
- Limitations: Bun ecosystem still maturing, fewer production deployments than Node.js

**Deno WebSocket**
- Native WebSocket in Deno — standards-based, secure by default
- Deno Deploy supports WebSocket at the edge
- Best for: Deno projects, edge-deployed WebSocket services

### Go

**Gorilla WebSocket** (maintained community fork — `github.com/coder/websocket` or `nhooyr.io/websocket`)
- The original gorilla/websocket is archived, but community forks are actively maintained
- `nhooyr.io/websocket` (by Coder) is the recommended replacement — context-aware, net/http compatible
- Handles 100K-500K+ connections per server (goroutine-per-connection, lightweight)
- Best for: High-connection-count services, Go-based infrastructure

**Centrifugo** (Go)
- Not a library but a standalone real-time messaging server written in Go
- Covered in section 10 (Self-Hosted Real-Time Servers)

### Rust

**Actix-Web WebSocket**
- Part of the Actix-Web framework — actor-based, high performance
- Each WebSocket connection is an actor with its own lifecycle
- Best for: When you need both HTTP and WebSocket in one Rust service

**Axum + tokio-tungstenite**
- Modern Rust async WebSocket using Tokio ecosystem
- Integrates with Axum's extract/response patterns
- Best for: New Rust projects using the Tokio/Axum stack

**Performance note**: Rust WebSocket servers routinely handle 500K-1M+ connections per server with sub-millisecond processing latency.

### Python

**websockets**
- asyncio-based, standards-compliant Python WebSocket library
- Best for: Python async services, scripts, and tooling
- Limitations: Python's GIL and async overhead limit throughput — ~5K-10K connections per process for interactive workloads

**FastAPI WebSocket**
- WebSocket endpoints within FastAPI using Starlette's WebSocket support
- Best for: Adding WebSocket to an existing FastAPI application
- Limitations: Same Python performance constraints

### Elixir/Erlang

**Phoenix Channels**
- Built on the BEAM VM, designed for massive concurrency (millions of lightweight processes)
- Handles 2M+ concurrent connections per server (Phoenix benchmark)
- Built-in presence system, pub/sub, topic-based channels
- Used by Discord (pre-Rust migration) for real-time
- Best for: Systems requiring massive connection counts with complex per-connection logic

### Framework Selection Decision Matrix

| Factor | ws (Node) | uWS.js | Socket.IO | Bun WS | Go (nhooyr) | Rust (Axum) | Phoenix |
|--------|-----------|--------|-----------|--------|-------------|-------------|---------|
| Connections/server | ~50K | ~200K | ~30K | ~500K | ~300K | ~1M | ~2M |
| Latency overhead | Low | Very low | Medium | Very low | Low | Very low | Low |
| Batteries included | None | Pub/Sub | Full suite | Pub/Sub | None | None | Full suite |
| Learning curve | Low | Medium | Low | Low | Medium | High | Medium |
| Ecosystem/community | Largest | Small | Large | Growing | Large | Growing | Medium |
| Production track record | Extensive | Moderate | Extensive | Early | Extensive | Growing | Discord, Pinterest |
| Best for | Custom protocols | Max performance | Rapid dev | Performance + JS | Go services | Max perf + safety | Massive concurrency |

---

## 3. Managed WebSocket Services

### Ably

- **Model**: Pub/sub with channels, presence, history, push notifications
- **Scale**: Enterprise-grade, handles millions of connections
- **Features**: Message ordering guarantees, exactly-once delivery semantics, message history and rewind, presence, push notifications, webhooks, MQTT/SSE/WebSocket transports
- **Protocol**: Custom protocol over WebSocket, also supports SSE and MQTT
- **Pricing**: Per-message + per-connection minute pricing
- **Differentiator**: Strongest delivery guarantees (exactly-once with idempotent publishing), message ordering, and data integrity focus
- **Best for**: Financial data, IoT, applications where message delivery guarantees matter

### Pusher

- **Model**: Channels with events, presence channels, private channels
- **Scale**: Up to 500K concurrent connections (enterprise plan)
- **Features**: Client events, webhooks, presence, encrypted channels, rate limiting
- **Protocol**: Custom protocol over WebSocket
- **Pricing**: Per-connection + per-message pricing, tiered plans
- **Differentiator**: Simplest API, fastest time-to-integration, wide SDK support
- **Best for**: Adding real-time to an existing app quickly, small-medium scale

### PubNub

- **Model**: Pub/sub with channels, presence, message persistence
- **Scale**: Enterprise-grade, global edge network
- **Features**: Message persistence, mobile push, presence, access management, functions (serverless), signals (ephemeral messages)
- **Protocol**: Custom protocol over WebSocket/long-polling
- **Pricing**: Per-transaction pricing (send + receive counted separately)
- **Differentiator**: Global edge network (15+ PoPs), strongest mobile push integration, message persistence
- **Best for**: Chat, mobile apps, IoT, global low-latency delivery

### Supabase Realtime

- **Model**: PostgreSQL-native real-time via CDC (Change Data Capture), broadcast channels, presence
- **Scale**: Managed Supabase plans or self-hosted
- **Features**: Database change streams (INSERT/UPDATE/DELETE notifications), broadcast channels, presence, Row Level Security integration
- **Protocol**: Phoenix Channels over WebSocket (Elixir-based)
- **Differentiator**: Deep PostgreSQL integration — real-time derived from your existing database writes, no separate pub/sub needed
- **Best for**: Supabase users, applications where real-time is driven by database changes

### Convex

- **Model**: Reactive database — queries automatically update when underlying data changes
- **Scale**: Managed platform
- **Features**: Reactive queries (subscriptions to query results), mutations, actions, scheduled functions
- **Protocol**: Custom reactive protocol
- **Differentiator**: No separate real-time layer needed — the database IS the real-time layer. Queries are functions that re-run when dependencies change.
- **Best for**: New projects that want real-time baked into the data layer, full-stack TypeScript

### AWS API Gateway WebSocket

- **Model**: Serverless WebSocket with Lambda integration
- **Scale**: Managed, auto-scaling
- **Features**: Route-based message handling (connect/disconnect/message routes), integration with Lambda, DynamoDB, SQS
- **Pricing**: Per-connection-minute + per-message
- **Differentiator**: Serverless — no servers to manage, pay-per-use
- **Limitations**: Cold start latency for Lambda handlers, 500K connections per API, 128KB max message size, 2-hour max connection duration (idle timeout 10 min)
- **Best for**: Serverless architectures, infrequent real-time (notifications), AWS-native stacks

### Azure Web PubSub / SignalR

- **Model**: SignalR is the hub-based framework; Web PubSub is the low-level pub/sub service
- **Scale**: 1M+ connections per unit
- **Features**: Groups, user-specific messaging, connection events, upstream webhooks
- **Pricing**: Per-unit (connection capacity) + per-message
- **Best for**: .NET/Azure ecosystems, enterprise applications

### Service Selection Decision Matrix

| Factor | Ably | Pusher | PubNub | Supabase RT | Convex | AWS APIGW WS |
|--------|------|--------|--------|-------------|--------|--------------|
| Delivery guarantee | Exactly-once | At-most-once | At-least-once | At-most-once | Reactive | At-most-once |
| Message ordering | Guaranteed | Per-channel | Per-channel | Per-table | N/A (reactive) | No guarantee |
| Presence | Yes | Yes | Yes | Yes | Custom | Custom |
| Message history | Yes (rewind) | No | Yes (persist) | Via database | Via database | Custom |
| Global edge | Yes | Yes | Yes (15+ PoPs) | No | No | Per-region |
| Max connections | Millions | 500K | Millions | Varies | Varies | 500K/API |
| Self-host option | No | No | No | Yes | No | No |
| Serverless-friendly | Webhooks | Webhooks | Functions | Edge Functions | Native | Lambda |
| Best for | Mission-critical | Simple + fast | Chat + mobile | DB-driven RT | Full-stack | Serverless |

---

## 4. SSE vs WebSocket vs WebTransport

### When to Use SSE

SSE is the right choice when:
- **Server→client only**: Live feeds, notifications, dashboards, stock tickers, log streaming
- **Simplicity**: No special server infrastructure — works with standard HTTP servers, load balancers, CDNs, and reverse proxies
- **Auto-reconnection**: Built into the EventSource API — the browser reconnects automatically with `Last-Event-ID`
- **HTTP semantics**: Authentication via cookies/headers works naturally (unlike WebSocket where auth happens post-upgrade)
- **Text data**: Events are UTF-8 text (JSON, HTML fragments)

SSE implementation:
```
// Server response
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

id: 1
event: update
data: {"price": 142.50, "symbol": "AAPL"}

id: 2
event: update
data: {"price": 142.52, "symbol": "AAPL"}
```

**HTTP/2 eliminates the 6-connection limit**: Under HTTP/1.1, browsers limit to 6 connections per domain, so 6 SSE streams exhaust the budget. With HTTP/2 (universal in 2026), all streams multiplex over one TCP connection — no practical limit.

### When to Use WebSocket Over SSE

- **Bidirectional**: Client sends messages frequently (chat, collaboration, games)
- **Binary data**: File chunks, audio/video frames, compressed data
- **Custom protocols**: You need a specific message format beyond SSE's `data:` fields
- **High frequency**: Sub-100ms message intervals where SSE's text parsing overhead matters

### When to Use WebTransport Over Both

- **Unreliable delivery needed**: Gaming (stale position updates should be dropped, not retransmitted)
- **Multiple streams**: Independent data channels that shouldn't block each other
- **0-RTT connection**: QUIC enables connecting without the TCP+TLS handshake delay
- **No head-of-line blocking**: Lost packet on one stream doesn't delay others (unlike TCP/WebSocket)

---

## 5. WebTransport and HTTP/3

### What WebTransport Is

WebTransport is a web API for bidirectional communication over HTTP/3 (QUIC). It provides:

- **Bidirectional streams**: Reliable, ordered streams (like WebSocket but multiplexed)
- **Unidirectional streams**: Server→client or client→server (like SSE but over QUIC)
- **Datagrams**: Unreliable, unordered messages (like UDP but through the browser)

This is significant because it's the first time browsers can send unreliable, unordered data — critical for gaming, real-time audio/video, and any scenario where stale data should be dropped rather than retransmitted.

### Browser Support (2026)

| Browser | Status |
|---------|--------|
| Chrome/Chromium | Shipped (Chrome 97+) |
| Edge | Shipped (same as Chrome) |
| Firefox | Shipped (Firefox 114+) |
| Safari | In development — behind a flag. Check `WebSearch` for latest. |

### Server Libraries

| Language | Library | Notes |
|----------|---------|-------|
| Go | `quic-go/webtransport-go` | Mature, used in production |
| Rust | `wtransport` | Active development |
| Node.js | Experimental support via `@aspect-build/rules_webtransport` | Less mature |
| Python | `aioquic` | QUIC + WebTransport support |
| C/C++ | `msquic` (Microsoft), `ngtcp2` | Production-grade QUIC |

### When to Use WebTransport vs WebSocket

| Scenario | WebSocket | WebTransport | Recommendation |
|----------|-----------|--------------|----------------|
| Chat/messaging | Works perfectly | Overkill | WebSocket |
| Notifications | Works perfectly | Overkill | SSE or WebSocket |
| Collaborative editing | Works well | Marginal benefit | WebSocket (broader support) |
| Browser game (casual) | Adequate | Better (unreliable datagrams) | WebSocket (unless latency-critical) |
| Browser game (competitive) | Limiting (TCP HOL) | Ideal (datagrams + streams) | WebTransport (if Safari not needed) |
| Real-time audio/video | Use WebRTC | Use WebRTC | WebRTC (media-optimized) |
| Live dashboard | Works well | Overkill | SSE |

---

## 6. Connection Lifecycle Management

### Heartbeats and Keepalives

WebSocket connections can silently die (mobile network switch, NAT timeout, proxy timeout) without triggering a TCP close. Heartbeats detect dead connections:

**Application-level ping/pong:**
```
Server sends: {"type": "ping", "ts": 1713100800000}
Client responds: {"type": "pong", "ts": 1713100800000}
```

**WebSocket protocol ping/pong (opcode 0x9/0xA):**
- Built into the protocol — server sends a Ping frame, client's browser automatically responds with Pong
- Most WebSocket libraries support this natively
- Doesn't trigger application-level message handlers

**Recommended intervals:**
- Desktop/broadband: 30-60 second intervals, 10-second timeout
- Mobile: 15-30 second intervals (cellular NATs timeout aggressively — some as low as 30 seconds)
- Aggressive (gaming): 5-10 second intervals

**Important**: Both sides should send heartbeats. Server detects dead clients. Client detects dead servers (or network loss). If 2-3 consecutive heartbeats are missed, consider the connection dead and trigger reconnection.

### Reconnection Strategies

**Exponential backoff with jitter:**
```
base_delay = 1000ms
max_delay = 30000ms
attempt = 0

delay = min(base_delay * 2^attempt, max_delay) + random(0, 1000ms)
```

Jitter is critical — without it, when a server restarts, all clients reconnect simultaneously (thundering herd). Full jitter: `delay = random(0, min(base_delay * 2^attempt, max_delay))`.

**Reconnection state machine:**
```
CONNECTED → (connection lost) → RECONNECTING → (backoff delay) → CONNECTING → CONNECTED
                                      ↓
                              (max retries exceeded)
                                      ↓
                                 DISCONNECTED
                                 (manual retry only)
```

**State recovery on reconnect:**
1. Client stores the last received sequence number / event ID
2. On reconnect, client sends: `{"type": "resume", "last_seq": 42}`
3. Server replays missed messages from sequence 42 onwards (from buffer or message store)
4. If the gap is too large (buffer expired), server sends full state snapshot instead

### Connection Draining for Zero-Downtime Deploys

During deployments, existing connections must be gracefully migrated:

1. **Mark server as draining**: Stop accepting new connections (remove from load balancer)
2. **Send drain notification**: Tell connected clients to reconnect elsewhere
   ```json
   {"type": "system", "action": "reconnect", "reason": "server_drain", "delay_ms": 5000}
   ```
3. **Stagger reconnections**: Include a random delay (0-30 seconds) per client to avoid thundering herd
4. **Wait for connections to close**: Set a deadline (60-120 seconds)
5. **Force close remaining**: Send WebSocket close frame (1001 Going Away) to stragglers
6. **Shut down server**: Now safe to terminate

### Connection Authentication

**Token in query string (simple but visible in logs):**
```
ws://example.com/ws?token=eyJhbGciOiJIUzI1NiJ9...
```
- Pro: Works immediately on connection
- Con: Token visible in server access logs, browser history, referrer headers

**Token in first message (secure, slight delay):**
```
1. Client connects (unauthenticated)
2. Client sends: {"type": "auth", "token": "eyJ..."}
3. Server validates, upgrades connection to authenticated
4. Server starts sending data
```
- Pro: Token not in URL
- Con: Brief unauthenticated window — server must buffer/reject messages until auth completes

**Ticket-based (most secure for WebSocket):**
```
1. Client calls REST API: POST /ws/ticket (with Bearer token)
2. Server returns: {"ticket": "abc123", "expires": "2024-01-01T00:05:00Z"}
3. Client connects: ws://example.com/ws?ticket=abc123
4. Server validates ticket (single-use, short-lived), establishes authenticated connection
```
- Pro: Token never in WebSocket URL, ticket is single-use and short-lived
- Con: Extra HTTP round-trip before connecting

---

## 7. Scaling WebSocket Connections

### The Scaling Challenge

WebSocket connections are stateful and persistent — each connection is bound to a specific server. This fundamentally differs from stateless HTTP where any server can handle any request.

**Per-server connection limits:**
- File descriptors: Default ulimit is often 1024 — increase to 100K+ for WebSocket servers
- Memory: Each connection uses 2-10KB (depending on buffering). 100K connections = 200MB-1GB just for connection state
- CPU: Mostly idle connections — CPU bound by message rate, not connection count
- Kernel: `net.core.somaxconn`, `net.ipv4.tcp_max_syn_backlog` tuning for many connections
- Ephemeral ports: If proxying, each proxied connection uses an ephemeral port on the proxy (limit ~28K per IP pair)

### Load Balancing for WebSocket

**Layer 7 (Application Layer) — Recommended:**
- Nginx: `proxy_pass` with `Upgrade` and `Connection` headers, `ip_hash` or `hash $request_uri` for sticky sessions
- HAProxy: `balance source` for sticky sessions, `timeout tunnel` for long-lived connections
- Envoy: First-class WebSocket support, connection-aware load balancing, automatic protocol detection
- Cloud: AWS ALB (native WebSocket), GCP HTTP(S) LB, Azure Application Gateway

**Sticky sessions vs connection-aware routing:**
- **Sticky sessions (simple)**: Route client to same server based on cookie/IP. Works but doesn't balance evenly if connections have different lifetimes.
- **Connection-aware routing**: Load balancer tracks connection count per backend and routes new connections to least-loaded server. Envoy and modern load balancers support this.

### Horizontal Scaling Architecture

```
                        ┌─────────────┐
                        │  Load       │
Clients ──────────────▶ │  Balancer   │
                        │  (L7/sticky)│
                        └──────┬──────┘
                    ┌──────────┼──────────┐
                    ▼          ▼          ▼
             ┌──────────┐┌──────────┐┌──────────┐
             │  WS      ││  WS      ││  WS      │
             │ Server 1 ││ Server 2 ││ Server 3 │
             │ (30K     ││ (25K     ││ (28K     │
             │  conns)  ││  conns)  ││  conns)  │
             └────┬─────┘└────┬─────┘└────┬─────┘
                  │           │           │
                  └───────────┼───────────┘
                              │
                       ┌──────▼──────┐
                       │  Pub/Sub    │
                       │  (Redis /   │
                       │   NATS)     │
                       └─────────────┘
```

**Cross-server message routing**: When User A (on Server 1) sends a message to a room that User B (on Server 2) is in, the message must route through the pub/sub layer:

1. Server 1 receives message from User A
2. Server 1 publishes to Redis/NATS channel `room:42`
3. Server 2 (subscribed to `room:42`) receives the message
4. Server 2 delivers to User B's WebSocket connection

### Autoscaling WebSocket Servers

Standard CPU/memory-based autoscaling doesn't work well for WebSocket servers because:
- Connections are mostly idle (low CPU) but consume memory and file descriptors
- Scaling down kills connections (disruptive)

**Connection-count-based scaling:**
- Scale up when average connections per server exceeds threshold (e.g., 70% of capacity)
- Scale down cautiously: drain connections before removing servers, use longer cooldown periods
- Custom metrics: Publish connection count to CloudWatch/Prometheus, use HPA (Kubernetes) or target tracking (AWS)

**Kubernetes HPA example:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  metrics:
  - type: Pods
    pods:
      metric:
        name: websocket_connections_total
      target:
        type: AverageValue
        averageValue: "30000"  # Scale when avg exceeds 30K connections per pod
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
      policies:
      - type: Pods
        value: 1  # Remove one pod at a time (drain gracefully)
        periodSeconds: 120
```

---

## 8. Pub/Sub Backends for Cross-Server Routing

### Redis Pub/Sub

- **Model**: Fire-and-forget pub/sub — no persistence, no replay
- **Throughput**: ~1M messages/second per Redis instance
- **Pattern**: Subscribe to channels matching room/topic patterns
- **Limitations**: Messages are lost if no subscriber is listening, no persistence, single-threaded
- **Redis Cluster note**: Pub/Sub in Redis Cluster broadcasts to ALL nodes (not sharded) — this limits scale. Use Redis Streams or NATS for larger deployments.
- **Best for**: Small-medium scale (<50K connections), simple fan-out, ephemeral messages

**Redis Streams** (persistent alternative):
- Append-only log with consumer groups — messages persist and can be replayed
- Supports consumer groups for load-balanced consumption
- Better for: Message history, catch-up on reconnect, reliable delivery

### NATS

- **Model**: Subject-based pub/sub with optional persistence (JetStream)
- **Throughput**: 10M+ messages/second per server, cluster scales linearly
- **Pattern**: Hierarchical subjects (`chat.room.42`, `game.match.abc`), wildcard subscriptions
- **Features**: Request/reply, queue groups (load balanced consumers), JetStream for persistence
- **NATS JetStream**: Adds persistence, exactly-once delivery, replay, consumer tracking — like Kafka but simpler
- **Best for**: Medium-large scale, when you need more than Redis Pub/Sub but less than Kafka

### Kafka

- **Model**: Partitioned, persistent event log with consumer groups
- **Throughput**: 100K+ messages/second per partition, thousands of partitions
- **Pattern**: Topics with partitions, consumer groups for parallel consumption
- **Features**: Persistence (configurable retention), exactly-once semantics, compacted topics for state
- **Latency**: Higher than Redis/NATS (10-50ms typical) — batch-oriented design
- **Limitations**: Operational complexity (ZooKeeper or KRaft), not designed for per-user pub/sub (partition count limit)
- **Best for**: Persistent event streams, audit trails, high-throughput pipelines — NOT for ephemeral real-time fan-out

### Comparison

| Factor | Redis Pub/Sub | Redis Streams | NATS | NATS JetStream | Kafka |
|--------|--------------|---------------|------|----------------|-------|
| Persistence | No | Yes | No | Yes | Yes |
| Ordering | Per-channel | Per-stream | Per-subject | Per-stream | Per-partition |
| Replay | No | Yes | No | Yes | Yes |
| Throughput | ~1M msg/s | ~500K msg/s | ~10M msg/s | ~5M msg/s | ~100K msg/s/partition |
| Latency | <1ms | <1ms | <1ms | 1-5ms | 10-50ms |
| Ops complexity | Low | Low | Low | Medium | High |
| Best for | Ephemeral fan-out | Reliable fan-out | High-throughput RT | Reliable RT | Event streams |

---

## 9. Edge Computing for Real-Time

### Cloudflare Durable Objects

- **Model**: Single-threaded JavaScript objects with persistent state and WebSocket support
- **Key concept**: Each Durable Object has a unique ID, lives on one edge server, and all connections to that object route to the same instance — providing strong consistency without distributed coordination
- **WebSocket**: Native WebSocket handling within the Durable Object — accept connections, send/receive messages, manage state in a single process
- **State**: Transactional key-value storage local to the object, SQLite storage for complex queries
- **Scaling**: One DO per "room" or "document" — thousands of DOs across the edge network
- **Limitations**: Single-threaded (one DO handles ~100-1000 concurrent connections), 128MB memory per DO, DO can migrate between edge locations
- **Best for**: Collaborative editing, game rooms, presence, any room-based real-time feature
- **Pricing**: Per-request + per-millisecond of compute + per-GB storage

**Pattern: One Durable Object per room/document**
```
Room "project-42" → Durable Object (lives at nearest edge)
  ├─ WebSocket connections from users
  ├─ In-memory state (document, presence)
  └─ Persistent state (saved edits, history)
```

### PartyKit (now part of Cloudflare)

- Built on Cloudflare Workers + Durable Objects — higher-level abstraction for real-time
- Party = a Durable Object with a simpler API for WebSocket management
- Built-in: room-based routing, connection management, hibernation (idle parties sleep to save cost)
- Y-Sweet: Yjs CRDT server built on PartyKit for collaborative editing
- Best for: Quick start with edge-based real-time without managing Durable Objects directly

### Vercel / Netlify Edge

- Edge Functions can handle SSE streams
- No persistent WebSocket support at the edge (connections must go to an origin server or external service)
- Can use edge functions as a gateway that proxies to a WebSocket service

### Fly.io

- Full VM/container hosting at the edge — run any WebSocket server close to users
- Fly Machines: spin up/down per region based on demand
- Replay proxy: automatically routes requests to the region where the app's state lives
- Best for: Running traditional WebSocket servers at global edge locations

---

## 10. Self-Hosted Real-Time Servers

### Centrifugo

- **Language**: Go
- **Model**: Standalone real-time messaging server — you run it alongside your application
- **Protocol**: Custom protocol over WebSocket, SSE, HTTP streaming, GRPC; client SDKs for JS, Go, Python, Dart, Swift, Java
- **Features**: Channels (public, private, presence), history and recovery (catch up on reconnect), presence (who's in a channel), server-side subscriptions, JWT authentication, connection/channel tokens, proxy to your backend for auth/connect/publish events, Redis/Kafka/NATS/Tarantool engine options
- **Scaling**: Connects to Redis/NATS/Kafka as a broker — multiple Centrifugo nodes share state
- **Performance**: Handles 500K+ connections per node, millions with clustering
- **Differentiator**: Production-ready, batteries-included real-time server that doesn't require you to write WebSocket handling code. Your backend is HTTP-only; Centrifugo handles all real-time connections.
- **Best for**: Adding real-time to an existing HTTP backend without rewriting it, medium-to-large scale

**Architecture with Centrifugo:**
```
Client ←WebSocket→ Centrifugo ←HTTP Proxy→ Your App Server ←→ Database
                       ↕
                   Redis/NATS
                   (clustering)
```

### Mercure

- **Language**: Go
- **Model**: SSE-based real-time hub — designed for hypermedia APIs
- **Protocol**: Server-Sent Events (standard EventSource API), also supports WebSocket
- **Features**: JWT-based authorization per topic, auto-discovery via Link headers, publish via POST
- **Best for**: Adding real-time updates to REST APIs, Symfony/PHP backends, SSE-first architectures
- **Limitations**: SSE-primary (unidirectional), less suited for bidirectional real-time

### Soketi

- **Model**: Open-source, self-hosted Pusher-compatible server
- **Protocol**: Pusher protocol — existing Pusher client SDKs work unchanged
- **Language**: Node.js (uWebSockets.js under the hood)
- **Best for**: Migrating off Pusher to self-hosted, Pusher SDK compatibility

---

## 11. Binary Protocols and Serialization

### Why Binary Over JSON

JSON is human-readable but costly for high-frequency real-time:
- **Parsing overhead**: JSON.parse() is 5-10x slower than binary deserialization
- **Size**: JSON is 2-5x larger than binary equivalents (field names repeated, number encoding)
- **No schema**: Typos in field names are silent bugs; no type safety across client/server

### Protocol Buffers (Protobuf)

- **Best for**: Structured messages with a schema, cross-language compatibility
- **Size**: 3-10x smaller than JSON
- **Speed**: 20-100x faster than JSON parsing
- **Schema evolution**: Forward/backward compatible field additions
- **Limitation**: Requires `.proto` files and code generation, not self-describing

### MessagePack

- **Best for**: Drop-in JSON replacement — same data model, binary encoding
- **Size**: 1.5-2x smaller than JSON
- **Speed**: 3-5x faster than JSON parsing
- **No schema**: Same data model as JSON (maps, arrays, strings, numbers)
- **Advantage**: No code generation needed — swap `JSON.stringify/parse` for `msgpack.encode/decode`

### FlatBuffers

- **Best for**: Zero-copy access to serialized data — no deserialization step
- **Speed**: Access fields directly from the binary buffer without parsing
- **Use case**: Gaming (read position data without deserializing the whole message), performance-critical paths
- **Limitation**: More complex API than Protobuf, larger serialized size than Protobuf

### Comparison

| Factor | JSON | MessagePack | Protobuf | FlatBuffers |
|--------|------|-------------|----------|-------------|
| Size (relative) | 1x | 0.5-0.7x | 0.2-0.3x | 0.3-0.5x |
| Parse speed (relative) | 1x | 3-5x | 20-100x | Infinite (zero-copy) |
| Schema required | No | No | Yes (.proto) | Yes (.fbs) |
| Human readable | Yes | No | No | No |
| Schema evolution | Fragile | Fragile | Excellent | Excellent |
| Browser support | Native | Library | Library (protobuf.js) | Library |
| Best for | Debugging, low freq | Drop-in perf boost | Production protocols | Gaming, zero-copy |

---

## 12. WebSocket Security

### Origin Validation

Always validate the `Origin` header during the WebSocket handshake:
```javascript
server.on('upgrade', (request, socket, head) => {
  const origin = request.headers.origin;
  if (!allowedOrigins.includes(origin)) {
    socket.write('HTTP/1.1 403 Forbidden\r\n\r\n');
    socket.destroy();
    return;
  }
  // Proceed with upgrade
});
```

### Rate Limiting

WebSocket connections bypass traditional HTTP rate limiting. Implement:

1. **Connection rate limiting**: Max N new connections per IP per minute (prevents connection flooding)
2. **Message rate limiting**: Max N messages per connection per second (prevents spam)
3. **Payload size limiting**: Max message size (prevents memory exhaustion)
4. **Channel rate limiting**: Max N subscriptions per connection (prevents resource exhaustion)

### DDoS Protection

WebSocket connections are attractive DDoS targets because:
- Each connection holds server resources (memory, file descriptor)
- Slowloris-style attacks: open connections and send data slowly
- Connection flooding: open thousands of connections and do nothing

**Mitigations:**
- Idle timeout: Close connections that don't authenticate within N seconds
- Connection limits per IP: Max connections from a single IP
- WebSocket-aware WAF: Cloudflare, AWS WAF can inspect WebSocket traffic
- Authentication before resource allocation: Don't allocate rooms/subscriptions until JWT is validated

### Encryption

- Always use `wss://` (WebSocket Secure = WebSocket over TLS) in production
- Never send credentials over `ws://` (unencrypted)
- TLS termination at the load balancer is standard — internal traffic can be `ws://` if the network is trusted

---

## 13. Monitoring and Observability

### Key Metrics

**Connection metrics:**
- `websocket_connections_active`: Current open connections (gauge)
- `websocket_connections_total`: Total connections since server start (counter)
- `websocket_connection_duration_seconds`: How long connections live (histogram)
- `websocket_connections_rejected_total`: Rejected connections by reason (counter)

**Message metrics:**
- `websocket_messages_received_total`: Messages from clients (counter)
- `websocket_messages_sent_total`: Messages to clients (counter)
- `websocket_message_size_bytes`: Message payload sizes (histogram)
- `websocket_message_latency_seconds`: Time from receive to all deliveries (histogram)

**Fan-out metrics:**
- `websocket_fanout_ratio`: Messages delivered / messages received (gauge)
- `websocket_room_size`: Number of connections per room (histogram)
- `websocket_pubsub_latency_seconds`: Time for cross-server message routing (histogram)

**Health metrics:**
- `websocket_heartbeat_missed_total`: Missed heartbeats before disconnect (counter)
- `websocket_reconnections_total`: Client reconnection events (counter)
- `websocket_backpressure_drops_total`: Messages dropped due to slow consumers (counter)

### Distributed Tracing for Real-Time

Assign a trace ID to each message and propagate it:
```json
{
  "type": "message",
  "trace_id": "abc-123",
  "channel": "room:42",
  "payload": "Hello",
  "ts": 1713100800000
}
```

Trace the full path: client → gateway → pub/sub → gateway → client. Measure each hop's latency independently. This is critical for debugging "messages are slow" — is it serialization, pub/sub, fan-out, or client rendering?
