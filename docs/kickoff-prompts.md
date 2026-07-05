# Kickoff prompts

The full execution plans live in `docs/plan/` — task-level breakdowns,
frozen technical contracts, status ledgers, and the session protocol. These
prompts point a fresh session at them. Run the same prompt every session;
the status ledger tells it where work stands.

Scope split (2026-07-05): **etyb-skills 5.0** = all skills-level work
(M1+M2+M3 — done). **etyb.ai 0.1** = everything MCP-server-shaped (memory,
code memory, hosted stacks) plus the desktop app.

---

## Prompt 1 — etyb-skills 5.0 release finalization (real Claude Code install)

Needs a local machine: live hook observation, vendor-doc egress for the
anthropic fact-check, and the merge/tag. Run in a Claude Code session on the
cloned repo, on branch `claude/usability-standards-review-27ckxa`.

```
You are finalizing the etyb-skills 5.0 release. Read
docs/plan/skills-5.0-plan.md — M1+M2+M3 are all done; work ONLY the
"Release checklist" section at the top. Do each item, checking it off in
the plan file as you go, committing per item:

1. Install this repo as a Claude Code plugin locally and confirm all five
   hooks in hooks/hooks.json actually fire (edit a file without a test →
   TDD warning; stage a commit → review-evidence warning; attempt a merge
   into main → pre-merge warning). Paste the observed systemMessage output
   into the M2-T4 ledger note. If a hook misbehaves, fix the script or
   wiring (the scripts are advisory, exit 0, stdin-JSON).
2. Spot-verify the Claude 5 facts in stacks/anthropic-claude/ against
   docs.anthropic.com (models, IDs, pricing, context windows). Fix any
   drift; re-stamp only pages you actually edit to today's date (the
   currency CI treats batch stamps as a failure).
3. Flip 5.0.0-dev -> 5.0.0 across VERSION + the 5 bundle files + 13 stacks
   + SKILL.md frontmatter; update manifest.json published_at and
   .claude-plugin/marketplace.json (name etyb, 5.0.0). Run
   scripts/maintainer/validate-version-sync.sh until green.
4. Run the full gate: CHECK_CURRENCY_STRICT=1 scripts/maintainer/validate-pr.sh,
   scripts/lint-portability.sh, scripts/lint-token-budget.sh,
   tests/hooks/run.sh, and both drift checks (build-manifest, build-adapters
   + git diff --exit-code). All must pass.
5. Open a PR from claude/usability-standards-review-27ckxa to main using the
   repo's PR template; on merge, tag v5.0.0. Then publish/verify
   `npx skills add e-t-y-b/etyb-skills` resolves the new version.

Contracts are frozen (see docs/plan/00-execution-guide.md). Record any
forced change in the plan's Deviations section.
```

## Prompt 2 — etyb.ai 0.1 bootstrap + engine (local; new repo)

Needs a local machine: a new `etyb-ai` GitHub repo, Rust + Electron
toolchains, and (for later epics) code-signing certs. This repo owns ALL
MCP work — memory, code memory, and eventually hosted stacks.

```
Fetch docs/plan/00-execution-guide.md, docs/plan/etyb-ai-0.1-plan.md, and
docs/plan/etyb-ai-0.1-architecture.md from the e-t-y-b/etyb-skills repo
(branch claude/usability-standards-review-27ckxa, or main once merged) and
follow the guide exactly. Work the etyb.ai train in a new `etyb-ai` repo.
Note the "Absorbed from etyb-skills" section: this product owns decision
memory, code memory, and hosted stacks — all the MCP-server work that is
NOT in the skills repo.

Start at E0-T1 (create the repo + Rust/Electron workspace, copy the three
plan docs + rfc-etyb-ai-0.1.md into docs/) and proceed down the status
ledger, taking the first unblocked `todo`, executing with subagents per the
guide's dispatch table, verifying acceptance criteria, running two-stage
review, updating the ledger, and committing per task. The architecture file
is a FROZEN contract — storage schemas, the 7 MCP tool shapes, lens URIs,
the incremental-index algorithm, repo layout — implement to it; record any
forced deviation and stop for sign-off. Checkpoints: E2 done = usable
headless product (dogfood by connecting Claude Code to etybd and querying
this repo); E3 done = private alpha. The owner-input checklist at the end of
the plan lists what only the owner can provide (repo creation, license
choice, signing certs, domain) — surface those when a task hits one.

Decisions already frozen: Electron (not Tauri); local-first, no telemetry,
no cloud in 0.1; 7 MCP tools + lenses as resources; SQLite storage;
clean-room engine, MIT/Apache/BSD deps only + THIRD-PARTY-NOTICES.
```

---

Division of labor: Prompt 1 finishes the skills release and can only fully
complete on a real Claude Code install (hooks + vendor egress + merge).
Prompt 2 starts etyb.ai and needs your machine for the new repo and the
Electron/daemon toolchains.
