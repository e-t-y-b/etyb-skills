---
title: Tool Use
description: "Claude's function-calling protocol — declare tools, model emits `tool_use` blocks, you execute and return `tool_result` blocks. Parallel tool use is default on 4.x. Schema discipline determines accuracy."
product:
  name: Tool Use
  stack: anthropic-claude
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, security-engineer]
  authoritative_url: https://docs.anthropic.com/en/docs/build-with-claude/tool-use
  notes: "Schema is stable; parallel tool use + tool_choice behaviors evolve with each model release."
---

## What it is

Tool use is Claude's native function-calling protocol. You declare `tools` in the request; Claude returns `tool_use` content blocks; you execute the tools and pass results back as `tool_result` blocks; Claude continues. See [Tool Use Guide](https://docs.anthropic.com/en/docs/build-with-claude/tool-use).

Structurally similar to OpenAI's function calling, with Claude-specific niceties: explicit `tool_choice` semantics, parallel tool use by default on 4.x models, and a content-block-typed protocol (rather than separate JSON fields).

## When to use

Tool use is the path for **any action Claude must take outside text generation** — calling APIs, querying databases, sending notifications, retrieving content, executing computation. Reach for it whenever your prompt would otherwise instruct Claude to "respond with `{action: X, args: Y}`" — tools are the supported, parseable, validated alternative.

Don't use tool use for:

- **Pure text generation** with no external action — just generate text.
- **Pre-determined sequential pipelines** where Claude has no decision-making — write deterministic code; don't ask Claude to orchestrate.

For multi-turn agent loops with tool use, layer the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) on top — don't hand-roll the loop.

## 2025-2026 currency anchors

- **Parallel tool use is default** on Claude 4.x models. Multiple `tool_use` blocks can come back in one assistant turn — your loop must handle all of them in parallel.
- **`tool_choice` semantics:** `auto` (model decides), `any` (must call one tool), `{type: "tool", name: "..."}` (force specific tool), `none` (no tools, text only).
- **`tool_use_id` round-trip required.** Every `tool_result` must reference the originating `tool_use.id`. The SDK handles this; manual REST users get it wrong.
- **Tool-use accuracy is dominated by tool description quality.** This hasn't changed and won't — clean descriptions are the most leveraged input.

## Patterns + anti-patterns

### Pattern — verb-first names + explicit when/when-not descriptions

```json
{
  "name": "search_orders",
  "description": "Search a customer's order history. Use ONLY when the user explicitly asks about past orders, returns, refunds, or shipment status. Returns up to 20 orders matching the criteria. Does NOT create or modify orders.",
  "input_schema": {
    "type": "object",
    "properties": {
      "customer_id": {"type": "string", "description": "The customer's unique ID (format: cust_XXX)"},
      "status": {"type": "string", "enum": ["pending", "shipped", "delivered", "returned"], "description": "Filter by order status"}
    },
    "required": ["customer_id"]
  }
}
```

Rules:

- **Lead with the verb** — `Search`, `Create`, `Send`, `Delete`. Claude routes by verb.
- **Specify when AND when NOT to use** — explicit negatives reduce mis-routing.
- **Type and describe every parameter.** No untyped, undescribed params.
- **Use `enum` for finite sets.** Don't make Claude guess valid status values.
- **Mark `required` accurately.** A required param Claude can't infer = failed tool call.

### Pattern — tool-use as structured output

The cleanest way to get JSON-compliant structured output is `tool_choice: {"type": "tool", "name": "extract_data"}`. The tool's `input_schema` is your output schema; Claude fills it; you parse `tool_use.input`. More reliable than asking for JSON in prose (which sometimes wraps in markdown fences).

### Pattern — parallel execution of multi-tool responses

When Claude emits multiple `tool_use` blocks in one turn (parallel tool use), execute them concurrently (`asyncio.gather` / `Promise.all`) and return all `tool_result` blocks in the next user message. If your loop handles only the first `tool_use`, you've broken parallel tool use.

### Anti-pattern — one mega-tool with a giant union-type input

`run_action(action_type, action_args)` with a switch inside. Splits into multiple cleaner tools — `send_email`, `create_ticket`, `update_record` — each with their own schema.

### Anti-pattern — tools that return free text

Tool outputs that are unstructured prose force Claude to re-parse them. Return structured data (JSON-stringified or schema-bound).

### Anti-pattern — no iteration cap on the agent loop

Always cap the agent loop at 5-20 tool calls per task. Without a cap, one bug = unbounded spend. The [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) enforces this by default.

### Anti-pattern — tools without idempotency

If Claude retries a tool (it sometimes does), did you just send the email twice? Idempotency on tool name + input hash. See the [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) on tool design.

### Anti-pattern — stripping `tool_use_id` when returning results

The Messages API requires `tool_result` blocks to reference the originating `tool_use_id`. The SDK handles this; manual builders forget.

### Anti-pattern — trusting Claude's tool inputs as authoritative

A user can prompt-inject Claude into calling a tool with out-of-scope arguments. Server-side validate every tool input — permission checks, schema validation, scope enforcement — at the tool layer, not the model layer. See the [security-engineer overlay](/stacks/anthropic-claude/security-engineer/).

## Gotchas

- **Schema validation is on you.** Claude tries to honor `input_schema`, but you must validate on the server before executing. Use Pydantic (Python) or Zod (TypeScript) at tool entry.
- **Tool errors should return `is_error: true`** in the `tool_result`, not propagate up the stack. Let Claude see the error and adapt.
- **Tool ordering is preserved** in a parallel-tool response — but don't depend on Claude calling them in semantic order. If A must happen before B, encode that in the prompt or as separate turns.
- **`tool_choice: "any"` forces a tool call** even when none is appropriate. Use only when you know a tool call is the right output.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — protocol substrate
- [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) — agent loop with tool use built in
- [MCP](/stacks/anthropic-claude/mcp/) — externalize tool surfaces as MCP servers for cross-client reuse
- [Extended Thinking](/stacks/anthropic-claude/extended-thinking/) — interleaved thinking + tool use
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — tool schema design
- [backend-architect overlay](/stacks/anthropic-claude/backend-architect/) — production loop hardening
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — tool input validation, permission scoping
