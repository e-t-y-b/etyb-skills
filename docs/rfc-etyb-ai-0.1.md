# RFC: etyb.ai 0.1 — the local agent-memory hub

Status: draft v2 · Target: etyb.ai 0.1.0 · Cross-platform desktop app (macOS,
Windows, Linux) + daemon.
Companion plan: `rfc-v5-plugin-architecture.md` (etyb-skills v5.0) — separate
product, separate release train. This document covers only etyb.ai.
Revision note: v2 upgrades the product from a menu-bar utility to a full
workspace app whose UI — visual lenses over the codebase — is a first-class
pillar, per owner direction.

## One-line thesis

A desktop app + daemon that maintains an always-fresh, per-branch memory of
every repo you work on, renders it as visual lenses (code graph, data
schema, API contracts) that humans and AI agents read alike, and serves it
to every AI coding harness — Claude Code, Cursor, Antigravity, Trae, Codex —
over one local MCP endpoint, so agents stop re-reading trees and start
querying structure.

## Why this is a product and not a feature

- Memory is a **daemon-shaped** problem: indexes must be maintained
  continuously (file watches, branch switches, commits), not rebuilt when an
  agent happens to ask. A skill can't own a background process; an app can.
- Memory is **cross-tool by nature**: the same repo is touched from Claude
  Code today, Cursor tomorrow. Knowledge captured in one session must be
  served to the next regardless of harness.
- Understanding is **visual**: "what does my agent know about this code?"
  and "how does this system fit together?" are the same question. A
  structured view that an agent can query cheaply is also the view a human
  wants to look at. The UI is not chrome around the daemon — it is the
  second consumer of the same data.

etyb-skills stays MIT and open. etyb.ai is the product built on the same
principles (local-first, standards-based), free in 0.1, with room for a paid
cloud/team tier later per the licensing policy in the v5 RFC.

## Product shape

**A cross-platform Electron workspace app + a daemon (`etybd`).** The app is
a real window — projects sidebar, lens canvas, inspector — with an optional
tray/menu-bar affordance for status and quick actions. The daemon runs
independently of the app window (login item / service) so agents are served
even when the UI is closed, and runs headless on servers.

```
┌────────────────────────────── etyb.ai app (Electron) ─────────────────────┐
│  Projects sidebar        Lens canvas                    Inspector         │
│  ├ Project A             ┌────────────────────────┐     symbol details    │
│  │  ├ repo: web          │  Code graph · Data ·   │     memory entries    │
│  │  ├ repo: api          │  Contracts · Sessions  │     session refs      │
│  │  └ repo: infra        └────────────────────────┘                       │
│  └ Project B                                                              │
├────────────────────────────── etybd (daemon) ─────────────────────────────┤
│  MCP endpoint (streamable HTTP, localhost, token-authed)                  │
│  ├── 7 tools (query surface)     ├── MCP resources (lens documents)       │
│  Indexer   tree-sitter code graph, per branch @ head commit               │
│  Lenses    extractors: code graph · db schema · api contracts             │
│  Memory    decision memory (repo / branch / link scopes)                  │
│  Watcher   FS events + git HEAD/branch tracking per repo                  │
│  Sessions  which agent, which repo, what was asked / learned              │
│  Storage   ~/.etyb/ (catalog.db + per-project sqlite + snapshots)         │
└────────────────────────────────────────────────────────────────────────────┘
        ▲                ▲                 ▲                ▲
   Claude Code        Cursor          Antigravity        Codex / Trae
        ▲
   companion skill (installed per harness: "query the hub first")
```

### Projects and repos

A **project** is the unit of work: one or more linked git repos (frontend +
api + infra of one product). You open a project and browse into any of its
repos — full tree, full graph. Cross-repo within a project in 0.1: shared
decision-memory namespace + project-wide `code_search`; deep cross-repo
graph edges (API call → handler across services) are 0.2, with the Contract
lens as the bridge.

### The five pillars

**1. Code memory (the engine).** Per repo, per git branch, keyed to the
latest commit: a symbol/call/import graph built with tree-sitter, updated
incrementally — git's own tree diff is the invalidation set;
content-addressed entries mean a branch switch is a retag, not a re-index
(the Continue/Cursor pattern); queries on non-head commits resolve via
nearest-indexed-commit + diff adjustment (the Sourcegraph pattern). Agents
get `code_search` / `trace_path` / `blast_radius` instead of re-reading the
tree — graph-first exploration benchmarks at ~10x fewer tokens and ~2x fewer
tool calls per task. Token saving is the headline agent benefit.

**2. Visual lenses (the face — and the second read surface).** Each lens is
a structured document extracted by the daemon, rendered interactively for
humans AND exposed over MCP for agents. Same data, two readers:

| Lens | Extracted from | Human view | Agent view (MCP resource) |
|---|---|---|---|
| **Code graph** | tree-sitter index | zoomable module/symbol/call graph, click-to-expand, blast-radius highlighting | graph slices (module map, neighbors-of-symbol) |
| **Data** | migrations, ORM models, SQL DDL, prisma/drizzle schemas | ER diagram: tables, relations, indexes | schema document per datastore |
| **Contracts** | OpenAPI/Swagger, GraphQL SDL, protobuf, route definitions | API surface map: endpoints, types, who-calls-what | contract document per service |
| **Sessions** | session log | timeline: which agent, which repo, what was learned/reused | recent-session digest |

Lens documents ride MCP **resources** (supported by Claude Code, Cursor,
Windsurf, Kiro, Gemini-lineage clients), so they cost zero tool slots; the
companion skill teaches agents to pull the relevant lens before diving into
files. 0.1 ships Code graph fully interactive; Data and Contracts ship as
v1 extractors + read-only views (TS/JS + Python ORMs, OpenAPI + GraphQL
first); Sessions ships as timeline.

**3. Decision memory.** Structured, queryable store of what sessions
learned: conventions, decisions, trouble spots, active plans. Scopes:
`repo`, `branch` (merged forward on branch merge), and `project` (shared
across linked repos). This is the cross-session, cross-harness memory the
platforms don't provide (native agent memory is per-agent, machine-local,
branch-blind).

**4. Skills integration (the etyb-skills bridge).** The app is also the
friendly face of the skills product: it detects installed harnesses, shows
which etyb skills are installed where, installs/updates the companion skill
and (optionally) etyb-skills 5.0 itself via the same mechanics as
`npx skills add`, and surfaces stack-currency status. etyb.ai brings the
power of the skills; the skills make every connected agent use the hub.

**5. Sessions & analytics.** Every MCP connection is a session: harness,
project, tools called, memory written/reused. The UI shows the timeline and
aggregates (queries served, memory reuse, estimated tokens saved). Where
harnesses support hooks (Claude Code, Cursor, Kiro, Codex) the app can
optionally wire SessionStart/Stop for exact boundaries; otherwise it infers
from connection + activity windows.

### MCP surface (tool-frugal by design)

Harness tool caps (Cursor ~40 active tools total) demand discipline. 0.1
ships **7 tools**: `project_list`, `code_search`, `trace_path`,
`blast_radius`, `memory_query`, `memory_write`, `session_note` — plus lens
documents as **resources** (no tool cost). Transport: streamable HTTP on
localhost with a locally generated bearer token (survives the Antigravity
OAuth bug; no cloud auth for a local daemon).

## Tech choices (proposed)

| Concern | Choice | Why |
|---|---|---|
| App shell | **Electron** | The product is a heavy interactive visualization. Electron bundles one Chromium: identical WebGL/canvas rendering and performance on macOS/Windows/Linux. Tauri's per-OS webviews (WKWebView/WebView2) vary exactly where this app can't afford variance. Cross-platform from day one. |
| Graph rendering | WebGL graph engine (e.g. sigma.js/regl-based or custom) over the lens API | Module-level graphs are thousands of nodes; SVG won't hold. Same lens API feeds MCP resources. |
| Daemon/indexer | Rust (`etyb-core` + `etybd`): tree-sitter, notify, git2 | Performance; single binary shipped inside the app and standalone for servers/CI; UI-independent by construction |
| Storage | SQLite per project + global catalog.db | Proven at 28M-LOC scale; zero-ops; snapshot/export friendly |
| App↔daemon | Same MCP endpoint + a private control channel (project mgmt, indexing progress) | The UI eats the same API agents eat — dogfooding the lens contract |
| Distribution | Signed installers: notarized .dmg, signed MSI/NSIS, AppImage/deb; auto-update | Trust matters for a daemon that reads all your code |

**Privacy stance (product-defining):** local-first, nothing leaves the
machine in 0.1, no telemetry without opt-in. The pitch is *your* code
memory on *your* device.

## Relationship to etyb-skills v5

- Two release trains: **etyb-skills 5.0** (skills, stacks, protocols — MIT,
  open) and **etyb.ai 0.1** (the app). Neither blocks the other.
- The v5 `etyb-memory` / `etyb-code-memory` MCP servers become the *degraded
  mode*: when the hub is installed, the v5 skills detect its endpoint and
  delegate; when absent, they fall back to file-based `.etyb/memory/`.
- The app doubles as an installer/updater surface for the skills (pillar 4).
- The daemon headless (`etybd`) covers the "runs on a server" half of the
  vision — same binary, no Electron.

## 0.1 scope (what ships)

- Electron workspace app (macOS + Windows; Linux best-effort) + `etybd`
  daemon with localhost MCP endpoint (token-authed); daemon runs without
  the window.
- Projects: create, link multiple repos, browse repos; index per-branch at
  head; watch (FS + git).
- The 7 MCP tools + lens resources; companion skill auto-installed into
  detected harnesses; auto-config of MCP entries (one confirmation dialog
  per harness — never silent config edits).
- Lenses: Code graph interactive; Data + Contracts v1 extractors
  (TS/JS + Python ORMs; OpenAPI + GraphQL) with read-only views; Sessions
  timeline with basic aggregates.
- Decision memory with repo/branch/project scopes.
- Headless `etybd` mode with the same config file.

Explicitly **not** in 0.1: cloud sync/team sharing (0.3+, the paid tier),
deep cross-repo graph edges (0.2), embeddings/semantic search (evaluate for
0.2 — symbol graph ships first), editing from the app (read/visualize only),
stack-currency UI beyond status.

## Milestones

- **E1 — engine:** Rust daemon: indexer (tree-sitter; launch languages
  TS/JS, Python, Go, Rust, Java), per-branch content-addressed storage, git
  watcher, incremental updates.
- **E2 — protocol:** MCP endpoint: 7 tools + lens resources; token auth;
  harness auto-config; companion skill; headless mode. *(E1+E2 = usable
  headless product.)*
- **E3 — workspace app:** Electron shell, projects sidebar + repo browser,
  Code-graph lens interactive (WebGL), memory browser.
- **E4 — lenses & sessions:** Data + Contracts extractors and views;
  sessions timeline + analytics; skills-integration panel.
- **E5 — ship:** signing/notarization on macOS + Windows, auto-update,
  onboarding ("point me at a repo → watch your agent get faster"), etyb.ai
  website + downloads.

## Open questions

1. **Engine: build vs embed.** Clean-room Rust from day one (owns the IP)
   vs embedding codebase-memory-mcp (MIT) behind our tool surface for E1
   and swapping later. Recommendation: embed only if E1 slips; the
   per-branch layer is ours either way.
2. **Graph engine:** off-the-shelf WebGL graph lib vs custom renderer —
   decide by prototyping against a large repo (target: 50k symbols
   interactive).
3. **Lens extractor priorities:** which ORMs/contract formats after the
   first wave (Prisma, Drizzle, SQLAlchemy, Django; OpenAPI, GraphQL —
   then protobuf? Rails? Spring?).
4. **Session attribution fidelity:** connection-window inference vs hook
   wiring for exact boundaries — how much in 0.1?
5. **Monetization line:** free forever = local single-user (all of 0.1);
   paid = cloud sync, cross-machine project sharing, org analytics. Decide
   before 0.3, not before 0.1.
6. **Name/domain:** etyb.ai must go live with (or before) this release —
   the v4 signature already points at etyb.ai/changelog.
