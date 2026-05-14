# Gaming Backends — Deep Reference

**Always use `WebSearch` to verify game server framework versions, orchestration platform pricing, and engine compatibility before giving advice. The multiplayer gaming infrastructure space is evolving rapidly. Last verified: April 2026.**

## Table of Contents
1. [Game Server Architecture Fundamentals](#1-game-server-architecture-fundamentals)
2. [Netcode Patterns](#2-netcode-patterns)
3. [State Synchronization](#3-state-synchronization)
4. [Game Server Frameworks](#4-game-server-frameworks)
5. [Networking Protocols for Games](#5-networking-protocols-for-games)
6. [Game Server Orchestration](#6-game-server-orchestration)
7. [Matchmaking Systems](#7-matchmaking-systems)
8. [Tick Rate and Simulation](#8-tick-rate-and-simulation)
9. [Anti-Cheat Architecture](#9-anti-cheat-architecture)
10. [MMO-Specific Patterns](#10-mmo-specific-patterns)
11. [Browser-Based Multiplayer](#11-browser-based-multiplayer)
12. [Real-Time Leaderboards and Analytics](#12-real-time-leaderboards-and-analytics)

---

## 1. Game Server Architecture Fundamentals

### Server-Authoritative vs Client-Authoritative

**Server-authoritative (standard for competitive games):**
- Server is the single source of truth for all game state
- Clients send inputs (move forward, shoot, jump); server simulates and broadcasts results
- Prevents most cheating — client can't lie about game state
- Higher latency feel without client-side prediction
- Used by: Fortnite, Valorant, Counter-Strike, Overwatch, every serious competitive game

**Client-authoritative (rare, specific use cases):**
- Clients own their state and broadcast updates
- Server validates but trusts clients more
- Lower latency, simpler server logic
- Vulnerable to cheating (speed hacks, teleportation, damage modification)
- Used by: Some mobile games, cooperative PvE games, turn-based games
- Rule: Never use client-authoritative for competitive PvP

**Hybrid (common in practice):**
- Movement: Client-authoritative with server validation (client moves, server checks for impossible speeds/positions)
- Combat/damage: Server-authoritative (server resolves all hits, damage, kills)
- Inventory/economy: Server-authoritative (never trust client for item ownership or currency)
- Used by: Many MMOs, battle royales (movement is predicted, combat is server-resolved)

### The Game Server Loop

```
while running:
    receive_inputs()          # Collect all player inputs for this tick
    simulate(delta_time)      # Advance physics, AI, game logic
    resolve_conflicts()       # Handle collisions, damage, interactions
    snapshot_state()          # Create authoritative state snapshot
    send_updates(clients)     # Broadcast state to all players
    sleep_until_next_tick()   # Maintain consistent tick rate
```

### Session vs Persistent Game Servers

**Session-based (match-based games):**
- Server created per match, destroyed when match ends
- State lives only for the match duration
- Examples: Fortnite (battle royale match), Valorant (competitive match), Rocket League
- Orchestration: Agones, GameLift, Hathora spin up/down servers per match

**Persistent (always-on worlds):**
- Server runs continuously with players joining/leaving
- State persists across sessions (databases, save files)
- Examples: World of Warcraft, EVE Online, Minecraft servers, Roblox experiences
- Orchestration: Traditional server management, auto-scaling based on player count

---

## 2. Netcode Patterns

### Client-Side Prediction

The most important technique for making networked games feel responsive. The client simulates the player's own actions immediately, without waiting for server confirmation.

**How it works:**
1. Player presses "move forward" at time T
2. Client immediately moves the player (predicted state)
3. Client sends input to server: `{tick: 42, input: "move_forward"}`
4. Server processes input at tick 42, broadcasts authoritative state
5. Client receives server state ~50-100ms later
6. Client compares predicted state to server state
7. If mismatch → correction (snap or interpolate to server position)

**The prediction buffer:**
- Client stores a buffer of all unacknowledged inputs (inputs sent but not yet confirmed by server)
- When server state arrives (for tick N), client:
  1. Discards all inputs up to tick N
  2. Replays remaining unacknowledged inputs on top of the server state
  3. This produces a corrected predicted state

**When prediction goes wrong (misprediction):**
- Server disagrees with client (e.g., client predicted movement but server says player was stunned)
- Client must "snap" or smoothly interpolate to the corrected position
- Visible as rubber-banding in games with high latency or packet loss

### Server Reconciliation

The server's response to client-side prediction. When the server processes inputs and determines the authoritative state:

1. Server receives input `{tick: 42, input: "move_forward"}` from Client A
2. Server simulates tick 42 with all players' inputs
3. Server determines authoritative position for Client A
4. Server sends state update: `{tick: 42, position: {x: 10.5, y: 0, z: 22.3}}`
5. Client A compares with its prediction, corrects if needed
6. Other clients see Client A's movement via interpolation

### Lag Compensation (Server-Side Rewind)

For hit detection in shooters, the server must answer: "Did this shot hit at the time the player fired?" — not at the current server time.

**How it works:**
1. Player fires at tick 42 (sees enemy at position X on their screen)
2. Input arrives at server at tick 45 (~50ms later)
3. Server rewinds world state to tick 42
4. Server performs hit detection at tick 42's positions
5. If hit → apply damage, broadcast
6. Server resumes to current tick

**Implementation:**
- Server maintains a circular buffer of world snapshots (last 200ms of state)
- On hit check, look up snapshot closest to `current_tick - client_RTT/2`
- This is why you can get "shot behind cover" in high-ping scenarios — the server validated the shot at the shooter's view of the world

### Interpolation

Other players' positions arrive as discrete updates (every tick or less). Without interpolation, other players would teleport between positions.

**Entity interpolation (standard):**
- Render other entities at a position slightly in the past (~100ms behind server time)
- Interpolate between the two most recent server snapshots
- Results in smooth movement at the cost of seeing other players slightly behind

**Interpolation buffer:**
```
Server sends: tick 40 → position A
              tick 41 → position B
              tick 42 → position C

Client renders at tick 42 but displays other entities at tick 40→41 (interpolating between A and B)
```

### Extrapolation (Dead Reckoning)

When you don't have future data, extrapolate from the last known state:
- Use last known position + velocity to predict where an entity will be
- Less accurate than interpolation — can cause "snapping" when real data arrives
- Used when: packets are lost or arrive late, prediction is better than freezing

### Rollback Netcode

Used in fighting games and fast-paced competitive games (GGPO/GGBack pattern):

1. Each client simulates locally using predicted inputs for remote players
2. When real inputs arrive (potentially late), if they differ from predictions:
   - Roll back game state to the tick where the misprediction occurred
   - Re-simulate forward with correct inputs
   - This happens in a single frame — player sees a "correction" but gameplay continues smoothly
3. Benefits: Game feels local-latency responsive, even at 100-200ms RTT
4. Used by: Street Fighter 6, Guilty Gear Strive, Mortal Kombat 1, MultiVersus, most modern fighting games

**GGPO (Good Game Peace Out):**
- The reference implementation of rollback netcode
- Open-sourced as GGPO (now integrated into many engines)
- Key insight: It's cheaper to re-simulate 7 frames of game logic than to add 7 frames of input delay

### Lockstep Simulation

All clients simulate the same deterministic game state in perfect sync:

1. All clients exchange inputs for tick N
2. All clients wait until they have everyone's inputs
3. All clients simulate tick N with identical inputs → identical state
4. No need to sync game state — it's identical by construction

**Requirements:**
- **Deterministic simulation**: Floating-point must produce identical results across platforms (use fixed-point math)
- **Synchronized random**: Shared seed for all random number generation
- **Input latency**: Gameplay feels delayed by the slowest player's network — every player waits for all inputs

**Best for**: RTS games (StarCraft, Age of Empires), where simulation is too complex to send full state but inputs are small. Also used in blockchain games (deterministic replay from inputs).

---

## 3. State Synchronization

### Full State Sync

Send the entire game state to every client on every update.

- **When**: Small state (card games, board games, simple multiplayer)
- **Size**: Typically <1KB per update
- **Pros**: Simple, no delta bugs, easy to debug
- **Cons**: Bandwidth scales with state size × player count × tick rate

### Delta Compression

Only send what changed since the last acknowledged state:

1. Server maintains per-client "last acknowledged state"
2. Server computes diff between current state and client's last acked state
3. Server sends only the diff
4. Client applies diff to reconstruct current state
5. Client ACKs → server updates the client's baseline

**Compression techniques:**
- **Field-level delta**: Only include fields that changed
- **Quantization**: Reduce precision (float32 → fixed16 for positions within a bounded area)
- **Bit packing**: Pack multiple small values into fewer bytes
- **Run-length encoding**: Compress repeated zero-diffs

**Example**: 100 entities × 64 bytes each = 6.4KB full state. With delta compression on a typical frame (5% change) = ~320 bytes.

### Interest Management (Area of Interest)

Don't send everything to everyone — only send what's relevant:

**Grid-based interest management:**
```
┌────┬────┬────┬────┐
│    │ B  │    │    │
├────┼────┼────┼────┤
│    │ A  │    │    │  Player A sees: B, C (adjacent cells)
├────┼────┼────┼────┤  Player A doesn't see: D (too far)
│    │    │ C  │    │
├────┼────┼────┼────┤
│    │    │    │ D  │
└────┴────┴────┴────┘
```

- Divide the world into cells/chunks
- Each player subscribes to their cell + adjacent cells
- Only receive updates for entities in subscribed cells
- Used by: Every open-world multiplayer game

**Spatial hashing:**
- Hash entity positions to grid cells: `cell = (floor(x/cell_size), floor(y/cell_size))`
- O(1) lookup for nearby entities
- Dynamic cell assignment as entities move

**Priority-based interest:**
- Nearby entities: Full update rate (60Hz)
- Medium distance: Reduced rate (20Hz)
- Far away: Minimal rate (5Hz) or none
- This dramatically reduces bandwidth for open-world games

### Snapshot Interpolation

A simpler alternative to client-side prediction + server reconciliation:

1. Server sends full snapshots at a fixed rate (e.g., 20Hz)
2. Client buffers 2-3 snapshots
3. Client interpolates between buffered snapshots
4. All entities (including the player) are rendered ~100ms in the past

**Pros**: Simple, correct, no misprediction artifacts
**Cons**: Everything feels slightly delayed (~100-150ms), less responsive than client-side prediction
**Best for**: Third-person games, cooperative games, games where 100ms of latency is acceptable

---

## 4. Game Server Frameworks

### Colyseus (TypeScript/JavaScript)

- **Language**: TypeScript (Node.js)
- **Model**: Room-based — each game session is a "Room" class with state and message handlers
- **State sync**: Automatic schema-based state synchronization (define schema, Colyseus diffs and syncs)
- **Transport**: WebSocket (built-in), WebTransport support
- **Client SDKs**: JavaScript, Unity (C#), Defold (Lua), Godot, Cocos Creator, Haxe
- **Scalability**: Single process handles ~100-500 rooms depending on complexity, horizontal scaling with matchmaking
- **Best for**: Web-based multiplayer, casual games, prototyping, small-medium scale
- **Limitations**: Node.js single-threaded limits per-room complexity, not suitable for physics-heavy simulations at high tick rates
- **Notable**: Arena Cloud provides managed hosting for Colyseus

### Nakama (Go)

- **Language**: Go (server), Lua/TypeScript/Go for server-side game logic
- **Model**: Full game server with matchmaking, presence, chat, leaderboards, storage, auth — all built in
- **State sync**: Real-time multiplayer via matches (authoritative or relayed), state sent via match data messages
- **Transport**: WebSocket, gRPC
- **Client SDKs**: Unity, Unreal, Godot, JavaScript, Swift, Java, .NET, Flutter
- **Scalability**: Clustered deployment, handles thousands of matches per node
- **Best for**: Full-featured game backend (not just networking), mobile games, when you need auth + social + leaderboards + multiplayer in one package
- **Differentiator**: Nakama is a complete game backend, not just a netcode framework — it replaces Firebase/PlayFab + custom multiplayer
- **Open source**: Heroic Labs offers managed Nakama, or self-host

### Photon Engine

- **Model**: Cloud-hosted networking with client SDKs, or self-hosted Photon Server
- **Products**:
  - **Photon Realtime**: Low-level real-time networking, room-based
  - **Photon Fusion**: Tick-based state sync with prediction/interpolation built in
  - **Photon Quantum**: Deterministic simulation engine (predict/rollback, great for fighting/action games)
  - **Photon Chat**: Chat service
- **Client SDKs**: Unity (primary), Unreal, JavaScript, C++, Java, .NET
- **Transport**: UDP (reliable + unreliable), WebSocket for browser
- **Best for**: Unity games, when you want a mature cloud-hosted solution without server management
- **Pricing**: Per-CCU (concurrent user) pricing — can be expensive at scale
- **Differentiator**: Deepest Unity integration, mature ecosystem, Quantum's deterministic simulation

### PlayFab (Microsoft)

- **Model**: Complete game backend-as-a-service (LiveOps platform)
- **Features**: Multiplayer servers (Azure-hosted), matchmaking, player data, leaderboards, economy/virtual currency, analytics, A/B testing, LiveOps
- **Multiplayer Servers**: Azure-hosted dedicated game servers with auto-scaling
- **Client SDKs**: Unity, Unreal, C#, Java, JavaScript, Python
- **Best for**: Xbox/PC games (Microsoft ecosystem), LiveOps-heavy games, when you need analytics + economy + multiplayer in one platform
- **Pricing**: Free tier, per-user pricing at scale

### Mirror (Unity — Open Source)

- **Model**: Networking library for Unity — successor to UNet
- **Architecture**: Server-authoritative, SyncVar/Command/RPC pattern
- **Transport**: KCP (reliable UDP), WebSocket, Steam Networking
- **Best for**: Unity multiplayer games, self-hosted dedicated servers
- **Limitations**: Unity-specific, mostly synchronous, less suited for large player counts

### Fish-Net (Unity — Open Source)

- **Model**: Networking library for Unity — alternative to Mirror with more features
- **Architecture**: Server-authoritative with prediction support, lag compensation
- **Transport**: Multiple transport options including reliable UDP
- **Best for**: Unity games needing more advanced features than Mirror (prediction, lag compensation)
- **Differentiator**: Built-in prediction, reconciliation, and lag compensation

### Bevy (Rust — ECS-based)

- **Model**: Entity Component System engine with multiplayer plugins
- **Networking**: `bevy_replicon`, `lightyear` — community networking crates
- **Best for**: Rust game developers, performance-critical simulations, deterministic physics
- **Limitations**: Still maturing, smaller community than Unity/Unreal ecosystem

---

## 5. Networking Protocols for Games

### Why Games Use UDP

TCP guarantees ordered, reliable delivery — but this is often harmful for games:

- **Head-of-line blocking**: If packet 5 is lost, TCP blocks packets 6, 7, 8 until packet 5 is retransmitted and received. For a game sending position updates 60 times per second, blocking for 100-200ms means missing 6-12 frames of game state.
- **Stale data retransmission**: By the time lost packet 5 arrives, packets 6, 7, 8 already contain newer position data — retransmitting packet 5 is wasted bandwidth.
- **No selective reliability**: Everything or nothing. Games need reliable delivery for some data (chat, inventory changes) and unreliable for others (position updates).

**The solution**: UDP + custom reliability layer — selective reliability per message type.

### Reliable UDP Libraries

**ENet**
- Mature, battle-tested C library with bindings for most languages
- Provides reliable, unreliable, and sequenced channels over UDP
- Used by: Many production games
- Limitation: Single-threaded, no encryption built-in

**KCP**
- Fast reliable transport over UDP — TCP-like reliability without TCP's latency
- 30-40% less latency than TCP under packet loss
- Used by: Genshin Impact (reportedly), many Chinese mobile games
- Available in C, Go, Rust, and other languages

**GameNetworkingSockets (Valve)**
- Valve's production networking library — used in Dota 2, CS2
- Reliable and unreliable messages, encryption, authentication
- P2P and dedicated server support
- Steam Datagram Relay (SDR) for DDoS protection and optimal routing

**QUIC for Games**
- QUIC provides multiplexed streams over UDP — each stream is independently reliable
- No head-of-line blocking between streams
- Built-in encryption (TLS 1.3)
- 0-RTT connection establishment
- Growing adoption for game networking (replaces custom reliable UDP)

### Protocol Selection

| Factor | TCP (WebSocket) | UDP (Raw) | ENet | KCP | QUIC | WebTransport |
|--------|-----------------|-----------|------|-----|------|--------------|
| Reliability | All reliable | None | Selectable | Reliable | Per-stream | Per-stream |
| Ordering | Total order | None | Per-channel | Ordered | Per-stream | Per-stream |
| HOL blocking | Yes | No | No (per-channel) | Minimal | No (per-stream) | No |
| Encryption | TLS | Custom | Custom | Custom | Built-in (TLS 1.3) | Built-in |
| NAT traversal | Easy | Hard | Moderate | Hard | Moderate | Easy (HTTP/3) |
| Browser support | WebSocket | None | None | None | None | Yes |
| Latency under loss | High | Lowest | Low | Low | Low | Low |
| Best for | Web games, casual | Custom engines | Proven reliability | Min-latency reliable | Modern games | Browser games |

---

## 6. Game Server Orchestration

### Agones (Kubernetes-native)

- **Model**: Kubernetes controller that manages dedicated game server lifecycle
- **How it works**:
  1. Define a GameServer resource (container image, ports, health check)
  2. Agones creates and manages pods for game server instances
  3. Fleet controller maintains a pool of ready servers
  4. Allocator assigns a ready server when matchmaker requests one
  5. Server moves through states: Scheduled → Ready → Allocated → Shutdown
- **Scaling**: Fleet Autoscaler scales based on buffer size (always keep N servers ready)
- **Features**: Health checking, graceful shutdown, SDK for game server → Agones communication
- **Best for**: Teams already on Kubernetes, custom game servers, maximum control
- **Limitations**: Requires Kubernetes expertise, operational overhead of running K8s

**Agones Fleet Autoscaler:**
```yaml
apiVersion: autoscaling.agones.dev/v1
kind: FleetAutoscaler
spec:
  fleetName: game-server-fleet
  policy:
    type: Buffer
    buffer:
      bufferSize: 10        # Always keep 10 servers ready
      minReplicas: 5        # Never go below 5
      maxReplicas: 100      # Cap at 100
```

### Amazon GameLift

- **Model**: AWS-managed game server hosting with FlexMatch matchmaking
- **Features**: Auto-scaling, game session management, matchmaking (FlexMatch), multi-region, Spot instances for cost savings
- **FlexMatch**: Built-in matchmaking with custom rules (skill, latency, team balance)
- **Pricing**: Per-instance hour + data transfer
- **Best for**: AWS-native, when you want managed infrastructure + matchmaking
- **Differentiator**: FlexMatch is one of the most full-featured managed matchmaking services

### Hathora (DEFUNCT — May 2026)

- **Status**: Acquired by Fireworks AI in March 2026, platform permanently shut down May 5, 2026
- **Was**: Managed game server hosting — deploy containers, get global servers
- **Migration**: Studios must migrate to alternatives (Edgegap, GameLift, Rivet, Agones)
- **Note**: Do NOT recommend Hathora for new projects. Use `WebSearch` to verify current status if asked.

### Rivet

- **Model**: Open-source game server orchestration platform — can self-host or use managed
- **Features**: Matchmaking, server provisioning, lobbies, analytics, DDoS protection
- **Differentiator**: Open-source, can run on any cloud or bare metal
- **Best for**: Teams who want orchestration without vendor lock-in

### Edgegap

- **Model**: Edge-deployed game servers — automatically places servers near players
- **Features**: Intelligent server placement based on player locations, scaling, DDoS protection
- **Differentiator**: Latency optimization — server is automatically deployed at the edge PoP closest to the match's players
- **Best for**: Latency-sensitive games, global player bases

### Orchestration Selection

| Factor | Agones | GameLift | Rivet | Edgegap |
|--------|--------|----------|-------|---------|
| Infrastructure | Self-managed K8s | AWS managed | Self-host or managed | Managed edge |
| Matchmaking | BYO | FlexMatch (built-in) | Built-in | BYO |
| Scaling | Fleet autoscaler | Auto-scaling groups | Automatic | Edge-aware |
| Lock-in | Kubernetes | AWS | None (open source) | Low |
| K8s required | Yes | No | No | No |
| Latency optimization | BYO (multi-region K8s) | Multi-region | Multi-region | Edge placement (615+ PoPs) |
| Best for | K8s teams | AWS + matchmaking | Open-source control | Edge latency |

---

## 7. Matchmaking Systems

### Skill Rating Systems

**Elo (Classic)**
- Binary win/loss, single number rating
- Used by: Chess, many mobile games
- Limitations: Doesn't handle uncertainty, slow to converge for new players

**Glicko-2**
- Extends Elo with rating deviation (uncertainty) and rating volatility
- New players have high uncertainty → rating changes faster until it stabilizes
- Used by: Lichess, many competitive games
- Better than Elo for online games where play frequency varies

**TrueSkill 2 (Microsoft)**
- Bayesian skill estimation — represents skill as a distribution, not a single number
- Handles team games (not just 1v1), individual contribution within teams
- Uncertainty decreases with more games played
- Used by: Xbox matchmaking, Halo, Gears of War
- Considers: Win/loss, individual performance metrics, team composition

**OpenSkill**
- Open-source alternative to TrueSkill — similar Bayesian approach
- No patent restrictions (TrueSkill has Microsoft patents)
- Libraries available in most languages

### Matchmaking Queue Architecture

```
Player joins queue → Queue Manager → Rating Window Match → Team Balancer → Server Allocator → Match Start
       │                    │                │                    │                │
       ▼                    ▼                ▼                    ▼                ▼
  Submit rating,       Group players     Find players with     Balance teams      Request server
  preferences,         by game mode,     close ratings         for fair match     from orchestrator,
  latency data         region, party     (expand window        (equal avg         send connection
                       size              over time)            rating ± threshold) info to players
```

**Queue expansion over time:**
- Start with tight skill window (±50 rating points)
- Every 10 seconds, expand by ±25 points
- After 60 seconds, expand aggressively
- After 120 seconds, match with anyone available
- Balance: Fair matches vs queue time. Players prefer 30-second unfair matches over 5-minute perfect matches.

### Lobby Systems

For games where players form groups before matchmaking:

- **Host-based lobbies**: One player hosts, others join. Host starts the match. Simple but host has power.
- **Server-managed lobbies**: Server creates lobby, players join, server manages ready-up and game start. More control, fairer.
- **Party system**: Groups of friends join matchmaking together as a pre-formed team.

---

## 8. Tick Rate and Simulation

### What Tick Rate Means

The tick rate is how many times per second the server updates the game simulation. A 64-tick server runs 64 simulation steps per second (one every ~15.6ms).

| Game Type | Typical Tick Rate | Why |
|-----------|-------------------|-----|
| Competitive FPS (Valorant, CS2) | 128 tick | Precise hit detection requires high-frequency simulation |
| Battle Royale (Fortnite) | 30-60 tick | 100 players × high tick = expensive; 30-60 is the compromise |
| Fighting games | 60 tick (frame-locked) | Match display refresh rate, deterministic simulation |
| MMO | 10-30 tick | Many players, complex state, lower precision acceptable |
| Turn-based | Event-driven | No tick loop — process actions on input |
| Casual mobile | 10-20 tick | Lower precision acceptable, battery/bandwidth conservation |

### Fixed Timestep vs Variable Timestep

**Fixed timestep (standard for multiplayer):**
```
const TICK_RATE = 64;
const TICK_DURATION = 1000 / TICK_RATE; // 15.625ms

while (running) {
    const start = now();
    processInputs();
    simulate(TICK_DURATION);  // Always advance by exact same delta
    sendUpdates();
    const elapsed = now() - start;
    sleep(TICK_DURATION - elapsed);
}
```

- Deterministic: Same inputs always produce same outputs
- Required for: Rollback netcode, lockstep, replay systems
- Risk: If simulation takes longer than tick duration, the server falls behind (tick debt)

**Handling tick debt:**
- If the simulation occasionally takes longer than 15.6ms:
  - Skip rendering/non-essential work
  - Process multiple ticks in one iteration (catch up)
  - Alert monitoring if consistently falling behind (need to reduce tick rate or optimize simulation)

### Network Send Rate vs Tick Rate

The tick rate and the network send rate don't have to match:
- Simulate at 128 tick (high-precision game logic)
- Send updates at 64Hz or 32Hz (save bandwidth)
- Client interpolates between received updates

This is common in battle royales: simulate at 60 tick, send at 20-30Hz to save bandwidth with 100 players.

---

## 9. Anti-Cheat Architecture

### Server-Authoritative Design (The Foundation)

The most effective anti-cheat is architectural: **never trust the client**.

- Client sends inputs, not outcomes: "I pressed fire" not "I hit player X for 50 damage"
- Server validates all inputs against game rules:
  - Movement speed within allowed bounds?
  - Fire rate within weapon's fire rate?
  - Line-of-sight check for hits?
  - Cooldowns respected?
- Server computes outcomes (damage, kills, loot drops)

**What the server should validate:**
- **Movement**: Speed, acceleration, position (no teleporting), collision (no clipping through walls)
- **Combat**: Fire rate, ammo count, damage values, hit registration (raycast on server)
- **Economy**: Item ownership, currency, trades (never trust client-reported values)
- **Timing**: Action timestamps (detect speed hacks by checking if inputs arrive faster than possible)

### Input Validation

```
function validateInput(input, player, gameState):
    // Movement
    if (distance(input.position, player.lastPosition) > MAX_SPEED * TICK_DURATION * 1.1):
        reject("movement too fast")
    
    // Fire rate
    if (input.fire && (now - player.lastFireTime) < weapon.minFireInterval * 0.95):
        reject("fire rate too fast")
    
    // Ammo
    if (input.fire && player.ammo <= 0):
        reject("no ammo")
    
    // Accept and process
    applyInput(input, player, gameState)
```

### Wallhack Prevention (Information Hiding)

Only send entities the player can see:
- **Server-side visibility check**: Before including an entity in a player's update, check if it's within line-of-sight or audible range
- **Don't send positions of enemies behind walls** — if the client doesn't have the data, no wallhack can display it
- **Fog of war**: Common in RTS/MOBA — only send data for entities in the player's visible area

### Client-Side Anti-Cheat (Defense in Depth)

Server-authoritative design prevents most cheating, but client-side anti-cheat adds layers:
- **Memory scanning**: Detect known cheat signatures in process memory
- **Driver-level monitoring**: Kernel anti-cheat (EasyAntiCheat, BattlEye, Vanguard)
- **Behavioral analysis**: Detect inhuman input patterns (perfect aim, impossible reaction times)
- **Replay verification**: Record inputs, replay on server to verify outcomes match

---

## 10. MMO-Specific Patterns

### World Partitioning (Sharding)

Divide the world into independent zones, each running on a separate server:

```
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Zone A  │  │  Zone B  │  │  Zone C  │
│  Server  │  │  Server  │  │  Server  │
│          │──│          │──│          │
│ 500 players│ 300 players│ 200 players│
└──────────┘  └──────────┘  └──────────┘
        ↕              ↕              ↕
    ┌─────────────────────────────────────┐
    │        Shared Database / Cache      │
    └─────────────────────────────────────┘
```

**Zone boundaries:**
- Players near zone boundaries see entities from adjacent zones
- Cross-zone interactions (combat, chat) require inter-server communication
- **Seamless transitions**: Player crosses boundary → handoff to new zone server without loading screen

### Instancing

Create isolated copies of the same area:
- **Dungeon instances**: Party enters dungeon → private copy of that zone
- **Overflow instances**: City too crowded → spawn additional instance with load balancing
- **Phasing**: Same physical location, different instance based on quest progress (WoW phasing)

### Entity Component System (ECS)

MMOs with thousands of entities benefit from data-oriented design:
- **Entity**: Just an ID (uint64)
- **Component**: Data only (Position, Health, Inventory, AI)
- **System**: Logic that processes components (MovementSystem processes all entities with Position + Velocity)

**Why ECS for MMOs:**
- Cache-friendly: Components stored contiguously in memory (iterate all positions without loading other data)
- Scalable: Add new behaviors by adding components/systems, no deep inheritance hierarchies
- Parallelizable: Systems with disjoint component access can run in parallel

**Frameworks**: Bevy (Rust), Flecs (C/C++), Unity DOTS, Entitas (C#)

### Player Count Scaling

| Players | Architecture | Examples |
|---------|-------------|----------|
| 2-16 | Single server, full state sync | Most multiplayer games |
| 16-64 | Single server, interest management | Battle royale, large FPS |
| 64-200 | Single server, aggressive interest management + delta compression | Fortnite (100), PUBG |
| 200-5,000 | Zoned/instanced, multiple servers | Most MMOs, GTA Online |
| 5,000-50,000+ | Massive sharding, spatial databases, serverless compute | EVE Online, PlanetSide 2 |

---

## 11. Browser-Based Multiplayer

### WebSocket Game Networking

For browser multiplayer, WebSocket is the primary transport:

**Architecture:**
```
Browser Client ←WebSocket→ Game Server (Node.js/Go/Rust)
```

**Challenges vs native UDP:**
- TCP head-of-line blocking (lost packet blocks all subsequent frames)
- Higher latency variance
- No unreliable delivery (every byte is reliably delivered — even stale position data)
- Limited binary performance (ArrayBuffer helps, but overhead exists)

**Mitigations:**
- Use binary protocols (MessagePack/Protobuf) to minimize payload size
- Client-side prediction to mask latency
- Aggressive delta compression
- Consider WebTransport for next-gen browsers (unreliable datagrams!)

### WebTransport for Browser Games

WebTransport is a game-changer for browser multiplayer:
- **Unreliable datagrams**: Send position updates that can be dropped without blocking
- **Multiple streams**: Reliable stream for chat/events + unreliable for positions
- **Lower latency**: QUIC 0-RTT, no TCP HOL blocking

This is the closest browsers have come to native UDP game networking.

### Colyseus for Web Games

Colyseus is the most popular framework for browser multiplayer:
- Schema-based state sync (define state shape, sync happens automatically)
- Room lifecycle (create, join, leave, dispose)
- Client prediction via `@colyseus/proxy`
- TypeScript on both client and server

---

## 12. Real-Time Leaderboards and Analytics

### Redis Sorted Sets for Leaderboards

Redis Sorted Sets provide O(log N) insertion and O(log N) rank lookup — ideal for leaderboards:

```
ZADD leaderboard 1500 "player:alice"     # Add/update score
ZADD leaderboard 2100 "player:bob"
ZREVRANK leaderboard "player:alice"      # Get rank (0-indexed, highest first)
ZREVRANGE leaderboard 0 9 WITHSCORES    # Top 10
ZREVRANGEBYSCORE leaderboard +inf -inf LIMIT 0 100  # Top 100
ZCOUNT leaderboard 1000 2000            # Players in score range
```

**Scaling leaderboards:**
- Single Redis instance handles millions of entries (Sorted Set is efficient)
- For global leaderboards with 100M+ entries: shard by score range or use Redis Cluster
- Per-region leaderboards: separate key per region, aggregate periodically

### Real-Time Scoring

For live game events (scores changing every second):
- **Push-based**: WebSocket subscription to leaderboard channel, server broadcasts top-N changes
- **Poll with freshness**: Client polls every 5-10 seconds, server returns from Redis (always fresh)
- **Hybrid**: Push top-10 changes in real-time, poll for the rest

### Game Analytics Pipeline

```
Game Events → Event Ingestion → Stream Processing → Analytics Store → Dashboards
     │            (Kafka)          (Flink/Spark)     (ClickHouse)     (Grafana)
     │
     └→ Real-time: Player count, match state, live KPIs
     └→ Batch: DAU/MAU, retention, monetization, balance metrics
```
