---
title: Chat Completions API
description: The stable, long-term-supported foundational endpoint. Lowest-overhead surface for one-shot generation, classification, extraction, and OpenAI-compatible third-party endpoints.
product:
  name: Chat Completions API
  stack: openai
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://platform.openai.com/docs/api-reference/chat
  notes: "Stable surface; OpenAI explicitly committed long-term support. Periodic feature drops (e.g., Structured Outputs additions) but no surface-level churn."
---

## What it is

`POST /v1/chat/completions` is OpenAI's foundational text-generation endpoint — the wire format every "OpenAI-compatible" provider re-implements. It accepts a `messages` array (system / user / assistant / tool roles), runs the model, returns a completion. Streaming via SSE is supported.

OpenAI has explicitly committed to long-term support for Chat Completions. The [Responses API](/stacks/openai/responses-api/) is the new default for agentic + built-in-tool workloads, but Chat Completions is **not** being deprecated — it remains the right surface for vanilla generation.

See the canonical reference at [platform.openai.com/docs/api-reference/chat](https://platform.openai.com/docs/api-reference/chat).

## When to use

**Use Chat Completions when:**

- You want minimum SDK surface — one-shot generation, classification, summarization, extraction.
- You need OpenAI-compatible endpoints (Groq, Together, Fireworks, vLLM, Ollama, LM Studio all serve Chat Completions; almost none serve Responses).
- You want the lowest-latency surface — Responses has slightly more overhead due to agentic-loop machinery.
- You're integrating with a framework still on Chat Completions (most LangChain providers, many gateway SDKs).
- You want a simple stream of tokens without conversation-state management.

**Use [Responses API](/stacks/openai/responses-api/) instead when:**

- You need [built-in tools](/stacks/openai/built-in-tools/) (`web_search`, `file_search`, `code_interpreter`, `computer_use_preview`).
- You need server-side conversation state via `previous_response_id`.
- You need remote MCP servers as tools.
- You want pre-parsed structured output (Chat Completions tool calls still return JSON-encoded strings even with `strict: true`).

**Use [Batch API](/stacks/openai/batch-api/) instead when:** workload is bulk and non-interactive. Batch wraps Chat Completions (and Responses + Embeddings) at 50% off with a 24h SLA.

## 2025-2026 currency anchors

- **GPT-5 family is the production default** as of 2025. New builds should not default to `gpt-4o` / `gpt-4-turbo` without a reason. See [GPT-5 family](/stacks/openai/gpt-5/) and [GPT-4.1](/stacks/openai/gpt-4-1/).
- **`response_format: { type: "json_schema", strict: true }`** is the production default for any JSON output. See [Structured Outputs](/stacks/openai/structured-outputs/).
- **`stream_options.include_usage: true`** is mandatory on streaming requests if you want token counts (needed for cost accounting). Without it, the final `usage` object is omitted.
- **Prompt Caching is automatic** when prompts share a prefix of ≥1024 tokens; 50% off on cached input. Architect for cacheability (stable prefix, varying tail). See [Prompt Caching](/stacks/openai/prompt-caching/).
- **`temperature` does not exist on o-series models**. If you're routing reasoning workloads through Chat Completions to an o3/o4 model, pass `reasoning.effort` instead (`low` / `medium` / `high`).
- **OpenAI-compatible endpoints have multiplied.** Almost every inference vendor serves the Chat Completions wire format; this is the surface for multi-provider gateways (LiteLLM, Helicone, Portkey, OpenRouter).
- **Tool-call `arguments` is still a JSON-encoded string** even with `strict: true`. You must `JSON.parse()` it. The strict guarantee is *schema compliance*, not *parsed object return*. Responses API returns the parsed object; Chat Completions does not.

## Patterns

### Pattern: classification / extraction with strict JSON

```python
response = client.chat.completions.create(
    model="gpt-5-mini",
    messages=[
        {"role": "system", "content": "Extract invoice fields..."},
        {"role": "user",   "content": text},
    ],
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "Invoice",
            "strict": True,
            "schema": Invoice.model_json_schema(),
        },
    },
)
data = Invoice.model_validate_json(response.choices[0].message.content)
```

Strict mode + a Pydantic / Zod schema = zero JSON parse failures.

### Pattern: streaming through your service

Always pass `stream_options={"include_usage": True}` so the final chunk carries `prompt_tokens`, `completion_tokens`, `cached_tokens`, and (for o-series) `reasoning_tokens`. Without it, you cannot bill or observe cost per streamed request. See the [backend-architect overlay](/stacks/openai/backend-architect/) for a full SSE example.

### Pattern: cheap-router → expensive-synthesizer

Two-phase: GPT-5 Nano on Chat Completions classifies intent + extracts entities into a structured output; based on intent, route to either a templated reply or an expensive GPT-5 Standard call. Reduces expensive-model calls 50-90%.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Using Chat Completions for an agent that needs web search | Use [Responses API](/stacks/openai/responses-api/) — built-in tools are Responses-only. |
| Greenfield code defaulting to `gpt-4o` / `gpt-4-turbo` | Default to [GPT-5 Standard](/stacks/openai/gpt-5/) or [GPT-4.1](/stacks/openai/gpt-4-1/). |
| Free-form JSON parsing with try/except | [Structured Outputs](/stacks/openai/structured-outputs/) `strict: true` + Pydantic / Zod. |
| Forgetting `stream_options.include_usage` | Set it. No cost data otherwise. |
| Passing `temperature` to o3/o4 via Chat Completions | Use [o-series](/stacks/openai/o-series-reasoning/) `reasoning.effort` instead. |
| Hardcoding `gpt-5` (alias) for high-stakes workload | Pin to a snapshot ID (`gpt-5-2026-04-01`) to stabilize evals. |
| Putting per-request UUIDs / timestamps in the system prompt | Busts the cache. Keep prefix stable. |

## Gotchas

- **Tool args are strings.** `tool_call.function.arguments` is always a JSON-encoded string on Chat Completions, even with `strict: true`. Parse it. Only the Responses API returns a parsed object.
- **Streaming + usage requires opt-in.** Default streaming omits the `usage` chunk.
- **Mid-stream errors are real.** A long stream can fail partway — catch, emit an error SSE event with `request_id`, and log partial output.
- **Tool-iteration loops belong to your code.** Chat Completions has no agentic-loop primitive. If a model emits a tool call, *you* execute it, append the result to `messages`, and call again. Responses API has a server-side loop; Chat Completions does not.
- **`finish_reason: "content_filter"`** indicates the model output was filtered post-generation. Surface it; don't treat as a regular completion.
- **Refusals come back as normal responses** (not errors). Detect via content pattern matching or `finish_reason`.

## Cross-references

### Related products in this Stack

- [Responses API](/stacks/openai/responses-api/) — the new unified surface for agentic + built-in-tool work.
- [Structured Outputs](/stacks/openai/structured-outputs/) — production JSON default.
- [Function calling / tool use](/stacks/openai/function-calling/) — tool definition + execution discipline.
- [Prompt Caching](/stacks/openai/prompt-caching/) — automatic discount; architect the prompt for it.
- [Batch API](/stacks/openai/batch-api/) — wraps Chat Completions at 50% off.
- [GPT-5 family](/stacks/openai/gpt-5/) / [GPT-4.1](/stacks/openai/gpt-4-1/) / [o-series](/stacks/openai/o-series-reasoning/) — model choices for this surface.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — surface selection in context.
- [backend-architect](/stacks/openai/backend-architect/) — SDK plumbing, streaming, idempotency.
- [system-architect](/stacks/openai/system-architect/) — topology + multi-provider compositions.

### Authoritative sources

- [Chat Completions API reference](https://platform.openai.com/docs/api-reference/chat)
- [Chat Completions guide](https://platform.openai.com/docs/guides/text-generation)
- [Streaming guide](https://platform.openai.com/docs/api-reference/streaming)
