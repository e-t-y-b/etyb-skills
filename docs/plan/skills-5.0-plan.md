# etyb-skills 5.0 — execution plan (M1–M3)

Rationale: `../rfc-v5-plugin-architecture.md`. Protocol:
`00-execution-guide.md`. Repo: e-t-y-b/etyb-skills.

## Status ledger

| Task | Title | Depends | Status |
|---|---|---|---|
| M1-T1 | Portable description rewrite | — | done (2026-07-05, 0846699; 967 chars) |
| M1-T2 | SKILL.md body rewrite (≤150 lines) | M1-T1 | done (2026-07-05, 0846699; 76 lines) |
| M1-T3 | Consolidate always-on core; resolve contradictions | M1-T2 | done (2026-07-05, 8be4b67; core −40.1%) |
| M1-T4 | AGENTS.md + CLAUDE.md bridge | M1-T2 | done (2026-07-05, e5f8178) |
| M1-T5 | Plugin manifest + retire install.sh | M1-T2 | done (2026-07-05, 82d6aef) |
| M1-T6 | Token-budget CI lint | M1-T3 | done (2026-07-05, cleanup commit) |
| M2-T1 | Five agent definitions (Claude) | M1 | done (2026-07-05, 1b9334e) |
| M2-T2 | Role skills with context:fork overlays | M2-T1 | done (2026-07-05, 1384e39) |
| M2-T3 | Hook scripts → stdin JSON | — | done (2026-07-05, 08e09e6; 21 tests) |
| M2-T4 | hooks.json wiring (Claude plugin) | M2-T3, M1-T5 | done (2026-07-06, local plugin install; all 6 wired hooks observed firing — see Deviations) |
| M2-T5 | Adapter generator (Codex/Kiro/Cursor emission) | M2-T1 | done (2026-07-05, salvage commit; deterministic, 20 emissions) |
| M3-T1 | Stack manifest generator | — | done (2026-07-05, f1b9f5b; 537 pages) |
| M3-T2 | Stack-researcher fetch protocol | M2-T1, M3-T1 | done (2026-07-05, 320159b) |
| M3-T3 | Per-page currency CI | M3-T1 | done (2026-07-05, abb2399) |
| M3-T4 | anthropic-claude stack refresh | — | done (2026-07-05, salvage commit; Claude 5 generation) |
| M3-T5 | Stack description compression (≤1,024 chars × 13) | — | done (2026-07-05; 13/13 ≤1,000, lint hard-fails now) |

**Scope decision (2026-07-05):** etyb-skills 5.0 contains ALL skills-level
work — M1+M2+M3 — and nothing else. Everything MCP-server-shaped moved to the
etyb.ai product (`etyb-ai-0.1-plan.md`), which owns memory, code memory, and
hosted stacks as daemon/MCP features:

| Former task | Now owned by |
|---|---|
| M4-T1/T2 etyb-memory MCP | etyb.ai decision-memory (arch §2, plan E2-T4) |
| M5-T1 etyb-code-memory | etyb.ai code-memory engine (arch §2, plan E1/E2) |
| M6 hosted stacks middleware | etyb.ai stacks Tier B (rfc-etyb-ai §3, plan E-future) |

Release gate: **v5.0.0 = M1+M2+M3 — all done.** This is the complete 5.0
scope; there is no skills 5.1. Remaining before tagging: the release-prep
debt below (needs a real Claude Code install + vendor-doc egress).

## Release checklist (do on a real machine, then tag 5.0.0)

- [x] Flip `5.0.0-dev` → `5.0.0` across VERSION + 5 bundle files + 13 stacks
      + SKILL.md (single-version policy; `validate-version-sync.sh` enforces).
- [x] Update `manifest.json` `published_at` and `.claude-plugin/marketplace.json`
      (name `etyb`, version 5.0.0) to match plugin.json.
- [x] Observe the five hooks actually firing in a Claude Code plugin install
      (M2-T4 debt — only fixture-verified so far).
- [x] Spot-verify the anthropic-claude Claude 5 facts against
      docs.anthropic.com (M3-T4 debt — vendor egress was blocked in the
      build environment).
- [ ] Merge `claude/usability-standards-review-27ckxa` → `main`; tag `v5.0.0`.
      PR opened: https://github.com/e-t-y-b/etyb-skills/pull/13 (all 6 CI
      checks green as of 2026-07-06). Merge/tag/npx-verify pending explicit
      go-ahead — see PR for the full diff before merging a major release.

## Deviations

- **Full release gate (2026-07-06, done):** ran the complete CI-equivalent
  gate locally in a clean `git worktree` of this branch's HEAD (so
  untracked local scratch dirs like `stacks/salesforce-workspace/` and
  `skills/etyb-workspace/` — pre-existing, gitignored eval debris unrelated
  to this release — can't mask or fake results): `shellcheck -x` over all
  21 shell scripts, `tests/hooks/test-*.sh` + `tests/maintainer/test-*.sh`,
  `lint-portability.sh`, `lint-token-budget.sh`, `tests/hooks/run.sh` (21
  passed), `build-manifest.sh` + `git diff --exit-code manifest.json` (no
  drift), `build-adapters.sh` + `git diff --exit-code .codex/agents
  dist/adapters` (no drift), and `CHECK_CURRENCY_STRICT=1
  scripts/maintainer/validate-pr.sh` (all 6 maintainer checks green,
  including the fixed `validate-skill-manifest-sync.sh`). `claude plugin
  validate .` also green (one pre-existing informational warning about
  root `CLAUDE.md` not loading as plugin context — expected, by design
  per M1-T4's AGENTS.md/CLAUDE.md split, not a defect). This run is what
  surfaced the marketplace/validator contradiction below.

- **Release-gate contradiction found and resolved (2026-07-06, done):**
  the M2-T4 fix (this checklist's item 1) removed `marketplace.json`'s
  `"skills": ["./skills/etyb"]` array under `strict: false` to stop
  `claude plugin install` from failing with a manifest conflict. Running
  the full release gate (this checklist's item 4) surfaced that this
  broke `scripts/maintainer/validate-skill-manifest-sync.sh`, which
  hard-asserts the marketplace plugin installs *exactly* `./skills/etyb`
  — a frozen v4-era single-skill invariant that M2-T2 (three thin
  `etyb-explore`/`etyb-plan`/`etyb-review` role skills, shipped in v5)
  already superseded but this validator was never updated for.

  Investigated properly rather than picking whichever side was easier to
  make pass: reinstalling the real plugin with `strict: true` restored
  (and `skills: ["./skills/etyb"]` re-added) *did* clear the "conflicting
  manifests" error, but `claude plugin details etyb@etyb-skills` then
  showed only **1** skill loaded (`etyb`) instead of 4 — `strict: true`
  with an explicit-but-incomplete `skills` array silently drops the
  auto-discovered role skills, which would have shipped v5.0.0 with
  `/etyb-review`, `/etyb-plan`, `/etyb-explore` unreachable via the
  Claude Code plugin path. Listing all four skills explicitly
  (`strict: true` + `skills: ["./skills/etyb", "./skills/etyb-explore",
  "./skills/etyb-plan", "./skills/etyb-review"]`) is the configuration
  that is simultaneously conflict-free AND loads the full component
  inventory (4 skills, 5 agents, hooks) — confirmed via
  `claude plugin details` after a clean uninstall/reinstall.

  Fixed `validate-skill-manifest-sync.sh` to check the marketplace
  `skills` array against the *actual* set of `skills/etyb*` directories
  (computed, not hardcoded) instead of a hardcoded single value, so this
  can't silently drift out of sync with `skills/` again the next time a
  role skill is added or removed. `.claude-plugin/marketplace.json` is
  the final, tested state; the script's own docstring calling this "the
  v4 single-skill layout" was corrected too.

- **M3-T4 ledger note — Claude 5 fact spot-check (2026-07-06, done):**
  dispatched 3 parallel research agents (with live WebFetch access — vendor
  egress is NOT blocked from this environment, unlike the build environment
  the M3-T4 debt note refers to) to check every checkable factual claim
  (model IDs, pricing, context windows, dates, API behavior) across the 20
  pages the M3-T4 refresh touched, against `platform.claude.com` (the
  domain `docs.anthropic.com` now 301-redirects to — same content).
  Verdict: **0 wrong facts** in the core model pages (`claude-sonnet.md`,
  `claude-opus.md`, `claude-haiku.md`, `index.md`, `SKILL.md`,
  `ai-ml-engineer.md`) and cloud/role-overlay pages (`bedrock-provider.md`,
  `vertex-ai-provider.md`, `backend-architect.md`, `system-architect.md`,
  `security-engineer.md`) — including the two specific lines a prior review
  flagged for a "retired model id" (`backend-architect.md:189`,
  `stacks/observability/otel-genai.md:38`), both confirmed already fixed,
  no action needed. The M3-T4 debt claim that vendor egress was blocked
  turned out to be environment-specific to the prior build sandbox, not a
  durable constraint.

  The API/SDK-surface pages (`claude-api.md`, `anthropic-sdk.md`,
  `claude-agent-sdk.md`, `extended-thinking.md`, `citations.md`,
  `pdf-input.md`, `files-api.md`, `batches-api.md`, `computer-use.md`) had
  6 real defects, fixed (re-stamped to 2026-07-06, the only pages touched):
  1. `claude-agent-sdk.md` — the two Python code samples used an invented
     `Agent`/`.run()`/`.spawn_subagent()` API shape. The real SDK is
     function-based: `query()` + `ClaudeAgentOptions`, with sub-agents
     declared via `AgentDefinition` in `options.agents` and invoked through
     the built-in `Agent` tool, not called imperatively. Rewrote both
     samples against the live `code.claude.com/docs/en/agent-sdk/overview`
     examples; also fixed the dead `authoritative_url`
     (`docs.anthropic.com/en/api/claude-code-sdk` → `code.claude.com/docs/en/agent-sdk/overview`).
  2. `anthropic-sdk.md` — claimed 5 first-party SDK languages (Python, TS,
     Go, Java, Ruby) with PHP/C#/Rust/Kotlin as "community." Anthropic now
     ships **7** first-party SDKs — C# (`Anthropic` on NuGet) and PHP
     (`anthropic-ai/sdk` on Packagist) graduated to first-party (both still
     beta). Table and prose updated.
  3. `pdf-input.md` — claimed "~100 pages" max; actual limit is **600
     pages per request, 100 only for 200k-context models** (Haiku 4.5).
     Also claimed encrypted/scanned PDFs are "OCR'd internally" —
     scanned/image PDFs are handled via vision (true), but
     encrypted/password-protected PDFs are explicitly **not supported**
     (rejected, not processed) — the file's own Gotchas section already
     half-hedged this ("verify current support") while the currency-anchor
     bullet flatly asserted the wrong thing. Fixed both.
  4. `files-api.md` — claimed "GA 2025"; the Files API is **still beta**
     as of mid-2026 (requires the `anthropic-beta: files-api-2025-04-14`
     header on every call, including Messages requests that reference a
     `file_id` — the file's own code sample was missing it). Storage quota
     was described as "per-workspace"; it's **500GB per organization**
     (pools across workspaces) plus a 500MB per-file limit the file didn't
     mention at all. Also added: Files API isn't available on Bedrock or
     Google Cloud at all (Claude API / Claude Platform on AWS / Microsoft
     Foundry only), which contradicted an anti-pattern suggesting Bedrock/
     Vertex as a residency workaround.
  5. `batches-api.md` — claimed "polling-based status (or webhook on
     enterprise tiers)"; live docs describe polling only, no webhook
     mechanism at any tier. Removed the webhook claim.
  6. All 5 edited files' `authoritative_url` and inline doc links updated
     from `docs.anthropic.com` to `platform.claude.com` (the real
     destination after the 301) or, for the Agent SDK, `code.claude.com`
     (a distinct product domain, not a redirect).

  Not edited (no wrong facts found, so not re-stamped, per the checklist's
  "re-stamp only pages you actually edit"): `claude-api.md`,
  `extended-thinking.md`, `citations.md`, `computer-use.md` — a few minor
  omissions were noted (e.g. citations/structured-outputs incompatibility,
  computer-use per-model image-size limits) but omissions aren't factual
  errors and are out of scope for a spot-check.

- **Version flip (2026-07-06, done):** `5.0.0-dev` → `5.0.0` across VERSION,
  the 4 other bundle files (package.json, manifest.json, marketplace.json,
  plugin.json), all 13 `stacks/*/SKILL.md`, `skills/etyb/SKILL.md`, and the
  3 role-skill SKILL.md files (`etyb-explore`/`etyb-plan`/`etyb-review`);
  `dist/adapters/**` and `.codex/agents/**` regenerated via
  `build-adapters.sh` to pick up the bump (0 hand-edits to generated
  output). `manifest.json`'s `bundle.published_at` set to 2026-07-06.
  `validate-version-sync.sh` green. CHANGELOG.md's `[Unreleased]` section
  converted to `[5.0.0] — 2026-07-06`.

  Found and fixed two pre-existing bugs while regenerating `manifest.json`
  to verify zero drift (its own release-gate check, run early since the
  version bump touches it):
  1. **`stacks/vercel/marketplace.md` was untracked** — `.gitignore:13` had
     a bare `MARKETPLACE.md` pattern intended only for the repo-root
     internal doc, but gitignore patterns without a `/` match the basename
     anywhere in the tree, and on this (case-insensitive) filesystem it
     also silently matched `stacks/vercel/marketplace.md`. That page (real
     content: Vercel Marketplace integrations, referenced from
     `stacks/vercel/SKILL.md`'s prose) had never been committed. Fixed the
     pattern to `/MARKETPLACE.md` (root-anchored) and `git add -f`'d the
     recovered page; `manifest.json` now lists 538 stack pages (was 537).
  2. Verified the `build-manifest.sh` / `build-adapters.sh` drift checks
     both by regenerating in-place and, separately, in a filtered copy
     under scratch space (excluding an untracked, gitignored local
     `stacks/salesforce-workspace/` eval-scratch directory left over from
     unrelated prior work, which the manifest generator's `stacks/**/*.md`
     glob doesn't skip since it isn't gitignore-aware) — confirms the
     generators are drift-clean against the real committed tree, not just
     against local disk state that wouldn't exist in a clean CI checkout.

- **M2-T4 ledger note — live hook observation (2026-07-06, done):** installed
  the repo as a real Claude Code plugin (`claude plugin marketplace add
  /path/to/etyb-skills` + `claude plugin install etyb@etyb-skills`) rather
  than only running the fixture suite. This surfaced and fixed two real
  bugs the fixtures could not catch:
  1. **Marketplace/plugin manifest conflict.** `claude plugin list` reported
     `etyb@etyb-skills` as "✘ failed to load — Plugin etyb has conflicting
     manifests: both plugin.json and marketplace entry specify components.
     Set strict: true in marketplace entry or remove component specs from
     one location." `.claude-plugin/marketplace.json`'s plugin entry
     declared `"skills": ["./skills/etyb"]` while `strict: false`, which
     conflicts with `plugin.json`'s convention-based auto-discovery of the
     same skill. First fix attempt: removed the redundant `skills` array
     from the marketplace entry (kept `strict: false`) — this cleared the
     conflict and loaded the full component inventory (`Skills (4) etyb,
     etyb-explore, etyb-plan, etyb-review`; `Agents (5)
     etyb-stack-researcher, etyb-reviewer, etyb-planner, etyb-explorer,
     etyb-cartographer`; `Hooks (4) PreToolUse, PostToolUse, Stop,
     SessionStart`), but was later found to conflict with
     `validate-skill-manifest-sync.sh`'s frozen assertion that the
     marketplace entry explicitly lists its skills — see the
     "Release-gate contradiction found and resolved" entry below for the
     final configuration (`strict: true` + all four skills listed
     explicitly), which satisfies both the real plugin loader and the
     validator.
  2. **`hooks/session-start-memory.sh` shipped without the executable bit**
     (git mode `100644`; every other hook script is `100755`). Since
     `hooks.json` invokes it directly by path (no `bash` prefix), Claude
     Code would hit `permission denied` (exit 126) the first time
     SessionStart fired on a real install. Reproduced directly against the
     installed plugin cache path
     (`~/.claude/plugins/cache/etyb-skills/etyb/5.0.0-dev/hooks/session-start-memory.sh`):
     `(eval):30: permission denied ... exit=126`. Fixed with `chmod +x` +
     `git add` (mode now `100755`); after refreshing the marketplace and
     reinstalling, the same invocation returned `exit=0` with no output, as
     designed.

  With both fixed, exercised all 6 wired hook commands directly at the
  **installed plugin path** (`CLAUDE_PLUGIN_ROOT` resolved to the plugin
  cache dir, not the repo checkout) with realistic Claude-Code-shaped stdin
  payloads — this is stronger evidence than the fixture suite alone, since
  it validates the actual materialized install, not the source tree.
  Observed output:
  - `PreToolUse[Edit|Write] → pre-edit-check.sh`: editing a `.js` file with
    no sibling test emitted `{"systemMessage": "TDD warning: no test file
    found for .../app.js. ..."}`, exit 0.
  - `PostToolUse[Edit|Write] → post-edit-log.sh`: silent exit 0; appended
    `{"timestamp":"...","file":"app.js","task":"unknown","plan":"unknown"}`
    to `.etyb/edit-log.jsonl`.
  - `PostToolUse[Bash] → post-test-log.sh`: a failing test command (`exit_code:
    1`) emitted `{"systemMessage": "[TDD] Test command failed (exit 1) ...
    Logged to .etyb/test-log.jsonl."}` and appended a `"result":"fail"`
    entry.
  - `Stop → pre-commit-review-check.sh`: a staged commit with no review
    marker emitted `{"systemMessage": "[review-protocol] No review evidence
    detected before commit. ..."}`.
  - `PreToolUse[Bash, git merge*] → pre-merge-verify.sh`: `git merge
    feature-x` on branch `main` with no passing entry in
    `.etyb/test-log.jsonl` emitted the `[git-workflow]` warning; after
    appending a `"result":"pass"` entry it went silent (exit 0), confirming
    both the warn-path and the clean-path.
  - `SessionStart → session-start-memory.sh`: silent exit 0 (stub, as
    designed) — this is the one that was broken pre-fix (see above).

  Full nested-session observation via `claude -p --debug hooks` inside the
  installed plugin was not reachable in this non-interactive environment —
  a spawned `claude -p` subprocess hit `401 Invalid authentication
  credentials` (no separate credential path available to a nested
  process here). The installed-path direct-invocation method above is the
  substitute and is the stronger check of the two: it exercises the exact
  materialized files Claude Code would run, catching the permission-bit
  bug that a source-tree fixture run cannot see.

  Also fixed while here: `docs/installation.md`'s "Enforcement Status" note
  claimed "no hook wiring is installed and none needs verifying" — stale
  since M2 landed hook wiring. Rewritten to describe the actual advisory
  (non-blocking) hook behavior on the Claude Code plugin path, and that
  skills-CLI installs on other harnesses do not get hook enforcement.

- **M2/M3 stage-2 review (2026-07-05, done):** independent review of range
  9562de7..HEAD found 0 blockers, 2 majors, 2 minors — all resolved: currency
  CI flipped to CHECK_CURRENCY_STRICT=1 (M-1); the etyb_docs_researcher→
  etyb_stack_researcher rename's 4 dangling refs fixed in codex ADAPTER/
  enforcement-notes, the .codex prompt hook, and the eval keyword (M-2);
  the one content-free re-stamp reverted to 2026-05-14 (m-1). Accepted
  limitation (m-2): frontmatter `tools:` can't express Bash-read-only or a
  Write path-scope, so etyb-explorer's Bash and etyb-cartographer's Write
  boundaries are prompt-enforced, not tool-enforced — hardened when hooks
  can gate tool args.
- **M2/M3 interruption (2026-07-05):** org monthly spend limit killed the
  M2-T4/M2-T5/M3-T4 subagents mid-task; the orchestrator verified and
  landed their near-complete working-tree output directly (salvage
  commits). Outstanding debt: (a) the milestone-wide stage-2 review of
  M2+M3 has NOT run yet — do it first next session; (b) M2-T4 live-session
  hook observation impossible in this environment — verify on a real
  Claude Code install; (c) M3-T4 fact-checking used repo knowledge +
  reachable sources only (vendor-doc egress blocked here) — spot-verify
  model facts against docs.anthropic.com before release.

- **M1 process:** per-task `feat/` branches replaced by task-scoped commits
  on the session branch `claude/usability-standards-review-27ckxa` (remote
  execution environment restricts pushes to the designated branch).
- **M1-T1:** `validate-frontmatter.sh` hard-requires a literal `Triggers:`
  line; one sentence added to the approved description draft (971/1,024
  chars stripped total). Draft in this plan updated in spirit, not rewritten.
- **M1-T6 → M3-T5:** all 13 `stacks/*/SKILL.md` descriptions exceed the
  1,024-char spec cap (1.7k–3.5k). Out of M1 scope (stacks frozen until
  M3). Lint warns on `stacks/` until M3-T5 compresses them, then flips to
  hard fail.
- **Versioning:** whole repo bumped to `5.0.0-dev` (single-version policy
  spans VERSION + 5 bundle files + 13 stacks + SKILL.md frontmatter); flip
  to `5.0.0` at release. plugin.json follows the same policy (plan said
  `5.0.0`).
- **M1-T3:** hitting the ≤7,100-word core target required also compressing
  `version-awareness.md` (462→284 words) — no behavior lost, fixed its
  dangling `update.sh` reference.
- **v4 hook-lint finding:** `lint-portability.sh` required hook wiring in
  `.claude/settings.json`, which is *gitignored* — the check could pass
  only on the original author's machine. Replaced with script-existence
  checks + a TODO to re-add wiring checks against plugin `hooks/hooks.json`
  when M2-T4 lands.

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
