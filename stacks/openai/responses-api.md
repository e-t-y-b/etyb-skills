---
title: Responses API
description: The 2025 unified surface that supersedes Assistants — server-side conversation state, built-in tools, remote MCP, and an agentic loop in one endpoint. The default for new agentic builds.
product:
  name: Responses API
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect, security-engineer]
  authoritative_url: https://platform.openai.com/docs/api-reference/responses
  notes: "Launched 2025; supersedes Assistants; built-in tools + remote MCP support; rapidly evolving — new event types + tool types ship multiple times per year."
---

## What it is

`POST /v1/responses` is the unified surface OpenAI introduced in 2025 to replace the [Assistants API](/stacks/openai/assistants-api-legacy/) and absorb the agentic + tool-using workloads that were awkward on [Chat Completions](/stacks/openai/chat-completions/). One request can chain multiple tool calls (built-in and function), maintain server-side conversation state, and return a parsed final response. Streaming uses a typed event stream rather than raw delta chunks.

Canonical reference: [platform.openai.com/docs/api-reference/responses](https://platform.openai.com/docs/api-reference/responses).

## When to use

**Use Responses API when:**

- You need any [built-in tool](/stacks/openai/built-in-tools/) — `web_search`, `file_search`, `code_interpreter`, [`computer_use_preview`](/stacks/openai/computer-use/). These don't exist on Chat Completions.
- You want a remote MCP server exposed to the model as a tool (`type: "mcp"`).
- You want server-side conversation state via `previous_response_id` — no client-side message-stitching.
- You're building a multi-step agent loop and want the loop machinery handled server-side.
- You want pre-parsed structured output (Responses returns the parsed object; Chat Completions returns a JSON-encoded string).
- You want clean reasoning-token surfacing for [o-series](/stacks/openai/o-series-reasoning/) models with reasoning summaries.
- **Greenfield in 2026** — Responses is the default for new builds.

**Stay on [Chat Completions](/stacks/openai/chat-completions/) when:**

- The workload is single-turn classification / extraction / vanilla generation with no tools.
- You need OpenAI-compatible third-party endpoints (Groq, Together, vLLM — they serve Chat Completions, almost none serve Responses).
- You need minimum latency for one-shot generation.
- Your framework hasn't migrated yet (most LangChain providers, some gateways).

**Migrate off [Assistants API](/stacks/openai/assistants-api-legacy/) onto Responses immediately** if you're greenfielding on Assistants in 2026 — Assistants is on the deprecation glide path.

## 2025-2026 currency anchors

- **Responses API launched 2025** as the unified surface. The migration path from Assistants is into Responses. New built-in tools land here first.
- **Remote MCP tool input (`type: "mcp"`)** lets you point at an external MCP server. The model sees the MCP's tool set alongside your function tools. This is how Responses consumes external tool surfaces (databases via dbt-mcp, Sentry, Linear, etc.).
- **Responses Batch went GA late 2025** — the [Batch API](/stacks/openai/batch-api/) now wraps Responses too, at 50% off + 24h SLA.
- **Reasoning summary** is exposed on Responses for o-series models — the model can return a human-readable summary of its reasoning alongside the visible answer.
- **`previous_response_id`** replaces the Assistants thread + message model. Pass it to extend a conversation; server handles state.
- **`store: true` on Responses** writes to [Stored Completions](/stacks/openai/stored-completions/) for [Eval Platform](/stacks/openai/eval-platform/) + [Distillation Platform](/stacks/openai/distillation-platform/) consumption.
- **Built-in tools are tier-gated.** A new project on Tier 1 may not have access to `web_search` or `computer_use_preview`. Confirm tier before promising.

## Patterns

### Pattern: greenfield agent on Responses

```python
response = client.responses.create(
    model="gpt-5",
    instructions="You are a customer support agent...",
    input=[
        {"role": "user", "content": user_message},
    ],
    tools=[
        {"type": "web_search"},
        {"type": "function", "name": "create_ticket", "parameters": {...}, "strict": True},
    ],
    previous_response_id=previous_response_id,  # for multi-turn
    store=True,  # for evals + distillation
)
```

One call. Built-in `web_search` and a custom function tool side by side. State carried via `previous_response_id`.

### Pattern: remote MCP as a tool

```python
tools = [
    {"type": "mcp", "server_label": "linear", "server_url": "https://mcp.linear.app/..."},
    {"type": "function", "name": "escalate", "parameters": {...}},
]
```

The model sees Linear's MCP-exposed tools alongside your function tools. Use this to compose external services without rewriting their APIs into function tools.

### Pattern: typed streaming events

Responses streaming emits typed events: `response.created`, `response.output_text.delta`, `response.function_call.arguments.delta`, `response.refusal.delta`, `response.completed`. Handle each event type explicitly. The client UI can render text deltas, surface tool-call progress, and detect refusals separately.

### Pattern: server-side conversation state

```python
first = client.responses.create(model="gpt-5", input=[{"role": "user", "content": "..."}])
second = client.responses.create(
    model="gpt-5",
    input=[{"role": "user", "content": "..."}],
    previous_response_id=first.id,
)
```

No client-side message-stitching. Server holds the chain. Replaces Assistants' thread + run loop.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Greenfielding on [Assistants API](/stacks/openai/assistants-api-legacy/) in 2026 | Use Responses API instead. |
| Using Responses for vanilla one-shot classification | [Chat Completions](/stacks/openai/chat-completions/) is lower overhead. |
| Putting Responses traffic through a Chat-Completions-only gateway | Most gateways (Helicone, LiteLLM) proxy Chat Completions cleanly but Responses partially. Send Responses direct to OpenAI. |
| Manual client-side conversation-state management on Responses | Use `previous_response_id`. |
| Manual `JSON.parse()` on tool args | Responses returns parsed objects; remove the parse. |
| Ignoring typed stream events; parsing raw text | Handle events by `type`. |
| Wiring up own agent loop when Responses' server-side loop fits | Let Responses handle the loop unless you need explicit control. |

## Gotchas

- **Built-in tools are Responses-only.** Chat Completions cannot reach `web_search`, `file_search`, `code_interpreter`, `computer_use_preview`. If you wrote your app on Chat Completions and now need web search, that's an API-surface migration.
- **Tier-gating.** Tier 1 projects may have no access to GPT-5 / o-series / Realtime / Computer Use even with a valid key. Confirm tier before promising features.
- **`previous_response_id` is not infinite.** Server retention has limits; chains broken across long idle windows may fail. For durable multi-day conversations, persist your own state.
- **Tool definitions differ from Chat Completions.** Responses tool schema is flatter (no nested `function` wrapper). Don't copy-paste Chat Completions tool definitions; restructure.
- **Latency is slightly higher** than Chat Completions for equivalent single-shot work due to agentic-loop machinery. For pure generation, prefer Chat Completions.
- **Gateways lag.** LiteLLM / Helicone / Portkey support Chat Completions cleanly; Responses support varies. Verify before assuming a gateway covers your Responses traffic.
- **Streaming structured output** still arrives token-by-token; client cannot `JSON.parse()` until the stream completes. Use partial parsers (e.g. `useObject` in Vercel AI SDK) or buffer.
- **Computer Use on Responses has a massive safety surface** — see [Computer Use](/stacks/openai/computer-use/) before enabling.

## Cross-references

### Related products in this Stack

- [Chat Completions API](/stacks/openai/chat-completions/) — the other primary text surface.
- [Assistants API (legacy)](/stacks/openai/assistants-api-legacy/) — what Responses replaces.
- [Built-in tools](/stacks/openai/built-in-tools/) — Responses-only tool surface.
- [Computer Use](/stacks/openai/computer-use/) — highest-risk Responses-only primitive.
- [Structured Outputs](/stacks/openai/structured-outputs/) — JSON enforcement on Responses + Chat Completions.
- [Function calling / tool use](/stacks/openai/function-calling/) — custom tool design.
- [Agents SDK](/stacks/openai/agents-sdk/) — orchestration layer on top of Responses.
- [Stored Completions](/stacks/openai/stored-completions/) — `store: true` opts in.
- [Batch API](/stacks/openai/batch-api/) — wraps Responses at 50% off.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — surface selection in agent design.
- [backend-architect](/stacks/openai/backend-architect/) — typed-event streaming, idempotency, conversation state.
- [system-architect](/stacks/openai/system-architect/) — Responses vs Chat-Completions vs Realtime composition.
- [security-engineer](/stacks/openai/security-engineer/) — Built-in tools threat models, MCP-tool trust.

### Authoritative sources

- [Responses API reference](https://platform.openai.com/docs/api-reference/responses)
- [Responses API guide](https://platform.openai.com/docs/guides/responses)
- [Migration: Assistants → Responses](https://platform.openai.com/docs/assistants/migration)
