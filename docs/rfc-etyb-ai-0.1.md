# RFC: etyb.ai 0.1 — the local agent-memory hub

Status: draft · Target: etyb.ai 0.1.0 (macOS first, Windows next)
Companion plan: `rfc-v5-plugin-architecture.md` (etyb-skills v5.0) — separate
product, separate release train. This document covers only etyb.ai.

## One-line thesis

A small installable app that runs a local server on your machine and gives
every AI coding agent you use — Claude Code, Cursor, Antigravity, Trae,
Codex — the same always-fresh, per-branch memory of every repo you work on,
plus a UI to see your projects, your code graph, and what your agent
sessions are learning.

## Why this is a product and not a feature

The v5 skills RFC already concluded that memory (decision memory + code
memory) must be delivered over MCP to work across harnesses, and that the
per-branch commit-keyed code graph is the differentiator no permissively
licensed tool ships. Those conclusions point past a skills repo:

- Memory is a **daemon-shaped** problem. Indexes must be maintained
  continuously (file watches, branch switches, commits), not rebuilt when an
  agent happens to ask. A skill can't own a background process; an app can.
- Memory is **cross-tool by nature.** The same repo is touched from Claude
  Code today, Cursor tomorrow. Knowledge captured in one session must be
  served to the next regardless of harness. A per-harness plugin can't own
  that; a hub can.
- Memory is **visible.** "What does my agent know about this repo?" deserves
  a UI — projects, graph, sessions — not a JSON file.

etyb-skills stays MIT and open. etyb.ai is the product built on the same
principles (local-first, standards-based), free in 0.1, with room for a paid
cloud/team tier later per the licensing policy in the v5 RFC (ETYB-original
layers may be licensed independently).

## Product shape

**A menu-bar (macOS) / tray (Windows) app wrapping a local daemon.**

```
┌─────────────────────────────── etyb.ai app ──────────────────────────────┐
│  UI (Projects · Memory · Graph · Sessions)                               │
│  ────────────────────────────────────────────────────────────────────    │
│  Daemon                                                                  │
│  ├── MCP endpoint (streamable HTTP, localhost, token-authed)             │
│  ├── Indexer     (tree-sitter code graph, per branch @ head commit)      │
│  ├── Memory      (decision memory: structured, scoped repo/branch/link)  │
│  ├── Watcher     (FS events + git HEAD/branch tracking per project)      │
│  └── Session log (which agent, which repo, what was asked/learned)       │
│  Storage: ~/.etyb/  (catalog.db + per-project sqlite + graph snapshots)  │
└───────────────────────────────────────────────────────────────────────────┘
        ▲                ▲                 ▲                ▲
   Claude Code        Cursor          Antigravity        Codex / Trae
   (.mcp.json)    (.cursor/mcp.json) (mcp_config.json)  (config.toml / UI)
        ▲
   companion skill (installed into each harness: "query the hub first")
```

### The four pillars

**1. Code memory (the engine).** Per project, per git branch, keyed to the
latest commit: a symbol/call/import graph built with tree-sitter, updated
incrementally — git's own tree diff (`git diff --name-status
<indexed>..<head>`) is the invalidation set; content-addressed entries mean a
branch switch is a retag, not a re-index (the Continue/Cursor pattern);
queries on non-head commits resolve via nearest-indexed-commit + diff
adjustment (the Sourcegraph pattern). Agents get `code_search`,
`trace_path`, `blast_radius` instead of re-reading the tree — published
benchmarks for graph-first exploration show ~10x fewer tokens and ~2x fewer
tool calls per task.

**2. Decision memory.** Structured, queryable store of what sessions
learned: conventions, decisions, trouble spots, active plans. Scopes:
`repo`, `branch` (merged forward on branch merge), and `link` (shared across
linked repos). This is the cross-session, cross-harness memory the platforms
don't provide (native agent memory is per-agent, machine-local,
branch-blind).

**3. Multi-repo links (lightweight).** Register repos into a *link group*
(e.g. frontend + backend + infra of one product). 0.1 scope: shared decision
memory namespace + cross-repo `code_search` over the group. Deep cross-repo
graph edges (API call → handler across services) are 0.2.

**4. Sessions & analytics.** Every MCP connection is a session: which
harness, which project, which tools were called, what memory was written.
The UI shows a session timeline and simple aggregates (queries served,
memory entries created/reused, estimated tokens saved). Where harnesses
support hooks (Claude Code, Cursor, Kiro, Codex), the app can optionally
wire SessionStart/Stop hooks for richer boundaries; without hooks it infers
sessions from connection + activity windows.

### The companion skill

The app installs one small Agent Skills-standard skill (`etyb-ai`) into
detected harnesses (same auto-detection trick as the `npx skills` installer).
It teaches the agent: *before exploring a repo manually, ask the hub*
(`code_search` / `trace_path` / `memory_query`); *after decisions, write
back* (`memory_write`). This is what turns a passive server into faster
sessions everywhere — and it works day one on all harnesses because the
skill format is the open standard.

### MCP surface (tool-frugal by design)

Harness tool caps (Cursor ~40 active tools total) demand discipline. 0.1
ships **7 tools**: `project_list`, `code_search`, `trace_path`,
`blast_radius`, `memory_query`, `memory_write`, `session_note`. Transport:
streamable HTTP on localhost with a locally generated bearer token (survives
the Antigravity OAuth bug; no cloud auth needed for a local daemon).

## Tech choices (proposed)

| Concern | Choice | Why |
|---|---|---|
| App shell | **Tauri 2** | "Small app" is the brief: ~10MB installers, native menu-bar/tray on both OSes, Rust core shared with the daemon. Electron is the fallback if webview graph rendering disappoints. |
| Daemon/indexer | Rust (tree-sitter bindings, notify for FS events, git2) | Performance for indexing; single binary; ships inside the app bundle and headless on servers |
| Storage | SQLite per project + global catalog.db | Proven at 28M-LOC scale by codebase-memory-mcp; zero-ops; snapshot/export friendly |
| Graph viz | Web canvas in the Tauri webview (force/hierarchical layouts over the symbol graph) | The "code visualizer" pillar; reuse the query API the MCP tools use |
| Engine strategy | Own Rust indexer informed by the researched patterns; evaluate embedding codebase-memory-mcp (MIT) as an interim engine behind our tool surface | Licensing policy allows either; own engine is the long-term IP per the v5 RFC's build-vs-adopt question |
| Distribution | Signed+notarized .dmg (macOS), signed installer (Windows); auto-update | Trust matters for a daemon that reads all your code |

**Privacy stance (product-defining):** local-first, nothing leaves the
machine in 0.1, no telemetry without opt-in. The pitch is *your* code
memory on *your* device.

## Relationship to etyb-skills v5

- Two release trains: **etyb-skills 5.0** (skills, stacks, protocols — MIT,
  open) and **etyb.ai 0.1** (the app). Neither blocks the other.
- The v5 `etyb-memory` / `etyb-code-memory` MCP servers become the *degraded
  mode*: when the hub is installed, the v5 skills detect it (its MCP
  endpoint) and delegate; when absent, they fall back to the file-based
  `.etyb/memory/` behavior. One contract, two backends.
- The v5 stack middleware (`etyb-stacks`) stays with the skills product; the
  app may later surface stack currency in its UI, but 0.1 does not depend
  on it.
- Server mode: the same daemon runs headless (`etybd`) on a shared dev
  server or CI box — this is the "runs on a server" half of the vision, and
  it's free because the daemon is already UI-independent.

## 0.1 scope (what ships)

- macOS menu-bar app; daemon with localhost MCP endpoint (token-authed).
- Add project → index (per-branch code graph at head) → watch (FS + git).
- The 7 MCP tools; companion skill auto-installed into detected harnesses;
  auto-config of MCP entries for Claude Code, Cursor, Codex, Antigravity,
  Trae (one confirmation dialog per harness — never silent config edits).
- Decision memory with repo/branch/link scopes; lightweight multi-repo link
  groups (shared memory + cross-repo search).
- UI: Projects list · Memory browser · Graph visualizer (v1: symbols +
  calls, click-to-expand) · Sessions timeline with basic aggregates.
- Headless `etybd` mode with the same config file.

Explicitly **not** in 0.1: Windows build (0.2), cloud sync/team sharing
(0.3+, the paid tier), deep cross-repo graph edges (0.2), embeddings/semantic
search (evaluate for 0.2 — symbol graph ships first), stack-currency UI.

## Milestones

- **E1 — engine:** Rust daemon: indexer (tree-sitter, 5 launch languages:
  TS/JS, Python, Go, Rust, Java), per-branch storage, git watcher,
  content-addressed incremental updates.
- **E2 — protocol:** MCP endpoint + the 7 tools; token auth; harness
  auto-config; companion skill; headless mode.
- **E3 — app:** Tauri shell, menu-bar UX, Projects + Memory browser.
- **E4 — visibility:** graph visualizer + sessions timeline/analytics.
- **E5 — ship:** signing, notarization, auto-update, onboarding flow
  ("point me at a repo → watch your agent get faster"), etyb.ai website +
  download.

E1+E2 alone are a usable headless product for early adopters; E3–E5 make it
the app.

## Open questions

1. **Engine: build vs embed.** Start clean-room Rust (slower to first
   demo, owns the IP) or embed codebase-memory-mcp behind our tool surface
   for E1 and swap later (faster demo, migration cost)? Recommendation:
   embed for the 0.1 demo *only if* E1 slips; the per-branch layer is ours
   either way.
2. **Language coverage at launch** — the 5 proposed vs. tree-sitter's full
   range (each language adds testing surface).
3. **Session attribution fidelity** — connection-window inference vs.
   requiring hook wiring for full analytics; how much do we invest in 0.1?
4. **Monetization line** — what stays free forever (local single-user, all
   of 0.1) vs. paid (cloud sync, team/link sharing across machines, org
   analytics)? Needs deciding before 0.3, not before 0.1.
5. **Name/domain** — etyb.ai as product + domain; the v4 signature already
   points at etyb.ai/changelog, so the domain must go live with (or before)
   this release.
