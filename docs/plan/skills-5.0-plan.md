# etyb-skills 5.0 — execution plan (M1–M6)

Rationale: `../rfc-v5-plugin-architecture.md`. Protocol:
`00-execution-guide.md`. Repo: e-t-y-b/etyb-skills.

## Status ledger

| Task | Title | Depends | Status |
|---|---|---|---|
| M1-T1 | Portable description rewrite | — | todo |
| M1-T2 | SKILL.md body rewrite (≤150 lines) | M1-T1 | todo |
| M1-T3 | Consolidate always-on core; resolve contradictions | M1-T2 | todo |
| M1-T4 | AGENTS.md + CLAUDE.md bridge | M1-T2 | todo |
| M1-T5 | Plugin manifest + retire install.sh | M1-T2 | todo |
| M1-T6 | Token-budget CI lint | M1-T3 | todo |
| M2-T1 | Five agent definitions (Claude) | M1 | todo |
| M2-T2 | Role skills with context:fork overlays | M2-T1 | todo |
| M2-T3 | Hook scripts → stdin JSON | — | todo |
| M2-T4 | hooks.json wiring (Claude plugin) | M2-T3, M1-T5 | todo |
| M2-T5 | Adapter generator (Codex/Kiro/Cursor emission) | M2-T1 | todo |
| M3-T1 | Stack manifest generator | — | todo |
| M3-T2 | Stack-researcher fetch protocol | M2-T1, M3-T1 | todo |
| M3-T3 | Per-page currency CI | M3-T1 | todo |
| M3-T4 | anthropic-claude stack refresh | — | todo |
| M4-T1 | etyb-memory MCP server | — | todo |
| M4-T2 | Memory wiring (hook injection + fallback) | M4-T1, M2-T4 | todo |
| M5-T1 | etyb-code-memory wrapper (adopt) | — | todo |
| M6-* | Hosted stacks middleware | M3 | needs-design-session |

Release gate: **v5.0.0 = M1+M2+M3 done.** M4/M5 are 5.1 candidates. M6 has
no task breakdown yet — run a design session against RFC §3 Tier B first.

## Deviations

(record here when implementation must diverge from a spec — see guide)

---

## M1 — universal core

### M1-T1 Portable description rewrite

Rewrite `skills/etyb/SKILL.md` frontmatter to the open-spec subset. Keep
`name`, `description` (≤1,024 chars), `license: MIT`, `compatibility`,
`metadata` (author/version/category). Delete nothing else from frontmatter
without checking M2-T2 (Claude-only fields move to overlay, not to trash).

**Approved description draft (validate ≤1,024 chars, tune only if over):**

> Engineering co-pilot for any software situation — code, architecture,
> debugging, review, infra, deployment, testing, security, performance,
> AI/ML, mobile, data, compliance. The situation is the trigger: a bug, a
> stuck debug session, an architecture question, an X-vs-Y tradeoff, a
> "set up CI" ask, or a platform name in conversation (Postgres, Lambda,
> Kubernetes, React, Stripe, FHIR, Apex, Cloudflare, Vercel, Supabase,
> Expo, Bedrock). Acts as a senior engineering leader: restates the
> problem plainly, asks at most 3 questions only when the answer changes
> the work, confirms scope, then executes end-to-end — routing internally
> to specialist roles, enforcing TDD/verification/review discipline, and
> reading currency-stamped vendor stacks for post-cutoff facts. Incidents
> skip ceremony and triage immediately. Skip only for requests with no
> software or technical-decision content at all.

**Acceptance:** `wc -c` of description ≤1,024; frontmatter parses;
`skills-ref validate` (or spec-shape check) passes; trigger coverage
spot-check — the 8 scenario phrases in `tests/` (if present) still map.

### M1-T2 SKILL.md body rewrite

Target ≤150 lines. Structure (in order): identity paragraph (3 lines);
**inline tier table** replacing the charter read (Tier 0 trivial→just do;
Tier 1 single-domain→read one specialist ref; Tier 2 incident→triage now;
Tier 3-4 multi-domain→plan + gates, read `core/gates.md`); routing table
(specialists/protocols/verticals paths — keep); stacks pointer (one
paragraph: detection via `stacks/<vendor>/SKILL.md`, currency per
`core/knowledge-currency.md`); always-on disciplines (one line each, 9
lines); response contract (link `core/session.md` from M1-T3). Delete: the
module-table demanding charter-first, the adapter table (moves to
`adapters/README.md`).

**Acceptance:** ≤150 lines; a Tier-0 request needs ZERO additional file
reads to be answered; every referenced path exists; lint-portability green.

### M1-T3 Consolidate always-on core

Create `skills/etyb/core/session.md` (≤120 lines) merging: signature block
(from signature.md), response formats (tier templates, compressed),
scale-calibration table, always-on protocol one-liners. Delete the four
source files; update every reference to them (grep `signature.md`,
`response-formats.md`, `scale-calibration.md`, `always-on-protocols.md`
across repo). **Resolve documented contradictions, in this direction:**
progress markers — CTO-voice status lines allowed, file-path narration
banned (charter.md:74 wins; delete the mandate at response-formats.md:91);
clarifying questions — cap is 3 everywhere (fix backend-architect README
lines 36/41/247 and grep all specialists for `2-4|3-4` question phrasing).

**Acceptance:** four files gone, no dangling refs (`grep -r` clean);
contradiction greps return nothing; core/ total word count reduced ≥40% vs
v4 (baseline 11,847 words).

### M1-T4 AGENTS.md + CLAUDE.md bridge

Generate root `AGENTS.md` (≤60 lines): what ETYB is, how to invoke the
skill, the tier model in 5 lines, pointer to docs. Replace repo `CLAUDE.md`
content's duplication with `@AGENTS.md` import plus Claude-specific notes
only. Keep both under Codex's 32KiB chain budget (trivially true).

**Acceptance:** AGENTS.md standalone-readable; CLAUDE.md imports it; no
content duplicated between the two.

### M1-T5 Plugin manifest + retire install.sh

Add `.claude-plugin/plugin.json`: `{"name":"etyb", "version":"5.0.0",
"description":..., "author":{"name":"e-t-y-b"}, "license":"MIT",
"homepage":"https://github.com/e-t-y-b/etyb-skills"}`. Delete
`scripts/install.sh`. Rewrite `docs/installation.md`: primary =
`npx skills add e-t-y-b/etyb-skills`; Claude Code alternative = plugin
install; per-harness notes (Codex/Antigravity/Trae read `.agents/skills/`;
Kiro `.kiro/skills/`; Cursor `.cursor/skills/`). Fix the stale claims
found in review ("30 skills", VERSION check, hook-count check).

**Acceptance:** `claude plugin validate` passes (or schema-checked);
installation.md contains no command that fails on a clean machine.

### M1-T6 Token-budget CI lint

`scripts/lint-token-budget.sh`: fail if (a) sum of all `skills/**/SKILL.md`
description chars > 4,000 (~400 tokens? no — chars: use 1,600 chars ≈ 400
tokens at 4 chars/token; set limit 1,600 chars TOTAL descriptions), (b) any
SKILL.md description > 1,024 chars, (c) `skills/etyb/SKILL.md` > 150 lines.
Wire into existing CI alongside lint-portability. NOTE: stack SKILL.md
descriptions count toward (b) only, not (a) — they are separate skills
loaded per-repo; document this in the script header.

**Acceptance:** script exits 1 on a seeded violation, 0 on the real tree;
CI runs it.

---

## M2 — agents & hooks

### M2-T1 Five agent definitions

Create `agents/` (plugin-root) with five files. Shared frontmatter policy:
`model: inherit`, `memory: project`. Exact specs:

| File | tools | key prompt content source |
|---|---|---|
| `etyb-explorer.md` | Read, Glob, Grep, Bash(read-only) | port `.codex/agents/etyb_explorer.toml` developer_instructions |
| `etyb-planner.md` | Read, Glob, Grep | port etyb_planner.toml + `references/process-architecture.md` plan format |
| `etyb-reviewer.md` | Read, Glob, Grep | port etyb_reviewer.toml + `review-protocol` two-stage stage-2 rules; `maxTurns: 30` |
| `etyb-stack-researcher.md` | Read, WebFetch, Glob | fetch protocol from M3-T2; knowledge-currency soft/strict/degraded rules |
| `etyb-cartographer.md` | Read, Glob, Grep, Write (scoped `.etyb/memory/**`) | repo-map maintenance rules from RFC §6 |

**Acceptance:** each file has valid frontmatter (name, description, tools);
`claude` loads them (or schema check); reviewer/explorer/planner are
read-only-verified (no Edit/Write in tools).

### M2-T2 Role skills with context:fork

Create thin skills `skills/etyb-review/`, `skills/etyb-plan/`,
`skills/etyb-explore/` — each SKILL.md ≤40 lines, open-spec frontmatter in
the shared tree, plus a Claude overlay adding `context: fork` and
`agent: etyb-<role>`. Overlay mechanism: the adapter generator (M2-T5)
merges `adapters/claude/overlays/<skill>.yaml` into the emitted plugin
copy — the SHARED tree keeps only portable fields (this preserves
lint-portability's guarantee).

**Acceptance:** shared-tree SKILL.md files contain no Claude-only fields;
emitted plugin copies contain them; invoking /etyb-review on Claude Code
runs in a fork (manual smoke test documented in PR).

### M2-T3 Hook scripts → stdin JSON

Rewrite the five scripts under `references/protocols/*/hooks/` to read the
Claude Code stdin payload: `payload=$(cat)`; extract with
`jq -r '.tool_input.file_path // empty'` etc. Keep exit-0 advisory
semantics (warnings via `{"systemMessage": "..."}` on stdout). Each script
gets a 5-line test harness in `tests/hooks/` feeding a fixture payload.

**Acceptance:** `tests/hooks/run.sh` green; scripts no-op gracefully on
missing jq (check + plain exit 0 with note).

### M2-T4 hooks.json wiring

`hooks/hooks.json` (plugin root), correct schema:
PreToolUse[matcher Edit|Write] → pre-edit-check; PreToolUse[matcher Bash]
with `if: "Bash(git merge*)"`-style guard → pre-merge-verify;
Stop → pre-commit-review-check; SessionStart → memory summary injection
(no-op until M4-T2 lands; ship the hook stub that exits 0 fast).

**Acceptance:** schema-valid per Claude docs; hooks observed firing in a
live session (evidence in PR: transcript snippet).

### M2-T5 Adapter generator

`scripts/build-adapters.sh` (bash or node, no new heavy deps): reads
`agents/*.md` + overlay yamls and emits: `.codex/agents/*.toml` (update the
existing four, add cartographer), `adapters/kiro/` (agent JSON per Kiro CLI
reference + hooks), `adapters/cursor/.cursor-plugin/` skeleton. Generated
dirs carry a `# GENERATED — edit agents/ + overlays instead` header. CI
check: regenerate and `git diff --exit-code`.

**Acceptance:** one source edit propagates to all emissions; CI drift check
green.

---

## M3 — remote stacks

### M3-T1 Stack manifest generator

`scripts/build-manifest.sh` regenerates root `manifest.json`: every
`stacks/**/*.md` with `path`, `last_verified_on`, `drift_risk` (inherit
from stack SKILL.md products_covered where per-page absent),
`authoritative_url`. Deterministic ordering. CI drift check like M2-T5.

**Acceptance:** manifest covers all 537+ pages; jq-parses; CI green.

### M3-T2 Stack-researcher fetch protocol

Write the fetch contract INTO `agents/etyb-stack-researcher.md`: (1) fetch
`https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/manifest.json`;
(2) resolve most-specific page (product → role → index); (3) fetch page,
apply knowledge-currency soft/strict/degraded rules (strict: also fetch
authoritative_url); (4) return ≤400-token distillation + citation +
last_verified_on. No-network: return explicit degraded-mode statement.
Update `core/knowledge-currency.md` to name the researcher agent as the
single owner of this protocol.

**Acceptance:** live smoke test in PR (one soft-path and one strict-path
query transcript).

### M3-T3 Per-page currency CI

Extend `scripts/maintainer/check-currency.sh`: read EVERY page's
`last_verified_on` (not just stack SKILL.md), threshold by drift_risk
(high 90d / medium 180d / low 365d). Add batch-stamp detector: if >100
pages share one date AND that date is newer than the median git-log date of
those files by >7 days → fail with "batch re-stamp suspected". Wire into
CI as warning first (repo currently fails it), flip to hard fail after
M3-T4.

**Acceptance:** correctly flags current repo state; passes after M3-T4 for
the anthropic stack.

### M3-T4 anthropic-claude stack refresh

Update `stacks/anthropic-claude/` to the Claude 5 generation. Required
content (verify against docs.anthropic.com at execution time — do NOT trust
this plan's snapshot): Claude 5 family incl. claude-fable-5 (Mythos-class
tier above Opus; Fable = GA with dual-use safety measures, Mythos =
approved-orgs), Opus 4.8, Sonnet 5, Haiku 4.5; update rotation chart,
model-id pinning guidance, per-page `last_verified_on` to actual
verification date (per page, not batch). Also fix
`stacks/observability/otel-genai.md:38` and `backend-architect.md:189`
(retired model id in examples).

**Acceptance:** zero references to 4.7-as-current; M3-T3 green on this
stack; researcher smoke query returns Claude 5 info.

---

## M4 — decision memory (5.1 candidate)

### M4-T1 etyb-memory MCP server

New dir `servers/etyb-memory/` (Node ≥20, `@modelcontextprotocol/sdk`,
stdio + streamable HTTP modes). Tools (3): `memory_write(scope, topic,
entry)`, `memory_query(query, scope?)`, `memory_summary(budget_tokens)`.
Storage: `.etyb/memory/{repo,branch/<name>,local}/entries.jsonl` +
rendered `repo-map.md`; `local/` gitignored. Entry shape:
`{id, ts, scope, topic, text, refs[], session}`. Query = substring+topic
filter in 0.x (no embeddings). Tests: vitest, fixture repo.

**Acceptance:** all 3 tools pass integration tests; server runs stdio under
Claude Code `.mcp.json`; THIRD-PARTY-NOTICES updated.

### M4-T2 Memory wiring

SessionStart hook (from M2-T4 stub) calls `memory_summary(300)` via the
server CLI mode and emits `additionalContext`. Skills' degraded mode: if
server absent, orchestrator reads `.etyb/memory/repo-map.md` directly
(instruction in core/session.md). Cartographer agent gets write duty
documented.

**Acceptance:** live session shows injected summary; degraded path manual
test documented.

---

## M5 — code memory adopt (5.1 candidate)

### M5-T1 etyb-code-memory wrapper

`servers/etyb-code-memory/`: install-on-setup wrapper that downloads the
pinned codebase-memory-mcp release (MIT; verify license file at fetch),
generates its config, registers via `.mcp.json`, and exposes setup docs.
Add its attribution to THIRD-PARTY-NOTICES (bundling begins only if we
later vendor the binary). Wire `search_graph`/`trace_path`/`detect_changes`
into explorer/reviewer agent tool guidance (prompt text, not tools field —
MCP tools are session-level). NOTE: superseded on machines running etyb.ai
(the hub serves the same contract) — detection order: hub endpoint first,
wrapper second, nothing third.

**Acceptance:** clean-machine setup script works; explorer agent
demonstrably uses graph tools in a smoke task; notices updated.
