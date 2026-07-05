# Execution guide — how any session runs these plans

This directory is the single source of truth for executing the two release
trains. A fresh agent session should be able to open this file, follow the
protocol, and produce correct work with no strategic re-planning.

## Documents

| File | Contents |
|---|---|
| `00-execution-guide.md` | This protocol |
| `skills-5.0-plan.md` | etyb-skills 5.0: milestones M1–M6, task level, with status ledger |
| `etyb-ai-0.1-architecture.md` | etyb.ai: frozen technical contracts (schemas, tools, layouts) |
| `etyb-ai-0.1-plan.md` | etyb.ai: epics E1–E5, task level, with status ledger |
| `../rfc-v5-plugin-architecture.md` | Skills 5.0 rationale (read when a task's "why" is unclear) |
| `../rfc-etyb-ai-0.1.md` | etyb.ai rationale (same) |

## Session protocol

1. **Orient.** Read this file, then the plan file for the train you're
   working on. Read ONLY the status ledger and the task(s) you'll execute —
   not the whole plan — unless dependencies force more.
2. **Pick work.** Take the first task whose status is `todo` and whose
   `depends` are all `done`. If the user named a task, do that one.
3. **Branch.** Work on a feature branch named `feat/<task-id>-<slug>`
   (e.g. `feat/m1-t2-skill-body`). Never commit to main directly.
4. **Execute with subagents.** The main session is the ORCHESTRATOR — it
   does not write product code inline. Dispatch per the agent-role table
   below. One agent per independent domain; parallelize independent tasks.
5. **Verify before done.** Every task lists acceptance criteria. Run them.
   A task without passing acceptance evidence stays `in-progress`.
6. **Two-stage review.** Stage 1: orchestrator checks the diff against the
   task spec. Stage 2: dispatch a FRESH review agent (no context from the
   implementer) with the task spec + diff; it must return findings or an
   explicit pass. Fix findings before merge.
7. **Record.** Update the task's row in the status ledger (status, date,
   branch/PR, one-line note) in the same PR. The ledger is how the next
   session knows where things stand — never skip it.
8. **Ship.** Push, open a PR per milestone-or-smaller. Do not merge without
   green checks.

## Agent roles (dispatch table)

| Role | Used for | Type / notes |
|---|---|---|
| implementer | one task's code/doc changes | general-purpose; give it the FULL task spec text, not a summary |
| explorer | answering "what exists / where" before implementing | read-only search agent |
| reviewer | stage-2 review | fresh context; read-only; prompt = task spec + diff + "find defects, do not praise" |
| researcher | resolving an open question flagged `needs-research` | web-enabled; findings go into the plan file, not just chat |

Context packet for every dispatch: task ID + full task text + acceptance
criteria + relevant contracts section (for etyb.ai, the exact
`etyb-ai-0.1-architecture.md` section) + branch name. Subagents return
diffs/results, not narration.

## Hard rules

- **Contracts are frozen.** `etyb-ai-0.1-architecture.md` and the specs
  embedded in `skills-5.0-plan.md` are decisions, not suggestions. If a
  contract proves wrong during implementation, STOP, record the problem in
  the plan file under "Deviations", propose the change in the PR
  description, and get user sign-off before diverging. Never silently drift.
- **Tests first** where a task has runtime behavior; docs claims must match
  shipped reality (the v4 review failed on claim/reality gaps).
- **Licensing:** MIT/Apache-2.0/BSD/ISC deps only; THIRD-PARTY-NOTICES
  updated whenever a dep is added. No GPL/AGPL/PolyForm.
- **Token discipline:** heavy exploration goes to subagents; the
  orchestrator's context is for decisions.
- Model: plan-critical ambiguity → ask the user; mechanical ambiguity →
  decide, note it in the PR.

## Status vocabulary

`todo` · `in-progress (<branch>)` · `blocked (<on what>)` · `review` ·
`done (<date>, <pr/commit>)` · `dropped (<why>)`
