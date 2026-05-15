---
title: Extended Thinking
description: "Claude produces internal reasoning before its final response. `budget_tokens` controls length; `signature` field must round-trip across tool-use turns. Transformative for complex agents via interleaved thinking."
product:
  name: Extended Thinking
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
  notes: "First-class on 4.x; budget_tokens semantics + interleaved thinking with tool use; signature_delta round-trip mandatory."
---

## What it is

Extended Thinking lets Claude produce internal reasoning as `thinking` content blocks before its final `text` response. You configure `thinking={"type": "enabled", "budget_tokens": N}`; the model reasons up to `N` tokens before answering. **Interleaved thinking** — when extended thinking is enabled AND tools are in use — lets Claude think between tool calls (think → call tool → see result → think again → call another tool → respond).

See [Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking).

```python
response = client.messages.create(
    model="claude-sonnet-4-7-20260301",
    max_tokens=8000,
    thinking={"type": "enabled", "budget_tokens": 4000},
    messages=[...]
)
```

## When to use

Enable extended thinking for:

- **Hard reasoning problems** — math, multi-step logic, complex code generation.
- **Agent planning** — let the model think through a plan before executing tool calls.
- **Tasks where you'd prompt "think step by step"** — extended thinking is the supported way to do CoT, with the thinking output separated from the user-facing response.
- **Interleaved with [Tool Use](/stacks/anthropic-claude/tool-use/) on long agent chains** — the model reasons between calls; quality on 50+ step chains observably improves.

Don't enable thinking for:

- **Trivial tasks** — classification, extraction, formatting. The thinking budget is wasted tokens.
- **Latency-critical paths** — thinking adds latency proportional to `budget_tokens`. A 4000-token think-budget adds several seconds.
- **Memory-tool / agent loops where every turn thinks** — costs compound; thinking on every turn often isn't necessary.

## 2025-2026 currency anchors

- **Interleaved thinking** went GA across the 4.x family in 2025; previously beta. Verify model-by-model support against current docs.
- **`signature` field on thinking blocks** must round-trip when passed back to Claude. Stripping or modifying it = API rejection. The [Anthropic SDK](/stacks/anthropic-claude/anthropic-sdk/) preserves it automatically when you pass `response.content` back as the assistant message; manual REST builders forget.
- **Thinking tokens bill at output rate.** A 16K-token thinking budget on every classification query is unconscionable; cost compounds quickly.
- **Bedrock / Vertex parity** on Extended Thinking — verify per-provider in current docs.

## Patterns + anti-patterns

### Pattern — budget proportional to task difficulty

- **Trivial tasks:** thinking disabled.
- **Standard reasoning:** 1K-2K budget.
- **Hard reasoning / code generation:** 4K-8K.
- **Hardest reasoning / long agent planning:** 8K-16K.

Tune via evals — set the lowest budget that meets the quality bar; don't pay for unused thinking.

### Pattern — interleaved thinking on long agent chains

For agents with 10+ tool calls in sequence, interleaved thinking measurably improves coherence. The model thinks between each tool result, plans the next call, and stays oriented to the overall task. Pair with the [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/), which handles the round-tripping correctly.

### Pattern — log thinking, display text

Thinking is the model's scratchpad. Log `thinking` blocks for debugging / replay / audit; display only `text` blocks to end users. Customer-facing UIs don't show scratchpads.

### Anti-pattern — showing thinking to end users

Thinking output isn't polished. It's the model working through a problem, complete with false starts and corrections. Render only the `text` content.

### Anti-pattern — `budget_tokens` too low on hard problems

Claude given 100 tokens to think on a hard problem will either truncate mid-thought (bad output) or skip thinking (back to non-thinking quality). Either bump the budget or disable thinking — middle ground is worst.

### Anti-pattern — `budget_tokens` too high "to be safe"

You pay for thinking tokens at the output rate. A 16K-token budget on every classification query costs dollars per thousand requests for no quality benefit.

### Anti-pattern — modifying thinking blocks between turns

The `signature` field is content-bound. Stripping or modifying it = the API rejects the request. Pass thinking blocks verbatim when round-tripping.

### Anti-pattern — thinking on every turn of a multi-turn chat

Each thinking turn adds latency and cost. Enable thinking selectively — first turn of a task, or hard turns flagged by a router; not every reply in a long conversation.

## Gotchas

- **Signature round-trip is non-obvious.** The SDK handles it; manual REST builders need to copy `thinking` blocks verbatim including the `signature` field when sending follow-up turns.
- **Thinking + tool use** requires explicit support in your loop — both content block types come back; both need to be passed forward correctly.
- **Streaming thinking** — `thinking_delta` events stream in alongside `text_delta`. Decide whether to display, log, or discard during streaming.
- **Token usage** — thinking tokens count in `output_tokens`; budget caps and rate limits apply.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — `thinking` is a request parameter and response content block
- [Tool Use](/stacks/anthropic-claude/tool-use/) — interleaved thinking between tool calls
- [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) — handles signature round-trip
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — when to enable thinking
- [Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking)
