---
title: Claude Agent SDK
description: The recommended way to build agents on Claude in 2026 — owns the tool loop, retries, sub-agents, MCP integration, permission gating. Don't roll your own agent loop unless you have an explicit reason.
product:
  name: Claude Agent SDK
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, system-architect]
  authoritative_url: https://docs.anthropic.com/en/api/claude-code-sdk
  notes: "Released 2025; replaces ad-hoc agent loops; harness conventions still settling — verify against release notes."
---

## What it is

The Claude Agent SDK (`@anthropic-ai/claude-agent-sdk` on npm, `claude-agent-sdk` on PyPI) is Anthropic's recommended substrate for building agentic loops on top of the [Messages API](/stacks/anthropic-claude/claude-api/). Launched 2025, matured through 2026.

What it gives you:

- **Tool-use loop** — receive response, execute `tool_use` blocks, send results back, loop until `end_turn` or iteration cap.
- **Sub-agent spawning** — fork a [sub-agent](/stacks/anthropic-claude/sub-agents/) with a scoped task; get its result.
- **Permission gating** — hooks for "ask the user before this tool runs" patterns.
- **Streaming** — text and tool calls stream to the caller.
- **Retries / timeouts / backoff** — sensible defaults built in.
- **[MCP](/stacks/anthropic-claude/mcp/) integration** — tools defined via MCP servers loaded automatically if configured.

See [Claude Agent SDK docs](https://docs.anthropic.com/en/api/claude-code-sdk) and verify field shapes against current release notes — the surface is still settling.

## When to use

Use the SDK for:

- Any multi-turn agent.
- Any service that wraps Claude with a fixed tool surface.
- Anything that needs [sub-agents](/stacks/anthropic-claude/sub-agents/).
- Anything that integrates [MCP](/stacks/anthropic-claude/mcp/) servers.

Skip the SDK for:

- **Pure prompt completion with no tools.** Just use the Messages API directly via the [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/).
- **Specialized constraints the SDK can't accommodate** (rare; the SDK is flexible).
- **Educational reasons** — you're learning the protocol; move to the SDK once you understand it.

## 2025-2026 currency anchors

- **Launched 2025, matured 2026.** The early "claude-code-sdk" naming is deprecated; "Claude Agent SDK" is current.
- **Owns iteration cap by default** — no unbounded loops without explicit override. Cost-safety built in.
- **Parallel tool use handled correctly** — multiple `tool_use` blocks in one turn are executed concurrently. Hand-rolled loops often miss this.
- **Sub-agents are first-class** — spawn and await sub-agents with their own context window and tool surface.
- **MCP servers integrate transparently** — declare your MCP servers in SDK config; tools appear in the agent's surface.
- **Streaming + tool use combined** — both text and tool calls stream; the SDK assembles content blocks correctly.

## Patterns + anti-patterns

### Pattern — SDK-first agent design

```python
from claude_agent_sdk import Agent

agent = Agent(
    model="claude-sonnet-4-7-20260301",
    system="...",
    tools=[...],
    max_iters=10,
)
result = await agent.run(user_message="...")
```

Build agents on the SDK. Drop down to the raw [Messages API](/stacks/anthropic-claude/claude-api/) tool loop only when you have constraints the SDK doesn't fit.

### Pattern — sub-agents for specialized tasks

```python
# Parent agent spawns a code-reviewer sub-agent
reviewer = await agent.spawn_subagent(
    system="You are a code reviewer focused on security issues.",
    tools=[code_read, code_lint],
    max_iters=5,
)
review_result = await reviewer.run(user_message=f"Review this diff: {diff}")
```

One domain per sub-agent; two-stage review (sub-agent proposes, primary reviews). See [Sub-agents](/stacks/anthropic-claude/sub-agents/) for the full pattern.

### Pattern — permission gating on destructive tools

Configure the SDK to require human approval before specified tools execute. For irreversible actions (send email, delete record, charge payment), approval is mandatory.

### Anti-pattern — hand-rolling a tool loop in 2026

If you find yourself writing a retry-and-backoff agent loop with parallel tool execution and signature round-tripping for [Extended Thinking](/stacks/anthropic-claude/extended-thinking/) — stop. Use the SDK. You will reinvent bugs Anthropic already fixed.

### Anti-pattern — wrapping the SDK in another abstraction layer

The SDK is the abstraction. Another layer on top usually slows iteration without adding value. Use the SDK directly; configure it for your service.

### Anti-pattern — no iteration cap even with the SDK

The SDK has a default cap, but explicit per-task caps are better — they're visible in code and easier to tune per task. Surface the cap in your service config.

### Anti-pattern — running the SDK against the Anthropic API without observability

The SDK exposes per-iteration callbacks. Wire them to your observability layer (Langfuse, Helicone, OpenTelemetry). Without this, you can't tune the agent.

## Gotchas

- **The SDK is opinionated.** Tool-execution semantics, retry behavior, streaming format — they have defaults that match Anthropic's recommended patterns. Override only when necessary.
- **Surface conventions still settling.** This is a 2025-2026 release; field names and config shapes may shift. Pin the SDK version in production; review changelogs.
- **TypeScript and Python parity is high but not perfect.** Check feature parity for your language before assuming.
- **Bedrock / Vertex with the SDK** — verify the SDK supports your target provider before assuming. Anthropic-API-first; provider parity follows.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — underlying protocol
- [Tool Use](/stacks/anthropic-claude/tool-use/) — what the SDK orchestrates
- [Sub-agents](/stacks/anthropic-claude/sub-agents/) — pattern formalized by the SDK
- [MCP](/stacks/anthropic-claude/mcp/) — SDK loads MCP-defined tools
- [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) — used under the Agent SDK
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — when to drop down to raw Messages API
- [Claude Agent SDK Docs](https://docs.anthropic.com/en/api/claude-code-sdk)
