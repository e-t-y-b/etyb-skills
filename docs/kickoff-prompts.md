# Kickoff prompts

Copy-paste prompts to start each release train in a fresh agent session.
Both reference the RFCs on branch `claude/usability-standards-review-27ckxa`
(merge that branch to main first, or point the session at the branch).

---

## Prompt 1 — etyb-skills 5.0, Milestone M1 (any environment)

```
You are working in the e-t-y-b/etyb-skills repo. Read
docs/rfc-v5-plugin-architecture.md end to end — it is the approved plan —
then execute Milestone M1 (universal core) exactly as specified:

1. Restructure the skill tree to the portable Agent Skills open-standard
   subset: skills/etyb/SKILL.md keeps only spec frontmatter (name,
   description, license, compatibility, metadata); move Claude-only fields
   into an adapter overlay. Rewrite the description to <= 1,024 characters
   while preserving the trigger coverage (situation-based, vendor names,
   role names).
2. Delete the charter-read floor: fold Tier 0-4 classification into the
   SKILL.md body (<= 150 lines total); collapse signature.md,
   response-formats.md, scale-calibration.md, and always-on-protocols.md
   into one always-on core module; resolve the documented contradictions
   (progress-marker narration banned in charter.md but mandated in
   response-formats.md; clarifying-question caps 3 vs 2-4).
3. Generate AGENTS.md from the charter (short, points at the etyb skill)
   and a CLAUDE.md that imports it via @AGENTS.md.
4. Add .claude-plugin/plugin.json so the repo doubles as a Claude Code
   plugin; retire scripts/install.sh and fix docs/installation.md to
   document `npx skills add e-t-y-b/etyb-skills` as the universal install
   plus the plugin path for Claude Code.
5. Add a CI lint that fails if the always-injected surface (all skill
   descriptions summed) exceeds 400 tokens or SKILL.md exceeds 150 lines.

Constraints: keep the stacks/ tree untouched (M3 owns it); do not break
scripts/lint-portability.sh — update it where the file layout moves; every
doc claim must match what actually ships (the v4 review failed on
claim/reality gaps — docs/rfc-v5-plugin-architecture.md "Why v5" lists
them). Work on a feature branch, commit in reviewable chunks, and finish
with a summary of what changed vs. the RFC.
```

## Prompt 2 — etyb.ai 0.1, bootstrap + E1/E2 (run locally)

```
Create a new project for etyb.ai — a cross-platform Electron workspace app
plus a local daemon (etybd) that gives AI coding agents per-branch code
memory over MCP and renders the codebase as visual lenses (code graph, data
schema, API contracts) that humans and agents read alike. The approved plan
is docs/rfc-etyb-ai-0.1.md in the e-t-y-b/etyb-skills repo (branch
claude/usability-standards-review-27ckxa) — fetch and read it end to end
first; it defines the five pillars, the 7-tool + lens-resources MCP
surface, tech choices, and milestones E1-E5.

Bootstrap:
1. Initialize a new git repo `etyb-ai` (private for now): a Rust workspace
   with crates/etyb-core (indexer + lens extractors + storage) and
   crates/etybd (daemon: MCP streamable-HTTP server on localhost with
   generated bearer token, runs without any UI), plus apps/desktop — an
   Electron app scaffold (projects sidebar, lens canvas placeholder,
   private control channel to the daemon). Copy the RFC into docs/ as the
   canonical plan.
2. Execute E1 (engine): tree-sitter indexing for TypeScript/JavaScript,
   Python, Go, Rust, Java into a per-project SQLite symbol/call/import
   graph; per-branch keying with content-addressed entries (file blob hash
   -> symbols; branch = tag set; `git diff --name-status
   <indexed>..<head>` as the incremental invalidation set); a file/git
   watcher that keeps the head index fresh. Projects link multiple repos
   and share a decision-memory namespace.
3. Then E2 (protocol): exactly 7 MCP tools — project_list, code_search,
   trace_path, blast_radius, memory_query, memory_write, session_note —
   plus lens documents (code-graph slices first) exposed as MCP RESOURCES
   so they cost no tool slots; decision-memory store with
   repo/branch/project scopes; headless `etybd` mode.
4. Definition of done for this session: `etybd` runs locally, Claude Code
   connects via .mcp.json, code_search/trace_path answer real queries
   against this very repo, and the code-graph lens resource returns a
   module-level graph slice. Integration tests: index a fixture repo with
   two branches and assert branch-switch does not re-index unchanged
   content.

Decisions already made (do not relitigate): Electron (bundled Chromium =
deterministic WebGL for the graph canvas across macOS/Windows/Linux);
local-first, no telemetry, no cloud in 0.1; tool budget is 7 with lenses
as resources; SQLite storage; clean-room engine (no GPL/AGPL/PolyForm
dependencies — MIT/Apache/BSD only, keep a THIRD-PARTY-NOTICES file). The
UI (E3: interactive WebGL code graph; E4: data + contracts lenses,
sessions timeline) comes after the engine proves out — do not start the
visual canvas before E1/E2 are done. Open questions you may decide as you
go are listed at the end of the RFC.
```

---

Division of labor: Prompt 1 can also run in the Claude Code remote/cloud
session attached to etyb-skills. Prompt 2 runs locally (E1/E2 are
OS-agnostic; the Electron app and installers are why you want your own
machine).
