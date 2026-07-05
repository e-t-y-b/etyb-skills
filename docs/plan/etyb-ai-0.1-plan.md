# etyb.ai 0.1 — execution plan (E1–E5)

Rationale: `../rfc-etyb-ai-0.1.md`. Contracts (FROZEN):
`etyb-ai-0.1-architecture.md` — cited below as ARCH §n. Protocol:
`00-execution-guide.md`. Repo: `etyb-ai` (new; created at E0-T1).

## Absorbed from etyb-skills (2026-07-05 scope decision)

All MCP-server work lives here, not in the skills repo: decision memory
(former skills M4 → E2-T4 + arch §2), code memory (former skills M5 →
E1/E2 engine + arch §2), and hosted stacks middleware (former skills M6 →
stacks Tier B, rfc-etyb-ai §3; a post-0.1 epic). No new tasks — the E-plan
below already covers memory and code memory; hosted stacks is scheduled
after 0.1.

## Status ledger

| Task | Title | Depends | Status |
|---|---|---|---|
| E0-T1 | Repo + workspace bootstrap | — | todo |
| E0-T2 | CI skeleton | E0-T1 | todo |
| E1-T1 | Storage layer (catalog + project DBs) | E0-T1 | todo |
| E1-T2 | Git integration (ls-tree/diff/HEAD watch) | E1-T1 | todo |
| E1-T3 | Parser pipeline (tree-sitter, 5 langs) | E1-T1 | todo |
| E1-T4 | Symbol/edge extraction per language | E1-T3 | todo |
| E1-T5 | Incremental indexer (content-addressed, branch tags) | E1-T2, E1-T4 | todo |
| E1-T6 | Watcher (FS + branch switch) | E1-T5 | todo |
| E2-T1 | etybd CLI + config + token auth | E1-T1 | todo |
| E2-T2 | MCP server: 7 tools | E1-T5, E2-T1 | todo |
| E2-T3 | Lens: code-graph resources | E2-T2 | todo |
| E2-T4 | Decision memory store + tools | E1-T1 | todo |
| E2-T5 | Session tracking | E2-T2 | todo |
| E2-T6 | Harness auto-config (`etybd connect`) | E2-T1 | todo |
| E2-T7 | Companion skill | E2-T2 | todo |
| E2-T8 | Token/quality benchmark harness | E2-T2, E2-T7 | todo |
| E3-T1 | Electron shell + daemon lifecycle | E2-T1 | todo |
| E3-T2 | Projects sidebar + repo browser | E3-T1, E2-T2 | todo |
| E3-T3 | Code-graph canvas (WebGL) | E3-T1, E2-T3 | todo |
| E3-T4 | Memory browser | E3-T1, E2-T4 | todo |
| E4-T1 | Data lens extractors + view | E2-T2 | todo |
| E4-T2 | Contracts lens extractors + view | E2-T2 | todo |
| E4-T3 | Sessions timeline + analytics | E2-T5, E3-T1 | todo |
| E4-T4 | Skills-integration panel | E3-T1 | todo |
| E5-T1 | Packaging + signing (mac/win) | E3 | todo |
| E5-T2 | Auto-update | E5-T1 | todo |
| E5-T3 | Onboarding flow | E3 | todo |
| E5-T4 | Website + downloads (etyb.ai) | E5-T1 | blocked (domain decision, RFC Q6) |

**Checkpoints:** after E2 → usable headless product (dogfood on this repo);
after E3 → private alpha; after E5 → 0.1.0 public.

## Deviations

(record here — see guide)

---

## E0 — bootstrap

**E0-T1 Repo + workspace.** Create `etyb-ai` repo per ARCH §1 layout. Rust
workspace with empty `etyb-core`/`etybd` crates compiling; Electron app
scaffold (Vite+React) opening a window; `packages/lens-schema` with the
five schema stubs; copy RFC + this plan + ARCH into `docs/`; LICENSE
placeholder + THIRD-PARTY-NOTICES seeded. **Accept:** `cargo build` and
`npm run dev` both work on a clean machine; repo pushed.

**E0-T2 CI.** GitHub Actions per ARCH §8 (crate tests on 3 OS; desktop
build mac+win; clippy + fmt gates). **Accept:** green on the empty
skeleton.

## E1 — engine (`etyb-core`)

**E1-T1 Storage.** Implement ARCH §2 schemas exactly (rusqlite,
migrations via `refinery` or embedded SQL versions table); typed accessors;
WAL mode. **Accept:** schema round-trip tests; concurrent read while write
test.

**E1-T2 Git integration.** git2-based: enumerate tree at ref
(path→blob hash), diff two commits (name-status), current branch + HEAD
watch hook point. **Accept:** fixture-repo tests incl. detached HEAD
(skip-with-note behavior) and renames (treated as delete+add).

**E1-T3 Parser pipeline.** tree-sitter runtime + grammars for TS/JS (incl.
TSX), Python, Go, Rust, Java; language detection by extension; parse
blob→AST with 2s/file timeout; parse failures logged, file skipped (never
abort an index run). **Accept:** parses the fixture corpus; timeout test.

**E1-T4 Symbol/edge extraction.** Per language, tree-sitter queries
extracting symbols (kinds per ARCH §2) and edges (calls, imports, extends,
implements, references). Import-path resolution heuristic per language
(TS: tsconfig paths best-effort; Python: module dotted paths; Go: package
paths; Rust: use-tree; Java: package+import). Unresolved → `dst NULL`.
**Accept:** golden tests per language: fixture file → expected
symbol/edge set; resolution rate reported (target ≥70% intra-repo on
fixtures, measured not enforced).

**E1-T5 Incremental indexer.** The frozen algorithm (ARCH §2): full walk
first time, diff-driven after; content-addressed blob reuse; branch-tag
sets; `branch_state` bookkeeping. **Accept:** THE canonical test — fixture
repo, index branch A, create branch B changing 1 of 50 files, index B:
exactly 1 blob parsed; switch back to A: 0 parsed. Plus: 10k-file
synthetic repo indexes < 60s on CI hardware (soft target, log it).

**E1-T6 Watcher.** notify-based FS watch (debounce 500ms, gitignore-aware)
+ `.git/HEAD` watch → incremental updates; backpressure (coalesce storms).
**Accept:** integration test: touch file → symbol updated within 2s;
branch switch → branch_state follows.

## E2 — protocol (`etybd`)

**E2-T1 CLI + config + auth.** ARCH §3: config.toml, token generation
(chmod 600), `serve`/`project add`/`project list`/`index`/`status`
commands; axum HTTP bound to 127.0.0.1; bearer middleware (401 without).
**Accept:** CLI integration tests; auth test.

**E2-T2 MCP tools.** Implement the 7 tools per ARCH §4 exactly (names,
shapes, limits, error hints) over streamable HTTP MCP. Response-size
guards (truncation flags). **Accept:** MCP client integration tests for
all 7; contract snapshots checked into tests (breaking change = failing
snapshot); manual smoke: Claude Code `.mcp.json` connect + code_search
against the etyb-ai repo itself (transcript in PR).

**E2-T3 Code-graph lens resources.** `etyb://{project}/lens/code/modules`
and `/lens/code/symbol/{id}` per ARCH §5, validated against lens-schema.
Module aggregation: group symbols by file/dir module; edge weights =
call-count. **Accept:** schema-validation tests; resource listed +
readable from Claude Code (@-mention smoke, transcript in PR).

**E2-T4 Decision memory.** memory table (ARCH §2) + memory_query/
memory_write behavior (scope grammar validation, archived filter) —
already counted in the 7 tools; this task is the store + scope semantics
incl. `branch:` merge-forward job (on branch delete/merge detection, copy
branch-scope entries to repo scope with provenance note). **Accept:** unit
tests incl. merge-forward; scope-validation rejection tests.

**E2-T5 Session tracking.** Connection+token → session row; tool-call and
memory-write counters; activity-window close (30 min idle). Optional
harness hint via `session_note`. **Accept:** integration test simulating
two concurrent clients → two sessions with correct counters.

**E2-T6 Harness auto-config.** `etybd connect` per ARCH §7 matrix — diff
preview + confirm, env-var token pattern, `--all`, Trae prints manual
instructions. **Accept:** golden-file tests per harness config format;
never-writes-without-confirm test.

**E2-T7 Companion skill.** Write `skills/etyb-ai/SKILL.md` per ARCH §6
(description draft provided there); `etybd connect` also installs it into
detected harnesses' skill dirs (same confirm flow). **Accept:** skill
passes spec-shape validation; description ≤1,024 chars; install flow test.

**E2-T8 Token/quality benchmark harness.** Replicate the
codebase-memory-mcp evaluation shape at small scale: a fixture set of ≥20
questions across ≥3 real OSS repos (mixed sizes), three categories —
locate ("where is X defined/handled"), trace ("what calls X / what breaks
if X changes"), explain ("how does flow Y work"). Run each question through
an agent (a) with hub tools + companion skill and (b) without (file
exploration only); record tokens, tool calls, and graded answer quality
(rubric in repo). Store results in `bench/results/` with commit + date.
**Gates (frozen):** locate+trace categories must show ≥5x token reduction
at equal-or-better quality; if search-style (locate) quality with the hub
is below the no-hub baseline, embeddings move into 0.2 scope (ARCH §2
known-gap register); if trace quality lags due to unresolved edges,
resolution upgrade (SCIP/LSP) moves into 0.2 scope. Re-run per minor
release. **Accept:** harness runs end-to-end in CI (manual trigger);
first results committed and summarized in the PR.

## E3 — workspace app

**E3-T1 Shell + daemon lifecycle.** Electron main process: find-or-spawn
etybd, health check, tray icon (status + quit), single window (sidebar /
canvas / inspector zones), control-API client with token from
`~/.etyb/token`. **Accept:** app boots with and without pre-running
daemon; daemon survives window close (setting-controlled).

**E3-T2 Projects + repo browser.** Sidebar: project CRUD, link repos
(native dir picker), index status/progress (SSE); repo browser: file tree
+ symbol outline per file (from index, not re-parse). **Accept:**
Playwright: create project → add this repo → indexed badge appears;
browse to a file → symbols listed.

**E3-T3 Code-graph canvas.** WebGL graph (sigma.js first; custom renderer
only if it fails the perf gate) rendering `/lens/code/modules`; click
module → expand symbols; click symbol → inspector shows neighbors +
blast-radius highlight (depth 2, visual). Layout: force-directed with
cached positions per project. **PERF GATE (frozen):** 5k visible nodes at
≥30fps on a 2021 MacBook Pro class machine; if sigma.js misses it after
tuning, escalate per Deviations. **Accept:** perf measurement script in
repo + recorded result; interaction tests.

**E3-T4 Memory browser.** Table+filter view over memory entries (scope,
topic, text search); manual add/archive; entry refs deep-link to graph
nodes. **Accept:** Playwright CRUD flow.

## E4 — lenses & sessions

**E4-T1 Data lens.** Extractors (ARCH §5 list: Prisma, Drizzle,
SQLAlchemy, Django, SQL DDL) → lens JSON; ER-diagram view (tables,
relations; reuse graph canvas with static layout). **Accept:** golden
tests per extractor; view renders fixture schemas; "nothing detected"
state.

**E4-T2 Contracts lens.** OpenAPI (json/yaml) + GraphQL SDL extractors →
lens JSON; API surface view (grouped endpoints, types, expandable
request/response). **Accept:** golden tests; renders petstore + a GraphQL
fixture.

**E4-T3 Sessions timeline.** Timeline view of sessions (harness, project,
duration, counters), aggregates header (7-day: queries served, memory
reuse rate, estimated tokens saved = Σ tool responses' token estimate ×
3 vs file-read baseline — label it "estimate"). **Accept:** renders
fixture session data; aggregates unit-tested.

**E4-T4 Skills panel.** Detect harnesses (config-file presence per ARCH
§7), show etyb-ai skill installed-where, install/update buttons (reuse
E2-T7 flow), link to etyb-skills. **Accept:** detection unit tests with
fixture home dirs.

## E5 — ship

**E5-T1 Packaging.** electron-builder: notarized .dmg (universal), signed
NSIS .exe, AppImage; etybd bundled per-platform (cargo target matrix);
first-run creates `~/.etyb`. Requires: Apple Developer ID + Windows
signing cert (OWNER INPUT). **Accept:** installers boot on clean VMs.

**E5-T2 Auto-update.** electron-updater against GitHub Releases; etybd
version pinned to app version; daemon restart on update with reconnect.
**Accept:** staged-update test from n-1 build.

**E5-T3 Onboarding.** First-run: pick a repo → index with live progress →
"connect your agents" (runs `connect` flows) → install companion skill →
success screen pointing at the graph. **Accept:** Playwright full flow on
fixture repo.

**E5-T4 Website + downloads.** Blocked on domain decision (RFC Q6). Scope
when unblocked: one-page site, download links, changelog page (the URL the
v4 signature already advertises).

## Owner-input checklist (things only the user can provide)

- [ ] Create the `etyb-ai` GitHub repo (private) — E0-T1
- [ ] LICENSE decision for etyb-ai (private/proprietary vs BSL vs MIT) — RFC Q5
- [ ] Apple Developer ID + Windows code-signing cert — E5-T1
- [ ] etyb.ai domain live + hosting choice — E5-T4 / RFC Q6
- [ ] Monetization line sign-off before 0.3 — RFC Q5
