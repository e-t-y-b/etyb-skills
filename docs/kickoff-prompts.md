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

## Prompt 2 — etyb.ai 0.1, bootstrap + E1 (run on your Mac)

```
Create a new project for etyb.ai — a macOS menu-bar app wrapping a local
daemon that gives AI coding agents per-branch code memory over MCP. The
approved plan is docs/rfc-etyb-ai-0.1.md in the e-t-y-b/etyb-skills repo
(branch claude/usability-standards-review-27ckxa) — fetch and read it end
to end first; it defines the four pillars, the 7-tool MCP surface, tech
choices, and milestones E1-E5.

Bootstrap:
1. Initialize a new git repo `etyb-ai` (private for now) with a Rust
   workspace: crates/etyb-core (indexer + storage), crates/etybd (daemon:
   MCP streamable-HTTP server on localhost with generated bearer token),
   and an apps/desktop Tauri 2 shell (menu-bar only for now). Copy the RFC
   into docs/ as the canonical plan.
2. Execute E1 (engine): tree-sitter indexing for TypeScript/JavaScript,
   Python, Go, Rust, Java into a per-project SQLite symbol/call/import
   graph; per-branch keying with content-addressed entries (file blob hash
   -> symbols; branch = tag set; `git diff --name-status
   <indexed>..<head>` as the incremental invalidation set); a file/git
   watcher that keeps the head index fresh.
3. Then E2 (protocol): expose exactly 7 MCP tools — project_list,
   code_search, trace_path, blast_radius, memory_query, memory_write,
   session_note — plus a decision-memory store with repo/branch/link
   scopes, and a headless `etybd` mode.
4. Definition of done for this session: `etybd` runs locally, Claude Code
   connects to it via .mcp.json, and code_search/trace_path answer real
   queries against this very repo. Write integration tests that index a
   fixture repo with two branches and assert branch-switch does not
   re-index unchanged content.

Decisions already made (do not relitigate): local-first, no telemetry,
no cloud in 0.1; tool budget is 7; SQLite storage; clean-room engine (no
GPL/AGPL/PolyForm dependencies — MIT/Apache/BSD only, keep a
THIRD-PARTY-NOTICES file). Open questions you may decide as you go are
listed at the end of the RFC.
```

---

Division of labor: Prompt 1 can also run in the Claude Code remote/cloud
session attached to etyb-skills. Prompt 2 needs a Mac for the Tauri shell
(E1/E2 daemon work is OS-agnostic, but you will want to run the result).
