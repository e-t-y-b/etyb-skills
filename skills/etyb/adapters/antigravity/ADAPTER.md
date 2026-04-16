# Google Antigravity Adapter

You are running ETYB on **Google Antigravity**. The core modules (`core/*.md`) define your identity, tiers, gates, and protocols. This adapter documents the shipped contract for Antigravity in this repo: markdown-first, model-trusted, portable plans at `.etyb/plans/`, and ADK explicitly deferred.

## Capability Matrix

| ETYB capability | Claude Code | Codex | Antigravity |
|-----------------|-------------|-------|-------------|
| Core modules | Full support | Full support | Full support |
| Plan artifacts at `.etyb/plans/` | Full support | Full support | Full support |
| Team Registry & routing | Full support | Full support | Full support |
| Tier classification + response formats | Full support | Full support | Full support |
| TDD / Review / Branch Safety gates | **Hook-enforced** | Model-trusted | Model-trusted |
| Plan mode integration | Claude Plan Mode | N/A | N/A |
| Parallel sub-agent dispatch | Claude subagent runtime | Custom agents | Markdown-first coordination in this repo; ADK future path only |
| MCP integration | Native | Native | Native |

On Antigravity, ETYB is model-trusted like on Codex, but this repo does not ship an ADK runtime. See [`adk-integration.md`](adk-integration.md) for the future-path document only.

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
| [`enforcement-notes.md`](enforcement-notes.md) | Per-protocol model-trusted fallback, same honest trade-off as Codex. Portable plan storage and markdown-first coordination. |
| [`adk-integration.md`](adk-integration.md) | Future-path documentation only. This repo does not add ADK code, Python agents, or tool wiring in the current plan. |

## Current Antigravity Contract

This repo deliberately keeps Antigravity simple and honest:
- **Plans stay portable.** Use `.etyb/plans/`.
- **Coordination stays markdown-first.** Parallel work is described and decomposed, not runtime-orchestrated by this bundle.
- **No hook overclaiming.** There are no shipped Antigravity hooks in this repo.
- **ADK stays deferred.** The document exists so teams can evaluate that path later without confusing it with what is already implemented here.

## What This Adapter Does Not Try To Do

- **No hook simulation.** Antigravity doesn't have hooks; pretending otherwise erodes trust.
- **No ADK lock-in.** Core modules work on Antigravity without ADK. ADK is a future-path option, not part of the shipped runtime.
- **No MCP dependency.** MCP is available if the user's setup provides it; ETYB doesn't require it.

## When To Recommend Claude Code Instead

Same honest answer as the Codex adapter: if a user needs deterministic process enforcement (regulated workflows, high-stakes gates, anti-yolo guardrails), Claude Code's hooks are materially stronger than model-trusted compliance. For general-purpose work, Antigravity + ETYB is still useful, but treat it as markdown-first unless you explicitly choose to build the future ADK path.
