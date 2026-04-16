# OpenAI Codex Adapter

You are running ETYB on **OpenAI Codex**. The core modules (`core/*.md`) define your identity, tier classification, gates, and protocols. This adapter documents how those apply on Codex — what works the same, what works differently, and what is not supported.

## The Honest Trade-Off

Codex now gives ETYB more than markdown alone: project config, lifecycle hooks, custom agents, and per-skill `agents/openai.yaml` metadata. But the enforcement surface is still narrower than Claude Code: hooks are experimental, `PreToolUse` and `PostToolUse` are currently Bash-only, and there is still no edit-before-test interception.

| ETYB capability | Claude Code | Codex |
|-----------------|-------------|-------|
| Core modules (charter, gates, protocols, etc.) | Full support | Full support |
| Plan artifacts at `.etyb/plans/` | Full support | Full support |
| Team Registry & domain routing | Full support | Full support |
| Tier classification + response formats | Full support | Full support |
| Scale-aware calibration | Full support | Full support |
| Project config | Full support | Full support via `.codex/config.toml` |
| Lifecycle hooks | Full support | `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop` via `.codex/hooks.json` |
| TDD / Review / Branch Safety gates | **Hook-enforced** | **Partially runtime-enforced, with model-trusted gaps** |
| Plan mode integration | Claude Plan Mode at `.claude/plans/` | Not applicable — use `.etyb/plans/` |
| Parallel subagent dispatch | Claude subagent runtime | Custom agents in `.codex/agents/` |
| Skill metadata | Plugin metadata | `agents/openai.yaml` shipped for every installable skill |

**What this means:** on Codex, ETYB's gates and protocols still apply, and several now have real runtime help. Prompt hooks can block obvious gate-skipping. Bash hooks can guard merge attempts and record test evidence. Stop hooks can force one more verification pass. The remaining gaps — especially edit-before-test and non-Bash tool calls — are still model-trusted.

This is the honest trade-off of portability. It is not a bug; it is the cost of running on a platform with partial deterministic surfaces rather than Claude's broader runtime controls.

## Installation

Codex discovers skills from `.agents/skills/` at the current working directory and every ancestor up to the repo root, plus `$HOME/.agents/skills/` (user scope) and `/etc/codex/skills/` (admin scope).

For ETYB, the expected layout on a project using Codex:

```
your-project/
├── .codex/
│   ├── config.toml
│   ├── hooks.json
│   ├── hooks/
│   └── agents/
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

The repo layout used in this project is `skills/etyb/` rather than `.agents/skills/etyb/`. Distribution scripts should copy or symlink skills into `.agents/skills/` and install the project-scoped `.codex/` runtime into the workspace root.

## Load These On Top Of Core

| File | Purpose |
|------|---------|
| [`enforcement-notes.md`](enforcement-notes.md) | Exactly what is partially runtime-enforced vs. still model-trusted. Custom-agent expectations and Codex-specific gaps. |
| [`openai-yaml-example.md`](openai-yaml-example.md) | Reference `agents/openai.yaml` — interface metadata, invocation policy, tool declarations. The repo now ships this file for every installable skill. |

## Key Differences From Claude Code

- **Hooks are real but scoped.** Codex can run `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, and `Stop`, but tool interception is currently Bash-only.
- **No pre-edit TDD check.** TDD remains required by `core/always-on-protocols.md` §1, but Codex still cannot intercept file edits before they happen.
- **No native plan mode.** Default to `.etyb/plans/{name}.md`. This plan deliberately does not add a Codex-native plan artifact layer.
- **Custom agents are project-scoped, not skill-embedded.** ETYB ships `.codex/agents/etyb_explorer.toml`, `etyb_planner.toml`, `etyb_reviewer.toml`, and `etyb_docs_researcher.toml` for bounded parallel work and independent review.
- **Windows is currently excluded for hooks.** Codex hooks are still experimental and disabled on Windows per the current OpenAI docs.

## When To Recommend Claude Code Instead

If a user explicitly needs deterministic process enforcement (regulated industries, high-stakes review gates, anti-yolo guardrails), the flagship Claude Code experience is materially stronger. Be honest about this — don't pretend Codex enforces what it cannot.

For general-purpose engineering work, Codex + ETYB is fine. The 80% of ETYB's value (routing, synthesis, scale-calibrated advice, expert mandating, plan artifacts) works identically.
