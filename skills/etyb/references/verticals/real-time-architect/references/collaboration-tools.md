# Collaboration Tools Architecture — Deep Reference

**Always use `WebSearch` to verify CRDT framework versions, collaboration platform pricing, and library capabilities before giving advice. The real-time collaboration space is evolving rapidly with new entrants and approaches. Last verified: April 2026.**

## Table of Contents
1. [Conflict Resolution Fundamentals](#1-conflict-resolution-fundamentals)
2. [CRDTs Deep Dive](#2-crdts-deep-dive)
3. [CRDT Frameworks](#3-crdt-frameworks)
4. [Operational Transformation](#4-operational-transformation)
5. [Presence Systems](#5-presence-systems)
6. [Collaboration Platforms](#6-collaboration-platforms)
7. [Document Collaboration Patterns](#7-document-collaboration-patterns)
8. [Local-First and Offline-First Architecture](#8-local-first-and-offline-first-architecture)
9. [Version History and Undo](#9-version-history-and-undo)
10. [Permission Models for Real-Time Collaboration](#10-permission-models-for-real-time-collaboration)
11. [Real-World Architecture Analysis](#11-real-world-architecture-analysis)
12. [Choosing Between CRDTs and OT](#12-choosing-between-crdts-and-ot)

---

## 1. Conflict Resolution Fundamentals

### The Core Problem

When multiple users edit the same content simultaneously, their operations can conflict. If Alice inserts "Hello" at position 5 and Bob deletes characters 3-7 at the same time, what should the result be? Both are valid operations, but they can't both be applied naively without corruption.

Two families of solutions exist:

**Operational Transformation (OT):**
- Transforms operations against each other so they can be applied in any order and converge to the same state
- Requires a central server to serialize operations (total ordering)
- Used by Google Docs, legacy collaborative editors

**CRDTs (Conflict-free Replicated Data Types):**
- Data structures that mathematically guarantee convergence without coordination
- No central server required — operations can be applied in any order, any number of times, and all replicas converge
- Used by Figma, newer collaborative tools, local-first software

### The 2025 Hybrid Breakthrough: Eg-walker

Published by Joseph Gentle and Martin Kleppmann at EuroSys 2025: "Collaborative Text Editing with Eg-walker: Better, Faster, Smaller." Eg-walker combines the best properties of OT and CRDTs:

- Uses integer indexes like OT but can merge divergent branches like CRDTs
- Temporarily builds a CRDT structure for conflict resolution, then discards it — freeing memory
- **Order of magnitude less memory** than traditional CRDTs in steady state
- Merging long-running branches is orders of magnitude faster than OT
- **Figma adopted Eg-walker** for their Code Layers feature in 2025
- Diamond Types implements Eg-walker in Rust

### When to Use Which

| Factor | OT | CRDTs | Eg-walker |
|--------|-----|-------|-----------|
| Central server required | Yes (for ordering) | No (peer-to-peer capable) | Optional |
| Offline support | Limited (need server to transform) | Excellent (merge on reconnect) | Excellent |
| Implementation complexity | Correctness is notoriously hard | Library handles convergence | Medium |
| Memory overhead | Lower (operations are compact) | Higher (metadata for convergence) | Low |
| Latency | Server round-trip for confirmation | Immediate local application | Immediate local |
| Undo/redo | Well-understood | More complex (intention preservation) | More complex |
| Mature libraries (2026) | ShareDB | Yjs, Automerge, Loro | Diamond Types |
| Server requirement | Stateful (holds document state) | Stateless possible (just relay) | Stateless possible |
| Production maturity | 35+ years | ~15 years | ~1 year |
| Best for | Centralized, server-controlled | Local-first, offline-first, P2P | New projects wanting best of both |

**Default recommendation (2026)**: CRDTs (specifically Yjs) for most projects — the library ecosystem is mature and offline/local-first benefits are significant. For performance-critical text editing, consider Diamond Types (Eg-walker). Use OT only if extending an existing OT-based system.

---

## 2. CRDTs Deep Dive

### What Makes a CRDT

A CRDT is a data structure where:
1. **Any replica can be modified independently** (no coordination needed)
2. **Replicas can be merged** and the merge operation is:
   - **Commutative**: merge(A, B) = merge(B, A)
   - **Associative**: merge(merge(A, B), C) = merge(A, merge(B, C))
   - **Idempotent**: merge(A, A) = A
3. **All replicas converge** to the same state once they've seen the same operations

### CRDT Types

**Operation-based CRDTs (op-based / CmRDTs):**
- Replicas broadcast operations ("insert 'x' at position 5")
- Operations must be delivered exactly once (or be idempotent)
- Smaller messages (just the operation)
- Require reliable, causal-order delivery

**State-based CRDTs (state-based / CvRDTs):**
- Replicas broadcast their full state, merge with join/merge function
- Can tolerate message loss and duplication (merge is idempotent)
- Larger messages (full state per sync)
- Simpler infrastructure requirements

**Delta-state CRDTs (delta CRDTs):**
- Hybrid: send only the delta (diff) of state changes
- Combines small messages of op-based with robustness of state-based
- Used by most modern CRDT libraries (Yjs, Automerge)

### Text CRDTs

Text editing is the hardest and most important CRDT application. Key algorithms:

**YATA (Yet Another Transformation Approach) — used by Yjs:**
- Each character has a unique ID (clientID, clock)
- Characters form a doubly-linked list with left/right references
- Insertions between two characters are unambiguous (ID-based ordering breaks ties)
- Deletions are tombstones (marked as deleted, not removed — required for convergence)
- Highly optimized for sequential edits (common case)

**RGA (Replicated Growable Array):**
- Similar to YATA — linked list with unique IDs
- Each insertion references its predecessor
- Concurrent insertions sorted by timestamp/ID

**Fugue (2023):**
- Newer algorithm that avoids interleaving (a problem where concurrent insertions can shuffle characters)
- Guarantees that concurrent insertions by different users don't interleave character-by-character
- Used by some newer editors

### JSON CRDTs

For structured data (documents, configurations, game state):

- **Automerge**: Full JSON CRDT — supports nested objects, arrays, text, counters
- **Yjs**: Y.Map, Y.Array, Y.Text — Yjs types map to JSON structures
- **Loro**: JSON-like CRDT with rich-text support

**Conflict resolution for JSON:**
- **Concurrent object edits**: Both edits survive (last-writer-wins per field, or multi-value)
- **Concurrent array inserts**: Both elements inserted, ordering determined by algorithm
- **Concurrent map key sets**: Both values kept (multi-value register) or LWW per key
- **Delete + edit conflict**: Typically edit wins (resurrects deleted content) — configurable in some libraries

---

## 3. CRDT Frameworks

### Yjs

- **Language**: JavaScript (TypeScript)
- **Algorithm**: YATA-based, delta-state CRDT
- **Data types**: Y.Text, Y.Map, Y.Array, Y.XmlFragment, Y.XmlElement, Y.XmlText
- **Performance**: Handles documents with millions of operations, sub-millisecond merge
- **Ecosystem**: Largest CRDT ecosystem — bindings for ProseMirror, TipTap, Monaco, CodeMirror, Quill, Slate, BlockSuite, Lexical
- **Networking**: Provider-based — y-websocket, y-webrtc, y-indexeddb, y-sweet, Hocuspocus, Liveblocks
- **Persistence**: y-indexeddb (browser), y-leveldb (server), y-redis, any provider
- **Document encoding**: Compact binary format, efficient sync protocol (state vector + diff)
- **Best for**: Web-based collaborative editing, richest editor integration ecosystem
- **Production users**: Many Tiptap-based editors, Notesnook, AFFiNE (BlockSuite)

**Yjs sync protocol:**
```
1. Client connects, sends its state vector (compact summary of what it knows)
2. Server computes diff (operations client hasn't seen)
3. Server sends diff
4. Client applies diff → synced
5. Ongoing: client sends operations, server relays to other clients
```

### Automerge

- **Language**: Rust core with JavaScript (WASM), Python, Swift, Kotlin bindings
- **Algorithm**: Custom CRDT with Rust-based engine (Automerge 2.0 — major rewrite)
- **Data types**: JSON-like: objects, arrays, text, counters, timestamps
- **Performance**: Automerge 2.0 (Rust/WASM) is dramatically faster than v1 — handles large documents efficiently
- **Ecosystem**: Growing — ProseMirror binding (`automerge-prosemirror`), React, Svelte
- **Networking**: `automerge-repo` — sync protocol with pluggable network and storage adapters
- **Differentiator**: True JSON CRDT — the entire document is a CRDT, not just text. Change tracking, branching, and merging built in.
- **Best for**: Structured data collaboration (not just text), local-first applications, when you need the full document history as a first-class feature
- **Production users**: Ink & Switch experiments, growing adoption

**Automerge unique features:**
- **Change objects**: Every edit is a "change" with author, timestamp, and dependencies — full history built in
- **Branching and merging**: Fork a document, make changes, merge back — like git for data
- **Patches API**: Subscribe to changes as patches (for efficient UI updates)

### Diamond Types

- **Language**: Rust (with WASM for JavaScript)
- **Algorithm**: Fugue-based text CRDT — avoids the interleaving problem
- **Performance**: Extremely fast — benchmarks show it outperforming Yjs and Automerge on large documents
- **Focus**: Text editing specifically (not a general JSON CRDT)
- **Differentiator**: Highest performance text CRDT, Fugue algorithm avoids interleaving
- **Best for**: Performance-critical text editing, when you need the fastest possible CRDT
- **Maturity**: Newer, smaller ecosystem than Yjs or Automerge

### Loro

- **Language**: Rust core with JavaScript (WASM) bindings
- **Algorithm**: Custom CRDT supporting rich text, lists, maps, trees, and movable lists
- **Data types**: Rich text (with formatting marks), List, Map, Tree, MovableList, Counter
- **Differentiator**: Rich text as a first-class CRDT type (not just plain text + separate formatting), tree CRDT for hierarchical data, movable list (reorder items without delete+insert)
- **Best for**: Rich text collaboration, document editors with complex structure (outliners, block editors)
- **Maturity**: Newer but actively developed, gaining adoption

### Framework Comparison

| Factor | Yjs | Automerge 2 | Diamond Types | Loro |
|--------|-----|-------------|---------------|------|
| Core language | JavaScript | Rust (WASM) | Rust (WASM) | Rust (WASM) |
| Text editing | Excellent | Good | Best perf | Excellent (rich text) |
| Structured data | Y.Map/Y.Array | Full JSON | Text only | Rich types + tree |
| Editor bindings | Most extensive | Growing | Limited | Growing |
| Sync protocol | Mature | automerge-repo | Custom | Custom |
| History/branching | Limited | First-class | Limited | First-class |
| Offline support | Via providers | Built-in (automerge-repo) | Custom | Custom |
| Performance (text) | Very fast | Fast (WASM) | Fastest | Very fast |
| Memory overhead | Moderate | Moderate | Low (text) | Moderate |
| Ecosystem maturity | Most mature | Growing rapidly | Early | Early |
| Best for | Web editors | Structured data, local-first | Max perf text | Rich text, trees |

---

## 4. Operational Transformation

### How OT Works

OT transforms operations so they can be applied in any order and converge:

**Example:** Document starts as "ABC"
- Alice inserts "X" at position 1: "AXBC"
- Bob inserts "Y" at position 2: "ABYC"

Without transformation, if we apply Alice's op then Bob's:
1. Insert "X" at 1: "AXBC"
2. Insert "Y" at 2: "AXBYBC" — Wrong! Bob intended to insert after "B", not after "X"

With transformation:
1. Apply Alice's op: "AXBC"
2. Transform Bob's op against Alice's: Bob's position 2 becomes position 3 (because Alice inserted before it)
3. Apply transformed op: Insert "Y" at 3: "AXBYC" — Correct!

### Transform Function Complexity

The transform function must handle every combination of operation types:
- Insert × Insert
- Insert × Delete
- Delete × Insert
- Delete × Delete

For rich text (bold, italic, lists, etc.), the combinations explode. This is why OT is notoriously hard to implement correctly. Google Docs spent years getting this right.

### ShareDB

- **Language**: JavaScript (Node.js)
- **Model**: OT-based real-time sync with a central server
- **Backend**: MongoDB or PostgreSQL for document storage + operation history
- **Editing**: JSON OT (json0) for structured documents, rich-text OT for text
- **Client**: ShareDB client connects via WebSocket, sends ops, receives transformed ops
- **Best for**: Server-centric collaboration where you need a central authority
- **Limitations**: Requires central server (no P2P), MongoDB/PostgreSQL dependency, OT complexity

---

## 5. Presence Systems

### What Presence Includes

Presence is the real-time awareness of other users' state:

- **Online status**: Who is currently viewing this document/room?
- **Cursor position**: Where is each user's cursor in the document?
- **Selection**: What text/cells/objects does each user have selected?
- **Typing indicator**: Is a user currently typing?
- **Viewport**: What part of the document/canvas is each user looking at?
- **Custom metadata**: User name, avatar color, role, activity description

### Cursor Sync Architecture

**For text editors:**
```json
{
  "type": "presence",
  "user": {"id": "alice", "name": "Alice", "color": "#e74c3c"},
  "cursor": {
    "anchor": {"index": 42},
    "head": {"index": 47}
  },
  "activity": "editing"
}
```

- Anchor = start of selection, Head = end of selection (cursor is when anchor === head)
- Send cursor updates on every change, throttled to 50-100ms
- Use CRDT-relative positions (Y.js `RelativePosition`) instead of absolute indices — survives concurrent edits

**For canvas/whiteboard (Figma-like):**
```json
{
  "type": "presence",
  "user": {"id": "alice", "name": "Alice", "color": "#e74c3c"},
  "cursor": {"x": 450.5, "y": 322.0},
  "viewport": {"x": 0, "y": 0, "width": 1920, "height": 1080, "zoom": 1.5},
  "selection": ["object-id-1", "object-id-3"],
  "activity": "dragging"
}
```

### Presence at Scale

For small documents (2-20 collaborators), broadcast every presence update to everyone. For large documents or rooms:

**Throttling:**
- Cursor moves: Send at most every 50ms (20Hz) — smooth enough, bandwidth-friendly
- Typing indicators: Debounce (send "started typing" once, "stopped typing" after 3s of inactivity)
- Viewport changes: Send on scroll end / zoom end, not during

**Viewport-based filtering:**
- Only send presence for users whose cursors are within or near the recipient's viewport
- Prevents rendering 100 cursors you can't see
- Server-side filtering or client-side culling

**Presence data structure (server-side):**
```
Room presence (Redis Hash):
  room:doc-42:presence = {
    "user:alice": "{cursor: {x: 100, y: 200}, ts: 1713100800}",
    "user:bob": "{cursor: {x: 300, y: 150}, ts: 1713100799}",
    ...
  }
  
  TTL on each user's key: 30 seconds (expire stale presence)
```

---

## 6. Collaboration Platforms

### Liveblocks

- **Model**: Real-time collaboration infrastructure — storage, presence, comments
- **Products**:
  - **Presence**: Real-time awareness (cursors, selections, "who's here")
  - **Storage**: CRDT-based conflict-free storage (synced state for collaboration)
  - **Comments**: Threaded comments anchored to elements in the document
  - **Notifications**: In-app notification system for collaboration events
- **Integration**: React hooks (`useMyPresence`, `useOthers`, `useMutation`), Yjs integration, Tiptap, BlockNote, CodeMirror
- **Architecture**: Managed backend — connect via WebSocket, Liveblocks handles sync, conflict resolution, persistence
- **Best for**: Adding collaboration to existing React apps, when you want managed infrastructure
- **Pricing**: Per-MAU (Monthly Active User), free tier available

### Tiptap Collaboration (Hocuspocus)

- **Model**: Self-hosted or cloud collaboration server for Tiptap (ProseMirror-based) editors
- **Architecture**: Yjs document sync server — stores Yjs documents, relays operations between clients
- **Features**: Document management, webhook events, authentication, persistence (multiple backends)
- **Tiptap Cloud**: Managed Hocuspocus service
- **Best for**: Rich text collaborative editing with Tiptap/ProseMirror
- **Note**: Hocuspocus works with any Yjs-based editor, not just Tiptap

### Y-Sweet (Jamsocket)

- **Model**: Cloud-native Yjs server optimized for serverless and edge deployment
- **Architecture**: Built on PartyKit/Cloudflare — each document is a Durable Object at the edge
- **Features**: Yjs sync, persistence to S3/R2, authentication, per-document isolation
- **Best for**: Yjs-based collaboration with edge deployment, serverless architectures

### PartyKit (Cloudflare)

- **Model**: Programmable real-time servers at the edge — each "party" is a Durable Object
- **Features**: WebSocket rooms, state management, hibernation (sleep when idle), global edge deployment
- **Collaboration**: Built-in Y-Party integration for Yjs collaboration
- **Best for**: Custom collaboration logic, when you need more than just Yjs sync (e.g., custom validation, game logic, AI integration)

### Replicache / Zero

- **Model**: Client-side sync engine — sync arbitrary data between clients and server
- **Status**: Replicache is now in **maintenance mode** — existing users should migrate to Zero
- **Zero architecture**: `zero-cache` runs in cloud (read-only replica of PostgreSQL), `zero-client` maintains client-side store of recently used rows, query-driven sync for precise control over synced data
- **Not a CRDT**: Uses a server-authoritative model — client sends mutations, server resolves, pushes authoritative state
- **Best for**: Syncing application state (not just text), reactive UIs with optimistic updates, PostgreSQL-backed apps

### Triplit

- **Model**: Full-stack database with real-time sync — replaces separate backend + sync layer
- **Status**: Acquired by **Supabase** in 2025; pivoted to open-source initiative
- **Architecture**: Client-side database (TriplitClient) syncs with server (TriplitServer) via a custom sync protocol
- **Features**: Relational queries, schema, access control, real-time subscriptions, offline-first
- **Best for**: Full-stack apps where the database is the collaboration layer

### PowerSync

- **Model**: Sync layer between client SQLite databases and server PostgreSQL
- **Architecture**: Client runs SQLite (via wa-sqlite or native), PowerSync syncs bidirectionally with PostgreSQL
- **Features**: Offline-first, conflict resolution (configurable), real-time sync, partial sync (sync rules)
- **Best for**: Offline-first apps with PostgreSQL backends, mobile apps that need local-first data

### Electric SQL

- **Model**: Postgres-to-client sync — real-time partial replication from PostgreSQL to clients
- **Architecture**: Electric sits between PostgreSQL (CDC via logical replication) and clients, streaming changes
- **Features**: Shape-based sync (subscribe to subsets of data), real-time, PostgreSQL-native
- **Best for**: Adding real-time to existing PostgreSQL apps, when you want sync derived from your database

---

## 7. Document Collaboration Patterns

### Rich Text Collaboration

**Architecture:**
```
Editor (ProseMirror/TipTap) ←→ Y.XmlFragment ←→ Yjs Provider ←→ Server ←→ Other Clients
```

- Editor produces ProseMirror transactions (insert text, add bold, split paragraph)
- `y-prosemirror` binding converts transactions to Yjs operations
- Yjs operations sync via provider (y-websocket, Hocuspocus, Liveblocks)
- Other clients receive operations, `y-prosemirror` converts to ProseMirror transactions, editor updates

**Rich text CRDT challenges:**
- **Formatting spans**: Bold from position 5-10, concurrent insert at position 7 — does the new text inherit bold?
- **Block-level formatting**: Concurrent paragraph split and heading change
- **Embedded objects**: Images, tables, code blocks as first-class CRDT elements
- **Solution**: Yjs XML types model rich text as an XML tree — formatting is attributes on XML elements

### Code Collaboration

**Architecture:**
```
CodeMirror/Monaco ←→ Yjs (Y.Text) ←→ Provider ←→ Server ←→ Other Clients
```

- Simpler than rich text — code is plain text (Y.Text)
- `y-codemirror.next` for CodeMirror 6, `y-monaco` for Monaco
- Additional considerations: language server integration, cursor colors, syntax highlighting consistency

### Canvas/Whiteboard Collaboration

**Architecture:**
```
Canvas Renderer ←→ CRDT Document (Yjs/Automerge) ←→ Provider ←→ Server
                     ├─ Y.Map for objects (id → shape data)
                     ├─ Y.Array for z-ordering
                     └─ Y.Map for selection/presence
```

- Each shape is a CRDT map: `{id, type, x, y, width, height, color, ...}`
- Z-order is a CRDT array of shape IDs
- Concurrent move + resize: Both operations preserved (last-writer-wins per field)
- Concurrent create: Both shapes appear
- Concurrent delete + edit: Configurable (delete usually wins)

### Spreadsheet Collaboration

Most complex collaboration scenario:

- Cell values: CRDT map keyed by cell reference (A1, B2)
- Formulas: Must recalculate when referenced cells change
- Row/column operations: Insert/delete rows shifts all references — similar to text editing
- Cell formatting: Separate CRDT for formatting (bold, background color, borders)
- Concurrent formula + value edit: Both changes preserved, formula recalculates

---

## 8. Local-First and Offline-First Architecture

### What Local-First Means

From the Ink & Switch paper "Local-First Software":
1. **No spinners**: Work is done locally, instantly visible
2. **Your work is not trapped on one device**: Sync across devices
3. **The network is optional**: Full functionality offline
4. **Seamless collaboration**: No conflicts when multiple people edit
5. **The long now**: Data is stored locally, available forever (not dependent on cloud service)
6. **Security and privacy**: End-to-end encryption possible (data never decrypted on server)
7. **User retains ownership**: Not locked into a cloud service

### Architecture Pattern

```
┌─────────────────┐       ┌─────────────────┐
│  Client A        │       │  Client B        │
│  ┌─────────────┐│       │┌─────────────┐  │
│  │ Local CRDT  ││◀─sync─▶││ Local CRDT  │  │
│  │ Document    ││       ││ Document    │  │
│  └──────┬──────┘│       │└──────┬──────┘  │
│         │       │       │       │         │
│  ┌──────▼──────┐│       │┌──────▼──────┐  │
│  │ IndexedDB / ││       ││ IndexedDB / │  │
│  │ SQLite      ││       ││ SQLite      │  │
│  └─────────────┘│       │└─────────────┘  │
└────────┬────────┘       └────────┬────────┘
         │                         │
         └───────────┬─────────────┘
                     │
              ┌──────▼──────┐
              │  Sync Server │ (optional — can be P2P)
              │  (relay +    │
              │   persist)   │
              └──────────────┘
```

### Offline Sync Strategy

1. **Working offline**: All edits applied to local CRDT immediately, stored in IndexedDB/SQLite
2. **Coming back online**: 
   - Client sends its state vector (compact summary of what it knows)
   - Server computes diff (operations missed while offline)
   - Server sends diff, client merges — CRDT guarantees convergence
   - Client sends its operations (changes made offline)
   - Other clients receive those operations
3. **No conflicts**: CRDTs are conflict-free by definition — merge always succeeds

### Challenges of Local-First

- **Initial sync**: Large documents can take significant time/bandwidth for first sync
- **Tombstone accumulation**: Deleted items leave tombstones — document metadata grows indefinitely without garbage collection
- **Schema evolution**: Changing the data model while users have offline data in the old format
- **Access control changes**: User's permissions revoked while offline — local copy still has the data
- **Storage limits**: IndexedDB has per-origin storage limits (~50MB default, varies by browser)

---

## 9. Version History and Undo

### Version History in CRDTs

**Snapshot-based history:**
- Periodically save full document snapshots (e.g., every 100 operations or every minute)
- Store in a timeline: `[snapshot_t0, snapshot_t1, ...]`
- "Restore to version X" = load snapshot + replay operations after it
- Storage cost: Each snapshot is a full document copy (or compressed diff from previous)

**Operation-based history (Automerge):**
- Every change is stored with author, timestamp, and dependencies
- Can replay operations to reconstruct any point in time
- Can attribute any content to its author ("who wrote this?")
- Branching: Fork at any point, make changes, optionally merge back

### Undo in Collaborative Contexts

Undo in collaborative editing is fundamentally different from single-user undo:

**The problem:** Alice types "Hello", Bob types "World" after it, Alice presses undo. Should it:
- (a) Undo Alice's last action (remove "Hello") — leaves "World" orphaned
- (b) Undo the last action by anyone (remove "World" — Bob's text!) — violates expectations

**Solution: Selective undo (undo only your own operations)**
- Each user has their own undo stack
- Undo reverses the user's last operation, not the global last operation
- The "inverse" of the operation is applied as a new operation (not a revert)
- Other users' changes remain intact

**Implementation with Yjs:**
- `UndoManager` tracks changes by origin (user)
- Undo/redo applies inverse operations scoped to that user
- Works with Y.Text, Y.Map, Y.Array

---

## 10. Permission Models for Real-Time Collaboration

### Document-Level Permissions

Simplest model — permissions at the document/room level:

| Role | Can view | Can edit | Can comment | Can share |
|------|----------|----------|-------------|-----------|
| Viewer | Yes | No | No | No |
| Commenter | Yes | No | Yes | No |
| Editor | Yes | Yes | Yes | No |
| Owner | Yes | Yes | Yes | Yes |

Implementation: Check permission on WebSocket connect. Editors join the CRDT sync group; viewers receive a read-only stream.

### Field-Level Permissions

More granular — different permissions for different parts of the document:

- **Locked sections**: Certain sections are "locked" by admins — only specific roles can edit
- **Per-block permissions**: In block editors (Notion-like), each block can have its own permission
- **Column-level in spreadsheets**: Certain columns are read-only for certain roles

**Implementation challenge with CRDTs:**
- CRDTs don't natively support permissions — any replica can apply any operation
- Server-side validation: Server checks permissions before relaying operations; rejects unauthorized edits
- Client-side enforcement: UI disables editing for unauthorized fields (but malicious clients could bypass)
- **Belt and suspenders**: Both client-side UI restrictions AND server-side validation

### Real-Time Permission Changes

When permissions change while users are connected:
1. Server broadcasts permission change event
2. Editors with revoked access: Downgrade to viewer (disable editing, preserve read-only view)
3. Viewers with granted access: Upgrade to editor (enable editing, join CRDT sync)
4. Document sharing link changes: New connections use updated permissions; existing connections may need re-evaluation

---

## 11. Real-World Architecture Analysis

### Figma

- **Collaboration model**: Custom CRDT-based with server-authoritative components
- **Architecture**: Clients connect via WebSocket to Figma servers, operations sync in real-time
- **Key insight**: Figma uses a multiplayer server written in Rust (originally C++, migrated) that manages document state
- **Conflict resolution**: CRDT for concurrent edits, last-writer-wins for property changes on the same object
- **Presence**: Live cursors, selection highlights, viewport indicators, avatar stack
- **Scale**: Millions of users, documents with thousands of objects, real-time with sub-100ms latency
- **Why not Yjs/Automerge**: Figma predates these libraries' maturity; custom implementation optimized for their specific needs (vector graphics, component instances, auto-layout)

### Notion

- **Collaboration model**: OT-based (server-authoritative)
- **Architecture**: Block-based — each block (paragraph, heading, image) is an independent unit
- **Real-time**: WebSocket for live updates, server resolves conflicts
- **Offline**: Limited offline support (compared to local-first)
- **Key insight**: Block-level granularity means conflicts are rare (two users editing different blocks is trivially handled)
- **Scale**: Millions of workspaces, documents with thousands of blocks

### Google Docs

- **Collaboration model**: OT (Operational Transformation) — the canonical OT implementation
- **Architecture**: Client sends ops to server, server transforms and broadcasts
- **History**: Every keystroke is stored — full revision history
- **Scale**: Billions of documents, up to 100 concurrent editors per document
- **Key insight**: Google invested years perfecting OT for rich text. It works because they have the engineering resources to handle OT's correctness challenges.

### Linear

- **Collaboration model**: Custom sync engine — optimistic updates with server reconciliation
- **Architecture**: Client-side cache (IndexedDB) + server sync — feels local-first
- **Real-time**: WebSocket for live updates, presence, activity feeds
- **Key insight**: Not CRDT or OT — Linear uses a simpler model because their data (issues, projects) is structured and conflicts are rare (two people rarely edit the same field simultaneously)

---

## 12. Choosing Between CRDTs and OT

### Decision Framework

**Choose CRDTs when:**
- Offline/local-first support is required
- Peer-to-peer sync is desired (no central server dependency)
- You want proven convergence guarantees (mathematical, not implementation-dependent)
- You're starting a new project (CRDT libraries are now mature and well-documented)
- Your team is small and correctness is more important than optimization

**Choose OT when:**
- You need fine-grained server control over every operation
- You're extending an existing OT-based system
- Server-side validation before applying operations is critical (e.g., permission checks per keystroke)
- You need the smallest possible wire format (OT operations can be more compact)

**Choose neither (custom sync) when:**
- Your data model has infrequent conflicts (e.g., structured forms, issue trackers)
- Simple last-writer-wins is acceptable for your use case
- You need server-authoritative conflict resolution with custom business logic

### Migration Path

Many teams start with a simpler approach and migrate to CRDTs as collaboration requirements grow:

1. **Stage 1**: Polling + optimistic updates (refresh to see others' changes)
2. **Stage 2**: WebSocket live updates (see changes in real-time, but no concurrent editing)
3. **Stage 3**: CRDT-based collaboration (true concurrent editing with conflict resolution)
4. **Stage 4**: Local-first (offline support, P2P optional)

Each stage requires more infrastructure but provides a better user experience.
