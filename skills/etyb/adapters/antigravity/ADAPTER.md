# Google Antigravity Adapter

You are running ETYB on **Google Antigravity**. The core modules (`core/*.md`) define your identity, tiers, gates, and protocols. This adapter documents how those apply on Antigravity, plus one capability Antigravity uniquely exposes: **ADK-backed skills** that can spawn live sub-agents.

## Capability Matrix

| ETYB capability | Claude Code | Codex | Antigravity |
|-----------------|-------------|-------|-------------|
| Core modules | Full support | Full support | Full support |
| Plan artifacts at `.etyb/plans/` | Full support | Full support | Full support |
| Team Registry & routing | Full support | Full support | Full support |
| Tier classification + response formats | Full support | Full support | Full support |
| TDD / Review / Branch Safety gates | **Hook-enforced** | Model-trusted | Model-trusted |
| Plan mode integration | Claude Plan Mode | N/A | N/A |
| Parallel sub-agent dispatch | Agent tool | Not in-skill | **ADK sub-agents** (if elevated) |
| MCP integration | Native | Native | Native |

On Antigravity, ETYB is model-trusted like on Codex — but with a path to ADK-backed sub-agent orchestration that Codex lacks. See [`adk-integration.md`](adk-integration.md).

## Installation

Antigravity discovers skills from:

- **Workspace:** `<workspace-root>/.agent/skills/` (note: singular `.agent/`, not `.agents/`)
- **Global:** `~/.gemini/antigravity/skills/`

Expected layout:

```
your-project/
└── .agent/
    └── skills/
        └── etyb/
            ├── SKILL.md
            ├── core/
            ├── adapters/antigravity/    # this adapter
            ├── references/
            └── (optional) adk/          # if elevated to ADK
        └── <each specialist>/
```

Compatible installers like `npx add-skill <repo>` auto-detect Antigravity and place skills in the correct directory. The repo's `skills/etyb/` layout is the source; installation copies or symlinks into `.agent/skills/`.

## Load These On Top Of Core

| File | Purpose |
|------|---------|
| [`enforcement-notes.md`](enforcement-notes.md) | Per-protocol model-trusted fallback, same honest trade-off as Codex. Where Antigravity's ADK gives you an extra lever. |
| [`adk-integration.md`](adk-integration.md) | Optional elevation from markdown-only skill to ADK-backed skill with live sub-agent orchestration. When to bother, what it buys you, how to wire it up. |

## The Antigravity Advantage (vs. Codex)

Both Antigravity and Codex lack hooks. Neither gives you deterministic gate enforcement like Claude Code. But Antigravity's **ADK-backed skills** let you do something Codex cannot: spawn and coordinate sub-agents from inside a skill, with tool definitions and multi-turn reasoning.

For ETYB's Parallel Tracks coordination pattern (`core/coordination-patterns.md`), this matters:
- On Codex: parallel tracks collapse to sequential or require user-driven multi-session coordination
- On Antigravity with ADK elevation: parallel tracks work — ETYB dispatches sub-agents for each track from within the skill

Elevating to ADK is optional. Markdown-only ETYB works fine on Antigravity for most use cases. Consider ADK when:
- You regularly run Tier 4 projects with genuine parallel work
- You want sub-agents to use tools that aren't available in the main Antigravity agent context
- You want stateful multi-turn reasoning scoped to a specific track

## What This Adapter Does Not Try To Do

- **No hook simulation.** Antigravity doesn't have hooks; pretending otherwise erodes trust.
- **No ADK lock-in.** Core modules work on Antigravity without ADK. ADK is a power-user option.
- **No MCP dependency.** MCP is available if the user's setup provides it; ETYB doesn't require it.

## When To Recommend Claude Code Instead

Same honest answer as the Codex adapter: if a user needs deterministic process enforcement (regulated workflows, high-stakes gates, anti-yolo guardrails), Claude Code's hooks are materially stronger than model-trusted compliance. For general-purpose work, Antigravity + ETYB (especially with ADK elevation) is a strong experience.
