# Subagents on Claude Code

Claude Code provides the **Agent tool** — it spawns a sub-agent with a fresh context window, runs it against a focused prompt, and returns the result. This is how ETYB executes parallel specialist work on Claude.

The subagent discipline (context isolation, one agent per domain, two-stage review) is defined platform-neutrally in `skills/subagent-protocol/`. This file is about the Claude-specific mechanics.

## When To Dispatch a Subagent

Read `core/coordination-patterns.md` → Parallel Tracks first. Generally, dispatch a subagent when:

- Multiple specialists need to work on independent domains simultaneously (frontend + backend + database against an agreed API contract)
- You need to protect the main conversation's context window from a large, self-contained piece of work (an exploration, a codebase audit, a research spike)
- You need an independent review — the reviewer shouldn't see the implementer's reasoning, only the output

## Claude-Specific Dispatch Primitives

| Agent type | When to use |
|------------|-------------|
| `Explore` | Fast codebase exploration — finding files, tracing symbols, answering "how does X work" questions. Optimized for read-only surveys. |
| `Plan` | Designing an implementation approach. Returns step-by-step plans, identifies critical files. |
| `general-purpose` | Everything else — multi-step tasks, targeted edits, domain specialist work |
| `code-reviewer` (if installed) | Independent review of a change. Should NOT have seen the reasoning that produced the change. |

When you want a domain specialist to act as a subagent, use `general-purpose` with a prompt that instructs the agent to read the specialist's SKILL.md first.

## Two-Stage Review

`skills/subagent-protocol/references/two-stage-review.md` defines the pattern. On Claude, it maps to:

**Stage 1 — Implementation subagent:**
- Prompt includes the task, the relevant skill file(s), and the acceptance criteria
- Agent produces a change (code, doc, plan)
- Agent reports back

**Stage 2 — Review subagent:**
- Fresh subagent (no context from Stage 1)
- Prompt gives the subagent the change + the acceptance criteria, nothing else
- Agent evaluates against criteria independently

ETYB synthesizes the two reports and decides. Do not let a single agent both implement and review its own work — that defeats the point of the isolation.

## Context Isolation Pitfalls

- **Do not pass your own reasoning.** The subagent's power is its fresh view. Sharing your hypothesis contaminates it.
- **Include file paths, not file content.** The subagent can read files itself. Passing large content wastes their context.
- **Be specific about acceptance criteria.** A vague prompt gives a vague answer. "Review the change" is weak; "verify that the new retry logic handles 429s specifically and does not retry 4xx other than 429" is strong.
- **Report length.** Ask for a specific length (e.g., "Under 200 words") if you don't need a full transcript.

## Parallel Tracks — Practical Pattern

For the "multiple specialists against an API contract" case:

1. **Design gate** — produce the API contract (architecture track, no parallelism yet)
2. **Plan gate** — task breakdown per track (frontend, backend, database, mobile)
3. **Implement gate** — dispatch one subagent per track, running in parallel. Each agent:
   - Reads its track's specialist skill
   - Reads the API contract
   - Implements only its track
   - Reports back
4. **Verify gate** — ETYB synthesizes the tracks, then dispatches an independent review subagent per track (two-stage review)

The gate enforcement rule from `core/gates.md` still applies: **Implement gate blocks until all parallel tracks complete**. Individual tracks may finish in different orders, but the formal gate waits for the last one.
