# RFC: ETYB v5 — Universal Package, Subagents, Remote Stacks, Repo & Code Memory

Status: draft v2 · Target: v5.0.0 · Supersedes the v4 "one skill + install.sh" distribution model.
Revision note: v2 replaces the Claude-plugin-first packaging of draft v1 with a
universal Agent Skills core (per cross-harness research, 2026-07-05) and adds
the memory-tooling and code-memory designs.

## Why v5

The v4.0.2 review (2026-07-05) found that ETYB's strongest ideas are currently
prose rather than mechanism:

- `install.sh` ships only `skills/etyb/`; the 537 stack pages never reach the
  user's machine, and the docs claim "read from disk" when the design intent
  was always remote.
- No agent definitions exist on Claude Code, so specialist work, review, and
  brainstorm all run inline in the user's session context — the opposite of
  the intent.
- Hooks exist as scripts but are unregistered, documented with an invalid
  settings schema, and read `$1` instead of Claude Code's stdin JSON.
- The always-injected skill `description` is ~3,600 chars against a 1,536-char
  platform cap, and a Tier 1 request loads ~13k tokens of scaffolding.
- The anthropic-claude stack went a full model generation stale within 7 weeks
  because currency lives in git commits, not in a continuously updatable source.

v5 keeps the v4 knowledge architecture (roles, protocols, stacks, drift-check)
and replaces the delivery mechanism with platform-native and open-standard
primitives.

## Design principles

1. **One universal package.** The core is a pure Agent Skills-standard tree
   that runs unmodified on every harness that adopted the open spec — which,
   as of mid-2026, is all of them (see §1). Per-harness material is reduced to
   thin adapter shims for the one non-portable surface: hooks.
2. **Subagents own the heavy work.** Analysis, brainstorm, review, and stack
   research run in forked contexts with their own windows. The user's session
   receives distilled results only — no lag, no context pollution.
3. **Stacks are remote documentation middleware.** Stack pages are fetched
   from the canonical source at answer time, never vendored into the install.
   Updating a page updates every user immediately.
4. **Skills are SDLC roles.** Each role (architect, QA, reviewer, domain
   expert) is a thin skill that forks into its agent and consults stacks.
5. **Token budget is a feature.** Hard ceilings per surface, enforced by
   structure (what loads) rather than discipline (what the model is told).
6. **ETYB remembers.** Two memory planes: *decision memory* (what we decided,
   conventions, trouble spots — per repo, cross-session, shared across agents)
   and *code memory* (a per-branch, commit-keyed graph of the code itself).
   Both are delivered over MCP so every harness gets them, with graceful
   degradation to platform-native memory where MCP is unavailable.

## 1. Universal packaging — one package, every harness

**The industry converged on ETYB's format.** Anthropic published the Agent
Skills standard (SKILL.md; agentskills.io, spec repo
github.com/agentskills/agentskills, Anthropic-stewarded) as an open standard
in Dec 2025. By mid-2026 the official client showcase lists **42 adopters**,
including every target harness: Claude Code, OpenAI Codex, Google Antigravity,
ByteDance Trae, AWS Kiro, Cursor (2.4+) — plus GitHub Copilot/VS Code,
Windsurf, Cline, Roo Code, OpenCode, Amp, Goose, and Factory. Codex,
Antigravity, and Trae share a vendor-neutral discovery directory,
`.agents/skills/`; several others (OpenCode, Amp) also read `.claude/skills/`
and `.agents/skills/` for compatibility. MCP is supported across the board,
including remote servers. AGENTS.md (stewarded by the Linux Foundation's
Agentic AI Foundation, 60k+ OSS projects) is read natively by Codex, Copilot,
Cursor, Windsurf, Trae, Kiro, Antigravity, and most others — but NOT by
Claude Code, whose sanctioned bridge is a `CLAUDE.md` containing `@AGENTS.md`
(kept alongside the generated AGENTS.md), nor by Gemini CLI without a
settings flip.

Note: Gemini CLI adopted the standard but is being sunset into the
closed-source Antigravity CLI (stopped serving requests June 2026) — treat
Antigravity as the Google target, not Gemini CLI.

Open-spec frontmatter is `name` (1–64 chars) + `description` (**1–1,024
chars**) required, with `license`, `compatibility`, and `metadata` as legal
optional fields — so ETYB's existing frontmatter shape is spec-compliant;
only the description length is not. The portable core targets the 1,024-char
spec cap (which also satisfies Claude Code's 1,536-char listing cap).
Everything else (`context: fork`, `agent`, `hooks`, `when_to_use`, `paths`)
is a vendor extension and belongs in adapter overlays.

The layered architecture:

| Layer | Contents | Portability |
|---|---|---|
| **Core (universal)** | `skills/` tree per the Agent Skills spec: orchestrator skill + role skills + stack trigger skills. Frontmatter restricted to the portable subset (`name`, `description`); Claude-only fields (`context: fork`, `agent`, `hooks`, `memory`) live in Claude adapter overlays, not the shared tree. | All harnesses |
| **Context file** | A short generated `AGENTS.md` (charter summary + pointer to the etyb skill; keep under Codex's 32 KiB combined-chain cap); `CLAUDE.md` containing `@AGENTS.md` for Claude Code. | All harnesses |
| **Tools (universal)** | Remote/local MCP servers: `etyb-stacks` (§3), `etyb-memory` (§6), `etyb-code-memory` (§7). MCP config shims per harness (`.mcp.json`, `config.toml`, `mcp_config.json`, `mcp.json`, `settings.json` — syntax-only differences). Build constraints from the 2026 client matrix: transport is **streamable HTTP** (SSE is deprecated in Claude Code and unsupported in Antigravity); auth must accept static bearer tokens alongside OAuth (Antigravity CLI's OAuth is currently broken); and servers must be **tool-frugal** — some harnesses cap active MCP tools (Cursor ~40, Windsurf 100 across all servers), so ETYB budgets ≤ 8 tools total across its three servers. | All harnesses |
| **Adapters (thin)** | Hook wiring + native subagent definitions where the harness supports them. Plugin packaging has converged in three harnesses, so adapters emit native plugin forms where they exist: Claude Code (`.claude-plugin/plugin.json`: agents + hooks/hooks.json), Cursor (`.cursor-plugin/plugin.json`: agents + hooks + skills), Gemini CLI (`gemini-extension.json`), plus Kiro (hooks + custom agents + `skill://` resources), Codex (config.toml + custom agents + hooks.json), Antigravity CLI (`agy plugin`). Trae: instruction-level enforcement only. | Per harness |

**Distribution:** `npx skills add e-t-y-b/etyb-skills` (vercel-labs `skills`
CLI) installs the core tree into every detected agent's native skills
directory — one command, 18+ harnesses, `skills-lock.json` for reproducible
team installs, plus listing on skills.sh and `gh skills` compatibility. Claude
Code users can alternatively install the plugin form
(`.claude-plugin/plugin.json`), which is simply the core tree plus the Claude
adapter (agents, hooks) packaged natively. `install.sh` is retired.

**Generation, not duplication:** the per-harness adapters are generated from
one source at release time (the `ruler`/`rulesync` transpiler pattern —
adopting one of those tools for the rules layer is optional; our surface is
small enough to template ourselves in `scripts/build-adapters.sh`).

This resolves the v1-draft open question: the Claude plugin is no longer the
package — it is one adapter output of the universal package.

## 2. Subagents — context isolation as the default

**Rule: any work whose intermediate reads exceed ~2k tokens runs in a fork.**

Agent roster (defined once, emitted per harness by the adapter build):

| Agent | Purpose | Tools | Notes |
|---|---|---|---|
| `etyb-explorer` | codebase analysis, "understand X" | read-only + code-memory MCP | background-capable |
| `etyb-planner` | plan drafting for Tier 3+ | read-only | returns plan artifact |
| `etyb-reviewer` | stage-2 independent review | read-only | fresh context = real independence |
| `etyb-stack-researcher` | fetch + distill remote stack pages | WebFetch/stacks MCP | the ONLY place stack pages are read |
| `etyb-cartographer` | maintain decision memory + repo map | read-only + memory MCP | see §6 |

Native emission per harness: Claude Code `.claude/agents/*.md` (with
`memory: project`), Kiro custom agents, Cursor subagents, Codex custom agents
(the four existing `.codex/agents/*.toml` are already correctly shaped),
Gemini CLI `.gemini/agents/`. On Antigravity/Trae the role skills run inline
with the same prompts (their built-in orchestration picks up parallelism).

On Claude Code, role skills bind via `context: fork` + `agent:` so invoking a
role never spends the user's window. Two-stage review finally works as
designed: stage 1 (spec conformance) in the dispatching context, stage 2 in a
genuinely fresh reviewer context, only findings returned. Brainstorm gains a
real fan-out: 2–3 explorer agents with different lenses in parallel, then
synthesis.

The v4 `subagent-protocol` prose (context packets, 5-agent cap, independence
rules) survives as the *prompt content* of these agents — it was always good
guidance; now it has a runtime.

## 3. Remote stacks — documentation middleware

Stacks stay in this repo as the editable source of truth, but consumers never
copy them. Two delivery tiers:

**Tier A (v5.0, zero infra): manifest + raw fetch.**
- `manifest.json` lists every page with `path`, `last_verified_on`,
  `drift_risk`, `authoritative_url`.
- `etyb-stack-researcher` fetches manifest → page via
  `raw.githubusercontent.com/e-t-y-b/etyb-skills/main/...`.
- Updating a page on `main` updates every user instantly.

**Tier B (v5.x, the real middleware): `etyb-stacks` MCP server.**
- Remote MCP server exposing `stack_lookup(vendor, product, role)` and
  `stack_search(query)`.
- Returns the answer-bearing *section*, not the whole page — the token
  optimization raw fetch cannot do.
- Server-side: search, usage telemetry (which pages get hit → what to refresh
  first), staleness headers, later private/paid stacks behind auth.
- Because every target harness speaks remote MCP, this is also the
  zero-install path: a harness with only the MCP config gets stack knowledge
  with no skills installed at all (the "skills-over-MCP" pattern).

**Degraded mode:** in no-network environments the researcher states plainly
that stack knowledge is unverifiable and answers from model knowledge with an
explicit flag — one owner (the researcher agent) instead of instructions
scattered across every response.

Currency enforcement moves where it can see truth: `check-currency.sh`
extends to per-page stamps; a scheduled job diffs high-drift pages against
`authoritative_url` instead of only checking stamp age; batch re-stamps (508
pages, one date) become a CI failure.

## 4. Skills as SDLC roles

- `etyb` (orchestrator) — classify, route, synthesize. Body ≤ 150 lines,
  description ≤ 1,536 chars. Tier classification inline; the charter-read
  floor (~4.5k tokens before a Tier 0 answer) is deleted.
- `etyb-architect`, `etyb-qa`, `etyb-review`, `etyb-debug`, `etyb-plan` —
  thin role skills. Role depth (current specialist READMEs, pruned of
  name-list filler) loads in the *agent's* window, never the user's.
- Verticals become stack-shaped (`stacks/verticals/fintech/...`) fetched
  remotely, since the review showed they carry dated pricing/metrics and are
  not actually time-invariant.

Token budget targets (structural, verified in CI by a lint that sums the
always-on surface):

| Surface | v4 actual | v5 ceiling |
|---|---|---|
| Always-injected description(s) | ~900 tokens | ≤ 400 total across all skills |
| Orchestrator invocation | ~4,450 min | ≤ 1,500 |
| Tier 1 answer, user-session cost | ~12,700 | ≤ 2,500 (rest in forks) |
| Tier 3 plan, user-session cost | ~33,000+ | ≤ 5,000 (plan built by etyb-planner) |

## 5. Hooks and rules — wired where the harness allows

One set of handler scripts (stdin-JSON aware; the v4 `$1` convention is
retired), wired by adapters on the harnesses with lifecycle events:

- **Claude Code** — plugin `hooks/hooks.json`, current schema (nested
  `hooks: [{type: "command", command: ...}]`; events `PreToolUse`,
  `PostToolUse`, `Stop`, `SessionStart`).
- **Kiro** — near-identical events (`preToolUse` can block, `postToolUse`,
  `stop`, `agentSpawn`).
- **Cursor** — `beforeSubmitPrompt`, `PreToolUse`, `PostToolUse`, `stop`.
- **Codex** — full hooks system (`hooks.json` in `.codex/` or `[hooks]` in
  config.toml): `session-start`, `pre/post-tool-use`, `stop`,
  `subagent-start/stop` — the existing `.codex/hooks/*.py` scripts rewire
  onto it.
- **Gemini CLI extensions** — `hooks/hooks.json` with `BeforeTool`/`AfterTool`
  events (where that runtime is still in use).
- **Antigravity / Trae** — no hook surface; the disciplines degrade to
  instruction-level enforcement in the skill text (documented per adapter,
  not silently).

Carried over, now actually firing: TDD advisory on edit-without-test,
review-evidence check on stop-with-staged-commit, merge guard on protected
branches. New: `SessionStart` injects the repo memory summary (§6).

Hard constraints ("max 5 concurrent agents", "reviewer is read-only") move
from prose into agent frontmatter (`tools`, `maxTurns`, `permissionMode`)
where platforms enforce them.

## 6. Decision memory — per-repo, cross-session, cross-agent

**What the platform gives us (Claude Code):** agent `memory: project` writes
`.claude/agent-memory/<agent>/MEMORY.md` + topic files; the first 200 lines /
25KB of MEMORY.md auto-load at agent start. Documented limits that matter:
memory is **per-agent isolated** (no sharing), **machine-local** (no sync; no
persistence across ephemeral cloud/CI sessions), **not branch-aware**, and
plain-text (no query). Other harnesses have even less.

**Therefore v5 ships `etyb-memory`, a small MCP memory server**, and treats
native memory as the degraded mode — exactly the owner's call: where platform
memory falls short, tools maintain the memories.

- **Storage:** `.etyb/memory/` in-repo (git-tracked by default → team-shared
  and cloud/CI-durable for free; `local/` subdir gitignored for personal
  notes). Structured JSONL/SQLite + rendered `repo-map.md`.
- **Tools:** `memory_write(scope, topic, entry)`, `memory_query(query)`,
  `memory_summary(budget_tokens)` — shared by ALL agents and ALL harnesses,
  which closes the per-agent isolation and cross-machine gaps at once.
- **Scopes:** `repo` (default, committed), `branch` (keyed to current branch,
  merged forward by the cartographer on branch merge), `local` (personal).
- **Injection:** `SessionStart` hook (where hooks exist) injects
  `memory_summary(300)`; elsewhere the orchestrator skill's first action is a
  `memory_summary` call.
- **Curation:** `etyb-cartographer` owns compaction of stale entries and the
  repo map (architecture, module ownership, test entry points, active plans,
  decision log), refreshing after significant merges.
- **Degraded mode:** no MCP available → fall back to native `memory: project`
  (Claude) or plain `.etyb/memory/repo-map.md` reads (everywhere).

## 7. Code memory — per-branch, commit-keyed code graph

The goal: agents query a continuously maintained graph of the code — symbols,
call chains, imports, blast radius — instead of re-reading the tree every
session; and the graph tracks **each git branch at its latest commit**.

**Landscape (researched 2026-07-05).** "Headroom" is a real tool (56k stars)
but it is a context-compression layer, not a code graph — complementary, not
competing. The relevant graph tools:

| Tool | Shape | Branch/commit aware | License |
|---|---|---|---|
| codebase-memory-mcp | tree-sitter knowledge graph, SQLite, 14 MCP tools, team-shareable snapshot; used with Claude Code/Codex/Antigravity/Kiro | working-tree polling; no per-branch pinning | MIT |
| GitNexus | tree-sitter graph + embedded graph DB, 17 MCP tools | **yes — `--branch` pinned indexes** | PolyForm Noncommercial |
| Serena | live LSP symbol server (no persisted graph) | working tree only | MIT |
| Greptile / Augment | hosted graphs, branch-aware | yes | commercial SaaS |
| Sourcegraph SCIP | compiler-grade symbol index per commit | **yes — the reference design** | open format |

**Strategy: adopt, then extend.**

- **v5.0 (adopt):** ship `etyb-code-memory` as a thin wrapper/config around
  **codebase-memory-mcp** (MIT, single static binary, SQLite, proven on the
  exact harness set we target). Explorer/reviewer/planner agents get its
  tools (`search_graph`, `trace_path`, `detect_changes`) in their tool lists.
  Published benchmarks for this approach: ~10x fewer tokens and 2x fewer tool
  calls than file-by-file exploration — directly serving the token goal.
- **v5.x (extend — the differentiator):** add the per-branch commit-keyed
  layer no permissively-licensed OSS tool ships, using the proven designs:
  - **Content-addressed entries, branch tags** (Continue.dev/Cursor pattern):
    symbols/chunks/embeddings computed once per file blob hash; a branch is a
    set of tags over content-addressed entries. Branch switch = retag the
    delta, not re-index. Reuse git's own Merkle tree for invalidation
    (`git diff --name-status <indexed>..<head>` is the exact dirty set).
  - **Nearest-commit + diff adjustment** (Sourcegraph pattern): index branch
    heads only; answer queries on other commits from the nearest indexed
    commit adjusted by git diff.
  - **Storage:** sidecar `.codememory/` (gitignored), NOT `.git/objects`;
    optional committed compressed snapshot for team warm-start
    (codebase-memory-mcp pattern).
- **Composition:** Headroom can sit in front as an optional compression proxy
  for what the graph returns; decision memory (§6) stores *why*, code memory
  stores *what is* — the cartographer links the two (decisions reference
  graph nodes).

Because delivery is MCP, code memory works identically on Claude Code, Codex,
Antigravity, Trae, Kiro, Cursor, and Gemini CLI.

## Licensing & provenance policy

ETYB remains MIT and open source. Rules that keep it that way (engineering
guidance, not legal advice):

1. **Allowed dependency licenses:** MIT, BSD, ISC, Apache-2.0, public domain.
   Apache-2.0 components keep their LICENSE/NOTICE files in any distribution;
   a `THIRD-PARTY-NOTICES` file at repo root aggregates all bundled
   attributions. **Never** GPL/AGPL (AGPL reaches through the network into
   hosted services), and never PolyForm/noncommercial (GitNexus is excluded
   for exactly this).
2. **Bundle vs. install-on-setup:** bundling a third-party binary/code means
   shipping its license text; having setup fetch it from the upstream release
   keeps obligations upstream. `etyb-code-memory` defaults to
   install-on-setup.
3. **Branding vs. provenance:** everything is presented under the ETYB
   interface, but provenance is never obscured — notices stay intact, and the
   public repo makes composition inspectable by design. Hosted services
   (stacks Tier B, hosted memory) carry no disclosure obligations because
   nothing is distributed; that is the legitimate "behind the scenes" layer.
   No third-party trademarks in ETYB branding without permission.
4. **Learn-and-build is unrestricted:** techniques (Merkle-diff indexing,
   branch-tag content addressing, nearest-commit diff adjustment, PageRank
   repo maps, SCIP ingestion) are ideas, not copyrightable expression —
   clean-room implementations carry no obligation. Verbatim snippets from
   permissive repos keep their headers. ETYB-original layers (the per-branch
   commit-keyed graph) are ETYB IP and may be licensed independently of the
   MIT core (e.g., hosted-only enhancements).
5. **Commercial SaaS (Greptile, Augment, etc.):** never wrapped or resold
   without a written agreement; at most offered as optional user-configured
   backends.

## Migration plan

- **M1 — universal core:** restructure to the portable Agent Skills tree +
  generated AGENTS.md; description ≤ 1,536 chars; `npx skills add`
  distribution + Claude plugin as adapter output; delete `install.sh`.
- **M2 — agents:** ship the five-agent roster across Claude/Codex/Kiro/
  Cursor/Gemini adapters (port the existing `.codex/agents/*.toml`); wire
  hooks with the correct schema on Claude/Kiro/Cursor.
- **M3 — remote stacks Tier A:** manifest-driven fetch via
  `etyb-stack-researcher`; per-page currency CI; refresh anthropic-claude to
  the Claude 5 generation as the proving case.
- **M4 — decision memory:** `etyb-memory` MCP server + `.etyb/memory/`
  layout + cartographer + SessionStart injection; native-memory fallback.
- **M5 — code memory v1:** adopt codebase-memory-mcp via `etyb-code-memory`
  wrapper; agent tool wiring.
- **M6 — stacks Tier B + code memory v2:** hosted `etyb-stacks` MCP with
  sectioned responses and staleness telemetry; per-branch commit-keyed layer
  on the code graph.

M1–M3 constitute a releasable v5.0.0. Each milestone is independently
shippable.

## Open questions

1. Stack/memory hosting for Tier B: GitHub-backed serverless (Cloudflare
   Worker over raw content) vs. dedicated service at `etyb.ai`? Domain
   liveness must precede shipping any URL in output.
2. How much of the 20-specialist taxonomy survives consolidation? Proposal:
   5 agents × role-skill prompts; verticals as stacks. Needs an eval pass.
3. Offline posture: optional slim cache pack for air-gapped users, or declare
   network a requirement?
4. Code memory v2 build scope: wrap-and-extend codebase-memory-mcp (upstream
   the branch layer?) vs. clean-room MCP server composing tree-sitter + SQLite
   + optional SCIP ingestion (~4–8 weeks for a v1). Depends on upstream's
   receptiveness and how central code memory becomes to ETYB's identity.
5. Embeddings in code memory: local (fastembed-class) vs. none-at-first
   (symbol graph only)? Symbol-graph-only ships faster and avoids a model
   dependency.
