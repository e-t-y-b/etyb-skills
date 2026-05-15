---
title: Function calling / tool use
description: Mature surface for defining custom tools the model can call. Pair with Structured Outputs for production. Tool definitions consume tokens — keep them tight.
product:
  name: Function calling
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://platform.openai.com/docs/guides/function-calling
  notes: "Mature; surface stable. Pair with Structured Outputs (strict mode). Schema details and `strict: true` semantics evolved through 2024-2025."
---

## What it is

Function calling lets you declare custom tools the model can invoke. You provide a JSON schema describing each tool's name, purpose, and parameters; the model decides when to call which tool and with what arguments. Available on both [Chat Completions](/stacks/openai/chat-completions/) and [Responses API](/stacks/openai/responses-api/) (with slightly different schema shapes), and on [Agents SDK](/stacks/openai/agents-sdk/) (via `@function_tool` decorator).

Reference: [Function calling guide](https://platform.openai.com/docs/guides/function-calling).

## When to use

**Use function calling when:**

- You need a custom tool — your own API, your database, your downstream service.
- Built-in tools don't cover the case (e.g., your own search API instead of `web_search`).
- You want explicit control over execution (rate limiting, idempotency, observability).

**Use [built-in tools](/stacks/openai/built-in-tools/) instead when:** OpenAI's managed version is sufficient (web_search v0, file_search v0, code_interpreter for scratchpad).

**Don't conflate function calling with [Structured Outputs](/stacks/openai/structured-outputs/):**
- Function calling = tool invocation with structured arguments.
- Structured Outputs = constrained JSON output for the response itself.
- Pair them: tool definitions with `strict: true` use Structured Outputs at the parameter level.

## 2025-2026 currency anchors

- **`strict: true`** on tool definitions is the production default. Schema-compliant JSON arguments at decode time.
- **[Responses API](/stacks/openai/responses-api/)** returns parsed tool-call arguments (object). [Chat Completions](/stacks/openai/chat-completions/) returns JSON-encoded strings — you must `JSON.parse()` them even with `strict: true`.
- **Tool definitions consume input tokens.** A 10-tool agent with verbose descriptions can add 1-3K tokens per request. Tight definitions matter for cost + cache hit rate.
- **Tool schema differences between surfaces:**
  - Chat Completions: `{"type": "function", "function": {"name": ..., "parameters": ...}, "strict": true}`
  - Responses: `{"type": "function", "name": ..., "parameters": ..., "strict": true}` (flatter)
  - Agents SDK: `@function_tool` decorator; SDK generates the schema.
- **Schema strictness rules** (all fields required, no oneOf at top level, `additionalProperties: false`, no deep recursion) — see [Structured Outputs](/stacks/openai/structured-outputs/).

## Patterns

### Pattern: tool definition (Chat Completions)

```python
tools = [{
    "type": "function",
    "function": {
        "name": "create_ticket",
        "description": "Create a support ticket. Use when user reports an issue requiring follow-up.",
        "parameters": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "priority": {"type": "string", "enum": ["low", "medium", "high"]},
                "description": {"type": "string"},
            },
            "required": ["title", "priority", "description"],
            "additionalProperties": False,
        },
        "strict": True,
    },
}]
```

### Pattern: tool definition (Responses API)

```python
tools = [{
    "type": "function",
    "name": "create_ticket",
    "description": "Use when user reports an issue requiring follow-up.",
    "parameters": { ... },
    "strict": True,
}]
```

### Pattern: executing tool calls (Chat Completions)

Tool arguments are a JSON-encoded string. Parse it.

```python
for tool_call in response.choices[0].message.tool_calls:
    name = tool_call.function.name
    args = json.loads(tool_call.function.arguments)
    result = run_tool(name, args)
    messages.append({
        "role": "tool",
        "tool_call_id": tool_call.id,
        "content": json.dumps(result),
    })
```

### Pattern: tool naming + description discipline

The model picks tools based on names + descriptions. Both matter.

- **Verb-noun names** — `create_ticket`, `search_invoices`, `escalate_to_human`.
- **Descriptions tell the model *when* to use the tool.** "Use when..." is more useful than "Does..."
- **One tool, one job.** Don't make `do_anything`. Narrow tools route better.
- **3-7 tools** is the sweet spot. >10 and the model confuses them; <3 means you're doing too much in code.

### Pattern: idempotency keys derived from tool args

```python
def execute_tool_call(tool_call):
    idempotency_key = f"{tool_call.function.name}:{hash(tool_call.function.arguments)}"
    return downstream_service.execute(args, idempotency_key=idempotency_key)
```

Model may retry tool calls (agent loops, errors, re-runs). Idempotency keys prevent duplicate side effects.

### Pattern: structured tool error returns

Don't let exceptions propagate to the model. Return structured errors:

```python
def run_tool(name, args):
    try:
        return {"success": True, "data": _run(name, args)}
    except DownstreamError as e:
        return {"success": False, "error": str(e), "code": e.code}
```

The model decides how to recover (retry, escalate, surface to user). An uncaught exception breaks the agent loop.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Free-form JSON parsing of tool args without `strict: true` | Add `strict: true`. Schema is enforced at decode time. |
| Tool descriptions like "Does X" | "Use when..." — the description is a routing instruction. |
| 15+ tools in one agent | Split into specialized agents with handoffs (see [Agents SDK](/stacks/openai/agents-sdk/)). |
| `do_anything` god-tool | Narrow tools — one job each. |
| Exceptions propagating to the model | Structured `{"success": false, "error": "..."}`. |
| Non-idempotent tools | Idempotency keys from tool args. |
| Tool runtime that takes >30s | Async; return `{"status": "queued"}` immediately. |
| Reordering tool definitions per request | Stable order — preserves [prompt cache](/stacks/openai/prompt-caching/). |
| Tool descriptions copied from internal docs without trimming | Trim to essentials. Tool definitions consume input tokens every request. |

## Gotchas

- **Arguments are strings on Chat Completions.** Even with `strict: true`. `JSON.parse()` always. Only [Responses API](/stacks/openai/responses-api/) returns parsed objects.
- **Strict mode constraints** — see [Structured Outputs](/stacks/openai/structured-outputs/). All fields required, no `oneOf` at top level, `additionalProperties: false`, no deep recursion.
- **Tool definitions consume input tokens** — measurable cost + cache impact. Trim descriptions.
- **Schema must be JSON-Schema-compliant.** Don't invent fields OpenAI doesn't support.
- **Parallel tool calls** — model may emit multiple tool calls in one response. Handle them in parallel where possible; respect tool dependencies.
- **Max-iteration guard** — set one. Agent loops can run away on confused models.
- **Tool result size** — large results (a DB query returning 1000 rows) blow context. Truncate before feeding back; tell the model it was truncated.

## Cross-references

### Related products in this Stack

- [Structured Outputs](/stacks/openai/structured-outputs/) — strict mode for tool params.
- [Responses API](/stacks/openai/responses-api/) — parsed tool calls.
- [Chat Completions API](/stacks/openai/chat-completions/) — string tool args.
- [Agents SDK](/stacks/openai/agents-sdk/) — `@function_tool` decorator.
- [Built-in tools](/stacks/openai/built-in-tools/) — alternative to custom tools.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — tool design + naming + selection.
- [backend-architect](/stacks/openai/backend-architect/) — tool runtime + idempotency + observability.

### Authoritative sources

- [Function calling guide](https://platform.openai.com/docs/guides/function-calling)
- [Structured Outputs guide](https://platform.openai.com/docs/guides/structured-outputs)
