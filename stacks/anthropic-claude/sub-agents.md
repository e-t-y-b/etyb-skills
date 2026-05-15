---
title: Sub-agents
description: Separately-instantiated Claude invocations with their own context window, system prompt, tool set, optionally their own model. One domain per sub-agent; two-stage review pattern.
product:
  name: Sub-agents
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/claude-code/sub-agents
  notes: "Pattern formalized in Claude Code 2025; one-domain-per-agent convention; ETYB's specialist pattern."
---

## What it is

A sub-agent is a separately-instantiated Claude invocation with its own context window, system prompt, tool set, and optionally its own model. The primary agent calls the sub-agent for a focused task; the sub-agent runs to completion and returns a result; the sub-agent's intermediate context never pollutes the primary.

In [Claude Code](/stacks/anthropic-claude/claude-code/): `.claude/agents/<name>.md` files declare sub-agents with their own description, tools, system prompt. The primary agent invokes them via the Task tool. Sub-agent prompts auto-load like [Skills](/stacks/anthropic-claude/skills/) do.

In the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/): `agent.spawn_subagent(...)` for programmatic sub-agent spawning.

This is **ETYB's specialist pattern** — each of the 20 specialists in `skills/etyb/references/specialists/` is a sub-agent in concept. See [Sub-agents docs](https://docs.anthropic.com/en/docs/claude-code/sub-agents).

## When to use

Sub-agents fit for:

- **One-domain specialists** — a "code reviewer" sub-agent reviews a diff; a "security scanner" sub-agent runs a checklist; a "test author" sub-agent writes tests. Each has its own narrow context.
- **Parallel exploration** — multiple sub-agents try different approaches; primary picks the best.
- **Context window isolation** — keep a sub-task's noisy intermediate state out of the primary's window.
- **Tool surface isolation** — the primary doesn't need the sub-agent's narrow tool set polluting routing decisions.

Don't use sub-agents when:

- **The task is simple enough for the primary** — sub-agent overhead (context setup, model invocation, result parsing) costs more than the savings.
- **The "sub-agent" is general-purpose** — defeats the point; specialization is the value.
- **You'd nest 3+ levels deep** — coordination overhead exceeds parallelism gains.

## 2025-2026 currency anchors

- **Pattern formalized in Claude Code (2025)** — `.claude/agents/<name>.md` first-class.
- **Claude Agent SDK supports sub-agents** programmatically — `spawn_subagent()` and equivalents.
- **One-domain-per-agent convention** — codified in ETYB's [subagent-protocol](https://github.com/e-t-y-b/etyb-skills/blob/main/skills/etyb/references/protocols/subagent-protocol/).
- **Two-stage review** — sub-agent proposes; primary reviews and decides. Sub-agent is not authoritative on its own.

## Patterns + anti-patterns

### Pattern — one agent per domain

Don't have a "do-everything-backend" sub-agent. Split into backend-architect, qa-engineer, security-engineer, etc. Each has its own narrow context and tool surface. Routing decisions become clearer; failures become more localized.

### Pattern — two-stage review

Sub-agent proposes a result; primary reviews and decides whether to accept. The primary holds final authority — sub-agents are advisors, not deciders. This pattern protects against sub-agent hallucination and lets the primary integrate cross-domain context.

### Pattern — narrow task scope

"Review this 100-line diff" beats "review the codebase." Sub-agents excel on bounded tasks; degrade on open-ended ones. Scope explicitly.

### Pattern — structured returns

Sub-agents return JSON-shaped findings (or tool-call-shaped structured output), not chatty prose summaries. The primary doesn't have to re-parse natural language; it acts on structured data.

### Pattern — sub-agent for untrusted-content processing

A sub-agent has its own context window. Untrusted content (user-uploaded document, third-party tool output) processed in a sub-agent doesn't pollute the primary. The sub-agent returns a structured summary; the primary acts on the summary. See [security-engineer overlay on context isolation](/stacks/anthropic-claude/security-engineer/#pattern--context-isolation-via-sub-agents).

### Anti-pattern — sub-agents nested 3+ levels deep

Coordination overhead exceeds the parallelism gain. Two levels (primary + sub-agents) is the sweet spot for most workloads.

### Anti-pattern — "general-purpose helper" sub-agent

Defeats the point. The value of sub-agents is specialization. A general-purpose sub-agent is just another primary with extra latency.

### Anti-pattern — sub-agents that hand off via natural-language summaries

The primary has to parse the sub-agent's prose, often imperfectly. Use structured outputs (tool-call-shaped JSON).

### Anti-pattern — sub-agent that uses Opus when Sonnet would do

Sub-agents multiply request volume. Using [Opus](/stacks/anthropic-claude/claude-opus/) for every sub-agent invocation costs 5x. Default [Sonnet](/stacks/anthropic-claude/claude-sonnet/) for sub-agents unless an eval shows otherwise. Some sub-agents can run on [Haiku](/stacks/anthropic-claude/claude-haiku/).

## Gotchas

- **Sub-agent context window is independent** — what the primary saw doesn't transfer. The primary must pass sufficient context in the sub-agent invocation.
- **Sub-agent tool inheritance varies by harness.** In Claude Code, sub-agents have their own tool surface declared in `.claude/agents/<name>.md`. In the Agent SDK, you configure explicitly. Read your harness's docs.
- **Sub-agent failures should escalate to primary**, not crash the chain. Wrap invocations; surface errors meaningfully.
- **Sub-agent costs multiply** — N sub-agent invocations = N+1 Claude requests minimum. Plan capacity (rate limits, budgets).
- **Compromised sub-agent prompt = compromised tool use.** A sub-agent inherits trust in the agent system. See [security-engineer overlay](/stacks/anthropic-claude/security-engineer/#skills-and-sub-agents--security-implications).

## Cross-references

- [Skills](/stacks/anthropic-claude/skills/) — pair Skills + sub-agents for specialization
- [Claude Code](/stacks/anthropic-claude/claude-code/) — `.claude/agents/` location
- [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) — programmatic sub-agent spawning
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — sub-agent design discipline
- [system-architect overlay](/stacks/anthropic-claude/system-architect/) — sub-agents in delivery
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — context isolation via sub-agents
- [Sub-agents docs](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
