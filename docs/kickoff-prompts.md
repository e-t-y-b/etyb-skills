# Kickoff prompts

The full execution plans live in `docs/plan/` — task-level breakdowns,
frozen technical contracts, status ledgers, and the session protocol. These
prompts just point a fresh session at them. Run the same prompt every
session; the status ledger tells it where work stands.

---

## Prompt 1 — etyb-skills 5.0 (any environment with this repo)

```
Open docs/plan/00-execution-guide.md in the e-t-y-b/etyb-skills repo and
follow it exactly. Work the skills-5.0 train: docs/plan/skills-5.0-plan.md.
Pick the first unblocked `todo` task from the status ledger (or the task I
name), execute it with subagents per the guide's dispatch table, verify
against the task's acceptance criteria, run two-stage review, update the
ledger, and open a PR. Contracts and content drafts embedded in the task
specs are decisions — do not redesign them; record any forced deviation in
the plan's Deviations section and stop for my sign-off. Release gate:
v5.0.0 = M1+M2+M3 complete.
```

## Prompt 2 — etyb.ai 0.1 (run locally; needs the new etyb-ai repo)

```
Fetch docs/plan/00-execution-guide.md, docs/plan/etyb-ai-0.1-plan.md, and
docs/plan/etyb-ai-0.1-architecture.md from the e-t-y-b/etyb-skills repo
(main, or branch claude/usability-standards-review-27ckxa if not yet
merged) and follow the guide exactly. Work the etyb.ai train in the
etyb-ai repo (create it via task E0-T1 if it doesn't exist yet, copying
the three plan docs plus docs/rfc-etyb-ai-0.1.md into its docs/). Pick the
first unblocked `todo` task from the status ledger (or the task I name),
execute with subagents, verify acceptance criteria, two-stage review,
update the ledger, PR. The architecture file is a frozen contract —
storage schemas, MCP tool shapes, lens URIs, repo layout are decided;
record any forced deviation and stop for sign-off. Checkpoints: E2 done =
usable headless product; E3 done = private alpha. The owner-input
checklist at the end of the plan lists the things only I can provide —
surface them when a task hits one.
```

---

Division of labor: Prompt 1 can run in the Claude Code cloud session
attached to etyb-skills. Prompt 2 runs locally (Electron/daemon work; the
repo bootstrap and E1/E2 are OS-agnostic but you'll want to run the
result).
