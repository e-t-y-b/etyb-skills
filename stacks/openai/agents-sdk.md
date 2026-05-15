---
title: Agents SDK
description: Rebranded + hardened Swarm. Python + TypeScript libraries for multi-agent orchestration on OpenAI — handoffs, guardrails, tracing, function tools. Best fit for OpenAI-only teams.
product:
  name: Agents SDK
  stack: openai
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, security-engineer]
  authoritative_url: https://github.com/openai/openai-agents-python
  notes: "Rebranded from experimental Swarm (2024) → production-hardened 2025; Python + TypeScript; surface still moving — verify against repo changelog."
---

## What it is

The Agents SDK is OpenAI's production-grade replacement for the experimental Swarm library (2024). It is a thin orchestration layer over the [Responses API](/stacks/openai/responses-api/) with:

- **`Agent` primitive** — model + system prompt + tools + handoff targets.
- **Handoffs** — explicit transfer of conversation control to another agent.
- **Guardrails** — input + output validation hooks.
- **Tracing** — enabled by default, surfaces in OpenAI Platform Logs.
- **Function tools** via `@function_tool` decorator (Python) or `tool()` (TS).
- **[Built-in tools](/stacks/openai/built-in-tools/)** (web_search, file_search, code_interpreter, computer_use_preview) declared inline.

Python: `pip install openai-agents`. TypeScript: `npm install @openai/agents`. Reference: [github.com/openai/openai-agents-python](https://github.com/openai/openai-agents-python).

## When to use

**Use Agents SDK when:**

- You are **OpenAI-only**. The SDK is OpenAI-shaped; cross-provider needs go to LangGraph.
- You want deterministic handoff semantics (triage → specialist).
- You want zero-config tracing in OpenAI's console.
- The team is small enough that one framework's idioms are an asset.
- You want to declaratively wire [built-in tools](/stacks/openai/built-in-tools/) alongside custom function tools.

**Don't use Agents SDK when:**

- Multi-provider routing is real (Claude / Gemini / DeepSeek). Stay on direct SDK + LangGraph.
- You need long-running state machines with persistence + time-travel — that's LangGraph territory.
- You're shipping browser-side agents — the SDK is server-side.
- The orchestration is simple (one model + three tools + no handoffs) — direct [Responses API](/stacks/openai/responses-api/) loop is less abstraction.

**Use [Realtime Agents](/stacks/openai/realtime-agents/)** when the multi-agent flow is voice-based.

## 2025-2026 currency anchors

- **Rebranded from Swarm 2025.** Swarm was experimental; Agents SDK is the production successor.
- **Hardened through 2025-2026** — guardrails, tracing, handoff semantics stabilized.
- **Python + TypeScript** both first-party.
- **Tracing is on by default** in OpenAI Platform Logs. Disable explicitly if you don't want traces; can also pipe to OpenTelemetry.
- **Native [built-in tools](/stacks/openai/built-in-tools/) integration** — declare web_search / file_search / code_interpreter / computer_use_preview alongside your function tools.
- **Native [Responses API](/stacks/openai/responses-api/) under the hood** — Agents SDK is not its own runtime; it's an orchestration layer.

## Patterns

### Pattern: triage + handoffs

```python
from openai_agents import Agent, function_tool, handoff

triage = Agent(
    name="Triage",
    instructions="Route the user to the right specialist.",
    handoffs=[billing_agent, support_agent, technical_agent],
)
billing_agent = Agent(
    name="Billing",
    instructions="Handle billing questions...",
    tools=[lookup_invoice, refund_charge],
)
```

The triage agent decides handoffs; each specialist has its own scoped tools. Handoff is traced.

### Pattern: guardrails on input + output

```python
@input_guardrail
async def detect_pii(ctx, input):
    if contains_pii(input):
        return GuardrailFunctionOutput(output_info="PII detected", tripwire_triggered=True)

@output_guardrail
async def validate_response(ctx, output):
    if not response_passes_policy(output):
        return GuardrailFunctionOutput(output_info="Policy violation", tripwire_triggered=True)
```

Guardrails run before/after the model call; tripwires can abort the agent loop.

### Pattern: function tool with strict schema

```python
@function_tool(strict_mode=True)
async def create_ticket(title: str, priority: Literal["low", "medium", "high"], description: str) -> dict:
    """Create a support ticket. Use when user reports an issue requiring follow-up."""
    return await ticketing_api.create(title=title, priority=priority, description=description)
```

Strict mode enforces JSON schema at decode time. Pydantic-style type annotations generate the schema.

### Pattern: built-in tools inline

```python
agent = Agent(
    model="gpt-5",
    instructions="...",
    tools=[
        {"type": "web_search"},
        {"type": "file_search", "vector_store_ids": [vs.id]},
        create_ticket,  # function tool
    ],
)
```

Mix [built-in tools](/stacks/openai/built-in-tools/) with function tools. Agents SDK normalizes the schema.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Agents SDK on cross-provider workload (need Claude + GPT-5) | Use LangGraph + direct SDKs. Agents SDK is OpenAI-shaped. |
| Custom hand-rolled handoff state machine | Use Agents SDK handoffs — tracing won't capture custom flows. |
| Simple workflow (1 model, 2 tools) on Agents SDK | Overkill. Use [Responses API](/stacks/openai/responses-api/) direct. |
| Disabled tracing in production | Keep it on; it's your forensic trail. Pipe to OTel if you want centralized observability. |
| Long-running multi-day workflows on Agents SDK | Use LangGraph + persistence; Agents SDK doesn't checkpoint. |
| Browser-side agents on Agents SDK | Server-side only. For browser, server proxies the agent. |
| Handoffs without per-agent scoped tools | Each agent should have its own tool list; handoff is a privilege boundary. |

## Gotchas

- **OpenAI-only.** The SDK calls OpenAI directly. No drop-in provider swap.
- **Server-side only.** Don't ship the SDK to the browser; proxy through your server.
- **Tracing overhead** is small but real; benchmark if you're latency-sensitive.
- **Handoff context** — by default, the new agent sees the conversation so far. Configure context filtering if you want isolation.
- **Guardrail tripwires abort the loop.** Plan how the user experiences an abort (graceful message, fallback agent, escalation).
- **Max-iteration guard.** Set one. Default loops can run away on confused agents.
- **Tool calls are not idempotent by default.** See [function calling / tool use](/stacks/openai/function-calling/) for idempotency keys.
- **Pin the SDK version.** It's moving; minor versions may shift handoff semantics.

## Cross-references

### Related products in this Stack

- [Responses API](/stacks/openai/responses-api/) — what Agents SDK calls under the hood.
- [Realtime Agents](/stacks/openai/realtime-agents/) — voice-side companion.
- [Function calling / tool use](/stacks/openai/function-calling/) — function tool implementation.
- [Built-in tools](/stacks/openai/built-in-tools/) — wire alongside function tools.
- [Structured Outputs](/stacks/openai/structured-outputs/) — strict mode on tools.
- [Agents Platform](/stacks/openai/agents-platform/) — the console-side surface.
- [Eval Platform](/stacks/openai/eval-platform/) — eval your agents.

### Role overlays

- [ai-ml-engineer](/stacks/openai/ai-ml-engineer/) — when to pick Agents SDK vs LangGraph vs direct.
- [backend-architect](/stacks/openai/backend-architect/) — runtime + idempotency.
- [security-engineer](/stacks/openai/security-engineer/) — guardrail placement, handoff context isolation.

### Authoritative sources

- [Agents SDK Python repo](https://github.com/openai/openai-agents-python)
- [Agents SDK TypeScript repo](https://github.com/openai/openai-agents-js)
- [Agents SDK docs](https://openai.github.io/openai-agents-python/)
