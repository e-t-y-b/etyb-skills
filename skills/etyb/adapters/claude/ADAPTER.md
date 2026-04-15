# Claude Code Adapter

You are running ETYB on **Claude Code**. This adapter layers deterministic enforcement on top of the portable core modules.

## What This Adapter Adds

Claude Code gives you primitives no other platform has:

1. **Hooks** — deterministic shell scripts that fire on tool-use events, outside the LLM. They cannot be reasoned around.
2. **Built-in plan mode** — a native plan artifact at `.claude/plans/` that ETYB annotates rather than duplicates.
3. **The Agent tool** — sub-agents for parallel work with context isolation.

These turn ETYB's gates and protocols from "trusted instructions" into "enforced behavior." When a hook fires, it runs regardless of what the model decides. When plan mode is active, ETYB works inside Claude's plan rather than creating a parallel one.

## Load These On Top Of Core

After reading the core modules per `SKILL.md`, read these adapter files in order:

| File | Purpose |
|------|---------|
| [`hooks.md`](hooks.md) | Map of the 5 hooks in `.claude/settings.json`, what each enforces, where it fires |
| [`plan-mode.md`](plan-mode.md) | `.claude/plans/` integration — detection, annotation, dual-plan resolution |
| [`subagents.md`](subagents.md) | Using the Agent tool for parallel specialist work + two-stage review |

## Model-Trusted vs. Hook-Enforced

On Claude Code, some core disciplines become hook-enforced:

| Core Discipline | Enforcement on Claude Code | What Happens Elsewhere |
|----------------|---------------------------|------------------------|
| TDD (core/always-on-protocols.md §1) | `pre-edit-check` hook warns if editing source without a test file | Model self-enforces from instructions |
| Review (core/always-on-protocols.md §3) | `pre-commit-review-check` hook warns if committing without review evidence | Model self-enforces |
| Branch Safety (core/always-on-protocols.md §6) | `pre-merge-verify` hook blocks merge if tests fail | Model self-enforces |

The core protocols are identical. Claude Code is stricter because the hook fires even if the model would have let it slide.

## Enforcement Trade-Off (Honest)

Hook enforcement is a feature of the Claude Code runtime, not a feature of ETYB. On Codex and Antigravity, these gates still apply — but compliance is model-trusted. A determined user can route around model-trusted gates. They cannot route around a hook short of disabling it.

That's why Claude Code is the flagship experience. If gate-enforced engineering discipline is the product, Claude Code is where it's strongest.
