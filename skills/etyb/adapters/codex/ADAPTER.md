# OpenAI Codex Adapter

You are running ETYB on **OpenAI Codex**. The core modules (`core/*.md`) define your identity, tier classification, gates, and protocols. This adapter documents how those apply on Codex — what works the same, what works differently, and what is not supported.

## The Honest Trade-Off

Codex has no hooks, no lifecycle events, and no skill-to-skill orchestration primitive. Skills are pure instructions + optional metadata.

| ETYB capability | Claude Code | Codex |
|-----------------|-------------|-------|
| Core modules (charter, gates, protocols, etc.) | Full support | Full support |
| Plan artifacts at `.etyb/plans/` | Full support | Full support |
| Team Registry & domain routing | Full support | Full support |
| Tier classification + response formats | Full support | Full support |
| Scale-aware calibration | Full support | Full support |
| TDD / Review / Branch Safety gates | **Hook-enforced** | **Model-trusted only** |
| Plan mode integration | Claude Plan Mode at `.claude/plans/` | Not applicable — use `.etyb/plans/` |
| Parallel subagent dispatch | Agent tool | See `enforcement-notes.md` |

**What this means:** on Codex, ETYB's gates and protocols still apply, but compliance is *model-trusted*. A determined user can route around model-trusted gates (e.g., "just commit anyway"). They cannot route around a Claude Code hook.

This is the honest trade-off of portability. It is not a bug; it is the cost of running on a platform without deterministic enforcement primitives.

## Installation

Codex discovers skills from `.agents/skills/` at the current working directory and every ancestor up to the repo root, plus `$HOME/.agents/skills/` (user scope) and `/etc/codex/skills/` (admin scope).

For ETYB, the expected layout on a project using Codex:

```
your-project/
└── .agents/
    └── skills/
        └── etyb/                  # this skill
            ├── SKILL.md
            ├── core/
            ├── adapters/codex/    # this adapter
            ├── references/
            └── agents/
                └── openai.yaml    # optional Codex metadata
        └── <each specialist>/     # the 20+ specialists, each independent
```

The repo layout used in this project is `skills/etyb/` rather than `.agents/skills/etyb/`. Distribution scripts should copy or symlink into `.agents/skills/` on installation.

## Load These On Top Of Core

| File | Purpose |
|------|---------|
| [`enforcement-notes.md`](enforcement-notes.md) | Exactly what is model-trusted vs. what cannot be enforced. Subagent limitations. Practical guidance for gate discipline without hooks. |
| [`openai-yaml-example.md`](openai-yaml-example.md) | Reference `agents/openai.yaml` — interface metadata, invocation policy, tool declarations. Adopt per skill. |

## Key Differences From Claude Code

- **No pre-commit review hook.** You must remember to invoke `code-reviewer` before commits on Tier 3+ code changes. The `core/always-on-protocols.md` §3 discipline still applies — you enforce it by instruction.
- **No pre-merge test hook.** You must verify tests pass before merging. The `core/always-on-protocols.md` §6 discipline still applies by instruction.
- **No pre-edit TDD check.** TDD remains required by `core/always-on-protocols.md` §1 — but Codex won't warn if you edit source before writing the test.
- **No native plan mode.** Always use `.etyb/plans/{name}.md`. Ignore `core/gates.md`'s pointer to `adapters/{platform}/plan-mode.md` — there is none for Codex.
- **Subagents are not skill-integrated.** Codex has a subagent concept, but it is separate from skills. See `enforcement-notes.md` for how to handle parallel tracks.

## When To Recommend Claude Code Instead

If a user explicitly needs deterministic process enforcement (regulated industries, high-stakes review gates, anti-yolo guardrails), the flagship Claude Code experience is materially stronger. Be honest about this — don't pretend Codex enforces what it cannot.

For general-purpose engineering work, Codex + ETYB is fine. The 80% of ETYB's value (routing, synthesis, scale-calibrated advice, expert mandating, plan artifacts) works identically.
