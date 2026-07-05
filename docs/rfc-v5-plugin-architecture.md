# RFC: ETYB v5 — Plugin, Subagents, Remote Stacks, Repo Memory

Status: draft · Target: v5.0.0 · Supersedes the v4 "one skill + install.sh" distribution model.

## Why v5

The v4.0.2 review (2026-07-05) found that ETYB's strongest ideas are currently
prose rather than mechanism:

- `install.sh` ships only `skills/etyb/`; the 537 stack pages never reach the
  user's machine, and the docs claim "read from disk" when the design intent
  was always remote.
- No `.claude/agents/*.md` exist, so specialist work, review, and brainstorm
  all run inline in the user's session context — the opposite of the intent.
- Hooks exist as scripts but are unregistered, documented with an invalid
  settings schema, and read `$1` instead of Claude Code's stdin JSON.
- The always-injected skill `description` is ~3,600 chars against a 1,536-char
  platform cap, and a Tier 1 request loads ~13k tokens of scaffolding.
- The anthropic-claude stack went a full model generation stale within 7 weeks
  because currency lives in git commits, not in a continuously updatable source.

v5 keeps the v4 knowledge architecture (roles, protocols, stacks, drift-check)
and replaces the delivery mechanism with the platform's native primitives.

## Design principles

1. **Plugin, not bare skills.** One `claude plugin install` delivers skills,
   agents, hooks, and MCP config together. `install.sh` is retired.
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
6. **ETYB remembers the repo.** Per-repo memory persists across sessions via
   the platform's native agent `memory` mechanism plus a maintained repo map.

## 1. Plugin packaging

```
etyb/
├── .claude-plugin/
│   └── plugin.json              # name, version, description, author, homepage
├── skills/
│   ├── etyb/SKILL.md            # orchestrator — description ≤ 1,536 chars
│   ├── etyb-architect/SKILL.md  # role skills (see §4), context: fork
│   ├── etyb-review/SKILL.md
│   ├── etyb-qa/SKILL.md
│   └── ...
├── agents/
│   ├── etyb-explorer.md
│   ├── etyb-planner.md
│   ├── etyb-reviewer.md
│   ├── etyb-stack-researcher.md
│   └── etyb-cartographer.md     # repo-memory maintainer (§6)
├── hooks/
│   └── hooks.json               # valid Claude Code schema (§5)
├── scripts/                     # hook handlers, stdin-JSON aware
└── .mcp.json                    # optional: etyb-stacks MCP server (§3)
```

Distribution: a marketplace entry (`/plugin marketplace add e-t-y-b/etyb-skills`)
or direct git install. Components ship at plugin root per the platform spec;
only `plugin.json` lives in `.claude-plugin/`.

This single change closes the three v4 criticals: the stacks question becomes
explicitly remote (§3), agents ship (§2), hooks ship wired (§5).

## 2. Subagents — context isolation as the default

**Rule: any work whose intermediate reads exceed ~2k tokens runs in a fork.**

Agent definitions (`agents/*.md`, platform frontmatter spec):

| Agent | Purpose | Tools | Notes |
|---|---|---|---|
| `etyb-explorer` | codebase analysis, "understand X" | read-only | `background: true` capable |
| `etyb-planner` | plan drafting for Tier 3+ | read-only | returns plan artifact |
| `etyb-reviewer` | stage-2 independent review | read-only | fresh context = real independence |
| `etyb-stack-researcher` | fetch + distill remote stack pages | WebFetch, Read | the ONLY place stack pages are read |
| `etyb-cartographer` | build/refresh repo memory | read-only + memory | `memory: project` |

All role-facing agents carry `memory: project` so learning persists per repo
across sessions (§6).

Role skills bind to agents via skill frontmatter:

```yaml
---
name: etyb-review
description: Independent two-stage code review of the current diff.
context: fork
agent: etyb-reviewer
---
```

With `context: fork`, invoking the skill runs its body as the agent's task in
an isolated window. Two-stage review finally works as designed: stage 1
(spec conformance) in the dispatching context, stage 2 in a genuinely fresh
reviewer context, and only the findings return to the user.

Brainstorm gains a real fan-out: the orchestrator dispatches 2–3 explorer
agents with different lenses in parallel and synthesizes, instead of the v4
inline technique library.

The v4 `subagent-protocol` prose (context packets, 5-agent cap, independence
rules) survives as the *prompt content* of these agents — it was always good
guidance; now it has a runtime.

## 3. Remote stacks — documentation middleware

Stacks stay in this repo as the editable source of truth, but consumers never
copy them. Two delivery tiers:

**Tier A (v5.0, zero infra): manifest + raw fetch.**
- `manifest.json` at repo root lists every page with `path`, `last_verified_on`,
  `drift_risk`, `authoritative_url`.
- `etyb-stack-researcher` fetches manifest → page via
  `raw.githubusercontent.com/e-t-y-b/etyb-skills/main/...`.
- Updating a page on `main` updates every user instantly. Currency stamps
  finally mean "when this page was verified," not "when the repo was built."

**Tier B (v5.x, the real middleware): `etyb-stacks` MCP server.**
- Remote MCP server exposing tools such as
  `stack_lookup(vendor, product, role)` and `stack_search(query)`.
- Server returns the answer-bearing *section*, not the whole page — the token
  optimization "tools" enable that raw fetch cannot.
- Server-side you can add search, analytics (which pages get hit → what to
  refresh first), staleness headers, and later private/paid stacks behind auth.
- Plugin ships `.mcp.json`; agents discover the tools natively.

**Degraded mode (both tiers):** in no-network environments the researcher
states plainly that stack knowledge is unverifiable and answers from model
knowledge with an explicit flag — same contract as v4's
`knowledge-currency.md` degraded path, now with one owner (the researcher
agent) instead of instructions scattered across every response.

Currency enforcement moves server/CI-side where it can actually see truth:
`check-currency.sh` extends to per-page stamps, and a scheduled job diffs
high-drift pages against `authoritative_url` instead of only checking stamp
age. Batch re-stamps (508 pages with one date) are treated as a CI failure.

## 4. Skills as SDLC roles

The 14 specialists + 6 verticals consolidate into role skills that share the
five agents above rather than each demanding its own README load:

- `etyb` (orchestrator) — classify, route, synthesize. Body ≤ 150 lines.
  Tier classification moves inline into the body; the charter-read floor
  (~4.5k tokens before a Tier 0 answer) is deleted.
- `etyb-architect`, `etyb-qa`, `etyb-review`, `etyb-debug`, `etyb-plan` —
  thin forked skills. Role depth (the current specialist READMEs, pruned of
  name-list filler) preloads into the *agent* via the agent `skills:` field,
  so it costs the agent's window, never the user's.
- Verticals become stack-shaped: `stacks/verticals/fintech/...` fetched
  remotely like any vendor stack, since the review showed they carry dated
  pricing/metrics and are not actually time-invariant.

Token budget targets (structural, verified in CI by a lint that sums the
always-on surface):

| Surface | v4 actual | v5 ceiling |
|---|---|---|
| Always-injected description(s) | ~900 tokens | ≤ 400 total across all skills |
| Orchestrator invocation | ~4,450 min | ≤ 1,500 |
| Tier 1 answer, user-session cost | ~12,700 | ≤ 2,500 (rest in forks) |
| Tier 3 plan, user-session cost | ~33,000+ | ≤ 5,000 (plan built by etyb-planner) |

## 5. Hooks and rules — wired and valid

`hooks/hooks.json` ships in the plugin using the current platform schema
(nested `hooks: [{type: "command", command: ...}]` under each matcher; events
`PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`). All handler scripts are
rewritten to parse the stdin JSON payload (`tool_input.file_path` etc.) —
the v4 `$1` convention is retired.

Carried over, now actually firing:
- TDD advisory on `Edit|Write` without a sibling test file.
- Review-evidence check on `Stop` when a commit is staged.
- Merge guard on `Bash` matching `git merge`/`git push` to protected branches.

New:
- `SessionStart` hook injects the repo memory summary (§6) so every session
  opens already knowing the repo.

Rules (hard constraints like "max 5 concurrent agents", "reviewer is
read-only") move from prose into agent frontmatter (`tools`, `maxTurns`,
`permissionMode`) where the platform enforces them.

## 6. Multi-session repo memory

Two cooperating layers:

1. **Native agent memory.** Every ETYB agent sets `memory: project`. The
   platform gives it a persistent per-project directory that survives
   sessions — the agent's own accumulated understanding of this repo
   (conventions, past decisions, known trouble spots).
2. **Maintained repo map.** `etyb-cartographer` owns `.etyb/memory/repo-map.md`
   (architecture, module ownership, test entry points, active plans, decision
   log). It refreshes the map after significant merges (PostToolUse/Stop hook
   heuristic or on-demand `etyb-map` skill) and the `SessionStart` hook
   injects a ≤300-token summary of it.

Result: ETYB is not a second controller — it is a per-repo colleague whose
knowledge of the codebase compounds across sessions, while each individual
session stays light.

## Migration plan

- **M1 — packaging:** `.claude-plugin/plugin.json`, move skills/agents/hooks
  into plugin layout, delete `install.sh` + fix `installation.md`. Description
  rewritten ≤ 1,536 chars.
- **M2 — agents:** ship the five agents (port the four `.codex/agents/*.toml`
  definitions, which are already correctly shaped, plus cartographer); convert
  review/brainstorm/plan to `context: fork`.
- **M3 — remote stacks Tier A:** manifest-driven fetch via
  `etyb-stack-researcher`; per-page currency CI; refresh anthropic-claude to
  the Claude 5 generation as the proving case.
- **M4 — memory:** `memory: project` on agents, cartographer + SessionStart
  injection.
- **M5 — stacks Tier B:** hosted MCP server, sectioned responses, staleness
  telemetry.

Each milestone is independently shippable; M1–M3 constitute a releasable
v5.0.0.

## Open questions

1. Stack hosting for Tier B: GitHub-backed serverless (Cloudflare Worker over
   raw content) vs. dedicated service at `etyb.ai`? The signature already
   points at `etyb.ai` — domain liveness must precede shipping any URL in
   output.
2. How much of the 20-specialist taxonomy survives consolidation? Proposal:
   5 agents × role-skill prompts; verticals as stacks. Needs an eval pass
   (skill-evolution-protocol applies to ourselves).
3. Offline posture: ship an optional slim cache pack for air-gapped users, or
   declare network a requirement?
4. Codex/Antigravity parity: the adapter model survives, but v5 makes Claude
   the reference implementation instead of the least-implemented one.
