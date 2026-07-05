# etyb.ai 0.1 — frozen technical contracts

Rationale: `../rfc-etyb-ai-0.1.md`. These contracts are DECISIONS. Change
protocol: see `00-execution-guide.md` → Hard rules → Deviations.

## 1. Repo layout (new repo: `etyb-ai`)

```
etyb-ai/
├── crates/
│   ├── etyb-core/        # indexer, lens extractors, storage, git watcher
│   └── etybd/            # daemon: MCP server (HTTP), control API, CLI
├── apps/desktop/         # Electron app (TypeScript, Vite, React)
│   ├── src/main/         # Electron main process (spawns/monitors etybd)
│   ├── src/renderer/     # UI: sidebar, lens canvas, inspector
│   └── src/shared/       # types generated from etyb-core (ts-rs)
├── packages/lens-schema/ # JSON Schemas for lens documents (shared truth)
├── skills/etyb-ai/       # companion skill (SKILL.md, open-spec)
├── docs/                 # RFC copy + this architecture + plan
├── THIRD-PARTY-NOTICES
└── LICENSE               # proprietary or BSL — owner decision Q5; default: not-yet-licensed private
```

Rust workspace; Electron app builds with electron-builder; `just` or `make`
for orchestration. Node ≥20, Rust stable, tree-sitter via `tree-sitter`
crate + per-language grammar crates (all MIT — verify each).

## 2. Storage (SQLite, one file per project + global catalog)

`~/.etyb/catalog.db`:

```sql
CREATE TABLE projects (id TEXT PRIMARY KEY, name TEXT NOT NULL,
  created_at INTEGER NOT NULL);
CREATE TABLE repos (id TEXT PRIMARY KEY, project_id TEXT NOT NULL
  REFERENCES projects(id), root_path TEXT NOT NULL UNIQUE,
  display_name TEXT, added_at INTEGER NOT NULL);
CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT);
```

`~/.etyb/projects/<project-id>.db` (WAL mode):

```sql
-- content-addressed: one row per unique file blob ever indexed
CREATE TABLE blobs (hash TEXT PRIMARY KEY,          -- git blob sha1/sha256
  lang TEXT, size INTEGER, parsed_at INTEGER);
CREATE TABLE symbols (id INTEGER PRIMARY KEY, blob_hash TEXT NOT NULL
  REFERENCES blobs(hash), name TEXT NOT NULL, kind TEXT NOT NULL,
  -- kind: module|class|function|method|type|const|var|endpoint|table
  start_line INTEGER, end_line INTEGER, signature TEXT, parent INTEGER);
CREATE INDEX idx_symbols_name ON symbols(name);
CREATE INDEX idx_symbols_blob ON symbols(blob_hash);
CREATE TABLE edges (src INTEGER NOT NULL, dst_name TEXT NOT NULL,
  dst INTEGER,        -- resolved symbol id, NULL if unresolved
  kind TEXT NOT NULL, -- calls|imports|extends|implements|references
  src_blob TEXT NOT NULL);
CREATE INDEX idx_edges_src ON edges(src); CREATE INDEX idx_edges_dst ON edges(dst);
-- a branch is a tag-set over blobs (Continue.dev pattern)
CREATE TABLE branch_files (repo_id TEXT NOT NULL, branch TEXT NOT NULL,
  path TEXT NOT NULL, blob_hash TEXT NOT NULL REFERENCES blobs(hash),
  PRIMARY KEY (repo_id, branch, path));
CREATE TABLE branch_state (repo_id TEXT NOT NULL, branch TEXT NOT NULL,
  indexed_commit TEXT NOT NULL, updated_at INTEGER,
  PRIMARY KEY (repo_id, branch));
-- decision memory
CREATE TABLE memory (id TEXT PRIMARY KEY, ts INTEGER NOT NULL,
  scope TEXT NOT NULL,       -- 'project' | 'repo:<id>' | 'branch:<repo>:<name>'
  topic TEXT NOT NULL, text TEXT NOT NULL,
  refs TEXT,                 -- JSON array of symbol ids / paths / urls
  session_id TEXT, archived INTEGER DEFAULT 0);
CREATE INDEX idx_memory_scope ON memory(scope, topic);
-- sessions
CREATE TABLE sessions (id TEXT PRIMARY KEY, harness TEXT, started INTEGER,
  last_seen INTEGER, tool_calls INTEGER DEFAULT 0,
  memory_writes INTEGER DEFAULT 0, notes TEXT);
```

**SQLite fitness envelope (why this holds):** precedent — the benchmarked
codebase-memory-mcp is SQLite, proven at 28M LOC; embedded graph DBs are the
riskier bet (Kuzu archived 2026). Expected scale for a large repo (~5M LOC):
2–5M symbol rows, 10–30M edge rows, single-digit-GB DB — well within SQLite
range with the indexes above. Concurrency: WAL — one writer (the indexer,
batched transactions of ≥500 files), many readers (MCP queries during
indexing). Traversals use recursive CTEs and are SAFE ONLY BECAUSE the tool
contracts bound depth (trace_path ≤4, blast_radius ≤2) — never add an
unbounded traversal tool; whole-graph products (module map for the
visualizer) are precomputed and cached in `lens_cache(project, lens, json,
computed_at)`, not queried live. `code_search` is backed by FTS5
(`symbols_fts` over name+signature, trigram tokenizer) — LIKE-scans are not
acceptable. Perf targets (soft, logged in CI): code_search p95 <100ms and
trace_path p95 <500ms on a 1M-symbol DB.

**Known-gap register vs the benchmarked tool (tracked, not hidden):**
(a) edge resolution — we ship heuristic name/import resolution; the
benchmarked tool adds LSP-style type resolution (10 langs). Upgrade path
0.2: SCIP index ingestion (Apache-2.0 format) or LSP-assisted resolution;
E1-T4 measures resolution rate so the gap is quantified per language.
(b) semantic search — we defer embeddings; their code_search is
embedding-backed. Gated by the E2-T8 benchmark: if hub-assisted answer
quality on search-style questions falls below the target, embeddings
(sqlite-vec + a local code-embedding model) get pulled into 0.2 scope.

**Incremental algorithm (frozen):** on index/update of repo R branch B:
`git rev-parse B` → head. If `branch_state` empty → full walk of
`git ls-tree -r B` (path, blob hash); parse only hashes missing from
`blobs`. Else `git diff --name-status <indexed_commit>..<head>` → upsert/
delete `branch_files` rows; parse only new hashes. Branch switch = same
path (new branch row-set), unchanged blobs are never re-parsed. Edge
resolution: within-project by name+import-path heuristic per language;
unresolved edges keep `dst NULL` (never fake certainty). Non-head-commit
queries: nearest `indexed_commit` + `git diff` adjustment of line ranges
(Sourcegraph pattern) — 0.1 may return nearest-head with a staleness
marker instead; full adjustment is 0.2.

## 3. Daemon (`etybd`)

- Config: `~/.etyb/config.toml` — `port` (default 41780), `token_file`
  (default `~/.etyb/token`, auto-generated 32-byte hex, chmod 600),
  `projects_dir`, `log_level`.
- CLI: `etybd serve` (foreground), `etybd project add <path> [--project <name>]`,
  `etybd project list`, `etybd index <repo> [--branch B]`, `etybd status`,
  `etybd connect <harness>|--all` (writes MCP config entries — always
  prints the diff and asks unless `--yes`).
- MCP: streamable HTTP at `http://127.0.0.1:<port>/mcp`, header
  `Authorization: Bearer <token>`. Binds 127.0.0.1 only.
- Control API (app-only, same port, `/control/*`, same token): project
  CRUD, index progress (SSE), lens fetch, session list. The renderer talks
  ONLY to control API; MCP is for agents.
- Watcher: `notify` on repo roots (debounced 500ms) + `.git/HEAD` watch for
  branch switches; re-index affected files on change.

## 4. MCP tool contracts (7 — frozen names and shapes)

All results include `"project"`, `"repo"`, `"branch"`, `"indexed_commit"`.

1. `project_list()` → `{projects:[{id,name,repos:[{id,name,root,branches_indexed,head_fresh:bool}]}]}`
2. `code_search({project?, repo?, query, kind?, limit=20})` — name/signature
   substring+fuzzy over symbols → `{matches:[{symbol_id,name,kind,path,lines:[s,e],signature,score}]}`
3. `trace_path({project, from_symbol, to_symbol?, direction:"out"|"in", max_depth=4})`
   → `{paths:[[{symbol_id,name,path,edge_kind}...]]}` (call/import chains)
4. `blast_radius({project, symbol_id|path, depth=2})` →
   `{impacted:[{symbol_id,name,path,via,distance}], truncated:bool}`
5. `memory_query({project, query?, scope?, topic?, limit=20})` →
   `{entries:[{id,ts,scope,topic,text,refs}]}`
6. `memory_write({project, scope, topic, text, refs?})` → `{id}` —
   scope validated against §2 grammar
7. `session_note({project, note})` → `{ok:true}` — appends to current
   session record (attribution: bearer token + connection id)

Errors: JSON-RPC error with `data.hint` (e.g. "project not indexed — run
etybd index"). Every response ≤ ~2,000 tokens by construction (limits +
truncation flags), because token saving is the product.

## 5. Lens resources (MCP resources — no tool cost)

URI scheme `etyb://` — templates:

| URI | Document |
|---|---|
| `etyb://{project}/lens/code/modules` | module-level graph: nodes {id,name,path,symbol_count}, edges {src,dst,weight} |
| `etyb://{project}/lens/code/symbol/{symbol_id}` | neighbors: the symbol, defs/refs in, calls out, 1-hop |
| `etyb://{project}/lens/data` | datastores: [{name, source(file), tables:[{name,columns:[{name,type,pk,fk}],relations}]}] |
| `etyb://{project}/lens/contracts` | services: [{name, kind:"openapi"|"graphql", endpoints:[{method,path,summary,request,response}]}] |
| `etyb://{project}/lens/sessions/recent` | last 20 sessions digest |

JSON Schemas for all five live in `packages/lens-schema/` and are the
single truth for daemon (serializer), renderer (viz), and docs. Extractors
0.1: Data — Prisma schema, Drizzle TS, SQLAlchemy models, Django models,
raw SQL DDL in `migrations/`; Contracts — OpenAPI (json/yaml), GraphQL SDL.
Extractor misses are silent-but-logged (lens shows "nothing detected —
supported formats: ...").

## 6. Companion skill (`skills/etyb-ai/SKILL.md`)

Open-spec frontmatter; description (draft, ≤1024 chars): "Local code-memory
hub is available for this machine's repositories. Before manually exploring
a codebase (listing directories, reading many files), query the etyb.ai
tools: code_search to locate symbols, trace_path/blast_radius to understand
call chains and impact, memory_query for decisions and conventions previous
sessions recorded. Read lens resources (etyb://...) for module maps, data
schemas, and API contracts instead of re-deriving them. After making
notable decisions or discovering conventions, persist them with
memory_write. Use for: understanding unfamiliar code, impact analysis
before refactors, resuming work across sessions, cross-repo questions
within a linked project." Body ≤60 lines: tool cheat-sheet + when-not-to
(tiny repos, non-indexed paths) + write-back etiquette (topic taxonomy:
`convention|decision|gotcha|plan|glossary`).

## 7. Harness auto-config matrix (`etybd connect`)

| Harness | File | Entry shape |
|---|---|---|
| Claude Code | `.mcp.json` (project) or `~/.claude.json` | `{"mcpServers":{"etyb":{"type":"http","url":"http://127.0.0.1:41780/mcp","headers":{"Authorization":"Bearer ${ETYB_TOKEN}"}}}}` + token env note |
| Cursor | `~/.cursor/mcp.json` | same http shape |
| Codex | `~/.codex/config.toml` | `[mcp_servers.etyb] url=... bearer_token_env_var="ETYB_TOKEN"` |
| Antigravity | `~/.gemini/config/mcp_config.json` | `serverUrl` field; static bearer header (OAuth broken there) |
| Trae | via UI — print instructions instead of editing | manual |

Rule: show diff + confirm before writing; `--yes` for scripts; never store
the raw token in configs that get committed — reference env var, and
`etybd connect` exports a shell snippet.

## 8. Testing strategy (definition of "tested")

- `etyb-core`: unit tests per language extractor (fixture files); the
  **two-branch fixture repo** test (create repo, branch, modify one file,
  assert: only changed blob re-parsed; branch switch re-parses nothing).
- `etybd`: integration tests driving MCP over HTTP (tools + one resource),
  auth-required test (401 without token).
- Extractors: golden-file tests (fixture schema → expected lens JSON,
  validated against lens-schema).
- Desktop: E3+ — Playwright smoke (app boots, project add flow, graph
  renders fixture project ≥1k nodes at 30fps measured via rAF sampling).
- CI: GitHub Actions matrix (macos-latest, windows-latest, ubuntu-latest)
  for crates; desktop build on macos+windows.

## 9. Dependency allowlist (licensing)

Approved: tree-sitter + official grammar crates, rusqlite, notify, git2,
axum/hyper, serde, tokio, ts-rs, Electron, React, Vite, sigma.js or regl
(graph), zod (renderer-side schema). Anything else: check license
(MIT/Apache/BSD/ISC only), add to THIRD-PARTY-NOTICES in same PR.
Explicitly banned: GitNexus (PolyForm), anything GPL/AGPL/SSPL.
